const std = @import("std");
const zignal = @import("zignal");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const token = "YOUR_BOT_TOKEN_HERE";
    
    var client = zignal.Client.init(allocator, token);
    defer client.deinit();

    std.log.info("Getting current user information...", .{});
    const user = try client.getCurrentUser();
    defer {
        allocator.free(user.username);
        allocator.free(user.discriminator);
        if (user.global_name) |gn| allocator.free(gn);
        if (user.avatar) |a| allocator.free(a);
        if (user.locale) |l| allocator.free(l);
        if (user.email) |e| allocator.free(e);
        if (user.avatar_decoration) |ad| allocator.free(ad);
    }
    
    std.log.info("Bot user: {s}#{s} (ID: {d})", .{ user.username, user.discriminator, user.id });

    std.log.info("Getting guilds...", .{});
    const guilds = try client.getGuilds();
    defer {
        for (guilds) |guild| {
            allocator.free(guild.name);
            if (guild.icon) |i| allocator.free(i);
            if (guild.splash) |s| allocator.free(s);
            if (guild.discovery_splash) |ds| allocator.free(ds);
            if (guild.permissions) |p| allocator.free(p);
            if (guild.region) |r| allocator.free(r);
            if (guild.vanity_url_code) |v| allocator.free(v);
            if (guild.description) |d| allocator.free(d);
            if (guild.banner) |b| allocator.free(b);
            allocator.free(guild.preferred_locale);
            allocator.free(guild.roles);
            allocator.free(guild.emojis);
            allocator.free(guild.features);
            allocator.free(guild.stage_instances);
            allocator.free(guild.stickers);
            allocator.free(guild.guild_scheduled_events);
        }
        allocator.free(guilds);
    }
    
    std.log.info("Bot is in {d} guilds:", .{guilds.len});
    for (guilds) |guild| {
        std.log.info("  - {s} (ID: {d})", .{ guild.name, guild.id });
    }

    if (guilds.len > 0) {
        const first_guild = guilds[0];
        
        std.log.info("Getting channels for guild: {s}", .{first_guild.name});
        
        const channels_path = try std.fmt.allocPrint(allocator, "/guilds/{d}/channels", .{first_guild.id});
        defer allocator.free(channels_path);
        
        var request = try client.makeRequest(.GET, channels_path, null, null);
        defer request.deinit();

        const body = try request.reader().readAllAlloc(allocator, 1024 * 1024);
        defer allocator.free(body);
        defer allocator.destroy(request);

        var parsed = try std.json.parseFromSlice([]struct {
            id: u64,
            type: u8,
            guild_id: ?u64,
            position: ?u32,
            permission_overwrites: []zignal.models.PermissionOverwrite,
            name: ?[]const u8,
            topic: ?[]const u8,
            nsfw: bool = false,
            last_message_id: ?u64,
            bitrate: ?u32,
            user_limit: ?u32,
            rate_limit_per_user: ?u32,
            recipients: []zignal.models.User,
            icon: ?[]const u8,
            owner_id: ?u64,
            application_id: ?u64,
            parent_id: ?u64,
            last_pin_timestamp: ?[]const u8,
            rtc_region: ?[]const u8,
            video_quality_mode: ?u8,
            message_count: ?u32,
            member_count: ?u32,
            default_auto_archive_duration: ?u32,
            permissions: ?[]const u8,
            flags: ?u32,
        }, allocator, body, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        var channels = allocator.alloc(zignal.models.Channel, parsed.value.len) catch return;
        defer {
            for (channels) |channel| {
                if (channel.name) |n| allocator.free(n);
                if (channel.topic) |t| allocator.free(t);
                if (channel.icon) |i| allocator.free(i);
                if (channel.last_pin_timestamp) |l| allocator.free(l);
                if (channel.rtc_region) |r| allocator.free(r);
                if (channel.permissions) |p| allocator.free(p);
                allocator.free(channel.permission_overwrites);
                allocator.free(channel.recipients);
            }
            allocator.free(channels);
        }

        for (parsed.value, 0..) |channel_data, i| {
            channels[i] = zignal.models.Channel{
                .id = channel_data.id,
                .type = channel_data.type,
                .guild_id = channel_data.guild_id,
                .position = channel_data.position,
                .permission_overwrites = allocator.dupe(zignal.models.PermissionOverwrite, channel_data.permission_overwrites) catch return,
                .name = if (channel_data.name) |n| allocator.dupe(u8, n) catch return else null,
                .topic = if (channel_data.topic) |t| allocator.dupe(u8, t) catch return else null,
                .nsfw = channel_data.nsfw,
                .last_message_id = channel_data.last_message_id,
                .bitrate = channel_data.bitrate,
                .user_limit = channel_data.user_limit,
                .rate_limit_per_user = channel_data.rate_limit_per_user,
                .recipients = allocator.dupe(zignal.models.User, channel_data.recipients) catch return,
                .icon = if (channel_data.icon) |icon| allocator.dupe(u8, icon) catch return else null,
                .owner_id = channel_data.owner_id,
                .application_id = channel_data.application_id,
                .parent_id = channel_data.parent_id,
                .last_pin_timestamp = if (channel_data.last_pin_timestamp) |l| allocator.dupe(u8, l) catch return else null,
                .rtc_region = if (channel_data.rtc_region) |r| allocator.dupe(u8, r) catch return else null,
                .video_quality_mode = channel_data.video_quality_mode,
                .message_count = channel_data.message_count,
                .member_count = channel_data.member_count,
                .default_auto_archive_duration = channel_data.default_auto_archive_duration,
                .permissions = if (channel_data.permissions) |p| allocator.dupe(u8, p) catch return else null,
                .flags = channel_data.flags,
            };
        }

        std.log.info("Found {d} channels:", .{channels.len});
        for (channels) |channel| {
            if (channel.name) |name| {
                const channel_type = switch (channel.type) {
                    0 => "Text",
                    2 => "Voice",
                    4 => "Category",
                    5 => "Announcement",
                    13 => "Stage",
                    15 => "Forum",
                    else => "Unknown",
                };
                std.log.info("  - #{s} ({s})", .{ name, channel_type });
            }
        }

        for (channels) |channel| {
            if (channel.type == 0 and channel.name != null) {
                std.log.info("Sending test message to channel #{s}...", .{channel.name.?});
                
                const embed = zignal.models.Embed{
                    .title = allocator.dupe(u8, "Zignal Test Message") catch return,
                    .description = allocator.dupe(u8, "This is a test message sent using the Zignal Discord API wrapper for Zig!") catch return,
                    .color = 0x5865F2,
                    .footer = zignal.models.EmbedFooter{
                        .text = allocator.dupe(u8, "Sent via Zignal REST API") catch return,
                        .icon_url = null,
                        .proxy_icon_url = null,
                    },
                    .fields = allocator.alloc(zignal.models.EmbedField, 2) catch return,
                    .image = null,
                    .thumbnail = null,
                    .video = null,
                    .provider = null,
                    .author = null,
                    .timestamp = null,
                    .url = null,
                    .type = null,
                };
                
                embed.fields[0] = zignal.models.EmbedField{
                    .name = allocator.dupe(u8, "Features") catch return,
                    .value = allocator.dupe(u8, "• Zero dependencies\n• Pure Zig implementation\n• Full Discord API coverage") catch return,
                    .is_inline = false,
                };
                
                embed.fields[1] = zignal.models.EmbedField{
                    .name = allocator.dupe(u8, "Performance") catch return,
                    .value = allocator.dupe(u8, "Lightning fast with minimal memory usage") catch return,
                    .is_inline = false,
                };
                
                var embeds = allocator.alloc(zignal.models.Embed, 1) catch return;
                embeds[0] = embed;
                
                const message = try client.createMessage(channel.id, "", embeds);
                defer {
                    allocator.free(message.content);
                    allocator.free(message.timestamp);
                    if (message.edited_timestamp) |et| allocator.free(et);
                    allocator.free(message.mentions);
                    allocator.free(message.mention_roles);
                    allocator.free(message.mention_channels);
                    allocator.free(message.attachments);
                    allocator.free(message.embeds);
                    allocator.free(message.reactions);
                    if (message.nonce) |n| allocator.free(n);
                    allocator.free(message.components);
                    allocator.free(message.sticker_items);
                }
                
                std.log.info("Message sent successfully! Message ID: {d}", .{message.id});
                
                std.time.sleep(3 * std.time.ns_per_s);
                
                std.log.info("Deleting test message...", .{});
                try client.deleteMessage(channel.id, message.id);
                std.log.info("Message deleted successfully", .{});
                
                break;
            }
        }
    }

    std.log.info("REST API example completed successfully!", .{});
}
