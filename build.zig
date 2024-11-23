const std = @import("std");
const rom = @import("rom.zig");

const PatchHeaderStep = struct {
    step: std.Build.Step,
    bin_path: []const u8,
    header: rom.Header,

    pub fn create(b: *std.Build, bin_path: []const u8, header: rom.Header) *PatchHeaderStep {
        const patch_header = b.allocator.create(PatchHeaderStep) catch @panic("OOM");
        patch_header.* = .{
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = "patch header",
                .makeFn = make,
                .owner = b,
            }),
            .bin_path = bin_path,
            .header = header,
        };
        return patch_header;
    }

    pub fn make(step: *std.Build.Step, node: *std.Progress.Node) anyerror!void {
        _ = node;
        const self: *PatchHeaderStep = @fieldParentPtr("step", step);
        const file = try std.fs.openFileAbsolute(step.owner.getInstallPath(.{ .bin = {} }, self.bin_path), .{ .mode = .write_only });
        defer file.close();
        try file.seekTo(0xFFB0);
        const header_writer = file.writer().any();
        try self.header.write(header_writer);
        step.result_cached = false;
    }
};

// Let's make an SNES game!
pub fn build(b: *std.Build) !void {

    // 65c816 setup.
    const target = b.resolveTargetQuery(.{
        .abi = .eabi,
        .cpu_arch = .mos,
        .cpu_features_add = std.Target.mos.featureSet(&[_]std.Target.mos.Feature{
            .mos_insns_6502,
            .mos_insns_6502bcd,
            .mos_insns_65c02,
            .mos_insns_w65816,
            .mos_insns_w65c02,
            .mosw65816,
            .static_stack,
        }),
        .cpu_model = .{ .explicit = &std.Target.mos.cpu.mosw65816 },
        .dynamic_linker = std.Target.DynamicLinker.none,
        .os_tag = .freestanding,
    });

    // Small optimizations produce the best code.
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall });

    // Exe status.
    const exe = b.addExecutable(.{
        .name = "hello-snes",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.bundle_compiler_rt = false;
    exe.linker_script = b.path("linkerscripts/snes.ld");
    const installed_exe = b.addInstallArtifact(exe, .{});
    installed_exe.step.dependOn(&exe.step);

    // Export binary.
    const objcopy = b.addObjCopy(installed_exe.emitted_bin.?, .{
        .format = .bin,
        .strip = .none,
    });
    objcopy.step.dependOn(&installed_exe.step);
    const bin = b.addInstallBinFile(objcopy.getOutput(), "hello-snes.sfc");
    bin.step.dependOn(&objcopy.step);

    // Generate header.
    const header = rom.Header{
        .cartdridge_type = .{ .no_coprocessor = .Rom },
        .destination_code = .NorthAmerica,
        .expansion_ram_size = .None,
        .game_code = "TST",
        .maker_code = [_]u8{ '0', '0' },
        .map_mode = .{ .ex_hi_rom = false, .mapping_model = .HiRom, .speed = .Slow },
        .ram_size = 0,
        .rom_size = 8,
        .title = "ZIG SNES DEMO",
        .version = 0,
    };
    const header_step = PatchHeaderStep.create(b, bin.dest_rel_path, header);
    header_step.step.dependOn(&bin.step);
    b.default_step.dependOn(&header_step.step);
}
