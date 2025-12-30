#version 330 core

out vec4 FragColor;

uniform vec4 wColor;

void main() {
    //FragColor = vec4(0.6, 0.46, 0.25, 1.0);
    FragColor = wColor;
}
