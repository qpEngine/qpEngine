//
//
//
//
//
//    I. qpEngine
//
//                                                         ,,
//                      `7MM"""YMM                         db
//                        MM    `7
//      ,dW"Yvd`7MMpdMAo. MM   d    `7MMpMMMb.  .P"Ybmmm `7MM  `7MMpMMMb.  .gP"Ya
//     ,W'   MM  MM   `Wb MMmmMM      MM    MM :MI  I8     MM    MM    MM ,M'   Yb
//     8M    MM  MM    M8 MM   Y  ,   MM    MM  WmmmP"     MM    MM    MM 8M""""""
//     YA.   MM  MM   ,AP MM     ,M   MM    MM 8M          MM    MM    MM YM.    ,
//      'MbmdMM  MMbmmd'.JMMmmmmMMM .JMML  JMML.YMMMMMb  .JMML..JMML  JMML.`Mbmmd'
//           MM  MM                            6'     dP
//         .JMMLJMML.                          YbmmmdY'
//
//
//
//    II. Copyright (c) 2025-present Rocco Ruscitti
//
//    III. License
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//
//
//
//
//

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

    const zmath = b.dependency("zmath", .{
        .target = target,
        .optimize = optimize,
    });
    qp_lib.addImport("zmath", zmath.module("root"));

    const zmesh = b.dependency("zmesh", .{
        .target = target,
        .optimize = optimize,
    });
    qp_lib.addImport("zmesh", zmesh.module("root"));

    // PCRE2 Regex Library
    const pcrez_lib = b.dependency("pcrez", .{
        .target = target,
        .optimize = optimize,
    });
    qp_lib.addImport("pcrez", pcrez_lib.module("pcrez"));

    // apEngine Editor
    if (build_editor) {
        const exe_mod = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe_mod.addImport("qp", qp_lib);

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
        exe.linkLibrary(zmesh.artifact("zmesh"));

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
            .root_source_file = b.path("lib/qp.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_vec_unit_tests = b.addRunArtifact(vec_lib_unit_test);
    vec_lib_unit_test.root_module.addImport("zmath", zmath.module("root"));

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_vec_unit_tests.step);
}
