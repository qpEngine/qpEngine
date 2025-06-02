#version 330 core

out vec4 FragColor;

uniform vec4 bColor;

void main() {
    //FragColor = vec4(0.31, 0.24, 0.13, 1.0);
    FragColor = bColor;
}
