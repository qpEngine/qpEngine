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
pub fn Vec(
    comptime T: type,
    comptime N: u16,
) type {
    switch (@typeInfo(T)) {
        .int => |info| if (info.signedness == .unsigned) @compileError("Vec element type must be signed"),
        .float => {},
        else => @compileError("Vec element type must be numeric"),
    }

    return struct {
        data: [N]T,

        const Self = @This(); // Type alias for self Vec type
        const Alt = Vec(f32, N); // Alternate Vec return type of integral type vectors
        const R = f32; // Alternate scalar return type of Integral type vectors
        const V = @Vector(N, T); // SIMD vector representaiton of self
        const W = @Vector(N, R); // Alternate vector representation of integral type vectors
        const B = @Vector(N, bool); // Boolean vector type
        const len: u16 = N; // store Vec type length

        // These functions simplify the logic for when functions operate differently with
        // integral or floating point vectors, or take different types of inputs
        inline fn scalar(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) R else T;
        }

        inline fn vec(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) Alt else Self;
        }

        inline fn vector(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) W else V;
        }

        inline fn comp(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) comptime_int else comptime_float;
        }

        inline fn bounds(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) Self else vec(T);
        }

        pub const VecError = error{
            DivideByZero,
        };

        /// Public
        /// Default initialization
        ///
        /// Vector components are set to undefined
        ///
        /// < Vec(T, N): A new Vector
        pub inline fn init() Self {
            return .{ .data = undefined };
        }

        /// Public
        /// Comprehensive initialization
        ///
        /// Vector components are set based on provided value
        ///
        /// > value: anytype
        ///     Value to set components with
        ///
        /// < Vect(T, N): A new Vector
        pub inline fn from(
            value_: anytype,
        ) Self {
            return .{ .data = vectorFromAny(value_, 0) };
        }

        /// Public
        /// Cast as SIMD Vector
        ///
        /// Cast Vector to SIMD Vector
        ///
        /// < @Vector(N, T): SIMD Vector
        pub inline fn as(
            self: *const Self,
        ) V {
            return self.data;
        }

        /// Public
        /// Convert Vector to new size
        ///
        /// Creates a new Vector of size M from current Vector
        ///
        /// If target size is smaller, excess elements are truncated
        /// If target size is larger, new elements are filled with provided value
        ///
        /// > M: comptime u8
        ///     Size of new Vector
        ///
        /// > fill: comptime_int | comptime_float
        ///     Value to fill new Vector with
        ///
        /// < Vec(T, M): A new Vector
        pub inline fn toSize(
            self: Self,
            comptime M_: u8,
            fill_: comp(T),
        ) Vec(T, M_) {
            if (M_ == N) return self;
            var result = Vec(T, M_).from(fill_);
            const min_size = @min(N, M_);
            result.data[0..min_size].* = self.data[0..min_size].*;
            return result;
        }

        /// Private
        /// Convert scalar to new type
        ///
        /// Cast from one scalar type to scalar type of Vector
        ///
        /// > I: type
        ///     Type that scalar is converted from
        ///
        /// > value: I
        ///     Value to convert
        ///
        /// < T: Converted value
        inline fn scalarFrom(
            comptime I: type,
            value_: I,
        ) T {
            return switch (@typeInfo(T)) {
                .int => switch (@typeInfo(I)) {
                    .int => @intCast(value_),
                    .float => @intFromFloat(value_),
                    else => @compileError("value_ type must be numeric"),
                },
                .float => switch (@typeInfo(I)) {
                    .int => @floatFromInt(value_),
                    .float => @floatCast(value_),
                    else => @compileError("value_ type must be numeric"),
                },
                else => @compileError("Vec element type must be numeric"),
            };
        }

        /// Private
        /// Convert array to new type
        ///
        /// Cast array of scalars from one type to scalar type of Vector
        ///
        /// > I: type
        ///    Type that array is converted from
        ///
        /// > values: [N]I
        ///     Array of values to convert
        ///
        /// < [N]T: Converted array
        inline fn arrayFrom(
            comptime I: type,
            values_: [N]I,
        ) [N]T {
            const Y: type = switch (I) {
                comptime_int, comptime_float => T,
                else => I,
            };
            // const a: @Vector(N, Y) = @as(@Vector(N, Y), values_);
            const a: @Vector(N, Y) = values_;

            return switch (@typeInfo(T)) {
                .int => switch (@typeInfo(Y)) {
                    .int => @as(V, @intCast(a)),
                    .float => @as(V, @intFromFloat(a)),
                    else => @compileError("Array element type must be numeric"),
                },
                .float => switch (@typeInfo(Y)) {
                    .int => @as(V, @floatFromInt(a)),
                    .float => @as(V, @floatCast(a)),
                    else => @compileError("Array element type must be numeric"),
                },
                else => @compileError("Vec element type must be numeric"),
            };
        }

        /// Private
        /// Resize an array
        ///
        /// Create a new array of size M from array of size N
        ///
        /// If target size is smaller, excess elements are truncated
        /// If target size is larger, new elements are filled with provided value
        ///
        /// > I: type
        ///     Type of array elements
        ///
        /// > M: u16
        ///     Size of new array
        ///
        /// > values: [N]I
        ///     Array to resize
        ///
        /// > fill: comptime_int | comptime_float
        ///     Value to fill new array with
        ///
        /// < [M]T: Resized array
        inline fn resizeArray(
            comptime I: type,
            M_: u16,
            values_: [M_]I,
            fill_: (if (@typeInfo(I) == .int) comptime_int else comptime_float),
        ) [N]T {
            comptime var old: [M_]I = values_;
            comptime var new: [N]I = [_]I{fill_} ** N;
            const min_size = @min(M_, N);
            new[0..min_size].* = old[0..min_size].*;
            return arrayFrom(I, new);
        }

        /// Private
        /// Convert any type to vector
        ///
        /// Convert any type to vector of type T
        ///
        /// If type is not supported, an error is thrown
        ///
        /// for scalars, splat of scalar is returned
        /// for arrays, array is converted to vector
        /// for pointers, pointer is dereferenced and converted to vector
        /// for vectors, vector is returned
        /// for structs, if struct has a 'data' field of type array, it is converted to vector
        ///
        /// > value: anytype
        ///    Value to convert
        ///
        /// > fill: comptime_int | comptime_float
        ///     Value to fill new vector with
        ///
        /// < @Vector(N, T): Converted vector
        inline fn vectorFromAny(
            value_: anytype,
            fill_: comp(T),
        ) V {
            const v_type = @TypeOf(value_);

            return switch (@typeInfo(v_type)) {
                .comptime_int, .comptime_float => @splat(value_),
                .int, .float => switch (v_type) {
                    T => @splat(value_),
                    else => @splat(scalarFrom(v_type, value_)),
                },
                .array => |a| switch (v_type) {
                    [N]T => value_,
                    else => arrayFrom(a.child, value_),
                },
                .pointer => |p| switch (v_type) {
                    []T => blk: {
                        if (value_.len != N) {
                            break :blk resizeArray(p.child, value_.len, value_, fill_);
                        }
                        break :blk value_.*;
                    },
                    else => Self.from(value_.*).as(),
                },
                .vector => |v| switch (v_type) {
                    V => value_,
                    else => blk: {
                        if (v.len != N) {
                            break :blk resizeArray(v.child, v.len, value_, fill_);
                        }
                        break :blk arrayFrom(@typeInfo(value_).child, value_);
                    },
                },
                .@"struct" => |s| switch (v_type) {
                    Self => value_.data,
                    else => blk: {
                        if (s.fields.len == 0) break :blk @splat(0);
                        if (s.is_tuple) {
                            const I: type = comptime iblk: {
                                var flag: bool = true;
                                const i: type = s.fields[0].type;
                                for (s.fields) |f| {
                                    flag = flag and f.type == i;
                                }
                                const msg = "Tuple elements must be of the same type";
                                break :iblk if (flag) i else @compileError(msg);
                            };
                            const size: usize = s.fields.len;
                            if (size != N) {
                                break :blk resizeArray(I, size, value_, fill_);
                            }
                            break :blk arrayFrom(I, value_);
                        } else if (@hasField(v_type, "data") and
                            @typeInfo(@FieldType(v_type, "data")) == .array)
                        {
                            const info: std.builtin.Type = @typeInfo(@FieldType(v_type, "data"));
                            break :blk arrayFrom(
                                info.array.child,
                                (if (v_type.len != N) value_.toSize(N, 0) else value_).data,
                            );
                        } else {
                            @compileError("Unsupported struct");
                            // TODO: Add support for other structs
                            // perhaps by expecting a 'toVec' method
                        }
                    },
                },
                else => {
                    @compileLog("Type: {any}\n", .{v_type});
                    @compileError("Unsupported type");
                },
            };
        }

        /// Public
        /// Positive unit vector
        ///
        /// Initialize vector with component at index set to 1, others to 0
        /// If index is out of bounds, vector is initialized to 0
        ///
        /// > index: usize
        ///     Index of component to set to 1
        ///
        /// < Vec(T, N): New positive Vector
        pub inline fn unitP(
            index_: usize,
        ) Self {
            var result = Self.from(0);
            if (index_ < N) {
                result.data[index_] = 1;
            }
            return result;
        }

        /// Public
        /// Negative unit vector
        ///
        /// Initialize vector with component at index set to -1, others to 0
        /// If index is out of bounds, vector is initialized to 0
        ///
        /// > index: usize
        ///     Index of component to set to -1
        ///
        /// < Vec(T, N): New negative unit Vector
        pub inline fn unitN(
            index_: usize,
        ) Self {
            var result = Self.from(0);
            if (index_ < N) {
                result.data[index_] = -1;
            }
            return result;
        }

        /// Public
        /// Swizzle vector components
        ///
        /// Generate a new vector with components picked from the current vector
        /// List of indices can be larger or smaller than current vector size
        ///
        /// > indices: []const i32
        ///     Indices of components to pick
        ///
        /// < Vec(T, indices.len): Swizzled Vector
        pub inline fn pick(
            self: Self,
            indices_: []const i32,
        ) Vec(T, indices_.len) {
            const a = self.data;
            const mask: @Vector(indices_.len, i32) = indices_[0..].*;

            return Vec(T, indices_.len).from(@shuffle(T, a, undefined, @abs(mask)));
        }

        /// Public
        /// Add two Vectors
        ///
        /// Summation of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to add
        ///
        /// < Vec(T, N): Sum Vector
        pub inline fn add(
            self: Self,
            other_: anytype,
        ) Self {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);

            return .{ .data = a + b };
        }

        /// Public
        /// Subtract two Vectors
        ///
        /// Difference of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to subtract
        ///
        /// < Vec(T, N): Difference Vector
        pub inline fn sub(
            self: Self,
            other_: anytype,
        ) Self {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);

            return .{ .data = a - b };
        }

        /// Public
        /// Multiply two Vectors
        ///
        /// Product of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to multiply
        ///
        /// < Vec(T, N): Product Vector
        pub inline fn mul(
            self: Self,
            other_: anytype,
        ) Self {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 1);

            return .{ .data = a * b };
        }

        /// Public
        /// Divide two Vectors
        ///
        /// Quotient of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to divide
        ///
        /// < Vec(T, N): Quotient Vector
        pub inline fn div(
            self: Self,
            other_: anytype,
        ) !Self {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 1);

            const c: V = @splat(0);
            const d: B = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = a / b };
        }

        /// Public
        /// Modulo two Vectors
        ///
        /// Modulus of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to divide
        ///
        /// < Vec(T, N): Modulus Vector
        pub inline fn mod(
            self: Self,
            other_: anytype,
        ) !Self {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 1);

            const c: V = @splat(0);
            const d: B = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = @mod(a, b) };
        }

        /// Public
        /// Get remainder from dividing two Vectors
        ///
        /// Remainder from division of ectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to divide
        ///
        /// < Vec(T, N): Remainder Vector
        pub inline fn rem(
            self: Self,
            other_: anytype,
        ) !Self {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 1);

            const c: V = @splat(0);
            const d: B = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = @rem(a, b) };
        }

        /// Public
        /// Lesser comparison of two Vectors
        ///
        /// Comparison of less than for one vector to another by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Vec(T, N): Comparison Vector
        pub inline fn lesser(
            self: Self,
            other_: anytype,
        ) B {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);

            return a < b;
        }

        /// Public
        /// Lesser or equal comparison of two Vectors
        ///
        /// Comparison of less than or equal for one vector to another by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Vec(T, N): Comparison Vector
        pub inline fn lesserEq(
            self: Self,
            other_: anytype,
        ) B {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);

            return a <= b;
        }

        /// Public
        /// Greater comparison of two Vectors
        ///
        /// Comparison of greater than for one vector to another by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Vec(T, N): Comparison Vector
        pub inline fn greater(
            self: Self,
            other_: anytype,
        ) B {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);

            return a > b;
        }

        /// Public
        /// Greater or equal comparison of two Vectors
        ///
        /// Comparison of greater than or equal for one vector to another by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Vec(T, N): Comparison Vector
        pub inline fn greaterEq(
            self: Self,
            other_: anytype,
        ) B {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);

            return a >= b;
        }

        /// Public
        /// Equality comparison of two Vectors
        ///
        /// Comparison of equality for one vector to another by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Vec(T, N): Comparison Vector
        pub inline fn equals(
            self: Self,
            other_: anytype,
        ) B {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);

            return a == b;
        }

        /// Public
        /// Approximate equality comparison of two Vectors
        ///
        /// Comparison of equality for one vector to another by components with tolerance
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///    Vector to compare
        ///
        /// > tolerance: ?T
        ///    Tolerance value for comparison
        ///    default: 0 | floatEps(T)
        ///
        /// < Vec(T, N): Comparison Vector
        pub inline fn approx(
            self: Self,
            other_: anytype,
            tolerance: ?T,
        ) B {
            const Y: type = comptime getY: {
                var y: std.builtin.Type = @typeInfo(T);
                if (y == .int) y.int.signedness = .unsigned;
                break :getY if (y == .float) T else @Type(y);
            };
            const t: Y = tolerance orelse if (Y == .float) std.math.floatEps(T) else 0;
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);

            const c: @Vector(N, Y) = @abs(a - b);
            const d: @Vector(N, Y) = @splat(t);

            return c <= d;
        }

        /// Public
        /// Inner dot product of two Vectors
        ///
        /// Compute dot product (inner) of two vectors
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compute dot product with
        ///
        /// < T: Dot product
        pub inline fn inner(
            self: Self,
            other_: anytype,
        ) T {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);
            const c: V = a * b;

            return @reduce(.Add, c);
        }

        /// Public
        /// Outer dot product of two Vectors
        ///
        /// Compute the outer product (for vectors results in a matrix)
        /// This returns a flat array in row-major order
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///    Vector to compute outer product with
        ///
        /// < [N * N]T: Outer product
        pub inline fn outer1d(
            self: Self,
            other_: anytype,
        ) [N * N]T {
            const a: @Vector(N * N, T) = std.simd.repeat(N * N, vectorFromAny(other_, 0));
            const s: V = self.data;
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

        /// Public
        /// Outer dot product of two Vectors
        ///
        /// Compute the outer product (for vectors results in a matrix)
        /// This returns a 2d array in row-major order
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///    Vector to compute outer product with
        ///
        /// < [N][N]T: Outer product
        pub inline fn outer2d(
            self: Self,
            other_: anytype,
        ) [N][N]T {
            return @bitCast(outer1d(self, other_));
        }

        /// Public
        /// Cross product of a set of Vectors
        ///
        /// Compute the cross product of N-1 vectors
        /// Uses matrix expansion to find determinants
        ///
        /// > vectors: [N - 1]Self
        ///    Vectors to compute cross product with
        ///
        /// < Vec(T, N): Cross product as Vector
        pub fn cross(
            vectors_: [N - 1]Self,
        ) Self {
            var result: [N]T = undefined;

            var matrix: [N][N]T = undefined;

            for (vectors_, 0..) |v, i| {
                matrix[i] = v.data;
            }
            matrix[N - 1] = [_]T{0} ** N;

            for (0..N) |i| {
                matrix[N - 1][i] = 1;

                result[i] = determinant(N, &matrix);

                matrix[N - 1][i] = 0;
            }

            return Self.from(result);
        }

        /// Private
        /// Calculate determinant of matrix
        ///
        /// Recursive function to calculate determinant of matrix
        /// using submatrix expansion
        ///
        /// > n: u16
        ///     Size of matrix
        ///
        /// > matrix: *[n][n]T
        ///     Matrix to calculate determinant of
        ///
        /// < T: Determinant
        fn determinant(
            comptime n: u16,
            matrix_: *[n][n]T,
        ) T {
            const nm = n - 1;

            if (n == 1) {
                return matrix_[0][0];
            }

            var det: T = 0;

            for (0..n) |i| {
                var submatrix_: [nm][nm]T = @bitCast([_]T{0} ** (nm * nm));

                for (1..n) |j| {
                    var sub_col_index: usize = 0;
                    for (0..n) |k| {
                        if (k == i) continue;
                        submatrix_[j - 1][sub_col_index] = matrix_[j][k];
                        sub_col_index += 1;
                    }
                }

                const sub_det = determinant(nm, &submatrix_);

                if (i % 2 == 0) {
                    det += matrix_[0][i] * sub_det;
                } else {
                    det -= matrix_[0][i] * sub_det;
                }
            }

            return det;
        }

        /// Public
        /// Length of vector
        ///
        /// Calculate length (magnitude) of vector
        /// returns float if vector element type is int
        ///
        /// < T | f32: Length
        pub inline fn length(
            self: Self,
        ) scalar(T) {
            return switch (@typeInfo(T)) {
                .float => @sqrt(self.inner(self)),
                .int => @sqrt(@as(R, @floatFromInt(self.inner(self)))),
                else => @compileError("Vec element type must be numeric"),
            };
        }

        /// Public
        /// Squared length of vector
        ///
        /// Calculate squared length of vector
        ///
        /// < T: Squared length
        pub inline fn length2(
            self: Self,
        ) T {
            return self.inner(self);
        }

        /// Public
        /// Normalized form of vector
        ///
        /// Return Vector normalized to unit length
        /// If vector length is 0, null is returned
        /// returns float vector type if vector element type is int
        ///
        /// < Vec(T, N) | Vec(f32, N): Normalized Vector
        pub inline fn normalized(
            self: Self,
        ) ?vec(T) {
            const v_len = self.length();
            if (v_len == 0) return null;
            return switch (@typeInfo(T)) {
                .float => self.div(v_len) catch unreachable,
                .int => Alt.from(self.data).div(v_len) catch unreachable,
                else => unreachable,
            };
        }

        /// Public
        /// Direction to another Vector
        ///
        /// Calculate direction vector from self to other vector
        /// If other vector is null, zero vector is returned
        /// returns float vector type if vector element type is int
        /// other vector converterd from anytype
        ///class
        /// > other: anytype
        ///     Vector to calculate direction to
        ///
        /// < Vec(T, N) | Vec(f32, N): Direction Vector
        pub inline fn dirTo(
            self: Self,
            other_: anytype,
        ) vec(T) {
            const new = if (@TypeOf(other_) == Self) other_ else Self.from(other_);
            return new.sub(self).normalized() orelse
                (vec(T)).from(0);
        }

        /// Public
        /// Distance between two vectors
        ///
        /// Calculate distance between self and other vector
        /// returns float if vector element type is int
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to calculate distance to
        ///
        /// < T | f32: Distance
        pub inline fn distTo(
            self: Self,
            other_: anytype,
        ) scalar(T) {
            const new = if (@TypeOf(other_) == Self) other_ else Self.from(other_);
            return switch (@typeInfo(T)) {
                .float => @sqrt(self.distTo2(new)),
                .int => @sqrt(@as(R, @floatFromInt(self.distTo2(new)))),
                else => @compileError("Vec element type must be numeric"),
            };
        }

        /// Public
        /// Squared distance between two vectors
        ///
        /// Calculate squared distance between self and other vector
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to calculate distance to
        ///
        /// < T: Squared distance
        pub inline fn distTo2(
            self: Self,
            other_: anytype,
        ) T {
            const new = if (@TypeOf(other_) == Self) other_ else Self.from(other_);
            return new.sub(self).length2();
        }

        /// Public
        /// Linear interpolation of two vectors
        ///
        /// Linear interpolates between self and other at time t
        /// returns float vector type if vector element type is int
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to interpolate to
        ///
        /// > t: T
        ///     Time to interpolate at
        ///
        /// < Vec(T, N) | Vec(f32, N): Interpolated Vector
        pub inline fn lerp(
            self: Self,
            other_: anytype,
            time_: f32,
        ) vec(T) {
            const new = if (@TypeOf(other_) == Self) other_ else Self.from(other_);
            return switch (@typeInfo(T)) {
                .float => self.mul(1 - time_).add(new.mul(time_)),
                .int => Alt.from(self.data).mul(1 - time_).add(Alt.from(other_.data).mul(time_)),
                else => @compileError("Vec element type must be numeric"),
            };
        }

        /// Public
        /// Maximum scalar of a vector
        ///
        /// Absolute max scalar of self
        ///
        /// < T: Max scalar
        pub inline fn max(
            self: Self,
        ) T {
            const a: V = self.data;
            return @reduce(.Max, a);
        }

        /// Public
        /// Minimum scalar of a vector
        ///
        /// Absolute min scalar of self
        ///
        /// < T: Min scalar
        pub inline fn min(
            self: Self,
        ) T {
            const a: V = self.data;
            return @reduce(.Min, a);
        }

        /// Public
        /// Maximum scalar of vectors
        ///
        /// Absolute max scalar between self and other
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < T: Max scalar
        pub inline fn maxOf(
            self: Self,
            other_: anytype,
        ) T {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);
            const c: T = @reduce(.Max, a);
            const d: T = @reduce(.Max, b);

            return @max(c, d);
        }

        /// Public
        /// Minimum scalar of vectors
        ///
        /// Absolute min scalar between self and other
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < T: Min scalar
        pub inline fn minOf(
            self: Self,
            other_: anytype,
        ) T {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);
            const c: T = @reduce(.Min, a);
            const d: T = @reduce(.Min, b);

            return @min(c, d);
        }

        /// Public
        /// Maximum vector of vectors
        ///
        /// Vector with component set to max of either self or other
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Vec(T, N): Max Vector
        pub inline fn maxOfs(
            self: Self,
            other_: anytype,
        ) Self {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);

            return .{ .data = @max(a, b) };
        }

        /// Public
        /// Minimum vector of vectors
        ///
        /// Vector with component set to min of either self or other
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Vec(T, N): Min Vector
        pub inline fn minOfs(
            self: Self,
            other_: anytype,
        ) Self {
            const a: V = self.data;
            const b: V = vectorFromAny(other_, 0);

            return .{ .data = @min(a, b) };
        }

        /// Public
        /// Vector of maximum scalar of vector
        ///
        /// Vector with max of self for all components
        ///
        /// < Vec(T, N): Maxxed Vector
        pub inline fn maxxed(
            self: Self,
        ) Self {
            const a: V = self.data;

            return .{ .data = @splat(@reduce(.Max, a)) };
        }

        /// Public
        /// Vector of minimum scalar of vector
        ///
        /// Vector with min of self for all components
        ///
        /// < Vec(T, N): Minned Vector
        pub inline fn minned(
            self: Self,
        ) Self {
            const a: V = self.data;

            return .{ .data = @splat(@reduce(.Min, a)) };
        }

        /// Public
        /// Vector with inverse of all components
        ///
        /// Vector with inverse of self for all components
        /// returns float vector type if vector element type is int
        ///
        /// < Vec(T, N): Inversed Vector
        pub inline fn inversed(
            self: Self,
        ) vec(T) {
            const a = switch (@typeInfo(T)) {
                .float => @as(V, self.data),
                .int => @as(W, @floatFromInt(self.as())),
                else => unreachable,
            };
            const b: vector(T) = @splat(1);

            return .{ .data = b / a };
        }

        /// Public
        /// Vector with negated components
        ///
        /// Vector with negated self for all components
        ///
        /// < Vec(T, N): Negated Vector
        pub inline fn negated(
            self: Self,
        ) Self {
            const a: V = self.data;
            const b: V = @splat(-1);

            return .{ .data = a * b };
        }

        /// Public
        /// Vector with negated and inversed components
        ///
        /// Vector with negated and inversed self for all components
        /// returns float vector type if vector element type is int
        ///
        /// < Vec(T, N): Negated and inversed Vector
        pub inline fn negInversed(
            self: Self,
        ) vec(T) {
            const a = switch (@typeInfo(T)) {
                .float => @as(V, self.data),
                .int => @as(W, @floatFromInt(self.as())),
                else => unreachable,
            };
            const b: vector(T) = @splat(-1);

            return .{ .data = b / a };
        }

        pub inline fn clamped(
            self: Self,
            min_: anytype,
            max_: anytype,
        ) bounds(@TypeOf(min_, max_)) {
            const min_t = @TypeOf(min_);
            if (!isNumeric(min_t)) @compileError("Min must be numeric scalar");

            const max_t = @TypeOf(max_);
            if (!isNumeric(max_t)) @compileError("Max must be numeric scalar");

            const I: type = @TypeOf(min_, max_);
            var a = switch (@typeInfo(T)) {
                .float => self.as(),
                .int => switch (@typeInfo(I)) {
                    .comptime_float, .float => @as(W, @floatFromInt(self.as())),
                    .comptime_int, .int => self.as(),
                    else => unreachable,
                },
                else => unreachable,
            };

            const min_v = switch (@typeInfo(I)) {
                .comptime_float, .float => switch (@typeInfo(min_t)) {
                    .comptime_float, .float => @as(vector(T), @splat(min_)),
                    .comptime_int, .int => @as(vector(T), @splat(@floatFromInt(min_))),
                    else => unreachable,
                },
                .comptime_int, .int => @as(V, @splat(min_)),
                else => unreachable,
            };

            const max_v = switch (@typeInfo(I)) {
                .comptime_float, .float => switch (@typeInfo(max_t)) {
                    .comptime_float, .float => @as(vector(T), @splat(max_)),
                    .comptime_int, .int => @as(vector(T), @splat(@floatFromInt(max_))),
                    else => unreachable,
                },
                .comptime_int, .int => @as(V, @splat(max_)),
                else => unreachable,
            };

            a = @max(min_v, a);
            return .{ .data = @min(max_v, a) };
        }

        pub inline fn project() void {}

        /// Public
        /// Vector to string
        ///
        /// Convert vector to formatted string
        /// Format is `Vec{N}({d}, ...)` where N is vector size
        ///
        /// > fmt: []const u8
        /// > options: std.fmt.FormatOptions
        /// > writer: anytype
        ///
        /// < void
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

inline fn isNumeric(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .comptime_int, .comptime_float => true,
        else => false,
    };
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

// NOTE: Fuzz testing not yet available on windows/macos
// test "Fuzz" {}

test "Initialize" {

    // useful data
    const a1 = [3]f32{ 1.0, 2.0, 3.0 };
    const simd1 = @as(@Vector(3, f32), a1);

    // casting
    {
        const v1 = Vec(f32, 3).from(a1);
        const v2: @Vector(3, f32) = .{ 1.0, 2.0, 3.0 };
        try testing.expectEqual(v2, v1.as());
    }

    // empty initialization
    {
        const v1 = Vec(f32, 3).init();
        try testing.expectEqual([3]f32{ undefined, undefined, undefined }, v1.data);
    }

    // splatting
    {
        // comptime_float
        const v1 = Vec(f32, 3).from(1.0);
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v1.data);

        // comptime_int
        const v2 = Vec(f32, 3).from(1);
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v2.data);

        // larger float
        const v3 = Vec(f32, 3).from(@as(f64, 1.0));
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v3.data);

        // int
        const v4 = Vec(f32, 3).from(@as(i32, 1));
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v4.data);

        // larger int
        const v5 = Vec(f32, 3).from(@as(i64, 1));
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v5.data);
    }

    // tuples
    {
        // full tuple
        const v1 = Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 });
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.data);

        // empty tuple
        const v2 = Vec(f32, 3).from(.{});
        try testing.expectEqual([3]f32{ 0, 0, 0 }, v2.data);

        // partial tuple
        const v3 = Vec(f32, 3).from(.{1.0});
        try testing.expectEqual([3]f32{ 1.0, 0, 0 }, v3.data);

        // overfull tuple
        const v4 = Vec(f32, 3).from(.{ 1.0, 2.0, 3.0, 4.0 });
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v4.data);

        // unacceptable tuple
        // WARNING: Expected Compiler Errors
        // const v5 = Vec(f32, 3).from(.{ true, true });
        // const v5 = Vec(f32, 3).from(.{ 1.0, true });
        // try testing.expectEqual([3]f32{ 1.0, 1.0, 0.0 }, v5.data);
    }

    // other vectors
    {
        // same type, size, length
        const v1 = Vec(f32, 3).from(1.0);
        const v2 = Vec(f32, 3).from(v1);
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v2.data);

        // different type, same size, length
        const v3 = Vec(i32, 3).from(v1);
        try testing.expectEqual([3]i32{ 1, 1, 1 }, v3.data);

        // same type, length, different size
        const v4 = Vec(f64, 3).from(v1);
        try testing.expectEqual([3]f64{ 1.0, 1.0, 1.0 }, v4.data);

        // different type, size, same length
        const v5 = Vec(i64, 3).from(v1);
        try testing.expectEqual([3]i64{ 1, 1, 1 }, v5.data);

        // different type, size, length
        const v6 = Vec(i64, 4).from(v1);
        try testing.expectEqual([4]i64{ 1, 1, 1, 0 }, v6.data);

        // different type, size, length
        const v7 = Vec(f16, 2).from(v5);
        try testing.expectEqual([2]f16{ 1.0, 1.0 }, v7.data);
    }

    // array
    {
        const v1 = Vec(f32, 3).from([3]f32{ 1.0, 2.0, 3.0 });
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.data);

        const v2 = Vec(i32, 3).from([3]i32{ 1, 2, 3 });
        try testing.expectEqual([3]i32{ 1, 2, 3 }, v2.data);
    }

    // simd vectors
    {
        const v1 = Vec(f32, 3).from(simd1);
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.data);

        const v2 = Vec(i32, 2).from(simd1);
        try testing.expectEqual([2]i32{ 1, 2 }, v2.data);

        const v3 = Vec(f64, 4).from(simd1);
        try testing.expectEqual([4]f64{ 1.0, 2.0, 3.0, 0.0 }, v3.data);
    }

    // pointer
    {
        const v1 = Vec(f32, 3).from(&a1);
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.data);

        const v2 = Vec(i32, 3).from(&a1);
        try testing.expectEqual([3]i32{ 1, 2, 3 }, v2.data);

        const v3 = Vec(f32, 3).from(&[3]f32{ 1.0, 2.0, 3.0 });
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v3.data);

        const v4 = Vec(f32, 3).from(a1[0..]);
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v4.data);
    }

    // unit vectors
    {
        const v1 = Vec(f32, 3).unitP(0);
        try testing.expectEqual([3]f32{ 1.0, 0.0, 0.0 }, v1.data);

        const v2 = Vec(f32, 3).unitP(1);
        try testing.expectEqual([3]f32{ 0.0, 1.0, 0.0 }, v2.data);

        const v3 = Vec(f32, 3).unitP(2);
        try testing.expectEqual([3]f32{ 0.0, 0.0, 1.0 }, v3.data);

        const v4 = Vec(f32, 3).unitN(0);
        try testing.expectEqual([3]f32{ -1.0, 0.0, 0.0 }, v4.data);

        const v5 = Vec(f32, 3).unitN(1);
        try testing.expectEqual([3]f32{ 0.0, -1.0, 0.0 }, v5.data);

        const v6 = Vec(f32, 3).unitN(2);
        try testing.expectEqual([3]f32{ 0.0, 0.0, -1.0 }, v6.data);
    }

    // pick
    {
        const v1 = Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 });
        const v2 = v1.pick(&.{ 1, 0 });
        const v3 = v1.pick(&.{ 1, 2, 0, 1 });
        try testing.expectEqual([2]f32{ 2.0, 1.0 }, v2.data);
        try testing.expectEqual([4]f32{ 2.0, 3.0, 1.0, 2.0 }, v3.data);

        const v4 = Vec(i64, 3).from(.{ 1, 2, 3 });
        const v5 = v4.pick(&.{ 1, 0 });
        const v6 = v4.pick(&.{ 1, 2, 0, 1 });
        try testing.expectEqual([2]i64{ 2, 1 }, v5.data);
        try testing.expectEqual([4]i64{ 2, 3, 1, 2 }, v6.data);
    }
}

test "Adddition" {
    const v1 = Vec(f32, 3).from(1.0);
    const v2 = Vec(f32, 3).from(2.0);
    try testing.expectEqual(Vec(f32, 3).from(3.0), v1.add(v2));

    const v3 = Vec(i64, 3).from(2);
    try testing.expectEqual(Vec(f32, 3).from(3), v1.add(v3));
}

test "Subtraction" {
    const v1 = Vec(f32, 3).from(1.0);
    const v2 = Vec(f32, 3).from(2.0);
    try testing.expectEqual(Vec(f32, 3).from(-1.0), v1.sub(v2));

    const v3 = Vec(i64, 3).from(2);
    try testing.expectEqual(Vec(f32, 3).from(-1), v1.sub(v3));
}

test "Multiplication" {
    const v1 = Vec(f32, 3).from(1.0);
    const v2 = Vec(f32, 3).from(2.0);
    try testing.expectEqual(Vec(f32, 3).from(2.0), v1.mul(v2));

    const v3 = Vec(i64, 3).from(2);
    try testing.expectEqual(Vec(f32, 3).from(2), v1.mul(v3));
}

test "Division" {
    const v1 = Vec(f32, 3).from(1.0);
    const v2 = Vec(f32, 3).from(2.0);
    try testing.expectEqual(Vec(f32, 3).from(0.5), v1.div(v2));

    const v3 = Vec(i64, 3).from(2);
    try testing.expectEqual(Vec(f32, 3).from(0.5), v1.div(v3));
}

test "Modulus" {
    const v1 = Vec(f32, 3).from(.{ 4.0, -5.0, 6.0 });
    const v2 = Vec(f32, 3).from(3.0);
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 1.0, 0.0 }), v1.mod(v2));

    const v3 = Vec(i64, 3).from(3);
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 1.0, 0.0 }), v1.mod(v3));
}

test "Remainder" {
    const v1 = Vec(f32, 3).from(.{ 4.0, -5.0, 6.0 });
    const v2 = Vec(f32, 3).from(3.0);
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, -2.0, 0.0 }), v1.rem(v2));

    const v3 = Vec(i64, 3).from(3);
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, -2.0, 0.0 }), v1.rem(v3));
}

test "Lesser" {
    const v1 = Vec(f32, 3).from(1.0);
    const v2 = Vec(f32, 3).from(2.0);
    try testing.expect(@reduce(.And, v1.lesser(v2)));
    try testing.expect(!@reduce(.Or, v1.lesser(v1)));

    const v3 = Vec(i64, 3).from(2);
    try testing.expect(@reduce(.And, v1.lesser(v3)));
}

test "LesserEq" {
    const v1 = Vec(f32, 3).from(1.0);
    const v2 = Vec(f32, 3).from(2.0);
    try testing.expect(@reduce(.And, v1.lesserEq(v2)));
    try testing.expect(@reduce(.And, v1.lesserEq(v1)));

    const v3 = Vec(i64, 3).from(2);
    try testing.expect(@reduce(.And, v1.lesserEq(v3)));
}

test "Greater" {
    const v1 = Vec(f32, 3).from(1.0);
    const v2 = Vec(f32, 3).from(2.0);
    try testing.expect(@reduce(.And, v2.greater(v1)));
    try testing.expect(!@reduce(.Or, v2.greater(v2)));

    const v3 = Vec(i64, 3).from(2);
    try testing.expect(@reduce(.And, v3.greater(v1)));
}

test "GreaterEq" {
    const v1 = Vec(f32, 3).from(1.0);
    const v2 = Vec(f32, 3).from(2.0);
    try testing.expect(@reduce(.And, v2.greaterEq(v1)));
    try testing.expect(@reduce(.And, v2.greaterEq(v2)));

    const v3 = Vec(i64, 3).from(2);
    try testing.expect(@reduce(.And, v3.greaterEq(v1)));
}

test "Equals" {
    const v1 = Vec(i32, 3).from(1);
    const v2 = Vec(i32, 3).from(2);
    try testing.expect(@reduce(.And, v1.equals(v1)));
    try testing.expect(!@reduce(.Or, v1.equals(v2)));

    const v3 = Vec(f64, 3).from(1.0);
    try testing.expect(@reduce(.And, v1.equals(v3)));
}

test "Approx" {
    const v1 = Vec(f32, 3).from(1.0);
    const v2 = Vec(f32, 3).from(1.000_000_1);
    try testing.expect(@reduce(.And, v1.approx(v2, 0.000_001)));
    try testing.expect(!@reduce(.Or, v1.approx(v2, 0.000_000_1)));
    try testing.expect(@reduce(.And, v1.approx(v2, 0.000_000_2)));

    const v3 = Vec(i64, 3).from(1);
    try testing.expect(@reduce(.And, v1.approx(v3, 0.000001)));
}

test "Dot" {
    const v1 = Vec(f32, 3).from(3.0);
    const v2 = Vec(f32, 3).from(2.0);
    try testing.expectEqual(18.0, v1.inner(v2));

    const v3 = Vec(i64, 3).from(2);
    try testing.expectEqual(18.0, v1.inner(v3));

    const v4 = Vec(i32, 2).from(2);
    const v5 = Vec(i32, 2).from(3);
    try testing.expectEqual([_]i32{6} ** 4, v4.outer1d(v5));
}

test "Cross" {
    const v1 = Vec(f32, 3).from(.{ 1.0, 0.0, 0.0 });
    const v2 = Vec(f32, 3).from(.{ 0.0, 1.0, 0.0 });
    try testing.expectEqual(Vec(f32, 3).from(.{ 0.0, 0.0, 1.0 }), Vec(f32, 3).cross(.{ v1, v2 }));

    const v3 = Vec(i64, 3).from(.{ 1, 0, 0 });
    const v4 = Vec(i64, 3).from(.{ 0, 1, 0 });
    try testing.expectEqual(Vec(i64, 3).from(.{ 0, 0, 1 }), Vec(i64, 3).cross(.{ v3, v4 }));
}

test "Length" {
    const v1 = Vec(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    try testing.expectEqual(3.0, v1.length());
    try testing.expectEqual(9.0, v1.length2());

    const v2 = Vec(i64, 3).from(.{ 1, 2, 2 });
    try testing.expectEqual(3.0, v2.length());
    try testing.expectEqual(9, v2.length2());
}

test "Normalize" {
    const v1 = Vec(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0 / 3.0, 2.0 / 3.0, 2.0 / 3.0 }), v1.normalized());

    const v2 = Vec(i64, 3).from(.{ 1, 2, 2 });
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0 / 3.0, 2.0 / 3.0, 2.0 / 3.0 }), v2.normalized());
}

test "Direction" {
    const v1 = Vec(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    const v2 = Vec(f32, 3).from(.{ 2.0, 4.0, 4.0 });
    try testing.expectEqual(Vec(f32, 3).from(.{ 3.3333334e-1, 6.666667e-1, 6.666667e-1 }), v1.dirTo(v2));

    const v3 = Vec(i64, 3).from(.{ 1, 2, 2 });
    const v4 = Vec(i64, 3).from(.{ 2, 4, 4 });
    try testing.expectEqual(Vec(f32, 3).from(.{ 3.3333334e-1, 6.666667e-1, 6.666667e-1 }), v3.dirTo(v4));
}
test "Distance" {
    const v1 = Vec(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    const v2 = Vec(f32, 3).from(.{ 2.0, 4.0, 4.0 });
    try testing.expectEqual(3.0, v1.distTo(v2));
    try testing.expectEqual(9.0, v1.distTo2(v2));

    const v3 = Vec(i64, 3).from(.{ 1, 2, 2 });
    const v4 = Vec(i64, 3).from(.{ 2, 4, 4 });
    try testing.expectEqual(3.0, v3.distTo(v4));
    try testing.expectEqual(9, v3.distTo2(v4));
}

test "Interpolation" {
    const v1 = Vec(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    const v2 = Vec(f32, 3).from(.{ 2.0, 4.0, 4.0 });
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.5, 3.0, 3.0 }), v1.lerp(v2, 0.5));

    const v3 = Vec(i64, 3).from(.{ 1, 2, 2 });
    const v4 = Vec(i64, 3).from(.{ 2, 4, 4 });
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.5, 3.0, 3.0 }), v3.lerp(v4, 0.5));
}

test "Min/Max" {
    const v1 = Vec(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    const v2 = Vec(f32, 3).from(.{ 2.0, 4.0, 4.0 });
    try testing.expectEqual(2.0, v1.max());
    try testing.expectEqual(1.0, v1.min());
    try testing.expectEqual(4.0, v1.maxOf(v2));
    try testing.expectEqual(1.0, v1.minOf(v2));
    try testing.expectEqual(Vec(f32, 3).from(.{ 2.0, 4.0, 4.0 }), v1.maxOfs(v2));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 2.0 }), v1.minOfs(v2));
    try testing.expectEqual(Vec(f32, 3).from(.{ 2.0, 2.0, 2.0 }), v1.maxxed());
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 1.0, 1.0 }), v1.minned());

    const v3 = Vec(i64, 3).from(.{ 1, 2, 2 });
    const v4 = Vec(i64, 3).from(.{ 2, 4, 4 });
    try testing.expectEqual(2, v3.max());
    try testing.expectEqual(1, v3.min());
    try testing.expectEqual(4, v3.maxOf(v4));
    try testing.expectEqual(1, v3.minOf(v4));
    try testing.expectEqual(Vec(i64, 3).from(.{ 2, 4, 4 }), v3.maxOfs(v4));
    try testing.expectEqual(Vec(i64, 3).from(.{ 1, 2, 2 }), v3.minOfs(v4));
    try testing.expectEqual(Vec(i64, 3).from(.{ 2, 2, 2 }), v3.maxxed());
    try testing.expectEqual(Vec(i64, 3).from(.{ 1, 1, 1 }), v3.minned());
}

test "Inverted, Negated" {
    const v1 = Vec(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 0.5, 0.5 }), v1.inversed());

    const v2 = Vec(i64, 3).from(.{ 1, 2, 2 });
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 0.5, 0.5 }), v2.inversed());

    try testing.expectEqual(Vec(f32, 3).from(.{ -1.0, -2.0, -2.0 }), v1.negated());
    try testing.expectEqual(Vec(i64, 3).from(.{ -1, -2, -2 }), v2.negated());

    try testing.expectEqual(Vec(f32, 3).from(.{ -1.0, -0.5, -0.5 }), v1.negInversed());
    try testing.expectEqual(Vec(f32, 3).from(.{ -1.0, -0.5, -0.5 }), v2.negInversed());
}

test "Clamping" {
    const v1 = Vec(f32, 3).from(.{ 0.0, 2.0, 4.0 });
    const minf: f32 = 1.0;
    const maxf: f32 = 3.0;
    const mini: i32 = 1;
    const maxi: i32 = 3;

    // commented out tests are expected to fail because of
    // the type mismatch between integral types and comptime_float
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(minf, maxf));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(mini, maxi));

    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(minf, maxi));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(mini, maxf));

    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(minf, 3.0));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(minf, 3));

    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(1.0, maxf));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(1, maxf));

    // try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(mini, 3.0));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(mini, 3));

    // try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(1.0, maxi));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(1, maxi));

    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(1.0, 3.0));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(1, 3));

    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(1.0, 3));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamp(1, 3.0));

    const v2 = Vec(i64, 3).from(.{ 1, 2, 4 });
    try testing.expectEqual(Vec(f32, 3).from(.{ 1, 2, 3 }), v2.clamp(minf, maxf));
    try testing.expectEqual(Vec(i64, 3).from(.{ 1, 2, 3 }), v2.clamp(mini, maxi));

    try testing.expectEqual(Vec(f32, 3).from(.{ 1, 2, 3 }), v2.clamp(minf, maxi));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1, 2, 3 }), v2.clamp(mini, maxf));

    try testing.expectEqual(Vec(f32, 3).from(.{ 1, 2, 3 }), v2.clamp(minf, 3.0));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1, 2, 3 }), v2.clamp(minf, 3));

    try testing.expectEqual(Vec(f32, 3).from(.{ 1, 2, 3 }), v2.clamp(1.0, maxf));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1, 2, 3 }), v2.clamp(1, maxf));

    // try testing.expectEqual(Vec(f32, 3).from(.{ 1, 2, 3 }), v2.clamp(mini, 3.0));
    try testing.expectEqual(Vec(i64, 3).from(.{ 1, 2, 3 }), v2.clamp(mini, 3));

    // try testing.expectEqual(Vec(f32, 3).from(.{ 1, 2, 3 }), v2.clamp(1.0, maxi));
    try testing.expectEqual(Vec(i64, 3).from(.{ 1, 2, 3 }), v2.clamp(1, maxi));

    try testing.expectEqual(Vec(f32, 3).from(.{ 1, 2, 3 }), v2.clamp(1.0, 3.0));
    try testing.expectEqual(Vec(i64, 3).from(.{ 1, 2, 3 }), v2.clamp(1, 3));

    try testing.expectEqual(Vec(f32, 3).from(.{ 1, 2, 3 }), v2.clamp(1.0, 3));
    try testing.expectEqual(Vec(f32, 3).from(.{ 1, 2, 3 }), v2.clamp(1, 3.0));
}

test "Formatting" {
    const v1 = Vec(f32, 3).from(.{ 1.2, 2.0, 0.25 });
    var buf: [64]u8 = undefined;
    const fmt = try std.fmt.bufPrint(&buf, "{}", .{v1});
    try testing.expect(std.mem.eql(u8, "Vec3(1.2, 2, 0.25)", fmt));
}
