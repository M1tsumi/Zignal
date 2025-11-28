const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Advanced guild member management operations
pub const GuildMemberManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildMemberManager {
        return GuildMemberManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild members
    pub fn getGuildMembers(
        self: *GuildMemberManager,
        guild_id: u64,
        limit: ?usize,
        after: ?u64,
    ) ![]models.GuildMember {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members",
            .{ self.client.base_url, guild_id },
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

        return try std.json.parse([]models.GuildMember, response.body, .{});
    }

    /// Get guild member
    pub fn getGuildMember(
        self: *GuildMemberManager,
        guild_id: u64,
        user_id: u64,
    ) !models.GuildMember {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildMember, response.body, .{});
    }

    /// Add guild member
    pub fn addGuildMember(
        self: *GuildMemberManager,
        guild_id: u64,
        user_id: u64,
        access_token: []const u8,
        nick: ?[]const u8,
        roles: ?[]u64,
        mute: ?bool,
        deaf: ?bool,
    ) !models.GuildMember {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = AddGuildMemberPayload{
            .access_token = access_token,
            .nick = nick,
            .roles = roles,
            .mute = mute,
            .deaf = deaf,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.put(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildMember, response.body, .{});
    }

    /// Modify guild member
    pub fn modifyGuildMember(
        self: *GuildMemberManager,
        guild_id: u64,
        user_id: u64,
        nick: ?[]const u8,
        roles: ?[]u64,
        mute: ?bool,
        deaf: ?bool,
        channel_id: ?u64,
        communication_disabled_until: ?[]const u8,
        reason: ?[]const u8,
    ) !models.GuildMember {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyGuildMemberPayload{
            .nick = nick,
            .roles = roles,
            .mute = mute,
            .deaf = deaf,
            .channel_id = channel_id,
            .communication_disabled_until = communication_disabled_until,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildMember, response.body, .{});
    }

    /// Modify current member
    pub fn modifyCurrentMember(
        self: *GuildMemberManager,
        guild_id: u64,
        nick: ?[]const u8,
    ) !models.GuildMember {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/@me",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyCurrentMemberPayload{
            .nick = nick,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildMember, response.body, .{});
    }

    /// Add guild member role
    pub fn addGuildMemberRole(
        self: *GuildMemberManager,
        guild_id: u64,
        user_id: u64,
        role_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}/roles/{d}",
            .{ self.client.base_url, guild_id, user_id, role_id },
        );
        defer self.allocator.free(url);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.put(url, "");
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Remove guild member role
    pub fn removeGuildMemberRole(
        self: *GuildMemberManager,
        guild_id: u64,
        user_id: u64,
        role_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}/roles/{d}",
            .{ self.client.base_url, guild_id, user_id, role_id },
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

    /// Remove guild member
    pub fn removeGuildMember(
        self: *GuildMemberManager,
        guild_id: u64,
        user_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/members/{d}",
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

    /// Get guild bans
    pub fn getGuildBans(
        self: *GuildMemberManager,
        guild_id: u64,
        limit: ?usize,
        before: ?u64,
        after: ?u64,
    ) ![]models.Ban {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/bans",
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

        return try std.json.parse([]models.Ban, response.body, .{});
    }

    /// Get guild ban
    pub fn getGuildBan(
        self: *GuildMemberManager,
        guild_id: u64,
        user_id: u64,
    ) !models.Ban {
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
        self: *GuildMemberManager,
        guild_id: u64,
        user_id: u64,
        delete_message_days: ?u8,
        reason: ?[]const u8,
    ) !void {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/bans/{d}",
            .{ self.client.base_url, guild_id, user_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (delete_message_days) |days| {
            try params.append(try std.fmt.allocPrint(self.allocator, "delete_message_days={d}", .{days}));
        }
        if (reason) |r| {
            try params.append(try std.fmt.allocPrint(self.allocator, "reason={s}", .{r}));
        }

        if (params.items.len > 0) {
            try url.appendSlice("?");
            for (params.items, 0..) |param, i| {
                if (i > 0) try url.appendSlice("&");
                try url.appendSlice(param);
            }
        }

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.put(url, "");
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Remove guild ban
    pub fn removeGuildBan(
        self: *GuildMemberManager,
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

    /// Get guild prune count
    pub fn getGuildPruneCount(
        self: *GuildMemberManager,
        guild_id: u64,
        days: ?u8,
        include_roles: ?[]u64,
    ) !struct { pruned: u32 } {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/prune",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (days) |d| {
            try params.append(try std.fmt.allocPrint(self.allocator, "days={d}", .{d}));
        }
        if (include_roles) |roles| {
            for (roles) |role_id| {
                try params.append(try std.fmt.allocPrint(self.allocator, "include_roles={d}", .{role_id}));
            }
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

        return try std.json.parse(struct { pruned: u32 }, response.body, .{});
    }

    /// Begin guild prune
    pub fn beginGuildPrune(
        self: *GuildMemberManager,
        guild_id: u64,
        days: ?u8,
        compute_prune_count: ?bool,
        include_roles: ?[]u64,
        reason: ?[]const u8,
    ) !struct { pruned: ?u32 } {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/prune",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = GuildPrunePayload{
            .days = days,
            .compute_prune_count = compute_prune_count,
            .include_roles = include_roles,
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

        return try std.json.parse(struct { pruned: ?u32 }, response.body, .{});
    }
};

/// Payload for adding guild member
pub const AddGuildMemberPayload = struct {
    access_token: []const u8,
    nick: ?[]const u8 = null,
    roles: ?[]u64 = null,
    mute: ?bool = null,
    deaf: ?bool = null,
};

/// Payload for modifying guild member
pub const ModifyGuildMemberPayload = struct {
    nick: ?[]const u8 = null,
    roles: ?[]u64 = null,
    mute: ?bool = null,
    deaf: ?bool = null,
    channel_id: ?u64 = null,
    communication_disabled_until: ?[]const u8 = null,
};

/// Payload for modifying current member
pub const ModifyCurrentMemberPayload = struct {
    nick: ?[]const u8 = null,
};

/// Payload for guild prune
pub const GuildPrunePayload = struct {
    days: ?u8 = null,
    compute_prune_count: ?bool = null,
    include_roles: ?[]u64 = null,
};

/// Guild member utilities
pub const GuildMemberUtils = struct {
    pub fn getMemberNickname(member: models.GuildMember) []const u8 {
        return member.nick orelse member.user.username;
    }

    pub fn getMemberDisplayName(member: models.GuildMember) []const u8 {
        return member.nick orelse member.user.global_name orelse member.user.username;
    }

    pub fn isMemberOwner(member: models.GuildMember, guild_id: u64) bool {
        return member.user.id == guild_id;
    }

    pub fn isMemberAdmin(member: models.GuildMember, guild_id: u64) bool {
        return isMemberOwner(member, guild_id) or hasMemberPermission(member, .administrator);
    }

    pub fn hasMemberPermission(_: models.GuildMember, _: models.Permission) bool {
        // This would parse the member's permissions and check if the permission is set
        // For now, return a placeholder
        return true;
    }

    pub fn getMemberRoleCount(member: models.GuildMember) usize {
        return member.roles.len;
    }

    pub fn hasMemberRole(member: models.GuildMember, role_id: u64) bool {
        for (member.roles) |member_role_id| {
            if (member_role_id == role_id) {
                return true;
            }
        }
        return false;
    }

    pub fn isMemberOnline(_: models.GuildMember) bool {
        // This would check the member's presence status
        // For now, assume all members are online
        return true;
    }

    pub fn isMemberMuted(member: models.GuildMember) bool {
        return member.mute;
    }

    pub fn isMemberDeafened(member: models.GuildMember) bool {
        return member.deaf;
    }

    pub fn isMemberPending(member: models.GuildMember) bool {
        return member.pending;
    }

    pub fn isMemberTimedOut(member: models.GuildMember) bool {
        return member.communication_disabled_until != null;
    }

    pub fn getMemberJoinDate(member: models.GuildMember) ?[]const u8 {
        return member.joined_at;
    }

    pub fn getMemberPremiumSince(member: models.GuildMember) ?[]const u8 {
        return member.premium_since;
    }

    pub fn isMemberBoosting(member: models.GuildMember) bool {
        return member.premium_since != null;
    }

    pub fn getMemberAvatarUrl(member: models.GuildMember) ?[]const u8 {
        if (member.avatar) |avatar_hash| {
            return try std.fmt.allocPrint(
                std.heap.page_allocator,
                "https://cdn.discordapp.com/guilds/{d}/users/{d}/avatars/{s}.png",
                .{ member.guild_id, member.user.id, avatar_hash },
            );
        }
        return member.user.avatar;
    }

    pub fn formatMemberSummary(member: models.GuildMember) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(getMemberDisplayName(member));
        try summary.appendSlice(" (");
        try summary.appendSlice(member.user.username);
        try summary.appendSlice(")");

        if (member.nick) |nick| {
            try summary.appendSlice(" - Nick: ");
            try summary.appendSlice(nick);
        }

        try summary.appendSlice(" - Roles: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getMemberRoleCount(member)}));

        if (isMemberMuted(member)) try summary.appendSlice(" [Muted]");
        if (isMemberDeafened(member)) try summary.appendSlice(" [Deafened]");
        if (isMemberPending(member)) try summary.appendSlice(" [Pending]");
        if (isMemberTimedOut(member)) try summary.appendSlice(" [Timed Out]");
        if (isMemberBoosting(member)) try summary.appendSlice(" [Boosting]");

        return summary.toOwnedSlice();
    }

    pub fn validateMember(member: models.GuildMember) bool {
        if (member.user.id == 0) return false;
        if (member.guild_id == 0) return false;
        if (member.joined_at == null) return false;

        return true;
    }

    pub fn getMembersByRole(members: []models.GuildMember, role_id: u64) []models.GuildMember {
        var role_members = std.ArrayList(models.GuildMember).init(std.heap.page_allocator);
        defer role_members.deinit();

        for (members) |member| {
            if (hasMemberRole(member, role_id)) {
                role_members.append(member) catch {};
            }
        }

        return role_members.toOwnedSlice() catch &[_]models.GuildMember{};
    }

    pub fn getOnlineMembers(members: []models.GuildMember) []models.GuildMember {
        var online_members = std.ArrayList(models.GuildMember).init(std.heap.page_allocator);
        defer online_members.deinit();

        for (members) |member| {
            if (isMemberOnline(member)) {
                online_members.append(member) catch {};
            }
        }

        return online_members.toOwnedSlice() catch &[_]models.GuildMember{};
    }

    pub fn getMutedMembers(members: []models.GuildMember) []models.GuildMember {
        var muted_members = std.ArrayList(models.GuildMember).init(std.heap.page_allocator);
        defer muted_members.deinit();

        for (members) |member| {
            if (isMemberMuted(member)) {
                muted_members.append(member) catch {};
            }
        }

        return muted_members.toOwnedSlice() catch &[_]models.GuildMember{};
    }

    pub fn getDeafenedMembers(members: []models.GuildMember) []models.GuildMember {
        var deafened_members = std.ArrayList(models.GuildMember).init(std.heap.page_allocator);
        defer deafened_members.deinit();

        for (members) |member| {
            if (isMemberDeafened(member)) {
                deafened_members.append(member) catch {};
            }
        }

        return deafened_members.toOwnedSlice() catch &[_]models.GuildMember{};
    }

    pub fn getPendingMembers(members: []models.GuildMember) []models.GuildMember {
        var pending_members = std.ArrayList(models.GuildMember).init(std.heap.page_allocator);
        defer pending_members.deinit();

        for (members) |member| {
            if (isMemberPending(member)) {
                pending_members.append(member) catch {};
            }
        }

        return pending_members.toOwnedSlice() catch &[_]models.GuildMember{};
    }

    pub fn getBoostingMembers(members: []models.GuildMember) []models.GuildMember {
        var boosting_members = std.ArrayList(models.GuildMember).init(std.heap.page_allocator);
        defer boosting_members.deinit();

        for (members) |member| {
            if (isMemberBoosting(member)) {
                boosting_members.append(member) catch {};
            }
        }

        return boosting_members.toOwnedSlice() catch &[_]models.GuildMember{};
    }

    pub fn getMemberStatistics(members: []models.GuildMember) struct {
        total: usize,
        online: usize,
        offline: usize,
        muted: usize,
        deafened: usize,
        pending: usize,
        boosting: usize,
        timed_out: usize,
    } {
        var stats = struct {
            total: usize = 0,
            online: usize = 0,
            offline: usize = 0,
            muted: usize = 0,
            deafened: usize = 0,
            pending: usize = 0,
            boosting: usize = 0,
            timed_out: usize = 0,
        }{};

        for (members) |member| {
            stats.total += 1;

            if (isMemberOnline(member)) {
                stats.online += 1;
            } else {
                stats.offline += 1;
            }

            if (isMemberMuted(member)) stats.muted += 1;
            if (isMemberDeafened(member)) stats.deafened += 1;
            if (isMemberPending(member)) stats.pending += 1;
            if (isMemberBoosting(member)) stats.boosting += 1;
            if (isMemberTimedOut(member)) stats.timed_out += 1;
        }

        return stats;
    }

    pub fn searchMembers(members: []models.GuildMember, query: []const u8) []models.GuildMember {
        var results = std.ArrayList(models.GuildMember).init(std.heap.page_allocator);
        defer results.deinit();

        for (members) |member| {
            if (std.mem.indexOf(u8, member.user.username, query) != null or
                std.mem.indexOf(u8, getMemberDisplayName(member), query) != null or
                (member.nick != null and std.mem.indexOf(u8, member.nick.?, query) != null))
            {
                results.append(member) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.GuildMember{};
    }

    pub fn getMembersJoinedSince(members: []models.GuildMember, _: u64) []models.GuildMember {
        var filtered = std.ArrayList(models.GuildMember).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (members) |member| {
            if (member.joined_at) |_| {
                // Parse ISO 8601 timestamp and compare
                // For now, assume all members joined after the timestamp
                filtered.append(member) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.GuildMember{};
    }

    pub fn getMembersWithRoleCount(members: []models.GuildMember, min_roles: usize, max_roles: usize) []models.GuildMember {
        var filtered = std.ArrayList(models.GuildMember).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (members) |member| {
            const role_count = getMemberRoleCount(member);
            if (role_count >= min_roles and role_count <= max_roles) {
                filtered.append(member) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.GuildMember{};
    }

    pub fn sortMembersByUsername(members: []models.GuildMember) void {
        std.sort.sort(models.GuildMember, members, {}, compareMembersByUsername);
    }

    pub fn sortMembersByJoinDate(members: []models.GuildMember) void {
        std.sort.sort(models.GuildMember, members, {}, compareMembersByJoinDate);
    }

    fn compareMembersByUsername(_: void, a: models.GuildMember, b: models.GuildMember) std.math.Order {
        return std.mem.compare(u8, a.user.username, b.user.username);
    }

    fn compareMembersByJoinDate(_: void, a: models.GuildMember, b: models.GuildMember) std.math.Order {
        // This would compare join dates
        // For now, compare by username as fallback
        return std.mem.compare(u8, a.user.username, b.user.username);
    }
};
