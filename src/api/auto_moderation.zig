const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Auto moderation management for guild content filtering
pub const AutoModerationManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) AutoModerationManager {
        return AutoModerationManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get auto moderation rules for a guild
    pub fn getAutoModerationRules(self: *AutoModerationManager, guild_id: u64) ![]models.AutoModerationRule {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/auto-moderation/rules",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.AutoModerationRule, response.body, .{});
    }

    /// Get a specific auto moderation rule
    pub fn getAutoModerationRule(
        self: *AutoModerationManager,
        guild_id: u64,
        rule_id: u64,
    ) !models.AutoModerationRule {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/auto-moderation/rules/{d}",
            .{ self.client.base_url, guild_id, rule_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.AutoModerationRule, response.body, .{});
    }

    /// Create an auto moderation rule
    pub fn createAutoModerationRule(
        self: *AutoModerationManager,
        guild_id: u64,
        name: []const u8,
        event_type: AutoModerationEventType,
        trigger_type: AutoModerationTriggerType,
        trigger_metadata: AutoModerationTriggerMetadata,
        actions: []AutoModerationAction,
        enabled: bool,
        reason: ?[]const u8,
    ) !models.AutoModerationRule {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/auto-moderation/rules",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreateAutoModerationRulePayload{
            .name = name,
            .event_type = event_type,
            .trigger_type = trigger_type,
            .trigger_metadata = trigger_metadata,
            .actions = actions,
            .enabled = enabled,
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

        return try std.json.parse(models.AutoModerationRule, response.body, .{});
    }

    /// Modify an auto moderation rule
    pub fn modifyAutoModerationRule(
        self: *AutoModerationManager,
        guild_id: u64,
        rule_id: u64,
        name: ?[]const u8,
        event_type: ?AutoModerationEventType,
        trigger_metadata: ?AutoModerationTriggerMetadata,
        actions: ?[]AutoModerationAction,
        enabled: ?bool,
        reason: ?[]const u8,
    ) !models.AutoModerationRule {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/auto-moderation/rules/{d}",
            .{ self.client.base_url, guild_id, rule_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyAutoModerationRulePayload{
            .name = name,
            .event_type = event_type,
            .trigger_metadata = trigger_metadata,
            .actions = actions,
            .enabled = enabled,
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

        return try std.json.parse(models.AutoModerationRule, response.body, .{});
    }

    /// Delete an auto moderation rule
    pub fn deleteAutoModerationRule(
        self: *AutoModerationManager,
        guild_id: u64,
        rule_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/auto-moderation/rules/{d}",
            .{ self.client.base_url, guild_id, rule_id },
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

/// Auto moderation event types
pub const AutoModerationEventType = enum(u8) {
    message_send = 1,
};

/// Auto moderation trigger types
pub const AutoModerationTriggerType = enum(u8) {
    keyword = 1,
    spam_link = 2,
    keyword_preset = 3,
    mention_spam = 4,
};

/// Auto moderation trigger metadata
pub const AutoModerationTriggerMetadata = struct {
    keyword_filter: ?[][]const u8 = null,
    regex_patterns: ?[][]const u8 = null,
    presets: ?[]AutoModerationKeywordPresetType = null,
    allow_list: ?[][]const u8 = null,
    mention_total_limit: ?u32 = null,
};

/// Auto moderation keyword preset types
pub const AutoModerationKeywordPresetType = enum(u8) {
    profanity = 1,
    sexual_content = 2,
    slurs = 3,
};

/// Auto moderation action types
pub const AutoModerationActionType = enum(u8) {
    block_message = 1,
    send_alert_message = 2,
    timeout = 3,
    block_member_interaction = 4,
};

/// Auto moderation action
pub const AutoModerationAction = struct {
    type: AutoModerationActionType,
    metadata: ?AutoModerationActionMetadata = null,
};

/// Auto moderation action metadata
pub const AutoModerationActionMetadata = struct {
    channel_id: ?u64 = null,
    duration_seconds: ?u32 = null,
    custom_message: ?[]const u8 = null,
};

/// Payload for creating an auto moderation rule
pub const CreateAutoModerationRulePayload = struct {
    name: []const u8,
    event_type: AutoModerationEventType,
    trigger_type: AutoModerationTriggerType,
    trigger_metadata: AutoModerationTriggerMetadata,
    actions: []AutoModerationAction,
    enabled: bool,
};

/// Payload for modifying an auto moderation rule
pub const ModifyAutoModerationRulePayload = struct {
    name: ?[]const u8,
    event_type: ?AutoModerationEventType,
    trigger_metadata: ?AutoModerationTriggerMetadata,
    actions: ?[]AutoModerationAction,
    enabled: ?bool,
};
