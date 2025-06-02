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

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(gpa.deinit() != .leak);
    // const allocator = gpa.allocator();

    try glfw.init();
    defer glfw.terminate();

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

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);
    gl.bindBuffer(gl.ARRAY_BUFFER, 0);

    var wEBO: gl.Uint = tlib.createEBO(&whiteIndices);
    defer gl.deleteBuffers(1, &wEBO);

    var bEBO: gl.Uint = tlib.createEBO(&blackIndices);
    defer gl.deleteBuffers(1, &bEBO);

    gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL);
    // gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE);

    // const wSP: gl.Uint = tlib.createShaderProgram(&vertexShaderSource, &wFragmentShaderSource);
    // defer gl.deleteProgram(wSP);

    var whiteShader = try Shader.init("src/shaders/main.vert", "src/shaders/white.frag", std.heap.page_allocator);
    defer whiteShader.delete();

    // const bSP: gl.Uint = tlib.createShaderProgram(&vertexShaderSource, &bFragmentShaderSource);
    // defer gl.deleteProgram(bSP);

    var blackShader = try Shader.init("src/shaders/main.vert", "src/shaders/black.frag", std.heap.page_allocator);
    defer blackShader.delete();

    // render loop
    while (!window.shouldClose()) {
        processInput(window);

        gl.clearColor(0.16, 0.12, 0.07, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.bindVertexArray(VAO);

        const timeValue: f64 = glfw.getTime();
        const oscValue: f64 = (@sin(timeValue) / 2.0) + 0.5; // oscillates between 0.0 and 1.0

        // const wColorLocation: gl.Int = gl.getUniformLocation(wSP, "wColor");
        // gl.useProgram(wSP);
        whiteShader.use();
        // white color  = vec4(0.6, 0.46, 0.25, 1.0);
        whiteShader.setFloat4("wColor", 0.6, 0.46, @as(f32, @floatCast(oscValue)), 1.0);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, wEBO);
        gl.drawElements(gl.TRIANGLES, whiteIndices.len, gl.UNSIGNED_INT, null);

        // const bColorLocation: gl.Int = gl.getUniformLocation(bSP, "bColor");
        // gl.useProgram(bSP);
        blackShader.use();
        // black color = vec4(0.31, 0.24, 0.13, 1.0);
        whiteShader.setFloat4("bColor", 0.31, @as(f32, @floatCast(oscValue)), 0.13, 1.0);
        // gl.bindVertexArray(VAO);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, bEBO);
        gl.drawElements(gl.TRIANGLES, blackIndices.len, gl.UNSIGNED_INT, null);

        window.swapBuffers();
        glfw.pollEvents();
    }

    std.debug.print("qpEngine\n", .{});
}

fn processInput(window: *glfw.Window) void {
    if (glfw.getKey(window, .escape) == glfw.Action.press) {
        glfw.setWindowShouldClose(window, true);
    }
}

fn framebufferSizeCallback(_: *glfw.Window, width: c_int, height: c_int) callconv(.c) void {
    gl.viewport(0, 0, width, height);
}

const gl_major = 3;
const gl_minor = 3;

const winHeight = 600;
const winWidth = 800;
const sqh = 200.0 / @as(comptime_float, @floatFromInt(winHeight / 2));
const sqw = 200.0 / @as(comptime_float, @floatFromInt(winWidth / 2));
// const sqh = 0.5;
// const sqw = 0.5;

const vertices = [_]f32{
    -sqw, sqh, 0.0, // top left   0
    0.0, sqh, 0.0, // top center  1
    sqw, sqh, 0.0, // top right   2
    //
    -sqw, 0.0, 0.0, // center left  3
    0.0, 0.0, 0.0, // center center 4
    sqw, 0.0, 0.0, // center right  5
    //
    -sqw, -sqh, 0.0, // bottom left  6
    0.0, -sqh, 0.0, // bottom center 7
    sqw, -sqh, 0.0, // bottom right  8
};

const whiteIndices = [_]u32{
    0, 1, 4,
    3, 0, 4,
    //
    4, 5, 8,
    7, 4, 8,
};

const blackIndices = [_]u32{
    1, 2, 5,
    4, 1, 5,
    //
    3, 4, 7,
    6, 3, 7,
};

const vertexShaderSource: [*c]const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\void main() {
    \\    gl_Position = vec4(aPos, 1.0);
    \\}
;

const wFragmentShaderSource: [*c]const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\uniform vec4 wColor;
    \\void main() {
    \\    //FragColor = vec4(0.6, 0.46, 0.25, 1.0);
    \\    FragColor = wColor;
    \\}
;

const bFragmentShaderSource: [*c]const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\uniform vec4 bColor;
    \\void main() {
    \\    //FragColor = vec4(0.31, 0.24, 0.13, 1.0);
    \\    FragColor = bColor;
    \\}
;

const std = @import("std");
const qp = @import("qp");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const tlib = @import("templib.zig");
const Shader = @import("shader.zig").Shader;

const Allocator = std.mem.Allocator;
const Regex = qp.util.Regex;
const RegexMatch = qp.util.RegexMatch;
const tests = std.testing;

const Vector = qp.math.Vector;
const Vector2 = qp.math.Vector2;
const Vector3 = qp.math.Vector3;
const Vector4 = qp.math.Vector4;
