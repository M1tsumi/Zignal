const std = @import("std");

pub const Snowflake = struct {
    id: u64,

    pub fn init(id: u64) Snowflake {
        return Snowflake{ .id = id };
    }

    pub fn parse(snowflake_str: []const u8) !Snowflake {
        const id = try std.fmt.parseInt(u64, snowflake_str, 10);
        return Snowflake{ .id = id };
    }

    pub fn toString(self: Snowflake, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "{d}", .{self.id});
    }

    pub fn getTimestamp(self: Snowflake) i64 {
        // Discord epoch: 1420070400000 (January 1, 2015)
        const discord_epoch = 1420070400000;
        return @intCast((self.id >> 22) + discord_epoch);
    }

    pub fn getDate(self: Snowflake) std.time.epoch.EpochSeconds {
        return std.time.epoch.EpochSeconds{ .secs = @intCast(self.getTimestamp() / 1000) };
    }

    pub fn getWorkerId(self: Snowflake) u8 {
        return @intCast((self.id & 0x3E0000) >> 17);
    }

    pub fn getProcessId(self: Snowflake) u8 {
        return @intCast((self.id & 0x1F000) >> 12);
    }

    pub fn getIncrement(self: Snowflake) u16 {
        return @intCast(self.id & 0xFFF);
    }

    pub fn isOlderThan(self: Snowflake, other: Snowflake) bool {
        return self.id < other.id;
    }

    pub fn isNewerThan(self: Snowflake, other: Snowflake) bool {
        return self.id > other.id;
    }
};

pub const Permissions = struct {
    pub const CREATE_INSTANT_INVITE: u64 = 0x0000000000000001;
    pub const KICK_MEMBERS: u64 = 0x0000000000000002;
    pub const BAN_MEMBERS: u64 = 0x0000000000000004;
    pub const ADMINISTRATOR: u64 = 0x0000000000000008;
    pub const MANAGE_CHANNELS: u64 = 0x0000000000000010;
    pub const MANAGE_GUILD: u64 = 0x0000000000000020;
    pub const ADD_REACTIONS: u64 = 0x0000000000000040;
    pub const VIEW_AUDIT_LOG: u64 = 0x0000000000000080;
    pub const PRIORITY_SPEAKER: u64 = 0x0000000000000100;
    pub const STREAM: u64 = 0x0000000000000200;
    pub const VIEW_CHANNEL: u64 = 0x0000000000000400;
    pub const SEND_MESSAGES: u64 = 0x0000000000000800;
    pub const SEND_TTS_MESSAGES: u64 = 0x0000000000001000;
    pub const MANAGE_MESSAGES: u64 = 0x0000000000002000;
    pub const EMBED_LINKS: u64 = 0x0000000000004000;
    pub const ATTACH_FILES: u64 = 0x0000000000008000;
    pub const READ_MESSAGE_HISTORY: u64 = 0x0000000000010000;
    pub const MENTION_EVERYONE: u64 = 0x0000000000020000;
    pub const USE_EXTERNAL_EMOJIS: u64 = 0x0000000000040000;
    pub const VIEW_GUILD_INSIGHTS: u64 = 0x0000000000080000;
    pub const CONNECT: u64 = 0x0000000000100000;
    pub const SPEAK: u64 = 0x0000000000200000;
    pub const MUTE_MEMBERS: u64 = 0x0000000000400000;
    pub const DEAFEN_MEMBERS: u64 = 0x0000000000800000;
    pub const MOVE_MEMBERS: u64 = 0x0000000001000000;
    pub const USE_VAD: u64 = 0x0000000002000000;
    pub const CHANGE_NICKNAME: u64 = 0x0000000004000000;
    pub const MANAGE_NICKNAMES: u64 = 0x0000000008000000;
    pub const MANAGE_ROLES: u64 = 0x0000000010000000;
    pub const MANAGE_WEBHOOKS: u64 = 0x0000000020000000;
    pub const MANAGE_EMOJIS_AND_STICKERS: u64 = 0x0000000040000000;
    pub const USE_APPLICATION_COMMANDS: u64 = 0x0000000080000000;
    pub const REQUEST_TO_SPEAK: u64 = 0x0000000100000000;
    pub const MANAGE_EVENTS: u64 = 0x0000000200000000;
    pub const MANAGE_THREADS: u64 = 0x0000000400000000;
    pub const CREATE_PUBLIC_THREADS: u64 = 0x0000000800000000;
    pub const CREATE_PRIVATE_THREADS: u64 = 0x0000001000000000;
    pub const USE_EXTERNAL_STICKERS: u64 = 0x0000002000000000;
    pub const SEND_MESSAGES_IN_THREADS: u64 = 0x0000004000000000;
    pub const START_EMBEDDED_ACTIVITIES: u64 = 0x0000008000000000;
    pub const MODERATE_MEMBERS: u64 = 0x0000010000000000;

    permissions: u64,

    pub fn init(permissions: u64) Permissions {
        return Permissions{ .permissions = permissions };
    }

    pub fn parse(permissions_str: []const u8) !Permissions {
        const perms = try std.fmt.parseInt(u64, permissions_str, 10);
        return Permissions{ .permissions = perms };
    }

    pub fn has(self: Permissions, permission: u64) bool {
        return (self.permissions & permission) != 0;
    }

    pub fn hasAll(self: Permissions, permissions: []const u64) bool {
        for (permissions) |perm| {
            if (!self.has(perm)) return false;
        }
        return true;
    }

    pub fn hasAny(self: Permissions, permissions: []const u64) bool {
        for (permissions) |perm| {
            if (self.has(perm)) return true;
        }
        return false;
    }

    pub fn add(self: *Permissions, permission: u64) void {
        self.permissions |= permission;
    }

    pub fn remove(self: *Permissions, permission: u64) void {
        self.permissions &= ~permission;
    }

    pub fn toString(self: Permissions, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "{d}", .{self.permissions});
    }

    pub fn getPermissionNames(self: Permissions, allocator: std.mem.Allocator) ![][]const u8 {
        var names = std.ArrayList([]const u8).init(allocator);
        defer names.deinit();

        const permission_map = std.ComptimeStringMap(u64, .{
            .{ "CREATE_INSTANT_INVITE", CREATE_INSTANT_INVITE },
            .{ "KICK_MEMBERS", KICK_MEMBERS },
            .{ "BAN_MEMBERS", BAN_MEMBERS },
            .{ "ADMINISTRATOR", ADMINISTRATOR },
            .{ "MANAGE_CHANNELS", MANAGE_CHANNELS },
            .{ "MANAGE_GUILD", MANAGE_GUILD },
            .{ "ADD_REACTIONS", ADD_REACTIONS },
            .{ "VIEW_AUDIT_LOG", VIEW_AUDIT_LOG },
            .{ "PRIORITY_SPEAKER", PRIORITY_SPEAKER },
            .{ "STREAM", STREAM },
            .{ "VIEW_CHANNEL", VIEW_CHANNEL },
            .{ "SEND_MESSAGES", SEND_MESSAGES },
            .{ "SEND_TTS_MESSAGES", SEND_TTS_MESSAGES },
            .{ "MANAGE_MESSAGES", MANAGE_MESSAGES },
            .{ "EMBED_LINKS", EMBED_LINKS },
            .{ "ATTACH_FILES", ATTACH_FILES },
            .{ "READ_MESSAGE_HISTORY", READ_MESSAGE_HISTORY },
            .{ "MENTION_EVERYONE", MENTION_EVERYONE },
            .{ "USE_EXTERNAL_EMOJIS", USE_EXTERNAL_EMOJIS },
            .{ "VIEW_GUILD_INSIGHTS", VIEW_GUILD_INSIGHTS },
            .{ "CONNECT", CONNECT },
            .{ "SPEAK", SPEAK },
            .{ "MUTE_MEMBERS", MUTE_MEMBERS },
            .{ "DEAFEN_MEMBERS", DEAFEN_MEMBERS },
            .{ "MOVE_MEMBERS", MOVE_MEMBERS },
            .{ "USE_VAD", USE_VAD },
            .{ "CHANGE_NICKNAME", CHANGE_NICKNAME },
            .{ "MANAGE_NICKNAMES", MANAGE_NICKNAMES },
            .{ "MANAGE_ROLES", MANAGE_ROLES },
            .{ "MANAGE_WEBHOOKS", MANAGE_WEBHOOKS },
            .{ "MANAGE_EMOJIS_AND_STICKERS", MANAGE_EMOJIS_AND_STICKERS },
            .{ "USE_APPLICATION_COMMANDS", USE_APPLICATION_COMMANDS },
            .{ "REQUEST_TO_SPEAK", REQUEST_TO_SPEAK },
            .{ "MANAGE_EVENTS", MANAGE_EVENTS },
            .{ "MANAGE_THREADS", MANAGE_THREADS },
            .{ "CREATE_PUBLIC_THREADS", CREATE_PUBLIC_THREADS },
            .{ "CREATE_PRIVATE_THREADS", CREATE_PRIVATE_THREADS },
            .{ "USE_EXTERNAL_STICKERS", USE_EXTERNAL_STICKERS },
            .{ "SEND_MESSAGES_IN_THREADS", SEND_MESSAGES_IN_THREADS },
            .{ "START_EMBEDDED_ACTIVITIES", START_EMBEDDED_ACTIVITIES },
            .{ "MODERATE_MEMBERS", MODERATE_MEMBERS },
        });

        var iterator = permission_map.iterator();
        while (iterator.next()) |entry| {
            if (self.has(entry.value_ptr.*)) {
                try names.append(entry.key_ptr.*);
            }
        }

        return names.toOwnedSlice();
    }
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,

    pub fn init(r: u8, g: u8, b: u8) Color {
        return Color{ .r = r, .g = g, .b = b };
    }

    pub fn fromRgb(rgb: u32) Color {
        return Color{
            .r = @intCast((rgb >> 16) & 0xFF),
            .g = @intCast((rgb >> 8) & 0xFF),
            .b = @intCast(rgb & 0xFF),
        };
    }

    pub fn toRgb(self: Color) u32 {
        return (@as(u32, self.r) << 16) | (@as(u32, self.g) << 8) | @as(u32, self.b);
    }

    pub fn toHex(self: Color, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "#{x:0>2}{x:0>2}{x:0>2}", .{ self.r, self.g, self.b });
    }

    pub fn parseHex(hex_str: []const u8) !Color {
        if (hex_str.len < 1 or hex_str[0] != '#') return error.InvalidHexFormat;

        const hex = hex_str[1..];
        if (hex.len != 6) return error.InvalidHexFormat;

        const r = try std.fmt.parseInt(u8, hex[0..2], 16);
        const g = try std.fmt.parseInt(u8, hex[2..4], 16);
        const b = try std.fmt.parseInt(u8, hex[4..6], 16);

        return Color{ .r = r, .g = g, .b = b };
    }

    // Predefined colors
    pub const DEFAULT = Color{ .r = 0, .g = 0, .b = 0 };
    pub const WHITE = Color{ .r = 255, .g = 255, .b = 255 };
    pub const BLACK = Color{ .r = 0, .g = 0, .b = 0 };
    pub const RED = Color{ .r = 255, .g = 0, .b = 0 };
    pub const GREEN = Color{ .r = 0, .g = 255, .b = 0 };
    pub const BLUE = Color{ .r = 0, .g = 0, .b = 255 };
    pub const YELLOW = Color{ .r = 255, .g = 255, .b = 0 };
    pub const PURPLE = Color{ .r = 128, .g = 0, .b = 128 };
    pub const ORANGE = Color{ .r = 255, .g = 165, .b = 0 };
    pub const CYAN = Color{ .r = 0, .g = 255, .b = 255 };
    pub const MAGENTA = Color{ .r = 255, .g = 0, .b = 255 };
    pub const PINK = Color{ .r = 255, .g = 192, .b = 203 };
    pub const BROWN = Color{ .r = 165, .g = 42, .b = 42 };
    pub const GRAY = Color{ .r = 128, .g = 128, .b = 128 };
    pub const LIGHT_GRAY = Color{ .r = 192, .g = 192, .b = 192 };
    pub const DARK_GRAY = Color{ .r = 64, .g = 64, .b = 64 };
    pub const LIME = Color{ .r = 0, .g = 255, .b = 0 };
    pub const NAVY = Color{ .r = 0, .g = 0, .b = 128 };
    pub const TEAL = Color{ .r = 0, .g = 128, .b = 128 };
    pub const AQUA = Color{ .r = 0, .g = 255, .b = 255 };
    pub const MAROON = Color{ .r = 128, .g = 0, .b = 0 };
    pub const OLIVE = Color{ .r = 128, .g = 128, .b = 0 };
    pub const SILVER = Color{ .r = 192, .g = 192, .b = 192 };
    pub const GOLD = Color{ .r = 255, .g = 215, .b = 0 };
};

pub const Timestamp = struct {
    timestamp: i64,

    pub fn init(timestamp: i64) Timestamp {
        return Timestamp{ .timestamp = timestamp };
    }

    pub fn now() Timestamp {
        return Timestamp{ .timestamp = std.time.timestamp() * 1000 };
    }

    pub fn fromSnowflake(snowflake: Snowflake) Timestamp {
        return Timestamp{ .timestamp = snowflake.getTimestamp() };
    }

    pub fn toIsoString(self: Timestamp, allocator: std.mem.Allocator) ![]const u8 {
        const seconds = @divFloor(self.timestamp, 1000);
        const epoch = std.time.epoch.EpochSeconds{ .secs = seconds };

        const year_day = epoch.getEpochDay();
        const year = year_day.calculateYear();
        const day = year_day.day();
        const month_day = std.time.epoch.getYearDay(year, day);
        const month = month_day.month;
        const day_of_month = month_day.day_index + 1;

        const hour_day = epoch.getDaySeconds();
        const hour = hour_day.getHoursIntoDay();
        const minute = hour_day.getMinutesIntoHour();
        const second = hour_day.getSecondsIntoMinute();
        const millis = @mod(self.timestamp, 1000);

        return std.fmt.allocPrint(allocator, "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}.{d:0>3}Z", .{ year, @intFromEnum(month) + 1, day_of_month, hour, minute, second, millis });
    }

    pub fn add(self: Timestamp, milliseconds: i64) Timestamp {
        return Timestamp{ .timestamp = self.timestamp + milliseconds };
    }

    pub fn subtract(self: Timestamp, milliseconds: i64) Timestamp {
        return Timestamp{ .timestamp = self.timestamp - milliseconds };
    }

    pub fn difference(self: Timestamp, other: Timestamp) i64 {
        return self.timestamp - other.timestamp;
    }
};

pub const EmojiUtils = struct {
    pub fn isCustomEmoji(emoji_str: []const u8) bool {
        return emoji_str.len >= 3 and emoji_str[0] == '<' and emoji_str[emoji_str.len - 1] == '>';
    }

    pub fn parseCustomEmoji(emoji_str: []const u8) !struct { id: u64, name: []const u8, animated: bool } {
        if (!isCustomEmoji(emoji_str)) return error.NotCustomEmoji;

        const content = emoji_str[1 .. emoji_str.len - 1];
        var parts = std.mem.split(u8, content, ":");

        const animated = std.mem.eql(u8, parts.first().?, "a");
        if (animated) _ = parts.next(); // Skip "a" part

        const name = parts.next().?;
        const id_str = parts.next().?;

        const id = try std.fmt.parseInt(u64, id_str, 10);

        return .{ .id = id, .name = name, .animated = animated };
    }

    pub fn formatCustomEmoji(allocator: std.mem.Allocator, id: u64, name: []const u8, animated: bool) ![]const u8 {
        if (animated) {
            return std.fmt.allocPrint(allocator, "<a:{s}:{d}>", .{ name, id });
        } else {
            return std.fmt.allocPrint(allocator, "<:{s}:{d}>", .{ name, id });
        }
    }

    pub fn isUnicodeEmoji(emoji_str: []const u8) bool {
        // Basic check for unicode emoji (simplified)
        for (emoji_str) |byte| {
            if (byte >= 0xF0) return true; // 4-byte UTF-8 sequence (likely emoji)
        }
        return false;
    }
};

pub const StringUtils = struct {
    pub fn truncate(str: []const u8, max_len: usize) []const u8 {
        if (str.len <= max_len) return str;
        return str[0..max_len];
    }

    pub fn escapeMarkdown(str: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        var result = std.ArrayList(u8).init(allocator);
        defer result.deinit();

        for (str) |char| {
            switch (char) {
                '\\', '*', '_', '~', '`', '|', '>', '#', '+', '=', '-', '!' => {
                    try result.append('\\');
                    try result.append(char);
                },
                else => try result.append(char),
            }
        }

        return result.toOwnedSlice();
    }

    pub fn sanitize(str: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        var result = std.ArrayList(u8).init(allocator);
        defer result.deinit();

        for (str) |char| {
            switch (char) {
                '@', '#', ':', '`', '~', '!', '$', '%', '^', '&', '*', '(', ')', '-', '+', '=', '{', '}', '[', ']', '|', '\\', ';', '\'', '"', '<', '>', ',', '.', '?' => {
                    // Skip these characters
                },
                else => try result.append(char),
            }
        }

        return result.toOwnedSlice();
    }

    pub fn mentionUser(user_id: u64) [21]u8 {
        var result: [21]u8 = undefined;
        _ = std.fmt.bufPrint(&result, "<@{d}>", .{user_id}) catch unreachable;
        return result;
    }

    pub fn mentionRole(role_id: u64) [21]u8 {
        var result: [21]u8 = undefined;
        _ = std.fmt.bufPrint(&result, "<@&{d}>", .{role_id}) catch unreachable;
        return result;
    }

    pub fn mentionChannel(channel_id: u64) [22]u8 {
        var result: [22]u8 = undefined;
        _ = std.fmt.bufPrint(&result, "<#{d}>", .{channel_id}) catch unreachable;
        return result;
    }

    pub fn bold(text: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "**{s}**", .{text});
    }

    pub fn italic(text: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "*{s}*", .{text});
    }

    pub fn underline(text: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "__{s}__", .{text});
    }

    pub fn strikethrough(text: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "~~{s}~~", .{text});
    }

    pub fn code(text: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "`{s}`", .{text});
    }

    pub fn codeBlock(text: []const u8, language: ?[]const u8, allocator: std.mem.Allocator) ![]const u8 {
        if (language) |lang| {
            return std.fmt.allocPrint(allocator, "```{s}\n{s}\n```", .{ lang, text });
        } else {
            return std.fmt.allocPrint(allocator, "```\n{s}\n```", .{text});
        }
    }

    pub fn blockQuote(text: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "> {s}", .{text});
    }

    pub fn hyperlink(text: []const u8, url: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "[{s}]({s})", .{ text, url });
    }

    pub fn spoiler(text: []const u8, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "||{s}||", .{text});
    }
};
