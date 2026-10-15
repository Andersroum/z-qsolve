const std = @import("std");
const lib = @import("lib.zig");
const SquareRoot = lib.SquareRoot;
const Fraction = lib.Fraction;
const FractionError = lib.Fraction_error;

const stderr = std.Io.File.stderr();
pub const panic = std.debug.FullPanic(customPanic);

fn customPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    _ = first_trace_addr;
    var buf: [512]u8 = undefined;

    const formatted = std.fmt.bufPrint(
        &buf,
        "\n[Critical: Panic] ==========\nReason:{s}\n============================\n",
        .{msg},
    ) catch "\nA panic occured. The message was too long\n";

    const err_out = std.posix.STDERR_FILENO;
    _ = std.posix.system.write(err_out, formatted.ptr, formatted.len);

    std.process.exit(1);
}

const QuadraticResult = union(enum) {
    OneReal: Fraction,
    TwoReal: struct {
        first_part: Fraction,
        sqrt_part: SquareRoot,
    },
    Complex: struct {
        first_part: Fraction,
        sqrt_part: SquareRoot,
    },

    pub fn format(self: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
        switch (self) {
            .OneReal => {
                try writer.print("{f}", .{self.OneReal});
            },
            .TwoReal => {
                try writer.print("{f} ± {f}", .{ self.TwoReal.first_part, self.TwoReal.sqrt_part });
            },
            .Complex => {
                if (self.Complex.sqrt_part.inside.numerator == self.Complex.sqrt_part.inside.denominator) {
                    if (self.Complex.sqrt_part.outside.denominator == 1) {
                        try writer.print("{f} ± {f}i", .{ self.Complex.first_part, self.Complex.sqrt_part });
                    } else {
                        try writer.print("{f} ± ({f})i", .{ self.Complex.first_part, self.Complex.sqrt_part });
                    }
                } else {
                    if (self.Complex.sqrt_part.outside.denominator == 1) {
                        try writer.print("{f} ± {f}i√{f}", .{ self.Complex.first_part, self.Complex.sqrt_part.outside, self.Complex.sqrt_part.inside });
                    } else {
                        try writer.print("{f} ± ({f})i√{f}", .{ self.Complex.first_part, self.Complex.sqrt_part.outside, self.Complex.sqrt_part.inside });
                    }
                }
            },
        }
    }
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

fn unexpectedErrorPrint(init: std.process.Init, err: anyerror) !void {
    const io = init.io;

    var buffer: [512]u8 = undefined;
    var stderr_writer = stderr.writer(io, &buffer);
    const err_output = &stderr_writer.interface;

    try UnfStderrWriter(io, "\nUnexpected error encountered:\n");
    try err_output.print("    {}\n", .{err});
    try err_output.flush();
}

fn maybeNumber(x: []const u8) !Fraction {
    const number: i64 = try std.fmt.parseInt(i64, x, 10);

    return .{
        .numerator = number,
        .denominator = 1,
    };
}

fn exactDecimal(before: []const u8, after: []const u8) !Fraction {
    const len: i64 = @intCast(after.len);
    const den: i64 = std.math.pow(i64, 10, len);

    const before_int: i64 = try std.fmt.parseInt(i64, before, 10);
    const after_int: i64 = try std.fmt.parseInt(i64, after, 10);

    const num: i64 = if (before_int < 0) before_int * den - after_int else before_int * den + after_int;

    return Fraction.New(num, den);
}

fn containsDot(x: []const u8) !Fraction {
    const parsed_inp: f64 = try std.fmt.parseFloat(f64, x);
    return Fraction.from(parsed_inp);
}

fn splitOnce(text: []const u8, delimiter: u8) ?struct { before: []const u8, after: []const u8 } {
    const index = std.mem.findScalar(u8, text, delimiter) orelse return null;

    return .{
        .before = text[0..index],
        .after = text[index + 1 ..],
    };
}

fn trasform(x: [:0]const u8) anyerror!Fraction {
    if (splitOnce(x, '/')) |splitted| {
        const num: i64 = try std.fmt.parseInt(i64, splitted.before, 10);
        const den: i64 = try std.fmt.parseInt(i64, splitted.after, 10);

        if (den == 0) {
            return FractionError.denZero;
        }

        return Fraction.New(num, den);
    } else if (splitOnce(x, '.')) |splitted| {
        if (splitted.after.len > 8) {
            return try containsDot(x);
        } else {
            return try exactDecimal(splitted.before, splitted.after);
        }
    } else {
        return try maybeNumber(x);
    }
}

fn constructResult(a: Fraction, b: Fraction, c: Fraction) !QuadraticResult {
    const neg_four: Fraction = Fraction{ .numerator = -4, .denominator = 1 };
    const two: Fraction = Fraction{
        .numerator = 2,
        .denominator = 1,
    };
    const neg_one: Fraction = Fraction{
        .numerator = -1,
        .denominator = 1,
    };

    const det: Fraction = det: {
        const b_sq: Fraction = try b.mul(b);
        const four_a_c: Fraction = try (try neg_four.mul(a)).mul(c);

        break :det try b_sq.add(four_a_c);
    };
    const den: Fraction = try two.mul(a);
    const first_part: Fraction = first_part: {
        const one_b: Fraction = try neg_one.mul(b);

        break :first_part try one_b.div(den);
    };

    const square_root: SquareRoot = try SquareRoot.findSquareRoot(det);
    const outside: Fraction = square_root.outside;
    const inside: Fraction = square_root.inside;

    const second_part: Fraction = try outside.div(den);

    if (det.numerator == 0) {
        return .{
            .OneReal = first_part,
        };
    } else if (det.numerator < 0) {
        return .{
            .Complex = .{
                .first_part = first_part,
                .sqrt_part = .{
                    .outside = second_part,
                    .inside = inside,
                },
            },
        };
    } else {
        return .{
            .TwoReal = .{
                .first_part = first_part,
                .sqrt_part = .{
                    .outside = second_part,
                    .inside = inside,
                },
            },
        };
    }
}

pub fn main(init: std.process.Init) !void {
    var args = init.minimal.args.iterate();
    _ = args.next();

    const a: Fraction = if (args.next()) |arg| out_path: {
        if (std.ascii.eqlIgnoreCase(arg, "help")) {
            try printHelp(init);
            return;
        }

        const temp_a: Fraction = trasform(arg) catch |err| switch (err) {
            FractionError.denZero => {
                try UnfStderrWriter(init.io, "\nError: The denominator cannot be zero\n");
                return;
            },
            FractionError.inputInfiniteOrNan => {
                try UnfStderrWriter(init.io, "\nError: The input cannot be infinite/NaN\n");
                return;
            },
            error.InvalidCharacter => {
                try UnfStderrWriter(init.io, "\nError: The input('a') couldn't be parsed: Invalid input\n");
                return;
            },
            else => {
                try unexpectedErrorPrint(init, err);
                return;
            },
        };

        if (temp_a.numerator == 0) {
            try UnfStderrWriter(init.io, "\nError: 'a' cannot be zero\n");
            return;
        }

        break :out_path temp_a;
    } else {
        try printHelp(init);
        try UnfStderrWriter(init.io, "\nError: No arguments were entered\n");
        return;
    };

    const b: Fraction = if (args.next()) |arg| out_path: {
        const temp_b: Fraction = trasform(arg) catch |err| switch (err) {
            FractionError.denZero => {
                try UnfStderrWriter(init.io, "\nError: The denominator cannot be zero\n");
                return;
            },
            FractionError.inputInfiniteOrNan => {
                try UnfStderrWriter(init.io, "\nError: The input cannot be infinite/NaN\n");
                return;
            },
            error.InvalidCharacter => {
                try UnfStderrWriter(init.io, "\nError: The input('b') couldn't be parsed: Invalid input\n");
                return;
            },
            else => {
                try unexpectedErrorPrint(init, err);
                return;
            },
        };

        break :out_path temp_b;
    } else {
        try UnfStderrWriter(init.io, "\nError: Entered arguments were not enough. Run with `help` for usage infos\n");
        return;
    };

    const c: Fraction = if (args.next()) |arg| out_path: {
        const temp_c: Fraction = trasform(arg) catch |err| switch (err) {
            FractionError.denZero => {
                try UnfStderrWriter(init.io, "\nError: The denominator cannot be zero\n");
                return;
            },
            FractionError.inputInfiniteOrNan => {
                try UnfStderrWriter(init.io, "\nError: The input cannot be infinite/NaN\n");
                return;
            },
            error.InvalidCharacter => {
                try UnfStderrWriter(init.io, "\nError: The input('c') couldn't be parsed: Invalid input\n");
                return;
            },
            else => {
                try unexpectedErrorPrint(init, err);
                return;
            },
        };

        break :out_path temp_c;
    } else {
        try UnfStderrWriter(init.io, "\nError: Entered argumets were not enough. Run with `help` for usage infos\n");
        return;
    };

    const result: QuadraticResult = constructResult(a, b, c) catch |err| {
        try unexpectedErrorPrint(init, err);
        return;
    };

    var buffer: [512]u8 = undefined;
    var file_writer = std.Io.File.stdout().writer(init.io, &buffer);
    const output = &file_writer.interface;

    switch (result) {
        .OneReal => {
            try output.print("This quadratic has a real solution:\n", .{});
            try output.print("     {f}", .{result});
            try output.flush();
        },
        .TwoReal => {
            try output.print("This quadratic has two real solutions:\n", .{});
            try output.print("     {f}", .{result});
            try output.flush();
        },
        .Complex => {
            try output.print("This quadratic has two complex solutions:\n", .{});
            try output.print("     {f}", .{result});
            try output.flush();
        },
    }
}
