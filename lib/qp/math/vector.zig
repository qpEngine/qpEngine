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
pub fn Vector(
    comptime T: type,
    comptime N: u16,
) type {
    switch (@typeInfo(T)) {
        .int => |info| if (info.signedness == .unsigned) @compileError("Vector element type must be signed"),
        .float => {},
        else => @compileError("Vector element type must be numeric"),
    }

    return struct {
        data: [N]T,

        const Self = @This(); // Type alias for self Vector type
        const Alt = Vector(f32, N); // Alternate Vector return type of integral type vectors
        const R = f32; // Alternate scalar return type of Integral type vectors
        const V = @Vector(N, T); // SIMD Vector representaiton of self
        const W = @Vector(N, R); // Alternate SIMD Vector representation of integral type vectors
        const B = @Vector(N, bool); // Boolean SIMD Vector type
        const len: u16 = N; // stored Vector type length
        const isInt: bool = @typeInfo(T) == .int; // stored Vector type is integral

        // These functions simplify the logic for when functions operate differently with
        // integral or floating point vectors, or take different types of inputs
        inline fn scalar(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) R else T;
        }

        inline fn vector(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) Alt else Self;
        }

        inline fn simd(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) W else V;
        }

        inline fn comp(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) comptime_int else comptime_float;
        }

        inline fn bounds(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) Self else vector(T);
        }

        pub const VError = error{
            DivideByZero,
        };

        /// Default initialization
        /// Vector components are set to undefined
        ///
        /// < Self: A new Vector
        pub inline fn init() Self {
            return .{ .data = undefined };
        }

        /// Comprehensive initialization
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

        /// Cast Vector as SIMD Vector
        ///
        /// < @Vector(N, T): SIMD Vector
        pub inline fn as(
            self: *const Self,
        ) V {
            return self.data;
        }

        /// Remove const from Vector pointer
        ///
        /// < *Self: Mutable Vector
        pub inline fn ptr(
            self: *const Self,
        ) *Self {
            return @constCast(self);
        }

        /// Create copy of current Vector
        ///
        /// < Self: Copied Vector
        pub inline fn clone(
            self: *const Self,
        ) Self {
            return .{ .data = self.data };
        }

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
        /// < Vector(T, M): A new Vector
        pub inline fn toSize(
            self: Self,
            comptime M_: u8,
            fill_: comp(T),
        ) Vector(T, M_) {
            if (M_ == N) return self;
            var result = Vector(T, M_).from(fill_);
            const min_size = @min(N, M_);
            result.data[0..min_size].* = self.data[0..min_size].*;
            return result;
        }

        /// Private
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
                else => @compileError("Vector element type must be numeric"),
            };
        }

        /// Private
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
                else => @compileError("Vector element type must be numeric"),
            };
        }

        /// Private
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
        /// Convert any type to SIMD Vector of type T and size N
        ///
        /// If type is not supported, an error is thrown
        ///
        /// for scalars, splat of scalar is returned
        /// for arrays, array is coerced
        /// for pointers, pointer is dereferenced and passed to recursive call
        /// for SIMD Vectors, Vector is returned
        /// for structs,
        ///     if struct is a tuple, all elements must be of the same type to be coerced
        ///     if struct has a 'data' field of type array, array is coerced
        ///
        /// > value: anytype
        ///     Value to convert
        ///
        /// > fill: comptime_int | comptime_float
        ///     Value to fill new SIMD Vector with
        ///
        /// < @Vector(N, T): Converted SIMD Vector
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
                    // else => Self.from(value_.*).as(),
                    else => vectorFromAny(value_.*, 0),
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

        /// Initialize Vector with component at index set to 1, others to 0
        /// If index is out of bounds, Vector is the zero vector
        ///
        /// > index: usize
        ///     Index of component to set to 1
        ///
        /// < Self: New positive unit Vector
        pub inline fn unitP(
            index_: usize,
        ) Self {
            var result = Self.from(0);
            if (index_ < N) {
                result.data[index_] = 1;
            }
            return result;
        }

        /// Initialize Vector with component at index set to -1, others to 0
        /// If index is out of bounds, Vector is the zero vector
        ///
        /// > index: usize
        ///     Index of component to set to -1
        ///
        /// < Self: New negative unit Vector
        pub inline fn unitN(
            index_: usize,
        ) Self {
            var result = Self.from(0);
            if (index_ < N) {
                result.data[index_] = -1;
            }
            return result;
        }

        /// Generate a new Vector with components picked from the current Vector
        /// List of indices can be larger or smaller than current Vector size
        ///
        /// > indices: []const i32
        ///     Indices of components to pick
        ///
        /// < Vector(T, indices.len): Swizzled Vector
        pub inline fn pick(
            self: *Self,
            indices_: []const i32,
        ) Vector(T, indices_.len) {
            const mask: @Vector(indices_.len, i32) = indices_[0..].*;

            return Vector(T, indices_.len).from(@shuffle(T, self.as(), undefined, @abs(mask)));
        }

        /// Update current vector with Summation of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to sum with
        ///
        /// < *Self: Updated Current Vector
        pub inline fn summate(
            self: *Self,
            other_: anytype,
        ) *Self {
            const b: V = vectorFromAny(other_, 0);

            self.data = self.as() + b;
            return self;
        }

        /// New Vector is Summation of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to sum with
        ///
        /// < Self: Sum Vector
        pub inline fn summated(
            self: *Self,
            other_: anytype,
        ) Self {
            const b: V = vectorFromAny(other_, 0);

            return .{ .data = self.as() + b };
        }

        pub inline fn summated2(
            self: *Self,
            other_: anytype,
        ) Self {
            return self.clone().ptr().summate(other_).*;
        }

        /// Update current vector with Difference of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to subtract
        ///
        /// < *Self: Updated Current Vector
        pub inline fn subtract(
            self: *Self,
            other_: anytype,
        ) *Self {
            const b: V = vectorFromAny(other_, 0);

            self.data = self.as() - b;
            return self;
        }

        /// New Vector is Difference of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to subtract
        ///
        /// < Self: Difference Vector
        pub inline fn subtracted(
            self: *Self,
            other_: anytype,
        ) Self {
            const b: V = vectorFromAny(other_, 0);

            return .{ .data = self.as() - b };
        }

        /// Update current vector with Product of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to multiply with
        ///
        /// < *Self: Updated Current Vector
        pub inline fn multiply(
            self: *Self,
            other_: anytype,
        ) *Self {
            const b: V = vectorFromAny(other_, 1);

            self.data = self.as() * b;
            return self;
        }

        /// New Vector is Product of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to multiply with
        ///
        /// < Self: Product Vector
        pub inline fn multiplied(
            self: *Self,
            other_: anytype,
        ) Self {
            const b: V = vectorFromAny(other_, 1);

            return .{ .data = self.as() * b };
        }

        /// Update current vector with Quotient of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to divide by
        ///
        /// < *Self: Updated Current Vector
        pub inline fn divide(
            self: *Self,
            other_: anytype,
        ) !*Self {
            const b: V = vectorFromAny(other_, 1);

            const c: V = @splat(0);
            const d: B = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VError.DivideByZero;

            self.data = self.as() / b;
            return self;
        }

        /// New Vector is Quotient of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to divide by
        ///
        /// < Self: Quotient Vector
        pub inline fn divided(
            self: *Self,
            other_: anytype,
        ) !Self {
            const b: V = vectorFromAny(other_, 1);

            const c: V = @splat(0);
            const d: B = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VError.DivideByZero;

            return .{ .data = self.as() / b };
        }

        /// Update current vector with Modulus of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to divide by
        ///
        /// < *Self: Updated Current Vector
        pub inline fn modulo(
            self: *Self,
            other_: anytype,
        ) !*Self {
            const b: V = vectorFromAny(other_, 1);

            const c: V = @splat(0);
            const d: B = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VError.DivideByZero;

            self.data = @mod(self.as(), b);
            return self;
        }

        /// New Vector is Modulus of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to divide by
        ///
        /// < Self: Modulus Vector
        pub inline fn moduloed(
            self: *Self,
            other_: anytype,
        ) !Self {
            const b: V = vectorFromAny(other_, 1);

            const c: V = @splat(0);
            const d: B = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VError.DivideByZero;

            return .{ .data = @mod(self.as(), b) };
        }

        /// Update current vector with Remainder from division of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to divide
        ///
        /// < *Self: Updated Current Vector
        pub inline fn remainder(
            self: *Self,
            other_: anytype,
        ) !*Self {
            const b: V = vectorFromAny(other_, 1);

            const c: V = @splat(0);
            const d: B = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VError.DivideByZero;

            self.data = @rem(self.as(), b);
            return self;
        }

        /// New Vector is Remainder from division of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to divide
        ///
        /// < Self: Remainder Vector
        pub inline fn remaindered(
            self: *Self,
            other_: anytype,
        ) !Self {
            const b: V = vectorFromAny(other_, 1);

            const c: V = @splat(0);
            const d: B = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VError.DivideByZero;

            return .{ .data = @rem(self.as(), b) };
        }

        /// Comparison SIMD Vector of less than for vectors by components
        /// Returns boolean SIMD Vector
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < @Vector(N, bool): Comparison SIMD Vector
        pub inline fn lesser(
            self: *const Self,
            other_: anytype,
        ) B {
            const b: V = vectorFromAny(other_, 0);

            return self.as() < b;
        }

        /// Comparison SIMD Vector of less than or equal for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < @Vector(N, bool): Comparison SIMD Vector
        pub inline fn lesserEq(
            self: *const Self,
            other_: anytype,
        ) B {
            const b: V = vectorFromAny(other_, 0);

            return self.as() <= b;
        }

        /// Comparison SIMD Vector of greater than for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < @Vector(N, bool): Comparison SIMD Vector
        pub inline fn greater(
            self: *const Self,
            other_: anytype,
        ) B {
            const b: V = vectorFromAny(other_, 0);

            return self.as() > b;
        }

        /// Comparison SIMD Vector of greater than or equal for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < @Vector(N, bool): Comparison SIMD Vector
        pub inline fn greaterEq(
            self: *const Self,
            other_: anytype,
        ) B {
            const b: V = vectorFromAny(other_, 0);

            return self.as() >= b;
        }

        /// Comparison SIMD Vector of equality for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < @Vector(N, bool): Comparison SIMD Vector
        pub inline fn equal(
            self: *const Self,
            other_: anytype,
        ) B {
            const b: V = vectorFromAny(other_, 0);

            return self.as() == b;
        }

        /// Comparison SIMD Vectors of approximation for vectors by components with tolerance
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///    Vector to compare
        ///
        /// > tolerance: ?T
        ///    Tolerance value for comparison
        ///    default: 0 | floatEps(T)
        ///
        /// < @Vector(N, bool): Comparison SIMD Vector
        pub inline fn approximate(
            self: *const Self,
            other_: anytype,
            tolerance: ?T,
        ) B {
            const Y: type = comptime getY: {
                var y: std.builtin.Type = @typeInfo(T);
                if (y == .int) y.int.signedness = .unsigned;
                break :getY if (y == .float) T else @Type(y);
            };
            const t: Y = tolerance orelse if (Y == .float) std.math.floatEps(T) else 0;
            const b: V = vectorFromAny(other_, 0);

            const c: @Vector(N, Y) = @abs(self.as() - b);
            const d: @Vector(N, Y) = @splat(t);

            return c <= d;
        }

        /// Compute inner dot product (inner) of vectors
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compute dot product with
        ///
        /// < T: Dot product scalar
        pub inline fn inner(
            self: *const Self,
            other_: anytype,
        ) T {
            const b: V = vectorFromAny(other_, 0);
            const c: V = self.as() * b;

            return @reduce(.Add, c);
        }

        /// Compute the outer dot product (results in a matrix) of vectors
        /// This returns a flat array in row-major order
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///    Vector to compute outer product with
        ///
        /// < [N * N]T: Outer product matrix array
        pub inline fn outer1d(
            self: *const Self,
            other_: anytype,
        ) [N * N]T {
            const a: @Vector(N * N, T) = std.simd.repeat(N * N, vectorFromAny(other_, 0));
            const mask = comptime getMask: {
                var output: [N * N]T = undefined;
                for (0..N) |i| {
                    output[i * N .. i * N + N].* = @splat(@as(i32, @intCast(i)));
                }
                break :getMask output;
            };
            const b: @Vector(N * N, T) = @shuffle(T, self.as(), undefined, mask);

            return a * b;
        }

        /// Compute the outer product (results in a matrix) of vectors
        /// This returns a 2d array in row-major order
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///    Vector to compute outer product with
        ///
        /// < [N][N]T: Outer product matrix array
        pub inline fn outer2d(
            self: *const Self,
            other_: anytype,
        ) [N][N]T {
            return @bitCast(outer1d(self, other_));
        }

        /// Compute the cross product of N-1 vectors
        /// Uses matrix expansion to find determinants
        ///
        /// > vectors: [N - 1]Self
        ///    Vectors to compute cross product with
        ///
        /// < Self: Cross product as new Vector
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
        /// Recursive function to calculate determinant of matrix using submatrix expansion
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

        /// Compute length (magnitude) of vector
        /// returns float if vector element type is int
        ///
        /// < T | R: Length scalar
        pub inline fn length(
            self: *const Self,
        ) scalar(T) {
            return switch (@typeInfo(T)) {
                .float => @sqrt(self.inner(self)),
                .int => @sqrt(@as(R, @floatFromInt(self.inner(self)))),
                else => @compileError("Vector element type must be numeric"),
            };
        }

        /// Compute squared length of vector
        ///
        /// < T: Squared length scalar
        pub inline fn length2(
            self: *const Self,
        ) T {
            return self.inner(self);
        }

        /// Update current vector with Normalization of itself to unit length
        /// If vector length is 0, error is returned
        /// For integral type Vector, components are rounded up or down
        ///
        /// < !*Self: Updated Current Vector
        pub inline fn normalize(
            self: *Self,
        ) !*Self {
            const a = if (isInt) Vector(f32, N).from(self.data) else self;
            const v_len = a.length();
            if (v_len == 0) return VError.DivideByZero;

            const b = @as(@Vector(N, @TypeOf(v_len)), @splat(v_len));
            const result = a.as() / b;

            self.data = if (isInt) @as(V, @intFromFloat(@round(result))) else result;
            return self;
        }

        /// Copy of current Vector normalized to unit length
        /// If vector length is 0, null is returned
        /// For integral type Vector, components are rounded up or down
        ///
        /// < Self | Alt: Normalized Vector
        pub inline fn normalized(
            self: *Self,
        ) ?Self {
            const a = if (isInt) Vector(f32, N).from(self.data) else self;
            const v_len = a.length();
            if (v_len == 0) return null;

            const b = @as(@Vector(N, @TypeOf(v_len)), @splat(v_len));
            const result = a.as() / b;

            return .{ .data = if (isInt) @as(V, @intFromFloat(@round(result))) else result };
        }

        /// Update current vector with Sign of components
        ///
        /// < *Self: Updated Current Vector
        pub inline fn sign(
            self: *Self,
        ) *Self {
            const comps = self.as();
            const abs = @abs(comps);
            var sabs = if (isInt) @as(V, @intCast(abs)) else abs;
            const equals = sabs == vectorFromAny(0, 0);
            sabs = @select(T, equals, vectorFromAny(1, 0), sabs);

            self.data = comps / sabs;
            return self;
        }

        /// Copy of current Vector with Sign of components
        ///
        /// < Self | Alt: Signed Vector
        pub inline fn signed(
            self: *const Self,
        ) Self {
            const comps = self.as();
            const abs = @abs(comps);
            var sabs = if (isInt) @as(V, @intCast(abs)) else abs;
            const equals = sabs == vectorFromAny(0, 0);
            sabs = @select(T, equals, vectorFromAny(1, 0), sabs);

            return .{ .data = comps / sabs };
        }

        /// Compute direction vector between vectors
        /// If length of distance is zero, zero vector is returned
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to calculate direction to
        ///
        /// < Self | Alt: Direction Vector
        pub inline fn directionTo(
            self: *const Self,
            other_: anytype,
        ) Self {
            var new = if (@TypeOf(other_) == Self) other_ else Self.from(other_);
            return new.subtract(self).normalized() orelse (Self).from(0);
        }

        /// Distance between current Vector and another vector
        ///
        /// Calculate distance between vectors
        /// returns float if vector element type is int
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to calculate distance to
        ///
        /// < T | R: Distance scalar
        pub inline fn distanceTo(
            self: *const Self,
            other_: anytype,
        ) scalar(T) {
            const new = if (@TypeOf(other_) == Self) other_ else Self.from(other_);
            return switch (@typeInfo(T)) {
                .float => @sqrt(self.distanceTo2(new)),
                .int => @sqrt(@as(R, @floatFromInt(self.distanceTo2(new)))),
                else => @compileError("Vector element type must be numeric"),
            };
        }

        /// Squared distance between current Vector and another vector
        ///
        /// Calculate squared distance between vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to calculate distance to
        ///
        /// < T: Squared distance scalar
        pub inline fn distanceTo2(
            self: *const Self,
            other_: anytype,
        ) T {
            var new = if (@TypeOf(other_) == Self) other_ else Self.from(other_);
            return new.subtract(self).length2();
        }

        /// Linear interpolation of current Vector to another Vector
        ///
        /// In place Linear Interpolation between vectors at time t
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to interpolate to
        ///
        /// > t: f32
        ///     Time to interpolate at
        ///
        /// < *Self | Alt: Interpolated Current Vector
        pub inline fn interpolate(
            self: *Self,
            other_: anytype,
            time_: f32,
        ) *Self {
            const time = if (isInt) @trunc(time_) else time_;
            var new = if (@TypeOf(other_) == Self) other_ else Self.from(other_);
            return self.multiply(1 - time).summate(new.multiply(time).*);
        }

        /// Linear interpolation of current Vector to another Vector
        ///
        /// New Vector is Linear interpolates between vectors at time t
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to interpolate to
        ///
        /// > time: f32
        ///
        /// < Self: Interpolated Vector
        pub inline fn interpolated(
            self: *Self,
            other_: anytype,
            time_: f32,
        ) Self {
            const time = if (isInt) @trunc(time_) else time_;
            var new = if (@TypeOf(other_) == Self) other_ else Self.from(other_);
            // return @constCast(&self.multiplied(1 - time)).summate(new.multiply(time).*).*;
            return self.multiplied(1 - time).ptr().summate(new.multiply(time).*).*;
        }

        /// Maximum scalar of current Vector
        ///
        /// Absolute max scalar of a vector
        ///
        /// < T: Max scalar
        pub inline fn maximum(
            self: *const Self,
        ) T {
            return @reduce(.Max, self.as());
        }

        /// Minimum scalar of current Vector
        ///
        /// Absolute min scalar of a vector
        ///
        /// < T: Min scalar
        pub inline fn minimum(
            self: *const Self,
        ) T {
            return @reduce(.Min, self.as());
        }

        /// Components set to maximum from current Vector and another vector
        ///
        /// Update current Vector with maximum components of either vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Self: Maximum Vector
        pub inline fn maximumOf(
            self: *const Self,
            other_: anytype,
        ) Self {
            const s = @constCast(self);
            const b: V = vectorFromAny(other_, 0);

            s.data = @max(self.as(), b);
            return s;
        }

        /// Vector with Components set to maximum from current Vector and another vector
        ///
        /// New Vector with maximum components of either vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Self: Maximum Vector
        pub inline fn maximumOfed(
            self: *const Self,
            other_: anytype,
        ) Self {
            const b: V = vectorFromAny(other_, 0);

            return .{ .data = @max(self.as(), b) };
        }

        /// Components set to minimum from current Vector and another vector
        ///
        /// Update current Vector with minimum components of either vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Self: Minimum Vector
        pub inline fn minimumOf(
            self: *const Self,
            other_: anytype,
        ) Self {
            const s = @constCast(self);
            const b: V = vectorFromAny(other_, 0);

            s.data = @min(self.as(), b);
            return s;
        }

        /// Components set to minimum from current Vector and another vector
        ///
        /// Update current Vector with minimum components of either vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Self: Minimum Vector
        pub inline fn minimumOfed(
            self: *const Self,
            other_: anytype,
        ) Self {
            const b: V = vectorFromAny(other_, 0);

            return .{ .data = @min(self.as(), b) };
        }

        ///
        ///
        /// Vector with max of self for all components
        ///
        /// < Self: maximized Vector
        pub inline fn maximized(
            self: *const Self,
        ) Self {
            return .{ .data = @splat(@reduce(.Max, self.as())) };
        }

        pub inline fn minimized(
            self: *const Self,
        ) Self {
            return .{ .data = @splat(@reduce(.Min, self.as())) };
        }

        /// Vector with inverse of all components
        ///
        /// Vector with inverse of self for all components
        /// returns float vector type if vector element type is int
        ///
        /// < Self: Inversed Vector
        pub inline fn inversed(
            self: *const Self,
        ) vector(T) {
            const a = switch (@typeInfo(T)) {
                .float => self.as(),
                .int => @as(W, @floatFromInt(self.as())),
                else => unreachable,
            };
            const b: simd(T) = @splat(1);

            return .{ .data = b / a };
        }

        /// Vector with negated components
        ///
        /// Vector with negated self for all components
        ///
        /// < Self: Negated Vector
        pub inline fn negated(
            self: *const Self,
        ) Self {
            const b: V = @splat(-1);

            return .{ .data = self.as() * b };
        }

        /// Vector with negated and inversed components
        ///
        /// Vector with negated and inversed self for all components
        /// returns float vector type if vector element type is int
        ///
        /// < Self: Negated and inversed Vector
        pub inline fn negInversed(
            self: *const Self,
        ) vector(T) {
            const a = switch (@typeInfo(T)) {
                .float => self.as(),
                .int => @as(W, @floatFromInt(self.as())),
                else => unreachable,
            };
            const b: simd(T) = @splat(-1);

            return .{ .data = b / a };
        }

        /// Vector with clamped components
        ///
        /// Vector with clamped self between min and max for all components
        ///
        /// > min_: anytype
        ///     Minimum value to clamp to
        ///
        /// > max_: anytype
        ///     Maximum value to clamp to
        ///
        /// < Self: Clamped Vector
        pub inline fn clamped(
            self: *const Self,
            min_: anytype,
            max_: anytype,
        ) Self {
            // ) void {
            const min_v = vectorFromAny(min_, 0);
            const max_v = vectorFromAny(max_, 0);

            return .{ .data = @min(max_v, @max(min_v, self.as())) };
        }

        pub inline fn project() void {}

        /// Vector to string
        ///
        /// Convert vector to formatted string
        /// Format is `Vector{N}({d}, ...)` where N is vector size
        ///
        /// > fmt: []const u8
        /// > options: std.fmt.FormatOptions
        /// > writer: anytype
        ///
        /// < void
        pub fn format( // zig fmt: off
            self: *const Self,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype
        ) !void {
            _ = fmt;
            _ = options;

            try writer.print("Vector{d}(", .{N});
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
    const baseType: type = Vector(T, 2);

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
    const baseType: type = Vector(T, 3);

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
    const baseType: type = Vector(T, 4);

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
// Vector

// NOTE: Fuzz testing not yet available on windows/macos
// test "Fuzz" {}

test "Initialize" {

    // useful data
    const a1 = [3]f32{ 1.0, 2.0, 3.0 };
    const simd1 = @as(@Vector(3, f32), a1);

    // casting
    {
        const v1 = Vector(f32, 3).from(a1);
        const v2: @Vector(3, f32) = .{ 1.0, 2.0, 3.0 };
        try testing.expectEqual(v2, v1.as());
    }

    // empty initialization
    {
        const v1 = Vector(f32, 3).init();
        try testing.expectEqual([3]f32{ undefined, undefined, undefined }, v1.data);
    }

    // splatting
    {
        // comptime_float
        const v1 = Vector(f32, 3).from(1.0);
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v1.data);

        // comptime_int
        const v2 = Vector(f32, 3).from(1);
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v2.data);

        // larger float
        const v3 = Vector(f32, 3).from(@as(f64, 1.0));
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v3.data);

        // int
        const v4 = Vector(f32, 3).from(@as(i32, 1));
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v4.data);

        // larger int
        const v5 = Vector(f32, 3).from(@as(i64, 1));
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v5.data);
    }

    // tuples
    {
        // full tuple
        const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 });
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.data);

        // empty tuple
        const v2 = Vector(f32, 3).from(.{});
        try testing.expectEqual([3]f32{ 0, 0, 0 }, v2.data);

        // partial tuple
        const v3 = Vector(f32, 3).from(.{1.0});
        try testing.expectEqual([3]f32{ 1.0, 0, 0 }, v3.data);

        // overfull tuple
        const v4 = Vector(f32, 3).from(.{ 1.0, 2.0, 3.0, 4.0 });
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v4.data);

        // unacceptable tuple
        // WARNING: Expected Compiler Errors
        // const v5 = Vector(f32, 3).from(.{ true, true });
        // const v5 = Vector(f32, 3).from(.{ 1.0, true });
        // try testing.expectEqual([3]f32{ 1.0, 1.0, 0.0 }, v5.data);
    }

    // other vectors
    {
        // same type, size, length
        const v1 = Vector(f32, 3).from(1.0);
        const v2 = Vector(f32, 3).from(v1);
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v2.data);

        // different type, same size, length
        const v3 = Vector(i32, 3).from(v1);
        try testing.expectEqual([3]i32{ 1, 1, 1 }, v3.data);

        // same type, length, different size
        const v4 = Vector(f64, 3).from(v1);
        try testing.expectEqual([3]f64{ 1.0, 1.0, 1.0 }, v4.data);

        // different type, size, same length
        const v5 = Vector(i64, 3).from(v1);
        try testing.expectEqual([3]i64{ 1, 1, 1 }, v5.data);

        // different type, size, length
        const v6 = Vector(i64, 4).from(v1);
        try testing.expectEqual([4]i64{ 1, 1, 1, 0 }, v6.data);

        // different type, size, length
        const v7 = Vector(f16, 2).from(v5);
        try testing.expectEqual([2]f16{ 1.0, 1.0 }, v7.data);
    }

    // array
    {
        const v1 = Vector(f32, 3).from([3]f32{ 1.0, 2.0, 3.0 });
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.data);

        const v2 = Vector(i32, 3).from([3]i32{ 1, 2, 3 });
        try testing.expectEqual([3]i32{ 1, 2, 3 }, v2.data);
    }

    // simd vectors
    {
        const v1 = Vector(f32, 3).from(simd1);
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.data);

        const v2 = Vector(i32, 2).from(simd1);
        try testing.expectEqual([2]i32{ 1, 2 }, v2.data);

        const v3 = Vector(f64, 4).from(simd1);
        try testing.expectEqual([4]f64{ 1.0, 2.0, 3.0, 0.0 }, v3.data);
    }

    // pointer
    {
        const v1 = Vector(f32, 3).from(&a1);
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.data);

        const v2 = Vector(i32, 3).from(&a1);
        try testing.expectEqual([3]i32{ 1, 2, 3 }, v2.data);

        const v3 = Vector(f32, 3).from(&[3]f32{ 1.0, 2.0, 3.0 });
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v3.data);

        const v4 = Vector(f32, 3).from(a1[0..]);
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v4.data);
    }

    // unit vectors
    {
        const v1 = Vector(f32, 3).unitP(0);
        try testing.expectEqual([3]f32{ 1.0, 0.0, 0.0 }, v1.data);

        const v2 = Vector(f32, 3).unitP(1);
        try testing.expectEqual([3]f32{ 0.0, 1.0, 0.0 }, v2.data);

        const v3 = Vector(f32, 3).unitP(2);
        try testing.expectEqual([3]f32{ 0.0, 0.0, 1.0 }, v3.data);

        const v4 = Vector(f32, 3).unitN(0);
        try testing.expectEqual([3]f32{ -1.0, 0.0, 0.0 }, v4.data);

        const v5 = Vector(f32, 3).unitN(1);
        try testing.expectEqual([3]f32{ 0.0, -1.0, 0.0 }, v5.data);

        const v6 = Vector(f32, 3).unitN(2);
        try testing.expectEqual([3]f32{ 0.0, 0.0, -1.0 }, v6.data);
    }

    // pick
    {
        var v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 });
        const v2 = v1.pick(&.{ 1, 0 });
        const v3 = v1.pick(&.{ 1, 2, 0, 1 });
        try testing.expectEqual([2]f32{ 2.0, 1.0 }, v2.data);
        try testing.expectEqual([4]f32{ 2.0, 3.0, 1.0, 2.0 }, v3.data);
    }

    // clone
    {
        const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 });
        const v2 = v1.clone().ptr().summate(1.0).*;
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.data);
        try testing.expectEqual([3]f32{ 2.0, 3.0, 4.0 }, v2.data);
    }
}

test "Summation" {
    var v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expectEqual(Vector(f32, 3).from(3.0), v1.summated(v2));
    _ = v1.summate(v2);
    try testing.expectEqual(Vector(f32, 3).from(3.0), v1);
}

test "Subtraction" {
    var v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expectEqual(Vector(f32, 3).from(-1.0), v1.subtracted(v2));
    _ = v1.subtract(v2);
    try testing.expectEqual(Vector(f32, 3).from(-1.0), v1);
}

test "Multiplication" {
    var v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expectEqual(Vector(f32, 3).from(2.0), v1.multiplied(v2));
    _ = v1.multiply(v2);
    try testing.expectEqual(Vector(f32, 3).from(2.0), v1);
}

test "Division" {
    var v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expectEqual(Vector(f32, 3).from(0.5), v1.divided(v2));
    _ = try v1.divide(v2);
    try testing.expectEqual(Vector(f32, 3).from(0.5), v1);
}

test "Modulus" {
    var v1 = Vector(f32, 3).from(.{ 4.0, -5.0, 6.0 });
    const v2 = Vector(f32, 3).from(3.0);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 1.0, 0.0 }), v1.moduloed(v2));
    _ = try v1.modulo(v2);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 1.0, 0.0 }), v1);
}

test "Remainder" {
    var v1 = Vector(f32, 3).from(.{ 4.0, -5.0, 6.0 });
    const v2 = Vector(f32, 3).from(3.0);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, -2.0, 0.0 }), v1.remaindered(v2));
    _ = try v1.remainder(v2);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, -2.0, 0.0 }), v1);
}

test "Lesser" {
    const v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expect(@reduce(.And, v1.lesser(v2)));
    try testing.expect(!@reduce(.Or, v1.lesser(v1)));

    const v3 = Vector(i64, 3).from(2);
    try testing.expect(@reduce(.And, v1.lesser(v3)));
}

test "LesserEq" {
    const v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expect(@reduce(.And, v1.lesserEq(v2)));
    try testing.expect(@reduce(.And, v1.lesserEq(v1)));

    const v3 = Vector(i64, 3).from(2);
    try testing.expect(@reduce(.And, v1.lesserEq(v3)));
}

test "Greater" {
    const v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expect(@reduce(.And, v2.greater(v1)));
    try testing.expect(!@reduce(.Or, v2.greater(v2)));

    const v3 = Vector(i64, 3).from(2);
    try testing.expect(@reduce(.And, v3.greater(v1)));
}

test "GreaterEq" {
    const v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expect(@reduce(.And, v2.greaterEq(v1)));
    try testing.expect(@reduce(.And, v2.greaterEq(v2)));

    const v3 = Vector(i64, 3).from(2);
    try testing.expect(@reduce(.And, v3.greaterEq(v1)));
}

test "equal" {
    const v1 = Vector(i32, 3).from(1);
    const v2 = Vector(i32, 3).from(2);
    try testing.expect(@reduce(.And, v1.equal(v1)));
    try testing.expect(!@reduce(.Or, v1.equal(v2)));

    const v3 = Vector(f64, 3).from(1.0);
    try testing.expect(@reduce(.And, v1.equal(v3)));
}

test "Approximate" {
    const v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(1.000_000_1);
    try testing.expect(@reduce(.And, v1.approximate(v2, 0.000_001)));
    try testing.expect(!@reduce(.Or, v1.approximate(v2, 0.000_000_1)));
    try testing.expect(@reduce(.And, v1.approximate(v2, 0.000_000_2)));

    const v3 = Vector(i64, 3).from(1);
    try testing.expect(@reduce(.And, v1.approximate(v3, 0.000001)));
}

test "Dot" {
    const v1 = Vector(f32, 3).from(3.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expectEqual(18.0, v1.inner(v2));

    const v3 = Vector(i64, 3).from(2);
    try testing.expectEqual(18.0, v1.inner(v3));

    const v4 = Vector(i32, 2).from(2);
    const v5 = Vector(i32, 2).from(3);
    try testing.expectEqual([_]i32{6} ** 4, v4.outer1d(v5));
}

test "Cross" {
    const v1 = Vector(f32, 3).from(.{ 1.0, 0.0, 0.0 });
    const v2 = Vector(f32, 3).from(.{ 0.0, 1.0, 0.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 0.0, 0.0, 1.0 }), Vector(f32, 3).cross(.{ v1, v2 }));

    const v3 = Vector(i64, 3).from(.{ 1, 0, 0 });
    const v4 = Vector(i64, 3).from(.{ 0, 1, 0 });
    try testing.expectEqual(Vector(i64, 3).from(.{ 0, 0, 1 }), Vector(i64, 3).cross(.{ v3, v4 }));
}

test "Length" {
    const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    try testing.expectEqual(3.0, v1.length());
    try testing.expectEqual(9.0, v1.length2());

    const v2 = Vector(i64, 3).from(.{ 1, 2, 2 });
    try testing.expectEqual(3.0, v2.length());
    try testing.expectEqual(9, v2.length2());
}

test "Normalize" {
    var v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0 / 3.0, 2.0 / 3.0, 2.0 / 3.0 }), v1.normalized());
    _ = try v1.normalize();
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0 / 3.0, 2.0 / 3.0, 2.0 / 3.0 }), v1);

    var v2 = Vector(i64, 3).from(.{ 1, 2, 2 });
    const t1 = .{ @as(i64, @intFromFloat(@round(1.0 / 3.0))), @as(i64, @intFromFloat(@round(2.0 / 3.0))), @as(i64, @intFromFloat(@round(2.0 / 3.0))) };
    try testing.expectEqual(Vector(i64, 3).from(t1), v2.normalized());
    _ = try v2.normalize();
    try testing.expectEqual(Vector(i64, 3).from(t1), v2);
}

test "Sign" {
    var v1 = Vector(f32, 3).from(.{ 1.0, -2.0, 0.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, -1.0, 0.0 }), v1.signed());
    _ = v1.sign();
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, -1.0, 0.0 }), v1);

    var v2 = Vector(i64, 3).from(.{ 1, -2, 0 });
    try testing.expectEqual(Vector(i64, 3).from(.{ 1, -1, 0 }), v2.signed());
    _ = v2.sign();
    try testing.expectEqual(Vector(i64, 3).from(.{ 1, -1, 0 }), v2);
}

test "Direction" {
    const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    const v2 = Vector(f32, 3).from(.{ 2.0, 4.0, 4.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 3.3333334e-1, 6.666667e-1, 6.666667e-1 }), v1.directionTo(v2));

    const v3 = Vector(i64, 3).from(.{ 1, 2, 2 });
    const v4 = Vector(i64, 3).from(.{ 2, 4, 4 });
    try testing.expectEqual(Vector(i64, 3).from(.{ 0, 1, 1 }), v3.directionTo(v4));
}
test "Distance" {
    const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    const v2 = Vector(f32, 3).from(.{ 2.0, 4.0, 4.0 });
    try testing.expectEqual(3.0, v1.distanceTo(v2));
    try testing.expectEqual(9.0, v1.distanceTo2(v2));

    const v3 = Vector(i64, 3).from(.{ 1, 2, 2 });
    const v4 = Vector(i64, 3).from(.{ 2, 4, 4 });
    try testing.expectEqual(3.0, v3.distanceTo(v4));
    try testing.expectEqual(9, v3.distanceTo2(v4));
}

test "Interpolation" {
    var v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    const v2 = Vector(f32, 3).from(.{ 2.0, 4.0, 4.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.5, 3.0, 3.0 }), v1.interpolated(v2, 0.5));
    _ = v1.interpolate(v2, 0.5);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.5, 3.0, 3.0 }), v1);

    var v3 = Vector(i64, 3).from(.{ 1, 2, 2 });
    const v4 = Vector(i64, 3).from(.{ 3, 7, 7 });
    try testing.expectEqual(Vector(i64, 3).from(.{ 5, 12, 12 }), v3.interpolated(v4, 2.0));
    try testing.expectEqual(Vector(i64, 3).from(.{ -3, -8, -8 }), v3.interpolated(v4, -2.0));
}

test "Min/Max" {
    const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    const v2 = Vector(f32, 3).from(.{ 2.0, 4.0, 4.0 });
    try testing.expectEqual(2.0, v1.maximum());
    try testing.expectEqual(1.0, v1.minimum());
    try testing.expectEqual(Vector(f32, 3).from(.{ 2.0, 4.0, 4.0 }), v1.maximumOfed(v2));
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 }), v1.minimumOfed(v2));
    try testing.expectEqual(Vector(f32, 3).from(.{ 2.0, 2.0, 2.0 }), v1.maximized());
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 1.0, 1.0 }), v1.minimized());

    const v3 = Vector(i64, 3).from(.{ 1, 2, 2 });
    const v4 = Vector(i64, 3).from(.{ 2, 4, 4 });
    try testing.expectEqual(2, v3.maximum());
    try testing.expectEqual(1, v3.minimum());
    try testing.expectEqual(Vector(i64, 3).from(.{ 2, 4, 4 }), v3.maximumOfed(v4));
    try testing.expectEqual(Vector(i64, 3).from(.{ 1, 2, 2 }), v3.minimumOfed(v4));
    try testing.expectEqual(Vector(i64, 3).from(.{ 2, 2, 2 }), v3.maximized());
    try testing.expectEqual(Vector(i64, 3).from(.{ 1, 1, 1 }), v3.minimized());
}

test "Inverted, Negated" {
    const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 0.5, 0.5 }), v1.inversed());

    const v2 = Vector(i64, 3).from(.{ 1, 2, 2 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 0.5, 0.5 }), v2.inversed());

    try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, -2.0, -2.0 }), v1.negated());
    try testing.expectEqual(Vector(i64, 3).from(.{ -1, -2, -2 }), v2.negated());

    try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, -0.5, -0.5 }), v1.negInversed());
    try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, -0.5, -0.5 }), v2.negInversed());
}

test "Clamping" {
    // const v1 = Vector(f32, 3).from(.{ 0.0, 2.0, 4.0 });
    // const minf: f32 = 1.0;
    // const maxf: f32 = 3.0;
    // const mini: i32 = 1;
    // const maxi: i32 = 3;

    // commented out tests are expected to fail because of
    // the type mismatch between integral types and comptime_float
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(minf, maxf));
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(mini, maxi));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(minf, maxi));
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(mini, maxf));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(minf, 3.0));
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(minf, 3));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(1.0, maxf));
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(1, maxf));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(mini, 3.0));
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(mini, 3));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(1.0, maxi));
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(1, maxi));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(1.0, 3.0));
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(1, 3));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(1.0, 3));
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }), v1.clamped(1, 3.0));
    //
    // const v2 = Vector(i64, 3).from(.{ 1, 2, 4 });
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1, 2, 3 }), v2.clamped(minf, maxf));
    // try testing.expectEqual(Vector(i64, 3).from(.{ 1, 2, 3 }), v2.clamped(mini, maxi));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1, 2, 3 }), v2.clamped(minf, maxi));
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1, 2, 3 }), v2.clamped(mini, maxf));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1, 2, 3 }), v2.clamped(minf, 3.0));
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1, 2, 3 }), v2.clamped(minf, 3));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1, 2, 3 }), v2.clamped(1.0, maxf));
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1, 2, 3 }), v2.clamped(1, maxf));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1, 2, 3 }), v2.clamped(mini, 3.0));
    // try testing.expectEqual(Vector(i64, 3).from(.{ 1, 2, 3 }), v2.clamped(mini, 3));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1, 2, 3 }), v2.clamped(1.0, maxi));
    // try testing.expectEqual(Vector(i64, 3).from(.{ 1, 2, 3 }), v2.clamped(1, maxi));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1, 2, 3 }), v2.clamped(1.0, 3.0));
    // try testing.expectEqual(Vector(i64, 3).from(.{ 1, 2, 3 }), v2.clamped(1, 3));
    //
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1, 2, 3 }), v2.clamped(1.0, 3));
    // try testing.expectEqual(Vector(f32, 3).from(.{ 1, 2, 3 }), v2.clamped(1, 3.0));
}

test "Formatting" {
    const v1 = Vector(f32, 3).from(.{ 1.2, 2.0, 0.25 });
    var buf: [64]u8 = undefined;
    const fmt = try std.fmt.bufPrint(&buf, "{}", .{v1});
    try testing.expect(std.mem.eql(u8, "Vector3(1.2, 2, 0.25)", fmt));
}
