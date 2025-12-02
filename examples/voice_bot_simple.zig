const std = @import("std");
const zignal = @import("zignal");

/// Simple voice bot example - demonstrates voice connection basics
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const token = "YOUR_BOT_TOKEN";

    // Create REST client
    var client = zignal.Client.init(allocator, token);
    defer client.deinit();

    // Create gateway connection
    var gateway = try zignal.Gateway.init(allocator, token);
    defer gateway.deinit();

    // Connect to Discord
    try gateway.connect();
    std.log.info("Voice bot connected to Discord", .{});

    // Note: Full voice support requires:
    // 1. Handling VOICE_STATE_UPDATE events
    // 2. Handling VOICE_SERVER_UPDATE events  
    // 3. Establishing WebSocket connection to voice server
    // 4. Setting up UDP for audio
    //
    // See the voice.zig module for the VoiceConnection implementation.
}
