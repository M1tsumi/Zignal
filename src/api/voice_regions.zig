const std = @import("std");
const models = @import("../models.zig");
const utils = @import("../utils.zig");

/// Voice region management for voice channel optimization
pub const VoiceRegionManager = struct {
    client: *Client,
    allocator: std.mem.Allocator,

    pub fn init(client: *Client, allocator: std.mem.Allocator) VoiceRegionManager {
        return VoiceRegionManager{
            .client = client,
            .allocator = allocator,
        };
    }

    /// Get all available voice regions
    pub fn getVoiceRegions(self: *VoiceRegionManager) ![]models.VoiceRegion {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/voice/regions",
            .{ self.client.base_url },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        return try std.json.parse([]models.VoiceRegion, response.body, .{});
    }

    /// Get optimal voice region for a guild
    pub fn getOptimalRegion(
        self: *VoiceRegionManager,
        guild_id: u64,
    ) !?models.VoiceRegion {
        const regions = try self.getVoiceRegions();
        defer self.allocator.free(regions);

        // Get guild information to determine optimal region
        const guild_info = try self.getGuildInfo(guild_id);
        defer self.allocator.free(guild_info.region);

        // Find the best region based on guild location
        for (regions) |region| {
            if (std.mem.eql(u8, region.id, guild_info.region)) {
                return region;
            }
        }

        // Fallback to first available region
        if (regions.len > 0) {
            return regions[0];
        }

        return null;
    }

    /// Get voice region by ID
    pub fn getVoiceRegion(
        self: *VoiceRegionManager,
        region_id: []const u8,
    ) !?models.VoiceRegion {
        const regions = try self.getVoiceRegions();
        defer self.allocator.free(regions);

        for (regions) |region| {
            if (std.mem.eql(u8, region.id, region_id)) {
                return region;
            }
        }

        return null;
    }

    /// Get regions sorted by latency (requires actual latency testing)
    pub fn getRegionsByLatency(
        self: *VoiceRegionManager,
        latencies: std.json.ObjectMap,
    ) ![]models.VoiceRegion {
        const regions = try self.getVoiceRegions();
        defer self.allocator.free(regions);

        // Sort regions by latency
        var sorted_regions = try self.allocator.dupe(models.VoiceRegion, regions);
        defer self.allocator.free(sorted_regions);

        std.sort.sort(models.VoiceRegion, sorted_regions, struct {
            latencies: std.json.ObjectMap,
            fn compare(ctx: @This(), a: models.VoiceRegion, b: models.VoiceRegion) bool {
                const a_latency = ctx.latencies.get(a.id).?.float;
                const b_latency = ctx.latencies.get(b.id).?.float;
                return a_latency < b_latency;
            }
        }{ .latencies = latencies }.compare);

        return sorted_regions;
    }

    /// Get regions with VIP support
    pub fn getVipRegions(self: *VoiceRegionManager) ![]models.VoiceRegion {
        const regions = try self.getVoiceRegions();
        defer self.allocator.free(regions);

        var vip_regions = std.ArrayList(models.VoiceRegion).init(self.allocator);
        defer vip_regions.deinit();

        for (regions) |region| {
            if (region.vip) {
                try vip_regions.append(region);
            }
        }

        return vip_regions.toOwnedSlice();
    }

    /// Get regions with custom capabilities
    pub fn getRegionsWithCapabilities(
        self: *VoiceRegionManager,
        optimal: bool,
        deprecated: bool,
        custom: bool,
    ) ![]models.VoiceRegion {
        const regions = try self.getVoiceRegions();
        defer self.allocator.free(regions);

        var filtered_regions = std.ArrayList(models.VoiceRegion).init(self.allocator);
        defer filtered_regions.deinit();

        for (regions) |region| {
            if ((optimal and region.optimal) or
                (deprecated and region.deprecated) or
                (custom and region.custom))
            {
                try filtered_regions.append(region);
            }
        }

        return filtered_regions.toOwnedSlice();
    }

    /// Test latency to a voice region
    pub fn testRegionLatency(
        self: *VoiceRegionManager,
        region_id: []const u8,
    ) !u64 {
        // This would typically involve actual network testing
        // For now, return estimated latency based on region
        const region = try self.getVoiceRegion(region_id);
        if (region) |r| {
            return estimateRegionLatency(r.id);
        }
        return 999; // High latency for unknown regions
    }

    /// Get recommended region for user location
    pub fn getRecommendedRegion(
        self: *VoiceRegionManager,
        user_location: []const u8,
    ) !?models.VoiceRegion {
        const regions = try self.getVoiceRegions();
        defer self.allocator.free(regions);

        // Map user locations to optimal regions
        const region_mapping = std.ComptimeStringMap([]const u8, .{
            .{ "us-east", "us-east" },
            .{ "us-west", "us-west" },
            .{ "us-central", "us-central" },
            .{ "europe", "europe" },
            .{ "amsterdam", "amsterdam" },
            .{ "frankfurt", "frankfurt" },
            .{ "london", "london" },
            .{ "russia", "russia" },
            .{ "asia", "asia" },
            .{ "hongkong", "hongkong" },
            .{ "japan", "japan" },
            .{ "sydney", "sydney" },
            .{ "brazil", "brazil" },
            .{ "southafrica", "southafrica" },
            .{ "india", "india" },
        });

        if (region_mapping.get(user_location)) |optimal_region_id| {
            return try self.getVoiceRegion(optimal_region_id);
        }

        // Fallback to any optimal region
        for (regions) |region| {
            if (region.optimal) {
                return region;
            }
        }

        return null;
    }

    /// Helper function to get guild info
    fn getGuildInfo(self: *VoiceRegionManager, guild_id: u64) !struct { region: []const u8 } {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/guilds/{d}",
            .{ self.client.base_url, guild_id },
        );
        defer self.allocator.free(url);

        const response = try self.client.http.get(url);
        defer response.deinit();

        if (response.status != 200) {
            return error.HttpRequestFailed;
        }

        const guild = try std.json.parse(models.Guild, response.body, .{});
        return .{ .region = try self.allocator.dupe(u8, guild.region) };
    }

    /// Helper function to estimate region latency
    fn estimateRegionLatency(region_id: []const u8) u64 {
        // Estimated latencies in milliseconds
        const latency_estimates = std.ComptimeStringMap(u64, .{
            .{ "us-east", 20 },
            .{ "us-west", 35 },
            .{ "us-central", 25 },
            .{ "us-south", 30 },
            .{ "europe", 45 },
            .{ "amsterdam", 40 },
            .{ "frankfurt", 50 },
            .{ "london", 45 },
            .{ "russia", 80 },
            .{ "asia", 120 },
            .{ "hongkong", 100 },
            .{ "japan", 110 },
            .{ "sydney", 150 },
            .{ "brazil", 100 },
            .{ "southafrica", 130 },
            .{ "india", 90 },
        });

        return latency_estimates.get(region_id) orelse 200;
    }
};

/// Voice region utilities
pub const VoiceRegionUtils = struct {
    pub fn isRegionDeprecated(region: models.VoiceRegion) bool {
        return region.deprecated;
    }

    pub fn isRegionOptimal(region: models.VoiceRegion) bool {
        return region.optimal;
    }

    pub fn isRegionVip(region: models.VoiceRegion) bool {
        return region.vip;
    }

    pub fn isRegionCustom(region: models.VoiceRegion) bool {
        return region.custom;
    }

    pub fn getRegionCategory(region: models.VoiceRegion) []const u8 {
        if (std.mem.startsWith(u8, region.id, "us-")) return "North America";
        if (std.mem.startsWith(u8, region.id, "europe")) return "Europe";
        if (std.mem.startsWith(u8, region.id, "asia")) return "Asia";
        if (std.mem.startsWith(u8, region.id, "sydney")) return "Oceania";
        if (std.mem.startsWith(u8, region.id, "brazil")) return "South America";
        if (std.mem.startsWith(u8, region.id, "southafrica")) return "Africa";
        if (std.mem.startsWith(u8, region.id, "russia")) return "Russia";
        if (std.mem.startsWith(u8, region.id, "india")) return "Asia";
        return "Other";
    }

    pub fn formatRegionInfo(region: models.VoiceRegion) []const u8 {
        var info = std.ArrayList(u8).init(std.heap.page_allocator);
        defer info.deinit();

        try info.appendSlice("Region: ");
        try info.appendSlice(region.name);
        try info.appendSlice(" (");
        try info.appendSlice(region.id);
        try info.appendSlice(")");

        if (region.optimal) try info.appendSlice(" [Optimal]");
        if (region.vip) try info.appendSlice(" [VIP]");
        if (region.deprecated) try info.appendSlice(" [Deprecated]");
        if (region.custom) try info.appendSlice(" [Custom]");

        try info.appendSlice(" - ");
        try info.appendSlice(getRegionCategory(region));

        return info.toOwnedSlice();
    }

    pub fn getRegionLatencyGrade(latency_ms: u64) []const u8 {
        if (latency_ms < 30) return "Excellent";
        if (latency_ms < 50) return "Good";
        if (latency_ms < 80) return "Fair";
        if (latency_ms < 120) return "Poor";
        return "Very Poor";
    }

    pub fn recommendRegionForVoiceChat(regions: []models.VoiceRegion, user_count: usize) ?models.VoiceRegion {
        // For small groups, prioritize optimal regions
        if (user_count < 5) {
            for (regions) |region| {
                if (region.optimal and !region.deprecated) {
                    return region;
                }
            }
        }

        // For larger groups, prioritize VIP regions
        if (user_count > 10) {
            for (regions) |region| {
                if (region.vip and !region.deprecated) {
                    return region;
                }
            }
        }

        // Fallback to any non-deprecated region
        for (regions) |region| {
            if (!region.deprecated) {
                return region;
            }
        }

        return null;
    }

    pub fn getRegionStats(regions: []models.VoiceRegion) struct {
        total: usize,
        optimal: usize,
        vip: usize,
        deprecated: usize,
        custom: usize,
    } {
        var stats = struct {
            total: usize = 0,
            optimal: usize = 0,
            vip: usize = 0,
            deprecated: usize = 0,
            custom: usize = 0,
        }{};

        for (regions) |region| {
            stats.total += 1;
            if (region.optimal) stats.optimal += 1;
            if (region.vip) stats.vip += 1;
            if (region.deprecated) stats.deprecated += 1;
            if (region.custom) stats.custom += 1;
        }

        return stats;
    }
};
