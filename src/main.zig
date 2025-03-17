//
//
//
//
//
//    I. qpEngine
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
//    II. Copyright (c) 2025-present Rocco Ruscitti
//
//    III. License
//    This software is not yet licensed and is not available for use or distribution.
//
//
//
//
//

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(gpa.deinit() != .leak);
    // const allocator = gpa.allocator();

    // const v2 = Vec(f32, 3).init([3]f32{ 4.0, 5.0, 6.0 });
    // const outer = v1.outer1d(v2);

    // {
    //     const start = std.time.milliTimestamp();
    //     var sum: f64 = 0.0;
    //
    //     const v1 = Vec3(f32).init(.{ 1.0, 2.0, 3.0 });
    //     for (0..1_000_000_000) |i| {
    //         const v2 = Vec3(f32).from(Vec(f32, 3).initS(@floatFromInt(i % 1092)));
    //         const v3 = v1.crossExp(v2);
    //         if (i % 2 == 0) {
    //             sum += @reduce(.Add, @as(@Vector(3, f32), v3.as().data));
    //         } else {
    //             const vm: @Vector(3, f32) = @splat(-1.0);
    //             const v4 = @as(@Vector(3, f32), v3.as().data) * vm;
    //             sum += @reduce(.Add, v4);
    //         }
    //     }
    //
    //     const end = std.time.milliTimestamp();
    //     std.debug.print("crossExp Time: {}, sum {}\n", .{ end - start, sum });
    // }
    {
        const start = std.time.milliTimestamp();
        var sum: f64 = 0.0;

        const v1 = Vec3(f32).init(.{ 1.0, 2.0, 3.0 });
        for (0..1_000_000_000) |i| {
            const v2 = Vec3(f32).from(Vec(f32, 3).initS(@floatFromInt(i % 1092)));
            const v3 = v1.crossComp(v2);
            if (i % 2 == 0) {
                sum += @reduce(.Add, @as(@Vector(3, f32), v3.as().data));
            } else {
                const vm: @Vector(3, f32) = @splat(-1.0);
                const v4 = @as(@Vector(3, f32), v3.as().data) * vm;
                sum += @reduce(.Add, v4);
            }
        }

        const end = std.time.milliTimestamp();
        std.debug.print("crossComp Time: {}, sum {}\n", .{ end - start, sum });
    }
    {
        const start = std.time.milliTimestamp();
        var sum: f64 = 0.0;

        var v1 = Vec3(f32).init(.{ 1.0, 2.0, 3.0 });
        for (0..1_000_000_000) |i| {
            var v2 = Vec3(f32).from(Vec(f32, 3).initS(@floatFromInt(i % 1092)));
            const v3 = v1.crossSimdSmall(&v2);
            if (i % 2 == 0) {
                sum += @reduce(.Add, @as(@Vector(3, f32), v3.as().data));
            } else {
                const vm: @Vector(3, f32) = @splat(-1.0);
                const v4 = @as(@Vector(3, f32), v3.as().data) * vm;
                sum += @reduce(.Add, v4);
            }
        }

        const end = std.time.milliTimestamp();
        std.debug.print("SimdSmall Time: {}, sum {}\n", .{ end - start, sum });
    }
    // {
    //     const start = std.time.milliTimestamp();
    //     var sum: f64 = 0.0;
    //
    //     const v1 = Vec3(f32).init(.{ 1.0, 2.0, 3.0 });
    //     for (0..1_000_000_000) |i| {
    //         const v2 = Vec3(f32).from(Vec(f32, 3).initS(@floatFromInt(i % 1092)));
    //         const v3 = v1.crossSimdLarge(v2);
    //         if (i % 2 == 0) {
    //             sum += @reduce(.Add, @as(@Vector(3, f32), v3.as().data));
    //         } else {
    //             const vm: @Vector(3, f32) = @splat(-1.0);
    //             const v4 = @as(@Vector(3, f32), v3.as().data) * vm;
    //             sum += @reduce(.Add, v4);
    //         }
    //     }
    //
    //     const end = std.time.milliTimestamp();
    //     std.debug.print("SimdLarge Time: {}, sum {}\n", .{ end - start, sum });
    // }

    std.debug.print("qpEngine: \n", .{});
}

const std = @import("std");
const qp = @import("qp");

const Allocator = std.mem.Allocator;
const Regex = qp.util.Regex;
const RegexMatch = qp.util.RegexMatch;
const tests = std.testing;

const Vec = qp.math.Vec;
const Vec3 = qp.math.Vec3;
