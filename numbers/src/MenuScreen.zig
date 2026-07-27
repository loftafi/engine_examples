/// Display the game main menu.
pub const MenuScreen = @This();

panel: *Entity,
heading: *Entity,

/// Show the game main menu
pub fn show(
    self: *MenuScreen,
    display: *Display,
    _: *Entity,
    _: *const Event, // Keypress or mouse click got us here
) error{OutOfMemory}!void {
    try display.choosePanel(self.panel.name, &.{});
}

/// Create the main menu panel and place entities into the main menu.
pub fn init(
    self: *MenuScreen,
    _: Allocator,
    display: *Display,
) !void {
    try display.setKeybinding(.space, .{ .func = @ptrCast(&startGame), .ptr = self });

    self.panel = try display.addPanel(.{
        .name = "menu.screen",
        .layout = .{ .x = .grows, .y = .grows },
        .child_align = .{ .x = .centre, .y = .centre },
        .pad = .{ .left = App.APP_PAD, .right = App.APP_PAD },
        .minimum = .{ .width = App.APP_MINIMUM_WIDTH, .height = App.APP_MINIMUM_HEIGHT },
        .maximum = .{ .width = App.APP_MAXIMUM_WIDTH },
        .type = .{ .panel = .{
            .direction = .top_to_bottom,
        } },
        .visible = .hidden,
    });

    self.heading = try self.panel.add(.{
        .name = "main_heading",
        .layout = .{ .y = .shrinks, .x = .grows },
        .child_align = .{ .x = .centre, .y = .start },
        .pad = .{ .top = 30 },
        .style = .tinted,
        .type = .{ .label = .{
            .text = "Numbers",
            .text_size = .heading,
        } },
    }, display);

    _ = try self.panel.add(.{
        .rect = .{ .height = 100 },
        .layout = .{ .y = .fixed, .x = .grows },
        .child_align = .{ .x = .centre, .y = .start },
        .type = .{ .label = .{} },
    }, display);

    const aligner = try self.panel.add(.{
        .name = "menu.screen",
        .layout = .{ .x = .grows, .y = .shrinks },
        .child_align = .{ .x = .centre, .y = .centre },
        .minimum = .{ .height = 100 },
        .pad = .{ .left = App.APP_PAD, .right = App.APP_PAD },
        .type = .{ .panel = .{ .direction = .left_to_right } },
    }, display);

    _ = try aligner.add(.{
        .name = "start.button",
        .pad = .{ .left = 20, .right = 20, .top = 20, .bottom = 20 },
        .layout = .{ .x = .shrinks, .y = .shrinks },
        .type = .{ .button = .{
            .text = "Start",
            .on_pressed = .{ .func = @ptrCast(&startGame), .ptr = self },
            .button = .{
                .default_name = "white rounded rect",
                .hover_name = "white rounded rect",
                .pressed_name = "white rounded rect",
            },
        } },
    }, display);
}

pub fn deinit(_: *MenuScreen) void {
    //
}

pub fn startGame(
    self: *MenuScreen,
    display: *Display,
    entity: *Entity,
    _: *const Event,
) error{OutOfMemory}!void {
    const app: *App = @fieldParentPtr("menu_screen", self);
    std.log.info("startGame fonts={d} in", .{display.fonts.items.len});
    std.log.info("startGame fonts={d} via app in", .{app.display.fonts.items.len});
    try app.play_screen.show(display, entity, &.{});
    std.log.info("startGame fonts={d} out", .{display.fonts.items.len});
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const engine = @import("engine");
const Entity = engine.Entity;
const Event = engine.Event;
const Display = engine.Display;
const App = @import("App.zig");
