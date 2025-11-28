const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// User relationship management for friends and blocked users
pub const UserRelationshipManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) UserRelationshipManager {
        return UserRelationshipManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get user relationships
    pub fn getUserRelationships(self: *UserRelationshipManager) ![]models.Relationship {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/relationships",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Relationship, response.body, .{});
    }

    /// Get user's friends
    pub fn getUserFriends(self: *UserRelationshipManager) ![]models.Relationship {
        const relationships = try getUserRelationships(self);
        defer self.allocator.free(relationships);

        var friends = std.ArrayList(models.Relationship).init(self.allocator);
        defer friends.deinit();

        for (relationships) |relationship| {
            if (relationship.type == .friend) {
                friends.append(relationship) catch {};
            }
        }

        return friends.toOwnedSlice();
    }

    /// Get user's blocked users
    pub fn getUserBlockedUsers(self: *UserRelationshipManager) ![]models.Relationship {
        const relationships = try getUserRelationships(self);
        defer self.allocator.free(relationships);

        var blocked = std.ArrayList(models.Relationship).init(self.allocator);
        defer blocked.deinit();

        for (relationships) |relationship| {
            if (relationship.type == .blocked) {
                blocked.append(relationship) catch {};
            }
        }

        return blocked.toOwnedSlice();
    }

    /// Get user's incoming friend requests
    pub fn getUserIncomingFriendRequests(self: *UserRelationshipManager) ![]models.Relationship {
        const relationships = try getUserRelationships(self);
        defer self.allocator.free(relationships);

        var incoming = std.ArrayList(models.Relationship).init(self.allocator);
        defer incoming.deinit();

        for (relationships) |relationship| {
            if (relationship.type == .incoming_friend_request) {
                incoming.append(relationship) catch {};
            }
        }

        return incoming.toOwnedSlice();
    }

    /// Get user's outgoing friend requests
    pub fn getUserOutgoingFriendRequests(self: *UserRelationshipManager) ![]models.Relationship {
        const relationships = try getUserRelationships(self);
        defer self.allocator.free(relationships);

        var outgoing = std.ArrayList(models.Relationship).init(self.allocator);
        defer outgoing.deinit();

        for (relationships) |relationship| {
            if (relationship.type == .outgoing_friend_request) {
                outgoing.append(relationship) catch {};
            }
        }

        return outgoing.toOwnedSlice();
    }

    /// Send friend request
    pub fn sendFriendRequest(
        self: *UserRelationshipManager,
        username: []const u8,
        discriminator: ?[]const u8,
    ) !models.User {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/relationships",
            .{self.client.base_url},
        );
        defer self.allocator.free(url);

        const payload = if (discriminator) |disc| struct {
            username: []const u8,
            discriminator: []const u8,
        }{
            .username = username,
            .discriminator = disc,
        } else struct {
            username: []const u8,
        }{
            .username = username,
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

        return try std.json.parse(models.User, response.body, .{});
    }

    /// Accept friend request
    pub fn acceptFriendRequest(
        self: *UserRelationshipManager,
        user_id: u64,
    ) !models.Relationship {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/relationships/{d}",
            .{ self.client.base_url, user_id },
        );
        defer self.allocator.free(url);

        const payload = struct { type: u32 }{ .type = @intFromEnum(models.RelationshipType.friend) };

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

        return try std.json.parse(models.Relationship, response.body, .{});
    }

    /// Decline friend request
    pub fn declineFriendRequest(
        self: *UserRelationshipManager,
        user_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/relationships/{d}",
            .{ self.client.base_url, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Block user
    pub fn blockUser(
        self: *UserRelationshipManager,
        user_id: u64,
        _: ?[]const u8,
    ) !models.Relationship {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/relationships/{d}",
            .{ self.client.base_url, user_id },
        );
        defer self.allocator.free(url);

        const payload = struct { type: u32 }{ .type = @intFromEnum(models.RelationshipType.blocked) };

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

        return try std.json.parse(models.Relationship, response.body, .{});
    }

    /// Unblock user
    pub fn unblockUser(
        self: *UserRelationshipManager,
        user_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/relationships/{d}",
            .{ self.client.base_url, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Remove friend
    pub fn removeFriend(
        self: *UserRelationshipManager,
        user_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/@me/relationships/{d}",
            .{ self.client.base_url, user_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }
};

/// User relationship utilities
pub const UserRelationshipUtils = struct {
    pub fn getRelationshipType(relationship: models.Relationship) []const u8 {
        return switch (relationship.type) {
            .friend => "Friend",
            .blocked => "Blocked",
            .incoming_friend_request => "Incoming Friend Request",
            .outgoing_friend_request => "Outgoing Friend Request",
        };
    }

    pub fn isFriend(relationship: models.Relationship) bool {
        return relationship.type == .friend;
    }

    pub fn isBlocked(relationship: models.Relationship) bool {
        return relationship.type == .blocked;
    }

    pub fn isIncomingFriendRequest(relationship: models.Relationship) bool {
        return relationship.type == .incoming_friend_request;
    }

    pub fn isOutgoingFriendRequest(relationship: models.Relationship) bool {
        return relationship.type == .outgoing_friend_request;
    }

    pub fn getRelationshipUserId(relationship: models.Relationship) u64 {
        return relationship.user.id;
    }

    pub fn getRelationshipUser(relationship: models.Relationship) models.User {
        return relationship.user;
    }

    pub fn getRelationshipUsername(relationship: models.Relationship) []const u8 {
        return relationship.user.username;
    }

    pub fn getRelationshipGlobalName(relationship: models.Relationship) ?[]const u8 {
        return relationship.user.global_name;
    }

    pub fn getRelationshipDisplayName(relationship: models.Relationship) []const u8 {
        return relationship.user.global_name orelse relationship.user.username;
    }

    pub fn getRelationshipAvatarUrl(relationship: models.Relationship) ?[]const u8 {
        return relationship.user.avatar;
    }

    pub fn getRelationshipDiscriminator(relationship: models.Relationship) []const u8 {
        return relationship.user.discriminator;
    }

    pub fn isRelationshipUserBot(relationship: models.Relationship) bool {
        return relationship.user.bot;
    }

    pub fn isRelationshipUserSystem(relationship: models.Relationship) bool {
        return relationship.user.system;
    }

    pub fn getRelationshipUserFlags(relationship: models.Relationship) u64 {
        return relationship.user.public_flags;
    }

    pub fn hasRelationshipUserFlag(relationship: models.Relationship, flag: u64) bool {
        return (relationship.user.public_flags & flag) != 0;
    }

    pub fn formatRelationshipSummary(relationship: models.Relationship) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(getRelationshipDisplayName(relationship));
        try summary.appendSlice(" (");
        try summary.appendSlice(getRelationshipUsername(relationship));
        try summary.appendSlice("#");
        try summary.appendSlice(getRelationshipDiscriminator(relationship));
        try summary.appendSlice(") - ");
        try summary.appendSlice(getRelationshipType(relationship));

        if (isRelationshipUserBot(relationship)) {
            try summary.appendSlice(" [Bot]");
        }

        if (isRelationshipUserSystem(relationship)) {
            try summary.appendSlice(" [System]");
        }

        return summary.toOwnedSlice();
    }

    pub fn validateRelationship(relationship: models.Relationship) bool {
        if (relationship.user.id == 0) return false;
        if (relationship.user.username.len == 0) return false;
        if (relationship.user.discriminator.len == 0) return false;

        return true;
    }

    pub fn validateUsername(username: []const u8) bool {
        // Usernames must be 2-32 characters
        return username.len >= 2 and username.len <= 32;
    }

    pub fn validateDiscriminator(discriminator: []const u8) bool {
        // Discriminators must be exactly 4 digits
        return discriminator.len == 4 and std.mem.all(u8, std.ascii.isDigit, discriminator);
    }

    pub fn getRelationshipsByType(relationships: []models.Relationship, relationship_type: models.RelationshipType) []models.Relationship {
        var filtered = std.ArrayList(models.Relationship).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (relationships) |relationship| {
            if (relationship.type == relationship_type) {
                filtered.append(relationship) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.Relationship{};
    }

    pub fn getRelationshipsByUsername(relationships: []models.Relationship, username: []const u8) []models.Relationship {
        var matches = std.ArrayList(models.Relationship).init(std.heap.page_allocator);
        defer matches.deinit();

        for (relationships) |relationship| {
            if (std.mem.indexOf(u8, relationship.user.username, username) != null) {
                matches.append(relationship) catch {};
            }
        }

        return matches.toOwnedSlice() catch &[_]models.Relationship{};
    }

    pub fn getRelationshipsByGlobalName(relationships: []models.Relationship, global_name: []const u8) []models.Relationship {
        var matches = std.ArrayList(models.Relationship).init(std.heap.page_allocator);
        defer matches.deinit();

        for (relationships) |relationship| {
            if (relationship.user.global_name) |name| {
                if (std.mem.indexOf(u8, name, global_name) != null) {
                    matches.append(relationship) catch {};
                }
            }
        }

        return matches.toOwnedSlice() catch &[_]models.Relationship{};
    }

    pub fn getRelationshipsByUser(relationships: []models.Relationship, user_id: u64) ?models.Relationship {
        for (relationships) |relationship| {
            if (relationship.user.id == user_id) {
                return relationship;
            }
        }
        return null;
    }

    pub fn getBotRelationships(relationships: []models.Relationship) []models.Relationship {
        var bots = std.ArrayList(models.Relationship).init(std.heap.page_allocator);
        defer bots.deinit();

        for (relationships) |relationship| {
            if (isRelationshipUserBot(relationship)) {
                bots.append(relationship) catch {};
            }
        }

        return bots.toOwnedSlice() catch &[_]models.Relationship{};
    }

    pub fn getSystemRelationships(relationships: []models.Relationship) []models.Relationship {
        var systems = std.ArrayList(models.Relationship).init(std.heap.page_allocator);
        defer systems.deinit();

        for (relationships) |relationship| {
            if (isRelationshipUserSystem(relationship)) {
                systems.append(relationship) catch {};
            }
        }

        return systems.toOwnedSlice() catch &[_]models.Relationship{};
    }

    pub fn getHumanRelationships(relationships: []models.Relationship) []models.Relationship {
        var humans = std.ArrayList(models.Relationship).init(std.heap.page_allocator);
        defer humans.deinit();

        for (relationships) |relationship| {
            if (!isRelationshipUserBot(relationship) and !isRelationshipUserSystem(relationship)) {
                humans.append(relationship) catch {};
            }
        }

        return humans.toOwnedSlice() catch &[_]models.Relationship{};
    }

    pub fn getRelationshipsByFlag(relationships: []models.Relationship, flag: u64) []models.Relationship {
        var flagged = std.ArrayList(models.Relationship).init(std.heap.page_allocator);
        defer flagged.deinit();

        for (relationships) |relationship| {
            if (hasRelationshipUserFlag(relationship, flag)) {
                flagged.append(relationship) catch {};
            }
        }

        return flagged.toOwnedSlice() catch &[_]models.Relationship{};
    }

    pub fn searchRelationships(relationships: []models.Relationship, query: []const u8) []models.Relationship {
        var results = std.ArrayList(models.Relationship).init(std.heap.page_allocator);
        defer results.deinit();

        for (relationships) |relationship| {
            if (std.mem.indexOf(u8, relationship.user.username, query) != null or
                (relationship.user.global_name != null and std.mem.indexOf(u8, relationship.user.global_name.?, query) != null))
            {
                results.append(relationship) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.Relationship{};
    }

    pub fn getRelationshipStatistics(relationships: []models.Relationship) struct {
        total_relationships: usize,
        friends: usize,
        blocked_users: usize,
        incoming_requests: usize,
        outgoing_requests: usize,
        bots: usize,
        systems: usize,
        humans: usize,
    } {
        var friend_count: usize = 0;
        var blocked_count: usize = 0;
        var incoming_count: usize = 0;
        var outgoing_count: usize = 0;
        var bot_count: usize = 0;
        var system_count: usize = 0;
        var human_count: usize = 0;

        for (relationships) |relationship| {
            switch (relationship.type) {
                .friend => friend_count += 1,
                .blocked => blocked_count += 1,
                .incoming_friend_request => incoming_count += 1,
                .outgoing_friend_request => outgoing_count += 1,
            }

            if (isRelationshipUserBot(relationship)) {
                bot_count += 1;
            } else if (isRelationshipUserSystem(relationship)) {
                system_count += 1;
            } else {
                human_count += 1;
            }
        }

        return .{
            .total_relationships = relationships.len,
            .friends = friend_count,
            .blocked_users = blocked_count,
            .incoming_requests = incoming_count,
            .outgoing_requests = outgoing_count,
            .bots = bot_count,
            .systems = system_count,
            .humans = human_count,
        };
    }

    pub fn sortRelationshipsByUsername(relationships: []models.Relationship) void {
        std.sort.sort(models.Relationship, relationships, {}, compareRelationshipsByUsername);
    }

    pub fn sortRelationshipsByType(relationships: []models.Relationship) void {
        std.sort.sort(models.Relationship, relationships, {}, compareRelationshipsByType);
    }

    fn compareRelationshipsByUsername(_: void, a: models.Relationship, b: models.Relationship) std.math.Order {
        return std.mem.compare(u8, a.user.username, b.user.username);
    }

    fn compareRelationshipsByType(_: void, a: models.Relationship, b: models.Relationship) std.math.Order {
        const a_type = @intFromEnum(a.type);
        const b_type = @intFromEnum(b.type);

        if (a_type < b_type) return .lt;
        if (a_type > b_type) return .gt;
        return .eq;
    }

    pub fn hasPendingRequests(relationships: []models.Relationship) bool {
        return getRelationshipsByType(relationships, .incoming_friend_request).len > 0 or
            getRelationshipsByType(relationships, .outgoing_friend_request).len > 0;
    }

    pub fn hasFriends(relationships: []models.Relationship) bool {
        return getRelationshipsByType(relationships, .friend).len > 0;
    }

    pub fn hasBlockedUsers(relationships: []models.Relationship) bool {
        return getRelationshipsByType(relationships, .blocked).len > 0;
    }

    pub fn hasBotFriends(relationships: []models.Relationship) bool {
        const friends = getRelationshipsByType(relationships, .friend);
        for (friends) |friend| {
            if (isRelationshipUserBot(friend)) {
                return true;
            }
        }
        return false;
    }

    pub fn getFriendCount(relationships: []models.Relationship) usize {
        return getRelationshipsByType(relationships, .friend).len;
    }

    pub fn getBlockedCount(relationships: []models.Relationship) usize {
        return getRelationshipsByType(relationships, .blocked).len;
    }

    pub fn getIncomingRequestCount(relationships: []models.Relationship) usize {
        return getRelationshipsByType(relationships, .incoming_friend_request).len;
    }

    pub fn getOutgoingRequestCount(relationships: []models.Relationship) usize {
        return getRelationshipsByType(relationships, .outgoing_friend_request).len;
    }

    pub fn formatUsernameDiscriminator(username: []const u8, discriminator: []const u8) []const u8 {
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "{s}#{s}",
            .{ username, discriminator },
        );
    }

    pub fn parseUsernameDiscriminator(user_tag: []const u8) struct { username: []const u8, discriminator: []const u8 } {
        if (std.mem.lastIndexOf(u8, user_tag, "#")) |hash_pos| {
            if (hash_pos > 0 and hash_pos < user_tag.len - 1) {
                const username = user_tag[0..hash_pos];
                const discriminator = user_tag[hash_pos + 1 ..];
                return .{ .username = username, .discriminator = discriminator };
            }
        }

        return .{ .username = user_tag, .discriminator = "" };
    }

    pub fn isValidUserTag(user_tag: []const u8) bool {
        const parsed = parseUsernameDiscriminator(user_tag);
        return validateUsername(parsed.username) and validateDiscriminator(parsed.discriminator);
    }

    pub fn formatFullRelationshipSummary(relationships: []models.Relationship) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        const stats = getRelationshipStatistics(relationships);

        try summary.appendSlice("Relationships: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{stats.total_relationships}));
        try summary.appendSlice(" total - Friends: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{stats.friends}));
        try summary.appendSlice(", Blocked: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{stats.blocked_users}));
        try summary.appendSlice(", Incoming: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{stats.incoming_requests}));
        try summary.appendSlice(", Outgoing: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{stats.outgoing_requests}));

        if (stats.bots > 0) {
            try summary.appendSlice(" - Bots: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{stats.bots}));
        }

        return summary.toOwnedSlice();
    }
};
