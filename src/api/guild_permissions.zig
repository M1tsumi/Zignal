const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Guild permission management for Discord server permissions
pub const GuildPermissionManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildPermissionManager {
        return GuildPermissionManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild permission overview
    pub fn getGuildPermissionOverview(self: *GuildPermissionManager, guild_id: u64) !models.GuildPermissionOverview {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/overview",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildPermissionOverview, response.body, .{});
    }

    /// Get role permissions
    pub fn getRolePermissions(
        self: *GuildPermissionManager,
        guild_id: u64,
        role_id: u64,
    ) !models.RolePermissions {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/roles/{d}",
            .{ self.client.base_url, guild_id, role_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.RolePermissions, response.body, .{});
    }

    /// Update role permissions
    pub fn updateRolePermissions(
        self: *GuildPermissionManager,
        guild_id: u64,
        role_id: u64,
        permissions: u64,
        reason: ?[]const u8,
    ) !models.RolePermissions {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/roles/{d}",
            .{ self.client.base_url, guild_id, role_id },
        );
        defer self.allocator.free(url);

        const payload = UpdateRolePermissionsPayload{
            .permissions = permissions,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.RolePermissions, response.body, .{});
    }

    /// Get channel permissions
    pub fn getChannelPermissions(
        self: *GuildPermissionManager,
        guild_id: u64,
        channel_id: u64,
    ) ![]models.ChannelPermission {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/channels/{d}",
            .{ self.client.base_url, guild_id, channel_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.ChannelPermission, response.body, .{});
    }

    /// Update channel permission overwrite
    pub fn updateChannelPermissionOverwrite(
        self: *GuildPermissionManager,
        guild_id: u64,
        channel_id: u64,
        overwrite_id: u64,
        allow: u64,
        deny: u64,
        type: models.OverwriteType,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/channels/{d}/{d}",
            .{ self.client.base_url, guild_id, channel_id, overwrite_id },
        );
        defer self.allocator.free(url);

        const payload = UpdateChannelPermissionOverwritePayload{
            .allow = allow,
            .deny = deny,
            .type = type,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.put(url, json_payload);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Delete channel permission overwrite
    pub fn deleteChannelPermissionOverwrite(
        self: *GuildPermissionManager,
        guild_id: u64,
        channel_id: u64,
        overwrite_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/channels/{d}/{d}",
            .{ self.client.base_url, guild_id, channel_id, overwrite_id },
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

    /// Get member permissions
    pub fn getMemberPermissions(
        self: *GuildPermissionManager,
        guild_id: u64,
        user_id: u64,
    ) !models.MemberPermissions {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.MemberPermissions, response.body, .{});
    }

    /// Check permission
    pub fn checkPermission(
        self: *GuildPermissionManager,
        guild_id: u64,
        user_id: u64,
        permission: models.Permission,
        channel_id: ?u64,
    ) !models.PermissionCheckResult {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/check",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        try params.append(try std.fmt.allocPrint(self.allocator, "user_id={d}", .{user_id}));
        try params.append(try std.fmt.allocPrint(self.allocator, "permission={d}", .{@intFromEnum(permission)}));

        if (channel_id) |cid| {
            try params.append(try std.fmt.allocPrint(self.allocator, "channel_id={d}", .{cid}));
        }

        if (params.items.len > 0) {
            try url.appendSlice("?");
            for (params.items, 0..) |param, i| {
                if (i > 0) try url.appendSlice("&");
                try url.appendSlice(param);
            }
        }

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.PermissionCheckResult, response.body, .{});
    }

    /// Create permission template
    pub fn createPermissionTemplate(
        self: *GuildPermissionManager,
        guild_id: u64,
        name: []const u8,
        description: ?[]const u8,
        role_permissions: ?[]models.RolePermissionTemplate,
        channel_overwrites: ?[]models.ChannelPermissionTemplate,
        reason: ?[]const u8,
    ) !models.PermissionTemplate {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/templates",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreatePermissionTemplatePayload{
            .name = name,
            .description = description,
            .role_permissions = role_permissions,
            .channel_overwrites = channel_overwrites,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.PermissionTemplate, response.body, .{});
    }

    /// Get permission templates
    pub fn getPermissionTemplates(
        self: *GuildPermissionManager,
        guild_id: u64,
    ) ![]models.PermissionTemplate {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/templates",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.PermissionTemplate, response.body, .{});
    }

    /// Apply permission template
    pub fn applyPermissionTemplate(
        self: *GuildPermissionManager,
        guild_id: u64,
        template_id: u64,
        target_type: models.TemplateTargetType,
        target_id: u64,
        reason: ?[]const u8,
    ) !models.PermissionTemplateApplication {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/templates/{d}/apply",
            .{ self.client.base_url, guild_id, template_id },
        );
        defer self.allocator.free(url);

        const payload = ApplyPermissionTemplatePayload{
            .target_type = target_type,
            .target_id = target_id,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.PermissionTemplateApplication, response.body, .{});
    }

    /// Get permission audit log
    pub fn getPermissionAuditLog(
        self: *GuildPermissionManager,
        guild_id: u64,
        action_type: ?models.PermissionActionType,
        user_id: ?u64,
        before: ?u64,
        after: ?u64,
        limit: ?usize,
    ) ![]models.PermissionAuditLogEntry {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/audit-log",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (action_type) |at| {
            try params.append(try std.fmt.allocPrint(self.allocator, "action_type={d}", .{@intFromEnum(at)}));
        }
        if (user_id) |uid| {
            try params.append(try std.fmt.allocPrint(self.allocator, "user_id={d}", .{uid}));
        }
        if (before) |b| {
            try params.append(try std.fmt.allocPrint(self.allocator, "before={d}", .{b}));
        }
        if (after) |a| {
            try params.append(try std.fmt.allocPrint(self.allocator, "after={d}", .{a}));
        }
        if (limit) |l| {
            try params.append(try std.fmt.allocPrint(self.allocator, "limit={d}", .{l}));
        }

        if (params.items.len > 0) {
            try url.appendSlice("?");
            for (params.items, 0..) |param, i| {
                if (i > 0) try url.appendSlice("&");
                try url.appendSlice(param);
            }
        }

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.PermissionAuditLogEntry, response.body, .{});
    }

    /// Sync permissions
    pub fn syncPermissions(
        self: *GuildPermissionManager,
        guild_id: u64,
        sync_type: models.PermissionSyncType,
        source_id: u64,
        target_ids: []u64,
        reason: ?[]const u8,
    ) !models.PermissionSyncResult {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/permissions/sync",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = SyncPermissionsPayload{
            .sync_type = sync_type,
            .source_id = source_id,
            .target_ids = target_ids,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.PermissionSyncResult, response.body, .{});
    }
};

// Payload structures
const UpdateRolePermissionsPayload = struct {
    permissions: u64,
};

const UpdateChannelPermissionOverwritePayload = struct {
    allow: u64,
    deny: u64,
    type: models.OverwriteType,
};

const CreatePermissionTemplatePayload = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    role_permissions: ?[]models.RolePermissionTemplate = null,
    channel_overwrites: ?[]models.ChannelPermissionTemplate = null,
};

const ApplyPermissionTemplatePayload = struct {
    target_type: models.TemplateTargetType,
    target_id: u64,
};

const SyncPermissionsPayload = struct {
    sync_type: models.PermissionSyncType,
    source_id: u64,
    target_ids: []u64,
};
