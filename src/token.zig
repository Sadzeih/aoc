const std = @import("std");

pub fn findToken(comptime T: type, haystack: []const T, token: []const T) ?usize {
    var i: usize = 0;

    while (i < haystack.len and i + token.len <= haystack.len) : (i += 1) {
        // std.debug.print("{s}\n", .{haystack[i .. i + token.len]});
        if (std.mem.eql(u8, haystack[i .. i + token.len], token)) return i;
    }
    return null;
}

test "findToken" {
    try std.testing.expectEqual(5, findToken(u8, "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))", "mul("));
    try std.testing.expectEqual(24, findToken(u8, "%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))", "mul("));
}
