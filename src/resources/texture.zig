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

pub const Texture = struct {
    ID: gl.Uint,

    pub fn init(path: [:0]const u8, hasAlpha: bool) !Texture {
        var texture: Texture = undefined;
        gl.genTextures(1, &texture.ID);
        gl.bindTexture(gl.TEXTURE_2D, texture.ID);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

        var image: stbi.Image = stbi.Image.loadFromFile(path, 0) catch |err| {
            std.debug.print("Failed to load texture\n{any}\n", .{err});
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
};

const std = @import("std");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const stbi = @import("zstbi");

const Allocator = std.mem.Allocator;
