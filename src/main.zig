const std = @import("std");
const root = @import("root.zig");

pub fn main() !void {
    std.debug.print("Hello, {s} !", .{"TOOL"});
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    
    const image = try root.ppm.load("C:\\Users\\Aryan\\Documents\\ppm-to-ascii\\image.ppm", allocator);
    image.deinit(allocator);
}