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

    // render loop
    while (!window.shouldClose()) {
        processInput(window);

        gl.clearColor(0.16, 0.12, 0.07, 1.0); // background color
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        gl.bindVertexArray(VAO);

        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, floorTexture.ID);
        gl.activeTexture(gl.TEXTURE1);
        gl.bindTexture(gl.TEXTURE_2D, faceTexture.ID);

        shader.setFloat("mixFactor", mixFactor);

        var model = Matrix(f32, 4, 4).identity();
        const axis = Vector(f32, 3).from(.{ 0.5, 1.0, 0.0 }).normalized();
        _ = model.rotate(@as(f32, (@floatCast(glfw.getTime()))) * qp.math.radians(50.0), axis);

        var view = Matrix(f32, 4, 4).identity();
        _ = view.translate(Vector(f32, 3).from(.{ 0.0, 0.0, -3.0 }));

        const projection = qp.math.perspective(f32, qp.math.radians(45.0), @as(f32, winWidth) / @as(f32, winHeight), 0.1, 100.0);

        shader.use();
        shader.setInt("floorTexture", 0);
        shader.setInt("faceTexture", 1);

        shader.setMat4("model", model.root());
        shader.setMat4("view", view.root());
        shader.setMat4("projection", projection.root());

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
}

fn framebufferSizeCallback(_: *glfw.Window, width: c_int, height: c_int) callconv(.c) void {
    gl.viewport(0, 0, width, height);
}

var mixFactor: f32 = 0.3; // used in the fragment shader to mix the two textures

const gl_major = 3;
const gl_minor = 3;

const winHeight = 600;
const winWidth = 800;
const sqh = 200.0 / @as(comptime_float, @floatFromInt(winHeight / 2));
const sqw = 200.0 / @as(comptime_float, @floatFromInt(winWidth / 2));
// const sqh = 0.5;
// const sqw = 0.5;

// zig fmt: off
const vertices = [_]f32{
    // positions from top left CCW, coords from top right CW
    // pos           // coords // colors
     // sqw,  sqh, 0.0, 0.55, 0.55, 1.0, 0.0, 0.0, // top right
     // sqw, -sqh, 0.0, 0.55, 0.45, 0.0, 1.0, 0.0, // bottom right
    // -sqw, -sqh, 0.0, 0.45, 0.45, 0.0, 0.0, 1.0, // bottom left
    // -sqw,  sqh, 0.0, 0.45, 0.55, 1.0, 1.0, 0.0, // top left
    //  sqw,  sqh, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, // top right
    //  sqw, -sqh, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, // bottom right
    // -sqw, -sqh, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, // bottom left
    // -sqw,  sqh, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, // top left
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

const Allocator = std.mem.Allocator;
const Regex = qp.util.Regex;
const RegexMatch = qp.util.RegexMatch;
const tests = std.testing;

const Vector = qp.math.Vector;
const Matrix = qp.math.Matrix;
