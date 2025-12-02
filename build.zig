const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library
    const lib = b.addStaticLibrary(.{
        .name = "zignal",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    // Module for users to import
    const zignal_module = b.addModule("zignal", .{
        .root_source_file = b.path("src/root.zig"),
    });

    // Tests
    const tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_tests.step);

    // Advanced tests (optional, can fail without blocking)
    const advanced_tests = b.addTest(.{
        .root_source_file = b.path("tests/test_advanced.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_advanced_tests = b.addRunArtifact(advanced_tests);
    const advanced_test_step = b.step("test-advanced", "Run advanced tests");
    advanced_test_step.dependOn(&run_advanced_tests.step);

    // Examples (individual steps)
    // Note: Some advanced examples are WIP and may not compile
    const examples = [_]struct { name: []const u8, path: []const u8 }{
        .{ .name = "basic-bot", .path = "examples/basic_bot.zig" },
        .{ .name = "rest-api", .path = "examples/rest_api.zig" },
    };

    const examples_step = b.step("examples", "Build all examples");
    
    inline for (examples) |example| {
        const exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = b.path(example.path),
            .target = target,
            .optimize = optimize,
        });
        
        // Link zignal module
        exe.root_module.addImport("zignal", zignal_module);
        
        const install_exe = b.addInstallArtifact(exe, .{});
        examples_step.dependOn(&install_exe.step);

        // Individual run step for each example
        const run_cmd = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step(
            b.fmt("run-{s}", .{example.name}),
            b.fmt("Run the {s} example", .{example.name}),
        );
        run_step.dependOn(&run_cmd.step);
    }

    // Formatting check
    const fmt_step = b.step("fmt", "Format source code");
    const fmt = b.addFmt(.{
        .paths = &.{ "src", "examples", "tests" },
    });
    fmt_step.dependOn(&fmt.step);

    // CI step - combines multiple checks
    const ci_step = b.step("ci", "Run all CI checks");
    ci_step.dependOn(&lib.step);
    ci_step.dependOn(test_step);
    // Don't include examples in CI by default (may need tokens)
}
