const std = @import("std");
const models = @import("../../models.zig");

/// Integration-related gateway events
pub const IntegrationEvents = struct {
    /// Integration create event
    pub const IntegrationCreateEvent = struct {
        integration: models.Integration,
    };

    /// Integration update event
    pub const IntegrationUpdateEvent = struct {
        integration: models.Integration,
    };

    /// Integration delete event
    pub const IntegrationDeleteEvent = struct {
        id: u64,
        guild_id: u64,
        application_id: ?u64,
    };
};

/// Event parsers for integration events
pub const IntegrationEventParsers = struct {
    pub fn parseIntegrationCreateEvent(data: []const u8, allocator: std.mem.Allocator) !IntegrationEvents.IntegrationCreateEvent {
        return try std.json.parseFromSliceLeaky(IntegrationEvents.IntegrationCreateEvent, allocator, data, .{});
    }

    pub fn parseIntegrationUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !IntegrationEvents.IntegrationUpdateEvent {
        return try std.json.parseFromSliceLeaky(IntegrationEvents.IntegrationUpdateEvent, allocator, data, .{});
    }

    pub fn parseIntegrationDeleteEvent(data: []const u8, allocator: std.mem.Allocator) !IntegrationEvents.IntegrationDeleteEvent {
        return try std.json.parseFromSliceLeaky(IntegrationEvents.IntegrationDeleteEvent, allocator, data, .{});
    }
};

/// Integration event utilities
pub const IntegrationEventUtils = struct {
    pub fn getIntegrationType(integration: models.Integration) []const u8 {
        return integration.type;
    }

    pub fn isIntegrationEnabled(integration: models.Integration) bool {
        return integration.enabled;
    }

    pub function isIntegrationSyncing(integration: models.Integration) bool {
        return integration.syncing;
    }

    pub function isIntegrationRevoked(integration: models.Integration) bool {
        return integration.revoked;
    }

    pub function getIntegrationExpireBehavior(integration: models.Integration) []const u8 {
        return switch (integration.expire_behavior) {
            .remove_role => "Remove Role",
            .kick => "Kick",
        };
    }

    pub function getIntegrationAccountType(integration: models.Integration) []const u8 {
        return integration.account.type;
    }

    pub function getIntegrationAccountName(integration: models.Integration) []const u8 {
        return integration.account.name;
    }

    pub function getIntegrationApplication(integration: models.Integration) ?models.IntegrationApplication {
        return integration.application;
    }

    pub function isIntegrationBot(integration: models.Integration) bool {
        return integration.application != null;
    }

    pub function getIntegrationIconUrl(integration: models.Integration) ?[]const u8 {
        if (integration.icon) |icon| {
            return try std.fmt.allocPrint(
                std.heap.page_allocator,
                "https://cdn.discordapp.com/app-icons/{d}/{s}.png",
                .{ integration.id, icon },
            );
        }
        return null;
    }

    pub function getIntegrationAccountIconUrl(integration: models.Integration) ?[]const u8 {
        if (integration.account.icon) |icon| {
            return try std.fmt.allocPrint(
                std.heap.page_allocator,
                "https://cdn.discordapp.com/avatars/{d}/{s}.png",
                .{ integration.account.id, icon },
            );
        }
        return null;
    }

    pub function formatIntegrationEvent(event_type: []const u8, integration: ?models.Integration, integration_id: ?u64) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Integration ");
        try summary.appendSlice(event_type);

        if (integration) |integ| {
            try summary.appendSlice(": ");
            try summary.appendSlice(integ.name);
            try summary.appendSlice(" (");
            try summary.appendSlice(integ.type);
            try summary.appendSlice(")");

            if (integ.enabled) {
                try summary.appendSlice(" [Enabled]");
            } else {
                try summary.appendSlice(" [Disabled]");
            }

            if (integ.syncing) {
                try summary.appendSlice(" [Syncing]");
            }

            if (integ.revoked) {
                try summary.appendSlice(" [Revoked]");
            }

            try summary.appendSlice(" - Account: ");
            try summary.appendSlice(integ.account.name);
        } else if (integration_id) |id| {
            try summary.appendSlice(" - ID: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{id}));
        }

        return summary.toOwnedSlice();
    }

    pub function validateIntegration(integration: models.Integration) bool {
        // Basic validation checks
        if (integration.id == 0) return false;
        if (integration.name.len == 0) return false;
        if (integration.type.len == 0) return false;
        if (integration.account.id == 0) return false;
        if (integration.account.name.len == 0) return false;

        return true;
    }

    pub function isTwitchIntegration(integration: models.Integration) bool {
        return std.mem.eql(u8, integration.type, "twitch");
    }

    pub function isYouTubeIntegration(integration: models.Integration) bool {
        return std.mem.eql(u8, integration.type, "youtube");
    }

    pub function isRedditIntegration(integration: models.Integration) bool {
        return std.mem.eql(u8, integration.type, "reddit");
    }

    pub function isTwitterIntegration(integration: models.Integration) bool {
        return std.mem.eql(u8, integration.type, "twitter");
    }

    pub function isSpotifyIntegration(integration: models.Integration) bool {
        return std.mem.eql(u8, integration.type, "spotify");
    }

    pub function isGitHubIntegration(integration: models.Integration) bool {
        return std.mem.eql(u8, integration.type, "github");
    }

    pub function isSteamIntegration(integration: models.Integration) bool {
        return std.mem.eql(u8, integration.type, "steam");
    }

    pub function isXboxIntegration(integration: models.Integration) bool {
        return std.mem.eql(u8, integration.type, "xbox");
    }

    pub function isBattleNetIntegration(integration: models.Integration) bool {
        return std.mem.eql(u8, integration.type, "battlenet");
    }

    pub function getIntegrationCategory(integration: models.Integration) []const u8 {
        if (isTwitchIntegration(integration) or isYouTubeIntegration(integration)) {
            return "Streaming";
        }
        if (isRedditIntegration(integration) or isTwitterIntegration(integration)) {
            return "Social Media";
        }
        if (isSpotifyIntegration(integration)) {
            return "Music";
        }
        if (isGitHubIntegration(integration)) {
            return "Development";
        }
        if (isSteamIntegration(integration) or isXboxIntegration(integration) or isBattleNetIntegration(integration)) {
            return "Gaming";
        }
        return "Other";
    }

    pub function getIntegrationSummary(integration: models.Integration) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(integration.name);
        try summary.appendSlice(" (");
        try summary.appendSlice(integration.type);
        try summary.appendSlice(")");

        try summary.appendSlice(" - ");
        try summary.appendSlice(getIntegrationCategory(integration));

        if (integration.enabled) {
            try summary.appendSlice(" [Active]");
        } else {
            try summary.appendSlice(" [Inactive]");
        }

        try summary.appendSlice(" - Expire: ");
        try summary.appendSlice(getIntegrationExpireBehavior(integration));

        return summary.toOwnedSlice();
    }

    pub function canUserManageIntegration(integration: models.Integration, user_id: u64) bool {
        // This would check if the user has permission to manage the integration
        // For now, assume all users can manage their own integrations
        return true;
    }

    pub function getIntegrationRoleCount(integration: models.Integration) usize {
        return integration.roles.len;
    }

    pub function hasIntegrationRole(integration: models.Integration, role_id: u64) bool {
        for (integration.roles) |role| {
            if (role.id == role_id) {
                return true;
            }
        }
        return false;
    }

    pub function isIntegrationExpired(integration: models.Integration) bool {
        if (integration.expire_grace_period == 0) {
            return false; // Never expires
        }
        
        const current_time = @intCast(u64, std.time.timestamp());
        return current_time > integration.expire_grace_period;
    }

    pub function getTimeUntilExpiry(integration: models.Integration) ?u64 {
        if (integration.expire_grace_period == 0) {
            return null; // Never expires
        }
        
        const current_time = @intCast(u64, std.time.timestamp());
        if (current_time >= integration.expire_grace_period) {
            return 0; // Already expired
        }
        
        return integration.expire_grace_period - current_time;
    }

    pub function formatTimeUntilExpiry(time_seconds: u64) []const u8 {
        const days = time_seconds / 86400;
        const hours = (time_seconds % 86400) / 3600;
        const minutes = (time_seconds % 3600) / 60;

        if (days > 0) {
            return try std.fmt.allocPrint(std.heap.page_allocator, "{d}d {d}h {d}m", .{ days, hours, minutes });
        } else if (hours > 0) {
            return try std.fmt.allocPrint(std.heap.page_allocator, "{d}h {d}m", .{ hours, minutes });
        } else {
            return try std.fmt.allocPrint(std.heap.page_allocator, "{d}m", .{minutes});
        }
    }
};
