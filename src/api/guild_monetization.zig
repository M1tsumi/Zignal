const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild monetization management for Discord server monetization
pub const GuildMonetizationManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildMonetizationManager {
        return GuildMonetizationManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// List SKUs
    pub fn listSKUs(
        self: *GuildMonetizationManager,
        application_id: u64,
    ) ![]models.SKU {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/skus",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.SKU, response.body, .{});
    }

    /// Create SKU
    pub fn createSKU(
        self: *GuildMonetizationManager,
        application_id: u64,
        name: []const u8,
        sku_type: models.SKUType,
        application_sku_type: models.ApplicationSKUType,
        flags: ?u64,
        description: ?[]const u8,
        show_age_gate: ?bool,
        age_gate_required: ?bool,
    ) !models.SKU {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/skus",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        const payload = CreateSKUPayload{
            .name = name,
            .sku_type = sku_type,
            .application_sku_type = application_sku_type,
            .flags = flags,
            .description = description,
            .show_age_gate = show_age_gate,
            .age_gate_required = age_gate_required,
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

        return try std.json.parse(models.SKU, response.body, .{});
    }

    /// Get SKU
    pub fn getSKU(
        self: *GuildMonetizationManager,
        sku_id: u64,
    ) !models.SKU {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/skus/{d}",
            .{ self.client.base_url, sku_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.SKU, response.body, .{});
    }

    /// Update SKU
    pub fn updateSKU(
        self: *GuildMonetizationManager,
        sku_id: u64,
        name: ?[]const u8,
        description: ?[]const u8,
        show_age_gate: ?bool,
        age_gate_required: ?bool,
    ) !models.SKU {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/skus/{d}",
            .{ self.client.base_url, sku_id },
        );
        defer self.allocator.free(url);

        const payload = UpdateSKUPayload{
            .name = name,
            .description = description,
            .show_age_gate = show_age_gate,
            .age_gate_required = age_gate_required,
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

        return try std.json.parse(models.SKU, response.body, .{});
    }

    /// Delete SKU
    pub fn deleteSKU(
        self: *GuildMonetizationManager,
        sku_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/skus/{d}",
            .{ self.client.base_url, sku_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// List payments
    pub fn listPayments(
        self: *GuildMonetizationManager,
        application_id: u64,
        user_id: ?u64,
        sku_id: ?u64,
        before: ?u64,
        after: ?u64,
        limit: ?usize,
    ) ![]models.Payment {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/payments",
            .{ self.client.base_url, application_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (user_id) |uid| {
            try params.append(try std.fmt.allocPrint(self.allocator, "user_id={d}", .{uid}));
        }
        if (sku_id) |sid| {
            try params.append(try std.fmt.allocPrint(self.allocator, "sku_id={d}", .{sid}));
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

        return try std.json.parse([]models.Payment, response.body, .{});
    }

    /// Get payment
    pub fn getPayment(
        self: *GuildMonetizationManager,
        payment_id: u64,
    ) !models.Payment {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/payments/{d}",
            .{ self.client.base_url, payment_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Payment, response.body, .{});
    }

    /// Refund payment
    pub fn refundPayment(
        self: *GuildMonetizationManager,
        payment_id: u64,
        reason: ?[]const u8,
    ) !models.Payment {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/payments/{d}/refund",
            .{ self.client.base_url, payment_id },
        );
        defer self.allocator.free(url);

        const payload = RefundPaymentPayload{
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

        return try std.json.parse(models.Payment, response.body, .{});
    }
};

// Payload structures
const CreateSKUPayload = struct {
    name: []const u8,
    sku_type: models.SKUType,
    application_sku_type: models.ApplicationSKUType,
    flags: ?u64 = null,
    description: ?[]const u8 = null,
    show_age_gate: ?bool = null,
    age_gate_required: ?bool = null,
};

const UpdateSKUPayload = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    show_age_gate: ?bool = null,
    age_gate_required: ?bool = null,
};

const RefundPaymentPayload = struct {
    reason: ?[]const u8 = null,
};
