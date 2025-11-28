const std = @import("std");
const models = @import("../models.zig");
const Client = @import("../Client.zig");
const utils = @import("../utils.zig");

/// Guild ban management for moderating guild members
pub const GuildBanManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildBanManager {
        return GuildBanManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild bans
    pub fn getGuildBans(self: *GuildBanManager, guild_id: u64) ![]models.Ban {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/bans",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Ban, response.body, .{});
    }

    /// Get guild ban
    pub fn getGuildBan(self: *GuildBanManager, guild_id: u64, user_id: u64) !models.Ban {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/bans/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Ban, response.body, .{});
    }

    /// Create guild ban
    pub fn createGuildBan(
        self: *GuildBanManager,
        guild_id: u64,
        user_id: u64,
        delete_message_days: ?u32,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/bans/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        var query_params = std.ArrayList([]const u8).init(self.allocator);
        defer query_params.deinit();

        if (delete_message_days) |days| {
            try query_params.append(try std.fmt.allocPrint(self.allocator, "delete_message_days={d}", .{days}));
        }

        if (reason) |r| {
            try query_params.append(try std.fmt.allocPrint(self.allocator, "reason={s}", .{r}));
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

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.put(full_url, "");
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Remove guild ban
    pub fn removeGuildBan(
        self: *GuildBanManager,
        guild_id: u64,
        user_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/bans/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Get bulk bans (batch ban lookup)
    pub fn getBulkGuildBans(self: *GuildBanManager, guild_id: u64, user_ids: []u64) ![]models.Ban {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/bans",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        // Convert user IDs to comma-separated string
        var user_id_str = std.ArrayList(u8).init(self.allocator);
        defer user_id_str.deinit();

        for (user_ids, 0..) |user_id, i| {
            if (i > 0) try user_id_str.append(',');
            try user_id_str.writer().print("{d}", .{user_id});
        }

        const full_url = try std.fmt.allocPrint(
            self.allocator,
            "{s}?user_ids={s}",
            .{ url, user_id_str.items },
        );
        defer self.allocator.free(full_url);

        const response = try self.client.http.get(full_url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Ban, response.body, .{});
    }

    /// Create bulk bans (batch ban multiple users)
    pub fn createBulkGuildBans(
        self: *GuildBanManager,
        guild_id: u64,
        user_ids: []u64,
        delete_message_days: ?u32,
        reason: ?[]const u8,
    ) !struct {
        banned_users: []u64,
        failed_users: []u64,
    } {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/bulk-ban",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = struct {
            user_ids: []u64,
            delete_message_days: ?u32,
            reason: ?[]const u8,
        }{
            .user_ids = user_ids,
            .delete_message_days = delete_message_days,
            .reason = reason,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        const result = try std.json.parse(struct {
            banned_users: []u64,
            failed_users: []u64,
        }, response.body, .{});

        return result;
    }
};

/// Guild ban utilities
pub const GuildBanUtils = struct {
    pub fn getBannedUser(ban: models.Ban) models.User {
        return ban.user;
    }

    pub fn getBannedUserId(ban: models.Ban) u64 {
        return ban.user.id;
    }

    pub fn getBannedUsername(ban: models.Ban) []const u8 {
        return ban.user.username;
    }

    pub fn getBannedUserDiscriminator(ban: models.Ban) []const u8 {
        return ban.user.discriminator;
    }

    pub fn getBannedUserGlobalName(ban: models.Ban) ?[]const u8 {
        return ban.user.global_name;
    }

    pub fn getBannedUserDisplayName(ban: models.Ban) []const u8 {
        return ban.user.global_name orelse ban.user.username;
    }

    pub fn getBanReason(ban: models.Ban) ?[]const u8 {
        return ban.reason;
    }

    pub fn isUserBanned(ban: models.Ban) bool {
        return ban.user.id != 0;
    }

    pub fn hasBanReason(ban: models.Ban) bool {
        return ban.reason != null;
    }

    pub fn getBanCreatedAt(_: models.Ban) ?[]const u8 {
        // This would need to be added to the Ban model if Discord provides it
        return null;
    }

    pub fn formatBanSummary(ban: models.Ban) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(getBannedUserDisplayName(ban));
        try summary.appendSlice(" (");
        try summary.appendSlice(getBannedUsername(ban));
        try summary.appendSlice("#");
        try summary.appendSlice(getBannedUserDiscriminator(ban));
        try summary.appendSlice(")");

        if (hasBanReason(ban)) {
            try summary.appendSlice(" - Reason: ");
            try summary.appendSlice(getBanReason(ban).?);
        }

        return summary.toOwnedSlice();
    }

    pub fn validateBan(ban: models.Ban) bool {
        if (getBannedUserId(ban) == 0) return false;
        if (getBannedUsername(ban).len == 0) return false;
        if (getBannedUserDiscriminator(ban).len == 0) return false;

        return true;
    }

    pub fn validateDeleteMessageDays(days: u32) bool {
        // Discord allows 0-7 days of message deletion
        return days <= 7;
    }

    pub fn validateBanReason(reason: []const u8) bool {
        // Ban reasons should be reasonable length
        return reason.len <= 512;
    }

    pub fn getBansByReason(bans: []models.Ban, reason_query: []const u8) []models.Ban {
        var filtered = std.ArrayList(models.Ban).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (bans) |ban| {
            if (getBanReason(ban)) |reason| {
                if (std.mem.indexOf(u8, reason, reason_query) != null) {
                    filtered.append(ban) catch {};
                }
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Ban{};
    }

    pub fn getBansByUsername(bans: []models.Ban, username: []const u8) []models.Ban {
        var filtered = std.ArrayList(models.Ban).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (bans) |ban| {
            if (std.mem.indexOf(u8, getBannedUsername(ban), username) != null) {
                filtered.append(ban) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Ban{};
    }

    pub fn getBansByUser(bans: []models.Ban, user_id: u64) ?models.Ban {
        for (bans) |ban| {
            if (getBannedUserId(ban) == user_id) {
                return ban;
            }
        }
        return null;
    }

    pub fn getBansWithoutReason(bans: []models.Ban) []models.Ban {
        var filtered = std.ArrayList(models.Ban).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (bans) |ban| {
            if (!hasBanReason(ban)) {
                filtered.append(ban) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Ban{};
    }

    pub fn getBansWithReason(bans: []models.Ban) []models.Ban {
        var filtered = std.ArrayList(models.Ban).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (bans) |ban| {
            if (hasBanReason(ban)) {
                filtered.append(ban) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Ban{};
    }

    pub fn getBotBans(bans: []models.Ban) []models.Ban {
        var filtered = std.ArrayList(models.Ban).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (bans) |ban| {
            if (getBannedUser(ban).bot) {
                filtered.append(ban) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Ban{};
    }

    pub fn getHumanBans(bans: []models.Ban) []models.Ban {
        var filtered = std.ArrayList(models.Ban).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (bans) |ban| {
            if (!getBannedUser(ban).bot) {
                filtered.append(ban) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Ban{};
    }

    pub fn searchBans(bans: []models.Ban, query: []const u8) []models.Ban {
        var results = std.ArrayList(models.Ban).init(std.heap.page_allocator);
        defer results.deinit();

        for (bans) |ban| {
            if (std.mem.indexOf(u8, getBannedUsername(ban), query) != null or
                (getBannedUserGlobalName(ban) != null and std.mem.indexOf(u8, getBannedUserGlobalName(ban).?, query) != null) or
                (getBanReason(ban) != null and std.mem.indexOf(u8, getBanReason(ban).?, query) != null))
            {
                results.append(ban) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.Ban{};
    }

    pub fn sortBansByUsername(bans: []models.Ban) void {
        std.sort.sort(models.Ban, bans, {}, compareBansByUsername);
    }

    pub fn sortBansByReason(bans: []models.Ban) void {
        std.sort.sort(models.Ban, bans, {}, compareBansByReason);
    }

    fn compareBansByUsername(_: void, a: models.Ban, b: models.Ban) std.math.Order {
        return std.mem.compare(u8, getBannedUsername(a), getBannedUsername(b));
    }

    fn compareBansByReason(_: void, a: models.Ban, b: models.Ban) std.math.Order {
        const a_reason = getBanReason(a) orelse "";
        const b_reason = getBanReason(b) orelse "";
        return std.mem.compare(u8, a_reason, b_reason);
    }

    pub fn getBanStatistics(bans: []models.Ban) struct {
        total_bans: usize,
        bans_with_reason: usize,
        bans_without_reason: usize,
        bot_bans: usize,
        human_bans: usize,
    } {
        var bans_with_reason_count: usize = 0;
        var bot_bans_count: usize = 0;
        var human_bans_count: usize = 0;

        for (bans) |ban| {
            if (hasBanReason(ban)) {
                bans_with_reason_count += 1;
            }

            if (getBannedUser(ban).bot) {
                bot_bans_count += 1;
            } else {
                human_bans_count += 1;
            }
        }

        return .{
            .total_bans = bans.len,
            .bans_with_reason = bans_with_reason_count,
            .bans_without_reason = bans.len - bans_with_reason_count,
            .bot_bans = bot_bans_count,
            .human_bans = human_bans_count,
        };
    }

    pub fn hasUserBans(bans: []models.Ban, user_id: u64) bool {
        return getBansByUser(bans, user_id) != null;
    }

    pub fn getBanCount(bans: []models.Ban) usize {
        return bans.len;
    }

    pub fn getBannedUserIds(bans: []models.Ban) []u64 {
        var user_ids = std.ArrayList(u64).init(std.heap.page_allocator);
        defer user_ids.deinit();

        for (bans) |ban| {
            user_ids.append(getBannedUserId(ban)) catch {};
        }

        return user_ids.toOwnedSlice() catch &[_]u64{};
    }

    pub fn formatFullBanInfo(ban: models.Ban) []const u8 {
        var info = std.ArrayList(u8).init(std.heap.page_allocator);
        defer info.deinit();

        try info.appendSlice("Banned User: ");
        try info.appendSlice(getBannedUserDisplayName(ban));
        try info.appendSlice("\n");
        try info.appendSlice("Username: ");
        try info.appendSlice(getBannedUsername(ban));
        try info.appendSlice("#");
        try info.appendSlice(getBannedUserDiscriminator(ban));
        try info.appendSlice("\n");
        try info.appendSlice("User ID: ");
        try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getBannedUserId(ban)}));
        try info.appendSlice("\n");
        try info.appendSlice("Reason: ");
        try info.appendSlice(getBanReason(ban) orelse "No reason provided");
        try info.appendSlice("\n");
        try info.appendSlice("Bot: ");
        try info.appendSlice(if (getBannedUser(ban).bot) "Yes" else "No");

        return info.toOwnedSlice();
    }

    pub fn getCommonBanReasons(bans: []models.Ban) []struct { reason: []const u8, count: usize } {
        var reason_counts = std.hash_map.StringHashMap(usize).init(std.heap.page_allocator);
        defer reason_counts.deinit();

        // Count occurrences of each reason
        for (bans) |ban| {
            if (getBanReason(ban)) |reason| {
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
};
