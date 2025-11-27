const std = @import("std");
const models = @import("../../models.zig");

/// Application command permission-related gateway events
pub const ApplicationCommandPermissionEvents = struct {
    /// Application command permissions update event
    pub const ApplicationCommandPermissionsUpdateEvent = struct {
        application_id: u64,
        guild_id: u64,
        id: u64,
        permissions: []models.ApplicationCommandPermission,
    };
};

/// Event parsers for application command permission events
pub const ApplicationCommandPermissionEventParsers = struct {
    pub fn parseApplicationCommandPermissionsUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent {
        return try std.json.parseFromSliceLeaky(ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent, allocator, data, .{});
    }
};

/// Application command permission event utilities
pub const ApplicationCommandPermissionEventUtils = struct {
    pub fn formatPermissionUpdateEvent(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Command permissions updated - App: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.application_id}));
        try summary.appendSlice(" - Guild: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.guild_id}));
        try summary.appendSlice(" - Command: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.id}));
        try summary.appendSlice(" - Permissions: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.permissions.len}));

        return summary.toOwnedSlice();
    }

    pub fn getAffectedApplication(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) u64 {
        return event.application_id;
    }

    pub fn getAffectedGuild(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) u64 {
        return event.guild_id;
    }

    pub fn getAffectedCommand(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) u64 {
        return event.id;
    }

    pub fn getPermissionCount(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) usize {
        return event.permissions.len;
    }

    pub fn hasPermissionForRole(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent, role_id: u64) bool {
        for (event.permissions) |permission| {
            if (permission.id == role_id and permission.type == .role) {
                return true;
            }
        }
        return false;
    }

    pub fn hasPermissionForUser(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent, user_id: u64) bool {
        for (event.permissions) |permission| {
            if (permission.id == user_id and permission.type == .user) {
                return true;
            }
        }
        return false;
    }

    pub fn hasPermissionForChannel(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent, channel_id: u64) bool {
        for (event.permissions) |permission| {
            if (permission.id == channel_id and permission.type == .channel) {
                return true;
            }
        }
        return false;
    }

    pub fn getRolePermissions(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) []models.ApplicationCommandPermission {
        var role_perms = std.ArrayList(models.ApplicationCommandPermission).init(std.heap.page_allocator);
        defer role_perms.deinit();

        for (event.permissions) |permission| {
            if (permission.type == .role) {
                role_perms.append(permission) catch {};
            }
        }

        return role_perms.toOwnedSlice() catch &[_]models.ApplicationCommandPermission{};
    }

    pub fn getUserPermissions(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) []models.ApplicationCommandPermission {
        var user_perms = std.ArrayList(models.ApplicationCommandPermission).init(std.heap.page_allocator);
        defer user_perms.deinit();

        for (event.permissions) |permission| {
            if (permission.type == .user) {
                user_perms.append(permission) catch {};
            }
        }

        return user_perms.toOwnedSlice() catch &[_]models.ApplicationCommandPermission{};
    }

    pub fn getChannelPermissions(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) []models.ApplicationCommandPermission {
        var channel_perms = std.ArrayList(models.ApplicationCommandPermission).init(std.heap.page_allocator);
        defer channel_perms.deinit();

        for (event.permissions) |permission| {
            if (permission.type == .channel) {
                channel_perms.append(permission) catch {};
            }
        }

        return channel_perms.toOwnedSlice() catch &[_]models.ApplicationCommandPermission{};
    }

    pub fn getPermissionSummary(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        const role_perms = getRolePermissions(event);
        const user_perms = getUserPermissions(event);
        const channel_perms = getChannelPermissions(event);

        try summary.appendSlice("Permissions - Roles: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{role_perms.len}));
        try summary.appendSlice(", Users: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{user_perms.len}));
        try summary.appendSlice(", Channels: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{channel_perms.len}));

        return summary.toOwnedSlice();
    }

    pub fn validatePermissionUpdateEvent(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) bool {
        if (event.application_id == 0) return false;
        if (event.guild_id == 0) return false;
        if (event.id == 0) return false;
        if (event.permissions.len == 0) return false;

        for (event.permissions) |permission| {
            if (permission.id == 0) return false;
        }

        return true;
    }

    pub fn isPermissionGranted(permission: models.ApplicationCommandPermission) bool {
        return permission.permission;
    }

    pub fn isPermissionDenied(permission: models.ApplicationCommandPermission) bool {
        return !permission.permission;
    }

    pub fn getPermissionType(permission: models.ApplicationCommandPermission) []const u8 {
        return switch (permission.type) {
            .role => "Role",
            .user => "User",
            .channel => "Channel",
        };
    }

    pub fn formatPermission(permission: models.ApplicationCommandPermission) []const u8 {
        var formatted = std.ArrayList(u8).init(std.heap.page_allocator);
        defer formatted.deinit();

        try formatted.appendSlice(getPermissionType(permission));
        try formatted.appendSlice(" ");
        try formatted.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{permission.id}));
        try formatted.appendSlice(": ");

        if (isPermissionGranted(permission)) {
            try formatted.appendSlice("✓ Allowed");
        } else {
            try formatted.appendSlice("✗ Denied");
        }

        return formatted.toOwnedSlice();
    }

    pub fn getAllPermissionSummaries(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) []const u8 {
        var summaries = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summaries.deinit();

        for (event.permissions, 0..) |permission, i| {
            if (i > 0) try summaries.appendSlice(", ");
            try summaries.appendSlice(formatPermission(permission));
        }

        return summaries.toOwnedSlice();
    }

    pub function hasAnyPermissions(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) bool {
        return event.permissions.len > 0;
    }

    pub function hasAllPermissionsGranted(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) bool {
        for (event.permissions) |permission| {
            if (!isPermissionGranted(permission)) {
                return false;
            }
        }
        return true;
    }

    pub function hasAllPermissionsDenied(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) bool {
        for (event.permissions) |permission| {
            if (isPermissionGranted(permission)) {
                return false;
            }
        }
        return true;
    }

    pub function getGrantedPermissions(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) []models.ApplicationCommandPermission {
        var granted = std.ArrayList(models.ApplicationCommandPermission).init(std.heap.page_allocator);
        defer granted.deinit();

        for (event.permissions) |permission| {
            if (isPermissionGranted(permission)) {
                granted.append(permission) catch {};
            }
        }

        return granted.toOwnedSlice() catch &[_]models.ApplicationCommandPermission{};
    }

    pub function getDeniedPermissions(event: ApplicationCommandPermissionEvents.ApplicationCommandPermissionsUpdateEvent) []models.ApplicationCommandPermission {
        var denied = std.ArrayList(models.ApplicationCommandPermission).init(std.heap.page_allocator);
        defer denied.deinit();

        for (event.permissions) |permission| {
            if (isPermissionDenied(permission)) {
                denied.append(permission) catch {};
            }
        }

        return denied.toOwnedSlice() catch &[_]models.ApplicationCommandPermission{};
    }
};
