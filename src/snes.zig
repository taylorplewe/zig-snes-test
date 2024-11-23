const std = @import("std");

/// Frames per second in interlacing mode.
pub const fps_interlaced = 30;

/// Frames per second in non-interlacing mode.
pub const fps_noninterlaced = 60;

/// Number of horizontal lines on screen if interlaced.
pub const num_lines_interlaced = 512;

/// Number of horizontal lines on screen if non-interlaced.
pub const num_lines_noninterlaced = 216;

/// Maximum number of objects that can be displayed on screen.
pub const max_num_objs = 128;

/// Number of colors in an object's palette.
pub const num_colors_in_obj_palette = 16;

/// Number of object palettes available.
pub const num_obj_palettes = 8;

/// Number of background layers.
pub const num_bgs = 4;

/// INIDISP. Write-only screen display controller.
pub const screen_display: *volatile packed struct(u8) {
    /// Brightness between 0 and 15 inclusively.
    brightness: u4,
    padding: u3 = 0,
    /// Normal if false. If true, screen will be set off such that VRAM, OAM, and CGRAM can be accessed outside of VBLANK.
    force_blank: bool,
} = @ptrFromInt(0x2100);

/// REG_OBSEL. Write-only object size and object base.
pub const obj_select: *volatile packed struct(u8) {
    /// Base address for the 1st bank of object tiles.
    obj_tiles_1_addr: enum(u3) {
        Addr_0x0000,
        Addr_0x2000,
        Addr_0x4000,
        Addr_0x6000,
        Addr_0x8000,
        Addr_0xa000,
        Addr_0xc000,
        Addr_0xe000,
    },
    /// Offset from the bank 1 of object tiles address to where the 2nd bank of object tiles is.
    obj_tiles_2_off: enum(u2) {
        Off_0x1000,
        Off_0x2000,
        Off_0x3000,
    },
    /// Object sizes for bank 1 and bank 2.
    obj_size: enum(u3) {
        Objs_b1_8x8_b2_16x16,
        Objs_b1_8x8_b2_32x32,
        Objs_b1_8x8_b2_64x64,
        Objs_b1_16x16_b2_32x32,
        Objs_b1_16x16_b2_64x64,
        Objs_b1_32x32_b2_64x64,
        Objs_b1_16x32_b2_32x64,
        Objs_b1_16x32_b2_32x32,
    },
} = @ptrFromInt(0x2101);

/// Write-only OAM word address.
pub const oam_address: *volatile packed struct(u16) {
    word_address: u8,
    table_select: enum(u1) {
        Has_256_words,
        Has_16_words,
    },
    padding: u6 = 0,
    /// Use this to set the object to have the highest priority.
    priority_rotation: bool,
} = @ptrFromInt(0x2102);

/// Write-only 8-bit OAM data to write to.
pub const oam_data_8: *volatile u8 = @ptrFromInt(0x2104);

/// Write-only 16-bit OAM data to write to.
pub const oam_data_16: *volatile u16 = @ptrFromInt(0x2104);

/// Background size.
pub const BgSize = enum(u1) {
    Size_8x8,
    Size_16x16,
};

/// Write-only background mode and character size.
pub const bg_mode: *volatile packed struct(u8) {
    mode: enum(u3) {
        bpp_2_2_2_2,
        bpp_4_4_2_0,
        bpp_4_4_0_0,
        bpp_8_4_0_0,
        bpp_8_2_0_0,
        bpp_4_2_0_0,
        bpp_4_0_0_0,
        bpp_8_0_0_0,
    },
    mode_1_bg3_priority: enum(u1) {
        Normal,
        High,
    },
    bg_character_size: [num_bgs]BgSize,
} = @ptrFromInt(0x2105);

/// Write-only mosaic data.
pub const mosaic: *volatile packed struct(u8) {
    bgs: [num_bgs]bool,
    mosaic_size_plus_1: u4,
} = @ptrFromInt(0x2106);

pub const blank_flags_and_joypad_status: *const volatile packed struct(u8) {
    joypad: bool,
    padding: u5 = 0,
    horizontal_blank: bool,
    vertical_blank: bool,
} = @ptrFromInt(0x4212);
pub const joypad_io: *const volatile u8 = @ptrFromInt(0x4213);
pub const quotient_result: *const volatile u16 = @ptrFromInt(0x4214);
pub const product_or_remainder_result: *const volatile u16 = @ptrFromInt(0x4216);

pub const joypads: *const volatile [4]packed struct(u16) {
    padding: u4 = 0,
    r: bool,
    l: bool,
    x: bool,
    a: bool,
    dpad_right: bool,
    dpad_left: bool,
    dpad_down: bool,
    dpad_up: bool,
    start: bool,
    select: bool,
    y: bool,
    b: bool,
} = @ptrFromInt(0x4218);

/// Disable interrupts.
pub inline fn disableInterrupts() void {
    asm volatile ("sei");
}

/// Enable interrupts.
pub inline fn enableInterrupts() void {
    asm volatile ("cli");
}

/// Initialize the console.
export fn _consoleInit() linksection(".prolog") void {
    screen_display.* = .{ .brightness = 0xf, .force_blank = true };
    obj_select.* = .{ .obj_tiles_1_addr = .Addr_0x0000, .obj_tiles_2_off = .Off_0x1000, .obj_size = .Objs_b1_8x8_b2_16x16 };
    oam_address.* = .{ .priority_rotation = false, .table_select = .Has_256_words, .word_address = 0 };
}

/// Main entry point for the program.
export fn _start() linksection(".entry") void {
    disableInterrupts();
    asm volatile (
        \\clc               ; Switch to native mode by clearing carry.
        \\xce               ; Native mode.
        \\rep #$18          ; Disable decimal mode. X/Y 16-bit as well.
        \\ldx #$1fff        ; Stack address.
        \\txs               ; Set new stack address.
        \\sep #$30          ; A, X, and Y are assumed to be 8-bits initially.
        \\jsl _consoleInit  ; Initialize the console. Not called in C to make sure "prolog" section is kept.
    );
    // enableInterrupts();
    asm volatile (
        \\jsl _main
        \\lda _header_with_interrupts   ; PLEASE STOP DISCARDING MY HEADER. EVEN THE DONOTOPTIMIZEAWAY FUNCTION DOES NOTHING. THIS CODE IS UNREACHABLE.
    );
    unreachable;
}

/// Trampoline for main, since main uses RTS and we need to be on the same bank for it to work.
export fn _main() linksection(".text") callconv(.Naked) void {
    asm volatile (
        \\jsr main
        \\stp
    );
}

/// Header is kinda blanked out here. Interrupts are populated at the end though.
const _start_addr = 0x8000; // Mirrored in memory so it's fine.
export const _header_with_interrupts: [0x50 / 2]u16 linksection(".header") = [_]u16{
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE,
    0xFFFE, // Actual interrupts start below.
    0x0000,
    0x0000, // 65c816:
    0x0000, // COP.
    0x0000, // BRK.
    0x0000, // ABORT.
    0x0000, // NMI.
    0x0000,
    0x0000, // IRQ.
    0x0000,
    0x0000, // 6502 Emulation:
    0x0000, // COP.
    0x0000,
    0x0000, // ABORT.
    0x0000, // NMI.
    _start_addr, // RESET.
    0x0000, // IRQ.
};
