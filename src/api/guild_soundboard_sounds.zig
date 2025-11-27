const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild soundboard sound management for custom server sounds
pub const GuildSoundboardSoundManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildSoundboardSoundManager {
        return GuildSoundboardSoundManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// List guild soundboard sounds
    pub fn listGuildSoundboardSounds(self: *GuildSoundboardSoundManager, guild_id: u64) ![]models.Sound {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/soundboard-sounds",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.Sound, response.body, .{});
    }

    /// Create guild soundboard sound
    pub fn createGuildSoundboardSound(
        self: *GuildSoundboardSoundManager,
        guild_id: u64,
        name: []const u8,
        sound: []const u8, // Base64 encoded audio data
        volume: ?f32,
        emoji_id: ?u64,
        emoji_name: ?[]const u8,
        reason: ?[]const u8,
    ) !models.Sound {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/soundboard-sounds",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreateSoundPayload{
            .name = name,
            .sound = sound,
            .volume = volume,
            .emoji_id = emoji_id,
            .emoji_name = emoji_name,
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

        return try std.json.parse(models.Sound, response.body, .{});
    }

    /// Modify guild soundboard sound
    pub fn modifyGuildSoundboardSound(
        self: *GuildSoundboardSoundManager,
        guild_id: u64,
        sound_id: u64,
        name: ?[]const u8,
        volume: ?f32,
        emoji_id: ?u64,
        emoji_name: ?[]const u8,
        reason: ?[]const u8,
    ) !models.Sound {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/soundboard-sounds/{d}",
            .{ self.client.base_url, guild_id, sound_id },
        );
        defer self.allocator.free(url);

        const payload = ModifySoundPayload{
            .name = name,
            .volume = volume,
            .emoji_id = emoji_id,
            .emoji_name = emoji_name,
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

        return try std.json.parse(models.Sound, response.body, .{});
    }

    /// Delete guild soundboard sound
    pub fn deleteGuildSoundboardSound(
        self: *GuildSoundboardSoundManager,
        guild_id: u64,
        sound_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/soundboard-sounds/{d}",
            .{ self.client.base_url, guild_id, sound_id },
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
};

/// Payload for creating sound
pub const CreateSoundPayload = struct {
    name: []const u8,
    sound: []const u8,
    volume: ?f32 = null,
    emoji_id: ?u64 = null,
    emoji_name: ?[]const u8 = null,
};

/// Payload for modifying sound
pub const ModifySoundPayload = struct {
    name: ?[]const u8 = null,
    volume: ?f32 = null,
    emoji_id: ?u64 = null,
    emoji_name: ?[]const u8 = null,
};

/// Soundboard sound utilities
pub const GuildSoundboardSoundUtils = struct {
    pub fn getSoundName(sound: models.Sound) []const u8 {
        return sound.name;
    }

    pub fn getSoundDuration(sound: models.Sound) u32 {
        return sound.duration;
    }

    pub fn getSoundVolume(sound: models.Sound) f32 {
        return sound.volume;
    }

    pub fn getSoundVolumePercentage(sound: models.Sound) u32 {
        return @intFromFloat(sound.volume * 100);
    }

    pub fn getSoundId(sound: models.Sound) u64 {
        return sound.id;
    }

    pub fn getSoundUserId(sound: models.Sound) u64 {
        return sound.user_id;
    }

    pub fn getSoundGuildId(sound: models.Sound) u64 {
        return sound.guild_id;
    }

    pub fn getSoundEmoji(sound: models.Sound) ?models.Emoji {
        return sound.emoji;
    }

    pub fn getSoundEmojiName(sound: models.Sound) ?[]const u8 {
        if (sound.emoji) |emoji| {
            return emoji.name;
        }
        return null;
    }

    pub fn getSoundEmojiId(sound: models.Sound) ?u64 {
        if (sound.emoji) |emoji| {
            return emoji.id;
        }
        return null;
    }

    pub fn isSoundAvailable(sound: models.Sound) bool {
        return sound.available;
    }

    pub fn isSoundCustom(sound: models.Sound) bool {
        return sound.sound_id != null;
    }

    pub fn isSoundDefault(sound: models.Sound) bool {
        return sound.sound_id == null;
    }

    pub fn isSoundLoud(sound: models.Sound) bool {
        return sound.volume > 0.7;
    }

    pub fn isSoundQuiet(sound: models.Sound) bool {
        return sound.volume < 0.3;
    }

    pub fn isSoundShort(sound: models.Sound) bool {
        return sound.duration < 5;
    }

    pub fn isSoundMedium(sound: models.Sound) bool {
        return sound.duration >= 5 and sound.duration <= 15;
    }

    pub fn isSoundLong(sound: models.Sound) bool {
        return sound.duration > 15;
    }

    pub fn getSoundUrl(sound: models.Sound) ?[]const u8 {
        if (sound.sound_id) |sound_id| {
            return try std.fmt.allocPrint(
                std.heap.page_allocator,
                "https://cdn.discordapp.com/sounds/{d}",
                .{sound_id},
            );
        }
        return null;
    }

    pub fn getSoundEmojiUrl(sound: models.Sound) ?[]const u8 {
        if (sound.emoji) |emoji| {
            if (emoji.id != 0) {
                return try std.fmt.allocPrint(
                    std.heap.page_allocator,
                    "https://cdn.discordapp.com/emojis/{d}.png",
                    .{emoji.id},
                );
            }
        }
        return null;
    }

    pub fn isCustomEmoji(sound: models.Sound) bool {
        if (sound.emoji) |emoji| {
            return emoji.id != 0;
        }
        return false;
    }

    pub fn isUnicodeEmoji(sound: models.Sound) bool {
        if (sound.emoji) |emoji| {
            return emoji.id == 0;
        }
        return false;
    }

    pub fn getEmojiDisplay(sound: models.Sound) []const u8 {
        if (sound.emoji) |emoji| {
            if (isCustomEmoji(sound)) {
                return emoji.name;
            } else {
                return emoji.name; // Unicode emoji
            }
        }
        return "";
    }

    pub fn formatSoundSummary(sound: models.Sound) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(sound.name);
        try summary.appendSlice(" (");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}s", .{sound.duration}));
        try summary.appendSlice(", ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}%", .{getSoundVolumePercentage(sound)}));
        try summary.appendSlice(")");

        if (isSoundLoud(sound)) try summary.appendSlice(" [Loud]");
        if (isSoundQuiet(sound)) try summary.appendSlice(" [Quiet]");
        if (isSoundShort(sound)) try summary.appendSlice(" [Short]");
        if (isSoundMedium(sound)) try summary.appendSlice(" [Medium]");
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

    pub fn validateSound(sound: models.Sound) bool {
        if (sound.id == 0) return false;
        if (sound.name.len == 0) return false;
        if (sound.duration == 0) return false;
        if (sound.volume < 0.0 or sound.volume > 1.0) return false;

        // Validate emoji if present
        if (sound.emoji) |emoji| {
            if (emoji.name.len == 0) return false;
        }

        return true;
    }

    pub fn validateSoundName(name: []const u8) bool {
        // Sound names must be 2-32 characters
        return name.len >= 2 and name.len <= 32;
    }

    pub fn validateSoundVolume(volume: f32) bool {
        return volume >= 0.0 and volume <= 1.0;
    }

    pub fn validateEmojiName(name: []const u8) bool {
        // Emoji names must be 2-32 characters
        return name.len >= 2 and name.len <= 32;
    }

    pub fn getSoundById(sounds: []models.Sound, sound_id: u64) ?models.Sound {
        for (sounds) |sound| {
            if (sound.id == sound_id) {
                return sound;
            }
        }
        return null;
    }

    pub fn getSoundsByUser(sounds: []models.Sound, user_id: u64) []models.Sound {
        var user_sounds = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer user_sounds.deinit();

        for (sounds) |sound| {
            if (sound.user_id == user_id) {
                user_sounds.append(sound) catch {};
            }
        }

        return user_sounds.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub fn getSoundsByDuration(sounds: []models.Sound, min_duration: u32, max_duration: u32) []models.Sound {
        var filtered_sounds = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer filtered_sounds.deinit();

        for (sounds) |sound| {
            if (sound.duration >= min_duration and sound.duration <= max_duration) {
                filtered_sounds.append(sound) catch {};
            }
        }

        return filtered_sounds.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub fn getSoundsByVolume(sounds: []models.Sound, min_volume: f32, max_volume: f32) []models.Sound {
        var filtered_sounds = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer filtered_sounds.deinit();

        for (sounds) |sound| {
            if (sound.volume >= min_volume and sound.volume <= max_volume) {
                filtered_sounds.append(sound) catch {};
            }
        }

        return filtered_sounds.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub fn getShortSounds(sounds: []models.Sound, max_duration: u32) []models.Sound {
        return getSoundsByDuration(sounds, 0, max_duration);
    }

    pub fn getMediumSounds(sounds: []models.Sound) []models.Sound {
        return getSoundsByDuration(sounds, 5, 15);
    }

    pub fn getLongSounds(sounds: []models.Sound, min_duration: u32) []models.Sound {
        return getSoundsByDuration(sounds, min_duration, std.math.maxInt(u32));
    }

    pub fn getLoudSounds(sounds: []models.Sound, min_volume: f32) []models.Sound {
        return getSoundsByVolume(sounds, min_volume, 1.0);
    }

    pub fn getQuietSounds(sounds: []models.Sound, max_volume: f32) []models.Sound {
        return getSoundsByVolume(sounds, 0.0, max_volume);
    }

    pub fn getAvailableSounds(sounds: []models.Sound) []models.Sound {
        var available = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer available.deinit();

        for (sounds) |sound| {
            if (isSoundAvailable(sound)) {
                available.append(sound) catch {};
            }
        }

        return available.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub fn getUnavailableSounds(sounds: []models.Sound) []models.Sound {
        var unavailable = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer unavailable.deinit();

        for (sounds) |sound| {
            if (!isSoundAvailable(sound)) {
                unavailable.append(sound) catch {};
            }
        }

        return unavailable.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub fn getCustomSounds(sounds: []models.Sound) []models.Sound {
        var custom = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer custom.deinit();

        for (sounds) |sound| {
            if (isSoundCustom(sound)) {
                custom.append(sound) catch {};
            }
        }

        return custom.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub fn getDefaultSounds(sounds: []models.Sound) []models.Sound {
        var default_sounds = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer default_sounds.deinit();

        for (sounds) |sound| {
            if (isSoundDefault(sound)) {
                default_sounds.append(sound) catch {};
            }
        }

        return default_sounds.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub fn getSoundsWithCustomEmoji(sounds: []models.Sound) []models.Sound {
        var custom_emoji = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer custom_emoji.deinit();

        for (sounds) |sound| {
            if (isCustomEmoji(sound)) {
                custom_emoji.append(sound) catch {};
            }
        }

        return custom_emoji.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub fn getSoundsWithUnicodeEmoji(sounds: []models.Sound) []models.Sound {
        var unicode_emoji = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer unicode_emoji.deinit();

        for (sounds) |sound| {
            if (isUnicodeEmoji(sound)) {
                unicode_emoji.append(sound) catch {};
            }
        }

        return unicode_emoji.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub fn getSoundsWithoutEmoji(sounds: []models.Sound) []models.Sound {
        var no_emoji = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer no_emoji.deinit();

        for (sounds) |sound| {
            if (sound.emoji == null) {
                no_emoji.append(sound) catch {};
            }
        }

        return no_emoji.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub fn searchSounds(sounds: []models.Sound, query: []const u8) []models.Sound {
        var results = std.ArrayList(models.Sound).init(std.heap.page_allocator);
        defer results.deinit();

        for (sounds) |sound| {
            if (std.mem.indexOf(u8, sound.name, query) != null) {
                results.append(sound) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.Sound{};
    }

    pub fn getSoundStatistics(sounds: []models.Sound) struct {
        total_sounds: usize,
        available_sounds: usize,
        unavailable_sounds: usize,
        custom_sounds: usize,
        default_sounds: usize,
        custom_emoji_sounds: usize,
        unicode_emoji_sounds: usize,
        no_emoji_sounds: usize,
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
        var custom_emoji_count: usize = 0;
        var unicode_emoji_count: usize = 0;
        var no_emoji_count: usize = 0;

        for (sounds) |sound| {
            total_duration += sound.duration;
            total_volume += sound.volume;
            
            if (sound.duration < shortest) shortest = sound.duration;
            if (sound.duration > longest) longest = sound.duration;
            if (sound.volume < quietest) quietest = sound.volume;
            if (sound.volume > loudest) loudest = sound.volume;
            
            if (isSoundAvailable(sound)) available_count += 1;
            if (isSoundCustom(sound)) custom_count += 1;
            if (isCustomEmoji(sound)) custom_emoji_count += 1;
            if (isUnicodeEmoji(sound)) unicode_emoji_count += 1;
            if (sound.emoji == null) no_emoji_count += 1;
        }

        const average_duration = if (sounds.len > 0) @as(f32, @floatFromInt(total_duration)) / @as(f32, @floatFromInt(sounds.len)) else 0.0;
        const average_volume = if (sounds.len > 0) total_volume / @as(f32, @floatFromInt(sounds.len)) else 0.0;

        return .{
            .total_sounds = sounds.len,
            .available_sounds = available_count,
            .unavailable_sounds = sounds.len - available_count,
            .custom_sounds = custom_count,
            .default_sounds = sounds.len - custom_count,
            .custom_emoji_sounds = custom_emoji_count,
            .unicode_emoji_sounds = unicode_emoji_count,
            .no_emoji_sounds = no_emoji_count,
            .average_duration = average_duration,
            .average_volume = average_volume,
            .shortest_duration = shortest,
            .longest_duration = longest,
            .quietest_volume = quietest,
            .loudest_volume = loudest,
        };
    }

    pub fn sortSoundsByName(sounds: []models.Sound) void {
        std.sort.sort(models.Sound, sounds, {}, compareSoundsByName);
    }

    pub fn sortSoundsByDuration(sounds: []models.Sound) void {
        std.sort.sort(models.Sound, sounds, {}, compareSoundsByDuration);
    }

    pub fn sortSoundsByVolume(sounds: []models.Sound) void {
        std.sort.sort(models.Sound, sounds, {}, compareSoundsByVolume);
    }

    pub fn sortSoundsByUser(sounds: []models.Sound) void {
        std.sort.sort(models.Sound, sounds, {}, compareSoundsByUser);
    }

    fn compareSoundsByName(_: void, a: models.Sound, b: models.Sound) std.math.Order {
        return std.mem.compare(u8, a.name, b.name);
    }

    fn compareSoundsByDuration(_: void, a: models.Sound, b: models.Sound) std.math.Order {
        if (a.duration < b.duration) return .lt;
        if (a.duration > b.duration) return .gt;
        return .eq;
    }

    fn compareSoundsByVolume(_: void, a: models.Sound, b: models.Sound) std.math.Order {
        if (a.volume < b.volume) return .lt;
        if (a.volume > b.volume) return .gt;
        return .eq;
    }

    fn compareSoundsByUser(_: void, a: models.Sound, b: models.Sound) std.math.Order {
        if (a.user_id < b.user_id) return .lt;
        if (a.user_id > b.user_id) return .gt;
        return .eq;
    }

    pub fn getLongestSound(sounds: []models.Sound) ?models.Sound {
        var longest: ?models.Sound = null;
        var max_duration: u32 = 0;

        for (sounds) |sound| {
            if (sound.duration > max_duration) {
                max_duration = sound.duration;
                longest = sound;
            }
        }

        return longest;
    }

    pub fn getShortestSound(sounds: []models.Sound) ?models.Sound {
        var shortest: ?models.Sound = null;
        var min_duration: u32 = std.math.maxInt(u32);

        for (sounds) |sound| {
            if (sound.duration < min_duration) {
                min_duration = sound.duration;
                shortest = sound;
            }
        }

        return shortest;
    }

    pub fn getLoudestSound(sounds: []models.Sound) ?models.Sound {
        var loudest: ?models.Sound = null;
        var max_volume: f32 = 0.0;

        for (sounds) |sound| {
            if (sound.volume > max_volume) {
                max_volume = sound.volume;
                loudest = sound;
            }
        }

        return loudest;
    }

    pub fn getQuietestSound(sounds: []models.Sound) ?models.Sound {
        var quietest: ?models.Sound = null;
        var min_volume: f32 = 1.0;

        for (sounds) |sound| {
            if (sound.volume < min_volume) {
                min_volume = sound.volume;
                quietest = sound;
            }
        }

        return quietest;
    }

    pub fn hasCustomSounds(sounds: []models.Sound) bool {
        return getCustomSounds(sounds).len > 0;
    }

    pub fn hasDefaultSounds(sounds: []models.Sound) bool {
        return getDefaultSounds(sounds).len > 0;
    }

    pub fn hasUnavailableSounds(sounds: []models.Sound) bool {
        return getUnavailableSounds(sounds).len > 0;
    }

    pub fn createSoundPayload(
        name: []const u8,
        sound: []const u8,
        volume: ?f32,
        emoji_id: ?u64,
        emoji_name: ?[]const u8,
    ) CreateSoundPayload {
        return CreateSoundPayload{
            .name = name,
            .sound = sound,
            .volume = volume,
            .emoji_id = emoji_id,
            .emoji_name = emoji_name,
        };
    }

    pub fn createSoundPayloadWithCustomEmoji(
        name: []const u8,
        sound: []const u8,
        volume: ?f32,
        emoji_id: u64,
        emoji_name: []const u8,
    ) CreateSoundPayload {
        return createSoundPayload(name, sound, volume, emoji_id, emoji_name);
    }

    pub fn createSoundPayloadWithUnicodeEmoji(
        name: []const u8,
        sound: []const u8,
        volume: ?f32,
        emoji_name: []const u8,
    ) CreateSoundPayload {
        return createSoundPayload(name, sound, volume, null, emoji_name);
    }

    pub fn createSoundPayloadNoEmoji(
        name: []const u8,
        sound: []const u8,
        volume: ?f32,
    ) CreateSoundPayload {
        return createSoundPayload(name, sound, volume, null, null);
    }
};
