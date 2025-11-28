const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main library
    const lib = b.addStaticLibrary(.{
        .name = "zignal",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    // Create module for external use
    const zignal_module = b.addModule("zignal", .{
        .source_file = .{ .path = "src/root.zig" },
    });

    // Examples
    const basic_bot = b.addExecutable(.{
        .name = "basic_bot",
        .root_source_file = .{ .path = "examples/basic_bot.zig" },
        .target = target,
        .optimize = optimize,
    });
    
    // Add the zignal module to the example
    basic_bot.addModule("zignal", zignal_module);
    b.installArtifact(basic_bot);

    // Tests
    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);
    run_tests.step.dependOn(&lib.step);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_tests.step);

    // Advanced tests
    const advanced_tests = b.addTest(.{
        .root_source_file = .{ .path = "tests/test_advanced.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_advanced_tests = b.addRunArtifact(advanced_tests);
    run_advanced_tests.step.dependOn(&lib.step);

    const advanced_test_step = b.step("test-advanced", "Run advanced feature tests");
    advanced_test_step.dependOn(&run_advanced_tests.step);

    // Examples
    const examples = [_]struct {
        name: []const u8,
        path: []const u8,
        description: []const u8,
    }{
        .{ .name = "production_bot", .path = "examples/production_bot.zig", .description = "Production-ready bot with all features" },
        .{ .name = "voice_bot", .path = "examples/voice_bot.zig", .description = "Voice bot with audio processing" },
        .{ .name = "interactions_demo", .path = "examples/interactions_demo.zig", .description = "Interactive components demo" },
        .{ .name = "performance_benchmark", .path = "examples/performance_benchmark.zig", .description = "Performance benchmark suite" },
    };

    for (examples) |example| {
        const exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = .{ .path = example.path },
            .target = target,
            .optimize = optimize,
        });

        exe.addIncludePath(.{ .path = "src" });
        b.installArtifact(exe);

        const run_example = b.addRunArtifact(exe);
        run_example.step.dependOn(&exe.step);

        const example_step = b.step(example.name, example.description);
        example_step.dependOn(&run_example.step);
    }

    // Benchmarks
    const benchmark = b.addExecutable(.{
        .name = "benchmark",
        .root_source_file = .{ .path = "examples/performance_benchmark.zig" },
        .target = target,
        .optimize = .ReleaseFast,
    });

    benchmark.addIncludePath(.{ .path = "src" });
    b.installArtifact(benchmark);

    const run_benchmark = b.addRunArtifact(benchmark);
    run_benchmark.step.dependOn(&benchmark.step);

    const benchmark_step = b.step("benchmark", "Run performance benchmarks");
    benchmark_step.dependOn(&run_benchmark.step);

    // Documentation
    const docs = b.addSystemCommand(&.{
        "zig", "build-lib",
        "-femit-docs",
        "-fno-emit-bin",
        "src/root.zig",
    });

    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(&docs.step);

    // Linting
    const lint = b.addSystemCommand(&.{
        "zig", "fmt",
        "--check",
        "src/",
        "examples/",
        "tests/",
    });

    const lint_step = b.step("lint", "Check code formatting");
    lint_step.dependOn(&lint.step);

    // Security audit
    const security_audit = b.addSystemCommand(&.{
        "zig", "build",
        "-Dtarget=native-native",
        "-Doptimize=Debug",
        "test",
    });

    const security_step = b.step("security", "Run security audit");
    security_step.dependOn(&security_audit.step);

    // Coverage
    const coverage = b.addSystemCommand(&.{
        "zig", "test",
        "-femit-llvm",
        "-fcoverage",
        "src/root.zig",
    });

    const coverage_step = b.step("coverage", "Generate code coverage report");
    coverage_step.dependOn(&coverage.step);

    // CI pipeline
    const ci = b.step("ci", "Run full CI pipeline");
    ci.dependOn(lint_step);
    ci.dependOn(test_step);
    ci.dependOn(advanced_test_step);
    ci.dependOn(benchmark_step);
    ci.dependOn(docs_step);
    ci.dependOn(security_step);

    // Development setup
    const dev = b.step("dev", "Setup development environment");
    dev.dependOn(lint_step);
    dev.dependOn(test_step);
    dev.dependOn(advanced_test_step);

    // Release build
    const release = b.step("release", "Build release version");
    const release_lib = b.addStaticLibrary(.{
        .name = "zignal",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = .ReleaseFast,
    });
    b.installArtifact(release_lib);
    release.dependOn(&release_lib.step);

    // Package creation
    const package = b.step("package", "Create distributable package");
    const package_cmd = b.addSystemCommand(&.{
        "tar", "-czf", "zignal.tar.gz",
        "src/",
        "examples/",
        "tests/",
        "docs/",
        "build.zig",
        "README.md",
        "LICENSE",
    });
    package.dependOn(&package_cmd.step);
}
