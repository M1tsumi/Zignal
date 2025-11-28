const std = @import("std");
const models = @import("../../models.zig");

/// Guild scheduled event events
pub const GuildScheduledEvents = struct {
    /// Guild scheduled event create event
    pub const GuildScheduledEventCreateEvent = struct {
        guild_scheduled_event: models.GuildScheduledEvent,
    };

    /// Guild scheduled event update event
    pub const GuildScheduledEventUpdateEvent = struct {
        guild_scheduled_event: models.GuildScheduledEvent,
    };

    /// Guild scheduled event delete event
    pub const GuildScheduledEventDeleteEvent = struct {
        guild_scheduled_event: models.GuildScheduledEvent,
    };

    /// Guild scheduled event user add event
    pub const GuildScheduledEventUserAddEvent = struct {
        guild_scheduled_event_id: u64,
        guild_id: u64,
        user_id: u64,
    };

    /// Guild scheduled event user remove event
    pub const GuildScheduledEventUserRemoveEvent = struct {
        guild_scheduled_event_id: u64,
        guild_id: u64,
        user_id: u64,
    };
};

/// Event parsers for guild scheduled events
pub const GuildScheduledEventParsers = struct {
    pub fn parseGuildScheduledEventCreateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildScheduledEvents.GuildScheduledEventCreateEvent {
        return try std.json.parseFromSliceLeaky(GuildScheduledEvents.GuildScheduledEventCreateEvent, allocator, data, .{});
    }

    pub fn parseGuildScheduledEventUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildScheduledEvents.GuildScheduledEventUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildScheduledEvents.GuildScheduledEventUpdateEvent, allocator, data, .{});
    }

    pub fn parseGuildScheduledEventDeleteEvent(data: []const u8, allocator: std.mem.Allocator) !GuildScheduledEvents.GuildScheduledEventDeleteEvent {
        return try std.json.parseFromSliceLeaky(GuildScheduledEvents.GuildScheduledEventDeleteEvent, allocator, data, .{});
    }

    pub fn parseGuildScheduledEventUserAddEvent(data: []const u8, allocator: std.mem.Allocator) !GuildScheduledEvents.GuildScheduledEventUserAddEvent {
        return try std.json.parseFromSliceLeaky(GuildScheduledEvents.GuildScheduledEventUserAddEvent, allocator, data, .{});
    }

    pub fn parseGuildScheduledEventUserRemoveEvent(data: []const u8, allocator: std.mem.Allocator) !GuildScheduledEvents.GuildScheduledEventUserRemoveEvent {
        return try std.json.parseFromSliceLeaky(GuildScheduledEvents.GuildScheduledEventUserRemoveEvent, allocator, data, .{});
    }
};

/// Guild scheduled event utilities
pub const GuildScheduledEventUtils = struct {
    pub fn getEventType(event_type: models.GuildScheduledEventType) []const u8 {
        return switch (event_type) {
            .stage_instance => "Stage Instance",
            .voice => "Voice Channel",
            .external => "External",
        };
    }

    pub fn getEventStatus(status: models.GuildScheduledEventStatus) []const u8 {
        return switch (status) {
            .scheduled => "Scheduled",
            .active => "Active",
            .completed => "Completed",
            .canceled => "Canceled",
        };
    }

    pub fn getEventPrivacyLevel(privacy_level: models.GuildScheduledEventPrivacyLevel) []const u8 {
        return switch (privacy_level) {
            .guild_only => "Guild Only",
        };
    }

    pub fn isEventActive(status: models.GuildScheduledEventStatus) bool {
        return status == .active;
    }

    pub fn isEventCompleted(status: models.GuildScheduledEventStatus) bool {
        return status == .completed;
    }

    pub fn isEventCanceled(status: models.GuildScheduledEventStatus) bool {
        return status == .canceled;
    }

    pub fn isEventScheduled(status: models.GuildScheduledEventStatus) bool {
        return status == .scheduled;
    }

    pub fn isEventInFuture(event: models.GuildScheduledEvent) bool {
        const current_time = @as(u64, @intCast(std.time.timestamp() * 1000));
        return event.scheduled_start_time > current_time;
    }

    pub fn isEventInPast(event: models.GuildScheduledEvent) bool {
        if (event.scheduled_end_time) |end_time| {
            const current_time = @as(u64, @intCast(std.time.timestamp() * 1000));
            return end_time < current_time;
        }
        return false;
    }

    pub fn getEventDuration(event: models.GuildScheduledEvent) ?u64 {
        if (event.scheduled_end_time) |end_time| {
            return end_time - event.scheduled_start_time;
        }
        return null;
    }

    pub fn formatEventDuration(duration_ms: u64) []const u8 {
        const seconds = duration_ms / 1000;
        const minutes = seconds / 60;
        const hours = minutes / 60;
        const days = hours / 24;

        if (days > 0) {
            return try std.fmt.allocPrint(std.heap.page_allocator, "{d}d {d}h {d}m", .{ days, hours % 24, minutes % 60 });
        } else if (hours > 0) {
            return try std.fmt.allocPrint(std.heap.page_allocator, "{d}h {d}m", .{ hours, minutes % 60 });
        } else if (minutes > 0) {
            return try std.fmt.allocPrint(std.heap.page_allocator, "{d}m", .{minutes});
        } else {
            return try std.fmt.allocPrint(std.heap.page_allocator, "{d}s", .{seconds});
        }
    }

    pub fn getTimeUntilEvent(event: models.GuildScheduledEvent) []const u8 {
        const current_time = @as(u64, @intCast(std.time.timestamp() * 1000));
        const time_until = event.scheduled_start_time - current_time;
        return formatEventDuration(time_until);
    }

    pub fn formatEventSummary(event: models.GuildScheduledEvent) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Event: ");
        try summary.appendSlice(event.name);
        try summary.appendSlice(" (");
        try summary.appendSlice(getEventType(event.entity_type));
        try summary.appendSlice(")");

        try summary.appendSlice(" - Status: ");
        try summary.appendSlice(getEventStatus(event.status));

        try summary.appendSlice(" - Privacy: ");
        try summary.appendSlice(getEventPrivacyLevel(event.privacy_level));

        if (event.entity_metadata) |metadata| {
            if (metadata.location) |location| {
                try summary.appendSlice(" - Location: ");
                try summary.appendSlice(location);
            }
        }

        return summary.toOwnedSlice();
    }

    pub fn validateEvent(event: models.GuildScheduledEvent) bool {
        // Basic validation checks
        if (event.id == 0) return false;
        if (event.guild_id == 0) return false;
        if (event.name.len == 0) return false;
        if (event.scheduled_start_time == 0) return false;

        // Validate entity type
        switch (event.entity_type) {
            .stage_instance => {
                if (event.channel_id == null) return false;
            },
            .voice => {
                if (event.channel_id == null) return false;
            },
            .external => {
                if (event.entity_metadata == null) return false;
                if (event.entity_metadata.?.location == null) return false;
            },
        }

        return true;
    }

    pub fn getEventChannel(event: models.GuildScheduledEvent) ?u64 {
        return event.channel_id;
    }

    pub fn getEventLocation(event: models.GuildScheduledEvent) ?[]const u8 {
        if (event.entity_metadata) |metadata| {
            return metadata.location;
        }
        return null;
    }

    pub fn isEventRecurring(event: models.GuildScheduledEvent) bool {
        // Discord doesn't natively support recurring events
        // This would be implemented at the application level
        return false;
    }

    pub fn getEventAttendeeCount(event: models.GuildScheduledEvent) usize {
        return event.user_count;
    }

    pub fn isEventFull(event: models.GuildScheduledEvent) bool {
        // Discord doesn't have a concept of "full" events
        // This would be implemented at the application level
        return false;
    }

    pub fn canUserJoinEvent(event: models.GuildScheduledEvent, user_id: u64) bool {
        // Check if user is already interested
        // This would require checking the event's user list
        // For now, assume all users can join
        return true;
    }

    pub fn getEventImage(event: models.GuildScheduledEvent) ?[]const u8 {
        return event.image;
    }

    pub fn getEventDescription(event: models.GuildScheduledEvent) ?[]const u8 {
        return event.description;
    }

    pub fn getEventCreator(event: models.GuildScheduledEvent) ?u64 {
        return event.creator_id;
    }
};

/// Guild scheduled event tracking
pub const GuildScheduledEventTracker = struct {
    allocator: std.mem.Allocator,
    events: std.hash_map.AutoHashMap(u64, models.GuildScheduledEvent), // event_id -> event
    event_users: std.hash_map.AutoHashMap(u64, std.ArrayList(u64)), // event_id -> user_ids
    user_events: std.hash_map.AutoHashMap(u64, std.ArrayList(u64)), // user_id -> event_ids

    pub fn init(allocator: std.mem.Allocator) GuildScheduledEventTracker {
        return GuildScheduledEventTracker{
            .allocator = allocator,
            .events = std.hash_map.AutoHashMap(u64, models.GuildScheduledEvent).init(allocator),
            .event_users = std.hash_map.AutoHashMap(u64, std.ArrayList(u64)).init(allocator),
            .user_events = std.hash_map.AutoHashMap(u64, std.ArrayList(u64)).init(allocator),
        };
    }

    pub fn deinit(self: *GuildScheduledEventTracker) void {
        var event_iterator = self.event_users.iterator();
        while (event_iterator.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.event_users.deinit();

        var user_iterator = self.user_events.iterator();
        while (user_iterator.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.user_events.deinit();

        self.events.deinit();
    }

    pub fn addEvent(self: *GuildScheduledEventTracker, event: models.GuildScheduledEvent) !void {
        try self.events.put(event.id, event);
    }

    pub fn updateEvent(self: *GuildScheduledEventTracker, event: models.GuildScheduledEvent) !void {
        try self.events.put(event.id, event);
    }

    pub fn removeEvent(self: *GuildScheduledEventTracker, event_id: u64) !void {
        self.events.remove(event_id);

        // Remove all user associations
        if (self.event_users.get(event_id)) |users| {
            for (users.items) |user_id| {
                if (self.user_events.get(user_id)) |events| {
                    for (events.items, 0..) |eid, i| {
                        if (eid == event_id) {
                            _ = events.orderedRemove(i);
                            break;
                        }
                    }
                }
            }
            users.deinit();
        }
        self.event_users.remove(event_id);
    }

    pub fn addUserToEvent(self: *GuildScheduledEventTracker, event_id: u64, user_id: u64) !void {
        const users = try self.event_users.getOrPut(event_id);
        if (!users.found_existing) {
            users.value_ptr.* = std.ArrayList(u64).init(self.allocator);
        }
        try users.value_ptr.append(user_id);

        const events = try self.user_events.getOrPut(user_id);
        if (!events.found_existing) {
            events.value_ptr.* = std.ArrayList(u64).init(self.allocator);
        }
        try events.value_ptr.append(event_id);
    }

    pub fn removeUserFromEvent(self: *GuildScheduledEventTracker, event_id: u64, user_id: u64) !void {
        if (self.event_users.get(event_id)) |users| {
            for (users.items, 0..) |uid, i| {
                if (uid == user_id) {
                    _ = users.orderedRemove(i);
                    break;
                }
            }
        }

        if (self.user_events.get(user_id)) |events| {
            for (events.items, 0..) |eid, i| {
                if (eid == event_id) {
                    _ = events.orderedRemove(i);
                    break;
                }
            }
        }
    }

    pub fn getEvent(self: *GuildScheduledEventTracker, event_id: u64) ?models.GuildScheduledEvent {
        return self.events.get(event_id);
    }

    pub fn getEventUsers(self: *GuildScheduledEventTracker, event_id: u64) ?[]const u64 {
        if (self.event_users.get(event_id)) |users| {
            return users.items;
        }
        return null;
    }

    pub fn getUserEvents(self: *GuildScheduledEventTracker, user_id: u64) ?[]const u64 {
        if (self.user_events.get(user_id)) |events| {
            return events.items;
        }
        return null;
    }

    pub fn getActiveEvents(self: *GuildScheduledEventTracker) ![]u64 {
        var active_events = std.ArrayList(u64).init(self.allocator);
        defer active_events.deinit();

        var iterator = self.events.iterator();
        while (iterator.next()) |entry| {
            if (GuildScheduledEventUtils.isEventActive(entry.value_ptr.status)) {
                try active_events.append(entry.key_ptr.*);
            }
        }

        return active_events.toOwnedSlice();
    }

    pub fn getUpcomingEvents(self: *GuildScheduledEventTracker) ![]u64 {
        var upcoming_events = std.ArrayList(u64).init(self.allocator);
        defer upcoming_events.deinit();

        var iterator = self.events.iterator();
        while (iterator.next()) |entry| {
            if (GuildScheduledEventUtils.isEventInFuture(entry.value_ptr.*) and
                GuildScheduledEventUtils.isEventScheduled(entry.value_ptr.status))
            {
                try upcoming_events.append(entry.key_ptr.*);
            }
        }

        return upcoming_events.toOwnedSlice();
    }

    pub fn getCompletedEvents(self: *GuildScheduledEventTracker) ![]u64 {
        var completed_events = std.ArrayList(u64).init(self.allocator);
        defer completed_events.deinit();

        var iterator = self.events.iterator();
        while (iterator.next()) |entry| {
            if (GuildScheduledEventUtils.isEventCompleted(entry.value_ptr.status)) {
                try completed_events.append(entry.key_ptr.*);
            }
        }

        return completed_events.toOwnedSlice();
    }

    pub fn cleanupCompletedEvents(self: *GuildScheduledEventTracker) !usize {
        var removed_count: usize = 0;

        var events_to_remove = std.ArrayList(u64).init(self.allocator);
        defer events_to_remove.deinit();

        var iterator = self.events.iterator();
        while (iterator.next()) |entry| {
            if (GuildScheduledEventUtils.isEventCompleted(entry.value_ptr.status) or
                GuildScheduledEventUtils.isEventCanceled(entry.value_ptr.status))
            {
                try events_to_remove.append(entry.key_ptr.*);
            }
        }

        for (events_to_remove.items) |event_id| {
            try self.removeEvent(event_id);
            removed_count += 1;
        }

        return removed_count;
    }
};
