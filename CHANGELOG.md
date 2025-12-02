# Changelog

All notable changes to Zignal are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] - 2025-11-26

First public release.

### Added

**REST API**
- Full Discord API v10 coverage across 43 modules
- Channels, guilds, messages, users, webhooks
- Application commands and interactions
- Audit logs, moderation, auto-mod
- Emojis, stickers, scheduled events
- OAuth2 authentication flow

**Gateway**
- WebSocket connection with heartbeat
- Event dispatch for all Discord events
- Automatic reconnection handling
- Sharding support

**Voice**
- Voice gateway connection
- UDP audio transport
- Opus encoding
- XSalsa20-Poly1305 encryption
- RTP packet handling

**Interactions**
- Slash commands
- Buttons, select menus, modals
- Autocomplete handlers
- Context menu commands

**Advanced Features**
- Guild analytics and metrics
- Backup and restore system
- Permission management utilities
- Monetization and entitlements
- Connection pooling
- Request batching
- Circuit breaker error handling

**Developer Tools**
- Fluent builders for messages, embeds, channels
- Structured logging with multiple outputs
- Performance monitoring
- Cache system for guilds, channels, users

### Notes

- Requires Zig 0.13.0 or later
- Uses explicit allocator pattern throughout
- All API operations return Zig error unions

### Known Issues

None at release. Please report bugs via GitHub Issues.

---
## [1.1.0] - 2025-12-02

### Changed

- Rewrote README, CHANGELOG, CONTRIBUTING, and API_REFERENCE with a more natural, concise tone
- Fixed several build issues in core modules (client, cache, pooling, interactions, logging, voice)
- Limited default `zig build examples` to known-working examples (`basic_bot.zig`, `rest_api.zig`)
- Marked advanced examples as work-in-progress in README

## [1.1.1] - 2025-12-02

### Fixed

- Fixed compilation errors in Client_core.zig (removed invalid default_port)
- Fixed cache.zig references to non-existent model fields
- Fixed pooling.zig const pointer issue with PendingRequest.deinit
- Fixed logging.zig iterator type mismatch in Metrics.deinit
- Fixed interactions.zig iterator type mismatch and made options field const
- Fixed voice.zig UdpSocket compatibility with Zig 0.13.0

### Changed

- Updated zig.zon version to 1.1.1

### Planned

- Plugin system
- Improved caching strategies
- Additional deployment examples
- Performance optimizations
- Extended platform support
