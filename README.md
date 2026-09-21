# bnfn-preview

A Zig-based localtunnel implementation that creates tunnels to expose local ports to the internet.

## Overview

This project implements a localtunnel client in Zig, allowing you to expose a local port to the public internet via localtunnel.me. It supports bidirectional TCP forwarding and manages multiple tunnels simultaneously.

## Features

- Expose local ports via localtunnel.me
- Support for multiple concurrent tunnels
- Automatic reconnection and error handling
- Event-driven architecture for tunnel lifecycle management
- HTTP Host header transformation support

## Architecture

The project is structured with:

- **src/main.zig**: Entry point with CLI argument parsing
- **src/tunnel.zig**: Core tunnel logic and HTTP client
- **src/tunnel_cluster.zig**: Manages multiple tunnels
- **src/http_client.zig**: HTTP client implementation
- **src/event.zig**: Event emitter system
- **src/header_host_transformer.zig**: HTTP header manipulation

## Quick Start

### Prerequisites

- Zig compiler (version 0.16.0 or later)
- Linux or macOS

### Building

```bash
zig build
```

### Running

```bash
./zig-out/bin/localtunnel --help
```

To expose a local port:

```bash
./zig-out/bin/localtunnel --port 3000 --subdomain myapp
```

### Installation

Add this project as a dependency in your `.zig` project:

```zig
const std = @import("std");

pub fn main() !void {
    // Usage depends on your specific needs
}
```

## API

The library provides the following main components:

- `Tunnel`: Core tunnel abstraction
- `TunnelCluster`: Manages multiple tunnels
- `HttpClient`: HTTP client for API communication
- `EventEmitter`: Event system for callbacks

## Configuration

### Environment Variables

- `LT_HOST`: Localtunnel server URL (default: "https://localtunnel.me")
- `LT_SUBDOMAIN`: Requested subdomain
- `LT_PORT`: Local port to expose (default: 3000)
- `LT_LOCAL_HOST`: Proxy to a hostname other than localhost
- `LT_LOCAL_PORT`: Local port (default: 3000)
- `LT_LOCAL_HTTPS`: Enable HTTPS for local connections
- `LT_MAX_CONN`: Maximum number of concurrent connections (default: 1)

### Command Line Options

- `--port <port>`: Local port to expose
- `--subdomain <name>`: Request a specific subdomain
- `--local-host <host>`: Proxy to a hostname other than localhost
- `--help`: Show help message

## Development

### Building

```bash
zig build
```

### Testing

Currently no formal testing framework is implemented. The project focuses on functional correctness.

### Code Style

Follow Zig's standard formatting and conventions.

## License

This project is licensed under the MIT License. See `LICENSE` for details.

## Contributing

Contributions are welcome! Please see `CONTRIBUTING.md` for contribution guidelines.

## Acknowledgements

- Based on the original localtunnel concept
- Uses Zig's standard library for networking and HTTP

## Authors

- Damilola Alao

## Links

- GitHub Repository: https://github.com/DamilolaAlao/bnfn-preview
- Issues: https://github.com/DamilolaAlao/bnfn-preview/issues