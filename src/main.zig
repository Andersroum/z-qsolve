const std = @import("std");
const lib = @import("lib.zig");
const SquareRoot = lib.SquareRoot;
const Fraction = lib.Fraction;
const FractionError = lib.Fraction_error;
const stderr = std.Io.File.stderr();

const QuadraticResult = union(enum) {
    OneReal: Fraction,
    TwoReal: struct {
        first_part: Fraction,
        sqrt_part: SquareRoot,
    },
    Complex: struct {
        first_part: Fraction,
        second_part: Fraction,
        inside_sqrt: Fraction,
    },
};

fn UnfStderrWriter(io: std.Io, text: []const u8) !void {
    try stderr.writeStreamingAll(io, text);
}

fn printHelp(init: std.process.Init) !void {
    const io = init.io;
    var buffer: [4096]u8 = undefined;
    var file_writer = std.Io.File.stdout().writer(io, &buffer);
    const output = &file_writer.interface;

    try output.print("\nZig Qsolver\n", .{});
    try output.print("Solve equations in the form ax^2 + bx + c = 0\n\n", .{});
    try output.print("USAGE:\n", .{});
    try output.print("    zig run main.zig -- <a> <b> <c>\n", .{});
    try output.print("    *a,b and c must be numbers\n\n", .{});
    try output.print("FLAGSi:\n", .{});
    try output.print("    `help`   prints this message\n\n", .{});
    try output.print("EXAMPLES:\n", .{});
    try output.print("    zig run main.zig -- 1 -5 6\n", .{});
    try output.print("    zig run main.zig -- 43.2 3/4 78\n", .{});

    try output.flush();
}

fn maybeNumber(x: [:0]const u8) !Fraction {
    const number: i64 = try std.fmt.parseInt(i64, x, 10);

    return .{
        .numerator = number,
        .denominator = 1,
    };
}

fn splitOnce(text: [:0]const u8, delimiter: u8) ?struct { before: []const u8, after: []const u8 } {
    const index = std.mem.findScalar(u8, text, delimiter) orelse return null;

    return .{
        text[0..index],
        text[delimiter + 1 ..],
    };
}

fn trasform(x: [:0]const u8) anyerror!Fraction {
    if (splitOnce(x, '/')) |splitted| {
        const num: i64 = try std.fmt.parseInt(i64, splitted.before, 10);
        const den: i64 = try std.fmt.parseInt(i64, splitted.after, 10);

        if (den == 0) {
            return FractionError.denZero;
        }

        return .{
            .numerator = num,
            .denominator = den,
        };
    } else if (splitOnce(x, '.')) |splitted| {
        if (splitted.after.len > 12) {
            // todo
        } else {
            // todo
        }
    } else {
        maybeNumber(x);
    }
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
        try UnfStderrWriter(init.io, "\nError: No arguments were entered\n");
        return;
    };

    const b: [:0]const u8 = args.next() orelse {
        try UnfStderrWriter(init.io, "\nError: Entered arguments were not enough. Run with `help` for usage infos\n");
        return;
    };

    const c: [:0]const u8 = args.next() orelse {
        try UnfStderrWriter(init.io, "\nError: Entered argumets were not enough. Run with `help` for usage infos\n");
        return;
    };

    std.debug.print("{s}{s}{s}\n", .{ a, b, c });
}
