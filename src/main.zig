const std = @import("std");
const root = @import("root.zig");

const ascii = root.ascii;
const ppm   = root.ppm;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak)
            std.debug.print("Warning: memory leak detected\n", .{});
    }
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2 or std.mem.eql(u8, args[1], "--help")) {
        printHelp(args[0]);
        return;
    }

    const options = parseArgs(args) catch |err| {
        printArgError(err);
        return;
    };

    const image_path = resolvePath(options.path, allocator) catch |err| {
        std.debug.print("Path error: {any}\n", .{err});
        return;
    };
    defer if (!std.fs.path.isAbsolute(options.path))
        allocator.free(image_path);

    const image = ppm.load(image_path, allocator) catch |err| {
        std.debug.print("PPM error: {any}\n", .{err});
        return;
    };
    defer allocator.free(image.pixels);

    const ascii_image = ascii.convert(image, allocator, options.scale) catch |err| {
        std.debug.print("ASCII error: {any}\n", .{err});
        return;
    };
    defer allocator.free(ascii_image.chars);
    defer allocator.free(ascii_image.colors);

    ascii.print(ascii_image, options.print_type) catch |err| {
        std.debug.print("Print error: {any}\n", .{err});
        return;
    };

    if (options.save) {
        ppm.saveAsPpm(ascii_image, allocator, "output", options.print_type) catch |err| {
            std.debug.print("Save error: {any}\n", .{err});
            return;
        };
    }
}

const Options = struct {
    path: []const u8,
    print_type: []const u8,
    scale: f32,
    save: bool,
};

const ArgError = error{ InvalidScale, InvalidPrintType };

fn parseArgs(args: []const [:0]u8) !Options {
    var print_type: []const u8 = "normal";
    var scale: f32 = 1.0;
    var save = false;

    var i: usize = 2;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--save")) { save = true; continue; }
        if (isPrintType(arg)) { print_type = arg; continue; }

        scale = std.fmt.parseFloat(f32, arg) catch return ArgError.InvalidScale;
        if (scale <= 0.0) return ArgError.InvalidScale;
    }

    return Options{
        .path = args[1],
        .print_type = print_type,
        .scale = scale,
        .save = save
    };
}

fn isPrintType(value: []const u8) bool {
    return std.mem.eql(u8, value, "normal") or
           std.mem.eql(u8, value, "color") or
           std.mem.eql(u8, value, "full_color");
}

fn resolvePath(input: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (std.fs.path.isAbsolute(input)) return input;

    const cwd = std.fs.cwd();
    const cwd_path = try cwd.realpathAlloc(allocator, ".");
    defer allocator.free(cwd_path);

    return std.fs.path.join(allocator, &.{ cwd_path, input });
}

fn printHelp(program_name: []const u8) void {
    std.debug.print(
        "Usage: {s} <image.ppm> [print_type] [scale] [--save]\n" ++
        "print_type: normal | color | full_color\n" ++
        "scale: positive float (default 1.0)\n" ++
        "--save: also write output.ppm\n",
        .{program_name},
    );
}

fn printArgError(err: anyerror) void {
    switch (err) {
        ArgError.InvalidScale =>
            std.debug.print("Error: scale must be positive\n", .{}),
        ArgError.InvalidPrintType =>
            std.debug.print("Error: invalid print type\n", .{}),
        else =>
            std.debug.print("Error: invalid arguments\n", .{}),
    }
}
