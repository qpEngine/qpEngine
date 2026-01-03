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

pub fn main() !void {
    try Glfw_.init();
    defer Glfw_.terminate();

    Stbi_.init(Std_.heap.page_allocator);
    defer Stbi_.deinit();

    Glfw_.windowHint(.context_version_major, _GL_MAJOR_);
    Glfw_.windowHint(.context_version_minor, _GL_MINOR_);
    Glfw_.windowHint(.opengl_profile, .opengl_core_profile);
    if (Builtin_.os.tag == .macos) {
        Glfw_.windowHint(.opengl_forward_compat, true);
    }

    const window = try Glfw_.Window.create(_WIN_WIDTH_, _WIN_HEIGHT_, "qpEngine", null);
    defer window.destroy();

    Glfw_.makeContextCurrent(window);
    try Opengl_.loadCoreProfile(Glfw_.getProcAddress, _GL_MAJOR_, _GL_MINOR_);
    _ = Glfw_.setFramebufferSizeCallback(window, framebufferSizeCallback);
    try Glfw_.setInputMode(window, Glfw_.InputMode.cursor, Glfw_.Cursor.Mode.disabled);
    _ = Glfw_.setCursorPosCallback(window, mouseCallback);
    _ = Glfw_.setScrollCallback(window, scrollCallback);
    Stbi_.setFlipVerticallyOnLoad(false);
    GL_.enable(GL_.DEPTH_TEST);

    // build and compile our shader programs
    var our_shader = try Shader.init(
        "src/shaders/chapter1/1.model.vert",
        "src/shaders/chapter1/1.model.frag",
        Std_.heap.page_allocator,
    );
    defer our_shader.deinit();

    const model_path = "misc/models/backpack/scene.gltf";
    var buffer: [256]u8 = undefined;
    const full_model_path = try Std_.fs.cwd().realpath(model_path, &buffer);
    buffer[full_model_path.len] = 0;
    var our_model = try Model.init(buffer[0..full_model_path.len :0], false);
    defer our_model.deinit();

    _CAMERA = Camera.from(Vec3.from(.{ 0.0, 0.0, 3.0 }), null, null, null, false);

    // ~~~ RENDER LOOP ~~~
    while (!window.shouldClose()) {
        const currentFrame: f32 = @floatCast(Glfw_.getTime());
        _DELTA_TIME = currentFrame - _LAST_FRAME;
        _LAST_FRAME = currentFrame;

        processInput(window);

        // GL_.clearColor(0.16, 0.12, 0.07, 1.0); // dark brown
        GL_.clearColor(0.1, 0.1, 0.1, 1.0); // dark gray
        GL_.clear(GL_.COLOR_BUFFER_BIT | GL_.DEPTH_BUFFER_BIT);

        our_shader.use();
        var projection: Mat4 = QP_.math.perspective(
            f32,
            _CAMERA.zoom,
            @as(f32, _WIN_WIDTH_) / @as(f32, _WIN_HEIGHT_),
            0.1,
            100.0,
        );
        var view: Mat4 = _CAMERA.getViewMatrix();
        our_shader.setMat4("projection", projection.root());
        our_shader.setMat4("view", view.root());

        const model = Mat4.identity().cc()
            .translate(Vec3.from(.{ 0.0, 0.0, 0.0 }))
            .scale(Vec3.from(.{ 0.01, 0.01, 0.01 }));
        our_shader.setMat4("model", model.root());
        our_model.draw(&our_shader);

        window.swapBuffers();
        Glfw_.pollEvents();
    }

    Std_.debug.print("qpEngine\n", .{});
}

fn processInput(window: *Glfw_.Window) void {
    if (Glfw_.getKey(window, .escape) == Glfw_.Action.press) {
        Glfw_.setWindowShouldClose(window, true);
    }

    if (Glfw_.getKey(window, .w) == Glfw_.Action.press) {
        _CAMERA.processKeyboard(.FORWARD, _DELTA_TIME);
    }
    if (Glfw_.getKey(window, .s) == Glfw_.Action.press) {
        _CAMERA.processKeyboard(.BACKWARD, _DELTA_TIME);
    }
    if (Glfw_.getKey(window, .a) == Glfw_.Action.press) {
        _CAMERA.processKeyboard(.LEFT, _DELTA_TIME);
    }
    if (Glfw_.getKey(window, .d) == Glfw_.Action.press) {
        _CAMERA.processKeyboard(.RIGHT, _DELTA_TIME);
    }
}

fn mouseCallback(window: *Glfw_.Window, xpos: f64, ypos: f64) callconv(.c) void {
    _ = window;

    if (_FIRSTMOUSE) {
        _LAST_X = @floatCast(xpos);
        _LAST_Y = @floatCast(ypos);
        _FIRSTMOUSE = false;
    }

    const xoffset: f32 = @as(f32, @floatCast(xpos)) - _LAST_X;
    const yoffset: f32 = _LAST_Y - @as(f32, @floatCast(ypos)); // reversed since y-coordinates go from bottom to top
    _LAST_X = @as(f32, @floatCast(xpos));
    _LAST_Y = @as(f32, @floatCast(ypos));

    _CAMERA.processMouseMovement(xoffset, yoffset, true);
}

fn scrollCallback(_: *Glfw_.Window, xoffset: f64, yoffset: f64) callconv(.c) void {
    _ = xoffset;

    _CAMERA.processMouseScroll(@floatCast(yoffset));
}

fn framebufferSizeCallback(_: *Glfw_.Window, width: c_int, height: c_int) callconv(.c) void {
    GL_.viewport(0, 0, width, height);
}

var _CAMERA = Camera.init();
var _DELTA_TIME: f32 = 0.0;
var _LAST_FRAME: f32 = 0.0;

var _LAST_X: f32 = @as(f32, _WIN_WIDTH_) / 2.0;
var _LAST_Y: f32 = @as(f32, _WIN_HEIGHT_) / 2.0;
var _FIRSTMOUSE: bool = true;

const _LIGHT_POS_: Vec3 = Vec3{ .data = .{ 1.2, 1.0, 2.0 } };

const _GL_MAJOR_ = 3;
const _GL_MINOR_ = 3;

const _WIN_HEIGHT_ = 600;
const _WIN_WIDTH_ = 800;

const Std_ = @import("std");
const Builtin_ = @import("builtin");
const QP_ = @import("qp");
const Glfw_ = @import("zglfw");
const Stbi_ = @import("zstbi");
const Opengl_ = @import("zopengl");
const GL_ = Opengl_.bindings;
const Tlib_ = @import("templib.zig");

const bufPrint = Std_.fmt.bufPrint;

const Shader = @import("resources/shader.zig").Shader;
const Texture = @import("resources/texture.zig").Texture;
const Camera = @import("resources/camera.zig").Camera;
const Model = @import("resources/model.zig").Model;
const Mesh = @import("resources/mesh.zig").Mesh;

const Vector = QP_.math.Vector;
const Matrix = QP_.math.Matrix;
const Mat4 = Matrix(f32, 4, 4);
const Vec3 = Vector(f32, 3);
const Vec4 = Vector(f32, 4);
