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

/// Creates a Vector type of size N with element type T
pub fn Vec(comptime T: type, comptime N: u16) type {
    switch (@typeInfo(T)) {
        .int => |info| if (info.signedness == .unsigned) @compileError("Vec element type must be signed"),
        .float => {},
        else => @compileError("Vec element type must be numeric"),
    }

    return struct {
        data: [N]T,

        const Self = @This();

        pub const VecError = error{
            DivideByZero,
        };

        // (TESTED)
        /// Initialize vector with another vector
        pub inline fn initV(other: Self) Self {
            return .{ .data = other.data };
        }

        // (TESTED)
        /// Initialize vector with vector of different type
        pub inline fn fromV(comptime I: type, other: Vec(I, N)) Self {
            if (I == T) return Self.initV(other);

            return Self.fromA(I, other.data);
        }

        // (TESTED)
        /// Initialize vector with array of values
        pub fn initA(values: [N]T) Self {
            return .{ .data = values };
        }

        // (TESTED)
        /// Initialize vector with array of values of different type
        pub fn fromA(comptime I: type, values: [N]I) Self {
            if (I == T) return Self.initA(values);
            switch (@typeInfo(I)) {
                .int, .float => {},
                else => @compileError("Vec element type must be numeric"),
            }

            var result: [N]T = undefined;
            for (values, 0..) |v, i| {
                switch (@typeInfo(T)) {
                    .int => switch (@typeInfo(I)) {
                        .int => result[i] = @intCast(v),
                        .float => result[i] = @intFromFloat(v),
                        else => @compileError("Array element type must be numeric"),
                    },
                    .float => switch (@typeInfo(I)) {
                        .int => result[i] = @floatFromInt(v),
                        .float => result[i] = @floatCast(v),
                        else => @compileError("Array element type must be numeric"),
                    },
                    else => @compileError("Vec element type must be numeric"),
                }
            }

            return Self.initA(result);
        }

        // (TESTED)
        /// Initialize vector with all components set to the same value
        pub fn initS(scalar: T) Self {
            return .{ .data = @splat(scalar) };
        }

        pub inline fn fromS(comptime I: type, scalar: I) Self {
            if (I == T) return Self.initS(scalar);

            switch (@typeInfo(T)) {
                .int => switch (@typeInfo(I)) {
                    .int => return Self.initS(@intCast(scalar)),
                    .float => return Self.initS(@intFromFloat(scalar)),
                    else => @compileError("Scalar type must be numeric"),
                },
                .float => switch (@typeInfo(I)) {
                    .int => return Self.initS(@floatFromInt(scalar)),
                    .float => return Self.initS(@floatCast(scalar)),
                    else => @compileError("Scalar type must be numeric"),
                },
                else => @compileError("Vec element type must be numeric"),
            }
        }

        inline fn scalarFromAny(comptime I: type, value: I) T {
            return switch (@typeInfo(T)) {
                .int => switch (@typeInfo(I)) {
                    .int => @intCast(value),
                    .float => @intFromFloat(value),
                    else => @compileError("Value type must be numeric"),
                },
                .float => switch (@typeInfo(I)) {
                    .int => @floatFromInt(value),
                    .float => @floatCast(value),
                    else => @compileError("Value type must be numeric"),
                },
                else => @compileError("Vec element type must be numeric"),
            };
        }

        inline fn arrayFromAny(comptime I: type, values: [N]I) [N]T {
            // if (@typeInfo(I).array.len != N) @compileError("Array length must be equal to vector length");
            const Y: type = switch (I) {
                comptime_int, comptime_float => T,
                else => I,
            };
            const a: @Vector(N, Y) = @as(@Vector(N, Y), values);

            return switch (@typeInfo(T)) {
                .int => switch (@typeInfo(Y)) {
                    .int => @as(@Vector(N, T), @intCast(a)),
                    .float => @as(@Vector(N, T), @intFromFloat(a)),
                    else => @compileError("Array element type must be numeric"),
                },
                .float => switch (@typeInfo(Y)) {
                    .int => @as(@Vector(N, T), @floatFromInt(a)),
                    .float => @as(@Vector(N, T), @floatCast(a)),
                    else => @compileError("Array element type must be numeric"),
                },
                else => @compileError("Vec element type must be numeric"),
            };
        }

        inline fn vectorFromAny(value: anytype) @Vector(N, T) {
            return switch (@typeInfo(@TypeOf(value))) {
                .comptime_int, .comptime_float => @splat(value),
                .int, .float => switch (@TypeOf(value)) {
                    T => @splat(value),
                    else => @splat(scalarFromAny(@TypeOf(value), value)),
                },
                .array => |a| switch (@TypeOf(value)) {
                    [N]T => value,
                    else => arrayFromAny(a.child, value),
                },
                .pointer => |p| switch (@TypeOf(value)) {
                    []T => ptr: {
                        if (value.len != N) @compileError("Pointer length must be equal to vector length");
                        break :ptr value.*;
                    },
                    else => arrayFromAny(@typeInfo(p.child).array.child, value.*),
                },
                .@"struct" => |s| switch (@TypeOf(value)) {
                    Vec(T, N) => value.data,
                    else => if (s.is_tuple) arrayFromAny(s.fields[0].type, value) else arrayFromAny(@typeInfo(s.fields[0].type).array.child, value.data),
                    // TODO: Add support for other structs
                    // else => {
                    //     @compileLog("Type: {any}\n", .{@TypeOf(value)});
                    //     @compileError("Unsupported type");
                    // },
                },
                else => {
                    @compileLog("Type: {any}\n", .{@TypeOf(value)});
                    @compileError("Unsupported type");
                },
            };
        }

        // (TESTED)
        /// Initialize vector with component at index set to 1, others to 0
        pub inline fn unitP(index: usize) Self {
            var result = Self.initS(0);
            if (index < N) {
                result.data[index] = 1;
            }
            return result;
        }

        // (TESTED)
        /// Initialize vector with component at index set to -1, others to 0
        pub inline fn unitN(index: usize) Self {
            var result = Self.initS(0);
            if (index < N) {
                result.data[index] = -1;
            }
            return result;
        }

        // (TESTED)
        /// Generate a new vector with components picked from the current vector
        pub inline fn pick(self: Self, indices: []const i32) Vec(T, indices.len) {
            const a = self.data;
            const mask: @Vector(indices.len, i32) = indices[0..].*;

            return Vec(T, indices.len).initA(@shuffle(T, a, undefined, @abs(mask)));
        }

        /// Summation of two vectors by components
        pub inline fn add(self: Self, other: anytype) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = vectorFromAny(other);

            return .{ .data = a + b };
        }

        /// Difference of two vectors by components
        pub inline fn sub(self: Self, other: anytype) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = vectorFromAny(other);

            return .{ .data = a - b };
        }

        /// Product of two vectors by components
        pub inline fn mul(self: Self, other: anytype) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = vectorFromAny(other);

            return .{ .data = a * b };
        }

        /// Quotient of two vectors by components
        pub inline fn div(self: Self, other: anytype) !Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = vectorFromAny(other);

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = a / b };
        }

        /// Modulus of two vectors by components
        pub inline fn mod(self: Self, other: anytype) !Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = vectorFromAny(other);

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = @mod(a, b) };
        }

        /// Remainder of two vectors by components
        pub inline fn rem(self: Self, other: anytype) !Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = vectorFromAny(other);

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = @rem(a, b) };
        }

        /// Comparison of being less than for two vectors by components
        pub inline fn lesser(self: Self, other: anytype) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = vectorFromAny(other);

            return a < b;
        }

        /// Comparison of being less than or equal for two vectors by components
        pub inline fn lesserEq(self: Self, other: anytype) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = vectorFromAny(other);

            return a <= b;
        }

        /// Comparison of being greater than for two vectors by components
        pub inline fn greater(self: Self, other: anytype) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = vectorFromAny(other);

            return a > b;
        }

        /// Comparison of being greater than or equal for two vectors by components
        pub inline fn greaterEq(self: Self, other: anytype) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = vectorFromAny(other);

            return a >= b;
        }

        /// Comparison of equality for two vectors by components
        pub inline fn equals(self: Self, other: anytype) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = vectorFromAny(other);

            return a == b;
        }

        pub inline fn approx(self: Self, other: anytype, tolerance: ?T) @Vector(N, bool) {
            const Y: type = comptime getY: {
                var y: std.builtin.Type = @typeInfo(T);
                if (y == .int) y.int.signedness = .unsigned;
                break :getY if (y == .float) T else @Type(y);
            };
            const t: Y = tolerance orelse if (Y == .float) std.math.floatEps(T) else 0;
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = vectorFromAny(other);

            const c: @Vector(N, Y) = @abs(a - b);
            const d: @Vector(N, Y) = @splat(t);

            return c <= d;
        }

        /// Boolean result of approximate equality comparison of components using vector
        pub inline fn approxV(self: Self, other: Self, tolerance: ?T) @Vector(N, bool) {
            const Y: type = comptime getY: {
                var y: std.builtin.Type = @typeInfo(T);
                if (y == .int) y.int.signedness = .unsigned;
                break :getY if (y == .float) T else @Type(y);
            };
            const t: Y = tolerance orelse std.math.floatEps(T);
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;
            const c: @Vector(N, Y) = @abs(a - b);
            const d: @Vector(N, Y) = @splat(t);

            return c <= d;
        }

        /// Boolean result of approximate equality comparison of components using vector of different type
        pub inline fn approxFromV(self: Self, comptime I: type, other: Vec(I, N), tolerance: ?T) @Vector(N, bool) {
            if (I == T) return self.approxV(other, tolerance);

            const Y: type = comptime getY: {
                var y: std.builtin.Type = @typeInfo(T);
                if (y == .int) y.int.signedness = .unsigned;
                break :getY if (y == .float) T else @Type(y);
            };
            const t: Y = tolerance orelse std.math.floatEps(T);
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, other.data).data;
            const c: @Vector(N, Y) = @abs(a - b);
            const d: @Vector(N, Y) = @splat(t);

            return c <= d;
        }

        /// Boolean result of approximate equality comparison of components using array
        pub inline fn approxA(self: Self, array: [N]T, tolerance: ?T) @Vector(N, bool) {
            const Y: type = comptime getY: {
                var y: std.builtin.Type = @typeInfo(T);
                if (y == .int) y.int.signedness = .unsigned;
                break :getY if (y == .float) T else @Type(y);
            };
            const t: Y = tolerance orelse std.math.floatEps(T);
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = array;
            const c: @Vector(N, Y) = @abs(a - b);
            const d: @Vector(N, Y) = @splat(t);

            return c <= d;
        }

        /// Boolean result of approximate equality comparison of components using array of different type
        pub inline fn approxFromA(self: Self, comptime I: type, array: [N]I, tolerance: ?T) @Vector(N, bool) {
            if (I == T) return self.approxA(array, tolerance);

            const Y: type = comptime getY: {
                var y: std.builtin.Type = @typeInfo(T);
                if (y == .int) y.int.signedness = .unsigned;
                break :getY if (y == .float) T else @Type(y);
            };
            const t: Y = tolerance orelse std.math.floatEps(T);
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, array).data;
            const c: @Vector(N, Y) = @abs(a - b);
            const d: @Vector(N, Y) = @splat(t);

            return c <= d;
        }

        /// Boolean result of approximate equality comparison of components using scalar
        pub inline fn approxS(self: Self, scalar: T, tolerance: ?T) @Vector(N, bool) {
            const Y: type = comptime getY: {
                var y: std.builtin.Type = @typeInfo(T);
                if (y == .int) y.int.signedness = .unsigned;
                break :getY if (y == .float) T else @Type(y);
            };
            const t: Y = tolerance orelse std.math.floatEps(T);
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(scalar);
            const c: @Vector(N, Y) = @abs(a - b);
            const d: @Vector(N, Y) = @splat(t);

            return c <= d;
        }

        /// Boolean result of approximate equality comparison of components using scalar of different type
        pub inline fn approxFromS(self: Self, comptime I: type, scalar: I, tolerance: ?T) @Vector(N, bool) {
            if (I == T) return self.approxS(scalar, tolerance);

            const Y: type = comptime getY: {
                var y: std.builtin.Type = @typeInfo(T);
                if (y == .int) y.int.signedness = .unsigned;
                break :getY if (y == .float) T else @Type(y);
            };
            const t: Y = tolerance orelse std.math.floatEps(T);
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromS(I, scalar).data;
            const c: @Vector(N, Y) = @abs(a - b);
            const d: @Vector(N, Y) = @splat(t);

            return c <= d;
        }

        /// Compute dot product (inner product) of two vectors
        pub inline fn inner(self: Self, other: Self) T {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;
            const c: @Vector(N, T) = a * b;

            return @reduce(.Add, c);
        }

        /// Compute the outer product (for vectors results in a matrix)
        /// This returns a flat array in row-major order
        pub inline fn outer1d(self: Self, other: Self) [N * N]T {
            const a: @Vector(N * N, T) = std.simd.repeat(N * N, other.data);
            const s: @Vector(N, T) = self.data;
            const mask = comptime getMask: {
                var output: [N * N]T = undefined;
                for (0..N) |i| {
                    output[i * N .. i * N + N].* = @splat(@as(i32, @intCast(i)));
                }
                break :getMask output;
            };
            const b: @Vector(N * N, T) = @shuffle(T, s, undefined, mask);

            return a * b;
        }

        /// Compute the outer product (for vectors results in a matrix)
        /// This returns a 2d array in row-major order
        pub inline fn outer2d(self: Self, other: Self) [N][N]T {
            return @bitCast(outer1d(self, other));
        }

        /// Cross product
        pub fn cross(vectors: [N - 1]Self) Self {
            var result: [N]T = undefined;

            var matrix: [N][N]T = undefined;

            for (vectors, 0..) |v, i| {
                matrix[i] = v.data;
            }
            matrix[N - 1] = [_]T{0} ** N;

            for (0..N) |i| {
                matrix[N - 1][i] = 1;

                result[i] = determinant(N, &matrix);

                matrix[N - 1][i] = 0;
            }

            return Self.initA(result);
        }

        fn determinant(comptime n: u16, matrix: *[n][n]T) T {
            const nm = n - 1;

            if (n == 1) {
                return matrix[0][0];
            }

            var det: T = 0;

            for (0..n) |i| {
                var submatrix: [nm][nm]T = @bitCast([_]T{0} ** (nm * nm));

                for (1..n) |j| {
                    var sub_col_index: usize = 0;
                    for (0..n) |k| {
                        if (k == i) continue;
                        submatrix[j - 1][sub_col_index] = matrix[j][k];
                        sub_col_index += 1;
                    }
                }

                const sub_det = determinant(nm, &submatrix);

                if (i % 2 == 0) {
                    det += matrix[0][i] * sub_det;
                } else {
                    det -= matrix[0][i] * sub_det;
                }
            }

            return det;
        }

        /// Calculate length (magnitude) of vector
        pub inline fn length(self: Self) (if (@typeInfo(T) == .float) T else f32) {
            return switch (@typeInfo(T)) {
                .float => @sqrt(self.inner(self)),
                .int => @sqrt(@as(f32, @floatFromInt(self.inner(self)))),
                else => @compileError("Vec element type must be numeric"),
            };
        }

        /// Calculate squared length
        pub inline fn length2(self: Self) T {
            return self.inner(self);
        }

        /// Return Normalized vector to unit length
        pub inline fn normalized(self: Self) ?(if (@typeInfo(T) == .float) Self else Vec(f32, N)) {
            const len = self.length();
            if (len == 0) return null;
            return switch (@typeInfo(T)) {
                .float => self.div(len) catch unreachable,
                .int => Vec(f32, N).fromA(T, self.data).div(len) catch unreachable,
                else => @compileError("Vec element type must be numeric"),
            };
        }

        /// Calculate direction vector from self to other vector
        pub inline fn dirToV(self: Self, other: Self) (if (@typeInfo(T) == .float) Self else Vec(f32, N)) {
            return other.sub(self).normalized() orelse (if (@typeInfo(T) == (.float)) Self else Vec(f32, N)).initS(0);
        }

        /// Calculate direction vector from self to other vector of different type
        pub inline fn dirToFromV(self: Self, comptime I: type, other: Vec(I, N)) (if (@typeInfo(T) == .float) Self else Vec(f32, N)) {
            return Self.fromA(I, other.data).sub(self).normalized() orelse (if (@typeInfo(T) == (.float)) Self else Vec(f32, N)).initS(0);
        }

        /// Calculate direction vector from self to array
        pub inline fn dirToA(self: Self, array: [N]T) (if (@typeInfo(T) == .float) Self else Vec(f32, N)) {
            return Vec(T, N).initA(array).sub(self).normalized() orelse (if (@typeInfo(T) == (.float)) Self else Vec(f32, N)).initS(0);
        }

        /// Calculate direction vector from self to array of different type
        pub inline fn dirToFromA(self: Self, comptime I: type, array: [N]I) (if (@typeInfo(T) == .float) Self else Vec(f32, N)) {
            return Self.fromA(I, array).sub(self).normalized() orelse (if (@typeInfo(T) == (.float)) Self else Vec(f32, N)).initS(0);
        }

        /// Calculate direction vector from self to scalar
        pub inline fn dirToS(self: Self, scalar: T) (if (@typeInfo(T) == .float) Self else Vec(f32, N)) {
            return Self.initS(scalar).sub(self).normalized() orelse (if (@typeInfo(T) == (.float)) Self else Vec(f32, N)).initS(0);
        }

        /// Calculate direction vector from self to scalar of different type
        pub inline fn dirToFromS(self: Self, comptime I: type, scalar: I) (if (@typeInfo(T) == .float) Self else Vec(f32, N)) {
            return Self.fromS(I, scalar).sub(self).normalized() orelse (if (@typeInfo(T) == (.float)) Self else Vec(f32, N)).initS(0);
        }

        /// Calculate distance between two vectors
        pub inline fn distTo(self: Self, other: Self) (if (@typeInfo(T) == .float) T else f32) {
            return switch (@typeInfo(T)) {
                .float => @sqrt(self.distTo2(other)),
                .int => @sqrt(@as(f32, @floatFromInt(self.distTo2(other)))),
                else => @compileError("Vec element type must be numeric"),
            };
        }

        /// Calculate squared distance between two vectors
        pub inline fn distTo2(self: Self, other: Self) T {
            return other.sub(self).length2();
        }

        /// Linear interpolation between two vectors at time t
        pub inline fn lerp(self: Self, other: Self, t: T) (if (@typeInfo(T) == .float) Self else Vec(f32, N)) {
            return switch (@typeInfo(T)) {
                .float => self.mul(1 - t).add(other.mul(t)),
                .int => Vec(f32, N).fromA(T, self.data).mul(1 - t).add(Vec(f32, N).fromA(T, other.data).mul(t)),
                else => @compileError("Vec element type must be numeric"),
            };
        }

        // Absolute max scalar of both vectors
        pub inline fn maxOf(self: Self, other: Self) T {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;
            const c: T = @reduce(.Max, a);
            const d: T = @reduce(.Max, b);

            return @max(c, d);
        }

        // Absolute min scalar of both vectors
        pub inline fn minOf(self: Self, other: Self) T {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;
            const c: T = @reduce(.Min, a);
            const d: T = @reduce(.Min, b);

            return @min(c, d);
        }

        // New vector with component by component max of both vectors
        pub inline fn maxOfs(self: Self, other: Self) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            return .{ .data = @max(a, b) };
        }

        // New vector with component by component min of both vectors
        pub inline fn minOfs(self: Self, other: Self) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            return .{ .data = @min(a, b) };
        }

        // New vector with max of all components
        pub inline fn maxed(self: Self) Self {
            const a: @Vector(N, T) = self.data;

            return .{ .data = @splat(@reduce(.Max, a)) };
        }

        // New vector with min of all components
        pub inline fn mined(self: Self) Self {
            const a: @Vector(N, T) = self.data;

            return .{ .data = @splat(@reduce(.Min, a)) };
        }

        // New vector with inverse of all components
        pub inline fn inversed(self: Self) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(1);

            return .{ .data = b / a };
        }

        // New vector with negation of all components
        pub inline fn negated(self: Self) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(-1);

            return .{ .data = a * b };
        }
        //     pub fn clamp(){}
        //     pub fn project(){}
        //     pub fn projectOnPlane(){}
        //     pub fn projectOnLine(){}
        //     pub fn rotate(){}
        //     pub fn rotateAround(){}
        //     pub fn rotateTowards(){}
        //
        //     pub fn slerp(){}
        //     pub fn reflect(){}
        //     pub fn refract(){}
        //     pub fn angle(){}
        //     pub fn angle2(){}
        //     pub fn angleBetween(){}
        //     pub fn angleBetween2(){}

        /// Convert to a vector of different size
        /// If target size is smaller, excess elements are truncated
        /// If target size is larger, new elements are filled with 0
        pub fn toSize(self: Self, comptime M: u8) Vec(T, M) {
            if (M == N) return self;
            var result = Vec(T, M).initS(0);
            const min_size = @min(N, M);
            for (0..min_size) |i| {
                result.data[i] = self.data[i];
            }
            return result;
        }

        // To string function
        pub fn format( // zig fmt: off
            self: Self,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype
        ) !void {
            _ = fmt;
            _ = options;

            try writer.print("Vec{d}(", .{N});
            for (self.data, 0..) |v, i| {
                if (i > 0) try writer.print(", ", .{});
                try writer.print("{d}", .{v});
            }
            try writer.print(")", .{});
        }
    }; // zig fmt: on
}

// zig fmt: off
pub const Component = enum(i32) { x = 0, y, z, w, };
// zig fmt: on

/// Convenience function to create a Vec2
pub fn Vec2(comptime T: type) type {
    const baseType: type = Vec(T, 2);

    return struct {
        x: T,
        y: T,

        const Self = @This();

        pub inline fn as(self: *const Self) *baseType {
            return @as(*baseType, @ptrCast(@constCast(self)));
        }

        pub fn initV(vec: Self) Self {
            return .{ .x = vec.x, .y = vec.y };
        }

        pub fn initA(data: [2]T) Self {
            return .{ .x = data[0], .y = data[1] };
        }

        pub fn initS(scalar: T) Self {
            return .{ .x = scalar, .y = scalar };
        }

        pub fn from(vec: baseType) Self {
            const bytes = toBytes(vec);
            return bytesToValue(Self, &bytes);
        }

        pub fn to(self: Self) baseType {
            const bytes = toBytes(self);
            return bytesToValue(baseType, &bytes);
        }

        pub fn cross(self: Self) Self {
            return .{
                .x = self.y,
                .y = -self.x,
            };
        }
    };
}

/// Convenience function to create a Vec3
pub fn Vec3(comptime T: type) type {
    const baseType: type = Vec(T, 3);

    return struct {
        x: T,
        y: T,
        z: T,

        const Self = @This();

        pub inline fn as(self: *const Self) *baseType {
            return @as(*baseType, @ptrCast(@constCast(self)));
        }

        pub fn initV(vec: Self) Self {
            return .{ .x = vec.x, .y = vec.y, .z = vec.z };
        }

        pub fn initA(data: [3]T) Self {
            return .{ .x = data[0], .y = data[1], .z = data[2] };
        }

        pub fn initS(scalar: T) Self {
            return .{ .x = scalar, .y = scalar, .z = scalar };
        }

        pub fn from(vec: baseType) Self {
            const bytes = toBytes(vec);
            return bytesToValue(Self, &bytes);
        }

        pub fn to(self: Self) baseType {
            const bytes = toBytes(self);
            return bytesToValue(baseType, &bytes);
        }

        pub inline fn cross(self: Self, other: Self) Self {
            return .{
                .x = self.y * other.z - self.z * other.y,
                .y = self.z * other.x - self.x * other.z,
                .z = self.x * other.y - self.y * other.x,
            };
        }

        // faster at 10 Billion iterations
        // pub inline fn crossSimd(self: Self, other: Self) Self {
        //     const a: @Vector(3, T) = self.as().data;
        //     const b: @Vector(3, T) = other.as().data;
        //     const m1: @Vector(3, T) = .{ 1, 2, 0 };
        //     const m2: @Vector(3, T) = .{ 2, 0, 1 };
        //     const e1: @Vector(3, T) = @shuffle(T, a, undefined, m1);
        //     const e2: @Vector(3, T) = @shuffle(T, b, undefined, m2);
        //     const e3: @Vector(3, T) = @shuffle(T, a, undefined, m2);
        //     const e4: @Vector(3, T) = @shuffle(T, b, undefined, m1);
        //
        //     return Self.init(e1 * e2 - e3 * e4);
        // }
    };
}

/// Convenience function to create a Vec4
pub fn Vec4(comptime T: type) type {
    const baseType: type = Vec(T, 4);

    return struct {
        x: T,
        y: T,
        z: T,
        w: T,

        const Self = @This();

        pub inline fn as(self: *const Self) *baseType {
            return @as(*baseType, @ptrCast(@constCast(self)));
        }

        pub fn initV(vec: Self) Self {
            return .{ .x = vec.x, .y = vec.y, .z = vec.z, .w = vec.w };
        }

        pub fn initA(data: [4]T) Self {
            return .{ .x = data[0], .y = data[1], .z = data[2], .w = data[3] };
        }

        pub fn initS(scalar: T) Self {
            return .{ .x = scalar, .y = scalar, .z = scalar, .w = scalar };
        }

        pub fn from(vec: baseType) Self {
            const bytes = toBytes(vec);
            return bytesToValue(Self, &bytes);
        }

        pub fn to(self: Self) baseType {
            const bytes = toBytes(self);
            return bytesToValue(baseType, &bytes);
        }
    };
}

// Definitions
const std = @import("std");
const testing = std.testing;

const toBytes = std.mem.toBytes;
const bytesToValue = std.mem.bytesToValue;

// Tests
// Vec
test "Initialize" {
    // Floating point Vector
    // standard initialization from same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initS(1.0);
    const v3 = Vec(f32, 3).initV(v1);
    try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.data);
    try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v2.data);
    try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v3.data);

    // initialization from same type with different size
    const v4 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v5 = Vec(f32, 3).fromV(f64, v4);
    try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v5.data);

    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const v6 = Vec(f32, 3).fromA(f64, a1);
    try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v6.data);

    const s1: f64 = 1.0;
    const v7 = Vec(f32, 3).fromS(f64, s1);
    try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v7.data);

    // Signed Integral Vector
    // standard initialization from same type and size
    const v8 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v9 = Vec(i32, 3).initS(1);
    const v10 = Vec(i32, 3).initV(v8);
    try testing.expectEqual([3]i32{ 1, 2, 3 }, v8.data);
    try testing.expectEqual([3]i32{ 1, 1, 1 }, v9.data);
    try testing.expectEqual([3]i32{ 1, 2, 3 }, v10.data);

    // initialization from same type with different size
    const v11 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v12 = Vec(i32, 3).fromV(i64, v11);
    try testing.expectEqual([3]i32{ 1, 2, 3 }, v12.data);

    const a2 = [3]i64{ 1, 2, 3 };
    const v13 = Vec(i32, 3).fromA(i64, a2);
    try testing.expectEqual([3]i32{ 1, 2, 3 }, v13.data);

    const s2: i64 = 1;
    const v14 = Vec(i32, 3).fromS(i64, s2);
    try testing.expectEqual([3]i32{ 1, 1, 1 }, v14.data);

    // Both Vector types
    // initialization from different type and size
    const v15 = Vec(f32, 3).fromV(i64, v11);
    const v16 = Vec(i32, 3).fromV(f64, v4);
    try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v15.data);
    try testing.expectEqual([3]i32{ 1, 2, 3 }, v16.data);

    const v17 = Vec(f32, 3).fromA(i64, a2);
    const v18 = Vec(i32, 3).fromA(f64, a1);
    try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v17.data);
    try testing.expectEqual([3]i32{ 1, 2, 3 }, v18.data);

    const v19 = Vec(f32, 3).fromS(i64, s2);
    const v20 = Vec(i32, 3).fromS(f64, s1);
    try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v19.data);
    try testing.expectEqual([3]i32{ 1, 1, 1 }, v20.data);

    // initialization of unit vectors
    const v21 = Vec(f32, 3).unitP(1);
    const v22 = Vec(f32, 3).unitN(1);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 0.0 }, v21.data);
    try testing.expectEqual([3]f32{ 0.0, -1.0, 0.0 }, v22.data);

    const v23 = Vec(i32, 3).unitP(1);
    const v24 = Vec(i32, 3).unitN(1);
    try testing.expectEqual([3]i32{ 0, 1, 0 }, v23.data);
    try testing.expectEqual([3]i32{ 0, -1, 0 }, v24.data);

    // TODO: Not a real test yet, slated for future zig version
    // try testing.expect(@isComptimeErrorVec(u32, 3).initS(1));
}

test "Pick" {
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = v1.pick(&.{ 0, 2 });
    const v3 = v1.pick(&.{ 1, 2, 0 });
    const v4 = v1.pick(&.{1});
    const v5 = v1.pick(&.{ 1, 1, 2, 0 });
    try testing.expectEqual([2]f32{ 1.0, 3.0 }, v2.data);
    try testing.expectEqual([3]f32{ 2.0, 3.0, 1.0 }, v3.data);
    try testing.expectEqual([1]f32{2.0}, v4.data);
    try testing.expectEqual([4]f32{ 2.0, 2.0, 3.0, 1.0 }, v5.data);
}

test "Addition" {
    // Floating point Vector
    // standard addition of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v3 = v1.add(v2);
    const v4 = v1.add([3]f32{ 4.0, 5.0, 6.0 });
    const v5 = v1.add(@as(f32, 1.0));
    try testing.expectEqual([3]f32{ 5.0, 7.0, 9.0 }, v3.data);
    try testing.expectEqual([3]f32{ 5.0, 7.0, 9.0 }, v4.data);
    try testing.expectEqual([3]f32{ 2.0, 3.0, 4.0 }, v5.data);

    // addition of same type with different size
    const v6 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v7 = v1.add(v6);

    const a1 = [3]f64{ 4.0, 5.0, 6.0 };
    const v8 = v1.add(a1);

    const s1: f64 = 1.0;
    const v9 = v1.add(s1);
    try testing.expectEqual([3]f32{ 5.0, 7.0, 9.0 }, v7.data);
    try testing.expectEqual([3]f32{ 5.0, 7.0, 9.0 }, v8.data);
    try testing.expectEqual([3]f32{ 2.0, 3.0, 4.0 }, v9.data);

    // Signed Integral Vector
    // standard addition of same type and size
    const v10 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v11 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    const v12 = v10.add(v11);
    const v13 = v10.add([3]i32{ 4, 5, 6 });
    const v14 = v10.add(1);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, v12.data);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, v13.data);
    try testing.expectEqual([3]i32{ 2, 3, 4 }, v14.data);

    const vnew = v10.add(v11.data[0..3]);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, vnew.data);

    // addition of same type with different size
    const v15 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const v16 = v10.add(v15);

    const a2 = [3]i64{ 4, 5, 6 };
    const v17 = v10.add(a2);

    const s2: i64 = 1;
    const v18 = v10.add(s2);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, v16.data);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, v17.data);
    try testing.expectEqual([3]i32{ 2, 3, 4 }, v18.data);

    // Both Vector types
    // addition of different type and size
    const v19 = v1.add(v15);
    const v20 = v10.add(v6);
    try testing.expectEqual([3]f32{ 5.0, 7.0, 9.0 }, v19.data);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, v20.data);

    const v21 = v1.add(a2);
    const v22 = v10.add(a1);
    try testing.expectEqual([3]f32{ 5.0, 7.0, 9.0 }, v21.data);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, v22.data);

    const v23 = v1.add(s2);
    const v24 = v10.add(s1);
    try testing.expectEqual([3]f32{ 2.0, 3.0, 4.0 }, v23.data);
    try testing.expectEqual([3]i32{ 2, 3, 4 }, v24.data);
}

test "Subtraction" {
    // Floating point Vector
    // standard subtraction of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v3 = v1.sub(v2);
    const v4 = v1.sub(.{ 4.0, 5.0, 6.0 });
    const v5 = v1.sub(1.0);
    try testing.expectEqual([3]f32{ -3.0, -3.0, -3.0 }, v3.data);
    try testing.expectEqual([3]f32{ -3.0, -3.0, -3.0 }, v4.data);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v5.data);

    // subtraction of same type with different size
    const v6 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v7 = v1.sub(v6);

    const a1 = [3]f64{ 4.0, 5.0, 6.0 };
    const v8 = v1.sub(a1);

    const s1: f64 = 1.0;
    const v9 = v1.sub(s1);
    try testing.expectEqual([3]f32{ -3.0, -3.0, -3.0 }, v7.data);
    try testing.expectEqual([3]f32{ -3.0, -3.0, -3.0 }, v8.data);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v9.data);

    // Signed Integral Vector
    // standard subtraction of same type and size
    const v10 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v11 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    const v12 = v10.sub(v11);
    const v13 = v10.sub(.{ 4, 5, 6 });
    const v14 = v10.sub(1);
    try testing.expectEqual([3]i32{ -3, -3, -3 }, v12.data);
    try testing.expectEqual([3]i32{ -3, -3, -3 }, v13.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v14.data);

    // subtraction of same type with different size
    const v15 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const v16 = v10.sub(v15);

    const a2 = [3]i64{ 4, 5, 6 };
    const v17 = v10.sub(a2);

    const s2: i64 = 1;
    const v18 = v10.sub(s2);
    try testing.expectEqual([3]i32{ -3, -3, -3 }, v16.data);
    try testing.expectEqual([3]i32{ -3, -3, -3 }, v17.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v18.data);

    // Both Vector types
    // subtraction of different type and size
    const v19 = v1.sub(v15);
    const v20 = v10.sub(v6);
    try testing.expectEqual([3]f32{ -3.0, -3.0, -3.0 }, v19.data);
    try testing.expectEqual([3]i32{ -3, -3, -3 }, v20.data);

    const v21 = v1.sub(a2);
    const v22 = v10.sub(a1);
    try testing.expectEqual([3]f32{ -3.0, -3.0, -3.0 }, v21.data);
    try testing.expectEqual([3]i32{ -3, -3, -3 }, v22.data);

    const v23 = v1.sub(s2);
    const v24 = v10.sub(s1);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v23.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v24.data);
}

test "Multiplication" {
    // Floating point Vector
    // standard multiplication of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v3 = v1.mul(v2);
    const v4 = v1.mul(.{ 4.0, 5.0, 6.0 });
    const v5 = v1.mul(2.0);
    try testing.expectEqual([3]f32{ 4.0, 10.0, 18.0 }, v3.data);
    try testing.expectEqual([3]f32{ 4.0, 10.0, 18.0 }, v4.data);
    try testing.expectEqual([3]f32{ 2.0, 4.0, 6.0 }, v5.data);

    // multiplication of same type with different size
    const v6 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v7 = v1.mul(v6);

    const a1 = [3]f64{ 4.0, 5.0, 6.0 };
    const v8 = v1.mul(a1);

    const s1: f64 = 2.0;
    const v9 = v1.mul(s1);
    try testing.expectEqual([3]f32{ 4.0, 10.0, 18.0 }, v7.data);
    try testing.expectEqual([3]f32{ 4.0, 10.0, 18.0 }, v8.data);
    try testing.expectEqual([3]f32{ 2.0, 4.0, 6.0 }, v9.data);

    // Signed Integral Vector
    // standard multiplication of same type and size
    const v10 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v11 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    const v12 = v10.mul(v11);
    const v13 = v10.mul(.{ 4, 5, 6 });
    const v14 = v10.mul(2);
    try testing.expectEqual([3]i32{ 4, 10, 18 }, v12.data);
    try testing.expectEqual([3]i32{ 4, 10, 18 }, v13.data);
    try testing.expectEqual([3]i32{ 2, 4, 6 }, v14.data);

    // multiplication of same type with different size
    const v15 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const v16 = v10.mul(v15);

    const a2 = [3]i64{ 4, 5, 6 };
    const v17 = v10.mul(a2);

    const s2: i64 = 2;
    const v18 = v10.mul(s2);
    try testing.expectEqual([3]i32{ 4, 10, 18 }, v16.data);
    try testing.expectEqual([3]i32{ 4, 10, 18 }, v17.data);
    try testing.expectEqual([3]i32{ 2, 4, 6 }, v18.data);

    // Both Vector types
    // multiplication of different type and size
    const v19 = v1.mul(v15);
    const v20 = v10.mul(v6);
    try testing.expectEqual([3]f32{ 4.0, 10.0, 18.0 }, v19.data);
    try testing.expectEqual([3]i32{ 4, 10, 18 }, v20.data);

    const v21 = v1.mul(a2);
    const v22 = v10.mul(a1);
    try testing.expectEqual([3]f32{ 4.0, 10.0, 18.0 }, v21.data);
    try testing.expectEqual([3]i32{ 4, 10, 18 }, v22.data);

    const v23 = v1.mul(s2);
    const v24 = v10.mul(s1);
    try testing.expectEqual([3]f32{ 2.0, 4.0, 6.0 }, v23.data);
    try testing.expectEqual([3]i32{ 2, 4, 6 }, v24.data);
}

test "Division" {
    // Floating point Vector
    // standard division of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v3 = try v1.div(v2);
    const v4 = try v1.div(.{ 4.0, 5.0, 6.0 });
    const v5 = try v1.div(2.0);
    try testing.expectEqual([3]f32{ 0.25, 0.4, 0.5 }, v3.data);
    try testing.expectEqual([3]f32{ 0.25, 0.4, 0.5 }, v4.data);
    try testing.expectEqual([3]f32{ 0.5, 1.0, 1.5 }, v5.data);

    // division of same type with different size
    const v6 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v7 = try v1.div(v6);

    const a1 = [3]f64{ 4.0, 5.0, 6.0 };
    const v8 = try v1.div(a1);

    const s1: f64 = 2.0;
    const v9 = try v1.div(s1);
    try testing.expectEqual([3]f32{ 0.25, 0.4, 0.5 }, v7.data);
    try testing.expectEqual([3]f32{ 0.25, 0.4, 0.5 }, v8.data);
    try testing.expectEqual([3]f32{ 0.5, 1.0, 1.5 }, v9.data);

    // Signed Integral Vector
    // standard division of same type and size
    const v10 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    const v11 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v12 = try v10.div(v11);
    const v13 = try v10.div(.{ 1, 2, 3 });
    const v14 = try v10.div(2);
    try testing.expectEqual([3]i32{ 4, 2, 2 }, v12.data);
    try testing.expectEqual([3]i32{ 4, 2, 2 }, v13.data);
    try testing.expectEqual([3]i32{ 2, 2, 3 }, v14.data);

    // division of same type with different size
    const v15 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const v16 = try v11.div(v15);

    const a2 = [3]i64{ 4, 5, 6 };
    const v17 = try v11.div(a2);

    const s2: i64 = 2;
    const v18 = try v11.div(s2);
    try testing.expectEqual([3]i32{ 0, 0, 0 }, v16.data);
    try testing.expectEqual([3]i32{ 0, 0, 0 }, v17.data);
    try testing.expectEqual([3]i32{ 0, 1, 1 }, v18.data);

    // Both Vector types
    // division of different type and size
    const v19 = try v1.div(v15);
    const v20 = try v11.div(v6);
    try testing.expectEqual([3]f32{ 0.25, 0.4, 0.5 }, v19.data);
    try testing.expectEqual([3]i32{ 0, 0, 0 }, v20.data);

    const v21 = try v1.div(a2);
    const v22 = try v11.div(a1);
    try testing.expectEqual([3]f32{ 0.25, 0.4, 0.5 }, v21.data);
    try testing.expectEqual([3]i32{ 0, 0, 0 }, v22.data);

    const v23 = try v1.div(s2);
    const v24 = try v11.div(s1);
    try testing.expectEqual([3]f32{ 0.5, 1.0, 1.5 }, v23.data);
    try testing.expectEqual([3]i32{ 0, 1, 1 }, v24.data);
}

test "Modulus" {
    // Floating point Vector
    // standard modulus of same type and size
    const v1 = Vec(f32, 3).initA(.{ 2.0, 5.0, 8.0 });
    const v2 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v3 = try v1.mod(v2);
    const v4 = try v1.mod(.{ 1.0, 2.0, 3.0 });
    const v5 = try v1.mod(2.0);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v3.data);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v4.data);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 0.0 }, v5.data);

    // modulus of same type with different size
    const v6 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v7 = try v1.mod(v6);

    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const v8 = try v1.mod(a1);

    const s1: f64 = 2.0;
    const v9 = try v1.mod(s1);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v7.data);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v8.data);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 0.0 }, v9.data);

    // Signed Integral Vector
    // standard modulus of same type and size
    const v10 = Vec(i32, 3).initA(.{ 2, 5, 8 });
    const v11 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v12 = try v10.mod(v11);
    const v13 = try v10.mod(.{ 1, 2, 3 });
    const v14 = try v10.mod(2);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v12.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v13.data);
    try testing.expectEqual([3]i32{ 0, 1, 0 }, v14.data);

    // modulus of same type with different size
    const v15 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v16 = try v10.mod(v15);

    const a2 = [3]i64{ 1, 2, 3 };
    const v17 = try v10.mod(a2);

    const s2: i64 = 2;
    const v18 = try v10.mod(s2);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v16.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v17.data);
    try testing.expectEqual([3]i32{ 0, 1, 0 }, v18.data);

    // Both Vector types
    // modulus of different type and size
    const v19 = try v1.mod(v15);
    const v20 = try v10.mod(v6);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v19.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v20.data);

    const v21 = try v1.mod(a2);
    const v22 = try v10.mod(a1);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v21.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v22.data);

    const v23 = try v1.mod(s2);
    const v24 = try v10.mod(s1);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 0.0 }, v23.data);
    try testing.expectEqual([3]i32{ 0, 1, 0 }, v24.data);
}

test "Remainder" {
    // Floating point Vector
    // standard remainder of same type and size
    const v1 = Vec(f32, 3).initA(.{ -2.0, -5.0, -8.0 });
    const v2 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v3 = try v1.rem(v2);
    const v4 = try v1.rem(.{ 1.0, 2.0, 3.0 });
    const v5 = try v1.rem(2.0);
    try testing.expectEqual([3]f32{ 0.0, -1.0, -2.0 }, v3.data);
    try testing.expectEqual([3]f32{ 0.0, -1.0, -2.0 }, v4.data);
    try testing.expectEqual([3]f32{ 0.0, -1.0, 0.0 }, v5.data);

    // remainder of same type with different size
    const v6 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v7 = try v1.rem(v6);

    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const v8 = try v1.rem(a1);

    const s1: f64 = 2.0;
    const v9 = try v1.rem(s1);
    try testing.expectEqual([3]f32{ 0.0, -1.0, -2.0 }, v7.data);
    try testing.expectEqual([3]f32{ 0.0, -1.0, -2.0 }, v8.data);
    try testing.expectEqual([3]f32{ 0.0, -1.0, 0.0 }, v9.data);

    // Signed Integral Vector
    // standard remainder of same type and size
    const v10 = Vec(i32, 3).initA(.{ -2, -5, -8 });
    const v11 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v12 = try v10.rem(v11);
    const v13 = try v10.rem(.{ 1, 2, 3 });
    const v14 = try v10.rem(2);
    try testing.expectEqual([3]i32{ 0, -1, -2 }, v12.data);
    try testing.expectEqual([3]i32{ 0, -1, -2 }, v13.data);
    try testing.expectEqual([3]i32{ 0, -1, 0 }, v14.data);

    // remainder of same type with different size
    const v15 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v16 = try v10.rem(v15);

    const a2 = [3]i64{ 1, 2, 3 };
    const v17 = try v10.rem(a2);

    const s2: i64 = 2;
    const v18 = try v10.rem(s2);
    try testing.expectEqual([3]i32{ 0, -1, -2 }, v16.data);
    try testing.expectEqual([3]i32{ 0, -1, -2 }, v17.data);
    try testing.expectEqual([3]i32{ 0, -1, 0 }, v18.data);

    // Both Vector types
    // remainder of different type and size
    const v19 = try v1.rem(v15);
    const v20 = try v10.rem(v6);
    try testing.expectEqual([3]f32{ 0.0, -1.0, -2.0 }, v19.data);
    try testing.expectEqual([3]i32{ 0, -1, -2 }, v20.data);

    const v21 = try v1.rem(a2);
    const v22 = try v10.rem(a1);
    try testing.expectEqual([3]f32{ 0.0, -1.0, -2.0 }, v21.data);
    try testing.expectEqual([3]i32{ 0, -1, -2 }, v22.data);

    const v23 = try v1.rem(s2);
    const v24 = try v10.rem(s1);
    try testing.expectEqual([3]f32{ 0.0, -1.0, 0.0 }, v23.data);
    try testing.expectEqual([3]i32{ 0, -1, 0 }, v24.data);
}

test "Greater than" {
    // Floating point Vector
    // standard greater than of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    try testing.expect(@reduce(.And, v2.greater(v1)));
    try testing.expect(!@reduce(.And, v2.greater(v2)));
    try testing.expect(@reduce(.And, v2.greater(.{ 1.0, 2.0, 3.0 })));
    try testing.expect(!@reduce(.And, v2.greater(.{ 4.0, 5.0, 6.0 })));
    try testing.expect(@reduce(.And, v2.greater(3.0)));
    try testing.expect(!@reduce(.And, v2.greater(6.0)));

    // greater than of same type with different size
    const v3 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v4 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const a2 = [3]f64{ 4.0, 5.0, 6.0 };
    const s1: f64 = 3.0;
    const s2: f64 = 6.0;
    try testing.expect(@reduce(.And, v2.greater(v3)));
    try testing.expect(!@reduce(.And, v2.greater(v4)));
    try testing.expect(@reduce(.And, v2.greater(a1)));
    try testing.expect(!@reduce(.And, v2.greater(a2)));
    try testing.expect(@reduce(.And, v2.greater(s1)));
    try testing.expect(!@reduce(.And, v2.greater(s2)));

    // Signed Integral Vector
    // standard greater than of same type and size
    const v5 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v6 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    try testing.expect(@reduce(.And, v6.greater(v5)));
    try testing.expect(!@reduce(.And, v6.greater(v6)));
    try testing.expect(@reduce(.And, v6.greater(.{ 1, 2, 3 })));
    try testing.expect(!@reduce(.And, v6.greater(.{ 4, 5, 6 })));
    try testing.expect(@reduce(.And, v6.greater(3)));
    try testing.expect(!@reduce(.And, v6.greater(6)));

    // greater than of same type with different size
    const v7 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v8 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const a3 = [3]i64{ 1, 2, 3 };
    const a4 = [3]i64{ 4, 5, 6 };
    const s3: i64 = 3;
    const s4: i64 = 6;
    try testing.expect(@reduce(.And, v6.greater(v7)));
    try testing.expect(!@reduce(.And, v6.greater(v8)));
    try testing.expect(@reduce(.And, v6.greater(a3)));
    try testing.expect(!@reduce(.And, v6.greater(a4)));
    try testing.expect(@reduce(.And, v6.greater(s3)));
    try testing.expect(!@reduce(.And, v6.greater(s4)));

    // Both Vector types
    // greater than of different type and size
    try testing.expect(@reduce(.And, v2.greater(v7)));
    try testing.expect(!@reduce(.And, v2.greater(v8)));
    try testing.expect(@reduce(.And, v6.greater(v3)));
    try testing.expect(!@reduce(.And, v6.greater(v4)));
    try testing.expect(@reduce(.And, v2.greater(a3)));
    try testing.expect(!@reduce(.And, v2.greater(a4)));
    try testing.expect(@reduce(.And, v6.greater(a1)));
    try testing.expect(!@reduce(.And, v6.greater(a2)));
    try testing.expect(@reduce(.And, v2.greater(s3)));
    try testing.expect(!@reduce(.And, v2.greater(s4)));
    try testing.expect(@reduce(.And, v6.greater(s1)));
    try testing.expect(!@reduce(.And, v6.greater(s2)));
}

test "Greater than or equal" {
    // Floating point Vector
    // standard greater than or equal of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    try testing.expect(@reduce(.And, v2.greaterEq(v1)));
    try testing.expect(@reduce(.And, v2.greaterEq(v2)));
    try testing.expect(@reduce(.And, v2.greaterEq(.{ 1.0, 2.0, 3.0 })));
    try testing.expect(@reduce(.And, v2.greaterEq(.{ 4.0, 5.0, 6.0 })));
    try testing.expect(@reduce(.And, v2.greaterEq(3.0)));
    try testing.expect(!@reduce(.And, v2.greaterEq(6.0)));

    // greater than or equal of same type with different size
    const v3 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v4 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const a2 = [3]f64{ 4.0, 5.0, 6.0 };
    const s1: f64 = 3.0;
    const s2: f64 = 6.0;
    try testing.expect(@reduce(.And, v2.greaterEq(v3)));
    try testing.expect(@reduce(.And, v2.greaterEq(v4)));
    try testing.expect(@reduce(.And, v2.greaterEq(a1)));
    try testing.expect(@reduce(.And, v2.greaterEq(a2)));
    try testing.expect(@reduce(.And, v2.greaterEq(s1)));
    try testing.expect(!@reduce(.And, v2.greaterEq(s2)));

    // Signed Integral Vector
    // standard greater than or equal of same type and size
    const v5 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v6 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    try testing.expect(@reduce(.And, v6.greaterEq(v5)));
    try testing.expect(@reduce(.And, v6.greaterEq(v6)));
    try testing.expect(@reduce(.And, v6.greaterEq(.{ 1, 2, 3 })));
    try testing.expect(@reduce(.And, v6.greaterEq(.{ 4, 5, 6 })));
    try testing.expect(@reduce(.And, v6.greaterEq(3)));
    try testing.expect(!@reduce(.And, v6.greaterEq(6)));

    // greater than or equal of same type with different size
    const v7 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v8 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const a3 = [3]i64{ 1, 2, 3 };
    const a4 = [3]i64{ 4, 5, 6 };
    const s3: i64 = 3;
    const s4: i64 = 6;
    try testing.expect(@reduce(.And, v6.greaterEq(v7)));
    try testing.expect(@reduce(.And, v6.greaterEq(v8)));
    try testing.expect(@reduce(.And, v6.greaterEq(a3)));
    try testing.expect(@reduce(.And, v6.greaterEq(a4)));
    try testing.expect(@reduce(.And, v6.greaterEq(s3)));
    try testing.expect(!@reduce(.And, v6.greaterEq(s4)));

    // Both Vector types
    // greater than or equal of different type and size
    try testing.expect(@reduce(.And, v2.greaterEq(v7)));
    try testing.expect(@reduce(.And, v2.greaterEq(v8)));
    try testing.expect(@reduce(.And, v6.greaterEq(v3)));
    try testing.expect(@reduce(.And, v6.greaterEq(v4)));
    try testing.expect(@reduce(.And, v2.greaterEq(a3)));
    try testing.expect(@reduce(.And, v2.greaterEq(a4)));
    try testing.expect(@reduce(.And, v6.greaterEq(a1)));
    try testing.expect(@reduce(.And, v6.greaterEq(a2)));
    try testing.expect(@reduce(.And, v2.greaterEq(s3)));
    try testing.expect(!@reduce(.And, v2.greaterEq(s4)));
    try testing.expect(@reduce(.And, v6.greaterEq(s1)));
    try testing.expect(!@reduce(.And, v6.greaterEq(s2)));
}

test "Lesser than" {
    // Floating point Vector
    // standard lesser than of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    try testing.expect(@reduce(.And, v1.lesser(v2)));
    try testing.expect(!@reduce(.And, v1.lesser(v1)));
    try testing.expect(@reduce(.And, v1.lesser(.{ 4.0, 5.0, 6.0 })));
    try testing.expect(!@reduce(.And, v1.lesser(.{ 1.0, 2.0, 3.0 })));
    try testing.expect(@reduce(.And, v1.lesser(4.0)));
    try testing.expect(!@reduce(.And, v1.lesser(1.0)));

    // lesser than of same type with different size
    const v3 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v4 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const a2 = [3]f64{ 4.0, 5.0, 6.0 };
    const s1: f64 = 4.0;
    const s2: f64 = 1.0;
    try testing.expect(@reduce(.And, v1.lesser(v4)));
    try testing.expect(!@reduce(.And, v1.lesser(v3)));
    try testing.expect(@reduce(.And, v1.lesser(a2)));
    try testing.expect(!@reduce(.And, v1.lesser(a1)));
    try testing.expect(@reduce(.And, v1.lesser(s1)));
    try testing.expect(!@reduce(.And, v1.lesser(s2)));

    // Signed Integral Vector
    // standard lesser than of same type and size
    const v5 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v6 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    try testing.expect(@reduce(.And, v5.lesser(v6)));
    try testing.expect(!@reduce(.And, v5.lesser(v5)));
    try testing.expect(@reduce(.And, v5.lesser(.{ 4, 5, 6 })));
    try testing.expect(!@reduce(.And, v5.lesser(.{ 1, 2, 3 })));
    try testing.expect(@reduce(.And, v5.lesser(4)));
    try testing.expect(!@reduce(.And, v5.lesser(1)));

    // lesser than of same type with different size
    const v7 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v8 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const a3 = [3]i64{ 1, 2, 3 };
    const a4 = [3]i64{ 4, 5, 6 };
    const s3: i64 = 4;
    const s4: i64 = 1;
    try testing.expect(@reduce(.And, v5.lesser(v8)));
    try testing.expect(!@reduce(.And, v5.lesser(v7)));
    try testing.expect(@reduce(.And, v5.lesser(a4)));
    try testing.expect(!@reduce(.And, v5.lesser(a3)));
    try testing.expect(@reduce(.And, v5.lesser(s3)));
    try testing.expect(!@reduce(.And, v5.lesser(s4)));

    // Both Vector types
    // lesser than of different type and size
    try testing.expect(@reduce(.And, v1.lesser(v8)));
    try testing.expect(!@reduce(.And, v1.lesser(v7)));
    try testing.expect(@reduce(.And, v5.lesser(v4)));
    try testing.expect(!@reduce(.And, v5.lesser(v3)));
    try testing.expect(@reduce(.And, v1.lesser(a4)));
    try testing.expect(!@reduce(.And, v1.lesser(a3)));
    try testing.expect(@reduce(.And, v5.lesser(a2)));
    try testing.expect(!@reduce(.And, v5.lesser(a1)));
    try testing.expect(@reduce(.And, v1.lesser(s3)));
    try testing.expect(!@reduce(.And, v1.lesser(s4)));
    try testing.expect(@reduce(.And, v5.lesser(s1)));
    try testing.expect(!@reduce(.And, v5.lesser(s2)));
}

test "Lesser than or equal" {
    // Floating point Vector
    // standard lesser than or equal of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    try testing.expect(@reduce(.And, v1.lesserEq(v2)));
    try testing.expect(@reduce(.And, v1.lesserEq(v1)));
    try testing.expect(@reduce(.And, v1.lesserEq(.{ 4.0, 5.0, 6.0 })));
    try testing.expect(@reduce(.And, v1.lesserEq(.{ 1.0, 2.0, 3.0 })));
    try testing.expect(@reduce(.And, v1.lesserEq(4.0)));
    try testing.expect(!@reduce(.And, v1.lesserEq(1.0)));

    // lesser than or equal of same type with different size
    const v3 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v4 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const a2 = [3]f64{ 4.0, 5.0, 6.0 };
    const s1: f64 = 4.0;
    const s2: f64 = 1.0;
    try testing.expect(@reduce(.And, v1.lesserEq(v4)));
    try testing.expect(@reduce(.And, v1.lesserEq(v3)));
    try testing.expect(@reduce(.And, v1.lesserEq(a2)));
    try testing.expect(@reduce(.And, v1.lesserEq(a1)));
    try testing.expect(@reduce(.And, v1.lesserEq(s1)));
    try testing.expect(!@reduce(.And, v1.lesserEq(s2)));

    // Signed Integral Vector
    // standard lesser than or equal of same type and size
    const v5 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v6 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    try testing.expect(@reduce(.And, v5.lesserEq(v6)));
    try testing.expect(@reduce(.And, v5.lesserEq(v5)));
    try testing.expect(@reduce(.And, v5.lesserEq(.{ 4, 5, 6 })));
    try testing.expect(@reduce(.And, v5.lesserEq(.{ 1, 2, 3 })));
    try testing.expect(@reduce(.And, v5.lesserEq(4)));
    try testing.expect(!@reduce(.And, v5.lesserEq(1)));

    // lesser than or equal of same type with different size
    const v7 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v8 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const a3 = [3]i64{ 1, 2, 3 };
    const a4 = [3]i64{ 4, 5, 6 };
    const s3: i64 = 4;
    const s4: i64 = 1;
    try testing.expect(@reduce(.And, v5.lesserEq(v8)));
    try testing.expect(@reduce(.And, v5.lesserEq(v7)));
    try testing.expect(@reduce(.And, v5.lesserEq(a4)));
    try testing.expect(@reduce(.And, v5.lesserEq(a3)));
    try testing.expect(@reduce(.And, v5.lesserEq(s3)));
    try testing.expect(!@reduce(.And, v5.lesserEq(s4)));

    // Both Vector types
    // lesser than or equal of different type and size
    try testing.expect(@reduce(.And, v1.lesserEq(v8)));
    try testing.expect(@reduce(.And, v1.lesserEq(v7)));
    try testing.expect(@reduce(.And, v5.lesserEq(v4)));
    try testing.expect(@reduce(.And, v5.lesserEq(v3)));
    try testing.expect(@reduce(.And, v1.lesserEq(a4)));
    try testing.expect(@reduce(.And, v1.lesserEq(a3)));
    try testing.expect(@reduce(.And, v5.lesserEq(a2)));
    try testing.expect(@reduce(.And, v5.lesserEq(a1)));
    try testing.expect(@reduce(.And, v1.lesserEq(s3)));
    try testing.expect(!@reduce(.And, v1.lesserEq(s4)));
    try testing.expect(@reduce(.And, v5.lesserEq(s1)));
    try testing.expect(!@reduce(.And, v5.lesserEq(s2)));
}

test "Equality" {
    // Signed Integral Vector
    // standard equality of same type and size
    const v1 = Vec(i32, 3).initA(.{ 1, 1, 1 });
    const v2 = Vec(i32, 3).initA(.{ 4, 4, 4 });
    try testing.expect(@reduce(.And, v1.equals(v1)));
    try testing.expect(!@reduce(.Or, v1.equals(v2)));
    try testing.expect(@reduce(.And, v1.equals(.{ 1, 1, 1 })));
    try testing.expect(!@reduce(.Or, v1.equals(.{ 4, 4, 4 })));
    try testing.expect(@reduce(.And, v1.equals(1)));
    try testing.expect(!@reduce(.Or, v1.equals(4)));

    // equality of same type with different size
    const v3 = Vec(i64, 3).initA(.{ 1, 1, 1 });
    const v4 = Vec(i64, 3).initA(.{ 4, 4, 4 });
    const a1 = [3]i64{ 1, 1, 1 };
    const a2 = [3]i64{ 4, 4, 4 };
    const s1: i64 = 1;
    const s2: i64 = 4;
    try testing.expect(@reduce(.And, v1.equals(v3)));
    try testing.expect(!@reduce(.Or, v1.equals(v4)));
    try testing.expect(@reduce(.And, v1.equals(a1)));
    try testing.expect(!@reduce(.Or, v1.equals(a2)));
    try testing.expect(@reduce(.And, v1.equals(s1)));
    try testing.expect(!@reduce(.Or, v1.equals(s2)));

    // Floating point Vector
    // standard equality of same type and size
    const v5 = Vec(f32, 3).initA(.{ 1.0, 1.0, 1.0 });
    const v6 = Vec(f32, 3).initA(.{ 4.0, 4.0, 4.0 });
    try testing.expect(@reduce(.And, v5.equals(v5)));
    try testing.expect(!@reduce(.Or, v5.equals(v6)));
    try testing.expect(@reduce(.And, v5.equals(.{ 1.0, 1.0, 1.0 })));
    try testing.expect(!@reduce(.Or, v5.equals(.{ 4.0, 4.0, 4.0 })));
    try testing.expect(@reduce(.And, v5.equals(1.0)));
    try testing.expect(!@reduce(.Or, v5.equals(4.0)));

    // equality of same type with different size
    const v7 = Vec(f64, 3).initA(.{ 1.0, 1.0, 1.0 });
    const v8 = Vec(f64, 3).initA(.{ 4.0, 4.0, 4.0 });
    const a3 = [3]f64{ 1.0, 1.0, 1.0 };
    const a4 = [3]f64{ 4.0, 4.0, 4.0 };
    const s3: f64 = 1.0;
    const s4: f64 = 4.0;
    try testing.expect(@reduce(.And, v5.equals(v7)));
    try testing.expect(!@reduce(.Or, v5.equals(v8)));
    try testing.expect(@reduce(.And, v5.equals(a3)));
    try testing.expect(!@reduce(.Or, v5.equals(a4)));
    try testing.expect(@reduce(.And, v5.equals(s3)));
    try testing.expect(!@reduce(.Or, v5.equals(s4)));

    // Both Vector types
    // equality of different type and size
    try testing.expect(@reduce(.And, v1.equals(v7)));
    try testing.expect(!@reduce(.Or, v1.equals(v8)));
    try testing.expect(@reduce(.And, v5.equals(v3)));
    try testing.expect(!@reduce(.Or, v5.equals(v4)));
    try testing.expect(@reduce(.And, v1.equals(a3)));
    try testing.expect(!@reduce(.Or, v1.equals(a4)));
    try testing.expect(@reduce(.And, v5.equals(a1)));
    try testing.expect(!@reduce(.Or, v5.equals(a2)));
    try testing.expect(@reduce(.And, v1.equals(s3)));
    try testing.expect(!@reduce(.Or, v1.equals(s4)));
    try testing.expect(@reduce(.And, v5.equals(s1)));
    try testing.expect(!@reduce(.Or, v5.equals(s2)));
}

test "Approximately" {
    // Floating point Vector
    // standard equality of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 1.0, 1.0 });
    const v2 = Vec(f32, 3).initA(.{ 1.0000001, 0.9999999, 1.0000001 });
    const v3 = Vec(f32, 3).initA(.{ 1.0000003, 0.9999997, 1.0000003 });
    try testing.expect(@reduce(.And, v1.approx(v2, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approx(v3, 0.0000002)));
    try testing.expect(@reduce(.And, v1.approx(.{ 1.0000001, 0.9999999, 1.0000001 }, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approx(.{ 1.0000003, 0.9999997, 1.0000003 }, 0.0000002)));
    try testing.expect(@reduce(.And, v1.approx(1.0000001, 0.0000002)));
    try testing.expect(@reduce(.And, v1.approx(0.9999999, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approx(1.0000003, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approx(0.9999997, 0.0000002)));

    // equality of same type with different size
    const v4 = Vec(f64, 3).initA(.{ 1.0000001, 0.9999999, 1.0000001 });
    const v5 = Vec(f64, 3).initA(.{ 1.0000003, 0.9999997, 1.0000003 });
    const a1 = [3]f64{ 1.0000001, 0.9999999, 1.0000001 };
    const a2 = [3]f64{ 1.0000003, 0.9999997, 1.0000003 };
    const s1: f64 = 1.0000001;
    const s2: f64 = 0.9999999;
    const s3: f64 = 1.0000003;
    const s4: f64 = 0.9999997;
    try testing.expect(@reduce(.And, v1.approx(v4, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approx(v5, 0.0000002)));
    try testing.expect(@reduce(.And, v1.approx(a1, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approx(a2, 0.0000002)));
    try testing.expect(@reduce(.And, v1.approx(s1, 0.0000002)));
    try testing.expect(@reduce(.And, v1.approx(s2, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approx(s3, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approx(s4, 0.0000002)));

    // Signed Integral Vector
    // standard equality of same type and size
    const v6 = Vec(i32, 3).initA(.{ 1, 1, 1 });
    const v7 = Vec(i32, 3).initA(.{ 2, 3, 2 });
    try testing.expect(@reduce(.And, v6.approx(v6, 0)));
    try testing.expect(!@reduce(.Or, v6.approx(v7, 0)));
    try testing.expect(!@reduce(.And, v6.approx(v7, 1)));
    try testing.expect(@reduce(.Or, v6.approx(v7, 1)));
    try testing.expect(@reduce(.And, v6.approx(v7, 2)));

    // equality of same type with different size
    const v8 = Vec(i64, 3).initA(.{ 1, 1, 1 });
    const v9 = Vec(i64, 3).initA(.{ 2, 3, 2 });
    const a3 = [3]i64{ 1, 1, 1 };
    const a4 = [3]i64{ 2, 3, 2 };
    const s5: i64 = 1;
    const s6: i64 = 2;
    try testing.expect(@reduce(.And, v6.approx(v8, 0)));
    try testing.expect(!@reduce(.Or, v6.approx(v9, 0)));
    try testing.expect(!@reduce(.And, v6.approx(v9, 1)));
    try testing.expect(@reduce(.Or, v6.approx(v9, 1)));
    try testing.expect(@reduce(.And, v6.approx(v9, 2)));

    try testing.expect(@reduce(.And, v6.approx(a3, 0)));
    try testing.expect(!@reduce(.And, v6.approx(a4, 0)));
    try testing.expect(!@reduce(.Or, v6.approx(a4, 0)));
    try testing.expect(!@reduce(.And, v6.approx(a4, 1)));
    try testing.expect(@reduce(.Or, v6.approx(a4, 1)));
    try testing.expect(@reduce(.And, v6.approx(a4, 2)));

    try testing.expect(@reduce(.And, v6.approx(s5, 0)));
    try testing.expect(!@reduce(.Or, v6.approx(s6, 0)));
    try testing.expect(@reduce(.Or, v6.approx(s6, 1)));

    // Both Vector types
    // equality of different type and size
    try testing.expect(@reduce(.And, v8.approx(v1, 0)));
    try testing.expect(!@reduce(.Or, v9.approx(v1, 0)));
    try testing.expect(!@reduce(.And, v9.approx(v1, 1)));
    try testing.expect(@reduce(.Or, v9.approx(v1, 1)));
    try testing.expect(@reduce(.And, v9.approx(v1, 2)));

    try testing.expect(@reduce(.And, v4.approx(v6, 0.0000002)));
    try testing.expect(!@reduce(.Or, v5.approx(v6, 0.0000002)));

    try testing.expect(@reduce(.And, Vec(i64, 3).initA(a3).approx(v1.data, 0)));
    try testing.expect(!@reduce(.Or, Vec(i64, 3).initA(a4).approx(v1.data, 0)));
    try testing.expect(!@reduce(.And, Vec(i64, 3).initA(a4).approx(v1.data, 1)));
    try testing.expect(@reduce(.Or, Vec(i64, 3).initA(a4).approx(v1.data, 1)));
    try testing.expect(@reduce(.And, Vec(i64, 3).initA(a4).approx(v1.data, 2)));

    try testing.expect(@reduce(.And, Vec(f64, 3).initA(a1).approx(v6.data, 0.0000002)));
    try testing.expect(!@reduce(.Or, Vec(f64, 3).initA(a2).approx(v6.data, 0.0000002)));

    try testing.expect(@reduce(.And, Vec(i64, 3).initS(s5).approx(v1.data[0], 0)));
    try testing.expect(!@reduce(.Or, Vec(i64, 3).initS(s6).approx(v1.data[0], 0)));
    try testing.expect(@reduce(.And, Vec(i64, 3).initS(s6).approx(v1.data[0], 1)));

    try testing.expect(@reduce(.And, Vec(f64, 3).initS(s1).approx(v6.data[0], 0.0000002)));
    try testing.expect(@reduce(.And, Vec(f64, 3).initS(s2).approx(v6.data[0], 0.0000002)));
    try testing.expect(!@reduce(.Or, Vec(f64, 3).initS(s3).approx(v6.data[0], 0.0000002)));
    try testing.expect(!@reduce(.Or, Vec(f64, 3).initS(s4).approx(v6.data[0], 0.0000002)));
}

test "Dot product" {
    // Floating point Vector
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    const dot = v1.inner(v2);
    try testing.expectEqual(32.0, dot);

    const outer1d = v1.outer1d(v2);
    try testing.expectEqual([9]f32{ 4.0, 5.0, 6.0, 8.0, 10.0, 12.0, 12.0, 15.0, 18.0 }, outer1d);

    const outer2d = v1.outer2d(v2);
    try testing.expectEqual([3][3]f32{
        .{ 4.0, 5.0, 6.0 },
        .{ 8.0, 10.0, 12.0 },
        .{ 12.0, 15.0, 18.0 },
    }, outer2d);

    // Signed Integral Vector
    const v3 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v4 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    const dot2 = v3.inner(v4);
    try testing.expectEqual(32, dot2);

    const outer1d2 = v3.outer1d(v4);
    try testing.expectEqual([9]i32{ 4, 5, 6, 8, 10, 12, 12, 15, 18 }, outer1d2);

    const outer2d2 = v3.outer2d(v4);
    try testing.expectEqual([3][3]i32{
        .{ 4, 5, 6 },
        .{ 8, 10, 12 },
        .{ 12, 15, 18 },
    }, outer2d2);
}

test "Cross product" {
    // Floating point Vector
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    const cross1 = Vec(f32, 3).cross(.{ v1, v2 });
    const cross2 = Vec(f32, 3).cross(.{ v2, v1 });
    try testing.expectEqual([3]f32{ -3.0, 6.0, -3.0 }, cross1.data);
    try testing.expectEqual([3]f32{ 3.0, -6.0, 3.0 }, cross2.data);

    // Signed Integral Vector
    const v3 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v4 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    const cross3 = Vec(i32, 3).cross(.{ v3, v4 });
    const cross4 = Vec(i32, 3).cross(.{ v4, v3 });
    try testing.expectEqual([3]i32{ -3, 6, -3 }, cross3.data);
    try testing.expectEqual([3]i32{ 3, -6, 3 }, cross4.data);
}

test "Length" {
    // Floating point Vector
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const len1 = v1.length();
    try testing.expectEqual(3.7416573867739413, len1);

    const v2 = Vec(f32, 3).initA(.{ 0.0, 0.0, 0.0 });
    const len2 = v2.length();
    try testing.expectEqual(0.0, len2);

    const len3 = v1.length2();
    try testing.expectEqual(14.0, len3);

    const len4 = v2.length2();
    try testing.expectEqual(0.0, len4);

    // Signed Integral Vector
    const v3 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const len5 = v3.length();
    try testing.expectEqual(3.7416573867739413, len5);

    const v4 = Vec(i32, 3).initA(.{ 0, 0, 0 });
    const len6 = v4.length();
    try testing.expectEqual(0.0, len6);

    const len7 = v3.length2();
    try testing.expectEqual(14, len7);

    const len8 = v4.length2();
    try testing.expectEqual(0, len8);
}

// test "Normalize/Inverse/Negate" {
//     const v1 = Vec(f32, 3).init(.{ 1.0, 2.0, 3.0 });
//     const v2 = v1.normalized();
//     try testing.expectEqual([3]f32{ 0.2672612369060519, 0.5345224738121038, 0.8017836807181557 }, v2.?.data);
//
//     const v3 = Vec(f32, 3).init(.{ 0.0, 0.0, 0.0 });
//     const v4 = v3.normalized();
//     try testing.expectEqual(null, v4);
//
//     const v5 = v1.inversed();
//     const v6 = v1.negated();
//     try testing.expectEqual([3]f32{ 1.0, 0.5, 0.33333334 }, v5.data);
//     try testing.expectEqual([3]f32{ -1.0, -2.0, -3.0 }, v6.data);
// }

test "Direction" {
    // Floating point Vector
    // standard direction of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    const dir1 = v1.dirToV(v2);
    const dir2 = v1.dirToA(.{ 4.0, 5.0, 6.0 });
    const dir3 = v1.dirToS(4.0);
    try testing.expectEqual([3]f32{ 5.773503e-1, 5.773503e-1, 5.773503e-1 }, dir1.data);
    try testing.expectEqual([3]f32{ 5.773503e-1, 5.773503e-1, 5.773503e-1 }, dir2.data);
    try testing.expectEqual([3]f32{ 8.017837e-1, 5.345225e-1, 2.6726124e-1 }, dir3.data);

    // direction of same type with different size
    const v3 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const a1 = [3]f64{ 4.0, 5.0, 6.0 };
    const s1: f64 = 4.0;
    const dir4 = v1.dirToFromV(f64, v3);
    const dir5 = v1.dirToFromA(f64, a1);
    const dir6 = v1.dirToFromS(f64, s1);
    try testing.expectEqual([3]f32{ 5.773503e-1, 5.773503e-1, 5.773503e-1 }, dir4.data);
    try testing.expectEqual([3]f32{ 5.773503e-1, 5.773503e-1, 5.773503e-1 }, dir5.data);
    try testing.expectEqual([3]f32{ 8.017837e-1, 5.345225e-1, 2.6726124e-1 }, dir6.data);

    // Signed Integral Vector
    // standard direction of same type and size
    const v4 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v5 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    const dir7 = v4.dirToV(v5);
    const dir8 = v4.dirToA(.{ 4, 5, 6 });
    const dir9 = v4.dirToS(4);
    try testing.expectEqual([3]f32{ 5.773503e-1, 5.773503e-1, 5.773503e-1 }, dir7.data);
    try testing.expectEqual([3]f32{ 5.773503e-1, 5.773503e-1, 5.773503e-1 }, dir8.data);
    try testing.expectEqual([3]f32{ 8.017837e-1, 5.345225e-1, 2.6726124e-1 }, dir9.data);

    // direction of same type with different size
    const v6 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const a2 = [3]i64{ 4, 5, 6 };
    const s2: i64 = 4;
    const dir10 = v4.dirToFromV(i64, v6);
    const dir11 = v4.dirToFromA(i64, a2);
    const dir12 = v4.dirToFromS(i64, s2);
    try testing.expectEqual([3]f32{ 5.773503e-1, 5.773503e-1, 5.773503e-1 }, dir10.data);
    try testing.expectEqual([3]f32{ 5.773503e-1, 5.773503e-1, 5.773503e-1 }, dir11.data);
    try testing.expectEqual([3]f32{ 8.017837e-1, 5.345225e-1, 2.6726124e-1 }, dir12.data);

    // Both Vector types
    // direction of different type and size
    const dir13 = v1.dirToFromV(i64, v6);
    const dir14 = v1.dirToFromA(i64, a2);
    const dir15 = v1.dirToFromS(i64, s2);
    try testing.expectEqual([3]f32{ 5.773503e-1, 5.773503e-1, 5.773503e-1 }, dir13.data);
    try testing.expectEqual([3]f32{ 5.773503e-1, 5.773503e-1, 5.773503e-1 }, dir14.data);
    try testing.expectEqual([3]f32{ 8.017837e-1, 5.345225e-1, 2.6726124e-1 }, dir15.data);

    const dir16 = v4.dirToFromV(f64, v3);
    const dir17 = v4.dirToFromA(f64, a1);
    const dir18 = v4.dirToFromS(f64, s1);
    try testing.expectEqual([3]f32{ 5.773503e-1, 5.773503e-1, 5.773503e-1 }, dir16.data);
    try testing.expectEqual([3]f32{ 5.773503e-1, 5.773503e-1, 5.773503e-1 }, dir17.data);
    try testing.expectEqual([3]f32{ 8.017837e-1, 5.345225e-1, 2.6726124e-1 }, dir18.data);
}

// test "Distance" {
//     const v1 = Vec(f32, 3).init(.{ 1.0, 2.0, 3.0 });
//     const v2 = Vec(f32, 3).init(.{ 4.0, 5.0, 6.0 });
//     const dist = v1.distTo(v2);
//     try testing.expectEqual(5.1961524, dist);
//
//     const dist2 = v2.distTo(v2);
//     try testing.expectEqual(0.0, dist2);
//
//     const dist3 = v1.distTo2(v2);
//     try testing.expectEqual(27.0, dist3);
//
//     const dist4 = v2.distTo2(v2);
//     try testing.expectEqual(0.0, dist4);
// }
//
// test "Lerp" {
//     const v1 = Vec(f32, 3).init(.{ 1.0, 2.0, 3.0 });
//     const v2 = Vec(f32, 3).init(.{ 4.0, 5.0, 6.0 });
//     const v3 = v1.lerp(v2, 0.5);
//     try testing.expectEqual([3]f32{ 2.5, 3.5, 4.5 }, v3.data);
// }
//
// test "Min/Max" {
//     const v1 = Vec(f32, 3).init(.{ 1.0, 5.0, 3.0 });
//     const v2 = Vec(f32, 3).init(.{ 4.0, 2.0, 6.0 });
//
//     const v3 = v1.maxOfs(v2);
//     const v4 = v1.minOfs(v2);
//     try testing.expectEqual([3]f32{ 4.0, 5.0, 6.0 }, v3.data);
//     try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v4.data);
//
//     const v5 = v1.maxed();
//     const v6 = v2.mined();
//     try testing.expectEqual([3]f32{ 5.0, 5.0, 5.0 }, v5.data);
//     try testing.expectEqual([3]f32{ 2.0, 2.0, 2.0 }, v6.data);
//
//     const t1 = v1.maxOf(v2);
//     const t2 = v1.minOf(v2);
//     try testing.expectEqual(6.0, t1);
//     try testing.expectEqual(1.0, t2);
// }
//
// test "To size" {
//     const v1 = Vec(f32, 3).init(.{ 1.0, 2.0, 3.0 });
//     const v2 = v1.toSize(2);
//     try testing.expectEqual([2]f32{ 1.0, 2.0 }, v2.data);
//
//     const v3 = Vec(f32, 3).init(.{ 1.0, 2.0, 3.0 });
//     const v4 = v3.toSize(4);
//     try testing.expectEqual([4]f32{ 1.0, 2.0, 3.0, 0.0 }, v4.data);
// }
//
// test "To type" {
//     const v1 = Vec(f32, 3).init(.{ 1.0, 2.0, 3.0 });
//     const v2 = v1.toType(f64);
//     const v3 = v2.toType(f32);
//     try testing.expectEqual([3]f64{ 1.0, 2.0, 3.0 }, v2.data);
//     try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v3.data);
// }
//
// test "Format" {
//     const v1 = Vec(f32, 3).init(.{ 1.0, 2.0, 3.0 });
//     var buf: [64]u8 = [_]u8{0} ** 64;
//     var fbs = std.io.fixedBufferStream(buf[0..]);
//     try std.fmt.format(fbs.writer().any(), "{}", .{v1});
//     try testing.expect(std.mem.eql(u8, "Vec3(1, 2, 3)", fbs.getWritten()));
// }
//
// // Vec2, Vec3, Vec4
// test "Vec2.from()" {
//     const vn = Vec(f32, 2).init(.{ 1.0, 2.0 });
//     const v2 = Vec2(f32).from(vn);
//     try testing.expectEqual(1.0, v2.x);
//     try testing.expectEqual(2.0, v2.y);
// }
//
// test "Vec2.to()" {
//     const vn = Vec(f32, 2).init(.{ 1.0, 2.0 });
//     const v2 = Vec2(f32).from(vn);
//     const vn2 = v2.to();
//     try testing.expectEqual([2]f32{ 1.0, 2.0 }, vn2.data);
// }
//
// test "Vec2 as *Vec" {
//     const v2 = Vec2(f32).init(.{ 1.0, 2.0 });
//     try testing.expectEqual([2]f32{ 2.0, 4.0 }, v2.as().addV(v2.as().*).data);
// }
//
// test "Vec2/3.cross()" {
//     {
//         const v1 = Vec2(f32).init(.{ 1.0, 0.0 });
//         const cross = v1.cross();
//         try testing.expectEqual([2]f32{ 0.0, 1.0 }, cross.as().data);
//     }
//
//     {
//         const v1 = Vec3(f32).init(.{ 1.0, 0.0, 0.0 });
//         const v2 = Vec3(f32).init(.{ 0.0, 1.0, 0.0 });
//         const cross = v1.cross(v2);
//         try testing.expectEqual([3]f32{ 0.0, 0.0, 1.0 }, cross.as().data);
//     }
// }
