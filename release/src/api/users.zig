const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// User management for Discord users
pub const UserManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) UserManager {
        return UserManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get current user
    pub fn getCurrentUser(self: *UserManager) !models.User {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.User, response.body, .{});
    }

    /// Get user
    pub fn getUser(self: *UserManager, user_id: u64) !models.User {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/{d}",
            .{ self.client.base_url, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.User, response.body, .{});
    }

    /// Modify current user
    pub fn modifyCurrentUser(
        self: *UserManager,
        username: ?[]const u8,
        avatar: ?[]const u8, // Base64 encoded image data
        banner: ?[]const u8, // Base64 encoded image data
    ) !models.User {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        const payload = ModifyCurrentUserPayload{
            .username = username,
            .avatar = avatar,
            .banner = banner,
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

        return try std.json.parse(models.User, response.body, .{});
    }

    /// Get current user guilds
    pub fn getCurrentUserGuilds(
        self: *UserManager,
        before: ?u64,
        after: ?u64,
        limit: ?usize,
        with_counts: ?bool,
    ) ![]models.Guild {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/guilds",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (before) |b| {
            try params.append(try std.fmt.allocPrint(self.allocator, "before={d}", .{b}));
        }
        if (after) |a| {
            try params.append(try std.fmt.allocPrint(self.allocator, "after={d}", .{a}));
        }
        if (limit) |l| {
            try params.append(try std.fmt.allocPrint(self.allocator, "limit={d}", .{l}));
        }
        if (with_counts orelse false) {
            try params.append("with_counts=true");
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

        return try std.json.parse([]models.Guild, response.body, .{});
    }

    /// Get guild member
    pub fn getGuildMember(
        self: *UserManager,
        guild_id: u64,
    ) !models.GuildMember {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/guilds/{d}/member",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildMember, response.body, .{});
    }

    /// Leave guild
    pub fn leaveGuild(
        self: *UserManager,
        guild_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/guilds/{d}",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Create DM
    pub fn createDM(
        self: *UserManager,
        recipient_id: u64,
    ) !models.Channel {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/channels",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        const payload = CreateDMPayload{
            .recipient_id = recipient_id,
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

        return try std.json.parse(models.Channel, response.body, .{});
    }

    /// Create group DM
    pub fn createGroupDM(
        self: *UserManager,
        access_tokens: []const u8,
        nicks: ?std.json.ObjectMap,
    ) !models.Channel {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/channels",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        const payload = CreateGroupDMPayload{
            .access_tokens = access_tokens,
            .nicks = nicks,
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

        return try std.json.parse(models.Channel, response.body, .{});
    }

    /// Get user connections
    pub fn getUserConnections(self: *UserManager) ![]models.Connection {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/connections",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Connection, response.body, .{});
    }

    /// Get user application role connection
    pub fn getUserApplicationRoleConnection(
        self: *UserManager,
        application_id: u64,
    ) !models.ApplicationRoleConnection {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/applications/{d}/role-connection",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ApplicationRoleConnection, response.body, .{});
    }

    /// Update user application role connection
    pub fn updateUserApplicationRoleConnection(
        self: *UserManager,
        application_id: u64,
        platform_name: ?[]const u8,
        platform_username: ?[]const u8,
        metadata: ?std.json.ObjectMap,
    ) !models.ApplicationRoleConnection {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/applications/{d}/role-connection",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const payload = UpdateUserApplicationRoleConnectionPayload{
            .platform_name = platform_name,
            .platform_username = platform_username,
            .metadata = metadata,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.put(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ApplicationRoleConnection, response.body, .{});
    }

    /// Get voice regions
    pub fn getVoiceRegions(self: *UserManager) ![]models.VoiceRegion {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/voice/regions",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.VoiceRegion, response.body, .{});
    }
};

// Payload structures
const ModifyCurrentUserPayload = struct {
    username: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
    banner: ?[]const u8 = null,
};

const CreateDMPayload = struct {
    recipient_id: u64,
};

const CreateGroupDMPayload = struct {
    access_tokens: []const u8,
    nicks: ?std.json.ObjectMap = null,
};

const UpdateUserApplicationRoleConnectionPayload = struct {
    platform_name: ?[]const u8 = null,
    platform_username: ?[]const u8 = null,
    metadata: ?std.json.ObjectMap = null,
};
