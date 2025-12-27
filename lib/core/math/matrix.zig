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

/// Creates a Matrix type of size MxN (M rows, N columns) with element type T
/// For square matrices, M == N
/// Row-major storage order
pub fn Matrix(
    comptime T: type,
    comptime M: u16, // rows
    comptime N: u16, // columns
) type {
    switch (@typeInfo(T)) {
        .float => {},
        else => @compileError("Matrix element type must be Real (float)"),
    }

    return extern union {
        simd1: @Vector(M * N, T),
        simd2: [M]@Vector(N, T),
        data1: [M * N]T,
        data2: [M][N]T,
        root: [*]T,

        // zig fmt: off
        const Self = @This();
        const RowVec = Vector(T, N);           // Row vector type
        const ColVec = Vector(T, M);           // Column vector type
        const Transpose = Matrix(T, N, M);     // Transposed matrix type
        const R = f32;                         // Alternate scalar return type
        const V = @Vector(N, T);               // SIMD row vector
        const B = @Vector(N, bool);            // Boolean SIMD vector
        const rows: u16 = M;                   // Number of rows
        const cols: u16 = N;                   // Number of columns
        const isSquare: bool = M == N;         // Is square matrix
        const isInt: bool = @typeInfo(T) == .int;
        // zig fmt: on

        pub const MError = error{
            DivideByZero,
            SingularMatrix,
            DimensionMismatch,
        };

        inline fn scalar(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) R else T;
        }

        inline fn comp(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) comptime_int else comptime_float;
        }

        /// Default initialization
        /// Matrix data is set to undefined
        ///
        /// < Self: A new Matrix
        pub inline fn init() Self {
            return .{ .data = undefined };
        }

        fn scalarFrom(comptime VT: type, value: VT) T {
            return switch (@typeInfo(VT)) {
                .int, .comptime_int => @floatFromInt(value),
                .float, .comptime_float => @floatCast(value),
                else => value,
            };
        }

        /// Initialize all elements to a single value
        pub inline fn from(value_: anytype) Self {
            var result: Self = undefined;
            const v = scalarFrom(@TypeOf(value_), value_);
            inline for (0..M) |m| {
                result.data2[m] = [_]T{v} ** N;
            }
            return result;
        }

        /// Initialize from 2D array
        pub inline fn fromArray(arr: [M][N]T) Self {
            return .{ .data2 = arr };
        }
        /// Initialize from flat array (row-major)
        pub inline fn fromFlat(arr: [M * N]T) Self {
            return .{ .data1 = arr };
        }

        /// Initialize from row vectors
        pub inline fn fromRows(rows_: [M]RowVec) Self {
            var result: Self = undefined;
            inline for (0..M) |m| {
                result.data2[m] = rows_[m].data;
            }
            return result;
        }

        /// Initialize from column vectors
        pub inline fn fromCols(cols_: [N]ColVec) Self {
            var result: Self = undefined;
            inline for (0..M) |m| {
                inline for (0..N) |n| {
                    result.data2[m][n] = cols_[n].data[m];
                }
            }
            return result;
        }

        /// Identity matrix (only for square matrices)
        pub inline fn identity() Self {
            if (comptime !isSquare) @compileError("Identity matrix requires square matrix");
            var result = Self.from(0);
            inline for (0..M) |m| {
                result.data2[m][m] = 1.0;
            }
            return result;
        }

        /// Zero matrix
        pub inline fn zero() Self {
            return Self.from(0);
        }

        /// Create translation matrix (4x4 only)
        pub fn translation(other_: Vector(T, N - 1)) Self {
            if (comptime !isSquare) @compileError("Translation requires square matrix");
            var result = Self.identity();
            inline for (0..M - 1) |m| {
                result.data2[m][N - 1] = other_.data[m];
            }
            return result;
        }

        pub fn translate(self: *Self, other_: Vector(T, N - 1)) *Self {
            return self.multiplySq(Self.translation(other_));
        }

        /// Create scaling matrix (4x4 only, or any square matrix)
        pub fn scaling(factors: Vector(T, N - 1)) Self {
            if (comptime !isSquare) @compileError("Scaling requires square matrix");
            var result = Self.identity();
            inline for (0..M - 1) |m| {
                result.data2[m][m] = factors.data[m];
            }
            return result;
        }

        pub fn scale(self: *Self, factors_: Vector(T, N - 1)) *Self {
            return self.multiplySq(Self.scaling(factors_));
        }

        /// Matrix multiplication: Self (MxN) * Other (NxP) = Result (MxP)
        // pub inline fn mul(self: *const Self, other_: anytype) Matrix(T, M, getOtherCols(@TypeOf(other_))) {
        //     const P = comptime getOtherCols(@TypeOf(other_));
        //     const Other = Matrix(T, N, P);
        //     const Result = Matrix(T, M, P);
        //
        //     const other: Other = if (@TypeOf(other_) == Other) other_ else Other.fromAny(other_);
        //     var result: Result = undefined;
        //
        //     for (0..M) |m| {
        //         for (0..P) |p| {
        //             var sum: T = 0;
        //             inline for (0..N) |n| {
        //                 sum += self.data[m][n] * other.data[n][p];
        //             }
        //             result.data2[m][p] = sum;
        //         }
        //     }
        //     return result;
        // }

        pub inline fn multiplySq(self: *Self, other: Self) *Self {
            if (comptime !isSquare) @compileError("Matrix multiplication requires square matrices");
            var result: Self = undefined;

            for (0..M) |m| {
                for (0..N) |n| {
                    var sum: T = 0;
                    inline for (0..N) |l| {
                        sum += self.data2[m][l] * other.data2[l][n];
                    }
                    result.data2[m][n] = sum;
                }
            }
            self.data2 = result.data2;
            return self;
        }

        /// Matrix-vector multiplication: Matrix (MxN) * Vector (N) = Vector (M)
        pub inline fn multiplyVec(self: *const Self, vec: RowVec) ColVec {
            var result: [M]T = undefined;
            for (0..M) |m| {
                const row_vec: V = self.simd2[m];
                const v: V = vec.simd;
                result[m] = @reduce(.Add, row_vec * v);
            }
            return ColVec.from(result);
        }

        pub const rotation = switch (M) {
            2 => struct {
                pub inline fn rotation(angle_rad: f32) Self {
                    if (comptime !isSquare) @compileError("Rotation matrix requires square matrix");
                    var result = Self.init();
                    const c = @cos(angle_rad);
                    const s = @sin(angle_rad);
                    result.data2[0][0] = @as(T, c);
                    result.data2[0][1] = @as(T, -s);
                    result.data2[1][0] = @as(T, s);
                    result.data2[1][1] = @as(T, c);
                    return result;
                }
            }.rotation,
            3, 4 => struct {
                inline fn rotation(angle_rad_: f32, axis_: Vector(T, 3)) Self {
                    if (comptime !isSquare) @compileError("Rotation matrix requires square matrix");
                    std.debug.assert(axis_.isNormalized());
                    var result = Self.identity();
                    const c = @cos(angle_rad_);
                    const s = @sin(angle_rad_);
                    const t = 1.0 - c;
                    const x = axis_.data[0];
                    const y = axis_.data[1];
                    const z = axis_.data[2];

                    result.data2[0][0] = t * x * x + c;
                    result.data2[0][1] = t * x * y - z * s;
                    result.data2[0][2] = t * x * z + y * s;
                    result.data2[1][0] = t * x * y + z * s;
                    result.data2[1][1] = t * y * y + c;
                    result.data2[1][2] = t * z * y - x * s;
                    result.data2[2][0] = t * z * x - y * s;
                    result.data2[2][1] = t * z * y + x * s;
                    result.data2[2][2] = t * z * z + c;
                    return result;
                }
            }.rotation,
            else => @compileError("Rotation matrix not implemented for this size"),
        };

        pub const rotate = switch (M) {
            2 => struct {
                pub inline fn rotate(self: *Self, angle_rad_: f32) *Self {
                    const rot_mat = Self.rotation(angle_rad_);
                    return self.multiplySq(rot_mat);
                }
            }.rotate,
            3, 4 => struct {
                pub inline fn rotate(self: *Self, angle_rad_: f32, axis_: Vector(T, 3)) *Self {
                    const rot_mat = Self.rotation(angle_rad_, axis_);
                    return self.multiplySq(rot_mat);
                }
            }.rotate,
            else => @compileError("Rotate not implemented for this size"),
        };
    };
}

const std = @import("std");
const testing = std.testing;
const math = std.math;
const Vector = @import("vector.zig").Vector;

// Common types for testing
const Mat4 = Matrix(f32, 4, 4);
const Mat3 = Matrix(f32, 3, 3);
const Mat2 = Matrix(f32, 2, 2);
