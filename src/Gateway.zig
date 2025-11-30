const std = @import("std");
const models = @import("models.zig");
const interactions = @import("interactions.zig");

pub const Gateway = @This();

allocator: std.mem.Allocator,
token: []const u8,
websocket: ?WebSocketConnection = null,
session_id: ?[]const u8 = null,
sequence: ?u64 = null,
heartbeat_interval: ?u32 = null,
last_heartbeat: ?i64 = null,
connected: bool = false,
compression: bool = true,

const WebSocketConnection = struct {
    stream: std.net.Stream,
    allocator: std.mem.Allocator,
    
    fn init(allocator: std.mem.Allocator, stream: std.net.Stream) WebSocketConnection {
        return WebSocketConnection{
            .stream = stream,
            .allocator = allocator,
        };
    }
    
    fn close(self: *WebSocketConnection) void {
        self.stream.close();
    }
    
    fn deinit(self: *WebSocketConnection) void {
        self.close();
    }
    
    fn receiveMessage(self: *WebSocketConnection) ![]u8 {
        // Simplified WebSocket frame parsing
        var buffer: [4096]u8 = undefined;
        const bytes_read = try self.stream.read(&buffer);
        return self.allocator.dupe(u8, buffer[0..bytes_read]);
    }
    
    fn writeMessage(self: *WebSocketConnection, message: []const u8) !void {
        _ = try self.stream.writeAll(message);
    }
};

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
    // For now, create a placeholder connection
    // In a real implementation, this would establish a WebSocket connection
    self.connected = true;
    self.heartbeat_interval = 41250; // Default heartbeat interval
    self.last_heartbeat = std.time.timestamp();
    
    // TODO: Implement actual WebSocket connection
}

pub fn disconnect(self: *Gateway) void {
    if (self.websocket) |*ws| {
        ws.close();
        self.websocket = null;
    }
    self.connected = false;
}

fn handleHello(self: *Gateway) !void {
    // Simplified hello handling for compilation
    self.heartbeat_interval = 41250; // Default Discord heartbeat interval
    self.last_heartbeat = std.time.timestamp();
}

fn receiveMessage(self: *Gateway) ![]u8 {
    if (!self.connected or self.websocket == null) return error.NotConnected;

    // Simplified message receiving for compilation
    var buffer: [4096]u8 = undefined;
    const bytes_read = try self.websocket.?.stream.read(&buffer);
    return self.allocator.dupe(u8, buffer[0..bytes_read]);
}

pub fn sendHeartbeat(self: *Gateway) !void {
    if (!self.connected) return;
    // TODO: Implement heartbeat sending
    self.last_heartbeat = std.time.timestamp();
}

pub fn identify(self: *Gateway) !void {
    _ = self; // TODO: Implement identify payload
    // For now, just mark as identified
}

pub fn gatewayResume(self: *Gateway) !void {
    if (self.session_id == null or self.sequence == null) return error.CannotResume;
    // TODO: Implement resume functionality
}

pub fn startEventLoop(self: *Gateway, event_handler: anytype) !void {
    var heartbeat_timer = std.time.Timer.start() catch unreachable;
    var last_heartbeat_sent: u64 = 0;
    
    while (self.connected) {
        // Check if we need to send a heartbeat
        if (self.heartbeat_interval) |interval| {
            const elapsed_ms = @as(u32, @intCast(heartbeat_timer.read() / std.time.ns_per_ms));
            if (elapsed_ms - last_heartbeat_sent >= interval) {
                try self.sendHeartbeat();
                last_heartbeat_sent = elapsed_ms;
            }
        }

        // Try to receive a message with timeout
        const message = receiveMessageWithTimeout(self, 1000) catch |err| switch (err) {
            error.NotConnected => break,
            else => return err,
        };
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
            1 => { // Heartbeat request
                try self.sendHeartbeat();
                last_heartbeat_sent = @as(u32, @intCast(heartbeat_timer.read() / std.time.ns_per_ms));
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
                // Update heartbeat interval
                var hello_parsed = try std.json.parseFromSlice(struct {
                    op: u8,
                    d: struct {
                        heartbeat_interval: u32,
                    },
                }, self.allocator, message, .{ .ignore_unknown_fields = true });
                defer hello_parsed.deinit();
                
                if (hello_parsed.value.op == 10) {
                    self.heartbeat_interval = hello_parsed.value.d.heartbeat_interval;
                    last_heartbeat_sent = 0;
                    heartbeat_timer.reset();
                }
            },
            11 => { // Heartbeat ACK
                // Update last heartbeat time
                self.last_heartbeat = std.time.timestamp();
            },
            else => {},
        }
    }
}

fn receiveMessageWithTimeout(self: *Gateway, timeout_ms: u32) ![]u8 {
    _ = timeout_ms; // TODO: implement timeout logic
    return self.receiveMessage();
}

fn handleDispatch(self: *Gateway, event_type: []const u8, data: std.json.Value, event_handler: anytype) !void {
    _ = data; // Using simplified event handling for now
    
    if (std.mem.eql(u8, event_type, "READY")) {
        if (self.session_id) |sid| self.allocator.free(sid);
        self.session_id = try self.allocator.dupe(u8, "dummy_session_id");

        if (@hasDecl(@TypeOf(event_handler), "onReady")) {
            // Use minimal dummy data for now
            const dummy_user = models.User{
                .id = 123,
                .username = "TestBot",
                .discriminator = "0001",
                .global_name = null,
                .avatar = null,
                .bot = true,
                .system = false,
                .mfa_enabled = false,
                .locale = "en-US",
                .verified = true,
                .email = null,
                .flags = 0,
                .premium_type = null,
                .public_flags = 0,
                .avatar_decoration = null,
            };
            
            // Create minimal guild with default values
            var dummy_guild = std.mem.zeroes(models.Guild);
            dummy_guild.id = 456;
            dummy_guild.name = "Test Guild";
            dummy_guild.owner_id = 123;
            dummy_guild.permissions = "0";
            
            const guild_slice = try self.allocator.alloc(models.Guild, 1);
            guild_slice[0] = dummy_guild;
            
            try event_handler.onReady(dummy_user, guild_slice);
            self.allocator.free(guild_slice);
        }
    } else if (std.mem.eql(u8, event_type, "MESSAGE_CREATE")) {
        if (@hasDecl(@TypeOf(event_handler), "onMessageCreate")) {
            // Create minimal dummy message
            var dummy_message = std.mem.zeroes(models.Message);
            dummy_message.id = 789;
            dummy_message.channel_id = 101112;
            dummy_message.author = models.User{
                .id = 131415,
                .username = "TestUser",
                .discriminator = "9999",
                .global_name = null,
                .avatar = null,
                .bot = false,
                .system = false,
                .mfa_enabled = false,
                .locale = "en-US",
                .verified = true,
                .email = null,
                .flags = 0,
                .premium_type = null,
                .public_flags = 0,
                .avatar_decoration = null,
            };
            dummy_message.content = "Hello, world!";
            dummy_message.timestamp = "2023-01-01T00:00:00.000000+00:00";
            
            try event_handler.onMessageCreate(dummy_message);
        }
    }
    // Add more event types as needed
}

pub fn updatePresence(self: *Gateway, status: []const u8, _: []models.Activity) !void {
    const presence_data = std.json.ObjectMap.init(self.allocator);
    defer presence_data.deinit();

    const d_data = std.json.ObjectMap.init(self.allocator);
    defer d_data.deinit();

    try d_data.put("since", std.json.Value{.null});
    try d_data.put("activities", std.json.Value{ .array = std.json.ValueArray.init(self.allocator) });
    try d_data.put("status", std.json.Value{ .string = status });
    try d_data.put("afk", std.json.Value{ .bool = false });

    try presence_data.put("op", std.json.Value{ .integer = 3 });
    try presence_data.put("d", std.json.Value{ .object = d_data });

    const json_string = try std.json.stringifyAlloc(self.allocator, presence_data, .{});
    defer self.allocator.free(json_string);

    try self.websocket.?.writeMessage(json_string);
}
