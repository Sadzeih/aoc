const std = @import("std");

pub const Day4 = struct {
    const token = "XMAS";
    const token_part2 = "MAS";

    const errors = error{
        OutOfBounds,
    };

    allocator: std.mem.Allocator,
    matrix: std.ArrayList([]const u8),

    pub fn init(allocator: std.mem.Allocator) Day4 {
        return .{
            .allocator = allocator,
            .matrix = std.ArrayList([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *Day4) void {
        self.matrix.deinit();
    }

    pub fn parseLine(self: *Day4, line: []const u8) !void {
        try self.matrix.append(line);
    }

    fn findInDirection(comptime T: type, matrix: [][]const T, needle: []const T, y_start: usize, x_start: usize, y_offset: isize, x_offset: isize) bool {
        var x: isize = @intCast(x_start);
        var y: isize = @intCast(y_start);
        var i: usize = 0;

        while (i < needle.len) {
            if (y < 0 or x < 0 or y >= matrix.len or x >= matrix[@intCast(y)].len) return false;
            if (matrix[@intCast(y)][@intCast(x)] != needle[@intCast(i)]) return false;

            // std.debug.print("{c}", .{matrix[@intCast(y)][@intCast(x)]});
            i += 1;
            x += x_offset;
            y += y_offset;
        }
        // std.debug.print("{s}", .{"\n"});
        return true;
    }

    pub fn result(self: *Day4) !struct { usize, usize } {
        var total: usize = 0;
        var total_part2: usize = 0;

        const directions = [8][2]isize{
            [_]isize{ 0, 1 },
            [_]isize{ 1, 0 },
            [_]isize{ 1, 1 },
            [_]isize{ 0, -1 },
            [_]isize{ -1, 0 },
            [_]isize{ 1, -1 },
            [_]isize{ -1, 1 },
            [_]isize{ -1, -1 },
        };

        for (self.matrix.items, 0..) |row, y| {
            for (row, 0..) |col, x| {
                if (col == 'X') {
                    for (directions) |dir| {
                        if (findInDirection(u8, self.matrix.items, token, y, x, dir[0], dir[1])) {
                            total += 1;
                        }
                    }
                }

                if (col == 'A') {
                    var x_mas_total: usize = 0;
                    for (directions) |dir| {
                        if (dir[0] == 0 or dir[1] == 0) continue;
                        if ((y == 0 and dir[0] == -1) or (y == row.len - 1 and dir[0] == 1)) continue;
                        if ((x == 0 and dir[1] == -1) or (x == row.len - 1 and dir[1] == 1)) continue;

                        const opposite_y: isize = dir[0] * -1;
                        const opposite_x: isize = dir[1] * -1;
                        if (findInDirection(u8, self.matrix.items, token_part2, @intCast(@as(isize, @intCast(y)) + dir[0]), @intCast(@as(isize, @intCast(x)) + dir[1]), opposite_y, opposite_x)) {
                            x_mas_total += 1;
                        }
                    }
                    if (x_mas_total == 2) total_part2 += 1;
                }
            }
        }

        return .{ total, total_part2 };
    }
};

test "findInDirection" {
    const allocator = std.testing.allocator;

    var matrix = std.ArrayList([]const u8).init(allocator);
    defer matrix.deinit();
    try matrix.append("MMMSXXMASM");
    try matrix.append("MSAMXMSMSA");
    try matrix.append("AMXSXMAAMM");
    try matrix.append("MSAMASMSMX");
    try matrix.append("XMASAMXAMM");
    try matrix.append("XXAMMXXAMA");
    try matrix.append("SMSMSASXSS");
    try matrix.append("SAXAMASAAA");
    try matrix.append("MAMMMXMMMM");
    try matrix.append("MXMXAXMASX");

    try std.testing.expect(Day4.findInDirection(u8, matrix.items, Day4.token, 0, 5, 0, 1));
    try std.testing.expect(Day4.findInDirection(u8, matrix.items, Day4.token, 3, 9, 1, 0));
    try std.testing.expect(Day4.findInDirection(u8, matrix.items, Day4.token, 0, 4, 1, 1));
    try std.testing.expect(Day4.findInDirection(u8, matrix.items, Day4.token, 9, 9, -1, 0));
    try std.testing.expect(Day4.findInDirection(u8, matrix.items, Day4.token, 1, 4, 0, -1));
    try std.testing.expect(Day4.findInDirection(u8, matrix.items, Day4.token, 5, 0, -1, 1));
    try std.testing.expect(Day4.findInDirection(u8, matrix.items, Day4.token, 3, 9, 1, -1));
    try std.testing.expect(Day4.findInDirection(u8, matrix.items, Day4.token, 9, 9, -1, -1));
}

test "result" {
    const allocator = std.testing.allocator;

    var day4 = Day4.init(allocator);
    defer day4.deinit();

    try day4.parseLine("MMMSXXMASM");
    try day4.parseLine("MSAMXMSMSA");
    try day4.parseLine("AMXSXMAAMM");
    try day4.parseLine("MSAMASMSMX");
    try day4.parseLine("XMASAMXAMM");
    try day4.parseLine("XXAMMXXAMA");
    try day4.parseLine("SMSMSASXSS");
    try day4.parseLine("SAXAMASAAA");
    try day4.parseLine("MAMMMXMMMM");
    try day4.parseLine("MXMXAXMASX");

    try std.testing.expectEqual(.{ 18, 9 }, try day4.result());
}
