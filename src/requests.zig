const std = @import("std");

const RequestError = error{ NoResponseData, MismatchedContentLength };

fn request(comptime method: std.http.Method, comptime url: std.Uri, body: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    var req = try client.request(method, url, .{ .allocator = allocator }, .{});
    defer req.deinit();

    var contentLengthHeaderValue = try std.fmt.allocPrint(allocator, "{d}", .{body.len});

    try req.headers.append("Content-Length", contentLengthHeaderValue);
    try req.start();
    try req.writeAll(body);
    try req.wait();

    if (req.response.content_length == null) {
        req.response.content_length = 0;
    }

    std.debug.print("Response status: {d}, bytes received: {?d}\n", .{ req.response.status, req.response.content_length });

    var data: []u8 = try allocator.alloc(u8, req.response.content_length.?);
    var read = try req.readAll(data);

    if (read != req.response.content_length) {
        return error.MismatchedContentLength;
    }

    std.debug.print("Response: {s}\n", .{data});

    return data;
}

pub fn get(comptime url: std.Uri, allocator: std.mem.Allocator) ![]const u8 {
    return try request(.GET, url, .{}, allocator);
}

pub fn post(comptime url: std.Uri, body: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    return try request(.POST, url, body, allocator);
}
