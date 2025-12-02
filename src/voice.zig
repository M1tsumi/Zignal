const std = @import("std");
const models = @import("models.zig");

/// Voice connection state management with proper lifecycle handling
pub const VoiceConnection = struct {
    allocator: std.mem.Allocator,
    guild_id: u64,
    channel_id: u64,
    user_id: u64,
    session_id: []const u8,
    token: []const u8,
    endpoint: ?[]const u8,
    websocket: ?std.http.Client = null,
    udp_socket: ?std.posix.socket_t = null,
    state: ConnectionState,
    encryption: EncryptionState,
    audio: AudioState,

    pub const ConnectionState = enum {
        disconnected,
        connecting,
        authenticating,
        connected,
        speaking,
        reconnecting,
        failed,
    };

    pub const EncryptionState = struct {
        mode: EncryptionMode,
        secret_key: [32]u8,
        nonce_prefix: [4]u8,

        pub const EncryptionMode = enum {
            xsalsa20_poly1305,
            xsalsa20_poly1305_lite,
            xsalsa20_poly1305_suffix,
        };

        pub fn init(mode: EncryptionMode) EncryptionState {
            return EncryptionState{
                .mode = mode,
                .secret_key = std.mem.zeroes([32]u8),
                .nonce_prefix = std.mem.zeroes([4]u8),
            };
        }

        pub fn encrypt(self: *EncryptionState, audio_data: []const u8, sequence: u64, timestamp: u32, nonce: [24]u8) ![]u8 {
            _ = self;
            _ = audio_data;
            _ = sequence;
            _ = timestamp;
            _ = nonce;
            // Implementation would use libsodium for XSalsa20-Poly1305 encryption
            return error.NotImplemented;
        }

        pub fn decrypt(self: *EncryptionState, encrypted_data: []const u8, nonce: [24]u8) ![]u8 {
            _ = self;
            _ = encrypted_data;
            _ = nonce;
            // Implementation would use libsodium for XSalsa20-Poly1305 decryption
            return error.NotImplemented;
        }
    };

    pub const AudioState = struct {
        encoder: AudioEncoder,
        decoder: AudioDecoder,
        buffer: AudioBuffer,
        sequence: u64,
        timestamp: u32,

        pub const AudioEncoder = struct {
            sample_rate: u32,
            channels: u2,
            bitrate: u32,
            frame_size: u32,

            pub fn init(sample_rate: u32, channels: u2, bitrate: u32) AudioEncoder {
                return AudioEncoder{
                    .sample_rate = sample_rate,
                    .channels = channels,
                    .bitrate = bitrate,
                    .frame_size = 960, // Standard Opus frame size at 48kHz
                };
            }

            pub fn encode(self: AudioEncoder, pcm_data: []const i16) ![]u8 {
                _ = self;
                _ = pcm_data;
                // Implementation would use libopus for encoding
                return error.NotImplemented;
            }
        };

        pub const AudioDecoder = struct {
            sample_rate: u32,
            channels: u2,

            pub fn init(sample_rate: u32, channels: u2) AudioDecoder {
                return AudioDecoder{
                    .sample_rate = sample_rate,
                    .channels = channels,
                };
            }

            pub fn decode(self: AudioDecoder, opus_data: []const u8) ![]i16 {
                _ = self;
                _ = opus_data;
                // Implementation would use libopus for decoding
                return error.NotImplemented;
            }
        };

        pub const AudioBuffer = struct {
            data: std.ArrayList(i16),
            capacity: usize,
            read_position: usize,
            write_position: usize,

            pub fn init(allocator: std.mem.Allocator, capacity: usize) AudioBuffer {
                return AudioBuffer{
                    .data = std.ArrayList(i16).initCapacity(allocator, capacity) catch unreachable,
                    .capacity = capacity,
                    .read_position = 0,
                    .write_position = 0,
                };
            }

            pub fn write(self: *AudioBuffer, samples: []const i16) !usize {
                const available = self.capacity - self.write_position;
                const to_write = @min(samples.len, available);
                try self.data.appendSlice(samples[0..to_write]);
                self.write_position += to_write;
                return to_write;
            }

            pub fn read(self: *AudioBuffer, buffer: []i16) !usize {
                const available = self.write_position - self.read_position;
                const to_read = @min(buffer.len, available);
                std.mem.copy(i16, buffer, self.data.items[self.read_position .. self.read_position + to_read]);
                self.read_position += to_read;
                return to_read;
            }

            pub fn clear(self: *AudioBuffer) void {
                self.data.clear();
                self.read_position = 0;
                self.write_position = 0;
            }
        };
    };

    pub fn init(allocator: std.mem.Allocator, guild_id: u64, channel_id: u64, user_id: u64) !*VoiceConnection {
        const connection = try allocator.create(VoiceConnection);
        connection.* = .{
            .allocator = allocator,
            .guild_id = guild_id,
            .channel_id = channel_id,
            .user_id = user_id,
            .session_id = "",
            .token = "",
            .endpoint = null,
            .websocket = null,
            .udp_socket = null,
            .state = .disconnected,
            .encryption = EncryptionState.init(.xsalsa20_poly1305),
            .audio = AudioState{
                .encoder = AudioState.AudioEncoder.init(48000, 2, 64000),
                .decoder = AudioState.AudioDecoder.init(48000, 2),
                .buffer = AudioState.AudioBuffer.init(allocator, 4096),
                .sequence = 0,
                .timestamp = 0,
            },
        };
        return connection;
    }

    pub fn deinit(self: *VoiceConnection) void {
        self.disconnect();
        self.allocator.free(self.session_id);
        self.allocator.free(self.token);
        if (self.endpoint) |ep| self.allocator.free(ep);
        self.audio.buffer.data.deinit();
        self.allocator.destroy(self);
    }

    /// Establish voice connection with proper error handling and state management
    pub fn connect(self: *VoiceConnection, session_id: []const u8, token: []const u8, endpoint: []const u8) !void {
        if (self.state != .disconnected) return error.AlreadyConnected;

        self.state = .connecting;

        // Store connection parameters
        self.allocator.free(self.session_id);
        self.session_id = try self.allocator.dupe(u8, session_id);

        self.allocator.free(self.token);
        self.token = try self.allocator.dupe(u8, token);

        if (self.endpoint) |old_ep| self.allocator.free(old_ep);
        self.endpoint = try self.allocator.dupe(u8, endpoint);

        // Connect to voice websocket
        try self.connectWebSocket();
        defer if (self.state == .failed) self.disconnect();

        // Authenticate with voice server
        try self.authenticate();
        defer if (self.state == .failed) self.disconnect();

        // Establish UDP connection for audio
        try self.connectUdp();
        defer if (self.state == .failed) self.disconnect();

        // Setup encryption
        try self.setupEncryption();
        defer if (self.state == .failed) self.disconnect();

        self.state = .connected;
    }

    /// Disconnect with proper cleanup
    pub fn disconnect(self: *VoiceConnection) void {
        if (self.websocket) |ws| {
            ws.close();
            self.websocket = null;
        }

        if (self.udp_socket) |socket| {
            socket.close();
            self.udp_socket = null;
        }

        self.state = .disconnected;
    }

    /// Send audio data with proper sequence and timestamp management
    pub fn sendAudio(self: *VoiceConnection, pcm_data: []const i16) !void {
        if (self.state != .connected and self.state != .speaking) return error.NotConnected;

        // Encode PCM data to Opus
        const opus_data = try self.audio.encoder.encode(pcm_data);
        defer self.allocator.free(opus_data);

        // Encrypt audio data
        const nonce = self.generateNonce(self.audio.sequence, self.audio.timestamp);
        const encrypted_data = try self.encryption.encrypt(opus_data, self.audio.sequence, self.audio.timestamp, nonce);
        defer self.allocator.free(encrypted_data);

        // Send via UDP
        try self.sendUdpPacket(encrypted_data, self.audio.sequence, self.audio.timestamp);

        // Update sequence and timestamp
        self.audio.sequence += 1;
        self.audio.timestamp += 960; // Standard Opus frame size at 48kHz
    }

    /// Set speaking state
    pub fn setSpeaking(self: *VoiceConnection, speaking: bool) !void {
        if (self.state != .connected) return error.NotConnected;

        const speaking_payload = std.json.ObjectMap.init(self.allocator);
        defer speaking_payload.deinit();

        try speaking_payload.put("speaking", std.json.Value{ .integer = @intCast(if (speaking) 1 else 0) });
        try speaking_payload.put("delay", std.json.Value{ .integer = 0 });
        try speaking_payload.put("ssrc", std.json.Value{ .integer = 0 }); // Would be actual SSRC

        const json_string = try std.json.stringifyAlloc(self.allocator, speaking_payload, .{});
        defer self.allocator.free(json_string);

        // Send speaking notification via websocket
        if (self.websocket) |*ws| {
            try ws.writeAll(json_string);
        }

        self.state = if (speaking) .speaking else .connected;
    }

    fn connectWebSocket(self: *VoiceConnection) !void {
        const endpoint = self.endpoint orelse return error.NoEndpoint;
        const url = try std.fmt.allocPrint(self.allocator, "wss://{s}/?v=4", .{endpoint});
        defer self.allocator.free(url);

        var client = std.http.Client{ .allocator = self.allocator };
        defer client.deinit();

        var websocket = try client.openWebsocket(.GET, try std.Uri.parse(url), .{
            .max_header_size = 8192,
            .max_headers = 64,
        });
        errdefer websocket.close();

        self.websocket = websocket;
    }

    fn authenticate(self: *VoiceConnection) !void {
        const auth_payload = std.json.ObjectMap.init(self.allocator);
        defer auth_payload.deinit();

        try auth_payload.put("op", std.json.Value{ .integer = 0 });

        const d_data = std.json.ObjectMap.init(self.allocator);
        defer d_data.deinit();

        try d_data.put("server_id", std.json.Value{ .integer = @intCast(self.guild_id) });
        try d_data.put("user_id", std.json.Value{ .integer = @intCast(self.user_id) });
        try d_data.put("session_id", std.json.Value{ .string = self.session_id });
        try d_data.put("token", std.json.Value{ .string = self.token });

        try auth_payload.put("d", std.json.Value{ .object = d_data });

        const json_string = try std.json.stringifyAlloc(self.allocator, auth_payload, .{});
        defer self.allocator.free(json_string);

        // Send authentication via websocket
        if (self.websocket) |*ws| {
            try ws.writeAll(json_string);
        }

        self.state = .authenticating;
    }

    fn connectUdp(self: *VoiceConnection) !void {
        const endpoint = self.endpoint orelse return error.NoEndpoint;
        const port = 78; // Standard Discord voice UDP port

        const address = try std.net.Address.parseIp(endpoint, port);
        const socket = try std.net.UdpSocket.init(address.any.family);
        errdefer socket.close();

        try socket.connect(address);
        self.udp_socket = socket;
    }

    fn setupEncryption(self: *VoiceConnection) !void {
        // Would receive encryption key from voice server after UDP discovery
        // For now, initialize with zeros
        self.encryption.secret_key = std.mem.zeroes([32]u8);
        self.encryption.nonce_prefix = std.mem.zeroes([4]u8);
    }

    fn generateNonce(self: *VoiceConnection, sequence: u64, timestamp: u32) [24]u8 {
        var nonce: [24]u8 = undefined;
        std.mem.copy(u8, nonce[0..4], &self.encryption.nonce_prefix);
        std.mem.writeIntBig(u32, nonce[4..8], timestamp);
        std.mem.writeIntBig(u32, nonce[8..12], sequence);
        std.mem.set(u8, nonce[12..], 0);
        return nonce;
    }

    fn sendUdpPacket(self: *VoiceConnection, data: []const u8, sequence: u64, timestamp: u32) !void {
        const socket = self.udp_socket orelse return error.NoUdpSocket;

        // Construct RTP packet header
        var packet = std.ArrayList(u8).init(self.allocator);
        defer packet.deinit();

        // RTP header (12 bytes)
        try packet.append(0x80); // Version (2) + Padding (0) + Extension (0) + CSRC count (0)
        try packet.append(0x78); // Marker (0) + Payload type (120 = Opus)

        var seq_buf: [2]u8 = undefined;
        std.mem.writeIntBig(u16, &seq_buf, @intCast(sequence % 65536));
        try packet.appendSlice(&seq_buf);

        var ts_buf: [4]u8 = undefined;
        std.mem.writeIntBig(u32, &ts_buf, timestamp);
        try packet.appendSlice(&ts_buf);

        var ssrc_buf: [4]u8 = undefined;
        std.mem.writeIntBig(u32, &ssrc_buf, 0); // Would be actual SSRC
        try packet.appendSlice(&ssrc_buf);

        // Encrypted audio data
        try packet.appendSlice(data);

        // Send packet
        _ = try socket.send(packet.items);
    }
};

/// Voice server event handling
pub const VoiceEventHandler = struct {
    pub fn onReady(self: *VoiceEventHandler, data: struct {
        ssrc: u32,
        port: u32,
        modes: []const []const u8,
        heartbeat_interval: u32,
        ip: []const u8,
    }) void {
        _ = self;
        _ = data;
        // Handle voice server ready event
    }

    pub fn onSessionDescription(self: *VoiceEventHandler, data: struct {
        mode: []const u8,
        secret_key: [32]u8,
    }) void {
        _ = self;
        _ = data;
        // Handle session description with encryption key
    }

    pub fn onSpeaking(self: *VoiceEventHandler, data: struct {
        user_id: u64,
        speaking: u8,
        delay: u32,
        ssrc: u32,
    }) void {
        _ = self;
        _ = data;
        // Handle speaking event from other users
    }

    pub fn onClientDisconnect(self: *VoiceEventHandler, data: struct {
        user_id: u64,
    }) void {
        _ = self;
        _ = data;
        // Handle user disconnect from voice channel
    }

    pub fn onClientConnect(self: *VoiceEventHandler, data: struct {
        user_id: u64,
    }) void {
        _ = self;
        _ = data;
        // Handle user connect to voice channel
    }
};

/// Voice connection manager for multiple voice connections
pub const VoiceManager = struct {
    allocator: std.mem.Allocator,
    connections: std.hash_map.AutoHashMap(u64, *VoiceConnection), // guild_id -> connection
    event_handler: VoiceEventHandler,

    pub fn init(allocator: std.mem.Allocator, event_handler: VoiceEventHandler) !*VoiceManager {
        const manager = try allocator.create(VoiceManager);
        manager.* = .{
            .allocator = allocator,
            .connections = std.hash_map.AutoHashMap(u64, *VoiceConnection).init(allocator),
            .event_handler = event_handler,
        };
        return manager;
    }

    pub fn deinit(self: *VoiceManager) void {
        var iter = self.connections.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.connections.deinit();
        self.allocator.destroy(self);
    }

    pub fn getConnection(self: *VoiceManager, guild_id: u64) ?*VoiceConnection {
        return self.connections.get(guild_id);
    }

    pub fn createConnection(self: *VoiceManager, guild_id: u64, channel_id: u64, user_id: u64) !*VoiceConnection {
        if (self.connections.contains(guild_id)) return error.ConnectionExists;

        const connection = try VoiceConnection.init(self.allocator, guild_id, channel_id, user_id);
        try self.connections.put(guild_id, connection);
        return connection;
    }

    pub fn removeConnection(self: *VoiceManager, guild_id: u64) bool {
        if (self.connections.fetchRemove(guild_id)) |entry| {
            entry.value.deinit();
            return true;
        }
        return false;
    }

    pub fn getConnectionStats(self: *VoiceManager) struct {
        total_connections: usize,
        connected: usize,
        speaking: usize,
        failed: usize,
    } {
        var connected: usize = 0;
        var speaking: usize = 0;
        var failed: usize = 0;

        var iter = self.connections.iterator();
        while (iter.next()) |entry| {
            switch (entry.value_ptr.state) {
                .connected => connected += 1,
                .speaking => speaking += 1,
                .failed => failed += 1,
                else => {},
            }
        }

        return .{
            .total_connections = self.connections.count(),
            .connected = connected,
            .speaking = speaking,
            .failed = failed,
        };
    }
};
