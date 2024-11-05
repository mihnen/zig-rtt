const std = @import("std");
const config = @import("build_options");

pub const capi = @cImport({
    @cInclude("SEGGER_RTT.h");
});

pub fn Rtt() type {
    return struct {
        const debug = std.debug;
        const fmt = std.fmt;
        const Self = @This();

        const NumOfUpChannels = config.up_channels;
        const NumOfDownChannels = config.down_channels;
        up_channels: [NumOfUpChannels]UpChannel = undefined,
        down_channels: [NumOfDownChannels]DownChannel = undefined,

        pub fn print(self: *const Self, comptime fmt_str: []const u8, args: anytype) void {
            const writer = Writer{ .chan = &self.up_channels[0] };
            fmt.format(writer, fmt_str, args) catch unreachable;
        }

        pub fn init() Self {
            comptime std.debug.assert(NumOfUpChannels > 0 or NumOfDownChannels > 0);
            var self: @This() = .{};
            for (&self.up_channels, 0..) |*chan, i| {
                chan.* = .{ .chan_num = i };
            }
            for (&self.down_channels, 0..) |*chan, i| {
                chan.* = .{ .chan_num = i };
            }
            return self;
        }

        pub fn upChannel(self: *const Self, comptime num: comptime_int) *const UpChannel {
            comptime std.debug.assert(num < NumOfUpChannels);
            return &self.up_channels[num];
        }

        pub fn downChannel(self: *const Self, comptime num: comptime_int) *const DownChannel {
            comptime std.debug.assert(num < NumOfDownChannels);
            return &self.down_channels[num];
        }

        pub fn rttInit(_: Self) void {
            capi.SEGGER_RTT_Init();
        }

        const DownChannel = struct {
            pub const Error = error{};
            pub const Reader = std.io.Reader(DownChannel, Error, read);

            chan_num: u32,

            fn read(self: DownChannel, buf: []u8) DownChannel.Error!usize {
                var i: usize = 0;
                while (i == 0) {
                    i += capi.SEGGER_RTT_Read(self.chan_num, buf.ptr, buf.len);
                }
                return i;
            }

            pub fn reader(self: DownChannel) Reader {
                return .{ .context = self };
            }
        };

        const UpChannel = struct {
            chan_num: u32,

            pub fn print(self: *const UpChannel, comptime fmt_str: []const u8, args: anytype) void {
                const writer = Writer{ .chan = self };
                fmt.format(writer, fmt_str, args) catch unreachable;
            }
        };

        const Writer = struct {
            chan: *const UpChannel,

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
