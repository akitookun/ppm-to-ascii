const std = @import("std");

pub const PpmImage = struct {
    width: usize,
    height: usize,
    pixels: []u8,
    
    pub fn deinit(self: PpmImage, allocator: std.mem.Allocator) void {
        allocator.free(self.pixels);
    }
};

pub fn load(path: []const u8, allocator: std.mem.Allocator) !PpmImage {
    var width: usize = undefined;
    var height: usize = undefined;
    
    var image_file = try std.fs.openFileAbsolute(path, .{});
    defer image_file.close();
    
    var buff: [128]u8 = undefined;
    var reader = image_file.reader(&buff);
    
    // magic number    
    const magic_number = try reader.interface.takeDelimiter('\n');
    if (magic_number) |number| {
        std.debug.print("\nmagic number: {s}", .{number});
    }
    
    // dimentions
    const dimensions = try reader.interface.takeDelimiter('\n');
    if (dimensions) |dimension| {
        var split_dimension = std.mem.splitScalar(u8, dimension, ' ');
        width = try std.fmt.parseInt(usize, split_dimension.next().?, 10);
        height = try std.fmt.parseInt(usize, split_dimension.next().?, 10);
        
        std.debug.print("\nwidth: {} height: {}", .{width, height});
    }
    
    // maxval
    const maxval = try reader.interface.takeDelimiter('\n');
    if (maxval) |number| {
        std.debug.print("\nmaxval: {s}", .{number});
    }

    // pixels
    const pixels = try reader.interface.readAlloc(allocator, width * height * 3);
    
    return .{
        .width = width,
        .height = height,
        .pixels = pixels,
    };
}