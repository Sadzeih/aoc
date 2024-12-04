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
