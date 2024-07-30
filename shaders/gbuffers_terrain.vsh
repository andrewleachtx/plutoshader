#version 330
#include "common.glsl"
#include "defines.glsl"

// Uniforms
uniform mat4 modelViewMatrix;       
uniform mat4 modelViewMatrixInverse;
uniform mat4 projectionMatrix;
uniform vec3 cameraPosition; // camera in world space
uniform mat4 gbufferModelViewInverse; // "closer" to MVit

uniform vec3 chunkOffset; // this is zero for all non-terrain, so this is why we can template it

// Attributes
in vec3 vaPosition;
in vec3 vaNormal;
in vec2 vaUV0;
in ivec2 vaUV2;
in vec4 vaColor; // (r, g, b, a) of a vertex

// Varying
out vec2 texCoords;
out vec3 foliageColor;
out vec2 lightMapCoords; // flags this vertex as something not to use interpolation for in fragment shader
out vec3 vNor;

void main() {
    texCoords = vaUV0;
    foliageColor = vaColor.rgb;
    lightMapCoords = vaUV2 * (1.0 / 256.0) + (1.0 / 32.0);

    vec3 vaPosChunk = vaPosition + chunkOffset;
    gl_Position = P * MV * vec4(vaPosChunk, 1.0);

    // Why do we not need to do the inverse transpose like usual?
    // mat4 MVitt = inverse(transpose(MV));
    // vNor = normalize(MVitt * vec4(vaNormal, 0.0)).xyz;
    vNor = normalize(MV * vec4(vaNormal, 0.0)).xyz;
}