const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Integration management for third-party services
pub const IntegrationManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) IntegrationManager {
        return IntegrationManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get all integrations for a guild
    pub fn getGuildIntegrations(self: *IntegrationManager, guild_id: u64) ![]models.Integration {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/integrations",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Integration, response.body, .{});
    }

    /// Create a guild integration
    pub fn createGuildIntegration(
        self: *IntegrationManager,
        guild_id: u64,
        integration_type: []const u8,
        integration_id: u64,
    ) !models.Integration {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/integrations",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreateIntegrationPayload{
            .type = integration_type,
            .id = integration_id,
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

        return try std.json.parse(models.Integration, response.body, .{});
    }

    /// Modify a guild integration
    pub fn modifyGuildIntegration(
        self: *IntegrationManager,
        guild_id: u64,
        integration_id: u64,
        expire_behavior: ?IntegrationExpireBehavior,
        expire_grace_period: ?u32,
        enable_emoticons: ?bool,
    ) !models.Integration {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/integrations/{d}",
            .{ self.client.base_url, guild_id, integration_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyIntegrationPayload{
            .expire_behavior = expire_behavior,
            .expire_grace_period = expire_grace_period,
            .enable_emoticons = enable_emoticons,
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

        return try std.json.parse(models.Integration, response.body, .{});
    }

    /// Delete a guild integration
    pub fn deleteGuildIntegration(
        self: *IntegrationManager,
        guild_id: u64,
        integration_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/integrations/{d}",
            .{ self.client.base_url, guild_id, integration_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Sync a guild integration
    pub fn syncGuildIntegration(
        self: *IntegrationManager,
        guild_id: u64,
        integration_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/integrations/{d}/sync",
            .{ self.client.base_url, guild_id, integration_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.post(url, "");
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get integration account information
    pub fn getIntegrationAccount(
        self: *IntegrationManager,
        integration_id: u64,
    ) !models.IntegrationAccount {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/integrations/{d}",
            .{ self.client.base_url, integration_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.IntegrationAccount, response.body, .{});
    }
};

/// Integration expire behaviors
pub const IntegrationExpireBehavior = enum(u8) {
    remove_role = 0,
    kick = 1,
};

/// Payload for creating an integration
pub const CreateIntegrationPayload = struct {
    type: []const u8,
    id: u64,
};

/// Payload for modifying an integration
pub const ModifyIntegrationPayload = struct {
    expire_behavior: ?IntegrationExpireBehavior = null,
    expire_grace_period: ?u32 = null,
    enable_emoticons: ?bool = null,
};
