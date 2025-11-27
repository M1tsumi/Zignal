const std = @import("std");
const models = @import("models.zig");

pub const Gateway = @This();

allocator: std.mem.Allocator,
token: []const u8,
websocket: ?std.http.Client = null,
session_id: ?[]const u8 = null,
sequence: ?u64 = null,
heartbeat_interval: ?u32 = null,
last_heartbeat: ?i64 = null,
connected: bool = false,
compression: bool = true,

pub fn init(allocator: std.mem.Allocator, token: []const u8) !*Gateway {
    const gateway = try allocator.create(Gateway);
    gateway.* = .{
        .allocator = allocator,
        .token = try allocator.dupe(u8, token),
    };
    return gateway;
}

pub fn deinit(self: *Gateway) void {
    if (self.websocket) |*ws| ws.deinit();
    if (self.session_id) |sid| self.allocator.free(sid);
    self.allocator.free(self.token);
    self.allocator.destroy(self);
}

pub fn connect(self: *Gateway) !void {
    var client = std.http.Client{ .allocator = self.allocator };
    defer client.deinit();

    const url = if (self.compression) 
        "wss://gateway.discord.gg/?v=10&encoding=json&compress=zlib-stream"
    else 
        "wss://gateway.discord.gg/?v=10&encoding=json";
    
    var websocket = try client.openWebsocket(.GET, try std.Uri.parse(url), .{
        .max_header_size = 8192,
        .max_headers = 64,
    });
    errdefer websocket.close();

    self.websocket = websocket;
    self.connected = true;

    try self.handleHello();
}

pub fn disconnect(self: *Gateway) void {
    if (self.websocket) |*ws| {
        ws.close();
        self.websocket = null;
    }
    self.connected = false;
}

fn handleHello(self: *Gateway) !void {
    const hello_data = try self.receiveMessage();
    defer self.allocator.free(hello_data);

    var parsed = try std.json.parseFromSlice(struct {
        op: u8,
        d: struct {
            heartbeat_interval: u32,
        },
    }, self.allocator, hello_data, .{ .ignore_unknown_fields = true });
    defer parsed.deinit();

    if (parsed.value.op != 10) {
        return error.InvalidHello;
    }

    self.heartbeat_interval = parsed.value.d.heartbeat_interval;
    self.last_heartbeat = std.time.timestamp();
}

fn receiveMessage(self: *Gateway) ![]u8 {
    if (!self.connected or self.websocket == null) return error.NotConnected;

    if (self.compression) {
        // Handle zlib compressed messages
        var buffer = std.ArrayList(u8).init(self.allocator);
        defer buffer.deinit();

        while (true) {
            const chunk = try self.websocket.?.receiveMessage();
            defer self.allocator.free(chunk);
            
            try buffer.appendSlice(chunk);
            
            // Check for zlib footer (0x0000ffff)
            if (chunk.len >= 4 and 
                chunk[chunk.len-4] == 0x00 and 
                chunk[chunk.len-3] == 0x00 and 
                chunk[chunk.len-2] == 0xff and 
                chunk[chunk.len-1] == 0xff) {
                break;
            }
        }

        // Decompress the buffer
        var fbs = std.io.fixedBufferStream(buffer.items);
        var decompressor = try std.compress.zlib.decompress(self.allocator, fbs.reader());
        defer decompressor.deinit();

        var decompressed = std.ArrayList(u8).init(self.allocator);
        defer decompressed.deinit();

        try decompressed.writer().writeAll(decompressor.reader());

        return decompressed.toOwnedSlice();
    } else {
        return self.websocket.?.receiveMessage();
    }
}

pub fn sendHeartbeat(self: *Gateway) !void {
    if (!self.connected) return;

    const heartbeat = std.json.ObjectMap.init(self.allocator);
    defer heartbeat.deinit();

    try heartbeat.put("op", std.json.Value{ .integer = 1 });
    try heartbeat.put("d", if (self.sequence) |seq| std.json.Value{ .integer = @intCast(seq) } else std.json.Value{ .null });

    const json_string = try std.json.stringifyAlloc(self.allocator, heartbeat, .{});
    defer self.allocator.free(json_string);

    try self.websocket.?.writeMessage(json_string);
    self.last_heartbeat = std.time.timestamp();
}

pub fn identify(self: *Gateway) !void {
    const identify_data = std.json.ObjectMap.init(self.allocator);
    defer identify_data.deinit();

    const d_data = std.json.ObjectMap.init(self.allocator);
    defer d_data.deinit();

    try d_data.put("token", std.json.Value{ .string = self.token });
    try d_data.put("intents", std.json.Value{ .integer = 513 }); // GUILDS + GUILD_MESSAGES
    try d_data.put("properties", std.json.Value{
        .object = std.json.ObjectMap.init(self.allocator),
    });

    try identify_data.put("op", std.json.Value{ .integer = 2 });
    try identify_data.put("d", std.json.Value{ .object = d_data });

    const json_string = try std.json.stringifyAlloc(self.allocator, identify_data, .{});
    defer self.allocator.free(json_string);

    try self.websocket.?.writeMessage(json_string);
}

pub fn gatewayResume(self: *Gateway) !void {
    if (self.session_id == null or self.sequence == null) return error.CannotResume;

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

    try self.websocket.?.writeMessage(json_string);
}

pub fn startEventLoop(self: *Gateway, event_handler: anytype) !void {
    while (self.connected) {
        const message = try self.receiveMessage();
        defer self.allocator.free(message);

        var parsed = try std.json.parseFromSlice(struct {
            op: u8,
            d: ?std.json.Value,
            s: ?u64,
            t: ?[]const u8,
        }, self.allocator, message, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (parsed.value.s) |seq| {
            self.sequence = seq;
        }

        switch (parsed.value.op) {
            0 => { // Dispatch
                if (parsed.value.t) |event_type| {
                    try self.handleDispatch(event_type, parsed.value.d.?, event_handler);
                }
            },
            1 => { // Heartbeat
                try self.sendHeartbeat();
            },
            7 => { // Reconnect
                try self.gatewayResume();
            },
            9 => { // Invalid Session
                if (parsed.value.d) |d| {
                    if (d == .bool and d.bool) {
                        try self.gatewayResume();
                    } else {
                        try self.identify();
                    }
                }
            },
            10 => { // Hello
                // Already handled in connect
            },
            11 => { // Heartbeat ACK
                // Update last heartbeat time
                self.last_heartbeat = std.time.timestamp();
            },
            else => {},
        }
    }
}

fn handleDispatch(self: *Gateway, event_type: []const u8, data: std.json.Value, event_handler: anytype) !void {
    if (std.mem.eql(u8, event_type, "READY")) {
        var parsed = try std.json.parseFromSlice(struct {
            session_id: []const u8,
            user: models.User,
            guilds: []models.Guild,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (self.session_id) |sid| self.allocator.free(sid);
        self.session_id = try self.allocator.dupe(u8, parsed.value.session_id);

        if (@hasDecl(@TypeOf(event_handler), "onReady")) {
            try event_handler.onReady(parsed.value.user, parsed.value.guilds);
        }
    } else if (std.mem.eql(u8, event_type, "MESSAGE_CREATE")) {
        var parsed = try std.json.parseFromSlice(models.Message, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onMessageCreate")) {
            try event_handler.onMessageCreate(parsed.value);
        }
    } else if (std.mem.eql(u8, event_type, "MESSAGE_UPDATE")) {
        var parsed = try std.json.parseFromSlice(models.Message, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onMessageUpdate")) {
            try event_handler.onMessageUpdate(parsed.value);
        }
    } else if (std.mem.eql(u8, event_type, "MESSAGE_DELETE")) {
        var parsed = try std.json.parseFromSlice(struct {
            id: u64,
            channel_id: u64,
            guild_id: ?u64,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onMessageDelete")) {
            try event_handler.onMessageDelete(parsed.value.id, parsed.value.channel_id, parsed.value.guild_id);
        }
    } else if (std.mem.eql(u8, event_type, "MESSAGE_DELETE_BULK")) {
        var parsed = try std.json.parseFromSlice(struct {
            ids: []u64,
            channel_id: u64,
            guild_id: ?u64,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onMessageDeleteBulk")) {
            try event_handler.onMessageDeleteBulk(parsed.value.ids, parsed.value.channel_id, parsed.value.guild_id);
        }
    } else if (std.mem.eql(u8, event_type, "MESSAGE_REACTION_ADD")) {
        var parsed = try std.json.parseFromSlice(struct {
            user_id: u64,
            channel_id: u64,
            message_id: u64,
            guild_id: ?u64,
            member: ?models.GuildMember,
            emoji: models.Emoji,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onMessageReactionAdd")) {
            try event_handler.onMessageReactionAdd(
                parsed.value.user_id,
                parsed.value.channel_id,
                parsed.value.message_id,
                parsed.value.guild_id,
                parsed.value.member,
                parsed.value.emoji
            );
        }
    } else if (std.mem.eql(u8, event_type, "MESSAGE_REACTION_REMOVE")) {
        var parsed = try std.json.parseFromSlice(struct {
            user_id: u64,
            channel_id: u64,
            message_id: u64,
            guild_id: ?u64,
            emoji: models.Emoji,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onMessageReactionRemove")) {
            try event_handler.onMessageReactionRemove(
                parsed.value.user_id,
                parsed.value.channel_id,
                parsed.value.message_id,
                parsed.value.guild_id,
                parsed.value.emoji
            );
        }
    } else if (std.mem.eql(u8, event_type, "GUILD_CREATE")) {
        var parsed = try std.json.parseFromSlice(models.Guild, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onGuildCreate")) {
            try event_handler.onGuildCreate(parsed.value);
        }
    } else if (std.mem.eql(u8, event_type, "GUILD_UPDATE")) {
        var parsed = try std.json.parseFromSlice(models.Guild, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onGuildUpdate")) {
            try event_handler.onGuildUpdate(parsed.value);
        }
    } else if (std.mem.eql(u8, event_type, "GUILD_DELETE")) {
        var parsed = try std.json.parseFromSlice(struct {
            id: u64,
            unavailable: bool,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onGuildDelete")) {
            try event_handler.onGuildDelete(parsed.value.id, parsed.value.unavailable);
        }
    } else if (std.mem.eql(u8, event_type, "GUILD_MEMBER_ADD")) {
        var parsed = try std.json.parseFromSlice(struct {
            guild_id: u64,
            user: models.User,
            roles: []u64,
            joined_at: []const u8,
            premium_since: ?[]const u8,
            deaf: bool,
            mute: bool,
            pending: bool,
            nick: ?[]const u8,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        const member = models.GuildMember{
            .user = parsed.value.user,
            .nick = if (parsed.value.nick) |n| try self.allocator.dupe(u8, n) else null,
            .roles = try self.allocator.dupe(u64, parsed.value.roles),
            .joined_at = try self.allocator.dupe(u8, parsed.value.joined_at),
            .premium_since = if (parsed.value.premium_since) |ps| try self.allocator.dupe(u8, ps) else null,
            .deaf = parsed.value.deaf,
            .mute = parsed.value.mute,
            .pending = parsed.value.pending,
            .permissions = null,
            .communication_disabled_until = null,
        };

        if (@hasDecl(@TypeOf(event_handler), "onGuildMemberAdd")) {
            try event_handler.onGuildMemberAdd(parsed.value.guild_id, member);
        }
    } else if (std.mem.eql(u8, event_type, "GUILD_MEMBER_REMOVE")) {
        var parsed = try std.json.parseFromSlice(struct {
            guild_id: u64,
            user: models.User,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onGuildMemberRemove")) {
            try event_handler.onGuildMemberRemove(parsed.value.guild_id, parsed.value.user);
        }
    } else if (std.mem.eql(u8, event_type, "GUILD_MEMBER_UPDATE")) {
        var parsed = try std.json.parseFromSlice(struct {
            guild_id: u64,
            roles: []u64,
            user: models.User,
            nick: ?[]const u8,
            avatar: ?[]const u8,
            joined_at: []const u8,
            premium_since: ?[]const u8,
            deaf: bool,
            mute: bool,
            pending: bool,
            communication_disabled_until: ?[]const u8,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        const member = models.GuildMember{
            .user = parsed.value.user,
            .nick = if (parsed.value.nick) |n| try self.allocator.dupe(u8, n) else null,
            .roles = try self.allocator.dupe(u64, parsed.value.roles),
            .joined_at = try self.allocator.dupe(u8, parsed.value.joined_at),
            .premium_since = if (parsed.value.premium_since) |ps| try self.allocator.dupe(u8, ps) else null,
            .deaf = parsed.value.deaf,
            .mute = parsed.value.mute,
            .pending = parsed.value.pending,
            .permissions = null,
            .communication_disabled_until = parsed.value.communication_disabled_until,
        };

        if (@hasDecl(@TypeOf(event_handler), "onGuildMemberUpdate")) {
            try event_handler.onGuildMemberUpdate(parsed.value.guild_id, member);
        }
    } else if (std.mem.eql(u8, event_type, "GUILD_ROLE_CREATE")) {
        var parsed = try std.json.parseFromSlice(struct {
            guild_id: u64,
            role: models.Role,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onGuildRoleCreate")) {
            try event_handler.onGuildRoleCreate(parsed.value.guild_id, parsed.value.role);
        }
    } else if (std.mem.eql(u8, event_type, "GUILD_ROLE_UPDATE")) {
        var parsed = try std.json.parseFromSlice(struct {
            guild_id: u64,
            role: models.Role,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onGuildRoleUpdate")) {
            try event_handler.onGuildRoleUpdate(parsed.value.guild_id, parsed.value.role);
        }
    } else if (std.mem.eql(u8, event_type, "GUILD_ROLE_DELETE")) {
        var parsed = try std.json.parseFromSlice(struct {
            guild_id: u64,
            role_id: u64,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onGuildRoleDelete")) {
            try event_handler.onGuildRoleDelete(parsed.value.guild_id, parsed.value.role_id);
        }
    } else if (std.mem.eql(u8, event_type, "CHANNEL_CREATE")) {
        var parsed = try std.json.parseFromSlice(models.Channel, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onChannelCreate")) {
            try event_handler.onChannelCreate(parsed.value);
        }
    } else if (std.mem.eql(u8, event_type, "CHANNEL_UPDATE")) {
        var parsed = try std.json.parseFromSlice(models.Channel, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onChannelUpdate")) {
            try event_handler.onChannelUpdate(parsed.value);
        }
    } else if (std.mem.eql(u8, event_type, "CHANNEL_DELETE")) {
        var parsed = try std.json.parseFromSlice(models.Channel, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onChannelDelete")) {
            try event_handler.onChannelDelete(parsed.value);
        }
    } else if (std.mem.eql(u8, event_type, "TYPING_START")) {
        var parsed = try std.json.parseFromSlice(struct {
            channel_id: u64,
            guild_id: ?u64,
            user_id: u64,
            timestamp: u64,
            member: ?models.GuildMember,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onTypingStart")) {
            try event_handler.onTypingStart(
                parsed.value.channel_id,
                parsed.value.guild_id,
                parsed.value.user_id,
                parsed.value.timestamp,
                parsed.value.member
            );
        }
    } else if (std.mem.eql(u8, event_type, "PRESENCE_UPDATE")) {
        var parsed = try std.json.parseFromSlice(struct {
            user: models.User,
            guild_id: u64,
            status: []const u8,
            activities: []models.Activity,
            client_status: struct {
                desktop: ?[]const u8,
                mobile: ?[]const u8,
                web: ?[]const u8,
            },
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onPresenceUpdate")) {
            try event_handler.onPresenceUpdate(
                parsed.value.user,
                parsed.value.guild_id,
                parsed.value.status,
                parsed.value.activities,
                parsed.value.client_status
            );
        }
    } else if (std.mem.eql(u8, event_type, "VOICE_STATE_UPDATE")) {
        var parsed = try std.json.parseFromSlice(models.VoiceState, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onVoiceStateUpdate")) {
            try event_handler.onVoiceStateUpdate(parsed.value);
        }
    } else if (std.mem.eql(u8, event_type, "VOICE_SERVER_UPDATE")) {
        var parsed = try std.json.parseFromSlice(struct {
            token: []const u8,
            guild_id: u64,
            endpoint: ?[]const u8,
        }, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onVoiceServerUpdate")) {
            try event_handler.onVoiceServerUpdate(
                parsed.value.token,
                parsed.value.guild_id,
                parsed.value.endpoint
            );
        }
    }
}

pub fn updatePresence(self: *Gateway, status: []const u8, _: []models.Activity) !void {
    const presence_data = std.json.ObjectMap.init(self.allocator);
    defer presence_data.deinit();

    const d_data = std.json.ObjectMap.init(self.allocator);
    defer d_data.deinit();

    try d_data.put("since", std.json.Value{ .null });
    try d_data.put("activities", std.json.Value{ .array = std.json.ValueArray.init(self.allocator) });
    try d_data.put("status", std.json.Value{ .string = status });
    try d_data.put("afk", std.json.Value{ .bool = false });

    try presence_data.put("op", std.json.Value{ .integer = 3 });
    try presence_data.put("d", std.json.Value{ .object = d_data });

    const json_string = try std.json.stringifyAlloc(self.allocator, presence_data, .{});
    defer self.allocator.free(json_string);

    try self.websocket.?.writeMessage(json_string);
}
