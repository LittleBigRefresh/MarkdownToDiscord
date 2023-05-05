const std = @import("std");
const requests = @import("requests.zig");

// const gatewayUrl = std.Uri.parse("https://discord.com/api/gateway") catch unreachable;
const gatewayUrl = std.Uri.parse("http://localhost:10060") catch unreachable;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var data = try requests.post(gatewayUrl, "a", allocator);
    defer allocator.free(data);
}
