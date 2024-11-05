const std = @import("std");

const atomic = std.atomic;
const debug = std.debug;
const fmt = std.fmt;

pub const capi = @cImport({
    @cInclude("SEGGER_RTT.h");
});

pub fn Rtt() type {
    return struct {
        const Self = @This();

        const NumOfChannels: comptime_int = capi.SEGGER_RTT_MAX_NUM_UP_BUFFERS;
        channels: [NumOfChannels]Channel = undefined,

        pub fn print(self: *const Self, comptime fmt_str: []const u8, args: anytype) void {
            const writer = Writer{ .chan = &self.channels[0] };
            fmt.format(writer, fmt_str, args) catch unreachable;
        }

        pub fn init() @This() {
            comptime std.debug.assert(NumOfChannels > 0);
            var self: @This() = .{};
            for (&self.channels, 0..) |*chan, i| {
                chan.* = .{ .chan_num = i };
            }
            return self;
        }

        pub fn channel(self: *const Self, comptime num: comptime_int) *Channel {
            comptime std.debug.assert(num < NumOfChannels);
            return &self.channles[num];
        }

        pub fn rttInit(_: Self) void {
            capi.SEGGER_RTT_Init();
        }

        const Channel = struct {
            chan_num: u32,

            pub fn print(self: Channel, comptime fmt_str: []const u8, args: anytype) void {
                const writer = Writer{ .chan = self };
                fmt.format(writer, fmt_str, args) catch unreachable;
            }
        };

        const Writer = struct {
            chan: *const Channel,

            pub const Error = error{}; // infallible

            pub fn writeAll(self: *const Writer, bytes: []const u8) Writer.Error!void {
                _ = capi.SEGGER_RTT_Write(self.chan.chan_num, bytes.ptr, bytes.len);
            }

            pub fn writeBytesNTimes(
                self: Writer,
                bytes: []const u8,
                n: usize,
            ) Writer.Error!void {
                for (0..n) |_| self.writeAll(bytes) catch unreachable;
            }
        };
    };
}
