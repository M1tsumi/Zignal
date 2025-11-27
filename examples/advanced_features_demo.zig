const std = @import("std");
const zignal = @import("zignal");

/// Advanced Discord bot demonstrating audit logs, emoji management, and auto moderation
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

    // Create client with advanced configuration
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

    // Initialize API managers
    var audit_log_manager = zignal.audit_logs.AuditLogManager.init(&client, allocator);
    var emoji_manager = zignal.emoji.EmojiManager.init(&client, allocator);
    var stage_manager = zignal.stage_instances.StageInstanceManager.init(&client, allocator);
    var auto_mod_manager = zignal.auto_moderation.AutoModerationManager.init(&client, allocator);

    // Register event handlers
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
    client.on(.message_create, onMessageCreate);
    client.on(.message_update, onMessageUpdate);
    client.on(.message_delete, onMessageDelete);
    client.on(.message_bulk_delete, onMessageBulkDelete);
    client.on(.message_reaction_add, onMessageReactionAdd);
    client.on(.message_reaction_remove, onMessageReactionRemove);
    client.on(.message_reaction_remove_all, onMessageReactionRemoveAll);
    client.on(.interaction_create, onInteractionCreate);

    // Register slash commands
    try setupSlashCommands(&client, allocator);

    // Connect to Discord
    try client.connect();
    logger.info("Advanced features bot connected successfully", .{});

    // Example: Fetch audit logs
    try demonstrateAuditLogs(&audit_log_manager, 1234567890123456789, allocator);

    // Example: Manage emojis
    try demonstrateEmojiManagement(&emoji_manager, 1234567890123456789, allocator);

    // Example: Create auto moderation rule
    try demonstrateAutoModeration(&auto_mod_manager, 1234567890123456789, allocator);

    // Example: Stage instance management
    try demonstrateStageManagement(&stage_manager, 987654321098765432, allocator);

    // Keep the bot running
    logger.info("Bot is now running. Press Ctrl+C to stop.", .{});
    while (true) {
        std.time.sleep(1_000_000_000); // Sleep for 1 second
    }
}

fn setupSlashCommands(client: *zignal.Client, allocator: std.mem.Allocator) !void {
    // Audit log command
    const audit_command = try allocator.create(zignal.interactions.InteractionHandler.SlashCommandHandler);
    audit_command.* = .{
        .name = "audit",
        .description = "View recent audit log entries",
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
        .execute = handleAuditCommand,
    };

    // Emoji management command
    const emoji_command = try allocator.create(zignal.interactions.InteractionHandler.SlashCommandHandler);
    emoji_command.* = .{
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
        .execute = handleEmojiCommand,
    };

    // Auto moderation command
    const automod_command = try allocator.create(zignal.interactions.InteractionHandler.SlashCommandHandler);
    automod_command.* = .{
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
        .execute = handleAutoModCommand,
    };

    // Register commands with the interaction handler
    var interaction_handler = zignal.interactions.InteractionHandler.init(allocator);
    defer interaction_handler.deinit();

    try interaction_handler.registerSlashCommand(audit_command);
    try interaction_handler.registerSlashCommand(emoji_command);
    try interaction_handler.registerSlashCommand(automod_command);
}

fn demonstrateAuditLogs(audit_manager: *zignal.audit_logs.AuditLogManager, guild_id: u64, allocator: std.mem.Allocator) !void {
    const logger = zignal.logging.getGlobalLogger().?;

    // Get recent audit log entries
    const audit_log = try audit_manager.getAuditLog(guild_id, .{
        .limit = 10,
    });
    defer {
        allocator.free(audit_log.audit_log_entries);
        if (audit_log.users) |users| allocator.free(users);
        if (audit_log.webhooks) |webhooks| allocator.free(webhooks);
    }

    logger.info("Retrieved {d} audit log entries", .{audit_log.audit_log_entries.len});

    for (audit_log.audit_log_entries) |entry| {
        logger.info("Action: {s}, User: {d}, Reason: {s}", .{
            @tagName(entry.action_type),
            entry.user_id,
            entry.reason orelse "No reason provided",
        });
    }

    // Get specific action type entries
    const ban_entries = try audit_manager.getAuditLog(guild_id, .{
        .action_type = .member_ban_add,
        .limit = 5,
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

    // Create a new emoji (example)
    if (emojis.len < 50) { // Discord limit is 50 emojis
        const base64_image = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==";
        
        const new_emoji = try emoji_manager.createGuildEmoji(
            guild_id,
            "test_emoji",
            base64_image,
            null, // No roles restriction
            "Created by bot",
        );

        logger.info("Created new emoji: {s} (ID: {d})", .{ new_emoji.name, new_emoji.id });

        // Clean up - delete the test emoji
        try emoji_manager.deleteGuildEmoji(guild_id, new_emoji.id, "Cleaning up test emoji");
        logger.info("Deleted test emoji", .{});
    }
}

fn demonstrateAutoModeration(auto_mod_manager: *zignal.auto_moderation.AutoModerationManager, guild_id: u64, allocator: std.mem.Allocator) !void {
    const logger = zignal.logging.getGlobalLogger().?;

    // List existing auto moderation rules
    const rules = try auto_mod_manager.getAutoModerationRules(guild_id);
    defer allocator.free(rules);

    logger.info("Guild has {d} auto moderation rules", .{rules.len});

    for (rules) |rule| {
        logger.info("Rule: {s} (ID: {d}, Enabled: {})", .{
            rule.name,
            rule.id,
            rule.enabled,
        });
    }

    // Create a simple keyword filter rule
    const actions = [_]zignal.auto_moderation.AutoModerationAction{
        .{
            .type = .block_message,
            .metadata = .{
                .custom_message = "This message contains blocked content",
            },
        },
    };

    const trigger_metadata = zignal.auto_moderation.AutoModerationTriggerMetadata{
        .keyword_filter = &[_][]const u8{"spam", "advertisement"},
        .mention_total_limit = 5,
    };

    const new_rule = try auto_mod_manager.createAutoModerationRule(
        guild_id,
        "Anti-Spam Filter",
        .message_send,
        .keyword,
        trigger_metadata,
        &actions,
        true,
        "Created to reduce spam in the server",
    );

    logger.info("Created auto moderation rule: {s} (ID: {d})", .{
        new_rule.name,
        new_rule.id,
    });

    // Clean up - delete the test rule
    try auto_mod_manager.deleteAutoModerationRule(guild_id, new_rule.id, "Cleaning up test rule");
    logger.info("Deleted test auto moderation rule", .{});
}

fn demonstrateStageManagement(stage_manager: *zignal.stage_instances.StageInstanceManager, channel_id: u64, allocator: std.mem.Allocator) !void {
    const logger = zignal.logging.getGlobalLogger().?;

    // Create a stage instance
    const stage_instance = try stage_manager.createStageInstance(
        channel_id,
        "Live Discussion: API Development",
        .guild_only,
        "Started stage for discussion",
    );

    logger.info("Created stage instance: {s} (Channel: {d})", .{
        stage_instance.topic,
        stage_instance.channel_id,
    });

    // Modify the stage instance
    const updated_stage = try stage_manager.modifyStageInstance(
        channel_id,
        "Live Discussion: API Development & Testing",
        null, // Keep same privacy level
        "Updated topic",
    );

    logger.info("Updated stage instance topic: {s}", .{updated_stage.topic});

    // Clean up - delete the stage instance
    try stage_manager.deleteStageInstance(channel_id, "Stage discussion ended");
    logger.info("Deleted stage instance", .{});
}

// Event handlers
fn onGuildCreate(event: zignal.guild_events.GuildEvents.GuildCreateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Joined guild: {s} (ID: {d})", .{ event.name, event.id });
}

fn onGuildUpdate(event: zignal.guild_events.GuildEvents.GuildUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Guild updated: {s} (ID: {d})", .{ event.name, event.id });
}

fn onGuildDelete(event: zignal.guild_events.GuildEvents.GuildDeleteEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Left guild: {d} (Unavailable: {})", .{ event.id, event.unavailable });
}

fn onGuildBanAdd(event: zignal.guild_events.GuildEvents.GuildBanAddEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("User banned: {s} (ID: {d})", .{ event.user.username, event.user.id });
}

fn onGuildBanRemove(event: zignal.guild_events.GuildEvents.GuildBanRemoveEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("User unbanned: {s} (ID: {d})", .{ event.user.username, event.user.id });
}

fn onGuildMemberAdd(event: zignal.guild_events.GuildEvents.GuildMemberAddEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Member joined: {s} (ID: {d})", .{ event.user.username, event.user.id });
}

fn onGuildMemberRemove(event: zignal.guild_events.GuildEvents.GuildMemberRemoveEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Member left: {s} (ID: {d})", .{ event.user.username, event.user.id });
}

fn onGuildMemberUpdate(event: zignal.guild_events.GuildEvents.GuildMemberUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Member updated: {s} (ID: {d})", .{ event.user.username, event.user.id });
}

fn onGuildRoleCreate(event: zignal.guild_events.GuildEvents.GuildRoleCreateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Role created: {s} (ID: {d})", .{ event.role.name, event.role.id });
}

fn onGuildRoleUpdate(event: zignal.guild_events.GuildEvents.GuildRoleUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Role updated: {s} (ID: {d})", .{ event.role.name, event.role.id });
}

fn onGuildRoleDelete(event: zignal.guild_events.GuildEvents.GuildRoleDeleteEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Role deleted: {d}", .{event.role_id});
}

fn onGuildEmojisUpdate(event: zignal.guild_events.GuildEvents.GuildEmojisUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Guild emojis updated: {d} emojis", .{event.emojis.len});
}

fn onGuildStickersUpdate(event: zignal.guild_events.GuildEvents.GuildStickersUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Guild stickers updated: {d} stickers", .{event.stickers.len});
}

fn onGuildIntegrationsUpdate(event: zignal.guild_events.GuildEvents.GuildIntegrationsUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Guild integrations updated: {d}", .{event.guild_id});
}

fn onMessageCreate(event: zignal.message_events.MessageEvents.MessageCreateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Message created: {s} (ID: {d})", .{ event.content, event.id });
}

fn onMessageUpdate(event: zignal.message_events.MessageEvents.MessageUpdateEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Message updated: {d}", .{event.id});
}

fn onMessageDelete(event: zignal.message_events.MessageEvents.MessageDeleteEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Message deleted: {d}", .{event.id});
}

fn onMessageBulkDelete(event: zignal.message_events.MessageEvents.MessageBulkDeleteEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Bulk delete: {d} messages", .{event.ids.len});
}

fn onMessageReactionAdd(event: zignal.message_events.MessageEvents.MessageReactionAddEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Reaction added: {s} to message {d}", .{ event.emoji.name orelse "unknown", event.message_id });
}

fn onMessageReactionRemove(event: zignal.message_events.MessageEvents.MessageReactionRemoveEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Reaction removed: {s} from message {d}", .{ event.emoji.name orelse "unknown", event.message_id });
}

fn onMessageReactionRemoveAll(event: zignal.message_events.MessageEvents.MessageReactionRemoveAllEvent) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("All reactions removed from message: {d}", .{event.message_id});
}

fn onInteractionCreate(interaction: zignal.interactions.Interaction) void {
    const logger = zignal.logging.getGlobalLogger().?;
    logger.info("Interaction received: {s}", .{@tagName(interaction.type)});
}

// Slash command handlers
fn handleAuditCommand(interaction: zignal.interactions.Interaction, options: []const zignal.interactions.InteractionOption) !zignal.interactions.InteractionResponse {
    _ = interaction;
    _ = options;
    
    const embed = try zignal.builders.EmbedBuilder.init(std.heap.page_allocator)
        .title("Audit Log")
        .description("Recent audit log entries")
        .colorRgb(255, 255, 0)
        .build();
    defer embed.deinit();

    return zignal.interactions.InteractionResponse{
        .type = .channel_message_with_source,
        .data = .{
            .embeds = &[_]zignal.models.Embed{embed},
        },
    };
}

fn handleEmojiCommand(interaction: zignal.interactions.Interaction, options: []const zignal.interactions.InteractionOption) !zignal.interactions.InteractionResponse {
    _ = interaction;
    _ = options;
    
    const embed = try zignal.builders.EmbedBuilder.init(std.heap.page_allocator)
        .title("Emoji Management")
        .description("Emoji operations")
        .colorRgb(0, 255, 255)
        .build();
    defer embed.deinit();

    return zignal.interactions.InteractionResponse{
        .type = .channel_message_with_source,
        .data = .{
            .embeds = &[_]zignal.models.Embed{embed},
        },
    };
}

fn handleAutoModCommand(interaction: zignal.interactions.Interaction, options: []const zignal.interactions.InteractionOption) !zignal.interactions.InteractionResponse {
    _ = interaction;
    _ = options;
    
    const embed = try zignal.builders.EmbedBuilder.init(std.heap.page_allocator)
        .title("Auto Moderation")
        .description("Auto moderation rule management")
        .colorRgb(255, 0, 255)
        .build();
    defer embed.deinit();

    return zignal.interactions.InteractionResponse{
        .type = .channel_message_with_source,
        .data = .{
            .embeds = &[_]zignal.models.Embed{embed},
        },
    };
}
