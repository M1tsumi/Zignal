const std = @import("std");
const zignal = @import("zignal");

/// Comprehensive Discord bot demonstrating full API coverage
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

    // Create client with full intents
    var client = try zignal.Client.init(allocator, .{
        .token = "YOUR_BOT_TOKEN",
        .intents = .{
            .guilds = true,
            .guild_messages = true,
            .guild_members = true,
            .guild_bans = true,
            .guild_emojis = true,
            .guild_integrations = true,
            .guild_webhooks = true,
            .guild_invites = true,
            .guild_voice_states = true,
            .guild_presences = true,
            .guild_message_reactions = true,
            .guild_message_typing = true,
            .message_content = true,
            .direct_messages = true,
            .direct_message_reactions = true,
            .direct_message_typing = true,
            .guild_scheduled_events = true,
            .auto_moderation_configuration = true,
            .auto_moderation_execution = true,
        },
        .connection_pool = &connection_pool,
        .request_batcher = &request_batcher,
        .error_handler = &error_handler,
        .logger = logger,
    });
    defer client.deinit();

    // Initialize all API managers
    var audit_log_manager = zignal.audit_logs.AuditLogManager.init(&client, allocator);
    var emoji_manager = zignal.emoji.EmojiManager.init(&client, allocator);
    var stage_manager = zignal.stage_instances.StageInstanceManager.init(&client, allocator);
    var auto_mod_manager = zignal.auto_moderation.AutoModerationManager.init(&client, allocator);
    var integration_manager = zignal.integrations.IntegrationManager.init(&client, allocator);
    var invite_manager = zignal.invites.InviteManager.init(&client, allocator);
    var sticker_manager = zignal.stickers.StickerManager.init(&client, allocator);
    var app_command_manager = zignal.application_commands.ApplicationCommandManager.init(&client, allocator);

    // Initialize event trackers
    var voice_tracker = zignal.voice_events.VoiceChannelTracker.init(allocator);
    defer voice_tracker.deinit();

    var typing_tracker = zignal.typing_events.TypingTracker.init(allocator);
    defer typing_tracker.deinit();

    // Register comprehensive event handlers
    setupEventHandlers(&client, &voice_tracker, &typing_tracker);

    // Register all slash commands
    try setupComprehensiveSlashCommands(&client, &app_command_manager, allocator);

    // Connect to Discord
    try client.connect();
    logger.info("Comprehensive API demo bot connected successfully", .{});

    // Demonstrate all API functionality
    try demonstrateAllAPIs(
        &audit_log_manager,
        &emoji_manager,
        &stage_manager,
        &auto_mod_manager,
        &integration_manager,
        &invite_manager,
        &sticker_manager,
        &app_command_manager,
        1234567890123456789,
        allocator,
    );

    // Keep the bot running
    logger.info("Comprehensive API demo bot is now running. Press Ctrl+C to stop.", .{});
    while (true) {
        // Cleanup expired typing states
        typing_tracker.cleanupExpired();
        
        // Update performance metrics
        monitor.updateMetrics();
        
        std.time.sleep(1_000_000_000); // Sleep for 1 second
    }
}

fn setupEventHandlers(
    client: *zignal.Client,
    voice_tracker: *zignal.voice_events.VoiceChannelTracker,
    typing_tracker: *zignal.typing_events.TypingTracker,
) void {
    const logger = zignal.logging.getGlobalLogger().?;

    // Guild events
    client.on(.guild_create, onGuildCreate);
    client.on(.guild_update, onGuildUpdate);
    client.on(.guild_delete, onGuildDelete);
    client.on(.guild_ban_add, onGuildBanAdd);
    client.on(.guild_ban_remove, onGuildBanRemove);
    client.on(.guild_member_add, onGuildMemberAdd);
    client.on(.guild_member_remove, onGuildMemberRemove);
    client.on(.guild_member_update, onGuildMemberUpdate);
    client.on(.guild_role_create, onGuildRoleCreate);
    client.on(.guild_role_update, onGuildRoleUpdate);
    client.on(.guild_role_delete, onGuildRoleDelete);
    client.on(.guild_emojis_update, onGuildEmojisUpdate);
    client.on(.guild_stickers_update, onGuildStickersUpdate);
    client.on(.guild_integrations_update, onGuildIntegrationsUpdate);

    // Message events
    client.on(.message_create, onMessageCreate);
    client.on(.message_update, onMessageUpdate);
    client.on(.message_delete, onMessageDelete);
    client.on(.message_bulk_delete, onMessageBulkDelete);
    client.on(.message_reaction_add, onMessageReactionAdd);
    client.on(.message_reaction_remove, onMessageReactionRemove);
    client.on(.message_reaction_remove_all, onMessageReactionRemoveAll);

    // Presence events
    client.on(.presence_update, onPresenceUpdate);

    // Typing events
    client.on(.typing_start, onTypingStart);

    // Voice events
    client.on(.voice_state_update, onVoiceStateUpdate);
    client.on(.voice_server_update, onVoiceServerUpdate);

    // Interaction events
    client.on(.interaction_create, onInteractionCreate);
}

fn setupComprehensiveSlashCommands(
    client: *zignal.Client,
    app_command_manager: *zignal.application_commands.ApplicationCommandManager,
    allocator: std.mem.Allocator,
) !void {
    // Guild management commands
    const audit_command = try createAuditCommand(allocator);
    const emoji_command = try createEmojiCommand(allocator);
    const invite_command = try createInviteCommand(allocator);
    const sticker_command = try createStickerCommand(allocator);
    const integration_command = try createIntegrationCommand(allocator);
    const auto_mod_command = try createAutoModCommand(allocator);
    const stage_command = try createStageCommand(allocator);
    const app_command_mgmt = try createAppCommandMgmtCommand(allocator);

    // Register all commands globally
    const commands = [_]zignal.models.ApplicationCommand{
        audit_command,
        emoji_command,
        invite_command,
        sticker_command,
        integration_command,
        auto_mod_command,
        stage_command,
        app_command_mgmt,
    };

    const registered_commands = try app_command_manager.bulkOverwriteGlobalApplicationCommands(&commands);
    defer allocator.free(registered_commands);

    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Registered {d} global slash commands", .{commands.len});
}

fn createAuditCommand(allocator: std.mem.Allocator) !zignal.models.ApplicationCommand {
    return zignal.models.ApplicationCommand{
        .name = "audit",
        .description = "View and manage audit logs",
        .options = &[_]zignal.models.ApplicationCommandOption{
            .{
                .name = "action",
                .description = "Filter by action type",
                .type = .string,
                .required = false,
                .choices = &[_]zignal.models.ApplicationCommandOption.Choice{
                    .{ .name = "Member Ban", .value = "22" },
                    .{ .name = "Member Kick", .value = "20" },
                    .{ .name = "Message Delete", .value = "72" },
                    .{ .name = "Channel Create", .value = "10" },
                    .{ .name = "Role Create", .value = "30" },
                    .{ .name = "Emoji Create", .value = "60" },
                    .{ .name = "Sticker Create", .value = "90" },
                    .{ .name = "Integration Create", .value = "80" },
                },
            },
            .{
                .name = "limit",
                .description = "Number of entries to show",
                .type = .integer,
                .required = false,
                .min_value = 1,
                .max_value = 50,
            },
        },
    };
}

fn createEmojiCommand(allocator: std.mem.Allocator) !zignal.models.ApplicationCommand {
    return zignal.models.ApplicationCommand{
        .name = "emoji",
        .description = "Manage server emojis",
        .options = &[_]zignal.models.ApplicationCommandOption{
            .{
                .name = "action",
                .description = "Action to perform",
                .type = .string,
                .required = true,
                .choices = &[_]zignal.models.ApplicationCommandOption.Choice{
                    .{ .name = "List", .value = "list" },
                    .{ .name = "Create", .value = "create" },
                    .{ .name = "Delete", .value = "delete" },
                    .{ .name = "Info", .value = "info" },
                },
            },
            .{
                .name = "name",
                .description = "Emoji name",
                .type = .string,
                .required = false,
            },
            .{
                .name = "image",
                .description = "Emoji image URL",
                .type = .string,
                .required = false,
            },
        },
    };
}

fn createInviteCommand(allocator: std.mem.Allocator) !zignal.models.ApplicationCommand {
    return zignal.models.ApplicationCommand{
        .name = "invite",
        .description = "Manage server invites",
        .options = &[_]zignal.models.ApplicationCommandOption{
            .{
                .name = "action",
                .description = "Action to perform",
                .type = .string,
                .required = true,
                .choices = &[_]zignal.models.ApplicationCommandOption.Choice{
                    .{ .name = "List", .value = "list" },
                    .{ .name = "Create", .value = "create" },
                    .{ .name = "Delete", .value = "delete" },
                    .{ .name = "Info", .value = "info" },
                },
            },
            .{
                .name = "max_uses",
                .description = "Maximum uses",
                .type = .integer,
                .required = false,
                .min_value = 1,
                .max_value = 100,
            },
            .{
                .name = "duration",
                .description = "Duration in hours",
                .type = .integer,
                .required = false,
                .min_value = 1,
                .max_value = 168, // 1 week
            },
        },
    };
}

fn createStickerCommand(allocator: std.mem.Allocator) !zignal.models.ApplicationCommand {
    return zignal.models.ApplicationCommand{
        .name = "sticker",
        .description = "Manage server stickers",
        .options = &[_]zignal.models.ApplicationCommandOption{
            .{
                .name = "action",
                .description = "Action to perform",
                .type = .string,
                .required = true,
                .choices = &[_]zignal.models.ApplicationCommandOption.Choice{
                    .{ .name = "List", .value = "list" },
                    .{ .name = "Create", .value = "create" },
                    .{ .name = "Delete", .value = "delete" },
                    .{ .name = "Info", .value = "info" },
                },
            },
            .{
                .name = "name",
                .description = "Sticker name",
                .type = .string,
                .required = false,
            },
            .{
                .name = "description",
                .description = "Sticker description",
                .type = .string,
                .required = false,
            },
            .{
                .name = "tags",
                .description = "Sticker tags",
                .type = .string,
                .required = false,
            },
        },
    };
}

fn createIntegrationCommand(allocator: std.mem.Allocator) !zignal.models.ApplicationCommand {
    return zignal.models.ApplicationCommand{
        .name = "integration",
        .description = "Manage server integrations",
        .options = &[_]zignal.models.ApplicationCommandOption{
            .{
                .name = "action",
                .description = "Action to perform",
                .type = .string,
                .required = true,
                .choices = &[_]zignal.models.ApplicationCommandOption.Choice{
                    .{ .name = "List", .value = "list" },
                    .{ .name = "Create", .value = "create" },
                    .{ .name = "Delete", .value = "delete" },
                    .{ .name = "Sync", .value = "sync" },
                },
            },
            .{
                .name = "integration_type",
                .description = "Integration type",
                .type = .string,
                .required = false,
                .choices = &[_]zignal.models.ApplicationCommandOption.Choice{
                    .{ .name = "Twitch", .value = "twitch" },
                    .{ .name = "YouTube", .value = "youtube" },
                    .{ .name = "Reddit", .value = "reddit" },
                    .{ .name = "Twitter", .value = "twitter" },
                },
            },
        },
    };
}

fn createAutoModCommand(allocator: std.mem.Allocator) !zignal.models.ApplicationCommand {
    return zignal.models.ApplicationCommand{
        .name = "automod",
        .description = "Manage auto moderation rules",
        .options = &[_]zignal.models.ApplicationCommandOption{
            .{
                .name = "action",
                .description = "Action to perform",
                .type = .string,
                .required = true,
                .choices = &[_]zignal.models.ApplicationCommandOption.Choice{
                    .{ .name = "List Rules", .value = "list" },
                    .{ .name = "Create Rule", .value = "create" },
                    .{ .name = "Delete Rule", .value = "delete" },
                    .{ .name = "Enable Rule", .value = "enable" },
                    .{ .name = "Disable Rule", .value = "disable" },
                },
            },
            .{
                .name = "rule_name",
                .description = "Rule name",
                .type = .string,
                .required = false,
            },
            .{
                .name = "trigger_type",
                .description = "Trigger type",
                .type = .string,
                .required = false,
                .choices = &[_]zignal.models.ApplicationCommandOption.Choice{
                    .{ .name = "Keyword Filter", .value = "1" },
                    .{ .name = "Spam Link Filter", .value = "2" },
                    .{ .name = "Keyword Preset", .value = "3" },
                    .{ .name = "Mention Spam", .value = "4" },
                },
            },
        },
    };
}

fn createStageCommand(allocator: std.mem.Allocator) !zignal.models.ApplicationCommand {
    return zignal.models.ApplicationCommand{
        .name = "stage",
        .description = "Manage stage instances",
        .options = &[_]zignal.models.ApplicationCommandOption{
            .{
                .name = "action",
                .description = "Action to perform",
                .type = .string,
                .required = true,
                .choices = &[_]zignal.models.ApplicationCommandOption.Choice{
                    .{ .name = "Create", .value = "create" },
                    .{ .name = "Update", .value = "update" },
                    .{ .name = "Delete", .value = "delete" },
                    .{ .name = "Info", .value = "info" },
                },
            },
            .{
                .name = "topic",
                .description = "Stage topic",
                .type = .string,
                .required = false,
            },
            .{
                .name = "privacy_level",
                .description = "Privacy level",
                .type = .string,
                .required = false,
                .choices = &[_]zignal.models.ApplicationCommandOption.Choice{
                    .{ .name = "Public", .value = "1" },
                    .{ .name = "Guild Only", .value = "2" },
                },
            },
        },
    };
}

fn createAppCommandMgmtCommand(allocator: std.mem.Allocator) !zignal.models.ApplicationCommand {
    return zignal.models.ApplicationCommand{
        .name = "commands",
        .description = "Manage application commands",
        .options = &[_]zignal.models.ApplicationCommandOption{
            .{
                .name = "action",
                .description = "Action to perform",
                .type = .string,
                .required = true,
                .choices = &[_]zignal.models.ApplicationCommandOption.Choice{
                    .{ .name = "List Global", .value = "list_global" },
                    .{ .name = "List Guild", .value = "list_guild" },
                    .{ .name = "Create Guild", .value = "create_guild" },
                    .{ .name = "Delete Global", .value = "delete_global" },
                    .{ .name = "Delete Guild", .value = "delete_guild" },
                    .{ .name = "Permissions", .value = "permissions" },
                },
            },
            .{
                .name = "command_name",
                .description = "Command name",
                .type = .string,
                .required = false,
            },
        },
    };
}

fn demonstrateAllAPIs(
    audit_manager: *zignal.audit_logs.AuditLogManager,
    emoji_manager: *zignal.emoji.EmojiManager,
    stage_manager: *zignal.stage_instances.StageInstanceManager,
    auto_mod_manager: *zignal.auto_moderation.AutoModerationManager,
    integration_manager: *zignal.integrations.IntegrationManager,
    invite_manager: *zignal.invites.InviteManager,
    sticker_manager: *zignal.stickers.StickerManager,
    app_command_manager: *zignal.application_commands.ApplicationCommandManager,
    guild_id: u64,
    allocator: std.mem.Allocator,
) !void {
    const logger = zignal.logging.getGlobalLogger().?;

    logger.info("=== Demonstrating All API Functionality ===", .{});

    // Audit Logs
    try demonstrateAuditLogs(audit_manager, guild_id, allocator);

    // Emoji Management
    try demonstrateEmojiManagement(emoji_manager, guild_id, allocator);

    // Stage Management
    try demonstrateStageManagement(stage_manager, 987654321098765432, allocator);

    // Auto Moderation
    try demonstrateAutoModeration(auto_mod_manager, guild_id, allocator);

    // Integration Management
    try demonstrateIntegrationManagement(integration_manager, guild_id, allocator);

    // Invite Management
    try demonstrateInviteManagement(invite_manager, 123456789012345678, allocator);

    // Sticker Management
    try demonstrateStickerManagement(sticker_manager, guild_id, allocator);

    // Application Commands
    try demonstrateApplicationCommands(app_command_manager, guild_id, allocator);

    logger.info("=== API Demonstration Complete ===", .{});
}

fn demonstrateAuditLogs(audit_manager: *zignal.audit_logs.AuditLogManager, guild_id: u64, allocator: std.mem.Allocator) !void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🔍 Demonstrating Audit Logs API", .{});

    // Get recent audit log entries
    const audit_log = try audit_manager.getAuditLog(guild_id, .{
        .limit = 5,
    });
    defer {
        allocator.free(audit_log.audit_log_entries);
        if (audit_log.users) |users| allocator.free(users);
        if (audit_log.webhooks) |webhooks| allocator.free(webhooks);
    }

    logger.info("Retrieved {d} audit log entries", .{audit_log.audit_log_entries.len});

    // Get specific action type entries
    const ban_entries = try audit_manager.getAuditLog(guild_id, .{
        .action_type = .member_ban_add,
        .limit = 3,
    });
    defer {
        allocator.free(ban_entries.audit_log_entries);
        if (ban_entries.users) |users| allocator.free(users);
        if (ban_entries.webhooks) |webhooks| allocator.free(webhooks);
    }

    logger.info("Found {d} recent ban entries", .{ban_entries.audit_log_entries.len});
}

fn demonstrateEmojiManagement(emoji_manager: *zignal.emoji.EmojiManager, guild_id: u64, allocator: std.mem.Allocator) !void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("😀 Demonstrating Emoji Management API", .{});

    // List all emojis
    const emojis = try emoji_manager.listGuildEmojis(guild_id);
    defer allocator.free(emojis);

    logger.info("Guild has {d} custom emojis", .{emojis.len});

    for (emojis) |emoji| {
        const emoji_url = try zignal.emoji.EmojiManager.getEmojiUrl(emoji.id, emoji.animated);
        defer allocator.free(emoji_url);
        
        logger.info("Emoji: {s} (ID: {d}, Animated: {})", .{
            emoji.name,
            emoji.id,
            emoji.animated,
        });
    }

    // Create a test emoji if under limit
    if (emojis.len < 50) {
        const base64_image = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==";
        
        const new_emoji = try emoji_manager.createGuildEmoji(
            guild_id,
            "demo_emoji",
            base64_image,
            null,
            "Demo emoji creation",
        );

        logger.info("Created new emoji: {s} (ID: {d})", .{ new_emoji.name, new_emoji.id });

        // Clean up
        try emoji_manager.deleteGuildEmoji(guild_id, new_emoji.id, "Cleaning up demo emoji");
        logger.info("Deleted demo emoji", .{});
    }
}

fn demonstrateStageManagement(stage_manager: *zignal.stage_instances.StageInstanceManager, channel_id: u64, allocator: std.mem.Allocator) !void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🎭 Demonstrating Stage Management API", .{});

    // Create a stage instance
    const stage_instance = try stage_manager.createStageInstance(
        channel_id,
        "Demo Stage: API Showcase",
        .guild_only,
        "Created for API demonstration",
    );

    logger.info("Created stage instance: {s} (Channel: {d})", .{
        stage_instance.topic,
        stage_instance.channel_id,
    });

    // Modify the stage instance
    const updated_stage = try stage_manager.modifyStageInstance(
        channel_id,
        "Demo Stage: API Showcase & Testing",
        null,
        "Updated topic",
    );

    logger.info("Updated stage instance topic: {s}", .{updated_stage.topic});

    // Clean up
    try stage_manager.deleteStageInstance(channel_id, "Demo stage ended");
    logger.info("Deleted demo stage instance", .{});
}

fn demonstrateAutoModeration(auto_mod_manager: *zignal.auto_moderation.AutoModerationManager, guild_id: u64, allocator: std.mem.Allocator) !void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🛡️ Demonstrating Auto Moderation API", .{});

    // List existing rules
    const rules = try auto_mod_manager.getAutoModerationRules(guild_id);
    defer allocator.free(rules);

    logger.info("Guild has {d} auto moderation rules", .{rules.len});

    // Create a demo rule
    const actions = [_]zignal.auto_moderation.AutoModerationAction{
        .{
            .type = .block_message,
            .metadata = .{
                .custom_message = "This message contains blocked content",
            },
        },
    };

    const trigger_metadata = zignal.auto_moderation.AutoModerationTriggerMetadata{
        .keyword_filter = &[_][]const u8{"spam", "advertisement", "demo"},
        .mention_total_limit = 5,
    };

    const new_rule = try auto_mod_manager.createAutoModerationRule(
        guild_id,
        "Demo Anti-Spam Filter",
        .message_send,
        .keyword,
        trigger_metadata,
        &actions,
        true,
        "Created for API demonstration",
    );

    logger.info("Created auto moderation rule: {s} (ID: {d})", .{
        new_rule.name,
        new_rule.id,
    });

    // Clean up
    try auto_mod_manager.deleteAutoModerationRule(guild_id, new_rule.id, "Cleaning up demo rule");
    logger.info("Deleted demo auto moderation rule", .{});
}

fn demonstrateIntegrationManagement(integration_manager: *zignal.integrations.IntegrationManager, guild_id: u64, allocator: std.mem.Allocator) !void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🔗 Demonstrating Integration Management API", .{});

    // List existing integrations
    const integrations = try integration_manager.getGuildIntegrations(guild_id);
    defer allocator.free(integrations);

    logger.info("Guild has {d} integrations", .{integrations.len});

    for (integrations) |integration| {
        logger.info("Integration: {s} (ID: {d}, Type: {s})", .{
            integration.name,
            integration.id,
            integration.type,
        });
    }

    // Note: Creating integrations requires OAuth2 flow, so we'll just list existing ones
    logger.info("Integration management requires OAuth2 authorization", .{});
}

fn demonstrateInviteManagement(invite_manager: *zignal.invites.InviteManager, channel_id: u64, allocator: std.mem.Allocator) !void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("📨 Demonstrating Invite Management API", .{});

    // List channel invites
    const channel_invites = try invite_manager.getChannelInvites(channel_id);
    defer allocator.free(channel_invites);

    logger.info("Channel has {d} active invites", .{channel_invites.len});

    // Create a temporary invite
    const new_invite = try invite_manager.createChannelInvite(
        channel_id,
        3600, // 1 hour
        10,   // 10 uses
        false, // not temporary
        true,  // unique
        null,
        null,
        "Demo invite creation",
    );

    logger.info("Created new invite: {s} (Code: {s})", .{
        new_invite.code,
        try zignal.invites.InviteManager.generateInviteUrl(new_invite.code),
    });

    // Get invite info
    const invite_info = try invite_manager.getInvite(new_invite.code, true, true);
    logger.info("Invite info: Uses {d}/{d}, Expires: {s}", .{
        invite_info.uses,
        invite_info.max_uses orelse 0,
        invite_info.expires_at orelse "Never",
    });

    // Clean up
    _ = invite_manager.deleteChannelInvite(channel_id, new_invite.code);
    logger.info("Deleted demo invite", .{});
}

fn demonstrateStickerManagement(sticker_manager: *zignal.stickers.StickerManager, guild_id: u64, allocator: std.mem.Allocator) !void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🏷️ Demonstrating Sticker Management API", .{});

    // List guild stickers
    const stickers = try sticker_manager.listGuildStickers(guild_id);
    defer allocator.free(stickers);

    logger.info("Guild has {d} custom stickers", .{stickers.len});

    for (stickers) |sticker| {
        const format = zignal.stickers.StickerManager.getStickerFormat(sticker);
        const sticker_url = try zignal.stickers.StickerManager.getStickerUrl(sticker.id, format);
        defer allocator.free(sticker_url);

        logger.info("Sticker: {s} (ID: {d}, Format: {s})", .{
            sticker.name,
            sticker.id,
            format,
        });
    }

    // List sticker packs
    const sticker_packs = try sticker_manager.listStickerPacks();
    defer allocator.free(sticker_packs);

    logger.info("Available sticker packs: {d}", .{sticker_packs.len});

    for (sticker_packs) |pack| {
        logger.info("Pack: {s} ({d} stickers)", .{ pack.name, pack.stickers.len });
    }

    // Note: Creating stickers requires file upload, so we'll just list existing ones
    logger.info("Sticker creation requires file upload", .{});
}

fn demonstrateApplicationCommands(app_command_manager: *zignal.application_commands.ApplicationCommandManager, guild_id: u64, allocator: std.mem.Allocator) !void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("⚡ Demonstrating Application Commands API", .{});

    // List global commands
    const global_commands = try app_command_manager.getGlobalApplicationCommands();
    defer allocator.free(global_commands);

    logger.info("Bot has {d} global commands", .{global_commands.len});

    for (global_commands) |command| {
        logger.info("Global command: /{s} - {s}", .{ command.name, command.description });
    }

    // List guild commands
    const guild_commands = try app_command_manager.getGuildApplicationCommands(guild_id);
    defer allocator.free(guild_commands);

    logger.info("Bot has {d} guild commands", .{guild_commands.len});

    for (guild_commands) |command| {
        logger.info("Guild command: /{s} - {s}", .{ command.name, command.description });
    }

    // Get command permissions
    const permissions = try app_command_manager.getGuildApplicationCommandPermissions(guild_id);
    defer allocator.free(permissions);

    logger.info("Guild has {d} command permission sets", .{permissions.len});
}

// Event handlers (simplified versions)
fn onGuildCreate(event: zignal.guild_events.GuildEvents.GuildCreateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🏰 Guild joined: {s} ({d} members)", .{ event.name, event.approximate_member_count orelse 0 });
}

fn onGuildUpdate(event: zignal.guild_events.GuildEvents.GuildUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🏰 Guild updated: {s}", .{event.name});
}

fn onGuildDelete(event: zignal.guild_events.GuildEvents.GuildDeleteEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🏰 Guild left: {d} (Unavailable: {})", .{ event.id, event.unavailable });
}

fn onGuildBanAdd(event: zignal.guild_events.GuildEvents.GuildBanAddEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🔨 User banned: {s}", .{event.user.username});
}

fn onGuildBanRemove(event: zignal.guild_events.GuildEvents.GuildBanRemoveEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🔓 User unbanned: {s}", .{event.user.username});
}

fn onGuildMemberAdd(event: zignal.guild_events.GuildEvents.GuildMemberAddEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("👋 Member joined: {s}", .{event.user.username});
}

fn onGuildMemberRemove(event: zignal.guild_events.GuildEvents.GuildMemberRemoveEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("👋 Member left: {s}", .{event.user.username});
}

fn onGuildMemberUpdate(event: zignal.guild_events.GuildEvents.GuildMemberUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("👤 Member updated: {s}", .{event.user.username});
}

fn onGuildRoleCreate(event: zignal.guild_events.GuildEvents.GuildRoleCreateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🎭 Role created: {s}", .{event.role.name});
}

fn onGuildRoleUpdate(event: zignal.guild_events.GuildEvents.GuildRoleUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🎭 Role updated: {s}", .{event.role.name});
}

fn onGuildRoleDelete(event: zignal.guild_events.GuildEvents.GuildRoleDeleteEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🎭 Role deleted: {d}", .{event.role_id});
}

fn onGuildEmojisUpdate(event: zignal.guild_events.GuildEvents.GuildEmojisUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("😀 Guild emojis updated: {d} emojis", .{event.emojis.len});
}

fn onGuildStickersUpdate(event: zignal.guild_events.GuildEvents.GuildStickersUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🏷️ Guild stickers updated: {d} stickers", .{event.stickers.len});
}

fn onGuildIntegrationsUpdate(event: zignal.guild_events.GuildEvents.GuildIntegrationsUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🔗 Guild integrations updated: {d}", .{event.guild_id});
}

fn onMessageCreate(event: zignal.message_events.MessageEvents.MessageCreateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("💬 Message: {s}", .{event.content});
}

fn onMessageUpdate(event: zignal.message_events.MessageEvents.MessageUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("✏️ Message updated: {d}", .{event.id});
}

fn onMessageDelete(event: zignal.message_events.MessageEvents.MessageDeleteEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🗑️ Message deleted: {d}", .{event.id});
}

fn onMessageBulkDelete(event: zignal.message_events.MessageEvents.MessageBulkDeleteEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🗑️ Bulk delete: {d} messages", .{event.ids.len});
}

fn onMessageReactionAdd(event: zignal.message_events.MessageEvents.MessageReactionAddEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("😊 Reaction added: {s}", .{event.emoji.name orelse "unknown"});
}

fn onMessageReactionRemove(event: zignal.message_events.MessageEvents.MessageReactionRemoveEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("😐 Reaction removed: {s}", .{event.emoji.name orelse "unknown"});
}

fn onMessageReactionRemoveAll(event: zignal.message_events.MessageEvents.MessageReactionRemoveAllEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("😐 All reactions removed: {d}", .{event.message_id});
}

fn onPresenceUpdate(event: zignal.presence_events.PresenceEvents.PresenceUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("👤 Presence update: {s} is {s}", .{
        event.user.username,
        @tagName(event.status),
    });
}

fn onTypingStart(event: zignal.typing_events.TypingEvents.TypingStartEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("⌨️ {s} is typing...", .{event.user.username});
}

fn onVoiceStateUpdate(event: zignal.voice_events.VoiceEvents.VoiceStateUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    if (event.channel_id) |channel_id| {
        logger.info("🎙️ Voice state: {s} joined channel {d}", .{ event.user.username, channel_id });
    } else {
        logger.info("🎙️ Voice state: {s} left voice channel", .{event.user.username});
    }
}

fn onVoiceServerUpdate(event: zignal.voice_events.VoiceEvents.VoiceServerUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("🎙️ Voice server: {s}", .{event.endpoint orelse "None"});
}

fn onInteractionCreate(interaction: zignal.interactions.Interaction) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("⚡ Interaction: {s}", .{@tagName(interaction.type)});
}
