const std = @import("std");
const ratelimit = @import("ratelimit.zig");

const RequestError = error{ NoResponseData, MismatchedContentLength, MissingAuthorization };

pub var authorization: ?[]const u8 = null;

pub fn request(comptime method: std.http.Method, url: std.Uri, body: []const u8, allocator: std.mem.Allocator) ![]u8 {
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

    var data: []u8 = try req.reader().readAllAlloc(allocator, 65536);
    // std.debug.print("Response: {s}\n", .{data});

    if (req.response.status == .too_many_requests) std.debug.print("\n - !!!! HIT RATELIMIT! !!!! - \n\n", .{});

    try ratelimit.handleRatelimitBucket(req, allocator);
    ratelimit.waitForRatelimitIfNecessary();

    return data;
}
