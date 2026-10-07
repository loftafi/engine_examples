pub var app: App = undefined;

/// Main app function for desktop versions of the app.
pub fn main(init: std.process.Init) !void {
    try engine.start.start(&startup, &shutdown, init.minimal.args);
}

/// Entrypoint for callback version of the app.
pub export fn SDL_AppInit(
    appstate: [*c]?*anyopaque,
    argc: c_int,
    argv: [*c][*c]u8, // [*:null]?[*:0]u8
) callconv(.c) engine.sdl.SDL_AppResult {
    engine.start.startup_handler = startup;
    engine.start.shutdown_handler = shutdown;
    return engine.AppInitC(appstate, argc, argv);
}
pub export const SDL_AppQuit = engine.AppQuitC;
pub export const SDL_AppEvent = engine.AppEventC;
pub export const SDL_AppIterate = engine.AppIterateC;

pub fn startup(
    gpa: Allocator,
    arena: Allocator,
    io: std.Io,
    args: []const [*:0]const u8,
) error{ OutOfMemory, AppInitFailed }!*engine.Display {
    _ = arena;
    _ = args;

    var config: engine.Config = .{
        .app_name = "Text Label Alignment",
        .app_version = "1.0",
        .app_id = "org.example",
        .app_build = "123",
        .app_org = "My Org",
        .app_bundle_output = "resources.bd",
        .full_screen = false,
        .bundles = &.{
            .{ .folder = "resources/" },
            //.{ .filename = "resources.bd" },
        },
        .width = 500,
        .height = 500,
        .min_width = 300,
        .min_height = 300,
        //.translation_filename = "translations",
        //.desktop_icon = if (builtin.os.tag == .macos) "desktop icon" else null,
    };

    app.init(gpa, io, &config) catch |f| {
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

pub fn shutdown(
    _: Allocator,
    _: Allocator,
    _: std.Io,
) void {
    app.deinit();
}

pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = engine.log.log_capture,
};

const std = @import("std");
const Allocator = std.mem.Allocator;
const DebugAllocator = std.heap.DebugAllocator;
const builtin = @import("builtin");
const App = @import("App.zig");
const engine = @import("engine");
