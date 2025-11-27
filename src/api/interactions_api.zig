const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Interaction API management for Discord interactions
pub const InteractionAPIManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) InteractionAPIManager {
        return InteractionAPIManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Create interaction response
    pub fn createInteractionResponse(
        self: *InteractionAPIManager,
        interaction_id: u64,
        interaction_token: []const u8,
        response_type: models.InteractionResponseType,
        data: ?models.InteractionApplicationCommandCallbackData,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/interactions/{d}/{s}/callback",
            .{ self.client.base_url, interaction_id, interaction_token },
        );
        defer self.allocator.free(url);

        const payload = CreateInteractionResponsePayload{
            .type = response_type,
            .data = data,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get original interaction response
    pub fn getOriginalInteractionResponse(
        self: *InteractionAPIManager,
        application_id: u64,
        interaction_token: []const u8,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}/messages/@original",
            .{ self.client.base_url, application_id, interaction_token },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Message, response.body, .{});
    }

    /// Edit original interaction response
    pub fn editOriginalInteractionResponse(
        self: *InteractionAPIManager,
        application_id: u64,
        interaction_token: []const u8,
        content: ?[]const u8,
        embeds: ?[]models.Embed,
        components: ?[]models.Component,
        file: ?[]models.File,
        attachments: ?[]models.Attachment,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}/messages/@original",
            .{ self.client.base_url, application_id, interaction_token },
        );
        defer self.allocator.free(url);

        const payload = EditInteractionResponsePayload{
            .content = content,
            .embeds = embeds,
            .components = components,
            .file = file,
            .attachments = attachments,
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

    /// Delete original interaction response
    pub fn deleteOriginalInteractionResponse(
        self: *InteractionAPIManager,
        application_id: u64,
        interaction_token: []const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}/messages/@original",
            .{ self.client.base_url, application_id, interaction_token },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Create followup message
    pub fn createFollowupMessage(
        self: *InteractionAPIManager,
        application_id: u64,
        interaction_token: []const u8,
        content: ?[]const u8,
        embeds: ?[]models.Embed,
        components: ?[]models.Component,
        files: ?[]models.File,
        attachments: ?[]models.Attachment,
        tts: ?bool,
        allowed_mentions: ?models.AllowedMentions,
        flags: ?u64,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}",
            .{ self.client.base_url, application_id, interaction_token },
        );
        defer self.allocator.free(url);

        const payload = CreateFollowupMessagePayload{
            .content = content,
            .embeds = embeds,
            .components = components,
            .files = files,
            .attachments = attachments,
            .tts = tts,
            .allowed_mentions = allowed_mentions,
            .flags = flags,
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

    /// Get followup message
    pub fn getFollowupMessage(
        self: *InteractionAPIManager,
        application_id: u64,
        interaction_token: []const u8,
        message_id: u64,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}/messages/{d}",
            .{ self.client.base_url, application_id, interaction_token, message_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Message, response.body, .{});
    }

    /// Edit followup message
    pub fn editFollowupMessage(
        self: *InteractionAPIManager,
        application_id: u64,
        interaction_token: []const u8,
        message_id: u64,
        content: ?[]const u8,
        embeds: ?[]models.Embed,
        components: ?[]models.Component,
        file: ?[]models.File,
        attachments: ?[]models.Attachment,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}/messages/{d}",
            .{ self.client.base_url, application_id, interaction_token, message_id },
        );
        defer self.allocator.free(url);

        const payload = EditInteractionResponsePayload{
            .content = content,
            .embeds = embeds,
            .components = components,
            .file = file,
            .attachments = attachments,
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

    /// Delete followup message
    pub fn deleteFollowupMessage(
        self: *InteractionAPIManager,
        application_id: u64,
        interaction_token: []const u8,
        message_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/webhooks/{d}/{s}/messages/{d}",
            .{ self.client.base_url, application_id, interaction_token, message_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }
};

// Payload structures
const CreateInteractionResponsePayload = struct {
    type: models.InteractionResponseType,
    data: ?models.InteractionApplicationCommandCallbackData = null,
};

const EditInteractionResponsePayload = struct {
    content: ?[]const u8 = null,
    embeds: ?[]models.Embed = null,
    components: ?[]models.Component = null,
    file: ?[]models.File = null,
    attachments: ?[]models.Attachment = null,
};

const CreateFollowupMessagePayload = struct {
    content: ?[]const u8 = null,
    embeds: ?[]models.Embed = null,
    components: ?[]models.Component = null,
    files: ?[]models.File = null,
    attachments: ?[]models.Attachment = null,
    tts: ?bool = null,
    allowed_mentions: ?models.AllowedMentions = null,
    flags: ?u64 = null,
};
