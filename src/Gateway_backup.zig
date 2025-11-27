const std = @import("std");
const models = @import("models.zig");

const Gateway = @This();

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
    if (self.websocket) |ws| ws.deinit();
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

pub fn resume(self: *Gateway) !void {
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
                try self.resume();
            },
            9 => { // Invalid Session
                if (parsed.value.d) |d| {
                    if (d == .bool and d.bool) {
                        try self.resume();
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
    } else if (std.mem.eql(u8, event_type, "GUILD_CREATE")) {
        var parsed = try std.json.parseFromSlice(models.Guild, self.allocator, data, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        if (@hasDecl(@TypeOf(event_handler), "onGuildCreate")) {
            try event_handler.onGuildCreate(parsed.value);
        }
    }
}

pub fn updatePresence(self: *Gateway, status: []const u8, activities: []models.Activity) !void {
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
