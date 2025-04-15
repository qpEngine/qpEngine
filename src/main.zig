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

    const winHeight = 600;
    const winWidth = 800;

    try glfw.init();
    defer glfw.terminate();

    const gl_major = 3;
    const gl_minor = 3;

    // Choose the set of features that we want to use from OpenGL
    glfw.windowHint(.context_version_major, gl_major);
    glfw.windowHint(.context_version_minor, gl_minor);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);
    // glfw.windowHint(.opengl_forward_compat, true);  //  NOTE: necessary for macOS

    // create a window and its OpenGL context
    const window = try glfw.Window.create(winWidth, winHeight, "qpEngine", null);
    defer window.destroy();

    glfw.makeContextCurrent(window); // make our window the current context of the current thread

    // necessary for zig to load the OpenGL functions??
    try zopengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);

    // set the viewport to the size of the window, and a callback to update the viewport on window resize
    gl.viewport(0, 0, winWidth, winHeight);
    _ = glfw.setFramebufferSizeCallback(window, framebufferSizeCallback);

    // glfw.swapInterval(1);

    var shaderProgram: gl.Uint = undefined;
    {
        var success: gl.Int = 0;
        var infoLog: [512]u8 = undefined;

        // create vertex shader
        var vertexShader: gl.Uint = undefined;
        vertexShader = gl.createShader(gl.VERTEX_SHADER);

        gl.shaderSource(vertexShader, 1, &vertexShaderSource, null);
        gl.compileShader(vertexShader);

        gl.getShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            gl.getShaderInfoLog(vertexShader, 512, null, &infoLog[0]);
            std.debug.print("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n", .{infoLog[0..]});
        }

        // create fragment shader
        var fragmentShader: gl.Uint = undefined;
        fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragmentShader, 1, &fragmentShaderSource, null);
        gl.compileShader(fragmentShader);

        gl.getShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            gl.getShaderInfoLog(fragmentShader, 512, null, &infoLog[0]);
            std.debug.print("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n", .{infoLog[0..]});
        }

        // create shader program
        shaderProgram = gl.createProgram();
        gl.attachShader(shaderProgram, vertexShader);
        gl.attachShader(shaderProgram, fragmentShader);
        gl.linkProgram(shaderProgram);

        gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
        if (success == 0) {
            gl.getProgramInfoLog(shaderProgram, 512, null, &infoLog[0]);
            std.debug.print("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}\n", .{infoLog[0..]});
        }

        gl.deleteShader(vertexShader);
        gl.deleteShader(fragmentShader);
    }
    defer gl.deleteProgram(shaderProgram);

    const vertices = [_]f32{
        0.5, 0.5, 0.0, // top right
        0.5, -0.5, 0.0, // bottom right
        -0.5, -0.5, 0.0, // bottom left
        -0.5, 0.5, 0.0, // top left
    };

    const indices = [_]u32{
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
    };

    // create vertex array object
    var VAO: gl.Uint = undefined;
    var VBO: gl.Uint = undefined;
    var EBO: gl.Uint = undefined;
    {
        gl.genVertexArrays(1, &VAO);
        gl.genBuffers(1, &VBO);
        gl.genBuffers(1, &EBO);

        gl.bindVertexArray(VAO);
        gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
        gl.bufferData(gl.ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices[0], gl.STATIC_DRAW);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u32), &indices[0], gl.STATIC_DRAW);

        gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
        gl.enableVertexAttribArray(0);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0); // unbind the buffer
        gl.bindBuffer(gl.ARRAY_BUFFER, 0); // unbind the buffer
        gl.bindVertexArray(0); // unbind the VAO
    }
    defer gl.deleteBuffers(1, &EBO);
    defer gl.deleteBuffers(1, &VBO);
    defer gl.deleteVertexArrays(1, &VAO);

    // gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL);
    gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE);

    // render loop
    while (!window.shouldClose()) {
        processInput(window);

        gl.clearColor(0.16, 0.12, 0.07, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(shaderProgram);
        gl.bindVertexArray(VAO);
        // gl.drawArrays(gl.TRIANGLES, 0, 3);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
        gl.drawElements(gl.TRIANGLES, indices.len, gl.UNSIGNED_INT, null);

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

const vertexShaderSource: [*c]const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\void main() {
    \\    gl_Position = vec4(aPos, 1.0);
    \\}
;

const fragmentShaderSource: [*c]const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\void main() {
    \\    FragColor = vec4(0.31, 0.22, 0.1, 1.0);
    \\}
;

const std = @import("std");
const qp = @import("qp");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const tlib = @import("templib.zig").createShaderProgram;

const Allocator = std.mem.Allocator;
const Regex = qp.util.Regex;
const RegexMatch = qp.util.RegexMatch;
const tests = std.testing;

const Vector = qp.math.Vector;
const Vector2 = qp.math.Vector2;
const Vector3 = qp.math.Vector3;
const Vector4 = qp.math.Vector4;
