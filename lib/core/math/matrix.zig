/// Creates a Matrix type of size MxN (M rows, N columns) with element type T
/// For square matrices, M == N
/// Row-major storage order
pub fn Matrix(
    comptime T: type,
    comptime M: u16, // rows
    comptime N: u16, // columns
) type {
    switch (@typeInfo(T)) {
        .int => |info| if (info.signedness == .unsigned) @compileError("Matrix element type must be signed"),
        .float => {},
        else => @compileError("Matrix element type must be numeric"),
    }

    return struct {
        data: [M][N]T,

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

        // ============================================
        // Initialization
        // ============================================

        /// Default initialization with undefined values
        pub inline fn init() Self {
            return .{ .data = undefined };
        }

        /// Initialize all elements to a single value
        pub inline fn from(value_: anytype) Self {
            var result: Self = undefined;
            const v = scalarFrom(@TypeOf(value_), value_);
            for (0..M) |i| {
                result.data[i] = [_]T{v} ** N;
            }
            return result;
        }

        /// Initialize from 2D array
        pub inline fn fromArray(arr: [M][N]T) Self {
            return .{ .data = arr };
        }

        /// Initialize from flat array (row-major)
        pub inline fn fromFlat(arr: [M * N]T) Self {
            return .{ .data = @bitCast(arr) };
        }

        /// Initialize from row vectors
        pub inline fn fromRows(rows_: [M]RowVec) Self {
            var result: Self = undefined;
            for (0..M) |i| {
                result.data[i] = rows_[i].data;
            }
            return result;
        }

        /// Initialize from column vectors
        pub inline fn fromCols(cols_: [N]ColVec) Self {
            var result: Self = undefined;
            for (0..M) |i| {
                for (0..N) |j| {
                    result.data[i][j] = cols_[j].data[i];
                }
            }
            return result;
        }

        /// Identity matrix (only for square matrices)
        pub inline fn identity() Self {
            if (!isSquare) @compileError("Identity matrix requires square matrix");
            var result = Self.from(0);
            for (0..M) |i| {
                result.data[i][i] = 1;
            }
            return result;
        }

        /// Zero matrix
        pub inline fn zero() Self {
            return Self.from(0);
        }

        /// Diagonal matrix from vector or scalar
        pub inline fn diagonal(value_: anytype) Self {
            if (!isSquare) @compileError("Diagonal matrix requires square matrix");
            var result = Self.from(0);
            const VT = @TypeOf(value_);
            if (VT == ColVec or VT == RowVec) {
                const min_dim = @min(M, N);
                for (0..min_dim) |i| {
                    result.data[i][i] = value_.data[i];
                }
            } else {
                const v = scalarFrom(VT, value_);
                for (0..M) |i| {
                    result.data[i][i] = v;
                }
            }
            return result;
        }

        // ============================================
        // Accessors
        // ============================================

        /// Get element at row i, column j
        pub inline fn get(self: *const Self, i: usize, j: usize) T {
            return self.data[i][j];
        }

        /// Set element at row i, column j
        pub inline fn set(self: *Self, i: usize, j: usize, value: T) *Self {
            self.data[i][j] = value;
            return self;
        }

        /// Get row as vector
        pub inline fn row(self: *const Self, i: usize) RowVec {
            return RowVec.from(self.data[i]);
        }

        /// Get column as vector
        pub inline fn col(self: *const Self, j: usize) ColVec {
            var result: [M]T = undefined;
            for (0..M) |i| {
                result[i] = self.data[i][j];
            }
            return ColVec.from(result);
        }

        /// Set row from vector
        pub inline fn setRow(self: *Self, i: usize, vec: RowVec) *Self {
            self.data[i] = vec.data;
            return self;
        }

        /// Set column from vector
        pub inline fn setCol(self: *Self, j: usize, vec: ColVec) *Self {
            for (0..M) |i| {
                self.data[i][j] = vec.data[i];
            }
            return self;
        }

        /// Get diagonal as vector (square matrices)
        pub inline fn getDiagonal(self: *const Self) ColVec {
            if (!isSquare) @compileError("getDiagonal requires square matrix");
            var result: [M]T = undefined;
            for (0..M) |i| {
                result[i] = self.data[i][i];
            }
            return ColVec.from(result);
        }

        /// Get as flat array (row-major)
        pub inline fn flat(self: *const Self) [M * N]T {
            return @bitCast(self.data);
        }

        /// Clone matrix
        pub inline fn clone(self: *const Self) Self {
            return .{ .data = self.data };
        }

        /// Remove const from pointer
        pub inline fn ptr(self: *const Self) *Self {
            return @constCast(self);
        }

        // ============================================
        // Arithmetic Operations
        // ============================================

        /// Element-wise addition (in-place)
        pub inline fn add(self: *Self, other_: anytype) *Self {
            const other = matrixFromAny(other_);
            for (0..M) |i| {
                const a: V = self.data[i];
                const b: V = other.data[i];
                self.data[i] = a + b;
            }
            return self;
        }

        /// Element-wise addition (new matrix)
        pub inline fn added(self: *const Self, other_: anytype) Self {
            return self.clone().ptr().add(other_).*;
        }

        /// Element-wise subtraction (in-place)
        pub inline fn sub(self: *Self, other_: anytype) *Self {
            const other = matrixFromAny(other_);
            for (0..M) |i| {
                const a: V = self.data[i];
                const b: V = other.data[i];
                self.data[i] = a - b;
            }
            return self;
        }

        /// Element-wise subtraction (new matrix)
        pub inline fn subbed(self: *const Self, other_: anytype) Self {
            return self.clone().ptr().sub(other_).*;
        }

        /// Scalar multiplication (in-place)
        pub inline fn scale(self: *Self, scalar_: anytype) *Self {
            const s: T = scalarFrom(@TypeOf(scalar_), scalar_);
            const sv: V = @splat(s);
            for (0..M) |i| {
                const a: V = self.data[i];
                self.data[i] = a * sv;
            }
            return self;
        }

        /// Scalar multiplication (new matrix)
        pub inline fn scaled(self: *const Self, scalar_: anytype) Self {
            return self.clone().ptr().scale(scalar_).*;
        }

        /// Element-wise multiplication (Hadamard product, in-place)
        pub inline fn hadamard(self: *Self, other_: anytype) *Self {
            const other = matrixFromAny(other_);
            for (0..M) |i| {
                const a: V = self.data[i];
                const b: V = other.data[i];
                self.data[i] = a * b;
            }
            return self;
        }

        /// Element-wise multiplication (new matrix)
        pub inline fn hadamarded(self: *const Self, other_: anytype) Self {
            return self.clone().ptr().hadamard(other_).*;
        }

        /// Matrix multiplication: Self (MxN) * Other (NxP) = Result (MxP)
        pub inline fn mul(self: *const Self, other_: anytype) Matrix(T, M, getOtherCols(@TypeOf(other_))) {
            const P = comptime getOtherCols(@TypeOf(other_));
            const Other = Matrix(T, N, P);
            const Result = Matrix(T, M, P);

            const other: Other = if (@TypeOf(other_) == Other) other_ else Other.fromAny(other_);
            var result: Result = undefined;

            for (0..M) |i| {
                for (0..P) |j| {
                    var sum: T = 0;
                    inline for (0..N) |k| {
                        sum += self.data[i][k] * other.data[k][j];
                    }
                    result.data[i][j] = sum;
                }
            }
            return result;
        }

        /// Matrix-vector multiplication: Matrix (MxN) * Vector (N) = Vector (M)
        pub inline fn mulVec(self: *const Self, vec: RowVec) ColVec {
            var result: [M]T = undefined;
            for (0..M) |i| {
                const row_vec: V = self.data[i];
                const v: V = vec.data;
                result[i] = @reduce(.Add, row_vec * v);
            }
            return ColVec.from(result);
        }

        /// Vector-matrix multiplication: Vector (M) * Matrix (MxN) = Vector (N)
        pub inline fn vecMul(vec: ColVec, self: *const Self) RowVec {
            var result: [N]T = undefined;
            for (0..N) |j| {
                var sum: T = 0;
                for (0..M) |i| {
                    sum += vec.data[i] * self.data[i][j];
                }
                result[j] = sum;
            }
            return RowVec.from(result);
        }

        /// Scalar division (in-place)
        pub inline fn divScale(self: *Self, scalar_: anytype) !*Self {
            const s: T = scalarFrom(@TypeOf(scalar_), scalar_);
            if (s == 0) return MError.DivideByZero;
            const sv: V = @splat(s);
            for (0..M) |i| {
                const a: V = self.data[i];
                self.data[i] = a / sv;
            }
            return self;
        }

        /// Scalar division (new matrix)
        pub inline fn divScaled(self: *const Self, scalar_: anytype) !Self {
            return (try self.clone().ptr().divScale(scalar_)).*;
        }

        /// Negate all elements (in-place)
        pub inline fn negate(self: *Self) *Self {
            return self.scale(-1);
        }

        /// Negate all elements (new matrix)
        pub inline fn negated(self: *const Self) Self {
            return self.scaled(-1);
        }

        // ============================================
        // Matrix Operations
        // ============================================

        /// Transpose matrix
        pub inline fn transpose(self: *const Self) Transpose {
            var result: Transpose = undefined;
            for (0..M) |i| {
                for (0..N) |j| {
                    result.data[j][i] = self.data[i][j];
                }
            }
            return result;
        }

        /// Trace (sum of diagonal, square matrices only)
        pub inline fn trace(self: *const Self) T {
            if (!isSquare) @compileError("Trace requires square matrix");
            var sum: T = 0;
            for (0..M) |i| {
                sum += self.data[i][i];
            }
            return sum;
        }

        /// Determinant (square matrices only)
        pub fn determinant(self: *const Self) T {
            if (!isSquare) @compileError("Determinant requires square matrix");
            return computeDeterminant(M, &self.data);
        }

        /// Private: Recursive determinant calculation
        fn computeDeterminant(comptime n: u16, matrix: *const [n][n]T) T {
            if (n == 1) return matrix[0][0];
            if (n == 2) return matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0];
            if (n == 3) {
                return matrix[0][0] * (matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1]) -
                    matrix[0][1] * (matrix[1][0] * matrix[2][2] - matrix[1][2] * matrix[2][0]) +
                    matrix[0][2] * (matrix[1][0] * matrix[2][1] - matrix[1][1] * matrix[2][0]);
            }

            var det: T = 0;
            for (0..n) |j| {
                var submatrix: [n - 1][n - 1]T = undefined;
                for (1..n) |i| {
                    var sub_col: usize = 0;
                    for (0..n) |k| {
                        if (k == j) continue;
                        submatrix[i - 1][sub_col] = matrix[i][k];
                        sub_col += 1;
                    }
                }
                const sign: T = if (j % 2 == 0) 1 else -1;
                det += sign * matrix[0][j] * computeDeterminant(n - 1, &submatrix);
            }
            return det;
        }

        /// Minor matrix (remove row i, column j)
        pub fn minor(self: *const Self, row_idx: usize, col_idx: usize) Matrix(T, M - 1, N - 1) {
            if (M <= 1 or N <= 1) @compileError("Cannot compute minor of 1xN or Mx1 matrix");
            var result: Matrix(T, M - 1, N - 1) = undefined;
            var ri: usize = 0;
            for (0..M) |i| {
                if (i == row_idx) continue;
                var rj: usize = 0;
                for (0..N) |j| {
                    if (j == col_idx) continue;
                    result.data[ri][rj] = self.data[i][j];
                    rj += 1;
                }
                ri += 1;
            }
            return result;
        }

        /// Cofactor at position (i, j)
        pub fn cofactor(self: *const Self, i: usize, j: usize) T {
            if (!isSquare) @compileError("Cofactor requires square matrix");
            const sign: T = if ((i + j) % 2 == 0) 1 else -1;
            const minor_det = self.minor(i, j).determinant();
            return sign * minor_det;
        }

        /// Cofactor matrix (matrix of all cofactors)
        pub fn cofactorMatrix(self: *const Self) Self {
            if (!isSquare) @compileError("Cofactor matrix requires square matrix");
            var result: Self = undefined;
            for (0..M) |i| {
                for (0..N) |j| {
                    result.data[i][j] = self.cofactor(i, j);
                }
            }
            return result;
        }

        /// Adjugate (adjoint) matrix - transpose of cofactor matrix
        pub fn adjugate(self: *const Self) Self {
            if (!isSquare) @compileError("Adjugate requires square matrix");
            return self.cofactorMatrix().transpose();
        }

        /// Inverse matrix (square matrices only)
        pub fn inverse(self: *const Self) !Self {
            if (!isSquare) @compileError("Inverse requires square matrix");

            const det = self.determinant();
            if (det == 0) return MError.SingularMatrix;

            // For small matrices, use direct formulas
            if (M == 1) {
                return Self.from(1 / det);
            }

            if (M == 2) {
                var result: Self = undefined;
                const inv_det = 1 / det;
                result.data[0][0] = self.data[1][1] * inv_det;
                result.data[0][1] = -self.data[0][1] * inv_det;
                result.data[1][0] = -self.data[1][0] * inv_det;
                result.data[1][1] = self.data[0][0] * inv_det;
                return result;
            }

            if (M == 3) {
                var result: Self = undefined;
                const inv_det = 1 / det;

                result.data[0][0] = (self.data[1][1] * self.data[2][2] - self.data[1][2] * self.data[2][1]) * inv_det;
                result.data[0][1] = (self.data[0][2] * self.data[2][1] - self.data[0][1] * self.data[2][2]) * inv_det;
                result.data[0][2] = (self.data[0][1] * self.data[1][2] - self.data[0][2] * self.data[1][1]) * inv_det;
                result.data[1][0] = (self.data[1][2] * self.data[2][0] - self.data[1][0] * self.data[2][2]) * inv_det;
                result.data[1][1] = (self.data[0][0] * self.data[2][2] - self.data[0][2] * self.data[2][0]) * inv_det;
                result.data[1][2] = (self.data[0][2] * self.data[1][0] - self.data[0][0] * self.data[1][2]) * inv_det;
                result.data[2][0] = (self.data[1][0] * self.data[2][1] - self.data[1][1] * self.data[2][0]) * inv_det;
                result.data[2][1] = (self.data[0][1] * self.data[2][0] - self.data[0][0] * self.data[2][1]) * inv_det;
                result.data[2][2] = (self.data[0][0] * self.data[1][1] - self.data[0][1] * self.data[1][0]) * inv_det;
                return result;
            }

            if (M == 4) {
                return inverse4x4(self);
            }

            // General case: use adjugate method
            var adj = self.adjugate();
            return (try adj.divScale(det)).*;
        }

        /// Optimized 4x4 inverse
        fn inverse4x4(self: *const Self) !Self {
            const m = self.data;
            var result: Self = undefined;

            const s0 = m[0][0] * m[1][1] - m[1][0] * m[0][1];
            const s1 = m[0][0] * m[1][2] - m[1][0] * m[0][2];
            const s2 = m[0][0] * m[1][3] - m[1][0] * m[0][3];
            const s3 = m[0][1] * m[1][2] - m[1][1] * m[0][2];
            const s4 = m[0][1] * m[1][3] - m[1][1] * m[0][3];
            const s5 = m[0][2] * m[1][3] - m[1][2] * m[0][3];

            const c5 = m[2][2] * m[3][3] - m[3][2] * m[2][3];
            const c4 = m[2][1] * m[3][3] - m[3][1] * m[2][3];
            const c3 = m[2][1] * m[3][2] - m[3][1] * m[2][2];
            const c2 = m[2][0] * m[3][3] - m[3][0] * m[2][3];
            const c1 = m[2][0] * m[3][2] - m[3][0] * m[2][2];
            const c0 = m[2][0] * m[3][1] - m[3][0] * m[2][1];

            const det = s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0;
            if (det == 0) return MError.SingularMatrix;

            const inv_det = 1 / det;

            result.data[0][0] = (m[1][1] * c5 - m[1][2] * c4 + m[1][3] * c3) * inv_det;
            result.data[0][1] = (-m[0][1] * c5 + m[0][2] * c4 - m[0][3] * c3) * inv_det;
            result.data[0][2] = (m[3][1] * s5 - m[3][2] * s4 + m[3][3] * s3) * inv_det;
            result.data[0][3] = (-m[2][1] * s5 + m[2][2] * s4 - m[2][3] * s3) * inv_det;

            result.data[1][0] = (-m[1][0] * c5 + m[1][2] * c2 - m[1][3] * c1) * inv_det;
            result.data[1][1] = (m[0][0] * c5 - m[0][2] * c2 + m[0][3] * c1) * inv_det;
            result.data[1][2] = (-m[3][0] * s5 + m[3][2] * s2 - m[3][3] * s1) * inv_det;
            result.data[1][3] = (m[2][0] * s5 - m[2][2] * s2 + m[2][3] * s1) * inv_det;

            result.data[2][0] = (m[1][0] * c4 - m[1][1] * c2 + m[1][3] * c0) * inv_det;
            result.data[2][1] = (-m[0][0] * c4 + m[0][1] * c2 - m[0][3] * c0) * inv_det;
            result.data[2][2] = (m[3][0] * s4 - m[3][1] * s2 + m[3][3] * s0) * inv_det;
            result.data[2][3] = (-m[2][0] * s4 + m[2][1] * s2 - m[2][3] * s0) * inv_det;

            result.data[3][0] = (-m[1][0] * c3 + m[1][1] * c1 - m[1][2] * c0) * inv_det;
            result.data[3][1] = (m[0][0] * c3 - m[0][1] * c1 + m[0][2] * c0) * inv_det;
            result.data[3][2] = (-m[3][0] * s3 + m[3][1] * s1 - m[3][2] * s0) * inv_det;
            result.data[3][3] = (m[2][0] * s3 - m[2][1] * s1 + m[2][2] * s0) * inv_det;

            return result;
        }

        /// Check if matrix is invertible
        pub fn isInvertible(self: *const Self) bool {
            if (!isSquare) return false;
            return self.determinant() != 0;
        }

        // ============================================
        // Comparison Operations
        // ============================================

        /// Element-wise equality check
        pub fn isEqual(self: *const Self, other_: anytype) bool {
            const other = matrixFromAny(other_);
            for (0..M) |i| {
                for (0..N) |j| {
                    if (self.data[i][j] != other.data[i][j]) return false;
                }
            }
            return true;
        }

        /// Element-wise approximate equality
        pub fn isApproximate(self: *const Self, other_: anytype, tolerance: ?T) bool {
            const other = matrixFromAny(other_);
            const tol = tolerance orelse if (@typeInfo(T) == .float) std.math.floatEps(T) else 0;
            for (0..M) |i| {
                for (0..N) |j| {
                    const diff = if (self.data[i][j] > other.data[i][j])
                        self.data[i][j] - other.data[i][j]
                    else
                        other.data[i][j] - self.data[i][j];
                    if (diff > tol) return false;
                }
            }
            return true;
        }

        /// Check if identity matrix
        pub fn isIdentity(self: *const Self) bool {
            if (!isSquare) return false;
            for (0..M) |i| {
                for (0..N) |j| {
                    const expected: T = if (i == j) 1 else 0;
                    if (self.data[i][j] != expected) return false;
                }
            }
            return true;
        }

        /// Check if zero matrix
        pub fn isZero(self: *const Self) bool {
            for (0..M) |i| {
                for (0..N) |j| {
                    if (self.data[i][j] != 0) return false;
                }
            }
            return true;
        }

        /// Check if symmetric (A == A^T)
        pub fn isSymmetric(self: *const Self) bool {
            if (!isSquare) return false;
            for (0..M) |i| {
                for (i + 1..N) |j| {
                    if (self.data[i][j] != self.data[j][i]) return false;
                }
            }
            return true;
        }

        /// Check if orthogonal (A * A^T == I)
        pub fn isOrthogonal(self: *const Self, tolerance: ?T) bool {
            if (!isSquare) return false;
            const product = self.mul(self.transpose());
            return product.isApproximate(Self.identity(), tolerance);
        }

        // ============================================
        // Transform Operations (for 4x4 matrices)
        // ============================================

        /// Create translation matrix (4x4 only)
        pub fn translation(x: T, y: T, z: T) Self {
            if (M != 4 or N != 4) @compileError("Translation requires 4x4 matrix");
            var result = Self.identity();
            result.data[0][3] = x;
            result.data[1][3] = y;
            result.data[2][3] = z;
            return result;
        }

        /// Create translation matrix from vector
        pub fn translationVec(vec: Vector(T, 3)) Self {
            return translation(vec.data[0], vec.data[1], vec.data[2]);
        }

        /// Create scaling matrix (4x4)
        pub fn scaling(x: T, y: T, z: T) Self {
            if (M != 4 or N != 4) @compileError("Scaling requires 4x4 matrix");
            var result = Self.identity();
            result.data[0][0] = x;
            result.data[1][1] = y;
            result.data[2][2] = z;
            return result;
        }

        /// Create scaling matrix from vector
        pub fn scalingVec(vec: Vector(T, 3)) Self {
            return scaling(vec.data[0], vec.data[1], vec.data[2]);
        }

        /// Create uniform scaling matrix
        pub fn scalingUniform(s: T) Self {
            return scaling(s, s, s);
        }

        /// Create rotation matrix around X axis (radians)
        pub fn rotationX(angle: T) Self {
            if (M != 4 or N != 4) @compileError("Rotation requires 4x4 matrix");
            if (isInt) @compileError("Rotation requires floating point matrix");
            var result = Self.identity();
            const c = @cos(angle);
            const s = @sin(angle);
            result.data[1][1] = c;
            result.data[1][2] = -s;
            result.data[2][1] = s;
            result.data[2][2] = c;
            return result;
        }

        /// Create rotation matrix around Y axis (radians)
        pub fn rotationY(angle: T) Self {
            if (M != 4 or N != 4) @compileError("Rotation requires 4x4 matrix");
            if (isInt) @compileError("Rotation requires floating point matrix");
            var result = Self.identity();
            const c = @cos(angle);
            const s = @sin(angle);
            result.data[0][0] = c;
            result.data[0][2] = s;
            result.data[2][0] = -s;
            result.data[2][2] = c;
            return result;
        }

        /// Create rotation matrix around Z axis (radians)
        pub fn rotationZ(angle: T) Self {
            if (M != 4 or N != 4) @compileError("Rotation requires 4x4 matrix");
            if (isInt) @compileError("Rotation requires floating point matrix");
            var result = Self.identity();
            const c = @cos(angle);
            const s = @sin(angle);
            result.data[0][0] = c;
            result.data[0][1] = -s;
            result.data[1][0] = s;
            result.data[1][1] = c;
            return result;
        }

        /// Create rotation matrix around arbitrary axis (radians)
        pub fn rotationAxis(axis: Vector(T, 3), angle: T) Self {
            if (M != 4 or N != 4) @compileError("Rotation requires 4x4 matrix");
            if (isInt) @compileError("Rotation requires floating point matrix");
            const n = axis.normalized();
            const c = @cos(angle);
            const s = @sin(angle);
            const t = 1 - c;
            const x = n.data[0];
            const y = n.data[1];
            const z = n.data[2];

            var result = Self.identity();
            result.data[0][0] = t * x * x + c;
            result.data[0][1] = t * x * y - s * z;
            result.data[0][2] = t * x * z + s * y;
            result.data[1][0] = t * x * y + s * z;
            result.data[1][1] = t * y * y + c;
            result.data[1][2] = t * y * z - s * x;
            result.data[2][0] = t * x * z - s * y;
            result.data[2][1] = t * y * z + s * x;
            result.data[2][2] = t * z * z + c;
            return result;
        }

        /// Create rotation matrix from Euler angles (XYZ order, radians)
        pub fn rotationEuler(pitch: T, yaw: T, roll: T) Self {
            if (M != 4 or N != 4) @compileError("Rotation requires 4x4 matrix");
            if (isInt) @compileError("Rotation requires floating point matrix");
            return rotationZ(roll).mul(rotationY(yaw)).mul(rotationX(pitch));
        }

        /// Create rotation matrix from Euler angles vector (XYZ)
        pub fn rotationEulerVec(euler: Vector(T, 3)) Self {
            return rotationEuler(euler.data[0], euler.data[1], euler.data[2]);
        }

        /// Create rotation matrix from quaternion
        pub fn fromQuaternion(q: Vector(T, 4)) Self {
            if (M != 4 or N != 4) @compileError("fromQuaternion requires 4x4 matrix");
            if (isInt) @compileError("fromQuaternion requires floating point matrix");
            const x = q.data[0];
            const y = q.data[1];
            const z = q.data[2];
            const w = q.data[3];

            const x2 = x + x;
            const y2 = y + y;
            const z2 = z + z;
            const xx = x * x2;
            const xy = x * y2;
            const xz = x * z2;
            const yy = y * y2;
            const yz = y * z2;
            const zz = z * z2;
            const wx = w * x2;
            const wy = w * y2;
            const wz = w * z2;

            var result = Self.identity();
            result.data[0][0] = 1 - (yy + zz);
            result.data[0][1] = xy - wz;
            result.data[0][2] = xz + wy;
            result.data[1][0] = xy + wz;
            result.data[1][1] = 1 - (xx + zz);
            result.data[1][2] = yz - wx;
            result.data[2][0] = xz - wy;
            result.data[2][1] = yz + wx;
            result.data[2][2] = 1 - (xx + yy);
            return result;
        }

        /// Extract quaternion from rotation matrix
        pub fn toQuaternion(self: *const Self) Vector(T, 4) {
            if (M != 4 or N != 4) @compileError("toQuaternion requires 4x4 matrix");
            if (isInt) @compileError("toQuaternion requires floating point matrix");
            const m = self.data;
            var q: [4]T = undefined;

            const trace = m[0][0] + m[1][1] + m[2][2];
            if (trace > 0) {
                const s = @sqrt(trace + 1) * 2;
                q[3] = 0.25 * s;
                q[0] = (m[2][1] - m[1][2]) / s;
                q[1] = (m[0][2] - m[2][0]) / s;
                q[2] = (m[1][0] - m[0][1]) / s;
            } else if (m[0][0] > m[1][1] and m[0][0] > m[2][2]) {
                const s = @sqrt(1 + m[0][0] - m[1][1] - m[2][2]) * 2;
                q[3] = (m[2][1] - m[1][2]) / s;
                q[0] = 0.25 * s;
                q[1] = (m[0][1] + m[1][0]) / s;
                q[2] = (m[0][2] + m[2][0]) / s;
            } else if (m[1][1] > m[2][2]) {
                const s = @sqrt(1 + m[1][1] - m[0][0] - m[2][2]) * 2;
                q[3] = (m[0][2] - m[2][0]) / s;
                q[0] = (m[0][1] + m[1][0]) / s;
                q[1] = 0.25 * s;
                q[2] = (m[1][2] + m[2][1]) / s;
            } else {
                const s = @sqrt(1 + m[2][2] - m[0][0] - m[1][1]) * 2;
                q[3] = (m[1][0] - m[0][1]) / s;
                q[0] = (m[0][2] + m[2][0]) / s;
                q[1] = (m[1][2] + m[2][1]) / s;
                q[2] = 0.25 * s;
            }
            return Vector(T, 4).from(q);
        }

        /// Extract Euler angles from rotation matrix (XYZ order)
        pub fn toEuler(self: *const Self) Vector(T, 3) {
            if (M != 4 or N != 4) @compileError("toEuler requires 4x4 matrix");
            if (isInt) @compileError("toEuler requires floating point matrix");
            const m = self.data;
            var euler: [3]T = undefined;

            if (m[0][2] < 1) {
                if (m[0][2] > -1) {
                    euler[1] = std.math.asin(m[0][2]);
                    euler[0] = std.math.atan2(-m[1][2], m[2][2]);
                    euler[2] = std.math.atan2(-m[0][1], m[0][0]);
                } else {
                    euler[1] = -std.math.pi / 2.0;
                    euler[0] = -std.math.atan2(m[1][0], m[1][1]);
                    euler[2] = 0;
                }
            } else {
                euler[1] = std.math.pi / 2.0;
                euler[0] = std.math.atan2(m[1][0], m[1][1]);
                euler[2] = 0;
            }
            return Vector(T, 3).from(euler);
        }

        // ============================================
        // Projection Matrices
        // ============================================

        /// Create perspective projection matrix (right-handed, depth [0, 1])
        pub fn perspective(fov_y: T, aspect: T, near: T, far: T) Self {
            if (M != 4 or N != 4) @compileError("Perspective requires 4x4 matrix");
            if (isInt) @compileError("Perspective requires floating point matrix");
            var result = Self.zero();
            const tan_half_fov = @tan(fov_y / 2);
            result.data[0][0] = 1 / (aspect * tan_half_fov);
            result.data[1][1] = 1 / tan_half_fov;
            result.data[2][2] = far / (near - far);
            result.data[2][3] = -(far * near) / (far - near);
            result.data[3][2] = -1;
            return result;
        }

        /// Create perspective projection matrix (left-handed, depth [0, 1])
        pub fn perspectiveLH(fov_y: T, aspect: T, near: T, far: T) Self {
            if (M != 4 or N != 4) @compileError("Perspective requires 4x4 matrix");
            if (isInt) @compileError("Perspective requires floating point matrix");
            var result = Self.zero();
            const tan_half_fov = @tan(fov_y / 2);
            result.data[0][0] = 1 / (aspect * tan_half_fov);
            result.data[1][1] = 1 / tan_half_fov;
            result.data[2][2] = far / (far - near);
            result.data[2][3] = -(far * near) / (far - near);
            result.data[3][2] = 1;
            return result;
        }

        /// Create infinite perspective projection matrix
        pub fn perspectiveInfinite(fov_y: T, aspect: T, near: T) Self {
            if (M != 4 or N != 4) @compileError("Perspective requires 4x4 matrix");
            if (isInt) @compileError("Perspective requires floating point matrix");
            var result = Self.zero();
            const tan_half_fov = @tan(fov_y / 2);
            result.data[0][0] = 1 / (aspect * tan_half_fov);
            result.data[1][1] = 1 / tan_half_fov;
            result.data[2][2] = -1;
            result.data[2][3] = -near;
            result.data[3][2] = -1;
            return result;
        }

        /// Create orthographic projection matrix (right-handed, depth [0, 1])
        pub fn orthographic(left: T, right: T, bottom: T, top: T, near: T, far: T) Self {
            if (M != 4 or N != 4) @compileError("Orthographic requires 4x4 matrix");
            if (isInt) @compileError("Orthographic requires floating point matrix");
            var result = Self.identity();
            result.data[0][0] = 2 / (right - left);
            result.data[1][1] = 2 / (top - bottom);
            result.data[2][2] = -1 / (far - near);
            result.data[0][3] = -(right + left) / (right - left);
            result.data[1][3] = -(top + bottom) / (top - bottom);
            result.data[2][3] = -near / (far - near);
            return result;
        }

        /// Create orthographic projection matrix (left-handed, depth [0, 1])
        pub fn orthographicLH(left: T, right: T, bottom: T, top: T, near: T, far: T) Self {
            if (M != 4 or N != 4) @compileError("Orthographic requires 4x4 matrix");
            if (isInt) @compileError("Orthographic requires floating point matrix");
            var result = Self.identity();
            result.data[0][0] = 2 / (right - left);
            result.data[1][1] = 2 / (top - bottom);
            result.data[2][2] = 1 / (far - near);
            result.data[0][3] = -(right + left) / (right - left);
            result.data[1][3] = -(top + bottom) / (top - bottom);
            result.data[2][3] = -near / (far - near);
            return result;
        }

        // ============================================
        // View Matrices
        // ============================================

        /// Create look-at view matrix (right-handed)
        pub fn lookAt(eye: Vector(T, 3), target: Vector(T, 3), up: Vector(T, 3)) Self {
            if (M != 4 or N != 4) @compileError("lookAt requires 4x4 matrix");
            if (isInt) @compileError("lookAt requires floating point matrix");
            const f = target.subbed(eye).normalized();
            const s = f.cross(up).normalized();
            const u = s.cross(f);

            var result = Self.identity();
            result.data[0][0] = s.data[0];
            result.data[0][1] = s.data[1];
            result.data[0][2] = s.data[2];
            result.data[1][0] = u.data[0];
            result.data[1][1] = u.data[1];
            result.data[1][2] = u.data[2];
            result.data[2][0] = -f.data[0];
            result.data[2][1] = -f.data[1];
            result.data[2][2] = -f.data[2];
            result.data[0][3] = -s.dot(eye);
            result.data[1][3] = -u.dot(eye);
            result.data[2][3] = f.dot(eye);
            return result;
        }

        /// Create look-at view matrix (left-handed)
        pub fn lookAtLH(eye: Vector(T, 3), target: Vector(T, 3), up: Vector(T, 3)) Self {
            if (M != 4 or N != 4) @compileError("lookAt requires 4x4 matrix");
            if (isInt) @compileError("lookAt requires floating point matrix");
            const f = target.subbed(eye).normalized();
            const s = up.cross(f).normalized();
            const u = f.cross(s);

            var result = Self.identity();
            result.data[0][0] = s.data[0];
            result.data[0][1] = s.data[1];
            result.data[0][2] = s.data[2];
            result.data[1][0] = u.data[0];
            result.data[1][1] = u.data[1];
            result.data[1][2] = u.data[2];
            result.data[2][0] = f.data[0];
            result.data[2][1] = f.data[1];
            result.data[2][2] = f.data[2];
            result.data[0][3] = -s.dot(eye);
            result.data[1][3] = -u.dot(eye);
            result.data[2][3] = -f.dot(eye);
            return result;
        }

        // ============================================
        // Transform Decomposition & Composition
        // ============================================

        /// Compose TRS (Translation * Rotation * Scale) matrix
        pub fn compose(trans: Vector(T, 3), rot: Vector(T, 4), scl: Vector(T, 3)) Self {
            if (M != 4 or N != 4) @compileError("compose requires 4x4 matrix");
            var result = fromQuaternion(rot);
            // Apply scale
            result.data[0][0] *= scl.data[0];
            result.data[0][1] *= scl.data[0];
            result.data[0][2] *= scl.data[0];
            result.data[1][0] *= scl.data[1];
            result.data[1][1] *= scl.data[1];
            result.data[1][2] *= scl.data[1];
            result.data[2][0] *= scl.data[2];
            result.data[2][1] *= scl.data[2];
            result.data[2][2] *= scl.data[2];
            // Apply translation
            result.data[0][3] = trans.data[0];
            result.data[1][3] = trans.data[1];
            result.data[2][3] = trans.data[2];
            return result;
        }

        /// Decompose matrix into Translation, Rotation (quaternion), Scale
        pub fn decompose(self: *const Self) struct { translation: Vector(T, 3), rotation: Vector(T, 4), scale: Vector(T, 3) } {
            if (M != 4 or N != 4) @compileError("decompose requires 4x4 matrix");
            if (isInt) @compileError("decompose requires floating point matrix");
            const m = self.data;

            // Extract translation
            const trans = Vector(T, 3).from(.{ m[0][3], m[1][3], m[2][3] });

            // Extract scale
            const sx = @sqrt(m[0][0] * m[0][0] + m[1][0] * m[1][0] + m[2][0] * m[2][0]);
            const sy = @sqrt(m[0][1] * m[0][1] + m[1][1] * m[1][1] + m[2][1] * m[2][1]);
            const sz = @sqrt(m[0][2] * m[0][2] + m[1][2] * m[1][2] + m[2][2] * m[2][2]);
            const scl = Vector(T, 3).from(.{ sx, sy, sz });

            // Extract rotation (remove scale from rotation matrix)
            var rot_mat = Self.identity();
            if (sx != 0) {
                rot_mat.data[0][0] = m[0][0] / sx;
                rot_mat.data[1][0] = m[1][0] / sx;
                rot_mat.data[2][0] = m[2][0] / sx;
            }
            if (sy != 0) {
                rot_mat.data[0][1] = m[0][1] / sy;
                rot_mat.data[1][1] = m[1][1] / sy;
                rot_mat.data[2][1] = m[2][1] / sy;
            }
            if (sz != 0) {
                rot_mat.data[0][2] = m[0][2] / sz;
                rot_mat.data[1][2] = m[1][2] / sz;
                rot_mat.data[2][2] = m[2][2] / sz;
            }
            const rot = rot_mat.toQuaternion();

            return .{ .translation = trans, .rotation = rot, .scale = scl };
        }

        /// Get translation component from 4x4 matrix
        pub fn getTranslation(self: *const Self) Vector(T, 3) {
            if (M != 4 or N != 4) @compileError("getTranslation requires 4x4 matrix");
            return Vector(T, 3).from(.{ self.data[0][3], self.data[1][3], self.data[2][3] });
        }

        /// Set translation component in 4x4 matrix
        pub fn setTranslation(self: *Self, trans: Vector(T, 3)) *Self {
            if (M != 4 or N != 4) @compileError("setTranslation requires 4x4 matrix");
            self.data[0][3] = trans.data[0];
            self.data[1][3] = trans.data[1];
            self.data[2][3] = trans.data[2];
            return self;
        }

        /// Get scale component from 4x4 matrix
        pub fn getScale(self: *const Self) Vector(T, 3) {
            if (M != 4 or N != 4) @compileError("getScale requires 4x4 matrix");
            const m = self.data;
            const sx = @sqrt(m[0][0] * m[0][0] + m[1][0] * m[1][0] + m[2][0] * m[2][0]);
            const sy = @sqrt(m[0][1] * m[0][1] + m[1][1] * m[1][1] + m[2][1] * m[2][1]);
            const sz = @sqrt(m[0][2] * m[0][2] + m[1][2] * m[1][2] + m[2][2] * m[2][2]);
            return Vector(T, 3).from(.{ sx, sy, sz });
        }

        /// Get the upper-left 3x3 rotation/scale submatrix
        pub fn getBasis(self: *const Self) Matrix(T, 3, 3) {
            if (M != 4 or N != 4) @compileError("getBasis requires 4x4 matrix");
            var result: Matrix(T, 3, 3) = undefined;
            for (0..3) |i| {
                for (0..3) |j| {
                    result.data[i][j] = self.data[i][j];
                }
            }
            return result;
        }

        /// Set the upper-left 3x3 basis from a 3x3 matrix
        pub fn setBasis(self: *Self, basis: Matrix(T, 3, 3)) *Self {
            if (M != 4 or N != 4) @compileError("setBasis requires 4x4 matrix");
            for (0..3) |i| {
                for (0..3) |j| {
                    self.data[i][j] = basis.data[i][j];
                }
            }
            return self;
        }

        // ============================================
        // Transform Application
        // ============================================

        /// Transform a 3D point (applies full transform including translation)
        pub fn transformPoint(self: *const Self, point: Vector(T, 3)) Vector(T, 3) {
            if (M != 4 or N != 4) @compileError("transformPoint requires 4x4 matrix");
            const m = self.data;
            const x = point.data[0];
            const y = point.data[1];
            const z = point.data[2];
            const w = m[3][0] * x + m[3][1] * y + m[3][2] * z + m[3][3];
            const inv_w = if (w != 0) 1 / w else 1;
            return Vector(T, 3).from(.{
                (m[0][0] * x + m[0][1] * y + m[0][2] * z + m[0][3]) * inv_w,
                (m[1][0] * x + m[1][1] * y + m[1][2] * z + m[1][3]) * inv_w,
                (m[2][0] * x + m[2][1] * y + m[2][2] * z + m[2][3]) * inv_w,
            });
        }

        /// Transform a 3D direction (ignores translation)
        pub fn transformDirection(self: *const Self, dir: Vector(T, 3)) Vector(T, 3) {
            if (M != 4 or N != 4) @compileError("transformDirection requires 4x4 matrix");
            const m = self.data;
            const x = dir.data[0];
            const y = dir.data[1];
            const z = dir.data[2];
            return Vector(T, 3).from(.{
                m[0][0] * x + m[0][1] * y + m[0][2] * z,
                m[1][0] * x + m[1][1] * y + m[1][2] * z,
                m[2][0] * x + m[2][1] * y + m[2][2] * z,
            });
        }

        /// Transform a normal vector (uses inverse transpose)
        pub fn transformNormal(self: *const Self, normal: Vector(T, 3)) !Vector(T, 3) {
            if (M != 4 or N != 4) @compileError("transformNormal requires 4x4 matrix");
            const inv = try self.inverse();
            const m = inv.transpose().data;
            const x = normal.data[0];
            const y = normal.data[1];
            const z = normal.data[2];
            return Vector(T, 3).from(.{
                m[0][0] * x + m[0][1] * y + m[0][2] * z,
                m[1][0] * x + m[1][1] * y + m[1][2] * z,
                m[2][0] * x + m[2][1] * y + m[2][2] * z,
            }).normalized();
        }

        /// Transform a 4D vector (homogeneous coordinates)
        pub fn transformVec4(self: *const Self, vec: Vector(T, 4)) Vector(T, 4) {
            if (M != 4 or N != 4) @compileError("transformVec4 requires 4x4 matrix");
            return self.mulVec(vec);
        }

        // ============================================
        // Matrix Norms & Properties
        // ============================================

        /// Frobenius norm (square root of sum of squares)
        pub fn frobeniusNorm(self: *const Self) T {
            if (isInt) @compileError("frobeniusNorm requires floating point matrix");
            var sum: T = 0;
            for (0..M) |i| {
                for (0..N) |j| {
                    sum += self.data[i][j] * self.data[i][j];
                }
            }
            return @sqrt(sum);
        }

        /// Infinity norm (maximum absolute row sum)
        pub fn infinityNorm(self: *const Self) T {
            var max_sum: T = 0;
            for (0..M) |i| {
                var row_sum: T = 0;
                for (0..N) |j| {
                    row_sum += if (self.data[i][j] < 0) -self.data[i][j] else self.data[i][j];
                }
                if (row_sum > max_sum) max_sum = row_sum;
            }
            return max_sum;
        }

        /// One norm (maximum absolute column sum)
        pub fn oneNorm(self: *const Self) T {
            var max_sum: T = 0;
            for (0..N) |j| {
                var col_sum: T = 0;
                for (0..M) |i| {
                    col_sum += if (self.data[i][j] < 0) -self.data[i][j] else self.data[i][j];
                }
                if (col_sum > max_sum) max_sum = col_sum;
            }
            return max_sum;
        }

        /// Sum of all elements
        pub fn sum(self: *const Self) T {
            var total: T = 0;
            for (0..M) |i| {
                for (0..N) |j| {
                    total += self.data[i][j];
                }
            }
            return total;
        }

        /// Maximum element
        pub fn max(self: *const Self) T {
            var max_val: T = self.data[0][0];
            for (0..M) |i| {
                for (0..N) |j| {
                    if (self.data[i][j] > max_val) max_val = self.data[i][j];
                }
            }
            return max_val;
        }

        /// Minimum element
        pub fn min(self: *const Self) T {
            var min_val: T = self.data[0][0];
            for (0..M) |i| {
                for (0..N) |j| {
                    if (self.data[i][j] < min_val) min_val = self.data[i][j];
                }
            }
            return min_val;
        }

        // ============================================
        // Element-wise Operations
        // ============================================

        /// Element-wise absolute value (in-place)
        pub fn abs(self: *Self) *Self {
            for (0..M) |i| {
                for (0..N) |j| {
                    if (self.data[i][j] < 0) self.data[i][j] = -self.data[i][j];
                }
            }
            return self;
        }

        /// Element-wise absolute value (new matrix)
        pub fn absed(self: *const Self) Self {
            return self.clone().ptr().abs().*;
        }

        /// Element-wise floor (in-place)
        pub fn floor(self: *Self) *Self {
            if (isInt) return self;
            for (0..M) |i| {
                for (0..N) |j| {
                    self.data[i][j] = @floor(self.data[i][j]);
                }
            }
            return self;
        }

        /// Element-wise floor (new matrix)
        pub fn floored(self: *const Self) Self {
            return self.clone().ptr().floor().*;
        }

        /// Element-wise ceil (in-place)
        pub fn ceil(self: *Self) *Self {
            if (isInt) return self;
            for (0..M) |i| {
                for (0..N) |j| {
                    self.data[i][j] = @ceil(self.data[i][j]);
                }
            }
            return self;
        }

        /// Element-wise ceil (new matrix)
        pub fn ceiled(self: *const Self) Self {
            return self.clone().ptr().ceil().*;
        }

        // ============================================
        // Helper Functions (add these near the top after existing helpers)
        // ============================================

        fn scalarFrom(comptime VT: type, value: VT) T {
            return switch (@typeInfo(VT)) {
                .int, .comptime_int => @floatFromInt(value),
                .float, .comptime_float => @floatCast(value),
                else => value,
            };
        }

        fn matrixFromAny(value: anytype) Self {
            const VT = @TypeOf(value);
            if (VT == Self) return value;
            if (@typeInfo(VT) == .int or @typeInfo(VT) == .float or
                @typeInfo(VT) == .comptime_int or @typeInfo(VT) == .comptime_float)
            {
                return Self.from(value);
            }
            return value;
        }

        fn getOtherCols(comptime OT: type) u16 {
            if (@hasField(OT, "cols")) return OT.cols;
            return N; // Default to square multiplication
        }

        // ============================================
        // Row Operations (Gaussian Elimination support)
        // ============================================

        /// Swap two rows (in-place)
        pub fn swapRows(self: *Self, i: usize, j: usize) *Self {
            if (i == j) return self;
            const temp = self.data[i];
            self.data[i] = self.data[j];
            self.data[j] = temp;
            return self;
        }

        /// Swap two columns (in-place)
        pub fn swapCols(self: *Self, i: usize, j: usize) *Self {
            if (i == j) return self;
            for (0..M) |row| {
                const temp = self.data[row][i];
                self.data[row][i] = self.data[row][j];
                self.data[row][j] = temp;
            }
            return self;
        }

        /// Scale a row by a scalar (in-place)
        pub fn scaleRow(self: *Self, i: usize, scalar_: T) *Self {
            const sv: V = @splat(scalar_);
            const row_v: V = self.data[i];
            self.data[i] = row_v * sv;
            return self;
        }

        /// Add scaled row j to row i (in-place): row[i] += scalar * row[j]
        pub fn addScaledRow(self: *Self, i: usize, j: usize, scalar_: T) *Self {
            const sv: V = @splat(scalar_);
            const row_i: V = self.data[i];
            const row_j: V = self.data[j];
            self.data[i] = row_i + row_j * sv;
            return self;
        }

        // ============================================
        // Matrix Decomposition
        // ============================================

        /// LU Decomposition (Doolittle algorithm)
        /// Returns L (lower triangular) and U (upper triangular) where A = L * U
        pub fn lu(self: *const Self) !struct { L: Self, U: Self } {
            if (!isSquare) @compileError("LU decomposition requires square matrix");

            var L = Self.identity();
            var U = self.clone();

            for (0..M) |i| {
                // Check for zero pivot
                if (U.data[i][i] == 0) return MError.SingularMatrix;

                for (i + 1..M) |j| {
                    const factor = U.data[j][i] / U.data[i][i];
                    L.data[j][i] = factor;
                    for (i..N) |k| {
                        U.data[j][k] -= factor * U.data[i][k];
                    }
                }
            }
            return .{ .L = L, .U = U };
        }

        /// LU Decomposition with partial pivoting
        /// Returns L, U, and P (permutation matrix) where P * A = L * U
        pub fn luPivot(self: *const Self) !struct { L: Self, U: Self, P: Self, pivots: usize } {
            if (!isSquare) @compileError("LU decomposition requires square matrix");

            var L = Self.zero();
            var U = self.clone();
            var P = Self.identity();
            var pivots: usize = 0;

            for (0..M) |i| {
                // Find pivot
                var max_val: T = if (U.data[i][i] < 0) -U.data[i][i] else U.data[i][i];
                var max_row: usize = i;
                for (i + 1..M) |j| {
                    const abs_val: T = if (U.data[j][i] < 0) -U.data[j][i] else U.data[j][i];
                    if (abs_val > max_val) {
                        max_val = abs_val;
                        max_row = j;
                    }
                }

                if (max_val == 0) return MError.SingularMatrix;

                // Swap rows if needed
                if (max_row != i) {
                    _ = U.swapRows(i, max_row);
                    _ = P.swapRows(i, max_row);
                    // Swap L's already computed elements
                    for (0..i) |k| {
                        const temp = L.data[i][k];
                        L.data[i][k] = L.data[max_row][k];
                        L.data[max_row][k] = temp;
                    }
                    pivots += 1;
                }

                L.data[i][i] = 1;
                for (i + 1..M) |j| {
                    const factor = U.data[j][i] / U.data[i][i];
                    L.data[j][i] = factor;
                    for (i..N) |k| {
                        U.data[j][k] -= factor * U.data[i][k];
                    }
                }
            }
            return .{ .L = L, .U = U, .P = P, .pivots = pivots };
        }

        /// QR Decomposition (Gram-Schmidt orthogonalization)
        /// Returns Q (orthogonal) and R (upper triangular) where A = Q * R
        pub fn qr(self: *const Self) struct { Q: Self, R: Self } {
            if (!isSquare) @compileError("QR decomposition requires square matrix");
            if (isInt) @compileError("QR decomposition requires floating point matrix");

            var Q = Self.zero();
            var R = Self.zero();

            for (0..N) |j| {
                // Get column j
                var v: [M]T = undefined;
                for (0..M) |i| {
                    v[i] = self.data[i][j];
                }

                // Subtract projections onto previous Q columns
                for (0..j) |k| {
                    var dot: T = 0;
                    for (0..M) |i| {
                        dot += self.data[i][j] * Q.data[i][k];
                    }
                    R.data[k][j] = dot;
                    for (0..M) |i| {
                        v[i] -= dot * Q.data[i][k];
                    }
                }

                // Normalize
                var norm: T = 0;
                for (0..M) |i| {
                    norm += v[i] * v[i];
                }
                norm = @sqrt(norm);
                R.data[j][j] = norm;

                if (norm != 0) {
                    for (0..M) |i| {
                        Q.data[i][j] = v[i] / norm;
                    }
                }
            }
            return .{ .Q = Q, .R = R };
        }

        /// Cholesky Decomposition (for symmetric positive-definite matrices)
        /// Returns L (lower triangular) where A = L * L^T
        pub fn cholesky(self: *const Self) !Self {
            if (!isSquare) @compileError("Cholesky decomposition requires square matrix");
            if (isInt) @compileError("Cholesky decomposition requires floating point matrix");

            var L = Self.zero();

            for (0..M) |i| {
                for (0..i + 1) |j| {
                    var sum: T = 0;
                    if (j == i) {
                        for (0..j) |k| {
                            sum += L.data[j][k] * L.data[j][k];
                        }
                        const diff = self.data[j][j] - sum;
                        if (diff <= 0) return MError.SingularMatrix; // Not positive definite
                        L.data[j][j] = @sqrt(diff);
                    } else {
                        for (0..j) |k| {
                            sum += L.data[i][k] * L.data[j][k];
                        }
                        if (L.data[j][j] == 0) return MError.SingularMatrix;
                        L.data[i][j] = (self.data[i][j] - sum) / L.data[j][j];
                    }
                }
            }
            return L;
        }

        // ============================================
        // Linear System Solvers
        // ============================================

        /// Solve Ax = b using LU decomposition
        pub fn solve(self: *const Self, b: ColVec) !ColVec {
            if (!isSquare) @compileError("solve requires square matrix");

            const decomp = try self.luPivot();

            // Apply permutation to b: Pb
            var pb: [M]T = undefined;
            for (0..M) |i| {
                var sum: T = 0;
                for (0..M) |j| {
                    sum += decomp.P.data[i][j] * b.data[j];
                }
                pb[i] = sum;
            }

            // Forward substitution: Ly = Pb
            var y: [M]T = undefined;
            for (0..M) |i| {
                var sum: T = 0;
                for (0..i) |j| {
                    sum += decomp.L.data[i][j] * y[j];
                }
                y[i] = pb[i] - sum;
            }

            // Back substitution: Ux = y
            var x: [M]T = undefined;
            var i: usize = M;
            while (i > 0) {
                i -= 1;
                var sum: T = 0;
                for (i + 1..M) |j| {
                    sum += decomp.U.data[i][j] * x[j];
                }
                if (decomp.U.data[i][i] == 0) return MError.SingularMatrix;
                x[i] = (y[i] - sum) / decomp.U.data[i][i];
            }

            return ColVec.from(x);
        }

        /// Solve multiple systems AX = B where B is a matrix
        pub fn solveMatrix(self: *const Self, B: Self) !Self {
            if (!isSquare) @compileError("solveMatrix requires square matrix");

            var result: Self = undefined;
            for (0..N) |j| {
                const b_col = B.col(j);
                const x_col = try self.solve(b_col);
                _ = result.setCol(j, x_col);
            }
            return result;
        }

        // ============================================
        // Eigenvalue Related (Power Iteration for dominant eigenvalue)
        // ============================================

        /// Compute dominant eigenvalue and eigenvector using power iteration
        pub fn powerIteration(self: *const Self, max_iterations: usize, tolerance: T) struct { eigenvalue: T, eigenvector: ColVec } {
            if (!isSquare) @compileError("Power iteration requires square matrix");
            if (isInt) @compileError("Power iteration requires floating point matrix");

            // Start with random-ish vector
            var v: ColVec = undefined;
            for (0..M) |i| {
                v.data[i] = 1;
            }
            v = v.normalized();

            var eigenvalue: T = 0;

            for (0..max_iterations) |_| {
                const Av = self.mulVec(v);
                const new_eigenvalue = v.dot(Av);

                const norm = Av.length();
                if (norm == 0) break;
                const new_v = Av.scaled(1 / norm);

                const diff = if (new_eigenvalue > eigenvalue)
                    new_eigenvalue - eigenvalue
                else
                    eigenvalue - new_eigenvalue;

                eigenvalue = new_eigenvalue;
                v = new_v;

                if (diff < tolerance) break;
            }

            return .{ .eigenvalue = eigenvalue, .eigenvector = v };
        }

        // ============================================
        // Rank and Null Space
        // ============================================

        /// Compute matrix rank using row echelon form
        pub fn rank(self: *const Self) usize {
            var m = self.clone();
            const tol: T = if (@typeInfo(T) == .float) std.math.floatEps(T) * 100 else 0;
            var r: usize = 0;
            var lead: usize = 0;

            for (0..M) |row| {
                if (lead >= N) break;

                var i = row;
                while (m.data[i][lead] == 0 or
                    (if (m.data[i][lead] < 0) -m.data[i][lead] else m.data[i][lead]) < tol)
                {
                    i += 1;
                    if (i == M) {
                        i = row;
                        lead += 1;
                        if (lead == N) return r;
                    }
                }

                _ = m.swapRows(i, row);

                if (m.data[row][lead] != 0) {
                    const div = m.data[row][lead];
                    for (0..N) |j| {
                        m.data[row][j] /= div;
                    }
                }

                for (0..M) |j| {
                    if (j != row) {
                        const mult = m.data[j][lead];
                        for (0..N) |k| {
                            m.data[j][k] -= mult * m.data[row][k];
                        }
                    }
                }

                lead += 1;
                r += 1;
            }

            return r;
        }

        /// Check if matrix is full rank
        pub fn isFullRank(self: *const Self) bool {
            return self.rank() == @min(M, N);
        }
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
