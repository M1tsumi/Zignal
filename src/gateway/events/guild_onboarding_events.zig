const std = @import("std");
const models = @import("../../models.zig");

/// Guild onboarding-related gateway events
pub const GuildOnboardingEvents = struct {
    /// Guild onboarding update event
    pub const GuildOnboardingUpdateEvent = struct {
        guild_id: u64,
        onboarding: models.GuildOnboarding,
    };

    /// Guild onboarding prompt create event
    pub const GuildOnboardingPromptCreateEvent = struct {
        guild_id: u64,
        prompt: models.OnboardingPrompt,
    };

    /// Guild onboarding prompt update event
    pub const GuildOnboardingPromptUpdateEvent = struct {
        guild_id: u64,
        prompt: models.OnboardingPrompt,
    };

    /// Guild onboarding prompt delete event
    pub const GuildOnboardingPromptDeleteEvent = struct {
        guild_id: u64,
        prompt_id: u64,
    };
};

/// Event parsers for guild onboarding events
pub const GuildOnboardingEventParsers = struct {
    pub fn parseGuildOnboardingUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildOnboardingEvents.GuildOnboardingUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildOnboardingEvents.GuildOnboardingUpdateEvent, allocator, data, .{});
    }

    pub fn parseGuildOnboardingPromptCreateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildOnboardingEvents.GuildOnboardingPromptCreateEvent {
        return try std.json.parseFromSliceLeaky(GuildOnboardingEvents.GuildOnboardingPromptCreateEvent, allocator, data, .{});
    }

    pub fn parseGuildOnboardingPromptUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !GuildOnboardingEvents.GuildOnboardingPromptUpdateEvent {
        return try std.json.parseFromSliceLeaky(GuildOnboardingEvents.GuildOnboardingPromptUpdateEvent, allocator, data, .{});
    }

    pub fn parseGuildOnboardingPromptDeleteEvent(data: []const u8, allocator: std.mem.Allocator) !GuildOnboardingEvents.GuildOnboardingPromptDeleteEvent {
        return try std.json.parseFromSliceLeaky(GuildOnboardingEvents.GuildOnboardingPromptDeleteEvent, allocator, data, .{});
    }
};

/// Guild onboarding event utilities
pub const GuildOnboardingEventUtils = struct {
    pub fn formatOnboardingUpdateEvent(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Onboarding updated - Guild: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.guild_id}));
        try summary.appendSlice(" - Enabled: ");
        try summary.appendSlice(if (event.onboarding.enabled) "Yes" else "No");
        try summary.appendSlice(" - Prompts: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.onboarding.prompts.len}));
        try summary.appendSlice(" - Default Channels: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.onboarding.default_channel_ids.len}));

        return summary.toOwnedSlice();
    }

    pub fn formatPromptEvent(event_type: []const u8, guild_id: u64, prompt: ?models.OnboardingPrompt, prompt_id: ?u64) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Onboarding prompt ");
        try summary.appendSlice(event_type);
        try summary.appendSlice(" - Guild: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{guild_id}));

        if (prompt) |p| {
            try summary.appendSlice(" - Prompt: ");
            try summary.appendSlice(p.title);
            try summary.appendSlice(" (ID: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{p.id}));
            try summary.appendSlice(")");
            try summary.appendSlice(" - Type: ");
            try summary.appendSlice(getPromptType(p));
        } else if (prompt_id) |id| {
            try summary.appendSlice(" - ID: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{id}));
        }

        return summary.toOwnedSlice();
    }

    pub fn getAffectedGuild(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) u64 {
        return event.guild_id;
    }

    pub fn isOnboardingEnabled(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) bool {
        return event.onboarding.enabled;
    }

    pub fn getPromptCount(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) usize {
        return event.onboarding.prompts.len;
    }

    pub fn getDefaultChannelCount(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) usize {
        return event.onboarding.default_channel_ids.len;
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

    pub fn getPromptById(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent, prompt_id: u64) ?models.OnboardingPrompt {
        for (event.onboarding.prompts) |prompt| {
            if (prompt.id == prompt_id) {
                return prompt;
            }
        }
        return null;
    }

    pub fn getRequiredPrompts(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) []models.OnboardingPrompt {
        var required = std.ArrayList(models.OnboardingPrompt).init(std.heap.page_allocator);
        defer required.deinit();

        for (event.onboarding.prompts) |prompt| {
            if (isPromptRequired(prompt)) {
                required.append(prompt) catch {};
            }
        }

        return required.toOwnedSlice() catch &[_]models.OnboardingPrompt{};
    }

    pub fn getOptionalPrompts(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) []models.OnboardingPrompt {
        var optional = std.ArrayList(models.OnboardingPrompt).init(std.heap.page_allocator);
        defer optional.deinit();

        for (event.onboarding.prompts) |prompt| {
            if (!isPromptRequired(prompt)) {
                optional.append(prompt) catch {};
            }
        }

        return optional.toOwnedSlice() catch &[_]models.OnboardingPrompt{};
    }

    pub fn getMultipleChoicePrompts(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) []models.OnboardingPrompt {
        var multiple_choice = std.ArrayList(models.OnboardingPrompt).init(std.heap.page_allocator);
        defer multiple_choice.deinit();

        for (event.onboarding.prompts) |prompt| {
            if (prompt.type == .multiple_choice) {
                multiple_choice.append(prompt) catch {};
            }
        }

        return multiple_choice.toOwnedSlice() catch &[_]models.OnboardingPrompt{};
    }

    pub fn getDropdownPrompts(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) []models.OnboardingPrompt {
        var dropdown = std.ArrayList(models.OnboardingPrompt).init(std.heap.page_allocator);
        defer dropdown.deinit();

        for (event.onboarding.prompts) |prompt| {
            if (prompt.type == .dropdown) {
                dropdown.append(prompt) catch {};
            }
        }

        return dropdown.toOwnedSlice() catch &[_]models.OnboardingPrompt{};
    }

    pub fn getPromptsInOnboarding(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) []models.OnboardingPrompt {
        var in_onboarding = std.ArrayList(models.OnboardingPrompt).init(std.heap.page_allocator);
        defer in_onboarding.deinit();

        for (event.onboarding.prompts) |prompt| {
            if (isPromptInOnboarding(prompt)) {
                in_onboarding.append(prompt) catch {};
            }
        }

        return in_onboarding.toOwnedSlice() catch &[_]models.OnboardingPrompt{};
    }

    pub fn getPromptOptionById(prompt: models.OnboardingPrompt, option_id: u64) ?models.OnboardingPromptOption {
        for (prompt.options) |option| {
            if (option.id == option_id) {
                return option;
            }
        }
        return null;
    }

    pub function getPromptRoles(prompt: models.OnboardingPrompt) []u64 {
        var roles = std.ArrayList(u64).init(std.heap.page_allocator);
        defer roles.deinit();

        for (prompt.options) |option| {
            for (option.roles) |role_id| {
                roles.append(role_id) catch {};
            }
        }

        return roles.toOwnedSlice() catch &[_]u64{};
    }

    pub function getPromptChannels(prompt: models.OnboardingPrompt) []u64 {
        var channels = std.ArrayList(u64).init(std.heap.page_allocator);
        defer channels.deinit();

        for (prompt.options) |option| {
            for (option.channels) |channel_id| {
                channels.append(channel_id) catch {};
            }
        }

        return channels.toOwnedSlice() catch &[_]u64{};
    }

    pub function formatPromptSummary(prompt: models.OnboardingPrompt) []const u8 {
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

    pub function formatOptionSummary(option: models.OnboardingPromptOption) []const u8 {
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

    pub function validateOnboardingUpdateEvent(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) bool {
        if (event.guild_id == 0) return false;

        // Validate prompts
        for (event.onboarding.prompts) |prompt| {
            if (prompt.id == 0) return false;
            if (prompt.title.len == 0) return false;
            if (prompt.options.len == 0) return false;

            // Validate options
            for (prompt.options) |option| {
                if (option.id == 0) return false;
                if (option.title.len == 0) return false;
            }
        }

        return true;
    }

    pub function validatePrompt(prompt: models.OnboardingPrompt) bool {
        if (prompt.id == 0) return false;
        if (prompt.title.len == 0) return false;
        if (prompt.options.len == 0) return false;

        // Validate options
        for (prompt.options) |option| {
            if (option.id == 0) return false;
            if (option.title.len == 0) return false;
        }

        return true;
    }

    pub function getOnboardingStatistics(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) struct {
        total_prompts: usize,
        required_prompts: usize,
        optional_prompts: usize,
        multiple_choice_prompts: usize,
        dropdown_prompts: usize,
        prompts_in_onboarding: usize,
        default_channels: usize,
    } {
        const total_prompts = getPromptCount(event);
        const required_prompts = getRequiredPrompts(event).len;
        const optional_prompts = getOptionalPrompts(event).len;
        const multiple_choice_prompts = getMultipleChoicePrompts(event).len;
        const dropdown_prompts = getDropdownPrompts(event).len;
        const prompts_in_onboarding = getPromptsInOnboarding(event).len;
        const default_channels = getDefaultChannelCount(event);

        return .{
            .total_prompts = total_prompts,
            .required_prompts = required_prompts,
            .optional_prompts = optional_prompts,
            .multiple_choice_prompts = multiple_choice_prompts,
            .dropdown_prompts = dropdown_prompts,
            .prompts_in_onboarding = prompts_in_onboarding,
            .default_channels = default_channels,
        };
    }

    pub function hasRequiredPrompts(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) bool {
        return getRequiredPrompts(event).len > 0;
    }

    pub function hasOptionalPrompts(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) bool {
        return getOptionalPrompts(event).len > 0;
    }

    pub function hasMultipleChoicePrompts(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) bool {
        return getMultipleChoicePrompts(event).len > 0;
    }

    pub function hasDropdownPrompts(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) bool {
        return getDropdownPrompts(event).len > 0;
    }

    pub function hasDefaultChannels(event: GuildOnboardingEvents.GuildOnboardingUpdateEvent) bool {
        return getDefaultChannelCount(event) > 0;
    }
};
