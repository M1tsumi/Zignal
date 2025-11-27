const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Guild poll management for Discord server polls
pub const GuildPollManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) GuildPollManager {
        return GuildPollManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Create poll
    pub fn createPoll(
        self: *GuildPollManager,
        channel_id: u64,
        question: models.PollMedia,
        answers: []models.PollAnswer,
        duration: u32,
        allow_multiselect: ?bool,
        layout_type: ?models.PollLayoutType,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/messages",
            .{ self.client.base_url, channel_id },
        );
        defer self.allocator.free(url);

        const payload = CreatePollPayload{
            .content = "",
            .poll = models.Poll{
                .question = question,
                .answers = answers,
                .duration = duration,
                .allow_multiselect = allow_multiselect orelse false,
                .layout_type = layout_type orelse .default,
            },
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

        return try std.json.parse(models.Message, response.body, .{});
    }

    /// Get poll results
    pub fn getPollResults(
        self: *GuildPollManager,
        channel_id: u64,
        message_id: u64,
    ) !models.PollResults {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/polls/{d}/results",
            .{ self.client.base_url, channel_id, message_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.PollResults, response.body, .{});
    }

    /// End poll
    pub fn endPoll(
        self: *GuildPollManager,
        channel_id: u64,
        message_id: u64,
    ) !models.Message {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/polls/{d}/expire",
            .{ self.client.base_url, channel_id, message_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.post(url, "");
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Message, response.body, .{});
    }

    /// Answer poll
    pub fn answerPoll(
        self: *GuildPollManager,
        channel_id: u64,
        message_id: u64,
        answer_ids: []u64,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/channels/{d}/polls/{d}/answers",
            .{ self.client.base_url, channel_id, message_id },
        );
        defer self.allocator.free(url);

        const payload = AnswerPollPayload{
            .answer_ids = answer_ids,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 204) {
            return error.HttpRequestFailed;
        }
    }
};

// Payload structures
const CreatePollPayload = struct {
    content: []const u8,
    poll: models.Poll,
};

const AnswerPollPayload = struct {
    answer_ids: []u64,
};
