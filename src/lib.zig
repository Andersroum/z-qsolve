/// Returns the greatest common divisor of two numbers using the Euclidean algorithm
pub fn FindGcd(x: i64, y: i64) i64 {
    var a: i64 = x;
    var b: i64 = y;

    while (b != 0) {
        const rem: i64 = @rem(a, b);
        a = b;
        b = rem;
    }
    return @intCast(@abs(a));
}

/// Returns the least common multiple of two numbers
pub fn FindLcm(x: i64, y: i64) i64 {
    return @divExact(@abs(x), FindGcd(x, y) * @abs(y));
}

pub fn SimplifyFraction(num: i64, den: i64) Fraction {
    const gcd: i64 = FindGcd(num, den);
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
        return SimplifyFraction(num, den);
    }
};
