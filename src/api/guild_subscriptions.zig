const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Guild subscription management for Discord server subscriptions
pub const GuildSubscriptionManager = struct {
    client: *Client,
    allocator: std.mem.Allocator;

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildSubscriptionManager {
        return GuildSubscriptionManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// List subscriptions
    pub fn listSubscriptions(
        self: *GuildSubscriptionManager,
        user_id: ?u64,
        sku_ids: ?[]u64,
        before: ?u64,
        after: ?u64,
        limit: ?usize,
        guild_id: ?u64,
    ) ![]models.Subscription {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/subscriptions",
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

        return try std.json.parse([]models.Subscription, response.body, .{});
    }

    /// Get subscription
    pub fn getSubscription(
        self: *GuildSubscriptionManager,
        subscription_id: u64,
    ) !models.Subscription {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/subscriptions/{d}",
            .{ self.client.base_url, subscription_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Subscription, response.body, .{});
    }

    /// Create subscription
    pub fn createSubscription(
        self: *GuildSubscriptionManager,
        sku_id: u64,
        user_id: u64,
        payment_source_id: u64,
        currency: []const u8,
        renewal: ?bool,
    ) !models.Subscription {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/subscriptions",
            .{ self.client.base_url },
        );
        defer self.allocator.free(url);

        const payload = CreateSubscriptionPayload{
            .sku_id = sku_id,
            .user_id = user_id,
            .payment_source_id = payment_source_id,
            .currency = currency,
            .renewal = renewal orelse true,
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

        return try std.json.parse(models.Subscription, response.body, .{});
    }

    /// Cancel subscription
    pub fn cancelSubscription(
        self: *GuildSubscriptionManager,
        subscription_id: u64,
        reason: ?[]const u8,
    ) !models.Subscription {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/subscriptions/{d}/cancel",
            .{ self.client.base_url, subscription_id },
        );
        defer self.allocator.free(url);

        const payload = CancelSubscriptionPayload{
            .reason = reason,
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

        return try std.json.parse(models.Subscription, response.body, .{});
    }

    /// Update subscription
    pub fn updateSubscription(
        self: *GuildSubscriptionManager,
        subscription_id: u64,
        sku_id: ?u64,
        renewal: ?bool,
    ) !models.Subscription {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/subscriptions/{d}",
            .{ self.client.base_url, subscription_id },
        );
        defer self.allocator.free(url);

        const payload = UpdateSubscriptionPayload{
            .sku_id = sku_id,
            .renewal = renewal,
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

        return try std.json.parse(models.Subscription, response.body, .{});
    }

    /// Get subscription invoices
    pub fn getSubscriptionInvoices(
        self: *GuildSubscriptionManager,
        subscription_id: u64,
        before: ?u64,
        after: ?u64,
        limit: ?usize,
    ) ![]models.SubscriptionInvoice {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/subscriptions/{d}/invoices",
            .{ self.client.base_url, subscription_id },
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

        return try std.json.parse([]models.SubscriptionInvoice, response.body, .{});
    }
};

// Payload structures
const CreateSubscriptionPayload = struct {
    sku_id: u64,
    user_id: u64,
    payment_source_id: u64,
    currency: []const u8,
    renewal: bool,
};

const CancelSubscriptionPayload = struct {
    reason: ?[]const u8 = null,
};

const UpdateSubscriptionPayload = struct {
    sku_id: ?u64 = null,
    renewal: ?bool = null,
};
