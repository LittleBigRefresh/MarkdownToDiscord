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

fn getObject(comptime T: type, comptime endpointFmt: []const u8, args: anytype, allocator: std.mem.Allocator) !T {
    if (endpointFmt[0] != '/') {
        @compileError("Endpoint URL must start with a slash.");
    }

    var endpointUrlString = try std.fmt.allocPrint(allocator, endpointFmt, args);
    defer allocator.free(endpointUrlString);

    var urlString = try std.fmt.allocPrint(allocator, "{s}{s}", .{ apiBaseUrl, endpointUrlString });
    defer allocator.free(urlString);

    // now that we've constructed the url, lets fire a request and try to parse an object from it
    var data = try requests.get(try std.Uri.parse(urlString), allocator);
    defer allocator.free(data); // yes, we free this here - it's not needed after we parse json

    const options: std.json.ParseOptions = .{ .ignore_unknown_fields = true, .allocator = allocator };

    var jsonStream = std.json.TokenStream.init(data);
    const object = try std.json.parse(T, &jsonStream, options);

    return object;
}

pub fn getChannel(id: u64, allocator: std.mem.Allocator) !DiscordChannel {
    return getObject(DiscordChannel, "/channels/{d}", .{id}, allocator);
}
