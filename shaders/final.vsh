#version 330
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

// Varying
out vec2 texCoords;

void main() {
    texCoords = vaUV0;

    vec3 vaPosChunk = vaPosition + chunkOffset;
    gl_Position = P * MV * vec4(vaPosChunk, 1.0);
}