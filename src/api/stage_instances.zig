const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Stage instance management for voice channel stages
pub const StageInstanceManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) StageInstanceManager {
        return StageInstanceManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Create a stage instance
    pub fn createStageInstance(
        self: *StageInstanceManager,
        channel_id: u64,
        topic: []const u8,
        privacy_level: StagePrivacyLevel,
        reason: ?[]const u8,
    ) !models.StageInstance {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/stage-instances",
            .{ self.client.base_url },
        );
        defer self.allocator.free(url);

        const payload = CreateStageInstancePayload{
            .channel_id = channel_id,
            .topic = topic,
            .privacy_level = privacy_level,
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

        return try std.json.parse(models.StageInstance, response.body, .{});
    }

    /// Get a stage instance
    pub fn getStageInstance(
        self: *StageInstanceManager,
        channel_id: u64,
    ) !models.StageInstance {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/stage-instances/{d}",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.StageInstance, response.body, .{});
    }

    /// Modify a stage instance
    pub fn modifyStageInstance(
        self: *StageInstanceManager,
        channel_id: u64,
        topic: ?[]const u8,
        privacy_level: ?StagePrivacyLevel,
        reason: ?[]const u8,
    ) !models.StageInstance {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/stage-instances/{d}",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyStageInstancePayload{
            .topic = topic,
            .privacy_level = privacy_level,
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

        return try std.json.parse(models.StageInstance, response.body, .{});
    }

    /// Delete a stage instance
    pub fn deleteStageInstance(
        self: *StageInstanceManager,
        channel_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/stage-instances/{d}",
            .{ self.client.base_url, channel_id },
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

/// Stage privacy levels
pub const StagePrivacyLevel = enum(u8) {
    public = 1,
    guild_only = 2,
};

/// Payload for creating a stage instance
pub const CreateStageInstancePayload = struct {
    channel_id: u64,
    topic: []const u8,
    privacy_level: StagePrivacyLevel,
};

/// Payload for modifying a stage instance
pub const ModifyStageInstancePayload = struct {
    topic: ?[]const u8,
    privacy_level: ?StagePrivacyLevel,
};
