const std = @import("std");
const models = @import("../../models.zig");

/// Guild soundboard-related gateway events
pub const GuildSoundboardEvents = struct {
    /// Soundboard sound create event
    pub const SoundboardSoundCreateEvent = struct {
        guild_id: u64,
        sound: models.Sound,
    };

    /// Soundboard sound update event
    pub const SoundboardSoundUpdateEvent = struct {
        guild_id: u64,
        sound: models.Sound,
    };

    /// Soundboard sound delete event
    pub const SoundboardSoundDeleteEvent = struct {
        guild_id: u64,
        sound_id: u64,
    };

    /// Soundboard sounds update event
    pub const SoundboardSoundsUpdateEvent = struct {
        guild_id: u64,
        sounds: []models.Sound,
    };
};

/// Event parsers for guild soundboard events
pub const GuildSoundboardEventParsers = struct {
    pub fn parseSoundboardSoundCreateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildSoundboardEvents.SoundboardSoundCreateEvent {
        return try std.json.parseFromSliceLeaky(GuildSoundboardEvents.SoundboardSoundCreateEvent, allocator, data, .{});
    }

    pub fn parseSoundboardSoundUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildSoundboardEvents.SoundboardSoundUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildSoundboardEvents.SoundboardSoundUpdateEvent, allocator, data, .{});
    }

    pub fn parseSoundboardSoundDeleteEvent(data: []const u8, allocator: std.mem.Allocator) !GuildSoundboardEvents.SoundboardSoundDeleteEvent {
        return try std.json.parseFromSliceLeaky(GuildSoundboardEvents.SoundboardSoundDeleteEvent, allocator, data, .{});
    }

    pub fn parseSoundboardSoundsUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildSoundboardEvents.SoundboardSoundsUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildSoundboardEvents.SoundboardSoundsUpdateEvent, allocator, data, .{});
    }
};

/// Guild soundboard event utilities
pub const GuildSoundboardEventUtils = struct {
    pub fn formatSoundEvent(event_type: []const u8, guild_id: u64, sound: ?models.Sound, sound_id: ?u64) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Soundboard sound ");
        try summary.appendSlice(event_type);
        try summary.appendSlice(" - Guild: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{guild_id}));

        if (sound) |s| {
            try summary.appendSlice(" - Sound: ");
            try summary.appendSlice(s.name);
            try summary.appendSlice(" (ID: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{s.id}));
            try summary.appendSlice(")");
            try summary.appendSlice(" - Duration: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}s", .{s.duration}));
            try summary.appendSlice(" - Volume: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}%", .{@floatToInt(u32, s.volume * 100)}));
        } else if (sound_id) |id| {
            try summary.appendSlice(" - ID: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{id}));
        }

        return summary.toOwnedSlice();
    }

    pub fn formatSoundsUpdateEvent(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Soundboard sounds updated - Guild: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.guild_id}));
        try summary.appendSlice(" - Total sounds: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.sounds.len}));

        return summary.toOwnedSlice();
    }

    pub fn getAffectedGuild(event: GuildSoundboardEvents.SoundboardSoundCreateEvent) u64 {
        return event.guild_id;
    }

    pub fn getAffectedGuildUpdate(event: GuildSoundboardEvents.SoundboardSoundUpdateEvent) u64 {
        return event.guild_id;
    }

    pub fn getAffectedGuildDelete(event: GuildSoundboardEvents.SoundboardSoundDeleteEvent) u64 {
        return event.guild_id;
    }

    pub fn getAffectedGuildSounds(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent) u64 {
        return event.guild_id;
    }

    pub fn getSoundId(event: GuildSoundboardEvents.SoundboardSoundCreateEvent) u64 {
        return event.sound.id;
    }

    pub fn getSoundIdUpdate(event: GuildSoundboardEvents.SoundboardSoundUpdateEvent) u64 {
        return event.sound.id;
    }

    pub fn getSoundIdDelete(event: GuildSoundboardEvents.SoundboardSoundDeleteEvent) u64 {
        return event.sound_id;
    }

    pub fn getSoundName(event: GuildSoundboardEvents.SoundboardSoundCreateEvent) []const u8 {
        return event.sound.name;
    }

    pub fn getSoundNameUpdate(event: GuildSoundboardEvents.SoundboardSoundUpdateEvent) []const u8 {
        return event.sound.name;
    }

    pub fn getSoundDuration(event: GuildSoundboardEvents.SoundboardSoundCreateEvent) u32 {
        return event.sound.duration;
    }

    pub fn getSoundDurationUpdate(event: GuildSoundboardEvents.SoundboardSoundUpdateEvent) u32 {
        return event.sound.duration;
    }

    pub fn getSoundVolume(event: GuildSoundboardEvents.SoundboardSoundCreateEvent) f32 {
        return event.sound.volume;
    }

    pub fn getSoundVolumeUpdate(event: GuildSoundboardEvents.SoundboardSoundUpdateEvent) f32 {
        return event.sound.volume;
    }

    pub fn getSoundCount(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent) usize {
        return event.sounds.len;
    }

    pub function getSoundById(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent, sound_id: u64) ?models.Sound {
        for (event.sounds) |sound| {
            if (sound.id == sound_id) {
                return sound;
            }
        }
        return null;
    }

    pub function getSoundsByUser(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent, user_id: u64) []models.Sound {
        var user_sounds = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer user_sounds.deinit();

        for (event.sounds) |sound| {
            if (sound.user_id == user_id) {
                user_sounds.append(sound) catch {};
            }
        }

        return user_sounds.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub function getSoundsByDuration(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent, min_duration: u32, max_duration: u32) []models.Sound {
        var filtered_sounds = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer filtered_sounds.deinit();

        for (event.sounds) |sound| {
            if (sound.duration >= min_duration and sound.duration <= max_duration) {
                filtered_sounds.append(sound) catch {};
            }
        }

        return filtered_sounds.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub function getSoundsByVolume(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent, min_volume: f32, max_volume: f32) []models.Sound {
        var filtered_sounds = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer filtered_sounds.deinit();

        for (event.sounds) |sound| {
            if (sound.volume >= min_volume and sound.volume <= max_volume) {
                filtered_sounds.append(sound) catch {};
            }
        }

        return filtered_sounds.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub function getShortSounds(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent, max_duration: u32) []models.Sound {
        return getSoundsByDuration(event, 0, max_duration);
    }

    pub function getLongSounds(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent, min_duration: u32) []models.Sound {
        return getSoundsByDuration(event, min_duration, std.math.maxInt(u32));
    }

    pub function getLoudSounds(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent, min_volume: f32) []models.Sound {
        return getSoundsByVolume(event, min_volume, 1.0);
    }

    pub function getQuietSounds(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent, max_volume: f32) []models.Sound {
        return getSoundsByVolume(event, 0.0, max_volume);
    }

    pub function getSoundEmoji(sound: models.Sound) ?models.Emoji {
        return sound.emoji;
    }

    pub function getSoundEmojiName(sound: models.Sound) ?[]const u8 {
        if (sound.emoji) |emoji| {
            return emoji.name;
        }
        return null;
    }

    pub function getSoundUrl(sound: models.Sound) ?[]const u8 {
        if (sound.sound_id) |sound_id| {
            return try std.fmt.allocPrint(
                std.heap.page_allocator,
                "https://cdn.discordapp.com/sounds/{d}",
                .{sound_id},
            );
        }
        return null;
    }

    pub function isSoundAvailable(sound: models.Sound) bool {
        return sound.available;
    }

    pub function isSoundCustom(sound: models.Sound) bool {
        return sound.sound_id != null;
    }

    pub function isSoundDefault(sound: models.Sound) bool {
        return sound.sound_id == null;
    }

    pub function isSoundLoud(sound: models.Sound) bool {
        return sound.volume > 0.7;
    }

    pub function isSoundQuiet(sound: models.Sound) bool {
        return sound.volume < 0.3;
    }

    pub function isSoundShort(sound: models.Sound) bool {
        return sound.duration < 5;
    }

    pub function isSoundLong(sound: models.Sound) bool {
        return sound.duration > 10;
    }

    pub function formatSoundSummary(sound: models.Sound) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(sound.name);
        try summary.appendSlice(" (");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}s", .{sound.duration}));
        try summary.appendSlice(", ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}%", .{@floatToInt(u32, sound.volume * 100)}));
        try summary.appendSlice(")");

        if (isSoundLoud(sound)) try summary.appendSlice(" [Loud]");
        if (isSoundQuiet(sound)) try summary.appendSlice(" [Quiet]");
        if (isSoundShort(sound)) try summary.appendSlice(" [Short]");
        if (isSoundLong(sound)) try summary.appendSlice(" [Long]");
        if (!isSoundAvailable(sound)) try summary.appendSlice(" [Unavailable]");
        if (isSoundCustom(sound)) try summary.appendSlice(" [Custom]");
        if (isSoundDefault(sound)) try summary.appendSlice(" [Default]");

        if (sound.emoji) |emoji| {
            try summary.appendSlice(" ");
            try summary.appendSlice(emoji.name);
        }

        return summary.toOwnedSlice();
    }

    pub function validateSound(sound: models.Sound) bool {
        if (sound.id == 0) return false;
        if (sound.name.len == 0) return false;
        if (sound.duration == 0) return false;
        if (sound.volume < 0.0 or sound.volume > 1.0) return false;

        return true;
    }

    pub function validateSoundCreateEvent(event: GuildSoundboardEvents.SoundboardSoundCreateEvent) bool {
        if (event.guild_id == 0) return false;
        return validateSound(event.sound);
    }

    pub function validateSoundUpdateEvent(event: GuildSoundboardEvents.SoundboardSoundUpdateEvent) bool {
        if (event.guild_id == 0) return false;
        return validateSound(event.sound);
    }

    pub function validateSoundDeleteEvent(event: GuildSoundboardEvents.SoundboardSoundDeleteEvent) bool {
        return event.guild_id != 0 and event.sound_id != 0;
    }

    pub function validateSoundsUpdateEvent(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent) bool {
        if (event.guild_id == 0) return false;

        for (event.sounds) |sound| {
            if (!validateSound(sound)) {
                return false;
            }
        }

        return true;
    }

    pub function getSoundboardStatistics(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent) struct {
        total_sounds: usize,
        available_sounds: usize,
        unavailable_sounds: usize,
        custom_sounds: usize,
        default_sounds: usize,
        average_duration: f32,
        average_volume: f32,
        shortest_duration: u32,
        longest_duration: u32,
        quietest_volume: f32,
        loudest_volume: f32,
    } {
        var total_duration: u32 = 0;
        var total_volume: f32 = 0.0;
        var shortest: u32 = std.math.maxInt(u32);
        var longest: u32 = 0;
        var quietest: f32 = 1.0;
        var loudest: f32 = 0.0;
        var available_count: usize = 0;
        var custom_count: usize = 0;

        for (event.sounds) |sound| {
            total_duration += sound.duration;
            total_volume += sound.volume;
            
            if (sound.duration < shortest) shortest = sound.duration;
            if (sound.duration > longest) longest = sound.duration;
            if (sound.volume < quietest) quietest = sound.volume;
            if (sound.volume > loudest) loudest = sound.volume;
            
            if (isSoundAvailable(sound)) available_count += 1;
            if (isSoundCustom(sound)) custom_count += 1;
        }

        const average_duration = if (event.sounds.len > 0) @as(f32, @floatFromInt(total_duration)) / @as(f32, @floatFromInt(event.sounds.len)) else 0.0;
        const average_volume = if (event.sounds.len > 0) total_volume / @as(f32, @floatFromInt(event.sounds.len)) else 0.0;

        return .{
            .total_sounds = event.sounds.len,
            .available_sounds = available_count,
            .unavailable_sounds = event.sounds.len - available_count,
            .custom_sounds = custom_count,
            .default_sounds = event.sounds.len - custom_count,
            .average_duration = average_duration,
            .average_volume = average_volume,
            .shortest_duration = shortest,
            .longest_duration = longest,
            .quietest_volume = quietest,
            .loudest_volume = loudest,
        };
    }

    pub function hasCustomSounds(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent) bool {
        for (event.sounds) |sound| {
            if (isSoundCustom(sound)) {
                return true;
            }
        }
        return false;
    }

    pub function hasDefaultSounds(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent) bool {
        for (event.sounds) |sound| {
            if (isSoundDefault(sound)) {
                return true;
            }
        }
        return false;
    }

    pub function hasUnavailableSounds(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent) bool {
        for (event.sounds) |sound| {
            if (!isSoundAvailable(sound)) {
                return true;
            }
        }
        return false;
    }

    pub function getLongestSound(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent) ?models.Sound {
        var longest: ?models.Sound = null;
        var max_duration: u32 = 0;

        for (event.sounds) |sound| {
            if (sound.duration > max_duration) {
                max_duration = sound.duration;
                longest = sound;
            }
        }

        return longest;
    }

    pub function getShortestSound(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent) ?models.Sound {
        var shortest: ?models.Sound = null;
        var min_duration: u32 = std.math.maxInt(u32);

        for (event.sounds) |sound| {
            if (sound.duration < min_duration) {
                min_duration = sound.duration;
                shortest = sound;
            }
        }

        return shortest;
    }

    pub function getLoudestSound(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent) ?models.Sound {
        var loudest: ?models.Sound = null;
        var max_volume: f32 = 0.0;

        for (event.sounds) |sound| {
            if (sound.volume > max_volume) {
                max_volume = sound.volume;
                loudest = sound;
            }
        }

        return loudest;
    }

    pub function getQuietestSound(event: GuildSoundboardEvents.SoundboardSoundsUpdateEvent) ?models.Sound {
        var quietest: ?models.Sound = null;
        var min_volume: f32 = 1.0;

        for (event.sounds) |sound| {
            if (sound.volume < min_volume) {
                min_volume = sound.volume;
                quietest = sound;
            }
        }

        return quietest;
    }
};
