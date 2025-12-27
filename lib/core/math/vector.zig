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

    return extern union {
        simd: @Vector(N, T),
        data: [N]T,
        comp: switch (N) {
            2 => extern struct { x: T, y: T },
            3 => extern struct { x: T, y: T, z: T },
            4 => extern struct { x: T, y: T, z: T, w: T },
            else => [N]T
        },
        size: switch (N) {
            2 => extern struct { width: T, height: T },
            3 => extern struct { width: T, height: T, depth: T },
            4 => extern struct { width: T, height: T, depth: T, time: T },
            else => [N]T,
        },

        pub const UNIT = switch (N) {
            2 => struct {
                pub const LEFT = Self.unitN(0);
                pub const RIGHT = Self.unitP(0);
                pub const UP = Self.unitN(1);
                pub const DOWN = Self.unitP(1);
            },
            3 => struct {
                pub const LEFT = Self.unitN(0);
                pub const RIGHT = Self.unitP(0);
                pub const DOWN = Self.unitN(1);
                pub const UP = Self.unitP(1);
                pub const FORWARD = Self.unitN(2);
                pub const BACK = Self.unitP(2);
                pub const MODEL_LEFT = Self.unitP(0);
                pub const MODEL_RIGHT = Self.unitN(0);
                pub const MODEL_TOP = Self.unitP(1);
                pub const MODEL_BOTTOM = Self.unitN(1);
                pub const MODEL_FRONT = Self.unitP(2);
                pub const MODEL_REAR = Self.unitN(2);
            },
            else => {},
        };

        // zig fmt: off
        const Self = @This();       // Type alias for self Vector type
        const Alt = Vector(f32, N); // Alternate Vector return type of integer type vectors
        const R = f32;              // Alternate scalar return type of Integral type vectors
        const V = @Vector(N, T);    // SIMD Vector representaiton of self
        const B = @Vector(N, bool); // Boolean SIMD Vector type
        const len: u16 = N;                       // stored Vector type length
        const isInt: bool = @typeInfo(T) == .int; // stored Vector type is integer
        const BoolInt = @Type(.{ .int = .{ .signedness = .unsigned, .bits = N } });
        // zig fmt: on

        inline fn scalar(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) R else T;
        }

        inline fn compare(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) comptime_int else comptime_float;
        }

        pub const VError = error{
            DivideByZero,
        };

        /// Default initialization
        /// Vector components are set to undefined
        ///
        /// < Self: A new Vector
        pub inline fn init() Self {
            return .{ .simd = undefined };
        }

        /// Comprehensive initialization
        /// Vector components are set based on provided value
        ///
        /// > value: anytype
        ///     Value to set components with
        ///
        /// < Vector(T, N): A new Vector
        pub inline fn from(
            value_: anytype,
        ) Self {
            return .{ .simd = vectorFromAny(value_, 0) };
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
            return .{ .simd = self.simd };
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
            fill_: compare(T),
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
        ///     Type that array is converted from
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
        inline fn resizeArrayComptime(
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

        inline fn resizeArray(
            I: type,
            M_: u16,
            values_: [M_]I,
            fill_: I,
        ) [N]T {
            const old: [M_]I = values_;
            var new: [N]I = [_]I{fill_} ** N;
            const min_size = @min(M_, N);
            new[0..min_size].* = old[0..min_size].*;
            return arrayFrom(I, new);
        }

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
        /// < SIMD Vector(N, T): Converted SIMD Vector
        pub inline fn vectorFromAny(
            value_: anytype,
            fill_: compare(T),
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
                    // else => arrayFrom(a.child, value_),
                    else => switch (a.child) {
                        comptime_int, comptime_float => resizeArrayComptime(a.child, value_.len, value_, fill_),
                        else => resizeArray(a.child, value_.len, value_, fill_),
                    },
                },
                .pointer => |p| switch (v_type) {
                    []T => blk: {
                        if (value_.len != N) {
                            break :blk switch (p.child) {
                                comptime_int, comptime_float => resizeArrayComptime(p.child, value_.len, value_, fill_),
                                else => resizeArray(p.child, value_.len, value_, fill_),
                            };
                        }
                        break :blk value_.*;
                    },
                    else => vectorFromAny(value_.*, 0),
                },
                .vector => |v| switch (v_type) {
                    V => value_,
                    else => blk: {
                        if (v.len != N) {
                            break :blk switch (v.child) {
                                comptime_int, comptime_float => resizeArrayComptime(v.child, v.len, value_, fill_),
                                else => resizeArray(v.child, v.len, value_, fill_),
                            };
                        }
                        break :blk arrayFrom(@typeInfo(v_type).child, value_);
                    },
                },
                .@"struct" => |s| switch (v_type) {
                    else => blk: {
                        if (s.fields.len == 0) break :blk @splat(0);
                        if (s.is_tuple) {
                            const I: type = comptime iblk: {
                                const i: type = s.fields[0].type;
                                const flag: bool = for (s.fields) |f| {
                                    if (f.type != i) break false;
                                } else true;
                                const msg = "Tuple elements must be of the same type";
                                break :iblk if (flag) i else @compileError(msg);
                            };
                            const size: usize = s.fields.len;
                            if (size != N) {
                                break :blk switch (I) {
                                    comptime_int, comptime_float => resizeArrayComptime(I, size, value_, fill_),
                                    else => resizeArray(I, size, value_, fill_),
                                };
                            }
                            break :blk arrayFrom(I, value_);
                        } else {
                            @compileError("Unsupported struct");
                        }
                    },
                },
                .@"union" => switch (v_type) {
                    Self => value_.simd,
                    else => if (@hasField(v_type, "simd")) blk: {
                        if (@typeInfo(@TypeOf(value_.simd)) == .vector) {
                            break :blk vectorFromAny(value_.data, fill_);
                        } else {
                            @compileError("Unsupported union simd declaration");
                        }
                    } else {
                        @compileError("Unsupported union");
                    },
                },
                else => {
                    @compileError(std.fmt.comptimePrint("Unsupported Type: {any}\n", .{v_type}));
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

            return Vector(T, indices_.len).from(@shuffle(T, self.simd, undefined, @abs(mask)));
        }

        /// Update Vector with Summation of vectors by components
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

            self.simd = self.simd + b;
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
            self: *const Self,
            other_: anytype,
        ) Self {
            return self.clone().ptr().summate(other_).*;
        }

        /// Update Vector with Difference of vectors by components
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

            self.simd = self.simd - b;
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
            self: *const Self,
            other_: anytype,
        ) Self {
            return self.clone().ptr().subtract(other_).*;
        }

        /// Update Vector with Product of vectors by components
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

            self.simd = self.simd * b;
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
            self: *const Self,
            other_: anytype,
        ) Self {
            return self.clone().ptr().multiply(other_).*;
        }

        /// Update Vector with Quotient of vectors by components
        /// Throws error if division by zero is attempted
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

            self.simd = self.simd / b;
            return self;
        }

        /// New Vector is Quotient of vectors by components
        /// Throws error if division by zero is attempted
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to divide by
        ///
        /// < Self: Quotient Vector
        pub inline fn divided(
            self: *const Self,
            other_: anytype,
        ) !Self {
            return (try self.clone().ptr().divide(other_)).*;
        }

        /// Update Vector with Modulus of vectors by components
        /// Throws error if division by zero is attempted
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

            self.simd = @mod(self.simd, b);
            return self;
        }

        /// New Vector is Modulus of vectors by components
        /// Throws error if division by zero is attempted
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to divide by
        ///
        /// < Self: Modulus Vector
        pub inline fn moduloed(
            self: *const Self,
            other_: anytype,
        ) !Self {
            return (try self.clone().ptr().modulo(other_)).*;
        }

        /// Update Vector with Remainder from division of vectors by components
        /// Throws error if division by zero is attempted
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

            self.simd = @rem(self.simd, b);
            return self;
        }

        /// New Vector is Remainder from division of vectors by components
        /// Throws error if division by zero is attempted
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to divide
        ///
        /// < Self: Remainder Vector
        pub inline fn remaindered(
            self: *const Self,
            other_: anytype,
        ) !Self {
            return (try self.clone().ptr().remainder(other_)).*;
        }

        /// Comparison SIMD Vector of less than for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < SIMD Vector(N, bool): Comparison SIMD Vector
        pub inline fn lesser(
            self: *const Self,
            other_: anytype,
        ) B {
            const b: V = vectorFromAny(other_, 0);

            return self.simd < b;
        }

        /// Comparison scalar of less than for vectors by components
        /// True if all components of current are lesser than other
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < bool: Comparison scalar
        pub inline fn isLesser(
            self: *const Self,
            other_: anytype,
        ) bool {
            return @reduce(.And, self.lesser(other_));
        }

        /// Comparison SIMD Vector of less than or equal for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < SIMD Vector(N, bool): Comparison SIMD Vector
        pub inline fn lesserEq(
            self: *const Self,
            other_: anytype,
        ) B {
            const b: V = vectorFromAny(other_, 0);

            return self.simd <= b;
        }

        /// Comparison scalar of less than or equal for vectors by components
        /// True if all components of current are lesser than or equal to other
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < bool: Comparison scalar
        pub inline fn isLesserEq(
            self: *const Self,
            other_: anytype,
        ) bool {
            return @reduce(.And, self.lesserEq(other_));
        }

        /// Comparison SIMD Vector of greater than for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < SIMD Vector(N, bool): Comparison SIMD Vector
        pub inline fn greater(
            self: *const Self,
            other_: anytype,
        ) B {
            const b: V = vectorFromAny(other_, 0);

            return self.simd > b;
        }

        /// Comparison scalar of greater than for vectors by components
        /// True if all components of current are greater than other
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < bool: Comparison scalar
        pub inline fn isGreater(
            self: *const Self,
            other_: anytype,
        ) bool {
            return @reduce(.And, self.greater(other_));
        }

        /// Comparison SIMD Vector of greater than or equal for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < SIMD Vector(N, bool): Comparison SIMD Vector
        pub inline fn greaterEq(
            self: *const Self,
            other_: anytype,
        ) B {
            const b: V = vectorFromAny(other_, 0);

            return self.simd >= b;
        }

        /// Comparison scalar of greater than or equal for vectors by components
        /// True if all components of current are greater than or equal to other
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < bool: Comparison scalar
        pub inline fn isGreaterEq(
            self: *const Self,
            other_: anytype,
        ) bool {
            return @reduce(.And, self.greaterEq(other_));
        }

        /// Comparison SIMD Vector of equality for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < SIMD Vector(N, bool): Comparison SIMD Vector
        pub inline fn equal(
            self: *const Self,
            other_: anytype,
        ) B {
            const b: V = vectorFromAny(other_, 0);

            return self.simd == b;
        }

        /// Comparison scalar of equality for vectors by components
        /// True if all components of current are equal to other
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < bool: Comparison scalar
        pub inline fn isEqual(
            self: *const Self,
            other_: anytype,
        ) bool {
            return @reduce(.And, self.equal(other_));
        }

        /// Comparison SIMD Vectors of approximation for vectors by components with tolerance
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// > tolerance: ?T
        ///     Tolerance value for comparison
        ///     default: 0 | floatEps(T)
        ///
        /// < SIMD Vector(N, bool): Comparison SIMD Vector
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

            const c: @Vector(N, Y) = @abs(self.simd - b);
            const d: @Vector(N, Y) = @splat(t);

            return c <= d;
        }

        /// Comparison scalar of approximation for vectors by components with tolerance
        /// True if all components of current are approximately equal to other
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// > tolerance: ?T
        ///     Tolerance value for comparison
        ///     default: 0 | floatEps(T)
        ///
        /// < bool: Comparison scalar
        pub inline fn isApproximate(
            self: *const Self,
            other_: anytype,
            tolerance: ?T,
        ) bool {
            return @reduce(.And, self.approximate(other_, tolerance));
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
            const c: V = self.simd * b;

            return @reduce(.Add, c);
        }

        /// Compute the outer dot product (results in a matrix) of vectors
        /// This returns a flat array in row-major order
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compute outer product with
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
            const b: @Vector(N * N, T) = @shuffle(T, self.simd, undefined, mask);

            return a * b;
        }

        /// Compute the outer product (results in a matrix) of vectors
        /// This returns a 2d array in row-major order
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compute outer product with
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
        ///     Vectors to compute cross product with
        ///
        /// < Self: Cross product as new Vector
        pub inline fn cross(
            vectors_: [N - 1]Self,
        ) Self {
            if (N == 2) {
                const a = vectors_[0];
                return .{ .comp = .{
                    .x = a.comp.y,
                    .y = -a.comp.x,
                } };
            } else if (N == 3) {
                const a = vectors_[0];
                const b = vectors_[1];
                return .{ .comp = .{
                    .x = a.comp.y * b.comp.z - a.comp.z * b.comp.y,
                    .y = a.comp.z * b.comp.x - a.comp.x * b.comp.z,
                    .z = a.comp.x * b.comp.y - a.comp.y * b.comp.x,
                } };
            } else {
                var result: [N]T = undefined;

                var matrix: [N][N]T = undefined;

                for (vectors_, 0..) |v, i| {
                    matrix[i] = v.simd;
                }
                matrix[N - 1] = [_]T{0} ** N;

                for (0..N) |i| {
                    matrix[N - 1][i] = 1;

                    result[i] = determinant(N, &matrix);

                    matrix[N - 1][i] = 0;
                }

                return Self.from(result);
            }
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

        /// Compute the n-volume spanned by opposing corner Vectors
        /// Does not include content of sides bounded by other Vector
        /// Other vectors converterd from anytype
        ///
        /// > other: anytype
        ///     Vector opposite corner
        ///
        /// < T: unit^n volume scalar
        pub inline fn content(
            self: *const Self,
            comptime ResultT: type,
            other_: anytype,
        ) ResultT {
            const res_info = @typeInfo(ResultT);
            if (comptime isInt) {
                if (res_info != .int) @compileError("ResultT must be an integer type for integer vectors");
            } else {
                if (res_info != .float) @compileError("ResultT must be a float type for float vectors");
            }
            const b: V = vectorFromAny(other_, 0);
            const diff = self.simd - b;

            const RVec = @Vector(N, ResultT);
            const wide: RVec = if (comptime isInt) @intCast(@abs(diff)) else @floatCast(@abs(diff));
            return @reduce(.Mul, wide);
        }

        /// Compute whether Vector is contained within bounds defined
        /// by two corner Vectors
        /// Other vectors converterd from anytype
        ///
        /// > a: anytype
        ///     First corner Vector
        ///
        /// > b: anytype
        ///     Second corner Vector
        ///
        /// > bounds: []const u8
        ///     Content bounds defined by two characters from sets:
        ///     0:{'[', '('} and 1:{']', ')'}
        ///
        /// < bool: Containment boolean
        pub inline fn contained(
            self: *const Self,
            a_: anytype,
            b_: anytype,
            comptime bounds_: []const u8,
        ) bool {
            if (bounds_.len != 2) @compileError("bounds_ must be of length 2");
            if (comptime std.mem.indexOfNone(u8, bounds_[0..1], "[(") != null) {
                @compileError("Min bounds can only contain '[', '(', found: " ++ bounds_[0..1]);
            }
            if (comptime std.mem.indexOfNone(u8, bounds_[1..], "])") != null) {
                @compileError("Max bounds can only contain ']', ')', found: " ++ bounds_[1..]);
            }

            const a: V = vectorFromAny(a_, 0);
            const b: V = vectorFromAny(b_, 0);

            const min_vec: V = @min(a, b);
            const max_vec: V = @max(a, b);

            const greater_min: B = switch (bounds_[0]) {
                '[' => min_vec <= self.simd,
                '(' => min_vec < self.simd,
                else => unreachable,
            };
            const less_max: B = switch (bounds_[1]) {
                ']' => self.simd <= max_vec,
                ')' => self.simd < max_vec,
                else => unreachable,
            };

            return @reduce(.And, greater_min & less_max);
        }

        /// Compute length (magnitude) of vector
        /// returns float if vector element type is int
        ///
        /// < T | R: Length scalar
        pub inline fn length(
            self: *const Self,
        ) scalar(T) {
            return switch (@typeInfo(T)) {
                .float => @sqrt(@reduce(.Add, self.simd * self.simd)),
                .int => @sqrt(@as(R, @floatFromInt(@reduce(.Add, self.simd * self.simd)))),
                else => unreachable,
            };
        }

        /// Compute squared length of vector
        ///
        /// < T: Squared length scalar
        pub inline fn lengthSq(
            self: *const Self,
        ) T {
            return @reduce(.Add, self.simd * self.simd);
        }

        /// Update Vector with Normalization of itself to unit length
        /// For integer type Vector, components are rounded up or down
        /// Does not protect against division by zero (zero vector only)
        ///
        /// < !*Self: Updated Current Vector
        pub inline fn normalize(
            self: *Self,
        ) *Self {
            const v_len = @reduce(.Add, self.simd * self.simd);
            const a = if (comptime isInt) Vector(R, N).vectorFromAny(self.data, 0) else self.simd;

            const b = if (comptime isInt) @as(@Vector(N, scalar(T)), @splat(@sqrt(@as(R, @floatFromInt(v_len))))) else //
                @as(@Vector(N, scalar(T)), @splat(@sqrt(v_len)));
            const result = a / b;

            self.simd = if (comptime isInt) @as(V, @intFromFloat(@round(result))) else result;
            return self;
        }

        /// Copy of current Vector normalized to unit length
        /// If vector length is 0, null is returned
        /// For integer type Vector, components are rounded up or down
        ///
        /// < Self: Normalized Vector
        pub inline fn normalized(
            self: *const Self,
        ) Self {
            return self.clone().ptr().normalize().*;
        }

        /// Check if Vector is normalized to unit length
        ///
        /// < bool: Normalization boolean
        pub inline fn isNormalized(
            self: *const Self,
        ) bool {
            const _len = self.length();
            const Y: type = scalar(T);
            return std.math.approxEqAbs(Y, _len, 1.0, std.math.floatEps(Y));
        }

        /// Update Vector with Sign of components
        /// Sign of 0 = 0
        ///
        /// < *Self: Updated Current Vector
        pub inline fn signZ(
            self: *Self,
        ) *Self {
            const comps = self.simd;
            const abs = @abs(comps);
            var sabs = if (comptime isInt) @as(V, @intCast(abs)) else abs;
            const equals = sabs == vectorFromAny(0, 0);
            sabs = @select(T, equals, vectorFromAny(1, 0), sabs);

            self.simd = comps / sabs;
            return self;
        }

        /// Copy of current Vector with Sign of components
        /// Sign of 0 = 0
        ///
        /// < Self: Signed Vector
        pub inline fn signedZ(
            self: *const Self,
        ) Self {
            return self.clone().ptr().signZ().*;
        }

        /// Update Vector with the Sign of Components
        /// Sign of 0 = 1
        ///
        /// < *Self: Update Current Vector
        pub inline fn sign(
            self: *Self,
        ) *Self {
            _ = self.signZ();
            const comps = self.simd;
            const equals = comps == vectorFromAny(0, 0);
            self.simd = @select(T, equals, vectorFromAny(1, 0), comps);
            return self;
        }

        /// Copy of current Vector with the Sign of Components
        /// Sign of 0 = 1
        ///
        /// < Self: Signed Vector
        pub inline fn signed(
            self: *const Self,
        ) Self {
            return self.clone().ptr().sign().*;
        }

        /// Update Vector with Absolute value of components
        ///
        /// < *Self: Updated Current Vector
        pub inline fn absolute(
            self: *Self,
        ) *Self {
            self.simd = if (comptime isInt) @as(V, @intCast(@abs(self.simd))) else @abs(self.simd);
            return self;
        }

        /// Copy of current Vector with Absolute value of components
        ///
        /// < Self: Absolute Vector
        pub inline fn absoluted(
            self: *const Self,
        ) Self {
            return self.clone().ptr().absolute().*;
        }

        /// Compute direction vector between vectors
        /// If length of distance is zero, zero vector is returned
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to calculate direction to
        ///
        /// < Self: Direction Vector
        pub inline fn directionTo(
            self: *const Self,
            other_: anytype,
        ) Self {
            var new = if (@TypeOf(other_) == Self) other_ else Self.from(other_);
            _ = new.subtract(self);
            if (new.lengthSq() == 0) return Self.from(0);
            return new.normalized();
        }

        /// Calculate euclidean distance between vectors
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
            // const new = if (@TypeOf(other_) == Self) other_ else Self.from(other_);
            return switch (@typeInfo(T)) {
                .float => @sqrt(self.distanceToSq(other_)),
                .int => @sqrt(@as(R, @floatFromInt(self.distanceToSq(other_)))),
                else => unreachable,
            };
        }

        /// Calculate squared euclidean distance between vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to calculate distance to
        ///
        /// < T: Squared distance scalar
        pub inline fn distanceToSq(
            self: *const Self,
            other_: anytype,
        ) T {
            var new = if (@TypeOf(other_) == Self) other_ else Self.from(other_);
            return new.subtract(self).lengthSq();
        }

        /// Calculate manhattan distance between vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to calculate distance to
        ///
        /// < T: Manhattan distance scalar
        pub inline fn manhattanTo(
            self: *const Self,
            other_: anytype,
        ) T {
            const b: V = vectorFromAny(other_, 0);
            const c: V = if (comptime isInt) @intCast(@abs(self.simd - b)) else @abs(self.simd - b);

            return @reduce(.Add, c);
        }

        /// In place Linear Interpolation between vectors at time t
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to interpolate to
        ///
        /// > t: f32
        ///     Time to interpolate at
        ///
        /// < *Self: Interpolated Current Vector
        pub inline fn interpolate(
            self: *Self,
            other_: anytype,
            time_: f32,
        ) *Self {
            const time = if (comptime isInt) @trunc(time_) else time_;
            var new = Self.from(other_);
            return self.multiply(1 - time).summate(new.multiply(time).*);
        }

        /// New Vector is Linear interpolates between vectors at time t
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to interpolate to
        ///
        /// > time: f32
        ///     Time to interpolate at
        ///
        /// < Self: Interpolated Vector
        pub inline fn interpolated(
            self: *const Self,
            other_: anytype,
            time_: f32,
        ) Self {
            return self.clone().ptr().interpolate(other_, time_).*;
        }

        /// Maximum scalar of a vector
        ///
        /// < T: Max scalar
        pub inline fn maximum(
            self: *const Self,
        ) T {
            return @reduce(.Max, self.simd);
        }

        /// Minimum scalar of a vector
        ///
        /// < T: Min scalar
        pub inline fn minimum(
            self: *const Self,
        ) T {
            return @reduce(.Min, self.simd);
        }

        /// Update Vector with maximum components of either vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Self: Maximum Vector
        pub inline fn maximumOf(
            self: *Self,
            other_: anytype,
        ) *Self {
            const b: V = vectorFromAny(other_, 0);

            self.simd = @max(self.simd, b);
            return self;
        }

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
            return self.clone().ptr().maximumOf(other_).*;
        }

        /// Update Vector with minimum components of either vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Self: Minimum Vector
        pub inline fn minimumOf(
            self: *Self,
            other_: anytype,
        ) *Self {
            const b: V = vectorFromAny(other_, 0);

            self.simd = @min(self.simd, b);
            return self;
        }

        /// Update Vector with minimum components of either vectors
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
            return self.clone().ptr().minimumOf(other_).*;
        }

        /// Vector has all components updated to current maximum
        ///
        /// < Self: maximized Vector
        pub inline fn maximize(
            self: *Self,
        ) *Self {
            self.simd = @splat(@reduce(.Max, self.simd));
            return self;
        }

        /// New Vector with all components updated to current maximum
        ///
        /// < Self: maximized Vector
        pub inline fn maximized(
            self: *const Self,
        ) Self {
            return self.clone().ptr().maximize().*;
        }

        /// Vector has all components updated to current minimum
        ///
        /// < Self: minimized Vector
        pub inline fn minimize(
            self: *Self,
        ) *Self {
            self.simd = @splat(@reduce(.Min, self.simd));
            return self;
        }

        /// New Vector with all components updated to current minimum
        ///
        /// < Self: minimized Vector
        pub inline fn minimized(
            self: *const Self,
        ) Self {
            return self.clone().ptr().minimize().*;
        }

        /// Update Vector with inverse for all components
        /// Not supported for integer vectors
        ///
        /// < *Self: Updated Current Vector
        pub inline fn inverse(
            self: *Self,
        ) switch (isInt) {
            true => @compileError("Operation not supported for integer vectors"),
            false => *Self,
        } {
            const b: V = @splat(1);

            self.simd = b / self.simd;
            return self;
        }

        /// New Vector with inverse for all components
        /// Not supported for integer vectors
        ///
        /// < Self: Inversed Vector
        pub inline fn inversed(
            self: *Self,
        ) Self {
            return self.clone().ptr().inverse().*;
        }

        /// Update Vector with negation for all components
        ///
        /// < *Self: Updated Current Vector
        pub inline fn negate(
            self: *Self,
        ) *Self {
            const b: V = @splat(-1);

            self.simd = self.simd * b;
            return self;
        }

        /// New Vector with negation for all components
        ///
        /// < Self: Negated Vector
        pub inline fn negated(
            self: *Self,
        ) Self {
            return self.clone().ptr().negate().*;
        }

        /// Update Vector with negation and inversion of all components
        /// Not supported for integer vectors
        ///
        /// < *Self: Updated Current Vector
        pub inline fn negInverse(
            self: *Self,
        ) switch (isInt) {
            true => @compileError("Operation not supported for integer vectors"),
            false => *Self,
        } {
            const b: V = @splat(-1);

            self.simd = b / self.simd;
            return self;
        }

        /// New Vector with negation and inversion of all components
        /// Not supported for integer vectors
        ///
        /// < Self: Negated and inversed Vector
        pub inline fn negInversed(
            self: *const Self,
        ) Self {
            return self.clone().ptr().negInverse().*;
        }

        /// Update Vector with components clamped between min and max
        ///
        /// > min_: anytype
        ///     Minimum value to clamp to
        ///
        /// > max_: anytype
        ///     Maximum value to clamp to
        ///
        /// < *Self: Updated Current Vector
        pub inline fn clamp(
            self: *Self,
            min_: anytype,
            max_: anytype,
        ) *Self {
            const min_v = vectorFromAny(min_, 0);
            const max_v = vectorFromAny(max_, 0);

            self.simd = @min(max_v, @max(min_v, self.simd));
            return self;
        }

        /// New Vector with components clamped between min and max
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
            return self.clone().ptr().clamp(min_, max_).*;
        }

        /// Update Vector with projection onto given normal vector
        /// normal_ must be normalized
        ///
        /// > normal_: Self
        ///     Vector to project onto
        ///
        /// < *Self: Projected Current Vector
        pub inline fn project(self: *Self, normal_: Self) *Self {
            std.debug.assert(normal_.isNormalized());
            const dot = self.inner(normal_) / normal_.lengthSq();
            self.simd = normal_.simd * @as(V, @splat(dot));
            return self;
        }

        /// New Vector projected onto given normal vector
        /// normal_ must be normalized
        ///
        /// > other_: anytype
        ///     Vector to project onto
        ///
        /// < Self: Projected Vector
        pub inline fn projected(
            self: *const Self,
            other_: Self,
        ) Self {
            return self.clone().ptr().project(other_).*;
        }

        // Update Vector to its rejection for a given normal vector
        // rejection is perpendicular to projection on normal
        // normal_ must be normalized
        //
        // > normal_: Self
        //     Normal Vector to reject from
        //
        // < *Self: Updated Current Vector
        pub inline fn reject(
            self: *Self,
            normal_: Self,
        ) *Self {
            std.debug.assert(normal_.isNormalized());
            const dot = self.inner(normal_);
            self.simd = self.simd - normal_.simd * @as(V, @splat(dot));
            return self;
        }

        // New Vector of its rejection for a given normal vector
        // rejection is perpendicular to projection on normal
        // normal_ must be normalized
        //
        // > normal_: Self
        //     Normal Vector to reject from
        //
        // < Self: Rejected Vector
        pub inline fn rejected(
            self: *const Self,
            normal_: Self,
        ) Self {
            return self.clone().ptr().reject(normal_).*;
        }

        /// Index of axis with minimum component
        ///
        /// < usize: Minimum axis index
        pub inline fn minAxisIndex(
            self: *const Self,
        ) usize {
            const min_vec: V = @splat(self.minimum());
            const min_bool: BoolInt = @bitCast(self.simd == min_vec);
            return @ctz(min_bool);
        }

        /// Index of axis with maximum component
        ///
        /// < usize: Maximum axis index
        pub inline fn maxAxisIndex(
            self: *const Self,
        ) usize {
            const max_vec: V = @splat(self.maximum());
            const max_bool: BoolInt = @bitCast(self.simd == max_vec);
            return @ctz(max_bool);
        }

        // Update Vector with length clamped between min_length and max_length
        // If vector length is 0, no changes are made
        // For integer type Vector, components are rounded up or down
        //
        // > min_length_: scalar(T)
        //     Minimum length to clamp to
        //
        // > max_length_: scalar(T)
        //     Maximum length to clamp to
        //
        // < *Self: Updated Current Vector
        pub inline fn clampLength(
            self: *Self,
            min_length_: scalar(T),
            max_length_: scalar(T),
        ) *Self {
            if (min_length_ > max_length_) {
                @compileError("min_length cannot be greater than max_length");
            }
            const _len = self.length();
            if (!(0 < _len)) return self;

            const a = if (comptime isInt) Vector(R, N).from(self.simd) else self;
            if (max_length_ < _len) {
                const ratio = max_length_ / _len;
                const result = a.simd * @as(V, @splat(ratio));
                self.simd = if (comptime isInt) @as(V, @intFromFloat(@round(result))) else result;
            } else if (_len < min_length_) {
                const ratio = min_length_ / _len;
                const result = a.simd * @as(V, @splat(ratio));
                self.simd = if (comptime isInt) @as(V, @intFromFloat(@round(result))) else result;
            }
            return self;
        }

        // New Vector with length clamped between min_length and max_length
        // If vector length is 0, no changes are made
        // For integer type Vector, components are rounded up or down
        //
        // > min_length_: scalar(T)
        //     Minimum length to clamp to
        // > max_length_: scalar(T)
        //     Maximum length to clamp to
        //
        // < Self: Clamped Length Vector
        pub inline fn clampedLength(
            self: *const Self,
            min_length_: T,
            max_length_: T,
        ) Self {
            return self.clone().ptr().clampLength(min_length_, max_length_).*;
        }

        // Update Vector moving it toward other by delta units
        // If distance to other is less than delta, sets to other
        // other vector converterd from anytype
        //
        // > other: anytype
        //     Vector to move toward
        //
        // > delta_: scalar(T)
        //     Amount to move toward other
        //
        // < *Self: Updated Current Vector
        pub inline fn moveToward(
            self: *Self,
            other_: anytype,
            delta_: scalar(T),
        ) *Self {
            const other = vectorFromAny(other_, 0);
            const dir = other - self.simd;
            const _len =
                if (comptime isInt) @sqrt(@as(R, @floatFromInt(@reduce(.Add, dir * dir)))) //
                else @sqrt(@reduce(.Add, dir * dir));
            if (_len <= delta_ or _len < std.math.floatEps(scalar(T))) {
                self.simd = other;
            } else {
                self.simd = if (comptime isInt) blk: {
                    const vect = @Vector(N, R);
                    const dist = (@as(vect, @floatFromInt(dir)) / @as(vect, @splat(_len))) *
                        @as(vect, @splat(delta_));
                    break :blk self.simd + @as(V, @intFromFloat(@round(dist)));
                } else blk: {
                    const dist = (dir / @as(V, @splat(_len))) * @as(V, @splat(delta_));
                    break :blk self.simd + dist;
                };
            }
            return self;
        }

        // New Vector moved toward other by delta units
        // If distance to other is less than delta, sets to other
        // other vector converterd from anytype
        //
        // > other_: anytype
        //     Vector to move toward
        //
        // > delta_: scalar(T)
        //     Amount to move toward other
        //
        // < Self: Moved Toward Vector
        pub inline fn movedToward(
            self: *const Self,
            other_: anytype,
            delta_: f32,
        ) Self {
            return self.clone().ptr().moveToward(other_, delta_).*;
        }

        // Update Vector to bounce off given normal vector
        // normal_ must be normalized
        //
        // > normal_: Self
        //     Vector to bounce off of
        //
        // < *Self: Bounced Current Vector
        pub inline fn bounce(
            self: *Self,
            normal_: Self,
        ) *Self {
            std.debug.assert(normal_.isNormalized());
            const dot = self.inner(normal_);
            self.simd = self.simd - normal_.simd * @as(V, @splat(2 * dot));
            return self;
        }

        // New Vector bounced off given normal vector
        // normal_ must be normalized
        //
        // > normal_: Self
        //     Vector to bounce off of
        //
        // < Self: Bounced Vector
        pub inline fn bounced(
            self: *const Self,
            normal_: Self,
        ) Self {
            return self.clone().ptr().bounce(normal_).*;
        }

        // Update Vector to its reflection about given normal vector
        // normal_ must be normalized
        //
        // > normal_: Self
        //     Vector to reflect about
        //
        // < *Self: Reflected Current Vector
        pub inline fn reflect(
            self: *Self,
            normal_: Self,
        ) *Self {
            std.debug.assert(normal_.isNormalized());
            const dot = self.inner(normal_);
            self.simd = normal_.simd * @as(V, @splat(2 * dot)) - self.simd;
            return self;
        }

        // New Vector reflected about given normal vector
        // normal_ must be normalized
        //
        // > normal_: Self
        //     Vector to reflect about
        //
        // < Self: Reflected Vector
        pub inline fn reflected(
            self: *const Self,
            normal_: Self,
        ) Self {
            return self.clone().ptr().reflect(normal_).*;
        }

        /// Update Vector with floor of components
        /// Integer vectors are unchanged
        ///
        /// < *Self: Updated Current Vector
        pub inline fn floor(
            self: *Self,
        ) *Self {
            if (comptime isInt) return self;
            self.simd = @floor(self.simd);
            return self;
        }

        /// Copy of current Vector with floor of components
        /// Integer vectors are unchanged
        ///
        /// < Self: Floored Vector
        pub inline fn floored(
            self: *const Self,
        ) Self {
            return self.clone().ptr().floor().*;
        }

        /// Update Vector with ceil of components
        /// Integer vectors are unchanged
        ///
        /// < *Self: Updated Current Vector
        pub inline fn ceil(
            self: *Self,
        ) *Self {
            if (comptime isInt) return self;
            self.simd = @ceil(self.simd);
            return self;
        }

        /// Copy of current Vector with ceil of components
        /// Integer vectors are unchanged
        ///
        /// < Self: Ceiled Vector
        pub inline fn ceiled(
            self: *const Self,
        ) Self {
            return self.clone().ptr().ceil().*;
        }

        /// Update Vector with round of components
        /// Integer vectors are unchanged
        ///
        /// < *Self: Updated Current Vector
        pub inline fn round(
            self: *Self,
        ) *Self {
            if (comptime isInt) return self;
            self.simd = @round(self.simd);
            return self;
        }

        /// Copy of current Vector with round of components
        /// Integer vectors are unchanged
        ///
        /// < Self: Rounded Vector
        pub inline fn rounded(
            self: *const Self,
        ) Self {
            return self.clone().ptr().round().*;
        }

        /// Update Vector with snapped components to increment
        /// For integer type Vector, components are rounded up or down
        /// If increment is 0, no snapping is performed
        /// increment vector converterd from anytype
        ///
        /// > increment: anytype
        ///     Increment to snap to
        ///
        /// < *Self: Updated Current Vector
        pub inline fn snap(
            self: *Self,
            increment_: anytype,
        ) *Self {
            const increment = vectorFromAny(increment_, 1);

            // any 0 increment values result in no snapping
            var safe_mask = increment == @as(V, @splat(0));
            var safe_increment = @select(T, safe_mask, self.simd, increment);

            // if initial component was 0, set to 1 to avoid division by zero
            safe_mask = safe_increment == @as(V, @splat(0));
            safe_increment = @select(T, safe_mask, @as(V, @splat(1)), safe_increment);

            if (comptime isInt) {
                const signs = self.signed().simd;
                const base = @divTrunc(self.simd, safe_increment) * safe_increment;
                const mod = @rem(self.simd, safe_increment);
                const double = mod * @as(V, @splat(2));
                const add_mask = @abs(double) >= @abs(safe_increment);
                const signed_increment = signs * @as(V, @intCast(@abs(safe_increment)));
                self.simd = @select(T, add_mask, base + signed_increment, base);
            } else {
                self.simd = @round(self.simd / safe_increment) * safe_increment;
            }
            return self;
        }

        /// Copy of current Vector with snapped components to increment
        /// For integer type Vector, components are rounded up or down
        /// If increment is 0, no snapping is performed
        /// increment vector converterd from anytype
        ///
        /// > increment: anytype
        ///     Increment to snap to
        ///
        /// < Self: Snapped Vector
        pub inline fn snapped(
            self: *const Self,
            increment_: anytype,
        ) Self {
            return self.clone().ptr().snap(increment_).*;
        }

        // TODO: remaining Vector methods
        //
        // aspect
        // hash
        //
        // angle_to
        // signed_angle_to
        // angle_to_point
        //
        // plane project
        //
        // angle
        // from_angle
        //
        // rotate
        // rotated
        //
        // slerp
        // cubic interpolation
        // cubic interpoaltion in time
        // bezier interpolate
        // bezier derivative

        /// Vector formatted print function
        ///
        /// Print vector as formatted string
        /// Format is `VectorN({d}, ...)` where N is vector size
        ///
        /// > writer: anytype
        ///
        /// < void
        pub fn format(
            self: *const Self,
            writer_: anytype,
        ) !void {
            try writer_.print("Vector{d}(", .{N});
            // for (self.simd, 0..) |v, i| {
            for (self.data, 0..) |v, i| {
                if (i > 0) try writer_.print(", ", .{});
                try writer_.print("{d}", .{v});
            }
            try writer_.print(")", .{});
        }
    };
}

inline fn isNumeric(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .comptime_int, .comptime_float => true,
        else => false,
    };
}

// BEGIN: Vector Tests
test "Initialize" {

    // useful data
    const a1 = [3]f32{ 1.0, 2.0, 3.0 };
    const simd1 = @as(@Vector(3, f32), a1);

    // casting
    {
        const v1 = Vector(f32, 3).from(a1);
        const v2: @Vector(3, f32) = .{ 1.0, 2.0, 3.0 };
        try testing.expectEqual(v2, v1.simd);
    }

    // empty initialization
    {
        // const v1 = Vector(f32, 3).init();
        // try testing.expectEqual([3]f32{ undefined, undefined, undefined }, v1.simd);
    }

    // splatting
    {
        // comptime_float
        const v1 = Vector(f32, 3).from(1.0);
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v1.simd);

        // comptime_int
        const v2 = Vector(f32, 3).from(1);
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v2.simd);

        // larger float
        const v3 = Vector(f32, 3).from(@as(f64, 1.0));
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v3.simd);

        // int
        const v4 = Vector(f32, 3).from(@as(i32, 1));
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v4.simd);

        // larger int
        const v5 = Vector(f32, 3).from(@as(i64, 1));
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v5.simd);
    }

    // tuples
    {
        // full tuple
        const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 });
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.simd);

        // empty tuple
        const v2 = Vector(f32, 3).from(.{});
        try testing.expectEqual([3]f32{ 0, 0, 0 }, v2.simd);

        // partial tuple
        const v3 = Vector(f32, 3).from(.{1.0});
        try testing.expectEqual([3]f32{ 1.0, 0, 0 }, v3.simd);

        // overfull tuple
        const v4 = Vector(f32, 3).from(.{ 1.0, 2.0, 3.0, 4.0 });
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v4.simd);

        // unacceptable tuple
        // WARNING: Expected Compiler Errors
        // const v5 = Vector(f32, 3).from(.{ true, true });
        // const v5 = Vector(f32, 3).from(.{ 1.0, true });
        // try testing.expectEqual([3]f32{ 1.0, 1.0, 0.0 }, v5.simd);
    }

    // other vectors
    {
        // same type, size, length
        const v1 = Vector(f32, 3).from(1.0);
        const v2 = Vector(f32, 3).from(v1);
        try testing.expectEqual([3]f32{ 1.0, 1.0, 1.0 }, v2.simd);

        // different type, same size, length
        const v3 = Vector(i32, 3).from(v1);
        try testing.expectEqual([3]i32{ 1, 1, 1 }, v3.simd);

        // same type, length, different size
        const v4 = Vector(f64, 3).from(v1);
        try testing.expectEqual([3]f64{ 1.0, 1.0, 1.0 }, v4.simd);

        // different type, size, same length
        const v5 = Vector(i64, 3).from(v1);
        try testing.expectEqual([3]i64{ 1, 1, 1 }, v5.simd);

        // different type, size, length
        const v6 = Vector(i64, 4).from(v1);
        try testing.expectEqual([4]i64{ 1, 1, 1, 0 }, v6.simd);

        // different type, size, length
        const v7 = Vector(f16, 2).from(v5);
        try testing.expectEqual([2]f16{ 1.0, 1.0 }, v7.simd);
    }

    // array
    {
        const v1 = Vector(f32, 3).from([3]f32{ 1.0, 2.0, 3.0 });
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.simd);

        const v2 = Vector(i32, 3).from([3]i32{ 1, 2, 3 });
        try testing.expectEqual([3]i32{ 1, 2, 3 }, v2.simd);
    }

    // simd vectors
    {
        const v1 = Vector(f32, 3).from(simd1);
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.simd);

        const v2 = Vector(i32, 2).from(simd1);
        try testing.expectEqual([2]i32{ 1, 2 }, v2.simd);

        const v3 = Vector(f64, 4).from(simd1);
        try testing.expectEqual([4]f64{ 1.0, 2.0, 3.0, 0.0 }, v3.simd);
    }

    // pointer
    {
        const v1 = Vector(f32, 3).from(&a1);
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.simd);

        const v2 = Vector(i32, 3).from(&a1);
        try testing.expectEqual([3]i32{ 1, 2, 3 }, v2.simd);

        const v3 = Vector(f32, 3).from(&[3]f32{ 1.0, 2.0, 3.0 });
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v3.simd);

        const v4 = Vector(f32, 3).from(a1[0..]);
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v4.simd);
    }

    // to size
    {
        const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 });
        const v2 = v1.toSize(2, 0);
        const v3 = v1.toSize(4, 0);
        var v4 = v1.toSize(3, 0);
        try testing.expectEqual([2]f32{ 1.0, 2.0 }, v2.simd);
        try testing.expectEqual([4]f32{ 1.0, 2.0, 3.0, 0.0 }, v3.simd);
        v4.data[0] = 4.0;
        try testing.expectEqual([3]f32{ 4.0, 2.0, 3.0 }, v4.simd);
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.simd);
    }

    // unit vectors
    {
        const v1 = Vector(f32, 3).unitP(0);
        try testing.expectEqual([3]f32{ 1.0, 0.0, 0.0 }, v1.simd);

        const v2 = Vector(f32, 3).unitP(1);
        try testing.expectEqual([3]f32{ 0.0, 1.0, 0.0 }, v2.simd);

        const v3 = Vector(f32, 3).unitP(2);
        try testing.expectEqual([3]f32{ 0.0, 0.0, 1.0 }, v3.simd);

        const v4 = Vector(f32, 3).unitN(0);
        try testing.expectEqual([3]f32{ -1.0, 0.0, 0.0 }, v4.simd);

        const v5 = Vector(f32, 3).unitN(1);
        try testing.expectEqual([3]f32{ 0.0, -1.0, 0.0 }, v5.simd);

        const v6 = Vector(f32, 3).unitN(2);
        try testing.expectEqual([3]f32{ 0.0, 0.0, -1.0 }, v6.simd);
    }

    // pick
    {
        var v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 });
        const v2 = v1.pick(&.{ 1, 0 });
        const v3 = v1.pick(&.{ 1, 2, 0, 1 });
        try testing.expectEqual([2]f32{ 2.0, 1.0 }, v2.simd);
        try testing.expectEqual([4]f32{ 2.0, 3.0, 1.0, 2.0 }, v3.simd);
    }

    // clone
    {
        const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 });
        const v2 = v1.clone().ptr().summate(1.0).*;
        try testing.expectEqual([3]f32{ 1.0, 2.0, 3.0 }, v1.simd);
        try testing.expectEqual([3]f32{ 2.0, 3.0, 4.0 }, v2.simd);
    }
}

test "Summation" {
    var v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expectEqual(Vector(f32, 3).from(3.0).data, v1.summated(v2).data);
    _ = v1.summate(v2);
    try testing.expectEqual(Vector(f32, 3).from(3.0).data, v1.data);
}

test "Subtraction" {
    var v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expectEqual(Vector(f32, 3).from(-1.0).data, v1.subtracted(v2).data);
    _ = v1.subtract(v2);
    try testing.expectEqual(Vector(f32, 3).from(-1.0).data, v1.data);
}

test "Multiplication" {
    var v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expectEqual(Vector(f32, 3).from(2.0).data, v1.multiplied(v2).data);
    _ = v1.multiply(v2);
    try testing.expectEqual(Vector(f32, 3).from(2.0).data, v1.data);
}

test "Division" {
    var v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expectEqual(Vector(f32, 3).from(0.5).data, (try v1.divided(v2)).data);
    _ = try v1.divide(v2);
    try testing.expectEqual(Vector(f32, 3).from(0.5).data, v1.data);
}

test "Modulus" {
    var v1 = Vector(f32, 3).from(.{ 4.0, -5.0, 6.0 });
    const v2 = Vector(f32, 3).from(3.0);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 1.0, 0.0 }).data, (try v1.moduloed(v2)).data);
    _ = try v1.modulo(v2);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 1.0, 0.0 }).data, v1.data);
}

test "Remainder" {
    var v1 = Vector(f32, 3).from(.{ 4.0, -5.0, 6.0 });
    const v2 = Vector(f32, 3).from(3.0);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, -2.0, 0.0 }).data, (try v1.remaindered(v2)).data);
    _ = try v1.remainder(v2);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, -2.0, 0.0 }).data, v1.data);
}

test "Lesser" {
    const v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expect(@reduce(.And, v1.lesser(v2)));
    try testing.expect(v1.isLesser(v2));
    try testing.expect(!@reduce(.Or, v1.lesser(v1)));
    try testing.expect(!v1.isLesser(v1));
}

test "LesserEq" {
    const v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    const v3 = Vector(f32, 3).from(0.0);
    try testing.expect(@reduce(.And, v1.lesserEq(v2)));
    try testing.expect(v1.isLesserEq(v2));
    try testing.expect(@reduce(.And, v1.lesserEq(v1)));
    try testing.expect(!v1.isLesserEq(v3));
}

test "Greater" {
    const v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    try testing.expect(@reduce(.And, v2.greater(v1)));
    try testing.expect(v2.isGreater(v1));
    try testing.expect(!@reduce(.Or, v2.greater(v2)));
    try testing.expect(!v2.isGreater(v2));
}

test "GreaterEq" {
    const v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(2.0);
    const v3 = Vector(f32, 3).from(4.0);
    try testing.expect(@reduce(.And, v2.greaterEq(v1)));
    try testing.expect(v2.isGreaterEq(v1));
    try testing.expect(@reduce(.And, v2.greaterEq(v2)));
    try testing.expect(!v2.isGreaterEq(v3));
}

test "equal" {
    const v1 = Vector(i32, 3).from(1);
    const v2 = Vector(i32, 3).from(2);
    try testing.expect(@reduce(.And, v1.equal(v1)));
    try testing.expect(v1.isEqual(v1));
    try testing.expect(!@reduce(.Or, v1.equal(v2)));
    try testing.expect(!v1.isEqual(v2));
}

test "Approximate" {
    const v1 = Vector(f32, 3).from(1.0);
    const v2 = Vector(f32, 3).from(1.000_000_1);
    try testing.expect(@reduce(.And, v1.approximate(v2, 0.000_001)));
    try testing.expect(!@reduce(.Or, v1.approximate(v2, 0.000_000_1)));
    try testing.expect(@reduce(.And, v1.approximate(v2, 0.000_000_2)));
    try testing.expect(v1.isApproximate(v2, 0.000_000_2));
    try testing.expect(!v1.isApproximate(v2, 0.000_000_1));

    const v3 = Vector(i64, 3).from(1);
    const v4 = Vector(i64, 3).from(2);
    try testing.expect(@reduce(.And, v3.approximate(v3, 0)));
    try testing.expect(v3.isApproximate(v3, 0));
    try testing.expect(!@reduce(.Or, v3.approximate(v4, 0)));
    try testing.expect(!v3.isApproximate(v4, 0));
    try testing.expect(@reduce(.And, v3.approximate(v4, 1)));
    try testing.expect(v3.isApproximate(v4, 1));
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
    try testing.expectEqual(Vector(f32, 3).from(.{ 0.0, 0.0, 1.0 }).data, Vector(f32, 3).cross(.{ v1, v2 }).data);

    const v3 = Vector(i64, 3).from(.{ 1, 0, 0 });
    const v4 = Vector(i64, 3).from(.{ 0, 1, 0 });
    try testing.expectEqual(Vector(i64, 3).from(.{ 0, 0, 1 }).data, Vector(i64, 3).cross(.{ v3, v4 }).data);
}

test "Content" {
    const v1 = Vector(f32, 3).from(.{ 1.5, 2.5, 3.5 });
    const v2 = Vector(f32, 3).from(.{ 3.5, 4.5, 5.5 });
    try testing.expectEqual(8.0, v1.content(f32, v2));

    const v3 = Vector(i32, 2).from(.{ 1, 4 });
    const v4 = Vector(i32, 2).from(.{ 3, 6 });
    try testing.expectEqual(4, v3.content(i16, v4));
    try testing.expectEqual(4, v3.content(i64, v4));
}

test "Contained" {
    {
        const v_min = Vector(f32, 2).from(.{ 1.0, 1.0 });
        const v_max = Vector(f32, 2).from(.{ 3.0, 3.0 });

        // Point strictly inside - should pass all bounds
        const v_inside = Vector(f32, 2).from(.{ 2.0, 2.0 });
        try testing.expect(v_inside.contained(v_min, v_max, "[]"));
        try testing.expect(v_inside.contained(v_min, v_max, "[)"));
        try testing.expect(v_inside.contained(v_min, v_max, "(]"));
        try testing.expect(v_inside.contained(v_min, v_max, "()"));

        // Point on min boundary
        const v_on_min = Vector(f32, 2).from(.{ 1.0, 2.0 });
        try testing.expect(v_on_min.contained(v_min, v_max, "[]"));
        try testing.expect(v_on_min.contained(v_min, v_max, "[)"));
        try testing.expect(!v_on_min.contained(v_min, v_max, "(]"));
        try testing.expect(!v_on_min.contained(v_min, v_max, "()"));

        // Point on max boundary
        const v_on_max = Vector(f32, 2).from(.{ 2.0, 3.0 });
        try testing.expect(v_on_max.contained(v_min, v_max, "[]"));
        try testing.expect(!v_on_max.contained(v_min, v_max, "[)"));
        try testing.expect(v_on_max.contained(v_min, v_max, "(]"));
        try testing.expect(!v_on_max.contained(v_min, v_max, "()"));

        // Point outside (below min)
        const v_below = Vector(f32, 2).from(.{ 0.5, 2.0 });
        try testing.expect(!v_below.contained(v_min, v_max, "[]"));

        // Point outside (above max)
        const v_above = Vector(f32, 2).from(.{ 2.0, 3.5 });
        try testing.expect(!v_above.contained(v_min, v_max, "[]"));

        // Corner order independence - reversed corners
        try testing.expect(v_inside.contained(v_max, v_min, "[]"));

        // Mixed corner order (different components swapped)
        const v_mixed1 = Vector(f32, 2).from(.{ 1.0, 3.0 });
        const v_mixed2 = Vector(f32, 2).from(.{ 3.0, 1.0 });
        try testing.expect(v_inside.contained(v_mixed1, v_mixed2, "[]"));
    }

    {
        const v_min = Vector(i32, 2).from(.{ 1, 1 });
        const v_max = Vector(i32, 2).from(.{ 3, 3 });

        // Point strictly inside - should pass all bounds
        const v_inside = Vector(i32, 2).from(.{ 2, 2 });
        try testing.expect(v_inside.contained(v_min, v_max, "[]"));
        try testing.expect(v_inside.contained(v_min, v_max, "[)"));
        try testing.expect(v_inside.contained(v_min, v_max, "(]"));
        try testing.expect(v_inside.contained(v_min, v_max, "()"));

        // Point on min boundary
        const v_on_min = Vector(i32, 2).from(.{ 1, 2 });
        try testing.expect(v_on_min.contained(v_min, v_max, "[]"));
        try testing.expect(v_on_min.contained(v_min, v_max, "[)"));
        try testing.expect(!v_on_min.contained(v_min, v_max, "(]"));
        try testing.expect(!v_on_min.contained(v_min, v_max, "()"));

        // Point on max boundary
        const v_on_max = Vector(i32, 2).from(.{ 2, 3 });
        try testing.expect(v_on_max.contained(v_min, v_max, "[]"));
        try testing.expect(!v_on_max.contained(v_min, v_max, "[)"));
        try testing.expect(v_on_max.contained(v_min, v_max, "(]"));
        try testing.expect(!v_on_max.contained(v_min, v_max, "()"));

        // Point outside (below min)
        const v_below = Vector(i32, 2).from(.{ 0, 2 });
        try testing.expect(!v_below.contained(v_min, v_max, "[]"));

        // Point outside (above max)
        const v_above = Vector(i32, 2).from(.{ 2, 4 });
        try testing.expect(!v_above.contained(v_min, v_max, "[]"));

        // Corner order independence - reversed corners
        try testing.expect(v_inside.contained(v_max, v_min, "[]"));

        // Mixed corner order (different components swapped)
        const v_mixed1 = Vector(i32, 2).from(.{ 1, 3 });
        const v_mixed2 = Vector(i32, 2).from(.{ 3, 1 });
        try testing.expect(v_inside.contained(v_mixed1, v_mixed2, "[]"));
    }
}

test "Length" {
    const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    try testing.expectEqual(3.0, v1.length());
    try testing.expectEqual(9.0, v1.lengthSq());

    const v2 = Vector(i64, 3).from(.{ 1, 2, 2 });
    try testing.expectEqual(3.0, v2.length());
    try testing.expectEqual(9, v2.lengthSq());
}

test "Normalize" {
    var v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0 / 3.0, 2.0 / 3.0, 2.0 / 3.0 }).data, v1.normalized().data);
    _ = v1.normalize();
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0 / 3.0, 2.0 / 3.0, 2.0 / 3.0 }).data, v1.data);

    var v2 = Vector(i64, 3).from(.{ 1, 2, 2 });
    const t1 = .{ @as(i64, @intFromFloat(@round(1.0 / 3.0))), @as(i64, @intFromFloat(@round(2.0 / 3.0))), @as(i64, @intFromFloat(@round(2.0 / 3.0))) };
    try testing.expectEqual(Vector(i64, 3).from(t1).data, v2.normalized().data);
    _ = v2.normalize();
    try testing.expectEqual(Vector(i64, 3).from(t1).data, v2.data);
}

test "Sign" {
    // SignZ
    var v1 = Vector(f32, 3).from(.{ 1.0, -2.0, 0.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, -1.0, 0.0 }).data, v1.signedZ().data);
    _ = v1.signZ();
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, -1.0, 0.0 }).data, v1.data);

    var v2 = Vector(i64, 3).from(.{ 1, -2, 0 });
    try testing.expectEqual(Vector(i64, 3).from(.{ 1, -1, 0 }).data, v2.signedZ().data);
    _ = v2.signZ();
    try testing.expectEqual(Vector(i64, 3).from(.{ 1, -1, 0 }).data, v2.data);

    // Sign
    var v3 = Vector(f32, 3).from(.{ 1.0, -2.0, 0.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, -1.0, 1.0 }).data, v3.signed().data);
    _ = v3.sign();
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, -1.0, 1.0 }).data, v3.data);

    var v4 = Vector(i64, 3).from(.{ 1, -2, 0 });
    try testing.expectEqual(Vector(i64, 3).from(.{ 1, -1, 1 }).data, v4.signed().data);
    _ = v4.sign();
    try testing.expectEqual(Vector(i64, 3).from(.{ 1, -1, 1 }).data, v4.data);

    // Absolute
    var v5 = Vector(f32, 3).from(.{ 1.0, -2.0, 0.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 0.0 }).data, v5.absoluted().data);
    _ = v5.absolute();
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 0.0 }).data, v5.data);

    var v6 = Vector(i64, 3).from(.{ 1, -2, 0 });
    try testing.expectEqual(Vector(i64, 3).from(.{ 1, 2, 0 }).data, v6.absoluted().data);
    _ = v6.absolute();
    try testing.expectEqual(Vector(i64, 3).from(.{ 1, 2, 0 }).data, v6.data);
}

test "Direction" {
    const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    const v2 = Vector(f32, 3).from(.{ 2.0, 4.0, 4.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 3.3333334e-1, 6.666667e-1, 6.666667e-1 }).data, v1.directionTo(v2).data);

    const v3 = Vector(i64, 3).from(.{ 1, 2, 2 });
    const v4 = Vector(i64, 3).from(.{ 2, 4, 4 });
    try testing.expectEqual(Vector(i64, 3).from(.{ 0, 1, 1 }).data, v3.directionTo(v4).data);
}

test "Distance" {
    const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    const v2 = Vector(f32, 3).from(.{ 2.0, 4.0, 4.0 });
    try testing.expectEqual(3.0, v1.distanceTo(v2));
    try testing.expectEqual(9.0, v1.distanceToSq(v2));
    try testing.expectEqual(5.0, v1.manhattanTo(v2));

    const v3 = Vector(i64, 3).from(.{ 1, 2, 2 });
    const v4 = Vector(i64, 3).from(.{ 2, 4, 4 });
    try testing.expectEqual(3.0, v3.distanceTo(v4));
    try testing.expectEqual(9, v3.distanceToSq(v4));
    try testing.expectEqual(5, v3.manhattanTo(v4));
}

test "Interpolation" {
    var v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    const v2 = Vector(f32, 3).from(.{ 2.0, 4.0, 4.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.5, 3.0, 3.0 }).data, v1.interpolated(v2, 0.5).data);
    _ = v1.interpolate(v2, 0.5);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.5, 3.0, 3.0 }).data, v1.data);

    var v3 = Vector(i64, 3).from(.{ 1, 2, 2 });
    const v4 = Vector(i64, 3).from(.{ 3, 7, 7 });
    try testing.expectEqual(Vector(i64, 3).from(.{ 5, 12, 12 }).data, v3.interpolated(v4, 2.0).data);
    try testing.expectEqual(Vector(i64, 3).from(.{ -3, -8, -8 }).data, v3.interpolated(v4, -2.0).data);
}

test "Minimum" {
    var v1 = Vector(f32, 3).from(.{ 2.0, 3.0, 4.0 });
    const v2 = Vector(f32, 3).from(.{ 1.0, 4.0, 6.0 });
    try testing.expectEqual(2.0, v1.minimum());

    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 3.0, 4.0 }).data, v1.minimumOfed(v2).data);
    _ = v1.minimumOf(v2);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 3.0, 4.0 }).data, v1.data);

    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 1.0, 1.0 }).data, v1.minimized().data);
    _ = v1.minimize();
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 1.0, 1.0 }).data, v1.data);
}

test "Maximum" {
    var v1 = Vector(f32, 3).from(.{ 2.0, 3.0, 4.0 });
    const v2 = Vector(f32, 3).from(.{ 1.0, 4.0, 6.0 });
    try testing.expectEqual(4.0, v1.maximum());

    try testing.expectEqual(Vector(f32, 3).from(.{ 2.0, 4.0, 6.0 }).data, v1.maximumOfed(v2).data);
    _ = v1.maximumOf(v2);
    try testing.expectEqual(Vector(f32, 3).from(.{ 2.0, 4.0, 6.0 }).data, v1.data);

    try testing.expectEqual(Vector(f32, 3).from(.{ 6.0, 6.0, 6.0 }).data, v1.maximized().data);
    _ = v1.maximize();
    try testing.expectEqual(Vector(f32, 3).from(.{ 6.0, 6.0, 6.0 }).data, v1.data);
}

test "Inverted, Negated" {
    var v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 0.5, 0.5 }).data, v1.inversed().data);
    _ = v1.inverse();
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 0.5, 0.5 }).data, v1.data);
    try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, -0.5, -0.5 }).data, v1.negated().data);
    _ = v1.negate();
    try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, -0.5, -0.5 }).data, v1.data);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 }).data, v1.negInversed().data);
    _ = v1.negInverse();
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 }).data, v1.data);

    var v2 = Vector(i64, 3).from(.{ 1, 2, 2 });
    try testing.expectEqual(Vector(i64, 3).from(.{ -1, -2, -2 }).data, v2.negated().data);
}

test "Clamping" {
    var v1 = Vector(f32, 3).from(.{ 0.0, 2.0, 4.0 });
    const minf: f32 = 1.5;
    const maxf: f32 = 3.5;
    const mini: i32 = 1;
    const maxi: i32 = 3;

    try testing.expectEqual(Vector(f32, 3).from(.{ 1.5, 2.0, 3.5 }).data, v1.clamped(minf, maxf).data);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }).data, v1.clamped(mini, maxi).data);

    var v2 = Vector(i64, 3).from(.{ 1, 2, 4 });
    try testing.expectEqual(Vector(i64, 3).from(.{ 1, 2, 3 }).data, v2.clamped(minf, maxf).data);
    try testing.expectEqual(Vector(i64, 3).from(.{ 1, 2, 3 }).data, v2.clamped(mini, maxi).data);
}

test "Projection" {
    var v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 2.0 });
    const v2 = Vector(f32, 3).from(.{ 4.0, 2.0, 2.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 2.0, 1.0, 1.0 }).data, v1.projected(v2.normalized()).data);
    _ = v1.project(v2.normalized());
    try testing.expectEqual(Vector(f32, 3).from(.{ 2.0, 1.0, 1.0 }).data, v1.data);
}

test "Min/Max Axis Index" {
    const v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 0.5 });
    try testing.expectEqual(2, v1.minAxisIndex());
    try testing.expectEqual(1, v1.maxAxisIndex());

    const v2 = Vector(i64, 4).from(.{ 3, 1, 4, 2 });
    try testing.expectEqual(1, v2.minAxisIndex());
    try testing.expectEqual(2, v2.maxAxisIndex());
}

test "Clamp Length" {
    var v1 = Vector(f32, 3).from(.{ -2.0, 0.0, 0.0 });
    var v2 = Vector(f32, 3).from(.{ 0.5, 0.0, 0.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, 0.0, 0.0 }).data, v1.clampedLength(0.0, 1.0).data);
    _ = v1.clampLength(0.0, 1.0);
    try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, 0.0, 0.0 }).data, v1.data);
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 0.0, 0.0 }).data, v2.clampedLength(1.0, std.math.inf(f32)).data);
    _ = v2.clampLength(1.0, std.math.inf(f32));
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 0.0, 0.0 }).data, v2.data);
}

test "Rejection" {
    {
        var v1 = Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 });
        const normal = Vector(f32, 3).from(.{ 0.0, 1.0, 0.0 });
        try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 0.0, 3.0 }).data, v1.rejected(normal).data);
        _ = v1.reject(normal);
        try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 0.0, 3.0 }).data, v1.data);
    }

    {
        var v2 = Vector(i32, 3).from(.{ 1, 2, 3 });
        const normal = Vector(i32, 3).from(.{ 0, 1, 0 });
        try testing.expectEqual(Vector(i32, 3).from(.{ 1, 0, 3 }).data, v2.rejected(normal).data);
        _ = v2.reject(normal);
        try testing.expectEqual(Vector(i32, 3).from(.{ 1, 0, 3 }).data, v2.data);
    }
}

test "Bounce" {
    {
        var v1 = Vector(f32, 3).from(.{ 1.0, -2.0, 3.0 });
        const normal = Vector(f32, 3).from(.{ 0.0, 1.0, 0.0 });
        try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }).data, v1.bounced(normal).data);
        _ = v1.bounce(normal);
        try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }).data, v1.data);
    }

    {
        var v2 = Vector(i32, 3).from(.{ 1, -2, 3 });
        const normal = Vector(i32, 3).from(.{ 0, 1, 0 });
        try testing.expectEqual(Vector(i32, 3).from(.{ 1, 2, 3 }).data, v2.bounced(normal).data);
        _ = v2.bounce(normal);
        try testing.expectEqual(Vector(i32, 3).from(.{ 1, 2, 3 }).data, v2.data);
    }
}

test "Reflect" {
    {
        var v1 = Vector(f32, 3).from(.{ 1.0, -2.0, 3.0 });
        const normal = Vector(f32, 3).from(.{ 0.0, 1.0, 0.0 });
        try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, -2.0, -3.0 }).data, v1.reflected(normal).data);
        _ = v1.reflect(normal);
        try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, -2.0, -3.0 }).data, v1.data);
    }

    {
        var v2 = Vector(i32, 3).from(.{ 1, -2, 3 });
        const normal = Vector(i32, 3).from(.{ 0, 1, 0 });
        try testing.expectEqual(Vector(i32, 3).from(.{ -1, -2, -3 }).data, v2.reflected(normal).data);
        _ = v2.reflect(normal);
        try testing.expectEqual(Vector(i32, 3).from(.{ -1, -2, -3 }).data, v2.data);
    }
}

test "Ceil" {
    var v1 = Vector(f32, 3).from(.{ 1.2, 2.5, 3.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 2.0, 3.0, 3.0 }).data, v1.ceiled().data);
    _ = v1.ceil();
    try testing.expectEqual(Vector(f32, 3).from(.{ 2.0, 3.0, 3.0 }).data, v1.data);

    var v2 = Vector(f32, 3).from(.{ -1.2, -2.5, -3.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, -2.0, -3.0 }).data, v2.ceiled().data);
    _ = v2.ceil();
    try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, -2.0, -3.0 }).data, v2.data);
}

test "Floor" {
    var v1 = Vector(f32, 3).from(.{ 1.2, 2.5, 3.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }).data, v1.floored().data);
    _ = v1.floor();
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 2.0, 3.0 }).data, v1.data);

    var v2 = Vector(f32, 3).from(.{ -1.2, -2.5, -3.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ -2.0, -3.0, -3.0 }).data, v2.floored().data);
    _ = v2.floor();
    try testing.expectEqual(Vector(f32, 3).from(.{ -2.0, -3.0, -3.0 }).data, v2.data);
}

test "Round" {
    var v1 = Vector(f32, 3).from(.{ 1.2, 2.5, 3.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 3.0, 3.0 }).data, v1.rounded().data);
    _ = v1.round();
    try testing.expectEqual(Vector(f32, 3).from(.{ 1.0, 3.0, 3.0 }).data, v1.data);

    var v2 = Vector(f32, 3).from(.{ -1.2, -2.5, -3.0 });
    try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, -3.0, -3.0 }).data, v2.rounded().data);
    _ = v2.round();
    try testing.expectEqual(Vector(f32, 3).from(.{ -1.0, -3.0, -3.0 }).data, v2.data);
}

test "Snap" {
    {
        var v1 = Vector(f32, 5).from(.{ 1.3, 2.7, 3.5, 5.0, 0.0 });
        const grid_pos = Vector(f32, 5).from(.{ 1.0, 0.5, 2.0, 0.0, 2.0 });
        const grid_neg = Vector(f32, 5).from(.{ -1.0, -0.5, -2.0, 0.0, -2.0 });
        try testing.expectEqual(Vector(f32, 5).from(.{ 1.0, 2.5, 4.0, 5.0, 0.0 }).data, v1.snapped(grid_pos).data);
        _ = v1.snap(grid_pos);
        try testing.expectEqual(Vector(f32, 5).from(.{ 1.0, 2.5, 4.0, 5.0, 0.0 }).data, v1.data);

        var v2 = Vector(f32, 5).from(.{ -1.3, -2.7, -3.5, -5.0, 0.0 });
        try testing.expectEqual(Vector(f32, 5).from(.{ -1.0, -2.5, -4.0, -5.0, 0.0 }).data, v2.snapped(grid_pos).data);
        _ = v2.snap(grid_pos);
        try testing.expectEqual(Vector(f32, 5).from(.{ -1.0, -2.5, -4.0, -5.0, 0.0 }).data, v2.data);

        try testing.expectEqual(Vector(f32, 5).from(.{ 1.0, 2.5, 4.0, 5.0, 0.0 }).data, v1.snapped(grid_neg).data);
        _ = v1.snap(grid_neg);
        try testing.expectEqual(Vector(f32, 5).from(.{ 1.0, 2.5, 4.0, 5.0, 0.0 }), v1);

        try testing.expectEqual(Vector(f32, 5).from(.{ -1.0, -2.5, -4.0, -5.0, 0.0 }).data, v2.snapped(grid_neg).data);
        _ = v2.snap(grid_neg);
        try testing.expectEqual(Vector(f32, 5).from(.{ -1.0, -2.5, -4.0, -5.0, 0.0 }).data, v2.data);
    }

    {
        var v1 = Vector(i64, 5).from(.{ 3, 7, 10, 5, 0 });
        const grid_i_pos = Vector(i64, 5).from(.{ 2, 3, 4, 0, 2 });
        const grid_i_neg = Vector(i64, 5).from(.{ -2, -3, -4, 0, -2 });

        try testing.expectEqual(Vector(i64, 5).from(.{ 4, 6, 12, 5, 0 }).data, v1.snapped(grid_i_pos).data);
        _ = v1.snap(grid_i_pos);
        try testing.expectEqual(Vector(i64, 5).from(.{ 4, 6, 12, 5, 0 }).data, v1.data);

        var v2 = Vector(i64, 5).from(.{ -3, -7, -10, -5, 0 });
        try testing.expectEqual(Vector(i64, 5).from(.{ -4, -6, -12, -5, 0 }).data, v2.snapped(grid_i_pos).data);
        _ = v2.snap(grid_i_pos);
        try testing.expectEqual(Vector(i64, 5).from(.{ -4, -6, -12, -5, 0 }).data, v2.data);

        try testing.expectEqual(Vector(i64, 5).from(.{ 4, 6, 12, 5, 0 }).data, v1.snapped(grid_i_neg).data);
        _ = v1.snap(grid_i_neg);
        try testing.expectEqual(Vector(i64, 5).from(.{ 4, 6, 12, 5, 0 }).data, v1.data);

        try testing.expectEqual(Vector(i64, 5).from(.{ -4, -6, -12, -5, 0 }).data, v2.snapped(grid_i_neg).data);
        _ = v2.snap(grid_i_neg);
    }
}

test "Move Toward" {
    var v1 = Vector(f32, 2).from(.{ 1.0, 0.0 });
    const v2 = Vector(f32, 2).from(.{ 4.0, 0.0 });
    try testing.expectEqual(Vector(f32, 2).from(.{ 1.5, 0.0 }).data, v1.movedToward(v2, 0.5).data);
    _ = v1.moveToward(v2, 0.5);
    try testing.expectEqual(Vector(f32, 2).from(.{ 1.5, 0.0 }).data, v1.data);

    var v3 = Vector(i64, 2).from(.{ 1, 0 });
    const v4 = Vector(i64, 2).from(.{ 4, 0 });
    try testing.expectEqual(Vector(i64, 2).from(.{ 3, 0 }).data, v3.movedToward(v4, 2.0).data);
    _ = v3.moveToward(v4, 2.0);
    try testing.expectEqual(Vector(i64, 2).from(.{ 3, 0 }).data, v3.data);
}

test "Formatting" {
    const v1 = Vector(f32, 3).from(.{ 1.2, 2.0, 0.25 });
    var buf: [64]u8 = undefined;
    const fmt = try std.fmt.bufPrint(&buf, "{f}", .{v1});
    try testing.expect(std.mem.eql(u8, "Vector3(1.2, 2, 0.25)", fmt));
}

test "Testfunc" {
    const vec3 = Vector(f32, 3).from(1.0);
    const vec2 = Vector(i32, 2).from(2);
    // const vec4 = Vector(i8, 4).from(3);
    vec3.float.temp();
    vec2.float.temp();
    // vec4.testfunc();
}

const std = @import("std");
const testing = std.testing;

const toBytes = std.mem.toBytes;
const bytesToValue = std.mem.bytesToValue;
