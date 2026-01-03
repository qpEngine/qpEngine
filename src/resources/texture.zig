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

var wrap_s: gl.Int = gl.REPEAT;
var wrap_t: gl.Int = gl.REPEAT;
var min_filter: gl.Int = gl.LINEAR_MIPMAP_LINEAR;
var mag_filter: gl.Int = gl.LINEAR;

pub const Texture = struct {
    ID: gl.Uint,
    type: []const u8,
    path: []const u8,

    pub fn init(path: [:0]const u8, hasAlpha: bool) !Texture {
        var texture: Texture = undefined;
        gl.genTextures(1, &texture.ID);
        gl.bindTexture(gl.TEXTURE_2D, texture.ID);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrap_s);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrap_t);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, min_filter);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, mag_filter);

        var image: stbi.Image = stbi.Image.loadFromFile(path, 0) catch |err| {
            std.debug.print("Failed to load texture\n{s}\n{any}\n", .{ path, err });
            return err;
        };
        gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RGB,
            @as(gl.Int, @intCast(image.width)),
            @as(gl.Int, @intCast(image.height)),
            0,
            if (hasAlpha) gl.RGBA else gl.RGB,
            gl.UNSIGNED_BYTE,
            @as(?*anyopaque, @ptrCast(image.data)),
        );
        gl.generateMipmap(gl.TEXTURE_2D);
        image.deinit();

        return texture;
    }

    pub fn setParams(s: gl.Int, t: gl.Int, min: gl.Int, mag: gl.Int) void {
        wrap_s = s;
        wrap_t = t;
        min_filter = min;
        mag_filter = mag;
    }
};

const std = @import("std");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const stbi = @import("zstbi");

const Allocator = std.mem.Allocator;
