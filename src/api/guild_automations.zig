const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Guild automation management for Discord server automation
pub const GuildAutomationManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildAutomationManager {
        return GuildAutomationManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild automations
    pub fn getGuildAutomations(self: *GuildAutomationManager, guild_id: u64) ![]models.GuildAutomation {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/automations",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.GuildAutomation, response.body, .{});
    }

    /// Create guild automation
    pub fn createGuildAutomation(
        self: *GuildAutomationManager,
        guild_id: u64,
        name: []const u8,
        trigger_type: models.AutomationTriggerType,
        trigger_metadata: ?models.AutomationTriggerMetadata,
        actions: []models.AutomationAction,
        enabled: ?bool,
        reason: ?[]const u8,
    ) !models.GuildAutomation {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/automations",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreateGuildAutomationPayload{
            .name = name,
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

        return try std.json.parse(models.GuildAutomation, response.body, .{});
    }

    /// Get guild automation
    pub fn getGuildAutomation(
        self: *GuildAutomationManager,
        guild_id: u64,
        automation_id: u64,
    ) !models.GuildAutomation {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/automations/{d}",
            .{ self.client.base_url, guild_id, automation_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildAutomation, response.body, .{});
    }

    /// Modify guild automation
    pub fn modifyGuildAutomation(
        self: *GuildAutomationManager,
        guild_id: u64,
        automation_id: u64,
        name: ?[]const u8,
        trigger_type: ?models.AutomationTriggerType,
        trigger_metadata: ?models.AutomationTriggerMetadata,
        actions: ?[]models.AutomationAction,
        enabled: ?bool,
        reason: ?[]const u8,
    ) !models.GuildAutomation {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/automations/{d}",
            .{ self.client.base_url, guild_id, automation_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyGuildAutomationPayload{
            .name = name,
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

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildAutomation, response.body, .{});
    }

    /// Delete guild automation
    pub fn deleteGuildAutomation(
        self: *GuildAutomationManager,
        guild_id: u64,
        automation_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/automations/{d}",
            .{ self.client.base_url, guild_id, automation_id },
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

    /// Get automation execution logs
    pub fn getAutomationExecutionLogs(
        self: *GuildAutomationManager,
        guild_id: u64,
        automation_id: u64,
        before: ?u64,
        after: ?u64,
        limit: ?usize,
    ) ![]models.AutomationExecutionLog {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/automations/{d}/logs",
            .{ self.client.base_url, guild_id, automation_id },
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

        return try std.json.parse([]models.AutomationExecutionLog, response.body, .{});
    }

    /// Execute automation manually
    pub fn executeAutomationManually(
        self: *GuildAutomationManager,
        guild_id: u64,
        automation_id: u64,
        context: ?std.json.ObjectMap,
        reason: ?[]const u8,
    ) !models.AutomationExecutionResult {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/automations/{d}/execute",
            .{ self.client.base_url, guild_id, automation_id },
        );
        defer self.allocator.free(url);

        const payload = ExecuteAutomationPayload{
            .context = context,
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

        return try std.json.parse(models.AutomationExecutionResult, response.body, .{});
    }

    /// Get automation statistics
    pub fn getAutomationStatistics(
        self: *GuildAutomationManager,
        guild_id: u64,
        automation_id: u64,
        period: ?[]const u8,
    ) !models.AutomationStatistics {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/automations/{d}/statistics",
            .{ self.client.base_url, guild_id, automation_id },
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

        return try std.json.parse(models.AutomationStatistics, response.body, .{});
    }

    /// Enable automation
    pub fn enableAutomation(
        self: *GuildAutomationManager,
        guild_id: u64,
        automation_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/automations/{d}/enable",
            .{ self.client.base_url, guild_id, automation_id },
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

    /// Disable automation
    pub fn disableAutomation(
        self: *GuildAutomationManager,
        guild_id: u64,
        automation_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/automations/{d}/disable",
            .{ self.client.base_url, guild_id, automation_id },
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
};

// Payload structures
const CreateGuildAutomationPayload = struct {
    name: []const u8,
    trigger_type: models.AutomationTriggerType,
    trigger_metadata: ?models.AutomationTriggerMetadata = null,
    actions: []models.AutomationAction,
    enabled: ?bool = null,
};

const ModifyGuildAutomationPayload = struct {
    name: ?[]const u8 = null,
    trigger_type: ?models.AutomationTriggerType = null,
    trigger_metadata: ?models.AutomationTriggerMetadata = null,
    actions: ?[]models.AutomationAction = null,
    enabled: ?bool = null,
};

const ExecuteAutomationPayload = struct {
    context: ?std.json.ObjectMap = null,
};
