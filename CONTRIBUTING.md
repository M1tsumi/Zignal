# Contributing to Zignal

Thanks for considering a contribution. This guide covers what you need to know.

## Setup

```bash
git clone https://github.com/M1tsumi/Zignal.git
cd Zignal
zig build test
```

Requirements:
- Zig 0.13.0+
- Git
- A Discord bot token (for running examples)

## Project Structure

```
src/
├── Client.zig       # REST client
├── Gateway.zig      # WebSocket connection
├── voice.zig        # Voice support
├── api/             # Discord API modules (43 total)
├── builders.zig     # Fluent builders
├── cache.zig        # Caching layer
├── errors.zig       # Error types
├── interactions.zig # Slash commands, components
├── logging.zig      # Logging utilities
└── pooling.zig      # Connection pooling
```

## Code Style

Follow Zig conventions. Use `defer` for cleanup. Handle errors explicitly.

```zig
// Good: explicit cleanup, error handling
pub fn joinVoiceChannel(
    voice_manager: *VoiceManager,
    guild_id: u64,
    channel_id: u64,
) !*VoiceConnection {
    const connection = try allocator.create(VoiceConnection);
    errdefer allocator.destroy(connection);
    
    connection.* = VoiceConnection.init(allocator, guild_id, channel_id);
    try voice_manager.connections.put(guild_id, connection);
    return connection;
}
```

## Testing

```bash
zig build test           # unit tests
zig build test-advanced  # integration tests
```

Write tests for new features. Use `GeneralPurposeAllocator` to catch leaks:

```zig
test "example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // test code here
}
```

## Pull Requests

Before submitting:

1. Run `zig build test`
2. Run `zig fmt --check src examples`
3. Update docs if needed
4. Add tests for new functionality

For larger changes, open an issue first to discuss the approach.

## Adding API Endpoints

New endpoints go in `src/api/`. Follow the existing pattern:

```zig
pub fn createGuild(
    client: *Client,
    name: []const u8,
    options: CreateGuildOptions,
) !Guild {
    const url = try std.fmt.allocPrint(client.allocator, "{s}/guilds", .{client.base_url});
    defer client.allocator.free(url);

    const response = try client.http.post(url, payload);
    defer response.deinit();

    return try std.json.parse(Guild, response.body, .{});
}
```

## Bug Reports

Include:
- Zig version
- OS
- Minimal reproduction code
- Expected vs actual behavior

## Questions

Open a GitHub issue or discussion. We're happy to help.
