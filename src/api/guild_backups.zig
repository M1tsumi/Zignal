const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Guild backup management for Discord server backup and restoration
pub const GuildBackupManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildBackupManager {
        return GuildBackupManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Create guild backup
    pub fn createGuildBackup(
        self: *GuildBackupManager,
        guild_id: u64,
        name: []const u8,
        description: ?[]const u8,
        include_channels: ?bool,
        include_roles: ?bool,
        include_permissions: ?bool,
        include_emojis: ?bool,
        include_settings: ?bool,
        reason: ?[]const u8,
    ) !models.GuildBackup {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = CreateGuildBackupPayload{
            .name = name,
            .description = description,
            .include_channels = include_channels,
            .include_roles = include_roles,
            .include_permissions = include_permissions,
            .include_emojis = include_emojis,
            .include_settings = include_settings,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildBackup, response.body, .{});
    }

    /// Get guild backups
    pub fn getGuildBackups(
        self: *GuildBackupManager,
        guild_id: u64,
        before: ?u64,
        after: ?u64,
        limit: ?usize,
    ) ![]models.GuildBackup {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        if (before) |b| {
            try params.append(try std.fmt.allocPrint(self.allocator, "before={d}", .{b}));
        }
        if (after) |a| {
            try params.append(try std.fmt.allocPrint(self.allocator, "after={d}", .{a}));
        }
        if (limit) |l| {
            try params.append(try std.fmt.allocPrint(self.allocator, "limit={d}", .{l}));
        }

        if (params.items.len > 0) {
            try url.appendSlice("?");
            for (params.items, 0..) |param, i| {
                if (i > 0) try url.appendSlice("&");
                try url.appendSlice(param);
            }
        }

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.GuildBackup, response.body, .{});
    }

    /// Get guild backup
    pub fn getGuildBackup(
        self: *GuildBackupManager,
        guild_id: u64,
        backup_id: u64,
    ) !models.GuildBackup {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups/{d}",
            .{ self.client.base_url, guild_id, backup_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildBackup, response.body, .{});
    }

    /// Modify guild backup
    pub fn modifyGuildBackup(
        self: *GuildBackupManager,
        guild_id: u64,
        backup_id: u64,
        name: ?[]const u8,
        description: ?[]const u8,
        reason: ?[]const u8,
    ) !models.GuildBackup {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups/{d}",
            .{ self.client.base_url, guild_id, backup_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyGuildBackupPayload{
            .name = name,
            .description = description,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.patch(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildBackup, response.body, .{});
    }

    /// Delete guild backup
    pub fn deleteGuildBackup(
        self: *GuildBackupManager,
        guild_id: u64,
        backup_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups/{d}",
            .{ self.client.base_url, guild_id, backup_id },
        );
        defer self.allocator.free(url);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Restore guild backup
    pub fn restoreGuildBackup(
        self: *GuildBackupManager,
        guild_id: u64,
        backup_id: u64,
        restore_options: models.BackupRestoreOptions,
        reason: ?[]const u8,
    ) !models.BackupRestoreJob {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups/{d}/restore",
            .{ self.client.base_url, guild_id, backup_id },
        );
        defer self.allocator.free(url);

        const payload = RestoreGuildBackupPayload{
            .restore_options = restore_options,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 202) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.BackupRestoreJob, response.body, .{});
    }

    /// Get backup restore status
    pub fn getBackupRestoreStatus(
        self: *GuildBackupManager,
        guild_id: u64,
        backup_id: u64,
        job_id: u64,
    ) !models.BackupRestoreJob {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups/{d}/restore/{d}",
            .{ self.client.base_url, guild_id, backup_id, job_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.BackupRestoreJob, response.body, .{});
    }

    /// Cancel backup restore
    pub fn cancelBackupRestore(
        self: *GuildBackupManager,
        guild_id: u64,
        backup_id: u64,
        job_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups/{d}/restore/{d}",
            .{ self.client.base_url, guild_id, backup_id, job_id },
        );
        defer self.allocator.free(url);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }

    /// Download guild backup
    pub fn downloadGuildBackup(
        self: *GuildBackupManager,
        guild_id: u64,
        backup_id: u64,
        format: ?[]const u8,
    ) !models.BackupDownload {
        var url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups/{d}/download",
            .{ self.client.base_url, guild_id, backup_id },
        );
        defer self.allocator.free(url);

        if (format) |f| {
            try url.appendSlice("?format=");
            try url.appendSlice(f);
        }

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.BackupDownload, response.body, .{});
    }

    /// Upload guild backup
    pub fn uploadGuildBackup(
        self: *GuildBackupManager,
        guild_id: u64,
        backup_data: []const u8,
        name: []const u8,
        description: ?[]const u8,
        format: []const u8,
        reason: ?[]const u8,
    ) !models.GuildBackup {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups/upload",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        var params = std.ArrayList([]const u8).init(self.allocator);
        defer params.deinit();

        try params.append(try std.fmt.allocPrint(self.allocator, "name={s}", .{name}));
        try params.append(try std.fmt.allocPrint(self.allocator, "format={s}", .{format}));

        if (description) |desc| {
            try params.append(try std.fmt.allocPrint(self.allocator, "description={s}", .{desc}));
        }

        if (params.items.len > 0) {
            try url.appendSlice("?");
            for (params.items, 0..) |param, i| {
                if (i > 0) try url.appendSlice("&");
                try url.appendSlice(param);
            }
        }

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/octet-stream");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.post(url, backup_data);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildBackup, response.body, .{});
    }

    /// Schedule automatic backup
    pub fn scheduleAutomaticBackup(
        self: *GuildBackupManager,
        guild_id: u64,
        schedule: models.BackupSchedule,
        backup_options: models.BackupOptions,
        reason: ?[]const u8,
    ) !models.ScheduledBackup {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups/schedule",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = ScheduleAutomaticBackupPayload{
            .schedule = schedule,
            .backup_options = backup_options,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 201) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.ScheduledBackup, response.body, .{});
    }

    /// Get scheduled backups
    pub fn getScheduledBackups(
        self: *GuildBackupManager,
        guild_id: u64,
    ) ![]models.ScheduledBackup {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups/schedule",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.ScheduledBackup, response.body, .{});
    }

    /// Delete scheduled backup
    pub fn deleteScheduledBackup(
        self: *GuildBackupManager,
        guild_id: u64,
        schedule_id: u64,
        reason: ?[]const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/backups/schedule/{d}",
            .{ self.client.base_url, guild_id, schedule_id },
        );
        defer self.allocator.free(url);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.delete(url);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }
};

// Payload structures
const CreateGuildBackupPayload = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    include_channels: ?bool = null,
    include_roles: ?bool = null,
    include_permissions: ?bool = null,
    include_emojis: ?bool = null,
    include_settings: ?bool = null,
};

const ModifyGuildBackupPayload = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
};

const RestoreGuildBackupPayload = struct {
    restore_options: models.BackupRestoreOptions,
};

const ScheduleAutomaticBackupPayload = struct {
    schedule: models.BackupSchedule,
    backup_options: models.BackupOptions,
};
