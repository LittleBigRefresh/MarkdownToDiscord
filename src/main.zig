const std = @import("std");

const url = std.Uri.parse("https://discord.com/api/gateway") catch unreachable;

pub fn main() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};

    var client: std.http.Client = .{ .allocator = allocator.allocator() };
    defer client.deinit();

    var req = try client.request(.GET, url, .{ .allocator = allocator.allocator() }, .{});
    defer req.deinit();

    try req.start();
    try req.wait();

    std.debug.print("Response status: {d}\n", .{req.response.status});
}
