const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Guild thread management for Discord thread channels
pub const GuildThreadManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildThreadManager {
        return GuildThreadManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get active threads in guild
    pub fn getActiveGuildThreads(self: *GuildThreadManager, guild_id: u64) !models.ThreadListResponse {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/threads/active",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ThreadListResponse, response.body, .{});
    }

    /// Get joined private archived threads
    pub fn getJoinedPrivateArchivedThreads(
        self: *GuildThreadManager,
        guild_id: u64,
        before: ?u64,
        limit: ?usize,
    ) !models.ThreadListResponse {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/guilds/{d}/threads/archived/private",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (before) |b| {
            try params.append(try std.fmt.allocPrint(self.allocator, "before={d}", .{b}));
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

        return try std.json.parse(models.ThreadListResponse, response.body, .{});
    }

    /// Search for threads in guild
    pub fn searchGuildThreads(
        self: *GuildThreadManager,
        guild_id: u64,
        query: []const u8,
        limit: ?usize,
        sort_by: ?[]const u8,
        sort_order: ?[]const u8,
        include_threads: ?bool,
        include_members: ?bool,
        include_total_count: ?bool,
    ) !models.ThreadSearchResponse {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/threads/search",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        try params.append(try std.fmt.allocPrint(self.allocator, "query={s}", .{query}));
        
        if (limit) |l| {
            try params.append(try std.fmt.allocPrint(self.allocator, "limit={d}", .{l}));
        }
        if (sort_by) |sort| {
            try params.append(try std.fmt.allocPrint(self.allocator, "sort_by={s}", .{sort}));
        }
        if (sort_order) |order| {
            try params.append(try std.fmt.allocPrint(self.allocator, "sort_order={s}", .{order}));
        }
        if (include_threads) |include| {
            try params.append(try std.fmt.allocPrint(self.allocator, "include_threads={}", .{include}));
        }
        if (include_members) |include| {
            try params.append(try std.fmt.allocPrint(self.allocator, "include_members={}", .{include}));
        }
        if (include_total_count) |include| {
            try params.append(try std.fmt.allocPrint(self.allocator, "include_total_count={}", .{include}));
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

        return try std.json.parse(models.ThreadSearchResponse, response.body, .{});
    }

    /// Create forum thread
    pub fn createForumThread(
        self: *GuildThreadManager,
        channel_id: u64,
        name: []const u8,
        auto_archive_duration: ?i64,
        rate_limit_per_user: ?i64,
        content: []const u8,
        embeds: ?[]models.Embed,
        components: ?[]models.Component,
        files: ?[]models.File,
        attachments: ?[]models.Attachment,
        applied_tags: ?[]u64,
        flags: ?u64,
        reason: ?[]const u8,
    ) !models.Channel {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/threads",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const payload = CreateForumThreadPayload{
            .name = name,
            .auto_archive_duration = auto_archive_duration,
            .rate_limit_per_user = rate_limit_per_user,
            .message = CreateForumMessagePayload{
                .content = content,
                .embeds = embeds,
                .components = components,
                .files = files,
                .attachments = attachments,
            },
            .applied_tags = applied_tags,
            .flags = flags,
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

        return try std.json.parse(models.Channel, response.body, .{});
    }

    /// Add thread member
    pub fn addThreadMember(
        self: *GuildThreadManager,
        channel_id: u64,
        user_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/thread-members/{d}",
            .{ self.client.base_url, channel_id, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.put(url, "");
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Remove thread member
    pub fn removeThreadMember(
        self: *GuildThreadManager,
        channel_id: u64,
        user_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/thread-members/{d}",
            .{ self.client.base_url, channel_id, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get thread member
    pub fn getThreadMember(
        self: *GuildThreadManager,
        channel_id: u64,
        user_id: u64,
    ) !models.ThreadMember {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/thread-members/{d}",
            .{ self.client.base_url, channel_id, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ThreadMember, response.body, .{});
    }

    /// Get thread members
    pub fn getThreadMembers(
        self: *GuildThreadManager,
        channel_id: u64,
    ) ![]models.ThreadMember {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/thread-members",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.ThreadMember, response.body, .{});
    }

    /// Join thread
    pub fn joinThread(
        self: *GuildThreadManager,
        channel_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/thread-members/@me",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.put(url, "");
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Leave thread
    pub fn leaveThread(
        self: *GuildThreadManager,
        channel_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/thread-members/@me",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get guild thread directory
    pub fn getGuildThreadDirectory(
        self: *GuildThreadManager,
        guild_id: u64,
        before: ?u64,
        limit: ?usize,
    ) !models.ThreadDirectoryResponse {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/threads/directory",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (before) |b| {
            try params.append(try std.fmt.allocPrint(self.allocator, "before={d}", .{b}));
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

        return try std.json.parse(models.ThreadDirectoryResponse, response.body, .{});
    }
};

// Payload structures
const CreateForumThreadPayload = struct {
    name: []const u8,
    auto_archive_duration: ?i64 = null,
    rate_limit_per_user: ?i64 = null,
    message: CreateForumMessagePayload,
    applied_tags: ?[]u64 = null,
    flags: ?u64 = null,
};

const CreateForumMessagePayload = struct {
    content: []const u8,
    embeds: ?[]models.Embed = null,
    components: ?[]models.Component = null,
    files: ?[]models.File = null,
    attachments: ?[]models.Attachment = null,
};
