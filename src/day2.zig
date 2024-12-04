const std = @import("std");

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
