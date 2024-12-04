const std = @import("std");
const findToken = @import("token.zig").findToken;

const Day3 = struct {
    const instruction_start = "mul(";
    const delimiter = ",";
    const end = ")";

    const do_token = "do()";
    const dont_token = "don't()";

    do: bool = true,
    allocator: std.mem.Allocator,
    mults: std.ArrayList([2]u16),

    fn init(allocator: std.mem.Allocator) Day3 {
        return .{
            .allocator = allocator,
            .mults = std.ArrayList([2]u16).init(allocator),
        };
    }

    fn deinit(self: *Day3) void {
        self.mults.deinit();
    }

    fn parseLine(self: *Day3, line: []const u8) !void {
        const i: ?usize = findToken(u8, line, Day3.instruction_start) orelse return;
        const do_idx: ?usize = findToken(u8, line, Day3.do_token);
        const dont_idx: ?usize = findToken(u8, line, Day3.dont_token);

        var indexes = std.ArrayList(usize).init(self.allocator);
        defer indexes.deinit();

        try indexes.append(i.?);
        if (do_idx != null) {
            try indexes.append(do_idx.?);
        }
        if (dont_idx != null) {
            try indexes.append(dont_idx.?);
        }
        std.mem.sort(usize, indexes.items, {}, std.sort.asc(usize));
        for (indexes.items) |idx| {
            if (idx == i) break;
            if (idx == do_idx) self.do = true;
            if (idx == dont_idx) self.do = false;
        }

        const first_number_idx: usize = i.?;
        const end_idx = i.? + (findToken(u8, line[first_number_idx..], Day3.end) orelse return);

        var it = std.mem.tokenizeAny(u8, line[first_number_idx .. end_idx - 1], ",");

        var mults = [2]u16{ 0, 0 };
        var j: usize = 0;
        while (it.next()) |number| : (j += 1) {
            mults[j] = std.fmt.parseInt(u16, number, 10) catch {
                return try self.parseLine(line[i.?..]);
            };
        }

        if (self.do) {
            try self.mults.append(mults);
        }

        try self.parseLine(line[i.?..]);
    }

    fn result(self: *Day3) u64 {
        var total: u64 = 0;
        for (self.mults.items) |mult| {
            total += @as(u64, @intCast(mult[0])) * @as(u64, @intCast(mult[1]));
        }
        return total;
    }
};

test "Day3.parseLine" {
    var d3: Day3 = Day3.init(std.testing.allocator);
    defer d3.deinit();

    try d3.parseLine("xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(111,842)mul(8,5))");

    try std.testing.expectEqual([2]u16{ 2, 4 }, d3.mults.items[0]);
    try std.testing.expectEqual([2]u16{ 5, 5 }, d3.mults.items[1]);
    try std.testing.expectEqual([2]u16{ 111, 842 }, d3.mults.items[2]);
    try std.testing.expectEqual([2]u16{ 8, 5 }, d3.mults.items[3]);
}

test "Day3.result 1" {
    var d3: Day3 = Day3.init(std.testing.allocator);
    defer d3.deinit();

    try d3.parseLine("xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))");
    try std.testing.expectEqual(161, d3.result());
}

test "Day3.result 2" {
    var d3: Day3 = Day3.init(std.testing.allocator);
    defer d3.deinit();

    try d3.parseLine("xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))");
    try std.testing.expectEqual(48, d3.result());
}
