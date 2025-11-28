const std = @import("std");
const zignal = @import("zignal");

/// Performance benchmark demonstrating optimization features
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize logger
    try zignal.logging.initGlobalLogger(allocator, .info);
    defer zignal.logging.deinitGlobalLogger(allocator);
    const logger = zignal.logging.getGlobalLogger().?;

    logger.info("🚀 Starting Zignal Performance Benchmark", .{});

    // Initialize performance monitoring components
    var connection_pool = zignal.pooling.ConnectionPool.init(allocator, 20, 30000);
    defer connection_pool.deinit();

    var request_batcher = zignal.pooling.RequestBatcher.init(allocator, 100, 1000);
    defer request_batcher.deinit();

    var monitor = zignal.pooling.PerformanceMonitor.init(
        allocator,
        &connection_pool,
        &request_batcher,
        logger,
    );
    defer monitor.deinit();

    // Add rate limiters
    try monitor.addRateLimiter(zignal.pooling.RateLimiter.init(allocator, 1000, 100.0));
    try monitor.addRateLimiter(zignal.pooling.RateLimiter.init(allocator, 100, 10.0));

    // Run comprehensive benchmarks
    try runConnectionPoolBenchmark(&connection_pool, logger);
    try runRequestBatchingBenchmark(&request_batcher, logger);
    try runCacheBenchmark(allocator, logger);
    try runMemoryBenchmark(allocator, logger);
    try runJsonBenchmark(allocator, logger);
    try runErrorHandlingBenchmark(allocator, logger);
    try runVoiceBenchmark(allocator, logger);
    try runInteractionBenchmark(allocator, logger);

    // Generate comprehensive report
    const report = try monitor.generateReport();
    defer allocator.free(report);

    logger.info("\n📊 {s}", .{report});

    logger.info("✅ Performance benchmark completed", .{});
}

fn runConnectionPoolBenchmark(
    pool: *zignal.pooling.ConnectionPool,
    logger: *zignal.logging.Logger,
) !void {
    logger.info("🔗 Testing Connection Pool Performance", .{});

    const start_time = std.time.nanoTimestamp();
    var connections: [100]*zignal.pooling.ConnectionPool.PooledConnection = undefined;

    // Test connection acquisition
    for (0..100) |i| {
        connections[i] = try pool.acquire("https://discord.com/api/v10");
    }

    const acquisition_time = std.time.nanoTimestamp() - start_time;
    logger.info("  Connection acquisition: {d:.2}ms (100 connections)", .{@as(f64, @floatFromInt(acquisition_time)) / 1_000_000.0});

    // Test connection reuse
    const reuse_start = std.time.nanoTimestamp();
    for (0..50) |i| {
        pool.release(connections[i]);
        connections[i] = try pool.acquire("https://discord.com/api/v10");
    }
    const reuse_time = std.time.nanoTimestamp() - reuse_start;
    logger.info("  Connection reuse: {d:.2}ms (50 cycles)", .{@as(f64, @floatFromInt(reuse_time)) / 1_000_000.0});

    // Release all connections
    for (connections) |conn| {
        pool.release(conn);
    }

    // Get pool stats
    const stats = pool.getStats();
    logger.info("  Pool utilization: {d:.2}%", .{stats.connection_utilization * 100.0});
    logger.info("  Total connections: {d}", .{stats.total_connections});
}

fn runRequestBatchingBenchmark(
    batcher: *zignal.pooling.RequestBatcher,
    logger: *zignal.logging.Logger,
) !void {
    logger.info("📦 Testing Request Batching Performance", .{});

    const start_time = std.time.nanoTimestamp();

    // Simulate adding many requests
    for (0..1000) |i| {
        const url = try std.fmt.allocPrint(logger.allocator, "https://discord.com/api/v10/channels/{d}", .{i});
        defer logger.allocator.free(url);

        const headers = std.json.ObjectMap.init(logger.allocator);
        defer headers.deinit();

        const callback = struct {
            fn callback(result: zignal.pooling.RequestBatcher.BatchResult) void {
                _ = result; // Handle result
            }
        }.callback;

        try batcher.addRequest(
            "GET",
            url,
            headers,
            null,
            callback,
            5000,
            3,
        );
    }

    const add_time = std.time.nanoTimestamp() - start_time;
    logger.info("  Request queuing: {d:.2}ms (1000 requests)", .{@as(f64, @floatFromInt(add_time)) / 1_000_000.0});

    // Process batches
    const process_start = std.time.nanoTimestamp();
    try batcher.processBatch();
    const process_time = std.time.nanoTimestamp() - process_start;
    logger.info("  Batch processing: {d:.2}ms", .{@as(f64, @floatFromInt(process_time)) / 1_000_000.0});

    // Get batcher stats
    const stats = batcher.getStats();
    logger.info("  Pending requests: {d}", .{stats.pending_requests});
    logger.info("  Average wait time: {d:.2}ms", .{stats.average_wait_time_ms});
}

fn runCacheBenchmark(allocator: std.mem.Allocator, logger: *zignal.logging.Logger) !void {
    logger.info("💾 Testing Cache Performance", .{});

    var cache = zignal.cache.Cache.init(allocator, 10000);
    defer cache.deinit();

    const start_time = std.time.nanoTimestamp();

    // Add many items to cache
    for (0..10000) |i| {
        const guild = zignal.models.Guild{
            .id = @intCast(i),
            .name = try std.fmt.allocPrint(allocator, "Test Guild {d}", .{i}),
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

    const add_time = std.time.nanoTimestamp() - start_time;
    logger.info("  Cache insertion: {d:.2}ms (10000 items)", .{@as(f64, @floatFromInt(add_time)) / 1_000_000.0});

    // Test cache retrieval
    const retrieve_start = std.time.nanoTimestamp();
    var hits: u32 = 0;
    for (0..10000) |i| {
        if (cache.getGuild(@intCast(i))) |_| {
            hits += 1;
        }
    }
    const retrieve_time = std.time.nanoTimestamp() - retrieve_start;
    logger.info("  Cache retrieval: {d:.2}ms (10000 lookups)", .{@as(f64, @floatFromInt(retrieve_time)) / 1_000_000.0});
    logger.info("  Cache hit rate: {d:.2}%", .{@as(f64, @floatFromInt(hits)) / 10000.0 * 100.0});

    // Get cache stats
    const stats = cache.getStats();
    logger.info("  Memory usage: {d:.2}MB", .{stats.memory_usage_mb});
    logger.info("  Total items: {d}", .{stats.total_items});
}

fn runMemoryBenchmark(allocator: std.mem.Allocator, logger: *zignal.logging.Logger) !void {
    logger.info("🧠 Testing Memory Management", .{});

    const start_time = std.time.nanoTimestamp();

    // Test string allocation and deallocation
    var strings = std.ArrayList([]const u8).init(allocator);
    defer strings.deinit();

    for (0..100000) |i| {
        const str = try std.fmt.allocPrint(allocator, "Test string {d}", .{i});
        try strings.append(str);
    }

    const alloc_time = std.time.nanoTimestamp() - start_time;
    logger.info("  String allocation: {d:.2}ms (100000 strings)", .{@as(f64, @floatFromInt(alloc_time)) / 1_000_000.0});

    // Test memory deallocation
    const dealloc_start = std.time.nanoTimestamp();
    for (strings.items) |str| {
        allocator.free(str);
    }
    strings.clearAndFree();
    const dealloc_time = std.time.nanoTimestamp() - dealloc_start;
    logger.info("  String deallocation: {d:.2}ms", .{@as(f64, @floatFromInt(dealloc_time)) / 1_000_000.0});

    // Test zero-copy operations
    const zero_copy_start = std.time.nanoTimestamp();
    for (0..100000) |i| {
        const str = "Zero copy test string";
        _ = str[i % str.len]; // Access without copying
    }
    const zero_copy_time = std.time.nanoTimestamp() - zero_copy_start;
    logger.info("  Zero-copy access: {d:.2}ms (100000 accesses)", .{@as(f64, @floatFromInt(zero_copy_time)) / 1_000_000.0});
}

fn runJsonBenchmark(allocator: std.mem.Allocator, logger: *zignal.logging.Logger) !void {
    logger.info("📄 Testing JSON Performance", .{});

    // Create test JSON object
    var test_obj = std.json.ObjectMap.init(allocator);
    defer test_obj.deinit();

    try test_obj.put("id", std.json.Value{ .integer = 12345 });
    try test_obj.put("name", std.json.Value{ .string = try allocator.dupe(u8, "Test Object") });
    try test_obj.put("active", std.json.Value{ .bool = true });

    var array = std.ArrayList(std.json.Value).init(allocator);
    defer array.deinit();
    try array.append(std.json.Value{ .integer = 1 });
    try array.append(std.json.Value{ .integer = 2 });
    try array.append(std.json.Value{ .integer = 3 });
    try test_obj.put("numbers", std.json.Value{ .array = array.toOwnedSlice() });

    // Test JSON serialization
    const serialize_start = std.time.nanoTimestamp();
    for (0..10000) |_| {
        const json_str = try std.json.stringifyAlloc(allocator, std.json.Value{ .object = test_obj }, .{});
        allocator.free(json_str);
    }
    const serialize_time = std.time.nanoTimestamp() - serialize_start;
    logger.info("  JSON serialization: {d:.2}ms (10000 operations)", .{@as(f64, @floatFromInt(serialize_time)) / 1_000_000.0});

    // Test JSON parsing
    const json_str = try std.json.stringifyAlloc(allocator, std.json.Value{ .object = test_obj }, .{});
    defer allocator.free(json_str);

    const parse_start = std.time.nanoTimestamp();
    for (0..10000) |_| {
        var parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
        parsed.deinit();
    }
    const parse_time = std.time.nanoTimestamp() - parse_start;
    logger.info("  JSON parsing: {d:.2}ms (10000 operations)", .{@as(f64, @floatFromInt(parse_time)) / 1_000_000.0});
}

fn runErrorHandlingBenchmark(allocator: std.mem.Allocator, logger: *zignal.logging.Logger) !void {
    logger.info("⚠️ Testing Error Handling Performance", .{});

    var error_handler = zignal.errors.ErrorHandler.init(
        allocator,
        zignal.errors.RecoveryConfig{
            .max_retries = 3,
            .base_delay_ms = 100,
            .max_delay_ms = 1000,
            .backoff_multiplier = 2.0,
            .jitter = true,
        },
        1000,
    );
    defer error_handler.deinit();

    const start_time = std.time.nanoTimestamp();

    // Simulate many errors
    for (0..10000) |i| {
        const error_ctx = zignal.errors.ErrorContext.init(
            allocator,
            zignal.errors.ZignalError.HttpRequestFailed,
            .warning,
            try std.fmt.allocPrint(allocator, "Simulated error {d}", .{i}),
            "test.zig",
            42,
            "test_function",
        ).withRequestId(allocator, try std.fmt.allocPrint(allocator, "req_{d}", .{i}));

        error_handler.handleError(error_ctx) catch {};
        error_ctx.deinit(allocator);
    }

    const error_time = std.time.nanoTimestamp() - start_time;
    logger.info("  Error handling: {d:.2}ms (10000 errors)", .{@as(f64, @floatFromInt(error_time)) / 1_000_000.0});

    // Test circuit breaker
    const circuit_start = std.time.nanoTimestamp();
    var circuit_breaker = zignal.errors.CircuitBreaker.init(
        allocator,
        5,
        60000,
        30000,
    );
    defer circuit_breaker.deinit();

    for (0..100) |_| {
        const result = circuit_breaker.execute(struct {
            fn operation() !void {
                return error.SimulatedError;
            }
        }.operation);
        _ = result catch {};
    }
    const circuit_time = std.time.nanoTimestamp() - circuit_start;
    logger.info("  Circuit breaker: {d:.2}ms (100 operations)", .{@as(f64, @floatFromInt(circuit_time)) / 1_000_000.0});
}

fn runVoiceBenchmark(allocator: std.mem.Allocator, logger: *zignal.logging.Logger) !void {
    logger.info("🎤 Testing Voice Performance", .{});

    var voice_manager = zignal.voice.VoiceManager.init(allocator);
    defer voice_manager.deinit();

    const start_time = std.time.nanoTimestamp();

    // Simulate voice connections
    for (0..100) |i| {
        const guild_id = @as(u64, @intCast(i + 1));
        const channel_id = @as(u64, @intCast(i + 1001));
        const user_id = @as(u64, @intCast(i + 2001));

        const connection = try voice_manager.joinVoiceChannel(guild_id, channel_id, user_id);
        
        // Simulate audio processing
        const audio_data = try allocator.alloc(u8, 960 * 2 * 2); // 960 samples, 2 channels, 2 bytes per sample
        defer allocator.free(audio_data);
        
        std.crypto.random.bytes(audio_data);
        
        // Simulate RTP packet creation
        const rtp_packet = try connection.createRTPPacket(audio_data);
        allocator.free(rtp_packet);
        
        voice_manager.leaveVoiceChannel(guild_id);
    }

    const voice_time = std.time.nanoTimestamp() - start_time;
    logger.info("  Voice operations: {d:.2}ms (100 connections)", .{@as(f64, @floatFromInt(voice_time)) / 1_000_000.0});
}

fn runInteractionBenchmark(allocator: std.mem.Allocator, logger: *zignal.logging.Logger) !void {
    logger.info("🎮 Testing Interaction Performance", .{});

    var interaction_handler = zignal.interactions.InteractionHandler.init(allocator);
    defer interaction_handler.deinit();

    const start_time = std.time.nanoTimestamp();

    // Simulate interaction processing
    for (0..10000) |i| {
        const interaction = zignal.interactions.Interaction{
            .id = @intCast(i),
            .type = .application_command,
            .token = try allocator.dupe(u8, "test_token"),
            .version = 1,
            .application_id = 12345,
            .guild_id = @intCast(i + 1),
            .channel_id = @intCast(i + 1001),
            .member = null,
            .user = zignal.models.User{
                .id = @intCast(i + 2001),
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
            .data = null,
        };
        defer allocator.free(interaction.token);
        defer allocator.free(interaction.user.username);

        // Simulate interaction processing
        _ = interaction_handler.handleInteraction(interaction) catch {};
    }

    const interaction_time = std.time.nanoTimestamp() - start_time;
    logger.info("  Interaction processing: {d:.2}ms (10000 interactions)", .{@as(f64, @floatFromInt(interaction_time)) / 1_000_000.0});

    // Test builder performance
    const builder_start = std.time.nanoTimestamp();
    for (0..10000) |_| {
        const embed = zignal.builders.EmbedBuilder.init(allocator)
            .title("Test Embed")
            .description("Test description")
            .colorRgb(255, 0, 0)
            .build() catch continue;
        
        embed.deinit();
    }
    const builder_time = std.time.nanoTimestamp() - builder_start;
    logger.info("  Builder operations: {d:.2}ms (10000 builds)", .{@as(f64, @floatFromInt(builder_time)) / 1_000_000.0});
}
