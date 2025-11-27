const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");
const Client = @import("../Client.zig");

/// OAuth2 management for Discord authentication
pub const OAuth2Manager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) OAuth2Manager {
        return OAuth2Manager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get current authorization information
    pub fn getCurrentAuthorizationInformation(self: *OAuth2Manager) !models.AuthorizationInformation {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/oauth2/@me",
            .{ self.client.base_url },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.AuthorizationInformation, response.body, .{});
    }

    /// Get current bot application information
    pub fn getCurrentBotApplicationInformation(self: *OAuth2Manager) !models.Application {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/oauth2/applications/@me",
            .{ self.client.base_url },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.Application, response.body, .{});
    }

    /// Authorization code grant
    pub fn authorizationCodeGrant(
        self: *OAuth2Manager,
        client_id: u64,
        client_secret: []const u8,
        grant_type: []const u8,
        code: []const u8,
        redirect_uri: []const u8,
    ) !models.TokenResponse {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/oauth2/token",
            .{ self.client.base_url },
        );
        defer self.allocator.free(url);

        const payload = AuthorizationCodeGrantPayload{
            .client_id = client_id,
            .client_secret = client_secret,
            .grant_type = grant_type,
            .code = code,
            .redirect_uri = redirect_uri,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/x-www-form-urlencoded");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.TokenResponse, response.body, .{});
    }

    /// Refresh token
    pub fn refreshToken(
        self: *OAuth2Manager,
        client_id: u64,
        client_secret: []const u8,
        grant_type: []const u8,
        refresh_token: []const u8,
    ) !models.TokenResponse {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/oauth2/token",
            .{ self.client.base_url },
        );
        defer self.allocator.free(url);

        const payload = RefreshTokenPayload{
            .client_id = client_id,
            .client_secret = client_secret,
            .grant_type = grant_type,
            .refresh_token = refresh_token,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/x-www-form-urlencoded");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.TokenResponse, response.body, .{});
    }

    /// Client credentials grant
    pub fn clientCredentialsGrant(
        self: *OAuth2Manager,
        client_id: u64,
        client_secret: []const u8,
        grant_type: []const u8,
        scope: ?[]const u8,
    ) !models.TokenResponse {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/oauth2/token",
            .{ self.client.base_url },
        );
        defer self.allocator.free(url);

        const payload = ClientCredentialsGrantPayload{
            .client_id = client_id,
            .client_secret = client_secret,
            .grant_type = grant_type,
            .scope = scope,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/x-www-form-urlencoded");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse(models.TokenResponse, response.body, .{});
    }

    /// Revoke token
    pub fn revokeToken(
        self: *OAuth2Manager,
        client_id: u64,
        client_secret: []const u8,
        token: []const u8,
    ) !void {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/oauth2/token/revoke",
            .{ self.client.base_url },
        );
        defer self.allocator.free(url);

        const payload = RevokeTokenPayload{
            .client_id = client_id,
            .client_secret = client_secret,
            .token = token,
        };

        const json_payload = try std.json.stringifyAlloc(self.allocator, payload, .{});
        defer self.allocator.free(json_payload);

        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/x-www-form-urlencoded");

        const response = try self.client.http.post(url, json_payload);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }
    }
};

// Payload structures
const AuthorizationCodeGrantPayload = struct {
    client_id: u64,
    client_secret: []const u8,
    grant_type: []const u8,
    code: []const u8,
    redirect_uri: []const u8,
};

const RefreshTokenPayload = struct {
    client_id: u64,
    client_secret: []const u8,
    grant_type: []const u8,
    refresh_token: []const u8,
};

const ClientCredentialsGrantPayload = struct {
    client_id: u64,
    client_secret: []const u8,
    grant_type: []const u8,
    scope: ?[]const u8 = null,
};

const RevokeTokenPayload = struct {
    client_id: u64,
    client_secret: []const u8,
    token: []const u8,
};
