#version 330 core

out vec4 FragColor;

in vec2 TexCoord;
in vec3 rainbowColor;

uniform sampler2D walltexture;

void main() {
    FragColor = texture(walltexture, TexCoord) * vec4(rainbowColor, 1.0);
}
