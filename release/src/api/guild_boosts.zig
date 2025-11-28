const std = @import("std");
const models = @import("../models.zig");
const Client = @import("../Client.zig");
const utils = @import("../utils.zig");

/// Guild boost management for server boosting
pub const GuildBoostManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildBoostManager {
        return GuildBoostManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild boost subscriptions
    pub fn getGuildBoostSubscriptions(
        self: *GuildBoostManager,
        guild_id: u64,
        limit: ?usize,
        before: ?u64,
        after: ?u64,
    ) ![]models.BoostSubscription {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/boost-subscriptions",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (limit) |l| {
            try params.append(try std.fmt.allocPrint(self.allocator, "limit={d}", .{l}));
        }
        if (before) |b| {
            try params.append(try std.fmt.allocPrint(self.allocator, "before={d}", .{b}));
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

        return try std.json.parse([]models.BoostSubscription, response.body, .{});
    }

    /// Get guild boost slots
    pub fn getGuildBoostSlots(self: *GuildBoostManager, guild_id: u64) ![]models.BoostSlot {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/boost-slots",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.BoostSlot, response.body, .{});
    }

    /// Get guild premium subscriptions
    pub fn getGuildPremiumSubscriptions(
        self: *GuildBoostManager,
        guild_id: u64,
        limit: ?usize,
        before: ?u64,
        after: ?u64,
    ) ![]models.PremiumSubscription {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/premium-subscriptions",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (limit) |l| {
            try params.append(try std.fmt.allocPrint(self.allocator, "limit={d}", .{l}));
        }
        if (before) |b| {
            try params.append(try std.fmt.allocPrint(self.allocator, "before={d}", .{b}));
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

        return try std.json.parse([]models.PremiumSubscription, response.body, .{});
    }
};

/// Guild boost utilities
pub const GuildBoostUtils = struct {
    pub fn getBoostLevel(boost_count: u32) models.PremiumTier {
        if (boost_count >= 14) return .tier_3;
        if (boost_count >= 7) return .tier_2;
        if (boost_count >= 2) return .tier_1;
        return .none;
    }

    pub fn getBoostLevelName(tier: models.PremiumTier) []const u8 {
        return switch (tier) {
            .none => "No Boosts",
            .tier_1 => "Level 1",
            .tier_2 => "Level 2",
            .tier_3 => "Level 3",
        };
    }

    pub fn getBoostsForTier(tier: models.PremiumTier) u32 {
        return switch (tier) {
            .none => 0,
            .tier_1 => 2,
            .tier_2 => 7,
            .tier_3 => 14,
        };
    }

    pub fn getBoostsUntilNextTier(current_boosts: u32) u32 {
        const current_level = getBoostLevel(current_boosts);
        const next_boosts = switch (current_level) {
            .none => 2,
            .tier_1 => 7,
            .tier_2 => 14,
            .tier_3 => 0, // Already at max
        };

        if (next_boosts == 0) return 0;
        return next_boosts - current_boosts;
    }

    pub fn isBoostActive(subscription: models.BoostSubscription) bool {
        return subscription.status == .active;
    }

    pub fn isBoostGracePeriod(subscription: models.BoostSubscription) bool {
        return subscription.status == .grace_period;
    }

    pub fn getBoostStatus(status: models.BoostSubscriptionStatus) []const u8 {
        return switch (status) {
            .active => "Active",
            .grace_period => "Grace Period",
            .inactive => "Inactive",
        };
    }

    pub fn getBoostSubscriptionTier(subscription: models.BoostSubscription) models.PremiumTier {
        return subscription.plan.tier;
    }

    pub fn getBoostSubscriptionUserId(subscription: models.BoostSubscription) u64 {
        return subscription.user_id;
    }

    pub fn getBoostSubscriptionGuildId(subscription: models.BoostSubscription) u64 {
        return subscription.guild_id;
    }

    pub fn getBoostSubscriptionEndsAt(subscription: models.BoostSubscription) ?[]const u8 {
        return subscription.ends_at;
    }

    pub fn getBoostSubscriptionStartedAt(subscription: models.BoostSubscription) ?[]const u8 {
        return subscription.started_at;
    }

    pub fn isBoostSubscriptionRecurring(subscription: models.BoostSubscription) bool {
        return subscription.recurring;
    }

    pub fn getBoostSubscriptionCooldownEndsAt(subscription: models.BoostSubscription) ?[]const u8 {
        return subscription.cooldown_ends_at;
    }

    pub fn isBoostSubscriptionInCooldown(subscription: models.BoostSubscription) bool {
        return subscription.cooldown_ends_at != null;
    }

    pub fn getBoostSlotTier(slot: models.BoostSlot) models.PremiumTier {
        return slot.plan.tier;
    }

    pub fn getBoostSlotGuildId(slot: models.BoostSlot) u64 {
        return slot.guild_id;
    }

    pub fn getBoostSlotUserId(slot: models.BoostSlot) ?u64 {
        return slot.user_id;
    }

    pub fn isBoostSlotUsed(slot: models.BoostSlot) bool {
        return slot.user_id != null;
    }

    pub fn getBoostSlotUsedSince(slot: models.BoostSlot) ?[]const u8 {
        return slot.used_since;
    }

    pub fn getBoostSlotPremiumUsage(slot: models.BoostSlot) ?[]const u8 {
        return slot.premium_guild_subscription;
    }

    pub fn getPremiumSubscriptionTier(subscription: models.PremiumSubscription) models.PremiumTier {
        return subscription.plan.tier;
    }

    pub fn getPremiumSubscriptionUserId(subscription: models.PremiumSubscription) u64 {
        return subscription.user_id;
    }

    pub fn isPremiumSubscriptionActive(subscription: models.PremiumSubscription) bool {
        return subscription.status == .active;
    }

    pub fn getPremiumSubscriptionStatus(status: models.PremiumSubscriptionStatus) []const u8 {
        return switch (status) {
            .active => "Active",
            .inactive => "Inactive",
        };
    }

    pub fn getPremiumSubscriptionEndsAt(subscription: models.PremiumSubscription) ?[]const u8 {
        return subscription.ends_at;
    }

    pub fn getPremiumSubscriptionStartedAt(subscription: models.PremiumSubscription) ?[]const u8 {
        return subscription.started_at;
    }

    pub fn isPremiumSubscriptionRecurring(subscription: models.PremiumSubscription) bool {
        return subscription.recurring;
    }

    pub fn formatBoostSummary(subscription: models.BoostSubscription) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Boost for User: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{subscription.user_id}));
        try summary.appendSlice(" - Guild: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{subscription.guild_id}));
        try summary.appendSlice(" - Tier: ");
        try summary.appendSlice(getBoostLevelName(getBoostSubscriptionTier(subscription)));
        try summary.appendSlice(" - Status: ");
        try summary.appendSlice(getBoostStatus(subscription.status));

        if (isBoostSubscriptionInCooldown(subscription)) {
            try summary.appendSlice(" [Cooldown]");
        }

        if (isBoostSubscriptionRecurring(subscription)) {
            try summary.appendSlice(" [Recurring]");
        }

        return summary.toOwnedSlice();
    }

    pub fn formatBoostSlotSummary(slot: models.BoostSlot) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Boost Slot - Tier: ");
        try summary.appendSlice(getBoostLevelName(getBoostSlotTier(slot)));
        try summary.appendSlice(" - Guild: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{slot.guild_id}));

        if (isBoostSlotUsed(slot)) {
            try summary.appendSlice(" - Used by: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{slot.user_id.?}));
            try summary.appendSlice(" since ");
            try summary.appendSlice(slot.used_since.?);
        } else {
            try summary.appendSlice(" - Available");
        }

        return summary.toOwnedSlice();
    }

    pub fn formatPremiumSubscriptionSummary(subscription: models.PremiumSubscription) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Premium Subscription - User: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{subscription.user_id}));
        try summary.appendSlice(" - Tier: ");
        try summary.appendSlice(getBoostLevelName(getPremiumSubscriptionTier(subscription)));
        try summary.appendSlice(" - Status: ");
        try summary.appendSlice(getPremiumSubscriptionStatus(subscription.status));

        if (isPremiumSubscriptionRecurring(subscription)) {
            try summary.appendSlice(" [Recurring]");
        }

        return summary.toOwnedSlice();
    }

    pub fn validateBoostSubscription(subscription: models.BoostSubscription) bool {
        if (subscription.user_id == 0) return false;
        if (subscription.guild_id == 0) return false;
        if (subscription.plan.tier == .none) return false;

        return true;
    }

    pub fn validateBoostSlot(slot: models.BoostSlot) bool {
        if (slot.guild_id == 0) return false;
        if (slot.plan.tier == .none) return false;

        return true;
    }

    pub fn validatePremiumSubscription(subscription: models.PremiumSubscription) bool {
        if (subscription.user_id == 0) return false;
        if (subscription.plan.tier == .none) return false;

        return true;
    }

    pub fn getActiveBoostSubscriptions(subscriptions: []models.BoostSubscription) []models.BoostSubscription {
        var active = std.ArrayList(models.BoostSubscription).init(std.heap.page_allocator);
        defer active.deinit();

        for (subscriptions) |subscription| {
            if (isBoostActive(subscription)) {
                active.append(subscription) catch {};
            }
        }

        return active.toOwnedSlice() catch &[_]models.BoostSubscription{};
    }

    pub fn getGracePeriodBoostSubscriptions(subscriptions: []models.BoostSubscription) []models.BoostSubscription {
        var grace_period = std.ArrayList(models.BoostSubscription).init(std.heap.page_allocator);
        defer grace_period.deinit();

        for (subscriptions) |subscription| {
            if (isBoostGracePeriod(subscription)) {
                grace_period.append(subscription) catch {};
            }
        }

        return grace_period.toOwnedSlice() catch &[_]models.BoostSubscription{};
    }

    pub fn getBoostSubscriptionsByUser(subscriptions: []models.BoostSubscription, user_id: u64) []models.BoostSubscription {
        var user_subs = std.ArrayList(models.BoostSubscription).init(std.heap.page_allocator);
        defer user_subs.deinit();

        for (subscriptions) |subscription| {
            if (subscription.user_id == user_id) {
                user_subs.append(subscription) catch {};
            }
        }

        return user_subs.toOwnedSlice() catch &[_]models.BoostSubscription{};
    }

    pub fn getBoostSubscriptionsByGuild(subscriptions: []models.BoostSubscription, guild_id: u64) []models.BoostSubscription {
        var guild_subs = std.ArrayList(models.BoostSubscription).init(std.heap.page_allocator);
        defer guild_subs.deinit();

        for (subscriptions) |subscription| {
            if (subscription.guild_id == guild_id) {
                guild_subs.append(subscription) catch {};
            }
        }

        return guild_subs.toOwnedSlice() catch &[_]models.BoostSubscription{};
    }

    pub fn getUsedBoostSlots(slots: []models.BoostSlot) []models.BoostSlot {
        var used = std.ArrayList(models.BoostSlot).init(std.heap.page_allocator);
        defer used.deinit();

        for (slots) |slot| {
            if (isBoostSlotUsed(slot)) {
                used.append(slot) catch {};
            }
        }

        return used.toOwnedSlice() catch &[_]models.BoostSlot{};
    }

    pub fn getAvailableBoostSlots(slots: []models.BoostSlot) []models.BoostSlot {
        var available = std.ArrayList(models.BoostSlot).init(std.heap.page_allocator);
        defer available.deinit();

        for (slots) |slot| {
            if (!isBoostSlotUsed(slot)) {
                available.append(slot) catch {};
            }
        }

        return available.toOwnedSlice() catch &[_]models.BoostSlot{};
    }

    pub fn getBoostSlotsByTier(slots: []models.BoostSlot, tier: models.PremiumTier) []models.BoostSlot {
        var tier_slots = std.ArrayList(models.BoostSlot).init(std.heap.page_allocator);
        defer tier_slots.deinit();

        for (slots) |slot| {
            if (getBoostSlotTier(slot) == tier) {
                tier_slots.append(slot) catch {};
            }
        }

        return tier_slots.toOwnedSlice() catch &[_]models.BoostSlot{};
    }

    pub fn getActivePremiumSubscriptions(subscriptions: []models.PremiumSubscription) []models.PremiumSubscription {
        var active = std.ArrayList(models.PremiumSubscription).init(std.heap.page_allocator);
        defer active.deinit();

        for (subscriptions) |subscription| {
            if (isPremiumSubscriptionActive(subscription)) {
                active.append(subscription) catch {};
            }
        }

        return active.toOwnedSlice() catch &[_]models.PremiumSubscription{};
    }

    pub fn getPremiumSubscriptionsByUser(subscriptions: []models.PremiumSubscription, user_id: u64) []models.PremiumSubscription {
        var user_subs = std.ArrayList(models.PremiumSubscription).init(std.heap.page_allocator);
        defer user_subs.deinit();

        for (subscriptions) |subscription| {
            if (subscription.user_id == user_id) {
                user_subs.append(subscription) catch {};
            }
        }

        return user_subs.toOwnedSlice() catch &[_]models.PremiumSubscription{};
    }

    pub fn getPremiumSubscriptionsByTier(subscriptions: []models.PremiumSubscription, tier: models.PremiumTier) []models.PremiumSubscription {
        var tier_subs = std.ArrayList(models.PremiumSubscription).init(std.heap.page_allocator);
        defer tier_subs.deinit();

        for (subscriptions) |subscription| {
            if (getPremiumSubscriptionTier(subscription) == tier) {
                tier_subs.append(subscription) catch {};
            }
        }

        return tier_subs.toOwnedSlice() catch &[_]models.PremiumSubscription{};
    }

    pub fn getBoostStatistics(subscriptions: []models.BoostSubscription, slots: []models.BoostSlot) struct {
        total_subscriptions: usize,
        active_subscriptions: usize,
        grace_period_subscriptions: usize,
        total_slots: usize,
        used_slots: usize,
        available_slots: usize,
        tier_1_boosts: usize,
        tier_2_boosts: usize,
        tier_3_boosts: usize,
        recurring_boosts: usize,
        cooldown_boosts: usize,
    } {
        var active_count: usize = 0;
        var grace_period_count: usize = 0;
        var tier_1_count: usize = 0;
        var tier_2_count: usize = 0;
        var tier_3_count: usize = 0;
        var recurring_count: usize = 0;
        var cooldown_count: usize = 0;

        for (subscriptions) |subscription| {
            if (isBoostActive(subscription)) active_count += 1;
            if (isBoostGracePeriod(subscription)) grace_period_count += 1;
            if (isBoostSubscriptionRecurring(subscription)) recurring_count += 1;
            if (isBoostSubscriptionInCooldown(subscription)) cooldown_count += 1;

            switch (getBoostSubscriptionTier(subscription)) {
                .tier_1 => tier_1_count += 1,
                .tier_2 => tier_2_count += 1,
                .tier_3 => tier_3_count += 1,
                .none => {},
            }
        }

        const used_slots_count = getUsedBoostSlots(slots).len;
        const available_slots_count = getAvailableBoostSlots(slots).len;

        return .{
            .total_subscriptions = subscriptions.len,
            .active_subscriptions = active_count,
            .grace_period_subscriptions = grace_period_count,
            .total_slots = slots.len,
            .used_slots = used_slots_count,
            .available_slots = available_slots_count,
            .tier_1_boosts = tier_1_count,
            .tier_2_boosts = tier_2_count,
            .tier_3_boosts = tier_3_count,
            .recurring_boosts = recurring_count,
            .cooldown_boosts = cooldown_count,
        };
    }

    pub fn getPremiumStatistics(subscriptions: []models.PremiumSubscription) struct {
        total_subscriptions: usize,
        active_subscriptions: usize,
        inactive_subscriptions: usize,
        tier_1_subscriptions: usize,
        tier_2_subscriptions: usize,
        tier_3_subscriptions: usize,
        recurring_subscriptions: usize,
    } {
        var active_count: usize = 0;
        var tier_1_count: usize = 0;
        var tier_2_count: usize = 0;
        var tier_3_count: usize = 0;
        var recurring_count: usize = 0;

        for (subscriptions) |subscription| {
            if (isPremiumSubscriptionActive(subscription)) active_count += 1;
            if (isPremiumSubscriptionRecurring(subscription)) recurring_count += 1;

            switch (getPremiumSubscriptionTier(subscription)) {
                .tier_1 => tier_1_count += 1,
                .tier_2 => tier_2_count += 1,
                .tier_3 => tier_3_count += 1,
                .none => {},
            }
        }

        return .{
            .total_subscriptions = subscriptions.len,
            .active_subscriptions = active_count,
            .inactive_subscriptions = subscriptions.len - active_count,
            .tier_1_subscriptions = tier_1_count,
            .tier_2_subscriptions = tier_2_count,
            .tier_3_subscriptions = tier_3_count,
            .recurring_subscriptions = recurring_count,
        };
    }
};
