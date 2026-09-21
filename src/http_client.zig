const std = @import("std");
const Allocator = std.mem.Allocator;

pub const HttpClient = struct {
    allocator: Allocator,
    host: []const u8,
    port: u16,
    scheme: []const u8,

    pub fn init(allocator: Allocator, host: []const u8, port: u16, scheme: []const u8) HttpClient {
        return .{
            .allocator = allocator,
            .host = host,
            .port = port,
            .scheme = scheme,
        };
    }

    pub fn deinit(self: *HttpClient) void {
        self.allocator.free(self.host);
        self.allocator.free(self.scheme);
    }

    pub fn get(self: *HttpClient, path: []const u8) !std.http.Response {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const url = try std.fmt.allocPrint(allocator, "{s}://{s}:{d}{s}", .{ self.scheme, self.host, self.port, path });

        var request = try std.http.Client.request(.GET, url, .{}, null);
        defer request.deinit();
        const response = try request.readToEnd();
        defer self.allocator.free(response);

        return .{
            .status = request.response.status,
            .body = response,
        };
    }
};