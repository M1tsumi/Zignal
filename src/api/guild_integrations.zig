const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild integration management for server integrations and third-party services
pub const GuildIntegrationManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildIntegrationManager {
        return GuildIntegrationManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild integrations
    pub fn getGuildIntegrations(self: *GuildIntegrationManager, guild_id: u64) ![]models.Integration {
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

    /// Create guild integration
    pub fn createGuildIntegration(
        self: *GuildIntegrationManager,
        guild_id: u64,
        integration_id: u64,
        integration_type: []const u8,
    ) !models.Integration {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/integrations",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = struct {
            id: u64,
            type: []const u8,
        }{
            .id = integration_id,
            .type = integration_type,
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

    /// Modify guild integration
    pub fn modifyGuildIntegration(
        self: *GuildIntegrationManager,
        guild_id: u64,
        integration_id: u64,
        expire_behavior: ?u8,
        expire_grace_period: ?u32,
        enable_emoticons: ?bool,
    ) !models.Integration {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/integrations/{d}",
            .{ self.client.base_url, guild_id, integration_id },
        );
        defer self.allocator.free(url);

        const payload = struct {
            expire_behavior: ?u8,
            expire_grace_period: ?u32,
            enable_emoticons: ?bool,
        }{
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

    /// Delete guild integration
    pub fn deleteGuildIntegration(
        self: *GuildIntegrationManager,
        guild_id: u64,
        integration_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/integrations/{d}",
            .{ self.client.base_url, guild_id, integration_id },
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

    /// Sync guild integration
    pub fn syncGuildIntegration(
        self: *GuildIntegrationManager,
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
};

/// Guild integration utilities
pub const GuildIntegrationUtils = struct {
    pub fn getIntegrationId(integration: models.Integration) u64 {
        return integration.id;
    }

    pub fn getIntegrationName(integration: models.Integration) []const u8 {
        return integration.name;
    }

    pub fn getIntegrationType(integration: models.Integration) []const u8 {
        return integration.type;
    }

    pub fn getIntegrationEnabled(integration: models.Integration) bool {
        return integration.enabled;
    }

    pub fn getIntegrationSyncing(integration: models.Integration) bool {
        return integration.syncing;
    }

    pub fn getIntegrationRoleCount(integration: models.Integration) ?u32 {
        return integration.role_count;
    }

    pub fn getIntegrationUser(integration: models.Integration) ?models.User {
        return integration.user;
    }

    pub fn getIntegrationUserId(integration: models.Integration) ?u64 {
        if (integration.user) |user| {
            return user.id;
        }
        return null;
    }

    pub fn getIntegrationAccount(integration: models.Integration) models.IntegrationAccount {
        return integration.account;
    }

    pub fn getIntegrationAccountId(integration: models.Integration) []const u8 {
        return integration.account.id;
    }

    pub fn getIntegrationAccountName(integration: models.Integration) []const u8 {
        return integration.account.name;
    }

    pub fn isIntegrationEnabled(integration: models.Integration) bool {
        return integration.enabled;
    }

    pub fn isIntegrationSyncing(integration: models.Integration) bool {
        return integration.syncing;
    }

    pub fn isIntegrationBot(integration: models.Integration) bool {
        return getIntegrationUserId(integration) != null;
    }

    pub fn isIntegrationTwitch(integration: models.Integration) bool {
        return std.mem.eql(u8, getIntegrationType(integration), "twitch");
    }

    pub fn isIntegrationYouTube(integration: models.Integration) bool {
        return std.mem.eql(u8, getIntegrationType(integration), "youtube");
    }

    pub fn isIntegrationReddit(integration: models.Integration) bool {
        return std.mem.eql(u8, getIntegrationType(integration), "reddit");
    }

    pub fn isIntegrationDiscord(integration: models.Integration) bool {
        return std.mem.eql(u8, getIntegrationType(integration), "discord");
    }

    pub fn hasIntegrationUser(integration: models.Integration) bool {
        return integration.user != null;
    }

    pub fn hasIntegrationRoles(integration: models.Integration) bool {
        return integration.role_count != null;
    }

    pub fn getIntegrationExpireBehavior(integration: models.Integration) ?u8 {
        return integration.expire_behavior;
    }

    pub fn getIntegrationExpireGracePeriod(integration: models.Integration) ?u32 {
        return integration.expire_grace_period;
    }

    pub fn getIntegrationEnableEmoticons(integration: models.Integration) ?bool {
        return integration.enable_emoticons;
    }

    pub fn getIntegrationSubscriberCount(integration: models.Integration) ?u32 {
        return integration.subscriber_count;
    }

    pub fn getIntegrationRevoked(integration: models.Integration) ?bool {
        return integration.revoked;
    }

    pub fn getIntegrationApplication(integration: models.Integration) ?models.Application {
        return integration.application;
    }

    pub fn getIntegrationApplicationId(integration: models.Integration) ?u64 {
        if (integration.application) |app| {
            return app.id;
        }
        return null;
    }

    pub fn formatIntegrationSummary(integration: models.Integration) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(getIntegrationName(integration));
        try summary.appendSlice(" (");
        try summary.appendSlice(getIntegrationType(integration));
        try summary.appendSlice(")");

        if (!isIntegrationEnabled(integration)) {
            try summary.appendSlice(" [Disabled]");
        }

        if (isIntegrationSyncing(integration)) {
            try summary.appendSlice(" [Syncing]");
        }

        if (hasIntegrationRoles(integration)) {
            try summary.appendSlice(" - ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getIntegrationRoleCount(integration).?}));
            try summary.appendSlice(" roles");
        }

        return summary.toOwnedSlice();
    }

    pub fn validateIntegration(integration: models.Integration) bool {
        if (getIntegrationId(integration) == 0) return false;
        if (getIntegrationName(integration).len == 0) return false;
        if (getIntegrationType(integration).len == 0) return false;
        if (getIntegrationAccountId(integration).len == 0) return false;

        return true;
    }

    pub fn getIntegrationsByType(integrations: []models.Integration, integration_type: []const u8) []models.Integration {
        var filtered = std.ArrayList(models.Integration).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (integrations) |integration| {
            if (std.mem.eql(u8, getIntegrationType(integration), integration_type)) {
                filtered.append(integration) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Integration{};
    }

    pub fn getEnabledIntegrations(integrations: []models.Integration) []models.Integration {
        var filtered = std.ArrayList(models.Integration).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (integrations) |integration| {
            if (isIntegrationEnabled(integration)) {
                filtered.append(integration) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Integration{};
    }

    pub fn getDisabledIntegrations(integrations: []models.Integration) []models.Integration {
        var filtered = std.ArrayList(models.Integration).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (integrations) |integration| {
            if (!isIntegrationEnabled(integration)) {
                filtered.append(integration) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Integration{};
    }

    pub fn getSyncingIntegrations(integrations: []models.Integration) []models.Integration {
        var filtered = std.ArrayList(models.Integration).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (integrations) |integration| {
            if (isIntegrationSyncing(integration)) {
                filtered.append(integration) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Integration{};
    }

    pub fn getBotIntegrations(integrations: []models.Integration) []models.Integration {
        var filtered = std.ArrayList(models.Integration).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (integrations) |integration| {
            if (isIntegrationBot(integration)) {
                filtered.append(integration) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Integration{};
    }

    pub fn getIntegrationsWithRoles(integrations: []models.Integration) []models.Integration {
        var filtered = std.ArrayList(models.Integration).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (integrations) |integration| {
            if (hasIntegrationRoles(integration)) {
                filtered.append(integration) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Integration{};
    }

    pub fn searchIntegrations(integrations: []models.Integration, query: []const u8) []models.Integration {
        var results = std.ArrayList(models.Integration).init(std.heap.page_allocator);
        defer results.deinit();

        for (integrations) |integration| {
            if (std.mem.indexOf(u8, getIntegrationName(integration), query) != null or
                std.mem.indexOf(u8, getIntegrationType(integration), query) != null or
                std.mem.indexOf(u8, getIntegrationAccountName(integration), query) != null) {
                results.append(integration) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.Integration{};
    }

    pub fn sortIntegrationsByName(integrations: []models.Integration) void {
        std.sort.sort(models.Integration, integrations, {}, compareIntegrationsByName);
    }

    pub fn sortIntegrationsByType(integrations: []models.Integration) void {
        std.sort.sort(models.Integration, integrations, {}, compareIntegrationsByType);
    }

    pub fn sortIntegrationsByRoleCount(integrations: []models.Integration) void {
        std.sort.sort(models.Integration, integrations, {}, compareIntegrationsByRoleCount);
    }

    fn compareIntegrationsByName(_: void, a: models.Integration, b: models.Integration) std.math.Order {
        return std.mem.compare(u8, getIntegrationName(a), getIntegrationName(b));
    }

    fn compareIntegrationsByType(_: void, a: models.Integration, b: models.Integration) std.math.Order {
        return std.mem.compare(u8, getIntegrationType(a), getIntegrationType(b));
    }

    fn compareIntegrationsByRoleCount(_: void, a: models.Integration, b: models.Integration) std.math.Order {
        const a_count = getIntegrationRoleCount(a) orelse 0;
        const b_count = getIntegrationRoleCount(b) orelse 0;
        return std.math.order(b_count, a_count); // Descending order
    }

    pub fn getIntegrationStatistics(integrations: []models.Integration) struct {
        total_integrations: usize,
        enabled_integrations: usize,
        disabled_integrations: usize,
        syncing_integrations: usize,
        bot_integrations: usize,
        integrations_with_roles: usize,
        twitch_integrations: usize,
        youtube_integrations: usize,
        reddit_integrations: usize,
        discord_integrations: usize,
    } {
        var enabled_count: usize = 0;
        var syncing_count: usize = 0;
        var bot_count: usize = 0;
        var with_roles_count: usize = 0;
        var twitch_count: usize = 0;
        var youtube_count: usize = 0;
        var reddit_count: usize = 0;
        var discord_count: usize = 0;

        for (integrations) |integration| {
            if (isIntegrationEnabled(integration)) {
                enabled_count += 1;
            }

            if (isIntegrationSyncing(integration)) {
                syncing_count += 1;
            }

            if (isIntegrationBot(integration)) {
                bot_count += 1;
            }

            if (hasIntegrationRoles(integration)) {
                with_roles_count += 1;
            }

            if (isIntegrationTwitch(integration)) {
                twitch_count += 1;
            }

            if (isIntegrationYouTube(integration)) {
                youtube_count += 1;
            }

            if (isIntegrationReddit(integration)) {
                reddit_count += 1;
            }

            if (isIntegrationDiscord(integration)) {
                discord_count += 1;
            }
        }

        return .{
            .total_integrations = integrations.len,
            .enabled_integrations = enabled_count,
            .disabled_integrations = integrations.len - enabled_count,
            .syncing_integrations = syncing_count,
            .bot_integrations = bot_count,
            .integrations_with_roles = with_roles_count,
            .twitch_integrations = twitch_count,
            .youtube_integrations = youtube_count,
            .reddit_integrations = reddit_count,
            .discord_integrations = discord_count,
        };
    }

    pub fn hasIntegration(integrations: []models.Integration, integration_id: u64) bool {
        for (integrations) |integration| {
            if (getIntegrationId(integration) == integration_id) {
                return true;
            }
        }
        return false;
    }

    pub fn getIntegration(integrations: []models.Integration, integration_id: u64) ?models.Integration {
        for (integrations) |integration| {
            if (getIntegrationId(integration) == integration_id) {
                return integration;
            }
        }
        return null;
    }

    pub fn getIntegrationCount(integrations: []models.Integration) usize {
        return integrations.len;
    }

    pub fn getIntegrationsByAccount(integrations: []models.Integration, account_id: []const u8) []models.Integration {
        var filtered = std.ArrayList(models.Integration).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (integrations) |integration| {
            if (std.mem.eql(u8, getIntegrationAccountId(integration), account_id)) {
                filtered.append(integration) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Integration{};
    }

    pub fn getIntegrationsByUser(integrations: []models.Integration, user_id: u64) []models.Integration {
        var filtered = std.ArrayList(models.Integration).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (integrations) |integration| {
            if (getIntegrationUserId(integration)) |uid| {
                if (uid == user_id) {
                    filtered.append(integration) catch {};
                }
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Integration{};
    }

    pub fn formatFullIntegrationInfo(integration: models.Integration) []const u8 {
        var info = std.ArrayList(u8).init(std.heap.page_allocator);
        defer info.deinit();

        try info.appendSlice("Integration: ");
        try info.appendSlice(getIntegrationName(integration));
        try info.appendSlice("\n");
        try info.appendSlice("ID: ");
        try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getIntegrationId(integration)}));
        try info.appendSlice("\n");
        try info.appendSlice("Type: ");
        try info.appendSlice(getIntegrationType(integration));
        try info.appendSlice("\n");
        try info.appendSlice("Enabled: ");
        try info.appendSlice(if (isIntegrationEnabled(integration)) "Yes" else "No");
        try info.appendSlice("\n");
        try info.appendSlice("Syncing: ");
        try info.appendSlice(if (isIntegrationSyncing(integration)) "Yes" else "No");
        try info.appendSlice("\n");
        try info.appendSlice("Account: ");
        try info.appendSlice(getIntegrationAccountName(integration));
        try info.appendSlice(" (");
        try info.appendSlice(getIntegrationAccountId(integration));
        try info.appendSlice(")\n");

        if (hasIntegrationRoles(integration)) {
            try info.appendSlice("Role Count: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getIntegrationRoleCount(integration).?}));
            try info.appendSlice("\n");
        }

        if (hasIntegrationUser(integration)) {
            try info.appendSlice("User: ");
            try info.appendSlice(getIntegrationUser(integration).?.username);
            try info.appendSlice("#");
            try info.appendSlice(getIntegrationUser(integration).?.discriminator);
            try info.appendSlice("\n");
        }

        if (getIntegrationExpireBehavior(integration)) |behavior| {
            try info.appendSlice("Expire Behavior: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{behavior}));
            try info.appendSlice("\n");
        }

        if (getIntegrationExpireGracePeriod(integration)) |grace_period| {
            try info.appendSlice("Expire Grace Period: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{grace_period}));
            try info.appendSlice("\n");
        }

        if (getIntegrationEnableEmoticons(integration)) |enable_emoticons| {
            try info.appendSlice("Enable Emoticons: ");
            try info.appendSlice(if (enable_emoticons) "Yes" else "No");
            try info.appendSlice("\n");
        }

        if (getIntegrationSubscriberCount(integration)) |subscriber_count| {
            try info.appendSlice("Subscriber Count: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{subscriber_count}));
            try info.appendSlice("\n");
        }

        if (getIntegrationRevoked(integration)) |revoked| {
            try info.appendSlice("Revoked: ");
            try info.appendSlice(if (revoked) "Yes" else "No");
            try info.appendSlice("\n");
        }

        if (getIntegrationApplication(integration)) |app| {
            try info.appendSlice("Application: ");
            try info.appendSlice(app.name);
            try info.appendSlice(" (ID: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{app.id}));
            try info.appendSlice(")\n");
        }

        return info.toOwnedSlice();
    }
};
