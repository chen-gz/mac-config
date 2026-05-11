const std = @import("std");
const args = @import("args");
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

fn run(io: Io, cmd_args: []const []const u8, cwd: ?[]const u8, environ_map: *process.Environ.Map) !void {
    try environ_map.put("NIX_CONFIG", "experimental-features = nix-command flakes");
    try environ_map.put("NIXPKGS_ALLOW_UNFREE", "1");

    var child = try process.spawn(io, .{
        .argv = cmd_args,
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

const GlobalOptions = struct {
    help: bool = false,

    pub const shorthands = .{
        .h = "help",
    };
};

const Verb = union(enum) {
    update: struct {},
    check: struct {},
    format: struct {},
    clean: struct {},
    deploy: struct {},
    help: struct {},
    // Allow bootstrap directly via config names as subcommands
    @"gg-mac": struct {},
    @"connie-mac": struct {},
};

fn printHelp() void {
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
        \\Configs (as subcommands):
        \\  gg-mac          Full bootstrap for guangzong-mac
        \\  connie-mac      Full bootstrap for connie-mac
        \\
    , .{});
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const environ_map = init.environ_map;
    const io = init.io;

    // Increase file descriptor limit
    if (posix.setrlimit(.NOFILE, .{ .cur = 4096, .max = 4096 })) |_| {} else |_| {}

    const result = args.parseWithVerbForCurrentProcess(GlobalOptions, Verb, init, .print) catch return;
    defer result.deinit();

    if (result.options.help) {
        printHelp();
        return;
    }

    const target_dir = try getTargetDir(arena, environ_map);

    const verb = result.verb orelse {
        printHelp();
        return;
    };

    switch (verb) {
        .update => try run(io, &.{ "nix", "flake", "update" }, target_dir, environ_map),
        .check => try run(io, &.{ "nix", "flake", "check" }, target_dir, environ_map),
        .format => try run(io, &.{ "nix", "fmt" }, target_dir, environ_map),
        .clean => try run(io, &.{ "nix-collect-garbage", "-d" }, null, environ_map),
        .help => printHelp(),
        .deploy => {
            if (result.positionals.len < 1) {
                err("Config name required for deploy");
                return;
            }
            try deploy(io, arena, target_dir, result.positionals[0], result.positionals[1..], environ_map);
        },
        .@"gg-mac" => {
            try installNix(io, environ_map);
            try ensureConfig(io, target_dir, environ_map);
            try deploy(io, arena, target_dir, "gg-mac", result.positionals, environ_map);
            success("Setup complete! Please restart your shell.");
        },
        .@"connie-mac" => {
            try installNix(io, environ_map);
            try ensureConfig(io, target_dir, environ_map);
            try deploy(io, arena, target_dir, "connie-mac", result.positionals, environ_map);
            success("Setup complete! Please restart your shell.");
        },
    }
}
