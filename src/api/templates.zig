const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Guild template management for server templates
pub const TemplateManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) TemplateManager {
        return TemplateManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get all templates for a guild
    pub fn getGuildTemplates(self: *TemplateManager, guild_id: u64) ![]models.GuildTemplate {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/templates",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.GuildTemplate, response.body, .{});
    }

    /// Create a guild template
    pub fn createGuildTemplate(
        self: *TemplateManager,
        guild_id: u64,
        name: []const u8,
        description: ?[]const u8,
    ) !models.GuildTemplate {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/templates",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreateTemplatePayload{
            .name = name,
            .description = description,
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

        return try std.json.parse(models.GuildTemplate, response.body, .{});
    }

    /// Sync a guild template
    pub fn syncGuildTemplate(
        self: *TemplateManager,
        guild_id: u64,
        template_code: []const u8,
    ) !models.GuildTemplate {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/templates/{s}/sync",
            .{ self.client.base_url, guild_id, template_code },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.put(url, "");
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildTemplate, response.body, .{});
    }

    /// Modify a guild template
    pub fn modifyGuildTemplate(
        self: *TemplateManager,
        guild_id: u64,
        template_code: []const u8,
        name: ?[]const u8,
        description: ?[]const u8,
    ) !models.GuildTemplate {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/templates/{s}",
            .{ self.client.base_url, guild_id, template_code },
        );
        defer self.allocator.free(url);

        const payload = ModifyTemplatePayload{
            .name = name,
            .description = description,
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

        return try std.json.parse(models.GuildTemplate, response.body, .{});
    }

    /// Delete a guild template
    pub fn deleteGuildTemplate(
        self: *TemplateManager,
        guild_id: u64,
        template_code: []const u8,
    ) !models.GuildTemplate {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/templates/{s}",
            .{ self.client.base_url, guild_id, template_code },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildTemplate, response.body, .{});
    }

    /// Get a template by code
    pub fn getTemplate(self: *TemplateManager, template_code: []const u8) !models.GuildTemplate {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/templates/{s}",
            .{ self.client.base_url, template_code },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildTemplate, response.body, .{});
    }

    /// Create a guild from a template
    pub fn createGuildFromTemplate(
        self: *TemplateManager,
        template_code: []const u8,
        name: []const u8,
        icon: ?[]const u8, // Base64 encoded image data
    ) !models.Guild {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/templates/{s}",
            .{ self.client.base_url, template_code },
        );
        defer self.allocator.free(url);

        const payload = CreateGuildFromTemplatePayload{
            .name = name,
            .icon = icon,
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

        return try std.json.parse(models.Guild, response.body, .{});
    }
};

/// Payload for creating a template
pub const CreateTemplatePayload = struct {
    name: []const u8,
    description: ?[]const u8 = null,
};

/// Payload for modifying a template
pub const ModifyTemplatePayload = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
};

/// Payload for creating a guild from template
pub const CreateGuildFromTemplatePayload = struct {
    name: []const u8,
    icon: ?[]const u8 = null,
};

/// Template validation utilities
pub const TemplateValidator = struct {
    pub fn validateTemplateName(name: []const u8) bool {
        // Template names must be 1-100 characters
        return name.len >= 1 and name.len <= 100;
    }

    pub fn validateTemplateDescription(description: []const u8) bool {
        // Template descriptions must be 0-120 characters
        return description.len <= 120;
    }

    pub fn validateTemplateCode(code: []const u8) bool {
        // Template codes are typically 16-32 characters
        // containing alphanumeric characters and hyphens
        if (code.len < 16 or code.len > 32) {
            return false;
        }

        for (code) |c| {
            if (!std.ascii.isAlphanumeric(c) and c != '-') {
                return false;
            }
        }

        return true;
    }

    pub fn generateTemplateUrl(template_code: []const u8) ![]const u8 {
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "https://discord.new/{s}",
            .{template_code},
        );
    }

    pub fn extractTemplateCode(url: []const u8) ?[]const u8 {
        // Extract template code from various URL formats
        // https://discord.new/abc123-def456
        // https://discord.com/template/abc123-def456
        
        const patterns = [_][]const u8{
            "discord.new/",
            "discord.com/template/",
        };

        for (patterns) |pattern| {
            if (std.mem.indexOf(u8, url, pattern)) |index| {
                const start = index + pattern.len;
                
                // Find the end of the template code
                var end = start;
                while (end < url.len and (std.ascii.isAlphanumeric(url[end]) or url[end] == '-')) {
                    end += 1;
                }
                
                const code = url[start..end];
                if (validateTemplateCode(code)) {
                    return code;
                }
            }
        }

        return null;
    }
};
