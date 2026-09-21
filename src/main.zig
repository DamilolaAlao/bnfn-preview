const std = @import("std");
const Allocator = std.mem.Allocator;
const EventEmitter = @import("event.zig").EventEmitter;
const HttpClient = @import("http_client.zig").HttpClient;
const Tunnel = @import("tunnel.zig").Tunnel;
const TunnelCluster = @import("tunnel_cluster.zig").TunnelCluster;

const Host = env.get("LT_HOST") orelse "https://localtunnel.me";
const Subdomain = env.get("LT_SUBDOMAIN");
const Port = std.meta.toInt(u16, env.get("LT_PORT") orelse "3000");
const LocalHost = env.get("LT_LOCAL_HOST");
const LocalPort = std.meta.toInt(u16, env.get("LT_LOCAL_PORT") orelse "3000");
const LocalHttps = std.meta.toBool(env.get("LT_LOCAL_HTTPS") orelse "false");
const MaxConn = std.meta.toInt(u32, env.get("LT_MAX_CONN") orelse "1");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Parse command line arguments
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    var port: u16 = LocalPort;
    var subdomain: ?[]const u8 = null;
    var local_host: ?[]const u8 = null;

    if (args.len > 1) {
        if (std.mem.eql(u8, args[1], "--port") and args.len > 2) {
            port = std.fmt.parseInt(u16, args[2], 10) catch |err| {
                std.debug.print("Invalid port: {s}\n", .{err});
                return err;
            };
        } else if (std.mem.eql(u8, args[1], "--subdomain") and args.len > 2) {
            subdomain = try alloc.dupe(u8, args[2]);
        } else if (std.mem.eql(u8, args[1], "--local-host") and args.len > 2) {
            local_host = try alloc.dupe(u8, args[2]);
        } else if (std.mem.eql(u8, args[1], "--help")) {
            printHelp();
            return;
        }
    }

    const opts = Tunnel.Options{
        .host = try alloc.dupe(u8, Host),
        .port = if (std.mem.endsWith(u8, Host, ".me")) 443 else 80,
        .scheme = if (std.mem.endsWith(u8, Host, ".me")) "https" else "http",
        .subdomain = subdomain,
        .local_host = local_host,
        .local_port = LocalPort,
        .local_https = LocalHttps,
        .local_cert = null,
        .local_key = null,
        .local_ca = null,
        .allow_invalid_cert = false,
        .max_conn = MaxConn,
    };

    var tunnel = try Tunnel.init(alloc, opts);
    defer {
        tunnel.deinit();
        alloc.destroy(tunnel);
    }

    // Set up event handlers
    var close_called = false;
    tunnel.emitter.on("close", &close_called);

    try tunnel.open();
    std.debug.print("Tunnel created: {s}\n", .{tunnel.url.?});
    std.debug.print("Press Ctrl+C to close\n", .{});

    // Wait forever or until closed
    while (!close_called) {
        std.time.sleep(std.time.ns_per.s * 1);
    }
}

fn printHelp() void {
    std.debug.print("Usage: localtunnel [options]\n", .{});
    std.debug.print("\nOptions:\n", .{});
    std.debug.print("  --port <port>        Local port to expose (default: 3000)\n", .{});
    std.debug.print("  --subdomain <name>   Request a specific subdomain\n", .{});
    std.debug.print("  --local-host <host>  Proxy to a hostname other than localhost\n", .{});
    std.debug.print("  --help                Show this help message\n", .{});
}