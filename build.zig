const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const build_editor = b.option(bool, "editor", "Build the editor") orelse false;

    // PCRE2 Regex Library
    const pcre2_8_dep = b.dependency("pcre2", .{
        .target = target,
        .optimize = optimize,
    });

    // qpEngine Library
    const qp_lib = b.addModule("qpEngine", .{
        .root_source_file = b.path("lib/qp/qp.zig"),
        .target = target,
        .optimize = optimize,
    });
    qp_lib.linkLibrary(pcre2_8_dep.artifact("pcre2-8"));

    // apEngine Editor
    if (build_editor) {
        const exe_mod = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe_mod.addImport("qp", qp_lib);

        const exe = b.addExecutable(.{
            .name = "qpEngine",
            .root_module = exe_mod,
        });
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
    const regex_lib_unit_test = b.addTest(.{
        .root_source_file = b.path("lib/qp/util/regex.zig"),
        // .root_module = regex_mod,
    });
    regex_lib_unit_test.linkLibrary(pcre2_8_dep.artifact("pcre2-8"));
    const run_regex_unit_tests = b.addRunArtifact(regex_lib_unit_test);

    const vec_lib_unit_test = b.addTest(.{
        .root_source_file = b.path("lib/qp/math/vec.zig"),
        // .root_module = regex_mod,
    });
    const run_vec_unit_tests = b.addRunArtifact(vec_lib_unit_test);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_regex_unit_tests.step);
    test_step.dependOn(&run_vec_unit_tests.step);
}
