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
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(gpa.deinit() != .leak);
    // const allocator = gpa.allocator();

    try glfw.init();
    defer glfw.terminate();

    stbi.init(std.heap.page_allocator);
    defer stbi.deinit();

    glfw.windowHint(.context_version_major, gl_major);
    glfw.windowHint(.context_version_minor, gl_minor);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);
    // glfw.windowHint(.opengl_forward_compat, true);  //  NOTE: necessary for macOS

    const window = try glfw.Window.create(winWidth, winHeight, "qpEngine", null);
    defer window.destroy();

    glfw.makeContextCurrent(window); // make our window the current context of the current thread
    try zopengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);
    gl.viewport(0, 0, winWidth, winHeight);
    _ = glfw.setFramebufferSizeCallback(window, framebufferSizeCallback);
    try glfw.setInputMode(window, glfw.InputMode.cursor, glfw.Cursor.Mode.disabled);
    _ = glfw.setCursorPosCallback(window, mouseCallback);
    _ = glfw.setScrollCallback(window, scrollCallback);

    var VAO: gl.Uint = tlib.createVAO();
    defer gl.deleteVertexArrays(1, &VAO);

    var VBO: gl.Uint = tlib.createVBO(&vertices);
    defer gl.deleteBuffers(1, &VBO);

    var EBO: gl.Uint = tlib.createEBO(&indices);
    defer gl.deleteBuffers(1, &EBO);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * @sizeOf(f32), null);
    gl.vertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * @sizeOf(f32), @as(?*anyopaque, @ptrFromInt(3 * @sizeOf(f32))));
    gl.enableVertexAttribArray(0);
    gl.enableVertexAttribArray(1);

    gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL);

    var shader = try Shader.init("src/shaders/tex_transform.vert", "src/shaders/tex.frag", std.heap.page_allocator);
    defer shader.deinit();

    Texture.setParams(gl.REPEAT, gl.REPEAT, gl.LINEAR_MIPMAP_LINEAR, gl.NEAREST);
    const floorTexture = try Texture.init("misc/textures/wall.jpg", false);
    const faceTexture = try Texture.init("misc/textures/awesomeface.png", true);

    gl.enable(gl.DEPTH_TEST);
    camera = Camera.from(Vec3{ .data = .{ 0.0, 0.0, 3.0 } }, null, null, null, true);

    // --- RENDER LOOP
    while (!window.shouldClose()) {
        const currentFrame: f32 = @floatCast(glfw.getTime());
        deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;

        processInput(window);

        gl.clearColor(0.16, 0.12, 0.07, 1.0); // background color
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        gl.bindVertexArray(VAO);

        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, floorTexture.ID);
        shader.setInt("floorTexture", 0);

        gl.activeTexture(gl.TEXTURE1);
        gl.bindTexture(gl.TEXTURE_2D, faceTexture.ID);
        shader.setInt("faceTexture", 1);

        shader.setFloat("mixFactor", mixFactor);

        const view = camera.getViewMatrix();
        shader.setMat4("view", view.root());

        const projection = qp.math.perspective(
            f32,
            qp.math.radians(camera.zoom),
            @as(f32, winWidth) / @as(f32, winHeight),
            0.1,
            100.0,
        );
        shader.setMat4("projection", projection.root());

        shader.use();

        for (0..10) |i| {
            const i_: f32 = @floatFromInt(i);
            var model = Mat4.identity();
            _ = model.translate(cubePositions[i]);
            var axis = Vec3{ .data = .{ i_, 0.3, i_ * 0.5 } };
            _ = axis.normalize();
            const angle = (i_ + 1.0) * @as(f32, @floatCast(glfw.getTime()));
            // var axis = Vec3{ .data = .{ 1.0, 0.3, 0.5 } };
            // _ = axis.normalize();
            // const angle = 20.0 * i_;
            _ = model.rotate(qp.math.radians(angle), axis);
            shader.setMat4("model", model.root());

            gl.drawArrays(gl.TRIANGLES, 0, 36);
        }

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
        // gl.drawElements(gl.TRIANGLES, indices.len, gl.UNSIGNED_INT, null);
        gl.drawArrays(gl.TRIANGLES, 0, 36);

        window.swapBuffers();
        glfw.pollEvents();
    }

    std.debug.print("qpEngine\n", .{});
}

fn processInput(window: *glfw.Window) void {
    if (glfw.getKey(window, .escape) == glfw.Action.press) {
        glfw.setWindowShouldClose(window, true);
    }

    if (glfw.getKey(window, .up) == glfw.Action.press) {
        mixFactor += 0.01;
        if (mixFactor >= 1.0) mixFactor = 1.0;
    }

    if (glfw.getKey(window, .down) == glfw.Action.press) {
        mixFactor -= 0.01;
        if (mixFactor <= 0.0) mixFactor = 0.0;
    }

    if (glfw.getKey(window, .w) == glfw.Action.press) {
        camera.processKeyboard(.FORWARD, deltaTime);
    }
    if (glfw.getKey(window, .s) == glfw.Action.press) {
        camera.processKeyboard(.BACKWARD, deltaTime);
    }
    if (glfw.getKey(window, .a) == glfw.Action.press) {
        camera.processKeyboard(.LEFT, deltaTime);
    }
    if (glfw.getKey(window, .d) == glfw.Action.press) {
        camera.processKeyboard(.RIGHT, deltaTime);
    }
}

fn mouseCallback(window: *glfw.Window, xpos: f64, ypos: f64) callconv(.c) void {
    _ = window;

    if (firstMouse) {
        lastX = @floatCast(xpos);
        lastY = @floatCast(ypos);
        firstMouse = false;
    }

    const xoffset: f32 = @as(f32, @floatCast(xpos)) - lastX;
    const yoffset: f32 = lastY - @as(f32, @floatCast(ypos)); // reversed since y-coordinates go from bottom to top
    lastX = @as(f32, @floatCast(xpos));
    lastY = @as(f32, @floatCast(ypos));

    camera.processMouseMovement(xoffset, yoffset, true);
}

fn scrollCallback(_: *glfw.Window, xoffset: f64, yoffset: f64) callconv(.c) void {
    _ = xoffset;

    camera.processMouseScroll(@floatCast(yoffset));
}

fn framebufferSizeCallback(_: *glfw.Window, width: c_int, height: c_int) callconv(.c) void {
    gl.viewport(0, 0, width, height);
}

var mixFactor: f32 = 0.3; // used in the fragment shader to mix the two textures

// var camera = Camera.init(Vec3.from(.{ 0.0, 0.0, 3.0 }), null, null, null);
var camera = Camera.init();
var deltaTime: f32 = 0.0; // time between current frame and last frame
var lastFrame: f32 = 0.0; // time of last frame

var lastX: f32 = @as(f32, winWidth) / 2.0;
var lastY: f32 = @as(f32, winHeight) / 2.0;
var firstMouse: bool = true;

const gl_major = 3;
const gl_minor = 3;

const winHeight = 600;
const winWidth = 800;

// zig fmt: off
const vertices = [_]f32{
    // positions from top left CCW, coords from top right CW
    // pos             // coords
    -0.5, -0.5, -0.5,  0.0, 0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 0.0,

    -0.5, -0.5,  0.5,  0.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,

    -0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5,  0.5,  1.0, 0.0,

     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5,  0.5,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,

    -0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  1.0, 1.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,

    -0.5,  0.5, -0.5,  0.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5, -0.5,  0.0, 1.0
}; // zig fmt: on

const cubePositions = [_]Vec3{ // zig fmt: off
    Vec3{ .data = .{ 0.0,  0.0,   0.0} },
    Vec3{ .data = .{ 2.0,  5.0, -15.0} },
    Vec3{ .data = .{-1.5, -2.2,  -2.5} },
    Vec3{ .data = .{-3.8, -2.0, -12.3} },
    Vec3{ .data = .{ 2.4, -0.4,  -3.5} },
    Vec3{ .data = .{-1.7,  3.0,  -7.5} },
    Vec3{ .data = .{ 1.3, -2.0,  -2.5} },
    Vec3{ .data = .{ 1.5,  2.0,  -2.5} },
    Vec3{ .data = .{ 1.5,  0.2,  -1.5} },
    Vec3{ .data = .{-1.3,  1.0,  -1.5} },
}; // zig fmt: on

const indices = [_]u32{
    0, 1, 3, // first triangle
    1, 2, 3, // second triangle
};

const std = @import("std");
const qp = @import("qp");
const glfw = @import("zglfw");
const stbi = @import("zstbi");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const tlib = @import("templib.zig");
const Shader = @import("resources/shader.zig").Shader;
const Texture = @import("resources/texture.zig").Texture;
const Camera = @import("resources/camera.zig").Camera;

const Allocator = std.mem.Allocator;
const Regex = qp.util.Regex;
const RegexMatch = qp.util.RegexMatch;
const tests = std.testing;

const Vector = qp.math.Vector;
const Matrix = qp.math.Matrix;

const Mat4 = Matrix(f32, 4, 4);
const Vec3 = Vector(f32, 3);
const Vec4 = Vector(f32, 4);
