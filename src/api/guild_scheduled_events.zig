const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Guild scheduled event management for server events
pub const GuildScheduledEventManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildScheduledEventManager {
        return GuildScheduledEventManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Create a guild scheduled event
    pub fn createGuildScheduledEvent(
        self: *GuildScheduledEventManager,
        guild_id: u64,
        name: []const u8,
        scheduled_start_time: u64,
        entity_type: models.GuildScheduledEventType,
        entity_metadata: ?models.GuildScheduledEventEntityMetadata,
        scheduled_end_time: ?u64,
        description: ?[]const u8,
        channel_id: ?u64,
        image: ?[]const u8, // Base64 encoded image data
        reason: ?[]const u8,
    ) !models.GuildScheduledEvent {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/scheduled-events",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreateGuildScheduledEventPayload{
            .name = name,
            .scheduled_start_time = scheduled_start_time,
            .entity_type = entity_type,
            .entity_metadata = entity_metadata,
            .scheduled_end_time = scheduled_end_time,
            .description = description,
            .channel_id = channel_id,
            .image = image,
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

        return try std.json.parse(models.GuildScheduledEvent, response.body, .{});
    }

    /// Get guild scheduled events
    pub fn getGuildScheduledEvents(
        self: *GuildScheduledEventManager,
        guild_id: u64,
        with_user_count: bool,
    ) ![]models.GuildScheduledEvent {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/scheduled-events?with_user_count={}",
            .{ self.client.base_url, guild_id, with_user_count },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.GuildScheduledEvent, response.body, .{});
    }

    /// Get a guild scheduled event
    pub fn getGuildScheduledEvent(
        self: *GuildScheduledEventManager,
        guild_id: u64,
        event_id: u64,
        with_user_count: bool,
    ) !models.GuildScheduledEvent {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/scheduled-events/{d}?with_user_count={}",
            .{ self.client.base_url, guild_id, event_id, with_user_count },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildScheduledEvent, response.body, .{});
    }

    /// Modify a guild scheduled event
    pub fn modifyGuildScheduledEvent(
        self: *GuildScheduledEventManager,
        guild_id: u64,
        event_id: u64,
        name: ?[]const u8,
        entity_type: ?models.GuildScheduledEventType,
        entity_metadata: ?models.GuildScheduledEventEntityMetadata,
        scheduled_start_time: ?u64,
        scheduled_end_time: ?u64,
        description: ?[]const u8,
        channel_id: ?u64,
        image: ?[]const u8,
        reason: ?[]const u8,
    ) !models.GuildScheduledEvent {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/scheduled-events/{d}",
            .{ self.client.base_url, guild_id, event_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyGuildScheduledEventPayload{
            .name = name,
            .entity_type = entity_type,
            .entity_metadata = entity_metadata,
            .scheduled_start_time = scheduled_start_time,
            .scheduled_end_time = scheduled_end_time,
            .description = description,
            .channel_id = channel_id,
            .image = image,
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

        return try std.json.parse(models.GuildScheduledEvent, response.body, .{});
    }

    /// Delete a guild scheduled event
    pub fn deleteGuildScheduledEvent(
        self: *GuildScheduledEventManager,
        guild_id: u64,
        event_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/scheduled-events/{d}",
            .{ self.client.base_url, guild_id, event_id },
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

    /// Get guild scheduled event users
    pub fn getGuildScheduledEventUsers(
        self: *GuildScheduledEventManager,
        guild_id: u64,
        event_id: u64,
        limit: ?usize,
        with_member: bool,
        before: ?u64,
        after: ?u64,
    ) ![]models.GuildScheduledEventUser {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/scheduled-events/{d}/users",
            .{ self.client.base_url, guild_id, event_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (limit) |l| {
            try params.append(try std.fmt.allocPrint(self.allocator, "limit={d}", .{l}));
        }
        if (with_member) {
            try params.append("with_member=true");
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

        return try std.json.parse([]models.GuildScheduledEventUser, response.body, .{});
    }
};

/// Payload for creating a guild scheduled event
pub const CreateGuildScheduledEventPayload = struct {
    name: []const u8,
    scheduled_start_time: u64,
    entity_type: models.GuildScheduledEventType,
    entity_metadata: ?models.GuildScheduledEventEntityMetadata = null,
    scheduled_end_time: ?u64 = null,
    description: ?[]const u8 = null,
    channel_id: ?u64 = null,
    image: ?[]const u8 = null,
};

/// Payload for modifying a guild scheduled event
pub const ModifyGuildScheduledEventPayload = struct {
    name: ?[]const u8 = null,
    entity_type: ?models.GuildScheduledEventType = null,
    entity_metadata: ?models.GuildScheduledEventEntityMetadata = null,
    scheduled_start_time: ?u64 = null,
    scheduled_end_time: ?u64 = null,
    description: ?[]const u8 = null,
    channel_id: ?u64 = null,
    image: ?[]const u8 = null,
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
        const current_time = @intCast(u64, std.time.timestamp() * 1000);
        return event.scheduled_start_time > current_time;
    }

    pub fn isEventInPast(event: models.GuildScheduledEvent) bool {
        if (event.scheduled_end_time) |end_time| {
            const current_time = @intCast(u64, std.time.timestamp() * 1000);
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
        const current_time = @intCast(u64, std.time.timestamp() * 1000);
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

        try summary.appendSlice(" - Starts: ");
        try summary.appendSlice(getTimeUntilEvent(event));

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

    pub fn getEventImageUrl(event: models.GuildScheduledEvent) ?[]const u8 {
        if (event.image) |image_hash| {
            return try std.fmt.allocPrint(
                std.heap.page_allocator,
                "https://cdn.discordapp.com/guild-events/{d}/{s}.png",
                .{ event.id, image_hash },
            );
        }
        return null;
    }

    pub function createEventMetadata(location: ?[]const u8) models.GuildScheduledEventEntityMetadata {
        return models.GuildScheduledEventEntityMetadata{
            .location = location,
        };
    }

    pub function validateEventName(name: []const u8) bool {
        // Event names must be 1-100 characters
        return name.len >= 1 and name.len <= 100;
    }

    pub function validateEventDescription(description: []const u8) bool {
        // Event descriptions must be 1-1000 characters
        return description.len >= 1 and description.len <= 1000;
    }

    pub function validateEventLocation(location: []const u8) bool {
        // Event locations must be 1-100 characters
        return location.len >= 1 and location.len <= 100;
    }

    pub function validateEventTime(start_time: u64, end_time: ?u64) bool {
        const current_time = @intCast(u64, std.time.timestamp() * 1000);
        
        // Start time must be in the future
        if (start_time <= current_time) return false;
        
        // If end time is provided, it must be after start time
        if (end_time) |end| {
            if (end <= start_time) return false;
        }
        
        return true;
    }

    pub function getEventStatistics(events: []models.GuildScheduledEvent) struct {
        total: usize,
        scheduled: usize,
        active: usize,
        completed: usize,
        canceled: usize,
        upcoming: usize,
        past: usize,
    } {
        var stats = struct {
            total: usize = 0,
            scheduled: usize = 0,
            active: usize = 0,
            completed: usize = 0,
            canceled: usize = 0,
            upcoming: usize = 0,
            past: usize = 0,
        }{};

        for (events) |event| {
            stats.total += 1;
            
            switch (event.status) {
                .scheduled => stats.scheduled += 1,
                .active => stats.active += 1,
                .completed => stats.completed += 1,
                .canceled => stats.canceled += 1,
            }
            
            if (isEventInFuture(event)) {
                stats.upcoming += 1;
            } else if (isEventInPast(event)) {
                stats.past += 1;
            }
        }

        return stats;
    }
};
