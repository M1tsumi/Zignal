const std = @import("std");
const models = @import("models.zig");
const errors = @import("errors.zig");
const logging = @import("logging.zig");

const PoolError = error{
    OutOfMemory,
    ConnectionFailed,
    RequestFailed,
    InvalidResponse,
};

/// HTTP connection pool for efficient connection reuse
pub const ConnectionPool = struct {
    allocator: std.mem.Allocator,
    max_connections: usize,
    max_idle_time_ms: u64,
    connections: std.ArrayList(PooledConnection),
    available_connections: std.ArrayList(usize),
    connection_counter: u64,
    metrics: PoolMetrics,

    pub const PooledConnection = struct {
        id: u64,
        client: std.http.Client,
        last_used: i64,
        in_use: bool,
        requests_served: u64,
        created_at: i64,
        endpoint: []const u8,

        pub fn deinit(self: *PooledConnection) void {
            self.client.deinit();
        }
    };

    pub const PoolMetrics = struct {
        total_connections_created: u64,
        total_connections_closed: u64,
        active_connections: u64,
        idle_connections: u64,
        requests_served: u64,
        connection_reuse_count: u64,
        average_connection_lifetime_ms: f64,

        pub fn reset(self: *PoolMetrics) void {
            self.* = std.mem.zeroes(PoolMetrics);
        }
    };

    pub fn init(allocator: std.mem.Allocator, max_connections: usize, max_idle_time_ms: u64) ConnectionPool {
        return ConnectionPool{
            .allocator = allocator,
            .max_connections = max_connections,
            .max_idle_time_ms = max_idle_time_ms,
            .connections = std.ArrayList(PooledConnection).init(allocator),
            .available_connections = std.ArrayList(usize).init(allocator),
            .connection_counter = 0,
            .metrics = std.mem.zeroes(PoolMetrics),
        };
    }

    pub fn deinit(self: *ConnectionPool) void {
        for (self.connections.items) |*connection| {
            connection.deinit();
            self.allocator.free(connection.endpoint);
        }
        self.connections.deinit();
        self.available_connections.deinit();
    }

    pub fn acquire(self: *ConnectionPool, endpoint: []const u8) !*PooledConnection {
        const now = std.time.timestamp();

        // Try to reuse an available connection to the same endpoint
        for (self.available_connections.items) |index| {
            const connection = &self.connections.items[index];

            if (std.mem.eql(u8, connection.endpoint, endpoint) and
                !connection.in_use and
                (now - connection.last_used) * 1000 <= self.max_idle_time_ms)
            {
                connection.in_use = true;
                connection.last_used = now;
                connection.requests_served += 1;
                self.metrics.connection_reuse_count += 1;

                // Remove from available list
                _ = self.available_connections.orderedRemove(index);
                self.metrics.idle_connections -= 1;
                self.metrics.active_connections += 1;

                return connection;
            }
        }

        // Create new connection if we haven't reached the limit
        if (self.connections.items.len < self.max_connections) {
            return self.createConnection(endpoint);
        }

        // Clean up idle connections and try again
        self.cleanupIdleConnections();

        // Try to find an available connection after cleanup
        for (self.available_connections.items) |index| {
            const connection = &self.connections.items[index];

            if (std.mem.eql(u8, connection.endpoint, endpoint) and !connection.in_use) {
                connection.in_use = true;
                connection.last_used = now;
                connection.requests_served += 1;
                self.metrics.connection_reuse_count += 1;

                // Remove from available list
                _ = self.available_connections.orderedRemove(index);
                self.metrics.idle_connections -= 1;
                self.metrics.active_connections += 1;

                return connection;
            }
        }

        return error.PoolExhausted;
    }

    pub fn release(self: *ConnectionPool, connection: *PooledConnection) void {
        if (!connection.in_use) return;

        connection.in_use = false;
        connection.last_used = std.time.timestamp();

        // Add to available list
        self.available_connections.append(self.connections.items.len) catch {};
        self.metrics.idle_connections += 1;
        self.metrics.active_connections -= 1;
    }

    fn createConnection(self: *ConnectionPool, endpoint: []const u8) !*PooledConnection {
        const connection_id = self.connection_counter;
        self.connection_counter += 1;

        const client = std.http.Client{ .allocator = self.allocator };

        const pooled_connection = PooledConnection{
            .id = connection_id,
            .client = client,
            .last_used = std.time.timestamp(),
            .in_use = true,
            .requests_served = 0,
            .created_at = std.time.timestamp(),
            .endpoint = try self.allocator.dupe(u8, endpoint),
        };

        try self.connections.append(pooled_connection);
        self.metrics.total_connections_created += 1;
        self.metrics.active_connections += 1;

        return &self.connections.items[self.connections.items.len - 1];
    }

    fn cleanupIdleConnections(self: *ConnectionPool) void {
        const now = std.time.timestamp();
        var i: usize = 0;

        while (i < self.available_connections.items.len) {
            const index = self.available_connections.items[i];
            const connection = &self.connections.items[index];

            if ((now - connection.last_used) * 1000 > self.max_idle_time_ms) {
                // Close and remove the connection
                connection.deinit();
                self.allocator.free(connection.endpoint);

                // Remove from connections list
                _ = self.connections.orderedRemove(index);

                // Remove from available list
                _ = self.available_connections.orderedRemove(i);

                self.metrics.total_connections_closed += 1;
                self.metrics.idle_connections -= 1;

                // Update remaining indices
                for (self.available_connections.items) |*available_index| {
                    if (available_index.* > index) {
                        available_index.* -= 1;
                    }
                }
            } else {
                i += 1;
            }
        }
    }

    pub fn getMetrics(self: ConnectionPool) PoolMetrics {
        return self.metrics;
    }

    pub fn getStats(self: ConnectionPool) struct {
        total_connections: usize,
        active_connections: usize,
        idle_connections: usize,
        available_connections: usize,
        connection_utilization: f64,
    } {
        const total = self.connections.items.len;
        const active = self.metrics.active_connections;
        const idle = self.metrics.idle_connections;
        const available = self.available_connections.items.len;
        const utilization = if (total > 0) @as(f64, @floatFromInt(active)) / @as(f64, @floatFromInt(total)) else 0.0;

        return .{
            .total_connections = total,
            .active_connections = active,
            .idle_connections = idle,
            .available_connections = available,
            .connection_utilization = utilization,
        };
    }
};

/// Request batching system for efficient Discord API calls
pub const RequestBatcher = struct {
    allocator: std.mem.Allocator,
    max_batch_size: usize,
    max_wait_time_ms: u64,
    pending_requests: std.ArrayList(PendingRequest),
    batch_handlers: std.ArrayList(BatchHandler),
    metrics: BatchMetrics,

    pub const PendingRequest = struct {
        id: u64,
        method: []const u8,
        url: []const u8,
        headers: std.json.ObjectMap,
        body: ?[]const u8,
        timestamp: i64,
        callback: *const fn (result: BatchResult) void,
        timeout_ms: u64,
        retry_count: u32,
        max_retries: u32,

        pub fn deinit(self: *PendingRequest, allocator: std.mem.Allocator) void {
            allocator.free(self.method);
            allocator.free(self.url);
            self.headers.deinit();
            if (self.body) |body| allocator.free(body);
        }
    };

    pub const BatchHandler = struct {
        endpoint_pattern: []const u8,
        batch_processor: *const fn (requests: []PendingRequest, allocator: std.mem.Allocator) PoolError!BatchResult,
        max_batch_size: usize,
        priority: u8,

        pub fn deinit(self: BatchHandler, allocator: std.mem.Allocator) void {
            allocator.free(self.endpoint_pattern);
        }
    };

    pub const BatchResult = struct {
        success: bool,
        responses: []BatchResponse,
        errors: []BatchError,

        pub const BatchResponse = struct {
            request_id: u64,
            status_code: u16,
            headers: std.json.ObjectMap,
            body: []const u8,
            duration_ms: u64,

            pub fn deinit(self: BatchResponse, allocator: std.mem.Allocator) void {
                self.headers.deinit();
                allocator.free(self.body);
            }
        };

        pub const BatchError = struct {
            request_id: u64,
            error_code: errors.ZignalError,
            message: []const u8,
            retry_after_ms: ?u64,

            pub fn deinit(self: BatchError, allocator: std.mem.Allocator) void {
                allocator.free(self.message);
            }
        };

        pub fn deinit(self: BatchResult, allocator: std.mem.Allocator) void {
            for (self.responses) |*response| {
                response.deinit(allocator);
            }
            for (self.errors) |*error_item| {
                error_item.deinit(allocator);
            }
            allocator.free(self.responses);
            allocator.free(self.errors);
        }
    };

    pub const BatchMetrics = struct {
        total_batches_processed: u64,
        total_requests_processed: u64,
        average_batch_size: f64,
        average_processing_time_ms: f64,
        failed_batches: u64,
        retry_count: u64,
        throughput_requests_per_second: f64,

        pub fn reset(self: *BatchMetrics) void {
            self.* = std.mem.zeroes(BatchMetrics);
        }
    };

    pub fn init(allocator: std.mem.Allocator, max_batch_size: usize, max_wait_time_ms: u64) RequestBatcher {
        return RequestBatcher{
            .allocator = allocator,
            .max_batch_size = max_batch_size,
            .max_wait_time_ms = max_wait_time_ms,
            .pending_requests = std.ArrayList(PendingRequest).init(allocator),
            .batch_handlers = std.ArrayList(BatchHandler).init(allocator),
            .metrics = std.mem.zeroes(BatchMetrics),
        };
    }

    pub fn deinit(self: *RequestBatcher) void {
        for (self.pending_requests.items) |*request| {
            request.deinit(self.allocator);
        }
        self.pending_requests.deinit();

        for (self.batch_handlers.items) |*handler| {
            handler.deinit(self.allocator);
        }
        self.batch_handlers.deinit();
    }

    pub fn addRequest(
        self: *RequestBatcher,
        method: []const u8,
        url: []const u8,
        headers: std.json.ObjectMap,
        body: ?[]const u8,
        callback: *const fn (result: BatchResult) void,
        timeout_ms: u64,
        max_retries: u32,
    ) !void {
        const request_id = std.crypto.random.int(u64);

        const request = PendingRequest{
            .id = request_id,
            .method = try self.allocator.dupe(u8, method),
            .url = try self.allocator.dupe(u8, url),
            .headers = headers,
            .body = if (body) |b| try self.allocator.dupe(u8, b) else null,
            .timestamp = std.time.timestamp(),
            .callback = callback,
            .timeout_ms = timeout_ms,
            .retry_count = 0,
            .max_retries = max_retries,
        };

        try self.pending_requests.append(request);

        // Check if we should process the batch immediately
        if (self.pending_requests.items.len >= self.max_batch_size) {
            try self.processBatch();
        }
    }

    pub fn addBatchHandler(
        self: *RequestBatcher,
        endpoint_pattern: []const u8,
        batch_processor: *const fn (requests: []PendingRequest, allocator: std.mem.Allocator) PoolError!BatchResult,
        max_batch_size: usize,
        priority: u8,
    ) !void {
        const handler = BatchHandler{
            .endpoint_pattern = try self.allocator.dupe(u8, endpoint_pattern),
            .batch_processor = batch_processor,
            .max_batch_size = max_batch_size,
            .priority = priority,
        };
        try self.batch_handlers.append(handler);
    }

    pub fn processBatch(self: *RequestBatcher) !void {
        if (self.pending_requests.items.len == 0) return;

        const start_time = std.time.nanoTimestamp();

        // Group requests by endpoint pattern
        var grouped_requests = std.ArrayList(struct {
            handler: *BatchHandler,
            requests: std.ArrayList(PendingRequest),
        }).init(self.allocator);
        defer grouped_requests.deinit();

        // Find matching handlers for each request
        for (self.pending_requests.items) |request| {
            for (self.batch_handlers.items) |*handler| {
                if (self.matchesPattern(request.url, handler.endpoint_pattern)) {
                    // Find or create group
                    var found_group = false;
                    for (grouped_requests.items) |*group| {
                        if (group.handler == handler) {
                            try group.requests.append(request);
                            found_group = true;
                            break;
                        }
                    }

                    if (!found_group) {
                        var requests = std.ArrayList(PendingRequest).init(self.allocator);
                        try requests.append(request);
                        try grouped_requests.append(.{
                            .handler = handler,
                            .requests = requests,
                        });
                    }
                    break;
                }
            }
        }

        // Process each group
        for (grouped_requests.items) |group| {
            const batch_size = @min(group.requests.items.len, group.handler.max_batch_size);
            const batch_requests = try self.allocator.dupe(PendingRequest, group.requests.items[0..batch_size]);

            const result = group.handler.batch_processor(batch_requests, self.allocator) catch |err| {
                // Handle batch processing error
                const error_result = BatchResult{
                    .success = false,
                    .responses = try self.allocator.dupe(BatchResult.BatchResponse, &[_]BatchResult.BatchResponse{}),
                    .errors = try self.allocator.dupe(BatchResult.BatchError, &[_]BatchResult.BatchError{
                        .{
                            .request_id = 0,
                            .error_code = errors.ZignalError.HttpRequestFailed,
                            .message = try std.fmt.allocPrint(self.allocator, "Batch processing failed: {}", .{err}),
                            .retry_after_ms = null,
                        },
                    }),
                };

                for (batch_requests) |request| {
                    request.callback(error_result);
                }

                error_result.deinit(self.allocator);
                continue;
            };

            // Call callbacks for each request
            for (batch_requests) |request| {
                request.callback(result);
            }

            // Remove processed requests from pending list
            for (batch_requests) |request| {
                for (self.pending_requests.items, 0..) |pending_request, idx| {
                    if (pending_request.id == request.id) {
                        _ = self.pending_requests.orderedRemove(idx);
                        break;
                    }
                }
                request.deinit(self.allocator);
            }
            self.allocator.free(batch_requests);
            result.deinit(self.allocator);
        }

        const end_time = std.time.nanoTimestamp();
        const processing_time_ms = @as(f64, @floatFromInt(end_time - start_time)) / 1_000_000.0;

        // Update metrics
        self.metrics.total_batches_processed += 1;
        self.metrics.total_requests_processed += grouped_requests.items.len;
        self.metrics.average_processing_time_ms =
            (self.metrics.average_processing_time_ms * @as(f64, @floatFromInt(self.metrics.total_batches_processed - 1)) + processing_time_ms) /
            @as(f64, @floatFromInt(self.metrics.total_batches_processed));

        grouped_requests.deinit();
    }

    fn matchesPattern(self: RequestBatcher, url: []const u8, pattern: []const u8) bool {
        _ = self;
        // Simple pattern matching - in a real implementation, this would be more sophisticated
        return std.mem.startsWith(u8, url, pattern);
    }

    pub fn processTimeouts(self: *RequestBatcher) void {
        const now = std.time.timestamp();

        var i: usize = 0;
        while (i < self.pending_requests.items.len) {
            const request = &self.pending_requests.items[i];

            if ((now - request.timestamp) * 1000 > request.timeout_ms) {
                // Handle timeout
                if (request.retry_count < request.max_retries) {
                    // Retry the request
                    request.retry_count += 1;
                    request.timestamp = now;
                    self.metrics.retry_count += 1;

                    logging.info(
                        "Retrying request {d} (attempt {d}/{d})",
                        .{ request.id, request.retry_count + 1, request.max_retries },
                    );

                    i += 1;
                } else {
                    // Max retries exceeded, fail the request
                    const error_result = BatchResult{
                        .success = false,
                        .responses = try self.allocator.dupe(BatchResult.BatchResponse, &[_]BatchResult.BatchResponse{}),
                        .errors = try self.allocator.dupe(BatchResult.BatchError, &[_]BatchResult.BatchError{
                            .{
                                .request_id = request.id,
                                .error_code = errors.ZignalError.HttpTimeout,
                                .message = try std.fmt.allocPrint(self.allocator, "Request timed out after {d}ms", .{request.timeout_ms}),
                                .retry_after_ms = null,
                            },
                        }),
                    };

                    request.callback(error_result);
                    error_result.deinit(self.allocator);

                    // Remove from pending list
                    request.deinit(self.allocator);
                    _ = self.pending_requests.orderedRemove(i);
                }
            } else {
                i += 1;
            }
        }
    }

    pub fn getMetrics(self: RequestBatcher) BatchMetrics {
        return self.metrics;
    }

    pub fn getStats(self: RequestBatcher) struct {
        pending_requests: usize,
        batch_handlers: usize,
        average_wait_time_ms: f64,
        oldest_request_age_ms: u64,
    } {
        const now = std.time.timestamp();
        var oldest_age_ms: u64 = 0;

        for (self.pending_requests.items) |request| {
            const age_ms = @as(u64, @intCast((now - request.timestamp) * 1000));
            oldest_age_ms = @max(oldest_age_ms, age_ms);
        }

        return .{
            .pending_requests = self.pending_requests.items.len,
            .batch_handlers = self.batch_handlers.items.len,
            .average_wait_time_ms = self.max_wait_time_ms,
            .oldest_request_age_ms = oldest_age_ms,
        };
    }
};

/// Rate limiter with token bucket algorithm
pub const RateLimiter = struct {
    allocator: std.mem.Allocator,
    capacity: u32,
    refill_rate: f64, // tokens per second
    tokens: f64,
    last_refill: i64,
    metrics: RateLimiterMetrics,

    pub const RateLimiterMetrics = struct {
        total_requests: u64,
        allowed_requests: u64,
        denied_requests: u64,
        average_wait_time_ms: f64,
        current_tokens: f64,

        pub fn reset(self: *RateLimiterMetrics) void {
            self.* = std.mem.zeroes(RateLimiterMetrics);
        }
    };

    pub fn init(allocator: std.mem.Allocator, capacity: u32, refill_rate: f64) RateLimiter {
        return RateLimiter{
            .allocator = allocator,
            .capacity = capacity,
            .refill_rate = refill_rate,
            .tokens = @as(f64, @floatFromInt(capacity)),
            .last_refill = std.time.timestamp(),
            .metrics = std.mem.zeroes(RateLimiterMetrics),
        };
    }

    pub fn tryAcquire(self: *RateLimiter) bool {
        self.refillTokens();

        if (self.tokens >= 1.0) {
            self.tokens -= 1.0;
            self.metrics.total_requests += 1;
            self.metrics.allowed_requests += 1;
            self.metrics.current_tokens = self.tokens;
            return true;
        } else {
            self.metrics.total_requests += 1;
            self.metrics.denied_requests += 1;
            self.metrics.current_tokens = self.tokens;
            return false;
        }
    }

    pub fn acquire(self: *RateLimiter, timeout_ms: u64) !bool {
        const start_time = std.time.nanoTimestamp();

        while (true) {
            if (self.tryAcquire()) {
                const end_time = std.time.nanoTimestamp();
                const wait_time_ms = @as(f64, @floatFromInt(end_time - start_time)) / 1_000_000.0;

                // Update average wait time
                self.metrics.average_wait_time_ms =
                    (self.metrics.average_wait_time_ms * @as(f64, @floatFromInt(self.metrics.allowed_requests - 1)) + wait_time_ms) /
                    @as(f64, @floatFromInt(self.metrics.allowed_requests));

                return true;
            }

            // Check timeout
            const elapsed_ms = @as(u64, @intCast((std.time.nanoTimestamp() - start_time) / 1_000_000));
            if (elapsed_ms >= timeout_ms) {
                return false;
            }

            // Wait a bit before retrying
            std.time.sleep(10_000_000); // 10ms
        }
    }

    pub fn getWaitTime(self: *RateLimiter) u64 {
        self.refillTokens();

        if (self.tokens >= 1.0) {
            return 0;
        }

        const tokens_needed = 1.0 - self.tokens;
        const wait_time_seconds = tokens_needed / self.refill_rate;
        return @as(u64, @intFromFloat(wait_time_seconds * 1000.0));
    }

    fn refillTokens(self: *RateLimiter) void {
        const now = std.time.timestamp();
        const time_passed = @as(f64, @floatFromInt(now - self.last_refill));

        if (time_passed > 0.0) {
            const tokens_to_add = time_passed * self.refill_rate;
            self.tokens = @min(@as(f64, @floatFromInt(self.capacity)), self.tokens + tokens_to_add);
            self.last_refill = now;
        }
    }

    pub fn getMetrics(self: RateLimiter) RateLimiterMetrics {
        return self.metrics;
    }

    pub fn getStats(self: RateLimiter) struct {
        capacity: u32,
        current_tokens: f64,
        refill_rate: f64,
        utilization: f64,
    } {
        const utilization = if (self.capacity > 0)
            (@as(f64, @floatFromInt(self.capacity)) - self.tokens) / @as(f64, @floatFromInt(self.capacity))
        else
            0.0;

        return .{
            .capacity = self.capacity,
            .current_tokens = self.tokens,
            .refill_rate = self.refill_rate,
            .utilization = utilization,
        };
    }
};

/// Performance monitor for tracking system performance
pub const PerformanceMonitor = struct {
    allocator: std.mem.Allocator,
    connection_pool: *ConnectionPool,
    request_batcher: *RequestBatcher,
    rate_limiters: std.ArrayList(RateLimiter),
    logger: *logging.Logger,
    metrics: PerformanceMetrics,

    pub const PerformanceMetrics = struct {
        total_requests: u64,
        successful_requests: u64,
        failed_requests: u64,
        average_response_time_ms: f64,
        requests_per_second: f64,
        connection_reuse_rate: f64,
        batch_efficiency: f64,
        memory_usage_mb: f64,
        cpu_usage_percent: f64,

        pub fn reset(self: *PerformanceMetrics) void {
            self.* = std.mem.zeroes(PerformanceMetrics);
        }
    };

    pub fn init(
        allocator: std.mem.Allocator,
        connection_pool: *ConnectionPool,
        request_batcher: *RequestBatcher,
        logger: *logging.Logger,
    ) PerformanceMonitor {
        return PerformanceMonitor{
            .allocator = allocator,
            .connection_pool = connection_pool,
            .request_batcher = request_batcher,
            .rate_limiters = std.ArrayList(RateLimiter).init(allocator),
            .logger = logger,
            .metrics = std.mem.zeroes(PerformanceMetrics),
        };
    }

    pub fn deinit(self: *PerformanceMonitor) void {
        self.rate_limiters.deinit();
    }

    pub fn addRateLimiter(self: *PerformanceMonitor, rate_limiter: RateLimiter) !void {
        try self.rate_limiters.append(rate_limiter);
    }

    pub fn recordRequest(self: *PerformanceMonitor, response_time_ms: u64, success: bool) void {
        self.metrics.total_requests += 1;

        if (success) {
            self.metrics.successful_requests += 1;
        } else {
            self.metrics.failed_requests += 1;
        }

        // Update average response time
        self.metrics.average_response_time_ms =
            (self.metrics.average_response_time_ms * @as(f64, @floatFromInt(self.metrics.total_requests - 1)) + @as(f64, @floatFromInt(response_time_ms))) /
            @as(f64, @floatFromInt(self.metrics.total_requests));
    }

    pub fn updateMetrics(self: *PerformanceMonitor) void {
        // Update connection pool metrics
        _ = self.connection_pool.getStats();
        const pool_metrics = self.connection_pool.getMetrics();

        if (pool_metrics.total_connections_created > 0) {
            self.metrics.connection_reuse_rate =
                @as(f64, @floatFromInt(pool_metrics.connection_reuse_count)) /
                @as(f64, @floatFromInt(pool_metrics.total_connections_created));
        }

        // Update batch metrics
        const batch_metrics = self.request_batcher.getMetrics();
        if (batch_metrics.total_batches_processed > 0) {
            self.metrics.batch_efficiency =
                @as(f64, @floatFromInt(batch_metrics.total_requests_processed)) /
                @as(f64, @floatFromInt(batch_metrics.total_batches_processed));
        }

        // Calculate requests per second (simplified)
        if (self.metrics.total_requests > 0) {
            self.metrics.requests_per_second =
                @as(f64, @floatFromInt(self.metrics.total_requests)) /
                @as(f64, @floatFromInt(60.0)); // Assuming 1 minute window
        }

        // Memory usage (simplified - would use actual system metrics)
        self.metrics.memory_usage_mb = 0.0; // Would implement actual memory tracking

        // CPU usage (simplified - would use actual system metrics)
        self.metrics.cpu_usage_percent = 0.0; // Would implement actual CPU tracking
    }

    pub fn getMetrics(self: PerformanceMonitor) PerformanceMetrics {
        self.updateMetrics();
        return self.metrics;
    }

    pub fn getStats(self: PerformanceMonitor) struct {
        connection_pool: ConnectionPool.getStats.return_type,
        request_batcher: RequestBatcher.getStats.return_type,
        rate_limiters: usize,
        performance: PerformanceMetrics,
    } {
        return .{
            .connection_pool = self.connection_pool.getStats(),
            .request_batcher = self.request_batcher.getStats(),
            .rate_limiters = self.rate_limiters.items.len,
            .performance = self.getMetrics(),
        };
    }

    pub fn generateReport(self: PerformanceMonitor) ![]const u8 {
        const stats = self.getStats();

        var report = std.ArrayList(u8).init(self.allocator);
        defer report.deinit();

        try report.appendSlice("=== Performance Report ===\n\n");

        try report.appendSlice("Connection Pool:\n");
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Total: {d}\n", .{stats.connection_pool.total_connections}));
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Active: {d}\n", .{stats.connection_pool.active_connections}));
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Idle: {d}\n", .{stats.connection_pool.idle_connections}));
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Utilization: {d:.2}%\n\n", .{stats.connection_pool.connection_utilization * 100.0}));

        try report.appendSlice("Request Batching:\n");
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Pending: {d}\n", .{stats.request_batcher.pending_requests}));
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Handlers: {d}\n", .{stats.request_batcher.batch_handlers}));
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Average Wait: {d:.2}ms\n\n", .{stats.request_batcher.average_wait_time_ms}));

        try report.appendSlice("Performance Metrics:\n");
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Total Requests: {d}\n", .{stats.performance.total_requests}));
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Success Rate: {d:.2}%\n", .{@as(f64, @floatFromInt(stats.performance.successful_requests)) / @as(f64, @floatFromInt(stats.performance.total_requests)) * 100.0}));
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Average Response Time: {d:.2}ms\n", .{stats.performance.average_response_time_ms}));
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Requests/sec: {d:.2}\n", .{stats.performance.requests_per_second}));
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Connection Reuse Rate: {d:.2}%\n", .{stats.performance.connection_reuse_rate * 100.0}));
        try report.appendSlice(try std.fmt.allocPrint(self.allocator, "  Batch Efficiency: {d:.2}\n", .{stats.performance.batch_efficiency}));

        return report.toOwnedSlice();
    }
};
