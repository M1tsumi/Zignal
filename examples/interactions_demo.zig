const std = @import("std");
const zignal = @import("zignal");

/// Interactions demo showcasing buttons, modals, and select menus
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize logger
    try zignal.logging.initGlobalLogger(allocator, .info);
    defer zignal.logging.deinitGlobalLogger(allocator);
    const logger = zignal.logging.getGlobalLogger().?;

    // Create client
    var client = zignal.Client.init(allocator, "YOUR_BOT_TOKEN");
    defer client.deinit();

    // Initialize interaction handler
    var interaction_handler = zignal.interactions.InteractionHandler.init(allocator);
    defer interaction_handler.deinit();

    // Register all interaction handlers
    try registerInteractionHandlers(&interaction_handler, allocator);

    // Setup event handlers
    try setupInteractionEventHandlers(&client, &interaction_handler, logger);

    // Connect to gateway
    try client.connect();

    logger.info("Interactions demo bot started", .{});

    // Main loop
    while (true) {
        try client.processEvents();
        std.time.sleep(10_000_000); // 10ms
    }
}

fn registerInteractionHandlers(handler: *zignal.interactions.InteractionHandler, allocator: std.mem.Allocator) !void {
    // Register slash commands
    try registerSlashCommands(handler, allocator);
    
    // Register component handlers
    try registerComponentHandlers(handler, allocator);
    
    // Register modal handlers
    try registerModalHandlers(handler, allocator);
    
    // Register autocomplete handlers
    try registerAutocompleteHandlers(handler, allocator);
}

fn registerSlashCommands(handler: *zignal.interactions.InteractionHandler, allocator: std.mem.Allocator) !void {
    // Menu command - shows interactive menu
    const menu_handler = try allocator.create(zignal.interactions.InteractionHandler.SlashCommandHandler);
    menu_handler.* = .{
        .name = "menu",
        .description = "Show interactive menu",
        .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{},
        .execute = handleMenuCommand,
    };
    try handler.registerSlashCommand(menu_handler);

    // Form command - opens modal form
    const form_handler = try allocator.create(zignal.interactions.InteractionHandler.SlashCommandHandler);
    form_handler.* = .{
        .name = "form",
        .description = "Open a feedback form",
        .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{},
        .execute = handleFormCommand,
    };
    try handler.registerSlashCommand(form_handler);

    // Poll command - creates interactive poll
    const poll_handler = try allocator.create(zignal.interactions.InteractionHandler.SlashCommandHandler);
    poll_handler.* = .{
        .name = "poll",
        .description = "Create an interactive poll",
        .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{
            .{
                .type = .string,
                .name = "question",
                .description = "Poll question",
                .required = true,
                .choices = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption.ApplicationCommandOptionChoice{},
                .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{},
                .channel_types = &[_]u64{},
                .min_value = null,
                .max_value = null,
                .autocomplete = false,
            },
        },
        .execute = handlePollCommand,
    };
    try handler.registerSlashCommand(poll_handler);

    // Search command with autocomplete
    const search_handler = try allocator.create(zignal.interactions.InteractionHandler.SlashCommandHandler);
    search_handler.* = .{
        .name = "search",
        .description = "Search with autocomplete",
        .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{
            .{
                .type = .string,
                .name = "query",
                .description = "Search query",
                .required = true,
                .choices = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption.ApplicationCommandOptionChoice{},
                .options = &[_]zignal.interactions.ApplicationCommand.ApplicationCommandOption{},
                .channel_types = &[_]u64{},
                .min_value = null,
                .max_value = null,
                .autocomplete = true,
            },
        },
        .execute = handleSearchCommand,
    };
    try handler.registerSlashCommand(search_handler);
}

fn registerComponentHandlers(handler: *zignal.interactions.InteractionHandler, allocator: std.mem.Allocator) !void {
    // Menu button handlers
    const info_button_handler = try allocator.create(zignal.interactions.InteractionHandler.ComponentHandler);
    info_button_handler.* = .{
        .custom_id = "menu_info",
        .execute = handleInfoButton,
    };
    try handler.registerComponentHandler(info_button_handler);

    const settings_button_handler = try allocator.create(zignal.interactions.InteractionHandler.ComponentHandler);
    settings_button_handler.* = .{
        .custom_id = "menu_settings",
        .execute = handleSettingsButton,
    };
    try handler.registerComponentHandler(settings_button_handler);

    const help_button_handler = try allocator.create(zignal.interactions.InteractionHandler.ComponentHandler);
    help_button_handler.* = .{
        .custom_id = "menu_help",
        .execute = handleHelpButton,
    };
    try handler.registerComponentHandler(help_button_handler);

    // Poll vote handlers
    const poll_vote_a_handler = try allocator.create(zignal.interactions.InteractionHandler.ComponentHandler);
    poll_vote_a_handler.* = .{
        .custom_id = "poll_vote_a",
        .execute = handlePollVote,
    };
    try handler.registerComponentHandler(poll_vote_a_handler);

    const poll_vote_b_handler = try allocator.create(zignal.interactions.InteractionHandler.ComponentHandler);
    poll_vote_b_handler.* = .{
        .custom_id = "poll_vote_b",
        .execute = handlePollVote,
    };
    try handler.registerComponentHandler(poll_vote_b_handler);

    // Select menu handler
    const role_select_handler = try allocator.create(zignal.interactions.InteractionHandler.ComponentHandler);
    role_select_handler.* = .{
        .custom_id = "role_select",
        .execute = handleRoleSelect,
    };
    try handler.registerComponentHandler(role_select_handler);
}

fn registerModalHandlers(handler: *zignal.interactions.InteractionHandler, allocator: std.mem.Allocator) !void {
    const feedback_form_handler = try allocator.create(zignal.interactions.InteractionHandler.ModalHandler);
    feedback_form_handler.* = .{
        .custom_id = "feedback_form",
        .execute = handleFeedbackForm,
    };
    try handler.registerModalHandler(feedback_form_handler);
}

fn registerAutocompleteHandlers(handler: *zignal.interactions.InteractionHandler, allocator: std.mem.Allocator) !void {
    const search_autocomplete_handler = try allocator.create(zignal.interactions.InteractionHandler.AutocompleteHandler);
    search_autocomplete_handler.* = .{
        .command_name = "search",
        .option_name = "query",
        .execute = handleSearchAutocomplete,
    };
    try handler.registerAutocompleteHandler(search_autocomplete_handler);
}

fn setupInteractionEventHandlers(
    client: *zignal.Client,
    _interaction_handler: *zignal.interactions.InteractionHandler,
    _logger: *zignal.logging.Logger,
) !void {
    _ = _interaction_handler; // TODO: implement interaction handler usage
    _ = _logger; // TODO: implement logger usage
    
    // Ready event
    client.on(.ready, struct {
        fn handler(event: zignal.events.ReadyEvent, event_logger: *zignal.logging.Logger) !void {
            event_logger.info("Interactions demo ready: {s}", .{event.user.username});
        }
    }.handler);

    // Interaction create event
    client.on(.interaction_create, struct {
        fn handler(
            interaction: zignal.interactions.Interaction,
            ih: *zignal.interactions.InteractionHandler,
            ih_logger: *zignal.logging.Logger,
        ) !void {
            _ = ih_logger; // TODO: implement logger usage
            
            // Handle interaction directly
            switch (interaction.type) {
                .application_command => {
                    // Handle slash commands
                    const cmd_handler = ih.getSlashCommandHandler(interaction.data.name) orelse return;
                    try cmd_handler.execute(interaction);
                },
                .message_component => {
                    // Handle button/selection interactions
                    const component_handler = ih.getComponentHandler(interaction.data.custom_id) orelse return;
                    try component_handler.execute(interaction);
                },
                .modal_submit => {
                    // Handle modal submissions
                    const modal_handler = ih.getModalHandler(interaction.data.custom_id) orelse return;
                    try modal_handler.execute(interaction);
                },
                .application_command_autocomplete => {
                    // Handle autocomplete
                    const autocomplete_handler = ih.getAutocompleteHandler(interaction.data.name, interaction.data.options[0].name) orelse return;
                    try autocomplete_handler.execute(interaction);
                },
                else => return,
            }
        }
    }.handler);
}

fn handleMenuCommand(ctx: *zignal.interactions.InteractionHandler.SlashCommandHandler.SlashCommandContext) !void {
    // Create interactive menu with buttons
    var components = zignal.interactions.InteractionBuilder.ComponentBuilder.init(ctx.allocator);
    defer components.deinit();
    try components.addButton(.primary, "ℹ️ Info", "menu_info");
    try components.addButton(.secondary, "⚙️ Settings", "menu_settings");
    try components.addButton(.success, "❓ Help", "menu_help");
    const built_components = try components.build();

    const embed = zignal.builders.EmbedBuilder.init(ctx.allocator)
        .title("🎮 Interactive Menu")
        .description("Choose an option below:")
        .colorRgb(0, 128, 255)
        .build() catch return;

    const response = zignal.interactions.InteractionResponse{
        .type = .channel_message_with_source,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = null,
            .embeds = &[_]zignal.models.Embed{embed},
            .allowed_mentions = null,
            .flags = null,
            .components = built_components,
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = null,
            .title = null,
        },
    };

    ctx.respond(&ctx, response);
}

fn handleFormCommand(ctx: *zignal.interactions.InteractionHandler.SlashCommandHandler.SlashCommandContext) !void {
    // Create modal form
    var modal_components = zignal.interactions.InteractionBuilder.ComponentBuilder.init(ctx.allocator);
    defer modal_components.deinit();
    try modal_components.addTextInput(" feedback_title\, \Title\, .short);
 try modal_components.addTextInput(\feedback_content\, \Your feedback\, .paragraph);
 const built_modal_components = try modal_components.build();

    const response = zignal.interactions.InteractionResponse{
        .type = .modal,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = null,
            .embeds = &[_]zignal.models.Embed{},
            .allowed_mentions = null,
            .flags = null,
            .components = built_modal_components,
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = "feedback_form",
            .title = "📝 Feedback Form",
        },
    };

    ctx.respond(&ctx, response);
}

fn handlePollCommand(ctx: *zignal.interactions.InteractionHandler.SlashCommandHandler.SlashCommandContext) !void {
    const question_value = ctx.get_option("question") orelse return;
    const question = question_value.string;

    // Create poll with voting buttons
    const components = zignal.interactions.InteractionBuilder.ComponentBuilder.init(ctx.allocator)
        .addButton(.primary, "👍 Option A", "poll_vote_a")
        .addButton(.secondary, "👎 Option B", "poll_vote_b")
        .build() catch return;

    const embed = zignal.builders.EmbedBuilder.init(ctx.allocator)
        .title("📊 Poll")
        .description(question)
        .field("Option A", "👍 Vote for this option", true)
        .field("Option B", "👎 Vote for this option", true)
        .colorRgb(255, 255, 0)
        .build() catch return;

    const response = zignal.interactions.InteractionResponse{
        .type = .channel_message_with_source,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = null,
            .embeds = &[_]zignal.models.Embed{embed},
            .allowed_mentions = null,
            .flags = null,
            .components = built_components,
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = null,
            .title = null,
        },
    };

    ctx.respond(&ctx, response);
}

fn handleSearchCommand(ctx: *zignal.interactions.InteractionHandler.SlashCommandHandler.SlashCommandContext) !void {
    const query_value = ctx.get_option("query") orelse return;
    const query = query_value.string;

    const embed = zignal.builders.EmbedBuilder.init(ctx.allocator)
        .title("🔍 Search Results")
        .description(try std.fmt.allocPrint(ctx.allocator, "Searching for: **{s}**", .{query}))
        .field("Result 1", "First search result", false)
        .field("Result 2", "Second search result", false)
        .field("Result 3", "Third search result", false)
        .colorRgb(0, 255, 0)
        .build() catch return;

    const response = zignal.interactions.InteractionResponse{
        .type = .channel_message_with_source,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = null,
            .embeds = &[_]zignal.models.Embed{embed},
            .allowed_mentions = null,
            .flags = null,
            .components = &[_]zignal.interactions.Component{},
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = null,
            .title = null,
        },
    };

    ctx.respond(&ctx, response);
}

fn handleInfoButton(ctx: *zignal.interactions.InteractionHandler.ComponentHandler.ComponentContext) !void {
    const embed = zignal.builders.EmbedBuilder.init(ctx.allocator)
        .title("ℹ️ Bot Information")
        .description("This is an advanced Discord bot demo showcasing:")
        .field("Features", "• Slash commands\n• Buttons\n• Modals\n• Select menus\n• Autocomplete", false)
        .field("Version", "1.0.0", true)
        .field("Library", "Zignal", true)
        .colorRgb(0, 255, 255)
        .build() catch return;

    const response = zignal.interactions.InteractionResponse{
        .type = .update_message,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = null,
            .embeds = &[_]zignal.models.Embed{embed},
            .allowed_mentions = null,
            .flags = null,
            .components = &[_]zignal.interactions.Component{},
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = null,
            .title = null,
        },
    };

    ctx.respond(&ctx, response);
}

fn handleSettingsButton(ctx: *zignal.interactions.InteractionHandler.ComponentHandler.ComponentContext) !void {
    const components = zignal.interactions.InteractionBuilder.ComponentBuilder.init(ctx.allocator)
        .addStringSelect(
            "role_select",
            "Select your role",
            &[_]zignal.interactions.Component.StringSelect.StringSelectOption{
                .{
                    .label = "Developer",
                    .value = "developer",
                    .description = "Access to development tools",
                    .emoji = null,
                    .default = false,
                },
                .{
                    .label = "Moderator",
                    .value = "moderator",
                    .description = "Moderation permissions",
                    .emoji = null,
                    .default = false,
                },
                .{
                    .label = "Member",
                    .value = "member",
                    .description = "Standard member access",
                    .emoji = null,
                    .default = false,
                },
            }
        )
        .build() catch return;

    const embed = zignal.builders.EmbedBuilder.init(ctx.allocator)
        .title("⚙️ Settings")
        .description("Configure your bot preferences:")
        .colorRgb(255, 165, 0)
        .build() catch return;

    const response = zignal.interactions.InteractionResponse{
        .type = .update_message,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = null,
            .embeds = &[_]zignal.models.Embed{embed},
            .allowed_mentions = null,
            .flags = null,
            .components = built_components,
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = null,
            .title = null,
        },
    };

    ctx.respond(&ctx, response);
}

fn handleHelpButton(ctx: *zignal.interactions.InteractionHandler.ComponentHandler.ComponentContext) !void {
    const embed = zignal.builders.EmbedBuilder.init(ctx.allocator)
        .title("❓ Help")
        .description("Available commands:")
        .field("/menu", "Show interactive menu", true)
        .field("/form", "Open feedback form", true)
        .field("/poll <question>", "Create a poll", true)
        .field("/search <query>", "Search with autocomplete", true)
        .field("Features", "• Interactive buttons\n• Modal forms\n• Poll voting\n• Role selection", false)
        .colorRgb(0, 128, 255)
        .build() catch return;

    const response = zignal.interactions.InteractionResponse{
        .type = .update_message,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = null,
            .embeds = &[_]zignal.models.Embed{embed},
            .allowed_mentions = null,
            .flags = null,
            .components = &[_]zignal.interactions.Component{},
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = null,
            .title = null,
        },
    };

    ctx.respond(&ctx, response);
}

fn handlePollVote(ctx: *zignal.interactions.InteractionHandler.ComponentHandler.ComponentContext) !void {
    const component_data = ctx.get_component_data();
    const vote_option = if (std.mem.endsWith(u8, component_data.custom_id, "vote_a")) "Option A" else "Option B";

    const embed = zignal.builders.EmbedBuilder.init(ctx.allocator)
        .title("📊 Vote Recorded")
        .description(try std.fmt.allocPrint(ctx.allocator, "You voted for **{s}**!", .{vote_option}))
        .colorRgb(0, 255, 0)
        .build() catch return;

    const response = zignal.interactions.InteractionResponse{
        .type = .channel_message_with_source,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = null,
            .embeds = &[_]zignal.models.Embed{embed},
            .allowed_mentions = null,
            .flags = 64, // EPHEMERAL
            .components = &[_]zignal.interactions.Component{},
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = null,
            .title = null,
        },
    };

    ctx.respond(&ctx, response);
}

fn handleRoleSelect(ctx: *zignal.interactions.InteractionHandler.ComponentHandler.ComponentContext) !void {
    const component_data = ctx.get_component_data();
    if (component_data.values.len == 0) return;

    const selected_role = component_data.values[0];

    const embed = zignal.builders.EmbedBuilder.init(ctx.allocator)
        .title("⚙️ Role Updated")
        .description(try std.fmt.allocPrint(ctx.allocator, "Your role has been set to **{s}**", .{selected_role}))
        .colorRgb(0, 255, 0)
        .build() catch return;

    const response = zignal.interactions.InteractionResponse{
        .type = .update_message,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = null,
            .embeds = &[_]zignal.models.Embed{embed},
            .allowed_mentions = null,
            .flags = null,
            .components = &[_]zignal.interactions.Component{},
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = null,
            .title = null,
        },
    };

    ctx.respond(&ctx, response);
}

fn handleFeedbackForm(ctx: *zignal.interactions.InteractionHandler.ModalHandler.ModalContext) !void {
    // Get form data
    const title = ctx.get_input_value("feedback_title") orelse "No Title";
    const content = ctx.get_input_value("feedback_content") orelse "No Content";

    const embed = zignal.builders.EmbedBuilder.init(ctx.allocator)
        .title("📝 Feedback Received")
        .description("Thank you for your feedback!")
        .field("Title", title, false)
        .field("Content", content, false)
        .colorRgb(0, 255, 0)
        .build() catch return;

    const response = zignal.interactions.InteractionResponse{
        .type = .channel_message_with_source,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = null,
            .embeds = &[_]zignal.models.Embed{embed},
            .allowed_mentions = null,
            .flags = null,
            .components = &[_]zignal.interactions.Component{},
            .choices = &[_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{},
            .custom_id = null,
            .title = null,
        },
    };

    ctx.respond(&ctx, response);
}

fn handleSearchAutocomplete(ctx: *zignal.interactions.InteractionHandler.AutocompleteContext.AutocompleteContext) !void {
    // Simulate autocomplete suggestions
    const suggestions = [_]zignal.interactions.InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice{
        .{
            .name = "Zignal Documentation",
            .name_localizations = null,
            .value = std.json.Value{ .string = "docs" },
        },
        .{
            .name = "Zignal Examples",
            .name_localizations = null,
            .value = std.json.Value{ .string = "examples" },
        },
        .{
            .name = "Zignal API Reference",
            .name_localizations = null,
            .value = std.json.Value{ .string = "api" },
        },
    };

    ctx.respond(&ctx, zignal.interactions.InteractionResponse{
        .type = .application_command_autocomplete_result,
        .data = zignal.interactions.InteractionResponse.InteractionResponseData{
            .tts = false,
            .content = null,
            .embeds = &[_]zignal.models.Embed{},
            .allowed_mentions = null,
            .flags = null,
            .components = &[_]zignal.interactions.Component{},
            .choices = &suggestions,
            .custom_id = null,
            .title = null,
        },
    });
}

