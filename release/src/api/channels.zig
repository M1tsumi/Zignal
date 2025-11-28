const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Channel management for Discord channels
pub const ChannelManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) ChannelManager {
        return ChannelManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get channel
    pub fn getChannel(self: *ChannelManager, channel_id: u64) !models.Channel {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Channel, response.body, .{});
    }

    /// Modify channel
    pub fn modifyChannel(
        self: *ChannelManager,
        channel_id: u64,
        name: ?[]const u8,
        channel_type: ?models.ChannelType,
        position: ?i64,
        topic: ?[]const u8,
        nsfw: ?bool,
        rate_limit_per_user: ?i64,
        bitrate: ?i64,
        user_limit: ?i64,
        permission_overwrites: ?[]models.PermissionOverwrite,
        parent_id: ?u64,
        rtc_region: ?[]const u8,
        video_quality_mode: ?models.VideoQualityMode,
        default_auto_archive_duration: ?i64,
        flags: ?u64,
        reason: ?[]const u8,
    ) !models.Channel {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyChannelPayload{
            .name = name,
            .type = channel_type,
            .position = position,
            .topic = topic,
            .nsfw = nsfw,
            .rate_limit_per_user = rate_limit_per_user,
            .bitrate = bitrate,
            .user_limit = user_limit,
            .permission_overwrites = permission_overwrites,
            .parent_id = parent_id,
            .rtc_region = rtc_region,
            .video_quality_mode = video_quality_mode,
            .default_auto_archive_duration = default_auto_archive_duration,
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

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Channel, response.body, .{});
    }

    /// Delete channel
    pub fn deleteChannel(
        self: *ChannelManager,
        channel_id: u64,
        reason: ?[]const u8,
    ) !models.Channel {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}",
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

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Channel, response.body, .{});
    }

    /// Get channel messages
    pub fn getChannelMessages(
        self: *ChannelManager,
        channel_id: u64,
        around: ?u64,
        before: ?u64,
        after: ?u64,
        limit: ?usize,
    ) ![]models.Message {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (around) |a| {
            try params.append(try std.fmt.allocPrint(self.allocator, "around={d}", .{a}));
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

        return try std.json.parse([]models.Message, response.body, .{});
    }

    /// Create message
    pub fn createMessage(
        self: *ChannelManager,
        channel_id: u64,
        content: ?[]const u8,
        embeds: ?[]models.Embed,
        components: ?[]models.Component,
        files: ?[]models.File,
        attachments: ?[]models.Attachment,
        tts: ?bool,
        allowed_mentions: ?models.AllowedMentions,
        message_reference: ?models.MessageReference,
        stickers: ?[]u64,
        nonce: ?[]const u8,
        enforce_nonce: ?bool,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const payload = CreateMessagePayload{
            .content = content,
            .embeds = embeds,
            .components = components,
            .files = files,
            .attachments = attachments,
            .tts = tts,
            .allowed_mentions = allowed_mentions,
            .message_reference = message_reference,
            .stickers = stickers,
            .nonce = nonce,
            .enforce_nonce = enforce_nonce,
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

        return try std.json.parse(models.Message, response.body, .{});
    }

    /// Edit message
    pub fn editMessage(
        self: *ChannelManager,
        channel_id: u64,
        message_id: u64,
        content: ?[]const u8,
        embeds: ?[]models.Embed,
        components: ?[]models.Component,
        file: ?[]models.File,
        attachments: ?[]models.Attachment,
        flags: ?u64,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}",
            .{ self.client.base_url, channel_id, message_id },
        );
        defer self.allocator.free(url);

        const payload = EditMessagePayload{
            .content = content,
            .embeds = embeds,
            .components = components,
            .file = file,
            .attachments = attachments,
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

    /// Delete message
    pub fn deleteMessage(
        self: *ChannelManager,
        channel_id: u64,
        message_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}",
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

    /// Bulk delete messages
    pub fn bulkDeleteMessages(
        self: *ChannelManager,
        channel_id: u64,
        messages: []u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/bulk-delete",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const payload = BulkDeleteMessagesPayload{
            .messages = messages,
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

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }
};

// Payload structures
const ModifyChannelPayload = struct {
    name: ?[]const u8 = null,
    type: ?models.ChannelType = null,
    position: ?i64 = null,
    topic: ?[]const u8 = null,
    nsfw: ?bool = null,
    rate_limit_per_user: ?i64 = null,
    bitrate: ?i64 = null,
    user_limit: ?i64 = null,
    permission_overwrites: ?[]models.PermissionOverwrite = null,
    parent_id: ?u64 = null,
    rtc_region: ?[]const u8 = null,
    video_quality_mode: ?models.VideoQualityMode = null,
    default_auto_archive_duration: ?i64 = null,
    flags: ?u64 = null,
};

const CreateMessagePayload = struct {
    content: ?[]const u8 = null,
    embeds: ?[]models.Embed = null,
    components: ?[]models.Component = null,
    files: ?[]models.File = null,
    attachments: ?[]models.Attachment = null,
    tts: ?bool = null,
    allowed_mentions: ?models.AllowedMentions = null,
    message_reference: ?models.MessageReference = null,
    stickers: ?[]u64 = null,
    nonce: ?[]const u8 = null,
    enforce_nonce: ?bool = null,
};

const EditMessagePayload = struct {
    content: ?[]const u8 = null,
    embeds: ?[]models.Embed = null,
    components: ?[]models.Component = null,
    file: ?[]models.File = null,
    attachments: ?[]models.Attachment = null,
    flags: ?u64 = null,
};

const BulkDeleteMessagesPayload = struct {
    messages: []u64,
};
