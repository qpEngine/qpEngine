pub const Model = struct {
    textures_loaded: AList(Texture),
    meshes: AList(Mesh),
    directory: []const u8,
    gamma_correction: bool,

    pub fn init(path_: []const u8, gamma_: bool) !Model {
        var model = Model{
            .meshes = .empty,
            .textures_loaded = .empty,
            .directory = undefined,
            .gamma_correction = gamma_,
        };
        try model.loadModel(path_);
        return model;
    }

    pub fn draw(self: *const Model, shader_: *const Shader) void {
        for (self.meshes.items) |mesh| {
            mesh.draw(shader_);
        }
    }

    fn loadModel(self: *Model, path_: []const u8) !void {
        const allocator = Std_.heap.page_allocator;

        Mesh_.init(allocator);
        defer Mesh_.deinit();

        const data = try Mesh_.io.zcgltf.parseAndLoadFile(path_);
        defer Mesh_.io.zcgltf.freeData(data);

        self.processNode(data.scene.root_node, data.scene);
    }
};

const Std_ = @import("std");
const Fs_ = Std_.fs;
const Mem_ = Std_.mem;
const Mesh_ = @import("qp").mesh;
// const Zmesh_ = @import("zmesh");

const Mesh = @import("mesh.zig").Mesh;
const Texture = @import("texture.zig").Texture;
const Shader = @import("shader.zig").Shader;

const AList = Std_.ArrayList;
