const std = @import("std");
const discord = @import("discord.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    try discord.setToken(std.os.getenv("DISCORD_TOKEN"), allocator);

    var channel = try discord.getChannel(1102426423240691712, allocator);
    std.debug.print("id: {d}, type: {d}, name: '#{s}'\n", .{ channel.id, channel.type, channel.name });
}
