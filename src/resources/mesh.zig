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

const _MAX_BONE_INFLUENCE = 4;

pub const Vertex = struct {
    position: Vec3,
    normal: Vec3,
    tex_coords: Vec2,
    tangent: Vec3,
    bitangent: Vec3,
    bone_ids: [_MAX_BONE_INFLUENCE]GL_.Int,
    weights: [_MAX_BONE_INFLUENCE]GL_.Float,
};

pub const Mesh = struct {
    vertices: AList(Vertex),
    indices: AList(GL_.Uint),
    textures: AList(Texture),
    VAO: GL_.Uint,
    VBO: GL_.Uint,
    EBO: GL_.Uint,

    pub fn init(vertices_: AList(Vertex), indices_: AList(GL_.Uint), textures_: AList(Texture)) Mesh {
        var mesh = Mesh{
            .vertices = vertices_,
            .indices = indices_,
            .textures = textures_,
            .VAO = undefined,
            .VBO = undefined,
            .EBO = undefined,
        };

        mesh.setupMesh();
        return mesh;
    }

    pub fn deinit(self: *Mesh) void {
        const allocator = Std_.heap.page_allocator;
        self.vertices.deinit(allocator);
        self.indices.deinit(allocator);
        self.textures.deinit(allocator);

        GL_.deleteVertexArrays(1, &self.VAO);
        GL_.deleteBuffers(1, &self.VBO);
        GL_.deleteBuffers(1, &self.EBO);
    }

    pub fn draw(self: *const Mesh, shader: *const Shader) void {
        var diffuse_nr: u32 = 1;
        var specular_nr: u32 = 1;
        var normal_nr: u32 = 1;
        var height_nr: u32 = 1;

        for (self.textures.items, 0..) |texture, i| {
            GL_.activeTexture(GL_.TEXTURE0 + @as(GL_.Uint, @intCast(i)));

            var number: u32 = 0;
            const name = texture.type;
            if (Std_.mem.eql(u8, name, "texture_diffuse")) {
                number = diffuse_nr;
                diffuse_nr += 1;
            } else if (Std_.mem.eql(u8, name, "texture_specular")) {
                number = specular_nr;
                specular_nr += 1;
            } else if (Std_.mem.eql(u8, name, "texture_normal")) {
                number = normal_nr;
                normal_nr += 1;
            } else if (Std_.mem.eql(u8, name, "texture_height")) {
                number = height_nr;
                height_nr += 1;
            }
            var uniform_name: [64]u8 = undefined;
            const temp = Std_.fmt.bufPrint(&uniform_name, "{s}{d}\x00", .{ name, number }) catch unreachable;
            GL_.uniform1i(
                GL_.getUniformLocation(shader.ID, uniform_name[0 .. temp.len - 1 :0]),
                @as(GL_.Int, @intCast(i)),
            );
            GL_.bindTexture(GL_.TEXTURE_2D, texture.ID);
        }

        GL_.bindVertexArray(self.VAO);
        GL_.drawElements(
            GL_.TRIANGLES,
            @as(GL_.Int, @intCast(self.indices.items.len)),
            GL_.UNSIGNED_INT,
            @as(?*anyopaque, null),
        );
        GL_.bindVertexArray(0);

        GL_.activeTexture(GL_.TEXTURE0);
    }

    fn setupMesh(self: *Mesh) void {
        GL_.genVertexArrays(1, &self.VAO);
        GL_.genBuffers(1, &self.VBO);
        GL_.genBuffers(1, &self.EBO);

        GL_.bindVertexArray(self.VAO);

        GL_.bindBuffer(GL_.ARRAY_BUFFER, self.VBO);
        GL_.bufferData(
            GL_.ARRAY_BUFFER,
            @as(GL_.Sizeiptr, @intCast(self.vertices.items.len * @sizeOf(Vertex))),
            @as(?*anyopaque, self.vertices.items.ptr),
            GL_.STATIC_DRAW,
        );

        GL_.bindBuffer(GL_.ELEMENT_ARRAY_BUFFER, self.EBO);
        GL_.bufferData(
            GL_.ELEMENT_ARRAY_BUFFER,
            @as(GL_.Sizeiptr, @intCast(self.indices.items.len * @sizeOf(GL_.Uint))),
            @as(?*anyopaque, self.indices.items.ptr),
            GL_.STATIC_DRAW,
        );

        const stride = @sizeOf(Vertex);

        // vertex positions
        GL_.enableVertexAttribArray(0);
        GL_.vertexAttribPointer(0, 3, GL_.FLOAT, GL_.FALSE, @as(GL_.Int, stride), @as(?*anyopaque, null));

        // vertex normals
        GL_.enableVertexAttribArray(1);
        GL_.vertexAttribPointer(1, 3, GL_.FLOAT, GL_.FALSE, @as(GL_.Int, stride), @as(?*anyopaque, @ptrFromInt(@offsetOf(Vertex, "normal"))));

        // vertex texture coords
        GL_.enableVertexAttribArray(2);
        GL_.vertexAttribPointer(2, 2, GL_.FLOAT, GL_.FALSE, @as(GL_.Int, stride), @as(?*anyopaque, @ptrFromInt(@offsetOf(Vertex, "tex_coords"))));

        // vertex tangent
        GL_.enableVertexAttribArray(3);
        GL_.vertexAttribPointer(3, 3, GL_.FLOAT, GL_.FALSE, @as(GL_.Int, stride), @as(?*anyopaque, @ptrFromInt(@offsetOf(Vertex, "tangent"))));

        // vertex bitangent
        GL_.enableVertexAttribArray(4);
        GL_.vertexAttribPointer(4, 3, GL_.FLOAT, GL_.FALSE, @as(GL_.Int, stride), @as(?*anyopaque, @ptrFromInt(@offsetOf(Vertex, "bitangent"))));

        // bone IDs
        GL_.enableVertexAttribArray(5);
        GL_.vertexAttribIPointer(5, _MAX_BONE_INFLUENCE, GL_.INT, @as(GL_.Int, stride), @as(?*anyopaque, @ptrFromInt(@offsetOf(Vertex, "bone_ids"))));

        // weights
        GL_.enableVertexAttribArray(6);
        GL_.vertexAttribPointer(6, _MAX_BONE_INFLUENCE, GL_.FLOAT, GL_.FALSE, @as(GL_.Int, stride), @as(?*anyopaque, @ptrFromInt(@offsetOf(Vertex, "weights"))));

        GL_.bindVertexArray(0);
    }
};

const Std_ = @import("std");
const QP_ = @import("qp");
const Zopengl_ = @import("zopengl");
const GL_ = Zopengl_.bindings;
const Stbi_ = @import("zstbi");

const Texture = @import("texture.zig").Texture;
const Shader = @import("shader.zig").Shader;

const AList = Std_.ArrayList;
const Vec3 = QP_.math.Vector(f32, 3);
const Vec2 = QP_.math.Vector(f32, 2);
