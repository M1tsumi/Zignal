const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Guild onboarding management for new member flows
pub const GuildOnboardingManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildOnboardingManager {
        return GuildOnboardingManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get guild onboarding
    pub fn getGuildOnboarding(self: *GuildOnboardingManager, guild_id: u64) !models.GuildOnboarding {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/onboarding",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildOnboarding, response.body, .{});
    }

    /// Modify guild onboarding
    pub fn modifyGuildOnboarding(
        self: *GuildOnboardingManager,
        guild_id: u64,
        prompts: ?[]OnboardingPromptPayload,
        default_channel_ids: ?[]u64,
        enabled: ?bool,
        mode: ?models.OnboardingMode,
        reason: ?[]const u8,
    ) !models.GuildOnboarding {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}/onboarding",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const payload = ModifyOnboardingPayload{
            .prompts = prompts,
            .default_channel_ids = default_channel_ids,
            .enabled = enabled,
            .mode = mode,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");
        if (reason) |r| {
            try headers.append("X-Audit-Log-Reason", r);
        }

        const response = try self.client.http.put(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.GuildOnboarding, response.body, .{});
    }
};

/// Payload for onboarding prompt
pub const OnboardingPromptPayload = struct {
    id: ?u64 = null,
    type: models.OnboardingPromptType,
    options: []OnboardingPromptOptionPayload,
    title: []const u8,
    single_select: ?bool = null,
    required: ?bool = null,
    in_onboarding: ?bool = null,
};

/// Payload for onboarding prompt option
pub const OnboardingPromptOptionPayload = struct {
    id: ?u64 = null,
    channel_ids: ?[]u64 = null,
    role_ids: ?[]u64 = null,
    emoji: ?models.Emoji = null,
    title: []const u8,
    description: ?[]const u8 = null,
};

/// Payload for modifying onboarding
pub const ModifyOnboardingPayload = struct {
    prompts: ?[]OnboardingPromptPayload = null,
    default_channel_ids: ?[]u64 = null,
    enabled: ?bool = null,
    mode: ?models.OnboardingMode = null,
};

/// Guild onboarding utilities
pub const GuildOnboardingUtils = struct {
    pub fn isOnboardingEnabled(onboarding: models.GuildOnboarding) bool {
        return onboarding.enabled;
    }

    pub fn getOnboardingMode(onboarding: models.GuildOnboarding) []const u8 {
        return switch (onboarding.mode) {
            .default => "Default",
            .advanced => "Advanced",
        };
    }

    pub fn getPromptCount(onboarding: models.GuildOnboarding) usize {
        return onboarding.prompts.len;
    }

    pub fn getDefaultChannelCount(onboarding: models.GuildOnboarding) usize {
        return onboarding.default_channel_ids.len;
    }

    pub fn getPromptById(onboarding: models.GuildOnboarding, prompt_id: u64) ?models.OnboardingPrompt {
        for (onboarding.prompts) |prompt| {
            if (prompt.id == prompt_id) {
                return prompt;
            }
        }
        return null;
    }

    pub fn getPromptOptionById(onboarding: models.GuildOnboarding, prompt_id: u64, option_id: u64) ?models.OnboardingPromptOption {
        if (getPromptById(onboarding, prompt_id)) |prompt| {
            for (prompt.options) |option| {
                if (option.id == option_id) {
                    return option;
                }
            }
        }
        return null;
    }

    pub fn getPromptType(prompt: models.OnboardingPrompt) []const u8 {
        return switch (prompt.type) {
            .multiple_choice => "Multiple Choice",
            .dropdown => "Dropdown",
        };
    }

    pub fn isPromptRequired(prompt: models.OnboardingPrompt) bool {
        return prompt.required;
    }

    pub fn isPromptSingleChoice(prompt: models.OnboardingPrompt) bool {
        return prompt.single_select;
    }

    pub fn isPromptInOnboarding(prompt: models.OnboardingPrompt) bool {
        return prompt.in_onboarding;
    }

    pub fn getPromptOptionCount(prompt: models.OnboardingPrompt) usize {
        return prompt.options.len;
    }

    pub fn getRequiredPrompts(onboarding: models.GuildOnboarding) []models.OnboardingPrompt {
        var required = std.ArrayList(models.OnboardingPrompt).init(std.heap.page_allocator);
        defer required.deinit();

        for (onboarding.prompts) |prompt| {
            if (isPromptRequired(prompt)) {
                required.append(prompt) catch {};
            }
        }

        return required.toOwnedSlice() catch &[_]models.OnboardingPrompt{};
    }

    pub fn getOptionalPrompts(onboarding: models.GuildOnboarding) []models.OnboardingPrompt {
        var optional = std.ArrayList(models.OnboardingPrompt).init(std.heap.page_allocator);
        defer optional.deinit();

        for (onboarding.prompts) |prompt| {
            if (!isPromptRequired(prompt)) {
                optional.append(prompt) catch {};
            }
        }

        return optional.toOwnedSlice() catch &[_]models.OnboardingPrompt{};
    }

    pub fn getMultipleChoicePrompts(onboarding: models.GuildOnboarding) []models.OnboardingPrompt {
        var multiple_choice = std.ArrayList(models.OnboardingPrompt).init(std.heap.page_allocator);
        defer multiple_choice.deinit();

        for (onboarding.prompts) |prompt| {
            if (prompt.type == .multiple_choice) {
                multiple_choice.append(prompt) catch {};
            }
        }

        return multiple_choice.toOwnedSlice() catch &[_]models.OnboardingPrompt{};
    }

    pub fn getDropdownPrompts(onboarding: models.GuildOnboarding) []models.OnboardingPrompt {
        var dropdown = std.ArrayList(models.OnboardingPrompt).init(std.heap.page_allocator);
        defer dropdown.deinit();

        for (onboarding.prompts) |prompt| {
            if (prompt.type == .dropdown) {
                dropdown.append(prompt) catch {};
            }
        }

        return dropdown.toOwnedSlice() catch &[_]models.OnboardingPrompt{};
    }

    pub fn getPromptsInOnboarding(onboarding: models.GuildOnboarding) []models.OnboardingPrompt {
        var in_onboarding = std.ArrayList(models.OnboardingPrompt).init(std.heap.page_allocator);
        defer in_onboarding.deinit();

        for (onboarding.prompts) |prompt| {
            if (isPromptInOnboarding(prompt)) {
                in_onboarding.append(prompt) catch {};
            }
        }

        return in_onboarding.toOwnedSlice() catch &[_]models.OnboardingPrompt{};
    }

    pub fn getPromptRoles(prompt: models.OnboardingPrompt) []u64 {
        var roles = std.ArrayList(u64).init(std.heap.page_allocator);
        defer roles.deinit();

        for (prompt.options) |option| {
            for (option.roles) |role_id| {
                roles.append(role_id) catch {};
            }
        }

        return roles.toOwnedSlice() catch &[_]u64{};
    }

    pub fn getPromptChannels(prompt: models.OnboardingPrompt) []u64 {
        var channels = std.ArrayList(u64).init(std.heap.page_allocator);
        defer channels.deinit();

        for (prompt.options) |option| {
            for (option.channels) |channel_id| {
                channels.append(channel_id) catch {};
            }
        }

        return channels.toOwnedSlice() catch &[_]u64{};
    }

    pub fn getOptionRoles(option: models.OnboardingPromptOption) []u64 {
        return option.roles;
    }

    pub fn getOptionChannels(option: models.OnboardingPromptOption) []u64 {
        return option.channels;
    }

    pub fn getOptionEmoji(option: models.OnboardingPromptOption) ?models.Emoji {
        return option.emoji;
    }

    pub fn getOptionEmojiName(option: models.OnboardingPromptOption) ?[]const u8 {
        if (option.emoji) |emoji| {
            return emoji.name;
        }
        return null;
    }

    pub fn isCustomEmoji(option: models.OnboardingPromptOption) bool {
        if (option.emoji) |emoji| {
            return emoji.id != 0;
        }
        return false;
    }

    pub fn isUnicodeEmoji(option: models.OnboardingPromptOption) bool {
        if (option.emoji) |emoji| {
            return emoji.id == 0;
        }
        return false;
    }

    pub fn getOptionEmojiUrl(option: models.OnboardingPromptOption) ?[]const u8 {
        if (option.emoji) |emoji| {
            if (emoji.id != 0) {
                return try std.fmt.allocPrint(
                    std.heap.page_allocator,
                    "https://cdn.discordapp.com/emojis/{d}.png",
                    .{emoji.id},
                );
            }
        }
        return null;
    }

    pub fn formatPromptSummary(prompt: models.OnboardingPrompt) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(prompt.title);
        try summary.appendSlice(" (");
        try summary.appendSlice(getPromptType(prompt));
        try summary.appendSlice(")");

        if (isPromptRequired(prompt)) {
            try summary.appendSlice(" [Required]");
        } else {
            try summary.appendSlice(" [Optional]");
        }

        if (isPromptSingleChoice(prompt)) {
            try summary.appendSlice(" [Single]");
        } else {
            try summary.appendSlice(" [Multiple]");
        }

        if (isPromptInOnboarding(prompt)) {
            try summary.appendSlice(" [In Onboarding]");
        }

        try summary.appendSlice(" - Options: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getPromptOptionCount(prompt)}));

        return summary.toOwnedSlice();
    }

    pub fn formatOptionSummary(option: models.OnboardingPromptOption) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(option.title);

        if (option.description) |desc| {
            try summary.appendSlice(" - ");
            try summary.appendSlice(desc);
        }

        if (option.emoji) |emoji| {
            try summary.appendSlice(" ");
            try summary.appendSlice(emoji.name);
        }

        try summary.appendSlice(" - Roles: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{option.roles.len}));
        try summary.appendSlice(", Channels: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{option.channels.len}));

        return summary.toOwnedSlice();
    }

    pub fn formatOnboardingSummary(onboarding: models.GuildOnboarding) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Onboarding: ");
        try summary.appendSlice(if (isOnboardingEnabled(onboarding)) "Enabled" else "Disabled");
        try summary.appendSlice(" - Mode: ");
        try summary.appendSlice(getOnboardingMode(onboarding));
        try summary.appendSlice(" - Prompts: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getPromptCount(onboarding)}));
        try summary.appendSlice(" - Default Channels: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getDefaultChannelCount(onboarding)}));

        return summary.toOwnedSlice();
    }

    pub fn validateOnboarding(onboarding: models.GuildOnboarding) bool {
        if (onboarding.guild_id == 0) return false;

        // Validate prompts
        for (onboarding.prompts) |prompt| {
            if (!validatePrompt(prompt)) {
                return false;
            }
        }

        return true;
    }

    pub fn validatePrompt(prompt: models.OnboardingPrompt) bool {
        if (prompt.id == 0) return false;
        if (prompt.title.len == 0) return false;
        if (prompt.options.len == 0) return false;

        // Validate options
        for (prompt.options) |option| {
            if (!validateOption(option)) {
                return false;
            }
        }

        return true;
    }

    pub fn validateOption(option: models.OnboardingPromptOption) bool {
        if (option.id == 0) return false;
        if (option.title.len == 0) return false;

        // Validate emoji if present
        if (option.emoji) |emoji| {
            if (emoji.name.len == 0) return false;
        }

        return true;
    }

    pub fn validatePromptTitle(title: []const u8) bool {
        // Prompt titles must be 1-100 characters
        return title.len >= 1 and title.len <= 100;
    }

    pub fn validateOptionTitle(title: []const u8) bool {
        // Option titles must be 1-100 characters
        return title.len >= 1 and title.len <= 100;
    }

    pub fn validateOptionDescription(description: []const u8) bool {
        // Option descriptions must be 0-100 characters
        return description.len <= 100;
    }

    pub fn validateEmojiName(name: []const u8) bool {
        // Emoji names must be 1-100 characters
        return name.len >= 1 and name.len <= 100;
    }

    pub fn getOnboardingStatistics(onboarding: models.GuildOnboarding) struct {
        total_prompts: usize,
        required_prompts: usize,
        optional_prompts: usize,
        multiple_choice_prompts: usize,
        dropdown_prompts: usize,
        prompts_in_onboarding: usize,
        default_channels: usize,
        total_options: usize,
        custom_emoji_options: usize,
        unicode_emoji_options: usize,
        no_emoji_options: usize,
    } {
        var total_options: usize = 0;
        var custom_emoji_count: usize = 0;
        var unicode_emoji_count: usize = 0;
        var no_emoji_count: usize = 0;

        for (onboarding.prompts) |prompt| {
            total_options += prompt.options.len;

            for (prompt.options) |option| {
                if (option.emoji) |emoji| {
                    if (emoji.id != 0) {
                        custom_emoji_count += 1;
                    } else {
                        unicode_emoji_count += 1;
                    }
                } else {
                    no_emoji_count += 1;
                }
            }
        }

        return .{
            .total_prompts = getPromptCount(onboarding),
            .required_prompts = getRequiredPrompts(onboarding).len,
            .optional_prompts = getOptionalPrompts(onboarding).len,
            .multiple_choice_prompts = getMultipleChoicePrompts(onboarding).len,
            .dropdown_prompts = getDropdownPrompts(onboarding).len,
            .prompts_in_onboarding = getPromptsInOnboarding(onboarding).len,
            .default_channels = getDefaultChannelCount(onboarding),
            .total_options = total_options,
            .custom_emoji_options = custom_emoji_count,
            .unicode_emoji_options = unicode_emoji_count,
            .no_emoji_options = no_emoji_count,
        };
    }

    pub fn createPromptPayload(
        prompt_type: models.OnboardingPromptType,
        options: []OnboardingPromptOptionPayload,
        title: []const u8,
        single_select: ?bool,
        required: ?bool,
        in_onboarding: ?bool,
    ) OnboardingPromptPayload {
        return OnboardingPromptPayload{
            .type = prompt_type,
            .options = options,
            .title = title,
            .single_select = single_select,
            .required = required,
            .in_onboarding = in_onboarding,
        };
    }

    pub fn createOptionPayload(
        channel_ids: ?[]u64,
        role_ids: ?[]u64,
        emoji: ?models.Emoji,
        title: []const u8,
        description: ?[]const u8,
    ) OnboardingPromptOptionPayload {
        return OnboardingPromptOptionPayload{
            .channel_ids = channel_ids,
            .role_ids = role_ids,
            .emoji = emoji,
            .title = title,
            .description = description,
        };
    }

    pub fn createOptionPayloadWithRoles(
        role_ids: []u64,
        title: []const u8,
        description: ?[]const u8,
        emoji: ?models.Emoji,
    ) OnboardingPromptOptionPayload {
        return createOptionPayload(null, role_ids, emoji, title, description);
    }

    pub fn createOptionPayloadWithChannels(
        channel_ids: []u64,
        title: []const u8,
        description: ?[]const u8,
        emoji: ?models.Emoji,
    ) OnboardingPromptOptionPayload {
        return createOptionPayload(channel_ids, null, emoji, title, description);
    }

    pub fn createOptionPayloadWithRolesAndChannels(
        role_ids: []u64,
        channel_ids: []u64,
        title: []const u8,
        description: ?[]const u8,
        emoji: ?models.Emoji,
    ) OnboardingPromptOptionPayload {
        return createOptionPayload(channel_ids, role_ids, emoji, title, description);
    }

    pub fn searchPrompts(onboarding: models.GuildOnboarding, query: []const u8) []models.OnboardingPrompt {
        var results = std.ArrayList(models.OnboardingPrompt).init(std.heap.page_allocator);
        defer results.deinit();

        for (onboarding.prompts) |prompt| {
            if (std.mem.indexOf(u8, prompt.title, query) != null) {
                results.append(prompt) catch {};
            }
        }

        return results.toOwnedSlice() catch &[_]models.OnboardingPrompt{};
    }

    pub fn searchOptions(onboarding: models.GuildOnboarding, query: []const u8) []models.OnboardingPromptOption {
        var results = std.ArrayList(models.OnboardingPromptOption).init(std.heap.page_allocator);
        defer results.deinit();

        for (onboarding.prompts) |prompt| {
            for (prompt.options) |option| {
                if (std.mem.indexOf(u8, option.title, query) != null or
                    (option.description != null and std.mem.indexOf(u8, option.description.?, query) != null)) {
                    results.append(option) catch {};
                }
            }
        }

        return results.toOwnedSlice() catch &[_]models.OnboardingPromptOption{};
    }

    pub fn getOptionsByEmojiType(
        onboarding: models.GuildOnboarding,
        emoji_type: EmojiType,
    ) []models.OnboardingPromptOption {
        var filtered = std.ArrayList(models.OnboardingPromptOption).init(std.heap.page_allocator);
        defer filtered.deinit();

        for (onboarding.prompts) |prompt| {
            for (prompt.options) |option| {
                switch (emoji_type) {
                    .custom => {
                        if (isCustomEmoji(option)) {
                            filtered.append(option) catch {};
                        }
                    },
                    .unicode => {
                        if (isUnicodeEmoji(option)) {
                            filtered.append(option) catch {};
                        }
                    },
                    .none => {
                        if (option.emoji == null) {
                            filtered.append(option) catch {};
                        }
                    },
                }
            }
        }

        return filtered.toOwnedSlice() catch &[_]models.OnboardingPromptOption{};
    }

    pub fn getCustomEmojiOptions(onboarding: models.GuildOnboarding) []models.OnboardingPromptOption {
        return getOptionsByEmojiType(onboarding, .custom);
    }

    pub fn getUnicodeEmojiOptions(onboarding: models.GuildOnboarding) []models.OnboardingPromptOption {
        return getOptionsByEmojiType(onboarding, .unicode);
    }

    pub fn getNoEmojiOptions(onboarding: models.GuildOnboarding) []models.OnboardingPromptOption {
        return getOptionsByEmojiType(onboarding, .none);
    }

    pub fn hasRequiredPrompts(onboarding: models.GuildOnboarding) bool {
        return getRequiredPrompts(onboarding).len > 0;
    }

    pub fn hasOptionalPrompts(onboarding: models.GuildOnboarding) bool {
        return getOptionalPrompts(onboarding).len > 0;
    }

    pub fn hasMultipleChoicePrompts(onboarding: models.GuildOnboarding) bool {
        return getMultipleChoicePrompts(onboarding).len > 0;
    }

    pub fn hasDropdownPrompts(onboarding: models.GuildOnboarding) bool {
        return getDropdownPrompts(onboarding).len > 0;
    }

    pub fn hasDefaultChannels(onboarding: models.GuildOnboarding) bool {
        return getDefaultChannelCount(onboarding) > 0;
    }

    pub fn hasCustomEmojis(onboarding: models.GuildOnboarding) bool {
        return getCustomEmojiOptions(onboarding).len > 0;
    }

    pub fn hasUnicodeEmojis(onboarding: models.GuildOnboarding) bool {
        return getUnicodeEmojiOptions(onboarding).len > 0;
    }
};

pub const EmojiType = enum {
    custom,
    unicode,
    none,
};
