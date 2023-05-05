const std = @import("std");
const requests = @import("requests.zig");

// const gatewayUrl = std.Uri.parse("https://discord.com/api/gateway") catch unreachable;
// const gatewayUrl = std.Uri.parse("http://localhost:10060") catch unreachable;
const gatewayUrl = std.Uri.parse("https://discord.com/api/v10/channels/1049225653398016080") catch unreachable;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    requests.token = std.os.getenv("DISCORD_TOKEN");

    var data = try requests.get(gatewayUrl, allocator);
    defer allocator.free(data);
}
