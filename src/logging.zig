const std = @import("std");
const errors = @import("errors.zig");

/// Comprehensive logging system with structured logging and monitoring
pub const Logger = struct {
    allocator: std.mem.Allocator,
    level: LogLevel,
    handlers: std.ArrayList(LogHandler),
    context: std.json.ObjectMap,
    metrics: Metrics,

    pub const LogLevel = enum(u8) {
        trace = 0,
        debug = 1,
        info = 2,
        warning = 3,
        err = 4,
        critical = 5,
        fatal = 6,
        off = 7,

        pub fn fromString(str: []const u8) ?LogLevel {
            if (std.mem.eql(u8, str, "trace")) return .trace;
            if (std.mem.eql(u8, str, "debug")) return .debug;
            if (std.mem.eql(u8, str, "info")) return .info;
            if (std.mem.eql(u8, str, "warning")) return .warning;
            if (std.mem.eql(u8, str, "error")) return .err;
            if (std.mem.eql(u8, str, "critical")) return .critical;
            if (std.mem.eql(u8, str, "fatal")) return .fatal;
            if (std.mem.eql(u8, str, "off")) return .off;
            return null;
        }

        pub fn toString(self: LogLevel) []const u8 {
            return switch (self) {
                .trace => "TRACE",
                .debug => "DEBUG",
                .info => "INFO",
                .warning => "WARNING",
                .err => "ERROR",
                .critical => "CRITICAL",
                .fatal => "FATAL",
                .off => "OFF",
            };
        }

        pub fn shouldLog(self: LogLevel, target_level: LogLevel) bool {
            return @intFromEnum(self) >= @intFromEnum(target_level);
        }
    };

    pub const LogEntry = struct {
        timestamp: i64,
        level: LogLevel,
        message: []const u8,
        file: []const u8,
        line: u32,
        function: []const u8,
        thread_id: u64,
        context: std.json.ObjectMap,
        error_info: ?errors.ErrorContext,

        pub fn deinit(self: LogEntry, allocator: std.mem.Allocator) void {
            allocator.free(self.message);
            allocator.free(self.file);
            allocator.free(self.function);
            self.context.deinit();
            if (self.error_info) |*err_ctx| {
                err_ctx.deinit(allocator);
            }
        }

        pub fn toJson(self: LogEntry, allocator: std.mem.Allocator) !std.json.Value {
            var obj = std.json.ObjectMap.init(allocator);

            try obj.put("timestamp", std.json.Value{ .integer = self.timestamp });
            try obj.put("level", std.json.Value{ .string = try allocator.dupe(u8, self.level.toString()) });
            try obj.put("message", std.json.Value{ .string = try allocator.dupe(u8, self.message) });
            try obj.put("file", std.json.Value{ .string = try allocator.dupe(u8, self.file) });
            try obj.put("line", std.json.Value{ .integer = self.line });
            try obj.put("function", std.json.Value{ .string = try allocator.dupe(u8, self.function) });
            try obj.put("thread_id", std.json.Value{ .integer = self.thread_id });
            try obj.put("context", std.json.Value{ .object = self.context });

            if (self.error_info) |*err_ctx| {
                var error_obj = std.json.ObjectMap.init(allocator);
                try error_obj.put("code", std.json.Value{ .string = try allocator.dupe(u8, @tagName(err_ctx.error_code)) });
                try error_obj.put("severity", std.json.Value{ .string = try allocator.dupe(u8, @tagName(err_ctx.severity)) });
                try error_obj.put("message", std.json.Value{ .string = try allocator.dupe(u8, err_ctx.message) });
                try error_obj.put("retry_count", std.json.Value{ .integer = err_ctx.retry_count });

                if (err_ctx.user_id) |user_id| {
                    try error_obj.put("user_id", std.json.Value{ .integer = user_id });
                }
                if (err_ctx.guild_id) |guild_id| {
                    try error_obj.put("guild_id", std.json.Value{ .integer = guild_id });
                }
                if (err_ctx.channel_id) |channel_id| {
                    try error_obj.put("channel_id", std.json.Value{ .integer = channel_id });
                }
                if (err_ctx.request_id) |request_id| {
                    try error_obj.put("request_id", std.json.Value{ .string = try allocator.dupe(u8, request_id) });
                }

                try obj.put("error", std.json.Value{ .object = error_obj });
            }

            return std.json.Value{ .object = obj };
        }
    };

    pub const LogHandler = struct {
        level: LogLevel,
        formatter: *const fn (entry: LogEntry, allocator: std.mem.Allocator) []const u8,
        output: *const fn (formatted: []const u8) void,

        pub fn consoleFormatter(entry: LogEntry, allocator: std.mem.Allocator) []const u8 {
            const timestamp_str = std.fmt.allocPrint(allocator, "{d}", .{entry.timestamp}) catch return "";
            defer allocator.free(timestamp_str);

            const level_str = entry.level.toString();
            const file_line = std.fmt.allocPrint(allocator, "{s}:{d}", .{ entry.file, entry.line }) catch return "";
            defer allocator.free(file_line);

            var components = std.ArrayList([]const u8).init(allocator);
            defer components.deinit();

            components.append(std.fmt.allocPrint(allocator, "[{s}]", .{timestamp_str}) catch "") catch {};
            components.append(std.fmt.allocPrint(allocator, "[{s}]", .{level_str}) catch "") catch {};
            components.append(std.fmt.allocPrint(allocator, "[{s}]", .{file_line}) catch "") catch {};
            components.append(std.fmt.allocPrint(allocator, "{s}", .{entry.message}) catch "") catch {};

            if (entry.error_info) |*err_ctx| {
                components.append(std.fmt.allocPrint(allocator, "({s}: {s})", .{ @tagName(err_ctx.error_code), err_ctx.message }) catch "") catch {};
            }

            return std.mem.join(allocator, " ", components.items) catch "";
        }

        pub fn consoleOutput(formatted: []const u8) void {
            std.log.info("{s}", .{formatted});
        }

        pub fn jsonFormatter(entry: LogEntry, allocator: std.mem.Allocator) []const u8 {
            const json_value = entry.toJson(allocator) catch return "";
            return std.json.stringifyAlloc(allocator, json_value, .{ .whitespace = .indent_2 }) catch "";
        }

        pub fn fileOutput(formatted: []const u8) void {
            // In a real implementation, this would write to a file
            _ = formatted;
        }
    };

    pub const Metrics = struct {
        allocator: std.mem.Allocator,
        counters: std.hash_map.StringHashMap(Counter),
        gauges: std.hash_map.StringHashMap(Gauge),
        histograms: std.hash_map.StringHashMap(Histogram),
        timers: std.hash_map.StringHashMap(Timer),

        pub const Counter = struct {
            value: u64,
            timestamp: i64,

            pub fn inc(self: *Counter) void {
                self.value += 1;
                self.timestamp = std.time.timestamp();
            }

            pub fn add(self: *Counter, amount: u64) void {
                self.value += amount;
                self.timestamp = std.time.timestamp();
            }

            pub fn reset(self: *Counter) void {
                self.value = 0;
                self.timestamp = std.time.timestamp();
            }
        };

        pub const Gauge = struct {
            value: f64,
            timestamp: i64,

            pub fn set(self: *Gauge, value: f64) void {
                self.value = value;
                self.timestamp = std.time.timestamp();
            }

            pub fn inc(self: *Gauge) void {
                self.value += 1.0;
                self.timestamp = std.time.timestamp();
            }

            pub fn dec(self: *Gauge) void {
                self.value -= 1.0;
                self.timestamp = std.time.timestamp();
            }
        };

        pub const Histogram = struct {
            buckets: std.ArrayList(Bucket),
            count: u64,
            sum: f64,
            timestamp: i64,

            pub const Bucket = struct {
                upper_bound: f64,
                count: u64,
            };

            pub fn init(allocator: std.mem.Allocator, upper_bounds: []const f64) Histogram {
                var buckets = std.ArrayList(Bucket).init(allocator);
                for (upper_bounds) |bound| {
                    buckets.append(Bucket{ .upper_bound = bound, .count = 0 }) catch unreachable;
                }
                buckets.append(Bucket{ .upper_bound = std.math.inf(f64), .count = 0 }) catch unreachable;

                return Histogram{
                    .buckets = buckets,
                    .count = 0,
                    .sum = 0.0,
                    .timestamp = std.time.timestamp(),
                };
            }

            pub fn observe(self: *Histogram, value: f64) void {
                self.count += 1;
                self.sum += value;
                self.timestamp = std.time.timestamp();

                for (self.buckets.items) |*bucket| {
                    if (value <= bucket.upper_bound) {
                        bucket.count += 1;
                    }
                }
            }

            pub fn reset(self: *Histogram) void {
                for (self.buckets.items) |*bucket| {
                    bucket.count = 0;
                }
                self.count = 0;
                self.sum = 0.0;
                self.timestamp = std.time.timestamp();
            }
        };

        pub const Timer = struct {
            start_time: i64,
            end_time: ?i64,
            duration: ?f64,

            pub fn start(self: *Timer) void {
                self.start_time = std.time.nanoTimestamp();
                self.end_time = null;
                self.duration = null;
            }

            pub fn stop(self: *Timer) void {
                self.end_time = std.time.nanoTimestamp();
                if (self.end_time) |end| {
                    self.duration = @as(f64, @floatFromInt(end - self.start_time)) / 1_000_000.0; // Convert to milliseconds
                }
            }

            pub fn durationMs(self: Timer) ?f64 {
                return self.duration;
            }
        };

        pub fn init(allocator: std.mem.Allocator) Metrics {
            return Metrics{
                .allocator = allocator,
                .counters = std.hash_map.StringHashMap(Counter).init(allocator),
                .gauges = std.hash_map.StringHashMap(Gauge).init(allocator),
                .histograms = std.hash_map.StringHashMap(Histogram).init(allocator),
                .timers = std.hash_map.StringHashMap(Timer).init(allocator),
            };
        }

        pub fn deinit(self: *Metrics) void {
            var iter = self.counters.iterator();
            while (iter.next()) |entry| {
                self.allocator.free(entry.key_ptr.*);
            }
            self.counters.deinit();

            iter = self.gauges.iterator();
            while (iter.next()) |entry| {
                self.allocator.free(entry.key_ptr.*);
            }
            self.gauges.deinit();

            iter = self.histograms.iterator();
            while (iter.next()) |entry| {
                self.allocator.free(entry.key_ptr.*);
                entry.value_ptr.buckets.deinit();
            }
            self.histograms.deinit();

            iter = self.timers.iterator();
            while (iter.next()) |entry| {
                self.allocator.free(entry.key_ptr.*);
            }
            self.timers.deinit();
        }

        pub fn counter(self: *Metrics, name: []const u8) !*Counter {
            const entry = try self.counters.getOrPut(name);
            if (!entry.found_existing) {
                entry.key_ptr.* = try self.allocator.dupe(u8, name);
                entry.value_ptr.* = Counter{ .value = 0, .timestamp = std.time.timestamp() };
            }
            return entry.value_ptr;
        }

        pub fn gauge(self: *Metrics, name: []const u8) !*Gauge {
            const entry = try self.gauges.getOrPut(name);
            if (!entry.found_existing) {
                entry.key_ptr.* = try self.allocator.dupe(u8, name);
                entry.value_ptr.* = Gauge{ .value = 0.0, .timestamp = std.time.timestamp() };
            }
            return entry.value_ptr;
        }

        pub fn histogram(self: *Metrics, name: []const u8, upper_bounds: []const f64) !*Histogram {
            const entry = try self.histograms.getOrPut(name);
            if (!entry.found_existing) {
                entry.key_ptr.* = try self.allocator.dupe(u8, name);
                entry.value_ptr.* = Histogram.init(self.allocator, upper_bounds);
            }
            return entry.value_ptr;
        }

        pub fn timer(self: *Metrics, name: []const u8) !*Timer {
            const entry = try self.timers.getOrPut(name);
            if (!entry.found_existing) {
                entry.key_ptr.* = try self.allocator.dupe(u8, name);
                entry.value_ptr.* = Timer{ .start_time = 0, .end_time = null, .duration = null };
            }
            return entry.value_ptr;
        }

        pub fn getStats(self: Metrics) struct {
            total_counters: usize,
            total_gauges: usize,
            total_histograms: usize,
            total_timers: usize,
        } {
            return .{
                .total_counters = self.counters.count(),
                .total_gauges = self.gauges.count(),
                .total_histograms = self.histograms.count(),
                .total_timers = self.timers.count(),
            };
        }
    };

    pub fn init(allocator: std.mem.Allocator, level: LogLevel) Logger {
        return Logger{
            .allocator = allocator,
            .level = level,
            .handlers = std.ArrayList(LogHandler).init(allocator),
            .context = std.json.ObjectMap.init(allocator),
            .metrics = Metrics.init(allocator),
        };
    }

    pub fn deinit(self: *Logger) void {
        self.handlers.deinit();
        self.context.deinit();
        self.metrics.deinit();
    }

    pub fn addHandler(self: *Logger, handler: LogHandler) !void {
        try self.handlers.append(handler);
    }

    pub fn addContext(self: *Logger, key: []const u8, value: std.json.Value) !void {
        try self.context.put(key, value);
    }

    pub fn removeContext(self: *Logger, key: []const u8) void {
        _ = self.context.remove(key);
    }

    pub fn log(
        self: *Logger,
        level: LogLevel,
        message: []const u8,
        file: []const u8,
        line: u32,
        function: []const u8,
        error_info: ?errors.ErrorContext,
    ) void {
        if (!level.shouldLog(self.level)) return;

        var entry = LogEntry{
            .timestamp = std.time.timestamp(),
            .level = level,
            .message = self.allocator.dupe(u8, message) catch return,
            .file = self.allocator.dupe(u8, file) catch return,
            .line = line,
            .function = self.allocator.dupe(u8, function) catch return,
            .thread_id = std.Thread.getCurrentId(),
            .context = self.context.clone() catch return,
            .error_info = error_info,
        };
        defer entry.deinit(self.allocator);

        // Update metrics
        const log_counter = self.metrics.counter("logs.total") catch return;
        log_counter.inc();

        const level_counter = self.metrics.counter(try std.fmt.allocPrint(self.allocator, "logs.{s}", .{level.toString()})) catch return;
        level_counter.inc();

        // Send to all handlers
        for (self.handlers.items) |handler| {
            if (level.shouldLog(handler.level)) {
                const formatted = handler.formatter(entry, self.allocator) catch continue;
                defer self.allocator.free(formatted);
                handler.output(formatted) catch continue;
            }
        }
    }

    pub fn trace(self: *Logger, message: []const u8, file: []const u8, line: u32, function: []const u8) void {
        self.log(.trace, message, file, line, function, null);
    }

    pub fn debug(self: *Logger, message: []const u8, file: []const u8, line: u32, function: []const u8) void {
        self.log(.debug, message, file, line, function, null);
    }

    pub fn info(self: *Logger, message: []const u8, file: []const u8, line: u32, function: []const u8) void {
        self.log(.info, message, file, line, function, null);
    }

    pub fn warning(self: *Logger, message: []const u8, file: []const u8, line: u32, function: []const u8) void {
        self.log(.warning, message, file, line, function, null);
    }

    pub fn logError(self: *Logger, message: []const u8, file: []const u8, line: u32, function: []const u8) void {
        self.log(.err, message, file, line, function, null);
    }

    pub fn critical(self: *Logger, message: []const u8, file: []const u8, line: u32, function: []const u8) void {
        self.log(.critical, message, file, line, function, null);
    }

    pub fn fatal(self: *Logger, message: []const u8, file: []const u8, line: u32, function: []const u8) void {
        self.log(.fatal, message, file, line, function, null);
    }

    pub fn logErrorContext(self: *Logger, error_ctx: errors.ErrorContext, file: []const u8, line: u32, function: []const u8) void {
        self.log(error_ctx.severity, error_ctx.message, file, line, function, error_ctx);
    }

    pub fn setLevel(self: *Logger, level: LogLevel) void {
        self.level = level;
    }

    pub fn getLevel(self: Logger) LogLevel {
        return self.level;
    }

    pub fn getMetrics(self: *Logger) *Metrics {
        return &self.metrics;
    }

    pub fn getStats(self: Logger) struct {
        handlers: usize,
        context_keys: usize,
        metrics: Metrics.getStats.return_type,
    } {
        return .{
            .handlers = self.handlers.items.len,
            .context_keys = self.context.count(),
            .metrics = self.metrics.getStats(),
        };
    }
};

/// Monitoring system for application health and performance
pub const Monitor = struct {
    allocator: std.mem.Allocator,
    logger: *Logger,
    health_checks: std.ArrayList(HealthCheck),
    alerts: std.ArrayList(Alert),
    config: MonitorConfig,

    pub const MonitorConfig = struct {
        health_check_interval_ms: u32 = 30000, // 30 seconds
        alert_cooldown_ms: u32 = 300000, // 5 minutes
        max_alerts_per_hour: u32 = 100,
        enable_metrics: bool = true,
        enable_health_checks: bool = true,
    };

    pub const HealthCheck = struct {
        name: []const u8,
        check: *const fn () HealthStatus,
        interval_ms: u32,
        last_check: i64,
        last_status: HealthStatus,

        pub const HealthStatus = struct {
            healthy: bool,
            message: []const u8,
            timestamp: i64,
            metrics: ?std.json.ObjectMap,

            pub fn deinit(self: HealthStatus, allocator: std.mem.Allocator) void {
                allocator.free(self.message);
                if (self.metrics) |*metrics| {
                    metrics.deinit();
                }
            }
        };
    };

    pub const Alert = struct {
        id: u64,
        severity: errors.ErrorSeverity,
        title: []const u8,
        message: []const u8,
        source: []const u8,
        timestamp: i64,
        resolved: bool,
        resolved_at: ?i64,

        pub fn deinit(self: Alert, allocator: std.mem.Allocator) void {
            allocator.free(self.title);
            allocator.free(self.message);
            allocator.free(self.source);
        }
    };

    pub fn init(allocator: std.mem.Allocator, logger: *Logger, config: MonitorConfig) Monitor {
        return Monitor{
            .allocator = allocator,
            .logger = logger,
            .health_checks = std.ArrayList(HealthCheck).init(allocator),
            .alerts = std.ArrayList(Alert).init(allocator),
            .config = config,
        };
    }

    pub fn deinit(self: *Monitor) void {
        for (self.health_checks.items) |*check| {
            self.allocator.free(check.name);
        }
        self.health_checks.deinit();

        for (self.alerts.items) |*alert| {
            alert.deinit(self.allocator);
        }
        self.alerts.deinit();
    }

    pub fn addHealthCheck(self: *Monitor, name: []const u8, check: *const fn () HealthCheck.HealthStatus, interval_ms: u32) !void {
        const health_check = HealthCheck{
            .name = try self.allocator.dupe(u8, name),
            .check = check,
            .interval_ms = interval_ms,
            .last_check = 0,
            .last_status = HealthCheck.HealthStatus{
                .healthy = false,
                .message = try self.allocator.dupe(u8, "Not checked yet"),
                .timestamp = 0,
                .metrics = null,
            },
        };
        try self.health_checks.append(health_check);
    }

    pub fn runHealthChecks(self: *Monitor) void {
        if (!self.config.enable_health_checks) return;

        const now = std.time.timestamp();

        for (self.health_checks.items) |*health_check| {
            if (now - health_check.last_check >= health_check.interval_ms / 1000) {
                const status = health_check.check();

                // Clean up old status
                health_check.last_status.deinit(self.allocator);

                health_check.last_status = status;
                health_check.last_check = now;

                // Log health check result
                if (status.healthy) {
                    self.logger.info(
                        try std.fmt.allocPrint(self.allocator, "Health check '{s}' passed: {s}", .{ health_check.name, status.message }),
                        @src().file,
                        @src().line,
                        @src().fn_name,
                    );
                } else {
                    self.logger.warning(
                        try std.fmt.allocPrint(self.allocator, "Health check '{s}' failed: {s}", .{ health_check.name, status.message }),
                        @src().file,
                        @src().line,
                        @src().fn_name,
                    );

                    // Create alert for failed health check
                    self.createAlert(
                        .err,
                        try std.fmt.allocPrint(self.allocator, "Health Check Failed: {s}", .{health_check.name}),
                        try std.fmt.allocPrint(self.allocator, "Health check '{s}' failed: {s}", .{ health_check.name, status.message }),
                        health_check.name,
                    ) catch {};
                }
            }
        }
    }

    pub fn createAlert(self: *Monitor, severity: errors.ErrorSeverity, title: []const u8, message: []const u8, source: []const u8) !void {
        const alert_id = std.crypto.random.int(u64);
        const alert = Alert{
            .id = alert_id,
            .severity = severity,
            .title = try self.allocator.dupe(u8, title),
            .message = try self.allocator.dupe(u8, message),
            .source = try self.allocator.dupe(u8, source),
            .timestamp = std.time.timestamp(),
            .resolved = false,
            .resolved_at = null,
        };

        try self.alerts.append(alert);

        // Log alert
        self.logger.logError(
            errors.ErrorContext.init(
                self.allocator,
                .SystemError,
                severity,
                try std.fmt.allocPrint(self.allocator, "ALERT: {s} - {s}", .{ title, message }),
                @src().file,
                @src().line,
                @src().fn_name,
            ).withRequestId(self.allocator, try std.fmt.allocPrint(self.allocator, "alert_{d}", .{alert_id})),
            @src().file,
            @src().line,
            @src().fn_name,
        );

        // Update metrics
        const alert_counter = self.logger.getMetrics().counter("alerts.total") catch return;
        alert_counter.inc();

        const severity_counter = self.logger.getMetrics().counter(try std.fmt.allocPrint(self.allocator, "alerts.{s}", .{@tagName(severity)})) catch return;
        severity_counter.inc();
    }

    pub fn resolveAlert(self: *Monitor, alert_id: u64) bool {
        for (self.alerts.items) |*alert| {
            if (alert.id == alert_id and !alert.resolved) {
                alert.resolved = true;
                alert.resolved_at = std.time.timestamp();

                self.logger.info(
                    try std.fmt.allocPrint(self.allocator, "Alert resolved: {s}", .{alert.title}),
                    @src().file,
                    @src().line,
                    @src().fn_name,
                );

                const resolved_counter = self.logger.getMetrics().counter("alerts.resolved") catch return false;
                resolved_counter.inc();

                return true;
            }
        }
        return false;
    }

    pub fn getActiveAlerts(self: Monitor) []Alert {
        var active_alerts = std.ArrayList(Alert).init(self.allocator);
        defer active_alerts.deinit();

        for (self.alerts.items) |alert| {
            if (!alert.resolved) {
                active_alerts.append(alert) catch continue;
            }
        }

        return active_alerts.toOwnedSlice() catch &[_]Alert{};
    }

    pub fn getHealthStatus(self: Monitor) struct {
        total_checks: usize,
        healthy_checks: usize,
        unhealthy_checks: usize,
        last_check: i64,
    } {
        var healthy: usize = 0;
        var unhealthy: usize = 0;
        var last_check: i64 = 0;

        for (self.health_checks.items) |health_check| {
            if (health_check.last_status.healthy) {
                healthy += 1;
            } else {
                unhealthy += 1;
            }
            last_check = @max(last_check, health_check.last_check);
        }

        return .{
            .total_checks = self.health_checks.items.len,
            .healthy_checks = healthy,
            .unhealthy_checks = unhealthy,
            .last_check = last_check,
        };
    }

    pub fn getStats(self: Monitor) struct {
        health_checks: usize,
        alerts: usize,
        active_alerts: usize,
        resolved_alerts: usize,
    } {
        var active: usize = 0;
        var resolved: usize = 0;

        for (self.alerts.items) |alert| {
            if (alert.resolved) {
                resolved += 1;
            } else {
                active += 1;
            }
        }

        return .{
            .health_checks = self.health_checks.items.len,
            .alerts = self.alerts.items.len,
            .active_alerts = active,
            .resolved_alerts = resolved,
        };
    }
};

/// Global logger instance for convenience
var global_logger: ?*Logger = null;

pub fn initGlobalLogger(allocator: std.mem.Allocator, level: Logger.LogLevel) !void {
    global_logger = try allocator.create(Logger);
    global_logger.?.* = Logger.init(allocator, level);

    // Add default console handler
    try global_logger.?.addHandler(Logger.LogHandler{
        .level = level,
        .formatter = Logger.LogHandler.consoleFormatter,
        .output = Logger.LogHandler.consoleOutput,
    });
}

pub fn deinitGlobalLogger(allocator: std.mem.Allocator) void {
    if (global_logger) |logger| {
        logger.deinit();
        allocator.destroy(logger);
        global_logger = null;
    }
}

pub fn getGlobalLogger() ?*Logger {
    return global_logger;
}

// Convenience macros for logging
pub fn log(level: Logger.LogLevel, comptime message: []const u8, args: anytype) void {
    if (global_logger) |logger| {
        const formatted = std.fmt.allocPrint(logger.allocator, message, args) catch return;
        defer logger.allocator.free(formatted);
        logger.log(level, formatted, @src().file, @src().line, @src().fn_name, null);
    }
}

pub fn trace(comptime message: []const u8, args: anytype) void {
    log(.trace, message, args);
}

pub fn debug(comptime message: []const u8, args: anytype) void {
    log(.debug, message, args);
}

pub fn info(comptime message: []const u8, args: anytype) void {
    log(.info, message, args);
}

pub fn warning(comptime message: []const u8, args: anytype) void {
    log(.warning, message, args);
}

pub fn err(comptime message: []const u8, args: anytype) void {
    log(.err, message, args);
}

pub fn critical(comptime message: []const u8, args: anytype) void {
    log(.critical, message, args);
}

pub fn fatal(comptime message: []const u8, args: anytype) void {
    log(.fatal, message, args);
}
