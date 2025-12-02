# Zignal API Reference

Quick reference for Zignal's main components. See the source code for complete details.

## Client

```zig
var client = zignal.Client.init(allocator, "YOUR_BOT_TOKEN");
defer client.deinit();

// Make API calls
const user = try client.getCurrentUser();
defer user.deinit();

const message = try client.createMessage(channel_id, "Hello!", null);
```

## Gateway

```zig
var gateway = try zignal.Gateway.init(allocator, "YOUR_BOT_TOKEN");
defer gateway.deinit();

try gateway.connect();
try gateway.startEventLoop(handler);
```

## Voice

```zig
var voice_manager = VoiceManager.init(allocator);
defer voice_manager.deinit();

const connection = try voice_manager.joinVoiceChannel(guild_id, channel_id, user_id);
try connection.playAudio(url);
connection.stopAudio();
```

## Builders

Fluent builders for common Discord objects:

```zig
// Embed
const embed = try EmbedBuilder.init(allocator)
    .title("Title")
    .description("Description")
    .colorRgb(255, 0, 0)
    .addField("Name", "Value", true)
    .build();

// Message
const message = try MessageBuilder.init(allocator)
    .content("Hello!")
    .addEmbed(embed)
    .build();
```

## Interactions

```zig
var handler = InteractionHandler.init(allocator);
defer handler.deinit();

// Register slash command
try handler.registerSlashCommand(.{
    .name = "ping",
    .description = "Check latency",
    .execute = handlePing,
});

// Register button handler
try handler.registerComponentHandler(.{
    .custom_id = "my_button",
    .execute = handleButton,
});
```

## Cache

```zig
var cache = Cache.init(allocator, max_items);
defer cache.deinit();

try cache.addGuild(guild);
const guild = try cache.getGuild(guild_id);
try cache.removeGuild(guild_id);
```

## Connection Pooling

```zig
var pool = ConnectionPool.init(allocator, max_connections, idle_timeout_ms);
defer pool.deinit();

const conn = try pool.acquire(url);
defer pool.release(conn);
```

## Error Handling

```zig
var error_handler = ErrorHandler.init(allocator, .{
    .max_retries = 3,
    .base_delay_ms = 1000,
    .backoff_multiplier = 2.0,
});

// Circuit breaker for unreliable operations
var breaker = CircuitBreaker.init(allocator, failure_threshold, recovery_ms);
const result = try breaker.execute(operation);
```

## Logging

```zig
var logger = Logger.init(allocator, .info);
defer logger.deinit();

logger.info("Bot started", .{});
logger.error("Failed: {s}", .{err_msg});
```

## Gateway Intents

```zig
const intents = GatewayIntents{
    .guilds = true,
    .guild_messages = true,
    .message_content = true,
    .guild_voice_states = true,
};
```

## Error Codes

| HTTP | Meaning | Action |
|------|---------|--------|
| 400 | Bad request | Fix input |
| 401 | Unauthorized | Check token |
| 403 | Forbidden | Check permissions |
| 429 | Rate limited | Back off |
| 5xx | Server error | Retry |

| Gateway | Meaning | Action |
|---------|---------|--------|
| 4000-4002 | Protocol error | Reconnect |
| 4003-4004 | Auth error | Re-authenticate |
| 4008 | Rate limited | Back off |
| 4009 | Session timeout | Reconnect |
| 4013-4014 | Intent error | Fix intents |

## Memory

Always pair allocations with cleanup:

```zig
const data = try allocator.alloc(u8, size);
defer allocator.free(data);

var obj = try SomeType.init(allocator);
defer obj.deinit();
```

Use `GeneralPurposeAllocator` in development to catch leaks.
