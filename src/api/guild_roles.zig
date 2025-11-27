const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild role management for server role operations
pub const GuildRoleManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildRoleManager {
        return GuildRoleManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild roles
    pub fn getGuildRoles(self: *GuildRoleManager, guild_id: u64) ![]models.Role {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/roles",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Role, response.body, .{});
    }

    /// Create guild role
    pub fn createGuildRole(
        self: *GuildRoleManager,
        guild_id: u64,
        name: ?[]const u8,
        color: ?u32,
        hoist: ?bool,
        icon: ?[]const u8,
        unicode_emoji: ?[]const u8,
        mentionable: ?bool,
        permissions: ?u64,
    ) !models.Role {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/roles",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = struct {
            name: ?[]const u8,
            color: ?u32,
            hoist: ?bool,
            icon: ?[]const u8,
            unicode_emoji: ?[]const u8,
            mentionable: ?bool,
            permissions: ?u64,
        }{
            .name = name,
            .color = color,
            .hoist = hoist,
            .icon = icon,
            .unicode_emoji = unicode_emoji,
            .mentionable = mentionable,
            .permissions = permissions,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Role, response.body, .{});
    }

    /// Modify guild role positions
    pub fn modifyGuildRolePositions(
        self: *GuildRoleManager,
        guild_id: u64,
        positions: []struct { id: u64, position: ?i64 },
    ) ![]models.Role {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/roles",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const json_payload = try std.json.stringifyAlloc(self.allocator, positions, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Role, response.body, .{});
    }

    /// Modify guild role
    pub fn modifyGuildRole(
        self: *GuildRoleManager,
        guild_id: u64,
        role_id: u64,
        name: ?[]const u8,
        color: ?u32,
        hoist: ?bool,
        icon: ?[]const u8,
        unicode_emoji: ?[]const u8,
        mentionable: ?bool,
        permissions: ?u64,
    ) !models.Role {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/roles/{d}",
            .{ self.client.base_url, guild_id, role_id },
        );
        defer self.allocator.free(url);

        const payload = struct {
            name: ?[]const u8,
            color: ?u32,
            hoist: ?bool,
            icon: ?[]const u8,
            unicode_emoji: ?[]const u8,
            mentionable: ?bool,
            permissions: ?u64,
        }{
            .name = name,
            .color = color,
            .hoist = hoist,
            .icon = icon,
            .unicode_emoji = unicode_emoji,
            .mentionable = mentionable,
            .permissions = permissions,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Role, response.body, .{});
    }

    /// Delete guild role
    pub fn deleteGuildRole(
        self: *GuildRoleManager,
        guild_id: u64,
        role_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/roles/{d}",
            .{ self.client.base_url, guild_id, role_id },
        );
        defer self.allocator.free(url);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }
};

/// Guild role utilities
pub const GuildRoleUtils = struct {
    pub fn getRoleId(role: models.Role) u64 {
        return role.id;
    }

    pub fn getRoleName(role: models.Role) []const u8 {
        return role.name;
    }

    pub fn getRoleColor(role: models.Role) u32 {
        return role.color;
    }

    pub fn getRoleHoist(role: models.Role) bool {
        return role.hoist;
    }

    pub fn getRolePosition(role: models.Role) i64 {
        return role.position;
    }

    pub fn getRolePermissions(role: models.Role) u64 {
        return role.permissions;
    }

    pub fn roleHasPermission(role: models.Role, permission: models.Permission) bool {
        return (getRolePermissions(role) & @intFromEnum(permission)) != 0;
    }

    pub fn getRoleManaged(role: models.Role) bool {
        return role.managed;
    }

    pub fn getRoleMentionable(role: models.Role) bool {
        return role.mentionable;
    }

    pub fn getRoleIcon(role: models.Role) ?[]const u8 {
        return role.icon;
    }

    pub fn getRoleUnicodeEmoji(role: models.Role) ?[]const u8 {
        return role.unicode_emoji;
    }

    pub fn getRoleFlags(role: models.Role) u32 {
        return role.flags;
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
        return std.mem.eql(u8, role.name, "@everyone");
    }

    pub fn isRoleAdmin(role: models.Role) bool {
        return roleHasPermission(role, .administrator);
    }

    pub fn isRoleModerator(role: models.Role) bool {
        return roleHasPermission(role, .manage_messages) or 
               roleHasPermission(role, .kick_members) or 
               roleHasPermission(role, .ban_members);
    }

    pub fn isRoleBooster(role: models.Role) bool {
        return roleHasPermission(role, .manage_guild) or 
               roleHasPermission(role, .manage_channels) or 
               roleHasPermission(role, .manage_roles);
    }

    pub fn hasRoleIcon(role: models.Role) bool {
        return role.icon != null;
    }

    pub fn hasRoleUnicodeEmoji(role: models.Role) bool {
        return role.unicode_emoji != null;
    }

    pub fn hasRoleColor(role: models.Role) bool {
        return getRoleColor(role) != 0;
    }

    pub fn formatRoleMention(role: models.Role) []const u8 {
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "<@&{d}>",
            .{getRoleId(role)},
        );
    }

    pub fn formatRoleHexColor(role: models.Role) []const u8 {
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "#{x:0>6}",
            .{getRoleColor(role)},
        );
    }

    pub fn formatRoleRgbColor(role: models.Role) struct { r: u8, g: u8, b: u8 } {
        const color = getRoleColor(role);
        return .{
            .r = @intCast((color >> 16) & 0xFF),
            .g = @intCast((color >> 8) & 0xFF),
            .b = @intCast(color & 0xFF),
        };
    }

    pub fn validateRoleName(name: []const u8) bool {
        // Role names must be 1-100 characters
        return name.len >= 1 and name.len <= 100;
    }

    pub fn validateRoleColor(color: u32) bool {
        // Colors must be within 0x000000 to 0xFFFFFF
        return color <= 0xFFFFFF;
    }

    pub fn validateRole(role: models.Role) bool {
        if (!validateRoleName(getRoleName(role))) return false;
        if (!validateRoleColor(getRoleColor(role))) return false;
        if (getRoleId(role) == 0) return false;

        return true;
    }

    pub fn getRolesByName(roles: []models.Role, name: []const u8) []models.Role {
        var filtered = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (roles) |role| {
            if (std.mem.eql(u8, getRoleName(role), name)) {
                filtered.append(role) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn getRolesByPosition(roles: []models.Role, position: i64) []models.Role {
        var filtered = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (roles) |role| {
            if (getRolePosition(role) == position) {
                filtered.append(role) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn getRolesByPermission(roles: []models.Role, permission: u64) []models.Role {
        var filtered = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (roles) |role| {
            if ((getRolePermissions(role) & permission) != 0) {
                filtered.append(role) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn getHoistedRoles(roles: []models.Role) []models.Role {
        var filtered = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (roles) |role| {
            if (isRoleHoisted(role)) {
                filtered.append(role) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn getManagedRoles(roles: []models.Role) []models.Role {
        var filtered = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (roles) |role| {
            if (isRoleManaged(role)) {
                filtered.append(role) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn getMentionableRoles(roles: []models.Role) []models.Role {
        var filtered = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (roles) |role| {
            if (isRoleMentionable(role)) {
                filtered.append(role) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn getRolesWithColor(roles: []models.Role) []models.Role {
        var filtered = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (roles) |role| {
            if (hasRoleColor(role)) {
                filtered.append(role) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn getRolesWithIcon(roles: []models.Role) []models.Role {
        var filtered = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (roles) |role| {
            if (hasRoleIcon(role)) {
                filtered.append(role) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn getRolesWithUnicodeEmoji(roles: []models.Role) []models.Role {
        var filtered = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (roles) |role| {
            if (hasRoleUnicodeEmoji(role)) {
                filtered.append(role) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn getAdminRoles(roles: []models.Role) []models.Role {
        var filtered = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (roles) |role| {
            if (isRoleAdmin(role)) {
                filtered.append(role) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn getModeratorRoles(roles: []models.Role) []models.Role {
        var filtered = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (roles) |role| {
            if (isRoleModerator(role)) {
                filtered.append(role) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn getBoosterRoles(roles: []models.Role) []models.Role {
        var filtered = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (roles) |role| {
            if (isRoleBooster(role)) {
                filtered.append(role) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn searchRoles(roles: []models.Role, query: []const u8) []models.Role {
        var results = std.ArrayList(models.Role).init(std.heap.page_allocator);
        defer results.deinit();

        for (roles) |role| {
            if (std.mem.indexOf(u8, getRoleName(role), query) != null) {
                results.append(role) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.Role{};
    }

    pub fn sortRolesByName(roles: []models.Role) void {
        std.sort.sort(models.Role, roles, {}, compareRolesByName);
    }

    pub fn sortRolesByPosition(roles: []models.Role) void {
        std.sort.sort(models.Role, roles, {}, compareRolesByPosition);
    }

    pub fn sortRolesByColor(roles: []models.Role) void {
        std.sort.sort(models.Role, roles, {}, compareRolesByColor);
    }

    fn compareRolesByName(_: void, a: models.Role, b: models.Role) std.math.Order {
        return std.mem.compare(u8, getRoleName(a), getRoleName(b));
    }

    fn compareRolesByPosition(_: void, a: models.Role, b: models.Role) std.math.Order {
        return std.math.order(getRolePosition(b), getRolePosition(a)); // Descending order
    }

    fn compareRolesByColor(_: void, a: models.Role, b: models.Role) std.math.Order {
        return std.math.order(getRoleColor(a), getRoleColor(b));
    }

    pub fn getRoleStatistics(roles: []models.Role) struct {
        total_roles: usize,
        hoisted_roles: usize,
        managed_roles: usize,
        mentionable_roles: usize,
        roles_with_color: usize,
        roles_with_icon: usize,
        roles_with_unicode_emoji: usize,
        admin_roles: usize,
        moderator_roles: usize,
        booster_roles: usize,
    } {
        var hoisted_count: usize = 0;
        var managed_count: usize = 0;
        var mentionable_count: usize = 0;
        var with_color_count: usize = 0;
        var with_icon_count: usize = 0;
        var with_unicode_emoji_count: usize = 0;
        var admin_count: usize = 0;
        var moderator_count: usize = 0;
        var booster_count: usize = 0;

        for (roles) |role| {
            if (isRoleHoisted(role)) {
                hoisted_count += 1;
            }

            if (isRoleManaged(role)) {
                managed_count += 1;
            }

            if (isRoleMentionable(role)) {
                mentionable_count += 1;
            }

            if (hasRoleColor(role)) {
                with_color_count += 1;
            }

            if (hasRoleIcon(role)) {
                with_icon_count += 1;
            }

            if (hasRoleUnicodeEmoji(role)) {
                with_unicode_emoji_count += 1;
            }

            if (isRoleAdmin(role)) {
                admin_count += 1;
            }

            if (isRoleModerator(role)) {
                moderator_count += 1;
            }

            if (isRoleBooster(role)) {
                booster_count += 1;
            }
        }

        return .{
            .total_roles = roles.len,
            .hoisted_roles = hoisted_count,
            .managed_roles = managed_count,
            .mentionable_roles = mentionable_count,
            .roles_with_color = with_color_count,
            .roles_with_icon = with_icon_count,
            .roles_with_unicode_emoji = with_unicode_emoji_count,
            .admin_roles = admin_count,
            .moderator_roles = moderator_count,
            .booster_roles = booster_count,
        };
    }

    pub fn hasRole(roles: []models.Role, role_id: u64) bool {
        for (roles) |role| {
            if (getRoleId(role) == role_id) {
                return true;
            }
        }
        return false;
    }

    pub fn getRole(roles: []models.Role, role_id: u64) ?models.Role {
        for (roles) |role| {
            if (getRoleId(role) == role_id) {
                return role;
            }
        }
        return null;
    }

    pub fn getRoleCount(roles: []models.Role) usize {
        return roles.len;
    }

    pub fn getDefaultRole(roles: []models.Role) ?models.Role {
        for (roles) |role| {
            if (isRoleDefault(role)) {
                return role;
            }
        }
        return null;
    }

    pub fn getHighestRole(roles: []models.Role) ?models.Role {
        if (roles.len == 0) return null;
        
        var highest = roles[0];
        for (roles[1..]) |role| {
            if (getRolePosition(role) > getRolePosition(highest)) {
                highest = role;
            }
        }
        return highest;
    }

    pub fn getLowestRole(roles: []models.Role) ?models.Role {
        if (roles.len == 0) return null;
        
        var lowest = roles[0];
        for (roles[1..]) |role| {
            if (getRolePosition(role) < getRolePosition(lowest)) {
                lowest = role;
            }
        }
        return lowest;
    }

    pub fn formatRoleSummary(role: models.Role) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(getRoleName(role));
        try summary.appendSlice(" (ID: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getRoleId(role)}));
        try summary.appendSlice(")");

        if (hasRoleColor(role)) {
            try summary.appendSlice(" - Color: ");
            try summary.appendSlice(formatRoleHexColor(role));
        }

        if (isRoleHoisted(role)) {
            try summary.appendSlice(" [Hoisted]");
        }

        if (isRoleManaged(role)) {
            try summary.appendSlice(" [Managed]");
        }

        if (isRoleMentionable(role)) {
            try summary.appendSlice(" [Mentionable]");
        }

        if (isRoleAdmin(role)) {
            try summary.appendSlice(" [Admin]");
        }

        if (isRoleBooster(role)) {
            try summary.appendSlice(" [Booster]");
        }

        return summary.toOwnedSlice();
    }

    pub fn formatFullRoleInfo(role: models.Role) []const u8 {
        var info = std.ArrayList(u8).init(std.heap.page_allocator);
        defer info.deinit();

        try info.appendSlice("Role: ");
        try info.appendSlice(getRoleName(role));
        try info.appendSlice("\n");
        try info.appendSlice("ID: ");
        try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getRoleId(role)}));
        try info.appendSlice("\n");
        try info.appendSlice("Position: ");
        try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getRolePosition(role)}));
        try info.appendSlice("\n");
        try info.appendSlice("Color: ");
        try info.appendSlice(formatRoleHexColor(role));
        try info.appendSlice("\n");
        try info.appendSlice("Hoisted: ");
        try info.appendSlice(if (isRoleHoisted(role)) "Yes" else "No");
        try info.appendSlice("\n");
        try info.appendSlice("Managed: ");
        try info.appendSlice(if (isRoleManaged(role)) "Yes" else "No");
        try info.appendSlice("\n");
        try info.appendSlice("Mentionable: ");
        try info.appendSlice(if (isRoleMentionable(role)) "Yes" else "No");
        try info.appendSlice("\n");
        try info.appendSlice("Permissions: ");
        try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getRolePermissions(role)}));
        try info.appendSlice("\n");
        try info.appendSlice("Flags: ");
        try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getRoleFlags(role)}));

        if (hasRoleIcon(role)) {
            try info.appendSlice("\n");
            try info.appendSlice("Has Icon: Yes");
        }

        if (hasRoleUnicodeEmoji(role)) {
            try info.appendSlice("\n");
            try info.appendSlice("Unicode Emoji: ");
            try info.appendSlice(getRoleUnicodeEmoji(role).?);
        }

        return info.toOwnedSlice();
    }

    pub fn getPermissionNames(permissions: u64) []const []const u8 {
        var permission_names = std.ArrayList([]const u8).init(std.heap.page_allocator);
        defer permission_names.deinit();

        const permission_flags = struct {
            const CREATE_INSTANT_INVITE = 0x0000000000000001;
            const KICK_MEMBERS = 0x0000000000000002;
            const BAN_MEMBERS = 0x0000000000000004;
            const ADMINISTRATOR = 0x0000000000000008;
            const MANAGE_CHANNELS = 0x0000000000000010;
            const MANAGE_GUILD = 0x0000000000000020;
            const ADD_REACTIONS = 0x0000000000000040;
            const VIEW_AUDIT_LOG = 0x0000000000000080;
            const PRIORITY_SPEAKER = 0x0000000000000100;
            const STREAM = 0x0000000000000200;
            const VIEW_CHANNEL = 0x0000000000000400;
            const SEND_MESSAGES = 0x0000000000000800;
            const SEND_TTS_MESSAGES = 0x0000000000001000;
            const MANAGE_MESSAGES = 0x0000000000002000;
            const EMBED_LINKS = 0x0000000000004000;
            const ATTACH_FILES = 0x0000000000008000;
            const READ_MESSAGE_HISTORY = 0x0000000000010000;
            const MENTION_EVERYONE = 0x0000000000020000;
            const USE_EXTERNAL_EMOJIS = 0x0000000000040000;
            const VIEW_GUILD_INSIGHTS = 0x0000000000080000;
            const CONNECT = 0x0000000000100000;
            const SPEAK = 0x0000000000200000;
            const MUTE_MEMBERS = 0x0000000000400000;
            const DEAFEN_MEMBERS = 0x0000000000800000;
            const MOVE_MEMBERS = 0x0000000001000000;
            const USE_VAD = 0x0000000002000000;
            const CHANGE_NICKNAME = 0x0000000004000000;
            const MANAGE_NICKNAMES = 0x0000000008000000;
            const MANAGE_ROLES = 0x0000000010000000;
            const MANAGE_WEBHOOKS = 0x0000000020000000;
            const MANAGE_EMOJIS_AND_STICKERS = 0x0000000040000000;
            const USE_APPLICATION_COMMANDS = 0x0000000080000000;
            const REQUEST_TO_SPEAK = 0x0000000100000000;
            const MANAGE_EVENTS = 0x0000000200000000;
            const MANAGE_THREADS = 0x0000000400000000;
            const CREATE_PUBLIC_THREADS = 0x0000000800000000;
            const CREATE_PRIVATE_THREADS = 0x0000001000000000;
            const USE_EXTERNAL_STICKERS = 0x0000002000000000;
            const SEND_MESSAGES_IN_THREADS = 0x0000004000000000;
            const START_EMBEDDED_ACTIVITIES = 0x0000008000000000;
            const MODERATE_MEMBERS = 0x0000010000000000;
        };

        if (permissions & permission_flags.CREATE_INSTANT_INVITE != 0) permission_names.append("Create Instant Invite") catch {};
        if (permissions & permission_flags.KICK_MEMBERS != 0) permission_names.append("Kick Members") catch {};
        if (permissions & permission_flags.BAN_MEMBERS != 0) permission_names.append("Ban Members") catch {};
        if (permissions & permission_flags.ADMINISTRATOR != 0) permission_names.append("Administrator") catch {};
        if (permissions & permission_flags.MANAGE_CHANNELS != 0) permission_names.append("Manage Channels") catch {};
        if (permissions & permission_flags.MANAGE_GUILD != 0) permission_names.append("Manage Guild") catch {};
        if (permissions & permission_flags.ADD_REACTIONS != 0) permission_names.append("Add Reactions") catch {};
        if (permissions & permission_flags.VIEW_AUDIT_LOG != 0) permission_names.append("View Audit Log") catch {};
        if (permissions & permission_flags.PRIORITY_SPEAKER != 0) permission_names.append("Priority Speaker") catch {};
        if (permissions & permission_flags.STREAM != 0) permission_names.append("Stream") catch {};
        if (permissions & permission_flags.VIEW_CHANNEL != 0) permission_names.append("View Channel") catch {};
        if (permissions & permission_flags.SEND_MESSAGES != 0) permission_names.append("Send Messages") catch {};
        if (permissions & permission_flags.SEND_TTS_MESSAGES != 0) permission_names.append("Send TTS Messages") catch {};
        if (permissions & permission_flags.MANAGE_MESSAGES != 0) permission_names.append("Manage Messages") catch {};
        if (permissions & permission_flags.EMBED_LINKS != 0) permission_names.append("Embed Links") catch {};
        if (permissions & permission_flags.ATTACH_FILES != 0) permission_names.append("Attach Files") catch {};
        if (permissions & permission_flags.READ_MESSAGE_HISTORY != 0) permission_names.append("Read Message History") catch {};
        if (permissions & permission_flags.MENTION_EVERYONE != 0) permission_names.append("Mention Everyone") catch {};
        if (permissions & permission_flags.USE_EXTERNAL_EMOJIS != 0) permission_names.append("Use External Emojis") catch {};
        if (permissions & permission_flags.VIEW_GUILD_INSIGHTS != 0) permission_names.append("View Guild Insights") catch {};
        if (permissions & permission_flags.CONNECT != 0) permission_names.append("Connect") catch {};
        if (permissions & permission_flags.SPEAK != 0) permission_names.append("Speak") catch {};
        if (permissions & permission_flags.MUTE_MEMBERS != 0) permission_names.append("Mute Members") catch {};
        if (permissions & permission_flags.DEAFEN_MEMBERS != 0) permission_names.append("Deafen Members") catch {};
        if (permissions & permission_flags.MOVE_MEMBERS != 0) permission_names.append("Move Members") catch {};
        if (permissions & permission_flags.USE_VAD != 0) permission_names.append("Use VAD") catch {};
        if (permissions & permission_flags.CHANGE_NICKNAME != 0) permission_names.append("Change Nickname") catch {};
        if (permissions & permission_flags.MANAGE_NICKNAMES != 0) permission_names.append("Manage Nicknames") catch {};
        if (permissions & permission_flags.MANAGE_ROLES != 0) permission_names.append("Manage Roles") catch {};
        if (permissions & permission_flags.MANAGE_WEBHOOKS != 0) permission_names.append("Manage Webhooks") catch {};
        if (permissions & permission_flags.MANAGE_EMOJIS_AND_STICKERS != 0) permission_names.append("Manage Emojis and Stickers") catch {};
        if (permissions & permission_flags.USE_APPLICATION_COMMANDS != 0) permission_names.append("Use Application Commands") catch {};
        if (permissions & permission_flags.REQUEST_TO_SPEAK != 0) permission_names.append("Request to Speak") catch {};
        if (permissions & permission_flags.MANAGE_EVENTS != 0) permission_names.append("Manage Events") catch {};
        if (permissions & permission_flags.MANAGE_THREADS != 0) permission_names.append("Manage Threads") catch {};
        if (permissions & permission_flags.CREATE_PUBLIC_THREADS != 0) permission_names.append("Create Public Threads") catch {};
        if (permissions & permission_flags.CREATE_PRIVATE_THREADS != 0) permission_names.append("Create Private Threads") catch {};
        if (permissions & permission_flags.USE_EXTERNAL_STICKERS != 0) permission_names.append("Use External Stickers") catch {};
        if (permissions & permission_flags.SEND_MESSAGES_IN_THREADS != 0) permission_names.append("Send Messages in Threads") catch {};
        if (permissions & permission_flags.START_EMBEDDED_ACTIVITIES != 0) permission_names.append("Start Embedded Activities") catch {};
        if (permissions & permission_flags.MODERATE_MEMBERS != 0) permission_names.append("Moderate Members") catch {};

        return permission_names.toOwnedSlice() catch &[_][]const u8{};
    }
};
