const std = @import("std");
const Day4 = @import("day4.zig").Day4;

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

    var day4 = Day4.init(arena.allocator());
    defer day4.deinit();

    var buffer: [10000]u8 = undefined;

    i = 0;
    while (true) : (i += 1) {
        const line = input_file.reader().readUntilDelimiter(&buffer, '\n') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        try day4.parseLine(line);
    }

    const res = try day4.result();

    std.debug.print("res: {}\n", .{res});
}
