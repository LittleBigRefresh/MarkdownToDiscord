const requests = @import("requests.zig");
const std = @import("std");

const DiscordError = error{
    MissingBotToken,
};

const DiscordChannel = struct {
    id: u64,
    type: u8,
    name: []const u8,
};

const apiBaseUrl: []const u8 = "https://discord.com/api/v10";

pub fn setToken(token: ?[]const u8, allocator: std.mem.Allocator) !void {
    if (token == null) {
        return DiscordError.MissingBotToken;
    }

    // do not free here! requests is responsible for this memory
    // should probably rework to use structs
    var authorizationValue = try std.fmt.allocPrint(allocator, "Bot {?s}", .{token});

    requests.authorization = authorizationValue;
}

pub fn getChannel(id: u64, allocator: std.mem.Allocator) !DiscordChannel {
    var urlString = try std.fmt.allocPrint(allocator, "{s}/channels/{d}", .{ apiBaseUrl, id });
    defer allocator.free(urlString);

    var channelData = try requests.get(try std.Uri.parse(urlString), allocator);
    defer allocator.free(channelData); // yes, we free this here - it's not needed after we parse json

    const options: std.json.ParseOptions = .{ .ignore_unknown_fields = true, .allocator = allocator };

    var channelStream = std.json.TokenStream.init(channelData);
    const channel = try std.json.parse(DiscordChannel, &channelStream, options);

    return channel;
}
