const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// Guild template management for server templates
pub const GuildTemplateManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildTemplateManager {
        return GuildTemplateManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild template
    pub fn getGuildTemplate(self: *GuildTemplateManager, template_code: []const u8) !models.GuildTemplate {
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

    /// Get guild templates
    pub fn getGuildTemplates(self: *GuildTemplateManager, guild_id: u64) ![]models.GuildTemplate {
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

    /// Create guild template
    pub fn createGuildTemplate(
        self: *GuildTemplateManager,
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

        const payload = struct {
            name: []const u8,
            description: ?[]const u8,
        }{
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

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildTemplate, response.body, .{});
    }

    /// Sync guild template
    pub fn syncGuildTemplate(
        self: *GuildTemplateManager,
        guild_id: u64,
        template_code: []const u8,
    ) !models.GuildTemplate {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/templates/{s}",
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

    /// Modify guild template
    pub fn modifyGuildTemplate(
        self: *GuildTemplateManager,
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

        const payload = struct {
            name: ?[]const u8,
            description: ?[]const u8,
        }{
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

    /// Delete guild template
    pub fn deleteGuildTemplate(
        self: *GuildTemplateManager,
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

    /// Create guild from template
    pub fn createGuildFromTemplate(
        self: *GuildTemplateManager,
        template_code: []const u8,
        name: []const u8,
        icon: ?[]const u8,
    ) !models.Guild {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/templates/{s}",
            .{ self.client.base_url, template_code },
        );
        defer self.allocator.free(url);

        const payload = struct {
            name: []const u8,
            icon: ?[]const u8,
        }{
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

/// Guild template utilities
pub const GuildTemplateUtils = struct {
    pub fn getTemplateCode(template: models.GuildTemplate) []const u8 {
        return template.code;
    }

    pub fn getTemplateName(template: models.GuildTemplate) []const u8 {
        return template.name;
    }

    pub fn getTemplateDescription(template: models.GuildTemplate) ?[]const u8 {
        return template.description;
    }

    pub fn getTemplateUsageCount(template: models.GuildTemplate) u32 {
        return template.usage_count;
    }

    pub fn getTemplateCreatorId(template: models.GuildTemplate) u64 {
        return template.creator.id;
    }

    pub fn getTemplateCreator(template: models.GuildTemplate) models.User {
        return template.creator;
    }

    pub fn getTemplateCreatedAt(template: models.GuildTemplate) []const u8 {
        return template.created_at;
    }

    pub fn getTemplateUpdatedAt(template: models.GuildTemplate) []const u8 {
        return template.updated_at;
    }

    pub fn getTemplateSourceGuildId(template: models.GuildTemplate) u64 {
        return template.source_guild_id;
    }

    pub fn getTemplateSerializedSourceGuild(template: models.GuildTemplate) models.Guild {
        return template.serialized_source_guild;
    }

    pub fn isTemplateDirty(template: models.GuildTemplate) bool {
        return template.is_dirty;
    }

    pub fn validateTemplateName(name: []const u8) bool {
        // Template names must be 1-100 characters
        return name.len >= 1 and name.len <= 100;
    }

    pub fn validateTemplateDescription(description: []const u8) bool {
        // Template descriptions must be 0-120 characters
        return description.len <= 120;
    }

    pub fn validateTemplateCode(code: []const u8) bool {
        // Template codes should follow Discord's format
        return code.len >= 1 and code.len <= 50;
    }

    pub fn formatTemplateSummary(template: models.GuildTemplate) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(getTemplateName(template));
        try summary.appendSlice(" (");
        try summary.appendSlice(getTemplateCode(template));
        try summary.appendSlice(") - Used ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getTemplateUsageCount(template)}));
        try summary.appendSlice(" times");

        if (getTemplateDescription(template)) |desc| {
            try summary.appendSlice(" - ");
            try summary.appendSlice(desc);
        }

        return summary.toOwnedSlice();
    }

    pub fn validateTemplate(template: models.GuildTemplate) bool {
        if (!validateTemplateName(getTemplateName(template))) return false;
        if (getTemplateDescription(template)) |desc| {
            if (!validateTemplateDescription(desc)) return false;
        }
        if (!validateTemplateCode(getTemplateCode(template))) return false;
        if (getTemplateCreatorId(template) == 0) return false;
        if (getTemplateSourceGuildId(template) == 0) return false;

        return true;
    }

    pub fn getTemplatesByCreator(templates: []models.GuildTemplate, creator_id: u64) []models.GuildTemplate {
        var filtered = std.ArrayList(models.GuildTemplate).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (templates) |template| {
            if (getTemplateCreatorId(template) == creator_id) {
                filtered.append(template) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.GuildTemplate{};
    }

    pub fn getTemplatesByUsage(templates: []models.GuildTemplate, min_usage: u32) []models.GuildTemplate {
        var filtered = std.ArrayList(models.GuildTemplate).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (templates) |template| {
            if (getTemplateUsageCount(template) >= min_usage) {
                filtered.append(template) catch {};
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.GuildTemplate{};
    }

    pub fn searchTemplates(templates: []models.GuildTemplate, query: []const u8) []models.GuildTemplate {
        var results = std.ArrayList(models.GuildTemplate).init(std.heap.page_allocator);
        defer results.deinit();

        for (templates) |template| {
            if (std.mem.indexOf(u8, getTemplateName(template), query) != null or
                (getTemplateDescription(template) != null and std.mem.indexOf(u8, getTemplateDescription(template).?, query) != null)) {
                results.append(template) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.GuildTemplate{};
    }

    pub fn sortTemplatesByUsage(templates: []models.GuildTemplate) void {
        std.sort.sort(models.GuildTemplate, templates, {}, compareTemplatesByUsage);
    }

    pub fn sortTemplatesByName(templates: []models.GuildTemplate) void {
        std.sort.sort(models.GuildTemplate, templates, {}, compareTemplatesByName);
    }

    pub fn sortTemplatesByCreated(templates: []models.GuildTemplate) void {
        std.sort.sort(models.GuildTemplate, templates, {}, compareTemplatesByCreated);
    }

    fn compareTemplatesByUsage(_: void, a: models.GuildTemplate, b: models.GuildTemplate) std.math.Order {
        return std.math.order(getTemplateUsageCount(a), getTemplateUsageCount(b));
    }

    fn compareTemplatesByName(_: void, a: models.GuildTemplate, b: models.GuildTemplate) std.math.Order {
        return std.mem.compare(u8, getTemplateName(a), getTemplateName(b));
    }

    fn compareTemplatesByCreated(_: void, a: models.GuildTemplate, b: models.GuildTemplate) std.math.Order {
        return std.mem.compare(u8, getTemplateCreatedAt(a), getTemplateCreatedAt(b));
    }

    pub fn getTemplateStatistics(templates: []models.GuildTemplate) struct {
        total_templates: usize,
        total_usage: u32,
        average_usage: f32,
        most_used: ?models.GuildTemplate,
        least_used: ?models.GuildTemplate,
        unique_creators: usize,
    } {
        if (templates.len == 0) {
            return .{
                .total_templates = 0,
                .total_usage = 0,
                .average_usage = 0.0,
                .most_used = null,
                .least_used = null,
                .unique_creators = 0,
            };
        }

        var total_usage: u32 = 0;
        var most_used: ?models.GuildTemplate = null;
        var least_used: ?models.GuildTemplate = null;
        var creator_set = std.hash_map.AutoHashMap(u64, void).init(std.heap.page_allocator);
        defer creator_set.deinit();

        for (templates) |template| {
            const usage = getTemplateUsageCount(template);
            total_usage += usage;

            creator_set.put(getTemplateCreatorId(template), {}) catch {};

            if (most_used == null or usage > getTemplateUsageCount(most_used.?)) {
                most_used = template;
            }

            if (least_used == null or usage < getTemplateUsageCount(least_used.?)) {
                least_used = template;
            }
        }

        return .{
            .total_templates = templates.len,
            .total_usage = total_usage,
            .average_usage = @as(f32, @floatFromInt(total_usage)) / @as(f32, @floatFromInt(templates.len)),
            .most_used = most_used,
            .least_used = least_used,
            .unique_creators = creator_set.count(),
        };
    }

    pub fn hasDirtyTemplates(templates: []models.GuildTemplate) bool {
        for (templates) |template| {
            if (isTemplateDirty(template)) {
                return true;
            }
        }
        return false;
    }

    pub fn getDirtyTemplates(templates: []models.GuildTemplate) []models.GuildTemplate {
        var dirty = std.ArrayList(models.GuildTemplate).init(std.heap.page_allocator);
        defer dirty.deinit();

        for (templates) |template| {
            if (isTemplateDirty(template)) {
                dirty.append(template) catch {};
            }
        }

        return dirty.toOwnedSlice() catch &[_]models.GuildTemplate{};
    }

    pub fn getPopularTemplates(templates: []models.GuildTemplate, threshold: u32) []models.GuildTemplate {
        var popular = std.ArrayList(models.GuildTemplate).init(std.heap.page_allocator);
        defer popular.deinit();

        for (templates) |template| {
            if (getTemplateUsageCount(template) >= threshold) {
                popular.append(template) catch {};
            }
        }

        return popular.toOwnedSlice() catch &[_]models.GuildTemplate{};
    }

    pub fn formatFullTemplateInfo(template: models.GuildTemplate) []const u8 {
        var info = std.ArrayList(u8).init(std.heap.page_allocator);
        defer info.deinit();

        try info.appendSlice("Template: ");
        try info.appendSlice(getTemplateName(template));
        try info.appendSlice("\n");
        try info.appendSlice("Code: ");
        try info.appendSlice(getTemplateCode(template));
        try info.appendSlice("\n");
        try info.appendSlice("Description: ");
        try info.appendSlice(getTemplateDescription(template) orelse "No description");
        try info.appendSlice("\n");
        try info.appendSlice("Usage: ");
        try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getTemplateUsageCount(template)}));
        try info.appendSlice("\n");
        try info.appendSlice("Creator: ");
        try info.appendSlice(getTemplateCreator(template).username);
        try info.appendSlice("#");
        try info.appendSlice(getTemplateCreator(template).discriminator);
        try info.appendSlice("\n");
        try info.appendSlice("Created: ");
        try info.appendSlice(getTemplateCreatedAt(template));
        try info.appendSlice("\n");
        try info.appendSlice("Updated: ");
        try info.appendSlice(getTemplateUpdatedAt(template));
        try info.appendSlice("\n");
        try info.appendSlice("Source Guild ID: ");
        try info.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getTemplateSourceGuildId(template)}));
        try info.appendSlice("\n");
        try info.appendSlice("Dirty: ");
        try info.appendSlice(if (isTemplateDirty(template)) "Yes" else "No");

        return info.toOwnedSlice();
    }
};
