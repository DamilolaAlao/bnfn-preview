const std = @import("std");
const Allocator = std.mem.Allocator;

pub const HeaderHostTransformer = struct {
    allocator: Allocator,
    host: []const u8,
    replaced: bool = false,

    pub fn init(allocator: Allocator, host: []const u8) HeaderHostTransformer {
        return .{
            .allocator = allocator,
            .host = host,
        };
    }

    pub fn deinit(self: HeaderHostTransformer) void {
        self.allocator.free(self.host);
    }

    pub fn transform(self: *HeaderHostTransformer, data: []const u8) []const u8 {
        if (self.replaced) {
            return data;
        }

        const pattern = "\r\nHost: ";
        if (std.mem.indexOf(u8, data, pattern)) |pos| {
            self.replaced = true;
            const host_line_start = pos + pattern.len;
            const host_line_end = std.mem.indexOfAny(u8, data[host_line_start..], "\r\n") orelse data.len;
            const new_data = self.allocator.alloc(u8, data.len) catch @panic("Out of memory");
            @memcpy(new_data, data);
            @memcpy(new_data[host_line_start..host_line_start + self.host.len], self.host);
            self.allocator.free(data);
            return new_data;
        }

        return data;
    }
};