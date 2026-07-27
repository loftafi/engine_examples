pub const App = @This();

pub const RESOURCE_BUNDLE_FILENAME = "resources.bd";
pub const RESOURCE_TRANSLATION_FILE = "translation";

gpa: Allocator,
io: std.Io,
display: *Display,
menu_screen: MenuScreen,
play_screen: PlayScreen,

pub fn init(
    self: *App,
    gpa: Allocator,
    io: std.Io,
    config: *engine.Config,
) (engine.Error || Allocator.Error || error{
    ThreadCreationFailed,
    Utf8ExpectedContinuation,
    Utf8OverlongEncoding,
    Utf8EncodesSurrogateHalf,
    Utf8CodepointTooLarge,
    Utf8InvalidStartByte,
    FailedReadingTimezone,
} || Resources.Error || std.Io.File.OpenError || std.Io.File.StatError)!void {
    self.* = .{
        .gpa = gpa,
        .io = io,
        .display = try Display.create(gpa, io, config.*),
        .menu_screen = undefined,
        .play_screen = undefined,
    };

    // Load fonts after screen initialisation so that the
    // screen pixel density can be accounted for.
    try self.display.setDefaultFont("ComicNeue-Regular", .unknown, .{});

    try self.menu_screen.init(self.gpa, self.display);
    errdefer self.menu_screen.deinit();

    try self.play_screen.init(self.gpa, self.display);
    errdefer self.play_screen.deinit();

    try self.display.setKeybinding(.space, .{ .func = @ptrCast(&showPlayScreen), .ptr = self });
    try self.display.setKeybinding(.p, .{ .func = @ptrCast(&showPlayScreen), .ptr = self });
    try self.display.setKeybinding(.escape, .{ .func = @ptrCast(&handleBack), .ptr = self });
    try self.display.setKeybinding(.ac_back, .{ .func = @ptrCast(&handleBack), .ptr = self });

    try self.menu_screen.show(self.display, self.menu_screen.panel, &.{});
}

pub fn deinit(self: *App) void {
    self.menu_screen.deinit();
    self.play_screen.deinit();
    self.display.destroy();
    self.* = undefined;
}

fn showPlayScreen(
    self: *App,
    display: *Display,
    entity: *Entity,
    event: *const Event,
) error{OutOfMemory}!void {
    if (display.getPanel("play.screen")) |_| {
        try self.play_screen.show(display, entity, event);
    }
}

fn handleBack(
    self: *App,
    display: *Display,
    entity: *Entity,
    event: *const Event,
) error{OutOfMemory}!void {
    const screen = display.currentPanel();
    if (screen != null and std.mem.eql(u8, screen.?.name, "menu.screen")) {
        if (builtin.target.os.tag != .ios and !builtin.target.abi.isAndroid()) {
            display.endMainLoop();
        }
        return;
    }
    try self.menu_screen.show(display, entity, event);
}

const Scale = engine.Scale;
const std = @import("std");
const Allocator = std.mem.Allocator;
const log = std.log;

const builtin = @import("builtin");
const engine = @import("engine");
const Display = engine.Display;
const Entity = engine.Entity;
const Event = engine.Event;

const Resources = @import("resources").Resources;

const MenuScreen = @import("MenuScreen.zig");
const PlayScreen = @import("PlayScreen.zig");
const TextSize = @import("engine").TextSize;
