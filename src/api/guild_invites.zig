const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild invite management for server invitation operations
pub const GuildInviteManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildInviteManager {
        return GuildInviteManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get invite
    pub fn getInvite(self: *GuildInviteManager, invite_code: []const u8, with_counts: bool, with_expiration: bool) !models.Invite {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/invites/{s}",
            .{ self.client.base_url, invite_code },
        );
        defer self.allocator.free(url);

        var query_params = std.ArrayList([]const u8).init(self.allocator);
        defer query_params.deinit();

        if (with_counts) {
            try query_params.append("with_counts=true");
        }

        if (with_expiration) {
            try query_params.append("with_expiration=true");
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

        return try std.json.parse(models.Invite, response.body, .{});
    }

    /// Delete invite
    pub fn deleteInvite(
        self: *GuildInviteManager,
        invite_code: []const u8,
        reason: ?[]const u8,
    ) !models.Invite {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/invites/{s}",
            .{ self.client.base_url, invite_code },
        );
        defer self.allocator.free(url);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Invite, response.body, .{});
    }

    /// Get guild invite count
    pub fn getGuildInviteCount(self: *GuildInviteManager, guild_id: u64) !struct {
        total: u32,
        online: u32,
    } {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/invites",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(struct {
            total: u32,
            online: u32,
        }, response.body, .{});
    }

    /// Get channel invites
    pub fn getChannelInvites(self: *GuildInviteManager, channel_id: u64) ![]models.Invite {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/invites",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Invite, response.body, .{});
    }

    /// Create channel invite
    pub fn createChannelInvite(
        self: *GuildInviteManager,
        channel_id: u64,
        max_age: ?u32,
        max_uses: ?u32,
        temporary: bool,
        unique: bool,
        target_type: ?u8,
        target_user_id: ?u64,
        target_application_id: ?u64,
    ) !models.Invite {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/invites",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const payload = struct {
            max_age: ?u32,
            max_uses: ?u32,
            temporary: bool,
            unique: bool,
            target_type: ?u8,
            target_user_id: ?u64,
            target_application_id: ?u64,
        }{
            .max_age = max_age,
            .max_uses = max_uses,
            .temporary = temporary,
            .unique = unique,
            .target_type = target_type,
            .target_user_id = target_user_id,
            .target_application_id = target_application_id,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Invite, response.body, .{});
    }

    /// Get guild invites
    pub fn getGuildInvites(self: *GuildInviteManager, guild_id: u64) ![]models.Invite {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/invites",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Invite, response.body, .{});
    }
};

/// Guild invite utilities
pub const GuildInviteUtils = struct {
    pub fn getInviteCode(invite: models.Invite) []const u8 {
        return invite.code;
    }

    pub fn getInviteGuild(invite: models.Invite) ?models.Guild {
        return invite.guild;
    }

    pub fn getInviteGuildId(invite: models.Invite) ?u64 {
        if (invite.guild) |guild| {
            return guild.id;
        }
        return null;
    }

    pub fn getInviteChannel(invite: models.Invite) ?models.Channel {
        return invite.channel;
    }

    pub fn getInviteChannelId(invite: models.Invite) ?u64 {
        if (invite.channel) |channel| {
            return channel.id;
        }
        return null;
    }

    pub fn getInviteInviter(invite: models.Invite) ?models.User {
        return invite.inviter;
    }

    pub fn getInviteInviterId(invite: models.Invite) ?u64 {
        if (invite.inviter) |inviter| {
            return inviter.id;
        }
        return null;
    }

    pub fn getInviteTargetType(invite: models.Invite) ?u8 {
        return invite.target_type;
    }

    pub fn getInviteTargetUser(invite: models.Invite) ?models.User {
        return invite.target_user;
    }

    pub fn getInviteTargetUserId(invite: models.Invite) ?u64 {
        if (invite.target_user) |user| {
            return user.id;
        }
        return null;
    }

    pub fn getInviteTargetApplication(invite: models.Invite) ?models.Application {
        return invite.target_application;
    }

    pub fn getInviteTargetApplicationId(invite: models.Invite) ?u64 {
        if (invite.target_application) |app| {
            return app.id;
        }
        return null;
    }

    pub fn getInviteApproximatePresenceCount(invite: models.Invite) ?u32 {
        return invite.approximate_presence_count;
    }

    pub fn getInviteApproximateMemberCount(invite: models.Invite) ?u32 {
        return invite.approximate_member_count;
    }

    pub fn getInviteExpiresAt(invite: models.Invite) ?[]const u8 {
        return invite.expires_at;
    }

    pub fn getInviteStageInstance(invite: models.Invite) ?models.StageInstance {
        return invite.stage_instance;
    }

    pub fn isInviteExpired(invite: models.Invite) bool {
        if (getInviteExpiresAt(invite)) |_| {
            // This would require date parsing, for now assume not expired
            return false;
        }
        return false;
    }

    pub fn isInviteTemporary(_: models.Invite) bool {
        // This would need to be added to the Invite model
        return false;
    }

    pub fn isInviteTemporaryMembership(_: models.Invite) bool {
        // This would need to be added to the Invite model
        return false;
    }

    pub fn hasInviteGuild(invite: models.Invite) bool {
        return invite.guild != null;
    }

    pub fn hasInviteChannel(invite: models.Invite) bool {
        return invite.channel != null;
    }

    pub fn hasInviteInviter(invite: models.Invite) bool {
        return invite.inviter != null;
    }

    pub fn hasInviteTarget(invite: models.Invite) bool {
        return invite.target_user != null or invite.target_application != null;
    }

    pub fn hasInviteTargetUser(invite: models.Invite) bool {
        return invite.target_user != null;
    }

    pub fn hasInviteTargetApplication(invite: models.Invite) bool {
        return invite.target_application != null;
    }

    pub fn hasInviteStageInstance(invite: models.Invite) bool {
        return invite.stage_instance != null;
    }

    pub fn hasInviteCounts(invite: models.Invite) bool {
        return invite.approximate_presence_count != null and invite.approximate_member_count != null;
    }

    pub fn hasInviteExpiration(invite: models.Invite) bool {
        return invite.expires_at != null;
    }

    pub fn formatInviteUrl(invite: models.Invite) []const u8 {
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "https://discord.gg/{s}",
            .{getInviteCode(invite)},
        );
    }

    pub fn formatInviteSummary(invite: models.Invite) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Invite: ");
        try summary.appendSlice(getInviteCode(invite));

        if (hasInviteGuild(invite)) {
            try summary.appendSlice(" - Guild: ");
            try summary.appendSlice(getInviteGuild(invite).?.name);
        }

        if (hasInviteChannel(invite)) {
            try summary.appendSlice(" - Channel: ");
            try summary.appendSlice(getInviteChannel(invite).?.name);
        }

        if (hasInviteInviter(invite)) {
            try summary.appendSlice(" - Inviter: ");
            try summary.appendSlice(getInviteInviter(invite).?.username);
        }

        if (hasInviteCounts(invite)) {
            try summary.appendSlice(" - Online: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getInviteApproximatePresenceCount(invite).?}));
            try summary.appendSlice("/");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getInviteApproximateMemberCount(invite).?}));
        }

        return summary.toOwnedSlice();
    }

    pub fn validateInviteCode(code: []const u8) bool {
        // Invite codes should be valid length and characters
        return code.len >= 1 and code.len <= 50;
    }

    pub fn validateInvite(invite: models.Invite) bool {
        if (!validateInviteCode(getInviteCode(invite))) return false;
        if (!hasInviteGuild(invite)) return false;
        if (!hasInviteChannel(invite)) return false;

        return true;
    }

    pub fn getInvitesByGuild(invites: []models.Invite, guild_id: u64) []models.Invite {
        var filtered = std.ArrayList(models.Invite).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (invites) |invite| {
            if (getInviteGuildId(invite) == guild_id) {
                filtered.append(invite) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Invite{};
    }

    pub fn getInvitesByChannel(invites: []models.Invite, channel_id: u64) []models.Invite {
        var filtered = std.ArrayList(models.Invite).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (invites) |invite| {
            if (getInviteChannelId(invite) == channel_id) {
                filtered.append(invite) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Invite{};
    }

    pub fn getInvitesByInviter(invites: []models.Invite, inviter_id: u64) []models.Invite {
        var filtered = std.ArrayList(models.Invite).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (invites) |invite| {
            if (getInviteInviterId(invite) == inviter_id) {
                filtered.append(invite) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Invite{};
    }

    pub fn getInvitesByTarget(invites: []models.Invite, target_user_id: u64) []models.Invite {
        var filtered = std.ArrayList(models.Invite).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (invites) |invite| {
            if (getInviteTargetUserId(invite) == target_user_id) {
                filtered.append(invite) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Invite{};
    }

    pub fn getInvitesWithTarget(invites: []models.Invite) []models.Invite {
        var filtered = std.ArrayList(models.Invite).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (invites) |invite| {
            if (hasInviteTarget(invite)) {
                filtered.append(invite) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Invite{};
    }

    pub fn getInvitesWithTargetUser(invites: []models.Invite) []models.Invite {
        var filtered = std.ArrayList(models.Invite).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (invites) |invite| {
            if (hasInviteTargetUser(invite)) {
                filtered.append(invite) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Invite{};
    }

    pub fn getInvitesWithTargetApplication(invites: []models.Invite) []models.Invite {
        var filtered = std.ArrayList(models.Invite).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (invites) |invite| {
            if (hasInviteTargetApplication(invite)) {
                filtered.append(invite) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Invite{};
    }

    pub fn getInvitesWithStageInstance(invites: []models.Invite) []models.Invite {
        var filtered = std.ArrayList(models.Invite).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (invites) |invite| {
            if (hasInviteStageInstance(invite)) {
                filtered.append(invite) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Invite{};
    }

    pub fn getInvitesWithCounts(invites: []models.Invite) []models.Invite {
        var filtered = std.ArrayList(models.Invite).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (invites) |invite| {
            if (hasInviteCounts(invite)) {
                filtered.append(invite) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Invite{};
    }

    pub fn getInvitesWithExpiration(invites: []models.Invite) []models.Invite {
        var filtered = std.ArrayList(models.Invite).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (invites) |invite| {
            if (hasInviteExpiration(invite)) {
                filtered.append(invite) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Invite{};
    }

    pub fn searchInvites(invites: []models.Invite, query: []const u8) []models.Invite {
        var results = std.ArrayList(models.Invite).init(std.heap.page_allocator);
        defer results.deinit();

        for (invites) |invite| {
            if (std.mem.indexOf(u8, getInviteCode(invite), query) != null or
                (hasInviteGuild(invite) and std.mem.indexOf(u8, getInviteGuild(invite).?.name, query) != null) or
                (hasInviteChannel(invite) and std.mem.indexOf(u8, getInviteChannel(invite).?.name, query) != null) or
                (hasInviteInviter(invite) and std.mem.indexOf(u8, getInviteInviter(invite).?.username, query) != null)) {
                results.append(invite) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.Invite{};
    }

    pub fn sortInvitesByCode(invites: []models.Invite) void {
        std.sort.sort(models.Invite, invites, {}, compareInvitesByCode);
    }

    pub fn sortInvitesByGuild(invites: []models.Invite) void {
        std.sort.sort(models.Invite, invites, {}, compareInvitesByGuild);
    }

    pub fn sortInvitesByChannel(invites: []models.Invite) void {
        std.sort.sort(models.Invite, invites, {}, compareInvitesByChannel);
    }

    pub fn sortInvitesByInviter(invites: []models.Invite) void {
        std.sort.sort(models.Invite, invites, {}, compareInvitesByInviter);
    }

    fn compareInvitesByCode(_: void, a: models.Invite, b: models.Invite) std.math.Order {
        return std.mem.compare(u8, getInviteCode(a), getInviteCode(b));
    }

    fn compareInvitesByGuild(_: void, a: models.Invite, b: models.Invite) std.math.Order {
        const a_name = if (hasInviteGuild(a)) getInviteGuild(a).?.name else "";
        const b_name = if (hasInviteGuild(b)) getInviteGuild(b).?.name else "";
        return std.mem.compare(u8, a_name, b_name);
    }

    fn compareInvitesByChannel(_: void, a: models.Invite, b: models.Invite) std.math.Order {
        const a_name = if (hasInviteChannel(a)) getInviteChannel(a).?.name else "";
        const b_name = if (hasInviteChannel(b)) getInviteChannel(b).?.name else "";
        return std.mem.compare(u8, a_name, b_name);
    }

    fn compareInvitesByInviter(_: void, a: models.Invite, b: models.Invite) std.math.Order {
        const a_name = if (hasInviteInviter(a)) getInviteInviter(a).?.username else "";
        const b_name = if (hasInviteInviter(b)) getInviteInviter(b).?.username else "";
        return std.mem.compare(u8, a_name, b_name);
    }

    pub fn getInviteStatistics(invites: []models.Invite) struct {
        total_invites: usize,
        invites_with_target: usize,
        invites_with_target_user: usize,
        invites_with_target_application: usize,
        invites_with_stage_instance: usize,
        invites_with_counts: usize,
        invites_with_expiration: usize,
    } {
        var with_target_count: usize = 0;
        var with_target_user_count: usize = 0;
        var with_target_application_count: usize = 0;
        var with_stage_instance_count: usize = 0;
        var with_counts_count: usize = 0;
        var with_expiration_count: usize = 0;

        for (invites) |invite| {
            if (hasInviteTarget(invite)) {
                with_target_count += 1;
            }

            if (hasInviteTargetUser(invite)) {
                with_target_user_count += 1;
            }

            if (hasInviteTargetApplication(invite)) {
                with_target_application_count += 1;
            }

            if (hasInviteStageInstance(invite)) {
                with_stage_instance_count += 1;
            }

            if (hasInviteCounts(invite)) {
                with_counts_count += 1;
            }

            if (hasInviteExpiration(invite)) {
                with_expiration_count += 1;
            }
        }

        return .{
            .total_invites = invites.len,
            .invites_with_target = with_target_count,
            .invites_with_target_user = with_target_user_count,
            .invites_with_target_application = with_target_application_count,
            .invites_with_stage_instance = with_stage_instance_count,
            .invites_with_counts = with_counts_count,
            .invites_with_expiration = with_expiration_count,
        };
    }

    pub fn hasInvite(invites: []models.Invite, invite_code: []const u8) bool {
        for (invites) |invite| {
            if (std.mem.eql(u8, getInviteCode(invite), invite_code)) {
                return true;
            }
        }
        return false;
    }

    pub fn getInvite(invites: []models.Invite, invite_code: []const u8) ?models.Invite {
        for (invites) |invite| {
            if (std.mem.eql(u8, getInviteCode(invite), invite_code)) {
                return invite;
            }
        }
        return null;
    }

    pub fn getInviteCount(invites: []models.Invite) usize {
        return invites.len;
    }

    pub fn formatFullInviteInfo(invite: models.Invite) []const u8 {
        var info = std.ArrayList(u8).init(std.heap.page_allocator);
        defer info.deinit();

        try info.appendSlice("Invite Code: ");
        try info.appendSlice(getInviteCode(invite));
        try info.appendSlice("\n");
        try info.appendSlice("URL: ");
        try info.appendSlice(formatInviteUrl(invite));
        try info.appendSlice("\n");

        if (hasInviteGuild(invite)) {
            try info.appendSlice("Guild: ");
            try info.appendSlice(getInviteGuild(invite).?.name);
            try info.appendSlice(" (ID: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getInviteGuildId(invite).?}));
            try info.appendSlice(")\n");
        }

        if (hasInviteChannel(invite)) {
            try info.appendSlice("Channel: ");
            try info.appendSlice(getInviteChannel(invite).?.name);
            try info.appendSlice(" (ID: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getInviteChannelId(invite).?}));
            try info.appendSlice(")\n");
        }

        if (hasInviteInviter(invite)) {
            try info.appendSlice("Inviter: ");
            try info.appendSlice(getInviteInviter(invite).?.username);
            try info.appendSlice("#");
            try info.appendSlice(getInviteInviter(invite).?.discriminator);
            try info.appendSlice(" (ID: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getInviteInviterId(invite).?}));
            try info.appendSlice(")\n");
        }

        if (hasInviteTarget(invite)) {
            try info.appendSlice("Target: ");
            if (hasInviteTargetUser(invite)) {
                try info.appendSlice("User: ");
                try info.appendSlice(getInviteTargetUser(invite).?.username);
                try info.appendSlice("#");
                try info.appendSlice(getInviteTargetUser(invite).?.discriminator);
            }
            if (hasInviteTargetApplication(invite)) {
                try info.appendSlice("Application: ");
                try info.appendSlice(getInviteTargetApplication(invite).?.name);
            }
            try info.appendSlice("\n");
        }

        if (hasInviteCounts(invite)) {
            try info.appendSlice("Online Members: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getInviteApproximatePresenceCount(invite).?}));
            try info.appendSlice("\n");
            try info.appendSlice("Total Members: ");
            try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getInviteApproximateMemberCount(invite).?}));
            try info.appendSlice("\n");
        }

        if (hasInviteExpiration(invite)) {
            try info.appendSlice("Expires At: ");
            try info.appendSlice(getInviteExpiresAt(invite).?);
            try info.appendSlice("\n");
        }

        if (hasInviteStageInstance(invite)) {
            try info.appendSlice("Stage Instance: ");
            try info.appendSlice(getInviteStageInstance(invite).?.topic);
            try info.appendSlice("\n");
        }

        return info.toOwnedSlice();
    }
};
