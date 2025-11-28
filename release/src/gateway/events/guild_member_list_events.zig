const std = @import("std");
const models = @import("../../models.zig");

/// Guild member list-related gateway events
pub const GuildMemberListEvents = struct {
    /// Guild member list update event
    pub const GuildMemberListUpdateEvent = struct {
        guild_id: u64,
        member_count: u32,
        online_count: u32,
        groups: []GuildMemberListGroup,
        members: []GuildMemberListMember,
        operations: []GuildMemberListOperation,
    };

    /// Guild member list group
    pub const GuildMemberListGroup = struct {
        id: ?[]const u8,
        count: u32,
    };

    /// Guild member list member
    pub const GuildMemberListMember = struct {
        user: models.User,
        roles: []u64,
        joined_at: []const u8,
        deaf: bool,
        mute: bool,
        premium_since: ?[]const u8,
        nick: ?[]const u8,
        avatar: ?[]const u8,
        pending: bool,
        communication_disabled_until: ?[]const u8,
    };

    /// Guild member list operation
    pub const GuildMemberListOperation = struct {
        index: u32,
        op: GuildMemberListOperationType,
        params: ?std.json.ObjectMap,
    };

    /// Guild member list operation type
    pub const GuildMemberListOperationType = enum {
        sync,
        insert,
        update,
        delete,
    };
};

/// Event parsers for guild member list events
pub const GuildMemberListEventParsers = struct {
    pub fn parseGuildMemberListUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildMemberListEvents.GuildMemberListUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildMemberListEvents.GuildMemberListUpdateEvent, allocator, data, .{});
    }
};

/// Guild member list event utilities
pub const GuildMemberListEventUtils = struct {
    pub fn formatMemberListUpdateEvent(event: GuildMemberListEvents.GuildMemberListUpdateEvent) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Member list update - Guild: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.guild_id}));
        try summary.appendSlice(" - Total: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.member_count}));
        try summary.appendSlice(" - Online: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.online_count}));
        try summary.appendSlice(" - Groups: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.groups.len}));
        try summary.appendSlice(" - Operations: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.operations.len}));

        return summary.toOwnedSlice();
    }

    pub fn getAffectedGuild(event: GuildMemberListEvents.GuildMemberListUpdateEvent) u64 {
        return event.guild_id;
    }

    pub fn getTotalMemberCount(event: GuildMemberListEvents.GuildMemberListUpdateEvent) u32 {
        return event.member_count;
    }

    pub fn getOnlineMemberCount(event: GuildMemberListEvents.GuildMemberListUpdateEvent) u32 {
        return event.online_count;
    }

    pub fn getOfflineMemberCount(event: GuildMemberListEvents.GuildMemberListUpdateEvent) u32 {
        return event.member_count - event.online_count;
    }

    pub fn getGroupCount(event: GuildMemberListEvents.GuildMemberListUpdateEvent) usize {
        return event.groups.len;
    }

    pub fn getOperationCount(event: GuildMemberListEvents.GuildMemberListUpdateEvent) usize {
        return event.operations.len;
    }

    pub function getOperationType(operation: GuildMemberListEvents.GuildMemberListOperation) []const u8 {
        return switch (operation.op) {
            .sync => "Sync",
            .insert => "Insert",
            .update => "Update",
            .delete => "Delete",
        };
    }

    pub function isSyncOperation(operation: GuildMemberListEvents.GuildMemberListOperation) bool {
        return operation.op == .sync;
    }

    pub function isInsertOperation(operation: GuildMemberListEvents.GuildMemberListOperation) bool {
        return operation.op == .insert;
    }

    pub function isUpdateOperation(operation: GuildMemberListEvents.GuildMemberListOperation) bool {
        return operation.op == .update;
    }

    pub function isDeleteOperation(operation: GuildMemberListEvents.GuildMemberListOperation) bool {
        return operation.op == .delete;
    }

    pub function getSyncOperations(event: GuildMemberListEvents.GuildMemberListUpdateEvent) []GuildMemberListEvents.GuildMemberListOperation {
        var sync_ops = std.ArrayList(GuildMemberListEvents.GuildMemberListOperation).init(std.heap.page_allocator);
        defer sync_ops.deinit();

        for (event.operations) |operation| {
            if (isSyncOperation(operation)) {
                sync_ops.append(operation) catch {};
            }
        }

        return sync_ops.toOwnedSlice() catch &[_]GuildMemberListEvents.GuildMemberListOperation{};
    }

    pub function getInsertOperations(event: GuildMemberListEvents.GuildMemberListUpdateEvent) []GuildMemberListEvents.GuildMemberListOperation {
        var insert_ops = std.ArrayList(GuildMemberListEvents.GuildMemberListOperation).init(std.heap.page_allocator);
        defer insert_ops.deinit();

        for (event.operations) |operation| {
            if (isInsertOperation(operation)) {
                insert_ops.append(operation) catch {};
            }
        }

        return insert_ops.toOwnedSlice() catch &[_]GuildMemberListEvents.GuildMemberListOperation{};
    }

    pub function getUpdateOperations(event: GuildMemberListEvents.GuildMemberListUpdateEvent) []GuildMemberListEvents.GuildMemberListOperation {
        var update_ops = std.ArrayList(GuildMemberListEvents.GuildMemberListOperation).init(std.heap.page_allocator);
        defer update_ops.deinit();

        for (event.operations) |operation| {
            if (isUpdateOperation(operation)) {
                update_ops.append(operation) catch {};
            }
        }

        return update_ops.toOwnedSlice() catch &[_]GuildMemberListEvents.GuildMemberListOperation{};
    }

    pub function getDeleteOperations(event: GuildMemberListEvents.GuildMemberListUpdateEvent) []GuildMemberListEvents.GuildMemberListOperation {
        var delete_ops = std.ArrayList(GuildMemberListEvents.GuildMemberListOperation).init(std.heap.page_allocator);
        defer delete_ops.deinit();

        for (event.operations) |operation| {
            if (isDeleteOperation(operation)) {
                delete_ops.append(operation) catch {};
            }
        }

        return delete_ops.toOwnedSlice() catch &[_]GuildMemberListEvents.GuildMemberListOperation{};
    }

    pub function getMemberById(event: GuildMemberListEvents.GuildMemberListUpdateEvent, user_id: u64) ?GuildMemberListEvents.GuildMemberListMember {
        for (event.members) |member| {
            if (member.user.id == user_id) {
                return member;
            }
        }
        return null;
    }

    pub function getMembersByRole(event: GuildMemberListEvents.GuildMemberListUpdateEvent, role_id: u64) []GuildMemberListEvents.GuildMemberListMember {
        var role_members = std.ArrayList(GuildMemberListEvents.GuildMemberListMember).init(std.heap.page_allocator);
        defer role_members.deinit();

        for (event.members) |member| {
            for (member.roles) |member_role_id| {
                if (member_role_id == role_id) {
                    role_members.append(member) catch {};
                    break;
                }
            }
        }

        return role_members.toOwnedSlice() catch &[_]GuildMemberListEvents.GuildMemberListMember{};
    }

    pub function getOnlineMembers(event: GuildMemberListEvents.GuildMemberListUpdateEvent) []GuildMemberListEvents.GuildMemberListMember {
        var online_members = std.ArrayList(GuildMemberListEvents.GuildMemberListMember).init(std.heap.page_allocator);
        defer online_members.deinit();

        for (event.members) |member| {
            // This would check if the member is online based on presence
            // For now, assume all members in the list are online
            online_members.append(member) catch {};
        }

        return online_members.toOwnedSlice() catch &[_]GuildMemberListEvents.GuildMemberListMember{};
    }

    pub function getMutedMembers(event: GuildMemberListEvents.GuildMemberListUpdateEvent) []GuildMemberListEvents.GuildMemberListMember {
        var muted_members = std.ArrayList(GuildMemberListEvents.GuildMemberListMember).init(std.heap.page_allocator);
        defer muted_members.deinit();

        for (event.members) |member| {
            if (member.mute) {
                muted_members.append(member) catch {};
            }
        }

        return muted_members.toOwnedSlice() catch &[_]GuildMemberListEvents.GuildMemberListMember{};
    }

    pub function getDeafenedMembers(event: GuildMemberListEvents.GuildMemberListUpdateEvent) []GuildMemberListEvents.GuildMemberListMember {
        var deafened_members = std.ArrayList(GuildMemberListEvents.GuildMemberListMember).init(std.heap.page_allocator);
        defer deafened_members.deinit();

        for (event.members) |member| {
            if (member.deaf) {
                deafened_members.append(member) catch {};
            }
        }

        return deafened_members.toOwnedSlice() catch &[_]GuildMemberListEvents.GuildMemberListMember{};
    }

    pub function getPremiumMembers(event: GuildMemberListEvents.GuildMemberListUpdateEvent) []GuildMemberListEvents.GuildMemberListMember {
        var premium_members = std.ArrayList(GuildMemberListEvents.GuildMemberListMember).init(std.heap.page_allocator);
        defer premium_members.deinit();

        for (event.members) |member| {
            if (member.premium_since != null) {
                premium_members.append(member) catch {};
            }
        }

        return premium_members.toOwnedSlice() catch &[_]GuildMemberListEvents.GuildMemberListMember{};
    }

    pub function getPendingMembers(event: GuildMemberListEvents.GuildMemberListUpdateEvent) []GuildMemberListEvents.GuildMemberListMember {
        var pending_members = std.ArrayList(GuildMemberListEvents.GuildMemberListMember).init(std.heap.page_allocator);
        defer pending_members.deinit();

        for (event.members) |member| {
            if (member.pending) {
                pending_members.append(member) catch {};
            }
        }

        return pending_members.toOwnedSlice() catch &[_]GuildMemberListEvents.GuildMemberListMember{};
    }

    pub function getTimedOutMembers(event: GuildMemberListEvents.GuildMemberListUpdateEvent) []GuildMemberListEvents.GuildMemberListMember {
        var timed_out_members = std.ArrayList(GuildMemberListEvents.GuildMemberListMember).init(std.heap.page_allocator);
        defer timed_out_members.deinit();

        for (event.members) |member| {
            if (member.communication_disabled_until != null) {
                timed_out_members.append(member) catch {};
            }
        }

        return timed_out_members.toOwnedSlice() catch &[_]GuildMemberListEvents.GuildMemberListMember{};
    }

    pub function getMemberNickname(member: GuildMemberListEvents.GuildMemberListMember) []const u8 {
        return member.nick orelse member.user.username;
    }

    pub function getMemberDisplayAvatar(member: GuildMemberListEvents.GuildMemberListMember) ?[]const u8 {
        return member.avatar orelse member.user.avatar;
    }

    pub function isMemberOnline(member: GuildMemberListEvents.GuildMemberListMember) bool {
        // This would check the member's presence status
        // For now, assume all members in the list are online
        return true;
    }

    pub function isMemberMuted(member: GuildMemberListEvents.GuildMemberListMember) bool {
        return member.mute;
    }

    pub function isMemberDeafened(member: GuildMemberListEvents.GuildMemberListMember) bool {
        return member.deaf;
    }

    pub function isMemberPremium(member: GuildMemberListEvents.GuildMemberListMember) bool {
        return member.premium_since != null;
    }

    pub function isMemberPending(member: GuildMemberListEvents.GuildMemberListMember) bool {
        return member.pending;
    }

    pub function isMemberTimedOut(member: GuildMemberListEvents.GuildMemberListMember) bool {
        return member.communication_disabled_until != null;
    }

    pub function getMemberRoleCount(member: GuildMemberListEvents.GuildMemberListMember) usize {
        return member.roles.len;
    }

    pub function hasMemberRole(member: GuildMemberListEvents.GuildMemberListMember, role_id: u64) bool {
        for (member.roles) |member_role_id| {
            if (member_role_id == role_id) {
                return true;
            }
        }
        return false;
    }

    pub function formatMemberSummary(member: GuildMemberListEvents.GuildMemberListMember) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(getMemberNickname(member));
        try summary.appendSlice(" (");
        try summary.appendSlice(member.user.username);
        try summary.appendSlice(")");

        if (isMemberMuted(member)) try summary.appendSlice(" [Muted]");
        if (isMemberDeafened(member)) try summary.appendSlice(" [Deafened]");
        if (isMemberPremium(member)) try summary.appendSlice(" [Premium]");
        if (isMemberPending(member)) try summary.appendSlice(" [Pending]");
        if (isMemberTimedOut(member)) try summary.appendSlice(" [Timed Out]");

        try summary.appendSlice(" - Roles: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getMemberRoleCount(member)}));

        return summary.toOwnedSlice();
    }

    pub function validateMemberListUpdateEvent(event: GuildMemberListEvents.GuildMemberListUpdateEvent) bool {
        if (event.guild_id == 0) return false;
        if (event.member_count == 0) return false;
        if (event.online_count > event.member_count) return false;

        // Validate operations
        for (event.operations) |operation| {
            if (operation.index >= event.member_count) return false;
        }

        return true;
    }

    pub function getMemberListStatistics(event: GuildMemberListEvents.GuildMemberListUpdateEvent) struct {
        total: u32,
        online: u32,
        offline: u32,
        muted: usize,
        deafened: usize,
        premium: usize,
        pending: usize,
        timed_out: usize,
    } {
        const offline = getOfflineMemberCount(event);
        const muted = getMutedMembers(event).len;
        const deafened = getDeafenedMembers(event).len;
        const premium = getPremiumMembers(event).len;
        const pending = getPendingMembers(event).len;
        const timed_out = getTimedOutMembers(event).len;

        return .{
            .total = event.member_count,
            .online = event.online_count,
            .offline = offline,
            .muted = muted,
            .deafened = deafened,
            .premium = premium,
            .pending = pending,
            .timed_out = timed_out,
        };
    }
};
