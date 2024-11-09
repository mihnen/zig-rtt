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
    const level_prefix = "[" ++ switch (level) {
        .debug => rtt.ctrl().TEXT_BLUE,
        .warn => rtt.ctrl().TEXT_YELLOW,
        .err => rtt.ctrl().TEXT_RED,
        .info => rtt.ctrl().TEXT_GREEN,
    } ++ comptime level.asText() ++ rtt.ctrl().RESET ++ "] ";

    const scope_prefix = switch (scope) {
        std.log.default_log_scope => "",
        else => "(" ++ @tagName(scope) ++ ") ",
    };

    rtt.print(level_prefix ++ scope_prefix ++ format, args);
}
```

### Accessing channels other than the default channel 0

If you need to access a channel other than the default they can be accesssed using the
upChannel and downChannel functions. It is a compile time error to try and access a channel
above what you have configured at build time.

```zig
rtt.upChannel(1).print("hello\n", .{});
```

### Accessing std.io.Reader or std.io.Writer

You can access standard library compatible Reader/Writer interfaces using the methods
on the appropriate upChannel (Writer) or downChannel (Reader)

```zig
const writer = rtt.upChannel(0).writer();
const reader = rtt.downChannel(0).reader();
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
