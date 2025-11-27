# Zignal API Reference

## Table of Contents

- [Core Client](#core-client)
- [Connection Pooling](#connection-pooling)
- [Request Batching](#request-batching)
- [Error Handling](#error-handling)
- [Logging System](#logging-system)
- [Voice Features](#voice-features)
- [Interaction System](#interaction-system)
- [Fluent Builders](#fluent-builders)
- [Cache System](#cache-system)
- [Performance Monitoring](#performance-monitoring)

---

## Core Client

### Client Configuration

```zig
const ClientConfig = struct {
    token: []const u8,
    intents: GatewayIntents,
    connection_pool: ?*ConnectionPool = null,
    request_batcher: ?*RequestBatcher = null,
    error_handler: ?*ErrorHandler = null,
    logger: ?*Logger = null,
};
```

### Initialization

```zig
var client = try Client.init(allocator, .{
    .token = "YOUR_BOT_TOKEN",
    .intents = .{
        .guilds = true,
        .guild_messages = true,
        .voice_states = true,
    },
    .connection_pool = &connection_pool,
    .request_batcher = &request_batcher,
    .error_handler = &error_handler,
    .logger = logger,
});
defer client.deinit();
```

### Event Registration

```zig
client.on(.ready, onReady);
client.on(.message_create, onMessage);
client.on(.interaction_create, onInteraction);
client.on(.voice_state_update, onVoiceStateUpdate);
```

### Connection Management

```zig
try client.connect();
try client.disconnect();
try client.reconnect();
```

---

## Connection Pooling

### ConnectionPool Configuration

```zig
var connection_pool = ConnectionPool.init(allocator, max_connections, max_idle_time_ms);
defer connection_pool.deinit();
```

**Parameters:**
- `allocator`: Memory allocator
- `max_connections`: Maximum number of connections in pool
- `max_idle_time_ms`: Maximum time a connection can be idle before cleanup

### Connection Acquisition

```zig
const connection = try connection_pool.acquire(endpoint_url);
defer connection_pool.release(connection);
```

**Returns:** `*PooledConnection` or `error.PoolExhausted`

### Connection Statistics

```zig
const stats = connection_pool.getStats();
// stats.total_connections
// stats.active_connections
// stats.idle_connections
// stats.connection_utilization
```

---

## Request Batching

### RequestBatcher Configuration

```zig
var request_batcher = RequestBatcher.init(allocator, max_batch_size, max_wait_time_ms);
defer request_batcher.deinit();
```

**Parameters:**
- `allocator`: Memory allocator
- `max_batch_size`: Maximum requests per batch
- `max_wait_time_ms`: Maximum time to wait before processing batch

### Adding Requests

```zig
try request_batcher.addRequest(
    method,
    url,
    headers,
    body,
    callback,
    timeout_ms,
    max_retries,
);
```

**Parameters:**
- `method`: HTTP method ("GET", "POST", etc.)
- `url`: Request URL
- `headers`: JSON object map of headers
- `body`: Optional request body
- `callback`: Function to handle batch result
- `timeout_ms`: Request timeout in milliseconds
- `max_retries`: Maximum retry attempts

### Batch Processing

```zig
try request_batcher.processBatch();
request_batcher.processTimeouts();
```

### Custom Batch Handlers

```zig
try request_batcher.addBatchHandler(
    endpoint_pattern,
    batch_processor,
    max_batch_size,
    priority,
);
```

---

## Error Handling

### Error Types

```zig
pub const ZignalError = enum {
    HttpRequestFailed,
    HttpTimeout,
    RateLimited,
    InvalidToken,
    InvalidPayload,
    GatewayDisconnected,
    VoiceConnectionFailed,
    CacheError,
    ValidationError,
    SystemError,
};
```

### Error Severity Levels

```zig
pub const ErrorSeverity = enum {
    trace,
    debug,
    info,
    warning,
    error,
    critical,
    fatal,
};
```

### Error Context

```zig
const error_ctx = ErrorContext.init(
    allocator,
    error_code,
    severity,
    message,
    file,
    line,
    function,
).withGuildId(guild_id)
 .withChannelId(channel_id)
 .withUserId(user_id)
 .withRequestId(request_id);
```

### Error Handler Configuration

```zig
var error_handler = ErrorHandler.init(
    allocator,
    RecoveryConfig{
        .max_retries = 3,
        .base_delay_ms = 1000,
        .max_delay_ms = 30000,
        .backoff_multiplier = 2.0,
        .jitter = true,
    },
    max_error_history,
);
```

### Circuit Breaker

```zig
var circuit_breaker = CircuitBreaker.init(
    allocator,
    failure_threshold,
    recovery_timeout_ms,
    expected_response_time_ms,
);
defer circuit_breaker.deinit();

const result = try circuit_breaker.execute(risky_operation);
```

---

## Logging System

### Logger Configuration

```zig
var logger = Logger.init(allocator, log_level);
defer logger.deinit();
```

**Log Levels:**
- `trace`: Most verbose
- `debug`: Debug information
- `info`: General information
- `warning`: Warning messages
- `error`: Error messages
- `critical`: Critical errors
- `fatal`: Fatal errors

### Log Handlers

```zig
try logger.addHandler(.{
    .level = .info,
    .formatter = jsonFormatter,
    .output = fileOutput,
});
```

### Context Management

```zig
try logger.addContext("guild_id", std.json.Value{ .integer = guild_id });
try logger.addContext("user_id", std.json.Value{ .integer = user_id });
logger.removeContext("guild_id");
```

### Metrics Collection

```zig
const metrics = logger.getMetrics();

// Counters
const counter = try metrics.counter("requests_total");
counter.inc();
counter.add(5);

// Gauges
const gauge = try metrics.gauge("memory_usage");
gauge.set(1024.0);

// Histograms
const histogram = try metrics.histogram("response_time", &[_]f64{ 1.0, 5.0, 10.0 });
histogram.observe(3.5);

// Timers
const timer = try metrics.timer("operation_duration");
timer.start();
// ... operation ...
timer.stop();
```

---

## Voice Features

### Voice Manager

```zig
var voice_manager = VoiceManager.init(allocator);
defer voice_manager.deinit();
```

### Voice Connection

```zig
const connection = try voice_manager.joinVoiceChannel(
    guild_id,
    channel_id,
    user_id,
);
```

### Audio Operations

```zig
// Play audio from URL
try connection.playAudio(url);

// Stop audio
connection.stopAudio();

// Pause/Resume audio
connection.pauseAudio();
connection.resumeAudio();

// Set speaking state
connection.setSpeaking(true);
```

### RTP Packet Handling

```zig
const audio_data = try allocator.alloc(u8, 960 * 2 * 2);
defer allocator.free(audio_data);

const rtp_packet = try connection.createRTPPacket(audio_data);
defer allocator.free(rtp_packet);

try connection.sendRTPPacket(rtp_packet);
```

### Voice Events

```zig
connection.on(.speaking_start, onSpeakingStart);
connection.on(.speaking_stop, onSpeakingStop);
connection.on(.audio_received, onAudioReceived);
```

### Voice Statistics

```zig
const stats = connection.getStats();
// stats.packets_sent
// stats.packets_received
// stats.bytes_sent
// stats.bytes_received
// stats.latency_ms
```

---

## Interaction System

### Interaction Handler

```zig
var interaction_handler = InteractionHandler.init(allocator);
defer interaction_handler.deinit();
```

### Slash Commands

```zig
const command_handler = try allocator.create(SlashCommandHandler);
command_handler.* = .{
    .name = "ping",
    .description = "Check bot latency",
    .options = &[_]ApplicationCommandOption{},
    .execute = handlePingCommand,
};

try interaction_handler.registerSlashCommand(command_handler);
```

### Component Handlers

```zig
const button_handler = try allocator.create(ComponentHandler);
button_handler.* = .{
    .custom_id = "confirm_button",
    .execute = handleConfirmButton,
};

try interaction_handler.registerComponentHandler(button_handler);
```

### Modal Handlers

```zig
const modal_handler = try allocator.create(ModalHandler);
modal_handler.* = .{
    .custom_id = "feedback_form",
    .execute = handleFeedbackForm,
};

try interaction_handler.registerModalHandler(modal_handler);
```

### Autocomplete Handlers

```zig
const autocomplete_handler = try allocator.create(AutocompleteHandler);
autocomplete_handler.* = .{
    .command_name = "search",
    .option_name = "query",
    .execute = handleSearchAutocomplete,
};

try interaction_handler.registerAutocompleteHandler(autocomplete_handler);
```

### Interaction Responses

```zig
// Message response
const response = InteractionResponse{
    .type = .channel_message_with_source,
    .data = .{
        .content = "Hello, World!",
        .embeds = &[_]Embed{},
        .components = components,
    },
};

// Modal response
const modal_response = InteractionResponse{
    .type = .modal,
    .data = .{
        .custom_id = "form_id",
        .title = "Form Title",
        .components = modal_components,
    },
};
```

---

## Fluent Builders

### Message Builder

```zig
const message = try MessageBuilder.init(allocator)
    .content("Hello, World!")
    .addEmbed(embed)
    .addFile("data.txt", file_content)
    .addMention(user_id)
    .setTTS(false)
    .reply(original_message_id)
    .build();
```

### Embed Builder

```zig
const embed = try EmbedBuilder.init(allocator)
    .title("Embed Title")
    .description("Embed description")
    .colorRgb(255, 0, 0)
    .addField("Field 1", "Value 1", true)
    .addField("Field 2", "Value 2", false)
    .setThumbnail(thumbnail_url)
    .setImage(image_url)
    .setFooter("Footer text")
    .setTimestamp()
    .build();
```

### Channel Builder

```zig
const channel_create = try ChannelBuilder.init(allocator)
    .name("new-channel")
    .type(.text)
    .topic("Channel topic")
    .setNSFW(false)
    .setRateLimitPerUser(5)
    .setParentId(category_id)
    .build();
```

### Role Builder

```zig
const role_create = try RoleBuilder.init(allocator)
    .name("new-role")
    .colorRgb(255, 0, 255)
    .hoist(true)
    .mentionable(false)
    .setPermissions(permissions)
    .build();
```

---

## Cache System

### Cache Configuration

```zig
var cache = Cache.init(allocator, max_items);
defer cache.deinit();
```

### Guild Operations

```zig
// Add guild
try cache.addGuild(guild);

// Get guild
const guild = try cache.getGuild(guild_id);

// Remove guild
try cache.removeGuild(guild_id);

// Get all guilds
const guilds = cache.getAllGuilds();
```

### Channel Operations

```zig
// Add channel
try cache.addChannel(channel);

// Get channel
const channel = try cache.getChannel(channel_id);

// Get guild channels
const channels = try cache.getGuildChannels(guild_id);
```

### User Operations

```zig
// Add user
try cache.addUser(user);

// Get user
const user = try cache.getUser(user_id);

// Get guild members
const members = try cache.getGuildMembers(guild_id);
```

### Message Operations

```zig
// Add message
try cache.addMessage(message);

// Get message
const message = try cache.getMessage(message_id);

// Get channel messages
const messages = try cache.getChannelMessages(channel_id, limit);
```

### Cache Statistics

```zig
const stats = cache.getStats();
// stats.total_items
// stats.memory_usage_mb
// stats.hit_rate
// stats.guilds_count
// stats.channels_count
// stats.users_count
// stats.messages_count
```

---

## Performance Monitoring

### Performance Monitor

```zig
var monitor = PerformanceMonitor.init(
    allocator,
    &connection_pool,
    &request_batcher,
    logger,
);
defer monitor.deinit();
```

### Rate Limiters

```zig
try monitor.addRateLimiter(RateLimiter.init(
    allocator,
    capacity,
    refill_rate,
));
```

### Performance Metrics

```zig
const metrics = monitor.getMetrics();
// metrics.total_requests
// metrics.successful_requests
// metrics.failed_requests
// metrics.average_response_time_ms
// metrics.requests_per_second
// metrics.connection_reuse_rate
// metrics.batch_efficiency
```

### Health Monitoring

```zig
var health_monitor = Monitor.init(
    allocator,
    logger,
    MonitorConfig{
        .health_check_interval_ms = 30000,
        .alert_cooldown_ms = 300000,
        .max_alerts_per_hour = 100,
    },
);
defer health_monitor.deinit();

// Add health check
try health_monitor.addHealthCheck(
    "database",
    checkDatabaseHealth,
    60000,
);

// Create alert
try health_monitor.createAlert(
    .error,
    "Database Connection Failed",
    "Unable to connect to database",
    "database_monitor",
);
```

### Performance Reports

```zig
const report = try monitor.generateReport();
defer allocator.free(report);
```

---

## Type Definitions

### Gateway Intents

```zig
pub const GatewayIntents = struct {
    guilds: bool = false,
    guild_members: bool = false,
    guild_bans: bool = false,
    guild_emojis: bool = false,
    guild_integrations: bool = false,
    guild_webhooks: bool = false,
    guild_invites: bool = false,
    guild_voice_states: bool = false,
    guild_presences: bool = false,
    guild_messages: bool = false,
    guild_message_reactions: bool = false,
    guild_message_typing: bool = false,
    direct_messages: bool = false,
    direct_message_reactions: bool = false,
    direct_message_typing: bool = false,
    message_content: bool = false,
    guild_scheduled_events: bool = false,
    auto_moderation_configuration: bool = false,
    auto_moderation_execution: bool = false,
};
```

### Permission Flags

```zig
pub const PermissionFlags = struct {
    create_instant_invite: bool = false,
    kick_members: bool = false,
    ban_members: bool = false,
    administrator: bool = false,
    manage_channels: bool = false,
    manage_guild: bool = false,
    add_reactions: bool = false,
    view_audit_log: bool = false,
    priority_speaker: bool = false,
    stream: bool = false,
    view_channel_insights: bool = false,
    connect: bool = false,
    speak: bool = false,
    mute_members: bool = false,
    deafen_members: bool = false,
    move_members: bool = false,
    use_vad: bool = false,
    change_nickname: bool = false,
    manage_nicknames: bool = false,
    manage_roles: bool = false,
    manage_webhooks: bool = false,
    manage_guild_expressions: bool = false,
    use_application_commands: bool = false,
    request_to_speak: bool = false,
    manage_events: bool = false,
    manage_threads: bool = false,
    create_public_threads: bool = false,
    create_private_threads: bool = false,
    use_external_stickers: bool = false,
    send_messages_in_threads: bool = false,
    use_embedded_activities: bool = false,
    moderate_members: bool = false,
    view_creator_monetization_analytics: bool = false,
    use_soundboard: bool = false,
    send_voice_messages: bool = false,
};
```

---

## Error Codes Reference

### HTTP Errors

| Error Code | Description | Recovery Strategy |
|------------|-------------|-------------------|
| 400 | Bad Request | Validate input, retry with corrected data |
| 401 | Unauthorized | Refresh token, retry |
| 403 | Forbidden | Check permissions, retry |
| 429 | Rate Limited | Exponential backoff with jitter |
| 500 | Internal Server Error | Retry with circuit breaker |
| 502 | Bad Gateway | Retry with exponential backoff |
| 503 | Service Unavailable | Retry with circuit breaker |

### Gateway Errors

| Error Code | Description | Recovery Strategy |
|------------|-------------|-------------------|
| 4000 | Unknown Error | Restart connection |
| 4001 | Unknown Opcode | Reconnect |
| 4002 | Decode Error | Reconnect |
| 4003 | Not Authenticated | Reauthenticate |
| 4004 | Authentication Failed | Reauthenticate |
| 4005 | Already Authenticated | Reconnect |
| 4007 | Invalid Seq | Reconnect |
| 4008 | Rate Limited | Exponential backoff |
| 4009 | Session Timed Out | Reconnect |
| 4010 | Invalid Shard | Reconnect with correct shard |
| 4011 | Sharding Required | Implement sharding |
| 4012 | Invalid API Version | Update library |
| 4013 | Invalid Intents | Correct intents |
| 4014 | Disallowed Intents | Remove disallowed intents |

---

## Performance Guidelines

### Memory Management

1. **Always free allocated memory**
   ```zig
   const data = try allocator.alloc(u8, size);
   defer allocator.free(data);
   ```

2. **Use deinit() methods for complex objects**
   ```zig
   var cache = Cache.init(allocator, 1000);
   defer cache.deinit();
   ```

3. **Prefer stack allocation for small objects**
   ```zig
   var small_buffer: [1024]u8 = undefined;
   ```

### Performance Optimization

1. **Use connection pooling**
   ```zig
   client.connection_pool = try ConnectionPool.init(allocator, 20, 30000);
   ```

2. **Enable request batching**
   ```zig
   client.request_batcher = try RequestBatcher.init(allocator, 100, 5000);
   ```

3. **Configure appropriate cache sizes**
   ```zig
   cache.setLimits(.{
       .max_guilds = 1000,
       .max_channels = 10000,
       .max_users = 50000,
   });
   ```

### Error Handling Best Practices

1. **Use specific error types**
   ```zig
   const result = try client.getChannel(channel_id) catch |err| switch (err) {
       error.HttpRequestFailed => return error.ChannelNotFound,
       error.RateLimited => return error.TemporarilyUnavailable,
       else => return err,
   };
   ```

2. **Implement circuit breakers for external services**
   ```zig
   const result = try circuit_breaker.execute(externalApiCall);
   ```

3. **Log errors with context**
   ```zig
   logger.error("Failed to process message: {s}", .{error_message});
   ```

---

## Migration Guide

### From Basic to Advanced

1. **Enable Connection Pooling**
   ```zig
   // Before
   var client = try Client.init(allocator, .{ .token = token });

   // After
   var connection_pool = try ConnectionPool.init(allocator, 20, 30000);
   var client = try Client.init(allocator, .{
       .token = token,
       .connection_pool = &connection_pool,
   });
   ```

2. **Add Error Handling**
   ```zig
   // Before
   const guild = try client.getGuild(guild_id);

   // After
   var error_handler = try ErrorHandler.init(allocator, config);
   var client = try Client.init(allocator, .{
       .token = token,
       .error_handler = &error_handler,
   });
   const guild = try client.getGuild(guild_id) catch |err| {
       error_handler.handleError(err) catch {};
       return err;
   };
   ```

3. **Enable Performance Monitoring**
   ```zig
   var monitor = try PerformanceMonitor.init(allocator, &pool, &batcher, logger);
   try monitor.addRateLimiter(RateLimiter.init(allocator, 1000, 100.0));
   ```

---

## Troubleshooting

### Common Issues

1. **Memory Leaks**
   - Ensure all allocated memory is freed
   - Use `defer` for cleanup
   - Check for circular references

2. **Performance Issues**
   - Enable connection pooling
   - Use request batching
   - Monitor metrics regularly

3. **Connection Problems**
   - Check rate limits
   - Implement circuit breakers
   - Use proper error recovery

4. **Voice Issues**
   - Check UDP port availability
   - Verify encryption keys
   - Monitor audio latency

### Debug Tools

1. **Performance Profiling**
   ```zig
   const report = try monitor.generateReport();
   std.log.info("Performance Report:\n{s}", .{report});
   ```

2. **Memory Debugging**
   ```zig
   var gpa = std.heap.GeneralPurposeAllocator(.{}){};
   defer _ = gpa.deinit();
   const allocator = gpa.allocator();
   ```

3. **Error Analysis**
   ```zig
   const stats = error_handler.getStats();
   std.log.info("Error Statistics: {}", .{stats});
   ```

---

This API reference provides comprehensive documentation for all advanced features of the Zignal Discord API wrapper. Each section includes practical examples and best practices for production use.
