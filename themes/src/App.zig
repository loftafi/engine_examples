pub const App = @This();

gpa: Allocator,
io: std.Io,
display: *Display,

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
    };

    // Load fonts after screen initialisation so that the
    // screen pixel density can be accounted for.
    try self.display.setDefaultFont("NotoSans-Regular", .unknown, .{});
    //try self.display.setDefaultFont("ComicNeue", .unknown, .{});
    try self.display.setDefaultFont("GFSNeohellenic", .greek, .{});

    var panel = try self.display.appendPanel(
        \\panel name "Example" vertical
        \\  pad left=1em right=1em top=1em bottom=1em spacing 1em
        \\  align start start layout grows grows not_choosable visible 
        \\
    , App, self);
    _ = try panel.appendMultiple(
        \\ panel name "Normal" vertical layout grows shrinks visible {
        \\  label text "Normal text" text_size heading
        \\    name "left" layout grows shrinks align start start
        \\
        \\  label text "This is some sample text to go under the heading. This is the 'normal' style."
        \\    name "left" layout grows shrinks align start start pad bottom=1em
        \\
        \\ panel horizontal spacing 1em layout grows shrinks {
        \\    button text "Normal" layout shrinks shrinks style normal
        \\      button_default "white rounded rect" image_corner_radius 14 corner_radius 0.5em
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\
        \\    button text "Normal" layout shrinks shrinks style normal
        \\      icon_size width=1em height=1em spacing=0.5em
        \\      icon_default "icon play" image_corner_radius 14 corner_radius 0.5em
        \\      button_default "white rounded rect"
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\
        \\    button text "Ok" layout shrinks shrinks style success
        \\      icon_default "feedback tick" image_corner_radius 14 corner_radius 0.5em
        \\      icon_size width=1em height=1em spacing=0.5em
        \\      button_default "white rounded rect"
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\
        \\    button text "Normal" layout shrinks shrinks style normal
        \\      icon_size width=1em height=1em spacing=0.5em
        \\      icon_default "david head" icon_mod #ffffff
        \\      image_corner_radius 14 corner_radius 0.5em
        \\      button_default "white rounded rect"
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\
        \\ }
        \\}
        \\
        \\panel name "Faded" vertical style faded
        \\  pad left=0.7em right=0.7em top=0.7em bottom=0.7em
        \\  background_image "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\  align start start layout grows shrinks visible 
        \\{
        \\  label text "Faded panel" style faded text_size subheading
        \\    name "left" layout grows shrinks align start start
        \\
        \\  label style faded
        \\    text "This is some sample text to go under the heading. This is the 'faded' style."
        \\    layout grows shrinks align start start pad bottom=1em
        \\
        \\ panel horizontal spacing 1em layout grows shrinks {
        \\    button text "Faded" layout shrinks shrinks style faded
        \\      button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\
        \\    button text "Faded" layout shrinks shrinks style faded
        \\      icon_default "icon play" image_corner_radius 14 corner_radius 1em
        \\      icon_size width=1em height=1em spacing=0.5em
        \\      button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\
        \\    button text "Ok" layout shrinks shrinks style success
        \\      icon_size width=1em height=1em spacing=0.5em
        \\      icon_default "feedback tick" image_corner_radius 14 corner_radius 1em
        \\      button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\
        \\    button text "Cancel" layout shrinks shrinks style failed
        \\      icon_size width=1em height=1em spacing=0.5em
        \\      icon_default "feedback cross" image_corner_radius 14 corner_radius 1em
        \\      button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\  }
        \\}
        \\
        \\panel name "Success" vertical style success
        \\  pad left=0.7em right=0.7em top=0.7em bottom=0.7em
        \\  background_image "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\  align start start layout grows shrinks visible 
        \\{
        \\  label text "Success panel" style success text_size subheading
        \\    name "left" layout grows shrinks align start start
        \\
        \\  label style success
        \\    text "Something good was achieved or something succeeded. This is the 'success' style."
        \\    layout grows shrinks align start start pad bottom=1em
        \\ panel horizontal spacing 1em layout grows shrinks {
        \\    button text "Ok" layout shrinks shrinks style success
        \\      icon_size width=1em height=1em spacing=0.5em
        \\      icon_default "feedback tick" image_corner_radius 14 corner_radius 1em
        \\      button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\    button text "Normal" layout shrinks shrinks style normal
        \\      button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\    button text "Normal" layout shrinks shrinks style normal
        \\      icon_size width=1em height=1em spacing=0.5em
        \\      icon_default "icon play" image_corner_radius 14 corner_radius 1em
        \\      button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\  }
        \\}
        \\
        \\panel name "Failed" vertical style failed
        \\  pad left=0.7em right=0.7em top=0.7em bottom=0.7em 
        \\  background_image "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\  align start start layout grows shrinks visible 
        \\{
        \\  label text "Failed panel" style failed text_size subheading
        \\    name "left" layout grows shrinks align start start
        \\
        \\  label style failed
        \\    text "A panel that indicates something went wrong. This uses the 'failed' style."
        \\    layout grows shrinks align start start pad bottom=1em
        \\ panel horizontal spacing 1em layout grows shrinks {
        \\    button text "Cancel" layout shrinks shrinks style failed
        \\      icon_size width=1em height=1em spacing=0.5em
        \\      icon_default "feedback cross" image_corner_radius 14 corner_radius 1em
        \\      button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\    button text "Faded" layout shrinks shrinks style faded
        \\      button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\    button text "Faded" layout shrinks shrinks style faded
        \\      icon_default "icon play" image_corner_radius 14 corner_radius 1em
        \\      icon_size width=1em height=1em spacing=0.5em
        \\      button_default "white rounded rect" image_corner_radius 14 corner_radius 1em
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\  }
        \\}
        \\
        \\
        \\panel name "Custom" vertical 
        \\  pad left=0.7em right=0.7em top=0.7em bottom=0.7em 
        \\  background_image "pixel-panel" image_corner_radius 38 corner_radius 1em
        \\  align start start layout grows shrinks visible 
        \\  style custom background_colour #ffffff
        \\{
        \\  label text "Custom panel" style failed text_size subheading
        \\    name "left" layout grows shrinks align start start
        \\    style custom colour #0e41db
        \\
        \\  label style failed
        \\    text "A panel that indicates something went wrong. This uses the 'failed' style."
        \\    layout grows shrinks align start start pad bottom=1em
        \\    style custom colour #4e41db
        \\
        \\ panel horizontal spacing 1em layout grows shrinks {
        \\    button text "Example" layout shrinks shrinks
        \\      style custom colour #5577ff background_colour #ffffff
        \\      icon_size width=1em height=1em spacing=0.5em
        \\      icon_default "feedback cross"  icon_mod #ff8888ff
        \\      button_default "pixel-button" image_corner_radius 38 corner_radius 1em
        \\      button_pressed "pixel-button-pressed"
        \\      pad left=0.5em right=0.5em top=0.5em bottom=0.5em
        \\  }
        \\}
    , App, self, self.display);
}

//      button_default "pixel-button" image_corner_radius 38 corner_radius 1em
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
