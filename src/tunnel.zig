const std = @import("std");
const Allocator = std.mem.Allocator;
const EventEmitter = @import("event.zig").EventEmitter;
const HttpClient = @import("http_client.zig").HttpClient;

pub const Tunnel = struct {
    allocator: Allocator,
    emitter: *EventEmitter,
    opts: Options,
    tunnel_cluster: *TunnelCluster,
    closed: bool = false,
    clientId: ?[]const u8 = null,
    url: ?[]const u8 = null,
    cachedUrl: ?[]const u8 = null,

    const Options = struct {
        host: []const u8,
        port: u16,
        scheme: []const u8,
        subdomain: ?[]const u8 = null,
        local_host: ?[]const u8 = null,
        local_port: u16,
        local_https: bool = false,
        local_cert: ?[]const u8 = null,
        local_key: ?[]const u8 = null,
        local_ca: ?[]const u8 = null,
        allow_invalid_cert: bool = false,
        max_conn: u32 = 1,
    };

    pub fn init(allocator: Allocator, opts: Options) !*Tunnel {
        const self = try allocator.create(Tunnel);
        self.* = .{
            .allocator = allocator,
            .emitter = try allocator.create(EventEmitter),
            .opts = opts,
            .tunnel_cluster = undefined,
            .closed = false,
        };
        self.emitter.* = EventEmitter.init(allocator);

        return self;
    }

    pub fn deinit(self: *Tunnel) void {
        self.emitter.deinit();
        self.allocator.destroy(self.emitter);
        self.allocator.free(self.opts.host);
        self.allocator.free(self.opts.scheme);
        if (self.clientId) |id| self.allocator.free(id);
        if (self.url) |u| self.allocator.free(u);
        if (self.cachedUrl) |cu| self.allocator.free(cu);
    }

    pub fn open(self: *Tunnel) !void {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const client = try allocator.create(HttpClient);
        client.* = HttpClient.init(
            self.allocator,
            self.opts.host,
            self.opts.port,
            self.opts.scheme,
        );

        defer client.deinit();

        const uri = try std.fmt.allocPrint(allocator, "/{s}", .{if (self.opts.subdomain) |sub| sub else "?new"});
        defer allocator.free(uri);

        var response = try client.get(uri);
        defer response.body.free(allocator);

        if (response.status != .OK) {
            return error.ServerError;
        }

        const tunnel_info = try parseTunnelInfo(allocator, response.body);
        defer tunnel_info.deinit();

        self.clientId = try allocator.dupe(u8, tunnel_info.id);
        self.url = try allocator.dupe(u8, tunnel_info.url);
        if (tunnel_info.cached_url) |cu| {
            self.cachedUrl = try allocator.dupe(u8, cu);
        }

        // Create tunnel cluster
        self.tunnel_cluster = try allocator.create(TunnelCluster);
        self.tunnel_cluster.* = try TunnelCluster.init(self.allocator, tunnel_info);
        // defer self.allocator.destroy(self.tunnel_cluster);

        try self.tunnel_cluster.open();
    }

    pub fn close(self: *Tunnel) void {
        self.closed = true;
        if (self.tunnel_cluster) |cluster| {
            cluster.close();
        }
        self.emitter.emit("close");
    }

    fn parseTunnelInfo(allocator: Allocator, body: []const u8) !*TunnelInfo {
        const info = try allocator.create(TunnelInfo);
        info.* = .{
            .allocator = allocator,
            .id = undefined,
            .ip = undefined,
            .port = undefined,
            .url = undefined,
            .cached_url = null,
            .max_conn_count = 1,
            .remote_host = undefined,
            .remote_ip = undefined,
            .remote_port = undefined,
            .local_port = undefined,
            .local_host = undefined,
            .local_https = undefined,
            .local_cert = null,
            .local_key = null,
            .local_ca = null,
            .allow_invalid_cert = undefined,
        };

        // Simple JSON parsing - this is a simplified version
        // In production, you'd use a proper JSON parser
        var parser = std.json.Parser.init(allocator);
        const tree = try parser.parse(body);
        defer tree.deinit();

        if (tree.value) |val| {
            if (val.object.get("id")) |id_val| {
                info.id = try allocator.dupe(u8, id_val.string);
            }
            if (val.object.get("ip")) |ip_val| {
                info.ip = try allocator.dupe(u8, ip_val.string);
            }
            if (val.object.get("port")) |port_val| {
                info.port = port_val.integer;
            }
            if (val.object.get("url")) |url_val| {
                info.url = try allocator.dupe(u8, url_val.string);
            }
            if (val.object.get("cached_url")) |cu_val| {
                info.cached_url = try allocator.dupe(u8, cu_val.string);
            }
            if (val.object.get("max_conn_count")) |max_val| {
                info.max_conn_count = max_val.integer;
            }
            if (val.object.get("remote_host")) |rh_val| {
                info.remote_host = try allocator.dupe(u8, rh_val.string);
            }
            if (val.object.get("remote_ip")) |rip_val| {
                info.remote_ip = try allocator.dupe(u8, rip_val.string);
            }
            if (val.object.get("remote_port")) |rp_val| {
                info.remote_port = rp_val.integer;
            }
            if (val.object.get("local_port")) |lp_val| {
                info.local_port = lp_val.integer;
            }
            if (val.object.get("local_host")) |lh_val| {
                info.local_host = try allocator.dupe(u8, lh_val.string);
            }
            if (val.object.get("local_https")) |lh_val| {
                info.local_https = lh_val.bool;
            }
            if (val.object.get("allow_invalid_cert")) |aic_val| {
                info.allow_invalid_cert = aic_val.bool;
            }
        }

        return info;
    }

    const TunnelInfo = struct {
        allocator: Allocator,
        id: []const u8,
        ip: []const u8,
        port: u32,
        url: []const u8,
        cached_url: ?[]const u8,
        max_conn_count: u32,
        remote_host: []const u8,
        remote_ip: []const u8,
        remote_port: u32,
        local_port: u32,
        local_host: []const u8,
        local_https: bool,
        local_cert: ?[]const u8,
        local_key: ?[]const u8,
        local_ca: ?[]const u8,
        allow_invalid_cert: bool,

        pub fn deinit(self: *TunnelInfo) void {
            self.allocator.free(self.id);
            self.allocator.free(self.ip);
            self.allocator.free(self.url);
            if (self.cached_url) |cu| self.allocator.free(cu);
            self.allocator.free(self.remote_host);
            self.allocator.free(self.remote_ip);
            self.allocator.free(self.local_host);
        }
    };
};