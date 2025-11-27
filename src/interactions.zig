const std = @import("std");
const models = @import("models.zig");

/// Interaction types with proper enum definitions
pub const InteractionType = enum(u8) {
    ping = 1,
    application_command = 2,
    message_component = 3,
    application_command_autocomplete = 4,
    modal_submit = 5,
};

/// Component types for message components
pub const ComponentType = enum(u8) {
    action_row = 1,
    button = 2,
    string_select = 3,
    user_select = 4,
    role_select = 5,
    mentionable_select = 6,
    channel_select = 7,
    text_input = 4,
};

/// Button styles with proper color coding
pub const ButtonStyle = enum(u8) {
    primary = 1,    // Blue
    secondary = 2,  // Gray
    success = 3,    // Green
    danger = 4,     // Red
    link = 5,       // Gray with link icon
};

/// Text input styles for modals
pub const TextInputStyle = enum(u8) {
    short = 1,
    paragraph = 2,
};

/// Application command types
pub const ApplicationCommandType = enum(u8) {
    slash = 1,
    user = 2,
    message = 3,
};

/// Permission types for application commands
pub const ApplicationCommandPermissionType = enum(u8) {
    role = 1,
    user = 2,
    channel = 3,
};

/// Base interaction structure with proper memory management
pub const Interaction = struct {
    id: u64,
    application_id: u64,
    type: InteractionType,
    data: ?InteractionData,
    guild_id: ?u64,
    channel_id: ?u64,
    member: ?models.GuildMember,
    user: ?models.User,
    token: []const u8,
    version: u8,
    message: ?models.Message,
    app_permissions: ?[]const u8,
    locale: ?[]const u8,
    guild_locale: ?[]const u8,
    entitlements: []models.Entitlement,
    authorizing_integration_owners: AuthorizingIntegrationOwners,
    context: ?InteractionContext,

    pub const AuthorizingIntegrationOwners = struct {
        user: ?u64,
        application: ?u64,
    };

    pub const InteractionContext = enum(u8) {
        guild = 0,
        bot_dm = 1,
        private_channel = 2,
    };

    pub fn deinit(self: Interaction, allocator: std.mem.Allocator) void {
        if (self.data) |data| data.deinit(allocator);
        if (self.member) |_| {
            // Member deinit would be handled by models
        }
        if (self.user) |_| {
            // User deinit would be handled by models
        }
        allocator.free(self.token);
        if (self.app_permissions) |ap| allocator.free(ap);
        if (self.locale) |l| allocator.free(l);
        if (self.guild_locale) |gl| allocator.free(gl);
        allocator.free(self.entitlements);
    }
};

/// Interaction data variants with proper type safety
pub const InteractionData = union(InteractionType) {
    ping: void,
    application_command: ApplicationCommandInteractionData,
    message_component: MessageComponentInteractionData,
    application_command_autocomplete: AutocompleteInteractionData,
    modal_submit: ModalSubmitInteractionData,

    pub const ApplicationCommandInteractionData = struct {
        id: u64,
        name: []const u8,
        type: ApplicationCommandType,
        resolved: ?ResolvedData,
        options: []ApplicationCommandOption,
        guild_id: ?u64,
        target_id: ?u64,

        pub const ResolvedData = struct {
            users: std.json.ObjectMap,
            members: std.json.ObjectMap,
            roles: std.json.ObjectMap,
            channels: std.json.ObjectMap,
            messages: std.json.ObjectMap,
            attachments: std.json.ObjectMap,
        };

        pub const ApplicationCommandOption = struct {
            name: []const u8,
            type: ApplicationCommandOptionType,
            value: ?std.json.Value,
            focused: bool,
        };

        pub const ApplicationCommandOptionType = enum(u8) {
            sub_command = 1,
            sub_command_group = 2,
            string = 3,
            integer = 4,
            boolean = 5,
            user = 6,
            channel = 7,
            role = 8,
            mentionable = 9,
            number = 10,
            attachment = 11,
        };
    };

    pub const MessageComponentInteractionData = struct {
        custom_id: []const u8,
        component_type: ComponentType,
        values: [][]const u8,
        resolved: ?ResolvedData,

        pub const ResolvedData = struct {
            users: std.json.ObjectMap,
            members: std.json.ObjectMap,
            roles: std.json.ObjectMap,
            channels: std.json.ObjectMap,
            messages: std.json.ObjectMap,
        };
    };

    pub const AutocompleteInteractionData = struct {
        id: u64,
        name: []const u8,
        type: ApplicationCommandType,
        options: []InteractionData.ApplicationCommandInteractionData.ApplicationCommandOption,
        guild_id: ?u64,
        target_id: ?u64,
    };

    pub const ModalSubmitInteractionData = struct {
        custom_id: []const u8,
        components: []ActionRow,
    };

    pub fn deinit(self: InteractionData, allocator: std.mem.Allocator) void {
        switch (self) {
            .ping => {},
            .application_command => |data| {
                allocator.free(data.name);
                allocator.free(data.options);
                if (data.resolved) |*resolved| {
                    resolved.users.deinit();
                    resolved.members.deinit();
                    resolved.roles.deinit();
                    resolved.channels.deinit();
                    resolved.messages.deinit();
                    resolved.attachments.deinit();
                }
            },
            .message_component => |data| {
                allocator.free(data.custom_id);
                allocator.free(data.values);
                if (data.resolved) |*resolved| {
                    resolved.users.deinit();
                    resolved.members.deinit();
                    resolved.roles.deinit();
                    resolved.channels.deinit();
                    resolved.messages.deinit();
                }
            },
            .application_command_autocomplete => |data| {
                allocator.free(data.name);
                allocator.free(data.options);
            },
            .modal_submit => |data| {
                allocator.free(data.custom_id);
                allocator.free(data.components);
            },
        }
    }
};

/// Action row component for organizing other components
pub const ActionRow = struct {
    type: ComponentType = .action_row,
    components: []Component,

    pub fn deinit(self: ActionRow, allocator: std.mem.Allocator) void {
        for (self.components) |*component| {
            component.deinit(allocator);
        }
        allocator.free(self.components);
    }
};

/// Component variants with proper type safety
pub const Component = union(ComponentType) {
    action_row: ActionRow,
    button: Button,
    string_select: StringSelect,
    user_select: UserSelect,
    role_select: RoleSelect,
    mentionable_select: MentionableSelect,
    channel_select: ChannelSelect,
    text_input: TextInput,

    pub const Button = struct {
        type: ComponentType = .button,
        style: ButtonStyle,
        label: ?[]const u8,
        emoji: ?models.Emoji,
        custom_id: ?[]const u8,
        url: ?[]const u8,
        disabled: bool = false,

        pub fn deinit(self: Button, allocator: std.mem.Allocator) void {
            if (self.label) |label| allocator.free(label);
            if (self.custom_id) |custom_id| allocator.free(custom_id);
            if (self.url) |url| allocator.free(url);
            if (self.emoji) |_| {
                // Emoji deinit would be handled by models
            }
        }
    };

    pub const StringSelect = struct {
        type: ComponentType = .string_select,
        custom_id: []const u8,
        placeholder: ?[]const u8,
        min_values: ?i32,
        max_values: ?i32,
        disabled: bool = false,
        options: []StringSelectOption,

        pub const StringSelectOption = struct {
            label: []const u8,
            value: []const u8,
            description: ?[]const u8,
            emoji: ?models.Emoji,
            default: bool = false,

            pub fn deinit(self: StringSelectOption, allocator: std.mem.Allocator) void {
                allocator.free(self.label);
                allocator.free(self.value);
                if (self.description) |desc| allocator.free(desc);
                if (self.emoji) |_| {
                    // Emoji deinit would be handled by models
                }
            }
        };

        pub fn deinit(self: StringSelect, allocator: std.mem.Allocator) void {
            allocator.free(self.custom_id);
            if (self.placeholder) |ph| allocator.free(ph);
            for (self.options) |*option| {
                option.deinit(allocator);
            }
            allocator.free(self.options);
        }
    };

    pub const UserSelect = struct {
        type: ComponentType = .user_select,
        custom_id: []const u8,
        placeholder: ?[]const u8,
        min_values: ?i32,
        max_values: ?i32,
        disabled: bool = false,
        default_values: []DefaultValue,

        pub const DefaultValue = struct {
            id: u64,
            type: ApplicationCommandPermissionType,
        };

        pub fn deinit(self: UserSelect, allocator: std.mem.Allocator) void {
            allocator.free(self.custom_id);
            if (self.placeholder) |ph| allocator.free(ph);
            allocator.free(self.default_values);
        }
    };

    pub const RoleSelect = struct {
        type: ComponentType = .role_select,
        custom_id: []const u8,
        placeholder: ?[]const u8,
        min_values: ?i32,
        max_values: ?i32,
        disabled: bool = false,
        default_values: []DefaultValue,

        pub const DefaultValue = struct {
            id: u64,
            type: ApplicationCommandPermissionType,
        };

        pub fn deinit(self: RoleSelect, allocator: std.mem.Allocator) void {
            allocator.free(self.custom_id);
            if (self.placeholder) |ph| allocator.free(ph);
            allocator.free(self.default_values);
        }
    };

    pub const MentionableSelect = struct {
        type: ComponentType = .mentionable_select,
        custom_id: []const u8,
        placeholder: ?[]const u8,
        min_values: ?i32,
        max_values: ?i32,
        disabled: bool = false,
        default_values: []DefaultValue,

        pub const DefaultValue = struct {
            id: u64,
            type: ApplicationCommandPermissionType,
        };

        pub fn deinit(self: MentionableSelect, allocator: std.mem.Allocator) void {
            allocator.free(self.custom_id);
            if (self.placeholder) |ph| allocator.free(ph);
            allocator.free(self.default_values);
        }
    };

    pub const ChannelSelect = struct {
        type: ComponentType = .channel_select,
        custom_id: []const u8,
        placeholder: ?[]const u8,
        min_values: ?i32,
        max_values: ?i32,
        disabled: bool = false,
        default_values: []DefaultValue,
        channel_types: []u64,

        pub const DefaultValue = struct {
            id: u64,
            type: ApplicationCommandPermissionType,
        };

        pub fn deinit(self: ChannelSelect, allocator: std.mem.Allocator) void {
            allocator.free(self.custom_id);
            if (self.placeholder) |ph| allocator.free(ph);
            allocator.free(self.default_values);
            allocator.free(self.channel_types);
        }
    };

    pub const TextInput = struct {
        type: ComponentType = .text_input,
        custom_id: []const u8,
        style: TextInputStyle,
        label: []const u8,
        placeholder: ?[]const u8,
        min_length: ?i32,
        max_length: ?i32,
        required: bool = true,
        value: ?[]const u8,

        pub fn deinit(self: TextInput, allocator: std.mem.Allocator) void {
            allocator.free(self.custom_id);
            allocator.free(self.label);
            if (self.placeholder) |ph| allocator.free(ph);
            if (self.value) |val| allocator.free(val);
        }
    };

    pub fn deinit(self: Component, allocator: std.mem.Allocator) void {
        switch (self) {
            .action_row => |*action_row| action_row.deinit(allocator),
            .button => |*button| button.deinit(allocator),
            .string_select => |*string_select| string_select.deinit(allocator),
            .user_select => |*user_select| user_select.deinit(allocator),
            .role_select => |*role_select| role_select.deinit(allocator),
            .mentionable_select => |*mentionable_select| mentionable_select.deinit(allocator),
            .channel_select => |*channel_select| channel_select.deinit(allocator),
            .text_input => |*text_input| text_input.deinit(allocator),
        }
    }
};

/// Application command structure for slash commands
pub const ApplicationCommand = struct {
    id: u64,
    application_id: u64,
    name: []const u8,
    name_localizations: ?std.json.ObjectMap,
    description: []const u8,
    description_localizations: ?std.json.ObjectMap,
    options: []ApplicationCommandOption,
    default_member_permissions: ?[]const u8,
    dm_permission: bool,
    default_member_permissions_int: ?u64,
    version: u64,
    type: ApplicationCommandType,
    nsfw: bool,
    integration_types: []u64,
    contexts: []u64,

    pub const ApplicationCommandOption = struct {
        type: ApplicationCommandOptionType,
        name: []const u8,
        name_localizations: ?std.json.ObjectMap,
        description: []const u8,
        description_localizations: ?std.json.ObjectMap,
        required: bool,
        choices: []ApplicationCommandOptionChoice,
        options: []ApplicationCommandOption,
        channel_types: []u64,
        min_value: ?std.json.Value,
        max_value: ?std.json.Value,
        autocomplete: bool,

        pub const ApplicationCommandOptionChoice = struct {
            name: []const u8,
            name_localizations: ?std.json.ObjectMap,
            value: std.json.Value,
        };
    };

    pub const ApplicationCommandOptionType = enum(u8) {
        sub_command = 1,
        sub_command_group = 2,
        string = 3,
        integer = 4,
        boolean = 5,
        user = 6,
        channel = 7,
        role = 8,
        mentionable = 9,
        number = 10,
        attachment = 11,
    };

    pub fn deinit(self: ApplicationCommand, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        if (self.name_localizations) |nl| nl.deinit();
        allocator.free(self.description);
        if (self.description_localizations) |dl| dl.deinit();
        allocator.free(self.options);
        if (self.default_member_permissions) |dmp| allocator.free(dmp);
        allocator.free(self.integration_types);
        allocator.free(self.contexts);
    }
};

/// Interaction response types
pub const InteractionResponseType = enum(u8) {
    pong = 1,
    channel_message_with_source = 4,
    deferred_channel_message_with_source = 5,
    deferred_update_message = 6,
    update_message = 7,
    application_command_autocomplete_result = 8,
    modal = 9,
};

/// Interaction response structure
pub const InteractionResponse = struct {
    type: InteractionResponseType,
    data: ?InteractionResponseData,

    pub const InteractionResponseData = struct {
        tts: bool,
        content: ?[]const u8,
        embeds: []models.Embed,
        allowed_mentions: ?models.AllowedMentions,
        flags: ?u64,
        components: []Component,
        choices: []ApplicationCommandOptionChoice,
        custom_id: ?[]const u8,
        title: ?[]const u8,

        pub const ApplicationCommandOptionChoice = struct {
            name: []const u8,
            name_localizations: ?std.json.ObjectMap,
            value: std.json.Value,
        };
    };

    pub fn deinit(self: InteractionResponse, allocator: std.mem.Allocator) void {
        if (self.data) |*data| {
            if (data.content) |content| allocator.free(content);
            allocator.free(data.embeds);
            if (data.allowed_mentions) |_| {
                // AllowedMentions deinit would be handled by models
            }
            allocator.free(data.components);
            allocator.free(data.choices);
            if (data.custom_id) |custom_id| allocator.free(custom_id);
            if (data.title) |title| allocator.free(title);
        }
    }
};

/// Interaction handler interface for type-safe event handling
pub const InteractionHandler = struct {
    allocator: std.mem.Allocator,
    slash_commands: std.hash_map.StringHashMap(*SlashCommandHandler),
    component_handlers: std.hash_map.StringHashMap(*ComponentHandler),
    modal_handlers: std.hash_map.StringHashMap(*ModalHandler),
    autocomplete_handlers: std.hash_map.StringHashMap(*AutocompleteHandler),

    pub const SlashCommandHandler = struct {
        name: []const u8,
        description: []const u8,
        options: []ApplicationCommand.ApplicationCommandOption,
        execute: *const fn (ctx: *SlashCommandContext) anyerror!void,

        pub const SlashCommandContext = struct {
            interaction: Interaction,
            allocator: std.mem.Allocator,
            respond: *const fn (ctx: *SlashCommandContext, response: InteractionResponse) anyerror!void,
            defer_response: *const fn (ctx: *SlashCommandContext) anyerror!void,
            get_option: *const fn (ctx: *SlashCommandContext, name: []const u8) ?std.json.Value,
        };
    };

    pub const ComponentHandler = struct {
        custom_id: []const u8,
        execute: *const fn (ctx: *ComponentContext) anyerror!void,

        pub const ComponentContext = struct {
            interaction: Interaction,
            allocator: std.mem.Allocator,
            respond: *const fn (ctx: *ComponentContext, response: InteractionResponse) anyerror!void,
            defer_response: *const fn (ctx: *ComponentContext) anyerror!void,
            get_component_data: *const fn (ctx: *ComponentContext) InteractionData.MessageComponentInteractionData,
        };
    };

    pub const ModalHandler = struct {
        custom_id: []const u8,
        execute: *const fn (ctx: *ModalContext) anyerror!void,

        pub const ModalContext = struct {
            interaction: Interaction,
            allocator: std.mem.Allocator,
            respond: *const fn (ctx: *ModalContext, response: InteractionResponse) anyerror!void,
            defer_response: *const fn (ctx: *ModalContext) anyerror!void,
            get_input_value: *const fn (ctx: *ModalContext, custom_id: []const u8) ?[]const u8,
        };
    };

    pub const AutocompleteHandler = struct {
        command_name: []const u8,
        option_name: []const u8,
        execute: *const fn (ctx: *AutocompleteContext) anyerror!void,

        pub const AutocompleteContext = struct {
            interaction: Interaction,
            allocator: std.mem.Allocator,
            respond: *const fn (ctx: *AutocompleteContext, choices: []InteractionResponse.InteractionResponseData.ApplicationCommandOptionChoice) anyerror!void,
            get_focused_option: *const fn (ctx: *AutocompleteContext) ?InteractionData.ApplicationCommandInteractionData.ApplicationCommandOption,
        };
    };

    pub fn init(allocator: std.mem.Allocator) InteractionHandler {
        return InteractionHandler{
            .allocator = allocator,
            .slash_commands = std.hash_map.StringHashMap(*SlashCommandHandler).init(allocator),
            .component_handlers = std.hash_map.StringHashMap(*ComponentHandler).init(allocator),
            .modal_handlers = std.hash_map.StringHashMap(*ModalHandler).init(allocator),
            .autocomplete_handlers = std.hash_map.StringHashMap(*AutocompleteHandler).init(allocator),
        };
    }

    pub fn deinit(self: *InteractionHandler) void {
        var iter = self.slash_commands.iterator();
        while (iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.destroy(entry.value_ptr.*);
        }
        self.slash_commands.deinit();

        iter = self.component_handlers.iterator();
        while (iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.destroy(entry.value_ptr.*);
        }
        self.component_handlers.deinit();

        iter = self.modal_handlers.iterator();
        while (iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.destroy(entry.value_ptr.*);
        }
        self.modal_handlers.deinit();

        iter = self.autocomplete_handlers.iterator();
        while (iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.destroy(entry.value_ptr.*);
        }
        self.autocomplete_handlers.deinit();
    }

    pub fn registerSlashCommand(self: *InteractionHandler, handler: *SlashCommandHandler) !void {
        const name = try self.allocator.dupe(u8, handler.name);
        try self.slash_commands.put(name, handler);
    }

    pub fn registerComponentHandler(self: *InteractionHandler, handler: *ComponentHandler) !void {
        const custom_id = try self.allocator.dupe(u8, handler.custom_id);
        try self.component_handlers.put(custom_id, handler);
    }

    pub fn registerModalHandler(self: *InteractionHandler, handler: *ModalHandler) !void {
        const custom_id = try self.allocator.dupe(u8, handler.custom_id);
        try self.modal_handlers.put(custom_id, handler);
    }

    pub fn registerAutocompleteHandler(self: *InteractionHandler, handler: *AutocompleteHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}:{s}", .{ handler.command_name, handler.option_name });
        try self.autocomplete_handlers.put(key, handler);
    }

    pub fn handleInteraction(self: *InteractionHandler, interaction: Interaction) !void {
        switch (interaction.type) {
            .application_command => {
                if (interaction.data) |data| {
                    const command_data = data.application_command;
                    if (self.slash_commands.get(command_data.name)) |handler| {
                        const ctx = SlashCommandHandler.SlashCommandContext{
                            .interaction = interaction,
                            .allocator = self.allocator,
                            .respond = undefined, // Would be implemented
                            .defer_response = undefined, // Would be implemented
                            .get_option = undefined, // Would be implemented
                        };
                        try handler.execute(&ctx);
                    }
                }
            },
            .message_component => {
                if (interaction.data) |data| {
                    const component_data = data.message_component;
                    if (self.component_handlers.get(component_data.custom_id)) |handler| {
                        const ctx = ComponentHandler.ComponentContext{
                            .interaction = interaction,
                            .allocator = self.allocator,
                            .respond = undefined, // Would be implemented
                            .defer_response = undefined, // Would be implemented
                            .get_component_data = undefined, // Would be implemented
                        };
                        try handler.execute(&ctx);
                    }
                }
            },
            .modal_submit => {
                if (interaction.data) |data| {
                    const modal_data = data.modal_submit;
                    if (self.modal_handlers.get(modal_data.custom_id)) |handler| {
                        const ctx = ModalHandler.ModalContext{
                            .interaction = interaction,
                            .allocator = self.allocator,
                            .respond = undefined, // Would be implemented
                            .defer_response = undefined, // Would be implemented
                            .get_input_value = undefined, // Would be implemented
                        };
                        try handler.execute(&ctx);
                    }
                }
            },
            .application_command_autocomplete => {
                if (interaction.data) |data| {
                    const autocomplete_data = data.application_command_autocomplete;
                    const key = try std.fmt.allocPrint(self.allocator, "{s}:{s}", .{ autocomplete_data.name, "focused_option" });
                    defer self.allocator.free(key);
                    if (self.autocomplete_handlers.get(key)) |handler| {
                        const ctx = AutocompleteHandler.AutocompleteContext{
                            .interaction = interaction,
                            .allocator = self.allocator,
                            .respond = undefined, // Would be implemented
                            .get_focused_option = undefined, // Would be implemented
                        };
                        try handler.execute(&ctx);
                    }
                }
            },
            .ping => {
                // Handle ping interaction
            },
        }
    }
};

/// Fluent builders for creating interactions with clean API
pub const InteractionBuilder = struct {
    pub const SlashCommandBuilder = struct {
        name: []const u8,
        description: []const u8,
        options: std.ArrayList(ApplicationCommand.ApplicationCommandOption),
        default_member_permissions: ?[]const u8 = null,
        dm_permission: bool = true,
        nsfw: bool = false,

        pub fn init(allocator: std.mem.Allocator, name: []const u8, description: []const u8) SlashCommandBuilder {
            return SlashCommandBuilder{
                .name = name,
                .description = description,
                .options = std.ArrayList(ApplicationCommand.ApplicationCommandOption).init(allocator),
            };
        }

        pub fn addOption(self: *SlashCommandBuilder, option: ApplicationCommand.ApplicationCommandOption) !*SlashCommandBuilder {
            try self.options.append(option);
            return self;
        }

        pub fn setDefaultPermissions(self: *SlashCommandBuilder, permissions: []const u8) *SlashCommandBuilder {
            self.default_member_permissions = permissions;
            return self;
        }

        pub fn setDmPermission(self: *SlashCommandBuilder, allowed: bool) *SlashCommandBuilder {
            self.dm_permission = allowed;
            return self;
        }

        pub fn setNsfw(self: *SlashCommandBuilder, nsfw: bool) *SlashCommandBuilder {
            self.nsfw = nsfw;
            return self;
        }

        pub fn build(self: *SlashCommandBuilder, allocator: std.mem.Allocator) !ApplicationCommand {
            return ApplicationCommand{
                .id = 0, // Would be assigned by Discord
                .application_id = 0, // Would be assigned by Discord
                .name = try allocator.dupe(u8, self.name),
                .name_localizations = null,
                .description = try allocator.dupe(u8, self.description),
                .description_localizations = null,
                .options = try allocator.dupe(ApplicationCommand.ApplicationCommandOption, self.options.items),
                .default_member_permissions = if (self.default_member_permissions) |dmp| try allocator.dupe(u8, dmp) else null,
                .dm_permission = self.dm_permission,
                .default_member_permissions_int = null,
                .version = 0, // Would be assigned by Discord
                .type = .slash,
                .nsfw = self.nsfw,
                .integration_types = &[_]u64{},
                .contexts = &[_]u64{},
            };
        }
    };

    pub const ComponentBuilder = struct {
        allocator: std.mem.Allocator,
        components: std.ArrayList(Component),

        pub fn init(allocator: std.mem.Allocator) ComponentBuilder {
            return ComponentBuilder{
                .allocator = allocator,
                .components = std.ArrayList(Component).init(allocator),
            };
        }

        pub fn addButton(self: *ComponentBuilder, style: ButtonStyle, label: []const u8, custom_id: []const u8) !*ComponentBuilder {
            const button = Component{
                .button = Component.Button{
                    .style = style,
                    .label = try self.allocator.dupe(u8, label),
                    .emoji = null,
                    .custom_id = try self.allocator.dupe(u8, custom_id),
                    .url = null,
                    .disabled = false,
                },
            };
            try self.components.append(button);
            return self;
        }

        pub fn addLinkButton(self: *ComponentBuilder, label: []const u8, url: []const u8) !*ComponentBuilder {
            const button = Component{
                .button = Component.Button{
                    .style = .link,
                    .label = try self.allocator.dupe(u8, label),
                    .emoji = null,
                    .custom_id = null,
                    .url = try self.allocator.dupe(u8, url),
                    .disabled = false,
                },
            };
            try self.components.append(button);
            return self;
        }

        pub fn addStringSelect(self: *ComponentBuilder, custom_id: []const u8, placeholder: ?[]const u8, options: []Component.StringSelect.StringSelectOption) !*ComponentBuilder {
            const select = Component{
                .string_select = Component.StringSelect{
                    .custom_id = try self.allocator.dupe(u8, custom_id),
                    .placeholder = if (placeholder) |ph| try self.allocator.dupe(u8, ph) else null,
                    .min_values = null,
                    .max_values = null,
                    .disabled = false,
                    .options = try self.allocator.dupe(Component.StringSelect.StringSelectOption, options),
                },
            };
            try self.components.append(select);
            return self;
        }

        pub fn addTextInput(self: *ComponentBuilder, custom_id: []const u8, label: []const u8, style: TextInputStyle) !*ComponentBuilder {
            const text_input = Component{
                .text_input = Component.TextInput{
                    .custom_id = try self.allocator.dupe(u8, custom_id),
                    .style = style,
                    .label = try self.allocator.dupe(u8, label),
                    .placeholder = null,
                    .min_length = null,
                    .max_length = null,
                    .required = true,
                    .value = null,
                },
            };
            try self.components.append(text_input);
            return self;
        }

        pub fn build(self: *ComponentBuilder) ![]ActionRow {
            var rows = std.ArrayList(ActionRow).init(self.allocator);
            defer rows.deinit();

            var current_row = std.ArrayList(Component).init(self.allocator);
            defer current_row.deinit();

            for (self.components.items) |component| {
                // Action rows can have max 5 components (except text inputs in modals)
                if (current_row.items.len >= 5) {
                    const row = ActionRow{
                        .type = .action_row,
                        .components = try self.allocator.dupe(Component, current_row.items),
                    };
                    try rows.append(row);
                    current_row.clear();
                }
                try current_row.append(component);
            }

            if (current_row.items.len > 0) {
                const row = ActionRow{
                    .type = .action_row,
                    .components = try self.allocator.dupe(Component, current_row.items),
                };
                try rows.append(row);
            }

            return rows.toOwnedSlice();
        }
    };
};
