const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild entitlement management for Discord server entitlements
pub const GuildEntitlementManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildEntitlementManager {
        return GuildEntitlementManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// List entitlements
    pub fn listEntitlements(
        self: *GuildEntitlementManager,
        user_id: ?u64,
        sku_ids: ?[]u64,
        before: ?u64,
        after: ?u64,
        limit: ?usize,
        guild_id: ?u64,
    ) ![]models.Entitlement {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/entitlements",
            .{ self.client.base_url },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (user_id) |uid| {
            try params.append(try std.fmt.allocPrint(self.allocator, "user_id={d}", .{uid}));
        }
        if (sku_ids) |skus| {
            for (skus, 0..) |sku_id, i| {
                try params.append(try std.fmt.allocPrint(self.allocator, "sku_ids[{d}]={d}", .{ i, sku_id }));
            }
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
        if (guild_id) |gid| {
            try params.append(try std.fmt.allocPrint(self.allocator, "guild_id={d}", .{gid}));
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

        return try std.json.parse([]models.Entitlement, response.body, .{});
    }

    /// Get entitlement
    pub fn getEntitlement(
        self: *GuildEntitlementManager,
        entitlement_id: u64,
    ) !models.Entitlement {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/entitlements/{d}",
            .{ self.client.base_url, entitlement_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Entitlement, response.body, .{});
    }

    /// Create test entitlement
    pub fn createTestEntitlement(
        self: *GuildEntitlementManager,
        sku_id: u64,
        owner_id: u64,
        owner_type: models.EntitlementOwnerType,
    ) !models.Entitlement {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/entitlements",
            .{ self.client.base_url },
        );
        defer self.allocator.free(url);

        const payload = CreateTestEntitlementPayload{
            .sku_id = sku_id,
            .owner_id = owner_id,
            .owner_type = owner_type,
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

        return try std.json.parse(models.Entitlement, response.body, .{});
    }

    /// Delete test entitlement
    pub fn deleteTestEntitlement(
        self: *GuildEntitlementManager,
        entitlement_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/entitlements/{d}",
            .{ self.client.base_url, entitlement_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Consume entitlement
    pub fn consumeEntitlement(
        self: *GuildEntitlementManager,
        entitlement_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/entitlements/{d}/consume",
            .{ self.client.base_url, entitlement_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.post(url, "");
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }
};

// Payload structures
const CreateTestEntitlementPayload = struct {
    sku_id: u64,
    owner_id: u64,
    owner_type: models.EntitlementOwnerType,
};
