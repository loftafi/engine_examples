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
    try self.display.setDefaultFont("ComicNeue", .unknown, .{});
    try self.display.setDefaultFont("GFSNeohellenic", .greek, .{});

    _ = try self.display.appendPanel(
        \\panel align start centre layout grows grows not_choosable {
        \\  rectangle layout grows grows
        \\}
    , App, self);
    _ = try self.display.appendPanel(
        \\panel align start centre layout grows grows vertical spacing=20 choosable {
        \\  label text "left a b c d e f g h i j k l m n o p q r s t u v w x y z a b c d e f g haw"
        \\    name "left" layout grows shrinks align start start
        \\    style custom colour #0e41db
        \\  label text "centre a b c d e f g h i j k l m n o p q r s t u v w x y z a b c d e f g owo"
        \\    name "centre" layout grows shrinks align centre start
        \\    style custom colour #0e41db
        \\  label text "right a b c d e f g h i j k l m n o p q r s t u v w x y z a b c d e f g h"
        \\    name "right" layout grows shrinks align end start
        \\    style custom colour #0e41db
        \\  label text "α ᾷ ἄ α β γ δ ε ζ η θ ι κ λ ν μ χ ο π ρ ζ τ υ φ ψ ω"
        \\    name "centre" layout grows shrinks align end start
        \\    style custom colour #0e41db
        \\}
    , App, self);
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
