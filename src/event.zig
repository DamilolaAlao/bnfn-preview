const std = @import("std");
const Allocator = std.mem.Allocator;

pub const EventEmitter = struct {
    allocator: Allocator,
    listeners: std.StringHashMap(std.ArrayList(*anyopaque)),

    pub fn init(allocator: Allocator) EventEmitter {
        return .{
            .allocator = allocator,
            .listeners = std.StringHashMap(std.ArrayList(*anyopaque)).init(allocator),
        };
    }

    pub fn deinit(self: *EventEmitter) void {
        var iter = self.listeners.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.listeners.deinit();
    }

    pub fn on(self: *EventEmitter, event: []const u8, callback: anytype) void {
        if (!self.listeners.contains(event)) {
            if (self.listeners.put(event, &.{}) == null) {
                return;
            }
        }
        var list = self.listeners.getPtr(event).?;
        list.append(@ptrCast(*anyopaque, &callback)) catch return;
    }

    pub fn emit(self: *EventEmitter, event: []const u8) void {
        if (self.listeners.get(event)) |listeners| {
            for (listeners.items) |callback_ptr| {
                const callback = @ptrCast(*const anyopaque, callback_ptr);
            }
        }
    }
};