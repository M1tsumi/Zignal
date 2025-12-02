const std = @import("std");
const models = @import("models.zig");
const utils = @import("utils.zig");

pub const Cache = struct {
    allocator: std.mem.Allocator,
    guilds: std.hash_map.AutoHashMap(u64, models.Guild),
    channels: std.hash_map.AutoHashMap(u64, models.Channel),
    users: std.hash_map.AutoHashMap(u64, models.User),
    members: std.hash_map.AutoHashMap(u64, std.hash_map.AutoHashMap(u64, models.PartialGuildMember)),
    roles: std.hash_map.AutoHashMap(u64, std.hash_map.AutoHashMap(u64, models.Role)),
    messages: std.hash_map.AutoHashMap(u64, models.Message),
    max_size: usize,
    current_size: usize,

    pub fn init(allocator: std.mem.Allocator, max_size: usize) !*Cache {
        const cache = try allocator.create(Cache);
        cache.* = .{
            .allocator = allocator,
            .guilds = std.hash_map.AutoHashMap(u64, models.Guild).init(allocator),
            .channels = std.hash_map.AutoHashMap(u64, models.Channel).init(allocator),
            .users = std.hash_map.AutoHashMap(u64, models.User).init(allocator),
            .members = std.hash_map.AutoHashMap(u64, std.hash_map.AutoHashMap(u64, models.PartialGuildMember)).init(allocator),
            .roles = std.hash_map.AutoHashMap(u64, std.hash_map.AutoHashMap(u64, models.Role)).init(allocator),
            .messages = std.hash_map.AutoHashMap(u64, models.Message).init(allocator),
            .max_size = max_size,
            .current_size = 0,
        };
        return cache;
    }

    pub fn deinit(self: *Cache) void {
        var guild_iter = self.guilds.iterator();
        while (guild_iter.next()) |entry| {
            self.deinitGuild(entry.value_ptr.*);
        }
        self.guilds.deinit();

        var channel_iter = self.channels.iterator();
        while (channel_iter.next()) |entry| {
            self.deinitChannel(entry.value_ptr.*);
        }
        self.channels.deinit();

        var user_iter = self.users.iterator();
        while (user_iter.next()) |entry| {
            self.deinitUser(entry.value_ptr.*);
        }
        self.users.deinit();

        var members_iter = self.members.iterator();
        while (members_iter.next()) |entry| {
            var member_iter = entry.value_ptr.iterator();
            while (member_iter.next()) |member_entry| {
                self.deinitGuildMember(member_entry.value_ptr.*);
            }
            entry.value_ptr.deinit();
        }
        self.members.deinit();

        var roles_iter = self.roles.iterator();
        while (roles_iter.next()) |entry| {
            var role_iter = entry.value_ptr.iterator();
            while (role_iter.next()) |role_entry| {
                self.deinitRole(role_entry.value_ptr.*);
            }
            entry.value_ptr.deinit();
        }
        self.roles.deinit();

        var message_iter = self.messages.iterator();
        while (message_iter.next()) |entry| {
            self.deinitMessage(entry.value_ptr.*);
        }
        self.messages.deinit();

        self.allocator.destroy(self);
    }

    fn deinitGuild(self: *Cache, guild: models.Guild) void {
        self.allocator.free(guild.name);
        if (guild.icon) |icon| self.allocator.free(icon);
        if (guild.splash) |splash| self.allocator.free(splash);
        if (guild.discovery_splash) |ds| self.allocator.free(ds);
        if (guild.permissions) |p| self.allocator.free(p);
        if (guild.region) |r| self.allocator.free(r);
        if (guild.vanity_url_code) |v| self.allocator.free(v);
        if (guild.description) |d| self.allocator.free(d);
        if (guild.banner) |b| self.allocator.free(b);
        self.allocator.free(guild.preferred_locale);
        self.allocator.free(guild.roles);
        self.allocator.free(guild.emojis);
        self.allocator.free(guild.features);
        self.allocator.free(guild.stage_instances);
        self.allocator.free(guild.stickers);
        self.allocator.free(guild.guild_scheduled_events);
    }

    fn deinitChannel(self: *Cache, channel: models.Channel) void {
        if (channel.name) |name| self.allocator.free(name);
        if (channel.topic) |topic| self.allocator.free(topic);
        self.allocator.free(channel.permission_overwrites);
        self.allocator.free(channel.recipients);
        if (channel.icon) |icon| self.allocator.free(icon);
        if (channel.last_pin_timestamp) |lpt| self.allocator.free(lpt);
        if (channel.rtc_region) |rr| self.allocator.free(rr);
        if (channel.permissions) |p| self.allocator.free(p);
    }

    fn deinitUser(self: *Cache, user: models.User) void {
        self.allocator.free(user.username);
        self.allocator.free(user.discriminator);
        if (user.global_name) |gn| self.allocator.free(gn);
        if (user.avatar) |avatar| self.allocator.free(avatar);
        if (user.locale) |locale| self.allocator.free(locale);
        if (user.email) |email| self.allocator.free(email);
        if (user.avatar_decoration) |ad| self.allocator.free(ad);
    }

    fn deinitGuildMember(self: *Cache, member: models.PartialGuildMember) void {
        if (member.nick) |nick| self.allocator.free(nick);
        self.allocator.free(member.roles);
        if (member.joined_at) |ja| self.allocator.free(ja);
        if (member.premium_since) |ps| self.allocator.free(ps);
        if (member.permissions) |p| self.allocator.free(p);
    }

    fn deinitRole(self: *Cache, role: models.Role) void {
        self.allocator.free(role.name);
        self.allocator.free(role.permissions);
        if (role.icon) |icon| self.allocator.free(icon);
        if (role.unicode_emoji) |ue| self.allocator.free(ue);
    }

    fn deinitMessage(self: *Cache, message: models.Message) void {
        self.allocator.free(message.content);
        self.allocator.free(message.timestamp);
        if (message.edited_timestamp) |ett| self.allocator.free(ett);
        self.allocator.free(message.mentions);
        self.allocator.free(message.mention_roles);
        self.allocator.free(message.mention_channels);
        self.allocator.free(message.attachments);
        self.allocator.free(message.embeds);
        self.allocator.free(message.reactions);
        if (message.nonce) |nonce| self.allocator.free(nonce);
        self.allocator.free(message.components);
        self.allocator.free(message.sticker_items);
    }

    fn ensureCapacity(self: *Cache) !void {
        if (self.current_size >= self.max_size) {
            // Simple LRU: clear 25% of the cache
            const target_size = @divFloor(self.max_size * 3, 4);

            // Clear some messages first (they're most numerous)
            var message_iter = self.messages.iterator();
            var messages_to_remove: usize = 0;
            while (message_iter.next() != null and self.current_size > target_size) {
                messages_to_remove += 1;
            }

            for (0..messages_to_remove) |_| {
                if (self.messages.pop()) |entry| {
                    self.deinitMessage(entry.value);
                    self.current_size -= 1;
                }
            }
        }
    }

    // Guild operations
    pub fn getGuild(self: *Cache, guild_id: u64) ?models.Guild {
        if (self.guilds.get(guild_id)) |guild| {
            // Return a copy since the original might be modified
            return self.cloneGuild(guild);
        }
        return null;
    }

    pub fn setGuild(self: *Cache, guild: models.Guild) !void {
        try self.ensureCapacity();

        // Remove old entry if exists
        if (self.guilds.fetchRemove(guild.id)) |old_entry| {
            self.deinitGuild(old_entry.value);
            self.current_size -= 1;
        }

        const cloned = try self.cloneGuild(guild);
        try self.guilds.put(guild.id, cloned);
        self.current_size += 1;
    }

    pub fn removeGuild(self: *Cache, guild_id: u64) bool {
        if (self.guilds.fetchRemove(guild_id)) |entry| {
            self.deinitGuild(entry.value);
            self.current_size -= 1;
            return true;
        }
        return false;
    }

    // Channel operations
    pub fn getChannel(self: *Cache, channel_id: u64) ?models.Channel {
        if (self.channels.get(channel_id)) |channel| {
            return self.cloneChannel(channel);
        }
        return null;
    }

    pub fn setChannel(self: *Cache, channel: models.Channel) !void {
        try self.ensureCapacity();

        if (self.channels.fetchRemove(channel.id)) |old_entry| {
            self.deinitChannel(old_entry.value);
            self.current_size -= 1;
        }

        const cloned = try self.cloneChannel(channel);
        try self.channels.put(channel.id, cloned);
        self.current_size += 1;
    }

    pub fn removeChannel(self: *Cache, channel_id: u64) bool {
        if (self.channels.fetchRemove(channel_id)) |entry| {
            self.deinitChannel(entry.value);
            self.current_size -= 1;
            return true;
        }
        return false;
    }

    // User operations
    pub fn getUser(self: *Cache, user_id: u64) ?models.User {
        if (self.users.get(user_id)) |user| {
            return self.cloneUser(user);
        }
        return null;
    }

    pub fn setUser(self: *Cache, user: models.User) !void {
        try self.ensureCapacity();

        if (self.users.fetchRemove(user.id)) |old_entry| {
            self.deinitUser(old_entry.value);
            self.current_size -= 1;
        }

        const cloned = try self.cloneUser(user);
        try self.users.put(user.id, cloned);
        self.current_size += 1;
    }

    pub fn removeUser(self: *Cache, user_id: u64) bool {
        if (self.users.fetchRemove(user_id)) |entry| {
            self.deinitUser(entry.value);
            self.current_size -= 1;
            return true;
        }
        return false;
    }

    // Member operations
    pub fn getMember(self: *Cache, guild_id: u64, user_id: u64) ?models.PartialGuildMember {
        if (self.members.get(guild_id)) |guild_members| {
            if (guild_members.get(user_id)) |member| {
                return self.cloneGuildMember(member);
            }
        }
        return null;
    }

    pub fn setMember(self: *Cache, guild_id: u64, member: models.PartialGuildMember) !void {
        try self.ensureCapacity();

        const guild_members_entry = try self.members.getOrPut(guild_id);
        if (!guild_members_entry.found_existing) {
            guild_members_entry.value_ptr.* = std.hash_map.AutoHashMap(u64, models.PartialGuildMember).init(self.allocator);
        }

        const user_id = member.user.id;
        if (guild_members_entry.value_ptr.fetchRemove(user_id)) |old_entry| {
            self.deinitGuildMember(old_entry.value);
            self.current_size -= 1;
        }

        const cloned = try self.cloneGuildMember(member);
        try guild_members_entry.value_ptr.put(user_id, cloned);
        self.current_size += 1;
    }

    pub fn removeMember(self: *Cache, guild_id: u64, user_id: u64) bool {
        if (self.members.get(guild_id)) |guild_members| {
            if (guild_members.fetchRemove(user_id)) |entry| {
                self.deinitGuildMember(entry.value);
                self.current_size -= 1;
                return true;
            }
        }
        return false;
    }

    // Role operations
    pub fn getRole(self: *Cache, guild_id: u64, role_id: u64) ?models.Role {
        if (self.roles.get(guild_id)) |guild_roles| {
            if (guild_roles.get(role_id)) |role| {
                return self.cloneRole(role);
            }
        }
        return null;
    }

    pub fn setRole(self: *Cache, guild_id: u64, role: models.Role) !void {
        try self.ensureCapacity();

        const guild_roles_entry = try self.roles.getOrPut(guild_id);
        if (!guild_roles_entry.found_existing) {
            guild_roles_entry.value_ptr.* = std.hash_map.AutoHashMap(u64, models.Role).init(self.allocator);
        }

        const role_id = role.id;
        if (guild_roles_entry.value_ptr.fetchRemove(role_id)) |old_entry| {
            self.deinitRole(old_entry.value);
            self.current_size -= 1;
        }

        const cloned = try self.cloneRole(role);
        try guild_roles_entry.value_ptr.put(role_id, cloned);
        self.current_size += 1;
    }

    pub fn removeRole(self: *Cache, guild_id: u64, role_id: u64) bool {
        if (self.roles.get(guild_id)) |guild_roles| {
            if (guild_roles.fetchRemove(role_id)) |entry| {
                self.deinitRole(entry.value);
                self.current_size -= 1;
                return true;
            }
        }
        return false;
    }

    // Message operations (limited caching for messages)
    pub fn getMessage(self: *Cache, message_id: u64) ?models.Message {
        if (self.messages.get(message_id)) |message| {
            return self.cloneMessage(message);
        }
        return null;
    }

    pub fn setMessage(self: *Cache, message: models.Message) !void {
        try self.ensureCapacity();

        if (self.messages.fetchRemove(message.id)) |old_entry| {
            self.deinitMessage(old_entry.value);
            self.current_size -= 1;
        }

        const cloned = try self.cloneMessage(message);
        try self.messages.put(message.id, cloned);
        self.current_size += 1;
    }

    pub fn removeMessage(self: *Cache, message_id: u64) bool {
        if (self.messages.fetchRemove(message_id)) |entry| {
            self.deinitMessage(entry.value);
            self.current_size -= 1;
            return true;
        }
        return false;
    }

    // Clone helpers
    fn cloneGuild(self: *Cache, guild: models.Guild) !models.Guild {
        return models.Guild{
            .id = guild.id,
            .name = try self.allocator.dupe(u8, guild.name),
            .icon = if (guild.icon) |icon| try self.allocator.dupe(u8, icon) else null,
            .splash = if (guild.splash) |splash| try self.allocator.dupe(u8, splash) else null,
            .discovery_splash = if (guild.discovery_splash) |ds| try self.allocator.dupe(u8, ds) else null,
            .owner = guild.owner,
            .owner_id = guild.owner_id,
            .permissions = if (guild.permissions) |p| try self.allocator.dupe(u8, p) else null,
            .region = if (guild.region) |r| try self.allocator.dupe(u8, r) else null,
            .afk_channel_id = guild.afk_channel_id,
            .afk_timeout = guild.afk_timeout,
            .widget_enabled = guild.widget_enabled,
            .widget_channel_id = guild.widget_channel_id,
            .verification_level = guild.verification_level,
            .default_message_notifications = guild.default_message_notifications,
            .explicit_content_filter = guild.explicit_content_filter,
            .roles = try self.allocator.dupe(models.Role, guild.roles),
            .emojis = try self.allocator.dupe(models.Emoji, guild.emojis),
            .features = try self.allocator.dupe([]const u8, guild.features),
            .mfa_level = guild.mfa_level,
            .application_id = guild.application_id,
            .system_channel_id = guild.system_channel_id,
            .system_channel_flags = guild.system_channel_flags,
            .rules_channel_id = guild.rules_channel_id,
            .max_members = guild.max_members,
            .max_presences = guild.max_presences,
            .vanity_url_code = if (guild.vanity_url_code) |v| try self.allocator.dupe(u8, v) else null,
            .description = if (guild.description) |d| try self.allocator.dupe(u8, d) else null,
            .banner = if (guild.banner) |b| try self.allocator.dupe(u8, b) else null,
            .premium_tier = guild.premium_tier,
            .premium_subscription_count = guild.premium_subscription_count,
            .preferred_locale = try self.allocator.dupe(u8, guild.preferred_locale),
            .public_updates_channel_id = guild.public_updates_channel_id,
            .max_video_channel_users = guild.max_video_channel_users,
            .approximate_member_count = guild.approximate_member_count,
            .approximate_presence_count = guild.approximate_presence_count,
            .nsfw_level = guild.nsfw_level,
            .stage_instances = try self.allocator.dupe(models.StageInstance, guild.stage_instances),
            .stickers = try self.allocator.dupe(models.Sticker, guild.stickers),
            .guild_scheduled_events = try self.allocator.dupe(models.GuildScheduledEvent, guild.guild_scheduled_events),
        };
    }

    fn cloneChannel(self: *Cache, channel: models.Channel) !models.Channel {
        return models.Channel{
            .id = channel.id,
            .type = channel.type,
            .guild_id = channel.guild_id,
            .position = channel.position,
            .permission_overwrites = try self.allocator.dupe(models.PermissionOverwrite, channel.permission_overwrites),
            .name = if (channel.name) |name| try self.allocator.dupe(u8, name) else null,
            .topic = if (channel.topic) |topic| try self.allocator.dupe(u8, topic) else null,
            .nsfw = channel.nsfw,
            .last_message_id = channel.last_message_id,
            .bitrate = channel.bitrate,
            .user_limit = channel.user_limit,
            .rate_limit_per_user = channel.rate_limit_per_user,
            .recipients = try self.allocator.dupe(models.User, channel.recipients),
            .icon = if (channel.icon) |icon| try self.allocator.dupe(u8, icon) else null,
            .owner_id = channel.owner_id,
            .application_id = channel.application_id,
            .parent_id = channel.parent_id,
            .last_pin_timestamp = if (channel.last_pin_timestamp) |lpt| try self.allocator.dupe(u8, lpt) else null,
            .rtc_region = if (channel.rtc_region) |rr| try self.allocator.dupe(u8, rr) else null,
            .video_quality_mode = channel.video_quality_mode,
            .message_count = channel.message_count,
            .member_count = channel.member_count,
            .default_auto_archive_duration = channel.default_auto_archive_duration,
            .permissions = if (channel.permissions) |p| try self.allocator.dupe(u8, p) else null,
            .flags = channel.flags,
        };
    }

    fn cloneUser(self: *Cache, user: models.User) !models.User {
        return models.User{
            .id = user.id,
            .username = try self.allocator.dupe(u8, user.username),
            .discriminator = try self.allocator.dupe(u8, user.discriminator),
            .global_name = if (user.global_name) |gn| try self.allocator.dupe(u8, gn) else null,
            .avatar = if (user.avatar) |avatar| try self.allocator.dupe(u8, avatar) else null,
            .bot = user.bot,
            .system = user.system,
            .mfa_enabled = user.mfa_enabled,
            .banner = if (user.banner) |banner| try self.allocator.dupe(u8, banner) else null,
            .accent_color = user.accent_color,
            .locale = if (user.locale) |locale| try self.allocator.dupe(u8, locale) else null,
            .verified = user.verified,
            .email = if (user.email) |email| try self.allocator.dupe(u8, email) else null,
            .flags = user.flags,
            .premium_type = user.premium_type,
            .public_flags = user.public_flags,
            .avatar_decoration = user.avatar_decoration,
            .bio = if (user.bio) |bio| try self.allocator.dupe(u8, bio) else null,
        };
    }

    fn cloneGuildMember(self: *Cache, member: models.PartialGuildMember) !models.PartialGuildMember {
        return models.PartialGuildMember{
            .user = try self.cloneUser(member.user),
            .nick = if (member.nick) |nick| try self.allocator.dupe(u8, nick) else null,
            .roles = try self.allocator.dupe(u64, member.roles),
            .joined_at = try self.allocator.dupe(u8, member.joined_at),
            .premium_since = if (member.premium_since) |ps| try self.allocator.dupe(u8, ps) else null,
            .deaf = member.deaf,
            .mute = member.mute,
            .pending = member.pending,
            .permissions = if (member.permissions) |p| try self.allocator.dupe(u8, p) else null,
            .communication_disabled_until = if (member.communication_disabled_until) |cdu| try self.allocator.dupe(u8, cdu) else null,
        };
    }

    fn cloneRole(self: *Cache, role: models.Role) !models.Role {
        return models.Role{
            .id = role.id,
            .name = try self.allocator.dupe(u8, role.name),
            .color = role.color,
            .hoist = role.hoist,
            .position = role.position,
            .permissions = try self.allocator.dupe(u8, role.permissions),
            .managed = role.managed,
            .mentionable = role.mentionable,
            .icon = if (role.icon) |icon| try self.allocator.dupe(u8, icon) else null,
            .unicode_emoji = if (role.unicode_emoji) |ue| try self.allocator.dupe(u8, ue) else null,
        };
    }

    fn cloneMessage(self: *Cache, message: models.Message) !models.Message {
        return models.Message{
            .id = message.id,
            .channel_id = message.channel_id,
            .author = try self.cloneUser(message.author),
            .content = try self.allocator.dupe(u8, message.content),
            .timestamp = try self.allocator.dupe(u8, message.timestamp),
            .edited_timestamp = if (message.edited_timestamp) |ett| try self.allocator.dupe(u8, ett) else null,
            .tts = message.tts,
            .mention_everyone = message.mention_everyone,
            .mentions = try self.allocator.dupe(models.User, message.mentions),
            .mention_roles = try self.allocator.dupe(u64, message.mention_roles),
            .mention_channels = try self.allocator.dupe(models.ChannelMention, message.mention_channels),
            .attachments = try self.allocator.dupe(models.Attachment, message.attachments),
            .embeds = try self.allocator.dupe(models.Embed, message.embeds),
            .reactions = try self.allocator.dupe(models.Reaction, message.reactions),
            .nonce = if (message.nonce) |nonce| try self.allocator.dupe(u8, nonce) else null,
            .pinned = message.pinned,
            .webhook_id = message.webhook_id,
            .type = message.type,
            .activity = message.activity,
            .application = message.application,
            .message_reference = message.message_reference,
            .flags = message.flags,
            .referenced_message = message.referenced_message,
            .interaction = message.interaction,
            .thread = message.thread,
            .components = try self.allocator.dupe(models.Component, message.components),
            .sticker_items = try self.allocator.dupe(models.StickerItem, message.sticker_items),
            .position = message.position,
            .role_subscription_data = message.role_subscription_data,
        };
    }

    // Statistics
    pub fn getStats(self: *Cache) struct {
        guilds: usize,
        channels: usize,
        users: usize,
        members: usize,
        roles: usize,
        messages: usize,
        total: usize,
    } {
        var total_members: usize = 0;
        var members_iter = self.members.iterator();
        while (members_iter.next()) |entry| {
            total_members += entry.value_ptr.count();
        }

        var total_roles: usize = 0;
        var roles_iter = self.roles.iterator();
        while (roles_iter.next()) |entry| {
            total_roles += entry.value_ptr.count();
        }

        return .{
            .guilds = self.guilds.count(),
            .channels = self.channels.count(),
            .users = self.users.count(),
            .members = total_members,
            .roles = total_roles,
            .messages = self.messages.count(),
            .total = self.current_size,
        };
    }

    pub fn clear(self: *Cache) void {
        // Clear all caches
        var guild_iter = self.guilds.iterator();
        while (guild_iter.next()) |entry| {
            self.deinitGuild(entry.value_ptr.*);
        }
        self.guilds.clear();

        var channel_iter = self.channels.iterator();
        while (channel_iter.next()) |entry| {
            self.deinitChannel(entry.value_ptr.*);
        }
        self.channels.clear();

        var user_iter = self.users.iterator();
        while (user_iter.next()) |entry| {
            self.deinitUser(entry.value_ptr.*);
        }
        self.users.clear();

        var members_iter = self.members.iterator();
        while (members_iter.next()) |entry| {
            var member_iter = entry.value_ptr.iterator();
            while (member_iter.next()) |member_entry| {
                self.deinitGuildMember(member_entry.value_ptr.*);
            }
            entry.value_ptr.clear();
        }
        self.members.clear();

        var roles_iter = self.roles.iterator();
        while (roles_iter.next()) |entry| {
            var role_iter = entry.value_ptr.iterator();
            while (role_iter.next()) |role_entry| {
                self.deinitRole(role_entry.value_ptr.*);
            }
            entry.value_ptr.clear();
        }
        self.roles.clear();

        var message_iter = self.messages.iterator();
        while (message_iter.next()) |entry| {
            self.deinitMessage(entry.value_ptr.*);
        }
        self.messages.clear();

        self.current_size = 0;
    }
};
