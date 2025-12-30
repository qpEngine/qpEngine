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
        simd2: [M]V,
        data1: [M * N]T,
        data2: [M][N]T,

        // zig fmt: off
        const Self = @This();
        const RowVec = Vector(T, N);           // Row vector type
        const ColVec = Vector(T, M);           // Column vector type
        const Transpose = Matrix(T, N, M);     // Transposed matrix type
        const R = f32;                         // Alternate scalar return type
        const W = @Vector(M * N, T);             // One dimension Matrix SIMD vector 
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

        pub inline fn root(self: *const Self) [*]const T {
            return &self.data1;
        }

        /// Remove const from Vector pointer
        ///
        /// < *Self: Mutable Matrix
        pub inline fn cc(
            self: *const Self,
        ) *Self {
            return @constCast(self);
        }

        /// Default initialization
        /// Matrix data is set to undefined
        ///
        /// < Self: A new Matrix
        pub inline fn init() Self {
            return .{ .data1 = undefined };
        }

        pub inline fn clone(
            self: *const Self,
        ) Self {
            return .{ .data2 = self.data2 };
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
        pub inline fn translation(other_: Vector(T, N - 1)) Self {
            if (comptime !isSquare) @compileError("Translation requires square matrix");
            var result = Self.identity();
            inline for (0..M - 1) |m| {
                result.data2[m][N - 1] = other_.data[m];
            }
            return result;
        }

        pub inline fn translate(self: *Self, other_: Vector(T, N - 1)) *Self {
            return self.multiplySq(Self.translation(other_));
        }

        pub inline fn translated(self: *const Self, other_: Vector(T, N - 1)) Self {
            return self.clone().cc().translate(other_).*;
        }

        /// Create scaling matrix (4x4 only, or any square matrix)
        pub inline fn scaling(factors: Vector(T, N - 1)) Self {
            if (comptime !isSquare) @compileError("Scaling requires square matrix");
            var result = Self.identity();
            inline for (0..M - 1) |m| {
                result.data2[m][m] = factors.data[m];
            }
            return result;
        }

        pub inline fn scale(self: *Self, factors_: Vector(T, N - 1)) *Self {
            return self.multiplySq(Self.scaling(factors_));
        }

        pub inline fn scaled(self: *const Self, factors_: Vector(T, N - 1)) Self {
            return self.clone().cc().scale(factors_).*;
        }

        /// Create rotation matrix
        pub inline fn rotation(
            angle_rad_: f32,
            vectors_: switch (M) {
                2 => void,
                3, 4 => Vector(T, 3),
                else => @compileError("Rotation matrix not implemented for this size"),
            },
        ) Self {
            if (comptime !isSquare) @compileError("Rotation matrix requires square matrix");
            return switch (M) {
                2 => {
                    var result = Self.init();
                    const c = @cos(angle_rad_);
                    const s = @sin(angle_rad_);
                    result.data2[0][0] = @as(T, c);
                    result.data2[0][1] = @as(T, -s);
                    result.data2[1][0] = @as(T, s);
                    result.data2[1][1] = @as(T, c);
                    return result;
                },
                3, 4 => {
                    std.debug.assert(vectors_.isNormalized());
                    var result = Self.identity();
                    const c = @cos(angle_rad_);
                    const s = @sin(angle_rad_);
                    const t = 1.0 - c;
                    const x = vectors_.data[0];
                    const y = vectors_.data[1];
                    const z = vectors_.data[2];

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
                },
                else => {},
            };
        }

        pub inline fn rotate(
            self: *Self,
            angle_rad_: f32,
            axis_: switch (M) {
                2 => void,
                3, 4 => Vector(T, 3),
                else => @compileError("Rotate not implemented for this size"),
            },
        ) *Self {
            return switch (M) {
                2 => {
                    const rot_mat = Self.rotation(angle_rad_);
                    return self.multiplySq(rot_mat);
                },
                3, 4 => {
                    const rot_mat = Self.rotation(angle_rad_, axis_);
                    return self.multiplySq(rot_mat);
                },
                else => {},
            };
        }

        pub inline fn rotated(
            self: *const Self,
            angle_rad_: f32,
            axis_: switch (M) {
                2 => void,
                3, 4 => Vector(T, 3),
                else => @compileError("Rotated not implemented for this size"),
            },
        ) Self {
            return self.clone().cc().rotate(angle_rad_, axis_).*;
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

        pub inline fn multiplySq(self: *Self, other_: Self) *Self {
            if (comptime !isSquare) @compileError("Matrix multiplication requires square matrices");
            var result: Self = undefined;

            if (M < 4) {
                for (0..M) |m| {
                    for (0..N) |n| {
                        var sum: T = 0;
                        inline for (0..N) |l| {
                            sum += self.data2[m][l] * other_.data2[l][n];
                        }
                        result.data2[m][n] = sum;
                    }
                }
            } else {
                const other = other_.transposed();
                for (0..M) |m| {
                    inline for (0..N) |n| {
                        result.data2[m][n] = @reduce(.Add, self.simd2[m] * other.simd2[n]);
                    }
                }
            }
            self.data2 = result.data2;
            return self;
        }

        pub inline fn multipliedSq(self: *const Self, other: Self) Self {
            return self.clone().cc().multiplySq(other).*;
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

        pub inline fn multiplyScalar(self: *Self, scalar_: T) *Self {
            const s_vec: W = @splat(scalar_);
            self.simd1 *= s_vec;
            return self;
        }

        pub inline fn multipliedScalar(self: *const Self, scalar_: T) Self {
            return self.clone().cc().multiplyScalar(scalar_).*;
        }

        pub inline fn transpose(self: *Self) *Self {
            if (comptime !isSquare) @compileError("Matrix transpose requires square matrix");
            self.data2 = self.transposed().data2;
            return self;
        }

        pub inline fn transposed(self: *const Self) Transpose {
            var result: Transpose = undefined;
            inline for (0..M) |m| {
                inline for (0..N) |n| {
                    result.data2[n][m] = self.data2[m][n];
                }
            }
            return result;
        }

        // TODO: Look up SIMD methods for 4x4 matrix inversion from GLM
        pub inline fn inverse(self: *Self) *Self {
            if (comptime !isSquare) @compileError("Matrix inversion requires square matrix");
            if (M == 2) {
                const m = self.data2;
                const det = m[0][0] * m[1][1] - m[0][1] * m[1][0];
                std.debug.assert(det != 0);
                const inv_det = 1.0 / det;
                const result: Self = .{ .data1 = .{
                    m[1][1] * inv_det,
                    -m[0][1] * inv_det,
                    -m[1][0] * inv_det,
                    m[0][0] * inv_det,
                } };
                self.data2 = result.data2;
                return self;
            } else if (M == 3) {
                const m = self.data2;
                const det =
                    m[0][0] * (m[1][1] * m[2][2] - m[2][1] * m[1][2]) -
                    m[0][1] * (m[1][0] * m[2][2] - m[2][0] * m[1][2]) +
                    m[0][2] * (m[1][0] * m[2][1] - m[2][0] * m[1][1]);

                std.debug.assert(@abs(det) > std.math.floatEps(T));

                const inv_det = 1.0 / det;

                const result: Self = .{
                    .data1 = .{
                        // Row 0
                        (m[1][1] * m[2][2] - m[2][1] * m[1][2]) * inv_det,
                        (m[0][2] * m[2][1] - m[0][1] * m[2][2]) * inv_det,
                        (m[0][1] * m[1][2] - m[0][2] * m[1][1]) * inv_det,
                        // Row 1
                        (m[1][2] * m[2][0] - m[1][0] * m[2][2]) * inv_det,
                        (m[0][0] * m[2][2] - m[0][2] * m[2][0]) * inv_det,
                        (m[1][0] * m[0][2] - m[0][0] * m[1][2]) * inv_det,
                        // Row 2
                        (m[1][0] * m[2][1] - m[2][0] * m[1][1]) * inv_det,
                        (m[2][0] * m[0][1] - m[0][0] * m[2][1]) * inv_det,
                        (m[0][0] * m[1][1] - m[1][0] * m[0][1]) * inv_det,
                    },
                };
                self.data2 = result.data2;
                return self;
            } else if (M == 4) { // Calculate inverse of a 4x4 matrix using analytical method
                const m = self.data2;
                // Calculate 2x2 sub-determinants (reused in cofactor calculations)
                const coef00 = m[2][2] * m[3][3] - m[3][2] * m[2][3];
                const coef02 = m[1][2] * m[3][3] - m[3][2] * m[1][3];
                const coef03 = m[1][2] * m[2][3] - m[2][2] * m[1][3];

                const coef04 = m[2][1] * m[3][3] - m[3][1] * m[2][3];
                const coef06 = m[1][1] * m[3][3] - m[3][1] * m[1][3];
                const coef07 = m[1][1] * m[2][3] - m[2][1] * m[1][3];

                const coef08 = m[2][1] * m[3][2] - m[3][1] * m[2][2];
                const coef10 = m[1][1] * m[3][2] - m[3][1] * m[1][2];
                const coef11 = m[1][1] * m[2][2] - m[2][1] * m[1][2];

                const coef12 = m[2][0] * m[3][3] - m[3][0] * m[2][3];
                const coef14 = m[1][0] * m[3][3] - m[3][0] * m[1][3];
                const coef15 = m[1][0] * m[2][3] - m[2][0] * m[1][3];

                const coef16 = m[2][0] * m[3][2] - m[3][0] * m[2][2];
                const coef18 = m[1][0] * m[3][2] - m[3][0] * m[1][2];
                const coef19 = m[1][0] * m[2][2] - m[2][0] * m[1][2];

                const coef20 = m[2][0] * m[3][1] - m[3][0] * m[2][1];
                const coef22 = m[1][0] * m[3][1] - m[3][0] * m[1][1];
                const coef23 = m[1][0] * m[2][1] - m[2][0] * m[1][1];

                const fac0 = V{ coef00, coef00, coef02, coef03 };
                const fac1 = V{ coef04, coef04, coef06, coef07 };
                const fac2 = V{ coef08, coef08, coef10, coef11 };
                const fac3 = V{ coef12, coef12, coef14, coef15 };
                const fac4 = V{ coef16, coef16, coef18, coef19 };
                const fac5 = V{ coef20, coef20, coef22, coef23 };

                const vec0 = V{ m[1][0], m[0][0], m[0][0], m[0][0] };
                const vec1 = V{ m[1][1], m[0][1], m[0][1], m[0][1] };
                const vec2 = V{ m[1][2], m[0][2], m[0][2], m[0][2] };
                const vec3 = V{ m[1][3], m[0][3], m[0][3], m[0][3] };

                const inv0: V = vec1 * fac0 - vec2 * fac1 + vec3 * fac2;
                const inv1: V = vec0 * fac0 - vec2 * fac3 + vec3 * fac4;
                const inv2: V = vec0 * fac1 - vec1 * fac3 + vec3 * fac5;
                const inv3: V = vec0 * fac2 - vec1 * fac4 + vec2 * fac5;

                const sign_a = V{ 1.0, -1.0, 1.0, -1.0 };
                const sign_b = V{ -1.0, 1.0, -1.0, 1.0 };

                var result: Self = .{
                    .simd2 = .{
                        inv0 * sign_a,
                        inv1 * sign_b,
                        inv2 * sign_a,
                        inv3 * sign_b,
                    },
                };

                const col0 = V{ result.data2[0][0], result.data2[1][0], result.data2[2][0], result.data2[3][0] };
                const det = @reduce(.Add, self.simd2[0] * col0);
                std.debug.assert(@abs(det) > std.math.floatEps(T));

                const inv_det = 1.0 / det;
                _ = result.multiplyScalar(inv_det);

                self.data2 = result.data2;
                return self;
            } else {
                @compileError("Matrix inversion not implemented for size greater than 4x4");
            }
        }

        pub inline fn inversed(self: *const Self) Self {
            return self.clone().cc().inverse().*;
        }
    };
}

// TESTING:
test "Non-sqare Matrix transpose: dimensions swap correctly" {
    const Mat3x2 = Matrix(f32, 3, 2);
    const Mat2x3 = Matrix(f32, 2, 3);

    var m = Mat3x2{
        .data2 = .{
            .{ 1, 2 },
            .{ 3, 4 },
            .{ 5, 6 },
        },
    };

    const n = Mat2x3{
        .data2 = .{
            .{ 1, 3, 5 },
            .{ 2, 4, 6 },
        },
    };

    const mt = m.transposed();
    const mtt = mt.transposed();

    try testing.expectEqual(@as(u16, 2), @TypeOf(mt).rows);
    try testing.expectEqual(@as(u16, 3), @TypeOf(mt).cols);
    try testing.expectEqual(n.data2, mt.data2);
    try testing.expectEqual(@as(u16, 3), @TypeOf(mtt).rows);
    try testing.expectEqual(@as(u16, 2), @TypeOf(mtt).cols);
    try testing.expectEqual(m.data2, mtt.data2);
}

test "Square Matrix transpose" {
    const Mat3x3 = Matrix(f32, 3, 3);

    var m = Mat3x3{
        .data2 = .{
            .{ 1, 2, 3 },
            .{ 4, 5, 6 },
            .{ 7, 8, 9 },
        },
    };

    const n = Mat3x3{
        .data2 = .{
            .{ 1, 4, 7 },
            .{ 2, 5, 8 },
            .{ 3, 6, 9 },
        },
    };

    const mt = m.transposed();
    try testing.expectEqual(n.data2, mt.data2);
    _ = m.transpose();
    try testing.expectEqual(n.data2, m.data2);
}

test "Matrix inverse: identity matrix" {
    { // 2x2
        var id = Mat2.identity();
        const inv = id.inversed();
        try testing.expectEqual(id.data2, inv.data2);
        _ = id.inverse();
        try testing.expectEqual(Mat2.identity().data2, id.data2);
    }

    { // 3x3
        var id = Mat3.identity();
        const inv = id.inversed();
        try testing.expectEqual(id.data2, inv.data2);
        _ = id.inverse();
        try testing.expectEqual(Mat3.identity().data2, id.data2);
    }

    { // 4x4
        var id = Mat4.identity();
        const inv = id.inversed();
        try testing.expectEqual(id.data2, inv.data2);
        _ = id.inverse();
        try testing.expectEqual(Mat4.identity().data2, id.data2);
    }
}

test "Matrix inverse: A * A^-1 = I" {
    { // 2x2
        var m = Mat2{
            .data2 = .{
                .{ 4, 7 },
                .{ 2, 6 },
            },
        };

        const inv = m.inversed();
        const product = m.multipliedSq(inv);
        const tolerance: @TypeOf(m).W = @splat(std.math.floatEps(f32));
        const difference: @TypeOf(m).W = @abs(product.simd1 - Mat2.identity().simd1);
        try testing.expect(@reduce(.And, difference <= tolerance));
    }

    { // 3x3
        var m = Mat3{
            .data2 = .{
                .{ 3, 0, 2 },
                .{ 2, 0, -2 },
                .{ 0, 1, 1 },
            },
        };

        const inv = m.inversed();
        const product = m.multipliedSq(inv);
        const tolerance: @TypeOf(m).W = @splat(std.math.floatEps(f32));
        const difference: @TypeOf(m).W = @abs(product.simd1 - Mat3.identity().simd1);
        try testing.expect(@reduce(.And, difference <= tolerance));
    }

    { // 4x4
        var m = Mat4{
            .data2 = .{
                .{ 1, 2, 3, 4 },
                .{ 0, 1, 4, 5 },
                .{ 5, 6, 0, 7 },
                .{ 8, 9, 10, 1 },
            },
        };

        const inv = m.inversed();
        const product = m.multipliedSq(inv);
        // try testing.expectEqual(Mat4.identity().data2, product.data2);
        const tolerance: @TypeOf(m).W = @splat(1e-5);
        const difference: @TypeOf(m).W = @abs(product.simd1 - Mat4.identity().simd1);
        try testing.expect(@reduce(.And, difference <= tolerance));
    }
}

test "Matrix inverse: A^-1 * A = I" {
    { // 2x2
        var m = Mat2{
            .data2 = .{
                .{ 4, 7 },
                .{ 2, 6 },
            },
        };

        const inv = m.inversed();
        const product = inv.multipliedSq(m);
        // const tolerance: @TypeOf(m).W = @splat(std.math.floatEps(f32));
        const tolerance: @TypeOf(m).W = @splat(1e-6);
        const difference: @TypeOf(m).W = @abs(product.simd1 - Mat2.identity().simd1);
        try testing.expect(@reduce(.And, difference <= tolerance));
    }

    { // 3x3
        var m = Mat3{
            .data2 = .{
                .{ 3, 0, 2 },
                .{ 2, 0, -2 },
                .{ 0, 1, 1 },
            },
        };

        const inv = m.inversed();
        const product = inv.multipliedSq(m);
        const tolerance: @TypeOf(m).W = @splat(std.math.floatEps(f32));
        const difference: @TypeOf(m).W = @abs(product.simd1 - Mat3.identity().simd1);
        try testing.expect(@reduce(.And, difference <= tolerance));
    }

    { // 4x4
        var m = Mat4{
            .data2 = .{
                .{ 1, 2, 3, 4 },
                .{ 0, 1, 4, 5 },
                .{ 5, 6, 0, 7 },
                .{ 8, 9, 10, 1 },
            },
        };

        const inv = m.inversed();
        const product = inv.multipliedSq(m);
        // try testing.expectEqual(Mat4.identity().data2, product.data2);
        const tolerance: @TypeOf(m).W = @splat(1e-6);
        const difference: @TypeOf(m).W = @abs(product.simd1 - Mat4.identity().simd1);
        try testing.expect(@reduce(.And, difference <= tolerance));
    }
}

test "Matrix inverse: (A^-1)^-1 = A" {
    { // 2x2
        var m = Mat2{
            .data2 = .{
                .{ 4, 7 },
                .{ 2, 6 },
            },
        };

        var inv = m.inversed();
        _ = inv.inverse();
        // const tolerance: @TypeOf(m).W = @splat(std.math.floatEps(f32));
        const tolerance: @TypeOf(m).W = @splat(1e-6);
        const difference: @TypeOf(m).W = @abs(inv.simd1 - m.simd1);
        try testing.expect(@reduce(.And, difference <= tolerance));
    }

    { // 3x3
        var m = Mat3{
            .data2 = .{
                .{ 3, 0, 2 },
                .{ 2, 0, -2 },
                .{ 0, 1, 1 },
            },
        };

        var inv = m.inversed();
        _ = inv.inverse();
        const tolerance: @TypeOf(m).W = @splat(1e-5);
        const difference: @TypeOf(m).W = @abs(inv.simd1 - m.simd1);
        try testing.expect(@reduce(.And, difference <= tolerance));
    }

    { // 4x4
        var m = Mat4{
            .data2 = .{
                .{ 1, 2, 3, 4 },
                .{ 0, 1, 4, 5 },
                .{ 5, 6, 0, 7 },
                .{ 8, 9, 10, 1 },
            },
        };

        var inv = m.inversed();
        _ = inv.inverse();
        // try testing.expectEqual(Mat4.identity().data2, product.data2);
        const tolerance: @TypeOf(m).W = @splat(1e-4);
        const difference: @TypeOf(m).W = @abs(inv.simd1 - m.simd1);
        try testing.expect(@reduce(.And, difference <= tolerance));
    }
}

test "Matrix inverse and transpose: (A^T)^-1 = (A^-1)^T" {
    { // 2x2
        var m = Mat2{
            .data2 = .{
                .{ 4, 7 },
                .{ 2, 6 },
            },
        };

        const inv_trans = m.inversed().cc().transpose();
        const trans_inv = m.transposed().cc().inverse();

        // const tolerance: @TypeOf(m).W = @splat(std.math.floatEps(f32));
        const tolerance: @TypeOf(m).W = @splat(1e-6);
        const difference: @TypeOf(m).W = @abs(inv_trans.simd1 - trans_inv.simd1);
        try testing.expect(@reduce(.And, difference <= tolerance));
    }

    { // 3x3
        var m = Mat3{
            .data2 = .{
                .{ 3, 0, 2 },
                .{ 2, 0, -2 },
                .{ 0, 1, 1 },
            },
        };

        const inv_trans = m.inversed().cc().transpose();
        const trans_inv = m.transposed().cc().inverse();

        // const tolerance: @TypeOf(m).W = @splat(std.math.floatEps(f32));
        const tolerance: @TypeOf(m).W = @splat(1e-6);
        const difference: @TypeOf(m).W = @abs(inv_trans.simd1 - trans_inv.simd1);
        try testing.expect(@reduce(.And, difference <= tolerance));
    }

    { // 4x4
        var m = Mat4{
            .data2 = .{
                .{ 1, 2, 3, 4 },
                .{ 0, 1, 4, 5 },
                .{ 5, 6, 0, 7 },
                .{ 8, 9, 10, 1 },
            },
        };

        const inv_trans = m.inversed().cc().transpose();
        const trans_inv = m.transposed().cc().inverse();

        // const tolerance: @TypeOf(m).W = @splat(std.math.floatEps(f32));
        const tolerance: @TypeOf(m).W = @splat(1e-6);
        const difference: @TypeOf(m).W = @abs(inv_trans.simd1 - trans_inv.simd1);
        try testing.expect(@reduce(.And, difference <= tolerance));
    }
}

const std = @import("std");
const testing = std.testing;
const math = std.math;
const Vector = @import("vector.zig").Vector;

// Common types for testing
const Mat4 = Matrix(f32, 4, 4);
const Mat3 = Matrix(f32, 3, 3);
const Mat2 = Matrix(f32, 2, 2);
