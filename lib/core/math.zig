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

pub inline fn radians(degrees_: f32) f32 {
    // return degrees_ * (std.math.pi / 180.0);
    return degrees_ * std.math.rad_per_deg;
}

pub inline fn degrees(radians_: f32) f32 {
    // return radians_ * (180.0 / std.math.pi);
    return radians_ * std.math.deg_per_rad;
}

/// Creates a right-handed perspective projection matrix with depth range [-1, 1] (OpenGL convention)
/// Equivalent to glm::perspective
pub inline fn perspective(
    comptime T: type,
    fovy: T,
    aspect: T,
    near: T,
    far: T,
) Matrix(T, 4, 4) {
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
pub inline fn perspectiveZ(
    comptime T: type,
    fovy: T,
    aspect: T,
    near: T,
    far: T,
) Matrix(T, 4, 4) {
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
pub inline fn ortho(
    comptime T: type,
    left: T,
    right: T,
    bottom: T,
    top: T,
    near: T,
    far: T,
) Matrix(T, 4, 4) {
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
pub inline fn orthoZ(
    comptime T: type,
    left: T,
    right: T,
    bottom: T,
    top: T,
    near: T,
    far: T,
) Matrix(T, 4, 4) {
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
pub inline fn ortho2D(comptime T: type, left: T, right: T, bottom: T, top: T) Matrix(T, 4, 4) {
    return ortho(T, left, right, bottom, top, -1, 1);
}

/// Creates a right-handed view matrix looking from position to target with the given up vector
/// Equivalent to glm::lookAt
pub inline fn lookAt(
    comptime T: type,
    position: Vector(T, 3),
    target: Vector(T, 3),
    up: Vector(T, 3),
) Matrix(T, 4, 4) {
    var d = position.subtracted(target).cc().normalize().*;
    const r = up.crossed(.{d}).cc().normalize().*;
    const u = d.crossed(.{r}).cc().normalize().*;

    var result = Matrix(T, 4, 4).identity();
    result.data2[0][0] = r.data[0];
    result.data2[0][1] = r.data[1];
    result.data2[0][2] = r.data[2];
    result.data2[1][0] = u.data[0];
    result.data2[1][1] = u.data[1];
    result.data2[1][2] = u.data[2];
    result.data2[2][0] = d.data[0];
    result.data2[2][1] = d.data[1];
    result.data2[2][2] = d.data[2];
    result.data2[0][3] = -r.inner(position);
    result.data2[1][3] = -u.inner(position);
    result.data2[2][3] = -d.inner(position);

    return result;
}
