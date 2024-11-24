const snes = @import("snes.zig");

comptime {
    _ = @import("snes.zig"); // Exports are at compile time??
}

export fn main() noreturn {
    snes.setColor(0b11111, 0b00010, 0b11111);
    snes.screen_display.* = .{ .brightness = 0xF, .force_blank = false };
    while (true) {}
}
