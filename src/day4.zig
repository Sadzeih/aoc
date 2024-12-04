const std = @import("std");
const findToken = @import("token.zig").findToken;

pub const Day4 = struct {
    const token = "XMAS";
    const reversedToken = "SAMX";

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

    fn findOccurences(occurences: u16, haystack: []const u8, needle: []const u8) u16 {
        const found: ?usize = findToken(u8, haystack, needle);
        if (found != null) {
            // std.debug.print("found at: {d}\n", .{found.?});
            return 1 + findOccurences(occurences, haystack[found.?..], needle);
        }
        return occurences;
    }

    fn makeDiagonal(allocator: std.mem.Allocator, comptime T: type, matrix: [][]const T, x: usize, y: usize, offset: isize) ![]const T {
        var diagonal = std.ArrayList(u8).init(allocator);
        defer diagonal.deinit();

        var i: usize = x;
        var j: usize = y;
        while (j >= 0 and i >= 0 and j < matrix.len and i < matrix.len) : ({
            if (offset < 0) {
                if (i == 0) break;
                i -|= @intCast(@abs(offset));
                j +|= @intCast(@abs(offset));
            } else {
                i +|= @intCast(offset);
                j +|= @intCast(offset);
            }
        }) {
            // std.debug.print("x: {}, y: {}\n", .{ i, j });
            try diagonal.append(matrix[j][i]);
        }

        return diagonal.toOwnedSlice();
    }

    fn makeVertical(allocator: std.mem.Allocator, comptime T: type, matrix: [][]const T, i: usize) ![]const T {
        if (i >= matrix.len) return errors.OutOfBounds;

        var vertical = std.ArrayList(u8).init(allocator);
        defer vertical.deinit();

        var j: usize = 0;
        while (j < matrix.len) : (j += 1) {
            try vertical.append(matrix[j][i]);
        }

        return vertical.toOwnedSlice();
    }

    pub fn result(self: *Day4) !u16 {
        var total: u16 = 0;

        for (self.matrix.items, 0..) |line, i| {
            total += findOccurences(0, line, token);
            total += findOccurences(0, line, reversedToken);

            const vert = try makeVertical(self.allocator, u8, self.matrix.items, i);
            total += findOccurences(0, vert, token);
            total += findOccurences(0, vert, reversedToken);
            self.allocator.free(vert);

            var diag = try makeDiagonal(self.allocator, u8, self.matrix.items, 0, i, 1);
            total += findOccurences(0, diag, token);
            total += findOccurences(0, diag, reversedToken);
            self.allocator.free(diag);
            diag = try makeDiagonal(self.allocator, u8, self.matrix.items, i, 0, 1);
            total += findOccurences(0, diag, token);
            total += findOccurences(0, diag, reversedToken);
            self.allocator.free(diag);

            diag = try makeDiagonal(self.allocator, u8, self.matrix.items, line.len - 1, i, -1);
            total += findOccurences(0, diag, token);
            total += findOccurences(0, diag, reversedToken);
            self.allocator.free(diag);
            diag = try makeDiagonal(self.allocator, u8, self.matrix.items, line.len - 1, 0, -1);
            total += findOccurences(0, diag, token);
            total += findOccurences(0, diag, reversedToken);
            self.allocator.free(diag);
        }

        return total;
    }
};

test "findOccurences" {
    try std.testing.expectEqual(1, Day4.findOccurences(0, "MMMSXXMASM", "XMAS"));
    try std.testing.expectEqual(0, Day4.findOccurences(0, "MMMSXXMASM", "SAMX"));
    try std.testing.expectEqual(2, Day4.findOccurences(0, "XMASXXMASM", "XMAS"));
    try std.testing.expectEqual(1, Day4.findOccurences(0, "MSAMXMSMSA", "SAMX"));
}

test "makeDiagonal" {
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

    const slice = try Day4.makeDiagonal(allocator, u8, matrix.items, 0, 0, 1);
    defer allocator.free(slice);
    try std.testing.expect(std.mem.eql(u8, "MSXMAXSAMX", slice));
    const slice2 = try Day4.makeDiagonal(allocator, u8, matrix.items, 1, 1, 1);
    defer allocator.free(slice2);
    try std.testing.expect(std.mem.eql(u8, "SXMAXSAMX", slice2));
    const slice3 = try Day4.makeDiagonal(allocator, u8, matrix.items, 0, 1, 1);
    defer allocator.free(slice3);
    try std.testing.expect(std.mem.eql(u8, "MMASMASMS", slice3));
    const slice4 = try Day4.makeDiagonal(allocator, u8, matrix.items, 9, 0, -1);
    defer allocator.free(slice4);
    try std.testing.expect(std.mem.eql(u8, "MSAMMMMXAM", slice4));
}

test "makeVertical" {
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

    const slice = try Day4.makeVertical(allocator, u8, matrix.items, 0);
    defer allocator.free(slice);
    try std.testing.expect(std.mem.eql(u8, "MMAMXXSSMM", slice));
    const slice2 = try Day4.makeVertical(allocator, u8, matrix.items, 5);
    defer allocator.free(slice2);
    try std.testing.expect(std.mem.eql(u8, "XMMSMXAAXX", slice2));
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

    try std.testing.expectEqual(18, try day4.result());
}
