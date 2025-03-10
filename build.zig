const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const regex_mod = b.createModule(.{
        .root_source_file = b.path("src/qp/regex/regex.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("regex", regex_mod);

    const exe = b.addExecutable(.{
        .name = "qpEngine",
        .root_module = exe_mod,
    });

    const pcre2_8_dep = b.dependency("pcre2", .{
        .target = target,
        .optimize = optimize,
    });
    regex_mod.linkLibrary(pcre2_8_dep.artifact("pcre2-8"));
    exe.linkLibrary(pcre2_8_dep.artifact("pcre2-8"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // TESTING
    const regex_lib_unit_test = b.addTest(.{
        .root_module = regex_mod,
    });
    const run_lib_unit_tests = b.addRunArtifact(regex_lib_unit_test);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
