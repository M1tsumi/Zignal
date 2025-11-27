const std = @import("std");
const models = @import("../../models.zig");

/// Guild-related gateway events
pub const GuildEvents = struct {
    /// Guild create event - when a guild becomes available
    pub const GuildCreateEvent = struct {
        id: u64,
        name: []const u8,
        icon: ?[]const u8,
        icon_hash: ?[]const u8,
        splash: ?[]const u8,
        splash_hash: ?[]const u8,
        discovery_splash: ?[]const u8,
        discovery_splash_hash: ?[]const u8,
        owner: bool,
        owner_id: u64,
        permissions: ?[]const u8,
        afk_channel_id: ?u64,
        afk_timeout: u32,
        widget_enabled: bool,
        widget_channel_id: ?u64,
        verification_level: models.VerificationLevel,
        default_message_notifications: models.DefaultMessageNotifications,
        explicit_content_filter: models.ExplicitContentFilter,
        roles: []models.Role,
        emojis: []models.Emoji,
        features: [][]const u8,
        mfa_level: models.MFALevel,
        application_id: ?u64,
        system_channel_id: ?u64,
        system_channel_flags: u32,
        rules_channel_id: ?u64,
        max_members: u32,
        max_presences: ?u32,
        max_video_channel_users: ?u32,
        vanity_url_code: ?[]const u8,
        description: ?[]const u8,
        banner: ?[]const u8,
        premium_tier: models.PremiumTier,
        premium_subscription_count: ?u32,
        preferred_locale: []const u8,
        public_updates_channel_id: ?u64,
        max_stage_video_channel_users: ?u32,
        approximate_member_count: ?u32,
        approximate_presence_count: ?u32,
        welcome_screen: ?models.WelcomeScreen,
        nsfw: bool,
        nsfw_level: models.NSFWLevel,
        stage_instances: ?[]models.StageInstance,
        stickers: ?[]models.Sticker,
        guild_scheduled_events: ?[]models.GuildScheduledEvent,
        premium_progress_bar_enabled: bool,
    };

    /// Guild update event - when a guild is updated
    pub const GuildUpdateEvent = struct {
        id: u64,
        name: []const u8,
        icon: ?[]const u8,
        icon_hash: ?[]const u8,
        splash: ?[]const u8,
        splash_hash: ?[]const u8,
        discovery_splash: ?[]const u8,
        discovery_splash_hash: ?[]const u8,
        owner: bool,
        owner_id: u64,
        permissions: ?[]const u8,
        afk_channel_id: ?u64,
        afk_timeout: u32,
        widget_enabled: bool,
        widget_channel_id: ?u64,
        verification_level: models.VerificationLevel,
        default_message_notifications: models.DefaultMessageNotifications,
        explicit_content_filter: models.ExplicitContentFilter,
        roles: []models.Role,
        emojis: []models.Emoji,
        features: [][]const u8,
        mfa_level: models.MFALevel,
        application_id: ?u64,
        system_channel_id: ?u64,
        system_channel_flags: u32,
        rules_channel_id: ?u64,
        max_members: u32,
        max_presences: ?u32,
        max_video_channel_users: ?u32,
        vanity_url_code: ?[]const u8,
        description: ?[]const u8,
        banner: ?[]const u8,
        premium_tier: models.PremiumTier,
        premium_subscription_count: ?u32,
        preferred_locale: []const u8,
        public_updates_channel_id: ?u64,
        max_stage_video_channel_users: ?u32,
        approximate_member_count: ?u32,
        approximate_presence_count: ?u32,
        welcome_screen: ?models.WelcomeScreen,
        nsfw: bool,
        nsfw_level: models.NSFWLevel,
        stage_instances: ?[]models.StageInstance,
        stickers: ?[]models.Sticker,
        guild_scheduled_events: ?[]models.GuildScheduledEvent,
        premium_progress_bar_enabled: bool,
    };

    /// Guild delete event - when a guild becomes unavailable
    pub const GuildDeleteEvent = struct {
        id: u64,
        unavailable: bool,
    };

    /// Guild ban add event
    pub const GuildBanAddEvent = struct {
        guild_id: u64,
        user: models.User,
    };

    /// Guild ban remove event
    pub const GuildBanRemoveEvent = struct {
        guild_id: u64,
        user: models.User,
    };

    /// Guild member add event
    pub const GuildMemberAddEvent = struct {
        guild_id: u64,
        user: models.User,
        roles: []u64,
        joined_at: []const u8,
        premium_since: ?[]const u8,
        deaf: bool,
        mute: bool,
        pending: bool,
        permissions: ?[]const u8,
    };

    /// Guild member remove event
    pub const GuildMemberRemoveEvent = struct {
        guild_id: u64,
        user: models.User,
    };

    /// Guild member update event
    pub const GuildMemberUpdateEvent = struct {
        guild_id: u64,
        roles: []u64,
        user: models.User,
        nick: ?[]const u8,
        avatar: ?[]const u8,
        joined_at: []const u8,
        premium_since: ?[]const u8,
        deaf: bool,
        mute: bool,
        pending: bool,
        permissions: ?[]const u8,
        communication_disabled_until: ?[]const u8,
    };

    /// Guild role create event
    pub const GuildRoleCreateEvent = struct {
        guild_id: u64,
        role: models.Role,
    };

    /// Guild role update event
    pub const GuildRoleUpdateEvent = struct {
        guild_id: u64,
        role: models.Role,
    };

    /// Guild role delete event
    pub const GuildRoleDeleteEvent = struct {
        guild_id: u64,
        role_id: u64,
    };

    /// Guild emojis update event
    pub const GuildEmojisUpdateEvent = struct {
        guild_id: u64,
        emojis: []models.Emoji,
    };

    /// Guild stickers update event
    pub const GuildStickersUpdateEvent = struct {
        guild_id: u64,
        stickers: []models.Sticker,
    };

    /// Guild integrations update event
    pub const GuildIntegrationsUpdateEvent = struct {
        guild_id: u64,
    };

    /// Guild member chunk event - when members are loaded in chunks
    pub const GuildMembersChunkEvent = struct {
        guild_id: u64,
        members: []models.GuildMember,
        chunk_index: u32,
        chunk_count: u32,
        not_found: ?[]u64,
        presences: ?[]models.PresenceUpdate,
        nonce: ?[]const u8,
    };

    /// Guild scheduled event create event
    pub const GuildScheduledEventCreateEvent = struct {
        guild_scheduled_event: models.GuildScheduledEvent,
    };

    /// Guild scheduled event update event
    pub const GuildScheduledEventUpdateEvent = struct {
        guild_scheduled_event: models.GuildScheduledEvent,
    };

    /// Guild scheduled event delete event
    pub const GuildScheduledEventDeleteEvent = struct {
        guild_scheduled_event: models.GuildScheduledEvent,
    };

    /// Guild scheduled event user add event
    pub const GuildScheduledEventUserAddEvent = struct {
        guild_scheduled_event_id: u64,
        guild_id: u64,
        user_id: u64,
    };

    /// Guild scheduled event user remove event
    pub const GuildScheduledEventUserRemoveEvent = struct {
        guild_scheduled_event_id: u64,
        guild_id: u64,
        user_id: u64,
    };
};

/// Event parsers for guild events
pub const GuildEventParsers = struct {
    pub fn parseGuildCreateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildCreateEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildCreateEvent, allocator, data, .{});
    }

    pub fn parseGuildUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildUpdateEvent, allocator, data, .{});
    }

    pub fn parseGuildDeleteEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildDeleteEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildDeleteEvent, allocator, data, .{});
    }

    pub fn parseGuildBanAddEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildBanAddEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildBanAddEvent, allocator, data, .{});
    }

    pub fn parseGuildBanRemoveEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildBanRemoveEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildBanRemoveEvent, allocator, data, .{});
    }

    pub fn parseGuildMemberAddEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildMemberAddEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildMemberAddEvent, allocator, data, .{});
    }

    pub fn parseGuildMemberRemoveEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildMemberRemoveEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildMemberRemoveEvent, allocator, data, .{});
    }

    pub fn parseGuildMemberUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildMemberUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildMemberUpdateEvent, allocator, data, .{});
    }

    pub fn parseGuildRoleCreateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildRoleCreateEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildRoleCreateEvent, allocator, data, .{});
    }

    pub fn parseGuildRoleUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildRoleUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildRoleUpdateEvent, allocator, data, .{});
    }

    pub fn parseGuildRoleDeleteEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildRoleDeleteEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildRoleDeleteEvent, allocator, data, .{});
    }

    pub fn parseGuildEmojisUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildEmojisUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildEmojisUpdateEvent, allocator, data, .{});
    }

    pub fn parseGuildStickersUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildStickersUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildStickersUpdateEvent, allocator, data, .{});
    }

    pub fn parseGuildIntegrationsUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildIntegrationsUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildIntegrationsUpdateEvent, allocator, data, .{});
    }

    pub fn parseGuildMembersChunkEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildMembersChunkEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildMembersChunkEvent, allocator, data, .{});
    }

    pub fn parseGuildScheduledEventCreateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildScheduledEventCreateEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildScheduledEventCreateEvent, allocator, data, .{});
    }

    pub fn parseGuildScheduledEventUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildScheduledEventUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildScheduledEventUpdateEvent, allocator, data, .{});
    }

    pub fn parseGuildScheduledEventDeleteEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildScheduledEventDeleteEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildScheduledEventDeleteEvent, allocator, data, .{});
    }

    pub fn parseGuildScheduledEventUserAddEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildScheduledEventUserAddEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildScheduledEventUserAddEvent, allocator, data, .{});
    }

    pub fn parseGuildScheduledEventUserRemoveEvent(data: []const u8, allocator: std.mem.Allocator) !GuildEvents.GuildScheduledEventUserRemoveEvent {
        return try std.json.parseFromSliceLeaky(GuildEvents.GuildScheduledEventUserRemoveEvent, allocator, data, .{});
    }
};
