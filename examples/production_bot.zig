const std = @import("std");
const zignal = @import("zignal");

/// Production Discord bot demonstrating advanced features
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize logger
    try zignal.logging.initGlobalLogger(allocator, .info);
    defer zignal.logging.deinitGlobalLogger(allocator);
    const logger = zignal.logging.getGlobalLogger().?;

    // Initialize error handler
    var error_handler = zignal.errors.ErrorHandler.init(
        allocator,
        zignal.errors.RecoveryConfig{
            .max_retries = 3,
            .base_delay_ms = 1000,
            .max_delay_ms = 30000,
            .backoff_multiplier = 2.0,
            .jitter = true,
        },
        1000,
    );
    defer error_handler.deinit();

    // Initialize performance monitoring
    var connection_pool = zignal.pooling.ConnectionPool.init(allocator, 10, 60000);
    defer connection_pool.deinit();

    var request_batcher = zignal.pooling.RequestBatcher.init(allocator, 50, 5000);
    defer request_batcher.deinit();

    var monitor = zignal.pooling.PerformanceMonitor.init(
        allocator,
        &connection_pool,
        &request_batcher,
        logger,
    );
    defer monitor.deinit();

    // Create client with advanced configuration
    var client = try zignal.Client.init(allocator, .{
        .token = "YOUR_BOT_TOKEN",
        .intents = .{
            .guilds = true,
            .guild_messages = true,
            .guild_members = true,
            .message_content = true,
            .voice_states = true,
        },
        .connection_pool = &connection_pool,
        .request_batcher = &request_batcher,
        .error_handler = &error_handler,
    });
    defer client.deinit();

    // Initialize cache
    var cache = zignal.cache.Cache.init(allocator, 10000);
    defer cache.deinit();

    // Initialize shard manager for large bots
    var shard_manager = zignal.shard.ShardManager.init(allocator, .{
        .auto_sharding = true,
        .max_shards = 10,
        .client = &client,
    });
    defer shard_manager.deinit();

    // Initialize interaction handler
    var interaction_handler = zignal.interactions.InteractionHandler.init(allocator);
    defer interaction_handler.deinit();

    // Register slash commands
    try registerSlashCommands(&interaction_handler, allocator);

    // Initialize voice manager
    var voice_manager = zignal.voice.VoiceManager.init(allocator);
    defer voice_manager.deinit();

    // Setup event handlers
    try setupEventHandlers(&client, &cache, &voice_manager, &interaction_handler, logger);

    // Start monitoring
    try monitor.addRateLimiter(zignal.pooling.RateLimiter.init(allocator, 100, 10.0));

    // Connect shards
    try shard_manager.connect();

    logger.info("Production bot started successfully", .{});

    // Main loop with health monitoring
    var health_check_timer = try std.time.Timer.start();
    while (true) {
        // Process events
        try shard_manager.processEvents();

        // Process timeouts
        request_batcher.processTimeouts();

        // Clean up idle connections
        connection_pool.cleanupIdleConnections();

        // Health check every 30 seconds
        if (health_check_timer.read() > 30_000_000_000) {
            const stats = monitor.getStats();
            logger.info(
                "Health Check - Connections: {d}, Pending: {d}, Memory: {d:.2}MB",
                .{ stats.connection_pool.total_connections, stats.request_batcher.pending_requests, stats.performance.memory_usage_mb }
            );
            health_check_timer.reset();
        }

        // Small delay to prevent CPU spinning
        std.time.sleep(10_000_000); // 10ms
    }
}

fn registerSlashCommands(handler: *zignal.interactions.InteractionHandler, allocator: std.mem.Allocator) !void {
    // Ping command
    const ping_handler = try allocator.create(zignal.interactions.InteractionHandler.SlashCommandHandler);
    ping_handler.* = .{
        .name = "ping",
        .description = "Check bot latency",
        .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{},
        .execute = handlePing,
    };
    try handler.registerSlashCommand(ping_handler);

    // Echo command with options
    const echo_handler = try allocator.create(zignal.interactions.InteractionHandler.SlashCommandHandler);
    echo_handler.* = .{
        .name = "echo",
        .description = "Echo back your message",
        .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{
            .{
                .type = .string,
                .name = "message",
                .description = "Message to echo",
                .required = true,
                .choices = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption.Choice{},
                .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{},
                .channel_types = &[_]u64{},
                .min_value = null,
                .max_value = null,
                .autocomplete = false,
            },
        },
        .execute = handleEcho,
    };
    try handler.registerSlashCommand(echo_handler);

    // Voice join command
    const voice_handler = try allocator.create(zignal.interactions.InteractionHandler.SlashCommandHandler);
    voice_handler.* = .{
        .name = "join",
        .description = "Join your voice channel",
        .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{},
        .execute = handleVoiceJoin,
    };
    try handler.registerSlashCommand(voice_handler);
}

fn setupEventHandlers(
    client: *zignal.Client,
    cache: *zignal.cache.Cache,
    voice_manager: *zignal.voice.VoiceManager,
    interaction_handler: *zignal.interactions.InteractionHandler,
    logger: *zignal.logging.Logger,
) !void {
    // Ready event
    client.on(.ready, struct {
        fn handler(event: zignal.events.ReadyEvent) !void {
            logger.info(
                "Bot ready: {s}#{s} ({d})",
                .{ event.user.username, event.user.discriminator, event.user.id }
            );
        }
    }.handler);

    // Message create event
    client.on(.message_create, struct {
        fn handler(message: zignal.models.Message, cache: *zignal.cache.Cache, logger: *zignal.logging.Logger) !void {
            // Cache the message
            try cache.addMessage(message);

            // Handle commands
            if (std.mem.startsWith(u8, message.content, "!")) {
                try handleTextCommand(message, cache, logger);
            }
        }
    }.handler);

    // Guild create event
    client.on(.guild_create, struct {
        fn handler(guild: zignal.models.Guild, cache: *zignal.cache.Cache, logger: *zignal.logging.Logger) !void {
            logger.info("Joined guild: {s} ({d})", .{ guild.name, guild.id });
            try cache.addGuild(guild);
        }
    }.handler);

    // Voice state update event
    client.on(.voice_state_update, struct {
        fn handler(
            voice_state: zignal.models.VoiceState,
            voice_manager: *zignal.voice.VoiceManager,
            logger: *zignal.logging.Logger,
        ) !void {
            logger.info(
                "Voice state update: {d} in channel {d}",
                .{ voice_state.user_id, voice_state.channel_id orelse 0 }
            );
            // Handle voice connections
        }
    }.handler);
}

fn handlePing(ctx: *zignal.interactions.InteractionHandler.SlashCommandHandler.SlashCommandContext) !void {
    const start_time = std.time.nanoTimestamp();
    
    // Simulate some work
    std.time.sleep(100_000); // 0.1ms
    
    const end_time = std.time.nanoTimestamp();
    const latency_ms = @as(f64, @floatFromInt(end_time - start_time)) / 1_000_000.0;

    const response = zignal.interactions.InteractionResponse{
        .type = .channel_message_with_source,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = try std.fmt.allocPrint(ctx.allocator, "Pong! Latency: {d:.2}ms", .{latency_ms}),
            .embeds = &[_]zignal.models.Embed{},
            .allowed_mentions = null,
            .flags = null,
            .components = &[_]zignal.interactions.Component{},
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = null,
            .title = null,
        },
    };

    ctx.respond(&ctx, response);
}

fn handleEcho(ctx: *zignal.interactions.InteractionHandler.SlashCommandHandler.SlashCommandContext) !void {
    const message_value = ctx.get_option("message") orelse return;
    const message = message_value.string;

    // Create an embed with the echoed message
    const embed = zignal.builders.EmbedBuilder.init(ctx.allocator)
        .title("Echo Message")
        .description(message)
        .colorRgb(0, 255, 0)
        .build() catch return;

    const response = zignal.interactions.InteractionResponse{
        .type = .channel_message_with_source,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = null,
            .embeds = &[_]zignal.models.Embed{embed},
            .allowed_mentions = null,
            .flags = null,
            .components = &[_]zignal.interactions.Component{},
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = null,
            .title = null,
        },
    };

    ctx.respond(&ctx, response);
}

fn handleVoiceJoin(ctx: *zignal.interactions.InteractionHandler.SlashCommandHandler.SlashCommandContext) !void {
    // Get user's voice channel
    const guild_id = ctx.interaction.guild_id orelse return;
    const user_id = ctx.interaction.user.?.id;

    // This would typically involve:
    // 1. Finding the user's current voice channel
    // 2. Joining the voice channel using the voice manager
    // 3. Setting up voice connection

    const response = zignal.interactions.InteractionResponse{
        .type = .channel_message_with_source,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = "Joining your voice channel...",
            .embeds = &[_]zignal.models.Embed{},
            .allowed_mentions = null,
            .flags = null,
            .components = &[_]zignal.interactions.Component{},
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = null,
            .title = null,
        },
    };

    ctx.respond(&ctx, response);
}

fn handleTextCommand(message: zignal.models.Message, cache: *zignal.cache.Cache, logger: *zignal.logging.Logger) !void {
    const content = message.content;
    const args = std.mem.splitScalar(u8, content, ' ');
    const command = args.first();

    if (std.mem.eql(u8, command, "!stats")) {
        try handleStatsCommand(message, cache, logger);
    } else if (std.mem.eql(u8, command, "!cache")) {
        try handleCacheCommand(message, cache, logger);
    } else if (std.mem.eql(u8, command, "!help")) {
        try handleHelpCommand(message, logger);
    }
}

fn handleStatsCommand(message: zignal.models.Message, cache: *zignal.cache.Cache, logger: *zignal.logging.Logger) !void {
    const stats = cache.getStats();
    
    const embed = zignal.builders.EmbedBuilder.init(logger.allocator)
        .title("Bot Statistics")
        .field("Guilds Cached", try std.fmt.allocPrint(logger.allocator, "{d}", .{stats.guilds_count}), true)
        .field("Channels Cached", try std.fmt.allocPrint(logger.allocator, "{d}", .{stats.channels_count}), true)
        .field("Users Cached", try std.fmt.allocPrint(logger.allocator, "{d}", .{stats.users_count}), true)
        .field("Messages Cached", try std.fmt.allocPrint(logger.allocator, "{d}", .{stats.messages_count}), true)
        .colorRgb(0, 255, 255)
        .build() catch return;

    // Send response using message builder
    const msg_builder = zignal.builders.MessageBuilder.init(logger.allocator)
        .content("📊 **Bot Statistics**")
        .addEmbed(embed)
        .reply(message.id);

    const response_message = try msg_builder.build();
    _ = response_message; // Would send via client
}

fn handleCacheCommand(message: zignal.models.Message, cache: *zignal.cache.Cache, logger: *zignal.logging.Logger) !void {
    const stats = cache.getStats();
    
    const embed = zignal.builders.EmbedBuilder.init(logger.allocator)
        .title("Cache Information")
        .field("Total Items", try std.fmt.allocPrint(logger.allocator, "{d}", .{stats.total_items}), true)
        .field("Memory Usage", try std.fmt.allocPrint(logger.allocator, "{d}MB", .{stats.memory_usage_mb}), true)
        .field("Hit Rate", try std.fmt.allocPrint(logger.allocator, "{d:.2}%", .{stats.hit_rate * 100.0}), true)
        .colorRgb(255, 165, 0)
        .build() catch return;

    const msg_builder = zignal.builders.MessageBuilder.init(logger.allocator)
        .content("💾 **Cache Information**")
        .addEmbed(embed)
        .reply(message.id);

    const response_message = try msg_builder.build();
    _ = response_message; // Would send via client
}

fn handleHelpCommand(message: zignal.models.Message, logger: *zignal.logging.Logger) !void {
    const embed = zignal.builders.EmbedBuilder.init(logger.allocator)
        .title("Bot Help")
        .description("Available commands:")
        .field("!stats", "Show bot statistics", true)
        .field("!cache", "Show cache information", true)
        .field("!help", "Show this help message", true)
        .field("/ping", "Check bot latency", true)
        .field("/echo <message>", "Echo back a message", true)
        .field("/join", "Join your voice channel", true)
        .colorRgb(0, 128, 255)
        .build() catch return;

    const msg_builder = zignal.builders.MessageBuilder.init(logger.allocator)
        .content("❓ **Help Menu**")
        .addEmbed(embed)
        .reply(message.id);

    const response_message = try msg_builder.build();
    _ = response_message; // Would send via client
}
