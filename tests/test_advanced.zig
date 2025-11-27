const std = @import("std");
const testing = std.testing;
const zignal = @import("zignal");

/// Test suite for advanced Zignal features
pub fn main() !void {
    try runConnectionPoolTests();
    try runRequestBatchingTests();
    try runCacheTests();
    try runErrorHandlingTests();
    try runLoggingTests();
    try runVoiceTests();
    try runInteractionTests();
    try runBuilderTests();
    try runPerformanceTests();
    try runIntegrationTests();

    std.log.info("All advanced tests passed!", .{});
}

fn runConnectionPoolTests() !void {
    std.log.info("Running connection pool tests...", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var pool = zignal.pooling.ConnectionPool.init(allocator, 5, 60000);
    defer pool.deinit();

    const conn1 = try pool.acquire("https://discord.com/api/v10");
    const conn2 = try pool.acquire("https://discord.com/api/v10");
    
    try testing.expect(conn1.id != conn2.id);
    try testing.expect(conn1.in_use);
    try testing.expect(conn2.in_use);

    pool.release(conn1);
    const conn3 = try pool.acquire("https://discord.com/api/v10");
    
    try testing.expect(conn3.id == conn1.id);
    try testing.expect(conn3.in_use);

    var connections: [5]*zignal.pooling.ConnectionPool.PooledConnection = undefined;
    for (0..5) |i| {
        connections[i] = try pool.acquire("https://discord.com/api/v10");
    }

    try testing.expectError(error.PoolExhausted, pool.acquire("https://discord.com/api/v10"));

    for (connections) |conn| {
        pool.release(conn);
    }

    std.log.info("Connection pool tests passed", .{});
}

fn runRequestBatchingTests() !void {
    std.log.info("Running request batching tests...", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var batcher = zignal.pooling.RequestBatcher.init(allocator, 10, 1000);
    defer batcher.deinit();

    // Test request addition
    var callback_called = false;
    const callback = struct {
        fn callback(result: zignal.pooling.RequestBatcher.BatchResult) void {
            callback_called = true;
            _ = result;
        }
    }.callback;

    const headers = std.json.ObjectMap.init(allocator);
    defer headers.deinit();

    try batcher.addRequest(
        "GET",
        "https://discord.com/api/v10/channels/123",
        headers,
        null,
        callback,
        5000,
        3,
    );

    const stats = batcher.getStats();
    try testing.expect(stats.pending_requests == 1);

    // Test batch processing
    try batcher.processBatch();
    try testing.expect(callback_called);

    // Test timeout handling
    try batcher.addRequest(
        "GET",
        "https://discord.com/api/v10/channels/456",
        headers,
        null,
        callback,
        1, // 1ms timeout
        0,
    );

    std.time.sleep(2_000_000); // 2ms
    batcher.processTimeouts();

    const timeout_stats = batcher.getStats();
    try testing.expect(timeout_stats.pending_requests == 0);

    std.log.info("Request batching tests passed", .{});
}

fn runCacheTests() !void {
    std.log.info("Running cache tests...", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cache = zignal.cache.Cache.init(allocator, 100);
    defer cache.deinit();

    // Test guild caching
    const guild = zignal.models.Guild{
        .id = 12345,
        .name = try allocator.dupe(u8, "Test Guild"),
        .icon = null,
        .owner_id = 67890,
        .member_count = 100,
        .channels = &[_]zignal.models.Channel{},
        .roles = &[_]zignal.models.Role{},
        .emojis = &[_]zignal.models.Emoji{},
    };
    defer allocator.free(guild.name);

    try cache.addGuild(guild);

    const retrieved_guild = try cache.getGuild(12345);
    try testing.expect(retrieved_guild != null);
    try testing.expect(retrieved_guild.?.id == 12345);
    try testing.expect(std.mem.eql(u8, retrieved_guild.?.name, "Test Guild"));

    // Test cache removal
    try cache.removeGuild(12345);
    const removed_guild = cache.getGuild(12345);
    try testing.expect(removed_guild == null);

    // Test message caching with LRU
    for (0..150) |i| {
        const message = zignal.models.Message{
            .id = @intCast(i),
            .channel_id = 12345,
            .author = .{
                .id = 67890,
                .username = try allocator.dupe(u8, "test_user"),
                .discriminator = "0001",
                .avatar = null,
                .bot = false,
                .system = false,
                .mfa_enabled = false,
                .locale = null,
                .verified = false,
                .email = null,
                .flags = 0,
                .premium_type = 0,
                .public_flags = 0,
            },
            .content = try allocator.dupe(u8, "Test message"),
            .timestamp = std.time.timestamp(),
            .edited_timestamp = null,
            .tts = false,
            .mention_everyone = false,
            .mentions = &[_]zignal.models.User{},
            .mention_roles = &[_]u64{},
            .attachments = &[_]zignal.models.Attachment{},
            .embeds = &[_]zignal.models.Embed{},
            .pinned = false,
            .type = .default_message,
            .flags = null,
            .components = &[_]zignal.interactions.Component{},
        };
        defer {
            allocator.free(message.author.username);
            allocator.free(message.content);
        };

        try cache.addMessage(message);
    }

    // Should only have 100 messages due to LRU
    const stats = cache.getStats();
    try testing.expect(stats.messages_count == 100);

    std.log.info("Cache tests passed", .{});
}

fn runErrorHandlingTests() !void {
    std.log.info("Running error handling tests...", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var error_handler = zignal.errors.ErrorHandler.init(
        allocator,
        zignal.errors.RecoveryConfig{
            .max_retries = 3,
            .base_delay_ms = 100,
            .max_delay_ms = 1000,
            .backoff_multiplier = 2.0,
            .jitter = true,
        },
        100,
    );
    defer error_handler.deinit();

    // Test error context creation
    const error_ctx = zignal.errors.ErrorContext.init(
        allocator,
        zignal.errors.ZignalError.HttpRequestFailed,
        .error,
        "Test error message",
        "test.zig",
        42,
        "test_function",
    ).withGuildId(12345)
     .withChannelId(67890)
     .withUserId(11111)
     .withRequestId(try allocator.dupe(u8, "req_123"));
    defer error_ctx.deinit(allocator);

    try testing.expect(error_ctx.error_code == .HttpRequestFailed);
    try testing.expect(error_ctx.severity == .error);
    try testing.expect(error_ctx.guild_id.? == 12345);
    try testing.expect(error_ctx.channel_id.? == 67890);
    try testing.expect(error_ctx.user_id.? == 11111);
    try testing.expect(std.mem.eql(u8, error_ctx.request_id.?, "req_123"));

    // Test circuit breaker
    var circuit_breaker = zignal.errors.CircuitBreaker.init(allocator, 3, 60000, 30000);
    defer circuit_breaker.deinit();

    // Test successful operation
    var success_count: u32 = 0;
    for (0..5) |_| {
        const result = circuit_breaker.execute(struct {
            fn operation() !void {
                success_count += 1;
            }
        }.operation);
        try result;
    }
    try testing.expect(success_count == 5);

    // Test circuit breaker opening
    var failure_count: u32 = 0;
    for (0..5) |_| {
        const result = circuit_breaker.execute(struct {
            fn operation() !void {
                failure_count += 1;
                return error.TestError;
            }
        }.operation);
        _ = result catch {};
    }
    try testing.expect(failure_count == 3); // Should stop after threshold

    // Test Result type
    const success_result: zignal.errors.Result(u32) = .{ .value = 42 };
    const failure_result: zignal.errors.Result(u32) = .{ .error = .HttpRequestFailed };

    try testing.expect(success_result.unwrap() == 42);
    try testing.expectError(.HttpRequestFailed, failure_result.unwrap());

    std.log.info("Error handling tests passed", .{});
}

fn runLoggingTests() !void {
    std.log.info("Running logging tests...", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var logger = zignal.logging.Logger.init(allocator, .info);
    defer logger.deinit();

    // Test log level filtering
    try testing.expect(logger.getLevel() == .info);
    logger.setLevel(.warning);
    try testing.expect(logger.getLevel() == .warning);

    // Test context management
    try logger.addContext("guild_id", std.json.Value{ .integer = 12345 });
    try logger.addContext("user_id", std.json.Value{ .integer = 67890 });

    const stats = logger.getStats();
    try testing.expect(stats.context_keys == 2);

    // Test metrics
    const metrics = logger.getMetrics();
    const counter = try metrics.counter("test_counter");
    try testing.expect(counter.value == 0);

    counter.inc();
    try testing.expect(counter.value == 1);

    counter.add(5);
    try testing.expect(counter.value == 6);

    // Test gauge
    const gauge = try metrics.gauge("test_gauge");
    try testing.expect(gauge.value == 0.0);

    gauge.set(3.14);
    try testing.expect(gauge.value == 3.14);

    // Test histogram
    const histogram = try metrics.histogram("test_histogram", &[_]f64{ 1.0, 5.0, 10.0 });
    histogram.observe(2.5);
    histogram.observe(7.5);

    try testing.expect(histogram.count == 2);
    try testing.expect(histogram.sum == 10.0);

    // Test timer
    const timer = try metrics.timer("test_timer");
    timer.start();
    std.time.sleep(1_000); // 1ms
    timer.stop();

    const duration = timer.durationMs();
    try testing.expect(duration.? > 0.0);

    std.log.info("Logging tests passed", .{});
}

fn runVoiceTests() !void {
    std.log.info("Running voice tests...", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var voice_manager = zignal.voice.VoiceManager.init(allocator);
    defer voice_manager.deinit();

    // Test voice connection creation
    const connection = try voice_manager.joinVoiceChannel(12345, 67890, 11111);
    try testing.expect(connection.guild_id == 12345);
    try testing.expect(connection.channel_id == 67890);
    try testing.expect(connection.user_id == 11111);

    // Test voice state management
    const initial_state = connection.getStatus();
    try testing.expect(initial_state.state == .disconnected);

    // Test RTP packet creation
    const audio_data = try allocator.alloc(u8, 960 * 2 * 2); // 960 samples, stereo, 16-bit
    defer allocator.free(audio_data);
    std.crypto.random.bytes(audio_data);

    const rtp_packet = try connection.createRTPPacket(audio_data);
    defer allocator.free(rtp_packet);

    try testing.expect(rtp_packet.len > 0);

    // Test encryption key generation
    const encryption_key = try connection.generateEncryptionKey();
    defer allocator.free(encryption_key);

    try testing.expect(encryption_key.len == 32); // 256 bits

    // Test speaking state
    connection.setSpeaking(true);
    const speaking_state = connection.getStatus();
    try testing.expect(speaking_state.speaking);

    // Test cleanup
    voice_manager.leaveVoiceChannel(12345);
    const removed_connection = voice_manager.getConnection(12345);
    try testing.expect(removed_connection == null);

    std.log.info("Voice tests passed", .{});
}

fn runInteractionTests() !void {
    std.log.info("Running interaction tests...", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var interaction_handler = zignal.interactions.InteractionHandler.init(allocator);
    defer interaction_handler.deinit();

    // Test slash command registration
    const ping_handler = try allocator.create(zignal.interactions.InteractionHandler.SlashCommandHandler);
    ping_handler.* = .{
        .name = "ping",
        .description = "Test ping command",
        .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{},
        .execute = struct {
            fn execute(ctx: *zignal.interactions.InteractionHandler.SlashCommandHandler.SlashCommandContext) !void {
                const response = zignal.interactions.InteractionResponse{
                    .type = .channel_message_with_source,
                    .data = .{
                        .tts = false,
                        .content = "Pong!",
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
        }.execute,
    };

    try interaction_handler.registerSlashCommand(ping_handler);

    // Test component handler registration
    const button_handler = try allocator.create(zignal.interactions.InteractionHandler.ComponentHandler);
    button_handler.* = .{
        .custom_id = "test_button",
        .execute = struct {
            fn execute(ctx: *zignal.interactions.InteractionHandler.ComponentHandler.ComponentContext) !void {
                const response = zignal.interactions.InteractionResponse{
                    .type = .update_message,
                    .data = .{
                        .tts = false,
                        .content = "Button clicked!",
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
        }.execute,
    };

    try interaction_handler.registerComponentHandler(button_handler);

    // Test modal handler registration
    const modal_handler = try allocator.create(zignal.interactions.InteractionHandler.ModalHandler);
    modal_handler.* = .{
        .custom_id = "test_modal",
        .execute = struct {
            fn execute(ctx: *zignal.interactions.InteractionHandler.ModalHandler.ModalContext) !void {
                const response = zignal.interactions.InteractionResponse{
                    .type = .channel_message_with_source,
                    .data = .{
                        .tts = false,
                        .content = "Modal submitted!",
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
        }.execute,
    };

    try interaction_handler.registerModalHandler(modal_handler);

    // Test interaction handling
    const test_interaction = zignal.interactions.Interaction{
        .id = 12345,
        .type = .application_command,
        .token = try allocator.dupe(u8, "test_token"),
        .version = 1,
        .application_id = 67890,
        .guild_id = 11111,
        .channel_id = 22222,
        .member = null,
        .user = .{
            .id = 33333,
            .username = try allocator.dupe(u8, "test_user"),
            .discriminator = "0001",
            .avatar = null,
            .bot = false,
            .system = false,
            .mfa_enabled = false,
            .locale = null,
            .verified = false,
            .email = null,
            .flags = 0,
            .premium_type = 0,
            .public_flags = 0,
        },
        .data = .{
            .id = 44444,
            .name = "ping",
            .type = .chat_input,
            .version = 1,
            .guild_id = 11111,
            .application_id = 67890,
            .default_member_permissions = null,
            .dm_permission = null,
            .name_localizations = null,
            .description_localizations = null,
            .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{},
        },
    };
    defer {
        allocator.free(test_interaction.token);
        allocator.free(test_interaction.user.username);
    }

    // This would normally send the response, but we'll just test that it doesn't crash
    try interaction_handler.handleInteraction(test_interaction);

    std.log.info("Interaction tests passed", .{});
}

fn runBuilderTests() !void {
    std.log.info("Running builder tests...", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test MessageBuilder
    const message = try zignal.builders.MessageBuilder.init(allocator)
        .content("Hello, World!")
        .setTTS(false)
        .build();
    defer message.deinit();

    try testing.expect(std.mem.eql(u8, message.content, "Hello, World!"));
    try testing.expect(message.tts == false);

    // Test EmbedBuilder
    const embed = try zignal.builders.EmbedBuilder.init(allocator)
        .title("Test Embed")
        .description("Test description")
        .colorRgb(255, 0, 0)
        .addField("Field 1", "Value 1", true)
        .addField("Field 2", "Value 2", false)
        .build();
    defer embed.deinit();

    try testing.expect(std.mem.eql(u8, embed.title.?, "Test Embed"));
    try testing.expect(std.mem.eql(u8, embed.description.?, "Test description"));
    try testing.expect(embed.color.? == 0xFF0000);
    try testing.expect(embed.fields.len == 2);
    try testing.expect(std.mem.eql(u8, embed.fields[0].name, "Field 1"));
    try testing.expect(embed.fields[0].inline_ == true);

    // Test ChannelBuilder
    const channel_create = try zignal.builders.ChannelBuilder.init(allocator)
        .name("test-channel")
        .type(.text)
        .topic("Test channel")
        .build();
    defer channel_create.deinit();

    try testing.expect(std.mem.eql(u8, channel_create.name, "test-channel"));
    try testing.expect(channel_create.type == .text);
    try testing.expect(std.mem.eql(u8, channel_create.topic.?, "Test channel"));

    // Test RoleBuilder
    const role_create = try zignal.builders.RoleBuilder.init(allocator)
        .name("test-role")
        .colorRgb(0, 255, 0)
        .hoist(true)
        .mentionable(false)
        .build();
    defer role_create.deinit();

    try testing.expect(std.mem.eql(u8, role_create.name, "test-role"));
    try testing.expect(role_create.color.? == 0x00FF00);
    try testing.expect(role_create.hoist == true);
    try testing.expect(role_create.mentionable == false);

    std.log.info("Builder tests passed", .{});
}

fn runPerformanceTests() !void {
    std.log.info("Running performance tests...", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test connection pool performance
    var pool = zignal.pooling.ConnectionPool.init(allocator, 10, 30000);
    defer pool.deinit();

    const pool_start = std.time.nanoTimestamp();
    var connections: [50]*zignal.pooling.ConnectionPool.PooledConnection = undefined;
    for (0..50) |i| {
        connections[i] = try pool.acquire("https://discord.com/api/v10");
    }
    const pool_time = std.time.nanoTimestamp() - pool_start;
    
    try testing.expect(@as(f64, @floatFromInt(pool_time)) / 1_000_000.0 < 100.0); // Should be under 100ms

    for (connections) |conn| {
        pool.release(conn);
    }

    // Test cache performance
    var cache = zignal.cache.Cache.init(allocator, 1000);
    defer cache.deinit();

    const cache_start = std.time.nanoTimestamp();
    for (0..1000) |i| {
        const guild = zignal.models.Guild{
            .id = @intCast(i),
            .name = try std.fmt.allocPrint(allocator, "Guild {d}", .{i}),
            .icon = null,
            .owner_id = 12345,
            .member_count = @intCast(i * 10),
            .channels = &[_]zignal.models.Channel{},
            .roles = &[_]zignal.models.Role{},
            .emojis = &[_]zignal.models.Emoji{},
        };
        try cache.addGuild(guild);
        allocator.free(guild.name);
    }
    const cache_time = std.time.nanoTimestamp() - cache_start;
    
    try testing.expect(@as(f64, @floatFromInt(cache_time)) / 1_000_000.0 < 50.0); // Should be under 50ms

    // Test builder performance
    const builder_start = std.time.nanoTimestamp();
    for (0..1000) |_| {
        const embed = try zignal.builders.EmbedBuilder.init(allocator)
            .title("Test Embed")
            .description("Test description")
            .colorRgb(255, 0, 0)
            .build();
        embed.deinit();
    }
    const builder_time = std.time.nanoTimestamp() - builder_start;
    
    try testing.expect(@as(f64, @floatFromInt(builder_time)) / 1_000_000.0 < 100.0); // Should be under 100ms

    std.log.info("Performance tests passed", .{});
}

fn runIntegrationTests() !void {
    std.log.info("Running integration tests...", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test client with all features
    var client = try zignal.Client.init(allocator, .{
        .token = "test_token",
        .intents = .{
            .guilds = true,
            .guild_messages = true,
            .voice_states = true,
        },
    });
    defer client.deinit();

    // Test integration between components
    var cache = zignal.cache.Cache.init(allocator, 100);
    defer cache.deinit();

    var voice_manager = zignal.voice.VoiceManager.init(allocator);
    defer voice_manager.deinit();

    var interaction_handler = zignal.interactions.InteractionHandler.init(allocator);
    defer interaction_handler.deinit();

    // Test that components work together
    const guild = zignal.models.Guild{
        .id = 12345,
        .name = try allocator.dupe(u8, "Integration Test Guild"),
        .icon = null,
        .owner_id = 67890,
        .member_count = 100,
        .channels = &[_]zignal.models.Channel{},
        .roles = &[_]zignal.models.Role{},
        .emojis = &[_]zignal.models.Emoji{},
    };
    defer allocator.free(guild.name);

    try cache.addGuild(guild);

    const retrieved_guild = try cache.getGuild(12345);
    try testing.expect(retrieved_guild != null);
    try testing.expect(retrieved_guild.?.id == 12345);

    // Test voice manager integration
    const voice_connection = try voice_manager.joinVoiceChannel(12345, 11111, 22222);
    try testing.expect(voice_connection.guild_id == 12345);

    // Test interaction handler integration
    const ping_handler = try allocator.create(zignal.interactions.InteractionHandler.SlashCommandHandler);
    ping_handler.* = .{
        .name = "ping",
        .description = "Integration test ping",
        .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{},
        .execute = struct {
            fn execute(ctx: *zignal.interactions.InteractionHandler.SlashCommandHandler.SlashCommandContext) !void {
                _ = ctx;
            }
        }.execute,
    };
    try interaction_handler.registerSlashCommand(ping_handler);

    // Test error handling integration
    var error_handler = zignal.errors.ErrorHandler.init(
        allocator,
        zignal.errors.RecoveryConfig{
            .max_retries = 2,
            .base_delay_ms = 100,
            .max_delay_ms = 500,
            .backoff_multiplier = 1.5,
            .jitter = false,
        },
        500,
    );
    defer error_handler.deinit();

    const error_ctx = zignal.errors.ErrorContext.init(
        allocator,
        zignal.errors.ZignalError.HttpRequestFailed,
        .warning,
        "Integration test error",
        "test.zig",
        42,
        "integration_test",
    );
    defer error_ctx.deinit(allocator);

    error_handler.handleError(error_ctx) catch {};

    std.log.info("Integration tests passed", .{});
}
