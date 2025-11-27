const std = @import("std");
const models = @import("../../models.zig");

/// Message-related gateway events
pub const MessageEvents = struct {
    /// Message create event
    pub const MessageCreateEvent = struct {
        id: u64,
        channel_id: u64,
        author: models.User,
        content: []const u8,
        timestamp: []const u8,
        edited_timestamp: ?[]const u8,
        tts: bool,
        mention_everyone: bool,
        mentions: []models.User,
        mention_roles: []u64,
        mention_channels: ?[]models.ChannelMention,
        attachments: []models.Attachment,
        embeds: []models.Embed,
        reactions: ?[]models.Reaction,
        nonce: ?std.json.Value,
        pinned: bool,
        webhook_id: ?u64,
        type: models.MessageType,
        activity: ?models.MessageActivity,
        application: ?models.MessageApplication,
        application_id: ?u64,
        message_reference: ?models.MessageReference,
        flags: ?u32,
        referenced_message: ?MessageEvents.MessageCreateEvent,
        interaction: ?models.MessageInteraction,
        thread: ?models.Channel,
        components: ?[]models.MessageComponent,
        sticker_items: ?[]models.StickerItem,
        stickers: ?[]models.Sticker,
        position: ?u32,
        role_subscription_data: ?models.RoleSubscriptionData,
    };

    /// Message update event
    pub const MessageUpdateEvent = struct {
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
        nonce: ?std.json.Value,
        pinned: ?bool,
        webhook_id: ?u64,
        type: ?models.MessageType,
        activity: ?models.MessageActivity,
        application: ?models.MessageApplication,
        application_id: ?u64,
        message_reference: ?models.MessageReference,
        flags: ?u32,
        referenced_message: ?MessageEvents.MessageCreateEvent,
        interaction: ?models.MessageInteraction,
        thread: ?models.Channel,
        components: ?[]models.MessageComponent,
        sticker_items: ?[]models.StickerItem,
        stickers: ?[]models.Sticker,
        position: ?u32,
        role_subscription_data: ?models.RoleSubscriptionData,
    };

    /// Message delete event
    pub const MessageDeleteEvent = struct {
        id: u64,
        channel_id: u64,
        guild_id: ?u64,
    };

    /// Message bulk delete event
    pub const MessageBulkDeleteEvent = struct {
        ids: []u64,
        channel_id: u64,
        guild_id: ?u64,
    };

    /// Message reaction add event
    pub const MessageReactionAddEvent = struct {
        user_id: u64,
        channel_id: u64,
        message_id: u64,
        guild_id: ?u64,
        member: ?models.GuildMember,
        emoji: models.PartialEmoji,
        burst: bool,
        burst_colors: ?[][]const u8,
        type: models.ReactionType,
    };

    /// Message reaction remove event
    pub const MessageReactionRemoveEvent = struct {
        user_id: u64,
        channel_id: u64,
        message_id: u64,
        guild_id: ?u64,
        emoji: models.PartialEmoji,
        type: models.ReactionType,
        burst: bool,
    };

    /// Message reaction remove emoji event
    pub const MessageReactionRemoveEmojiEvent = struct {
        channel_id: u64,
        guild_id: ?u64,
        message_id: u64,
        emoji: models.PartialEmoji,
    };

    /// Message reaction remove all event
    pub const MessageReactionRemoveAllEvent = struct {
        channel_id: u64,
        message_id: u64,
        guild_id: ?u64,
    };

    /// Message reaction remove all for emoji event
    pub const MessageReactionRemoveAllEmojiEvent = struct {
        channel_id: u64,
        guild_id: ?u64,
        message_id: u64,
        emoji: models.PartialEmoji,
    };

    /// Message poll vote add event
    pub const MessagePollVoteAddEvent = struct {
        user_id: u64,
        channel_id: u64,
        message_id: u64,
        guild_id: ?u64,
        answer_id: u32,
    };

    /// Message poll vote remove event
    pub const MessagePollVoteRemoveEvent = struct {
        user_id: u64,
        channel_id: u64,
        message_id: u64,
        guild_id: ?u64,
        answer_id: u32,
    };
};

/// Event parsers for message events
pub const MessageEventParsers = struct {
    pub fn parseMessageCreateEvent(data: []const u8, allocator: std.mem.Allocator) !MessageEvents.MessageCreateEvent {
        return try std.json.parseFromSliceLeaky(MessageEvents.MessageCreateEvent, allocator, data, .{});
    }

    pub fn parseMessageUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !MessageEvents.MessageUpdateEvent {
        return try std.json.parseFromSliceLeaky(MessageEvents.MessageUpdateEvent, allocator, data, .{});
    }

    pub fn parseMessageDeleteEvent(data: []const u8, allocator: std.mem.Allocator) !MessageEvents.MessageDeleteEvent {
        return try std.json.parseFromSliceLeaky(MessageEvents.MessageDeleteEvent, allocator, data, .{});
    }

    pub fn parseMessageBulkDeleteEvent(data: []const u8, allocator: std.mem.Allocator) !MessageEvents.MessageBulkDeleteEvent {
        return try std.json.parseFromSliceLeaky(MessageEvents.MessageBulkDeleteEvent, allocator, data, .{});
    }

    pub fn parseMessageReactionAddEvent(data: []const u8, allocator: std.mem.Allocator) !MessageEvents.MessageReactionAddEvent {
        return try std.json.parseFromSliceLeaky(MessageEvents.MessageReactionAddEvent, allocator, data, .{});
    }

    pub fn parseMessageReactionRemoveEvent(data: []const u8, allocator: std.mem.Allocator) !MessageEvents.MessageReactionRemoveEvent {
        return try std.json.parseFromSliceLeaky(MessageEvents.MessageReactionRemoveEvent, allocator, data, .{});
    }

    pub fn parseMessageReactionRemoveEmojiEvent(data: []const u8, allocator: std.mem.Allocator) !MessageEvents.MessageReactionRemoveEmojiEvent {
        return try std.json.parseFromSliceLeaky(MessageEvents.MessageReactionRemoveEmojiEvent, allocator, data, .{});
    }

    pub fn parseMessageReactionRemoveAllEvent(data: []const u8, allocator: std.mem.Allocator) !MessageEvents.MessageReactionRemoveAllEvent {
        return try std.json.parseFromSliceLeaky(MessageEvents.MessageReactionRemoveAllEvent, allocator, data, .{});
    }

    pub fn parseMessageReactionRemoveAllEmojiEvent(data: []const u8, allocator: std.mem.Allocator) !MessageEvents.MessageReactionRemoveAllEmojiEvent {
        return try std.json.parseFromSliceLeaky(MessageEvents.MessageReactionRemoveAllEmojiEvent, allocator, data, .{});
    }

    pub fn parseMessagePollVoteAddEvent(data: []const u8, allocator: std.mem.Allocator) !MessageEvents.MessagePollVoteAddEvent {
        return try std.json.parseFromSliceLeaky(MessageEvents.MessagePollVoteAddEvent, allocator, data, .{});
    }

    pub fn parseMessagePollVoteRemoveEvent(data: []const u8, allocator: std.mem.Allocator) !MessageEvents.MessagePollVoteRemoveEvent {
        return try std.json.parseFromSliceLeaky(MessageEvents.MessagePollVoteRemoveEvent, allocator, data, .{});
    }
};
