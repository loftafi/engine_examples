pub const App = @This();

gpa: Allocator,
io: std.Io,
display: *Display,

ton: *Entity = undefined,
toff: *Entity = undefined,
tcorrect: *Entity = undefined,
tincorrect: *Entity = undefined,

pub fn init(
    self: *App,
    gpa: Allocator,
    io: std.Io,
    config: *engine.Config,
) (engine.Error || Allocator.Error || Resources.Error ||
    std.Io.File.OpenError || std.Io.File.StatError)!void {
    self.* = .{
        .gpa = gpa,
        .io = io,
        .display = try Display.create(gpa, io, config.*),
    };

    // Load fonts before panels to ensure layout accounts for font metrics.
    try self.display.setDefaultFont("NotoSans-Regular", .unknown, .{});

    _ = try self.display.appendPanel(
        \\panel name "Example" vertical
        \\  pad left=1em right=1em top=1em bottom=1em spacing 1em
        \\  align start start layout grows grows not_choosable visible 
        \\{
        \\  panel name "Normal" vertical layout grows shrinks visible
        \\  {
        \\    label text "Toggle Button Example" text_size heading
        \\      name "left" layout grows shrinks align start start
        \\
        \\    label text "This is some sample text to go under the heading. This is the 'normal' style."
        \\      name "left" layout grows shrinks align start start pad bottom=1em
        \\
        \\  }
        \\
        \\  panel name "Faded" vertical style faded
        \\    pad left=0.7em right=0.7em top=0.7em bottom=0.7em
        \\    background_image "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\    align start start layout grows shrinks visible
        \\  {
        \\
        \\    panel horizontal spacing 1em layout grows shrinks
        \\    {
        \\      button:toff text "off" layout shrinks shrinks 
        \\        button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\        pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\
        \\      button:ton text "on" layout shrinks shrinks 
        \\        image_corner_radius 14 corner_radius 1em
        \\        button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\        pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\
        \\      button:tincorrect text "incorrect" layout shrinks shrinks 
        \\        image_corner_radius 14 corner_radius 1em
        \\        button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\        pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\
        \\      button:tcorrect text "correct" layout shrinks shrinks 
        \\        image_corner_radius 14 corner_radius 1em
        \\        button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\        pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\    }
        \\  }
        \\
        \\}
    , App, self);

    self.ton.type.button.toggle = .on;
    self.toff.type.button.toggle = .off;
    self.tcorrect.type.button.toggle = .correct;
    self.tincorrect.type.button.toggle = .incorrect;
}

pub fn deinit(self: *App) void {
    self.display.destroy();
    self.* = undefined;
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
