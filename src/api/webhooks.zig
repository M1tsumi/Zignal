const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Advanced webhook management for server automation
pub const WebhookManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) WebhookManager {
        return WebhookManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Create a channel webhook
    pub fn createChannelWebhook(
        self: *WebhookManager,
        channel_id: u64,
        name: []const u8,
        avatar: ?[]const u8, // Base64 encoded image data
        reason: ?[]const u8,
    ) !models.Webhook {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/webhooks",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const payload = CreateWebhookPayload{
            .name = name,
            .avatar = avatar,
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

        return try std.json.parse(models.Webhook, response.body, .{});
    }

    /// Get channel webhooks
    pub fn getChannelWebhooks(self: *WebhookManager, channel_id: u64) ![]models.Webhook {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/webhooks",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Webhook, response.body, .{});
    }

    /// Get guild webhooks
    pub fn getGuildWebhooks(self: *WebhookManager, guild_id: u64) ![]models.Webhook {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/webhooks",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Webhook, response.body, .{});
    }

    /// Get webhook by ID
    pub fn getWebhook(
        self: *WebhookManager,
        webhook_id: u64,
    ) !models.Webhook {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}",
            .{ self.client.base_url, webhook_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Webhook, response.body, .{});
    }

    /// Get webhook with token
    pub fn getWebhookWithToken(
        self: *WebhookManager,
        webhook_id: u64,
        webhook_token: []const u8,
    ) !models.Webhook {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}",
            .{ self.client.base_url, webhook_id, webhook_token },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Webhook, response.body, .{});
    }

    /// Modify a webhook
    pub fn modifyWebhook(
        self: *WebhookManager,
        webhook_id: u64,
        name: ?[]const u8,
        avatar: ?[]const u8,
        channel_id: ?u64,
        reason: ?[]const u8,
    ) !models.Webhook {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}",
            .{ self.client.base_url, webhook_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyWebhookPayload{
            .name = name,
            .avatar = avatar,
            .channel_id = channel_id,
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

        return try std.json.parse(models.Webhook, response.body, .{});
    }

    /// Modify a webhook with token
    pub fn modifyWebhookWithToken(
        self: *WebhookManager,
        webhook_id: u64,
        webhook_token: []const u8,
        name: ?[]const u8,
        avatar: ?[]const u8,
    ) !models.Webhook {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}",
            .{ self.client.base_url, webhook_id, webhook_token },
        );
        defer self.allocator.free(url);

        const payload = ModifyWebhookWithTokenPayload{
            .name = name,
            .avatar = avatar,
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

        return try std.json.parse(models.Webhook, response.body, .{});
    }

    /// Delete a webhook
    pub fn deleteWebhook(
        self: *WebhookManager,
        webhook_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}",
            .{ self.client.base_url, webhook_id },
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

    /// Delete a webhook with token
    pub fn deleteWebhookWithToken(
        self: *WebhookManager,
        webhook_id: u64,
        webhook_token: []const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}",
            .{ self.client.base_url, webhook_id, webhook_token },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Execute a webhook
    pub fn executeWebhook(
        self: *WebhookManager,
        webhook_id: u64,
        webhook_token: []const u8,
        content: ?[]const u8,
        username: ?[]const u8,
        avatar_url: ?[]const u8,
        tts: bool,
        embeds: ?[]models.Embed,
        allowed_mentions: ?models.AllowedMentions,
        components: ?[]models.MessageComponent,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}?wait=true",
            .{ self.client.base_url, webhook_id, webhook_token },
        );
        defer self.allocator.free(url);

        const payload = ExecuteWebhookPayload{
            .content = content,
            .username = username,
            .avatar_url = avatar_url,
            .tts = tts,
            .embeds = embeds,
            .allowed_mentions = allowed_mentions,
            .components = components,
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

    /// Execute a webhook with file upload
    pub fn executeWebhookWithFiles(
        self: *WebhookManager,
        webhook_id: u64,
        webhook_token: []const u8,
        content: ?[]const u8,
        username: ?[]const u8,
        avatar_url: ?[]const u8,
        tts: bool,
        embeds: ?[]models.Embed,
        files: []WebhookFile,
        allowed_mentions: ?models.AllowedMentions,
        components: ?[]models.MessageComponent,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}?wait=true",
            .{ self.client.base_url, webhook_id, webhook_token },
        );
        defer self.allocator.free(url);

        // Create multipart form data
        var boundary = std.ArrayList(u8).init(self.allocator);
        defer boundary.deinit();
        try boundary.appendSlice("----WebKitFormBoundary");

        // Generate random boundary
        var rng = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
        const random = rng.random();
        for (0..16) |_| {
            const char = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"[random.intRangeAtMost(u8, 61)];
            try boundary.append(char);
        }

        var form_data = std.ArrayList(u8).init(self.allocator);
        defer form_data.deinit();

        // Add JSON payload
        const json_payload = ExecuteWebhookPayload{
            .content = content,
            .username = username,
            .avatar_url = avatar_url,
            .tts = tts,
            .embeds = embeds,
            .allowed_mentions = allowed_mentions,
            .components = components,
        };

        const json_string = try std.json.stringifyAlloc(self.allocator, json_payload, .{});
        defer self.allocator.free(json_string);

        try form_data.appendSlice("--");
        try form_data.appendSlice(boundary.items);
        try form_data.appendSlice("\r\n");
        try form_data.appendSlice("Content-Disposition: form-data; name=\"payload_json\"\r\n\r\n");
        try form_data.appendSlice(json_string);
        try form_data.appendSlice("\r\n");

        // Add files
        for (files, 0..) |file, i| {
            try form_data.appendSlice("--");
            try form_data.appendSlice(boundary.items);
            try form_data.appendSlice("\r\n");
            try form_data.appendSlice("Content-Disposition: form-data; name=\"files[");
            try form_data.appendSlice(try std.fmt.allocPrint(self.allocator, "{d}", .{i}));
            try form_data.appendSlice("]\"; filename=\"");
            try form_data.appendSlice(file.name);
            try form_data.appendSlice("\"\r\n");
            try form_data.appendSlice("Content-Type: ");
            try form_data.appendSlice(file.content_type);
            try form_data.appendSlice("\r\n\r\n");
            try form_data.appendSlice(file.data);
            try form_data.appendSlice("\r\n");
        }

        // End boundary
        try form_data.appendSlice("--");
        try form_data.appendSlice(boundary.items);
        try form_data.appendSlice("--\r\n");

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", try std.fmt.allocPrint(self.allocator, "multipart/form-data; boundary={s}", .{boundary.items}));

        const response = try self.client.http.post(url, form_data.items);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Message, response.body, .{});
    }

    /// Get webhook message
    pub fn getWebhookMessage(
        self: *WebhookManager,
        webhook_id: u64,
        webhook_token: []const u8,
        message_id: u64,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}/messages/{d}",
            .{ self.client.base_url, webhook_id, webhook_token, message_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Message, response.body, .{});
    }

    /// Edit webhook message
    pub fn editWebhookMessage(
        self: *WebhookManager,
        webhook_id: u64,
        webhook_token: []const u8,
        message_id: u64,
        content: ?[]const u8,
        embeds: ?[]models.Embed,
        allowed_mentions: ?models.AllowedMentions,
        components: ?[]models.MessageComponent,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}/messages/{d}",
            .{ self.client.base_url, webhook_id, webhook_token, message_id },
        );
        defer self.allocator.free(url);

        const payload = EditWebhookMessagePayload{
            .content = content,
            .embeds = embeds,
            .allowed_mentions = allowed_mentions,
            .components = components,
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

    /// Delete webhook message
    pub fn deleteWebhookMessage(
        self: *WebhookManager,
        webhook_id: u64,
        webhook_token: []const u8,
        message_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}/messages/{d}",
            .{ self.client.base_url, webhook_id, webhook_token, message_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }
};

/// Payload for creating a webhook
pub const CreateWebhookPayload = struct {
    name: []const u8,
    avatar: ?[]const u8 = null,
};

/// Payload for modifying a webhook
pub const ModifyWebhookPayload = struct {
    name: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
    channel_id: ?u64 = null,
};

/// Payload for modifying a webhook with token
pub const ModifyWebhookWithTokenPayload = struct {
    name: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
};

/// Payload for executing a webhook
pub const ExecuteWebhookPayload = struct {
    content: ?[]const u8 = null,
    username: ?[]const u8 = null,
    avatar_url: ?[]const u8 = null,
    tts: bool = false,
    embeds: ?[]models.Embed = null,
    allowed_mentions: ?models.AllowedMentions = null,
    components: ?[]models.MessageComponent = null,
};

/// Payload for editing a webhook message
pub const EditWebhookMessagePayload = struct {
    content: ?[]const u8 = null,
    embeds: ?[]models.Embed = null,
    allowed_mentions: ?models.AllowedMentions = null,
    components: ?[]models.MessageComponent = null,
};

/// Webhook file for uploads
pub const WebhookFile = struct {
    name: []const u8,
    data: []const u8,
    content_type: []const u8,
};

/// Webhook utilities
pub const WebhookUtils = struct {
    pub fn validateWebhookName(name: []const u8) bool {
        // Webhook names must be 2-32 characters
        return name.len >= 2 and name.len <= 32;
    }

    pub fn generateWebhookUrl(webhook_id: u64, webhook_token: []const u8) ![]const u8 {
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "https://discord.com/api/webhooks/{d}/{s}",
            .{ webhook_id, webhook_token },
        );
    }

    pub fn extractWebhookInfo(url: []const u8) ?struct { id: u64, token: []const u8 } {
        // Extract webhook ID and token from URL
        // https://discord.com/api/webhooks/1234567890123456789/abcdef-ghijkl-mnopqr-stuvwx-yz123456
        
        if (std.mem.indexOf(u8, url, "webhooks/")) |index| {
            const start = index + 9; // length of "webhooks/"
            
            // Find the end of the webhook ID
            var id_end = start;
            while (id_end < url.len and std.ascii.isDigit(url[id_end])) {
                id_end += 1;
            }
            
            if (id_end == start or id_end >= url.len or url[id_end] != '/') {
                return null;
            }
            
            const id_str = url[start..id_end];
            const webhook_id = std.fmt.parseInt(u64, id_str, 10) catch return null;
            
            const token_start = id_end + 1;
            if (token_start >= url.len) {
                return null;
            }
            
            // Find the end of the token
            var token_end = token_start;
            while (token_end < url.len and (std.ascii.isAlphanumeric(url[token_end]) or url[token_end] == '-')) {
                token_end += 1;
            }
            
            const token = url[token_start..token_end];
            
            return .{ .id = webhook_id, .token = token };
        }
        
        return null;
    }

    pub fn createWebhookFile(
        name: []const u8,
        data: []const u8,
        content_type: []const u8,
    ) WebhookFile {
        return WebhookFile{
            .name = name,
            .data = data,
            .content_type = content_type,
        };
    }

    pub fn detectFileContentType(filename: []const u8) []const u8 {
        if (std.mem.endsWith(u8, filename, ".png")) return "image/png";
        if (std.mem.endsWith(u8, filename, ".jpg") or std.mem.endsWith(u8, filename, ".jpeg")) return "image/jpeg";
        if (std.mem.endsWith(u8, filename, ".gif")) return "image/gif";
        if (std.mem.endsWith(u8, filename, ".txt")) return "text/plain";
        if (std.mem.endsWith(u8, filename, ".json")) return "application/json";
        if (std.mem.endsWith(u8, filename, ".pdf")) return "application/pdf";
        if (std.mem.endsWith(u8, filename, ".zip")) return "application/zip";
        return "application/octet-stream";
    }

    pub fn formatWebhookInfo(webhook: models.Webhook) []const u8 {
        var info = std.ArrayList(u8).init(std.heap.page_allocator);
        defer info.deinit();

        try info.appendSlice("Webhook: ");
        try info.appendSlice(webhook.name);
        try info.appendSlice(" (ID: ");
        try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{webhook.id}));
        try info.appendSlice(")");

        if (webhook.channel_id) |channel_id| {
            try info.appendSlice(" - Channel: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{channel_id}));
        }

        if (webhook.guild_id) |guild_id| {
            try info.appendSlice(" - Guild: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{guild_id}));
        }

        return info.toOwnedSlice();
    }
};
