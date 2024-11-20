const std = @import("std");
const config = @import("build_options");

pub const capi = @cImport({
    @cInclude("SEGGER_RTT.h");
});

pub fn Rtt() type {
    return struct {
        const Self = @This();

        const Ctrl = struct {
            pub const RESET = "\x1B[0m"; // Reset to default colors
            pub const CLEAR = "\x1B[2J"; // Clear screen, reposition cursor to top left

            pub const TEXT_BLACK = "\x1B[2;30m";
            pub const TEXT_RED = "\x1B[2;31m";
            pub const TEXT_GREEN = "\x1B[2;32m";
            pub const TEXT_YELLOW = "\x1B[2;33m";
            pub const TEXT_BLUE = "\x1B[2;34m";
            pub const TEXT_MAGENTA = "\x1B[2;35m";
            pub const TEXT_CYAN = "\x1B[2;36m";
            pub const TEXT_WHITE = "\x1B[2;37m";

            pub const TEXT_BRIGHT_BLACK = "\x1B[1;30m";
            pub const TEXT_BRIGHT_RED = "\x1B[1;31m";
            pub const TEXT_BRIGHT_GREEN = "\x1B[1;32m";
            pub const TEXT_BRIGHT_YELLOW = "\x1B[1;33m";
            pub const TEXT_BRIGHT_BLUE = "\x1B[1;34m";
            pub const TEXT_BRIGHT_MAGENTA = "\x1B[1;35m";
            pub const TEXT_BRIGHT_CYAN = "\x1B[1;36m";
            pub const TEXT_BRIGHT_WHITE = "\x1B[1;37m";

            pub const BG_BLACK = "\x1B[24;40m";
            pub const BG_RED = "\x1B[24;41m";
            pub const BG_GREEN = "\x1B[24;42m";
            pub const BG_YELLOW = "\x1B[24;43m";
            pub const BG_BLUE = "\x1B[24;44m";
            pub const BG_MAGENTA = "\x1B[24;45m";
            pub const BG_CYAN = "\x1B[24;46m";
            pub const BG_WHITE = "\x1B[24;47m";

            pub const BG_BRIGHT_BLACK = "\x1B[4;40m";
            pub const BG_BRIGHT_RED = "\x1B[4;41m";
            pub const BG_BRIGHT_GREEN = "\x1B[4;42m";
            pub const BG_BRIGHT_YELLOW = "\x1B[4;43m";
            pub const BG_BRIGHT_BLUE = "\x1B[4;44m";
            pub const BG_BRIGHT_MAGENTA = "\x1B[4;45m";
            pub const BG_BRIGHT_CYAN = "\x1B[4;46m";
            pub const BG_BRIGHT_WHITE = "\x1B[4;47m";
        };

        const NumOfUpChannels = config.up_channels;
        const NumOfDownChannels = config.down_channels;

        up_channels: [NumOfUpChannels]UpChannel = undefined,
        down_channels: [NumOfDownChannels]DownChannel = undefined,

        pub fn ctrl(_: Self) type {
            return Ctrl;
        }

        pub fn print(self: *const Self, comptime fmt_str: []const u8, args: anytype) void {
            self.upChannel(0).print(fmt_str, args);
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
            pub const Error = error{EndOfStream};
            pub const Reader = std.io.Reader(DownChannel, Error, read);

            chan_num: u32,

            fn read(self: DownChannel, buf: []u8) DownChannel.Error!usize {
                const nbytes = capi.SEGGER_RTT_Read(self.chan_num, buf.ptr, buf.len);

                if (nbytes >= 0) {
                    return nbytes;
                }

                return Error.EndOfStream;
            }

            pub fn reader(self: DownChannel) Reader {
                return .{ .context = self };
            }
        };

        const UpChannel = struct {
            chan_num: u32,
            pub const Error = error{};
            pub const Writer = std.io.Writer(UpChannel, Error, write);

            fn write(self: UpChannel, bytes: []const u8) UpChannel.Error!usize {
                return capi.SEGGER_RTT_Write(self.chan_num, bytes.ptr, bytes.len);
            }

            pub fn writer(self: UpChannel) Writer {
                return .{ .context = self };
            }

            pub fn print(self: *const UpChannel, comptime fmt_str: []const u8, args: anytype) void {
                std.fmt.format(self.writer(), fmt_str, args) catch unreachable;
            }
        };
    };
}
