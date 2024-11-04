const std = @import("std");
pub const newlib = @import("gatz").newlib;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "segger-rtt-clib",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        // .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("zig-rtt", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    mod.linkLibrary(lib);

    const headers_paths = .{
        "",
        "src/segger_rtt/Config",
        "src/segger_rtt/RTT",
    };

    inline for (headers_paths) |header| {
        lib.addIncludePath(b.path(header));
        mod.addIncludePath(b.path(header));
    }

    const sources = .{
        "src/segger_rtt/SEGGER_RTT.c",
    };

    inline for (sources) |name| {
        lib.addCSourceFile(.{
            .file = b.path(name),
            .flags = &.{"-std=c99"},
        });
    }

    newlib.addIncludeHeadersAndSystemPathsTo(b, target, lib) catch |err| switch (err) {
        newlib.Error.CompilerNotFound => {
            std.log.err("Couldn't find arm-none-eabi-gcc compiler!\n", .{});
            unreachable;
        },
        newlib.Error.IncompatibleCpu => {
            std.log.err("Cpu: {s} isn't supported by gatz!\n", .{target.result.cpu.model.name});
            unreachable;
        },
    };

    b.installArtifact(lib);
}
