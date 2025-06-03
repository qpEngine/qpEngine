#version 330 core

out vec4 FragColor;

in vec2 TexCoord;
in vec3 rainbowColor;

uniform sampler2D floorTexture;
uniform sampler2D faceTexture;
uniform float mixFactor;

void main() {
    // FragColor = texture(floorTexture, TexCoord) * vec4(rainbowColor, 1.0);
    FragColor = mix(texture(floorTexture, TexCoord), texture(faceTexture, TexCoord), mixFactor);
}
