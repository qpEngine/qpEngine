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

    const iterations = 10_000_000_000;
    {
        const start = std.time.milliTimestamp();
        var sum: f32 = 0.0;
        const v2 = Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 });
        for (0..iterations) |i| {
            var v1 = Vector(f32, 3).from(.{ i % 2 + 1, i % 3 + 1, i % 5 + 1 });
            // v1 = v1.normalized().?;
            v1 = v1.summated(v2);
            sum += @reduce(.Add, v1.as());
        }

        const end = std.time.milliTimestamp();
        std.debug.print("op  - time: {d}, sum: {d}\n", .{ end - start, sum });
    }
    {
        const start = std.time.milliTimestamp();
        var sum: f32 = 0.0;
        const v2 = Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 });
        for (0..iterations) |i| {
            var v1 = Vector(f32, 3).from(.{ i % 2 + 1, i % 3 + 1, i % 5 + 1 });
            // try v1.normalize();
            v1 = v1.summated2(v2);
            sum += @reduce(.Add, v1.as());
        }

        const end = std.time.milliTimestamp();
        std.debug.print("op2 - time: {d}, sum: {d}\n", .{ end - start, sum });
    }
    // {
    //     const start = std.time.milliTimestamp();
    //     const v1 = Vector4(f32).initA(.{ 1.0, 2.0, 3.0, 4.0 });
    //
    //     var sum: f32 = 0.0;
    //     for (0..iterations) |i| {
    //         const v2 = Vector4(f32).initS(@floatFromInt(i % 128));
    //         // const v3 = v1.cross(v2);
    //         const v3 = try v2.as().div(v1.as());
    //         sum += @reduce(.Add, v3.as());
    //     }
    //     const end = std.time.milliTimestamp();
    //     std.debug.print("qpEngine: {d}, sum: {d}\n", .{ end - start, sum });
    // }

    std.debug.print("qpEngine: \n", .{});
}

const std = @import("std");
const qp = @import("qp");

const Allocator = std.mem.Allocator;
const Regex = qp.util.Regex;
const RegexMatch = qp.util.RegexMatch;
const tests = std.testing;

const Vector = qp.math.Vector;
const Vector3 = qp.math.Vector3;
const Vector4 = qp.math.Vector4;
