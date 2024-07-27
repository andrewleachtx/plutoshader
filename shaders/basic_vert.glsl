#version 460
#include "common.glsl"
#include "defines.glsl"

// Uniforms
uniform vec3 chunkOffset; // this is zero for all non-terrain, so this is why we can template it
uniform mat4 modelViewMatrix;       
uniform mat4 modelViewMatrixInverse;
uniform mat4 projectionMatrix;
uniform vec3 cameraPosition; // camera in world space
uniform mat4 gbufferModelViewInverse; // "closer" to MVit

// Attributes
in vec3 vaPosition;
in vec2 vaUV0;
in ivec2 vaUV2;
in vec4 vaColor; // (r, g, b, a) of a vertex

// Varying
out vec2 texCoords;
out vec3 foliageColor;
out vec2 lightMapCoords; // flags this vertex as something not to use interpolation for in fragment shader

void main() {
    texCoords = vaUV0;
    foliageColor = vaColor.rgb;
    lightMapCoords = vaUV2 * (1.0 / 256.0) + (1.0 / 32.0);

    vec3 vaPosChunk = vaPosition + chunkOffset;
    gl_Position = P * MV * vec4(vaPosChunk, 1.0);
}