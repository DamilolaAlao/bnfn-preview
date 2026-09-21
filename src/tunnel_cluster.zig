const std = @import("std");
const Allocator = std.mem.Allocator;
const EventEmitter = @import("event.zig").EventEmitter;
const HeaderHostTransformer = @import("header_host_transformer.zig").HeaderHostTransformer;
const HttpClient = @import("http_client.zig").HttpClient;

pub const TunnelCluster = struct {
    allocator: Allocator,
    emitter: EventEmitter,
    opts: anytype,
    closed: bool = false,
    max_tunnels: u32,
    tunnel_count: u32 = 0,
    tunnels: std.ArrayList(*Tunnel),

    const Tunnel = struct {
        remote: std.net.Stream,
        local: ?std.net.Stream = null,
        stream: std.io.AnyReaderWriter,
    };

    pub fn init(allocator: Allocator, opts: anytype) !*TunnelCluster {
        const self = try allocator.create(TunnelCluster);
        self.* = .{
            .allocator = allocator,
            .emitter = EventEmitter.init(allocator),
            .opts = opts,
            .closed = false,
            .max_tunnels = opts.max_conn_count,
            .tunnels = std.ArrayList(*Tunnel).init(allocator),
        };
        return self;
    }

    pub fn deinit(self: *TunnelCluster) void {
        self.emitter.deinit();
        for (self.tunnels.items) |tunnel| {
            tunnel.remote.close();
            if (tunnel.local) |local| {
                local.close();
            }
            self.allocator.destroy(tunnel);
        }
        self.tunnels.deinit();
        if (hasDeinitFn(self.opts)) {
            self.opts.deinit();
        }
    }

    pub fn open(self: *TunnelCluster) !void {
        // Create a tunnel to the remote server
        const tunnel = try self.allocator.create(Tunnel);
        tunnel.* = .{ .remote = undefined, .local = null, .stream = undefined };

        // Connect to remote tunnel server
        tunnel.remote = try std.net.tcpConnectTo(
            self.opts.remote_ip orelse self.opts.remote_host,
            self.opts.remote_port,
        );

        tunnel.remote.setKeepAlive(true);
        tunnel.remote.setBlocking(false);

        // Listen for errors on remote connection
        tunnel.remote.listenForUnexpectedDisconnect();

        // Create local connection if local_host specified
        if (self.opts.local_host) |host| {
            tunnel.local = try std.net.tcpConnectTo(host, self.opts.local_port);
            tunnel.local.?.setBlocking(false);
        }

        // Set up data handler for remote connection
        tunnel.remote.onData(handleRemoteData);

        // Emit open event with remote stream
        self.emitter.emit("open", tunnel.remote);

        try self.tunnels.append(tunnel);
        self.tunnel_count = self.tunnels.items.len;
    }

    pub fn close(self: *TunnelCluster) void {
        self.closed = true;
        for (self.tunnels.items) |tunnel| {
            tunnel.remote.close();
            if (tunnel.local) |local| {
                local.close();
            }
        }
        self.tunnels.clear();
        self.emitter.emit("close");
    }
};

fn hasDeinitFn(obj: anytype) bool {
    return @hasMethod(@TypeOf(obj), "deinit");
}

fn handleRemoteData(stream: std.net.Stream, data: []u8) void {
    // Forward data to local connection
    // Find the corresponding tunnel
    for (self.tunnels.items) |tunnel| {
        if (tunnel.remote == stream) {
            if (tunnel.local) |local| {
                local.write(data) catch {};
            }
            break;
        }
    }
}