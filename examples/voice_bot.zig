const std = @import("std");
const zignal = @import("zignal");

/// Voice bot demonstrating audio features
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize logger
    try zignal.logging.initGlobalLogger(allocator, .info);
    defer zignal.logging.deinitGlobalLogger(allocator);
    const logger = zignal.logging.getGlobalLogger().?;

    // Create client
    const token = "YOUR_BOT_TOKEN";
    var client = zignal.Client.init(allocator, token);
    defer client.deinit();

    // Initialize voice manager
    var voice_manager = zignal.voice.VoiceManager.init(allocator);
    defer voice_manager.deinit();

    // Initialize cache
    var cache = zignal.cache.Cache.init(allocator, 5000);
    defer cache.deinit();

    // Setup event handlers
    try setupVoiceEventHandlers(&client, &voice_manager, &cache, logger);

    // Connect to gateway
    try client.connect();

    logger.info("Voice bot started", .{});

    // Main loop
    while (true) {
        try client.processEvents();
        voice_manager.updateConnections();
        std.time.sleep(10_000_000); // 10ms
    }
}

fn setupVoiceEventHandlers(
    client: *zignal.Client,
    voice_manager: *zignal.voice.VoiceManager,
    cache: *zignal.cache.Cache,
    logger: *zignal.logging.Logger,
) !void {
    // Mark parameters as used (they're passed to event handlers)
    _ = voice_manager;
    _ = cache;
    _ = logger;
    // Ready event
    client.on(.ready, struct {
        fn handler(event: zignal.events.ReadyEvent, event_logger: *zignal.logging.Logger) !void {
            event_logger.info("Voice bot ready: {s}", .{event.user.username});
        }
    }.handler);

    // Message create event for voice commands
    client.on(.message_create, struct {
        fn handler(
            message: zignal.models.Message,
            vm: *zignal.voice.VoiceManager,
            msg_cache: *zignal.cache.Cache,
            msg_logger: *zignal.logging.Logger,
        ) !void {
            try handleVoiceCommand(message, vm, msg_cache, msg_logger);
        }
    }.handler);

    // Voice state update event
    client.on(.voice_state_update, struct {
        fn handler(
            voice_state: zignal.models.VoiceState,
            vm: *zignal.voice.VoiceManager,
            vs_logger: *zignal.logging.Logger,
        ) !void {
            _ = vm; // Voice manager available for state tracking
            vs_logger.info("Voice state update for user {d}", .{voice_state.user_id});
        }
    }.handler);

    // Voice server update event
    client.on(.voice_server_update, struct {
        fn handler(
            voice_server: zignal.events.VoiceServerUpdateEvent,
            vm: *zignal.voice.VoiceManager,
            vs_logger: *zignal.logging.Logger,
        ) !void {
            try handleVoiceServerUpdate(voice_server, vm, vs_logger);
        }
    }.handler);
}

fn handleVoiceCommand(
    message: zignal.models.Message,
    voice_manager: *zignal.voice.VoiceManager,
    cache: *zignal.cache.Cache,
    logger: *zignal.logging.Logger,
) !void {
    if (!std.mem.startsWith(u8, message.content, "!voice")) return;

    const args = std.mem.splitScalar(u8, message.content, ' ');
    _ = args.first(); // Skip "!voice"
    const command = args.first();

    if (std.mem.eql(u8, command, "join")) {
        try handleVoiceJoin(message, voice_manager, cache, logger);
    } else if (std.mem.eql(u8, command, "leave")) {
        try handleVoiceLeave(message, voice_manager, logger);
    } else if (std.mem.eql(u8, command, "play")) {
        const url = args.rest();
        try handleVoicePlay(message, url, voice_manager, logger);
    } else if (std.mem.eql(u8, command, "stop")) {
        try handleVoiceStop(message, voice_manager, logger);
    } else if (std.mem.eql(u8, command, "pause")) {
        try handleVoicePause(message, voice_manager, logger);
    } else if (std.mem.eql(u8, command, "resume")) {
        try handleVoiceResume(message, voice_manager, logger);
    } else if (std.mem.eql(u8, command, "status")) {
        try handleVoiceStatus(message, voice_manager, logger);
    }
}

fn handleVoiceJoin(
    message: zignal.models.Message,
    voice_manager: *zignal.voice.VoiceManager,
    cache: *zignal.cache.Cache,
    logger: *zignal.logging.Logger,
) !void {
    const guild_id = message.guild_id orelse return;
    const user_id = message.author.id;

    // Find user's voice channel
    const guild = try cache.getGuild(guild_id) orelse return;
    const voice_channel = findUserVoiceChannel(guild, user_id) orelse {
        try sendMessage(message.channel_id, "❌ You must be in a voice channel first!", logger);
        return;
    };

    // Join voice channel
    _ = try voice_manager.joinVoiceChannel(
        guild_id,
        voice_channel.id,
        user_id,
    );

    logger.info("Joining voice channel {d} in guild {d}", .{ voice_channel.id, guild_id });

    const embed = zignal.builders.EmbedBuilder.init(logger.allocator)
        .title("🎤 Voice Connection")
        .description(try std.fmt.allocPrint(
            logger.allocator,
            "Joined voice channel: **{s}**",
            .{voice_channel.name orelse "Unknown"}
        ))
        .colorRgb(0, 255, 0)
        .build() catch return;

    try sendEmbed(message.channel_id, embed, logger);
}

fn handleVoiceLeave(
    message: zignal.models.Message,
    voice_manager: *zignal.voice.VoiceManager,
    logger: *zignal.logging.Logger,
) !void {
    const guild_id = message.guild_id orelse return;

    if (voice_manager.leaveVoiceChannel(guild_id)) {
        logger.info("Left voice channel in guild {d}", .{guild_id});

        const embed = zignal.builders.EmbedBuilder.init(logger.allocator)
            .title("🎤 Voice Connection")
            .description("Left voice channel")
            .colorRgb(255, 165, 0)
            .build() catch return;

        try sendEmbed(message.channel_id, embed, logger);
    } else {
        try sendMessage(message.channel_id, "❌ Not in a voice channel", logger);
    }
}

fn handleVoicePlay(
    message: zignal.models.Message,
    url: []const u8,
    voice_manager: *zignal.voice.VoiceManager,
    logger: *zignal.logging.Logger,
) !void {
    const guild_id = message.guild_id orelse return;
    const voice_connection = voice_manager.getConnection(guild_id) orelse {
        try sendMessage(message.channel_id, "❌ Not in a voice channel", logger);
        return;
    };

    // Start playing audio from URL
    try voice_connection.playAudio(url);

    logger.info("Playing audio from: {s}", .{url});

    const embed = zignal.builders.EmbedBuilder.init(logger.allocator)
        .title("🎵 Now Playing")
        .description(try std.fmt.allocPrint(logger.allocator, "Playing: {s}", .{url}))
        .colorRgb(0, 255, 255)
        .build() catch return;

    try sendEmbed(message.channel_id, embed, logger);
}

fn handleVoiceStop(
    message: zignal.models.Message,
    voice_manager: *zignal.voice.VoiceManager,
    logger: *zignal.logging.Logger,
) !void {
    const guild_id = message.guild_id orelse return;
    const voice_connection = voice_manager.getConnection(guild_id) orelse {
        try sendMessage(message.channel_id, "❌ Not in a voice channel", logger);
        return;
    };

    voice_connection.stopAudio();

    logger.info("Stopped audio playback in guild {d}", .{guild_id});

    try sendMessage(message.channel_id, "⏹️ Stopped playback", logger);
}

fn handleVoicePause(
    message: zignal.models.Message,
    voice_manager: *zignal.voice.VoiceManager,
    logger: *zignal.logging.Logger,
) !void {
    const guild_id = message.guild_id orelse return;
    const voice_connection = voice_manager.getConnection(guild_id) orelse {
        try sendMessage(message.channel_id, "❌ Not in a voice channel", logger);
        return;
    };

    voice_connection.pauseAudio();

    logger.info("Paused audio playback in guild {d}", .{guild_id});

    try sendMessage(message.channel_id, "⏸️ Paused playback", logger);
}

fn handleVoiceResume(
    message: zignal.models.Message,
    voice_manager: *zignal.voice.VoiceManager,
    logger: *zignal.logging.Logger,
) !void {
    const guild_id = message.guild_id orelse return;
    const voice_connection = voice_manager.getConnection(guild_id) orelse {
        try sendMessage(message.channel_id, "❌ Not in a voice channel", logger);
        return;
    };

    voice_connection.resumeAudio();

    logger.info("Resumed audio playback in guild {d}", .{guild_id});

    try sendMessage(message.channel_id, "▶️ Resumed playback", logger);
}

fn handleVoiceStatus(
    message: zignal.models.Message,
    voice_manager: *zignal.voice.VoiceManager,
    logger: *zignal.logging.Logger,
) !void {
    const guild_id = message.guild_id orelse return;
    const voice_connection = voice_manager.getConnection(guild_id) orelse {
        try sendMessage(message.channel_id, "❌ Not in a voice channel", logger);
        return;
    };

    const status = voice_connection.getStatus();
    const stats = voice_connection.getStats();

    const embed = zignal.builders.EmbedBuilder.init(logger.allocator)
        .title("🎤 Voice Status")
        .field("Connection State", try std.fmt.allocPrint(logger.allocator, "{s}", .{@tagName(status.state)}), true)
        .field("Speaking", try std.fmt.allocPrint(logger.allocator, "{}", .{status.speaking}), true)
        .field("Audio Playing", try std.fmt.allocPrint(logger.allocator, "{}", .{status.audio_playing}), true)
        .field("Packets Sent", try std.fmt.allocPrint(logger.allocator, "{d}", .{stats.packets_sent}), true)
        .field("Packets Received", try std.fmt.allocPrint(logger.allocator, "{d}", .{stats.packets_received}), true)
        .field("Bytes Sent", try std.fmt.allocPrint(logger.allocator, "{d}", .{stats.bytes_sent}), true)
        .field("Bytes Received", try std.fmt.allocPrint(logger.allocator, "{d}", .{stats.bytes_received}), true)
        .field("Latency", try std.fmt.allocPrint(logger.allocator, "{d}ms", .{stats.latency_ms}), true)
        .colorRgb(0, 128, 255)
        .build() catch return;

    try sendEmbed(message.channel_id, embed, logger);
}

fn handleVoiceStateUpdate(
    voice_state: zignal.models.VoiceState,
    voice_manager: *zignal.voice.VoiceManager,
    logger: *zignal.logging.Logger,
) !void {
    const guild_id = voice_state.guild_id orelse return;
    
    logger.info(
        "Voice state update: user {d} in channel {d} (deaf: {}, mute: {})",
        .{ voice_state.user_id, voice_state.channel_id orelse 0, voice_state.deaf, voice_state.mute }
    );

    // Update voice connection if needed
    if (voice_state.user_id == voice_manager.getBotUserId(guild_id)) {
        const connection = voice_manager.getConnection(guild_id) orelse return;
        connection.updateVoiceState(voice_state);
    }
}

fn handleVoiceServerUpdate(
    voice_server: zignal.events.VoiceServerUpdateEvent,
    voice_manager: *zignal.voice.VoiceManager,
    logger: *zignal.logging.Logger,
) !void {
    const guild_id = voice_server.guild_id;
    
    logger.info(
        "Voice server update for guild {d}: endpoint={s}, token_len={d}",
        .{ guild_id, voice_server.endpoint, voice_server.token.len }
    );

    // Update voice connection with server information
    const connection = voice_manager.getConnection(guild_id) orelse return;
    try connection.updateVoiceServer(voice_server.endpoint, voice_server.token);
}

fn findUserVoiceChannel(guild: zignal.models.Guild, user_id: u64) ?zignal.models.Channel {
    _ = user_id; // Will be used when voice states are implemented
    // This would typically involve checking voice states
    // For now, return the first voice channel as a placeholder
    for (guild.channels) |channel| {
        if (channel.type == 2) { // GUILD_VOICE
            return channel;
        }
    }
    return null;
}

fn sendMessage(channel_id: u64, content: []const u8, logger: *zignal.logging.Logger) !void {
    // This would send a message via the client
    logger.info("Sending message to channel {d}: {s}", .{ channel_id, content });
}

fn sendEmbed(channel_id: u64, embed: zignal.models.Embed, logger: *zignal.logging.Logger) !void {
    // This would send an embed via the client
    logger.info("Sending embed to channel {d}: {s}", .{ channel_id, embed.title orelse "Untitled" });
}
