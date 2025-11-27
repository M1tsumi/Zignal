const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Guild verification management for Discord server verification
pub const GuildVerificationManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildVerificationManager {
        return GuildVerificationManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild verification
    pub fn getGuildVerification(self: *GuildVerificationManager, guild_id: u64) !models.GuildVerification {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/verification",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildVerification, response.body, .{});
    }

    /// Update guild verification
    pub fn updateGuildVerification(
        self: *GuildVerificationManager,
        guild_id: u64,
        enabled: ?bool,
        verification_level: ?models.VerificationLevel,
        verification_type: ?models.VerificationType,
        required_age: ?u64,
        required_actions: ?[]models.VerificationAction,
        custom_message: ?[]const u8,
        reason: ?[]const u8,
    ) !models.GuildVerification {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/verification",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = UpdateGuildVerificationPayload{
            .enabled = enabled,
            .verification_level = verification_level,
            .verification_type = verification_type,
            .required_age = required_age,
            .required_actions = required_actions,
            .custom_message = custom_message,
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

        return try std.json.parse(models.GuildVerification, response.body, .{});
    }

    /// Get member verification status
    pub fn getMemberVerificationStatus(
        self: *GuildVerificationManager,
        guild_id: u64,
        user_id: u64,
    ) !models.MemberVerificationStatus {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}/verification",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.MemberVerificationStatus, response.body, .{});
    }

    /// Update member verification status
    pub fn updateMemberVerificationStatus(
        self: *GuildVerificationManager,
        guild_id: u64,
        user_id: u64,
        verified: bool,
        verification_data: ?models.VerificationData,
        reason: ?[]const u8,
    ) !models.MemberVerificationStatus {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}/verification",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = UpdateMemberVerificationStatusPayload{
            .verified = verified,
            .verification_data = verification_data,
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

        return try std.json.parse(models.MemberVerificationStatus, response.body, .{});
    }

    /// Get verification queue
    pub fn getVerificationQueue(
        self: *GuildVerificationManager,
        guild_id: u64,
        status: ?models.VerificationStatus,
        before: ?u64,
        after: ?u64,
        limit: ?usize,
    ) ![]models.VerificationQueueEntry {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/verification/queue",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (status) |s| {
            try params.append(try std.fmt.allocPrint(self.allocator, "status={d}", .{@intFromEnum(s)}));
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

        return try std.json.parse([]models.VerificationQueueEntry, response.body, .{});
    }

    /// Process verification request
    pub fn processVerificationRequest(
        self: *GuildVerificationManager,
        guild_id: u64,
        user_id: u64,
        action: models.VerificationAction,
        reason: ?[]const u8,
    ) !models.MemberVerificationStatus {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/verification/queue/{d}/process",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = ProcessVerificationRequestPayload{
            .action = action,
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

        return try std.json.parse(models.MemberVerificationStatus, response.body, .{});
    }

    /// Get verification statistics
    pub fn getVerificationStatistics(
        self: *GuildVerificationManager,
        guild_id: u64,
        period: ?[]const u8,
    ) !models.VerificationStatistics {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/verification/statistics",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        if (period) |p| {
            try url.appendSlice("?period=");
            try url.appendSlice(p);
        }

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.VerificationStatistics, response.body, .{});
    }

    /// Export verification data
    pub fn exportVerificationData(
        self: *GuildVerificationManager,
        guild_id: u64,
        format: ?[]const u8,
        filters: ?std.json.ObjectMap,
    ) !models.VerificationExport {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/verification/export",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        if (format) |f| {
            try url.appendSlice("?format=");
            try url.appendSlice(f);
        }

        const payload = ExportVerificationDataPayload{
            .filters = filters,
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

        return try std.json.parse(models.VerificationExport, response.body, .{});
    }
};

// Payload structures
const UpdateGuildVerificationPayload = struct {
    enabled: ?bool = null,
    verification_level: ?models.VerificationLevel = null,
    verification_type: ?models.VerificationType = null,
    required_age: ?u64 = null,
    required_actions: ?[]models.VerificationAction = null,
    custom_message: ?[]const u8 = null,
};

const UpdateMemberVerificationStatusPayload = struct {
    verified: bool,
    verification_data: ?models.VerificationData = null,
};

const ProcessVerificationRequestPayload = struct {
    action: models.VerificationAction,
    reason: ?[]const u8 = null,
};

const ExportVerificationDataPayload = struct {
    filters: ?std.json.ObjectMap = null,
};
