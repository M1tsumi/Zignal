# Zignal

<div align="center">

![Zignal Banner](assets/banner.svg)

**Discord API wrapper for Zig — fast, zero dependencies**

[![Zig Version](https://img.shields.io/badge/Zig-0.13.0+-orange.svg)](https://ziglang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Discord API](https://img.shields.io/badge/Discord%20API-v10-7289da.svg)](https://discord.com/developers/docs)

[Examples](examples/) · [API Reference](docs/API_REFERENCE.md) · [Contributing](CONTRIBUTING.md)

</div>

---

## Overview

Zignal is a Discord API wrapper written in pure Zig. No runtime dependencies, no garbage collector, just native code that starts fast and stays responsive.

```zig
const std = @import("std");
const zignal = @import("zignal");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = zignal.Client.init(allocator, "YOUR_BOT_TOKEN");
    defer client.deinit();

    var gateway = try zignal.Gateway.init(allocator, "YOUR_BOT_TOKEN");
    defer gateway.deinit();

    try gateway.connect();
    std.log.info("Connected to Discord", .{});
}
```

---

## Installation

Add to your `build.zig.zon`:

```zig
.dependencies = .{
    .zignal = .{
        .url = "https://github.com/M1tsumi/Zignal/archive/refs/tags/v1.0.0.tar.gz",
        .hash = "7660f560466d98f7eeceee269b919c7bff8368e1141794f168e8a88ea2709f55",
    },
},
```

Then in `build.zig`:

```zig
const zignal = b.dependency("zignal", .{});
exe.root_module.addImport("zignal", zignal.module("zignal"));
```

Requires Zig 0.13.0 or later.

---

## What's Included

**REST API** — Full coverage of Discord's v10 API across 43 modules: channels, guilds, messages, users, webhooks, application commands, moderation, and more.

**Gateway** — WebSocket connection with automatic heartbeat, event dispatch, and reconnection handling.

**Voice** — Connect to voice channels, send audio over UDP with Opus encoding and XSalsa20-Poly1305 encryption.

**Interactions** — Slash commands, buttons, select menus, modals, and autocomplete.

**Extras** — Guild analytics, backup/restore, permission management, monetization support.

---

## Examples

The `examples/` directory has working bots:

| File | Description |
|------|-------------|
| `basic_bot.zig` | Responds to simple commands |
| `rest_api.zig` | REST API usage patterns |

Run an example:

```bash
zig build run-basic-bot
```

Additional examples in the directory demonstrate voice, interactions, and production patterns but may need updates for your use case.

---

## Building

```bash
git clone https://github.com/M1tsumi/Zignal.git
cd Zignal
zig build test      # run tests
zig build examples  # build all examples
```

Cross-compile for other platforms:

```bash
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseFast
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseFast
```

---

## Memory Management

Zignal uses Zig's explicit allocator pattern. You're responsible for freeing what you allocate:

```zig
const user = try client.getCurrentUser();
defer user.deinit();
```

Use `GeneralPurposeAllocator` during development to catch leaks.

---

## Deployment

**Docker:**

```dockerfile
FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY your-bot /usr/local/bin/bot
USER 1000:1000
CMD ["/usr/local/bin/bot"]
```

**Systemd:**

```ini
[Unit]
Description=Discord Bot
After=network.target

[Service]
Type=simple
User=discord-bot
ExecStart=/usr/local/bin/bot
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

---

## Status

The library is functional and under active development. Core features work, the build passes, and the examples run.

Current work:
- Improving test coverage
- Polishing the example code
- Documentation updates

---

## Contributing

PRs welcome. For larger changes, open an issue first to discuss.

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

MIT — see [LICENSE](LICENSE)