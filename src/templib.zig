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

pub fn createVAO() gl.Uint {
    var VAO: gl.Uint = undefined;
    gl.genVertexArrays(1, &VAO);
    gl.bindVertexArray(VAO);

    return VAO;
}

pub fn createVBO(vertices: []const f32) gl.Uint {
    var VBO: gl.Uint = undefined;
    gl.genBuffers(1, &VBO);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.bufferData(gl.ARRAY_BUFFER, @as(isize, @intCast(vertices.len)) * @sizeOf(f32), &vertices[0], gl.STATIC_DRAW);
    // gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    return VBO;
}

pub fn createEBO(indices: []const u32) gl.Uint {
    var EBO: gl.Uint = undefined;
    gl.genBuffers(1, &EBO);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @as(isize, @intCast(indices.len)) * @sizeOf(u32), &indices[0], gl.STATIC_DRAW);
    // gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    return EBO;
}

const std = @import("std");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;
