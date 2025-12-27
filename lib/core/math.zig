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
pub const Vector = @import("math/vector.zig").Vector;
pub const Matrix = @import("math/matrix.zig").Matrix;

pub fn radians(degrees_: f32) f32 {
    return degrees_ * (std.math.pi / 180.0);
}

pub fn degrees(radians_: f32) f32 {
    return radians_ * (180.0 / std.math.pi);
}

/// Creates a right-handed perspective projection matrix with depth range [-1, 1] (OpenGL convention)
/// Equivalent to glm::perspective
pub fn perspective(comptime T: type, fovy: T, aspect: T, near: T, far: T) Matrix(T, 4, 4) {
    const tan_half_fovy = @tan(fovy / 2);

    var result = Matrix(T, 4, 4).zero();
    result.data2[0][0] = 1 / (aspect * tan_half_fovy);
    result.data2[1][1] = 1 / tan_half_fovy;
    result.data2[2][2] = -(far + near) / (far - near);
    result.data2[2][3] = -(2 * far * near) / (far - near);
    result.data2[3][2] = -1;

    return result;
}

/// Creates a right-handed perspective projection matrix with depth range [0, 1] (Vulkan/DirectX convention)
/// Equivalent to glm::perspectiveZO (with GLM_DEPTH_ZERO_TO_ONE)
pub fn perspectiveZ(comptime T: type, fovy: T, aspect: T, near: T, far: T) Matrix(T, 4, 4) {
    const tan_half_fovy = @tan(fovy / 2);

    var result = Matrix(T, 4, 4).zero();
    result.data2[0][0] = 1 / (aspect * tan_half_fovy);
    result.data2[1][1] = 1 / tan_half_fovy;
    result.data2[2][2] = far / (near - far);
    result.data2[2][3] = -(far * near) / (far - near);
    result.data2[3][2] = -1;

    return result;
}

/// Creates a right-handed orthographic projection matrix with depth range [-1, 1] (OpenGL convention)
/// Equivalent to glm::ortho
pub fn ortho(comptime T: type, left: T, right: T, bottom: T, top: T, near: T, far: T) Matrix(T, 4, 4) {
    var result = Matrix(T, 4, 4).identity();
    result.data2[0][0] = 2 / (right - left);
    result.data2[1][1] = 2 / (top - bottom);
    result.data2[2][2] = -2 / (far - near);
    result.data2[0][3] = -(right + left) / (right - left);
    result.data2[1][3] = -(top + bottom) / (top - bottom);
    result.data2[2][3] = -(far + near) / (far - near);

    return result;
}

/// Creates a right-handed orthographic projection matrix with depth range [0, 1] (Vulkan/DirectX convention)
/// Equivalent to glm::orthoZO (with GLM_DEPTH_ZERO_TO_ONE)
pub fn orthoZ(comptime T: type, left: T, right: T, bottom: T, top: T, near: T, far: T) Matrix(T, 4, 4) {
    var result = Matrix(T, 4, 4).identity();
    result.data2[0][0] = 2 / (right - left);
    result.data2[1][1] = 2 / (top - bottom);
    result.data2[2][2] = -1 / (far - near);
    result.data2[0][3] = -(right + left) / (right - left);
    result.data2[1][3] = -(top + bottom) / (top - bottom);
    result.data2[2][3] = -near / (far - near);

    return result;
}

/// Creates a 2D orthographic projection matrix (no near/far planes)
/// Equivalent to glm::ortho (2D version)
pub fn ortho2D(comptime T: type, left: T, right: T, bottom: T, top: T) Matrix(T, 4, 4) {
    return ortho(T, left, right, bottom, top, -1, 1);
}

// const testing = @import("std").testing;
// const std = @import("std");
// const v32 = @import("zmath").f32x4;
// const normalize = @import("zmath").normalize4;
// const length4 = @import("zmath").length4;
// test "math lib" {
//     const loops = 10_000_000;
//
//     {
//         const start = @import("std").time.nanoTimestamp();
//         var accum: f32 = 0.0;
//         for (0..loops) |i| {
//             var v1 = Vector(f32, 4).from(i);
//             const v2 = Vector(f32, 4).from(2);
//             accum += v1.interpolate(v2, 0.5).data[0];
//         }
//         const end = @import("std").time.nanoTimestamp();
//         std.debug.print("part 1 took {D}: {d}\n", .{ @as(i64, @intCast(end - start)), accum });
//     }
// {
//     const start = @import("std").time.nanoTimestamp();
//     // var v1 = v32(@as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)));
//     // const v2 = v32(1.0, 1.0, 1.0, 1.0);
//     var accum: f32 = 0.0;
//     for (0..loops) |i| {
//         // for (0..loops) |_| {
//         const v1 = v32(@as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)));
//         const v2 = v32(1.0, 1.0, 1.0, 1.0);
//         accum += normalize(v1 + v2)[0];
//         // accum += length4(v2 - v1)[0];
//     }
//     const end = @import("std").time.nanoTimestamp();
//     std.debug.print("part 2 took {D}: {d}\n", .{ @as(i64, @intCast(end - start)), accum });
// }
// {
//     const start = @import("std").time.nanoTimestamp();
//     // var v1 = Vector(f32, 4).from(@as(@Vector(4, f32), .{ @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)), @as(f32, @floatFromInt(1)) }));
//     // const v2 = Vector(f32, 4).from(@as(@Vector(4, f32), .{ 1.0, 1.0, 1.0, 1.0 }));
//     var accum: f32 = 0.0;
//     for (0..loops) |i| {
//         var v1 = Vector(f32, 4).from(@as(@Vector(4, f32), .{ @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(i)) }));
//         const v2 = Vector(f32, 4).from(@as(@Vector(4, f32), .{ 1.0, 1.0, 1.0, 1.0 }));
//         // v1.simd += v2.simd;
//         // accum += v1.normalize().data[0];
//         accum += v1.summate(v2).normalize().data[0];
//         // accum += v1.distanceTo(v2);
//     }
//     const end = @import("std").time.nanoTimestamp();
//     std.debug.print("part 1 took {D}: {d}\n", .{ @as(i64, @intCast(end - start)), accum });
//     std.debug.print("{f}\n", .{Vector(f32, 3).UNIT.UP});
//     std.debug.print("{f}\n", .{Vector(f32, 2).UNIT.LEFT});
// }
// {
//     const start = @import("std").time.nanoTimestamp();
//     var v1 = Vector4(f32).from(@as(@Vector(4, f32), .{ 1.0, 1.0, 1.0, 1.0 }));
//     const v2 = Vector4(f32).from(@as(@Vector(4, f32), .{ 1.0, 1.0, 1.0, 1.0 }));
//     for (0..loops) |_| {
//         _ = v1.summate(v2.simd()).normalize();
//     }
//     const end = @import("std").time.nanoTimestamp();
//     std.debug.print("part 3 took {D}\n", .{@as(i64, @intCast(end - start))});
// }
// }
