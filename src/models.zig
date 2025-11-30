const std = @import("std");

pub const User = struct {
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
};

pub const Guild = struct {
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
    roles: []Role,
    emojis: []Emoji,
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
    stage_instances: []StageInstance,
    stickers: []Sticker,
    guild_scheduled_events: []GuildScheduledEvent,
};

pub const Channel = struct {
    id: u64,
    type: u8,
    guild_id: ?u64,
    position: ?u32,
    permission_overwrites: []PermissionOverwrite,
    name: ?[]const u8,
    topic: ?[]const u8,
    nsfw: bool = false,
    last_message_id: ?u64,
    bitrate: ?u32,
    user_limit: ?u32,
    rate_limit_per_user: ?u32,
    recipients: []User,
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
};

pub const Message = struct {
    id: u64,
    channel_id: u64,
    author: User,
    content: []const u8,
    timestamp: []const u8,
    edited_timestamp: ?[]const u8,
    tts: bool = false,
    mention_everyone: bool = false,
    mentions: []User,
    mention_roles: []u64,
    mention_channels: []ChannelMention,
    attachments: []Attachment,
    embeds: []Embed,
    reactions: []Reaction,
    nonce: ?[]const u8,
    pinned: bool = false,
    webhook_id: ?u64,
    type: u8,
    activity: ?MessageActivity,
    application: ?MessageApplication,
    message_reference: ?MessageReference,
    flags: ?u32,
    referenced_message: ?*Message,
    interaction: ?MessageInteraction,
    thread: ?Channel,
    components: []Component,
    sticker_items: []StickerItem,
    position: ?u32,
    role_subscription_data: ?RoleSubscriptionData,
};

pub const Role = struct {
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
};

pub const Emoji = struct {
    id: ?u64,
    name: []const u8,
    roles: ?[]u64,
    user: ?User,
    require_colons: bool = false,
    managed: bool = false,
    animated: bool = false,
    available: bool = true,
};

pub const PermissionOverwrite = struct {
    id: u64,
    type: u8,
    allow: []const u8,
    deny: []const u8,
};

pub const Attachment = struct {
    id: u64,
    filename: []const u8,
    description: ?[]const u8,
    content_type: ?[]const u8,
    size: u32,
    url: []const u8,
    proxy_url: []const u8,
    height: ?u32,
    width: ?u32,
    ephemeral: bool = false,
    duration_secs: ?f32,
    waveform: ?[]const u8,
    flags: ?u32,
};

pub const Embed = struct {
    title: ?[]const u8,
    type: ?[]const u8,
    description: ?[]const u8,
    url: ?[]const u8,
    timestamp: ?[]const u8,
    color: ?u32,
    footer: ?EmbedFooter,
    image: ?EmbedImage,
    thumbnail: ?EmbedThumbnail,
    video: ?EmbedVideo,
    provider: ?EmbedProvider,
    author: ?EmbedAuthor,
    fields: []EmbedField,
};

pub const EmbedFooter = struct {
    text: []const u8,
    icon_url: ?[]const u8,
    proxy_icon_url: ?[]const u8,
};

pub const EmbedImage = struct {
    url: ?[]const u8,
    proxy_url: ?[]const u8,
    height: ?u32,
    width: ?u32,
};

pub const EmbedThumbnail = struct {
    url: ?[]const u8,
    proxy_url: ?[]const u8,
    height: ?u32,
    width: ?u32,
};

pub const EmbedVideo = struct {
    url: ?[]const u8,
    proxy_url: ?[]const u8,
    height: ?u32,
    width: ?u32,
};

pub const EmbedProvider = struct {
    name: ?[]const u8,
    url: ?[]const u8,
};

pub const EmbedAuthor = struct {
    name: ?[]const u8,
    url: ?[]const u8,
    icon_url: ?[]const u8,
    proxy_icon_url: ?[]const u8,
};

pub const EmbedField = struct {
    name: []const u8,
    value: []const u8,
    is_inline: bool = false,
};

pub const Reaction = struct {
    count: u32,
    me: bool,
    emoji: Emoji,
};

pub const MessageActivity = struct {
    type: u8,
    party_id: ?[]const u8,
};

pub const MessageApplication = struct {
    id: u64,
    cover_image: ?[]const u8,
    description: []const u8,
    icon: ?[]const u8,
    name: []const u8,
};

pub const MessageReference = struct {
    type: u8,
    message_id: ?u64,
    channel_id: ?u64,
    guild_id: ?u64,
    fail_if_not_exists: bool = true,
};

pub const MessageInteraction = struct {
    id: u64,
    type: u8,
    name: []const u8,
    user: User,
    member: ?PartialGuildMember,
};

pub const PartialGuildMember = struct {
    user: User,
    roles: []u64,
    premium_since: ?[]const u8,
    permissions: ?[]const u8,
    pending: bool = false,
    nick: ?[]const u8,
    mute: bool = false,
    deaf: bool = false,
    joined_at: ?[]const u8,
    avatar: ?[]const u8,
};

pub const Component = struct {
    type: u8,
    custom_id: ?[]const u8,
    disabled: bool = false,
    style: ?u8,
    label: ?[]const u8,
    emoji: ?Emoji,
    url: ?[]const u8,
    options: []SelectOption,
    placeholder: ?[]const u8,
    min_values: ?u32,
    max_values: ?u32,
    components: []Component,
};

pub const SelectOption = struct {
    label: []const u8,
    value: []const u8,
    description: ?[]const u8,
    emoji: ?Emoji,
    default: bool = false,
};

pub const StickerItem = struct {
    id: u64,
    name: []const u8,
    format_type: u8,
};

pub const RoleSubscriptionData = struct {
    role_subscription_listing_id: u64,
    tier_name: []const u8,
    total_months_subscribed: u32,
    is_renewal: bool,
};

pub const ChannelMention = struct {
    id: u64,
    guild_id: u64,
    type: u8,
    name: []const u8,
};

pub const StageInstance = struct {
    id: u64,
    guild_id: u64,
    channel_id: u64,
    topic: []const u8,
    privacy_level: u8,
    discoverable_disabled: bool = false,
    guild_scheduled_event_id: ?u64,
};

pub const Sticker = struct {
    id: u64,
    pack_id: ?u64,
    name: []const u8,
    description: ?[]const u8,
    tags: ?[]const u8,
    type: u8,
    format_type: u8,
    available: ?bool,
    sort_value: ?u32,
    user: ?User,
};

pub const GuildScheduledEvent = struct {
    id: u64,
    guild_id: u64,
    channel_id: ?u64,
    creator_id: ?u64,
    name: []const u8,
    description: ?[]const u8,
    scheduled_start_time: []const u8,
    scheduled_end_time: ?[]const u8,
    privacy_level: u8,
    status: u8,
    entity_type: u8,
    entity_id: ?u64,
    entity_metadata: ?GuildScheduledEventEntityMetadata,
    creator: ?User,
    user_count: ?u32,
    image: ?[]const u8,
};

pub const GuildScheduledEventEntityMetadata = struct {
    location: ?[]const u8,
};

pub const AllowedMentions = struct {
    parse: ?[]const []const u8 = null,
    roles: ?[]const u64 = null,
    users: ?[]const u64 = null,
    replied_user: ?bool = null,
};

pub const Entitlement = struct {
    id: u64,
    sku_id: u64,
    application_id: u64,
    user_id: ?u64,
    type: u8,
    deleted: bool,
    start_time: ?[]const u8,
    end_time: ?[]const u8,
    guild_id: ?u64,
    consumable: bool,
};

pub const ReadyEvent = struct {
    user: User,
    session_id: []const u8,
    guilds: []Guild,
};
