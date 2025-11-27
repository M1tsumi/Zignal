const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Guild voice state management for Discord voice channels
pub const GuildVoiceStateManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildVoiceStateManager {
        return GuildVoiceStateManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get current user voice state
    pub fn getCurrentUserVoiceState(
        self: *GuildVoiceStateManager,
        guild_id: u64,
    ) !models.VoiceState {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/voice-states/@me",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.VoiceState, response.body, .{});
    }

    /// Modify current user voice state
    pub fn modifyCurrentUserVoiceState(
        self: *GuildVoiceStateManager,
        guild_id: u64,
        channel_id: ?u64,
        suppress: ?bool,
        request_to_speak_timestamp: ?u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/voice-states/@me",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyCurrentUserVoiceStatePayload{
            .channel_id = channel_id,
            .suppress = suppress,
            .request_to_speak_timestamp = request_to_speak_timestamp,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get user voice state
    pub fn getUserVoiceState(
        self: *GuildVoiceStateManager,
        guild_id: u64,
        user_id: u64,
    ) !models.VoiceState {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/voice-states/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.VoiceState, response.body, .{});
    }

    /// Modify user voice state
    pub fn modifyUserVoiceState(
        self: *GuildVoiceStateManager,
        guild_id: u64,
        user_id: u64,
        channel_id: ?u64,
        suppress: ?bool,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/voice-states/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyUserVoiceStatePayload{
            .channel_id = channel_id,
            .suppress = suppress,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get all voice states in guild
    pub fn getGuildVoiceStates(
        self: *GuildVoiceStateManager,
        guild_id: u64,
    ) ![]models.VoiceState {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/voice-states",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.VoiceState, response.body, .{});
    }

    /// Move user to voice channel
    pub fn moveUserToVoiceChannel(
        self: *GuildVoiceStateManager,
        guild_id: u64,
        user_id: u64,
        channel_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = MoveUserToVoiceChannelPayload{
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

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Disconnect user from voice
    pub fn disconnectUserFromVoice(
        self: *GuildVoiceStateManager,
        guild_id: u64,
        user_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = DisconnectUserFromVoicePayload{
            .channel_id = null,
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

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Mute user in voice channel
    pub fn muteUserInVoice(
        self: *GuildVoiceStateManager,
        guild_id: u64,
        user_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = MuteUserInVoicePayload{
            .mute = true,
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

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Unmute user in voice channel
    pub fn unmuteUserInVoice(
        self: *GuildVoiceStateManager,
        guild_id: u64,
        user_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = MuteUserInVoicePayload{
            .mute = false,
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

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Deafen user in voice channel
    pub fn deafenUserInVoice(
        self: *GuildVoiceStateManager,
        guild_id: u64,
        user_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = DeafenUserInVoicePayload{
            .deaf = true,
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

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Undeafen user in voice channel
    pub fn undeafenUserInVoice(
        self: *GuildVoiceStateManager,
        guild_id: u64,
        user_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = DeafenUserInVoicePayload{
            .deaf = false,
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

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }
};

// Payload structures
const ModifyCurrentUserVoiceStatePayload = struct {
    channel_id: ?u64 = null,
    suppress: ?bool = null,
    request_to_speak_timestamp: ?u64 = null,
};

const ModifyUserVoiceStatePayload = struct {
    channel_id: ?u64 = null,
    suppress: ?bool = null,
};

const MoveUserToVoiceChannelPayload = struct {
    channel_id: u64,
};

const DisconnectUserFromVoicePayload = struct {
    channel_id: ?u64 = null,
};

const MuteUserInVoicePayload = struct {
    mute: bool,
};

const DeafenUserInVoicePayload = struct {
    deaf: bool,
};
