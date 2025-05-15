#version 330
#include "common.glsl"
#include "defines.glsl"

// Uniforms
uniform vec3 chunkOffset; // this is zero for all non-terrain, so this is why we can template it
uniform mat4 modelViewMatrix;       
uniform mat4 projectionMatrix;

// Attributes
in vec3 vaPosition;

void main() {
    vec3 vaPosChunk = vaPosition + chunkOffset;
    gl_Position = P * MV * vec4(vaPosChunk, 1.0);
}