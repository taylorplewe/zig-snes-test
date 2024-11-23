/*
    The ROM lives in 0xC00000 to 0xFFFFFF in memory.
    The "bottom" half (0x8000-0xFFFF across higher addresses (banks) 0xC0-0xFF) is mirrored to banks 0x00-0x3F and 0x80-0xBF.
    The RAM lives in 0x7EFFFF to 0x7FFFFF in memory.
    The 0x7E0000 to 0x7E1FFF region is mirrored for banks 0x00-0x3F and banks 0x80-0xBF.
*/

MEMORY
{
    ROM_PROLOG (rx) : ORIGIN = 0xC00000, LENGTH = 0x007FFF
    ROM_ENTRY (rx)  : ORIGIN = 0xC08000, LENGTH = 0x007FB0
    HEADER (r)      : ORIGIN = 0xC0FFB0, LENGTH = 0x000050
    ROM (rx)        : ORIGIN = 0xC10000, LENGTH = 0x3EFFFF
    RAM (xrw)       : ORIGIN = 0x7E0000, LENGTH = 0x1FFFFF
}

SECTIONS
{
    .prolog : { *(.prolog) }    > ROM_PROLOG
    .entry  : { *(.entry) }     > ROM_ENTRY
    .header : { *(.header) }    > HEADER
    .text   : { *(.text) }      > ROM
}
