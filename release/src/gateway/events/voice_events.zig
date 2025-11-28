const std = @import("std");
const models = @import("../../models.zig");

/// Voice-related gateway events
pub const VoiceEvents = struct {
    /// Voice state update event
    pub const VoiceStateUpdateEvent = struct {
        guild_id: ?u64,
        channel_id: ?u64,
        user_id: u64,
        member: ?models.GuildMember,
        session_id: []const u8,
        deaf: bool,
        mute: bool,
        self_deaf: bool,
        self_mute: bool,
        self_video: bool,
        self_stream: bool,
        suppress: bool,
        request_to_speak_timestamp: ?u64,
    };

    /// Voice server update event
    pub const VoiceServerUpdateEvent = struct {
        token: []const u8,
        guild_id: u64,
        endpoint: ?[]const u8,
        member_count: ?u32,
    };

    /// Voice channel status update
    pub const VoiceChannelStatusUpdateEvent = struct {
        guild_id: u64,
        channel_id: u64,
        status: VoiceChannelStatus,
    };

    /// Voice channel status types
    pub const VoiceChannelStatus = enum {
        normal,
        full,
        locked,
        custom,
    };
};

/// Event parsers for voice events
pub const VoiceEventParsers = struct {
    pub fn parseVoiceStateUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !VoiceEvents.VoiceStateUpdateEvent {
        return try std.json.parseFromSliceLeaky(VoiceEvents.VoiceStateUpdateEvent, allocator, data, .{});
    }

    pub fn parseVoiceServerUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !VoiceEvents.VoiceServerUpdateEvent {
        return try std.json.parseFromSliceLeaky(VoiceEvents.VoiceServerUpdateEvent, allocator, data, .{});
    }

    pub fn parseVoiceChannelStatusUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !VoiceEvents.VoiceChannelStatusUpdateEvent {
        return try std.json.parseFromSliceLeaky(VoiceEvents.VoiceChannelStatusUpdateEvent, allocator, data, .{});
    }
};

/// Voice state management utilities
pub const VoiceStateManager = struct {
    pub fn isUserInVoiceChannel(event: VoiceEvents.VoiceStateUpdateEvent) bool {
        return event.channel_id != null;
    }

    pub fn isUserMuted(event: VoiceEvents.VoiceStateUpdateEvent) bool {
        return event.mute or event.self_mute;
    }

    pub fn isUserDeafened(event: VoiceEvents.VoiceStateUpdateEvent) bool {
        return event.deaf or event.self_deaf;
    }

    pub fn isUserStreaming(event: VoiceEvents.VoiceStateUpdateEvent) bool {
        return event.self_stream;
    }

    pub fn isUserVideoEnabled(event: VoiceEvents.VoiceStateUpdateEvent) bool {
        return event.self_video;
    }

    pub fn isUserSpeaking(event: VoiceEvents.VoiceStateUpdateEvent) bool {
        return event.suppress == false and !isUserMuted(event) and !isUserDeafened(event);
    }

    pub fn hasRequestToSpeak(event: VoiceEvents.VoiceStateUpdateEvent) bool {
        return event.request_to_speak_timestamp != null;
    }

    pub fn getVoiceStateSummary(event: VoiceEvents.VoiceStateUpdateEvent) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        if (isUserInVoiceChannel(event)) {
            try summary.appendSlice("In voice channel");
        } else {
            try summary.appendSlice("Not in voice channel");
        }

        if (isUserMuted(event)) try summary.appendSlice(" | Muted");
        if (isUserDeafened(event)) try summary.appendSlice(" | Deafened");
        if (isUserStreaming(event)) try summary.appendSlice(" | Streaming");
        if (isUserVideoEnabled(event)) try summary.appendSlice(" | Video");
        if (hasRequestToSpeak(event)) try summary.appendSlice(" | Requested to speak");

        return summary.toOwnedSlice();
    }
};

/// Voice server connection utilities
pub const VoiceServerManager = struct {
    pub fn isValidEndpoint(endpoint: []const u8) bool {
        // Discord voice endpoints follow the pattern: xxx.discord.media
        return std.mem.indexOf(u8, endpoint, ".discord.media") != null;
    }

    pub fn extractServerId(endpoint: []const u8) ?[]const u8 {
        // Extract server ID from endpoint like "atlanta123.discord.media"
        if (std.mem.indexOf(u8, endpoint, ".discord.media")) |index| {
            return endpoint[0..index];
        }
        return null;
    }

    pub fn getVoiceRegion(endpoint: []const u8) ?[]const u8 {
        // Extract region from endpoint like "us-east.discord.media"
        if (std.mem.indexOf(u8, endpoint, ".discord.media")) |index| {
            const server_id = endpoint[0..index];
            // Extract region from server ID patterns
            if (std.mem.startsWith(u8, server_id, "us-")) return "us-east";
            if (std.mem.startsWith(u8, server_id, "eu-")) return "europe";
            if (std.mem.startsWith(u8, server_id, "asia")) return "asia";
            if (std.mem.startsWith(u8, server_id, "brazil")) return "brazil";
            if (std.mem.startsWith(u8, server_id, "sydney")) return "sydney";
            if (std.mem.startsWith(u8, server_id, "japan")) return "japan";
            if (std.mem.startsWith(u8, server_id, "russia")) return "russia";
            if (std.mem.startsWith(u8, server_id, "hongkong")) return "hongkong";
            if (std.mem.startsWith(u8, server_id, "india")) return "india";
            if (std.mem.startsWith(u8, server_id, "southafrica")) return "southafrica";
        }
        return null;
    }

    pub fn formatEndpointInfo(event: VoiceEvents.VoiceServerUpdateEvent) []const u8 {
        var info = std.ArrayList(u8).init(std.heap.page_allocator);
        defer info.deinit();

        try info.appendSlice("Voice Server: ");
        if (event.endpoint) |endpoint| {
            try info.appendSlice(endpoint);
            if (getVoiceRegion(endpoint)) |region| {
                try info.appendSlice(" (");
                try info.appendSlice(region);
                try info.appendSlice(")");
            }
        } else {
            try info.appendSlice("No endpoint");
        }

        if (event.member_count) |count| {
            try info.appendSlice(" | Members: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{count}));
        }

        return info.toOwnedSlice();
    }
};

/// Voice channel tracking
pub const VoiceChannelTracker = struct {
    allocator: std.mem.Allocator,
    voice_states: std.hash_map.AutoHashMap(u64, VoiceEvents.VoiceStateUpdateEvent), // user_id -> voice_state
    channel_users: std.hash_map.AutoHashMap(u64, std.ArrayList(u64)), // channel_id -> user_ids

    pub fn init(allocator: std.mem.Allocator) VoiceChannelTracker {
        return VoiceChannelTracker{
            .allocator = allocator,
            .voice_states = std.hash_map.AutoHashMap(u64, VoiceEvents.VoiceStateUpdateEvent).init(allocator),
            .channel_users = std.hash_map.AutoHashMap(u64, std.ArrayList(u64)).init(allocator),
        };
    }

    pub fn deinit(self: *VoiceChannelTracker) void {
        var iterator = self.channel_users.iterator();
        while (iterator.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.channel_users.deinit();
        self.voice_states.deinit();
    }

    pub fn updateVoiceState(self: *VoiceChannelTracker, event: VoiceEvents.VoiceStateUpdateEvent) !void {
        const user_id = event.user_id;

        // Remove user from previous channel if they were in one
        if (self.voice_states.get(user_id)) |old_state| {
            if (old_state.channel_id) |old_channel_id| {
                if (self.channel_users.get(old_channel_id)) |users| {
                    for (users.items, 0..) |uid, i| {
                        if (uid == user_id) {
                            _ = users.orderedRemove(i);
                            break;
                        }
                    }
                }
            }
        }

        // Update voice state
        try self.voice_states.put(user_id, event);

        // Add user to new channel if they're in one
        if (event.channel_id) |new_channel_id| {
            const users = try self.channel_users.getOrPut(new_channel_id);
            if (!users.found_existing) {
                users.value_ptr.* = std.ArrayList(u64).init(self.allocator);
            }
            try users.value_ptr.append(user_id);
        }
    }

    pub fn getUsersInChannel(self: *VoiceChannelTracker, channel_id: u64) ?[]const u64 {
        if (self.channel_users.get(channel_id)) |users| {
            return users.items;
        }
        return null;
    }

    pub fn getUserCountInChannel(self: *VoiceChannelTracker, channel_id: u64) usize {
        if (self.channel_users.get(channel_id)) |users| {
            return users.items.len;
        }
        return 0;
    }

    pub fn getVoiceState(self: *VoiceChannelTracker, user_id: u64) ?VoiceEvents.VoiceStateUpdateEvent {
        return self.voice_states.get(user_id);
    }

    pub fn removeUser(self: *VoiceChannelTracker, user_id: u64) void {
        if (self.voice_states.get(user_id)) |state| {
            if (state.channel_id) |channel_id| {
                if (self.channel_users.get(channel_id)) |users| {
                    for (users.items, 0..) |uid, i| {
                        if (uid == user_id) {
                            _ = users.orderedRemove(i);
                            break;
                        }
                    }
                }
            }
        }
        self.voice_states.remove(user_id);
    }

    pub fn getActiveChannels(self: *VoiceChannelTracker) ![]u64 {
        var channels = std.ArrayList(u64).init(self.allocator);
        defer channels.deinit();

        var iterator = self.channel_users.iterator();
        while (iterator.next()) |entry| {
            if (entry.value_ptr.items.len > 0) {
                try channels.append(entry.key_ptr.*);
            }
        }

        return channels.toOwnedSlice();
    }

    pub fn getChannelSummary(self: *VoiceChannelTracker, channel_id: u64) []const u8 {
        const user_count = self.getUserCountInChannel(channel_id);
        return std.fmt.allocPrint(std.heap.page_allocator, "Channel {d}: {d} users", .{ channel_id, user_count }) catch "Error";
    }
};
