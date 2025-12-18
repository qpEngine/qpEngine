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

pub const Vector = @import("math/vector.zig").Vector;
// pub const Vector2 = @import("math/vector2.zig").Vector2;
// pub const Vector3 = @import("math/vector3.zig").Vector3;
// pub const Vector4 = @import("math/vector4.zig").Vector4;

// const testing = @import("std").testing;
const std = @import("std");
const v32 = @import("zmath").f32x4;
const normalize = @import("zmath").normalize4;
test "math lib" {
    const loops = 10_000_000;

    {
        const start = @import("std").time.nanoTimestamp();
        var v1 = v32(@as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)));
        const v2 = v32(1.0, 1.0, 1.0, 1.0);
        // ror (0..loops) |i| {
        for (0..loops) |_| {
            // var v1 = v32(@as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)));
            // const v2 = v32(1.0, 1.0, 1.0, 1.0);
            v1 = normalize(v1 + v2);
            // v1 = v1 + v2;
        }
        const end = @import("std").time.nanoTimestamp();
        std.debug.print("part 2 took {D}\n", .{@as(i64, @intCast(end - start))});
    }
    {
        const start = @import("std").time.nanoTimestamp();
        var v1 = Vector(f32, 4).from(@as(@Vector(4, f32), .{ @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)) }));
        const v2 = Vector(f32, 4).from(@as(@Vector(4, f32), .{ 1.0, 1.0, 1.0, 1.0 }));
        // var v1 = Vector(f32, 4).vectorFromAny(@as(@Vector(4, f32), .{ @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)) }), 0);
        // const v2 = Vector(f32, 4).vectorFromAny(@as(@Vector(4, f32), .{ 1.0, 1.0, 1.0, 1.0 }), 0);
        // for (0..loops) |i| {
        for (0..loops) |_| {
            // var v1 = Vector(f32, 4).from(@as(@Vector(4, f32), .{ @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)) }));
            // const v2 = Vector(f32, 4).from(@as(@Vector(4, f32), .{ 1.0, 1.0, 1.0, 1.0 }));
            // var v1 = Vector(f32, 4).vectorFromAny(@as(@Vector(4, f32), .{ @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)) }), 0);
            // const v2 = Vector(f32, 4).vectorFromAny(@as(@Vector(4, f32), .{ 1.0, 1.0, 1.0, 1.0 }), 0);
            _ = v1.summate(v2).normalize();
            // _ = v1.summate(v1.summate(v2));
            // v1.data = v1.simd() + v2.simd();
            // v1.data += v1.data + v2.data;
            // _ = v1.normalize();
            // v1 = v1 + v2;
        }
        const end = @import("std").time.nanoTimestamp();
        std.debug.print("part 1 took {D}\n", .{@as(i64, @intCast(end - start))});
    }
    // {
    //     const start = @import("std").time.nanoTimestamp();
    //     for (0..loops) |i| {
    //         var v1 = Vector3(f32).from(i);
    //         const v2 = Vector3(f32).from(1);
    //         _ = v1.summate(v2.simd());
    //     }
    //     const end = @import("std").time.nanoTimestamp();
    //     std.debug.print("part 2 took {D}\n", .{@as(i64, @intCast(end - start))});
    // }
}
