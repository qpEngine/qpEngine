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
    const vertices = [_]f32{ // zig fmt: off
        // positions from top left CCW, coords from top right CW
        // pos             // coords
        -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 0.0,
         0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 0.0,
         0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 1.0,
         0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 1.0,
        -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 0.0,
        // front face

        -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 0.0,
         0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 0.0,
         0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 1.0,
         0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 1.0,
        -0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 0.0,
        // back face

        -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0, 0.0,
        -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,  1.0, 1.0,
        -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0, 1.0,
        -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0, 1.0,
        -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,  0.0, 0.0,
        -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0, 0.0,
        // left face

         0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0,  0.0,  0.0,  1.0, 1.0,
         0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0, 1.0,
         0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0, 1.0,
         0.5, -0.5,  0.5,  1.0,  0.0,  0.0,  0.0, 0.0,
         0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,
         // right face

        -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0, 1.0,
         0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  1.0, 1.0,
         0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0, 0.0,
         0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  0.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0, 1.0,
        // bottom face

        -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0, 1.0,
         0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  1.0, 1.0,
         0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
         0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
        -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  0.0, 0.0,
        -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0, 1.0
        // top face
    }; // zig fmt: on

    const cube_positions = [_]Vec3{
        Vec3{ .data = .{ 0.0, 0.0, 0.0 } },
        Vec3{ .data = .{ 2.0, 5.0, -15.0 } },
        Vec3{ .data = .{ -1.5, -2.2, -2.5 } },
        Vec3{ .data = .{ -3.8, -2.0, -12.3 } },
        Vec3{ .data = .{ 2.4, -0.4, -3.5 } },
        Vec3{ .data = .{ -1.7, 3.0, -7.5 } },
        Vec3{ .data = .{ 1.3, -2.0, -2.5 } },
        Vec3{ .data = .{ 1.5, 2.0, -2.5 } },
        Vec3{ .data = .{ 1.5, 0.2, -1.5 } },
        Vec3{ .data = .{ -1.3, 1.0, -1.5 } },
    };

    const point_light_positions = [_]Vec3{
        Vec3{ .data = .{ 0.7, 0.2, 2.0 } },
        Vec3{ .data = .{ 2.3, -3.3, -4.0 } },
        Vec3{ .data = .{ -4.0, 2.0, -12.0 } },
        Vec3{ .data = .{ 0.0, 0.0, -3.0 } },
    };

    try Glfw_.init();
    defer Glfw_.terminate();

    Stbi_.init(Std_.heap.page_allocator);
    defer Stbi_.deinit();

    Glfw_.windowHint(.context_version_major, _GL_MAJOR_);
    Glfw_.windowHint(.context_version_minor, _GL_MINOR_);
    Glfw_.windowHint(.opengl_profile, .opengl_core_profile);
    if (Builtin_.os.tag == .macos) {
        Glfw_.windowHint(.opengl_forward_compat, true); // necessary for macOS
    }

    const window = try Glfw_.Window.create(_WIN_WIDTH_, _WIN_HEIGHT_, "qpEngine", null);
    defer window.destroy();

    Glfw_.makeContextCurrent(window);
    try Opengl_.loadCoreProfile(Glfw_.getProcAddress, _GL_MAJOR_, _GL_MINOR_);
    _ = Glfw_.setFramebufferSizeCallback(window, framebufferSizeCallback);
    try Glfw_.setInputMode(window, Glfw_.InputMode.cursor, Glfw_.Cursor.Mode.disabled);
    _ = Glfw_.setCursorPosCallback(window, mouseCallback);
    _ = Glfw_.setScrollCallback(window, scrollCallback);
    GL_.enable(GL_.DEPTH_TEST);

    // build and compile our shader programs
    var cube_shader = try Shader.init(
        "src/shaders/chapter1/1.colors.vert",
        "src/shaders/chapter1/1.colors.frag",
        Std_.heap.page_allocator,
    );
    defer cube_shader.deinit();

    var light_shader = try Shader.init(
        "src/shaders/chapter1/1.light.vert",
        "src/shaders/chapter1/1.light.frag",
        Std_.heap.page_allocator,
    );
    defer light_shader.deinit();

    // Configure cube's VAO and VBO
    var cube_VAO: GL_.Uint = Tlib_.createVAO();
    defer GL_.deleteVertexArrays(1, &cube_VAO);

    var cube_VBO: GL_.Uint = Tlib_.createVBO(&vertices);
    defer GL_.deleteBuffers(1, &cube_VBO);

    GL_.vertexAttribPointer(0, 3, GL_.FLOAT, GL_.FALSE, 8 * @sizeOf(f32), null);
    GL_.enableVertexAttribArray(0);
    GL_.vertexAttribPointer(1, 3, GL_.FLOAT, GL_.FALSE, 8 * @sizeOf(f32), @as(?*anyopaque, @ptrFromInt(3 * @sizeOf(f32))));
    GL_.enableVertexAttribArray(1);
    GL_.vertexAttribPointer(2, 2, GL_.FLOAT, GL_.FALSE, 8 * @sizeOf(f32), @as(?*anyopaque, @ptrFromInt(6 * @sizeOf(f32))));
    GL_.enableVertexAttribArray(2);

    var light_VAO: GL_.Uint = Tlib_.createVAO();
    defer GL_.deleteVertexArrays(1, &light_VAO);

    GL_.bindBuffer(GL_.ARRAY_BUFFER, cube_VBO);
    GL_.vertexAttribPointer(0, 3, GL_.FLOAT, GL_.FALSE, 8 * @sizeOf(f32), null);
    GL_.enableVertexAttribArray(0);

    // GL_.polygonMode(GL_.FRONT_AND_BACK, GL_.FILL);

    const diffuse_map = try Texture.init("misc/textures/container2.png", true);
    const specular_map = try Texture.init("misc/textures/container2_specular.png", true);
    cube_shader.use();
    cube_shader.setInt("material.diffuse", 0);
    cube_shader.setInt("material.specular", 1);
    cube_shader.setFloat("material.shininess", 64.0);

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

        cube_shader.use();
        cube_shader.setVec3("viewPos", _CAMERA.position.data);

        // set directional light
        cube_shader.setVec3("dirLight.direction", .{ -0.2, -1.0, -0.3 });
        cube_shader.setVec3("dirLight.ambient", .{ 0.05, 0.05, 0.05 });
        cube_shader.setVec3("dirLight.diffuse", .{ 0.4, 0.4, 0.4 });
        cube_shader.setVec3("dirLight.specular", .{ 0.5, 0.5, 0.5 });

        // set point lights
        var buf: [64]u8 = undefined;
        for (0..4) |i| {
            const p = "pointLights";
            cube_shader.setVec3((try bufPrint(&buf, "{s}[{d}].position\x00", .{ p, i })).ptr, point_light_positions[i].data);

            cube_shader.setVec3((try bufPrint(&buf, "{s}[{d}].ambient\x00", .{ p, i })).ptr, .{ 0.05, 0.05, 0.05 });
            cube_shader.setVec3((try bufPrint(&buf, "{s}[{d}].diffuse\x00", .{ p, i })).ptr, .{ 0.8, 0.8, 0.8 });
            cube_shader.setVec3((try bufPrint(&buf, "{s}[{d}].specular\x00", .{ p, i })).ptr, .{ 1.0, 1.0, 1.0 });

            cube_shader.setFloat((try bufPrint(&buf, "{s}[{d}].constant\x00", .{ p, i })).ptr, 1.0);
            cube_shader.setFloat((try bufPrint(&buf, "{s}[{d}].linear\x00", .{ p, i })).ptr, 0.09);
            cube_shader.setFloat((try bufPrint(&buf, "{s}[{d}].quadratic\x00", .{ p, i })).ptr, 0.032);
        }

        // set spot light
        cube_shader.setVec3("spotLight.position", _CAMERA.position.data);
        cube_shader.setVec3("spotLight.direction", _CAMERA.front.data);
        cube_shader.setFloat("spotLight.cutoff", @cos(QP_.math.radians(12.5)));
        cube_shader.setFloat("spotLight.outerCutoff", @cos(QP_.math.radians(15.0)));

        cube_shader.setVec3("spotLight.ambient", .{ 0.0, 0.0, 0.0 });
        cube_shader.setVec3("spotLight.diffuse", .{ 1.0, 1.0, 1.0 });
        cube_shader.setVec3("spotLight.specular", .{ 1.0, 1.0, 1.0 });

        cube_shader.setFloat("spotLight.constant", 1.0);
        cube_shader.setFloat("spotLight.linear", 0.09);
        cube_shader.setFloat("spotLight.quadratic", 0.032);

        const projection = QP_.math.perspective(
            f32,
            QP_.math.radians(_CAMERA.zoom),
            @as(f32, _WIN_WIDTH_) / @as(f32, _WIN_HEIGHT_),
            0.1,
            100.0,
        );
        const view = _CAMERA.getViewMatrix();
        cube_shader.setMat4("projection", projection.root());
        cube_shader.setMat4("view", view.root());

        GL_.activeTexture(GL_.TEXTURE0);
        GL_.bindTexture(GL_.TEXTURE_2D, diffuse_map.ID);
        GL_.activeTexture(GL_.TEXTURE1);
        GL_.bindTexture(GL_.TEXTURE_2D, specular_map.ID);

        GL_.bindVertexArray(cube_VAO);

        for (0..10) |i| {
            const angle: f32 = 20.0 * @as(f32, @floatFromInt(i));
            const model = Mat4.identity().cc()
                .translate(cube_positions[i])
                .rotate(angle, (Vec3{ .data = .{ 1.0, 0.3, 0.5 } }).normalized());
            cube_shader.setMat4("model", model.root());

            const normal_matrix = model.inversed().cc().transpose().*;
            cube_shader.setMat4("normalMatrix", normal_matrix.root());

            GL_.drawArrays(GL_.TRIANGLES, 0, 36);
        }

        light_shader.use();
        light_shader.setMat4("projection", projection.root());
        light_shader.setMat4("view", view.root());

        GL_.bindVertexArray(light_VAO);

        for (0..4) |i| {
            var light_model = Mat4.identity().cc()
                .translate(point_light_positions[i])
                .scale(Vec3.from(0.2)).*;
            light_shader.setMat4("model", light_model.root());
            GL_.drawArrays(GL_.TRIANGLES, 0, 36);
        }

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
var _DELTA_TIME: f32 = 0.0; // time between current frame and last frame
var _LAST_FRAME: f32 = 0.0; // time of last frame

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

const Vector = QP_.math.Vector;
const Matrix = QP_.math.Matrix;
const Mat4 = Matrix(f32, 4, 4);
const Vec3 = Vector(f32, 3);
const Vec4 = Vector(f32, 4);
