const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild application management for Discord server applications
pub const GuildApplicationManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildApplicationManager {
        return GuildApplicationManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get current application
    pub fn getCurrentApplication(self: *GuildApplicationManager) !models.Application {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/@me",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Application, response.body, .{});
    }

    /// Get application
    pub fn getApplication(
        self: *GuildApplicationManager,
        application_id: u64,
    ) !models.Application {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Application, response.body, .{});
    }

    /// Modify current application
    pub fn modifyCurrentApplication(
        self: *GuildApplicationManager,
        name: ?[]const u8,
        description: ?[]const u8,
        icon: ?[]const u8,
        cover_image: ?[]const u8,
        flags: ?u64,
        tags: ?[]const u8,
        install_params: ?models.InstallParams,
        integration_types_config: ?std.json.ObjectMap,
        role_connections_verification_url: ?[]const u8,
    ) !models.Application {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/@me",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        const payload = ModifyApplicationPayload{
            .name = name,
            .description = description,
            .icon = icon,
            .cover_image = cover_image,
            .flags = flags,
            .tags = tags,
            .install_params = install_params,
            .integration_types_config = integration_types_config,
            .role_connections_verification_url = role_connections_verification_url,
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

        return try std.json.parse(models.Application, response.body, .{});
    }

    /// Get application role connection metadata
    pub fn getApplicationRoleConnectionMetadata(
        self: *GuildApplicationManager,
        application_id: u64,
    ) ![]models.ApplicationRoleConnectionMetadata {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/role-connections/metadata",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.ApplicationRoleConnectionMetadata, response.body, .{});
    }

    /// Update application role connection metadata
    pub fn updateApplicationRoleConnectionMetadata(
        self: *GuildApplicationManager,
        application_id: u64,
        metadata: []models.ApplicationRoleConnectionMetadata,
    ) ![]models.ApplicationRoleConnectionMetadata {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/role-connections/metadata",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const json_payload = try std.json.stringifyAlloc(self.allocator, metadata, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.put(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.ApplicationRoleConnectionMetadata, response.body, .{});
    }

    /// Get application install params
    pub fn getApplicationInstallParams(
        self: *GuildApplicationManager,
        application_id: u64,
    ) !models.InstallParams {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/install-params",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.InstallParams, response.body, .{});
    }

    /// Update application install params
    pub fn updateApplicationInstallParams(
        self: *GuildApplicationManager,
        application_id: u64,
        install_params: models.InstallParams,
    ) !models.InstallParams {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/install-params",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const json_payload = try std.json.stringifyAlloc(self.allocator, install_params, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.InstallParams, response.body, .{});
    }

    /// Get application assets
    pub fn getApplicationAssets(
        self: *GuildApplicationManager,
        application_id: u64,
    ) ![]models.ApplicationAsset {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/assets",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.ApplicationAsset, response.body, .{});
    }

    /// Create application asset
    pub fn createApplicationAsset(
        self: *GuildApplicationManager,
        application_id: u64,
        name: []const u8,
        _: models.ApplicationAssetType,
        data: []const u8,
    ) !models.ApplicationAsset {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/assets",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const payload = CreateApplicationAssetPayload{
            .name = name,
            .type = type,
            .data = data,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ApplicationAsset, response.body, .{});
    }

    /// Delete application asset
    pub fn deleteApplicationAsset(
        self: *GuildApplicationManager,
        application_id: u64,
        asset_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/assets/{d}",
            .{ self.client.base_url, application_id, asset_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get application emoji
    pub fn getApplicationEmoji(
        self: *GuildApplicationManager,
        application_id: u64,
        emoji_id: u64,
    ) !models.ApplicationEmoji {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/emojis/{d}",
            .{ self.client.base_url, application_id, emoji_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ApplicationEmoji, response.body, .{});
    }

    /// Get application emojis
    pub fn getApplicationEmojis(
        self: *GuildApplicationManager,
        application_id: u64,
    ) ![]models.ApplicationEmoji {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/emojis",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.ApplicationEmoji, response.body, .{});
    }

    /// Create application emoji
    pub fn createApplicationEmoji(
        self: *GuildApplicationManager,
        application_id: u64,
        name: []const u8,
        image: []const u8,
    ) !models.ApplicationEmoji {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/emojis",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const payload = CreateApplicationEmojiPayload{
            .name = name,
            .image = image,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ApplicationEmoji, response.body, .{});
    }

    /// Modify application emoji
    pub fn modifyApplicationEmoji(
        self: *GuildApplicationManager,
        application_id: u64,
        emoji_id: u64,
        name: []const u8,
    ) !models.ApplicationEmoji {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/emojis/{d}",
            .{ self.client.base_url, application_id, emoji_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyApplicationEmojiPayload{
            .name = name,
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

        return try std.json.parse(models.ApplicationEmoji, response.body, .{});
    }

    /// Delete application emoji
    pub fn deleteApplicationEmoji(
        self: *GuildApplicationManager,
        application_id: u64,
        emoji_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/emojis/{d}",
            .{ self.client.base_url, application_id, emoji_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }
};

// Payload structures
const ModifyApplicationPayload = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    icon: ?[]const u8 = null,
    cover_image: ?[]const u8 = null,
    flags: ?u64 = null,
    tags: ?[]const u8 = null,
    install_params: ?models.InstallParams = null,
    integration_types_config: ?std.json.ObjectMap = null,
    role_connections_verification_url: ?[]const u8 = null,
};

const CreateApplicationAssetPayload = struct {
    name: []const u8,
    type: models.ApplicationAssetType,
    data: []const u8,
};

const CreateApplicationEmojiPayload = struct {
    name: []const u8,
    image: []const u8,
};

const ModifyApplicationEmojiPayload = struct {
    name: []const u8,
};
