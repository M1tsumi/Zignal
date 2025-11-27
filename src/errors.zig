const std = @import("std");

/// Comprehensive error system with proper categorization and recovery strategies
pub const ZignalError = error{
    // HTTP/Network Errors
    HttpRequestFailed,
    HttpResponseError,
    HttpTimeout,
    HttpConnectionRefused,
    HttpDnsResolutionFailed,
    HttpTlsHandshakeFailed,
    HttpRateLimited,
    HttpUnauthorized,
    HttpForbidden,
    HttpNotFound,
    HttpInternalServerError,
    HttpBadGateway,
    HttpServiceUnavailable,
    HttpGatewayTimeout,
    
    // WebSocket Errors
    WebSocketConnectionFailed,
    WebSocketHandshakeFailed,
    WebSocketDisconnected,
    WebSocketTimeout,
    WebSocketInvalidFrame,
    WebSocketProtocolError,
    WebSocketAuthenticationFailed,
    
    // Voice Errors
    VoiceConnectionFailed,
    VoiceAuthenticationFailed,
    VoiceEncryptionFailed,
    VoiceDecryptionFailed,
    VoiceUdpConnectionFailed,
    VoiceOpusEncodingFailed,
    VoiceOpusDecodingFailed,
    VoiceInvalidState,
    VoicePermissionDenied,
    
    // JSON Errors
    JsonParseError,
    JsonSerializeError,
    JsonInvalidFormat,
    JsonMissingField,
    JsonInvalidType,
    JsonOutOfRange,
    
    // Cache Errors
    CacheNotFound,
    CacheFull,
    CacheCorrupted,
    CacheInvalidKey,
    CacheSerializationFailed,
    
    // Shard Errors
    ShardConnectionFailed,
    ShardInvalidId,
    ShardAlreadyConnected,
    ShardNotConnected,
    ShardMaxReconnectAttempts,
    
    // Interaction Errors
    InteractionTimeout,
    InteractionInvalidType,
    InteractionInvalidData,
    InteractionAlreadyResponded,
    InteractionPermissionDenied,
    
    // Validation Errors
    InvalidToken,
    InvalidPermissions,
    InvalidIntent,
    InvalidChannelType,
    InvalidGuildId,
    InvalidUserId,
    InvalidMessageId,
    InvalidRoleId,
    
    // State Errors
    InvalidState,
    NotConnected,
    AlreadyConnected,
    NotAuthenticated,
    NotReady,
    
    // Resource Errors
    OutOfMemory,
    ResourceExhausted,
    BufferOverflow,
    FileNotFound,
    PermissionDenied,
    
    // Configuration Errors
    InvalidConfiguration,
    MissingConfiguration,
    ConfigurationConflict,
    
    // System Errors
    SystemError,
    UnknownError,
};

/// Error severity levels for proper handling and logging
pub const ErrorSeverity = enum(u8) {
    trace = 0,
    debug = 1,
    info = 2,
    warning = 3,
    error = 4,
    critical = 5,
    fatal = 6,
};

/// Error context information for debugging and recovery
pub const ErrorContext = struct {
    error_code: ZignalError,
    severity: ErrorSeverity,
    message: []const u8,
    file: []const u8,
    line: u32,
    function: []const u8,
    timestamp: i64,
    user_id: ?u64,
    guild_id: ?u64,
    channel_id: ?u64,
    request_id: ?[]const u8,
    retry_count: u32,
    metadata: std.json.ObjectMap,

    pub fn init(
        allocator: std.mem.Allocator,
        error_code: ZignalError,
        severity: ErrorSeverity,
        message: []const u8,
        file: []const u8,
        line: u32,
        function: []const u8,
    ) ErrorContext {
        return ErrorContext{
            .error_code = error_code,
            .severity = severity,
            .message = message,
            .file = file,
            .line = line,
            .function = function,
            .timestamp = std.time.timestamp(),
            .user_id = null,
            .guild_id = null,
            .channel_id = null,
            .request_id = null,
            .retry_count = 0,
            .metadata = std.json.ObjectMap.init(allocator),
        };
    }

    pub fn deinit(self: *ErrorContext, allocator: std.mem.Allocator) void {
        if (self.request_id) |req_id| allocator.free(req_id);
        self.metadata.deinit();
    }

    pub fn withUser(self: *ErrorContext, user_id: u64) *ErrorContext {
        self.user_id = user_id;
        return self;
    }

    pub fn withGuild(self: *ErrorContext, guild_id: u64) *ErrorContext {
        self.guild_id = guild_id;
        return self;
    }

    pub fn withChannel(self: *ErrorContext, channel_id: u64) *ErrorContext {
        self.channel_id = channel_id;
        return self;
    }

    pub fn withRequestId(self: *ErrorContext, allocator: std.mem.Allocator, request_id: []const u8) !*ErrorContext {
        if (self.request_id) |old_req_id| allocator.free(old_req_id);
        self.request_id = try allocator.dupe(u8, request_id);
        return self;
    }

    pub fn withRetryCount(self: *ErrorContext, retry_count: u32) *ErrorContext {
        self.retry_count = retry_count;
        return self;
    }

    pub fn addMetadata(self: *ErrorContext, key: []const u8, value: std.json.Value) !*ErrorContext {
        try self.metadata.put(key, value);
        return self;
    }

    pub fn toString(self: ErrorContext, allocator: std.mem.Allocator) ![]const u8 {
        var components = std.ArrayList([]const u8).init(allocator);
        defer components.deinit();

        try components.append(try std.fmt.allocPrint(allocator, "[{s}]", .{@tagName(self.severity)}));
        try components.append(try std.fmt.allocPrint(allocator, "{s}", .{@tagName(self.error_code)}));
        try components.append(try std.fmt.allocPrint(allocator, "{s}", .{self.message}));
        try components.append(try std.fmt.allocPrint(allocator, "{s}:{d}", .{ self.file, self.line }));
        try components.append(try std.fmt.allocPrint(allocator, "{s}", .{self.function}));

        if (self.user_id) |uid| {
            try components.append(try std.fmt.allocPrint(allocator, "user:{d}", .{uid}));
        }
        if (self.guild_id) |gid| {
            try components.append(try std.fmt.allocPrint(allocator, "guild:{d}", .{gid}));
        }
        if (self.channel_id) |cid| {
            try components.append(try std.fmt.allocPrint(allocator, "channel:{d}", .{cid}));
        }
        if (self.request_id) |req_id| {
            try components.append(try std.fmt.allocPrint(allocator, "request:{s}", .{req_id}));
        }
        if (self.retry_count > 0) {
            try components.append(try std.fmt.allocPrint(allocator, "retry:{d}", .{self.retry_count}));
        }

        return std.mem.join(allocator, " ", components.items);
    }
};

/// Recovery strategies for different error types
pub const RecoveryStrategy = enum {
    none,
    retry,
    exponential_backoff,
    circuit_breaker,
    fallback,
    reconnect,
    reset,
    escalate,
};

/// Error recovery configuration
pub const RecoveryConfig = struct {
    max_retries: u32 = 3,
    base_delay_ms: u32 = 1000,
    max_delay_ms: u32 = 30000,
    backoff_multiplier: f32 = 2.0,
    jitter: bool = true,
    circuit_breaker_threshold: u32 = 5,
    circuit_breaker_timeout_ms: u32 = 60000,
    fallback_enabled: bool = false,
};

/// Circuit breaker pattern implementation
pub const CircuitBreaker = struct {
    state: CircuitState,
    failure_count: u32,
    last_failure_time: i64,
    config: RecoveryConfig,

    const CircuitState = enum {
        closed,    // Normal operation
        open,      // Failing, reject requests
        half_open, // Testing if service recovered
    };

    pub fn init(config: RecoveryConfig) CircuitBreaker {
        return CircuitBreaker{
            .state = .closed,
            .failure_count = 0,
            .last_failure_time = 0,
            .config = config,
        };
    }

    pub fn canExecute(self: *CircuitBreaker) bool {
        const now = std.time.timestamp();

        switch (self.state) {
            .closed => return true,
            .open => {
                if (now - self.last_failure_time >= self.config.circuit_breaker_timeout_ms / 1000) {
                    self.state = .half_open;
                    return true;
                }
                return false;
            },
            .half_open => return true,
        }
    }

    pub fn onSuccess(self: *CircuitBreaker) void {
        self.failure_count = 0;
        self.state = .closed;
    }

    pub fn onFailure(self: *CircuitBreaker) void {
        self.failure_count += 1;
        self.last_failure_time = std.time.timestamp();

        if (self.failure_count >= self.config.circuit_breaker_threshold) {
            self.state = .open;
        }
    }

    pub fn getState(self: CircuitBreaker) CircuitState {
        return self.state;
    }
};

/// Comprehensive error handler with recovery strategies
pub const ErrorHandler = struct {
    allocator: std.mem.Allocator,
    config: RecoveryConfig,
    circuit_breakers: std.hash_map.StringHashMap(CircuitBreaker),
    error_log: std.ArrayList(ErrorContext),
    max_log_size: usize,
    recovery_callbacks: std.ArrayList(RecoveryCallback),

    const RecoveryCallback = struct {
        error_type: ZignalError,
        callback: *const fn (ctx: *ErrorContext) anyerror!bool,
    };

    pub fn init(allocator: std.mem.Allocator, config: RecoveryConfig, max_log_size: usize) ErrorHandler {
        return ErrorHandler{
            .allocator = allocator,
            .config = config,
            .circuit_breakers = std.hash_map.StringHashMap(CircuitBreaker).init(allocator),
            .error_log = std.ArrayList(ErrorContext).init(allocator),
            .max_log_size = max_log_size,
            .recovery_callbacks = std.ArrayList(RecoveryCallback).init(allocator),
        };
    }

    pub fn deinit(self: *ErrorHandler) void {
        var iter = self.circuit_breakers.iterator();
        while (iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
        }
        self.circuit_breakers.deinit();

        for (self.error_log.items) |*ctx| {
            ctx.deinit(self.allocator);
        }
        self.error_log.deinit();
        self.recovery_callbacks.deinit();
    }

    pub fn handleError(self: *ErrorHandler, error_code: ZignalError, severity: ErrorSeverity, message: []const u8, file: []const u8, line: u32, function: []const u8) !ErrorContext {
        var ctx = ErrorContext.init(self.allocator, error_code, severity, message, file, line, function);
        
        // Log the error
        try self.logError(ctx);

        // Attempt recovery
        const recovered = try self.attemptRecovery(&ctx);
        
        if (!recovered) {
            // Escalate if recovery failed
            if (severity == .critical or severity == .fatal) {
                try self.escalateError(&ctx);
            }
        }

        return ctx;
    }

    pub fn registerRecoveryCallback(self: *ErrorHandler, error_type: ZignalError, callback: *const fn (ctx: *ErrorContext) anyerror!bool) !void {
        try self.recovery_callbacks.append(RecoveryCallback{
            .error_type = error_type,
            .callback = callback,
        });
    }

    fn logError(self: *ErrorHandler, ctx: ErrorContext) !void {
        // Trim log if it exceeds max size
        while (self.error_log.items.len >= self.max_log_size) {
            const old_ctx = self.error_log.orderedRemove(0);
            old_ctx.deinit(self.allocator);
        }

        try self.error_log.append(ctx);

        // Log to console (in production, this would go to proper logging system)
        const error_string = try ctx.toString(self.allocator);
        defer self.allocator.free(error_string);
        std.log.err("{s}", .{error_string});
    }

    fn attemptRecovery(self: *ErrorHandler, ctx: *ErrorContext) !bool {
        const strategy = self.getRecoveryStrategy(ctx.error_code);
        
        switch (strategy) {
            .none => return false,
            .retry, .exponential_backoff => {
                if (ctx.retry_count >= self.config.max_retries) {
                    return false;
                }
                return self.executeRetry(ctx, strategy == .exponential_backoff);
            },
            .circuit_breaker => {
                return self.executeCircuitBreaker(ctx);
            },
            .fallback => {
                return self.executeFallback(ctx);
            },
            .reconnect => {
                return self.executeReconnect(ctx);
            },
            .reset => {
                return self.executeReset(ctx);
            },
            .escalate => {
                return self.executeEscalate(ctx);
            },
        }
    }

    fn getRecoveryStrategy(self: ErrorHandler, error_code: ZignalError) RecoveryStrategy {
        _ = self;
        return switch (error_code) {
            // Network errors - retry with exponential backoff
            .HttpRequestFailed,
            .HttpTimeout,
            .HttpConnectionRefused,
            .HttpDnsResolutionFailed,
            .HttpTlsHandshakeFailed,
            .WebSocketConnectionFailed,
            .WebSocketDisconnected,
            .WebSocketTimeout,
            .VoiceConnectionFailed,
            .VoiceUdpConnectionFailed => .exponential_backoff,

            // Rate limiting - retry with exponential backoff
            .HttpRateLimited => .exponential_backoff,

            // Authentication errors - reconnect
            .HttpUnauthorized,
            .WebSocketAuthenticationFailed,
            .VoiceAuthenticationFailed => .reconnect,

            // Server errors - retry with circuit breaker
            .HttpInternalServerError,
            .HttpBadGateway,
            .HttpServiceUnavailable,
            .HttpGatewayTimeout => .circuit_breaker,

            // State errors - reset
            .InvalidState,
            .NotConnected,
            .AlreadyConnected,
            .NotAuthenticated,
            .NotReady,
            .VoiceInvalidState => .reset,

            // Critical errors - escalate
            .OutOfMemory,
            .ResourceExhausted,
            .SystemError,
            .UnknownError => .escalate,

            // Other errors - simple retry
            .JsonParseError,
            .JsonSerializeError,
            .CacheNotFound,
            .InteractionTimeout => .retry,

            // Permission and validation errors - no recovery
            .HttpForbidden,
            .HttpNotFound,
            .InvalidToken,
            .InvalidPermissions,
            .InvalidIntent,
            .InteractionPermissionDenied,
            .VoicePermissionDenied => .none,
        };
    }

    fn executeRetry(self: *ErrorHandler, ctx: *ErrorContext, exponential: bool) !bool {
        const delay = if (exponential) self.calculateExponentialBackoff(ctx.retry_count) else self.config.base_delay_ms;
        
        // In a real implementation, this would schedule a retry
        _ = delay;
        
        ctx.retry_count += 1;
        return true;
    }

    fn executeCircuitBreaker(self: *ErrorHandler, ctx: *ErrorContext) !bool {
        const key = try std.fmt.allocPrint(self.allocator, "{s}:{d}", .{ @tagName(ctx.error_code), ctx.guild_id orelse 0 });
        defer self.allocator.free(key);

        const breaker = try self.circuit_breakers.getOrPut(key);
        if (!breaker.found_existing) {
            breaker.value_ptr.* = CircuitBreaker.init(self.config);
        }

        if (!breaker.value_ptr.canExecute()) {
            return false;
        }

        // Execute the operation and update circuit breaker based on result
        // In a real implementation, this would execute the actual operation
        breaker.value_ptr.onSuccess();
        return true;
    }

    fn executeFallback(self: *ErrorHandler, ctx: *ErrorContext) !bool {
        _ = self;
        _ = ctx;
        // In a real implementation, this would execute fallback logic
        return false;
    }

    fn executeReconnect(self: *ErrorHandler, ctx: *ErrorContext) !bool {
        _ = self;
        _ = ctx;
        // In a real implementation, this would trigger reconnection
        return true;
    }

    fn executeReset(self: *ErrorHandler, ctx: *ErrorContext) !bool {
        _ = self;
        _ = ctx;
        // In a real implementation, this would reset the connection/state
        return true;
    }

    fn executeEscalate(self: *ErrorHandler, ctx: *ErrorContext) !bool {
        _ = self;
        _ = ctx;
        // In a real implementation, this would escalate to monitoring/alerting
        return false;
    }

    fn calculateExponentialBackoff(self: ErrorHandler, retry_count: u32) u32 {
        const base_delay = self.config.base_delay_ms;
        const multiplier = self.config.backoff_multiplier;
        const delay = @as(u32, @intFromFloat(@as(f64, base_delay) * std.math.pow(f64, multiplier, @as(f64, @floatFromInt(retry_count)))));
        
        const max_delay = self.config.max_delay_ms;
        const capped_delay = @min(delay, max_delay);
        
        if (self.config.jitter) {
            // Add jitter to prevent thundering herd
            const jitter_range = @as(f64, @floatFromInt(capped_delay)) * 0.1;
            const jitter = std.crypto.random.floatNorm(f64) * jitter_range;
            return @intFromFloat(@as(f64, @floatFromInt(capped_delay)) + jitter);
        }
        
        return capped_delay;
    }

    fn escalateError(self: *ErrorHandler, ctx: *ErrorContext) !void {
        // In a real implementation, this would send alerts to monitoring systems
        const escalation_message = try std.fmt.allocPrint(self.allocator, "CRITICAL ERROR ESCALATION: {s}", .{@tagName(ctx.error_code)});
        defer self.allocator.free(escalation_message);
        std.log.critical("{s}", .{escalation_message});
    }

    pub fn getErrorStats(self: ErrorHandler) struct {
        total_errors: usize,
        errors_by_type: std.json.ObjectMap,
        errors_by_severity: std.json.ObjectMap,
        recent_errors: []ErrorContext,
    } {
        var errors_by_type = std.json.ObjectMap.init(self.allocator);
        defer errors_by_type.deinit();
        
        var errors_by_severity = std.json.ObjectMap.init(self.allocator);
        defer errors_by_severity.deinit();

        // Count errors by type and severity
        for (self.error_log.items) |error_ctx| {
            const type_key = @tagName(error_ctx.error_code);
            const type_count = errors_by_type.get(type_key) orelse std.json.Value{ .integer = 0 };
            errors_by_type.put(type_key, std.json.Value{ .integer = type_count.integer + 1 }) catch {};

            const severity_key = @tagName(error_ctx.severity);
            const severity_count = errors_by_severity.get(severity_key) orelse std.json.Value{ .integer = 0 };
            errors_by_severity.put(severity_key, std.json.Value{ .integer = severity_count.integer + 1 }) catch {};
        }

        // Get recent errors (last 10)
        const recent_count = @min(10, self.error_log.items.len);
        const recent_errors = self.allocator.alloc(ErrorContext, recent_count) catch unreachable;
        std.mem.copy(ErrorContext, recent_errors, self.error_log.items[self.error_log.items.len - recent_count..]);

        return .{
            .total_errors = self.error_log.items.len,
            .errors_by_type = errors_by_type,
            .errors_by_severity = errors_by_severity,
            .recent_errors = recent_errors,
        };
    }

    pub fn clearErrors(self: *ErrorHandler) void {
        for (self.error_log.items) |*ctx| {
            ctx.deinit(self.allocator);
        }
        self.error_log.clear();
    }
};

/// Result type with automatic error handling
pub fn Result(comptime T: type) type {
    return struct {
        value: ?T,
        error: ?ErrorContext,

        pub fn success(value: T) @This() {
            return @This(){
                .value = value,
                .error = null,
            };
        }

        pub fn failure(error: ErrorContext) @This() {
            return @This(){
                .value = null,
                .error = error,
            };
        }

        pub fn isSuccess(self: @This()) bool {
            return self.error == null;
        }

        pub fn isError(self: @This()) bool {
            return self.error != null;
        }

        pub fn unwrap(self: @This()) T {
            if (self.error) |err| {
                std.log.err("Attempted to unwrap error result: {s}", .{@tagName(err.error_code)});
                unreachable;
            }
            return self.value.?;
        }

        pub fn unwrapOr(self: @This(), default: T) T {
            if (self.error != null) {
                return default;
            }
            return self.value.?;
        }

        pub fn map(self: @This(), comptime U: type, mapper: *const fn (value: T) U) Result(U) {
            if (self.error) |err| {
                return Result(U).failure(err);
            }
            return Result(U).success(mapper(self.value.?));
        }
    };
}
