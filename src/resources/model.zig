pub const Model = struct {
    textures_loaded: AList(Texture),
    meshes: AList(Mesh),
    directory: []const u8,
    gamma_correction: bool,

    pub fn init(path_: [:0]const u8, gamma_: bool) !Model {
        var model = Model{
            .meshes = .empty,
            .textures_loaded = .empty,
            .directory = undefined,
            .gamma_correction = gamma_,
        };
        try model.loadModel(path_);
        return model;
    }

    pub fn deinit(self: *Model) void {
        const allocator = Std_.heap.page_allocator;

        for (self.meshes.items) |*mesh| {
            mesh.deinit();
        }
        self.meshes.deinit(allocator);

        // for (self.textures_loaded.items) |texture| {
        //     // Here you might want to delete the OpenGL texture if needed
        //     _ = texture;
        // }
        self.textures_loaded.deinit(allocator);
    }

    pub fn draw(self: *const Model, shader_: *const Shader) void {
        for (self.meshes.items) |mesh| {
            mesh.draw(shader_);
        }
    }

    fn loadModel(self: *Model, path_: [:0]const u8) !void {
        const allocator = Std_.heap.page_allocator;

        Mesh_.init(allocator);
        defer Mesh_.deinit();

        const data = try Mesh_.io.zcgltf.parseAndLoadFile(path_);
        defer Mesh_.io.zcgltf.freeData(data);

        self.directory = Std_.fs.path.dirname(path_).?;

        if (data.scene) |scene| {
            for (0..scene.nodes_count) |i| {
                const node = scene.nodes.?[i];
                self.processNode(node, data);
            }
        }
    }

    fn processNode(self: *Model, node_: *Mesh_.io.zcgltf.Node, data_: *Mesh_.io.zcgltf.Data) void {
        const allocator = Std_.heap.page_allocator;

        if (node_.mesh) |mesh| {
            const processedMesh = self.processMesh(mesh, data_);
            _ = self.meshes.append(allocator, processedMesh) catch unreachable;
        }

        for (0..node_.children_count) |i| {
            const child = node_.children.?[i];
            self.processNode(child, data_);
        }
    }

    fn processMesh(self: *Model, mesh_: *Mesh_.io.zcgltf.Mesh, data_: *Mesh_.io.zcgltf.Data) Mesh {
        const allocator = Std_.heap.page_allocator;

        var vertices: AList(Vertex) = .empty;
        // defer vertices.deinit(allocator);

        var indices: AList(GL_.Uint) = .empty;
        // defer indices.deinit(allocator);

        var textures: AList(Texture) = .empty;
        // defer textures.deinit(allocator);

        for (0..mesh_.primitives_count) |i| {
            const primitive = mesh_.primitives[i];

            // First, determine vertex count from POSITION attribute
            var vertex_count: usize = 0;
            var position_accessor: ?*Mesh_.io.zcgltf.Accessor = null;
            var normal_accessor: ?*Mesh_.io.zcgltf.Accessor = null;
            var texcoord_accessor: ?*Mesh_.io.zcgltf.Accessor = null;
            var tangent_accessor: ?*Mesh_.io.zcgltf.Accessor = null;

            for (0..primitive.attributes_count) |j| {
                const attribute = primitive.attributes[j];
                const name = Std_.mem.span(attribute.name.?);

                if (Std_.mem.eql(u8, name, "POSITION")) {
                    position_accessor = attribute.data;
                    vertex_count = attribute.data.count;
                } else if (Std_.mem.eql(u8, name, "NORMAL")) {
                    normal_accessor = attribute.data;
                } else if (Std_.mem.eql(u8, name, "TEXCOORD_0")) {
                    texcoord_accessor = attribute.data;
                } else if (Std_.mem.eql(u8, name, "TANGENT")) {
                    tangent_accessor = attribute.data;
                }
            }

            // Now build vertices with all attributes
            for (0..vertex_count) |k| {
                var vertex: Vertex = .{
                    .position = Vec3{ .data = .{ 0, 0, 0 } },
                    .normal = Vec3{ .data = .{ 0, 0, 0 } },
                    .tex_coords = .{ .data = .{ 0, 0 } }, // adjust type as needed
                    .tangent = Vec3{ .data = .{ 0, 0, 0 } },
                    .bitangent = Vec3{ .data = .{ 0, 0, 0 } },
                    .bone_ids = undefined,
                    .weights = undefined,
                };

                if (position_accessor) |acc| {
                    vertex.position = readFromAccessor([3]f32, acc, k);
                }
                if (normal_accessor) |acc| {
                    vertex.normal = readFromAccessor([3]f32, acc, k);
                }
                if (texcoord_accessor) |acc| {
                    vertex.tex_coords = readFromAccessor([2]f32, acc, k);
                }
                if (tangent_accessor) |acc| {
                    vertex.tangent = readFromAccessor([3]f32, acc, k);
                }

                _ = vertices.append(allocator, vertex) catch unreachable;
            }

            // Process indices
            if (primitive.indices) |p_indices| {
                const bufferView = p_indices.buffer_view.?;
                const buffer = bufferView.buffer;

                const dataPtr = @as(usize, @intFromPtr(buffer.data)) + bufferView.offset + p_indices.offset;
                const indexCount = p_indices.count;

                for (0..indexCount) |k| {
                    const indexDataPtr = dataPtr + k * @sizeOf(GL_.Uint);
                    const index = @as(*const GL_.Uint, @ptrFromInt(indexDataPtr)).*;
                    _ = indices.append(allocator, index) catch unreachable;
                }
            }

            // Process material and textures here
            if (primitive.material) |material| {
                const diffuse_texture = material.pbr_metallic_roughness.base_color_texture;
                if (diffuse_texture.texture) |tex| {
                    const texture = self.loadMaterialTexture(tex, data_, "texture_diffuse");
                    _ = textures.append(allocator, texture) catch unreachable;
                }

                const specular_texture = material.specular.specular_texture;
                if (specular_texture.texture) |tex| {
                    const texture = self.loadMaterialTexture(tex, data_, "texture_specular");
                    _ = textures.append(allocator, texture) catch unreachable;
                }

                const normal_texture = material.normal_texture;
                if (normal_texture.texture) |tex| {
                    const texture = self.loadMaterialTexture(tex, data_, "texture_normal");
                    _ = textures.append(allocator, texture) catch unreachable;
                }
            }
        }
        return Mesh.init(vertices, indices, textures);
    }

    fn loadMaterialTexture(self: *Model, tex_: *Mesh_.io.zcgltf.Texture, data_: *Mesh_.io.zcgltf.Data, type_: []const u8) Texture {
        const allocator = Std_.heap.page_allocator;
        _ = data_;
        const image = tex_.image.?;
        var texture_path: [:0]const u8 = Std_.mem.span(image.uri.?);
        var buffer: [1024]u8 = undefined;
        const temp = Std_.fmt.bufPrint(&buffer, "{s}/{s}\x00", .{ self.directory, texture_path }) catch unreachable;
        texture_path = buffer[0 .. temp.len - 1 :0];

        // Check if texture was loaded before
        for (self.textures_loaded.items) |loaded_texture| {
            if (Std_.mem.eql(u8, loaded_texture.path, texture_path)) {
                return loaded_texture;
            }
        }

        var new_texture = Texture.init(texture_path, false) catch unreachable;
        new_texture.type = type_;
        new_texture.path = texture_path;
        _ = self.textures_loaded.append(allocator, new_texture) catch unreachable;
        return new_texture;
    }
};
// [3]f32
fn readFromAccessor(T: type, accessor: *Mesh_.io.zcgltf.Accessor, index: usize) switch (T) {
    [2]f32 => Vec2,
    [3]f32 => Vec3,
    else => @compileError("Unsupported type"),
} {
    const bufferView = accessor.buffer_view.?;
    const buffer = bufferView.buffer;
    const stride = if (bufferView.stride != 0) bufferView.stride else @sizeOf(T);
    const dataPtr = @as([*]const u8, @ptrCast(buffer.data.?)) + bufferView.offset + accessor.offset + index * stride;
    const values = @as(*const T, @ptrCast(@alignCast(dataPtr))).*;
    return if (T == [3]f32) Vec3{ .data = values } else Vec2{ .data = values };
}

const Std_ = @import("std");
const QP_ = @import("qp");
const Fs_ = Std_.fs;
const Mem_ = Std_.mem;
const Mesh_ = @import("qp").mesh;
const Opengl_ = @import("zopengl");
const GL_ = Opengl_.bindings;

const Vertex = @import("mesh.zig").Vertex;
const Mesh = @import("mesh.zig").Mesh;
const Texture = @import("texture.zig").Texture;
const Shader = @import("shader.zig").Shader;

const AList = Std_.ArrayList;
const Vec3 = QP_.math.Vector(f32, 3);
const Vec2 = QP_.math.Vector(f32, 2);
