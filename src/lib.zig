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

    pub fn findSquareRoot(x: Fraction) SquareRoot {
        const fract: Fraction = simplifyFraction(x.numerator, x.denominator);

        const numerator_square_root: i64 = findSquare(fract.numerator);
        const outside_num: i64 = numerator_square_root[0];
        const inside_num: i64 = numerator_square_root[1];

        const denominator_square_root: i64 = findSquare(fract.denominator);
        const outside_den: i64 = denominator_square_root[0];
        const inside_den: i64 = denominator_square_root[1];

        return SquareRoot{
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
};

pub fn simplifyFraction(num: i64, den: i64) Fraction {
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

pub const Fraction = struct {
    numerator: i64,
    denominator: i64,

    pub fn New(num: i64, den: i64) Fraction {
        return simplifyFraction(num, den);
    }

    pub fn mul(self: Fraction, other: Fraction) Fraction {
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

    pub fn add(self: Fraction, other: Fraction) Fraction {
        if (self.denominator == other.denominator) {
            return Fraction.New(self.numerator + other.numerator, self.denominator);
        }
        const lcm: i64 = findLcm(self.denominator, other.denominator);

        const num: i64 =
            (@divExact(lcm, self.denominator) * self.numerator) + (@divExact(lcm, other.denominator) * other.numerator);
        const den: i64 = lcm;

        return Fraction.New(num, den);
    }

    pub fn subtract(self: Fraction, other: Fraction) Fraction {
        if (self.denominator == other.denominator) {
            return Fraction.New(self.numerator - other.numerator, self.denominator);
        }
        const lcm: i64 = findLcm(self.denominator, other.denominator);

        const num: i64 =
            (@divExact(lcm, self.denominator) * self.numerator) - (@divExact(lcm, other.denominator) * other.numerator);
        const den: i64 = lcm;

        return Fraction.New(num, den);
    }
};
