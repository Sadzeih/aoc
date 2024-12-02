const std = @import("std");

const Day1 = struct {
    leftList: []u32,
    rightList: []u32,
};

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

    // day1: a line is perfectly 14 bytes
    var buffer: [14:0]u8 = undefined;

    i = 0;
    while (true) : (i += 1) {
        const bytes_read = try input_file.read(&buffer);
        if (bytes_read < buffer.len) break;

        var location_ids = std.mem.tokenizeAny(u8, &buffer, " \n");

        var first = true;
        var left: u32 = undefined;
        var right: u32 = undefined;
        while (location_ids.next()) |id| {
            if (first) {
                left = try std.fmt.parseInt(u32, id, 10);
                first = false;
                continue;
            }
            right = try std.fmt.parseInt(u32, id, 10);
            break;
        }

        std.debug.print("left: {}, right: {}\n", .{ left, right });
    }
}
