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

pub const Shader = struct {
    ID: gl.Uint,

    pub fn init(vertexPath: []const u8, fragmentPath: []const u8, allocator: Allocator) !Shader {
        var vertexCode: []u8 = undefined;
        var fragmentCode: []u8 = undefined;

        const vertexFile = try std.fs.cwd().openFile(vertexPath, .{});
        const fragmentFile = try std.fs.cwd().openFile(fragmentPath, .{});
        defer vertexFile.close();
        defer fragmentFile.close();

        const vertexFileSize = (try vertexFile.stat()).size;
        const fragmentFileSize = (try fragmentFile.stat()).size;

        vertexCode = try allocator.alloc(u8, vertexFileSize);
        fragmentCode = try allocator.alloc(u8, fragmentFileSize);
        defer allocator.free(vertexCode);
        defer allocator.free(fragmentCode);

        const vCount: usize = try vertexFile.readAll(vertexCode);
        const fCount: usize = try fragmentFile.readAll(fragmentCode);

        if (vCount != vertexFileSize or fCount != fragmentFileSize) {
            std.debug.print("ERROR::SHADER::FILE_NOT_SUCCESSFULLY_READ\n", .{});
        }

        var success: gl.Int = 0;
        var infoLog: [512]u8 = undefined;

        // create vertex shader
        var vertexShader: gl.Uint = undefined;
        vertexShader = gl.createShader(gl.VERTEX_SHADER);

        gl.shaderSource(vertexShader, 1, &@as([*c]u8, @ptrCast(vertexCode)), null);
        gl.compileShader(vertexShader);

        gl.getShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            gl.getShaderInfoLog(vertexShader, 512, null, &infoLog[0]);
            std.debug.print("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n", .{infoLog[0..]});
        }

        // create fragment shader
        var fragmentShader: gl.Uint = undefined;
        fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragmentShader, 1, &@as([*c]u8, @ptrCast(fragmentCode)), null);
        gl.compileShader(fragmentShader);

        gl.getShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            gl.getShaderInfoLog(fragmentShader, 512, null, &infoLog[0]);
            std.debug.print("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n", .{infoLog[0..]});
        }

        // create shader program
        const shaderProgram: gl.Uint = gl.createProgram();
        gl.attachShader(shaderProgram, vertexShader);
        gl.attachShader(shaderProgram, fragmentShader);
        gl.linkProgram(shaderProgram);

        gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
        if (success == 0) {
            gl.getProgramInfoLog(shaderProgram, 512, null, &infoLog[0]);
            std.debug.print("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}\n", .{infoLog[0..]});
        }

        gl.deleteShader(vertexShader);
        gl.deleteShader(fragmentShader);

        return .{ .ID = shaderProgram };
    }

    pub fn use(self: *Shader) void {
        gl.useProgram(self.ID);
    }

    pub fn deinit(self: *Shader) void {
        gl.deleteProgram(self.ID);
    }

    pub fn setBool(self: *Shader, name: [*c]const u8, value: bool) void {
        gl.uniform1i(gl.getUniformLocation(self.ID, name), if (value) 1 else 0);
    }

    pub fn setInt(self: *Shader, name: [*c]const u8, value: gl.Int) void {
        gl.uniform1i(gl.getUniformLocation(self.ID, name), value);
    }

    pub fn setFloat(self: *Shader, name: [*c]const u8, value: f32) void {
        gl.uniform1f(gl.getUniformLocation(self.ID, name), value);
    }

    pub fn setFloat4(self: *Shader, name: [*c]const u8, v0: f32, v1: f32, v2: f32, v3: f32) void {
        gl.uniform4f(gl.getUniformLocation(self.ID, name), v0, v1, v2, v3);
    }
};

const std = @import("std");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const Allocator = std.mem.Allocator;
