const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild audit log management for server moderation tracking
pub const GuildAuditLogManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildAuditLogManager {
        return GuildAuditLogManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild audit logs
    pub fn getGuildAuditLogs(
        self: *GuildAuditLogManager,
        guild_id: u64,
        user_id: ?u64,
        action_type: ?u8,
        before: ?u64,
        limit: ?u32,
    ) !models.AuditLog {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/audit-logs",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var query_params = std.ArrayList([]const u8).init(self.allocator);
        defer query_params.deinit();

        if (user_id) |uid| {
            try query_params.append(try std.fmt.allocPrint(self.allocator, "user_id={d}", .{uid}));
        }

        if (action_type) |action| {
            try query_params.append(try std.fmt.allocPrint(self.allocator, "action_type={d}", .{action}));
        }

        if (before) |before_id| {
            try query_params.append(try std.fmt.allocPrint(self.allocator, "before={d}", .{before_id}));
        }

        if (limit) |lim| {
            try query_params.append(try std.fmt.allocPrint(self.allocator, "limit={d}", .{lim}));
        }

        var full_url = url;
        if (query_params.items.len > 0) {
            full_url = try std.fmt.allocPrint(
                self.allocator,
                "{s}?{s}",
                .{ url, try std.mem.join(self.allocator, "&", query_params.items) },
            );
            defer self.allocator.free(full_url);
        }

        const response = try self.client.http.get(full_url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.AuditLog, response.body, .{});
    }

    /// Get audit log entry by ID
    pub fn getAuditLogEntry(
        self: *GuildAuditLogManager,
        guild_id: u64,
        entry_id: u64,
    ) !models.AuditLogEntry {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/audit-logs/{d}",
            .{ self.client.base_url, guild_id, entry_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.AuditLogEntry, response.body, .{});
    }
};

/// Guild audit log utilities
pub const GuildAuditLogUtils = struct {
    pub fn getAuditLogEntryId(entry: models.AuditLogEntry) u64 {
        return entry.id;
    }

    pub fn getAuditLogEntryActionType(entry: models.AuditLogEntry) u8 {
        return entry.action_type;
    }

    pub fn getAuditLogEntryTargetId(entry: models.AuditLogEntry) ?u64 {
        return entry.target_id;
    }

    pub fn getAuditLogEntryUserId(entry: models.AuditLogEntry) u64 {
        return entry.user_id;
    }

    pub fn getAuditLogEntryUser(entry: models.AuditLogEntry) models.User {
        return entry.user;
    }

    pub fn getAuditLogEntryReason(entry: models.AuditLogEntry) ?[]const u8 {
        return entry.reason;
    }

    pub fn getAuditLogEntryCreatedAt(entry: models.AuditLogEntry) []const u8 {
        return entry.created_at;
    }

    pub fn getAuditLogEntryChanges(entry: models.AuditLogEntry) ?[]models.AuditLogChange {
        return entry.changes;
    }

    pub fn getAuditLogEntryOptions(entry: models.AuditLogEntry) ?models.AuditLogOptions {
        return entry.options;
    }

    pub fn isAuditLogEntryGuildAction(entry: models.AuditLogEntry) bool {
        const action_type = getAuditLogEntryActionType(entry);
        return action_type >= 1 and action_type <= 10;
    }

    pub fn isAuditLogEntryChannelAction(entry: models.AuditLogEntry) bool {
        const action_type = getAuditLogEntryActionType(entry);
        return action_type >= 10 and action_type <= 20;
    }

    pub fn isAuditLogEntryMemberAction(entry: models.AuditLogEntry) bool {
        const action_type = getAuditLogEntryActionType(entry);
        return action_type >= 20 and action_type <= 30;
    }

    pub fn isAuditLogEntryRoleAction(entry: models.AuditLogEntry) bool {
        const action_type = getAuditLogEntryActionType(entry);
        return action_type >= 30 and action_type <= 40;
    }

    pub fn isAuditLogEntryInviteAction(entry: models.AuditLogEntry) bool {
        const action_type = getAuditLogEntryActionType(entry);
        return action_type >= 40 and action_type <= 50;
    }

    pub fn isAuditLogEntryWebhookAction(entry: models.AuditLogEntry) bool {
        const action_type = getAuditLogEntryActionType(entry);
        return action_type >= 50 and action_type <= 60;
    }

    pub fn isAuditLogEntryEmojiAction(entry: models.AuditLogEntry) bool {
        const action_type = getAuditLogEntryActionType(entry);
        return action_type >= 60 and action_type <= 70;
    }

    pub fn isAuditLogEntryMessageAction(entry: models.AuditLogEntry) bool {
        const action_type = getAuditLogEntryActionType(entry);
        return action_type >= 70 and action_type <= 80;
    }

    pub fn isAuditLogEntryIntegrationAction(entry: models.AuditLogEntry) bool {
        const action_type = getAuditLogEntryActionType(entry);
        return action_type >= 80 and action_type <= 90;
    }

    pub fn isAuditLogEntryStageAction(entry: models.AuditLogEntry) bool {
        const action_type = getAuditLogEntryActionType(entry);
        return action_type >= 90 and action_type <= 100;
    }

    pub fn isAuditLogEntryStickerAction(entry: models.AuditLogEntry) bool {
        const action_type = getAuditLogEntryActionType(entry);
        return action_type >= 100 and action_type <= 110;
    }

    pub fn hasAuditLogEntryReason(entry: models.AuditLogEntry) bool {
        return entry.reason != null;
    }

    pub fn hasAuditLogEntryChanges(entry: models.AuditLogEntry) bool {
        return entry.changes != null;
    }

    pub fn hasAuditLogEntryOptions(entry: models.AuditLogEntry) bool {
        return entry.options != null;
    }

    pub fn hasAuditLogEntryTarget(entry: models.AuditLogEntry) bool {
        return entry.target_id != null;
    }

    pub fn getAuditLogActionTypeName(action_type: u8) []const u8 {
        return switch (action_type) {
            1 => "GUILD_UPDATE",
            2 => "CHANNEL_CREATE",
            3 => "CHANNEL_UPDATE",
            4 => "CHANNEL_DELETE",
            5 => "CHANNEL_OVERWRITE_CREATE",
            6 => "CHANNEL_OVERWRITE_UPDATE",
            7 => "CHANNEL_OVERWRITE_DELETE",
            8 => "MEMBER_KICK",
            9 => "MEMBER_PRUNE",
            10 => "MEMBER_BAN_ADD",
            11 => "MEMBER_BAN_REMOVE",
            12 => "MEMBER_UPDATE",
            13 => "MEMBER_ROLE_UPDATE",
            14 => "MEMBER_MOVE",
            15 => "MEMBER_DISCONNECT",
            16 => "BOT_ADD",
            17 => "ROLE_CREATE",
            18 => "ROLE_UPDATE",
            19 => "ROLE_DELETE",
            20 => "INVITE_CREATE",
            21 => "INVITE_UPDATE",
            22 => "INVITE_DELETE",
            23 => "WEBHOOK_CREATE",
            24 => "WEBHOOK_UPDATE",
            25 => "WEBHOOK_DELETE",
            26 => "EMOJI_CREATE",
            27 => "EMOJI_UPDATE",
            28 => "EMOJI_DELETE",
            29 => "MESSAGE_DELETE",
            30 => "MESSAGE_BULK_DELETE",
            31 => "MESSAGE_PIN",
            32 => "MESSAGE_UNPIN",
            33 => "INTEGRATION_CREATE",
            34 => "INTEGRATION_UPDATE",
            35 => "INTEGRATION_DELETE",
            36 => "STAGE_INSTANCE_CREATE",
            37 => "STAGE_INSTANCE_UPDATE",
            38 => "STAGE_INSTANCE_DELETE",
            39 => "STICKER_CREATE",
            40 => "STICKER_UPDATE",
            41 => "STICKER_DELETE",
            42 => "THREAD_CREATE",
            43 => "THREAD_UPDATE",
            44 => "THREAD_DELETE",
            45 => "APPLICATION_COMMAND_PERMISSION_UPDATE",
            46 => "AUTO_MODERATION_RULE_CREATE",
            47 => "AUTO_MODERATION_RULE_UPDATE",
            48 => "AUTO_MODERATION_RULE_DELETE",
            49 => "AUTO_MODERATION_BLOCK_MESSAGE",
            50 => "AUTO_MODERATION_FLAG_TO_CHANNEL",
            51 => "AUTO_MODERATION_USER_COMMUNICATION_DISABLED",
            else => "UNKNOWN",
        };
    }

    pub fn formatAuditLogEntrySummary(entry: models.AuditLogEntry) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(getAuditLogActionTypeName(getAuditLogEntryActionType(entry)));
        try summary.appendSlice(" by ");
        try summary.appendSlice(getAuditLogEntryUser(entry).username);
        try summary.appendSlice("#");
        try summary.appendSlice(getAuditLogEntryUser(entry).discriminator);

        if (hasAuditLogEntryReason(entry)) {
            try summary.appendSlice(" - Reason: ");
            try summary.appendSlice(getAuditLogEntryReason(entry).?);
        }

        return summary.toOwnedSlice();
    }

    pub fn validateAuditLogEntry(entry: models.AuditLogEntry) bool {
        if (getAuditLogEntryId(entry) == 0) return false;
        if (getAuditLogEntryUserId(entry) == 0) return false;
        if (getAuditLogEntryCreatedAt(entry).len == 0) return false;

        return true;
    }

    pub fn getAuditLogEntriesByUser(entries: []models.AuditLogEntry, user_id: u64) []models.AuditLogEntry {
        var filtered = std.ArrayList(models.AuditLogEntry).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (entries) |entry| {
            if (getAuditLogEntryUserId(entry) == user_id) {
                filtered.append(entry) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.AuditLogEntry{};
    }

    pub fn getAuditLogEntriesByActionType(entries: []models.AuditLogEntry, action_type: u8) []models.AuditLogEntry {
        var filtered = std.ArrayList(models.AuditLogEntry).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (entries) |entry| {
            if (getAuditLogEntryActionType(entry) == action_type) {
                filtered.append(entry) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.AuditLogEntry{};
    }

    pub fn getAuditLogEntriesByTarget(entries: []models.AuditLogEntry, target_id: u64) []models.AuditLogEntry {
        var filtered = std.ArrayList(models.AuditLogEntry).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (entries) |entry| {
            if (getAuditLogEntryTargetId(entry)) |target| {
                if (target == target_id) {
                    filtered.append(entry) catch {};
                }
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.AuditLogEntry{};
    }

    pub fn getAuditLogEntriesWithReason(entries: []models.AuditLogEntry) []models.AuditLogEntry {
        var filtered = std.ArrayList(models.AuditLogEntry).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (entries) |entry| {
            if (hasAuditLogEntryReason(entry)) {
                filtered.append(entry) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.AuditLogEntry{};
    }

    pub fn getAuditLogEntriesWithoutReason(entries: []models.AuditLogEntry) []models.AuditLogEntry {
        var filtered = std.ArrayList(models.AuditLogEntry).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (entries) |entry| {
            if (!hasAuditLogEntryReason(entry)) {
                filtered.append(entry) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.AuditLogEntry{};
    }

    pub fn getAuditLogEntriesByActionCategory(entries: []models.AuditLogEntry, category: []const u8) []models.AuditLogEntry {
        var filtered = std.ArrayList(models.AuditLogEntry).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (entries) |entry| {
            const is_category = if (std.mem.eql(u8, category, "guild"))
                isAuditLogEntryGuildAction(entry)
            else if (std.mem.eql(u8, category, "channel"))
                isAuditLogEntryChannelAction(entry)
            else if (std.mem.eql(u8, category, "member"))
                isAuditLogEntryMemberAction(entry)
            else if (std.mem.eql(u8, category, "role"))
                isAuditLogEntryRoleAction(entry)
            else if (std.mem.eql(u8, category, "invite"))
                isAuditLogEntryInviteAction(entry)
            else if (std.mem.eql(u8, category, "webhook"))
                isAuditLogEntryWebhookAction(entry)
            else if (std.mem.eql(u8, category, "emoji"))
                isAuditLogEntryEmojiAction(entry)
            else if (std.mem.eql(u8, category, "message"))
                isAuditLogEntryMessageAction(entry)
            else if (std.mem.eql(u8, category, "integration"))
                isAuditLogEntryIntegrationAction(entry)
            else if (std.mem.eql(u8, category, "stage"))
                isAuditLogEntryStageAction(entry)
            else if (std.mem.eql(u8, category, "sticker"))
                isAuditLogEntryStickerAction(entry)
            else
                false;

            if (is_category) {
                filtered.append(entry) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.AuditLogEntry{};
    }

    pub fn searchAuditLogEntries(entries: []models.AuditLogEntry, query: []const u8) []models.AuditLogEntry {
        var results = std.ArrayList(models.AuditLogEntry).init(std.heap.page_allocator);
        defer results.deinit();

        for (entries) |entry| {
            if (hasAuditLogEntryReason(entry) and std.mem.indexOf(u8, getAuditLogEntryReason(entry).?, query) != null) {
                results.append(entry) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.AuditLogEntry{};
    }

    pub fn sortAuditLogEntriesByDate(entries: []models.AuditLogEntry) void {
        std.sort.sort(models.AuditLogEntry, entries, {}, compareAuditLogEntriesByDate);
    }

    pub fn sortAuditLogEntriesByUser(entries: []models.AuditLogEntry) void {
        std.sort.sort(models.AuditLogEntry, entries, {}, compareAuditLogEntriesByUser);
    }

    pub fn sortAuditLogEntriesByActionType(entries: []models.AuditLogEntry) void {
        std.sort.sort(models.AuditLogEntry, entries, {}, compareAuditLogEntriesByActionType);
    }

    fn compareAuditLogEntriesByDate(_: void, a: models.AuditLogEntry, b: models.AuditLogEntry) std.math.Order {
        return std.mem.compare(u8, getAuditLogEntryCreatedAt(a), getAuditLogEntryCreatedAt(b));
    }

    fn compareAuditLogEntriesByUser(_: void, a: models.AuditLogEntry, b: models.AuditLogEntry) std.math.Order {
        const a_user = getAuditLogEntryUser(a).username;
        const b_user = getAuditLogEntryUser(b).username;
        return std.mem.compare(u8, a_user, b_user);
    }

    fn compareAuditLogEntriesByActionType(_: void, a: models.AuditLogEntry, b: models.AuditLogEntry) std.math.Order {
        return std.math.order(getAuditLogEntryActionType(a), getAuditLogEntryActionType(b));
    }

    pub fn getAuditLogStatistics(entries: []models.AuditLogEntry) struct {
        total_entries: usize,
        entries_with_reason: usize,
        entries_without_reason: usize,
        guild_actions: usize,
        channel_actions: usize,
        member_actions: usize,
        role_actions: usize,
        invite_actions: usize,
        webhook_actions: usize,
        emoji_actions: usize,
        message_actions: usize,
        integration_actions: usize,
        stage_actions: usize,
        sticker_actions: usize,
    } {
        var with_reason_count: usize = 0;
        var guild_count: usize = 0;
        var channel_count: usize = 0;
        var member_count: usize = 0;
        var role_count: usize = 0;
        var invite_count: usize = 0;
        var webhook_count: usize = 0;
        var emoji_count: usize = 0;
        var message_count: usize = 0;
        var integration_count: usize = 0;
        var stage_count: usize = 0;
        var sticker_count: usize = 0;

        for (entries) |entry| {
            if (hasAuditLogEntryReason(entry)) {
                with_reason_count += 1;
            }

            if (isAuditLogEntryGuildAction(entry)) {
                guild_count += 1;
            }

            if (isAuditLogEntryChannelAction(entry)) {
                channel_count += 1;
            }

            if (isAuditLogEntryMemberAction(entry)) {
                member_count += 1;
            }

            if (isAuditLogEntryRoleAction(entry)) {
                role_count += 1;
            }

            if (isAuditLogEntryInviteAction(entry)) {
                invite_count += 1;
            }

            if (isAuditLogEntryWebhookAction(entry)) {
                webhook_count += 1;
            }

            if (isAuditLogEntryEmojiAction(entry)) {
                emoji_count += 1;
            }

            if (isAuditLogEntryMessageAction(entry)) {
                message_count += 1;
            }

            if (isAuditLogEntryIntegrationAction(entry)) {
                integration_count += 1;
            }

            if (isAuditLogEntryStageAction(entry)) {
                stage_count += 1;
            }

            if (isAuditLogEntryStickerAction(entry)) {
                sticker_count += 1;
            }
        }

        return .{
            .total_entries = entries.len,
            .entries_with_reason = with_reason_count,
            .entries_without_reason = entries.len - with_reason_count,
            .guild_actions = guild_count,
            .channel_actions = channel_count,
            .member_actions = member_count,
            .role_actions = role_count,
            .invite_actions = invite_count,
            .webhook_actions = webhook_count,
            .emoji_actions = emoji_count,
            .message_actions = message_count,
            .integration_actions = integration_count,
            .stage_actions = stage_count,
            .sticker_actions = sticker_count,
        };
    }

    pub fn hasAuditLogEntry(entries: []models.AuditLogEntry, entry_id: u64) bool {
        for (entries) |entry| {
            if (getAuditLogEntryId(entry) == entry_id) {
                return true;
            }
        }
        return false;
    }

    pub fn getAuditLogEntry(entries: []models.AuditLogEntry, entry_id: u64) ?models.AuditLogEntry {
        for (entries) |entry| {
            if (getAuditLogEntryId(entry) == entry_id) {
                return entry;
            }
        }
        return null;
    }

    pub fn getAuditLogEntryCount(entries: []models.AuditLogEntry) usize {
        return entries.len;
    }

    pub fn getMostActiveUsers(entries: []models.AuditLogEntry) []struct { user: models.User, action_count: usize } {
        var user_counts = std.hash_map.AutoHashMap(u64, usize).init(std.heap.page_allocator);
        defer user_counts.deinit();

        // Count actions per user
        for (entries) |entry| {
            const user_id = getAuditLogEntryUserId(entry);
            const count = user_counts.get(user_id) orelse 0;
            user_counts.put(user_id, count + 1) catch {};
        }

        // Convert to array and sort by count
        var user_stats = std.ArrayList(struct { user: models.User, action_count: usize }).init(std.heap.page_allocator);
        defer user_stats.deinit();

        var iterator = user_counts.iterator();
        while (iterator.next()) |entry| {
            // Find the user for this ID
            for (entries) |log_entry| {
                if (getAuditLogEntryUserId(log_entry) == entry.key_ptr.*) {
                    user_stats.append(.{ .user = getAuditLogEntryUser(log_entry), .action_count = entry.value_ptr.* }) catch {};
                    break;
                }
            }
        }

        const stats = user_stats.toOwnedSlice() catch &[_]struct { user: models.User, action_count: usize }{};
        std.sort.sort(struct { user: models.User, action_count: usize }, stats, {}, compareUserActionCounts);

        return stats;
    }

    fn compareUserActionCounts(_: void, a: struct { user: models.User, action_count: usize }, b: struct { user: models.User, action_count: usize }) std.math.Order {
        return std.math.order(b.action_count, a.action_count); // Descending order
    }

    pub fn getCommonAuditLogReasons(entries: []models.AuditLogEntry) []struct { reason: []const u8, count: usize } {
        var reason_counts = std.hash_map.StringHashMap(usize).init(std.heap.page_allocator);
        defer reason_counts.deinit();

        // Count occurrences of each reason
        for (entries) |entry| {
            if (getAuditLogEntryReason(entry)) |reason| {
                const count = reason_counts.get(reason) orelse 0;
                reason_counts.put(reason, count + 1) catch {};
            }
        }

        // Convert to array and sort by count
        var common_reasons = std.ArrayList(struct { reason: []const u8, count: usize }).init(std.heap.page_allocator);
        defer common_reasons.deinit();

        var iterator = reason_counts.iterator();
        while (iterator.next()) |entry| {
            common_reasons.append(.{ .reason = entry.key_ptr.*, .count = entry.value_ptr.* }) catch {};
        }

        const reasons = common_reasons.toOwnedSlice() catch &[_]struct { reason: []const u8, count: usize }{};
        std.sort.sort(struct { reason: []const u8, count: usize }, reasons, {}, compareReasonCounts);

        return reasons;
    }

    fn compareReasonCounts(_: void, a: struct { reason: []const u8, count: usize }, b: struct { reason: []const u8, count: usize }) std.math.Order {
        return std.math.order(b.count, a.count); // Descending order
    }

    pub fn formatFullAuditLogEntryInfo(entry: models.AuditLogEntry) []const u8 {
        var info = std.ArrayList(u8).init(std.heap.page_allocator);
        defer info.deinit();

        try info.appendSlice("Audit Log Entry ID: ");
        try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getAuditLogEntryId(entry)}));
        try info.appendSlice("\n");
        try info.appendSlice("Action: ");
        try info.appendSlice(getAuditLogActionTypeName(getAuditLogEntryActionType(entry)));
        try info.appendSlice("\n");
        try info.appendSlice("User: ");
        try info.appendSlice(getAuditLogEntryUser(entry).username);
        try info.appendSlice("#");
        try info.appendSlice(getAuditLogEntryUser(entry).discriminator);
        try info.appendSlice(" (ID: ");
        try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getAuditLogEntryUserId(entry)}));
        try info.appendSlice(")\n");
        try info.appendSlice("Created At: ");
        try info.appendSlice(getAuditLogEntryCreatedAt(entry));
        try info.appendSlice("\n");
        try info.appendSlice("Reason: ");
        try info.appendSlice(getAuditLogEntryReason(entry) orelse "No reason provided");
        try info.appendSlice("\n");

        if (hasAuditLogEntryTarget(entry)) {
            try info.appendSlice("Target ID: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getAuditLogEntryTargetId(entry).?}));
            try info.appendSlice("\n");
        }

        if (hasAuditLogEntryChanges(entry)) {
            try info.appendSlice("Changes: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d} changes", .{getAuditLogEntryChanges(entry).?.len}));
            try info.appendSlice("\n");
        }

        if (hasAuditLogEntryOptions(entry)) {
            try info.appendSlice("Options: Available\n");
        }

        return info.toOwnedSlice();
    }
};
