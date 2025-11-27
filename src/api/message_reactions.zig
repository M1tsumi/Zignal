const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Message reaction management for emoji reactions
pub const MessageReactionManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) MessageReactionManager {
        return MessageReactionManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Create reaction
    pub fn createReaction(
        self: *MessageReactionManager,
        channel_id: u64,
        message_id: u64,
        emoji: []const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/reactions/{s}/@me",
            .{ self.client.base_url, channel_id, message_id, emoji },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.put(url, "");
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Delete own reaction
    pub fn deleteOwnReaction(
        self: *MessageReactionManager,
        channel_id: u64,
        message_id: u64,
        emoji: []const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/reactions/{s}/@me",
            .{ self.client.base_url, channel_id, message_id, emoji },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Delete user reaction
    pub fn deleteUserReaction(
        self: *MessageReactionManager,
        channel_id: u64,
        message_id: u64,
        emoji: []const u8,
        user_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/reactions/{s}/{d}",
            .{ self.client.base_url, channel_id, message_id, emoji, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get reactions
    pub fn getReactions(
        self: *MessageReactionManager,
        channel_id: u64,
        message_id: u64,
        emoji: []const u8,
        limit: ?usize,
        after: ?u64,
    ) ![]models.User {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/reactions/{s}",
            .{ self.client.base_url, channel_id, message_id, emoji },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (limit) |l| {
            try params.append(try std.fmt.allocPrint(self.allocator, "limit={d}", .{l}));
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

        return try std.json.parse([]models.User, response.body, .{});
    }

    /// Delete all reactions
    pub fn deleteAllReactions(
        self: *MessageReactionManager,
        channel_id: u64,
        message_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/reactions",
            .{ self.client.base_url, channel_id, message_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Delete emoji reactions
    pub fn deleteEmojiReactions(
        self: *MessageReactionManager,
        channel_id: u64,
        message_id: u64,
        emoji: []const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages/{d}/reactions/{s}",
            .{ self.client.base_url, channel_id, message_id, emoji },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }
};

/// Message reaction utilities
pub const MessageReactionUtils = struct {
    pub fn formatEmoji(emoji: models.Emoji) []const u8 {
        if (emoji.id != 0) {
            return try std.fmt.allocPrint(
                std.heap.page_allocator,
                "<:{s}:{d}>",
                .{ emoji.name, emoji.id },
            );
        } else {
            return emoji.name; // Unicode emoji
        }
    }

    pub fn isCustomEmoji(emoji: models.Emoji) bool {
        return emoji.id != 0;
    }

    pub fn isUnicodeEmoji(emoji: models.Emoji) bool {
        return emoji.id == 0;
    }

    pub fn getEmojiUrl(emoji: models.Emoji) ?[]const u8 {
        if (isCustomEmoji(emoji)) {
            return try std.fmt.allocPrint(
                std.heap.page_allocator,
                "https://cdn.discordapp.com/emojis/{d}.png",
                .{emoji.id},
            );
        }
        return null;
    }

    pub fn getReactionCount(reaction: models.Reaction) u32 {
        return reaction.count;
    }

    pub fn getReactionEmoji(reaction: models.Reaction) models.Emoji {
        return reaction.emoji;
    }

    pub fn isReactionAnimated(reaction: models.Reaction) bool {
        return reaction.emoji.animated;
    }

    pub fn isReactionCustom(reaction: models.Reaction) bool {
        return isCustomEmoji(reaction.emoji);
    }

    pub fn isReactionUnicode(reaction: models.Reaction) bool {
        return isUnicodeEmoji(reaction.emoji);
    }

    pub fn hasUserReacted(reaction: models.Reaction, user_id: u64) bool {
        for (reaction.me_checked) |checked_user_id| {
            if (checked_user_id == user_id) {
                return true;
            }
        }
        return false;
    }

    pub fn getReactedUsers(reaction: models.Reaction) []u64 {
        return reaction.me_checked;
    }

    pub fn formatReactionSummary(reaction: models.Reaction) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(formatEmoji(reaction.emoji));
        try summary.appendSlice(" ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{reaction.count}));

        if (reaction.me) {
            try summary.appendSlice(" (You)");
        }

        return summary.toOwnedSlice();
    }

    pub fn validateReaction(reaction: models.Reaction) bool {
        if (reaction.count == 0) return false;
        if (reaction.emoji.name.len == 0) return false;

        return true;
    }

    pub fn validateEmoji(emoji: models.Emoji) bool {
        if (emoji.name.len == 0) return false;

        // Custom emojis must have an ID
        if (isCustomEmoji(emoji) and emoji.id == 0) {
            return false;
        }

        return true;
    }

    pub fn validateEmojiString(emoji_str: []const u8) bool {
        // Basic validation for emoji string format
        return emoji_str.len > 0 and emoji_str.len <= 100;
    }

    pub fn getReactionsByEmoji(reactions: []models.Reaction, emoji: models.Emoji) ?models.Reaction {
        for (reactions) |reaction| {
            if (reaction.emoji.id == emoji.id and std.mem.eql(u8, reaction.emoji.name, emoji.name)) {
                return reaction;
            }
        }
        return null;
    }

    pub fn getReactionsByEmojiName(reactions: []models.Reaction, emoji_name: []const u8) []models.Reaction {
        var matching = std.ArrayList(models.Reaction).init(std.heap.page_allocator);
        defer matching.deinit();

        for (reactions) |reaction| {
            if (std.mem.eql(u8, reaction.emoji.name, emoji_name)) {
                matching.append(reaction) catch {};
            }
        }

        return matching.toOwnedSlice() catch &[_]models.Reaction{};
    }

    pub fn getCustomEmojiReactions(reactions: []models.Reaction) []models.Reaction {
        var custom = std.ArrayList(models.Reaction).init(std.heap.page_allocator);
        defer custom.deinit();

        for (reactions) |reaction| {
            if (isReactionCustom(reaction)) {
                custom.append(reaction) catch {};
            }
        }

        return custom.toOwnedSlice() catch &[_]models.Reaction{};
    }

    pub fn getUnicodeEmojiReactions(reactions: []models.Reaction) []models.Reaction {
        var unicode = std.ArrayList(models.Reaction).init(std.heap.page_allocator);
        defer unicode.deinit();

        for (reactions) |reaction| {
            if (isReactionUnicode(reaction)) {
                unicode.append(reaction) catch {};
            }
        }

        return unicode.toOwnedSlice() catch &[_]models.Reaction{};
    }

    pub fn getAnimatedReactions(reactions: []models.Reaction) []models.Reaction {
        var animated = std.ArrayList(models.Reaction).init(std.heap.page_allocator);
        defer animated.deinit();

        for (reactions) |reaction| {
            if (isReactionAnimated(reaction)) {
                animated.append(reaction) catch {};
            }
        }

        return animated.toOwnedSlice() catch &[_]models.Reaction{};
    }

    pub fn getReactionsByUser(reactions: []models.Reaction, user_id: u64) []models.Reaction {
        var user_reactions = std.ArrayList(models.Reaction).init(std.heap.page_allocator);
        defer user_reactions.deinit();

        for (reactions) |reaction| {
            if (hasUserReacted(reaction, user_id)) {
                user_reactions.append(reaction) catch {};
            }
        }

        return user_reactions.toOwnedSlice() catch &[_]models.Reaction{};
    }

    pub fn getTopReactions(reactions: []models.Reaction, limit: usize) []models.Reaction {
        var sorted = std.ArrayList(models.Reaction).init(std.heap.page_allocator);
        defer sorted.deinit();

        // Copy reactions
        for (reactions) |reaction| {
            sorted.append(reaction) catch {};
        }

        // Sort by count (descending)
        std.sort.sort(models.Reaction, sorted.items, {}, compareReactionsByCount);

        // Return top N
        const actual_limit = @min(limit, sorted.items.len);
        return sorted.items[0..actual_limit];
    }

    fn compareReactionsByCount(_: void, a: models.Reaction, b: models.Reaction) std.math.Order {
        if (a.count > b.count) return .lt;
        if (a.count < b.count) return .gt;
        return .eq;
    }

    pub fn getReactionStatistics(reactions: []models.Reaction) struct {
        total_reactions: usize,
        total_reacts: u32,
        custom_emoji_reactions: usize,
        unicode_emoji_reactions: usize,
        animated_reactions: usize,
        unique_emojis: usize,
        most_popular_reaction: ?models.Reaction,
    } {
        var total_reacts: u32 = 0;
        var custom_count: usize = 0;
        var unicode_count: usize = 0;
        var animated_count: usize = 0;
        var most_popular: ?models.Reaction = null;

        for (reactions) |reaction| {
            total_reacts += reaction.count;
            
            if (isReactionCustom(reaction)) custom_count += 1;
            if (isReactionUnicode(reaction)) unicode_count += 1;
            if (isReactionAnimated(reaction)) animated_count += 1;
            
            if (most_popular == null or reaction.count > most_popular.?.count) {
                most_popular = reaction;
            }
        }

        return .{
            .total_reactions = reactions.len,
            .total_reacts = total_reacts,
            .custom_emoji_reactions = custom_count,
            .unicode_emoji_reactions = unicode_count,
            .animated_reactions = animated_count,
            .unique_emojis = reactions.len,
            .most_popular_reaction = most_popular,
        };
    }

    pub fn searchReactions(reactions: []models.Reaction, query: []const u8) []models.Reaction {
        var results = std.ArrayList(models.Reaction).init(std.heap.page_allocator);
        defer results.deinit();

        for (reactions) |reaction| {
            if (std.mem.indexOf(u8, reaction.emoji.name, query) != null) {
                results.append(reaction) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.Reaction{};
    }

    pub fn formatEmojiString(emoji: models.Emoji) []const u8 {
        if (isCustomEmoji(emoji)) {
            return try std.fmt.allocPrint(
                std.heap.page_allocator,
                "{s}:{d}",
                .{ emoji.name, emoji.id },
            );
        } else {
            return emoji.name;
        }
    }

    pub fn createEmojiString(name: []const u8, id: ?u64) []const u8 {
        if (id) |emoji_id| {
            return try std.fmt.allocPrint(
                std.heap.page_allocator,
                "{s}:{d}",
                .{ name, emoji_id },
            );
        } else {
            return name;
        }
    }

    pub fn createCustomEmojiString(name: []const u8, id: u64) []const u8 {
        return createEmojiString(name, id);
    }

    pub fn createUnicodeEmojiString(name: []const u8) []const u8 {
        return createEmojiString(name, null);
    }

    pub fn parseEmojiString(emoji_str: []const u8) struct { name: []const u8, id: ?u64 } {
        if (std.mem.indexOf(u8, emoji_str, ":")) |colon_pos| {
            if (std.mem.lastIndexOf(u8, emoji_str, ":")) |last_colon_pos| {
                if (colon_pos != last_colon_pos) {
                    // Format: name:id
                    const name = emoji_str[0..colon_pos];
                    const id_str = emoji_str[last_colon_pos + 1..];
                    const id = std.fmt.parseInt(u64, id_str, 10) catch 0;
                    return .{ .name = name, .id = id };
                }
            }
        }
        
        // Unicode emoji (no ID)
        return .{ .name = emoji_str, .id = null };
    }

    pub fn isValidEmojiString(emoji_str: []const u8) bool {
        const parsed = parseEmojiString(emoji_str);
        
        // Name must be valid
        if (parsed.name.len == 0) return false;
        
        // If ID is present, it must be valid
        if (parsed.id) |id| {
            if (id == 0) return false;
        }
        
        return true;
    }

    pub fn getReactionsAboveCount(reactions: []models.Reaction, threshold: u32) []models.Reaction {
        var filtered = std.ArrayList(models.Reaction).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (reactions) |reaction| {
            if (reaction.count >= threshold) {
                filtered.append(reaction) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Reaction{};
    }

    pub fn getReactionsBelowCount(reactions: []models.Reaction, threshold: u32) []models.Reaction {
        var filtered = std.ArrayList(models.Reaction).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (reactions) |reaction| {
            if (reaction.count <= threshold) {
                filtered.append(reaction) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Reaction{};
    }

    pub fn sortReactionsByCount(reactions: []models.Reaction) void {
        std.sort.sort(models.Reaction, reactions, {}, compareReactionsByCount);
    }

    pub fn sortReactionsByName(reactions: []models.Reaction) void {
        std.sort.sort(models.Reaction, reactions, {}, compareReactionsByName);
    }

    fn compareReactionsByName(_: void, a: models.Reaction, b: models.Reaction) std.math.Order {
        return std.mem.compare(u8, a.emoji.name, b.emoji.name);
    }

    pub fn getUniqueEmojiNames(reactions: []models.Reaction) [][]const u8 {
        var names = std.ArrayList([]const u8).init(std.heap.page_allocator);
        defer names.deinit();

        for (reactions) |reaction| {
            var found = false;
            for (names.items) |name| {
                if (std.mem.eql(u8, name, reaction.emoji.name)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                names.append(reaction.emoji.name) catch {};
            }
        }

        return names.toOwnedSlice() catch &[_][]const u8{};
    }

    pub fn hasCustomEmojiReactions(reactions: []models.Reaction) bool {
        return getCustomEmojiReactions(reactions).len > 0;
    }

    pub fn hasUnicodeEmojiReactions(reactions: []models.Reaction) bool {
        return getUnicodeEmojiReactions(reactions).len > 0;
    }

    pub fn hasAnimatedReactions(reactions: []models.Reaction) bool {
        return getAnimatedReactions(reactions).len > 0;
    }

    pub fn getTotalReactionCount(reactions: []models.Reaction) u32 {
        var total: u32 = 0;
        for (reactions) |reaction| {
            total += reaction.count;
        }
        return total;
    }

    pub fn getAverageReactionCount(reactions: []models.Reaction) f32 {
        if (reactions.len == 0) return 0.0;
        const total = getTotalReactionCount(reactions);
        return @as(f32, @floatFromInt(total)) / @as(f32, @floatFromInt(reactions.len));
    }

    pub fn getMedianReactionCount(reactions: []models.Reaction) u32 {
        if (reactions.len == 0) return 0;
        
        var sorted = std.ArrayList(models.Reaction).init(std.heap.page_allocator);
        defer sorted.deinit();
        
        for (reactions) |reaction| {
            sorted.append(reaction) catch {};
        }
        
        sortReactionsByCount(sorted.items);
        
        const mid = sorted.items.len / 2;
        if (sorted.items.len % 2 == 0) {
            // Even number of items, return average of middle two
            const lower = sorted.items[mid - 1].count;
            const upper = sorted.items[mid].count;
            return (lower + upper) / 2;
        } else {
            // Odd number of items, return middle
            return sorted.items[mid].count;
        }
    }

    pub fn formatFullReactionSummary(reactions: []models.Reaction) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Reactions: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{reactions.len}));
        try summary.appendSlice(" unique, ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getTotalReactionCount(reactions)}));
        try summary.appendSlice(" total reacts");

        if (hasCustomEmojiReactions(reactions)) {
            try summary.appendSlice(" - Custom: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getCustomEmojiReactions(reactions).len}));
        }

        if (hasUnicodeEmojiReactions(reactions)) {
            try summary.appendSlice(" - Unicode: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getUnicodeEmojiReactions(reactions).len}));
        }

        if (hasAnimatedReactions(reactions)) {
            try summary.appendSlice(" - Animated: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getAnimatedReactions(reactions).len}));
        }

        return summary.toOwnedSlice();
    }
};
