const std = @import("std");
const discord = @import("discord.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    try discord.setToken(std.os.getenv("DISCORD_TOKEN"), allocator);

    var channel = try discord.getChannel(1078539918642516018, allocator);
    std.debug.print("channel id: {d}, type: {d}, name: '#{s}'\n", .{ channel.id, channel.type, channel.name });

    var messages = try discord.getMessagesInChannel(channel.id, allocator);
    for (messages) |message| {
        std.debug.print("message id: {d}, author: {s}#{d} ({d}), content: '{s}'\n", .{ message.id, message.author.username, message.author.discriminator, message.author.id, message.content });
        try discord.deleteMessage(channel.id, message.id, allocator);
    }
}
