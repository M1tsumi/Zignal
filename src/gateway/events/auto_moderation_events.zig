const std = @import("std");
const models = @import("../../models.zig");

/// Auto moderation-related gateway events
pub const AutoModerationEvents = struct {
    /// Auto moderation rule create event
    pub const AutoModerationRuleCreateEvent = struct {
        guild_id: u64,
        rule: models.AutoModerationRule,
    };

    /// Auto moderation rule update event
    pub const AutoModerationRuleUpdateEvent = struct {
        guild_id: u64,
        rule: models.AutoModerationRule,
    };

    /// Auto moderation rule delete event
    pub const AutoModerationRuleDeleteEvent = struct {
        guild_id: u64,
        rule: models.AutoModerationRule,
    };

    /// Auto moderation action execution event
    pub const AutoModerationActionExecutionEvent = struct {
        guild_id: u64,
        action: models.AutoModerationAction,
        rule_id: u64,
        rule_trigger_type: models.AutoModerationTriggerType,
        user_id: u64,
        channel_id: ?u64,
        message_id: ?u64,
        alert_system_message_id: ?u64,
        content: []const u8,
        matched_keyword: ?[]const u8,
        matched_content: ?[]const u8,
    };
};

/// Event parsers for auto moderation events
pub const AutoModerationEventParsers = struct {
    pub fn parseAutoModerationRuleCreateEvent(data: []const u8, allocator: std.mem.Allocator) !AutoModerationEvents.AutoModerationRuleCreateEvent {
        return try std.json.parseFromSliceLeaky(AutoModerationEvents.AutoModerationRuleCreateEvent, allocator, data, .{});
    }

    pub fn parseAutoModerationRuleUpdateEvent(data: []const u8, allocator: std.mem.Allocator) !AutoModerationEvents.AutoModerationRuleUpdateEvent {
        return try std.json.parseFromSliceLeaky(AutoModerationEvents.AutoModerationRuleUpdateEvent, allocator, data, .{});
    }

    pub fn parseAutoModerationRuleDeleteEvent(data: []const u8, allocator: std.mem.Allocator) !AutoModerationEvents.AutoModerationRuleDeleteEvent {
        return try std.json.parseFromSliceLeaky(AutoModerationEvents.AutoModerationRuleDeleteEvent, allocator, data, .{});
    }

    pub fn parseAutoModerationActionExecutionEvent(data: []const u8, allocator: std.mem.Allocator) !AutoModerationEvents.AutoModerationActionExecutionEvent {
        return try std.json.parseFromSliceLeaky(AutoModerationEvents.AutoModerationActionExecutionEvent, allocator, data, .{});
    }
};

/// Auto moderation event utilities
pub const AutoModerationEventUtils = struct {
    pub fn formatRuleEvent(event_type: []const u8, guild_id: u64, rule: models.AutoModerationRule) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Auto moderation rule ");
        try summary.appendSlice(event_type);
        try summary.appendSlice(" - Guild: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{guild_id}));
        try summary.appendSlice(" - Rule: ");
        try summary.appendSlice(rule.name);
        try summary.appendSlice(" (ID: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{rule.id}));
        try summary.appendSlice(")");
        try summary.appendSlice(" - Trigger: ");
        try summary.appendSlice(getTriggerType(rule.trigger_type));
        try summary.appendSlice(" - Actions: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{rule.actions.len}));

        return summary.toOwnedSlice();
    }

    pub fn formatActionExecutionEvent(event: AutoModerationEvents.AutoModerationActionExecutionEvent) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Auto moderation action executed - Guild: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.guild_id}));
        try summary.appendSlice(" - Rule ID: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.rule_id}));
        try summary.appendSlice(" - User: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.user_id}));
        try summary.appendSlice(" - Action: ");
        try summary.appendSlice(getActionType(event.action.type));
        try summary.appendSlice(" - Trigger: ");
        try summary.appendSlice(getTriggerType(event.rule_trigger_type));

        if (event.channel_id) |channel_id| {
            try summary.appendSlice(" - Channel: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{channel_id}));
        }

        if (event.message_id) |message_id| {
            try summary.appendSlice(" - Message: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{message_id}));
        }

        if (event.matched_keyword) |keyword| {
            try summary.appendSlice(" - Keyword: ");
            try summary.appendSlice(keyword);
        }

        return summary.toOwnedSlice();
    }

    pub fn getAffectedGuild(event: AutoModerationEvents.AutoModerationRuleCreateEvent) u64 {
        return event.guild_id;
    }

    pub fn getAffectedGuildUpdate(event: AutoModerationEvents.AutoModerationRuleUpdateEvent) u64 {
        return event.guild_id;
    }

    pub fn getAffectedGuildDelete(event: AutoModerationEvents.AutoModerationRuleDeleteEvent) u64 {
        return event.guild_id;
    }

    pub fn getAffectedGuildAction(event: AutoModerationEvents.AutoModerationActionExecutionEvent) u64 {
        return event.guild_id;
    }

    pub fn getRuleId(event: AutoModerationEvents.AutoModerationRuleCreateEvent) u64 {
        return event.rule.id;
    }

    pub fn getRuleIdUpdate(event: AutoModerationEvents.AutoModerationRuleUpdateEvent) u64 {
        return event.rule.id;
    }

    pub fn getRuleIdDelete(event: AutoModerationEvents.AutoModerationRuleDeleteEvent) u64 {
        return event.rule.id;
    }

    pub fn getRuleIdAction(event: AutoModerationEvents.AutoModerationActionExecutionEvent) u64 {
        return event.rule_id;
    }

    pub fn getRuleName(event: AutoModerationEvents.AutoModerationRuleCreateEvent) []const u8 {
        return event.rule.name;
    }

    pub fn getRuleNameUpdate(event: AutoModerationEvents.AutoModerationRuleUpdateEvent) []const u8 {
        return event.rule.name;
    }

    pub fn getRuleNameDelete(event: AutoModerationEvents.AutoModerationRuleDeleteEvent) []const u8 {
        return event.rule.name;
    }

    pub fn getTriggerType(trigger_type: models.AutoModerationTriggerType) []const u8 {
        return switch (trigger_type) {
            .keyword => "Keyword Filter",
            .spam => "Spam Filter",
            .keyword_preset => "Keyword Preset",
            .mention_spam => "Mention Spam",
            .member_profile => "Member Profile",
        };
    }

    pub fn getActionType(action_type: models.AutoModerationActionType) []const u8 {
        return switch (action_type) {
            .block_message => "Block Message",
            .send_alert_message => "Send Alert",
            .timeout => "Timeout",
            .block_member_interaction => "Block Member Interaction",
        };
    }

    pub fn isRuleEnabled(rule: models.AutoModerationRule) bool {
        return rule.enabled;
    }

    pub fn isRuleExemptRoles(rule: models.AutoModerationRule) bool {
        return rule.exempt_roles.len > 0;
    }

    pub fn isRuleExemptChannels(rule: models.AutoModerationRule) bool {
        return rule.exempt_channels.len > 0;
    }

    pub fn getRuleActionCount(rule: models.AutoModerationRule) usize {
        return rule.actions.len;
    }

    pub fn getRuleExemptRoleCount(rule: models.AutoModerationRule) usize {
        return rule.exempt_roles.len;
    }

    pub fn getRuleExemptChannelCount(rule: models.AutoModerationRule) usize {
        return rule.exempt_channels.len;
    }

    pub fn hasBlockMessageAction(rule: models.AutoModerationRule) bool {
        for (rule.actions) |action| {
            if (action.type == .block_message) {
                return true;
            }
        }
        return false;
    }

    pub fn hasAlertAction(rule: models.AutoModerationRule) bool {
        for (rule.actions) |action| {
            if (action.type == .send_alert_message) {
                return true;
            }
        }
        return false;
    }

    pub fn hasTimeoutAction(rule: models.AutoModerationRule) bool {
        for (rule.actions) |action| {
            if (action.type == .timeout) {
                return true;
            }
        }
        return false;
    }

    pub fn hasBlockInteractionAction(rule: models.AutoModerationRule) bool {
        for (rule.actions) |action| {
            if (action.type == .block_member_interaction) {
                return true;
            }
        }
        return false;
    }

    pub fn getActionExecutionUser(event: AutoModerationEvents.AutoModerationActionExecutionEvent) u64 {
        return event.user_id;
    }

    pub fn getActionExecutionChannel(event: AutoModerationEvents.AutoModerationActionExecutionEvent) ?u64 {
        return event.channel_id;
    }

    pub fn getActionExecutionMessage(event: AutoModerationEvents.AutoModerationActionExecutionEvent) ?u64 {
        return event.message_id;
    }

    pub fn getActionExecutionContent(event: AutoModerationEvents.AutoModerationActionExecutionEvent) []const u8 {
        return event.content;
    }

    pub fn getActionExecutionKeyword(event: AutoModerationEvents.AutoModerationActionExecutionEvent) ?[]const u8 {
        return event.matched_keyword;
    }

    pub fn getActionExecutionMatchedContent(event: AutoModerationEvents.AutoModerationActionExecutionEvent) ?[]const u8 {
        return event.matched_content;
    }

    pub fn isActionExecutionInChannel(event: AutoModerationEvents.AutoModerationActionExecutionEvent) bool {
        return event.channel_id != null;
    }

    pub fn isActionExecutionOnMessage(event: AutoModerationEvents.AutoModerationActionExecutionEvent) bool {
        return event.message_id != null;
    }

    pub fn isActionExecutionWithKeyword(event: AutoModerationEvents.AutoModerationActionExecutionEvent) bool {
        return event.matched_keyword != null;
    }

    pub fn isActionExecutionWithMatchedContent(event: AutoModerationEvents.AutoModerationActionExecutionEvent) bool {
        return event.matched_content != null;
    }

    pub fn isActionExecutionBlockMessage(event: AutoModerationEvents.AutoModerationActionExecutionEvent) bool {
        return event.action.type == .block_message;
    }

    pub fn isActionExecutionAlert(event: AutoModerationEvents.AutoModerationActionExecutionEvent) bool {
        return event.action.type == .send_alert_message;
    }

    pub fn isActionExecutionTimeout(event: AutoModerationEvents.AutoModerationActionExecutionEvent) bool {
        return event.action.type == .timeout;
    }

    pub fn isActionExecutionBlockInteraction(event: AutoModerationEvents.AutoModerationActionExecutionEvent) bool {
        return event.action.type == .block_member_interaction;
    }

    pub fn formatRuleSummary(rule: models.AutoModerationRule) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice(rule.name);
        try summary.appendSlice(" (");
        try summary.appendSlice(getTriggerType(rule.trigger_type));
        try summary.appendSlice(")");

        if (isRuleEnabled(rule)) {
            try summary.appendSlice(" [Enabled]");
        } else {
            try summary.appendSlice(" [Disabled]");
        }

        try summary.appendSlice(" - Actions: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getRuleActionCount(rule)}));
        try summary.appendSlice(" - Exempt Roles: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getRuleExemptRoleCount(rule)}));
        try summary.appendSlice(" - Exempt Channels: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{getRuleExemptChannelCount(rule)}));

        return summary.toOwnedSlice();
    }

    pub fn validateRule(rule: models.AutoModerationRule) bool {
        if (rule.id == 0) return false;
        if (rule.name.len == 0) return false;
        if (rule.actions.len == 0) return false;

        // Validate actions
        for (rule.actions) |action| {
            if (!validateAction(action)) {
                return false;
            }
        }

        return true;
    }

    pub fn validateAction(action: models.AutoModerationAction) bool {
        switch (action.type) {
            .block_message => {},
            .send_alert_message => {},
            .timeout => {
                if (action.metadata.duration_seconds == null) return false;
            },
            .block_member_interaction => {},
        }

        return true;
    }

    pub fn validateRuleCreateEvent(event: AutoModerationEvents.AutoModerationRuleCreateEvent) bool {
        if (event.guild_id == 0) return false;
        return validateRule(event.rule);
    }

    pub fn validateRuleUpdateEvent(event: AutoModerationEvents.AutoModerationRuleUpdateEvent) bool {
        if (event.guild_id == 0) return false;
        return validateRule(event.rule);
    }

    pub fn validateRuleDeleteEvent(event: AutoModerationEvents.AutoModerationRuleDeleteEvent) bool {
        if (event.guild_id == 0) return false;
        return validateRule(event.rule);
    }

    pub fn validateActionExecutionEvent(event: AutoModerationEvents.AutoModerationActionExecutionEvent) bool {
        if (event.guild_id == 0) return false;
        if (event.rule_id == 0) return false;
        if (event.user_id == 0) return false;
        if (event.content.len == 0) return false;

        return validateAction(event.action);
    }

    pub fn getRuleStatistics(rule: models.AutoModerationRule) struct {
        action_count: usize,
        exempt_role_count: usize,
        exempt_channel_count: usize,
        has_block_message: bool,
        has_alert: bool,
        has_timeout: bool,
        has_block_interaction: bool,
    } {
        return .{
            .action_count = getRuleActionCount(rule),
            .exempt_role_count = getRuleExemptRoleCount(rule),
            .exempt_channel_count = getRuleExemptChannelCount(rule),
            .has_block_message = hasBlockMessageAction(rule),
            .has_alert = hasAlertAction(rule),
            .has_timeout = hasTimeoutAction(rule),
            .has_block_interaction = hasBlockInteractionAction(rule),
        };
    }

    pub fn getActionExecutionStatistics(event: AutoModerationEvents.AutoModerationActionExecutionEvent) struct {
        has_channel: bool,
        has_message: bool,
        has_keyword: bool,
        has_matched_content: bool,
        is_block_message: bool,
        is_alert: bool,
        is_timeout: bool,
        is_block_interaction: bool,
    } {
        return .{
            .has_channel = isActionExecutionInChannel(event),
            .has_message = isActionExecutionOnMessage(event),
            .has_keyword = isActionExecutionWithKeyword(event),
            .has_matched_content = isActionExecutionWithMatchedContent(event),
            .is_block_message = isActionExecutionBlockMessage(event),
            .is_alert = isActionExecutionAlert(event),
            .is_timeout = isActionExecutionTimeout(event),
            .is_block_interaction = isActionExecutionBlockInteraction(event),
        };
    }

    pub fn getActionExecutionSummary(event: AutoModerationEvents.AutoModerationActionExecutionEvent) []const u8 {
        var summary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer summary.deinit();

        try summary.appendSlice("Action: ");
        try summary.appendSlice(getActionType(event.action.type));
        try summary.appendSlice(" - User: ");
        try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.user_id}));

        if (isActionExecutionInChannel(event)) {
            try summary.appendSlice(" - Channel: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.channel_id.?}));
        }

        if (isActionExecutionOnMessage(event)) {
            try summary.appendSlice(" - Message: ");
            try summary.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{event.message_id.?}));
        }

        if (isActionExecutionWithKeyword(event)) {
            try summary.appendSlice(" - Keyword: ");
            try summary.appendSlice(event.matched_keyword.?);
        }

        const content_preview = if (event.content.len > 50) event.content[0..50] else event.content;
        try summary.appendSlice(" - Content: \"");
        try summary.appendSlice(content_preview);
        try summary.appendSlice("\"");

        return summary.toOwnedSlice();
    }
};
