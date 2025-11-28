const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild management for Discord servers
pub const GuildManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildManager {
        return GuildManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild
    pub fn getGuild(self: *GuildManager, guild_id: u64, with_counts: ?bool) !models.Guild {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        if (with_counts orelse false) {
            try url.appendSlice("?with_counts=true");
        }

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Guild, response.body, .{});
    }

    /// Get guild preview
    pub fn getGuildPreview(self: *GuildManager, guild_id: u64) !models.GuildPreview {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/preview",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildPreview, response.body, .{});
    }

    /// Create guild
    pub fn createGuild(
        self: *GuildManager,
        name: []const u8,
        icon: ?[]const u8, // Base64 encoded image data
        verification_level: ?models.VerificationLevel,
        default_message_notifications: ?models.DefaultMessageNotificationLevel,
        explicit_content_filter: ?models.ExplicitContentFilterLevel,
        roles: ?[]models.Role,
        channels: ?[]models.Channel,
        afk_channel_id: ?u64,
        afk_timeout: ?i64,
        system_channel_id: ?u64,
        system_channel_flags: ?u64,
    ) !models.Guild {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        const payload = CreateGuildPayload{
            .name = name,
            .icon = icon,
            .verification_level = verification_level,
            .default_message_notifications = default_message_notifications,
            .explicit_content_filter = explicit_content_filter,
            .roles = roles,
            .channels = channels,
            .afk_channel_id = afk_channel_id,
            .afk_timeout = afk_timeout,
            .system_channel_id = system_channel_id,
            .system_channel_flags = system_channel_flags,
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

        return try std.json.parse(models.Guild, response.body, .{});
    }

    /// Modify guild
    pub fn modifyGuild(
        self: *GuildManager,
        guild_id: u64,
        name: ?[]const u8,
        icon: ?[]const u8,
        splash: ?[]const u8,
        discovery_splash: ?[]const u8,
        banner: ?[]const u8,
        owner_id: ?u64,
        afk_channel_id: ?u64,
        afk_timeout: ?i64,
        verification_level: ?models.VerificationLevel,
        default_message_notifications: ?models.DefaultMessageNotificationLevel,
        explicit_content_filter: ?models.ExplicitContentFilterLevel,
        rules_channel_id: ?u64,
        public_updates_channel_id: ?u64,
        preferred_locale: ?[]const u8,
        features: ?[]models.GuildFeature,
        description: ?[]const u8,
        premium_progress_bar_enabled: ?bool,
        reason: ?[]const u8,
    ) !models.Guild {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyGuildPayload{
            .name = name,
            .icon = icon,
            .splash = splash,
            .discovery_splash = discovery_splash,
            .banner = banner,
            .owner_id = owner_id,
            .afk_channel_id = afk_channel_id,
            .afk_timeout = afk_timeout,
            .verification_level = verification_level,
            .default_message_notifications = default_message_notifications,
            .explicit_content_filter = explicit_content_filter,
            .rules_channel_id = rules_channel_id,
            .public_updates_channel_id = public_updates_channel_id,
            .preferred_locale = preferred_locale,
            .features = features,
            .description = description,
            .premium_progress_bar_enabled = premium_progress_bar_enabled,
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

        return try std.json.parse(models.Guild, response.body, .{});
    }

    /// Delete guild
    pub fn deleteGuild(self: *GuildManager, guild_id: u64) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get guild channels
    pub fn getGuildChannels(self: *GuildManager, guild_id: u64) ![]models.Channel {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/channels",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Channel, response.body, .{});
    }

    /// Create guild channel
    pub fn createGuildChannel(
        self: *GuildManager,
        guild_id: u64,
        name: []const u8,
        channel_type: models.ChannelType,
        topic: ?[]const u8,
        position: ?i64,
        permission_overwrites: ?[]models.PermissionOverwrite,
        nsfw: ?bool,
        rate_limit_per_user: ?i64,
        bitrate: ?i64,
        user_limit: ?i64,
        parent_id: ?u64,
        rtc_region: ?[]const u8,
        video_quality_mode: ?models.VideoQualityMode,
        default_auto_archive_duration: ?i64,
        reason: ?[]const u8,
    ) !models.Channel {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/channels",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreateGuildChannelPayload{
            .name = name,
            .type = channel_type,
            .topic = topic,
            .position = position,
            .permission_overwrites = permission_overwrites,
            .nsfw = nsfw,
            .rate_limit_per_user = rate_limit_per_user,
            .bitrate = bitrate,
            .user_limit = user_limit,
            .parent_id = parent_id,
            .rtc_region = rtc_region,
            .video_quality_mode = video_quality_mode,
            .default_auto_archive_duration = default_auto_archive_duration,
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

    /// Modify guild channel positions
    pub fn modifyGuildChannelPositions(
        self: *GuildManager,
        guild_id: u64,
        positions: []struct { id: u64, position: ?i64, lock_permissions: ?bool, parent_id: ?u64 },
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/channels",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const json_payload = try std.json.stringifyAlloc(self.allocator, positions, .{});
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

    /// Get guild member
    pub fn getGuildMember(self: *GuildManager, guild_id: u64, user_id: u64) !models.GuildMember {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildMember, response.body, .{});
    }

    /// Add guild member
    pub fn addGuildMember(
        self: *GuildManager,
        guild_id: u64,
        user_id: u64,
        access_token: []const u8,
        nick: ?[]const u8,
        roles: ?[]u64,
        mute: ?bool,
        deaf: ?bool,
    ) !models.GuildMember {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = AddGuildMemberPayload{
            .access_token = access_token,
            .nick = nick,
            .roles = roles,
            .mute = mute,
            .deaf = deaf,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.put(url, json_payload);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildMember, response.body, .{});
    }

    /// Modify guild member
    pub fn modifyGuildMember(
        self: *GuildManager,
        guild_id: u64,
        user_id: u64,
        nick: ?[]const u8,
        roles: ?[]u64,
        mute: ?bool,
        deaf: ?bool,
        channel_id: ?u64,
        communication_disabled_until: ?[]const u8,
        reason: ?[]const u8,
    ) !models.GuildMember {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyGuildMemberPayload{
            .nick = nick,
            .roles = roles,
            .mute = mute,
            .deaf = deaf,
            .channel_id = channel_id,
            .communication_disabled_until = communication_disabled_until,
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

        return try std.json.parse(models.GuildMember, response.body, .{});
    }

    /// Modify current member nick
    pub fn modifyCurrentMemberNick(
        self: *GuildManager,
        guild_id: u64,
        nick: []const u8,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/@me/nick",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyCurrentMemberNickPayload{
            .nick = nick,
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
    }

    /// Add guild member role
    pub fn addGuildMemberRole(
        self: *GuildManager,
        guild_id: u64,
        user_id: u64,
        role_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}/roles/{d}",
            .{ self.client.base_url, guild_id, user_id, role_id },
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

    /// Remove guild member role
    pub fn removeGuildMemberRole(
        self: *GuildManager,
        guild_id: u64,
        user_id: u64,
        role_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}/roles/{d}",
            .{ self.client.base_url, guild_id, user_id, role_id },
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

    /// Remove guild member
    pub fn removeGuildMember(
        self: *GuildManager,
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

    /// Get guild bans
    pub fn getGuildBans(
        self: *GuildManager,
        guild_id: u64,
        limit: ?usize,
        before: ?u64,
        after: ?u64,
    ) ![]models.Ban {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/bans",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (limit) |l| {
            try params.append(try std.fmt.allocPrint(self.allocator, "limit={d}", .{l}));
        }
        if (before) |b| {
            try params.append(try std.fmt.allocPrint(self.allocator, "before={d}", .{b}));
        }
        if (after) |a| {
            try params.append(try std.fmt.allocPrint(self.allocator, "after={d}", .{a}));
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

        return try std.json.parse([]models.Ban, response.body, .{});
    }

    /// Get guild ban
    pub fn getGuildBan(self: *GuildManager, guild_id: u64, user_id: u64) !models.Ban {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/bans/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Ban, response.body, .{});
    }

    /// Create guild ban
    pub fn createGuildBan(
        self: *GuildManager,
        guild_id: u64,
        user_id: u64,
        delete_message_days: ?i64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/bans/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = CreateGuildBanPayload{
            .delete_message_days = delete_message_days,
            .reason = reason,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.put(url, json_payload);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Remove guild ban
    pub fn removeGuildBan(
        self: *GuildManager,
        guild_id: u64,
        user_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/bans/{d}",
            .{ self.client.base_url, guild_id, user_id },
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

    /// Get guild roles
    pub fn getGuildRoles(self: *GuildManager, guild_id: u64) ![]models.Role {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/roles",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Role, response.body, .{});
    }

    /// Create guild role
    pub fn createGuildRole(
        self: *GuildManager,
        guild_id: u64,
        name: ?[]const u8,
        color: ?u32,
        hoist: ?bool,
        icon: ?[]const u8,
        unicode_emoji: ?[]const u8,
        mentionable: ?bool,
        permissions: ?u64,
        reason: ?[]const u8,
    ) !models.Role {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/roles",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreateGuildRolePayload{
            .name = name,
            .color = color,
            .hoist = hoist,
            .icon = icon,
            .unicode_emoji = unicode_emoji,
            .mentionable = mentionable,
            .permissions = permissions,
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

        return try std.json.parse(models.Role, response.body, .{});
    }
};

// Payload structures
const CreateGuildPayload = struct {
    name: []const u8,
    icon: ?[]const u8 = null,
    verification_level: ?models.VerificationLevel = null,
    default_message_notifications: ?models.DefaultMessageNotificationLevel = null,
    explicit_content_filter: ?models.ExplicitContentFilterLevel = null,
    roles: ?[]models.Role = null,
    channels: ?[]models.Channel = null,
    afk_channel_id: ?u64 = null,
    afk_timeout: ?i64 = null,
    system_channel_id: ?u64 = null,
    system_channel_flags: ?u64 = null,
};

const ModifyGuildPayload = struct {
    name: ?[]const u8 = null,
    icon: ?[]const u8 = null,
    splash: ?[]const u8 = null,
    discovery_splash: ?[]const u8 = null,
    banner: ?[]const u8 = null,
    owner_id: ?u64 = null,
    afk_channel_id: ?u64 = null,
    afk_timeout: ?i64 = null,
    verification_level: ?models.VerificationLevel = null,
    default_message_notifications: ?models.DefaultMessageNotificationLevel = null,
    explicit_content_filter: ?models.ExplicitContentFilterLevel = null,
    rules_channel_id: ?u64 = null,
    public_updates_channel_id: ?u64 = null,
    preferred_locale: ?[]const u8 = null,
    features: ?[]models.GuildFeature = null,
    description: ?[]const u8 = null,
    premium_progress_bar_enabled: ?bool = null,
};

const CreateGuildChannelPayload = struct {
    name: []const u8,
    type: models.ChannelType,
    topic: ?[]const u8 = null,
    position: ?i64 = null,
    permission_overwrites: ?[]models.PermissionOverwrite = null,
    nsfw: ?bool = null,
    rate_limit_per_user: ?i64 = null,
    bitrate: ?i64 = null,
    user_limit: ?i64 = null,
    parent_id: ?u64 = null,
    rtc_region: ?[]const u8 = null,
    video_quality_mode: ?models.VideoQualityMode = null,
    default_auto_archive_duration: ?i64 = null,
};

const AddGuildMemberPayload = struct {
    access_token: []const u8,
    nick: ?[]const u8 = null,
    roles: ?[]u64 = null,
    mute: ?bool = null,
    deaf: ?bool = null,
};

const ModifyGuildMemberPayload = struct {
    nick: ?[]const u8 = null,
    roles: ?[]u64 = null,
    mute: ?bool = null,
    deaf: ?bool = null,
    channel_id: ?u64 = null,
    communication_disabled_until: ?[]const u8 = null,
};

const ModifyCurrentMemberNickPayload = struct {
    nick: []const u8,
};

const CreateGuildBanPayload = struct {
    delete_message_days: ?i64 = null,
    reason: ?[]const u8 = null,
};

const CreateGuildRolePayload = struct {
    name: ?[]const u8 = null,
    color: ?u32 = null,
    hoist: ?bool = null,
    icon: ?[]const u8 = null,
    unicode_emoji: ?[]const u8 = null,
    mentionable: ?bool = null,
    permissions: ?u64 = null,
};
