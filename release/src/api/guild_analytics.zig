const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild analytics management for Discord server analytics
pub const GuildAnalyticsManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildAnalyticsManager {
        return GuildAnalyticsManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild overview analytics
    pub fn getGuildOverviewAnalytics(
        self: *GuildAnalyticsManager,
        guild_id: u64,
        period: ?[]const u8,
    ) !models.GuildOverviewAnalytics {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/analytics/overview",
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

        return try std.json.parse(models.GuildOverviewAnalytics, response.body, .{});
    }

    /// Get member analytics
    pub fn getMemberAnalytics(
        self: *GuildAnalyticsManager,
        guild_id: u64,
        period: ?[]const u8,
        granularity: ?[]const u8,
    ) !models.MemberAnalytics {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/analytics/members",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (period) |p| {
            try params.append(try std.fmt.allocPrint(self.allocator, "period={s}", .{p}));
        }
        if (granularity) |g| {
            try params.append(try std.fmt.allocPrint(self.allocator, "granularity={s}", .{g}));
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

        return try std.json.parse(models.MemberAnalytics, response.body, .{});
    }

    /// Get message analytics
    pub fn getMessageAnalytics(
        self: *GuildAnalyticsManager,
        guild_id: u64,
        period: ?[]const u8,
        granularity: ?[]const u8,
        channel_id: ?u64,
    ) !models.MessageAnalytics {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/analytics/messages",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (period) |p| {
            try params.append(try std.fmt.allocPrint(self.allocator, "period={s}", .{p}));
        }
        if (granularity) |g| {
            try params.append(try std.fmt.allocPrint(self.allocator, "granularity={s}", .{g}));
        }
        if (channel_id) |cid| {
            try params.append(try std.fmt.allocPrint(self.allocator, "channel_id={d}", .{cid}));
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

        return try std.json.parse(models.MessageAnalytics, response.body, .{});
    }

    /// Get engagement analytics
    pub fn getEngagementAnalytics(
        self: *GuildAnalyticsManager,
        guild_id: u64,
        period: ?[]const u8,
        granularity: ?[]const u8,
    ) !models.EngagementAnalytics {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/analytics/engagement",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (period) |p| {
            try params.append(try std.fmt.allocPrint(self.allocator, "period={s}", .{p}));
        }
        if (granularity) |g| {
            try params.append(try std.fmt.allocPrint(self.allocator, "granularity={s}", .{g}));
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

        return try std.json.parse(models.EngagementAnalytics, response.body, .{});
    }

    /// Get voice analytics
    pub fn getVoiceAnalytics(
        self: *GuildAnalyticsManager,
        guild_id: u64,
        period: ?[]const u8,
        granularity: ?[]const u8,
    ) !models.VoiceAnalytics {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/analytics/voice",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (period) |p| {
            try params.append(try std.fmt.allocPrint(self.allocator, "period={s}", .{p}));
        }
        if (granularity) |g| {
            try params.append(try std.fmt.allocPrint(self.allocator, "granularity={s}", .{g}));
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

        return try std.json.parse(models.VoiceAnalytics, response.body, .{});
    }

    /// Get channel analytics
    pub fn getChannelAnalytics(
        self: *GuildAnalyticsManager,
        guild_id: u64,
        channel_id: u64,
        period: ?[]const u8,
        granularity: ?[]const u8,
    ) !models.ChannelAnalytics {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/analytics/channels/{d}",
            .{ self.client.base_url, guild_id, channel_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (period) |p| {
            try params.append(try std.fmt.allocPrint(self.allocator, "period={s}", .{p}));
        }
        if (granularity) |g| {
            try params.append(try std.fmt.allocPrint(self.allocator, "granularity={s}", .{g}));
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

        return try std.json.parse(models.ChannelAnalytics, response.body, .{});
    }

    /// Get role analytics
    pub fn getRoleAnalytics(
        self: *GuildAnalyticsManager,
        guild_id: u64,
        role_id: u64,
        period: ?[]const u8,
        granularity: ?[]const u8,
    ) !models.RoleAnalytics {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/analytics/roles/{d}",
            .{ self.client.base_url, guild_id, role_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (period) |p| {
            try params.append(try std.fmt.allocPrint(self.allocator, "period={s}", .{p}));
        }
        if (granularity) |g| {
            try params.append(try std.fmt.allocPrint(self.allocator, "granularity={s}", .{g}));
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

        return try std.json.parse(models.RoleAnalytics, response.body, .{});
    }

    /// Get custom analytics report
    pub fn getCustomAnalyticsReport(
        self: *GuildAnalyticsManager,
        guild_id: u64,
        metrics: []const []const u8,
        period: []const u8,
        granularity: []const u8,
        filters: ?std.json.ObjectMap,
    ) !models.CustomAnalyticsReport {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/analytics/custom",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        try params.append(try std.fmt.allocPrint(self.allocator, "period={s}", .{period}));
        try params.append(try std.fmt.allocPrint(self.allocator, "granularity={s}", .{granularity}));

        for (metrics, 0..) |metric, i| {
            try params.append(try std.fmt.allocPrint(self.allocator, "metrics[{d}]={s}", .{ i, metric }));
        }

        if (params.items.len > 0) {
            try url.appendSlice("?");
            for (params.items, 0..) |param, i| {
                if (i > 0) try url.appendSlice("&");
                try url.appendSlice(param);
            }
        }

        const payload = GetCustomAnalyticsReportPayload{
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

        return try std.json.parse(models.CustomAnalyticsReport, response.body, .{});
    }

    /// Export analytics data
    pub fn exportAnalyticsData(
        self: *GuildAnalyticsManager,
        guild_id: u64,
        export_type: models.AnalyticsExportType,
        period: []const u8,
        metrics: ?[]const []const u8,
        format: ?[]const u8,
    ) !models.AnalyticsExport {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/analytics/export",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        try params.append(try std.fmt.allocPrint(self.allocator, "export_type={d}", .{@intFromEnum(export_type)}));
        try params.append(try std.fmt.allocPrint(self.allocator, "period={s}", .{period}));

        if (format) |f| {
            try params.append(try std.fmt.allocPrint(self.allocator, "format={s}", .{f}));
        }

        if (metrics) |m| {
            for (m, 0..) |metric, i| {
                try params.append(try std.fmt.allocPrint(self.allocator, "metrics[{d}]={s}", .{ i, metric }));
            }
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

        return try std.json.parse(models.AnalyticsExport, response.body, .{});
    }

    /// Get analytics insights
    pub fn getAnalyticsInsights(
        self: *GuildAnalyticsManager,
        guild_id: u64,
        insight_types: ?[]models.InsightType,
        period: ?[]const u8,
    ) ![]models.AnalyticsInsight {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/analytics/insights",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (insight_types) |types| {
            for (types, 0..) |insight_type, i| {
                try params.append(try std.fmt.allocPrint(self.allocator, "insight_types[{d}]={d}", .{ i, @intFromEnum(insight_type) }));
            }
        }

        if (period) |p| {
            try params.append(try std.fmt.allocPrint(self.allocator, "period={s}", .{p}));
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

        return try std.json.parse([]models.AnalyticsInsight, response.body, .{});
    }
};

// Payload structures
const GetCustomAnalyticsReportPayload = struct {
    filters: ?std.json.ObjectMap = null,
};
