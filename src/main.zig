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
        const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });

        var sum: f32 = 0.0;
        for (0..iterations) |i| {
            const v2 = Vec(f32, 3).initS(@floatFromInt(i % 128));
            const v3 = v1.subV(v2);
            sum += @reduce(.Add, @as(@Vector(3, f32), v3.data));
        }
        const end = std.time.milliTimestamp();
        std.debug.print("subV: {d}, sum: {d}\n", .{ end - start, sum });
    }

    {
        const start = std.time.milliTimestamp();
        const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });

        var sum: f32 = 0.0;
        for (0..iterations) |i| {
            const v2 = Vec(f32, 3).initS(@floatFromInt(i % 128));
            const v3 = v1.sub(v2);
            sum += @reduce(.Add, @as(@Vector(3, f32), v3.data));
        }
        const end = std.time.milliTimestamp();
        std.debug.print("sub: {d}, sum: {d}\n", .{ end - start, sum });
    }

    {
        const start = std.time.milliTimestamp();
        const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });

        var sum: f32 = 0.0;
        for (0..iterations) |i| {
            const v3 = v1.subA(@as([3]f32, @splat(@floatFromInt(i % 128))));
            sum += @reduce(.Add, @as(@Vector(3, f32), v3.data));
        }
        const end = std.time.milliTimestamp();
        std.debug.print("subA: {d}, sum: {d}\n", .{ end - start, sum });
    }

    {
        const start = std.time.milliTimestamp();
        const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });

        var sum: f32 = 0.0;
        for (0..iterations) |i| {
            const v3 = v1.sub(@as([3]f32, @splat(@floatFromInt(i % 128))));
            sum += @reduce(.Add, @as(@Vector(3, f32), v3.data));
        }
        const end = std.time.milliTimestamp();
        std.debug.print("sub: {d}, sum: {d}\n", .{ end - start, sum });
    }

    {
        const start = std.time.milliTimestamp();
        const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });

        var sum: f32 = 0.0;
        for (0..iterations) |i| {
            const v3 = v1.subS(@floatFromInt(i % 128));
            sum += @reduce(.Add, @as(@Vector(3, f32), v3.data));
        }
        const end = std.time.milliTimestamp();
        std.debug.print("subS: {d}, sum: {d}\n", .{ end - start, sum });
    }

    {
        const start = std.time.milliTimestamp();
        const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });

        var sum: f32 = 0.0;
        for (0..iterations) |i| {
            const v3 = v1.sub(@as(f32, @floatFromInt(i % 128)));
            sum += @reduce(.Add, @as(@Vector(3, f32), v3.data));
        }
        const end = std.time.milliTimestamp();
        std.debug.print("sub: {d}, sum: {d}\n", .{ end - start, sum });
    }
    // {
    //     const start = std.time.milliTimestamp();
    //     const v1 = Vec3(f32).initA(.{ 1.0, 2.0, 3.0 });
    //
    //     var sum: f32 = 0.0;
    //     for (0..iterations) |i| {
    //         const v2 = Vec3(f32).initS(@floatFromInt(i % 128));
    //         // const v3 = v1.cross(v2);
    //         const v3 = v1.as().subV(v2.as().*);
    //         sum += @reduce(.Add, @as(@Vector(3, f32), v3.as().data));
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

const Vec = qp.math.Vec;
const Vec3 = qp.math.Vec3;
