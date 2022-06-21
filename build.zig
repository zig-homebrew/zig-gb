const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils.zig");

const emulator = "vbam";

pub fn build(b: *std.build.Builder) !void {
    b.build_root = try utils.root(b.build_root);
    try utils.ensure_tar(
        b.allocator,
        b.build_root,
        "gbdk",
        "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.0.6/gbdk-linux64.tar.gz",
    );
    const folder = try std.fs.openDirAbsolute(b.build_root, .{});
    folder.makeDir("zig-out") catch {};

    const obj = b.addSystemCommand(&.{
        "../gbdk/bin/lcc",
        "-Wa-l",
        "-DUSE_SFR_FOR_REG",
        "-c",
        "-o",
        "main.o",
        "../src/main.c",
    });
    obj.cwd = "zig-out";

    const gb = b.addSystemCommand(&.{
        "../gbdk/bin/lcc", "-Wa-l", "-DUSE_SFR_FOR_REG", "-o", "main.gb", "main.o",
    });
    gb.cwd = "zig-out";

    b.default_step.dependOn(&gb.step);
    gb.step.dependOn(&obj.step);

    const run_step = b.step("run", "Run in Visual Boy Advance");
    const vbam = b.addSystemCommand(&.{ emulator, "-F", "zig-out/main.gb" });
    run_step.dependOn(&gb.step);
    run_step.dependOn(&vbam.step);
}
