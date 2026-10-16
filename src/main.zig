const std = @import("std");
const lib = @import("lib.zig");
const solver = @import("solver.zig");
const trasform = solver.trasform;
const constructResult = solver.constructResult;
const QuadraticResult = solver.QuadraticResult;
const Fraction = lib.Fraction;
const FractionError = lib.Fraction_error;

const stderr = std.Io.File.stderr();
pub const panic = std.debug.FullPanic(customPanic);

pub fn customPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
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
            error.Overflow => {
                try UnfStderrWriter(init.io, "\nError: The input('a') is too large for an i64 to store\n");
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
            error.Overflow => {
                try UnfStderrWriter(init.io, "\nError: The input('b') is too large for an i64 to store\n");
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
            error.Overflow => {
                try UnfStderrWriter(init.io, "\nError: The input('c') is too large for an i64 to store\n");
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
