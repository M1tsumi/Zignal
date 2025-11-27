const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Invite management for guild access control
pub const InviteManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) InviteManager {
        return InviteManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get all invites for a channel
    pub fn getChannelInvites(self: *InviteManager, channel_id: u64) ![]models.Invite {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/invites",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Invite, response.body, .{});
    }

    /// Get all invites for a guild
    pub fn getGuildInvites(self: *InviteManager, guild_id: u64) ![]models.Invite {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/invites",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Invite, response.body, .{});
    }

    /// Create a channel invite
    pub fn createChannelInvite(
        self: *InviteManager,
        channel_id: u64,
        max_age: ?u32,
        max_uses: ?u32,
        temporary: bool,
        unique: bool,
        target_type: ?InviteTargetType,
        target_user_id: ?u64,
        target_application_id: ?u64,
        reason: ?[]const u8,
    ) !models.Invite {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/invites",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const payload = CreateInvitePayload{
            .max_age = max_age,
            .max_uses = max_uses,
            .temporary = temporary,
            .unique = unique,
            .target_type = target_type,
            .target_user_id = target_user_id,
            .target_application_id = target_application_id,
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

        return try std.json.parse(models.Invite, response.body, .{});
    }

    /// Delete a channel invite
    pub fn deleteChannelInvite(
        self: *InviteManager,
        channel_id: u64,
        invite_code: []const u8,
    ) !models.Invite {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/invites/{s}",
            .{ self.client.base_url, channel_id, invite_code },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Invite, response.body, .{});
    }

    /// Get invite information
    pub fn getInvite(
        self: *InviteManager,
        invite_code: []const u8,
        with_counts: bool,
        with_expiration: bool,
    ) !models.Invite {
        var query_builder = std.ArrayList(u8).init(self.allocator);
        defer query_builder.deinit();

        if (with_counts) {
            try query_builder.appendSlice("with_counts=true");
            try query_builder.append('&');
        }

        if (with_expiration) {
            try query_builder.appendSlice("with_expiration=true");
        }

        const query = if (query_builder.items.len > 0)
            try std.fmt.allocPrint(self.allocator, "?{s}", .{query_builder.items})
        else
            "";
        defer if (query.len > 0) self.allocator.free(query);

        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/invites/{s}{s}",
            .{ self.client.base_url, invite_code, query },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Invite, response.body, .{});
    }

    /// Accept an invite
    pub fn acceptInvite(
        self: *InviteManager,
        invite_code: []const u8,
    ) !models.Invite {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/invites/{s}",
            .{ self.client.base_url, invite_code },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.post(url, "");
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Invite, response.body, .{});
    }
};

/// Invite target types
pub const InviteTargetType = enum(u8) {
    stream = 1,
    embedded_application = 2,
};

/// Payload for creating an invite
pub const CreateInvitePayload = struct {
    max_age: ?u32 = null,
    max_uses: ?u32 = null,
    temporary: bool = false,
    unique: bool = false,
    target_type: ?InviteTargetType = null,
    target_user_id: ?u64 = null,
    target_application_id: ?u64 = null,
};

/// Invite validation utilities
pub const InviteValidator = struct {
    pub fn validateInviteCode(code: []const u8) bool {
        // Discord invite codes are 7-10 characters long
        // and contain alphanumeric characters and underscores
        if (code.len < 7 or code.len > 10) {
            return false;
        }

        for (code) |c| {
            if (!std.ascii.isAlphanumeric(c) and c != '_') {
                return false;
            }
        }

        return true;
    }

    pub fn generateInviteUrl(invite_code: []const u8) ![]const u8 {
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "https://discord.gg/{s}",
            .{invite_code},
        );
    }

    pub fn extractInviteCode(url: []const u8) ?[]const u8 {
        // Extract invite code from various URL formats
        // https://discord.gg/abc123
        // https://discord.com/invite/abc123
        // https://discord.com/channels/123456789/987654321/abc123
        
        const patterns = [_][]const u8{
            "discord.gg/",
            "discord.com/invite/",
            "discord.com/channels/",
        };

        for (patterns) |pattern| {
            if (std.mem.indexOf(u8, url, pattern)) |index| {
                const start = index + pattern.len;
                
                // Find the end of the invite code
                var end = start;
                while (end < url.len and (std.ascii.isAlphanumeric(url[end]) or url[end] == '_')) {
                    end += 1;
                }
                
                const code = url[start..end];
                if (validateInviteCode(code)) {
                    return code;
                }
            }
        }

        return null;
    }
};
