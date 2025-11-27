const std = @import("std");
const models = @import("../../models.zig");

/// Application command interaction events
pub const ApplicationCommandEvents = struct {
    /// Application command interaction event
    pub const ApplicationCommandInteractionEvent = struct {
        id: u64,
        application_id: u64,
        type: models.InteractionType,
        data: ApplicationCommandInteractionData,
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
        entitlements: ?[]models.Entitlement,
        authorizing_integration_owners: ?std.json.ObjectMap,
        context: ?InteractionContext,
    };

    /// Application command interaction data
    pub const ApplicationCommandInteractionData = struct {
        id: u64,
        name: []const u8,
        type: models.ApplicationCommandType,
        resolved: ?std.json.ObjectMap,
        options: ?[]ApplicationCommandInteractionDataOption,
        guild_id: ?u64,
        target_id: ?u64,
    };

    /// Application command interaction data option
    pub const ApplicationCommandInteractionDataOption = struct {
        name: []const u8,
        type: models.ApplicationCommandOptionType,
        value: ?std.json.Value,
        focused: ?bool,
        options: ?[]ApplicationCommandInteractionDataOption,
    };

    /// Interaction context
    pub const InteractionContext = enum(u8) {
        guild = 0,
        bot_dm = 1,
        private_channel = 2,
    };

    /// Application command permissions update event
    pub const ApplicationCommandPermissionsUpdateEvent = struct {
        application_id: u64,
        guild_id: u64,
        id: u64,
        permissions: []models.ApplicationCommandPermission,
    };
};

/// Event parsers for application command events
pub const ApplicationCommandEventParsers = struct {
    pub fn parseApplicationCommandInteractionEvent(data: []const u8, allocator: std.mem.Allocator) !ApplicationCommandEvents.ApplicationCommandInteractionEvent {
        return try std.json.parseFromSliceLeaky(ApplicationCommandEvents.ApplicationCommandInteractionEvent, allocator, data, .{});
    }

    pub fn parseApplicationCommandPermissionsUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !ApplicationCommandEvents.ApplicationCommandPermissionsUpdateEvent {
        return try std.json.parseFromSliceLeaky(ApplicationCommandEvents.ApplicationCommandPermissionsUpdateEvent, allocator, data, .{});
    }
};

/// Application command event utilities
pub const ApplicationCommandEventUtils = struct {
    pub fn getInteractionType(interaction: ApplicationCommandEvents.ApplicationCommandInteractionEvent) []const u8 {
        return switch (interaction.type) {
            .ping => "Ping",
            .application_command => "Application Command",
            .message_component => "Message Component",
            .application_command_autocomplete => "Application Command Autocomplete",
            .modal_submit => "Modal Submit",
        };
    }

    pub fn getCommandType(data: ApplicationCommandEvents.ApplicationCommandInteractionData) []const u8 {
        return switch (data.type) {
            .chat_input => "Slash Command",
            .user => "User Command",
            .message => "Message Command",
        };
    }

    pub fn getOptionValue(option: ApplicationCommandEvents.ApplicationCommandInteractionDataOption) ?std.json.Value {
        return option.value;
    }

    pub fn getOptionString(option: ApplicationCommandEvents.ApplicationCommandInteractionDataOption) ?[]const u8 {
        if (option.value) |value| {
            if (value == .string) {
                return value.string;
            }
        }
        return null;
    }

    pub fn getOptionInt(option: ApplicationCommandEvents.ApplicationCommandInteractionDataOption) ?i64 {
        if (option.value) |value| {
            if (value == .integer) {
                return value.integer;
            }
        }
        return null;
    }

    pub fn getOptionBool(option: ApplicationCommandEvents.ApplicationCommandInteractionDataOption) ?bool {
        if (option.value) |value| {
            if (value == .bool) {
                return value.bool;
            }
        }
        return null;
    }

    pub fn getOptionFloat(option: ApplicationCommandEvents.ApplicationCommandInteractionDataOption) ?f64 {
        if (option.value) |value| {
            if (value == .float) {
                return value.float;
            }
        }
        return null;
    }

    pub fn findOptionByName(
        data: ApplicationCommandEvents.ApplicationCommandInteractionData,
        name: []const u8,
    ) ?ApplicationCommandEvents.ApplicationCommandInteractionDataOption {
        if (data.options) |options| {
            for (options) |option| {
                if (std.mem.eql(u8, option.name, name)) {
                    return option;
                }
            }
        }
        return null;
    }

    pub fn getAllOptionsByName(
        data: ApplicationCommandEvents.ApplicationCommandInteractionData,
        name: []const u8,
    ) ?[]ApplicationCommandEvents.ApplicationCommandInteractionDataOption {
        var found_options = std.ArrayList(ApplicationCommandEvents.ApplicationCommandInteractionDataOption).init(std.heap.page_allocator);
        defer found_options.deinit();

        if (data.options) |options| {
            for (options) |option| {
                if (std.mem.eql(u8, option.name, name)) {
                    found_options.append(option) catch return null;
                }
            }
        }

        if (found_options.items.len > 0) {
            return found_options.toOwnedSlice() catch null;
        }
        return null;
    }

    pub fn formatInteractionSummary(interaction: ApplicationCommandEvents.ApplicationCommandInteractionEvent) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Interaction: ");
        try summary.appendSlice(getInteractionType(interaction));

        if (interaction.data.name.len > 0) {
            try summary.appendSlice(" - Command: /");
            try summary.appendSlice(interaction.data.name);
        }

        if (interaction.guild_id) |guild_id| {
            try summary.appendSlice(" - Guild: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{guild_id}));
        }

        if (interaction.channel_id) |channel_id| {
            try summary.appendSlice(" - Channel: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{channel_id}));
        }

        if (interaction.user) |user| {
            try summary.appendSlice(" - User: ");
            try summary.appendSlice(user.username);
        } else if (interaction.member) |member| {
            try summary.appendSlice(" - Member: ");
            try summary.appendSlice(member.user.username);
        }

        return summary.toOwnedSlice();
    }

    pub fn validateInteraction(interaction: ApplicationCommandEvents.ApplicationCommandInteractionEvent) bool {
        // Basic validation checks
        if (interaction.id == 0) return false;
        if (interaction.application_id == 0) return false;
        if (interaction.token.len == 0) return false;
        if (interaction.version == 0) return false;

        // Validate interaction type
        switch (interaction.type) {
            .ping => {},
            .application_command => {
                if (interaction.data.name.len == 0) return false;
                if (interaction.data.id == 0) return false;
            },
            .message_component => {},
            .application_command_autocomplete => {
                if (interaction.data.name.len == 0) return false;
                if (interaction.data.id == 0) return false;
            },
            .modal_submit => {},
        }

        return true;
    }

    pub fn getInteractionContext(interaction: ApplicationCommandEvents.ApplicationCommandInteractionEvent) []const u8 {
        if (interaction.guild_id != null) {
            return "Guild";
        }
        if (interaction.user != null) {
            return "DM";
        }
        return "Unknown";
    }

    pub fn hasUserPermissions(interaction: ApplicationCommandEvents.ApplicationCommandInteractionEvent, permission: []const u8) bool {
        if (interaction.app_permissions) |permissions| {
            // This would require parsing the permission string
            // For now, return true as a placeholder
            return true;
        }
        return false;
    }

    pub fn isFromGuild(interaction: ApplicationCommandEvents.ApplicationCommandInteractionEvent) bool {
        return interaction.guild_id != null;
    }

    pub fn isFromDM(interaction: ApplicationCommandEvents.ApplicationCommandInteractionEvent) bool {
        return interaction.guild_id == null and interaction.user != null;
    }

    pub fn getTargetUser(interaction: ApplicationCommandEvents.ApplicationCommandInteractionEvent) ?u64 {
        if (interaction.user) |user| {
            return user.id;
        }
        if (interaction.member) |member| {
            return member.user.id;
        }
        return null;
    }

    pub fn getTargetChannel(interaction: ApplicationCommandEvents.ApplicationCommandInteractionEvent) ?u64 {
        return interaction.channel_id;
    }

    pub fn getTargetGuild(interaction: ApplicationCommandEvents.ApplicationCommandInteractionEvent) ?u64 {
        return interaction.guild_id;
    }
};
