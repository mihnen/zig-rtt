const std = @import("std");
pub const newlib = @import("gatz").newlib;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const up_channels = b.option(u32, "up_channels", "How many up channels to allocate") orelse 1;
    const down_channels = b.option(u32, "down_channels", "How many up channels to allocate") orelse 1;
    const up_buffer_size = b.option(u32, "up_buffer_size", "Size of up buffers in bytes") orelse 1024;
    const down_buffer_size = b.option(u32, "down_buffer_size", "Size of down buffers in bytes") orelse 16;

    const lib = b.addStaticLibrary(.{
        .name = "segger_rtt_clib",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        // .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const up_channel_value = std.fmt.allocPrint(
        b.allocator,
        "{d}",
        .{up_channels},
    );

    const down_channel_value = std.fmt.allocPrint(
        b.allocator,
        "{d}",
        .{down_channels},
    );

    const up_buffer_size_value = std.fmt.allocPrint(
        b.allocator,
        "{d}",
        .{up_buffer_size},
    );

    const down_buffer_size_value = std.fmt.allocPrint(
        b.allocator,
        "{d}",
        .{down_buffer_size},
    );

    if (up_channel_value) |value| {
        lib.defineCMacro("SEGGER_RTT_MAX_NUM_UP_BUFFERS", value);
    } else |err| {
        std.debug.print("{s}\n", .{@errorName(err)});
    }

    if (down_channel_value) |value| {
        lib.defineCMacro("SEGGER_RTT_MAX_NUM_DOWN_BUFFERS", value);
    } else |err| {
        std.debug.print("{s}\n", .{@errorName(err)});
    }

    if (up_buffer_size_value) |value| {
        lib.defineCMacro("BUFFER_SIZE_UP", value);
    } else |err| {
        std.debug.print("{s}\n", .{@errorName(err)});
    }

    if (down_buffer_size_value) |value| {
        lib.defineCMacro("BUFFER_SIZE_DOWN", value);
    } else |err| {
        std.debug.print("{s}\n", .{@errorName(err)});
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

    const mod = b.addModule("zig_rtt", .{
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
        "src/segger_rtt/RTT/SEGGER_RTT.c",
    };

    inline for (sources) |name| {
        lib.addCSourceFile(.{
            .file = b.path(name),
            .flags = &.{"-std=c99"},
        });
    }

    lib.want_lto = false; // -flto
    lib.link_data_sections = true; // -fdata-sections
    lib.link_function_sections = true; // -ffunction-sections
    lib.link_gc_sections = true; // -Wl,--gc-sections

    b.installArtifact(lib);
}
