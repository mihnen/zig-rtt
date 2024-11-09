# Zig RTT

A Zig wrapper for Segger RTT library

## Description

A Zig wrapper for the Segger RTT library (https://www.segger.com/products/debug-probes/j-link/technology/about-real-time-transfer/).
Allows usage of the RTT protocol in Zig projects with a Zig like interface using std.fmt just like the standard library IO functions.
Please note this project is in no way affliated with Segger.

## Getting Started

### Dependencies

* Zig (https://ziglang.org/).
* Segger RTT library (https://www.segger.com/products/debug-probes/j-link/technology/about-real-time-transfer/).

### Using with a Zig application

In your main build.zig file import as a dependency and specify any library options such as the number of up/down channels and their
associated buffer sizes.

```zig
const zig_rtt_dep = b.dependency("zig_rtt", .{
    .target = target,
    .optimize = optimize,
    .up_channels = @as(u32, 1),
    .down_channels = @as(u32, 1),
    .up_buffer_size = @as(u32, 2048),
    .down_buffer_size = @as(u32, 64),
});
exe.root_module.addImport("zig_rtt", zig_rtt_dep.module("zig_rtt"));
```

In your build.zig.zon file. This assumes you have cloned this repo under src/lib/zig-rtt.

```zig
.dependencies = .{
    .cmsis_rtos = .{
        .path = "src/lib/zig-rtt",
    },
},
```

### Example usage to provide std.log interface

```zig
const std = @import("std");
const zrtt = @import("zig_rtt");

const rtt = zrtt.Rtt().init();

// The default log level is based on build mode.
pub const default_level: std.log.Level = switch (std.builtin.mode) {
    .Debug => .debug,
    .ReleaseSafe => .info,
    .ReleaseFast, .ReleaseSmall => .err,
};

pub const std_options = .{
    .logFn = myLogFn,
};

pub fn myLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const RTT_CTRL_RESET = "\x1B[0m";
    const RTT_CTRL_TEXT_RED = "\x1B[2;31m";
    const RTT_CTRL_TEXT_GREEN = "\x1B[2;32m";
    const RTT_CTRL_TEXT_YELLOW = "\x1B[2;33m";
    const RTT_CTRL_TEXT_BLUE = "\x1B[2;34m";

    const level_prefix = "[" ++ switch (level) {
        .debug => RTT_CTRL_TEXT_BLUE,
        .warn => RTT_CTRL_TEXT_YELLOW,
        .err => RTT_CTRL_TEXT_RED,
        .info => RTT_CTRL_TEXT_GREEN,
    } ++ comptime level.asText() ++ RTT_CTRL_RESET ++ "] ";

    const scope_prefix = switch (scope) {
        std.log.default_log_scope => "",
        else => "(" ++ @tagName(scope) ++ ") ",
    };

    rtt.print(level_prefix ++ scope_prefix ++ format, args);
}
```

### Licensing

* This project is licensed under MIT (https://opensource.org/license/mit).
* All source code from Segger RTT library is subject to it's own license see src/segger_rtt/LICENSE.md

## Authors

Contributors names and contact info

1. Matt Ihnen <mihnen@milwaukeeelectronics.com> <matt.ihnen@gmail.com>

## Version History

* 0.0.1
    * Initial Release
