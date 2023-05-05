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

const DiscordMessage = struct {
    id: u64,
    author: DiscordUser,
    content: []const u8,
};

const DiscordUser = struct {
    id: u64,
    username: []const u8,
    discriminator: u14,
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

fn fireRequest(comptime method: std.http.Method, comptime endpointFmt: []const u8, args: anytype, body: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (endpointFmt[0] != '/') {
        @compileError("Endpoint URL must start with a slash.");
    }

    var endpointUrlString = try std.fmt.allocPrint(allocator, endpointFmt, args);
    defer allocator.free(endpointUrlString);

    var urlString = try std.fmt.allocPrint(allocator, "{s}{s}", .{ apiBaseUrl, endpointUrlString });
    defer allocator.free(urlString);

    var data = try requests.request(method, try std.Uri.parse(urlString), body, allocator);
    return data; // caller is responsible
}

fn getObject(comptime T: type, comptime endpointFmt: []const u8, args: anytype, allocator: std.mem.Allocator) !T {
    var data = try fireRequest(.GET, endpointFmt, args, &[0]u8{}, allocator);
    defer allocator.free(data); // yes, we free this here - it's not needed after we parse json

    const options: std.json.ParseOptions = .{ .ignore_unknown_fields = true, .allocator = allocator };

    var jsonStream = std.json.TokenStream.init(data);
    const object = try std.json.parse(T, &jsonStream, options);

    return object;
}

pub fn getChannel(id: u64, allocator: std.mem.Allocator) !DiscordChannel {
    return getObject(DiscordChannel, "/channels/{d}", .{id}, allocator);
}

pub fn getMessagesInChannel(id: u64, allocator: std.mem.Allocator) ![]DiscordMessage {
    return getObject([]DiscordMessage, "/channels/{d}/messages?limit=100", .{id}, allocator);
}

pub fn deleteMessage(channelId: u64, messageId: u64, allocator: std.mem.Allocator) !void {
    _ = try fireRequest(.DELETE, "/channels/{d}/messages/{d}", .{ channelId, messageId }, &[0]u8{}, allocator);
}
