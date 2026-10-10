const std = @import("std");

pub fn findGcd(x: i64, y: i64) i64 {
    var a: i64 = x;
    var b: i64 = y;

    while (b != 0) {
        const rem: i64 = @rem(a, b);
        a = b;
        b = rem;
    }
    return @intCast(@abs(a));
}

pub fn findLcm(x: i64, y: i64) i64 {
    const abs_x: i64 = @as(i64, @intCast(@abs(x)));
    const abs_y: i64 = @as(i64, @intCast(@abs(y)));

    return @divExact(abs_x, findGcd(x, y)) * abs_y;
}

pub fn findSquare(num: i64) struct { i64, i64 } {
    var inside: i64 = @intCast(@abs(num));
    var outside: i64 = 1;

    while (@rem(inside, 4) == 0) {
        inside = @divExact(inside, 4);
        outside *= 2;
    }

    var iterations: u16 = 0;
    var i: i64 = 3;
    while (i < @divTrunc(inside, i)) {
        const i_sqr: i64 = i * i;
        while (@rem(inside, i_sqr) == 0) {
            inside = @divExact(inside, i_sqr);
            outside *= i;
        }
        iterations += 1;

        if (iterations > 2500) {
            break;
        }

        i += 2;
    }

    return .{ outside, inside };
}

pub const SquareRoot = struct {
    outside: Fraction,
    inside: Fraction,

    const Self = @This();

    pub fn findSquareRoot(x: Fraction) Self {
        const fract: Fraction = createSimplifiedFract(x.numerator, x.denominator);

        const numerator_square_root: i64 = findSquare(fract.numerator);
        const outside_num: i64 = numerator_square_root[0];
        const inside_num: i64 = numerator_square_root[1];

        const denominator_square_root: i64 = findSquare(fract.denominator);
        const outside_den: i64 = denominator_square_root[0];
        const inside_den: i64 = denominator_square_root[1];

        return .{
            .outside = Fraction{
                .numerator = outside_num,
                .denominator = outside_den,
            },
            //
            .inside = Fraction{
                .numerator = inside_num,
                .denominator = inside_den,
            },
        };
    }

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        if (self.inside.numerator == self.inside.denominator) {
            if (self.outside.denominator == 1) {
                try writer.print("{d}", .{self.outside.numerator});
            } else {
                try writer.print("({f})", .{self.outside});
            }
        } else {
            if (self.outside.denominator == 1) {
                try writer.print("{d}√{f}", .{ self.outside.numerator, self.inside });
            } else {
                try writer.print("({f})√{f}", .{ self.outside, self.inside });
            }
        }
    }
};

pub fn createSimplifiedFract(num: i64, den: i64) Fraction {
    const gcd: i64 = findGcd(num, den);
    var a: i64 = @divExact(num, gcd);
    var b: i64 = @divExact(den, gcd);

    if (b < 0) {
        a = -a;
        b = -b;

        return .{
            .numerator = a,
            .denominator = b,
        };
    }

    return .{
        .numerator = a,
        .denominator = b,
    };
}

pub const Fraction_error = error{
    denZero, //
    divisionByZero, //
    multiplicationByZero, //
    inputInfiniteOrNan,
};

pub const Fraction = struct {
    numerator: i64,
    denominator: i64,

    const Self = @This();

    pub fn New(num: i64, den: i64) Fraction_error!Self {
        if (den == 0) {
            return Fraction_error.denZero;
        }
        return createSimplifiedFract(num, den);
    }

    pub fn mul(self: Self, other: Self) Fraction_error!Self {
        if (self.numerator == 0 or
            self.denominator == 0 or
            other.numerator == 0 or
            other.denominator == 0)
        {
            return Fraction_error.multiplicationByZero;
        }

        const gcd_num_self_den_other: i64 = findGcd(self.numerator, other.denominator);
        const gcd_den_self_num_other: i64 = findGcd(self.denominator, other.numerator);

        var num: i64 = @divExact(self.numerator, gcd_num_self_den_other) * @divExact(other.numerator, gcd_den_self_num_other);
        var den: i64 = @divExact(self.denominator, gcd_den_self_num_other) * @divExact(other.denominator, gcd_num_self_den_other);

        if (den < 0) {
            num = -num;
            den = -den;
        }

        return .{ .numerator = num, .denominator = den };
    }

    pub fn add(self: Fraction, other: Fraction) Fraction_error!Fraction {
        if (self.denominator == other.denominator) {
            return try Fraction.New(self.numerator + other.numerator, self.denominator);
        }
        const lcm: i64 = findLcm(self.denominator, other.denominator);

        const num: i64 =
            (@divExact(lcm, self.denominator) * self.numerator) + (@divExact(lcm, other.denominator) * other.numerator);
        const den: i64 = lcm;

        return try Fraction.New(num, den);
    }

    pub fn sub(self: Fraction, other: Fraction) Fraction {
        if (self.denominator == other.denominator) {
            return try Fraction.New(self.numerator - other.numerator, self.denominator);
        }
        const lcm: i64 = findLcm(self.denominator, other.denominator);

        const num: i64 =
            (@divExact(lcm, self.denominator) * self.numerator) - (@divExact(lcm, other.denominator) * other.numerator);
        const den: i64 = lcm;

        return try Fraction.New(num, den);
    }

    pub fn div(self: Fraction, other: Fraction) Fraction_error!Fraction {
        return try self.mul(Fraction{
            .numerator = other.denominator,
            .denominator = other.numerator,
        });
    }

    pub fn from(num: f64) Fraction_error!Self {
        if (!std.math.isFinite(num)) {
            return Fraction_error.inputInfiniteOrNan;
        }
        var x: f64 = num;
        const a: i64 = @floor(x);

        var c0: struct { i64, i64 } = .{ a, 1 };

        if (x - @floor(x) < 1e-10) {
            return Fraction.New(c0[0], c0[1]);
        }

        x = 1.0 / (x - @floor(x));
        const a1: i64 = @floor(x);

        var c1: struct { i64, i64 } = .{ a * a1 + 1, a1 };

        var iterations: u8 = 0;

        while (true) {
            const remainder = x - @floor(x);

            if (remainder < 1e-10 or iterations > 15) {
                break;
            }

            x = 1.0 / remainder;
            const temp_a: i64 = @floor(x);

            const new_num = c1[0] * temp_a + c0[0];
            const new_den = c1[1] * temp_a + c0[1];

            c0 = c1;
            c1 = .{ new_num, new_den };

            iterations += 1;
        }
        return Fraction.New(c1[0], c1[1]);
    }

    pub fn format(
        self: Fraction,
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        if (self.denominator == 1) {
            try writer.print("{d}", .{self.numerator});
        } else {
            try writer.print("{d}/{d}", .{ self.numerator, self.denominator });
        }
    }
};

test "Fraction conversion from f64" {
    const testing = std.testing;

    {
        const fract: Fraction = try Fraction.from(4);
        try testing.expectEqual(@as(i128, 4), fract.numerator);
        try testing.expectEqual(@as(i128, 1), fract.denominator);
    }

    {
        const fract: Fraction = try Fraction.from(0.5);
        try testing.expectEqual(@as(i128, 1), fract.numerator);
        try testing.expectEqual(@as(i128, 2), fract.denominator);
    }

    {
        const fract: Fraction = try Fraction.from(-3.25);
        try testing.expectEqual(@as(i128, -13), fract.numerator);
        try testing.expectEqual(@as(i128, 4), fract.denominator);
    }

    {
        const fract: Fraction = try Fraction.from(0.375);
        try testing.expectEqual(@as(i128, 3), fract.numerator);
        try testing.expectEqual(@as(i128, 8), fract.denominator);
    }

    {
        try testing.expectError(Fraction_error.inputInfiniteOrNan, Fraction.from(std.math.inf(f64)));
    }

    {
        try testing.expectError(Fraction_error.inputInfiniteOrNan, Fraction.from(std.math.nan(f64)));
    }
}
