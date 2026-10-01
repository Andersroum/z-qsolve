const std = @import("std");
const lib = @import("lib.zig");
const fraction = lib.Fraction;

pub fn main() void {
    const fract1: fraction = fraction.New(6, 3);
    std.debug.print("{d}/{d}\n", .{ fract1.numerator, fract1.denominator });
}
