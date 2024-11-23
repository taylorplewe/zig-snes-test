const std = @import("std");

const max_game_code_len = 3;
const max_title_len = 21;

/// Error encountered writing header.
pub const HeaderWriteError = error{
    GameCodeTooLong,
    TitleTooLong,
};

/// SNES ROM header.
pub const Header = struct {
    /// Upper-case ASCII indicating the maker.
    maker_code: [2]u8,
    /// Up to 4-digit uppercase ASCII for game code. Last code is from the region.
    game_code: []const u8,
    /// Size of RAM to be used by coprocessor.
    expansion_ram_size: enum(u8) {
        None,
        Size16Kb,
        Size64Kb,
        Size256Kb,
        Size512Kb,
        Size1Mb,
    },
    /// Special version release of the game.
    special_version: u8 = 0,
    /// To distinguish games of same cartridge type, just leave at 0.
    cartridge_sub_number: u8 = 0,
    /// Up to 21-bytes of game title.
    title: []const u8,
    /// Mapping of chip into memory.
    map_mode: packed struct(u8) {
        mapping_model: enum(u1) {
            LoRom,
            HiRom,
        },
        extended: u1 = 0,
        ex_hi_rom: bool,
        padding1: u1 = 0,
        speed: enum(u1) {
            Slow,
            Fast,
        },
        padding2: u3 = 1,
    },
    /// What is included on the cartridge.
    cartdridge_type: union(enum) {
        no_coprocessor: NoCoprocessor,
        coprocessor: Coprocessor,

        pub const NoCoprocessor = enum(u8) {
            Rom,
            RomRam,
            RomRamBattery,
        };

        pub const Coprocessor = packed struct(u8) {
            chipset: enum(u4) {
                Rom = 3,
                RomRam,
                RomRamBattery,
                RomBattery,
            },
            coprocessor_type: enum(u4) {
                Dsp,
                SuperFx,
                Obc1,
                Sa1,
                Other,
                Custom,
            },
        };
    },
    /// ROM size is 2^rom_size KB.
    rom_size: u8,
    /// RAM size is 2^ram_size KB. 0 is for none.
    ram_size: u8,
    /// Destination region.
    destination_code: enum(u8) {
        Japan,
        NorthAmerica,
        Europe,
        Scandinavia,
        French,
        Dutch,
        Spanish,
        German,
        Italian,
        Chinese,
        Korean,
        Common,
        Canada,
        Brazil,
        Ngs,
        Australia,
        X,
        Y,
        Z,

        /// Get the game code letter.
        pub fn gameCodeLetter(self: @This()) u8 {
            return switch (self) {
                .Japan => 'J',
                .NorthAmerica => 'E',
                .Europe => 'P',
                .Scandinavia => 'W',
                .French => 'F',
                .Dutch => 'H',
                .Spanish => 'S',
                .German => 'D',
                .Italian => 'I',
                .Chinese => 'C',
                .Korean => 'K',
                .Common => 'A',
                .Canada => 'N',
                .Brazil => 'B',
                .Ngs => 'G',
                .Australia => 'U',
                .X => 'X',
                .Y => 'Y',
                .Z => 'Z',
            };
        }
    },
    /// First production run version.
    version: u8,

    /// Get the checksum. TODO!!!
    fn checksum(self: Header) u16 {
        _ = self;
        return 0;
    }

    /// Write the ROM format.
    pub fn write(self: Header, writer: std.io.AnyWriter) !void {
        try writer.writeAll(&self.maker_code); // 0xFFB0
        if (self.game_code.len > max_game_code_len)
            return error.GameCodeTooLong;
        try writer.writeAll(self.game_code); // 0xFFB2
        try writer.writeByteNTimes(' ', max_game_code_len - self.game_code.len);
        try writer.writeByte(self.destination_code.gameCodeLetter());
        try writer.writeByteNTimes(0, 7); // 0xFFB6
        try writer.writeByte(@intFromEnum(self.expansion_ram_size)); // 0xFFBD
        try writer.writeByte(self.special_version); // 0xFFBE
        try writer.writeByte(self.cartridge_sub_number); // 0xFFBF
        if (self.title.len > max_title_len)
            return error.TitleTooLong;
        try writer.writeAll(self.title); // 0xFFC0
        try writer.writeByteNTimes(' ', max_title_len - self.title.len);
        try writer.writeStruct(self.map_mode); // 0xFFD5
        switch (self.cartdridge_type) {
            .no_coprocessor => |val| try writer.writeByte(@intFromEnum(val)),
            .coprocessor => |val| try writer.writeStruct(val),
        } // 0xFFD6
        try writer.writeByte(self.rom_size); // 0xFFD7
        try writer.writeByte(self.ram_size); // 0xFFD8
        try writer.writeByte(@intFromEnum(self.destination_code)); // 0xFFD9
        try writer.writeByte(0x33); // 0xFFDA
        try writer.writeByte(self.version); // 0xFFDB
        const chksum = self.checksum();
        try writer.writeInt(u16, 0xFFFF - chksum, .little); // 0xFFDC
        try writer.writeInt(u16, chksum, .little); // 0xFFDE
    }
};
