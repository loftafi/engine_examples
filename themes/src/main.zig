var allocator: Allocator = undefined;
var io: std.Io = undefined;
var app: App = undefined;

/// Main app function for desktop versions of the app.
pub fn main(init: std.process.Init) !void {
    engine.start(&init, &startup, &shutdown);
}

pub fn startup(init: *const std.process.Init) error{ OutOfMemory, AppInitFailed }!*engine.Display {
    var config: engine.Config = .{
        .app_name = "Numbers Game",
        .app_version = "1.0",
        .app_id = "org.example.numbers",
        .app_build = "123",
        .app_org = "My Org",
        .app_bundle_output = "resources.bd",
        .full_screen = false,
        .bundles = &.{
            .{ .folder = "resources/" },
            //.{ .filename = "resources.bd" },
        },
        .width = 600,
        .height = 1000,
        .min_width = 375,
        .min_height = 812,
        //.translation_filename = "translations",
        //.desktop_icon = if (builtin.os.tag == .macos) "desktop icon" else null,
    };

    app.init(init.gpa, init.io, &config) catch |f| {
        std.log.err("App.create() failed: {t}", .{f});
        return error.AppInitFailed;
    };
    errdefer {
        app.?.deinit();
        app = null;
        @panic("App init failed");
    }

    return app.display;
}

pub fn shutdown(_: *const std.process.Init) void {
    app.deinit();
}

pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = engine.log.log_capture,
    //.allow_stack_tracing = if (engine.platform == .ios) false else true,
};

const std = @import("std");
const Allocator = std.mem.Allocator;
const DebugAllocator = std.heap.DebugAllocator;
const builtin = @import("builtin");
const App = @import("App.zig");
const engine = @import("engine");
