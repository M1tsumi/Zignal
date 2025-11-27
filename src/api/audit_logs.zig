const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Audit log management for guild moderation tracking
pub const AuditLogManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) AuditLogManager {
        return AuditLogManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get audit log entries for a guild
    pub fn getAuditLog(
        self: *AuditLogManager,
        guild_id: u64,
        options: GetAuditLogOptions,
    ) !AuditLog {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/audit-logs",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var query_builder = std.ArrayList(u8).init(self.allocator);
        defer query_builder.deinit();

        if (options.user_id) |user_id| {
            try query_builder.appendSlice("user_id=");
            try query_builder.appendSlice(try std.fmt.allocPrint(self.allocator, "{d}", .{user_id}));
            try query_builder.append('&');
        }

        if (options.action_type) |action_type| {
            try query_builder.appendSlice("action_type=");
            try query_builder.appendSlice(try std.fmt.allocPrint(self.allocator, "{d}", .{@intFromEnum(action_type)}));
            try query_builder.append('&');
        }

        if (options.before) |before| {
            try query_builder.appendSlice("before=");
            try query_builder.appendSlice(before);
            try query_builder.append('&');
        }

        if (options.after) |after| {
            try query_builder.appendSlice("after=");
            try query_builder.appendSlice(after);
            try query_builder.append('&');
        }

        if (options.limit) |limit| {
            try query_builder.appendSlice("limit=");
            try query_builder.appendSlice(try std.fmt.allocPrint(self.allocator, "{d}", .{limit}));
        }

        const final_url = if (query_builder.items.len > 0)
            try std.fmt.allocPrint(self.allocator, "{s}?{s}", .{ url, query_builder.items })
        else
            url;
        defer if (final_url.len > url.len) self.allocator.free(final_url);

        const response = try self.client.http.get(final_url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(AuditLog, response.body, .{});
    }

    /// Get audit log entry by ID
    pub fn getAuditLogEntry(
        self: *AuditLogManager,
        guild_id: u64,
        entry_id: u64,
    ) !AuditLogEntry {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/audit-logs/{d}",
            .{ self.client.base_url, guild_id, entry_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(AuditLogEntry, response.body, .{});
    }
};

/// Options for getting audit logs
pub const GetAuditLogOptions = struct {
    user_id: ?u64 = null,
    action_type: ?AuditLogActionType = null,
    before: ?[]const u8 = null,
    after: ?[]const u8 = null,
    limit: ?u32 = null,
};

/// Audit log action types
pub const AuditLogActionType = enum(u8) {
    guild_update = 1,
    channel_create = 10,
    channel_update = 11,
    channel_delete = 12,
    channel_overwrite_create = 13,
    channel_overwrite_update = 14,
    channel_overwrite_delete = 15,
    member_kick = 20,
    member_prune = 21,
    member_ban_add = 22,
    member_ban_remove = 23,
    member_update = 24,
    member_role_update = 25,
    member_move = 26,
    member_disconnect = 27,
    bot_add = 28,
    role_create = 30,
    role_update = 31,
    role_delete = 32,
    invite_create = 40,
    invite_update = 41,
    invite_delete = 42,
    webhook_create = 50,
    webhook_update = 51,
    webhook_delete = 52,
    emoji_create = 60,
    emoji_update = 61,
    emoji_delete = 62,
    message_delete = 72,
    message_bulk_delete = 73,
    message_pin = 74,
    message_unpin = 75,
    integration_create = 80,
    integration_update = 81,
    integration_delete = 82,
    stage_instance_create = 83,
    stage_instance_update = 84,
    stage_instance_delete = 85,
    sticker_create = 90,
    sticker_update = 91,
    sticker_delete = 92,
    guild_scheduled_event_create = 100,
    guild_scheduled_event_update = 101,
    guild_scheduled_event_delete = 102,
    thread_create = 110,
    thread_update = 111,
    thread_delete = 112,
    application_command_permission_update = 120,
    auto_moderation_rule_create = 140,
    auto_moderation_rule_update = 141,
    auto_moderation_rule_delete = 142,
    auto_moderation_block_message = 143,
};

/// Audit log entry
pub const AuditLogEntry = struct {
    target_id: ?u64,
    changes: ?[]AuditLogChange,
    user_id: u64,
    action_type: AuditLogActionType,
    options: ?AuditLogEntryOptions,
    reason: ?[]const u8,
};

/// Audit log change
pub const AuditLogChange = struct {
    key: []const u8,
    new_value: ?std.json.Value,
    old_value: ?std.json.Value,
};

/// Audit log entry options
pub const AuditLogEntryOptions = struct {
    delete_member_days: ?u32,
    members_removed: ?u32,
    channel_id: ?u64,
    message_id: ?u64,
    count: ?u32,
    id: ?u64,
    type: ?[]const u8,
    role_name: ?[]const u8,
};

/// Complete audit log
pub const AuditLog = struct {
    application_commands: ?[]models.ApplicationCommand,
    audit_log_entries: []AuditLogEntry,
    auto_moderation_rules: ?[]models.AutoModerationRule,
    guild_scheduled_events: ?[]models.GuildScheduledEvent,
    integrations: ?[]models.Integration,
    threads: ?[]models.Channel,
    users: ?[]models.User,
    webhooks: ?[]models.Webhook,
};
