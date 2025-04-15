pub fn createShaderProgram(vertexSS: *const [*c]const u8, fragmentSS: *const [*c]const u8) gl.Uint {
    var success: gl.Int = 0;
    var infoLog: [512]u8 = undefined;

    // create vertex shader
    var vertexShader: gl.Uint = undefined;
    vertexShader = gl.createShader(gl.VERTEX_SHADER);

    gl.shaderSource(vertexShader, 1, vertexSS, null);
    gl.compileShader(vertexShader);

    gl.getShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(vertexShader, 512, null, &infoLog[0]);
        std.debug.print("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n", .{infoLog[0..]});
    }

    // create fragment shader
    var fragmentShader: gl.Uint = undefined;
    fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragmentShader, 1, fragmentSS, null);
    gl.compileShader(fragmentShader);

    gl.getShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(fragmentShader, 512, null, &infoLog[0]);
        std.debug.print("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n", .{infoLog[0..]});
    }

    // create shader program
    const shaderProgram: gl.Uint = gl.createProgram();
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

    return shaderProgram;
}

pub fn createVAO(vertices: []const f32) gl.Uint {
    var VAO: gl.Uint = undefined;
    gl.genVertexArrays(1, &VAO);
    gl.bindVertexArray(VAO);
    gl.bufferData(gl.ARRAY_BUFFER, @as(isize, @intCast(vertices.len)) * @sizeOf(f32), &vertices[0], gl.STATIC_DRAW);
    gl.bindVertexArray(0);
    return VAO;
}

pub fn createEBO(indices: []const u32) gl.Uint {
    var EBO: gl.Uint = undefined;
    gl.genBuffers(1, &EBO);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @as(isize, @intCast(indices.len)) * @sizeOf(u32), &indices[0], gl.STATIC_DRAW);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0); // unbind the buffer
    return EBO;
}

const std = @import("std");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;
