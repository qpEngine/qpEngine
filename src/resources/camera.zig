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

const CameraMovement = enum {
    FORWARD,
    BACKWARD,
    LEFT,
    RIGHT,
};

const YAW: f32 = -90.0;
const PITCH: f32 = 0.0;
const SPEED: f32 = 2.5;
const ZOOM: f32 = 45.0;
const SENSITIVITY: f32 = 0.1;

pub const Camera = struct {
    // Camera Attributes
    position: Vec3,
    front: Vec3,
    up: Vec3,
    right: Vec3,
    world_up: Vec3,

    // Euler Angles
    yaw: f32,
    pitch: f32,

    // Camera options
    movement_speed: f32,
    mouse_sensitivity: f32,
    zoom: f32,

    is_fps: bool,

    pub fn init() Camera {
        return Camera{
            .position = undefined,
            .front = undefined,
            .up = undefined,
            .right = undefined,
            .world_up = undefined,
            .yaw = undefined,
            .pitch = undefined,
            .movement_speed = undefined,
            .mouse_sensitivity = undefined,
            .zoom = undefined,
            .is_fps = undefined,
        };
    }

    pub inline fn from(
        position_: ?Vec3,
        up_: ?Vec3,
        yaw_: ?f32,
        pitch_: ?f32,
        is_fps_: bool,
    ) Camera {
        var camera = Camera{
            .position = position_ orelse Vec3{ .data = .{ 0.0, 0.0, 0.0 } },
            .front = Vec3{ .data = .{ 0.0, 0.0, -1.0 } },
            .up = undefined,
            .right = undefined,
            .world_up = up_ orelse Vec3{ .data = .{ 0.0, 1.0, 0.0 } },

            .yaw = yaw_ orelse YAW,
            .pitch = pitch_ orelse PITCH,

            .movement_speed = SPEED,
            .mouse_sensitivity = SENSITIVITY,
            .zoom = ZOOM,
            .is_fps = is_fps_,
        };
        camera.updateCameraVectors();
        return camera;
    }

    pub inline fn getViewMatrix(self: *const Camera) Mat4 {
        return math.lookAt(f32, self.position, self.position.summated(self.front), self.up);
    }

    pub fn processKeyboard(self: *Camera, direction: CameraMovement, deltaTime: f32) void {
        const velocity: f32 = self.movement_speed * deltaTime;
        switch (direction) { // zig fmt: off
            .FORWARD =>  _ = self.position.summate(self.front.multiplied(velocity)),
            .BACKWARD => _ = self.position.subtract(self.front.multiplied(velocity)),
            .LEFT =>     _ = self.position.subtract(self.right.multiplied(velocity)),
            .RIGHT =>    _ = self.position.summate(self.right.multiplied(velocity)),
        } // zig fmt: on

        if (self.is_fps) {
            self.position.comp.y = 0.0;
        }
    }

    pub fn processMouseMovement(self: *Camera, xoffset: f32, yoffset: f32, constrainPitch: bool) void {
        const xoff = xoffset * self.mouse_sensitivity;
        const yoff = yoffset * self.mouse_sensitivity;

        self.yaw += xoff;
        self.pitch += yoff;

        if (constrainPitch) {
            if (self.pitch > 89.0) self.pitch = 89.0;
            if (self.pitch < -89.0) self.pitch = -89.0;
        }

        self.updateCameraVectors();
    }

    pub fn processMouseScroll(self: *Camera, yoffset: f32) void {
        self.zoom -= yoffset;
        if (self.zoom < 1.0) self.zoom = 1.0;
        if (self.zoom > 45.0) self.zoom = 45.0;
    }

    fn updateCameraVectors(self: *Camera) void {
        var front: Vec3 = undefined;
        front.data[0] = @cos(math.radians(self.yaw)) * @cos(math.radians(self.pitch));
        front.data[1] = @sin(math.radians(self.pitch));
        front.data[2] = @sin(math.radians(self.yaw)) * @cos(math.radians(self.pitch));
        self.front = front.normalized();
        self.right = self.front.crossed(.{self.world_up}).cc().normalize().*;
        self.up = self.right.crossed(.{self.front}).cc().normalize().*;
    }
};

const math = @import("qp").math;
const Vector = math.Vector;
const Matrix = math.Matrix;
const Vec3 = Vector(f32, 3);
const Mat4 = Matrix(f32, 4, 4);
