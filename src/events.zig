const std = @import("std");
const models = @import("models.zig");

pub const EventHandler = struct {
    allocator: std.mem.Allocator,
    handlers: std.json.ObjectMap,

    pub fn init(allocator: std.mem.Allocator) EventHandler {
        return EventHandler{
            .allocator = allocator,
            .handlers = std.json.ObjectMap.init(allocator),
        };
    }

    pub fn deinit(self: *EventHandler) void {
        self.handlers.deinit();
    }

    pub fn onMessageCreate(self: *EventHandler, handler: fn (*models.Message) void) !void {
        const handler_wrapper = struct {
            fn wrapper(json_data: []const u8) void {
                var parsed = std.json.parseFromSlice(struct {
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
                }, std.heap.page_allocator, json_data, .{ .ignore_unknown_fields = true }) catch return;
                defer parsed.deinit();

                var message = models.Message{
                    .id = parsed.value.id,
                    .channel_id = parsed.value.channel_id,
                    .author = parsed.value.author,
                    .content = std.heap.page_allocator.dupe(u8, parsed.value.content) catch return,
                    .timestamp = std.heap.page_allocator.dupe(u8, parsed.value.timestamp) catch return,
                    .edited_timestamp = if (parsed.value.edited_timestamp) |et| std.heap.page_allocator.dupe(u8, et) catch null else null,
                    .tts = parsed.value.tts,
                    .mention_everyone = parsed.value.mention_everyone,
                    .mentions = std.heap.page_allocator.dupe(models.User, parsed.value.mentions) catch return,
                    .mention_roles = std.heap.page_allocator.dupe(u64, parsed.value.mention_roles) catch return,
                    .mention_channels = std.heap.page_allocator.dupe(models.ChannelMention, parsed.value.mention_channels) catch return,
                    .attachments = std.heap.page_allocator.dupe(models.Attachment, parsed.value.attachments) catch return,
                    .embeds = std.heap.page_allocator.dupe(models.Embed, parsed.value.embeds) catch return,
                    .reactions = std.heap.page_allocator.dupe(models.Reaction, parsed.value.reactions) catch return,
                    .nonce = if (parsed.value.nonce) |n| std.heap.page_allocator.dupe(u8, n) catch null else null,
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
                    .components = std.heap.page_allocator.dupe(models.Component, parsed.value.components) catch return,
                    .sticker_items = std.heap.page_allocator.dupe(models.StickerItem, parsed.value.sticker_items) catch return,
                    .position = parsed.value.position,
                    .role_subscription_data = parsed.value.role_subscription_data,
                };

                handler(&message);
            }
        };

        try self.handlers.put("MESSAGE_CREATE", std.json.Value{ .string = @ptrCast(&handler_wrapper.wrapper) });
    }

    pub fn onMessageUpdate(self: *EventHandler, handler: fn (*models.Message) void) !void {
        const handler_wrapper = struct {
            fn wrapper(json_data: []const u8) void {
                var parsed = std.json.parseFromSlice(struct {
                    id: u64,
                    channel_id: u64,
                    author: ?models.User,
                    content: ?[]const u8,
                    timestamp: ?[]const u8,
                    edited_timestamp: ?[]const u8,
                    tts: ?bool,
                    mention_everyone: ?bool,
                    mentions: ?[]models.User,
                    mention_roles: ?[]u64,
                    mention_channels: ?[]models.ChannelMention,
                    attachments: ?[]models.Attachment,
                    embeds: ?[]models.Embed,
                    reactions: ?[]models.Reaction,
                    nonce: ?[]const u8,
                    pinned: ?bool,
                    webhook_id: ?u64,
                    type: ?u8,
                    activity: ?models.MessageActivity,
                    application: ?models.MessageApplication,
                    message_reference: ?models.MessageReference,
                    flags: ?u32,
                    referenced_message: ?models.Message,
                    interaction: ?models.MessageInteraction,
                    thread: ?models.Channel,
                    components: ?[]models.Component,
                    sticker_items: ?[]models.StickerItem,
                    position: ?u32,
                    role_subscription_data: ?models.RoleSubscriptionData,
                }, std.heap.page_allocator, json_data, .{ .ignore_unknown_fields = true }) catch return;
                defer parsed.deinit();

                var message = models.Message{
                    .id = parsed.value.id,
                    .channel_id = parsed.value.channel_id,
                    .author = parsed.value.author orelse std.mem.zeroes(models.User),
                    .content = if (parsed.value.content) |c| std.heap.page_allocator.dupe(u8, c) catch return else return,
                    .timestamp = if (parsed.value.timestamp) |t| std.heap.page_allocator.dupe(u8, t) catch return else return,
                    .edited_timestamp = if (parsed.value.edited_timestamp) |et| std.heap.page_allocator.dupe(u8, et) catch null else null,
                    .tts = parsed.value.tts orelse false,
                    .mention_everyone = parsed.value.mention_everyone orelse false,
                    .mentions = if (parsed.value.mentions) |m| std.heap.page_allocator.dupe(models.User, m) catch return else return,
                    .mention_roles = if (parsed.value.mention_roles) |mr| std.heap.page_allocator.dupe(u64, mr) catch return else return,
                    .mention_channels = if (parsed.value.mention_channels) |mc| std.heap.page_allocator.dupe(models.ChannelMention, mc) catch return else return,
                    .attachments = if (parsed.value.attachments) |a| std.heap.page_allocator.dupe(models.Attachment, a) catch return else return,
                    .embeds = if (parsed.value.embeds) |e| std.heap.page_allocator.dupe(models.Embed, e) catch return else return,
                    .reactions = if (parsed.value.reactions) |r| std.heap.page_allocator.dupe(models.Reaction, r) catch return else return,
                    .nonce = if (parsed.value.nonce) |n| std.heap.page_allocator.dupe(u8, n) catch null else null,
                    .pinned = parsed.value.pinned orelse false,
                    .webhook_id = parsed.value.webhook_id,
                    .type = parsed.value.type orelse 0,
                    .activity = parsed.value.activity,
                    .application = parsed.value.application,
                    .message_reference = parsed.value.message_reference,
                    .flags = parsed.value.flags,
                    .referenced_message = parsed.value.referenced_message,
                    .interaction = parsed.value.interaction,
                    .thread = parsed.value.thread,
                    .components = if (parsed.value.components) |c| std.heap.page_allocator.dupe(models.Component, c) catch return else return,
                    .sticker_items = if (parsed.value.sticker_items) |si| std.heap.page_allocator.dupe(models.StickerItem, si) catch return else return,
                    .position = parsed.value.position,
                    .role_subscription_data = parsed.value.role_subscription_data,
                };

                handler(&message);
            }
        };

        try self.handlers.put("MESSAGE_UPDATE", std.json.Value{ .string = @ptrCast(&handler_wrapper.wrapper) });
    }

    pub fn onMessageDelete(self: *EventHandler, handler: fn (u64, u64) void) !void {
        const handler_wrapper = struct {
            fn wrapper(json_data: []const u8) void {
                var parsed = std.json.parseFromSlice(struct {
                    id: u64,
                    channel_id: u64,
                    guild_id: ?u64,
                }, std.heap.page_allocator, json_data, .{ .ignore_unknown_fields = true }) catch return;
                defer parsed.deinit();

                handler(parsed.value.id, parsed.value.channel_id);
            }
        };

        try self.handlers.put("MESSAGE_DELETE", std.json.Value{ .string = @ptrCast(&handler_wrapper.wrapper) });
    }

    pub fn onGuildCreate(self: *EventHandler, handler: fn (*models.Guild) void) !void {
        const handler_wrapper = struct {
            fn wrapper(json_data: []const u8) void {
                var parsed = std.json.parseFromSlice(struct {
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
                }, std.heap.page_allocator, json_data, .{ .ignore_unknown_fields = true }) catch return;
                defer parsed.deinit();

                var guild = models.Guild{
                    .id = parsed.value.id,
                    .name = std.heap.page_allocator.dupe(u8, parsed.value.name) catch return,
                    .icon = if (parsed.value.icon) |i| std.heap.page_allocator.dupe(u8, i) catch null else null,
                    .splash = if (parsed.value.splash) |s| std.heap.page_allocator.dupe(u8, s) catch null else null,
                    .discovery_splash = if (parsed.value.discovery_splash) |ds| std.heap.page_allocator.dupe(u8, ds) catch null else null,
                    .owner = parsed.value.owner,
                    .owner_id = parsed.value.owner_id,
                    .permissions = if (parsed.value.permissions) |p| std.heap.page_allocator.dupe(u8, p) catch null else null,
                    .region = if (parsed.value.region) |r| std.heap.page_allocator.dupe(u8, r) catch null else null,
                    .afk_channel_id = parsed.value.afk_channel_id,
                    .afk_timeout = parsed.value.afk_timeout,
                    .widget_enabled = parsed.value.widget_enabled,
                    .widget_channel_id = parsed.value.widget_channel_id,
                    .verification_level = parsed.value.verification_level,
                    .default_message_notifications = parsed.value.default_message_notifications,
                    .explicit_content_filter = parsed.value.explicit_content_filter,
                    .roles = std.heap.page_allocator.dupe(models.Role, parsed.value.roles) catch return,
                    .emojis = std.heap.page_allocator.dupe(models.Emoji, parsed.value.emojis) catch return,
                    .features = std.heap.page_allocator.dupe([]const u8, parsed.value.features) catch return,
                    .mfa_level = parsed.value.mfa_level,
                    .application_id = parsed.value.application_id,
                    .system_channel_id = parsed.value.system_channel_id,
                    .system_channel_flags = parsed.value.system_channel_flags,
                    .rules_channel_id = parsed.value.rules_channel_id,
                    .max_members = parsed.value.max_members,
                    .max_presences = parsed.value.max_presences,
                    .vanity_url_code = if (parsed.value.vanity_url_code) |v| std.heap.page_allocator.dupe(u8, v) catch null else null,
                    .description = if (parsed.value.description) |d| std.heap.page_allocator.dupe(u8, d) catch null else null,
                    .banner = if (parsed.value.banner) |b| std.heap.page_allocator.dupe(u8, b) catch null else null,
                    .premium_tier = parsed.value.premium_tier,
                    .premium_subscription_count = parsed.value.premium_subscription_count,
                    .preferred_locale = std.heap.page_allocator.dupe(u8, parsed.value.preferred_locale) catch return,
                    .public_updates_channel_id = parsed.value.public_updates_channel_id,
                    .max_video_channel_users = parsed.value.max_video_channel_users,
                    .approximate_member_count = parsed.value.approximate_member_count,
                    .approximate_presence_count = parsed.value.approximate_presence_count,
                    .nsfw_level = parsed.value.nsfw_level,
                    .stage_instances = std.heap.page_allocator.dupe(models.StageInstance, parsed.value.stage_instances) catch return,
                    .stickers = std.heap.page_allocator.dupe(models.Sticker, parsed.value.stickers) catch return,
                    .guild_scheduled_events = std.heap.page_allocator.dupe(models.GuildScheduledEvent, parsed.value.guild_scheduled_events) catch return,
                };

                handler(&guild);
            }
        };

        try self.handlers.put("GUILD_CREATE", std.json.Value{ .string = @ptrCast(&handler_wrapper.wrapper) });
    }

    pub fn onReady(self: *EventHandler, handler: fn ([]const u8, u64) void) !void {
        const handler_wrapper = struct {
            fn wrapper(json_data: []const u8) void {
                var parsed = std.json.parseFromSlice(struct {
                    session_id: []const u8,
                    application: struct {
                        id: u64,
                    },
                }, std.heap.page_allocator, json_data, .{ .ignore_unknown_fields = true }) catch return;
                defer parsed.deinit();

                handler(parsed.value.session_id, parsed.value.application.id);
            }
        };

        try self.handlers.put("READY", std.json.Value{ .string = @ptrCast(&handler_wrapper.wrapper) });
    }

    pub fn callHandler(self: *EventHandler, event_type: []const u8, data: ?std.json.Value) void {
        if (self.handlers.get(event_type)) |handler_value| {
            const handler = @as(fn ([]const u8) void, @ptrCast(handler_value.string));

            if (data) |d| {
                const json_string = std.json.stringifyAlloc(std.heap.page_allocator, d, .{}) catch return;
                defer std.heap.page_allocator.free(json_string);
                handler(json_string);
            }
        }
    }
};
