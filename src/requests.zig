const std = @import("std");

const RequestError = error{ NoResponseData, MismatchedContentLength, MissingAuthorization };

pub var authorization: ?[]const u8 = null;

fn request(comptime method: std.http.Method, url: std.Uri, body: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    var req = try client.request(method, url, .{ .allocator = allocator }, .{});
    defer req.deinit();

    if (body.len > 0) {
        var contentLengthHeaderValue = try std.fmt.allocPrint(allocator, "{d}", .{body.len});
        defer allocator.free(contentLengthHeaderValue);
        try req.headers.append("Content-Length", contentLengthHeaderValue);
    }

    if (authorization == null) {
        return RequestError.MissingAuthorization;
    }

    try req.headers.append("Authorization", authorization.?);

    // Comply with discord user-agent regulation: https://discord.com/developers/docs/reference#user-agent-user-agent-example
    try req.headers.append("User-Agent", "DiscordBot (https://github.com/LittleBigRefresh/MarkdownToDiscord, 0.0.0)");
    try req.headers.append("Accept", "application/json");

    // Fire off the request, write the body
    try req.start();
    try req.writeAll(body);
    try req.wait();

    // std.debug.print("Response status: {d}, content length is {?d} bytes\n", .{ req.response.status, req.response.content_length });

    var data: []u8 = try req.reader().readAllAlloc(allocator, 16384);
    // std.debug.print("Response: {s}\n", .{data});

    return data;
}

pub fn get(url: std.Uri, allocator: std.mem.Allocator) ![]const u8 {
    return try request(.GET, url, &[0]u8{}, allocator);
}

pub fn post(url: std.Uri, body: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    return try request(.POST, url, body, allocator);
}
