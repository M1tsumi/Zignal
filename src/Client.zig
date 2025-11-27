const std = @import("std");
const models = @import("models.zig");

const DISCORD_API_BASE = "https://discord.com/api/v10";

pub const Client = struct {
    allocator: std.mem.Allocator,
    token: []const u8,
    http_client: std.http.Client,

    pub fn init(allocator: std.mem.Allocator, token: []const u8) Client {
        return Client{
            .allocator = allocator,
            .token = token,
            .http_client = std.http.Client{ .allocator = allocator },
        };
    }

    pub fn deinit(self: *Client) void {
        self.http_client.deinit();
    }

    fn makeRequest(self: *Client, method: std.http.Method, path: []const u8, headers: ?std.json.ObjectMap, body: ?[]const u8) !std.http.Client.Request {
        const url = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ DISCORD_API_BASE, path });
        defer self.allocator.free(url);

        var request = try self.http_client.open(method, try std.Uri.parse(url), .{
            .server_header_buffer_size = 1024,
            .max_response_headers = 64,
        });
        errdefer request.deinit();

        request.headers.append("Authorization", try std.fmt.allocPrint(self.allocator, "Bot {s}", .{self.token})) catch unreachable;
        request.headers.append("Content-Type", "application/json") catch unreachable;
        request.headers.append("User-Agent", "Zignal (https://github.com/M1tsumi/Zignal, 0.1.0)") catch unreachable;

        if (headers) |h| {
            var it = h.iterator();
            while (it.next()) |entry| {
                request.headers.append(entry.key_ptr.*, entry.value_ptr.*) catch unreachable;
            }
        }

        if (body) |b| {
            request.transfer_encoding = .{ .content_length = b.len };
            try request.send();
            try request.writeAll(b);
        } else {
            try request.send();
        }

        try request.finish();

        return request;
    }

    pub fn getCurrentUser(self: *Client) !models.User {
        var request = try self.makeRequest(.GET, "/users/@me", null, null);
        defer request.deinit();

        const body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        var parsed = try std.json.parseFromSlice(struct {
            id: u64,
            username: []const u8,
            discriminator: []const u8,
            global_name: ?[]const u8,
            avatar: ?[]const u8,
            bot: bool = false,
            system: bool = false,
            mfa_enabled: bool = false,
            locale: ?[]const u8,
            verified: bool = false,
            email: ?[]const u8,
            flags: ?u32,
            premium_type: ?u8,
            public_flags: ?u32,
            avatar_decoration: ?[]const u8,
        }, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        return models.User{
            .id = parsed.value.id,
            .username = try self.allocator.dupe(u8, parsed.value.username),
            .discriminator = try self.allocator.dupe(u8, parsed.value.discriminator),
            .global_name = if (parsed.value.global_name) |gn| try self.allocator.dupe(u8, gn) else null,
            .avatar = if (parsed.value.avatar) |a| try self.allocator.dupe(u8, a) else null,
            .bot = parsed.value.bot,
            .system = parsed.value.system,
            .mfa_enabled = parsed.value.mfa_enabled,
            .locale = if (parsed.value.locale) |l| try self.allocator.dupe(u8, l) else null,
            .verified = parsed.value.verified,
            .email = if (parsed.value.email) |e| try self.allocator.dupe(u8, e) else null,
            .flags = parsed.value.flags,
            .premium_type = parsed.value.premium_type,
            .public_flags = parsed.value.public_flags,
            .avatar_decoration = if (parsed.value.avatar_decoration) |ad| try self.allocator.dupe(u8, ad) else null,
        };
    }

    pub fn getGuilds(self: *Client) ![]models.Guild {
        var request = try self.makeRequest(.GET, "/users/@me/guilds", null, null);
        defer request.deinit();

        const body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        var parsed = try std.json.parseFromSlice([]struct {
            id: u64,
            name: []const u8,
            icon: ?[]const u8,
            splash: ?[]const u8,
            discovery_splash: ?[]const u8,
            owner: bool = false,
            owner_id: u64,
            permissions: ?[]const u8,
            region: ?[]const u8,
            afk_channel_id: ?u64,
            afk_timeout: u32,
            widget_enabled: bool = false,
            widget_channel_id: ?u64,
            verification_level: u8,
            default_message_notifications: u8,
            explicit_content_filter: u8,
            roles: []models.Role,
            emojis: []models.Emoji,
            features: []const []const u8,
            mfa_level: u8,
            application_id: ?u64,
            system_channel_id: ?u64,
            system_channel_flags: u32,
            rules_channel_id: ?u64,
            max_members: ?u32,
            max_presences: ?u32,
            vanity_url_code: ?[]const u8,
            description: ?[]const u8,
            banner: ?[]const u8,
            premium_tier: u8,
            premium_subscription_count: ?u32,
            preferred_locale: []const u8,
            public_updates_channel_id: ?u64,
            max_video_channel_users: ?u32,
            approximate_member_count: ?u32,
            approximate_presence_count: ?u32,
            nsfw_level: u8,
            stage_instances: []models.StageInstance,
            stickers: []models.Sticker,
            guild_scheduled_events: []models.GuildScheduledEvent,
        }, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        var guilds = try self.allocator.alloc(models.Guild, parsed.value.len);
        for (parsed.value, 0..) |guild_data, i| {
            guilds[i] = models.Guild{
                .id = guild_data.id,
                .name = try self.allocator.dupe(u8, guild_data.name),
                .icon = if (guild_data.icon) |icon| try self.allocator.dupe(u8, icon) else null,
                .splash = if (guild_data.splash) |splash| try self.allocator.dupe(u8, splash) else null,
                .discovery_splash = if (guild_data.discovery_splash) |ds| try self.allocator.dupe(u8, ds) else null,
                .owner = guild_data.owner,
                .owner_id = guild_data.owner_id,
                .permissions = if (guild_data.permissions) |p| try self.allocator.dupe(u8, p) else null,
                .region = if (guild_data.region) |r| try self.allocator.dupe(u8, r) else null,
                .afk_channel_id = guild_data.afk_channel_id,
                .afk_timeout = guild_data.afk_timeout,
                .widget_enabled = guild_data.widget_enabled,
                .widget_channel_id = guild_data.widget_channel_id,
                .verification_level = guild_data.verification_level,
                .default_message_notifications = guild_data.default_message_notifications,
                .explicit_content_filter = guild_data.explicit_content_filter,
                .roles = try self.allocator.dupe(models.Role, guild_data.roles),
                .emojis = try self.allocator.dupe(models.Emoji, guild_data.emojis),
                .features = try self.allocator.dupe([]const u8, guild_data.features),
                .mfa_level = guild_data.mfa_level,
                .application_id = guild_data.application_id,
                .system_channel_id = guild_data.system_channel_id,
                .system_channel_flags = guild_data.system_channel_flags,
                .rules_channel_id = guild_data.rules_channel_id,
                .max_members = guild_data.max_members,
                .max_presences = guild_data.max_presences,
                .vanity_url_code = if (guild_data.vanity_url_code) |v| try self.allocator.dupe(u8, v) else null,
                .description = if (guild_data.description) |d| try self.allocator.dupe(u8, d) else null,
                .banner = if (guild_data.banner) |b| try self.allocator.dupe(u8, b) else null,
                .premium_tier = guild_data.premium_tier,
                .premium_subscription_count = guild_data.premium_subscription_count,
                .preferred_locale = try self.allocator.dupe(u8, guild_data.preferred_locale),
                .public_updates_channel_id = guild_data.public_updates_channel_id,
                .max_video_channel_users = guild_data.max_video_channel_users,
                .approximate_member_count = guild_data.approximate_member_count,
                .approximate_presence_count = guild_data.approximate_presence_count,
                .nsfw_level = guild_data.nsfw_level,
                .stage_instances = try self.allocator.dupe(models.StageInstance, guild_data.stage_instances),
                .stickers = try self.allocator.dupe(models.Sticker, guild_data.stickers),
                .guild_scheduled_events = try self.allocator.dupe(models.GuildScheduledEvent, guild_data.guild_scheduled_events),
            };
        }

        return guilds;
    }

    pub fn getChannel(self: *Client, channel_id: u64) !models.Channel {
        const path = try std.fmt.allocPrint(self.allocator, "/channels/{d}", .{channel_id});
        defer self.allocator.free(path);

        var request = try self.makeRequest(.GET, path, null, null);
        defer request.deinit();

        const body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        var parsed = try std.json.parseFromSlice(struct {
            id: u64,
            type: u8,
            guild_id: ?u64,
            position: ?u32,
            permission_overwrites: []models.PermissionOverwrite,
            name: ?[]const u8,
            topic: ?[]const u8,
            nsfw: bool = false,
            last_message_id: ?u64,
            bitrate: ?u32,
            user_limit: ?u32,
            rate_limit_per_user: ?u32,
            recipients: []models.User,
            icon: ?[]const u8,
            owner_id: ?u64,
            application_id: ?u64,
            parent_id: ?u64,
            last_pin_timestamp: ?[]const u8,
            rtc_region: ?[]const u8,
            video_quality_mode: ?u8,
            message_count: ?u32,
            member_count: ?u32,
            default_auto_archive_duration: ?u32,
            permissions: ?[]const u8,
            flags: ?u32,
        }, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        return models.Channel{
            .id = parsed.value.id,
            .type = parsed.value.type,
            .guild_id = parsed.value.guild_id,
            .position = parsed.value.position,
            .permission_overwrites = try self.allocator.dupe(models.PermissionOverwrite, parsed.value.permission_overwrites),
            .name = if (parsed.value.name) |n| try self.allocator.dupe(u8, n) else null,
            .topic = if (parsed.value.topic) |t| try self.allocator.dupe(u8, t) else null,
            .nsfw = parsed.value.nsfw,
            .last_message_id = parsed.value.last_message_id,
            .bitrate = parsed.value.bitrate,
            .user_limit = parsed.value.user_limit,
            .rate_limit_per_user = parsed.value.rate_limit_per_user,
            .recipients = try self.allocator.dupe(models.User, parsed.value.recipients),
            .icon = if (parsed.value.icon) |i| try self.allocator.dupe(u8, i) else null,
            .owner_id = parsed.value.owner_id,
            .application_id = parsed.value.application_id,
            .parent_id = parsed.value.parent_id,
            .last_pin_timestamp = if (parsed.value.last_pin_timestamp) |l| try self.allocator.dupe(u8, l) else null,
            .rtc_region = if (parsed.value.rtc_region) |r| try self.allocator.dupe(u8, r) else null,
            .video_quality_mode = parsed.value.video_quality_mode,
            .message_count = parsed.value.message_count,
            .member_count = parsed.value.member_count,
            .default_auto_archive_duration = parsed.value.default_auto_archive_duration,
            .permissions = if (parsed.value.permissions) |p| try self.allocator.dupe(u8, p) else null,
            .flags = parsed.value.flags,
        };
    }

    pub fn createMessage(self: *Client, channel_id: u64, content: []const u8, embeds: ?[]models.Embed) !models.Message {
        const path = try std.fmt.allocPrint(self.allocator, "/channels/{d}/messages", .{channel_id});
        defer self.allocator.free(path);

        const message_data = std.json.ObjectMap.init(self.allocator);
        defer message_data.deinit();

        try message_data.put("content", std.json.Value{ .string = content });

        if (embeds) |e| {
            var embed_array = std.json.ValueArray.init(self.allocator);
            defer embed_array.deinit();

            for (e) |embed| {
                var embed_obj = std.json.ObjectMap.init(self.allocator);
                defer embed_obj.deinit();

                if (embed.title) |title| try embed_obj.put("title", std.json.Value{ .string = title });
                if (embed.description) |desc| try embed_obj.put("description", std.json.Value{ .string = desc });
                if (embed.url) |url| try embed_obj.put("url", std.json.Value{ .string = url });
                if (embed.color) |color| try embed_obj.put("color", std.json.Value{ .integer = @intCast(color) });

                try embed_array.append(std.json.Value{ .object = embed_obj });
            }

            try message_data.put("embeds", std.json.Value{ .array = embed_array });
        }

        const json_string = try std.json.stringifyAlloc(self.allocator, message_data, .{});
        defer self.allocator.free(json_string);

        var request = try self.makeRequest(.POST, path, null, json_string);
        defer request.deinit();

        const response_body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(response_body);

        var parsed = try std.json.parseFromSlice(struct {
            id: u64,
            channel_id: u64,
            author: models.User,
            content: []const u8,
            timestamp: []const u8,
            edited_timestamp: ?[]const u8,
            tts: bool = false,
            mention_everyone: bool = false,
            mentions: []models.User,
            mention_roles: []u64,
            mention_channels: []models.ChannelMention,
            attachments: []models.Attachment,
            embeds: []models.Embed,
            reactions: []models.Reaction,
            nonce: ?[]const u8,
            pinned: bool = false,
            webhook_id: ?u64,
            type: u8,
            activity: ?models.MessageActivity,
            application: ?models.MessageApplication,
            message_reference: ?models.MessageReference,
            flags: ?u32,
            referenced_message: ?models.Message,
            interaction: ?models.MessageInteraction,
            thread: ?models.Channel,
            components: []models.Component,
            sticker_items: []models.StickerItem,
            position: ?u32,
            role_subscription_data: ?models.RoleSubscriptionData,
        }, self.allocator, response_body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        return models.Message{
            .id = parsed.value.id,
            .channel_id = parsed.value.channel_id,
            .author = parsed.value.author,
            .content = try self.allocator.dupe(u8, parsed.value.content),
            .timestamp = try self.allocator.dupe(u8, parsed.value.timestamp),
            .edited_timestamp = if (parsed.value.edited_timestamp) |et| try self.allocator.dupe(u8, et) else null,
            .tts = parsed.value.tts,
            .mention_everyone = parsed.value.mention_everyone,
            .mentions = try self.allocator.dupe(models.User, parsed.value.mentions),
            .mention_roles = try self.allocator.dupe(u64, parsed.value.mention_roles),
            .mention_channels = try self.allocator.dupe(models.ChannelMention, parsed.value.mention_channels),
            .attachments = try self.allocator.dupe(models.Attachment, parsed.value.attachments),
            .embeds = try self.allocator.dupe(models.Embed, parsed.value.embeds),
            .reactions = try self.allocator.dupe(models.Reaction, parsed.value.reactions),
            .nonce = if (parsed.value.nonce) |n| try self.allocator.dupe(u8, n) else null,
            .pinned = parsed.value.pinned,
            .webhook_id = parsed.value.webhook_id,
            .type = parsed.value.type,
            .activity = parsed.value.activity,
            .application = parsed.value.application,
            .message_reference = parsed.value.message_reference,
            .flags = parsed.value.flags,
            .referenced_message = parsed.value.referenced_message,
            .interaction = parsed.value.interaction,
            .thread = parsed.value.thread,
            .components = try self.allocator.dupe(models.Component, parsed.value.components),
            .sticker_items = try self.allocator.dupe(models.StickerItem, parsed.value.sticker_items),
            .position = parsed.value.position,
            .role_subscription_data = parsed.value.role_subscription_data,
        };
    }

    pub fn deleteMessage(self: *Client, channel_id: u64, message_id: u64) !void {
        const path = try std.fmt.allocPrint(self.allocator, "/channels/{d}/messages/{d}", .{ channel_id, message_id });
        defer self.allocator.free(path);

        var request = try self.makeRequest(.DELETE, path, null, null);
        defer request.deinit();

        _ = try request.readAllAlloc(self.allocator, 1024);
    }

    pub fn editMessage(self: *Client, channel_id: u64, message_id: u64, content: []const u8, embeds: ?[]models.Embed) !models.Message {
        const path = try std.fmt.allocPrint(self.allocator, "/channels/{d}/messages/{d}", .{ channel_id, message_id });
        defer self.allocator.free(path);

        const message_data = std.json.ObjectMap.init(self.allocator);
        defer message_data.deinit();

        try message_data.put("content", std.json.Value{ .string = content });

        if (embeds) |e| {
            var embed_array = std.json.ValueArray.init(self.allocator);
            defer embed_array.deinit();

            for (e) |embed| {
                var embed_obj = std.json.ObjectMap.init(self.allocator);
                defer embed_obj.deinit();

                if (embed.title) |title| try embed_obj.put("title", std.json.Value{ .string = title });
                if (embed.description) |desc| try embed_obj.put("description", std.json.Value{ .string = desc });
                if (embed.url) |url| try embed_obj.put("url", std.json.Value{ .string = url });
                if (embed.color) |color| try embed_obj.put("color", std.json.Value{ .integer = @intCast(color) });

                try embed_array.append(std.json.Value{ .object = embed_obj });
            }

            try message_data.put("embeds", std.json.Value{ .array = embed_array });
        }

        const json_string = try std.json.stringifyAlloc(self.allocator, message_data, .{});
        defer self.allocator.free(json_string);

        var request = try self.makeRequest(.PATCH, path, null, json_string);
        defer request.deinit();

        const response_body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(response_body);

        var parsed = try std.json.parseFromSlice(struct {
            id: u64,
            channel_id: u64,
            author: models.User,
            content: []const u8,
            timestamp: []const u8,
            edited_timestamp: ?[]const u8,
            tts: bool = false,
            mention_everyone: bool = false,
            mentions: []models.User,
            mention_roles: []u64,
            mention_channels: []models.ChannelMention,
            attachments: []models.Attachment,
            embeds: []models.Embed,
            reactions: []models.Reaction,
            nonce: ?[]const u8,
            pinned: bool = false,
            webhook_id: ?u64,
            type: u8,
            activity: ?models.MessageActivity,
            application: ?models.MessageApplication,
            message_reference: ?models.MessageReference,
            flags: ?u32,
            referenced_message: ?models.Message,
            interaction: ?models.MessageInteraction,
            thread: ?models.Channel,
            components: []models.Component,
            sticker_items: []models.StickerItem,
            position: ?u32,
            role_subscription_data: ?models.RoleSubscriptionData,
        }, self.allocator, response_body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        return models.Message{
            .id = parsed.value.id,
            .channel_id = parsed.value.channel_id,
            .author = parsed.value.author,
            .content = try self.allocator.dupe(u8, parsed.value.content),
            .timestamp = try self.allocator.dupe(u8, parsed.value.timestamp),
            .edited_timestamp = if (parsed.value.edited_timestamp) |et| try self.allocator.dupe(u8, et) else null,
            .tts = parsed.value.tts,
            .mention_everyone = parsed.value.mention_everyone,
            .mentions = try self.allocator.dupe(models.User, parsed.value.mentions),
            .mention_roles = try self.allocator.dupe(u64, parsed.value.mention_roles),
            .mention_channels = try self.allocator.dupe(models.ChannelMention, parsed.value.mention_channels),
            .attachments = try self.allocator.dupe(models.Attachment, parsed.value.attachments),
            .embeds = try self.allocator.dupe(models.Embed, parsed.value.embeds),
            .reactions = try self.allocator.dupe(models.Reaction, parsed.value.reactions),
            .nonce = if (parsed.value.nonce) |n| try self.allocator.dupe(u8, n) else null,
            .pinned = parsed.value.pinned,
            .webhook_id = parsed.value.webhook_id,
            .type = parsed.value.type,
            .activity = parsed.value.activity,
            .application = parsed.value.application,
            .message_reference = parsed.value.message_reference,
            .flags = parsed.value.flags,
            .referenced_message = parsed.value.referenced_message,
            .interaction = parsed.value.interaction,
            .thread = parsed.value.thread,
            .components = try self.allocator.dupe(models.Component, parsed.value.components),
            .sticker_items = try self.allocator.dupe(models.StickerItem, parsed.value.sticker_items),
            .position = parsed.value.position,
            .role_subscription_data = parsed.value.role_subscription_data,
        };
    }

    pub fn getGuild(self: *Client, guild_id: u64) !models.Guild {
        const path = try std.fmt.allocPrint(self.allocator, "/guilds/{d}", .{guild_id});
        defer self.allocator.free(path);

        var request = try self.makeRequest(.GET, path, null, null);
        defer request.deinit();

        const body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        var parsed = try std.json.parseFromSlice(struct {
            id: u64,
            name: []const u8,
            icon: ?[]const u8,
            splash: ?[]const u8,
            discovery_splash: ?[]const u8,
            owner: bool = false,
            owner_id: u64,
            permissions: ?[]const u8,
            region: ?[]const u8,
            afk_channel_id: ?u64,
            afk_timeout: u32,
            widget_enabled: bool = false,
            widget_channel_id: ?u64,
            verification_level: u8,
            default_message_notifications: u8,
            explicit_content_filter: u8,
            roles: []models.Role,
            emojis: []models.Emoji,
            features: []const []const u8,
            mfa_level: u8,
            application_id: ?u64,
            system_channel_id: ?u64,
            system_channel_flags: u32,
            rules_channel_id: ?u64,
            max_members: ?u32,
            max_presences: ?u32,
            vanity_url_code: ?[]const u8,
            description: ?[]const u8,
            banner: ?[]const u8,
            premium_tier: u8,
            premium_subscription_count: ?u32,
            preferred_locale: []const u8,
            public_updates_channel_id: ?u64,
            max_video_channel_users: ?u32,
            approximate_member_count: ?u32,
            approximate_presence_count: ?u32,
            nsfw_level: u8,
            stage_instances: []models.StageInstance,
            stickers: []models.Sticker,
            guild_scheduled_events: []models.GuildScheduledEvent,
        }, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        return models.Guild{
            .id = parsed.value.id,
            .name = try self.allocator.dupe(u8, parsed.value.name),
            .icon = if (parsed.value.icon) |icon| try self.allocator.dupe(u8, icon) else null,
            .splash = if (parsed.value.splash) |splash| try self.allocator.dupe(u8, splash) else null,
            .discovery_splash = if (parsed.value.discovery_splash) |ds| try self.allocator.dupe(u8, ds) else null,
            .owner = parsed.value.owner,
            .owner_id = parsed.value.owner_id,
            .permissions = if (parsed.value.permissions) |p| try self.allocator.dupe(u8, p) else null,
            .region = if (parsed.value.region) |r| try self.allocator.dupe(u8, r) else null,
            .afk_channel_id = parsed.value.afk_channel_id,
            .afk_timeout = parsed.value.afk_timeout,
            .widget_enabled = parsed.value.widget_enabled,
            .widget_channel_id = parsed.value.widget_channel_id,
            .verification_level = parsed.value.verification_level,
            .default_message_notifications = parsed.value.default_message_notifications,
            .explicit_content_filter = parsed.value.explicit_content_filter,
            .roles = try self.allocator.dupe(models.Role, parsed.value.roles),
            .emojis = try self.allocator.dupe(models.Emoji, parsed.value.emojis),
            .features = try self.allocator.dupe([]const u8, parsed.value.features),
            .mfa_level = parsed.value.mfa_level,
            .application_id = parsed.value.application_id,
            .system_channel_id = parsed.value.system_channel_id,
            .system_channel_flags = parsed.value.system_channel_flags,
            .rules_channel_id = parsed.value.rules_channel_id,
            .max_members = parsed.value.max_members,
            .max_presences = parsed.value.max_presences,
            .vanity_url_code = if (parsed.value.vanity_url_code) |v| try self.allocator.dupe(u8, v) else null,
            .description = if (parsed.value.description) |d| try self.allocator.dupe(u8, d) else null,
            .banner = if (parsed.value.banner) |b| try self.allocator.dupe(u8, b) else null,
            .premium_tier = parsed.value.premium_tier,
            .premium_subscription_count = parsed.value.premium_subscription_count,
            .preferred_locale = try self.allocator.dupe(u8, parsed.value.preferred_locale),
            .public_updates_channel_id = parsed.value.public_updates_channel_id,
            .max_video_channel_users = parsed.value.max_video_channel_users,
            .approximate_member_count = parsed.value.approximate_member_count,
            .approximate_presence_count = parsed.value.approximate_presence_count,
            .nsfw_level = parsed.value.nsfw_level,
            .stage_instances = try self.allocator.dupe(models.StageInstance, parsed.value.stage_instances),
            .stickers = try self.allocator.dupe(models.Sticker, parsed.value.stickers),
            .guild_scheduled_events = try self.allocator.dupe(models.GuildScheduledEvent, parsed.value.guild_scheduled_events),
        };
    }

    pub fn getGuildChannels(self: *Client, guild_id: u64) ![]models.Channel {
        const path = try std.fmt.allocPrint(self.allocator, "/guilds/{d}/channels", .{guild_id});
        defer self.allocator.free(path);

        var request = try self.makeRequest(.GET, path, null, null);
        defer request.deinit();

        const body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        var parsed = try std.json.parseFromSlice([]struct {
            id: u64,
            type: u8,
            guild_id: ?u64,
            position: ?u32,
            permission_overwrites: []models.PermissionOverwrite,
            name: ?[]const u8,
            topic: ?[]const u8,
            nsfw: bool = false,
            last_message_id: ?u64,
            bitrate: ?u32,
            user_limit: ?u32,
            rate_limit_per_user: ?u32,
            recipients: []models.User,
            icon: ?[]const u8,
            owner_id: ?u64,
            application_id: ?u64,
            parent_id: ?u64,
            last_pin_timestamp: ?[]const u8,
            rtc_region: ?[]const u8,
            video_quality_mode: ?u8,
            message_count: ?u32,
            member_count: ?u32,
            default_auto_archive_duration: ?u32,
            permissions: ?[]const u8,
            flags: ?u32,
        }, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        var channels = try self.allocator.alloc(models.Channel, parsed.value.len);
        for (parsed.value, 0..) |channel_data, i| {
            channels[i] = models.Channel{
                .id = channel_data.id,
                .type = channel_data.type,
                .guild_id = channel_data.guild_id,
                .position = channel_data.position,
                .permission_overwrites = try self.allocator.dupe(models.PermissionOverwrite, channel_data.permission_overwrites),
                .name = if (channel_data.name) |n| try self.allocator.dupe(u8, n) else null,
                .topic = if (channel_data.topic) |t| try self.allocator.dupe(u8, t) else null,
                .nsfw = channel_data.nsfw,
                .last_message_id = channel_data.last_message_id,
                .bitrate = channel_data.bitrate,
                .user_limit = channel_data.user_limit,
                .rate_limit_per_user = channel_data.rate_limit_per_user,
                .recipients = try self.allocator.dupe(models.User, channel_data.recipients),
                .icon = if (channel_data.icon) |i| try self.allocator.dupe(u8, i) else null,
                .owner_id = channel_data.owner_id,
                .application_id = channel_data.application_id,
                .parent_id = channel_data.parent_id,
                .last_pin_timestamp = if (channel_data.last_pin_timestamp) |l| try self.allocator.dupe(u8, l) else null,
                .rtc_region = if (channel_data.rtc_region) |r| try self.allocator.dupe(u8, r) else null,
                .video_quality_mode = channel_data.video_quality_mode,
                .message_count = channel_data.message_count,
                .member_count = channel_data.member_count,
                .default_auto_archive_duration = channel_data.default_auto_archive_duration,
                .permissions = if (channel_data.permissions) |p| try self.allocator.dupe(u8, p) else null,
                .flags = channel_data.flags,
            };
        }

        return channels;
    }

    pub fn createGuildChannel(self: *Client, guild_id: u64, name: []const u8, channel_type: u8, topic: ?[]const u8) !models.Channel {
        const path = try std.fmt.allocPrint(self.allocator, "/guilds/{d}/channels", .{guild_id});
        defer self.allocator.free(path);

        const channel_data = std.json.ObjectMap.init(self.allocator);
        defer channel_data.deinit();

        try channel_data.put("name", std.json.Value{ .string = name });
        try channel_data.put("type", std.json.Value{ .integer = channel_type });

        if (topic) |t| {
            try channel_data.put("topic", std.json.Value{ .string = t });
        }

        const json_string = try std.json.stringifyAlloc(self.allocator, channel_data, .{});
        defer self.allocator.free(json_string);

        var request = try self.makeRequest(.POST, path, null, json_string);
        defer request.deinit();

        const response_body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(response_body);

        var parsed = try std.json.parseFromSlice(struct {
            id: u64,
            type: u8,
            guild_id: ?u64,
            position: ?u32,
            permission_overwrites: []models.PermissionOverwrite,
            name: ?[]const u8,
            topic: ?[]const u8,
            nsfw: bool = false,
            last_message_id: ?u64,
            bitrate: ?u32,
            user_limit: ?u32,
            rate_limit_per_user: ?u32,
            recipients: []models.User,
            icon: ?[]const u8,
            owner_id: ?u64,
            application_id: ?u64,
            parent_id: ?u64,
            last_pin_timestamp: ?[]const u8,
            rtc_region: ?[]const u8,
            video_quality_mode: ?u8,
            message_count: ?u32,
            member_count: ?u32,
            default_auto_archive_duration: ?u32,
            permissions: ?[]const u8,
            flags: ?u32,
        }, self.allocator, response_body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        return models.Channel{
            .id = parsed.value.id,
            .type = parsed.value.type,
            .guild_id = parsed.value.guild_id,
            .position = parsed.value.position,
            .permission_overwrites = try self.allocator.dupe(models.PermissionOverwrite, parsed.value.permission_overwrites),
            .name = if (parsed.value.name) |n| try self.allocator.dupe(u8, n) else null,
            .topic = if (parsed.value.topic) |t| try self.allocator.dupe(u8, t) else null,
            .nsfw = parsed.value.nsfw,
            .last_message_id = parsed.value.last_message_id,
            .bitrate = parsed.value.bitrate,
            .user_limit = parsed.value.user_limit,
            .rate_limit_per_user = parsed.value.rate_limit_per_user,
            .recipients = try self.allocator.dupe(models.User, parsed.value.recipients),
            .icon = if (parsed.value.icon) |i| try self.allocator.dupe(u8, i) else null,
            .owner_id = parsed.value.owner_id,
            .application_id = parsed.value.application_id,
            .parent_id = parsed.value.parent_id,
            .last_pin_timestamp = if (parsed.value.last_pin_timestamp) |l| try self.allocator.dupe(u8, l) else null,
            .rtc_region = if (parsed.value.rtc_region) |r| try self.allocator.dupe(u8, r) else null,
            .video_quality_mode = parsed.value.video_quality_mode,
            .message_count = parsed.value.message_count,
            .member_count = parsed.value.member_count,
            .default_auto_archive_duration = parsed.value.default_auto_archive_duration,
            .permissions = if (parsed.value.permissions) |p| try self.allocator.dupe(u8, p) else null,
            .flags = parsed.value.flags,
        };
    }

    pub fn getChannelMessages(self: *Client, channel_id: u64, limit: ?u32, around: ?u64, before: ?u64, after: ?u64) ![]models.Message {
        var path_buffer: [100]u8 = undefined;
        var path_stream = std.io.fixedBufferStream(&path_buffer);
        const writer = path_stream.writer();

        try writer.print("/channels/{d}/messages", .{channel_id});
        
        var first_param = true;
        const addParam = struct {
            fn add(w: anytype, first: *bool, name: []const u8, value: anytype) !void {
                if (first.*) {
                    try w.print("?{s}={}", .{ name, value });
                    first.* = false;
                } else {
                    try w.print("&{s}={}", .{ name, value });
                }
            }
        }.add;

        if (limit) |l| try addParam(writer, &first_param, "limit", l);
        if (around) |a| try addParam(writer, &first_param, "around", a);
        if (before) |b| try addParam(writer, &first_param, "before", b);
        if (after) |a| try addParam(writer, &first_param, "after", a);

        const path = try self.allocator.dupe(u8, path_stream.getWritten());
        defer self.allocator.free(path);

        var request = try self.makeRequest(.GET, path, null, null);
        defer request.deinit();

        const body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        var parsed = try std.json.parseFromSlice([]struct {
            id: u64,
            channel_id: u64,
            author: models.User,
            content: []const u8,
            timestamp: []const u8,
            edited_timestamp: ?[]const u8,
            tts: bool = false,
            mention_everyone: bool = false,
            mentions: []models.User,
            mention_roles: []u64,
            mention_channels: []models.ChannelMention,
            attachments: []models.Attachment,
            embeds: []models.Embed,
            reactions: []models.Reaction,
            nonce: ?[]const u8,
            pinned: bool = false,
            webhook_id: ?u64,
            type: u8,
            activity: ?models.MessageActivity,
            application: ?models.MessageApplication,
            message_reference: ?models.MessageReference,
            flags: ?u32,
            referenced_message: ?models.Message,
            interaction: ?models.MessageInteraction,
            thread: ?models.Channel,
            components: []models.Component,
            sticker_items: []models.StickerItem,
            position: ?u32,
            role_subscription_data: ?models.RoleSubscriptionData,
        }, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        var messages = try self.allocator.alloc(models.Message, parsed.value.len);
        for (parsed.value, 0..) |message_data, i| {
            messages[i] = models.Message{
                .id = message_data.id,
                .channel_id = message_data.channel_id,
                .author = message_data.author,
                .content = try self.allocator.dupe(u8, message_data.content),
                .timestamp = try self.allocator.dupe(u8, message_data.timestamp),
                .edited_timestamp = if (message_data.edited_timestamp) |et| try self.allocator.dupe(u8, et) else null,
                .tts = message_data.tts,
                .mention_everyone = message_data.mention_everyone,
                .mentions = try self.allocator.dupe(models.User, message_data.mentions),
                .mention_roles = try self.allocator.dupe(u64, message_data.mention_roles),
                .mention_channels = try self.allocator.dupe(models.ChannelMention, message_data.mention_channels),
                .attachments = try self.allocator.dupe(models.Attachment, message_data.attachments),
                .embeds = try self.allocator.dupe(models.Embed, message_data.embeds),
                .reactions = try self.allocator.dupe(models.Reaction, message_data.reactions),
                .nonce = if (message_data.nonce) |n| try self.allocator.dupe(u8, n) else null,
                .pinned = message_data.pinned,
                .webhook_id = message_data.webhook_id,
                .type = message_data.type,
                .activity = message_data.activity,
                .application = message_data.application,
                .message_reference = message_data.message_reference,
                .flags = message_data.flags,
                .referenced_message = message_data.referenced_message,
                .interaction = message_data.interaction,
                .thread = message_data.thread,
                .components = try self.allocator.dupe(models.Component, message_data.components),
                .sticker_items = try self.allocator.dupe(models.StickerItem, message_data.sticker_items),
                .position = message_data.position,
                .role_subscription_data = message_data.role_subscription_data,
            };
        }

        return messages;
    }

    pub fn addReaction(self: *Client, channel_id: u64, message_id: u64, emoji: []const u8) !void {
        const path = try std.fmt.allocPrint(self.allocator, "/channels/{d}/messages/{d}/reactions/{s}/@me", .{ channel_id, message_id, emoji });
        defer self.allocator.free(path);

        var request = try self.makeRequest(.PUT, path, null, null);
        defer request.deinit();

        _ = try request.readAllAlloc(self.allocator, 1024);
    }

    pub fn deleteOwnReaction(self: *Client, channel_id: u64, message_id: u64, emoji: []const u8) !void {
        const path = try std.fmt.allocPrint(self.allocator, "/channels/{d}/messages/{d}/reactions/{s}/@me", .{ channel_id, message_id, emoji });
        defer self.allocator.free(path);

        var request = try self.makeRequest(.DELETE, path, null, null);
        defer request.deinit();

        _ = try request.readAllAlloc(self.allocator, 1024);
    }

    pub fn triggerTyping(self: *Client, channel_id: u64) !void {
        const path = try std.fmt.allocPrint(self.allocator, "/channels/{d}/typing", .{channel_id});
        defer self.allocator.free(path);

        var request = try self.makeRequest(.POST, path, null, "");
        defer request.deinit();

        _ = try request.readAllAlloc(self.allocator, 1024);
    }

    pub fn getGuildRoles(self: *Client, guild_id: u64) ![]models.Role {
        const path = try std.fmt.allocPrint(self.allocator, "/guilds/{d}/roles", .{guild_id});
        defer self.allocator.free(path);

        var request = try self.makeRequest(.GET, path, null, null);
        defer request.deinit();

        const body = try request.readAllAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(body);

        var parsed = try std.json.parseFromSlice([]struct {
            id: u64,
            name: []const u8,
            color: u32,
            hoist: bool = false,
            position: u32,
            permissions: []const u8,
            managed: bool = false,
            mentionable: bool = false,
            icon: ?[]const u8,
            unicode_emoji: ?[]const u8,
        }, self.allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        var roles = try self.allocator.alloc(models.Role, parsed.value.len);
        for (parsed.value, 0..) |role_data, i| {
            roles[i] = models.Role{
                .id = role_data.id,
                .name = try self.allocator.dupe(u8, role_data.name),
                .color = role_data.color,
                .hoist = role_data.hoist,
                .position = role_data.position,
                .permissions = try self.allocator.dupe(u8, role_data.permissions),
                .managed = role_data.managed,
                .mentionable = role_data.mentionable,
                .icon = if (role_data.icon) |icon| try self.allocator.dupe(u8, icon) else null,
                .unicode_emoji = if (role_data.unicode_emoji) |emoji| try self.allocator.dupe(u8, emoji) else null,
            };
        }

        return roles;
    }
};
