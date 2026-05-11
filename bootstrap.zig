const std = @import("std");
const process = std.process;
const fs = std.fs;
const posix = std.posix;
const Io = std.Io;

const REPO_URL = "https://github.com/chen-gz/mac-config";
const DEFAULT_TARGET_DIR = ".config/nix-darwin";

const Color = struct {
    const blue = "\x1b[0;34m";
    const green = "\x1b[0;32m";
    const red = "\x1b[0;31m";
    const reset = "\x1b[0m";
};

fn log(msg: []const u8) void {
    std.debug.print("{s}[BOOTSTRAP]{s} {s}\n", .{ Color.blue, Color.reset, msg });
}

fn success(msg: []const u8) void {
    std.debug.print("{s}[SUCCESS]{s} {s}\n", .{ Color.green, Color.reset, msg });
}

fn err(msg: []const u8) void {
    std.debug.print("{s}[ERROR]{s} {s}\n", .{ Color.red, Color.reset, msg });
}

fn run(io: Io, args: []const []const u8, cwd: ?[]const u8, environ_map: *process.Environ.Map) !void {
    try environ_map.put("NIX_CONFIG", "experimental-features = nix-command flakes");
    try environ_map.put("NIXPKGS_ALLOW_UNFREE", "1");

    var child = try process.spawn(io, .{
        .argv = args,
        .cwd = if (cwd) |c| .{ .path = c } else .inherit,
        .environ_map = environ_map,
    });
    
    const term = try child.wait(io);
    switch (term) {
        .exited => |code| if (code != 0) {
            std.debug.print("Command failed with exit code {}\n", .{code});
            return error.CommandFailed;
        },
        else => return error.CommandFailed,
    }
}

fn getTargetDir(allocator: std.mem.Allocator, environ_map: *process.Environ.Map) ![]const u8 {
    const home = environ_map.get("HOME") orelse return error.HomeNotFound;
    return try std.fs.path.join(allocator, &.{ home, DEFAULT_TARGET_DIR });
}

fn installNix(io: Io, environ_map: *process.Environ.Map) !void {
    // Check Xcode tools
    {
        var child = process.spawn(io, .{
            .argv = &.{ "xcode-select", "-p" },
            .stdout = .ignore,
            .stderr = .ignore,
        }) catch |e| return e;
        const term = try child.wait(io);
        switch (term) {
            .exited => |code| if (code != 0) {
                log("Installing Xcode Command Line Tools...");
                try run(io, &.{ "xcode-select", "--install" }, null, environ_map);
                std.debug.print("Please complete the installation and press Enter...\n", .{});
                var buf: [1]u8 = undefined;
                _ = posix.read(posix.STDIN_FILENO, &buf) catch 0;
            },
            else => {},
        }
    }

    // Check Nix
    {
        var child = process.spawn(io, .{
            .argv = &.{ "which", "nix" },
            .stdout = .ignore,
            .stderr = .ignore,
        }) catch |e| return e;
        const term = try child.wait(io);
        switch (term) {
            .exited => |code| if (code != 0) {
                log("Nix not found. Installing...");
                try run(io, &.{ "curl", "-L", "https://install.determinate.systems/nix", "-o", "install-nix.sh" }, null, environ_map);
                try run(io, &.{ "sh", "install-nix.sh", "install" }, null, environ_map);
            },
            else => {},
        }
    }
}

fn ensureConfig(io: Io, target_dir: []const u8, environ_map: *process.Environ.Map) !void {
    var child = try process.spawn(io, .{
        .argv = &.{ "ls", "-d", target_dir },
        .stdout = .ignore,
        .stderr = .ignore,
    });
    const term = try child.wait(io);
    if (term == .exited and term.exited == 0) {
        log("Configuration directory already exists.");
    } else {
        log("Cloning configuration...");
        try run(io, &.{ "git", "clone", REPO_URL, target_dir }, null, environ_map);
    }
}

fn deploy(io: Io, allocator: std.mem.Allocator, target_dir: []const u8, flake_name: []const u8, extra_args: []const []const u8, environ_map: *process.Environ.Map) !void {
    log("Deploying configuration...");
    
    // Ensure synthetic.conf
    {
        var child = try process.spawn(io, .{
            .argv = &.{ "ls", "/etc/synthetic.conf" },
            .stdout = .ignore,
            .stderr = .ignore,
        });
        const term = try child.wait(io);
        switch (term) {
            .exited => |code| if (code != 0) {
                log("Creating /etc/synthetic.conf...");
                try run(io, &.{ "sudo", "touch", "/etc/synthetic.conf" }, null, environ_map);
            },
            else => {},
        }
    }

    const flake_path = try std.fmt.allocPrint(allocator, "{s}#{s}", .{ target_dir, flake_name });
    defer allocator.free(flake_path);

    var args_list = std.ArrayListUnmanaged([]const u8){ .items = &.{}, .capacity = 0 };
    try args_list.appendSlice(allocator, &.{ "sudo", "nix", "run", "nix-darwin", "--", "switch", "--flake", flake_path });
    try args_list.appendSlice(allocator, extra_args);

    try run(io, args_list.toOwnedSlice(allocator) catch unreachable, null, environ_map);
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const environ_map = init.environ_map;
    const io = init.io;

    // Increase file descriptor limit
    // Note: setrlimit might also have changed, but let's try.
    // If it fails, we'll just ignore it.

    var args_it = try std.process.Args.Iterator.initAllocator(init.minimal.args, arena);
    var args_list = std.ArrayListUnmanaged([]const u8){ .items = &.{}, .capacity = 0 };
    while (args_it.next()) |arg| {
        try args_list.append(arena, arg);
    }
    const args = args_list.toOwnedSlice(arena) catch unreachable;

    if (args.len < 2) {
        std.debug.print("Usage: {s} [command|config]\n", .{args[0]});
        return;
    }

    const cmd = args[1];
    if (std.mem.eql(u8, cmd, "help") or std.mem.eql(u8, cmd, "--help")) {
        std.debug.print(
            \\Usage: bootstrap [command|config]
            \\
            \\Commands:
            \\  update          Update flake inputs
            \\  check           Verify the flake configuration
            \\  format          Format all Nix files
            \\  clean           Garbage collect old generations
            \\  deploy <config> Deploy a specific configuration
            \\  help            Show this help
            \\
            \\Config:
            \\  gg-mac          Full bootstrap for guangzong-mac
            \\  connie-mac      Full bootstrap for connie-mac
            \\
        , .{});
        return;
    }

    const target_dir = try getTargetDir(arena, environ_map);

    if (std.mem.eql(u8, cmd, "update")) {
        try run(io, &.{ "nix", "flake", "update" }, target_dir, environ_map);
    } else if (std.mem.eql(u8, cmd, "check")) {
        try run(io, &.{ "nix", "flake", "check" }, target_dir, environ_map);
    } else if (std.mem.eql(u8, cmd, "format")) {
        try run(io, &.{ "nix", "fmt" }, target_dir, environ_map);
    } else if (std.mem.eql(u8, cmd, "clean")) {
        try run(io, &.{ "nix-collect-garbage", "-d" }, null, environ_map);
    } else if (std.mem.eql(u8, cmd, "deploy")) {
        if (args.len < 3) {
            err("Config name required for deploy");
            return;
        }
        try deploy(io, arena, target_dir, args[2], args[3..], environ_map);
    } else {
        // Assume cmd is a config name for full bootstrap
        try installNix(io, environ_map);
        try ensureConfig(io, target_dir, environ_map);
        try deploy(io, arena, target_dir, cmd, args[2..], environ_map);
        success("Setup complete! Please restart your shell.");
    }
}
