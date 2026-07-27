pub const PlayScreen = @This();

const ROWS: usize = 4;
const COLS: usize = 4;

const BOARD_SIZE: f32 = 500;
const PADDING: f32 = 20;
const BLOCK_SIZE: f32 = (BOARD_SIZE - (PADDING * (ROWS + 1))) / ROWS;

panel: *Entity = undefined,

grid_locations: [ROWS * COLS]*Entity = undefined,
grid_location: usize = 0,

blocks: [(ROWS * COLS * 100) + 1]*Entity = undefined,
next_free_block: usize = 0,
cells: [ROWS * COLS]?*Entity = undefined,

move_counter: usize = 0,
move_status: *Entity = undefined,

pub fn show(
    self: *PlayScreen,
    display: *Display,
    _: *Entity,
    event: *const Event, // Keypress or mouse click got us here
) error{OutOfMemory}!void {
    self.grid_location = 0;
    self.next_free_block = 0;
    self.move_counter = 0;

    for (0..(ROWS * COLS)) |i|
        self.cells[i] = null;

    for (&self.blocks) |*block|
        block.*.visible = .hidden;

    try self.move_status.setText(display, "0 moves");
    try display.choosePanel("play.screen", event);

    // Trigger blocks to be spaced correctly so that we can place
    // two blocks right now.
    display.relayout();

    // Place first starting block.
    const start1 = resources.random.random(self.grid_locations.len);
    try self.addBlockToLocation(display, start1, '1');

    // Place second starting block. (retry if block overlaps first block.)
    const start2 = resources.random.random(self.grid_locations.len);
    while (start1 != start2) {
        try self.addBlockToLocation(display, start2, '1');
        break;
    }
}

pub fn init(
    self: *PlayScreen,
    gpa: Allocator,
    display: *Display,
) (engine.Error || Resources.Error || Allocator.Error)!void {
    seed(display.io);
    self.grid_location = 0;
    self.next_free_block = 0;
    self.move_counter = 0;

    self.panel = try display.addPanel(.{
        .name = "play.screen",
        .layout = .{ .x = .grows, .y = .grows },
        .child_align = .{ .x = .centre, .y = .centre },
        .pad = .{ .left = App.APP_PAD, .right = App.APP_PAD },
        .maximum = .{ .width = BOARD_SIZE + (App.APP_PAD * 2) },
        .minimum = .{ .width = BOARD_SIZE + (App.APP_PAD * 2), .height = App.APP_MINIMUM_HEIGHT },
        .type = .{ .panel = .{ .direction = .top_to_bottom } },
        .visible = .hidden,
    });

    _ = try self.panel.add(.{
        .name = "main_heading",
        .layout = .{ .y = .shrinks, .x = .grows },
        .child_align = .{ .x = .centre, .y = .start },
        .style = .tinted,
        .type = .{ .label = .{
            .text = "Numbers",
            .translated = "",
            .text_size = .heading,
        } },
        .pad = .{ .top = 30 },
    }, display);

    const background = try self.panel.add(.{
        .name = "background",
        .layout = .{ .x = .shrinks, .y = .shrinks },
        .child_align = .{ .x = .centre, .y = .end },
        .pad = .{ .left = PADDING, .right = PADDING, .top = PADDING, .bottom = PADDING },
        .minimum = .{ .width = BOARD_SIZE, .height = BOARD_SIZE },
        .maximum = .{ .width = BOARD_SIZE, .height = BOARD_SIZE },
        .style = .faded,
        .type = .{ .panel = .{
            .direction = .top_to_bottom,
            .spacing = PADDING,
        } },
    }, display);

    // Create the rows of background squares
    for (0..ROWS) |_| {
        const row = try background.add(.{
            .name = "row",
            .layout = .{ .x = .grows, .y = .shrinks },
            .child_align = .{ .x = .start, .y = .centre },
            .minimum = .{ .height = BLOCK_SIZE },
            .maximum = .{ .height = BLOCK_SIZE },
            .style = .faded,
            .type = .{ .panel = .{
                .direction = .left_to_right,
                .spacing = PADDING,
            } },
        }, display);

        for (0..COLS) |_|
            try self.add_grid_button(gpa, display, row);
    }

    // Create the cache of blocks
    for (0..self.blocks.len) |i|
        self.blocks[i] = try self.initNumberBlock(gpa, display, self.panel);

    for (0..self.cells.len) |i|
        self.cells[i] = null;

    // Create the menu stat label
    self.move_status = try self.panel.add(.{
        .name = "status line",
        .visible = .visible,
        .layout = .{ .y = .shrinks, .x = .grows },
        .child_align = .{ .x = .centre, .y = .start },
        .style = .normal,
        .type = .{ .label = .{
            .text = "",
            .translated = "",
            .text_size = .small,
        } },
        .pad = .{ .top = 10 },
    }, display);

    try display.setKeybinding(.up, .{ .func = @ptrCast(&swipeUp), .ptr = self });
    try display.setKeybinding(.down, .{ .func = @ptrCast(&swipeDown), .ptr = self });
    try display.setKeybinding(.left, .{ .func = @ptrCast(&swipeLeft), .ptr = self });
    try display.setKeybinding(.right, .{ .func = @ptrCast(&swipeRight), .ptr = self });

    //try display.setKeybindings(.w, .{ .func = @ptrCast(&swipeUp), .ptr = self });
    //try display.setKeybindings(.s, .{ .func = @ptrCast(&swipeDown), .ptr = self });
    //try display.setKeybindings(.a, .{ .func = @ptrCast(&swipeLeft), .ptr = self });
    //try display.setKeybindings(.d, .{ .func = @ptrCast(&swipeRight), .ptr = self });

    try display.setKeybinding(.k, .{ .func = @ptrCast(&swipeUp), .ptr = self });
    try display.setKeybinding(.j, .{ .func = @ptrCast(&swipeDown), .ptr = self });
    try display.setKeybinding(.h, .{ .func = @ptrCast(&swipeLeft), .ptr = self });
    try display.setKeybinding(.l, .{ .func = @ptrCast(&swipeRight), .ptr = self });
}

pub fn deinit(_: *PlayScreen) void {
    //
}

fn updateMoveStatus(self: *PlayScreen, display: *Display) error{OutOfMemory}!void {
    self.move_counter += 1;
    std.log.info("move counter = {d}", .{self.move_counter});
    try self.move_status.setText(display, "");
    if (self.move_counter == 1) {
        try self.move_status.setText(display, "1 move.");
    } else {
        const status = display.bucket.addFmt("{d} moves", .{self.move_counter}) catch "-";
        try self.move_status.setText(display, status);
    }
    try self.isGameOver();
}

fn return_block(self: *PlayScreen, item: *Entity, display: *Display) error{OutOfMemory}!void {
    item.visible = .hidden;
    item.style = .failed;
    try item.setText(display, "#");

    if (false) {
        for (0..self.blocks.len) |i| {
            if (self.blocks[i] == item) {
                const a = self.blocks[i];
                const b = self.blocks[self.next_free_block];
                self.blocks[i] = b;
                self.blocks[self.next_free_block] = a;
                self.next_free_block -= 1;
                log.err(" -- {*} {s} {*} {s} {*} {s} {*} {s}", .{
                    self.blocks[0],
                    self.blocks[0].type.button.text,
                    self.blocks[1],
                    self.blocks[1].type.button.text,
                    self.blocks[2],
                    self.blocks[2].type.button.text,
                    self.blocks[3],
                    self.blocks[3].type.button.text,
                });
                log.err(" -- {*} {s} {*} {s} {*} {s} {*} {s}", .{
                    self.blocks[4],
                    self.blocks[4].type.button.text,
                    self.blocks[5],
                    self.blocks[5].type.button.text,
                    self.blocks[6],
                    self.blocks[6].type.button.text,
                    self.blocks[7],
                    self.blocks[7].type.button.text,
                });
                return;
            }
        }
        log.err("Failed to return block {any}", .{&item});
    }
}

fn next_text(current: u8) []const u8 {
    return switch (current) {
        '1' => "2",
        '2' => "3",
        '3' => "4",
        '4' => "5",
        '5' => "6",
        '6' => "7",
        '7' => "8",
        '8' => "9",
        '9' => "A",
        'A' => "B",
        'B' => "C",
        'C' => "D",
        'D' => "E",
        'E' => "F",
        else => "*",
    };
}

fn isGameOver(self: *PlayScreen) error{OutOfMemory}!void {
    for (self.cells) |cell| {
        if (cell == null)
            return;
    }
    for (0..(self.cells.len - 1)) |i| {
        if (i % COLS > 0 and (i + 1) % COLS != 0) {
            if (self.cells[i].?.type.button.text[0] == self.cells[i + 1].?.type.button.text[0]) {
                return;
            }
        }
    }
    for (0..(self.cells.len - COLS)) |i| {
        if (self.cells[i].?.type.button.text[0] == self.cells[i + COLS].?.type.button.text[0]) {
            return;
        }
    }
    log.info("game over", .{});
}

fn addBlockToLocation(
    self: *PlayScreen,
    display: *Display,
    location: usize,
    value: u8,
) error{OutOfMemory}!void {
    var next = self.blocks[self.next_free_block];
    self.next_free_block += 1;
    next.visible = .visible;
    next.style = .success;
    next.rect = self.grid_locations[location].rect;
    try next.setText(display, next_text(value));
    self.cells[location] = next;
}

fn slide_block_to_location(
    self: *PlayScreen,
    _: *Display,
    from: usize,
    to: usize,
) error{OutOfMemory}!void {
    self.cells[from].?.rect = self.grid_locations[to].rect;
    self.cells[to] = self.cells[from];
    self.cells[from] = null;
}

fn merge_block_to_location(
    self: *PlayScreen,
    display: *Display,
    from: usize,
    to: usize,
) error{OutOfMemory}!void {
    try self.cells[to].?.setText(display, next_text(self.cells[to].?.type.button.text[0]));
    try self.return_block(self.cells[from].?, display);
    self.cells[from] = null;
}

fn insert_new_block(
    self: *PlayScreen,
    display: *Display,
    options: [COLS + 2 + 2]usize,
) error{OutOfMemory}!void {
    // First work out how many can take an item
    var available: usize = 0;
    for (options) |option| {
        if (self.cells[option] == null)
            available += 1;
    }

    if (available == 0)
        return;

    // Choose which of the available cells to use
    var choice = random.random(available);
    for (options) |option| {
        if (self.cells[option] != null) continue;
        if (choice == 0) {
            try self.addBlockToLocation(display, option, '1');
            break;
        }
        choice -= 1;
    }
}

fn swipeDown(
    self: *PlayScreen,
    display: *Display,
    _: *Entity,
    _: *const Event,
) error{OutOfMemory}!void {
    std.log.info("Swipe Down", .{});

    var swipe_possible: bool = false;

    // Starting from the final cell, keep going until we hit the
    // top row. The top row doesnt have anything to pull down from above.
    var dest: usize = COLS * ROWS;
    while (dest > COLS) {
        dest -= 1;

        var src: usize = dest;
        while (src >= COLS) {
            // Run up the row from the bottom
            src -= COLS;
            if (self.cells[src] != null) {
                if (self.cells[dest] == null) {
                    swipe_possible = true;
                    try self.slide_block_to_location(display, src, dest);
                }
            }
        }

        src = dest;
        while (src >= COLS) {
            // Run up the row from the bottom
            src -= COLS;
            if (self.cells[src] != null) {
                if (self.cells[dest].?.type.button.text[0] == self.cells[src].?.type.button.text[0]) {
                    swipe_possible = true;
                    try self.merge_block_to_location(display, src, dest);
                }
            }
        }

        if (dest == COLS) break;
    }

    if (!swipe_possible) {
        try self.isGameOver();
        return;
    }

    try self.insert_new_block(display, .{
        (COLS * 0) + 0,
        (COLS * 0) + 1,
        (COLS * 0) + 2,
        (COLS * 0) + 3,
        (COLS * 1) + 0,
        (COLS * 1) + (COLS - 1),
        (COLS * 2) + 0,
        (COLS * 2) + (COLS - 1),
    });
    try self.updateMoveStatus(display);
}

fn swipeUp(
    self: *PlayScreen,
    display: *Display,
    _: *Entity,
    _: *const Event,
) error{OutOfMemory}!void {
    std.log.info("Swipe Up", .{});

    var swipe_possible: bool = false;

    // Starting from the first cell, keep going until we hit the bottom
    // row. The bottom row doesnt have anything to pull up from below.
    var dest: usize = 0;
    while (dest < ROWS * COLS) {
        dest += 1;

        var src: usize = dest + COLS;
        while (src < COLS * ROWS) {
            if (self.cells[src] != null) {
                if (self.cells[dest] == null) {
                    swipe_possible = true;
                    try self.slide_block_to_location(display, src, dest);
                }
            }
            // Run down the row
            src += COLS;
        }

        src = dest + COLS;
        while (src < COLS * ROWS) {
            if (self.cells[src] != null) {
                if (self.cells[dest].?.type.button.text[0] == self.cells[src].?.type.button.text[0]) {
                    swipe_possible = true;
                    try self.merge_block_to_location(display, src, dest);
                }
            }
            // Run down the row
            src += COLS;
        }

        if (dest == ROWS * COLS) break;
    }

    if (!swipe_possible) {
        try self.isGameOver();
        return;
    }

    try self.insert_new_block(display, .{
        (COLS * 3) + 0,
        (COLS * 3) + 1,
        (COLS * 3) + 2,
        (COLS * 3) + 3,
        (COLS * 2) + 0,
        (COLS * 2) + (COLS - 1),
        (COLS * 1) + 0,
        (COLS * 1) + (COLS - 1),
    });
    try self.updateMoveStatus(display);
}

fn swipeLeft(
    self: *PlayScreen,
    display: *Display,
    _: *Entity,
    _: *const Event,
) error{OutOfMemory}!void {
    std.log.info("Swipe Left", .{});

    var swipe_possible: bool = false;

    // Starting from the first cell, see what we can slide left.
    // Ignore the right most column, it cant pull anything left.
    var dest: usize = 0;
    while (dest < ROWS * COLS) {
        var src: usize = dest + 1;
        while (src < ROWS * COLS) {
            //if (src % COLS == COLS - 1) break;
            if (src % COLS == 0) break;
            if (self.cells[src] != null) {
                if (self.cells[dest] == null) {
                    swipe_possible = true;
                    try self.slide_block_to_location(display, src, dest);
                }
            }
            // Move right until we hit the right column
            src += 1;
        }

        src = dest + 1;
        while (src < ROWS * COLS) {
            //if (src % COLS == COLS - 1) break;
            if (src % COLS == 0) break;
            if (self.cells[src] != null) {
                if (self.cells[dest].?.type.button.text[0] == self.cells[src].?.type.button.text[0]) {
                    swipe_possible = true;
                    try self.merge_block_to_location(display, src, dest);
                }
            }
            // Move right until we hit the right column
            src += 1;
        }

        dest += 1;
    }

    if (!swipe_possible) {
        try self.isGameOver();
        return;
    }

    try self.insert_new_block(display, .{
        (COLS * 0) + (COLS - 1),
        (COLS * 1) + (COLS - 1),
        (COLS * 2) + (COLS - 1),
        (COLS * 3) + (COLS - 1),
        (COLS * 0) + (COLS - 2),
        (COLS * 0) + (COLS - 3),
        (COLS * 3) + (COLS - 2),
        (COLS * 3) + (COLS - 3),
    });
    try self.updateMoveStatus(display);
}

fn swipeRight(
    self: *PlayScreen,
    display: *Display,
    _: *Entity,
    _: *const Event,
) error{OutOfMemory}!void {
    std.log.info("Swipe Right", .{});

    var swipe_possible: bool = false;

    // Starting from the first cell, see what we can slide left.
    // Ignore the right most column, it cant pull anything left.
    var dest: usize = ROWS * COLS;
    while (dest > 1) {
        dest -= 1;
        var src: usize = dest;
        while (src > 0) {
            // Run (backwards) along the row from right to left.
            src -= 1;
            if (src % COLS == COLS - 1) break;
            if (self.cells[src] != null) {
                if (self.cells[dest] == null) {
                    swipe_possible = true;
                    try self.slide_block_to_location(display, src, dest);
                }
            }
        }

        src = dest;
        while (src > 0) {
            // Move right until we hit the right column
            src -= 1;
            if (src % COLS == COLS - 1) break;
            if (self.cells[src] != null) {
                if (self.cells[dest].?.type.button.text[0] == self.cells[src].?.type.button.text[0]) {
                    swipe_possible = true;
                    try self.merge_block_to_location(display, src, dest);
                }
            }
        }
    }

    if (!swipe_possible) {
        try self.isGameOver();
        return;
    }

    try self.insert_new_block(display, .{
        (COLS * 0),
        (COLS * 1),
        (COLS * 2),
        (COLS * 3),
        (COLS * 0) + 1,
        (COLS * 0) + 2,
        (COLS * 3) + 1,
        (COLS * 3) + 2,
    });
    try self.updateMoveStatus(display);
}

fn initNumberBlock(
    _: *PlayScreen,
    _: Allocator,
    display: *Display,
    parent: *Entity,
) (engine.Error || Resources.Error || Allocator.Error)!*Entity {
    return try parent.add(.{
        .name = "number.block",
        .pad = .{ .left = 40, .right = 10, .top = 10, .bottom = 10 },
        .rect = .{ .width = BLOCK_SIZE, .height = BLOCK_SIZE },
        .layout = .{ .x = .fixed, .y = .fixed, .position = .float },
        .visible = .hidden,
        .style = .success,
        .type = .{ .button = .{
            .text = "1",
            .button = .{
                .default_name = "white rounded rect",
                .hover_name = "white rounded rect",
                .pressed_name = "white rounded rect",
            },
        } },
    }, display);
}

fn add_grid_button(
    self: *PlayScreen,
    _: Allocator,
    display: *Display,
    parent: *Entity,
) (engine.Error || Resources.Error || Allocator.Error)!void {
    std.debug.assert(self.grid_location < ROWS * COLS);
    self.grid_locations[self.grid_location] = try parent.add(.{
        .name = "grid.button",
        .pad = .{ .left = 10, .right = 10, .top = 10, .bottom = 10 },
        .minimum = .{ .width = BLOCK_SIZE, .height = BLOCK_SIZE },
        .maximum = .{ .width = BLOCK_SIZE, .height = BLOCK_SIZE },
        .layout = .{ .x = .shrinks, .y = .shrinks },
        .type = .{ .button = .{
            .text = "",
            .button = .{
                .default_name = "white rounded rect",
                .hover_name = "white rounded rect",
                .pressed_name = "white rounded rect",
            },
        } },
    }, display);
    self.grid_location += 1;
}

const std = @import("std");
const log = std.log;
const Allocator = std.mem.Allocator;

const resources = @import("resources");
const Resources = resources.Resources;
const random = resources.random;
const seed = random.seed;

const engine = @import("engine");
const Display = engine.Display;
const Entity = engine.Entity;
const Event = engine.Event;

const App = @import("App.zig");
