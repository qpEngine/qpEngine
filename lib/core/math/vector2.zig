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
const Vector = @import("vector.zig").Vector;
const toBytes = std.mem.toBytes;
const bytesToValue = std.mem.bytesToValue;

pub const Component = enum(i32) { x = 0, y };

/// Creates a Vector2 type with element type T
pub fn Vector2(comptime T: type) type {
    const baseType: type = Vector(T, 2);

    return extern union {
        coord: [2]T,
        comp: extern struct {
            x: T,
            y: T,
        },
        size: extern struct {
            width: T,
            height: T,
        },

        const Self = @This();
        const Alt = Vector2(f32);
        const R = f32;
        const V = @Vector(2, T);
        const B = @Vector(2, bool);
        const isInt: bool = @typeInfo(T) == .int;

        inline fn scalar(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) R else T;
        }

        inline fn compare(comptime I: type) type {
            const info = @typeInfo(I);
            return if (info == .int or info == .comptime_int) comptime_int else comptime_float;
        }

        /// Default initialization
        /// Vector2 components are set to undefined
        ///
        /// < Self: A new Vector2
        pub inline fn init() Self {
            return .{ .coord = undefined };
        }

        /// Comprehensive initialization
        /// Vector2 components are set based on provided value
        ///
        /// > value: anytype
        ///     Value to set components with
        ///
        /// < Vector2(T): A new Vector2
        pub inline fn from(value_: anytype) Self {
            return switch (@TypeOf(value_)) {
                Self => value_,
                baseType, V => base: {
                    const bytes = toBytes(value_);
                    break :base bytesToValue(Self, &bytes);
                },
                else => vector: {
                    const bytes = toBytes(baseType.vectorFromAny(value_, 0));
                    break :vector bytesToValue(Self, &bytes);
                },
            };
        }

        /// Cast Vector2 to its base Vector type
        ///
        /// < *Vector(T, 2): Pointer to the base Vector type
        pub inline fn base(self: *const Self) *baseType {
            return @as(*baseType, @ptrCast(@constCast(self)));
        }

        /// Convert Vector2 to its base Vector type
        ///
        /// < Vector(T, 2): The base Vector type
        pub inline fn to(self: Self) baseType {
            const bytes = toBytes(self);
            return bytesToValue(baseType, &bytes);
        }

        /// Case Vector2 to SIMD vector
        ///
        /// < @Vector(2, T): SIMD vector
        pub inline fn simd(self: *const Self) V {
            return self.base().data;
        }

        /// Remove const from Vector2 pointer
        ///
        /// < *Self: Mutable Vector2
        pub inline fn ptr(self: *const Self) *Self {
            return @constCast(self);
        }

        /// Create a copy of the current Vector2
        ///
        /// < Self: A new Vector2
        pub inline fn clone(self: *const Self) Self {
            return .{ .coord = self.coord };
        }

        /// Convert any type to SIMD Vector of type T and size 2
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
        pub inline fn vectorFromAny(value_: anytype, fill_: compare(T)) V {
            return baseType.vectorFromAny(value_, fill_);
        }

        /// Initialize Vector2 with component set to 1, others to 0
        ///
        /// > component: enum
        ///     Component to set to 1
        ///
        /// < Self: New positive unit Vector2
        pub inline fn unitP(component_: Component) Self {
            return Self.from(baseType.unitP(@intFromEnum(component_)));
        }

        /// Initialize Vector2 with component set to -1, others to 0
        ///
        /// > component: enum
        ///     Component to set to -1
        ///
        /// < Self: New positive unit Vector2
        pub inline fn unitN(component_: Component) Self {
            return Self.from(baseType.unitN(@intFromEnum(component_)));
        }

        /// Update Vector2 with Summation of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to sum with
        ///
        /// < *Self: Updated Current Vector2
        pub inline fn summate(self: *Self, other_: anytype) *Self {
            _ = self.base().summate(other_);
            return self;
        }

        /// New Vector2 is Summation of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to sum with
        ///
        /// < Self: Sum Vector2
        pub inline fn summated(self: *const Self, other_: anytype) Self {
            return self.clone().ptr().summate(other_).*;
        }

        /// Update Vector2 with Difference of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to subtract
        ///
        /// < *Self: Updated Current Vector2
        pub inline fn subtract(self: *Self, other_: anytype) *Self {
            _ = self.base().subtract(other_);
            return self;
        }

        /// New Vector2 is Difference of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to subtract
        ///
        /// < Self: Difference Vector2
        pub inline fn subtracted(self: *const Self, other_: anytype) Self {
            return self.clone().ptr().subtract(other_).*;
        }

        /// Update Vector2 with Product of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to multiply with
        ///
        /// < *Self: Updated Current Vector2
        pub inline fn multiply(self: *Self, other_: anytype) *Self {
            _ = self.base().multiply(other_);
            return self;
        }

        /// New Vector2 is Product of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to multiply with
        ///
        /// < Self: Product Vector2
        pub inline fn multiplied(self: *const Self, other_: anytype) Self {
            return self.clone().ptr().multiply(other_).*;
        }

        /// Update Vector2 with Quotient of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to divide by
        ///
        /// < *Self: Updated Current Vector2
        pub inline fn divide(self: *Self, other_: anytype) *Self {
            _ = self.base().divide(other_);
            return self;
        }

        /// New Vector2 is Quotient of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to divide by
        ///
        /// < Self: Quotient Vector2
        pub inline fn divided(self: *const Self, other_: anytype) Self {
            return self.clone().ptr().divide(other_).*;
        }

        /// Update Vector2 with Modulus of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to divide by
        ///
        /// < *Self: Updated Current Vector2
        pub inline fn modulo(self: *Self, other_: anytype) *Self {
            _ = self.base().modulo(other_);
            return self;
        }

        /// New Vector2 is Modulus of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to divide by
        ///
        /// < Self: Modulus Vector2
        pub inline fn moduloed(self: *const Self, other_: anytype) Self {
            return self.clone().ptr().modulo(other_).*;
        }

        /// Update Vector2 with Remainder from division of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to divide
        ///
        /// < *Self: Updated Current Vector2
        pub inline fn remainder(self: *Self, other_: anytype) *Self {
            _ = self.base().remainder(other_);
            return self;
        }

        /// New Vector2 is Remainder from division of vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to divide
        ///
        /// < Self: Remainder Vector2
        pub inline fn remaindered(self: *const Self, other_: anytype) Self {
            return self.clone().ptr().remainder(other_).*;
        }

        /// Comparison SIMD Vector of less than for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < SIMD Vector(N, bool): Comparison SIMD Vector
        pub inline fn lesser(self: *const Self, other_: anytype) B {
            return self.base().lesser(other_);
        }

        /// Comparison scalar of less than for vectors by components
        /// True if all components of current are lesser than other
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < bool: Comparison scalar
        pub inline fn isLesser(self: *const Self, other_: anytype) bool {
            return self.base().isLesser(other_);
        }

        /// Comparison SIMD Vector of less than or equal for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < SIMD Vector(N, bool): Comparison SIMD Vector
        pub inline fn lesserEq(self: *const Self, other_: anytype) B {
            return self.base().lesserEq(other_);
        }

        /// Comparison scalar of less than or equal for vectors by components
        /// True if all components of current are lesser than or equal to other
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < bool: Comparison scalar
        pub inline fn isLesserEq(self: *const Self, other_: anytype) bool {
            return self.base().isLesserEq(other_);
        }

        /// Comparison SIMD Vector of greater than for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < SIMD Vector(N, bool): Comparison SIMD Vector
        pub inline fn greater(self: *const Self, other_: anytype) B {
            return self.base().greater(other_);
        }

        /// Comparison scalar of greater than for vectors by components
        /// True if all components of current are greater than other
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < bool: Comparison scalar
        pub inline fn isGreater(self: *const Self, other_: anytype) bool {
            return self.base().isGreater(other_);
        }

        /// Comparison SIMD Vector of greater than or equal for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < SIMD Vector(N, bool): Comparison SIMD Vector
        pub inline fn greaterEq(self: *const Self, other_: anytype) B {
            return self.base().greaterEq(other_);
        }

        /// Comparison scalar of greater than or equal for vectors by components
        /// True if all components of current are greater than or equal to other
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < bool: Comparison scalar
        pub inline fn isGreaterEq(self: *const Self, other_: anytype) bool {
            return self.base().isGreaterEq(other_);
        }

        /// Comparison SIMD Vector of equality for vectors by components
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < SIMD Vector(N, bool): Comparison SIMD Vector
        pub inline fn equal(self: *const Self, other_: anytype) B {
            return self.base().equal(other_);
        }

        /// Comparison scalar of equality for vectors by components
        /// True if all components of current are equal to other
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < bool: Comparison scalar
        pub inline fn isEqual(self: *const Self, other_: anytype) bool {
            return self.base().isEqual(other_);
        }

        /// Comparison SIMD Vectors of approximation for vectors by components with tolerance
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///    Vector2 to compare
        ///
        /// > tolerance: ?T
        ///    Tolerance value for comparison
        ///    default: 0 | floatEps(T)
        ///
        /// < SIMD Vector(N, bool): Comparison SIMD Vector
        pub inline fn approximate(self: *const Self, other_: anytype) B {
            return self.base().approximate(other_);
        }

        /// Comparison scalar of approximation for vectors by components with tolerance
        /// True if all components of current are approximately equal to other
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// > tolerance: ?T
        ///     Tolerance value for comparison
        ///     default: 0 | floatEps(T)
        ///
        /// < bool: Comparison scalar
        pub inline fn isApproximate(self: *const Self, other_: anytype) bool {
            return self.base().isApproximate(other_);
        }

        /// Compute inner dot product (inner) of vectors
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compute dot product with
        ///
        /// < T: Dot product scalar
        pub inline fn inner(self: *const Self, other_: anytype) T {
            return self.base().inner(other_);
        }

        /// Compute the outer dot product (results in a matrix) of vectors
        /// This returns a flat array in row-major order
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///    Vector2 to compute outer product with
        ///
        /// < [N * N]T: Outer product matrix array
        pub inline fn outer1d(self: *const Self, other_: anytype) [4]T {
            return self.base().outer1d(other_);
        }

        /// Compute the outer product (results in a matrix) of vectors
        /// This returns a 2d array in row-major order
        /// Other vector converterd from anytype
        ///
        /// > other: anytype
        ///    Vector2 to compute outer product with
        ///
        /// < [N][N]T: Outer product matrix array
        pub inline fn outer2d(self: *const Self, other_: anytype) [2][2]T {
            return self.base().outer2d(other_);
        }

        /// Compute the cross product of the current vector
        /// Uses matrix expansion to find determinants
        ///
        /// < Self: Cross product as new Vector2
        pub inline fn cross(self: Self) Self {
            return .{ .comp = .{
                .x = self.comp.y,
                .y = -self.comp.x,
            } };
        }

        /// Compute the area spanned by opposing corner Vectors
        /// Does not include content of sides bounded by other Vector2
        /// Other vectors converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 opposite corner
        ///
        /// < T: unit^2 volume scalar
        pub inline fn content(self: *const Self, comptime ResultT: type, other_: anytype) T {
            return self.base().content(ResultT, other_);
        }

        /// Compute whether Vector2 is contained within bounds defined
        /// by two corner Vectors
        /// Other vectors converterd from anytype
        ///
        /// > a: anytype
        ///    First corner Vector2
        ///
        /// > b: anytype
        ///    Second corner Vector2
        ///
        /// > bounds: []const u8
        ///     Content bounds defined by two characters from sets:
        ///     0:{ '[', '(' } and 1:{ ')', ']' }
        ///
        /// < bool: Containment boolean
        pub inline fn contained(
            self: *const Self,
            a_: anytype,
            b_: anytype,
            comptime bounds_: []const u8,
        ) bool {
            return self.base().contained(a_, b_, bounds_);
        }

        /// Compute length (magnitude) of vector
        /// returns float if vector element type is int
        ///
        /// < T | R: Length scalar
        pub inline fn length(self: *const Self) scalar(T) {
            return self.base().length();
        }

        /// Compute squared length of vector
        ///
        /// < T: Squared length scalar
        pub inline fn lengthSq(self: *const Self) T {
            return self.base().lengthSq();
        }

        /// Update Vector2 with Normalization of itself to unit length
        /// If vector length is 0, error is returned
        /// For integral type Vector2, components are rounded up or down
        ///
        /// < !*Self: Updated Current Vector
        pub inline fn normalize(self: *Self) !*Self {
            _ = try self.base().normalize();
            return self;
        }

        /// Copy of current Vector2 normalized to unit length
        /// If vector length is 0, null is returned
        /// For integral type Vector2, components are rounded up or down
        ///
        /// < Self: Normalized Vector
        pub inline fn normalized(self: *const Self) !Self {
            return self.clone().ptr().normalize().*;
        }

        /// Update Vector2 with Sign of components
        /// Sign of 0 = 0
        ///
        /// < *Self: Updated Current Vector2
        pub inline fn signZ(self: *Self) *Self {
            _ = self.base().signZ();
            return self;
        }

        /// Copy of current Vector2 with Sign of components
        /// Sign of 0 = 0
        ///
        /// < Self: Signed Vector2
        pub inline fn signZed(self: *const Self) Self {
            return self.clone().ptr().signZ().*;
        }

        /// Update Vector2 with the Sign of Components
        /// Sign of 0 = 1
        ///
        /// < *Self: Update Current Vector2
        pub inline fn sign(self: *Self) *Self {
            _ = self.base().sign();
            return self;
        }

        /// Copy of current Vector2 with the Sign of Components
        /// Sign of 0 = 1
        ///
        /// < Self: Signed Vector2
        pub inline fn signed(self: *const Self) Self {
            return self.clone().ptr().sign().*;
        }

        /// Update Vector2 with Absolute value of components
        ///
        /// < *Self: Updated Current Vector2
        pub inline fn absolute(self: *Self) *Self {
            _ = self.base().absolute();
            return self;
        }

        /// Copy of current Vector2 with Absolute value of components
        ///
        /// < Self: Absolute Vector2
        pub inline fn absoluted(self: *const Self) Self {
            return self.clone().ptr().absolute().*;
        }

        /// Compute direction vector between vectors
        /// If length of distance is zero, zero vector is returned
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to calculate direction to
        ///
        /// < Self: Direction Vector2
        pub inline fn directionTo(self: *const Self, other_: anytype) Self {
            return Self.from(self.base().directionTo(other_));
        }

        /// Calculate euclidean distance between vectors
        /// returns float if vector element type is int
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to calculate distance to
        ///
        /// < T | R: Distance scalar
        pub inline fn distanceTo(self: *const Self, other_: anytype) scalar(T) {
            return self.base().distanceTo(other_);
        }

        /// Calculate squared euclidean distance between vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to calculate distance to
        ///
        /// < T: Squared distance scalar
        pub inline fn distanceToSq(self: *const Self, other_: anytype) T {
            return self.base().distanceToSq(other_);
        }

        /// Calculate manhattan distance between vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///    Vector2 to calculate distance to
        ///
        /// < T: Manhattan distance scalar
        pub inline fn manhattanTo(self: *const Self, other_: anytype) T {
            return self.base().manhattanTo(other_);
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
        pub inline fn interpolate(self: *Self, other_: anytype, time_: f32) *Self {
            _ = self.base().interpolate(other_, time_);
            return self;
        }

        /// New Vector2 is Linear interpolates between vectors at time t
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to interpolate to
        ///
        /// > time: f32
        ///
        /// < Self: Interpolated Vector2
        pub inline fn interpolated(self: *const Self, other_: anytype, time_: f32) Self {
            return self.clone().ptr().interpolate(other_, time_).*;
        }

        /// Maximum scalar of a vector
        ///
        /// < T: Max scalar
        pub inline fn maximum(self: *const Self) T {
            return self.base().maximum();
        }

        /// Minimum scalar of a vector
        ///
        /// < T: Min scalar
        pub inline fn minimum(self: *const Self) T {
            return self.base().minimum();
        }

        /// Update Vector2 with maximum components of either vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < Self: Maximum Vector2
        pub inline fn maximumOf(self: *Self, other_: anytype) *Self {
            _ = self.base().maximumOf(other_);
            return self;
        }

        /// New Vector with maximum components of either vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector to compare
        ///
        /// < Self: Maximum Vector
        pub inline fn maximumOfed(self: *const Self, other_: anytype) Self {
            return self.clone().ptr().maximumOf(other_).*;
        }

        /// Update Vector2 with minimum components of either vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < Self: Minimum Vector2
        pub inline fn minimumOf(self: *Self, other_: anytype) *Self {
            _ = self.base().minimumOf(other_);
            return self;
        }

        /// Update Vector2 with minimum components of either vectors
        /// other vector converterd from anytype
        ///
        /// > other: anytype
        ///     Vector2 to compare
        ///
        /// < Self: Minimum Vector2
        pub inline fn minimumOfed(self: *const Self, other_: anytype) Self {
            return self.clone().ptr().minimumOf(other_).*;
        }

        /// Vector2 has all components updated to current maximum
        ///
        /// < Self: maximized Vector2
        pub inline fn maximize(self: *Self) *Self {
            _ = self.base().maximize();
            return self;
        }

        /// New Vector2 with all components updated to current maximum
        ///
        /// < Self: maximized Vector2
        pub inline fn maximized(self: *const Self) Self {
            return self.clone().ptr().maximize().*;
        }

        /// Vector2 has all components updated to current minimum
        ///
        /// < Self: minimized Vector2
        pub inline fn minimize(self: *Self) *Self {
            _ = self.base().minimize();
            return self;
        }

        /// New Vector with all components updated to current minimum
        ///
        /// < Self: minimized Vector
        pub inline fn minimized(self: *const Self) Self {
            return self.clone().ptr().minimize().*;
        }

        /// Update Vector2 with inverse for all components
        ///
        /// Not supported for integral vectors
        ///
        /// < *Self: Updated Current Vector2
        pub inline fn inverse(self: *Self) *Self {
            _ = self.base().inverse();
            return self;
        }

        /// New Vector with inverse for all components
        ///
        /// Not supported for integral vectors
        ///
        /// < Self: Inversed Vector
        pub inline fn inversed(self: *const Self) Self {
            return self.clone().ptr().inverse().*;
        }

        /// Update Vector2 with negation for all components
        ///
        /// < *Self: Updated Current Vector2
        pub inline fn negate(self: *Self) *Self {
            _ = self.base().negate();
            return self;
        }

        /// New Vector2 with negation for all components
        ///
        /// < Self: Negated Vector2
        pub inline fn negated(self: *const Self) Self {
            return self.clone().ptr().negate().*;
        }

        /// Update Vector2 with negation and inversion of all components
        ///
        /// Not supported for integral vectors
        ///
        /// < *Self: Updated Current Vector2
        pub inline fn negInverse(self: *Self) *Self {
            _ = self.base().negInverse();
            return self;
        }

        /// New Vector2 with negation and inversion of all components
        ///
        /// Not supported for integral vectors
        ///
        /// < Self: Negated and inversed Vector2
        pub inline fn negInversed(self: *const Self) Self {
            return self.clone().ptr().negInverse().*;
        }

        /// Update Vector2 with components clamped between min and max
        ///
        /// > min_: anytype
        ///     Minimum value to clamp to
        ///
        /// > max_: anytype
        ///     Maximum value to clamp to
        ///
        /// < *Self: Updated Current Vector2
        pub inline fn clamp(self: *Self, min_: anytype, max_: anytype) *Self {
            _ = self.base().clamp(min_, max_);
            return self;
        }

        /// New Vector2 with components clamped between min and max
        ///
        /// > min_: anytype
        ///     Minimum value to clamp to
        ///
        /// > max_: anytype
        ///     Maximum value to clamp to
        ///
        /// < Self: Clamped Vector2
        pub inline fn clamped(self: *const Self, min_: anytype, max_: anytype) Self {
            return self.clone().ptr().clamp(min_, max_).*;
        }

        pub inline fn project(self: *Self, other_: anytype) *Self {
            _ = self.base().project(other_);
            return self;
        }

        pub inline fn projected(self: *const Self, other_: anytype) Self {
            return self.clone().ptr().project(other_).*;
        }

        /// Vector2 to string
        ///
        /// Convert vector to formatted string
        /// Format is `Vector2({d}, ...)` where N is vector size
        ///
        /// > writer: anytype
        ///
        /// < void
        pub fn format(self: *const Self, writer_: anytype) !void {
            try self.base().format(writer_);
        }
    };
}

const testing = std.testing;

test "Initialize" {
    {
        const v1 = Vector2(f32).from(.{ 1.0, 2.0 });
        try testing.expectEqual(1.0, v1.comp.x);
        try testing.expectEqual(2.0, v1.comp.y);

        const v2 = Vector2(f32).from(0.0);
        try testing.expectEqual(0.0, v2.comp.x);
        try testing.expectEqual(0.0, v2.comp.y);

        const v3 = Vector2(f32).from(v1);
        try testing.expectEqual(1.0, v3.comp.x);
        try testing.expectEqual(2.0, v3.comp.y);

        const v4 = Vector2(f32).from(v1.base());
        try testing.expectEqual(1.0, v4.comp.x);
        try testing.expectEqual(2.0, v4.comp.y);

        const v5 = Vector2(f32).from(v1.base().*);
        try testing.expectEqual(1.0, v5.comp.x);
        try testing.expectEqual(2.0, v5.comp.y);
    }

    // unit vectors
    {
        const ux = Vector2(f32).unitP(.x);
        try testing.expectEqual(1.0, ux.comp.x);
        try testing.expectEqual(0.0, ux.comp.y);

        const uy = Vector2(f32).unitP(.y);
        try testing.expectEqual(0.0, uy.comp.x);
        try testing.expectEqual(1.0, uy.comp.y);

        const unx = Vector2(f32).unitN(.x);
        try testing.expectEqual(-1.0, unx.comp.x);
        try testing.expectEqual(0.0, unx.comp.y);

        const uny = Vector2(f32).unitN(.y);
        try testing.expectEqual(0.0, uny.comp.x);
        try testing.expectEqual(-1.0, uny.comp.y);
    }

    // clone
    {}
}

test "Summation" {
    var v1 = Vector2(f32).from(.{ 1.0, 2.0 });
    const v2 = Vector2(f32).from(.{ 3.0, 4.0 });

    const v3 = v1.summated(v2);
    try testing.expectEqual(4.0, v3.comp.x);
    try testing.expectEqual(6.0, v3.comp.y);

    _ = v1.summate(v2);
    try testing.expectEqual(4.0, v1.comp.x);
    try testing.expectEqual(6.0, v1.comp.y);
}

test "Lesser" {
    const v1 = Vector2(f32).from(.{ 1.0, 2.0 });
    const v2 = Vector2(f32).from(.{ 3.0, 4.0 });
    const v3 = Vector2(f32).from(.{ 1.0, 4.0 });

    try testing.expect(@reduce(.And, v1.lesser(v2)));
    try testing.expect(v1.isLesser(v2));
    try testing.expect(!@reduce(.And, v1.lesser(v3)));
    try testing.expect(!v1.isLesser(v3));
}

test "Dot" {
    const v1 = Vector2(f32).from(2.0);
    const v2 = Vector2(f32).from(3.0);

    try testing.expectEqual(12.0, v1.inner(v2));
    try testing.expectEqual([_]f32{6.0} ** 4, v1.outer1d(v2));
}

test "Projection" {
    var v1 = Vector2(f32).from(.{ 1.0, 2.0 });
    const v2 = Vector2(f32).from(.{ 4.0, 2.0 });

    const proj = v1.projected(v2);
    try testing.expectEqual(1.6, proj.comp.x);
    try testing.expectEqual(0.8, proj.comp.y);

    _ = v1.project(v2);
    try testing.expectEqual(1.6, v1.comp.x);
    try testing.expectEqual(0.8, v1.comp.y);
}
