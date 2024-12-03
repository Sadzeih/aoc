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

const Slope = enum {
    Increasing,
    Decreasing,
    Level,
};

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

    fn isSliceSafe(self: Report, slice: []u32) !bool {
        const asc = try self.allocator.alloc(u32, slice.len);
        defer self.allocator.free(asc);
        @memcpy(asc, slice);
        std.mem.sort(u32, asc, {}, std.sort.asc(u32));
        const desc = try self.allocator.alloc(u32, slice.len);
        defer self.allocator.free(desc);
        @memcpy(desc, slice);
        std.mem.sort(u32, desc, {}, std.sort.desc(u32));
        std.debug.print("eq to asc? {}", .{std.mem.eql(u32, slice, asc)});
        std.debug.print("eq to desc? {}", .{std.mem.eql(u32, slice, desc)});
        const inc_or_dec = std.mem.eql(u32, slice, asc) or std.mem.eql(u32, slice, desc);

        var i: usize = 0;
        while (i < slice.len) : (i += 1) {
            if (i + 1 >= slice.len) break;
            const diff: i32 = @as(i32, @intCast(slice[i])) - @as(i32, @intCast(slice[i + 1]));
            std.debug.print("diff: {d}\n", .{diff});
            if (@abs(diff) < 1 or @abs(diff) > 3) {
                return false;
            }
        }
        std.debug.print("inc_or_dec: {}\n", .{inc_or_dec});
        return inc_or_dec;
    }

    fn isSafe(self: *const Report) !bool {
        std.debug.print("{d}\n", .{self.levels.items});
        // var safe: bool = true;
        var i: usize = 0;
        while (i < self.levels.items.len) : ({
            i += 1;
        }) {
            if (i + 1 >= self.levels.items.len) {
                std.debug.print("{s}", .{"breaking cause of i\n"});
                break;
            }
            // self.isSliceSafe()
        }
        return try self.isSliceSafe(self.levels.items);
    }
};

test "Report.isSafe" {
    const reports = [7][5]u32{
        [_]u32{ 7, 6, 4, 2, 1 },
        [_]u32{ 1, 2, 7, 8, 9 },
        [_]u32{ 9, 7, 6, 2, 1 },
        [_]u32{ 1, 3, 2, 4, 5 },
        [_]u32{ 8, 6, 4, 4, 1 },
        [_]u32{ 1, 3, 6, 7, 9 },
        [_]u32{ 27, 25, 28, 29, 30 },
    };

    const expecteds = [_]bool{
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
        std.debug.print("{}\n", .{is_safe});
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
                std.debug.print("{}\n", .{true});
                safe_reports += 1;
                continue;
            }
            std.debug.print("{}\n", .{false});
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

    var day2 = Day2.init(arena.allocator());
    defer day2.deinit();

    var buffer: [100]u8 = undefined;

    i = 0;
    while (true) : (i += 1) {
        const line = input_file.reader().readUntilDelimiter(&buffer, '\n') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        try day2.parseLine(line);
    }

    const safe_report_count = try day2.countSafeReports();

    std.debug.print("safe report count: {}\n", .{safe_report_count});
}
