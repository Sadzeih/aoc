const std = @import("std");

const Day1 = struct {
    allocator: std.mem.Allocator,
    left_list: std.ArrayList(u32),
    right_list: std.ArrayList(u32),

    fn init(allocator: std.mem.Allocator) Day1 {
        return Day1{
            .allocator = allocator,
            .left_list = std.ArrayList(u32).init(allocator),
            .right_list = std.ArrayList(u32).init(allocator),
        };
    }

    fn deinit(self: *Day1) void {
        self.left_list.deinit();
        self.right_list.deinit();
    }

    fn parseLine(self: *Day1, line: [:0]u8) !void {
        var location_ids = std.mem.tokenizeAny(u8, line, " \n");

        var first = true;
        while (location_ids.next()) |id| {
            if (first) {
                try self.left_list.append(try std.fmt.parseInt(u32, id, 10));
                first = false;
                continue;
            }
            try self.right_list.append(try std.fmt.parseInt(u32, id, 10));
            break;
        }
    }

    fn produceDistance(self: *Day1) u32 {
        std.mem.sort(u32, self.left_list.items, {}, comptime std.sort.asc(u32));
        std.mem.sort(u32, self.right_list.items, {}, comptime std.sort.asc(u32));

        var total: u32 = 0;
        for (self.left_list.items, self.right_list.items) |left, right| {
            const left_i32: i32 = @intCast(left);
            const right_i32: i32 = @intCast(right);
            total += @abs(left_i32 - right_i32);
        }

        return total;
    }

    fn produceSimilarityScore(self: Day1) !u32 {
        var set = try std.bit_set.DynamicBitSet.initEmpty(self.allocator, self.left_list.items.len);
        defer set.deinit();

        var total: u32 = 0;
        for (self.left_list.items, 0..) |left, i| {
            if (!set.isSet(i)) set.set(i);
            const right_count: u32 = @intCast(std.mem.count(u32, self.right_list.items, &[_]u32{left}));
            total += left * right_count;
        }

        return total;
    }
};

test "Day1.produceDistance" {
    var day1: Day1 = Day1.init(std.testing.allocator);
    defer day1.deinit();
    try day1.left_list.appendSlice(&[_]u32{ 3, 4, 2, 1, 3, 3 });
    try day1.right_list.appendSlice(&[_]u32{ 4, 3, 5, 3, 9, 3 });

    try std.testing.expectEqual(11, day1.produceDistance());
}

test "Day1.produceSimilarityScore" {
    var day1: Day1 = Day1.init(std.testing.allocator);
    defer day1.deinit();
    try day1.left_list.appendSlice(&[_]u32{ 3, 4, 2, 1, 3, 3 });
    try day1.right_list.appendSlice(&[_]u32{ 4, 3, 5, 3, 9, 3 });

    try std.testing.expectEqual(31, day1.produceSimilarityScore());
}

const Report = struct {
    allocator: std.mem.Allocator,
    levels: std.ArrayList(u32),

    fn init(allocator: std.mem.Allocator) Report {
        return Report{
            .allocator = allocator,
            .levels = std.ArrayList(u32).init(allocator),
        };
    }

    fn deinit(self: *Report) void {
        self.levels.deinit();
    }

    fn appendLevels(self: *Report, levels: []const u32) !void {
        try self.levels.appendSlice(levels);
    }

    fn appendLevel(self: *Report, level: u32) !void {
        try self.levels.append(level);
    }

    fn findFirstDifference(comptime T: type, a: []const T, b: []const T) bool {
        if (a.len < b.len) return false;
        for (a, b) |ai, bi| {
            if (ai != bi) {
                return false;
            }
        }
        return true;
    }

    fn isSliceSafe(self: Report, slice: []u32) !bool {
        const asc = try self.allocator.alloc(u32, slice.len);
        defer self.allocator.free(asc);
        @memcpy(asc, slice);
        std.mem.sort(u32, asc, {}, std.sort.asc(u32));
        const desc = try self.allocator.alloc(u32, slice.len);
        defer self.allocator.free(desc);
        @memcpy(desc, slice);
        std.mem.sort(u32, desc, {}, std.sort.desc(u32));
        const is_inc: bool = Report.findFirstDifference(u32, slice, asc);
        const is_desc: bool = Report.findFirstDifference(u32, slice, desc);
        const inc_or_dec: bool = is_inc or is_desc;

        var i: usize = 0;
        var good_diff: bool = true;
        while (i < slice.len) : (i += 1) {
            if (i + 1 >= slice.len) break;
            const diff: i32 = @as(i32, @intCast(slice[i])) - @as(i32, @intCast(slice[i + 1]));
            if (@abs(diff) < 1 or @abs(diff) > 3) {
                good_diff = false;
                break;
            }
        }
        return inc_or_dec and good_diff;
    }

    fn isSafe(self: *const Report) !bool {
        // var safe: bool = true;
        var safe: bool = try self.isSliceSafe(self.levels.items);
        if (safe) {
            return true;
        }

        var i: usize = 0;
        const test_slice = try self.allocator.alloc(u32, self.levels.items.len);
        defer self.allocator.free(test_slice);
        while (i < self.levels.items.len and safe != true) : (i += 1) {
            @memcpy(test_slice, self.levels.items);
            std.mem.copyForwards(u32, test_slice[i..], test_slice[i + 1 ..]);
            safe = try self.isSliceSafe(test_slice[0 .. test_slice.len - 1]);
        }

        return safe;
    }
};

test "Report.isSafe" {
    const reports = [15][5]u32{
        [_]u32{ 7, 6, 4, 2, 1 },
        [_]u32{ 1, 2, 7, 8, 9 },
        [_]u32{ 9, 7, 6, 2, 1 },
        [_]u32{ 1, 3, 2, 4, 5 },
        [_]u32{ 8, 6, 4, 4, 1 },
        [_]u32{ 1, 3, 6, 7, 9 },
        [_]u32{ 27, 25, 28, 29, 30 },
        [_]u32{ 65, 68, 71, 72, 71 },
        [_]u32{ 19, 17, 21, 24, 26 },
        [_]u32{ 17, 21, 24, 26, 50 },
        [_]u32{ 17, 21, 24, 26, 23 },
        [_]u32{ 20, 21, 24, 26, 26 },
        [_]u32{ 20, 27, 23, 25, 26 },
        [_]u32{ 20, 21, 24, 28, 26 },
        [_]u32{ 15, 21, 24, 27, 29 },
    };

    const expecteds = [_]bool{
        true,
        false,
        false,
        true,
        true,
        true,
        true,
        true,
        true,
        false,
        false,
        true,
        true,
        true,
        true,
    };

    for (reports, expecteds) |levels, expected| {
        var report: Report = Report.init(std.testing.allocator);
        defer report.deinit();
        try report.appendLevels(levels[0..]);
        const is_safe = try report.isSafe();
        try std.testing.expectEqual(expected, is_safe);
    }
}

const Day2 = struct {
    allocator: std.mem.Allocator,
    reports: std.ArrayList(Report),

    fn init(allocator: std.mem.Allocator) Day2 {
        return Day2{
            .allocator = allocator,
            .reports = std.ArrayList(Report).init(allocator),
        };
    }

    fn deinit(self: *Day2) void {
        var i: usize = 0;
        while (i < self.reports.items.len) : (i += 1) {
            self.reports.items[i].deinit();
        }
        self.reports.deinit();
    }

    fn parseLine(self: *Day2, line: []u8) !void {
        var levels_data = std.mem.tokenizeAny(u8, line, " \n");

        var report: Report = Report.init(self.allocator);
        while (levels_data.next()) |level| {
            try report.appendLevel(try std.fmt.parseInt(u32, level, 10));
        }
        try self.reports.append(report);
    }

    fn countSafeReports(self: *Day2) !u32 {
        var safe_reports: u32 = 0;
        for (self.reports.items) |report| {
            if (try report.isSafe()) {
                safe_reports += 1;
                continue;
            }
        }
        return safe_reports;
    }
};

test "Day2.countSafeReports" {
    var day2: Day2 = Day2.init(std.testing.allocator);
    defer day2.deinit();

    const reports = [_][5]u32{
        [_]u32{ 7, 6, 4, 2, 1 },
        [_]u32{ 1, 2, 7, 8, 9 },
        [_]u32{ 9, 7, 6, 2, 1 },
        [_]u32{ 1, 3, 2, 4, 5 },
        [_]u32{ 8, 6, 4, 4, 1 },
        [_]u32{ 1, 3, 6, 7, 9 },
    };

    for (reports) |levels| {
        var report: Report = Report.init(std.testing.allocator);
        try report.appendLevels(levels[0..]);
        try day2.reports.append(report);
    }

    try std.testing.expectEqual(4, day2.countSafeReports());
}

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

    fn findToken(comptime T: type, haystack: []const T, token: []const T) ?usize {
        var i: usize = 0;

        while (i < haystack.len and i + token.len <= haystack.len) : (i += 1) {
            if (std.mem.eql(u8, haystack[i .. i + token.len], token)) return i + token.len;
        }
        return null;
    }

    fn parseLine(self: *Day3, line: []const u8) !void {
        // std.debug.print("line size: {d}\n", .{line.len});
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
            if (idx == i) {
                std.debug.print("{d} {s}\n", .{ idx, "idx == i" });
                break;
            }
            if (idx == do_idx) {
                std.debug.print("{d} {s}\n", .{ idx, "idx == do" });
                self.do = true;
            }
            if (idx == dont_idx) {
                std.debug.print("{d} {s}\n", .{ idx, "idx == dont" });
                self.do = false;
            }
        }
        std.debug.print("{}\n", .{self.do});

        // std.debug.print("first idx: {d}\n", .{i.?});
        const first_number_idx: usize = i.?;
        const end_idx = i.? + (findToken(u8, line[first_number_idx..], Day3.end) orelse return);

        // std.debug.print("inside instruction: {s}\n", .{line[first_number_idx .. end_idx - 1]});

        var it = std.mem.tokenizeAny(u8, line[first_number_idx .. end_idx - 1], ",");

        var mults = [2]u16{ 0, 0 };
        var j: usize = 0;
        while (it.next()) |number| : (j += 1) {
            mults[j] = std.fmt.parseInt(u16, number, 10) catch {
                return try self.parseLine(line[i.?..]);
            };
        }

        if (self.do) {
            std.debug.print("mul({d},{d})\n", .{ mults[0], mults[1] });
            try self.mults.append(mults);
        }

        try self.parseLine(line[i.?..]);
    }

    fn result(self: *Day3) u64 {
        var total: u64 = 0;
        for (self.mults.items, 0..) |mult, i| {
            std.debug.print("{d} mul({d},{d})\n", .{ i, mult[0], mult[1] });
            total += @as(u64, @intCast(mult[0])) * @as(u64, @intCast(mult[1]));
            // std.debug.print("total: {}\n", .{total});
        }
        return total;
    }
};

test "Day3.findToken" {
    try std.testing.expectEqual(5, Day3.findToken(u8, "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))", Day3.instruction_start));
    try std.testing.expectEqual(24, Day3.findToken(u8, "%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))", Day3.instruction_start));
}

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

pub fn main() !void {
    var args = std.process.args();

    var i: usize = 0;
    var input_path: []const u8 = undefined;
    while (args.next()) |arg| : (i += 1) {
        // skip program name
        if (i == 0) continue;

        input_path = arg;
        break;
    }

    const cwd = std.fs.cwd();

    const input_file = try cwd.openFile(input_path, .{});
    defer input_file.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var day3 = Day3.init(arena.allocator());
    defer day3.deinit();

    var buffer: [10000]u8 = undefined;

    i = 0;
    while (true) : (i += 1) {
        const line = input_file.reader().readUntilDelimiter(&buffer, '\n') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        try day3.parseLine(line);
    }

    const res = day3.result();

    std.debug.print("res: {}\n", .{res});
}
