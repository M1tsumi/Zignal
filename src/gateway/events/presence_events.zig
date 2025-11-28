const std = @import("std");
const models = @import("../../models.zig");

/// Presence-related gateway events
pub const PresenceEvents = struct {
    /// Presence update event
    pub const PresenceUpdateEvent = struct {
        user: models.User,
        guild_id: u64,
        status: PresenceStatus,
        activities: ?[]models.Activity,
        client_status: ClientStatus,
    };

    /// Presence status enum
    pub const PresenceStatus = enum {
        online,
        dnd,
        idle,
        invisible,
        offline,
    };

    /// Client status information
    pub const ClientStatus = struct {
        desktop: ?PresenceStatus,
        mobile: ?PresenceStatus,
        web: ?PresenceStatus,
    };
};

/// Event parsers for presence events
pub const PresenceEventParsers = struct {
    pub fn parsePresenceUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !PresenceEvents.PresenceUpdateEvent {
        return try std.json.parseFromSliceLeaky(PresenceEvents.PresenceUpdateEvent, allocator, data, .{});
    }
};

/// Presence management utilities
pub const PresenceManager = struct {
    pub fn getStatusString(status: PresenceEvents.PresenceStatus) []const u8 {
        return switch (status) {
            .online => "online",
            .dnd => "dnd",
            .idle => "idle",
            .invisible => "invisible",
            .offline => "offline",
        };
    }

    pub fn parseStatusString(status: []const u8) ?PresenceEvents.PresenceStatus {
        if (std.mem.eql(u8, status, "online")) return .online;
        if (std.mem.eql(u8, status, "dnd")) return .dnd;
        if (std.mem.eql(u8, status, "idle")) return .idle;
        if (std.mem.eql(u8, status, "invisible")) return .invisible;
        if (std.mem.eql(u8, status, "offline")) return .offline;
        return null;
    }

    pub fn isUserOnline(status: PresenceEvents.PresenceStatus) bool {
        return switch (status) {
            .online, .dnd, .idle => true,
            .invisible, .offline => false,
        };
    }

    pub fn isUserActive(client_status: PresenceEvents.ClientStatus) bool {
        return client_status.desktop != null or
            client_status.mobile != null or
            client_status.web != null;
    }
};
