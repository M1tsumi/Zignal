# 🤝 Contributing to Zignal

🎉 Thank you for your interest in contributing to Zignal! This document provides comprehensive guidelines for contributing to our enterprise-grade Discord API wrapper.

## 🚀 Quick Start

### 📋 Prerequisites
- **🔨 Zig 0.11.0** or later
- **📚 Git**
- **🤖 Discord bot token** (for testing)

### 🛠️ Setup Development Environment

```bash
# Clone the repository
git clone https://github.com/M1tsumi/Zignal.git
cd Zignal

# Initialize development environment
zig build dev  # Runs linting and tests
```

### 🧪 Run Tests

```bash
zig build test          # Basic tests
zig build test-advanced  # Advanced feature tests
zig build benchmark     # Performance benchmarks
```

## 🏗️ Architecture Overview

Zignal follows a layered architecture:

```text
┌─────────────────┐
│ 🎯 Client Layer │  (REST, Gateway, Voice)
├─────────────────┤
│ ⚡ Performance │ (Connection Pooling, Batching)
├─────────────────┤
│ 🛡️ Reliability │ (Error Handling, Circuit Breakers)
├─────────────────┤
│ 👨‍💻 Developer │ (Builders, Interactions, Logging)
├─────────────────┤
│ 💎 Core Layer   │  (Cache, Events, Models)
└─────────────────┘
```

## 🏆 Senior Software Engineering Standards

### 🧠 Code Quality Requirements

#### 1. **🛡️ Memory Safety**
   - Every allocation must have a corresponding free
   - Use `defer` for cleanup in all functions
   - Document memory ownership clearly
   - Test for memory leaks in complex scenarios

2. **Error Handling**
   - Use specific error types for different failure modes
   - Implement proper error recovery strategies
   - Include context in error messages
   - Use circuit breakers for external dependencies

3. **Performance**
   - Optimize for zero-copy operations where possible
   - Use connection pooling for HTTP requests
   - Implement request batching for API calls
   - Monitor and optimize hot paths

4. **Documentation**
   - All public APIs must have comprehensive documentation
   - Include examples for complex operations
   - Document performance characteristics
   - Provide troubleshooting guides

### Code Style Guidelines

```zig
// ✅ GOOD: Clear, documented, memory-safe
/// Joins a voice channel and establishes connection.
/// Caller must call `voice_manager.leaveVoiceChannel()` to cleanup.
pub fn joinVoiceChannel(
    voice_manager: *VoiceManager,
    guild_id: u64,
    channel_id: u64,
    user_id: u64,
) !*VoiceConnection {
    const connection = try allocator.create(VoiceConnection);
    errdefer allocator.destroy(connection);
    
    connection.* = VoiceConnection.init(allocator, guild_id, channel_id, user_id);
    errdefer connection.deinit();
    
    try voice_manager.connections.put(guild_id, connection);
    return connection;
}

// ❌ BAD: No error handling, memory leaks
pub fn joinVoiceChannel(guild_id: u64, channel_id: u64) *VoiceConnection {
    const connection = allocator.create(VoiceConnection);
    connection.* = VoiceConnection.init(guild_id, channel_id);
    return connection; // Memory leak if init fails
}
```

## 🔧 Development Workflow

### 1. Feature Development

```bash
# Create feature branch
git checkout -b feature/voice-optimization

# Make changes
# ... implement feature ...

# Run full test suite
zig build ci

# Run benchmarks
zig build benchmark

# Submit PR
git push origin feature/voice-optimization
```

### 2. Code Review Checklist

Before submitting a PR, ensure:

- [ ] All tests pass (`zig build test` and `zig build test-advanced`)
- [ ] Code is properly formatted (`zig fmt --check`)
- [ ] No new compiler warnings
- [ ] Performance benchmarks don't regress
- [ ] Documentation is updated
- [ ] Examples are provided for new features
- [ ] Memory safety is verified
- [ ] Error handling is comprehensive

### 3. Testing Requirements

#### Unit Tests
```zig
test "VoiceConnection.createRTPPacket" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var voice_manager = VoiceManager.init(allocator);
    defer voice_manager.deinit();

    const connection = try voice_manager.joinVoiceChannel(12345, 67890, 11111);
    defer voice_manager.leaveVoiceChannel(12345);

    const audio_data = try allocator.alloc(u8, 960 * 2 * 2);
    defer allocator.free(audio_data);

    const rtp_packet = try connection.createRTPPacket(audio_data);
    defer allocator.free(rtp_packet);

    try testing.expect(rtp_packet.len > 0);
    try testing.expect(rtp_packet.len <= 1500); // MTU limit
}
```

#### Integration Tests
```zig
test "Client with all features integration" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var connection_pool = ConnectionPool.init(allocator, 10, 30000);
    defer connection_pool.deinit();

    var request_batcher = RequestBatcher.init(allocator, 100, 5000);
    defer request_batcher.deinit();

    var client = try Client.init(allocator, .{
        .token = "test_token",
        .connection_pool = &connection_pool,
        .request_batcher = &request_batcher,
    });
    defer client.deinit();

    // Test integration...
}
```

#### Performance Tests
```zig
test "Connection pool performance" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var pool = ConnectionPool.init(allocator, 50, 30000);
    defer pool.deinit();

    const start_time = std.time.nanoTimestamp();
    
    // Acquire 100 connections
    for (0..100) |_| {
        const conn = try pool.acquire("https://discord.com/api/v10");
        pool.release(conn);
    }
    
    const elapsed_ms = @as(f64, @floatFromInt(std.time.nanoTimestamp() - start_time)) / 1_000_000.0;
    try testing.expect(elapsed_ms < 100.0); // Should be under 100ms
}
```

## 📦 Adding New Features

### 1. REST API Endpoints

When adding new Discord API endpoints:

```zig
// In src/api/guilds.zig
pub fn createGuild(
    client: *Client,
    name: []const u8,
    options: CreateGuildOptions,
) !Guild {
    const url = try std.fmt.allocPrint(client.allocator, "{s}/guilds", .{client.base_url});
    defer client.allocator.free(url);

    const payload = try std.json.stringifyAlloc(client.allocator, options, .{});
    defer client.allocator.free(payload);

    const response = try client.http.post(url, payload);
    defer response.deinit();

    if (response.status != 201) {
        return error.GuildCreationFailed;
    }

    return try std.json.parse(Guild, response.body, .{});
}
```

### 2. Gateway Events

```zig
// In src/gateway/events.zig
pub const GuildMemberUpdateEvent = struct {
    guild_id: u64,
    roles: []u64,
    user: User,
    nick: ?[]const u8,
    avatar: ?[]const u8,
    joined_at: []const u8,
    premium_since: ?[]const u8,
    deaf: bool,
    mute: bool,
    pending: bool,
    permissions: ?[]const u8,
};

pub fn parseGuildMemberUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildMemberUpdateEvent {
    return try std.json.parseFromSliceLeaky(GuildMemberUpdateEvent, allocator, data, .{});
}
```

### 3. Voice Features

```zig
// In src/voice/voice_connection.zig
pub fn playAudio(
    self: *VoiceConnection,
    url: []const u8,
) !void {
    const audio_data = try self.downloadAudio(url);
    defer self.allocator.free(audio_data);

    const opus_data = try self.encodeOpus(audio_data);
    defer self.allocator.free(opus_data);

    while (self.state == .playing) {
        const rtp_packet = try self.createRTPPacket(opus_data);
        defer self.allocator.free(rtp_packet);
        
        try self.sendRTPPacket(rtp_packet);
        std.time.sleep(20_000_000); // 20ms per packet
    }
}
```

## 🔍 Performance Guidelines

### 1. Memory Optimization

```zig
// ✅ GOOD: Zero-copy operations
pub fn processMessage(message: []const u8) void {
    // Process without copying
    const first_word = std.mem.splitScalar(u8, message, ' ').first();
    // ...
}

// ❌ BAD: Unnecessary copying
pub fn processMessage(message: []const u8) void {
    const message_copy = std.mem.Allocator.dupe(u8, message);
    defer allocator.free(message_copy);
    // ...
}
```

### 2. Connection Pooling

```zig
// Always use connection pooling
const connection = try client.connection_pool.acquire(endpoint_url);
defer client.connection_pool.release(connection);

const response = try connection.request(method, url, headers, body);
```

### 3. Request Batching

```zig
// Batch similar requests
try client.request_batcher.addRequest(
    "GET",
    "https://discord.com/api/v10/channels/123/messages",
    headers,
    null,
    handleMessagesResponse,
    5000,
    3,
);
```

## 🛡️ Security Considerations

### 1. Token Management

```zig
// ✅ GOOD: Secure token handling
const ClientConfig = struct {
    token: []const u8, // Must be kept secret
    // ... other config
};

// Never log tokens
logger.info("Client initialized", .{});
// Not: logger.info("Client initialized with token: {s}", .{token});
```

### 2. Input Validation

```zig
// ✅ GOOD: Validate all inputs
pub fn sendMessage(
    client: *Client,
    channel_id: u64,
    content: []const u8,
) !Message {
    if (channel_id == 0) return error.InvalidChannelId;
    if (content.len == 0) return error.EmptyContent;
    if (content.len > 2000) return error.MessageTooLong;
    
    // Validate for Discord-specific constraints
    if (containsInvalidContent(content)) return error.InvalidContent;
    
    // ... rest of implementation
}
```

### 3. Rate Limiting

```zig
// Always respect rate limits
const rate_limiter = client.getRateLimiter("channels_messages");
try rate_limiter.acquire();
defer rate_limiter.release();
```

## 📊 Performance Benchmarks

All performance changes must be benchmarked:

```bash
# Run benchmarks
zig build benchmark

# Compare with baseline
zig build benchmark-compare

# Generate performance report
zig build performance-report
```

### Performance Targets

- **Connection Pool**: <5ms acquisition time
- **Request Batching**: >1000 req/sec throughput
- **Cache Operations**: <1ms lookup time
- **Voice Latency**: <50ms average
- **Memory Usage**: <100MB for 10K guilds

## 🐛 Bug Reporting

### Bug Report Template

```markdown
## Bug Description
Brief description of the bug

## Reproduction Steps
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Zig version: 
- OS: 
- Zignal version: 
- Discord bot scope: 

## Additional Context
Logs, screenshots, etc.
```

## 📝 Documentation Standards

### 1. API Documentation

```zig
/// Creates a new guild with the specified configuration.
/// 
/// ## Parameters
/// - `client`: The Discord client instance
/// - `name`: Guild name (2-100 characters)
/// - `options`: Additional guild configuration options
/// 
/// ## Returns
/// The created Guild object
/// 
/// ## Errors
/// - `InvalidGuildName`: Name is too short or too long
/// - `RateLimited`: Too many guilds created recently
/// - `HttpRequestFailed`: Network request failed
/// 
/// ## Example
/// ```zig
/// const guild = try client.createGuild("My Server", .{
///     .region = "us_west",
///     .verification_level = .medium,
/// });
/// ```
pub fn createGuild(
    client: *Client,
    name: []const u8,
    options: CreateGuildOptions,
) !Guild;
```

### 2. Example Documentation

```zig
/// Example: Voice bot with audio processing
/// 
/// This example demonstrates:
/// - Voice gateway connection
/// - Audio encoding/decoding
/// - RTP packet handling
/// - Speaking state management
/// 
/// Run with: `zig run examples/voice_bot.zig`
```

## 🚀 Release Process

### 1. Version Bumping

```bash
# Update version in build.zig
# Update CHANGELOG.md
# Run full test suite
zig build ci

# Create release tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### 2. Release Checklist

- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Performance benchmarks meet targets
- [ ] Security audit passes
- [ ] Examples are tested
- [ ] CHANGELOG is updated
- [ ] Version is bumped

## 🤝 Community Guidelines

### 1. Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow senior engineering practices

### 2. Getting Help

- GitHub Issues for bug reports
- GitHub Discussions for questions
- Discord server for real-time help
- Documentation for reference

### 3. Contributing Types

- **Bug Fixes**: Always welcome
- **Features**: Open an issue first
- **Documentation**: Highly appreciated
- **Performance**: With benchmarks
- **Examples**: Great for community

## 📋 Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] All tests pass
- [ ] Added new tests
- [ ] Performance benchmarks run

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Examples provided (if applicable)

## Performance Impact
- [ ] No performance impact
- [ ] Improved performance
- [ ] Performance regression (with justification)

## Additional Notes
Any additional context or considerations
```

## 🎯 Success Metrics

Contributions are successful when they:

1. **Maintain Quality**: Pass all tests and code reviews
2. **Improve Performance**: Meet or exceed performance targets
3. **Enhance Features**: Provide real value to users
4. **Follow Standards**: Adhere to engineering best practices
5. **Document Well**: Clear, comprehensive documentation
6. **Test Thoroughly**: Comprehensive test coverage

## 📚 Resources

- [Zig Language Reference](https://ziglang.org/documentation/)
- [Discord API Documentation](https://discord.com/developers/docs)
- [Performance Optimization Guide](docs/PERFORMANCE.md)
- [Architecture Overview](docs/ARCHITECTURE.md)
- [API Reference](docs/API_REFERENCE.md)

---

Thank you for contributing to Zignal! Your contributions help make this library better for everyone. 🚀
