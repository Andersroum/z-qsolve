const std = @import("std");
const lib = @import("lib.zig");
const Fraction = lib.Fraction;
const stderr = std.Io.File.stderr();

fn UnfStderrWriter(io: std.Io, text: []const u8) !void {
    try stderr.writeStreamingAll(io, text);
}

fn printHelp(init: std.process.Init) !void {
    const io = init.io;
    var buffer: [4096]u8 = undefined;
    var file_writer = std.Io.File.writer(stderr, io, &buffer);
    const output = &file_writer.interface;

    try output.print("Zig Qsolver\n", .{});
    try output.print("Solve equations in the form ax^2 + bx + c = 0\n\n", .{});
    try output.print("USAGE:\n", .{});
    try output.print("    zig run main.zig -- <a> <b> <c>i\n", .{});
    try output.print("    *a,b and c must be numbers\n\n", .{});
    try output.print("FLAGSi:\n", .{});
    try output.print("    `help`   prints this message\n\n", .{});
    try output.print("EXAMPLES:\n", .{});
    try output.print("    zig run main.zig -- 1 -5 6\n", .{});
    try output.print("    zig run main.zig -- 43.2 3/4 78\n\n", .{});

    try output.flush();
}

pub fn main(init: std.process.Init) !void {
    var args = init.minimal.args.iterate();
    _ = args.next();

    const a: [:0]const u8 = if (args.next()) |arg| out_path: {
        if (std.ascii.eqlIgnoreCase(arg, "help")) {
            try printHelp(init);
            return;
        }
        break :out_path arg;
    } else {
        try printHelp(init);
        try UnfStderrWriter(init.io, "Error: No arguments were entered");
        return;
    };

    const b: [:0]const u8 = args.next() orelse {
        try UnfStderrWriter(init.io, "Error: Entered arguments were not enough. Run with `help` for usage infos");
        return;
    };

    const c: [:0]const u8 = args.next() orelse {
        try UnfStderrWriter(init.io, "Error: Entered argumets were not enough. Run with `help` for usage infos");
        return;
    };

    std.debug.print("{s}{s}{s}\n", .{ a, b, c });
}
