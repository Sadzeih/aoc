const std = @import("std");
const Day4 = @import("day4.zig").Day4;

fn readFile(allocator: std.mem.Allocator, filename: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(
        filename,
        std.fs.File.OpenFlags{},
    );
    defer file.close();

    const stat = try file.stat();
    return try file.readToEndAlloc(allocator, stat.size);
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

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const file_buf = try readFile(arena.allocator(), input_path);
    var lines = std.mem.splitAny(u8, file_buf, "\n");

    var day4 = Day4.init(arena.allocator());
    defer day4.deinit();

    while (lines.next()) |line| {
        try day4.parseLine(line);
    }

    const res = try day4.result();

    std.debug.print("res: {}\n", .{res});
}
