const std = @import("std");
const lib = @import("lib.zig");
const Fraction = lib.Fraction;
const SquareRoot = lib.SquareRoot;
const FractionError = lib.Fraction_error;

pub const QuadraticResult = union(enum) {
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

pub fn trasform(x: [:0]const u8) anyerror!Fraction {
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

pub fn constructResult(a: Fraction, b: Fraction, c: Fraction) !QuadraticResult {
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
