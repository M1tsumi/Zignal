const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Message management for Discord messages
pub const MessageManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) MessageManager {
        return MessageManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get message
    pub fn getMessage(
        self: *MessageManager,
        channel_id: u64,
        message_id: u64,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}",
            .{ self.client.base_url, channel_id, message_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Message, response.body, .{});
    }

    /// Crosspost message
    pub fn crosspostMessage(
        self: *MessageManager,
        channel_id: u64,
        message_id: u64,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/crosspost",
            .{ self.client.base_url, channel_id, message_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.post(url, "");
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Message, response.body, .{});
    }

    /// Create reaction
    pub fn createReaction(
        self: *MessageManager,
        channel_id: u64,
        message_id: u64,
        emoji: []const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/reactions/{s}/@me",
            .{ self.client.base_url, channel_id, message_id, emoji },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.put(url, "");
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Delete own reaction
    pub fn deleteOwnReaction(
        self: *MessageManager,
        channel_id: u64,
        message_id: u64,
        emoji: []const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/reactions/{s}/@me",
            .{ self.client.base_url, channel_id, message_id, emoji },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Delete user reaction
    pub fn deleteUserReaction(
        self: *MessageManager,
        channel_id: u64,
        message_id: u64,
        emoji: []const u8,
        user_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/reactions/{s}/{d}",
            .{ self.client.base_url, channel_id, message_id, emoji, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get reactions
    pub fn getReactions(
        self: *MessageManager,
        channel_id: u64,
        message_id: u64,
        emoji: []const u8,
        after: ?u64,
        limit: ?usize,
    ) ![]models.User {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/reactions/{s}",
            .{ self.client.base_url, channel_id, message_id, emoji },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

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

        return try std.json.parse([]models.User, response.body, .{});
    }

    /// Delete all reactions
    pub fn deleteAllReactions(
        self: *MessageManager,
        channel_id: u64,
        message_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/reactions",
            .{ self.client.base_url, channel_id, message_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Delete emoji reactions
    pub fn deleteEmojiReactions(
        self: *MessageManager,
        channel_id: u64,
        message_id: u64,
        emoji: []const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/reactions/{s}",
            .{ self.client.base_url, channel_id, message_id, emoji },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Edit message flags
    pub fn editMessageFlags(
        self: *MessageManager,
        channel_id: u64,
        message_id: u64,
        flags: u64,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/flags",
            .{ self.client.base_url, channel_id, message_id },
        );
        defer self.allocator.free(url);

        const payload = EditMessageFlagsPayload{
            .flags = flags,
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

        return try std.json.parse(models.Message, response.body, .{});
    }

    /// Pin message
    pub fn pinMessage(
        self: *MessageManager,
        channel_id: u64,
        message_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/pins/{d}",
            .{ self.client.base_url, channel_id, message_id },
        );
        defer self.allocator.free(url);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.put(url, "");
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Unpin message
    pub fn unpinMessage(
        self: *MessageManager,
        channel_id: u64,
        message_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/pins/{d}",
            .{ self.client.base_url, channel_id, message_id },
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

    /// Get pinned messages
    pub fn getPinnedMessages(
        self: *MessageManager,
        channel_id: u64,
    ) ![]models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/pins",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Message, response.body, .{});
    }

    /// Start thread from message
    pub fn startThreadFromMessage(
        self: *MessageManager,
        channel_id: u64,
        message_id: u64,
        name: []const u8,
        auto_archive_duration: ?i64,
        rate_limit_per_user: ?i64,
        reason: ?[]const u8,
    ) !models.Channel {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/threads",
            .{ self.client.base_url, channel_id, message_id },
        );
        defer self.allocator.free(url);

        const payload = StartThreadFromMessagePayload{
            .name = name,
            .auto_archive_duration = auto_archive_duration,
            .rate_limit_per_user = rate_limit_per_user,
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

    /// Start thread without message
    pub fn startThreadWithoutMessage(
        self: *MessageManager,
        channel_id: u64,
        name: []const u8,
        type: models.ChannelType,
        auto_archive_duration: ?i64,
        invitable: ?bool,
        rate_limit_per_user: ?i64,
        reason: ?[]const u8,
    ) !models.Channel {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/threads",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const payload = StartThreadWithoutMessagePayload{
            .name = name,
            .type = type,
            .auto_archive_duration = auto_archive_duration,
            .invitable = invitable,
            .rate_limit_per_user = rate_limit_per_user,
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

    /// Join thread
    pub fn joinThread(
        self: *MessageManager,
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

    /// Add thread member
    pub fn addThreadMember(
        self: *MessageManager,
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

    /// Leave thread
    pub fn leaveThread(
        self: *MessageManager,
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

    /// Remove thread member
    pub fn removeThreadMember(
        self: *MessageManager,
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

    /// Get thread members
    pub fn getThreadMembers(
        self: *MessageManager,
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

    /// Get archived threads (private)
    pub fn getArchivedThreadsPrivate(
        self: *MessageManager,
        channel_id: u64,
        before: ?u64,
        limit: ?usize,
    ) !models.ThreadListResponse {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/threads/archived/private",
            .{ self.client.base_url, channel_id },
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

    /// Get archived threads (private joined)
    pub fn getArchivedThreadsPrivateJoined(
        self: *MessageManager,
        channel_id: u64,
        before: ?u64,
        limit: ?usize,
    ) !models.ThreadListResponse {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/users/@me/threads/archived/private",
            .{ self.client.base_url, channel_id },
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

    /// Get archived threads (public)
    pub fn getArchivedThreadsPublic(
        self: *MessageManager,
        channel_id: u64,
        before: ?u64,
        limit: ?usize,
    ) !models.ThreadListResponse {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/threads/archived/public",
            .{ self.client.base_url, channel_id },
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

    /// Get active threads
    pub fn getActiveThreads(
        self: *MessageManager,
        channel_id: u64,
    ) !models.ThreadListResponse {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/threads/active",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ThreadListResponse, response.body, .{});
    }
};

// Payload structures
const EditMessageFlagsPayload = struct {
    flags: u64,
};

const StartThreadFromMessagePayload = struct {
    name: []const u8,
    auto_archive_duration: ?i64 = null,
    rate_limit_per_user: ?i64 = null,
};

const StartThreadWithoutMessagePayload = struct {
    name: []const u8,
    type: models.ChannelType,
    auto_archive_duration: ?i64 = null,
    invitable: ?bool = null,
    rate_limit_per_user: ?i64 = null,
};
