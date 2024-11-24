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

/// INIDISP.
/// Write-only screen display controller.
/// Writeable at any time.
/// Writing this register on the first line of V-blank when force blank is active causes the OAM address reset to occur.
pub const screen_display: *volatile packed struct(u8) {
    /// Brightness between 0 and 15 inclusively.
    brightness: u4,
    padding: u3 = 0,
    /// Normal if false. If true, screen will be set off such that VRAM, OAM, and CGRAM can be accessed outside of VBLANK.
    /// Disabling force blank mid-scanline will cause graphics to glitch on the scanline.
    force_blank: bool,
} = @ptrFromInt(0x2100);

/// OBJSEL.
/// Write-only object size and object base.
/// Writeable during forced blank and V-blank.
pub const obj_select: *volatile packed struct(u8) {
    /// Base address for the 1st bank of object tiles in VRAM.
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
    /// Declare the "small" and "big" object sizes.
    obj_size: enum(u3) {
        Small_8x8_big_16x16,
        Small_8x8_big_32x32,
        Small_8x8_big_64x64,
        Small_16x16_big_32x32,
        Small_16x16_big_64x64,
        Small_32x32_big_64x64,
        Small_16x32_big_32x64,
        Small_16x32_big_32x32,
    },
} = @ptrFromInt(0x2101);

/// OAMADDL, OAMADDH.
/// Write-only OAM word address.
/// Writeable during forced blank and V-blank.
/// Address is invalidated when scanlines are being rendered.
pub const oam_address: *volatile packed struct(u16) {
    /// Word address into the OAM table.
    word_address: u8,
    /// Which table to write to.
    table_select: enum(u1) {
        /// The first table with 512 bytes.
        Table1,
        /// The second table with 32 bytes.
        Table2,
    },
    padding: u6 = 0,
    /// Use this to set the object to have the highest priority.
    priority_rotation: bool,
} = @ptrFromInt(0x2102);

/// OAM_DATA.
/// Write-only 8-bit OAM data to write to.
/// For addresses less than 512, 2 writes are required to update a 16-bit number.
/// Writeable at forced blank and V-blank.
/// One write will write one byte for 512 or above.
/// Each write increments the byte address.
pub const oam_data: *volatile u8 = @ptrFromInt(0x2104);

/// Background size.
pub const BgSize = enum(u1) {
    Size_8x8,
    Size_16x16,
};

/// BGMODE.
/// Write-only background mode and character size.
/// Writeable at forced blank, V-blank, and H-blank.
/// Color 0 for any palette is transparent.
pub const bg_mode: *volatile packed struct(u8) {
    mode: enum(u3) {
        /// Mode 0.
        /// Each BG is 2bpp.
        /// No offsets per tile.
        /// Priority order (front to back):
        /// Sprites with priority 3.
        /// BG1 tiles with priority 1.
        /// BG2 tiles with priority 1.
        /// Sprites with priority 2.
        /// BG1 tiles with priority 0.
        /// BG2 tiles with priority 0.
        /// Sprites with priority 1.
        /// BG3 tiles with priority 1.
        /// BG4 tiles with priority 1.
        /// Sprites with priority 0.
        /// BG3 tiles with priority 0.
        /// BG4 tiles with priority 0.
        Bpp_2_2_2_2,
        /// Mode 1.
        /// BG1 and BG2 are 4bpp, BG3 is 2bpp.
        /// No offsets per tile.
        /// Priority order (front to back):
        /// BG3 tiles with priority 1 if mode_1_bg3_priority is true.
        /// Sprites with priority 3.
        /// BG1 tiles with priority 1.
        /// BG2 tiles with priority 1.
        /// Sprites with priority 2.
        /// BG1 tiles with priority 0.
        /// BG2 tiles with priority 0.
        /// Sprites with priority 1.
        /// BG3 tiles with priority 1 if mode_1_bg3_priority is false.
        /// Sprites with priority 0.
        /// BG3 tiles with priority 0.
        Bpp_4_4_2_0,
        /// Mode 2.
        /// BG1 and BG2 are 4bpp.
        /// Offsets per tile.
        /// Priority order (front to back):
        /// Sprites with priority 3.
        /// BG1 tiles with priority 1.
        /// Sprites with priority 2.
        /// BG2 tiles with priority 1.
        /// Sprites with priority 1.
        /// BG1 tiles with priority 0.
        /// Sprites with priority 0.
        /// BG2 tiles with priority 0.
        Bpp_4_4_0_0,
        /// Mode 3.
        /// BG1 is 8bpp, BG2 is 4bpp.
        /// BG1 supports direct color mode.
        /// No offsets per tile.
        /// Priority order (front to back):
        /// Sprites with priority 3.
        /// BG1 tiles with priority 1.
        /// Sprites with priority 2.
        /// BG2 tiles with priority 1.
        /// Sprites with priority 1.
        /// BG1 tiles with priority 0.
        /// Sprites with priority 0.
        /// BG2 tiles with priority 0.
        Bpp_8_4_0_0,
        /// Mode 4.
        /// BG1 is 8bpp. BG2 is 2bpp.
        /// BG1 supports direct color mode.
        /// Offsets per tile.
        /// Priority order (front to back):
        /// Sprites with priority 3.
        /// BG1 tiles with priority 1.
        /// Sprites with priority 2.
        /// BG2 tiles with priority 1.
        /// Sprites with priority 1.
        /// BG1 tiles with priority 0.
        /// Sprites with priority 0.
        /// BG2 tiles with priority 0.
        Bpp_8_2_0_0,
        /// Mode 5.
        /// BG1 is 4bpp, BG2 is 2bpp.
        /// Hires mode.
        /// Width of each tile is 16 (but only uses the left half), but height can still be chosen.
        /// No offsets per tile.
        /// Priority order (front to back):
        /// Sprites with priority 3.
        /// BG1 tiles with priority 1.
        /// Sprites with priority 2.
        /// BG2 tiles with priority 1.
        /// Sprites with priority 1.
        /// BG1 tiles with priority 0.
        /// Sprites with priority 0.
        /// BG2 tiles with priority 0.
        Bpp_4_2_0_0,
        /// Mode 6.
        /// BG1 is 4bpp.
        /// Hires mode.
        /// Width of each tile is 16 (but only uses the left half), but height can still be chosen.
        /// Offsets per tile.
        /// Priority order (front to back):
        /// Sprites with priority 3.
        /// BG1 tiles with priority 1.
        /// Sprites with priority 2.
        /// Sprites with priority 1.
        /// BG1 tiles with priority 0.
        /// Sprites with priority 0.
        Bpp_4_0_0_0,
        /// Mode 7.
        /// BG1 is 8bpp. BG2 is 7bpp if EXTBG is enabled.
        /// BG1 supports direct color mode.
        /// No offsets per tile.
        /// BG2 uses the same tilemap and character data as BG1, but the highest pit is priority
        /// Note that BG2 will use Mode 7 scrolling registers rather than normal BG2 scrolling registers.
        /// Priority order (front to back):
        /// Sprites with priority 3.
        /// Sprites with priority 2.
        /// BG2 pixels with priority 1.
        /// Sprites with priority 1.
        /// BG1 tiles.
        /// Sprites with priority 0.
        /// BG2 pixels with priority 0.
        Bpp_8_7_0_0,
    },
    /// Make BG3 have the highest priority.
    mode_1_bg3_priority: enum(u1) {
        Normal,
        High,
    },
    /// Tile size for each background.
    /// Width is fixed at 16 for mode 5 and 6. Mode 7 is always 8x8 tiles.
    bg1_character_size: BgSize,
    bg2_character_size: BgSize,
    bg3_character_size: BgSize,
    bg4_character_size: BgSize,
} = @ptrFromInt(0x2105);

/// MOSAIC.
/// Write-only mosaic data.
/// Writeable during forced blank, V-blank, and H-blank.
/// Note that for 512 scanline mode, the mosaic size is doubled for the width but not height.
pub const mosaic: *volatile packed struct(u8) {
    bg1_mosaic: bool,
    bg2_mosaic: bool,
    bg3_mosaic: bool,
    bg4_mosaic: bool,
    /// Each (size + 1)x(size + 1) square is set by the top left color.
    /// Mosaic starts at the "Starting scanline".
    mosaic_size_plus_1: u4,
} = @ptrFromInt(0x2106);

/// BG1SC, BG2SC, BG3SC, BG4SC.
/// Write-only address for setting tile-maps.
/// Writeable during forced blank and V-blank.
pub const bg_tilemaps: *volatile [4]packed struct(u8) {
    horizontal_count_plus_one: u1,
    vertical_count_plus_one: u1,
    /// VRAM address.
    /// A value of 1 here would be 0x400.
    base_address_shifted_left_10: u6,
} = @ptrFromInt(0x2107);

/// VRAM address for the background tile characters.
pub const BackgroundCharacterAddress = enum(u4) {
    Addr_0x00000,
    Addr_0x02000,
    Addr_0x04000,
    Addr_0x06000,
    Addr_0x08000,
    Addr_0x0a000,
    Addr_0x0c000,
    Addr_0x0e000,
    Addr_0x10000,
    Addr_0x12000,
    Addr_0x14000,
    Addr_0x16000,
    Addr_0x18000,
    Addr_0x1a000,
    Addr_0x1c000,
    Addr_0x1e000,
};

/// BG12NBA.
/// Write-only address for setting character tile addresses.
/// Writeable during forced blank and V-blank.
pub const bg_character_address_12: *volatile packed struct(u8) {
    bg1_address: BackgroundCharacterAddress,
    bg2_address: BackgroundCharacterAddress,
} = @ptrFromInt(0x210b);

/// BG34NBA.
/// Write-only address for setting character tile addresses.
/// Writeable during forced blank and V-blank.
pub const bg_character_address_34: *volatile packed struct(u8) {
    bg3_address: BackgroundCharacterAddress,
    bg4_address: BackgroundCharacterAddress,
} = @ptrFromInt(0x210c);

/// BG1HOFS, BG1VOFS, BG2HOFS, BG2VOFS, BG3HOFS, BG3VOFS, BG4HOFS, BG4VOFS.
/// Write-only address for setting background scrolling.
/// Writeable during forced blank, V-blank, and H-blank.
/// BG1 regs are shared with mode 7 scrolling.
/// Necessary to write to the same byte twice to activate, so use this included function.
pub inline fn setBgScroll(bg_index: u2, scroll: u10, vert: bool) void {
    const bg_ptr: *volatile u8 = @ptrFromInt(@as(u16, @intCast(bg_index)) * 2 + 0x210d + if (vert) 1 else 0);
    bg_ptr.* = @intCast(scroll & 0xFF);
    bg_ptr.* = @intCast((scroll >> 8) & 0b11);
}

/// M7HOFS, M7VOFS.
/// Write-only address for setting mode 7 scrolling.
/// Writeable during forced blank, V-blank, and H-blank.
/// BG1 regs are shared with mode 7 scrolling.
/// Necessary to write to the same byte twice to activate, so use this included function.
pub inline fn setMode7Scroll(scroll: i13, vert: bool) void {
    const mode7_ptr: *volatile u8 = @ptrFromInt(0x210d + if (vert) 1 else 0);
    mode7_ptr.* = @intCast(scroll & 0xFF);
    mode7_ptr.* = @intCast((scroll >> 8) & 0b11111);
}

/// VMAIN.
/// Write-only address to controll the video port.
/// Writeable during force blank and V-blank.
pub const video_port_control: *volatile packed struct(u8) {
    address_increment_mode: enum(u4) {
        Increment_1x1,
        Increment_32x32,
        Increment_64x64,
        Increment_128x128,
        Increment_8_for_32_times,
        Increment_8_for_64_times = 8,
        Increment_8_for_128_times = 12,
    },
    padding: u3 = 0,
    /// How to increment when reading/writing VRAM data.
    increment_mode: enum(u1) {
        LowReadOrWrite,
        HighReadOrWrite,
    },
} = @ptrFromInt(0x2115);

/// VMADDL, VMADDH.
/// Write-only VRAM address to read and write to.
/// Writeable during forced blank and V-blank.
pub const vram_rw_addr: *volatile u16 = @ptrFromInt(0x2116);

/// VMDATAL.
/// Write-only write data to VRAM.
/// Writeable during forced blank and V-blank.
/// Address in VRAM to write to may be automatically incremented.
pub const vram_write_low: *volatile u8 = @ptrFromInt(0x2118);

/// VMDATAH.
/// Write-only write data to VRAM.
/// Writeable during forced blank and V-blank.
/// Address in VRAM to write to may be automatically incremented.
pub const vram_write_high: *volatile u8 = @ptrFromInt(0x2119);

/// M7SEL.
/// Write-only mode 7 settings.
/// Writeable during forced blank and V-blank.
pub const mode_7_settings: *volatile packed struct(u8) {
    flip_x: bool,
    flip_y: bool,
    padding: u4 = 0,
    empty_space_fill: enum(u1) {
        Transparent,
        Character_0,
    },
    outside_screan_area_mode: enum(u1) {
        Repeat,
        UseEmptySpaceFillSetting,
    },
} = @ptrFromInt(0x211a);

// TODO: MODE 7 MATRICES!!!

/// CGADD.
/// Write-only color index to write to.
/// Writeable during force blank, V-blank, and H-blank.
pub const color_index: *volatile u8 = @ptrFromInt(0x2121);

/// CGDATA.
/// Write-only CGRAM color.
/// Writeable during force blank, V-blank, and H-blank.
/// Color index written to increments after each write.
/// Function since a write-twice must be done.
pub inline fn setColor(r: u5, g: u5, b: u5) void {
    const color_ptr: *volatile u8 = @ptrFromInt(0x2122);
    const b1: u8 = ((@as(u8, @intCast(g)) & 0b111) << 5) | @as(u8, @intCast(b));
    const b2: u8 = (@as(u8, @intCast(r)) << 2) | ((@as(u8, @intCast(g)) & 0b11000) >> 3);
    color_ptr.* = b1;
    color_ptr.* = b2;
}

/// W12SEL.
/// Write-only window mask settings.
/// Writeable during force blank, V-blank, and H-blank.
pub const window_mask_settings_bg12: *volatile packed struct(u8) {
    bg1_invert_window_1: bool,
    bg1_window_1: bool,
    bg1_invert_window_2: bool,
    bg1_window_2: bool,
    bg2_invert_window_1: bool,
    bg2_window_1: bool,
    bg2_invert_window_2: bool,
    bg2_window_2: bool,
} = @ptrFromInt(0x2123);

/// W34SEL.
/// Write-only window mask settings.
/// Writeable during force blank, V-blank, and H-blank.
pub const window_mask_settings_bg34: *volatile packed struct(u8) {
    bg3_invert_window_1: bool,
    bg3_window_1: bool,
    bg3_invert_window_2: bool,
    bg3_window_2: bool,
    bg4_invert_window_1: bool,
    bg4_window_1: bool,
    bg4_invert_window_2: bool,
    bg4_window_2: bool,
} = @ptrFromInt(0x2124);

/// WOBJSEL.
/// Write-only window mask settings.
/// Writeable during force blank, V-blank, and H-blank.
pub const window_mask_settings_obj_color_window: *volatile packed struct(u8) {
    obj_invert_window_1: bool,
    obj_window_1: bool,
    obj_invert_window_2: bool,
    obj_window_2: bool,
    color_window_invert_window_1: bool,
    color_window_window_1: bool,
    color_window_invert_window_2: bool,
    color_window_window_2: bool,
} = @ptrFromInt(0x2125);

/// WH0.
/// Write-only window position.
/// Writeable during force blank, V-blank, and H-blank.
pub const window1_left_position: *volatile u8 = @ptrFromInt(0x2126);

/// WH1.
/// Write-only window position.
/// Writeable during force blank, V-blank, and H-blank.
pub const window1_right_position: *volatile u8 = @ptrFromInt(0x2127);

/// WH2.
/// Write-only window position.
/// Writeable during force blank, V-blank, and H-blank.
pub const window2_left_position: *volatile u8 = @ptrFromInt(0x2128);

/// WH3.
/// Write-only window position.
/// Writeable during force blank, V-blank, and H-blank.
pub const window2_right_position: *volatile u8 = @ptrFromInt(0x2129);

/// Window combiner for pixel to be in window, if both windows are enabled.
pub const WindowMaskMode = enum(u2) {
    Or,
    And,
    Xor,
    Xnor,
};

/// WBGLOG.
/// Write-only window masking logic for backgrounds.
/// Writeable during force blank, V-blank, and H-blank.
pub const window_bg_logic: *volatile packed struct(u8) {
    bg1: WindowMaskMode,
    bg2: WindowMaskMode,
    bg3: WindowMaskMode,
    bg4: WindowMaskMode,
} = @ptrFromInt(0x212a);

/// WOBJLOG.
/// Write-only window masking logic for objects and color window.
/// Writeable during force blank, V-blank, and H-blank.
pub const window_obj_color_window_logic: *volatile packed struct(u8) {
    objs: WindowMaskMode,
    color_window: WindowMaskMode,
    padding: u4 = 0,
} = @ptrFromInt(0x212b);

/// TM.
/// Write-only if backgrounds and objects are to show up on the main screen.
/// Writeable during force blank, V-blank, and H-blank.
pub const main_screen_designations: *volatile packed struct(u8) {
    bg1: bool,
    bg2: bool,
    bg3: bool,
    bg4: bool,
    objs: bool,
    padding: u3 = 0,
} = @ptrFromInt(0x212c);

/// TS.
/// Write-only if backgrounds and objects are to show up on the sub screen.
/// Writeable during force blank, V-blank, and H-blank.
pub const sub_screen_designations: *volatile packed struct(u8) {
    bg1: bool,
    bg2: bool,
    bg3: bool,
    bg4: bool,
    objs: bool,
    padding: u3 = 0,
} = @ptrFromInt(0x212d);

/// TMW.
/// Write-only if window masks for backgrounds and objects are to show up on the main screen.
/// Writeable during force blank, V-blank, and H-blank.
pub const main_screen_window_mask_designations: *volatile packed struct(u8) {
    bg1: bool,
    bg2: bool,
    bg3: bool,
    bg4: bool,
    objs: bool,
    padding: u3 = 0,
} = @ptrFromInt(0x212e);

/// TSW.
/// Write-only if window masks for backgrounds and objects are to show up on the sub screen.
/// Writeable during force blank, V-blank, and H-blank.
pub const sub_screen_window_mask_designations: *volatile packed struct(u8) {
    bg1: bool,
    bg2: bool,
    bg3: bool,
    bg4: bool,
    objs: bool,
    padding: u3 = 0,
} = @ptrFromInt(0x212f);

/// CGWSEL.
/// Write-only color addition select.
/// Writeable during forced blank, V-blank, and H-blank.
pub const color_addition_select: *volatile packed struct(u8) {
    direct_color_mode: bool,
    add_subscreen: bool,
    padding: u2 = 0,
    prevent_color_math_mode: enum(u2) {
        Never,
        OutsideColorWindow,
        InsideColorWindow,
        Always,
    },
    clip_colors_to_blank_before_black_mode: enum(u2) {
        Never,
        OutsideColorWindow,
        InsideColorWindow,
        Always,
    },
} = @ptrFromInt(0x2130);

/// CGADSUB.
/// Write-only color math designation for controlling color math operations.
/// Writeable during forced blank, V-blank, and H-blank.
pub const color_math_designation: *volatile packed struct(u8) {
    bg1_math: bool,
    bg2_math: bool,
    bg3_math: bool,
    bg4_math: bool,
    obj_math: bool,
    backdrop_math: bool,
    half_result: bool,
    add_subtract_mode: enum(u1) {
        Add,
        Subtract,
    },
} = @ptrFromInt(0x2131);

/// COLDATA.
/// Write-only fixed color data. You can set the intensity for multiple RGB elements at a time, so to get the correct color additional calls may be needed.
/// Writeable during forced blank, V-blank, and H-blank.
pub inline fn setFixedColorData(intensity: u5, r: bool, g: bool, b: bool) void {
    const ptr: *volatile u8 = @ptrFromInt(0x2132);
    ptr.* = @as(u8, @intCast(intensity)) | (if (r) (1 << 5) else 0) | (if (g) (1 << 6) else 0) | (if (b) (1 << 7) else 0);
}

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
    obj_select.* = .{ .obj_tiles_1_addr = .Addr_0x0000, .obj_tiles_2_off = .Off_0x1000, .obj_size = .Small_8x8_big_16x16 };
    oam_address.* = .{ .priority_rotation = false, .table_select = .Table1, .word_address = 0 };
    bg_mode.* = .{
        .bg1_character_size = .Size_8x8,
        .bg2_character_size = .Size_8x8,
        .bg3_character_size = .Size_8x8,
        .bg4_character_size = .Size_8x8,
        .mode = .Bpp_2_2_2_2,
        .mode_1_bg3_priority = .Normal,
    };
    mosaic.* = .{ .bg1_mosaic = false, .bg2_mosaic = false, .bg3_mosaic = false, .bg4_mosaic = false, .mosaic_size_plus_1 = 0 };
    bg_tilemaps.*[0] = .{ .base_address_shifted_left_10 = 0, .horizontal_count_plus_one = 0, .vertical_count_plus_one = 0 };
    bg_tilemaps.*[1] = .{ .base_address_shifted_left_10 = 0, .horizontal_count_plus_one = 0, .vertical_count_plus_one = 0 };
    bg_tilemaps.*[2] = .{ .base_address_shifted_left_10 = 0, .horizontal_count_plus_one = 0, .vertical_count_plus_one = 0 };
    bg_tilemaps.*[3] = .{ .base_address_shifted_left_10 = 0, .horizontal_count_plus_one = 0, .vertical_count_plus_one = 0 };
    bg_character_address_12.* = .{ .bg1_address = .Addr_0x00000, .bg2_address = .Addr_0x00000 };
    bg_character_address_34.* = .{ .bg3_address = .Addr_0x00000, .bg4_address = .Addr_0x00000 };
    setBgScroll(0, 0, false);
    setBgScroll(0, std.math.maxInt(u10), true);
    setBgScroll(1, 0, false);
    setBgScroll(1, std.math.maxInt(u10), true);
    setBgScroll(2, 0, false);
    setBgScroll(2, std.math.maxInt(u10), true);
    setBgScroll(3, 0, false);
    setBgScroll(3, std.math.maxInt(u10), true);
    video_port_control.* = .{ .address_increment_mode = .Increment_1x1, .increment_mode = .HighReadOrWrite };
    vram_rw_addr.* = 0;
    mode_7_settings.* = .{ .empty_space_fill = .Transparent, .flip_x = false, .flip_y = false, .outside_screan_area_mode = .Repeat };
    color_index.* = 0;
    window_mask_settings_bg12.* = .{
        .bg1_invert_window_1 = false,
        .bg1_invert_window_2 = false,
        .bg1_window_1 = false,
        .bg1_window_2 = false,
        .bg2_invert_window_1 = false,
        .bg2_invert_window_2 = false,
        .bg2_window_1 = false,
        .bg2_window_2 = false,
    };
    window_mask_settings_bg34.* = .{
        .bg3_invert_window_1 = false,
        .bg3_invert_window_2 = false,
        .bg3_window_1 = false,
        .bg3_window_2 = false,
        .bg4_invert_window_1 = false,
        .bg4_invert_window_2 = false,
        .bg4_window_1 = false,
        .bg4_window_2 = false,
    };
    window_mask_settings_obj_color_window.* = .{
        .obj_invert_window_1 = false,
        .obj_invert_window_2 = false,
        .obj_window_1 = false,
        .obj_window_2 = false,
        .color_window_invert_window_1 = false,
        .color_window_invert_window_2 = false,
        .color_window_window_1 = false,
        .color_window_window_2 = false,
    };
    window1_left_position.* = 0;
    window1_right_position.* = 0;
    window2_left_position.* = 0;
    window2_right_position.* = 0;
    window_bg_logic.* = .{ .bg1 = .Or, .bg2 = .Or, .bg3 = .Or, .bg4 = .Or };
    window_obj_color_window_logic.* = .{ .color_window = .Or, .objs = .Or };
    main_screen_designations.* = .{ .bg1 = false, .bg2 = false, .bg3 = false, .bg4 = false, .objs = false };
    sub_screen_designations.* = .{ .bg1 = false, .bg2 = false, .bg3 = false, .bg4 = false, .objs = false };
    main_screen_window_mask_designations.* = .{ .bg1 = false, .bg2 = false, .bg3 = false, .bg4 = false, .objs = false };
    sub_screen_window_mask_designations.* = .{ .bg1 = false, .bg2 = false, .bg3 = false, .bg4 = false, .objs = false };
    color_addition_select.* = .{ .add_subscreen = false, .clip_colors_to_blank_before_black_mode = .Never, .direct_color_mode = false, .prevent_color_math_mode = .Never };
    color_math_designation.* = .{ .add_subtract_mode = .Add, .backdrop_math = false, .bg1_math = false, .bg2_math = false, .bg3_math = false, .bg4_math = false, .half_result = false, .obj_math = false };
    setFixedColorData(0, true, true, true);
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
