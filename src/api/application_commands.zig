const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Application command management for slash commands and interactions
pub const ApplicationCommandManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) ApplicationCommandManager {
        return ApplicationCommandManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get global application commands
    pub fn getGlobalApplicationCommands(self: *ApplicationCommandManager) ![]models.ApplicationCommand {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/commands",
            .{ self.client.base_url, self.client.application_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.ApplicationCommand, response.body, .{});
    }

    /// Create a global application command
    pub fn createGlobalApplicationCommand(
        self: *ApplicationCommandManager,
        name: []const u8,
        description: []const u8,
        options: ?[]models.ApplicationCommandOption,
        default_member_permissions: ?[]const u8,
        dm_permission: ?bool,
    ) !models.ApplicationCommand {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/commands",
            .{ self.client.base_url, self.client.application_id },
        );
        defer self.allocator.free(url);

        const payload = CreateApplicationCommandPayload{
            .name = name,
            .description = description,
            .options = options orelse &[_]models.ApplicationCommandOption{},
            .default_member_permissions = default_member_permissions,
            .dm_permission = dm_permission,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ApplicationCommand, response.body, .{});
    }

    /// Get a global application command
    pub fn getGlobalApplicationCommand(
        self: *ApplicationCommandManager,
        command_id: u64,
    ) !models.ApplicationCommand {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/commands/{d}",
            .{ self.client.base_url, self.client.application_id, command_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ApplicationCommand, response.body, .{});
    }

    /// Edit a global application command
    pub fn editGlobalApplicationCommand(
        self: *ApplicationCommandManager,
        command_id: u64,
        name: ?[]const u8,
        description: ?[]const u8,
        options: ?[]models.ApplicationCommandOption,
        default_member_permissions: ?[]const u8,
        dm_permission: ?bool,
    ) !models.ApplicationCommand {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/commands/{d}",
            .{ self.client.base_url, self.client.application_id, command_id },
        );
        defer self.allocator.free(url);

        const payload = EditApplicationCommandPayload{
            .name = name,
            .description = description,
            .options = options,
            .default_member_permissions = default_member_permissions,
            .dm_permission = dm_permission,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ApplicationCommand, response.body, .{});
    }

    /// Delete a global application command
    pub fn deleteGlobalApplicationCommand(
        self: *ApplicationCommandManager,
        command_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/commands/{d}",
            .{ self.client.base_url, self.client.application_id, command_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Bulk overwrite global application commands
    pub fn bulkOverwriteGlobalApplicationCommands(
        self: *ApplicationCommandManager,
        commands: []models.ApplicationCommand,
    ) ![]models.ApplicationCommand {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/commands",
            .{ self.client.base_url, self.client.application_id },
        );
        defer self.allocator.free(url);

        const json_payload = try std.json.stringifyAlloc(self.allocator, commands, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.put(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.ApplicationCommand, response.body, .{});
    }

    /// Get guild application commands
    pub fn getGuildApplicationCommands(
        self: *ApplicationCommandManager,
        guild_id: u64,
    ) ![]models.ApplicationCommand {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/guilds/{d}/commands",
            .{ self.client.base_url, self.client.application_id, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.ApplicationCommand, response.body, .{});
    }

    /// Create a guild application command
    pub fn createGuildApplicationCommand(
        self: *ApplicationCommandManager,
        guild_id: u64,
        name: []const u8,
        description: []const u8,
        options: ?[]models.ApplicationCommandOption,
        default_member_permissions: ?[]const u8,
    ) !models.ApplicationCommand {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/guilds/{d}/commands",
            .{ self.client.base_url, self.client.application_id, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreateApplicationCommandPayload{
            .name = name,
            .description = description,
            .options = options orelse &[_]models.ApplicationCommandOption{},
            .default_member_permissions = default_member_permissions,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ApplicationCommand, response.body, .{});
    }

    /// Edit a guild application command
    pub fn editGuildApplicationCommand(
        self: *ApplicationCommandManager,
        guild_id: u64,
        command_id: u64,
        name: ?[]const u8,
        description: ?[]const u8,
        options: ?[]models.ApplicationCommandOption,
        default_member_permissions: ?[]const u8,
    ) !models.ApplicationCommand {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/guilds/{d}/commands/{d}",
            .{ self.client.base_url, self.client.application_id, guild_id, command_id },
        );
        defer self.allocator.free(url);

        const payload = EditApplicationCommandPayload{
            .name = name,
            .description = description,
            .options = options,
            .default_member_permissions = default_member_permissions,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ApplicationCommand, response.body, .{});
    }

    /// Delete a guild application command
    pub fn deleteGuildApplicationCommand(
        self: *ApplicationCommandManager,
        guild_id: u64,
        command_id: u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/guilds/{d}/commands/{d}",
            .{ self.client.base_url, self.client.application_id, guild_id, command_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Bulk overwrite guild application commands
    pub fn bulkOverwriteGuildApplicationCommands(
        self: *ApplicationCommandManager,
        guild_id: u64,
        commands: []models.ApplicationCommand,
    ) ![]models.ApplicationCommand {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/guilds/{d}/commands",
            .{ self.client.base_url, self.client.application_id, guild_id },
        );
        defer self.allocator.free(url);

        const json_payload = try std.json.stringifyAlloc(self.allocator, commands, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.put(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.ApplicationCommand, response.body, .{});
    }

    /// Get guild application command permissions
    pub fn getGuildApplicationCommandPermissions(
        self: *ApplicationCommandManager,
        guild_id: u64,
    ) ![]models.GuildApplicationCommandPermissions {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/guilds/{d}/commands/permissions",
            .{ self.client.base_url, self.client.application_id, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.GuildApplicationCommandPermissions, response.body, .{});
    }

    /// Get application command permissions
    pub fn getApplicationCommandPermissions(
        self: *ApplicationCommandManager,
        guild_id: u64,
        command_id: u64,
    ) !models.GuildApplicationCommandPermissions {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/guilds/{d}/commands/{d}/permissions",
            .{ self.client.base_url, self.client.application_id, guild_id, command_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildApplicationCommandPermissions, response.body, .{});
    }

    /// Edit application command permissions
    pub fn editApplicationCommandPermissions(
        self: *ApplicationCommandManager,
        guild_id: u64,
        command_id: u64,
        permissions: []models.ApplicationCommandPermission,
    ) !models.GuildApplicationCommandPermissions {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/guilds/{d}/commands/{d}/permissions",
            .{ self.client.base_url, self.client.application_id, guild_id, command_id },
        );
        defer self.allocator.free(url);

        const json_payload = try std.json.stringifyAlloc(self.allocator, permissions, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.put(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildApplicationCommandPermissions, response.body, .{});
    }

    /// Batch edit application command permissions
    pub fn batchEditApplicationCommandPermissions(
        self: *ApplicationCommandManager,
        guild_id: u64,
        permissions: []models.GuildApplicationCommandPermissions,
    ) ![]models.GuildApplicationCommandPermissions {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/applications/{d}/guilds/{d}/commands/permissions",
            .{ self.client.base_url, self.client.application_id, guild_id },
        );
        defer self.allocator.free(url);

        const json_payload = try std.json.stringifyAlloc(self.allocator, permissions, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.put(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.GuildApplicationCommandPermissions, response.body, .{});
    }
};

/// Payload for creating an application command
pub const CreateApplicationCommandPayload = struct {
    name: []const u8,
    description: []const u8,
    options: []models.ApplicationCommandOption,
    default_member_permissions: ?[]const u8 = null,
    dm_permission: ?bool = null,
};

/// Payload for editing an application command
pub const EditApplicationCommandPayload = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    options: ?[]models.ApplicationCommandOption = null,
    default_member_permissions: ?[]const u8 = null,
    dm_permission: ?bool = null,
};

/// Application command validation utilities
pub const ApplicationCommandValidator = struct {
    pub fn validateCommandName(name: []const u8) bool {
        // Command names must be 1-32 characters, lowercase, with hyphens
        if (name.len < 1 or name.len > 32) {
            return false;
        }

        for (name) |c| {
            if (!std.ascii.isLower(c) and c != '-' and !std.ascii.isDigit(c)) {
                return false;
            }
        }

        return true;
    }

    pub fn validateCommandDescription(description: []const u8) bool {
        // Command descriptions must be 1-100 characters
        return description.len >= 1 and description.len <= 100;
    }

    pub fn validateOptionName(name: []const u8) bool {
        // Option names must be 1-32 characters, lowercase, with hyphens
        if (name.len < 1 or name.len > 32) {
            return false;
        }

        for (name) |c| {
            if (!std.ascii.isLower(c) and c != '-' and !std.ascii.isDigit(c)) {
                return false;
            }
        }

        return true;
    }

    pub fn validateOptionDescription(description: []const u8) bool {
        // Option descriptions must be 1-100 characters
        return description.len >= 1 and description.len <= 100;
    }

    pub fn validateCommandOptions(options: []models.ApplicationCommandOption) bool {
        if (options.len > 25) {
            return false; // Max 25 options per command
        }

        for (options) |option| {
            if (!validateOptionName(option.name)) {
                return false;
            }
            if (!validateOptionDescription(option.description)) {
                return false;
            }
            if (option.options) |sub_options| {
                if (!validateCommandOptions(sub_options)) {
                    return false;
                }
            }
        }

        return true;
    }
};
