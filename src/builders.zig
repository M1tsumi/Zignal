const std = @import("std");
const models = @import("models.zig");
const utils = @import("utils.zig");
const interactions = @import("interactions.zig");

/// Fluent message builder with type-safe API and validation
pub const MessageBuilder = struct {
    allocator: std.mem.Allocator,
    content: ?[]const u8 = null,
    embeds: std.ArrayList(models.Embed),
    components: std.ArrayList(interactions.ActionRow),
    attachments: std.ArrayList(models.Attachment),
    allowed_mentions: ?models.AllowedMentions = null,
    reply_to_message_id: ?u64 = null,
    mention_replied_user: bool = true,
    flags: u32 = 0,
    stickers: std.ArrayList(models.StickerItem),
    poll: ?models.Poll = null,

    pub fn init(allocator: std.mem.Allocator) MessageBuilder {
        return MessageBuilder{
            .allocator = allocator,
            .embeds = std.ArrayList(models.Embed).init(allocator),
            .components = std.ArrayList(interactions.ActionRow).init(allocator),
            .attachments = std.ArrayList(models.Attachment).init(allocator),
            .stickers = std.ArrayList(models.StickerItem).init(allocator),
        };
    }

    pub fn deinit(self: *MessageBuilder) void {
        if (self.content) |content| self.allocator.free(content);
        if (self.allowed_mentions) |*mentions| {
            // AllowedMentions deinit would be handled by models
        }
        for (self.embeds.items) |*embed| {
            // Embed deinit would be handled by models
        }
        for (self.components.items) |*component| {
            component.deinit(self.allocator);
        }
        for (self.attachments.items) |*attachment| {
            // Attachment deinit would be handled by models
        }
        for (self.stickers.items) |*sticker| {
            // StickerItem deinit would be handled by models
        }
        if (self.poll) |*poll| {
            // Poll deinit would be handled by models
        }
        self.embeds.deinit();
        self.components.deinit();
        self.attachments.deinit();
        self.stickers.deinit();
    }

    pub fn content(self: *MessageBuilder, text: []const u8) !*MessageBuilder {
        if (self.content) |old_content| self.allocator.free(old_content);
        self.content = try self.allocator.dupe(u8, text);
        return self;
    }

    pub fn addEmbed(self: *MessageBuilder, embed: models.Embed) !*MessageBuilder {
        try self.embeds.append(embed);
        return self;
    }

    pub fn embed(self: *MessageBuilder, builder: *EmbedBuilder) !*MessageBuilder {
        const embed = try builder.build(self.allocator);
        try self.embeds.append(embed);
        return self;
    }

    pub fn addComponent(self: *MessageBuilder, action_row: interactions.ActionRow) !*MessageBuilder {
        try self.components.append(action_row);
        return self;
    }

    pub fn component(self: *MessageBuilder, builder: *interactions.InteractionBuilder.ComponentBuilder) !*MessageBuilder {
        const components = try builder.build();
        defer self.allocator.free(components);
        for (components) |action_row| {
            try self.components.append(action_row);
        }
        return self;
    }

    pub fn addAttachment(self: *MessageBuilder, attachment: models.Attachment) !*MessageBuilder {
        try self.attachments.append(attachment);
        return self;
    }

    pub fn allowedMentions(self: *MessageBuilder, mentions: models.AllowedMentions) *MessageBuilder {
        self.allowed_mentions = mentions;
        return self;
    }

    pub fn reply(self: *MessageBuilder, message_id: u64) *MessageBuilder {
        self.reply_to_message_id = message_id;
        return self;
    }

    pub fn mentionRepliedUser(self: *MessageBuilder, mention: bool) *MessageBuilder {
        self.mention_replied_user = mention;
        return self;
    }

    pub fn suppressEmbeds(self: *MessageBuilder) *MessageBuilder {
        self.flags |= 1 << 2; // SUPPRESS_EMBEDS
        return self;
    }

    pub fn suppressNotifications(self: *MessageBuilder) *MessageBuilder {
        self.flags |= 1 << 12; // SUPPRESS_NOTIFICATIONS
        return self;
    }

    pub fn ephemeral(self: *MessageBuilder) *MessageBuilder {
        self.flags |= 1 << 6; // EPHEMERAL
        return self;
    }

    pub fn addSticker(self: *MessageBuilder, sticker: models.StickerItem) !*MessageBuilder {
        try self.stickers.append(sticker);
        return self;
    }

    pub fn poll(self: *MessageBuilder, poll: models.Poll) *MessageBuilder {
        self.poll = poll;
        return self;
    }

    pub fn build(self: *MessageBuilder) !models.Message {
        return models.Message{
            .id = 0, // Would be assigned by Discord
            .channel_id = 0, // Would be assigned by Discord
            .author = undefined, // Would be assigned by Discord
            .content = if (self.content) |content| try self.allocator.dupe(u8, content) else try self.allocator.dupe(u8, ""),
            .timestamp = "", // Would be assigned by Discord
            .edited_timestamp = null,
            .tts = false,
            .mention_everyone = false,
            .mentions = try self.allocator.dupe(models.User, &[_]models.User{}),
            .mention_roles = try self.allocator.dupe(u64, &[_]u64{}),
            .mention_channels = try self.allocator.dupe(models.ChannelMention, &[_]models.ChannelMention{}),
            .attachments = try self.allocator.dupe(models.Attachment, self.attachments.items),
            .embeds = try self.allocator.dupe(models.Embed, self.embeds.items),
            .reactions = try self.allocator.dupe(models.Reaction, &[_]models.Reaction{}),
            .nonce = null,
            .pinned = false,
            .webhook_id = null,
            .type = 0, // DEFAULT
            .activity = null,
            .application = null,
            .message_reference = if (self.reply_to_message_id) |msg_id| models.MessageReference{
                .message_id = msg_id,
                .channel_id = null,
                .guild_id = null,
                .fail_if_not_exists = null,
            } else null,
            .flags = self.flags,
            .referenced_message = null,
            .interaction = null,
            .thread = null,
            .components = try self.allocator.dupe(interactions.Component, &[_]interactions.Component{}),
            .sticker_items = try self.allocator.dupe(models.StickerItem, self.stickers.items),
            .position = null,
            .role_subscription_data = null,
        };
    }

    pub fn validate(self: *MessageBuilder) !void {
        // Validate content length
        if (self.content) |content| {
            if (content.len > 2000) {
                return error.ContentTooLong;
            }
        }

        // Validate embed count
        if (self.embeds.items.len > 10) {
            return error.TooManyEmbeds;
        }

        // Validate component count
        if (self.components.items.len > 5) {
            return error.TooManyComponents;
        }

        // Validate attachment count
        if (self.attachments.items.len > 10) {
            return error.TooManyAttachments;
        }

        // Validate sticker count
        if (self.stickers.items.len > 3) {
            return error.TooManyStickers;
        }

        // Validate that we have content, embeds, components, attachments, or stickers
        if (self.content == null and self.embeds.items.len == 0 and self.components.items.len == 0 and self.attachments.items.len == 0 and self.stickers.items.len == 0 and self.poll == null) {
            return error.EmptyMessage;
        }
    }
};

/// Fluent embed builder with comprehensive field support
pub const EmbedBuilder = struct {
    allocator: std.mem.Allocator,
    title: ?[]const u8 = null,
    description: ?[]const u8 = null,
    url: ?[]const u8 = null,
    timestamp: ?[]const u8 = null,
    color: ?u32 = null,
    footer: ?Footer = null,
    image: ?Image = null,
    thumbnail: ?Image = null,
    video: ?Video = null,
    provider: ?Provider = null,
    author: ?Author = null,
    fields: std.ArrayList(Field),

    const Footer = struct {
        text: []const u8,
        icon_url: ?[]const u8 = null,
        proxy_icon_url: ?[]const u8 = null,
    };

    const Image = struct {
        url: []const u8,
        proxy_url: ?[]const u8 = null,
        height: ?u32 = null,
        width: ?u32 = null,
    };

    const Video = struct {
        url: []const u8,
        proxy_url: ?[]const u8 = null,
        height: ?u32 = null,
        width: ?u32 = null,
    };

    const Provider = struct {
        name: ?[]const u8 = null,
        url: ?[]const u8 = null,
    };

    const Author = struct {
        name: []const u8,
        url: ?[]const u8 = null,
        icon_url: ?[]const u8 = null,
        proxy_icon_url: ?[]const u8 = null,
    };

    const Field = struct {
        name: []const u8,
        value: []const u8,
        inline: bool = false,
    };

    pub fn init(allocator: std.mem.Allocator) EmbedBuilder {
        return EmbedBuilder{
            .allocator = allocator,
            .fields = std.ArrayList(Field).init(allocator),
        };
    }

    pub fn deinit(self: *EmbedBuilder) void {
        if (self.title) |title| self.allocator.free(title);
        if (self.description) |description| self.allocator.free(description);
        if (self.url) |url| self.allocator.free(url);
        if (self.timestamp) |timestamp| self.allocator.free(timestamp);
        if (self.footer) |*footer| {
            self.allocator.free(footer.text);
            if (footer.icon_url) |icon_url| self.allocator.free(icon_url);
            if (footer.proxy_icon_url) |proxy_icon_url| self.allocator.free(proxy_icon_url);
        }
        if (self.image) |*image| {
            self.allocator.free(image.url);
            if (image.proxy_url) |proxy_url| self.allocator.free(proxy_url);
        }
        if (self.thumbnail) |*thumbnail| {
            self.allocator.free(thumbnail.url);
            if (thumbnail.proxy_url) |proxy_url| self.allocator.free(proxy_url);
        }
        if (self.video) |*video| {
            self.allocator.free(video.url);
            if (video.proxy_url) |proxy_url| self.allocator.free(proxy_url);
        }
        if (self.provider) |*provider| {
            if (provider.name) |name| self.allocator.free(name);
            if (provider.url) |url| self.allocator.free(url);
        }
        if (self.author) |*author| {
            self.allocator.free(author.name);
            if (author.url) |url| self.allocator.free(url);
            if (author.icon_url) |icon_url| self.allocator.free(icon_url);
            if (author.proxy_icon_url) |proxy_icon_url| self.allocator.free(proxy_icon_url);
        }
        for (self.fields.items) |*field| {
            self.allocator.free(field.name);
            self.allocator.free(field.value);
        }
        self.fields.deinit();
    }

    pub fn title(self: *EmbedBuilder, text: []const u8) !*EmbedBuilder {
        if (self.title) |old_title| self.allocator.free(old_title);
        self.title = try self.allocator.dupe(u8, text);
        return self;
    }

    pub fn description(self: *EmbedBuilder, text: []const u8) !*EmbedBuilder {
        if (self.description) |old_description| self.allocator.free(old_description);
        self.description = try self.allocator.dupe(u8, text);
        return self;
    }

    pub fn url(self: *EmbedBuilder, link: []const u8) !*EmbedBuilder {
        if (self.url) |old_url| self.allocator.free(old_url);
        self.url = try self.allocator.dupe(u8, link);
        return self;
    }

    pub fn timestamp(self: *EmbedBuilder, time: []const u8) !*EmbedBuilder {
        if (self.timestamp) |old_timestamp| self.allocator.free(old_timestamp);
        self.timestamp = try self.allocator.dupe(u8, time);
        return self;
    }

    pub fn color(self: *EmbedBuilder, color: u32) *EmbedBuilder {
        self.color = color;
        return self;
    }

    pub fn colorRgb(self: *EmbedBuilder, r: u8, g: u8, b: u8) *EmbedBuilder {
        self.color = (@as(u32, r) << 16) | (@as(u32, g) << 8) | b;
        return self;
    }

    pub fn colorHex(self: *EmbedBuilder, hex: []const u8) !*EmbedBuilder {
        const color = try utils.Color.parseHex(hex);
        self.color = color.toRgb();
        return self;
    }

    pub fn footer(self: *EmbedBuilder, text: []const u8, icon_url: ?[]const u8) !*EmbedBuilder {
        if (self.footer) |*old_footer| {
            self.allocator.free(old_footer.text);
            if (old_footer.icon_url) |old_icon_url| self.allocator.free(old_icon_url);
            if (old_footer.proxy_icon_url) |old_proxy_icon_url| self.allocator.free(old_proxy_icon_url);
        }
        self.footer = Footer{
            .text = try self.allocator.dupe(u8, text),
            .icon_url = if (icon_url) |url| try self.allocator.dupe(u8, url) else null,
            .proxy_icon_url = null,
        };
        return self;
    }

    pub fn image(self: *EmbedBuilder, url: []const u8, proxy_url: ?[]const u8, height: ?u32, width: ?u32) !*EmbedBuilder {
        if (self.image) |*old_image| {
            self.allocator.free(old_image.url);
            if (old_image.proxy_url) |old_proxy_url| self.allocator.free(old_proxy_url);
        }
        self.image = Image{
            .url = try self.allocator.dupe(u8, url),
            .proxy_url = if (proxy_url) |url| try self.allocator.dupe(u8, url) else null,
            .height = height,
            .width = width,
        };
        return self;
    }

    pub fn thumbnail(self: *EmbedBuilder, url: []const u8, proxy_url: ?[]const u8, height: ?u32, width: ?u32) !*EmbedBuilder {
        if (self.thumbnail) |*old_thumbnail| {
            self.allocator.free(old_thumbnail.url);
            if (old_thumbnail.proxy_url) |old_proxy_url| self.allocator.free(old_proxy_url);
        }
        self.thumbnail = Image{
            .url = try self.allocator.dupe(u8, url),
            .proxy_url = if (proxy_url) |url| try self.allocator.dupe(u8, url) else null,
            .height = height,
            .width = width,
        };
        return self;
    }

    pub fn author(self: *EmbedBuilder, name: []const u8, url: ?[]const u8, icon_url: ?[]const u8) !*EmbedBuilder {
        if (self.author) |*old_author| {
            self.allocator.free(old_author.name);
            if (old_author.url) |old_url| self.allocator.free(old_url);
            if (old_author.icon_url) |old_icon_url| self.allocator.free(old_icon_url);
            if (old_author.proxy_icon_url) |old_proxy_icon_url| self.allocator.free(old_proxy_icon_url);
        }
        self.author = Author{
            .name = try self.allocator.dupe(u8, name),
            .url = if (url) |u| try self.allocator.dupe(u8, u) else null,
            .icon_url = if (icon_url) |url| try self.allocator.dupe(u8, url) else null,
            .proxy_icon_url = null,
        };
        return self;
    }

    pub fn field(self: *EmbedBuilder, name: []const u8, value: []const u8, inline: bool) !*EmbedBuilder {
        try self.fields.append(Field{
            .name = try self.allocator.dupe(u8, name),
            .value = try self.allocator.dupe(u8, value),
            .inline = inline,
        });
        return self;
    }

    pub fn inlineField(self: *EmbedBuilder, name: []const u8, value: []const u8) !*EmbedBuilder {
        return self.field(name, value, true);
    }

    pub fn build(self: *EmbedBuilder) !models.Embed {
        return models.Embed{
            .title = if (self.title) |title| try self.allocator.dupe(u8, title) else null,
            .type = "rich",
            .description = if (self.description) |description| try self.allocator.dupe(u8, description) else null,
            .url = if (self.url) |url| try self.allocator.dupe(u8, url) else null,
            .timestamp = if (self.timestamp) |timestamp| try self.allocator.dupe(u8, timestamp) else null,
            .color = self.color,
            .footer = if (self.footer) |footer| models.Embed.Footer{
                .text = try self.allocator.dupe(u8, footer.text),
                .icon_url = if (footer.icon_url) |icon_url| try self.allocator.dupe(u8, icon_url) else null,
                .proxy_icon_url = if (footer.proxy_icon_url) |proxy_icon_url| try self.allocator.dupe(u8, proxy_icon_url) else null,
            } else null,
            .image = if (self.image) |image| models.Embed.Image{
                .url = try self.allocator.dupe(u8, image.url),
                .proxy_url = if (image.proxy_url) |proxy_url| try self.allocator.dupe(u8, proxy_url) else null,
                .height = image.height,
                .width = image.width,
            } else null,
            .thumbnail = if (self.thumbnail) |thumbnail| models.Embed.Thumbnail{
                .url = try self.allocator.dupe(u8, thumbnail.url),
                .proxy_url = if (thumbnail.proxy_url) |proxy_url| try self.allocator.dupe(u8, proxy_url) else null,
                .height = thumbnail.height,
                .width = thumbnail.width,
            } else null,
            .video = null, // Video is read-only
            .provider = if (self.provider) |provider| models.Embed.Provider{
                .name = if (provider.name) |name| try self.allocator.dupe(u8, name) else null,
                .url = if (provider.url) |url| try self.allocator.dupe(u8, url) else null,
            } else null,
            .author = if (self.author) |author| models.Embed.Author{
                .name = try self.allocator.dupe(u8, author.name),
                .url = if (author.url) |url| try self.allocator.dupe(u8, url) else null,
                .icon_url = if (author.icon_url) |icon_url| try self.allocator.dupe(u8, icon_url) else null,
                .proxy_icon_url = if (author.proxy_icon_url) |proxy_icon_url| try self.allocator.dupe(u8, proxy_icon_url) else null,
            } else null,
            .fields = try self.allocator.dupe(models.Embed.Field, &[_]models.Embed.Field{}),
        };
    }

    pub fn validate(self: *EmbedBuilder) !void {
        // Validate title length
        if (self.title) |title| {
            if (title.len > 256) {
                return error.TitleTooLong;
            }
        }

        // Validate description length
        if (self.description) |description| {
            if (description.len > 4096) {
                return error.DescriptionTooLong;
            }
        }

        // Validate field count
        if (self.fields.items.len > 25) {
            return error.TooManyFields;
        }

        // Validate field name and value lengths
        for (self.fields.items) |field| {
            if (field.name.len > 256) {
                return error.FieldNameTooLong;
            }
            if (field.value.len > 1024) {
                return error.FieldValueTooLong;
            }
        }

        // Validate footer text length
        if (self.footer) |footer| {
            if (footer.text.len > 2048) {
                return error.FooterTextTooLong;
            }
        }

        // Validate author name length
        if (self.author) |author| {
            if (author.name.len > 256) {
                return error.AuthorNameTooLong;
            }
        }

        // Validate total embed length
        var total_length: usize = 0;
        if (self.title) |title| total_length += title.len;
        if (self.description) |description| total_length += description.len;
        for (self.fields.items) |field| {
            total_length += field.name.len + field.value.len;
        }
        if (self.footer) |footer| total_length += footer.text.len;
        if (self.author) |author| total_length += author.name.len;

        if (total_length > 6000) {
            return error.EmbedTooLong;
        }
    }
};

/// Fluent channel builder for creating and updating channels
pub const ChannelBuilder = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    type: u8,
    topic: ?[]const u8 = null,
    position: ?u32 = null,
    permission_overwrites: std.ArrayList(models.PermissionOverwrite),
    nsfw: bool = false,
    rate_limit_per_user: ?u32 = null,
    bitrate: ?u32 = null,
    user_limit: ?u32 = null,
    parent_id: ?u64 = null,
    default_auto_archive_duration: ?u32 = null,

    pub fn init(allocator: std.mem.Allocator, name: []const u8, channel_type: u8) ChannelBuilder {
        return ChannelBuilder{
            .allocator = allocator,
            .name = name,
            .type = channel_type,
            .permission_overwrites = std.ArrayList(models.PermissionOverwrite).init(allocator),
        };
    }

    pub fn deinit(self: *ChannelBuilder) void {
        self.allocator.free(self.name);
        if (self.topic) |topic| self.allocator.free(topic);
        for (self.permission_overwrites.items) |*overwrite| {
            // PermissionOverwrite deinit would be handled by models
        }
        self.permission_overwrites.deinit();
    }

    pub fn topic(self: *ChannelBuilder, text: []const u8) !*ChannelBuilder {
        if (self.topic) |old_topic| self.allocator.free(old_topic);
        self.topic = try self.allocator.dupe(u8, text);
        return self;
    }

    pub fn position(self: *ChannelBuilder, pos: u32) *ChannelBuilder {
        self.position = pos;
        return self;
    }

    pub fn addPermissionOverwrite(self: *ChannelBuilder, overwrite: models.PermissionOverwrite) !*ChannelBuilder {
        try self.permission_overwrites.append(overwrite);
        return self;
    }

    pub fn nsfw(self: *ChannelBuilder, is_nsfw: bool) *ChannelBuilder {
        self.nsfw = is_nsfw;
        return self;
    }

    pub fn rateLimit(self: *ChannelBuilder, seconds: u32) *ChannelBuilder {
        self.rate_limit_per_user = seconds;
        return self;
    }

    pub fn bitrate(self: *ChannelBuilder, bits: u32) *ChannelBuilder {
        self.bitrate = bits;
        return self;
    }

    pub fn userLimit(self: *ChannelBuilder, limit: u32) *ChannelBuilder {
        self.user_limit = limit;
        return self;
    }

    pub fn parent(self: *ChannelBuilder, category_id: u64) *ChannelBuilder {
        self.parent_id = category_id;
        return self;
    }

    pub fn autoArchiveDuration(self: *ChannelBuilder, minutes: u32) *ChannelBuilder {
        self.default_auto_archive_duration = minutes;
        return self;
    }

    pub fn build(self: *ChannelBuilder) !models.Channel {
        return models.Channel{
            .id = 0, // Would be assigned by Discord
            .type = self.type,
            .guild_id = null, // Would be assigned by Discord
            .position = self.position,
            .permission_overwrites = try self.allocator.dupe(models.PermissionOverwrite, self.permission_overwrites.items),
            .name = try self.allocator.dupe(u8, self.name),
            .topic = if (self.topic) |topic| try self.allocator.dupe(u8, topic) else null,
            .nsfw = self.nsfw,
            .last_message_id = null,
            .bitrate = self.bitrate,
            .user_limit = self.user_limit,
            .rate_limit_per_user = self.rate_limit_per_user,
            .recipients = try self.allocator.dupe(models.User, &[_]models.User{}),
            .icon = null,
            .owner_id = null,
            .application_id = null,
            .parent_id = self.parent_id,
            .last_pin_timestamp = null,
            .rtc_region = null,
            .video_quality_mode = null,
            .message_count = null,
            .member_count = null,
            .default_auto_archive_duration = self.default_auto_archive_duration,
            .permissions = null,
            .flags = null,
        };
    }

    pub fn validate(self: *ChannelBuilder) !void {
        // Validate name length
        if (self.name.len > 100) {
            return error.NameTooLong;
        }

        // Validate topic length for text channels
        if (self.type == 0 and self.topic) |topic| { // GUILD_TEXT
            if (topic.len > 1024) {
                return error.TopicTooLong;
            }
        }

        // Validate bitrate for voice channels
        if (self.type == 2) { // GUILD_VOICE
            if (self.bitrate) |bitrate| {
                if (bitrate < 8000 or bitrate > 128000) {
                    return error.InvalidBitrate;
                }
            }
        }

        // Validate user limit for voice channels
        if (self.type == 2) { // GUILD_VOICE
            if (self.user_limit) |limit| {
                if (limit > 99) {
                    return error.InvalidUserLimit;
                }
            }
        }

        // Validate rate limit for text channels
        if ((self.type == 0 or self.type == 5) and self.rate_limit_per_user) |rate_limit| { // GUILD_TEXT or GUILD_PUBLIC_THREAD
            if (rate_limit > 21600) {
                return error.InvalidRateLimit;
            }
        }
    }
};

/// Fluent role builder with comprehensive permission management
pub const RoleBuilder = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    color: u32 = 0,
    hoist: bool = false,
    position: ?u32 = null,
    permissions: utils.Permissions,
    mentionable: bool = false,
    icon: ?[]const u8 = null,
    unicode_emoji: ?[]const u8 = null,

    pub fn init(allocator: std.mem.Allocator, name: []const u8) RoleBuilder {
        return RoleBuilder{
            .allocator = allocator,
            .name = name,
            .permissions = utils.Permissions.init(0),
        };
    }

    pub fn deinit(self: *RoleBuilder) void {
        self.allocator.free(self.name);
        if (self.icon) |icon| self.allocator.free(icon);
        if (self.unicode_emoji) |emoji| self.allocator.free(emoji);
    }

    pub fn color(self: *RoleBuilder, color: u32) *RoleBuilder {
        self.color = color;
        return self;
    }

    pub fn colorRgb(self: *RoleBuilder, r: u8, g: u8, b: u8) *RoleBuilder {
        self.color = (@as(u32, r) << 16) | (@as(u32, g) << 8) | b;
        return self;
    }

    pub fn colorHex(self: *RoleBuilder, hex: []const u8) !*RoleBuilder {
        const color = try utils.Color.parseHex(hex);
        self.color = color.toRgb();
        return self;
    }

    pub fn hoist(self: *RoleBuilder, is_hoisted: bool) *RoleBuilder {
        self.hoist = is_hoisted;
        return self;
    }

    pub fn position(self: *RoleBuilder, pos: u32) *RoleBuilder {
        self.position = pos;
        return self;
    }

    pub fn permissions(self: *RoleBuilder, perms: u64) *RoleBuilder {
        self.permissions = utils.Permissions.init(perms);
        return self;
    }

    pub fn addPermission(self: *RoleBuilder, permission: u64) *RoleBuilder {
        self.permissions.add(permission);
        return self;
    }

    pub fn removePermission(self: *RoleBuilder, permission: u64) *RoleBuilder {
        self.permissions.remove(permission);
        return self;
    }

    pub fn mentionable(self: *RoleBuilder, is_mentionable: bool) *RoleBuilder {
        self.mentionable = is_mentionable;
        return self;
    }

    pub fn icon(self: *RoleBuilder, icon_data: []const u8) !*RoleBuilder {
        if (self.icon) |old_icon| self.allocator.free(old_icon);
        self.icon = try self.allocator.dupe(u8, icon_data);
        return self;
    }

    pub fn unicodeEmoji(self: *RoleBuilder, emoji: []const u8) !*RoleBuilder {
        if (self.unicode_emoji) |old_emoji| self.allocator.free(old_emoji);
        self.unicode_emoji = try self.allocator.dupe(u8, emoji);
        return self;
    }

    pub fn build(self: *RoleBuilder) !models.Role {
        const permissions_str = try self.permissions.toString(self.allocator);
        defer self.allocator.free(permissions_str);

        return models.Role{
            .id = 0, // Would be assigned by Discord
            .name = try self.allocator.dupe(u8, self.name),
            .color = self.color,
            .hoist = self.hoist,
            .position = self.position orelse 0,
            .permissions = permissions_str,
            .managed = false,
            .mentionable = self.mentionable,
            .icon = if (self.icon) |icon| try self.allocator.dupe(u8, icon) else null,
            .unicode_emoji = if (self.unicode_emoji) |emoji| try self.allocator.dupe(u8, emoji) else null,
        };
    }

    pub fn validate(self: *RoleBuilder) !void {
        // Validate name length
        if (self.name.len > 100) {
            return error.NameTooLong;
        }

        // Validate that we don't have both icon and unicode emoji
        if (self.icon != null and self.unicode_emoji != null) {
            return error.IconAndEmojiConflict;
        }
    }
};
