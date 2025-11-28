const std = @import("std");
const models = @import("../../models.zig");

/// Webhook-related gateway events
pub const WebhookEvents = struct {
    /// Webhooks update event
    pub const WebhooksUpdateEvent = struct {
        guild_id: u64,
        channel_id: u64,
    };
};

/// Event parsers for webhook events
pub const WebhookEventParsers = struct {
    pub fn parseWebhooksUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !WebhookEvents.WebhooksUpdateEvent {
        return try std.json.parseFromSliceLeaky(WebhookEvents.WebhooksUpdateEvent, allocator, data, .{});
    }
};

/// Webhook event utilities
pub const WebhookEventUtils = struct {
    pub fn formatWebhookUpdateEvent(event: WebhookEvents.WebhooksUpdateEvent) []const u8 {
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "Webhooks updated in guild {d}, channel {d}",
            .{ event.guild_id, event.channel_id },
        );
    }

    pub fn getAffectedGuild(event: WebhookEvents.WebhooksUpdateEvent) u64 {
        return event.guild_id;
    }

    pub fn getAffectedChannel(event: WebhookEvents.WebhooksUpdateEvent) u64 {
        return event.channel_id;
    }

    pub fn validateWebhookUpdateEvent(event: WebhookEvents.WebhooksUpdateEvent) bool {
        return event.guild_id != 0 and event.channel_id != 0;
    }

    pub fn isChannelWebhookUpdate(event: WebhookEvents.WebhooksUpdateEvent) bool {
        return event.channel_id != 0;
    }

    pub fn isGuildWebhookUpdate(event: WebhookEvents.WebhooksUpdateEvent) bool {
        return event.channel_id == 0;
    }

    pub fn getWebhookUpdateType(event: WebhookEvents.WebhooksUpdateEvent) []const u8 {
        if (event.channel_id != 0) {
            return "Channel Webhooks";
        }
        return "Guild Webhooks";
    }

    pub fn getWebhookUpdateSummary(event: WebhookEvents.WebhooksUpdateEvent) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Webhook Update: ");
        try summary.appendSlice(getWebhookUpdateType(event));
        try summary.appendSlice(" - Guild: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.guild_id}));

        if (event.channel_id != 0) {
            try summary.appendSlice(" - Channel: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.channel_id}));
        }

        return summary.toOwnedSlice();
    }
};
