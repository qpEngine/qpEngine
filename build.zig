const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const build_editor = b.option(bool, "editor", "Build the editor") orelse false;

    // qpEngine Library
    const qp_lib = b.addModule("qpEngine", .{
        .root_source_file = b.path("lib/qp.zig"),
        .target = target,
        .optimize = optimize,
    });

    // PCRE2 Regex Library
    const pcrez_lib = b.dependency("pcrez", .{
        .target = target,
        .optimize = optimize,
    });

    // apEngine Editor
    if (build_editor) {
        const exe_mod = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe_mod.addImport("qp", qp_lib);

        exe_mod.addImport("pcrez", pcrez_lib.module("pcrez"));

        const zopengl = b.dependency("zopengl", .{});
        exe_mod.addImport("zopengl", zopengl.module("root"));

        const zglfw = b.dependency("zglfw", .{});
        exe_mod.addImport("zglfw", zglfw.module("root"));

        const zsdl = b.dependency("zsdl", .{});
        exe_mod.addImport("zsdl2", zsdl.module("zsdl2"));
        exe_mod.addImport("zsdl2_ttf", zsdl.module("zsdl2_ttf"));
        exe_mod.addImport("zsdl2_image", zsdl.module("zsdl2_image"));

        const zstbi = b.dependency("zstbi", .{});
        exe_mod.addImport("zstbi", zstbi.module("root"));

        const zgui = b.dependency("zgui", .{});
        exe_mod.addImport("zgui", zgui.module("root"));

        const exe = b.addExecutable(.{
            .name = "qpEngine",
            .root_module = exe_mod,
        });

        if (target.result.os.tag != .emscripten) {
            exe.linkLibrary(zglfw.artifact("glfw"));
        }

        b.installArtifact(exe);

        // run step
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    // testing step
    const vec_lib_unit_test = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("lib/core/math/vector.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_vec_unit_tests = b.addRunArtifact(vec_lib_unit_test);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_vec_unit_tests.step);
}
