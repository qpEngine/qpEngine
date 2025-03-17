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

        //  (TESTED)
        /// Summation of components using vector
        pub inline fn addV(self: Self, other: Self) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            return .{ .data = a + b };
        }

        // (TESTED)
        /// Summation of components using vector of different type
        pub inline fn addFromV(self: Self, comptime I: type, other: Vec(I, N)) Self {
            if (I == T) return self.addV(other);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, other.data).data;

            return .{ .data = a + b };
        }

        // (TESTED)
        /// Summation of components using array
        pub inline fn addA(self: Self, array: [N]T) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = array;

            return .{ .data = a + b };
        }

        // (TESTED)
        /// Summation of components using array of different type
        pub inline fn addFromA(self: Self, comptime I: type, array: [N]I) Self {
            if (I == T) return self.addA(array);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, array).data;

            return .{ .data = a + b };
        }

        // (TESTED)
        /// Summation of components using scalar
        pub inline fn addS(self: Self, scalar: T) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(scalar);

            return .{ .data = a + b };
        }

        // (TESTED)
        /// Summation of components using scalar of different type
        pub inline fn addFromS(self: Self, comptime I: type, scalar: I) Self {
            if (I == T) return self.addS(scalar);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromS(I, scalar).data;

            return .{ .data = a + b };
        }

        // (TESTED)
        /// Difference of components using vector
        pub inline fn subV(self: Self, other: Self) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            return .{ .data = a - b };
        }

        // (TESTED)
        // Difference of components using vector of different type
        pub inline fn subFromV(self: Self, comptime I: type, other: Vec(I, N)) Self {
            if (I == T) return self.addV(other);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, other.data).data;

            return .{ .data = a - b };
        }

        // (TESTED)
        /// Difference of components using array
        pub inline fn subA(self: Self, array: [N]T) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = array;

            return .{ .data = a - b };
        }

        // (TESTED)
        /// Difference of components using array of different type
        pub inline fn subFromA(self: Self, comptime I: type, array: [N]I) Self {
            if (I == T) return self.subA(array);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, array).data;

            return .{ .data = a - b };
        }

        // (TESTED)
        /// Difference of components using scalar
        pub inline fn subS(self: Self, scalar: T) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(scalar);

            return .{ .data = a - b };
        }

        // (TESTED)
        /// Difference of components using scalar of different type
        pub inline fn subFromS(self: Self, comptime I: type, scalar: I) Self {
            if (I == T) return self.subS(scalar);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromS(I, scalar).data;

            return .{ .data = a - b };
        }

        // (TESTED)
        /// Product of components using vector
        pub inline fn mulV(self: Self, other: Self) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            return .{ .data = a * b };
        }

        // (TESTED)
        /// Product of components using vector of different type
        pub inline fn mulFromV(self: Self, comptime I: type, other: Vec(I, N)) Self {
            if (I == T) return self.addV(other);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, other.data).data;

            return .{ .data = a * b };
        }

        // (TESTED)
        /// Product of components using array
        pub inline fn mulA(self: Self, array: [N]T) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = array;

            return .{ .data = a * b };
        }

        // (TESTED)
        /// Product of components using array of different type
        pub inline fn mulFromA(self: Self, comptime I: type, array: [N]I) Self {
            if (I == T) return self.mulA(array);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, array).data;

            return .{ .data = a * b };
        }

        // (TESTED)
        /// Product of components usitg scalar
        pub inline fn mulS(self: Self, scalar: T) Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(scalar);

            return .{ .data = a * b };
        }

        // (TESTED)
        /// Product of components using scalar of different type
        pub inline fn mulFromS(self: Self, comptime I: type, scalar: I) Self {
            if (I == T) return self.mulS(scalar);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromS(I, scalar).data;

            return .{ .data = a * b };
        }

        // (TESTED)
        /// Quotient of components using vector
        pub inline fn divV(self: Self, other: Self) !Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = a / b };
        }

        // (TESTED)
        /// Quotient of components using vector of different type
        pub inline fn divFromV(self: Self, comptime I: type, other: Vec(I, N)) !Self {
            if (I == T) return self.addV(other);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, other.data).data;

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = a / b };
        }

        // (TESTED)
        /// Quotient of components using array
        pub inline fn divA(self: Self, array: [N]T) !Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = array;

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = a / b };
        }

        // (TESTED)
        /// Quotient of components using array of different type
        pub inline fn divFromA(self: Self, comptime I: type, array: [N]I) !Self {
            if (I == T) return self.divA(array);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, array).data;

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = a / b };
        }

        // (TESTED)
        /// Quotient of components using scalar
        pub inline fn divS(self: Self, scalar: T) !Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(scalar);
            if (scalar == 0) return Self.initS(0);

            return .{ .data = a / b };
        }

        // (TESTED)
        /// Quotient of components using scalar of different type
        pub inline fn divFromS(self: Self, comptime I: type, scalar: I) !Self {
            if (I == T) return self.divS(scalar);
            if (scalar == 0) return Self.initS(0);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromS(I, scalar).data;

            return .{ .data = a / b };
        }

        /// Modulus of components using vector
        pub inline fn modV(self: Self, other: Self) !Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = @mod(a, b) };
        }

        /// Modulus of components using vector of different type
        pub inline fn modFromV(self: Self, comptime I: type, other: Vec(I, N)) !Self {
            if (I == T) return self.modV(other);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, other.data).data;

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = @mod(a, b) };
        }

        /// Modulus of components using array
        pub inline fn modA(self: Self, array: [N]T) !Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = array;

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = @mod(a, b) };
        }

        /// Modulus of components using array of different type
        pub inline fn modFromA(self: Self, comptime I: type, array: [N]I) !Self {
            if (I == T) return self.modA(array);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, array).data;

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return VecError.DivideByZero;

            return .{ .data = @mod(a, b) };
        }

        /// Modulus of components using scalar
        pub inline fn modS(self: Self, scalar: T) !Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(scalar);
            if (scalar == 0) return Self.initS(0);

            return .{ .data = @mod(a, b) };
        }

        /// Modulus of components using scalar of different type
        pub inline fn modFromS(self: Self, comptime I: type, scalar: I) !Self {
            if (I == T) return self.modS(scalar);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromS(I, scalar).data;
            if (scalar == 0) return Self.initS(0);

            return .{ .data = @mod(a, b) };
        }

        /// Remainder of components using vector
        pub inline fn remV(self: Self, other: Self) !Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return Self.initS(0);

            return .{ .data = @rem(a, b) };
        }

        /// Remainder of components using vector of different type
        pub inline fn remFromV(self: Self, comptime I: type, other: Vec(I, N)) !Self {
            if (I == T) return self.remV(other);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, other.data).data;

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return Self.initS(0);

            return .{ .data = @rem(a, b) };
        }

        /// Remainder of components using array
        pub inline fn remA(self: Self, array: [N]T) !Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = array;

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return Self.initS(0);

            return .{ .data = @rem(a, b) };
        }

        /// Remainder of components using array of different type
        pub inline fn remFromA(self: Self, comptime I: type, array: [N]I) !Self {
            if (I == T) return self.remA(array);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, array).data;

            const c: @Vector(N, T) = @splat(0);
            const d: @Vector(N, bool) = b == c;
            const dbz: bool = @reduce(.Or, d);
            if (dbz) return Self.initS(0);

            return .{ .data = @rem(a, b) };
        }

        /// Remainder of components using scalar
        pub inline fn remS(self: Self, scalar: T) !Self {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(scalar);
            if (scalar == 0) return Self.initS(0);

            return .{ .data = @rem(a, b) };
        }

        /// Remainder of components using scalar of different type
        pub inline fn remFromS(self: Self, comptime I: type, scalar: I) !Self {
            if (I == T) return self.remS(scalar);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromS(I, scalar).data;
            if (scalar == 0) return Self.initS(0);

            return .{ .data = @rem(a, b) };
        }

        /// Boolean result of lesser comparison of components using vector
        pub inline fn lesserV(self: Self, other: Self) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            return a < b;
        }

        /// Boolean result of lesser comparison of components using vector of different type
        pub inline fn lesserFromV(self: Self, comptime I: type, other: Vec(I, N)) @Vector(N, bool) {
            if (I == T) return self.addV(other);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, other.data).data;

            return a < b;
        }

        /// Boolean result of lesser comparison of components using array
        pub inline fn lesserA(self: Self, array: [N]T) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = array;

            return a < b;
        }

        /// Boolean result of lesser comparison of components using array of different type
        pub inline fn lesserFromA(self: Self, comptime I: type, array: [N]I) @Vector(N, bool) {
            if (I == T) return self.lesserA(array);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, array).data;

            return a < b;
        }

        /// Boolean result of lesser comparison of components using scalar
        pub inline fn lesserS(self: Self, scalar: T) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(scalar);

            return a < b;
        }

        /// Boolean result of lesser comparison of components using scalar of different type
        pub inline fn lesserFromS(self: Self, comptime I: type, scalar: I) @Vector(N, bool) {
            if (I == T) return self.lesserS(scalar);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromS(I, scalar).data;

            return a < b;
        }

        /// Boolean result of lesser or equal comparison of components using vector
        pub inline fn lesserEqV(self: Self, other: Self) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            return a <= b;
        }

        /// Boolean result of lesser or equal comparison of components using vector of different type
        pub inline fn lesserEqFromV(self: Self, comptime I: type, other: Vec(I, N)) @Vector(N, bool) {
            if (I == T) return self.lesserEqV(other);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, other.data).data;

            return a <= b;
        }

        /// Boolean result of lesser or equal comparison of components using array
        pub inline fn lesserEqA(self: Self, array: [N]T) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = array;

            return a <= b;
        }

        /// Boolean result of lesser or equal comparison of components using array of different type
        pub inline fn lesserEqFromA(self: Self, comptime I: type, array: [N]I) @Vector(N, bool) {
            if (I == T) return self.lesserEqA(array);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, array).data;

            return a <= b;
        }

        /// Boolean result of lesser or equal comparison of components using scalar
        pub inline fn lesserEqS(self: Self, scalar: T) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(scalar);

            return a <= b;
        }

        /// Boolean result of lesser or equal comparison of components using scalar of different type
        pub inline fn lesserEqFromS(self: Self, comptime I: type, scalar: I) @Vector(N, bool) {
            if (I == T) return self.lesserEqS(scalar);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromS(I, scalar).data;

            return a <= b;
        }

        /// Boolean result of greater comparison of components using vector
        pub inline fn greaterV(self: Self, other: Self) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            return a > b;
        }

        /// Boolean result of greater comparison of components using vector of different type
        pub inline fn greaterFromV(self: Self, comptime I: type, other: Vec(I, N)) @Vector(N, bool) {
            if (I == T) return self.greaterV(other);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, other.data).data;

            return a > b;
        }

        /// Boolean result of greater comparison of components using array
        pub inline fn greaterA(self: Self, array: [N]T) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = array;

            return a > b;
        }

        /// Boolean result of greater comparison of components using array of different type
        pub inline fn greaterFromA(self: Self, comptime I: type, array: [N]I) @Vector(N, bool) {
            if (I == T) return self.greaterA(array);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, array).data;

            return a > b;
        }

        /// Boolean result of greater comparison of components using scalar
        pub inline fn greaterS(self: Self, scalar: T) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(scalar);

            return a > b;
        }

        /// Boolean result of greater comparison of components using scalar of different type
        pub inline fn greaterFromS(self: Self, comptime I: type, scalar: I) @Vector(N, bool) {
            if (I == T) return self.greaterS(scalar);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromS(I, scalar).data;

            return a > b;
        }

        /// Boolean result of greater or equal comparison of components using vector
        pub inline fn greaterEqV(self: Self, other: Self) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            return a >= b;
        }

        /// Boolean result of greater or equal comparison of components using vector of different type
        pub inline fn greaterEqFromV(self: Self, comptime I: type, other: Vec(I, N)) @Vector(N, bool) {
            if (I == T) return self.greaterEqV(other);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, other.data).data;

            return a >= b;
        }

        /// Boolean result of greater or equal comparison of components using array
        pub inline fn greaterEqA(self: Self, array: [N]T) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = array;

            return a >= b;
        }

        /// Boolean result of greater or equal comparison of components using array of different type
        pub inline fn greaterEqFromA(self: Self, comptime I: type, array: [N]I) @Vector(N, bool) {
            if (I == T) return self.greaterEqA(array);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, array).data;

            return a >= b;
        }

        /// Boolean result of greater or equal comparison of components using scalar
        pub inline fn greaterEqS(self: Self, scalar: T) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(scalar);

            return a >= b;
        }

        /// Boolean result of greater or equal comparison of components using scalar of different type
        pub inline fn greaterEqFromS(self: Self, comptime I: type, scalar: I) @Vector(N, bool) {
            if (I == T) return self.greaterEqS(scalar);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromS(I, scalar).data;

            return a >= b;
        }

        /// Boolean result of equality comparison of components using vector
        pub inline fn equalV(self: Self, other: Self) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = other.data;

            return a == b;
        }

        /// Boolean result of equality comparison of components using vector of different type
        pub inline fn equalFromV(self: Self, comptime I: type, other: Vec(I, N)) @Vector(N, bool) {
            if (I == T) return self.equalV(other);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, other.data).data;

            return a == b;
        }

        /// Boolean result of equality comparison of components using array
        pub inline fn equalA(self: Self, array: [N]T) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = array;

            return a == b;
        }

        /// Boolean result of equality comparison of components using array of different type
        pub inline fn equalFromA(self: Self, comptime I: type, array: [N]I) @Vector(N, bool) {
            if (I == T) return self.equalA(array);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromA(I, array).data;

            return a == b;
        }

        /// Boolean result of equality comparison of components using scalar
        pub inline fn equalS(self: Self, scalar: T) @Vector(N, bool) {
            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = @splat(scalar);

            return a == b;
        }

        /// Boolean result of equality comparison of components using scalar of different type
        pub inline fn equalFromS(self: Self, comptime I: type, scalar: I) @Vector(N, bool) {
            if (I == T) return self.equalS(scalar);

            const a: @Vector(N, T) = self.data;
            const b: @Vector(N, T) = Self.fromS(I, scalar).data;

            return a == b;
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
                .float => self.divS(len),
                .int => Vec(f32, N).fromA(T, self.data).divS(len),
                else => @compileError("Vec element type must be numeric"),
            };
        }

        /// Calculate direction vector from self to other
        pub inline fn dirToV(self: Self, other: Self) Self {
            return other.subV(self).normalized() orelse Self.initS(0);
        }

        pub inline fn dirToFromV(self: Self, comptime I: type, other: Vec(I, N)) Self {
            return Self.initA(other.data).subV(self).normalized() orelse Self.initS(0);
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
            return other.subV(self).length2();
        }

        /// Linear interpolation between two vectors at time t
        pub inline fn lerp(self: Self, other: Self, t: T) (if (@typeInfo(T) == .float) Self else Vec(f32, N)) {
            return switch (@typeInfo(T)) {
                .float => self.mulS(1 - t).addV(other.mulS(t)),
                .int => Vec(f32, N).fromA(T, self.data).mulS(1 - t).addV(Vec(f32, N).fromA(T, other.data).mulS(t)),
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

        pub fn init(data: [2]T) Self {
            return .{ .x = data[0], .y = data[1] };
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

        pub fn init(data: [3]T) Self {
            return .{ .x = data[0], .y = data[1], .z = data[2] };
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

        pub fn init(data: [4]T) Self {
            return .{ .x = data[0], .y = data[1], .z = data[2], .w = data[3] };
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
    const v3 = v1.addV(v2);
    const v4 = v1.addA(.{ 4.0, 5.0, 6.0 });
    const v5 = v1.addS(1.0);
    try testing.expectEqual([3]f32{ 5.0, 7.0, 9.0 }, v3.data);
    try testing.expectEqual([3]f32{ 5.0, 7.0, 9.0 }, v4.data);
    try testing.expectEqual([3]f32{ 2.0, 3.0, 4.0 }, v5.data);

    // addition of same type with different size
    const v6 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v7 = v1.addFromV(f64, v6);

    const a1 = [3]f64{ 4.0, 5.0, 6.0 };
    const v8 = v1.addFromA(f64, a1);

    const s1: f64 = 1.0;
    const v9 = v1.addFromS(f64, s1);
    try testing.expectEqual([3]f32{ 5.0, 7.0, 9.0 }, v7.data);
    try testing.expectEqual([3]f32{ 5.0, 7.0, 9.0 }, v8.data);
    try testing.expectEqual([3]f32{ 2.0, 3.0, 4.0 }, v9.data);

    // Signed Integral Vector
    // standard addition of same type and size
    const v10 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v11 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    const v12 = v10.addV(v11);
    const v13 = v10.addA(.{ 4, 5, 6 });
    const v14 = v10.addS(1);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, v12.data);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, v13.data);
    try testing.expectEqual([3]i32{ 2, 3, 4 }, v14.data);

    // addition of same type with different size
    const v15 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const v16 = v10.addFromV(i64, v15);

    const a2 = [3]i64{ 4, 5, 6 };
    const v17 = v10.addFromA(i64, a2);

    const s2: i64 = 1;
    const v18 = v10.addFromS(i64, s2);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, v16.data);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, v17.data);
    try testing.expectEqual([3]i32{ 2, 3, 4 }, v18.data);

    // Both Vector types
    // addition of different type and size
    const v19 = v1.addFromV(i64, v15);
    const v20 = v10.addFromV(f64, v6);
    try testing.expectEqual([3]f32{ 5.0, 7.0, 9.0 }, v19.data);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, v20.data);

    const v21 = v1.addFromA(i64, a2);
    const v22 = v10.addFromA(f64, a1);
    try testing.expectEqual([3]f32{ 5.0, 7.0, 9.0 }, v21.data);
    try testing.expectEqual([3]i32{ 5, 7, 9 }, v22.data);

    const v23 = v1.addFromS(i64, s2);
    const v24 = v10.addFromS(f64, s1);
    try testing.expectEqual([3]f32{ 2.0, 3.0, 4.0 }, v23.data);
    try testing.expectEqual([3]i32{ 2, 3, 4 }, v24.data);
}

test "Subtraction" {
    // Floating point Vector
    // standard subtraction of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v3 = v1.subV(v2);
    const v4 = v1.subA(.{ 4.0, 5.0, 6.0 });
    const v5 = v1.subS(1.0);
    try testing.expectEqual([3]f32{ -3.0, -3.0, -3.0 }, v3.data);
    try testing.expectEqual([3]f32{ -3.0, -3.0, -3.0 }, v4.data);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v5.data);

    // subtraction of same type with different size
    const v6 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v7 = v1.subFromV(f64, v6);

    const a1 = [3]f64{ 4.0, 5.0, 6.0 };
    const v8 = v1.subFromA(f64, a1);

    const s1: f64 = 1.0;
    const v9 = v1.subFromS(f64, s1);
    try testing.expectEqual([3]f32{ -3.0, -3.0, -3.0 }, v7.data);
    try testing.expectEqual([3]f32{ -3.0, -3.0, -3.0 }, v8.data);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v9.data);

    // Signed Integral Vector
    // standard subtraction of same type and size
    const v10 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v11 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    const v12 = v10.subV(v11);
    const v13 = v10.subA(.{ 4, 5, 6 });
    const v14 = v10.subS(1);
    try testing.expectEqual([3]i32{ -3, -3, -3 }, v12.data);
    try testing.expectEqual([3]i32{ -3, -3, -3 }, v13.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v14.data);

    // subtraction of same type with different size
    const v15 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const v16 = v10.subFromV(i64, v15);

    const a2 = [3]i64{ 4, 5, 6 };
    const v17 = v10.subFromA(i64, a2);

    const s2: i64 = 1;
    const v18 = v10.subFromS(i64, s2);
    try testing.expectEqual([3]i32{ -3, -3, -3 }, v16.data);
    try testing.expectEqual([3]i32{ -3, -3, -3 }, v17.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v18.data);

    // Both Vector types
    // subtraction of different type and size
    const v19 = v1.subFromV(i64, v15);
    const v20 = v10.subFromV(f64, v6);
    try testing.expectEqual([3]f32{ -3.0, -3.0, -3.0 }, v19.data);
    try testing.expectEqual([3]i32{ -3, -3, -3 }, v20.data);

    const v21 = v1.subFromA(i64, a2);
    const v22 = v10.subFromA(f64, a1);
    try testing.expectEqual([3]f32{ -3.0, -3.0, -3.0 }, v21.data);
    try testing.expectEqual([3]i32{ -3, -3, -3 }, v22.data);

    const v23 = v1.subFromS(i64, s2);
    const v24 = v10.subFromS(f64, s1);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v23.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v24.data);
}

test "Multiplication" {
    // Floating point Vector
    // standard multiplication of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v3 = v1.mulV(v2);
    const v4 = v1.mulA(.{ 4.0, 5.0, 6.0 });
    const v5 = v1.mulS(2.0);
    try testing.expectEqual([3]f32{ 4.0, 10.0, 18.0 }, v3.data);
    try testing.expectEqual([3]f32{ 4.0, 10.0, 18.0 }, v4.data);
    try testing.expectEqual([3]f32{ 2.0, 4.0, 6.0 }, v5.data);

    // multiplication of same type with different size
    const v6 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v7 = v1.mulFromV(f64, v6);

    const a1 = [3]f64{ 4.0, 5.0, 6.0 };
    const v8 = v1.mulFromA(f64, a1);

    const s1: f64 = 2.0;
    const v9 = v1.mulFromS(f64, s1);
    try testing.expectEqual([3]f32{ 4.0, 10.0, 18.0 }, v7.data);
    try testing.expectEqual([3]f32{ 4.0, 10.0, 18.0 }, v8.data);
    try testing.expectEqual([3]f32{ 2.0, 4.0, 6.0 }, v9.data);

    // Signed Integral Vector
    // standard multiplication of same type and size
    const v10 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v11 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    const v12 = v10.mulV(v11);
    const v13 = v10.mulA(.{ 4, 5, 6 });
    const v14 = v10.mulS(2);
    try testing.expectEqual([3]i32{ 4, 10, 18 }, v12.data);
    try testing.expectEqual([3]i32{ 4, 10, 18 }, v13.data);
    try testing.expectEqual([3]i32{ 2, 4, 6 }, v14.data);

    // multiplication of same type with different size
    const v15 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const v16 = v10.mulFromV(i64, v15);

    const a2 = [3]i64{ 4, 5, 6 };
    const v17 = v10.mulFromA(i64, a2);

    const s2: i64 = 2;
    const v18 = v10.mulFromS(i64, s2);
    try testing.expectEqual([3]i32{ 4, 10, 18 }, v16.data);
    try testing.expectEqual([3]i32{ 4, 10, 18 }, v17.data);
    try testing.expectEqual([3]i32{ 2, 4, 6 }, v18.data);

    // Both Vector types
    // multiplication of different type and size
    const v19 = v1.mulFromV(i64, v15);
    const v20 = v10.mulFromV(f64, v6);
    try testing.expectEqual([3]f32{ 4.0, 10.0, 18.0 }, v19.data);
    try testing.expectEqual([3]i32{ 4, 10, 18 }, v20.data);

    const v21 = v1.mulFromA(i64, a2);
    const v22 = v10.mulFromA(f64, a1);
    try testing.expectEqual([3]f32{ 4.0, 10.0, 18.0 }, v21.data);
    try testing.expectEqual([3]i32{ 4, 10, 18 }, v22.data);

    const v23 = v1.mulFromS(i64, s2);
    const v24 = v10.mulFromS(f64, s1);
    try testing.expectEqual([3]f32{ 2.0, 4.0, 6.0 }, v23.data);
    try testing.expectEqual([3]i32{ 2, 4, 6 }, v24.data);
}

test "Division" {
    // Floating point Vector
    // standard division of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v3 = try v1.divV(v2);
    const v4 = try v1.divA(.{ 4.0, 5.0, 6.0 });
    const v5 = try v1.divS(2.0);
    try testing.expectEqual([3]f32{ 0.25, 0.4, 0.5 }, v3.data);
    try testing.expectEqual([3]f32{ 0.25, 0.4, 0.5 }, v4.data);
    try testing.expectEqual([3]f32{ 0.5, 1.0, 1.5 }, v5.data);

    // division of same type with different size
    const v6 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const v7 = try v1.divFromV(f64, v6);

    const a1 = [3]f64{ 4.0, 5.0, 6.0 };
    const v8 = try v1.divFromA(f64, a1);

    const s1: f64 = 2.0;
    const v9 = try v1.divFromS(f64, s1);
    try testing.expectEqual([3]f32{ 0.25, 0.4, 0.5 }, v7.data);
    try testing.expectEqual([3]f32{ 0.25, 0.4, 0.5 }, v8.data);
    try testing.expectEqual([3]f32{ 0.5, 1.0, 1.5 }, v9.data);

    // Signed Integral Vector
    // standard division of same type and size
    const v10 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    const v11 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v12 = try v10.divV(v11);
    const v13 = try v10.divA(.{ 1, 2, 3 });
    const v14 = try v10.divS(2);
    try testing.expectEqual([3]i32{ 4, 2, 2 }, v12.data);
    try testing.expectEqual([3]i32{ 4, 2, 2 }, v13.data);
    try testing.expectEqual([3]i32{ 2, 2, 3 }, v14.data);

    // division of same type with different size
    const v15 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const v16 = try v11.divFromV(i64, v15);

    const a2 = [3]i64{ 4, 5, 6 };
    const v17 = try v11.divFromA(i64, a2);

    const s2: i64 = 2;
    const v18 = try v11.divFromS(i64, s2);
    try testing.expectEqual([3]i32{ 0, 0, 0 }, v16.data);
    try testing.expectEqual([3]i32{ 0, 0, 0 }, v17.data);
    try testing.expectEqual([3]i32{ 0, 1, 1 }, v18.data);

    // Both Vector types
    // division of different type and size
    const v19 = try v1.divFromV(i64, v15);
    const v20 = try v11.divFromV(f64, v6);
    try testing.expectEqual([3]f32{ 0.25, 0.4, 0.5 }, v19.data);
    try testing.expectEqual([3]i32{ 0, 0, 0 }, v20.data);

    const v21 = try v1.divFromA(i64, a2);
    const v22 = try v11.divFromA(f64, a1);
    try testing.expectEqual([3]f32{ 0.25, 0.4, 0.5 }, v21.data);
    try testing.expectEqual([3]i32{ 0, 0, 0 }, v22.data);

    const v23 = try v1.divFromS(i64, s2);
    const v24 = try v11.divFromS(f64, s1);
    try testing.expectEqual([3]f32{ 0.5, 1.0, 1.5 }, v23.data);
    try testing.expectEqual([3]i32{ 0, 1, 1 }, v24.data);
}

test "Modulus" {
    // Floating point Vector
    // standard modulus of same type and size
    const v1 = Vec(f32, 3).initA(.{ 2.0, 5.0, 8.0 });
    const v2 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v3 = try v1.modV(v2);
    const v4 = try v1.modA(.{ 1.0, 2.0, 3.0 });
    const v5 = try v1.modS(2.0);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v3.data);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v4.data);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 0.0 }, v5.data);

    // modulus of same type with different size
    const v6 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v7 = try v1.modFromV(f64, v6);

    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const v8 = try v1.modFromA(f64, a1);

    const s1: f64 = 2.0;
    const v9 = try v1.modFromS(f64, s1);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v7.data);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v8.data);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 0.0 }, v9.data);

    // Signed Integral Vector
    // standard modulus of same type and size
    const v10 = Vec(i32, 3).initA(.{ 2, 5, 8 });
    const v11 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v12 = try v10.modV(v11);
    const v13 = try v10.modA(.{ 1, 2, 3 });
    const v14 = try v10.modS(2);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v12.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v13.data);
    try testing.expectEqual([3]i32{ 0, 1, 0 }, v14.data);

    // modulus of same type with different size
    const v15 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v16 = try v10.modFromV(i64, v15);

    const a2 = [3]i64{ 1, 2, 3 };
    const v17 = try v10.modFromA(i64, a2);

    const s2: i64 = 2;
    const v18 = try v10.modFromS(i64, s2);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v16.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v17.data);
    try testing.expectEqual([3]i32{ 0, 1, 0 }, v18.data);

    // Both Vector types
    // modulus of different type and size
    const v19 = try v1.modFromV(i64, v15);
    const v20 = try v10.modFromV(f64, v6);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v19.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v20.data);

    const v21 = try v1.modFromA(i64, a2);
    const v22 = try v10.modFromA(f64, a1);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 2.0 }, v21.data);
    try testing.expectEqual([3]i32{ 0, 1, 2 }, v22.data);

    const v23 = try v1.modFromS(i64, s2);
    const v24 = try v10.modFromS(f64, s1);
    try testing.expectEqual([3]f32{ 0.0, 1.0, 0.0 }, v23.data);
    try testing.expectEqual([3]i32{ 0, 1, 0 }, v24.data);
}

test "Remainder" {
    // Floating point Vector
    // standard remainder of same type and size
    const v1 = Vec(f32, 3).initA(.{ -2.0, -5.0, -8.0 });
    const v2 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v3 = try v1.remV(v2);
    const v4 = try v1.remA(.{ 1.0, 2.0, 3.0 });
    const v5 = try v1.remS(2.0);
    try testing.expectEqual([3]f32{ 0.0, -1.0, -2.0 }, v3.data);
    try testing.expectEqual([3]f32{ 0.0, -1.0, -2.0 }, v4.data);
    try testing.expectEqual([3]f32{ 0.0, -1.0, 0.0 }, v5.data);

    // remainder of same type with different size
    const v6 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v7 = try v1.remFromV(f64, v6);

    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const v8 = try v1.remFromA(f64, a1);

    const s1: f64 = 2.0;
    const v9 = try v1.remFromS(f64, s1);
    try testing.expectEqual([3]f32{ 0.0, -1.0, -2.0 }, v7.data);
    try testing.expectEqual([3]f32{ 0.0, -1.0, -2.0 }, v8.data);
    try testing.expectEqual([3]f32{ 0.0, -1.0, 0.0 }, v9.data);

    // Signed Integral Vector
    // standard remainder of same type and size
    const v10 = Vec(i32, 3).initA(.{ -2, -5, -8 });
    const v11 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v12 = try v10.remV(v11);
    const v13 = try v10.remA(.{ 1, 2, 3 });
    const v14 = try v10.remS(2);
    try testing.expectEqual([3]i32{ 0, -1, -2 }, v12.data);
    try testing.expectEqual([3]i32{ 0, -1, -2 }, v13.data);
    try testing.expectEqual([3]i32{ 0, -1, 0 }, v14.data);

    // remainder of same type with different size
    const v15 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v16 = try v10.remFromV(i64, v15);

    const a2 = [3]i64{ 1, 2, 3 };
    const v17 = try v10.remFromA(i64, a2);

    const s2: i64 = 2;
    const v18 = try v10.remFromS(i64, s2);
    try testing.expectEqual([3]i32{ 0, -1, -2 }, v16.data);
    try testing.expectEqual([3]i32{ 0, -1, -2 }, v17.data);
    try testing.expectEqual([3]i32{ 0, -1, 0 }, v18.data);

    // Both Vector types
    // remainder of different type and size
    const v19 = try v1.remFromV(i64, v15);
    const v20 = try v10.remFromV(f64, v6);
    try testing.expectEqual([3]f32{ 0.0, -1.0, -2.0 }, v19.data);
    try testing.expectEqual([3]i32{ 0, -1, -2 }, v20.data);

    const v21 = try v1.remFromA(i64, a2);
    const v22 = try v10.remFromA(f64, a1);
    try testing.expectEqual([3]f32{ 0.0, -1.0, -2.0 }, v21.data);
    try testing.expectEqual([3]i32{ 0, -1, -2 }, v22.data);

    const v23 = try v1.remFromS(i64, s2);
    const v24 = try v10.remFromS(f64, s1);
    try testing.expectEqual([3]f32{ 0.0, -1.0, 0.0 }, v23.data);
    try testing.expectEqual([3]i32{ 0, -1, 0 }, v24.data);
}

test "Greater than" {
    // Floating point Vector
    // standard greater than of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    try testing.expect(@reduce(.And, v2.greaterV(v1)));
    try testing.expect(!@reduce(.And, v2.greaterV(v2)));
    try testing.expect(@reduce(.And, v2.greaterA(.{ 1.0, 2.0, 3.0 })));
    try testing.expect(!@reduce(.And, v2.greaterA(.{ 4.0, 5.0, 6.0 })));
    try testing.expect(@reduce(.And, v2.greaterS(3.0)));
    try testing.expect(!@reduce(.And, v2.greaterS(6.0)));

    // greater than of same type with different size
    const v3 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v4 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const a2 = [3]f64{ 4.0, 5.0, 6.0 };
    const s1: f64 = 3.0;
    const s2: f64 = 6.0;
    try testing.expect(@reduce(.And, v2.greaterFromV(f64, v3)));
    try testing.expect(!@reduce(.And, v2.greaterFromV(f64, v4)));
    try testing.expect(@reduce(.And, v2.greaterFromA(f64, a1)));
    try testing.expect(!@reduce(.And, v2.greaterFromA(f64, a2)));
    try testing.expect(@reduce(.And, v2.greaterFromS(f64, s1)));
    try testing.expect(!@reduce(.And, v2.greaterFromS(f64, s2)));

    // Signed Integral Vector
    // standard greater than of same type and size
    const v5 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v6 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    try testing.expect(@reduce(.And, v6.greaterV(v5)));
    try testing.expect(!@reduce(.And, v6.greaterV(v6)));
    try testing.expect(@reduce(.And, v6.greaterA(.{ 1, 2, 3 })));
    try testing.expect(!@reduce(.And, v6.greaterA(.{ 4, 5, 6 })));
    try testing.expect(@reduce(.And, v6.greaterS(3)));
    try testing.expect(!@reduce(.And, v6.greaterS(6)));

    // greater than of same type with different size
    const v7 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v8 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const a3 = [3]i64{ 1, 2, 3 };
    const a4 = [3]i64{ 4, 5, 6 };
    const s3: i64 = 3;
    const s4: i64 = 6;
    try testing.expect(@reduce(.And, v6.greaterFromV(i64, v7)));
    try testing.expect(!@reduce(.And, v6.greaterFromV(i64, v8)));
    try testing.expect(@reduce(.And, v6.greaterFromA(i64, a3)));
    try testing.expect(!@reduce(.And, v6.greaterFromA(i64, a4)));
    try testing.expect(@reduce(.And, v6.greaterFromS(i64, s3)));
    try testing.expect(!@reduce(.And, v6.greaterFromS(i64, s4)));

    // Both Vector types
    // greater than of different type and size
    try testing.expect(@reduce(.And, v2.greaterFromV(i64, v7)));
    try testing.expect(!@reduce(.And, v2.greaterFromV(i64, v8)));
    try testing.expect(@reduce(.And, v6.greaterFromV(f64, v3)));
    try testing.expect(!@reduce(.And, v6.greaterFromV(f64, v4)));
    try testing.expect(@reduce(.And, v2.greaterFromA(i64, a3)));
    try testing.expect(!@reduce(.And, v2.greaterFromA(i64, a4)));
    try testing.expect(@reduce(.And, v6.greaterFromA(f64, a1)));
    try testing.expect(!@reduce(.And, v6.greaterFromA(f64, a2)));
    try testing.expect(@reduce(.And, v2.greaterFromS(i64, s3)));
    try testing.expect(!@reduce(.And, v2.greaterFromS(i64, s4)));
    try testing.expect(@reduce(.And, v6.greaterFromS(f64, s1)));
    try testing.expect(!@reduce(.And, v6.greaterFromS(f64, s2)));
}

test "Greater than or equal" {
    // Floating point Vector
    // standard greater than or equal of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    try testing.expect(@reduce(.And, v2.greaterEqV(v1)));
    try testing.expect(@reduce(.And, v2.greaterEqV(v2)));
    try testing.expect(@reduce(.And, v2.greaterEqA(.{ 1.0, 2.0, 3.0 })));
    try testing.expect(@reduce(.And, v2.greaterEqA(.{ 4.0, 5.0, 6.0 })));
    try testing.expect(@reduce(.And, v2.greaterEqS(3.0)));
    try testing.expect(!@reduce(.And, v2.greaterEqS(6.0)));

    // greater than or equal of same type with different size
    const v3 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v4 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const a2 = [3]f64{ 4.0, 5.0, 6.0 };
    const s1: f64 = 3.0;
    const s2: f64 = 6.0;
    try testing.expect(@reduce(.And, v2.greaterEqFromV(f64, v3)));
    try testing.expect(@reduce(.And, v2.greaterEqFromV(f64, v4)));
    try testing.expect(@reduce(.And, v2.greaterEqFromA(f64, a1)));
    try testing.expect(@reduce(.And, v2.greaterEqFromA(f64, a2)));
    try testing.expect(@reduce(.And, v2.greaterEqFromS(f64, s1)));
    try testing.expect(!@reduce(.And, v2.greaterEqFromS(f64, s2)));

    // Signed Integral Vector
    // standard greater than or equal of same type and size
    const v5 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v6 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    try testing.expect(@reduce(.And, v6.greaterEqV(v5)));
    try testing.expect(@reduce(.And, v6.greaterEqV(v6)));
    try testing.expect(@reduce(.And, v6.greaterEqA(.{ 1, 2, 3 })));
    try testing.expect(@reduce(.And, v6.greaterEqA(.{ 4, 5, 6 })));
    try testing.expect(@reduce(.And, v6.greaterEqS(3)));
    try testing.expect(!@reduce(.And, v6.greaterEqS(6)));

    // greater than or equal of same type with different size
    const v7 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v8 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const a3 = [3]i64{ 1, 2, 3 };
    const a4 = [3]i64{ 4, 5, 6 };
    const s3: i64 = 3;
    const s4: i64 = 6;
    try testing.expect(@reduce(.And, v6.greaterEqFromV(i64, v7)));
    try testing.expect(@reduce(.And, v6.greaterEqFromV(i64, v8)));
    try testing.expect(@reduce(.And, v6.greaterEqFromA(i64, a3)));
    try testing.expect(@reduce(.And, v6.greaterEqFromA(i64, a4)));
    try testing.expect(@reduce(.And, v6.greaterEqFromS(i64, s3)));
    try testing.expect(!@reduce(.And, v6.greaterEqFromS(i64, s4)));

    // Both Vector types
    // greater than or equal of different type and size
    try testing.expect(@reduce(.And, v2.greaterEqFromV(i64, v7)));
    try testing.expect(@reduce(.And, v2.greaterEqFromV(i64, v8)));
    try testing.expect(@reduce(.And, v6.greaterEqFromV(f64, v3)));
    try testing.expect(@reduce(.And, v6.greaterEqFromV(f64, v4)));
    try testing.expect(@reduce(.And, v2.greaterEqFromA(i64, a3)));
    try testing.expect(@reduce(.And, v2.greaterEqFromA(i64, a4)));
    try testing.expect(@reduce(.And, v6.greaterEqFromA(f64, a1)));
    try testing.expect(@reduce(.And, v6.greaterEqFromA(f64, a2)));
    try testing.expect(@reduce(.And, v2.greaterEqFromS(i64, s3)));
    try testing.expect(!@reduce(.And, v2.greaterEqFromS(i64, s4)));
    try testing.expect(@reduce(.And, v6.greaterEqFromS(f64, s1)));
    try testing.expect(!@reduce(.And, v6.greaterEqFromS(f64, s2)));
}

test "Lesser than" {
    // Floating point Vector
    // standard lesser than of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    try testing.expect(@reduce(.And, v1.lesserV(v2)));
    try testing.expect(!@reduce(.And, v1.lesserV(v1)));
    try testing.expect(@reduce(.And, v1.lesserA(.{ 4.0, 5.0, 6.0 })));
    try testing.expect(!@reduce(.And, v1.lesserA(.{ 1.0, 2.0, 3.0 })));
    try testing.expect(@reduce(.And, v1.lesserS(4.0)));
    try testing.expect(!@reduce(.And, v1.lesserS(1.0)));

    // lesser than of same type with different size
    const v3 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v4 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const a2 = [3]f64{ 4.0, 5.0, 6.0 };
    const s1: f64 = 4.0;
    const s2: f64 = 1.0;
    try testing.expect(@reduce(.And, v1.lesserFromV(f64, v4)));
    try testing.expect(!@reduce(.And, v1.lesserFromV(f64, v3)));
    try testing.expect(@reduce(.And, v1.lesserFromA(f64, a2)));
    try testing.expect(!@reduce(.And, v1.lesserFromA(f64, a1)));
    try testing.expect(@reduce(.And, v1.lesserFromS(f64, s1)));
    try testing.expect(!@reduce(.And, v1.lesserFromS(f64, s2)));

    // Signed Integral Vector
    // standard lesser than of same type and size
    const v5 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v6 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    try testing.expect(@reduce(.And, v5.lesserV(v6)));
    try testing.expect(!@reduce(.And, v5.lesserV(v5)));
    try testing.expect(@reduce(.And, v5.lesserA(.{ 4, 5, 6 })));
    try testing.expect(!@reduce(.And, v5.lesserA(.{ 1, 2, 3 })));
    try testing.expect(@reduce(.And, v5.lesserS(4)));
    try testing.expect(!@reduce(.And, v5.lesserS(1)));

    // lesser than of same type with different size
    const v7 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v8 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const a3 = [3]i64{ 1, 2, 3 };
    const a4 = [3]i64{ 4, 5, 6 };
    const s3: i64 = 4;
    const s4: i64 = 1;
    try testing.expect(@reduce(.And, v5.lesserFromV(i64, v8)));
    try testing.expect(!@reduce(.And, v5.lesserFromV(i64, v7)));
    try testing.expect(@reduce(.And, v5.lesserFromA(i64, a4)));
    try testing.expect(!@reduce(.And, v5.lesserFromA(i64, a3)));
    try testing.expect(@reduce(.And, v5.lesserFromS(i64, s3)));
    try testing.expect(!@reduce(.And, v5.lesserFromS(i64, s4)));

    // Both Vector types
    // lesser than of different type and size
    try testing.expect(@reduce(.And, v1.lesserFromV(i64, v8)));
    try testing.expect(!@reduce(.And, v1.lesserFromV(i64, v7)));
    try testing.expect(@reduce(.And, v5.lesserFromV(f64, v4)));
    try testing.expect(!@reduce(.And, v5.lesserFromV(f64, v3)));
    try testing.expect(@reduce(.And, v1.lesserFromA(i64, a4)));
    try testing.expect(!@reduce(.And, v1.lesserFromA(i64, a3)));
    try testing.expect(@reduce(.And, v5.lesserFromA(f64, a2)));
    try testing.expect(!@reduce(.And, v5.lesserFromA(f64, a1)));
    try testing.expect(@reduce(.And, v1.lesserFromS(i64, s3)));
    try testing.expect(!@reduce(.And, v1.lesserFromS(i64, s4)));
    try testing.expect(@reduce(.And, v5.lesserFromS(f64, s1)));
    try testing.expect(!@reduce(.And, v5.lesserFromS(f64, s2)));
}

test "Lesser than or equal" {
    // Floating point Vector
    // standard lesser than or equal of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec(f32, 3).initA(.{ 4.0, 5.0, 6.0 });
    try testing.expect(@reduce(.And, v1.lesserEqV(v2)));
    try testing.expect(@reduce(.And, v1.lesserEqV(v1)));
    try testing.expect(@reduce(.And, v1.lesserEqA(.{ 4.0, 5.0, 6.0 })));
    try testing.expect(@reduce(.And, v1.lesserEqA(.{ 1.0, 2.0, 3.0 })));
    try testing.expect(@reduce(.And, v1.lesserEqS(4.0)));
    try testing.expect(!@reduce(.And, v1.lesserEqS(1.0)));

    // lesser than or equal of same type with different size
    const v3 = Vec(f64, 3).initA(.{ 1.0, 2.0, 3.0 });
    const v4 = Vec(f64, 3).initA(.{ 4.0, 5.0, 6.0 });
    const a1 = [3]f64{ 1.0, 2.0, 3.0 };
    const a2 = [3]f64{ 4.0, 5.0, 6.0 };
    const s1: f64 = 4.0;
    const s2: f64 = 1.0;
    try testing.expect(@reduce(.And, v1.lesserEqFromV(f64, v4)));
    try testing.expect(@reduce(.And, v1.lesserEqFromV(f64, v3)));
    try testing.expect(@reduce(.And, v1.lesserEqFromA(f64, a2)));
    try testing.expect(@reduce(.And, v1.lesserEqFromA(f64, a1)));
    try testing.expect(@reduce(.And, v1.lesserEqFromS(f64, s1)));
    try testing.expect(!@reduce(.And, v1.lesserEqFromS(f64, s2)));

    // Signed Integral Vector
    // standard lesser than or equal of same type and size
    const v5 = Vec(i32, 3).initA(.{ 1, 2, 3 });
    const v6 = Vec(i32, 3).initA(.{ 4, 5, 6 });
    try testing.expect(@reduce(.And, v5.lesserEqV(v6)));
    try testing.expect(@reduce(.And, v5.lesserEqV(v5)));
    try testing.expect(@reduce(.And, v5.lesserEqA(.{ 4, 5, 6 })));
    try testing.expect(@reduce(.And, v5.lesserEqA(.{ 1, 2, 3 })));
    try testing.expect(@reduce(.And, v5.lesserEqS(4)));
    try testing.expect(!@reduce(.And, v5.lesserEqS(1)));

    // lesser than or equal of same type with different size
    const v7 = Vec(i64, 3).initA(.{ 1, 2, 3 });
    const v8 = Vec(i64, 3).initA(.{ 4, 5, 6 });
    const a3 = [3]i64{ 1, 2, 3 };
    const a4 = [3]i64{ 4, 5, 6 };
    const s3: i64 = 4;
    const s4: i64 = 1;
    try testing.expect(@reduce(.And, v5.lesserEqFromV(i64, v8)));
    try testing.expect(@reduce(.And, v5.lesserEqFromV(i64, v7)));
    try testing.expect(@reduce(.And, v5.lesserEqFromA(i64, a4)));
    try testing.expect(@reduce(.And, v5.lesserEqFromA(i64, a3)));
    try testing.expect(@reduce(.And, v5.lesserEqFromS(i64, s3)));
    try testing.expect(!@reduce(.And, v5.lesserEqFromS(i64, s4)));

    // Both Vector types
    // lesser than or equal of different type and size
    try testing.expect(@reduce(.And, v1.lesserEqFromV(i64, v8)));
    try testing.expect(@reduce(.And, v1.lesserEqFromV(i64, v7)));
    try testing.expect(@reduce(.And, v5.lesserEqFromV(f64, v4)));
    try testing.expect(@reduce(.And, v5.lesserEqFromV(f64, v3)));
    try testing.expect(@reduce(.And, v1.lesserEqFromA(i64, a4)));
    try testing.expect(@reduce(.And, v1.lesserEqFromA(i64, a3)));
    try testing.expect(@reduce(.And, v5.lesserEqFromA(f64, a2)));
    try testing.expect(@reduce(.And, v5.lesserEqFromA(f64, a1)));
    try testing.expect(@reduce(.And, v1.lesserEqFromS(i64, s3)));
    try testing.expect(!@reduce(.And, v1.lesserEqFromS(i64, s4)));
    try testing.expect(@reduce(.And, v5.lesserEqFromS(f64, s1)));
    try testing.expect(!@reduce(.And, v5.lesserEqFromS(f64, s2)));
}

test "Equality" {
    // Signed Integral Vector
    // standard equality of same type and size
    const v1 = Vec(i32, 3).initA(.{ 1, 1, 1 });
    const v2 = Vec(i32, 3).initA(.{ 4, 4, 4 });
    try testing.expect(@reduce(.And, v1.equalV(v1)));
    try testing.expect(!@reduce(.Or, v1.equalV(v2)));
    try testing.expect(@reduce(.And, v1.equalA(.{ 1, 1, 1 })));
    try testing.expect(!@reduce(.Or, v1.equalA(.{ 4, 4, 4 })));
    try testing.expect(@reduce(.And, v1.equalS(1)));
    try testing.expect(!@reduce(.Or, v1.equalS(4)));

    // equality of same type with different size
    const v3 = Vec(i64, 3).initA(.{ 1, 1, 1 });
    const v4 = Vec(i64, 3).initA(.{ 4, 4, 4 });
    const a1 = [3]i64{ 1, 1, 1 };
    const a2 = [3]i64{ 4, 4, 4 };
    const s1: i64 = 1;
    const s2: i64 = 4;
    try testing.expect(@reduce(.And, v1.equalFromV(i64, v3)));
    try testing.expect(!@reduce(.Or, v1.equalFromV(i64, v4)));
    try testing.expect(@reduce(.And, v1.equalFromA(i64, a1)));
    try testing.expect(!@reduce(.Or, v1.equalFromA(i64, a2)));
    try testing.expect(@reduce(.And, v1.equalFromS(i64, s1)));
    try testing.expect(!@reduce(.Or, v1.equalFromS(i64, s2)));

    // Floating point Vector
    // standard equality of same type and size
    const v5 = Vec(f32, 3).initA(.{ 1.0, 1.0, 1.0 });
    const v6 = Vec(f32, 3).initA(.{ 4.0, 4.0, 4.0 });
    try testing.expect(@reduce(.And, v5.equalV(v5)));
    try testing.expect(!@reduce(.Or, v5.equalV(v6)));
    try testing.expect(@reduce(.And, v5.equalA(.{ 1.0, 1.0, 1.0 })));
    try testing.expect(!@reduce(.Or, v5.equalA(.{ 4.0, 4.0, 4.0 })));
    try testing.expect(@reduce(.And, v5.equalS(1.0)));
    try testing.expect(!@reduce(.Or, v5.equalS(4.0)));

    // equality of same type with different size
    const v7 = Vec(f64, 3).initA(.{ 1.0, 1.0, 1.0 });
    const v8 = Vec(f64, 3).initA(.{ 4.0, 4.0, 4.0 });
    const a3 = [3]f64{ 1.0, 1.0, 1.0 };
    const a4 = [3]f64{ 4.0, 4.0, 4.0 };
    const s3: f64 = 1.0;
    const s4: f64 = 4.0;
    try testing.expect(@reduce(.And, v5.equalFromV(f64, v7)));
    try testing.expect(!@reduce(.Or, v5.equalFromV(f64, v8)));
    try testing.expect(@reduce(.And, v5.equalFromA(f64, a3)));
    try testing.expect(!@reduce(.Or, v5.equalFromA(f64, a4)));
    try testing.expect(@reduce(.And, v5.equalFromS(f64, s3)));
    try testing.expect(!@reduce(.Or, v5.equalFromS(f64, s4)));

    // Both Vector types
    // equality of different type and size
    try testing.expect(@reduce(.And, v1.equalFromV(f64, v7)));
    try testing.expect(!@reduce(.Or, v1.equalFromV(f64, v8)));
    try testing.expect(@reduce(.And, v5.equalFromV(i64, v3)));
    try testing.expect(!@reduce(.Or, v5.equalFromV(i64, v4)));
    try testing.expect(@reduce(.And, v1.equalFromA(f64, a3)));
    try testing.expect(!@reduce(.Or, v1.equalFromA(f64, a4)));
    try testing.expect(@reduce(.And, v5.equalFromA(i64, a1)));
    try testing.expect(!@reduce(.Or, v5.equalFromA(i64, a2)));
    try testing.expect(@reduce(.And, v1.equalFromS(f64, s3)));
    try testing.expect(!@reduce(.Or, v1.equalFromS(f64, s4)));
    try testing.expect(@reduce(.And, v5.equalFromS(i64, s1)));
    try testing.expect(!@reduce(.Or, v5.equalFromS(i64, s2)));
}

test "Approximately" {
    // Floating point Vector
    // standard equality of same type and size
    const v1 = Vec(f32, 3).initA(.{ 1.0, 1.0, 1.0 });
    const v2 = Vec(f32, 3).initA(.{ 1.0000001, 0.9999999, 1.0000001 });
    const v3 = Vec(f32, 3).initA(.{ 1.0000003, 0.9999997, 1.0000003 });
    try testing.expect(@reduce(.And, v1.approxV(v2, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approxV(v3, 0.0000002)));
    try testing.expect(@reduce(.And, v1.approxA(.{ 1.0000001, 0.9999999, 1.0000001 }, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approxA(.{ 1.0000003, 0.9999997, 1.0000003 }, 0.0000002)));
    try testing.expect(@reduce(.And, v1.approxS(1.0000001, 0.0000002)));
    try testing.expect(@reduce(.And, v1.approxS(0.9999999, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approxS(1.0000003, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approxS(0.9999997, 0.0000002)));

    // equality of same type with different size
    const v4 = Vec(f64, 3).initA(.{ 1.0000001, 0.9999999, 1.0000001 });
    const v5 = Vec(f64, 3).initA(.{ 1.0000003, 0.9999997, 1.0000003 });
    const a1 = [3]f64{ 1.0000001, 0.9999999, 1.0000001 };
    const a2 = [3]f64{ 1.0000003, 0.9999997, 1.0000003 };
    const s1: f64 = 1.0000001;
    const s2: f64 = 0.9999999;
    const s3: f64 = 1.0000003;
    const s4: f64 = 0.9999997;
    try testing.expect(@reduce(.And, v1.approxFromV(f64, v4, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approxFromV(f64, v5, 0.0000002)));
    try testing.expect(@reduce(.And, v1.approxFromA(f64, a1, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approxFromA(f64, a2, 0.0000002)));
    try testing.expect(@reduce(.And, v1.approxFromS(f64, s1, 0.0000002)));
    try testing.expect(@reduce(.And, v1.approxFromS(f64, s2, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approxFromS(f64, s3, 0.0000002)));
    try testing.expect(!@reduce(.Or, v1.approxFromS(f64, s4, 0.0000002)));

    // Signed Integral Vector
    // standard equality of same type and size
    const v6 = Vec(i32, 3).initA(.{ 1, 1, 1 });
    const v7 = Vec(i32, 3).initA(.{ 2, 3, 2 });
    try testing.expect(@reduce(.And, v6.approxV(v6, 0)));
    try testing.expect(!@reduce(.Or, v6.approxV(v7, 0)));
    try testing.expect(!@reduce(.And, v6.approxV(v7, 1)));
    try testing.expect(@reduce(.Or, v6.approxV(v7, 1)));
    try testing.expect(@reduce(.And, v6.approxV(v7, 2)));

    // equality of same type with different size
    const v8 = Vec(i64, 3).initA(.{ 1, 1, 1 });
    const v9 = Vec(i64, 3).initA(.{ 2, 3, 2 });
    const a3 = [3]i64{ 1, 1, 1 };
    const a4 = [3]i64{ 2, 3, 2 };
    const s5: i64 = 1;
    const s6: i64 = 2;
    try testing.expect(@reduce(.And, v6.approxFromV(i64, v8, 0)));
    try testing.expect(!@reduce(.Or, v6.approxFromV(i64, v9, 0)));
    try testing.expect(!@reduce(.And, v6.approxFromV(i64, v9, 1)));
    try testing.expect(@reduce(.Or, v6.approxFromV(i64, v9, 1)));
    try testing.expect(@reduce(.And, v6.approxFromV(i64, v9, 2)));

    try testing.expect(@reduce(.And, v6.approxFromA(i64, a3, 0)));
    try testing.expect(!@reduce(.And, v6.approxFromA(i64, a4, 0)));
    try testing.expect(!@reduce(.Or, v6.approxFromA(i64, a4, 0)));
    try testing.expect(!@reduce(.And, v6.approxFromA(i64, a4, 1)));
    try testing.expect(@reduce(.Or, v6.approxFromA(i64, a4, 1)));
    try testing.expect(@reduce(.And, v6.approxFromA(i64, a4, 2)));

    try testing.expect(@reduce(.And, v6.approxFromS(i64, s5, 0)));
    try testing.expect(!@reduce(.Or, v6.approxFromS(i64, s6, 0)));
    try testing.expect(@reduce(.Or, v6.approxFromS(i64, s6, 1)));

    // Both Vector types
    // equality of different type and size
    try testing.expect(@reduce(.And, v8.approxFromV(f32, v1, 0)));
    try testing.expect(!@reduce(.Or, v9.approxFromV(f32, v1, 0)));
    try testing.expect(!@reduce(.And, v9.approxFromV(f32, v1, 1)));
    try testing.expect(@reduce(.Or, v9.approxFromV(f32, v1, 1)));
    try testing.expect(@reduce(.And, v9.approxFromV(f32, v1, 2)));

    try testing.expect(@reduce(.And, v4.approxFromV(i32, v6, 0.0000002)));
    try testing.expect(!@reduce(.Or, v5.approxFromV(i32, v6, 0.0000002)));

    try testing.expect(@reduce(.And, Vec(i64, 3).initA(a3).approxFromA(f32, v1.data, 0)));
    try testing.expect(!@reduce(.Or, Vec(i64, 3).initA(a4).approxFromA(f32, v1.data, 0)));
    try testing.expect(!@reduce(.And, Vec(i64, 3).initA(a4).approxFromA(f32, v1.data, 1)));
    try testing.expect(@reduce(.Or, Vec(i64, 3).initA(a4).approxFromA(f32, v1.data, 1)));
    try testing.expect(@reduce(.And, Vec(i64, 3).initA(a4).approxFromA(f32, v1.data, 2)));

    try testing.expect(@reduce(.And, Vec(f64, 3).initA(a1).approxFromA(i32, v6.data, 0.0000002)));
    try testing.expect(!@reduce(.Or, Vec(f64, 3).initA(a2).approxFromA(i32, v6.data, 0.0000002)));

    try testing.expect(@reduce(.And, Vec(i64, 3).initS(s5).approxFromS(f32, v1.data[0], 0)));
    try testing.expect(!@reduce(.Or, Vec(i64, 3).initS(s6).approxFromS(f32, v1.data[0], 0)));
    try testing.expect(@reduce(.And, Vec(i64, 3).initS(s6).approxFromS(f32, v1.data[0], 1)));

    try testing.expect(@reduce(.And, Vec(f64, 3).initS(s1).approxFromS(i32, v6.data[0], 0.0000002)));
    try testing.expect(@reduce(.And, Vec(f64, 3).initS(s2).approxFromS(i32, v6.data[0], 0.0000002)));
    try testing.expect(!@reduce(.Or, Vec(f64, 3).initS(s3).approxFromS(i32, v6.data[0], 0.0000002)));
    try testing.expect(!@reduce(.Or, Vec(f64, 3).initS(s4).approxFromS(i32, v6.data[0], 0.0000002)));
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
//
// test "Direction" {
//     const v1 = Vec(f32, 3).init(.{ 1.0, 2.0, 3.0 });
//     const v2 = Vec(f32, 3).init(.{ 4.0, 5.0, 6.0 });
//     const dir = v1.dirTo(v2);
//     try testing.expectEqual([3]f32{ 0.57735026, 0.57735026, 0.57735026 }, dir.data);
//
//     const dir2 = v2.dirTo(v2);
//     try testing.expectEqual([3]f32{ 0.0, 0.0, 0.0 }, dir2.data);
// }
//
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
