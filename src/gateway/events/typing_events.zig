const std = @import("std");
const models = @import("../../models.zig");

/// Typing-related gateway events
pub const TypingEvents = struct {
    /// Typing start event
    pub const TypingStartEvent = struct {
        channel_id: u64,
        guild_id: ?u64,
        user_id: u64,
        timestamp: u64,
        member: ?models.GuildMember,
    };
};

/// Event parsers for typing events
pub const TypingEventParsers = struct {
    pub fn parseTypingStartEvent(data: []const u8, allocator: std.mem.Allocator) !TypingEvents.TypingStartEvent {
        return try std.json.parseFromSliceLeaky(TypingEvents.TypingStartEvent, allocator, data, .{});
    }
};

/// Typing management utilities
pub const TypingManager = struct {
    pub const TYPING_TIMEOUT_SECONDS = 10;

    pub fn isTypingExpired(timestamp: u64) bool {
        const current_time = @intCast(u64, std.time.timestamp() * 1000);
        const typing_duration = current_time - timestamp;
        return typing_duration > (TYPING_TIMEOUT_SECONDS * 1000);
    }

    pub fn getTypingDuration(timestamp: u64) u64 {
        const current_time = @intCast(u64, std.time.timestamp() * 1000);
        return current_time - timestamp;
    }

    pub fn formatTypingDuration(duration_ms: u64) []const u8 {
        const seconds = duration_ms / 1000;
        if (seconds < 60) {
            return try std.fmt.allocPrint(std.heap.page_allocator, "{d}s", .{seconds});
        } else {
            const minutes = seconds / 60;
            const remaining_seconds = seconds % 60;
            return try std.fmt.allocPrint(std.heap.page_allocator, "{d}m {d}s", .{ minutes, remaining_seconds });
        }
    }
};

/// Typing state tracking
pub const TypingState = struct {
    user_id: u64,
    channel_id: u64,
    guild_id: ?u64,
    start_time: u64,
    last_update: u64,

    pub fn init(user_id: u64, channel_id: u64, guild_id: ?u64, timestamp: u64) TypingState {
        return TypingState{
            .user_id = user_id,
            .channel_id = channel_id,
            .guild_id = guild_id,
            .start_time = timestamp,
            .last_update = timestamp,
        };
    }

    pub fn update(self: *TypingState, timestamp: u64) void {
        self.last_update = timestamp;
    }

    pub fn isExpired(self: *TypingState) bool {
        return TypingManager.isTypingExpired(self.last_update);
    }

    pub fn getDuration(self: *TypingState) u64 {
        return TypingManager.getTypingDuration(self.start_time);
    }
};

/// Typing tracker for multiple users
pub const TypingTracker = struct {
    allocator: std.mem.Allocator,
    typing_states: std.hash_map.AutoHashMap(u64, TypingState), // user_id -> typing_state

    pub fn init(allocator: std.mem.Allocator) TypingTracker {
        return TypingTracker{
            .allocator = allocator,
            .typing_states = std.hash_map.AutoHashMap(u64, TypingState).init(allocator),
        };
    }

    pub fn deinit(self: *TypingTracker) void {
        self.typing_states.deinit();
    }

    pub fn startTyping(self: *TypingTracker, event: TypingEvents.TypingStartEvent) !void {
        const state = TypingState.init(event.user_id, event.channel_id, event.guild_id, event.timestamp);
        try self.typing_states.put(event.user_id, state);
    }

    pub fn stopTyping(self: *TypingTracker, user_id: u64) void {
        self.typing_states.remove(user_id);
    }

    pub fn updateTyping(self: *TypingTracker, user_id: u64, timestamp: u64) void {
        if (self.typing_states.getEntry(user_id)) |entry| {
            entry.value_ptr.update(timestamp);
        }
    }

    pub fn cleanupExpired(self: *TypingTracker) void {
        var iterator = self.typing_states.iterator();
        while (iterator.next()) |entry| {
            if (entry.value_ptr.isExpired()) {
                self.typing_states.remove(entry.key_ptr.*);
            }
        }
    }

    pub fn getTypingUsers(self: *TypingTracker, channel_id: u64) ![]u64 {
        var typing_users = std.ArrayList(u64).init(self.allocator);
        defer typing_users.deinit();

        var iterator = self.typing_states.iterator();
        while (iterator.next()) |entry| {
            if (entry.value_ptr.channel_id == channel_id and !entry.value_ptr.isExpired()) {
                try typing_users.append(entry.key_ptr.*);
            }
        }

        return typing_users.toOwnedSlice();
    }

    pub fn isUserTyping(self: *TypingTracker, user_id: u64, channel_id: u64) bool {
        if (self.typing_states.get(user_id)) |state| {
            return state.channel_id == channel_id and !state.isExpired();
        }
        return false;
    }

    pub fn getTypingCount(self: *TypingTracker, channel_id: u64) usize {
        var count: usize = 0;
        var iterator = self.typing_states.iterator();
        while (iterator.next()) |entry| {
            if (entry.value_ptr.channel_id == channel_id and !entry.value_ptr.isExpired()) {
                count += 1;
            }
        }
        return count;
    }
};
