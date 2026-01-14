const std = @import("std");
const root = @import("root.zig");

const ascii = root.ascii;
const ppm   = root.ppm;

pub const Error = error{
    FileOpenFailed,
    InvalidHeader,
    InvalidDimensions,
    InvalidMaxValue,
    ReadFailed,
};

pub const PpmImage = struct {
    width: usize,
    height: usize,
    pixels: []u8,
};

pub fn load(
    path: []const u8,
    allocator: std.mem.Allocator,
) !PpmImage {
    var file = std.fs.openFileAbsolute(path, .{}) catch return Error.FileOpenFailed;
    defer file.close();
    return readPpm(file, allocator);
}

fn readPpm(
    file: std.fs.File,
    allocator: std.mem.Allocator,
) !PpmImage {
    var buffer: [128]u8 = undefined;
    var reader = file.reader(&buffer);

    const magic = (try reader.interface.takeDelimiter('\n'))
        orelse return Error.InvalidHeader;
    if (!std.mem.eql(u8, magic, "P6")) return Error.InvalidHeader;

    const size_line = (try reader.interface.takeDelimiter('\n'))
        orelse return Error.InvalidDimensions;
    var split = std.mem.splitScalar(u8, size_line, ' ');
    const width = parseSize(split.next()) catch return Error.InvalidDimensions;
    const height = parseSize(split.next()) catch return Error.InvalidDimensions;

    const maxval = (try reader.interface.takeDelimiter('\n'))
        orelse return Error.InvalidMaxValue;
    if (!std.mem.eql(u8, maxval, "255")) return Error.InvalidMaxValue;

    const pixels = try allocator.alloc(u8, width * height * 3);
    try reader.interface.readSliceAll(pixels);

    return PpmImage{ .width = width, .height = height, .pixels = pixels };
}

fn parseSize(value: ?[]const u8) !usize {
    return std.fmt.parseInt(usize, value orelse return error.Invalid, 10);
}

pub fn saveAsPpm(
    image: ascii.AsciiImage,
    allocator: std.mem.Allocator,
    base_name: []const u8,
    mode: []const u8,
) !void {
    const block_w: usize = 8;
    const block_h: usize = 16;

    const ppm_w = image.width * block_w;
    const ppm_h = image.height * block_h;

    const file_name = try generateUniqueName(base_name, allocator);
    defer allocator.free(file_name);

    var file = try std.fs.cwd().createFile(file_name, .{ .truncate = true });
    defer file.close();
    var buffer: [8192]u8 = undefined;
    var writer = file.writer(&buffer);
    const out = &writer.interface;

    try out.print("P6\n{} {}\n255\n", .{ ppm_w, ppm_h });

    var row_buffer = try allocator.alloc(u8, ppm_w * 3);
    defer allocator.free(row_buffer);

    for (0..image.height) |y| {
        for (0..block_h) |bh| {
            @memset(row_buffer, 0);
            for (0..image.width) |x| {
                const idx = y * image.width + x;
                const c = image.chars[idx];
                const glyph = ascii.font8x8_basic[@min(c, ascii.font8x8_basic.len - 1)];

                for (0..block_w) |bw| {
                    const pos = (x * block_w + bw) * 3;

                    if (std.mem.eql(u8, mode, "full_color")) {
                        row_buffer[pos + 0] = image.colors[idx*3 + 0];
                        row_buffer[pos + 1] = image.colors[idx*3 + 1];
                        row_buffer[pos + 2] = image.colors[idx*3 + 2];
                        continue;
                    }

                    const pixel_on = (glyph[bh] & (@as(u8, 1) << @intCast(7 - bw))) != 0;
                    if (!pixel_on) continue;

                    if (std.mem.eql(u8, mode, "normal")) {
                        const lum = ascii.luminance(
                            image.colors[idx*3+0],
                            image.colors[idx*3+1],
                            image.colors[idx*3+2]
                        );
                        row_buffer[pos + 0] = lum;
                        row_buffer[pos + 1] = lum;
                        row_buffer[pos + 2] = lum;
                    }
                    
                    else if (std.mem.eql(u8, mode, "color")) {
                        row_buffer[pos + 0] = image.colors[idx*3+0];
                        row_buffer[pos + 1] = image.colors[idx*3+1];
                        row_buffer[pos + 2] = image.colors[idx*3+2];
                    }
                }
            }
            try out.writeAll(row_buffer);
        }
    }
}

fn generateUniqueName(
    base: []const u8,
    allocator: std.mem.Allocator
) ![]const u8 {
    var fs = std.fs.cwd();
    var attempt: usize = 0;
    
    while (true) {
        const suffix = if (attempt == 0)
            try allocator.dupe(u8, "")
        else
            try std.fmt.allocPrint(allocator, "-{d}", .{attempt});
        defer allocator.free(suffix);

        const name = try std.fmt.allocPrint(allocator, "{s}{s}.ppm", .{ base, suffix });

        const exists = if (fs.access(name, .{})) |_| true else |err| switch (err) {
            error.FileNotFound => false,
            else => return err,
        };

        if (!exists) return name;

        allocator.free(name);
        attempt += 1;
    }
}
