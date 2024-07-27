#version 460
#include "/common.glsl"


// Input from terrain buffer
uniform sampler2D colortex0;
uniform sampler2D colortex1;

/*
const int colortex0Format = RGBA16;
const int colortex1Format = RGBA16;
*/

uniform vec3 sunPosition;

// outColor0, 1 in gbuffers_terrain.fsh

/* DRAWBUFFERS:0 */
// outColor0 should go to the first color attachment draw buffer
layout (location = 0) out vec4 outColor0; // ALBEDO

in vec2 texCoords;
in vec3 foliageColor;
in vec2 lightMapCoords;

void main() {
    // gbuffers_terrain has already updated foliage color and light
    vec3 albedo = texture2D(colortex0, texCoords).rgb;

    vec3 nor = normalize(texture2D(colortex1, texCoords).rgb * 2.0 - 1.0);
    float nDotL = max(dot(nor, normalize(sunPosition)), 0.0);

    vec3 diffuse = albedo * (nDotL + KA);

    // Omit see through fragments
    outColor0 = vec4(diffuse, 1.0);
}