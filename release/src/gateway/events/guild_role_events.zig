const std = @import("std");
const models = @import("../../models.zig");

/// Guild role-related gateway events
pub const GuildRoleEvents = struct {
    /// Guild role create event
    pub const GuildRoleCreateEvent = struct {
        guild_id: u64,
        role: models.Role,
    };

    /// Guild role update event
    pub const GuildRoleUpdateEvent = struct {
        guild_id: u64,
        role: models.Role,
    };

    /// Guild role delete event
    pub const GuildRoleDeleteEvent = struct {
        guild_id: u64,
        role_id: u64,
    };
};

/// Event parsers for guild role events
pub const GuildRoleEventParsers = struct {
    pub fn parseGuildRoleCreateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildRoleEvents.GuildRoleCreateEvent {
        return try std.json.parseFromSliceLeaky(GuildRoleEvents.GuildRoleCreateEvent, allocator, data, .{});
    }

    pub fn parseGuildRoleUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildRoleEvents.GuildRoleUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildRoleEvents.GuildRoleUpdateEvent, allocator, data, .{});
    }

    pub fn parseGuildRoleDeleteEvent(data: []const u8, allocator: std.mem.Allocator) !GuildRoleEvents.GuildRoleDeleteEvent {
        return try std.json.parseFromSliceLeaky(GuildRoleEvents.GuildRoleDeleteEvent, allocator, data, .{});
    }
};

/// Guild role event utilities
pub const GuildRoleEventUtils = struct {
    pub fn formatRoleEvent(event_type: []const u8, role: ?models.Role, role_id: ?u64) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Role ");
        try summary.appendSlice(event_type);

        if (role) |r| {
            try summary.appendSlice(": ");
            try summary.appendSlice(r.name);
            try summary.appendSlice(" (ID: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{r.id}));
            try summary.appendSlice(")");

            if (r.color != 0) {
                try summary.appendSlice(" - Color: ");
                try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "#{x:0>6}", .{r.color}));
            }

            if (r.position != 0) {
                try summary.appendSlice(" - Position: ");
                try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{r.position}));
            }

            if (r.permissions.len > 0) {
                try summary.appendSlice(" - Permissions: ");
                try summary.appendSlice(try formatPermissions(r.permissions));
            }
        } else if (role_id) |id| {
            try summary.appendSlice(" - ID: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{id}));
        }

        return summary.toOwnedSlice();
    }

    pub fn formatPermissions(permissions: []const u8) []const u8 {
        // This would parse the permission bitfield and format it
        // For now, return the raw permissions string
        return permissions;
    }

    pub fn getRoleColorHex(role: models.Role) []const u8 {
        return try std.fmt.allocPrint(std.heap.page_allocator, "#{x:0>6}", .{role.color});
    }

    pub fn isRoleHoisted(role: models.Role) bool {
        return role.hoist;
    }

    pub fn isRoleManaged(role: models.Role) bool {
        return role.managed;
    }

    pub fn isRoleMentionable(role: models.Role) bool {
        return role.mentionable;
    }

    pub fn isRoleDefault(role: models.Role) bool {
        return role.name == "@everyone";
    }

    pub fn isRoleBot(role: models.Role) bool {
        return role.managed and std.mem.indexOf(u8, role.name, "Bot") != null;
    }

    pub fn isRoleIntegration(role: models.Role) bool {
        return role.managed and std.mem.indexOf(u8, role.name, "Integration") != null;
    }

    pub fn isRoleBoost(role: models.Role) bool {
        return role.managed and std.mem.indexOf(u8, role.name, "Boost") != null;
    }

    pub fn getRoleIconUrl(role: models.Role) ?[]const u8 {
        if (role.icon) |icon| {
            return try std.fmt.allocPrint(
                std.heap.page_allocator,
                "https://cdn.discordapp.com/role-icons/{d}/{s}.png",
                .{ role.id, icon },
            );
        }
        return null;
    }

    pub fn getRoleEmoji(role: models.Role) ?models.Emoji {
        return role.unicode_emoji;
    }

    pub fn validateRole(role: models.Role) bool {
        // Basic validation checks
        if (role.id == 0) return false;
        if (role.name.len == 0) return false;

        // Validate color (0x000000 to 0xFFFFFF)
        if (role.color > 0xFFFFFF) return false;

        return true;
    }

    pub fn compareRolePosition(a: models.Role, b: models.Role) std.math.Order {
        if (a.position < b.position) return .lt;
        if (a.position > b.position) return .gt;

        // If positions are equal, compare by ID (lower ID = higher priority)
        if (a.id < b.id) return .gt;
        if (a.id > b.id) return .lt;

        return .eq;
    }

    pub fn sortRolesByPosition(roles: []models.Role) void {
        std.sort.sort(models.Role, roles, {}, compareRolePosition);
    }

    pub fn getHighestRole(roles: []models.Role) ?models.Role {
        if (roles.len == 0) return null;

        var highest = roles[0];
        for (roles[1..]) |role| {
            if (compareRolePosition(role, highest) == .gt) {
                highest = role;
            }
        }

        return highest;
    }

    pub fn getLowestRole(roles: []models.Role) ?models.Role {
        if (roles.len == 0) return null;

        var lowest = roles[0];
        for (roles[1..]) |role| {
            if (compareRolePosition(role, lowest) == .lt) {
                lowest = role;
            }
        }

        return lowest;
    }

    pub fn hasPermission(role: models.Role, permission: u64) bool {
        // Parse the permission bitfield and check if the permission is set
        // This is a simplified implementation
        const perm_value = std.fmt.parseInt(u64, role.permissions, 10) catch 0;
        return (perm_value & permission) != 0;
    }

    pub fn getRoleSummary(role: models.Role) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(role.name);
        try summary.appendSlice(" (");
        try summary.appendSlice(getRoleColorHex(role));
        try summary.appendSlice(")");

        if (role.hoist) try summary.appendSlice(" [Hoisted]");
        if (role.managed) try summary.appendSlice(" [Managed]");
        if (role.mentionable) try summary.appendSlice(" [Mentionable]");

        return summary.toOwnedSlice();
    }
};
