const std = @import("std");
const Gateway = @import("Gateway.zig");
const models = @import("models.zig");
const utils = @import("utils.zig");
const events = @import("events.zig");
const EventHandler = events.EventHandler;

pub const ShardManager = struct {
    allocator: std.mem.Allocator,
    token: []const u8,
    shards: std.ArrayList(*Shard),
    total_shards: u32,
    event_handler: *const fn (event: void, shard: *Shard) void,
    intents: u32,
    compression: bool,

    pub fn init(allocator: std.mem.Allocator, token: []const u8, total_shards: u32, event_handler: *const fn (event: void, shard: *Shard) void, intents: u32, compression: bool) !*ShardManager {
        const manager = try allocator.create(ShardManager);
        manager.* = .{
            .allocator = allocator,
            .token = try allocator.dupe(u8, token),
            .shards = std.ArrayList(*Shard).init(allocator),
            .total_shards = total_shards,
            .event_handler = event_handler,
            .intents = intents,
            .compression = compression,
        };
        return manager;
    }

    pub fn deinit(self: *ShardManager) void {
        for (self.shards.items) |shard| {
            shard.deinit();
        }
        self.shards.deinit();
        self.allocator.free(self.token);
        self.allocator.destroy(self);
    }

    pub fn calculateShards(guild_count: u32) u32 {
        // Discord's recommended sharding calculation
        return @max(1, @divTrunc(guild_count + 2499, 2500));
    }

    pub fn getShardId(guild_id: u64, total_shards: u32) u32 {
        return @intCast((guild_id >> 22) % total_shards);
    }

    pub fn connectAll(self: *ShardManager) !void {
        for (0..self.total_shards) |shard_id| {
            const shard = try Shard.init(self.allocator, self.token, @intCast(shard_id), self.total_shards, self.event_handler, self.intents, self.compression);
            try self.shards.append(shard);
        }

        // Connect all shards with a small delay between each
        for (self.shards.items) |shard| {
            try shard.connect();
            std.time.sleep(5 * std.time.ns_per_s); // 5 second delay between shard connections
        }
    }

    pub fn disconnectAll(self: *ShardManager) void {
        for (self.shards.items) |shard| {
            shard.disconnect();
        }
    }

    pub fn getShard(self: *ShardManager, shard_id: u32) ?*Shard {
        if (shard_id >= self.shards.items.len) return null;
        return self.shards.items[shard_id];
    }

    pub fn getGuildShard(self: *ShardManager, guild_id: u64) ?*Shard {
        const shard_id = getShardId(guild_id, self.total_shards);
        return self.getShard(shard_id);
    }

    pub fn getStats(self: *ShardManager) struct {
        total_shards: u32,
        connected_shards: u32,
        total_guilds: u32,
        total_ready: u32,
    } {
        var connected_shards: u32 = 0;
        var total_guilds: u32 = 0;
        var total_ready: u32 = 0;

        for (self.shards.items) |shard| {
            if (shard.connected) connected_shards += 1;
            total_guilds += shard.guild_count;
            if (shard.ready) total_ready += 1;
        }

        return .{
            .total_shards = self.total_shards,
            .connected_shards = connected_shards,
            .total_guilds = total_guilds,
            .total_ready = total_ready,
        };
    }
};

pub const Shard = struct {
    allocator: std.mem.Allocator,
    token: []const u8,
    shard_id: u32,
    total_shards: u32,
    gateway: ?*Gateway,
    event_handler: *const fn (event: void, shard: *Shard) void,
    intents: u32,
    compression: bool,
    connected: bool = false,
    ready: bool = false,
    guild_count: u32 = 0,
    reconnect_attempts: u32 = 0,
    max_reconnect_attempts: u32 = 5,
    session_id: ?[]const u8 = null,
    sequence: ?u64 = null,

    pub fn init(allocator: std.mem.Allocator, token: []const u8, shard_id: u32, total_shards: u32, event_handler: anytype, intents: u32, compression: bool) !*Shard {
        const shard = try allocator.create(Shard);
        shard.* = .{
            .allocator = allocator,
            .token = try allocator.dupe(u8, token),
            .shard_id = shard_id,
            .total_shards = total_shards,
            .gateway = null,
            .event_handler = event_handler,
            .intents = intents,
            .compression = compression,
        };
        return shard;
    }

    pub fn deinit(self: *Shard) void {
        if (self.gateway) |gw| gw.deinit();
        if (self.session_id) |sid| self.allocator.free(sid);
        self.allocator.free(self.token);
        self.allocator.destroy(self);
    }

    pub fn connect(self: *Shard) !void {
        self.gateway = try Gateway.init(self.allocator, self.token);
        self.gateway.?.compression = self.compression;

        try self.gateway.?.connect();
        self.connected = true;
        self.reconnect_attempts = 0;

        // Start the event loop in a separate task
        const loop_task = async self.eventLoop();
        _ = loop_task;
    }

    pub fn disconnect(self: *Shard) void {
        if (self.gateway) |gw| {
            gw.disconnect();
        }
        self.connected = false;
        self.ready = false;
    }

    pub fn identify(self: *Shard) !void {
        if (self.gateway == null) return error.NotConnected;

        const identify_data = std.json.ObjectMap.init(self.allocator);
        defer identify_data.deinit();

        const d_data = std.json.ObjectMap.init(self.allocator);
        defer d_data.deinit();

        try d_data.put("token", std.json.Value{ .string = self.token });
        try d_data.put("intents", std.json.Value{ .integer = self.intents });
        try d_data.put("shard", std.json.Value{ .array = std.json.ValueArray.init(self.allocator) });

        // Add shard info [shard_id, total_shards]
        var shard_array = std.json.ValueArray.init(self.allocator);
        try shard_array.append(std.json.Value{ .integer = self.shard_id });
        try shard_array.append(std.json.Value{ .integer = self.total_shards });
        try d_data.put("shard", std.json.Value{ .array = shard_array });

        try d_data.put("properties", std.json.Value{
            .object = std.json.ObjectMap.init(self.allocator),
        });

        try identify_data.put("op", std.json.Value{ .integer = 2 });
        try identify_data.put("d", std.json.Value{ .object = d_data });

        const json_string: []const u8 = try std.json.stringifyAlloc(self.allocator, identify_data, .{});
        defer self.allocator.free(json_string);

        // Send identify through gateway
        // In a real implementation, this would be sent
    }

    pub fn shardResume(self: *Shard) !void {
        if (self.gateway == null or self.session_id == null or self.sequence == null) return error.CannotResume;

        const resume_data = std.json.ObjectMap.init(self.allocator);
        defer resume_data.deinit();

        const d_data = std.json.ObjectMap.init(self.allocator);
        defer d_data.deinit();

        try d_data.put("token", std.json.Value{ .string = self.token });
        try d_data.put("session_id", std.json.Value{ .string = self.session_id.? });
        try d_data.put("seq", std.json.Value{ .integer = @intCast(self.sequence.?) });

        try resume_data.put("op", std.json.Value{ .integer = 6 });
        try resume_data.put("d", std.json.Value{ .object = d_data });

        const json_string = try std.json.stringifyAlloc(self.allocator, resume_data, .{});
        defer self.allocator.free(json_string);

        // Send resume through gateway
        // In a real implementation, this would be sent
    }

    pub fn eventLoop(self: *Shard) !void {
        while (self.connected) {
            if (self.gateway) |_| {
                // Handle gateway events
                // In a real implementation, this would process incoming messages
                std.time.sleep(1 * std.time.ns_per_s); // Placeholder
            } else {
                break;
            }
        }
    }

    pub fn handleReconnect(self: *Shard) !void {
        if (self.reconnect_attempts >= self.max_reconnect_attempts) {
            std.log.err("Shard {d} exceeded max reconnect attempts", .{self.shard_id});
            return;
        }

        self.reconnect_attempts += 1;
        const delay = @min(std.time.ns_per_s * std.math.pow(u64, 2, self.reconnect_attempts), 30 * std.time.ns_per_s);

        std.log.info("Shard {d} reconnecting in {d} seconds (attempt {d}/{d})", .{ self.shard_id, delay / std.time.ns_per_s, self.reconnect_attempts, self.max_reconnect_attempts });

        std.time.sleep(delay);

        self.disconnect();
        try self.connect();
    }

    pub fn updatePresence(self: *Shard, status: []const u8, activities: []models.Activity) !void {
        if (self.gateway) |gw| {
            try gw.updatePresence(status, activities);
        }
    }

    pub fn getShardInfo(self: *Shard) struct {
        shard_id: u32,
        total_shards: u32,
        connected: bool,
        ready: bool,
        guild_count: u32,
        reconnect_attempts: u32,
        session_id: ?[]const u8,
        sequence: ?u64,
    } {
        return .{
            .shard_id = self.shard_id,
            .total_shards = self.total_shards,
            .connected = self.connected,
            .ready = self.ready,
            .guild_count = self.guild_count,
            .reconnect_attempts = self.reconnect_attempts,
            .session_id = self.session_id,
            .sequence = self.sequence,
        };
    }
};

pub const ShardEventHandler = struct {
    pub fn onShardReady(shard_id: u32, guild_count: u32) void {
        std.log.info("Shard {d} is ready with {d} guilds", .{ shard_id, guild_count });
    }

    pub fn onShardDisconnect(shard_id: u32, code: u16, reason: []const u8) void {
        std.log.warn("Shard {d} disconnected: {d} - {s}", .{ shard_id, code, reason });
    }

    pub fn onShardReconnect(shard_id: u32) void {
        std.log.info("Shard {d} is reconnecting", .{shard_id});
    }

    pub fn onShardResume(shard_id: u32) void {
        std.log.info("Shard {d} resumed session", .{shard_id});
    }

    pub fn onGuildMoved(old_shard_id: u32, new_shard_id: u32, guild_id: u64) void {
        std.log.info("Guild {d} moved from shard {d} to shard {d}", .{ guild_id, old_shard_id, new_shard_id });
    }
};

pub const AutoSharder = struct {
    allocator: std.mem.Allocator,
    token: []const u8,
    shard_manager: ?*ShardManager,
    event_handler: EventHandler,
    intents: u32,
    compression: bool,
    recommended_shards: u32,

    pub fn init(allocator: std.mem.Allocator, token: []const u8, event_handler: EventHandler, intents: u32, compression: bool) !*AutoSharder {
        const auto_sharder = try allocator.create(AutoSharder);
        auto_sharder.* = .{
            .allocator = allocator,
            .token = try allocator.dupe(u8, token),
            .shard_manager = null,
            .event_handler = event_handler,
            .intents = intents,
            .compression = compression,
            .recommended_shards = 0,
        };
        return auto_sharder;
    }

    pub fn deinit(self: *AutoSharder) void {
        if (self.shard_manager) |sm| sm.deinit();
        self.allocator.free(self.token);
        self.allocator.destroy(self);
    }

    pub fn getGatewayInfo(self: *AutoSharder) !struct {
        url: []const u8,
        shards: u32,
        session_start_limit: struct {
            total: u32,
            remaining: u32,
            reset_after: u32,
            max_concurrency: u32,
        },
    } {
        // In a real implementation, this would make a REST API call to Discord
        // For now, return placeholder values
        return .{
            .url = try self.allocator.dupe(u8, "wss://gateway.discord.gg"),
            .shards = 1,
            .session_start_limit = .{
                .total = 1000,
                .remaining = 1000,
                .reset_after = 0,
                .max_concurrency = 1,
            },
        };
    }

    pub fn start(self: *AutoSharder) !void {
        const gateway_info = try self.getGatewayInfo();
        self.recommended_shards = gateway_info.shards;

        const total_shards = @max(1, self.recommended_shards);

        self.shard_manager = try ShardManager.init(self.allocator, self.token, total_shards, self.event_handler, self.intents, self.compression);

        try self.shard_manager.?.connectAll();
    }

    pub fn stop(self: *AutoSharder) void {
        if (self.shard_manager) |sm| {
            sm.disconnectAll();
        }
    }

    pub fn getRecommendedShards(self: *AutoSharder) u32 {
        return self.recommended_shards;
    }

    pub fn getShardManager(self: *AutoSharder) ?*ShardManager {
        return self.shard_manager;
    }
};

// Utility functions for sharding
pub fn getShardIdForGuild(guild_id: u64, total_shards: u32) u32 {
    return @intCast((guild_id >> 22) % total_shards);
}

pub fn shouldHandleEvent(shard_id: u32, total_shards: u32, guild_id: u64) bool {
    return getShardIdForGuild(guild_id, total_shards) == shard_id;
}

pub fn formatShardStatus(shard_info: Shard.ShardInfo, allocator: std.mem.Allocator) ![]const u8 {
    const status = if (shard_info.connected) if (shard_info.ready) "READY" else "CONNECTING" else "DISCONNECTED";
    return std.fmt.allocPrint(allocator, "Shard {d}/{d}: {s} (Guilds: {d})", .{ shard_info.shard_id, shard_info.total_shards, status, shard_info.guild_count });
}
