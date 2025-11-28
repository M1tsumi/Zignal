const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild security management for Discord server security features
pub const GuildSecurityManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildSecurityManager {
        return GuildSecurityManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild security settings
    pub fn getGuildSecuritySettings(self: *GuildSecurityManager, guild_id: u64) !models.GuildSecuritySettings {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/security",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildSecuritySettings, response.body, .{});
    }

    /// Modify guild security settings
    pub fn modifyGuildSecuritySettings(
        self: *GuildSecurityManager,
        guild_id: u64,
        verification_level: ?models.VerificationLevel,
        default_message_notifications: ?models.DefaultMessageNotificationLevel,
        explicit_content_filter: ?models.ExplicitContentFilterLevel,
        mfa_level: ?models.MFALevel,
        reason: ?[]const u8,
    ) !models.GuildSecuritySettings {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/security",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyGuildSecuritySettingsPayload{
            .verification_level = verification_level,
            .default_message_notifications = default_message_notifications,
            .explicit_content_filter = explicit_content_filter,
            .mfa_level = mfa_level,
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

        return try std.json.parse(models.GuildSecuritySettings, response.body, .{});
    }

    /// Get guild security audit logs
    pub fn getGuildSecurityAuditLogs(
        self: *GuildSecurityManager,
        guild_id: u64,
        user_id: ?u64,
        action_type: ?u64,
        before: ?u64,
        after: ?u64,
        limit: ?usize,
    ) !models.AuditLog {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/security/audit-logs",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (user_id) |uid| {
            try params.append(try std.fmt.allocPrint(self.allocator, "user_id={d}", .{uid}));
        }
        if (action_type) |at| {
            try params.append(try std.fmt.allocPrint(self.allocator, "action_type={d}", .{at}));
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

        return try std.json.parse(models.AuditLog, response.body, .{});
    }

    /// Get guild security alerts
    pub fn getGuildSecurityAlerts(
        self: *GuildSecurityManager,
        guild_id: u64,
        alert_type: ?models.SecurityAlertType,
        resolved: ?bool,
        before: ?u64,
        after: ?u64,
        limit: ?usize,
    ) ![]models.SecurityAlert {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/security/alerts",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (alert_type) |at| {
            try params.append(try std.fmt.allocPrint(self.allocator, "alert_type={d}", .{@intFromEnum(at)}));
        }
        if (resolved) |r| {
            try params.append(try std.fmt.allocPrint(self.allocator, "resolved={}", .{r}));
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

        return try std.json.parse([]models.SecurityAlert, response.body, .{});
    }

    /// Resolve security alert
    pub fn resolveSecurityAlert(
        self: *GuildSecurityManager,
        guild_id: u64,
        alert_id: u64,
        resolution_note: ?[]const u8,
        reason: ?[]const u8,
    ) !models.SecurityAlert {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/security/alerts/{d}/resolve",
            .{ self.client.base_url, guild_id, alert_id },
        );
        defer self.allocator.free(url);

        const payload = ResolveSecurityAlertPayload{
            .resolution_note = resolution_note,
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

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.SecurityAlert, response.body, .{});
    }

    /// Get guild security statistics
    pub fn getGuildSecurityStatistics(
        self: *GuildSecurityManager,
        guild_id: u64,
        period: ?[]const u8,
    ) !models.GuildSecurityStatistics {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/security/statistics",
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

        return try std.json.parse(models.GuildSecurityStatistics, response.body, .{});
    }

    /// Enable two-factor authentication requirement
    pub fn enableTwoFactorAuthRequirement(
        self: *GuildSecurityManager,
        guild_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/security/2fa/enable",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.post(url, "");
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Disable two-factor authentication requirement
    pub fn disableTwoFactorAuthRequirement(
        self: *GuildSecurityManager,
        guild_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/security/2fa/disable",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.post(url, "");
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get guild security rules
    pub fn getGuildSecurityRules(self: *GuildSecurityManager, guild_id: u64) ![]models.GuildSecurityRule {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/security/rules",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.GuildSecurityRule, response.body, .{});
    }

    /// Create guild security rule
    pub fn createGuildSecurityRule(
        self: *GuildSecurityManager,
        guild_id: u64,
        name: []const u8,
        rule_type: models.SecurityRuleType,
        conditions: []models.SecurityRuleCondition,
        actions: []models.SecurityRuleAction,
        enabled: ?bool,
        reason: ?[]const u8,
    ) !models.GuildSecurityRule {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/security/rules",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreateGuildSecurityRulePayload{
            .name = name,
            .rule_type = rule_type,
            .conditions = conditions,
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

        return try std.json.parse(models.GuildSecurityRule, response.body, .{});
    }

    /// Modify guild security rule
    pub fn modifyGuildSecurityRule(
        self: *GuildSecurityManager,
        guild_id: u64,
        rule_id: u64,
        name: ?[]const u8,
        conditions: ?[]models.SecurityRuleCondition,
        actions: ?[]models.SecurityRuleAction,
        enabled: ?bool,
        reason: ?[]const u8,
    ) !models.GuildSecurityRule {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/security/rules/{d}",
            .{ self.client.base_url, guild_id, rule_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyGuildSecurityRulePayload{
            .name = name,
            .conditions = conditions,
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

        return try std.json.parse(models.GuildSecurityRule, response.body, .{});
    }

    /// Delete guild security rule
    pub fn deleteGuildSecurityRule(
        self: *GuildSecurityManager,
        guild_id: u64,
        rule_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/security/rules/{d}",
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

// Payload structures
const ModifyGuildSecuritySettingsPayload = struct {
    verification_level: ?models.VerificationLevel = null,
    default_message_notifications: ?models.DefaultMessageNotificationLevel = null,
    explicit_content_filter: ?models.ExplicitContentFilterLevel = null,
    mfa_level: ?models.MFALevel = null,
};

const ResolveSecurityAlertPayload = struct {
    resolution_note: ?[]const u8 = null,
};

const CreateGuildSecurityRulePayload = struct {
    name: []const u8,
    rule_type: models.SecurityRuleType,
    conditions: []models.SecurityRuleCondition,
    actions: []models.SecurityRuleAction,
    enabled: ?bool = null,
};

const ModifyGuildSecurityRulePayload = struct {
    name: ?[]const u8 = null,
    conditions: ?[]models.SecurityRuleCondition = null,
    actions: ?[]models.SecurityRuleAction = null,
    enabled: ?bool = null,
};
