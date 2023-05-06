const std = @import("std");

const rateLimit = struct {
    limit: u8,
    remaining: u8,
    reset: u64,
};

// delay initialization of hashmap to get an allocator
var rateLimitBuckets: ?std.StringHashMap(rateLimit) = null;

pub fn handleRatelimitBucket(req: std.http.Client.Request, allocator: std.mem.Allocator) !void {
    var bucketField = req.response.headers.getFirstEntry("X-RateLimit-Bucket");
    if (bucketField == null) return;

    if (rateLimitBuckets == null) {
        rateLimitBuckets = std.StringHashMap(rateLimit).init(allocator);
    }

    // Copy the bucket ID as this it gets freed after the request completes.
    var bucketStr = try allocator.alloc(u8, bucketField.?.value.len);
    std.mem.copy(u8, bucketStr, bucketField.?.value);

    var bucket: ?rateLimit = rateLimitBuckets.?.get(bucketStr);

    if (bucket == null) {
        bucket = .{
            .limit = 0,
            .remaining = 0,
            .reset = 0,
        };
    } else {
        const removed: bool = rateLimitBuckets.?.remove(bucketStr);
        if (!removed) @panic("Could not remove bucket to replace it");
    }

    var limitStr = req.response.headers.getFirstEntry("X-RateLimit-Limit").?.value;
    var remainingStr = req.response.headers.getFirstEntry("X-RateLimit-Remaining").?.value;
    var resetStr = req.response.headers.getFirstEntry("X-RateLimit-Reset").?.value;

    bucket.?.limit = try std.fmt.parseInt(u8, limitStr, 10);
    bucket.?.remaining = try std.fmt.parseInt(u8, remainingStr, 10);
    bucket.?.reset = @floatToInt(u64, try std.fmt.parseFloat(f64, resetStr) * 1000); // Multiply by 1000 here because discord sends millisecond value as the decimal

    std.debug.print("Bucket {s}: {{limit: {d}, remaining: {d}, reset: {d}}}\n", .{ bucketStr, bucket.?.limit, bucket.?.remaining, bucket.?.reset });

    rateLimitBuckets.?.put(bucketStr, bucket.?) catch unreachable;
}

pub fn waitForRatelimitIfNecessary() void {
    if (rateLimitBuckets == null) return; // If the hashmap hasn't been initialized, a ratelimit can't have been set for us.

    var iterator = rateLimitBuckets.?.keyIterator();

    var bucketKey: ?*[]const u8 = iterator.next();
    const currentTime: i64 = std.time.milliTimestamp();

    while (bucketKey != null) {
        var bucket: ?rateLimit = rateLimitBuckets.?.get(bucketKey.?.*);
        if (bucket == null) unreachable;

        if (bucket.?.remaining <= 1) {
            const msToSleep: i64 = @max(@intCast(i64, bucket.?.reset) - currentTime + 100, 1000);
            if (msToSleep < 0) @panic("Tried using negative value to sleep");

            std.debug.print("Sleeping for {d}ms because bucket {s} has {d} remaining\n", .{ msToSleep, bucketKey.?.*, bucket.?.remaining });

            std.time.sleep(@intCast(u64, msToSleep * std.time.ns_per_ms));

            // Remove the bucket so we don't hold on to an empty one
            const removed: bool = rateLimitBuckets.?.remove(bucketKey.?.*);
            if (!removed) @panic("Could not remove empty bucket");
        }

        bucketKey = iterator.next();
    }
}
