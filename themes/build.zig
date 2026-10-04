pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const engine = b.dependency("engine", .{ .target = target, .optimize = optimize });
    const engine_module = engine.module("engine");
    const resources = engine.builder.dependency("resources", .{ .target = target, .optimize = optimize });
    const resources_module = resources.module("resources");

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "engine", .module = engine_module },
            .{ .name = "resources", .module = resources_module },
        },
    });

    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = mod,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

const std = @import("std");
