#version 330
#include "/common.glsl"

// Input from terrain buffer
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

/*
const int colortex0Format = RGBA16;
const int colortex1Format = RGB16;
const int colortex2Format = RGB16;
*/

// Sun direction from our eye
uniform vec3 sunPosition;

// outColor0, 1 in gbuffers_terrain.fsh

/* DRAWBUFFERS:0 */
// outColor0 should go to the first color attachment draw buffer
layout (location = 0) out vec4 outColor0; // ALBEDO

in vec2 texCoords;

// For lm.x (non sky light)
float updateLmBlock(float src) {
    return 2 * pow(src, 5.06);
}

// For lm.y (sky light)
float updateLmSky(float src) {
    return src * src * src * src;
}

vec2 genUpdatedLm(vec2 lm) {
    vec2 newLightMap = vec2(updateLmBlock(lm.x), updateLmSky(lm.y));
    return newLightMap;
}

vec3 genLmColor(vec2 lm) {
    const vec3 BLOCK_COLOR = vec3(1.0, 0.25, 0.08);
    const vec3 SKY_COLOR = vec3(0.05, 0.15, 0.3);

    vec3 blockLight = lm.x * BLOCK_COLOR;
    vec3 skyLight = lm.y * SKY_COLOR;

    vec3 overall = blockLight + skyLight;

    return overall;
}

void main() {
    // gbuffers_terrain has already updated foliage color and light
    vec3 albedo = texture2D(colortex0, texCoords).rgb;

    // Grab lightmap info
    vec2 lightMapCoords = texture2D(colortex2, texCoords).xy;
    vec2 updatedLm = genUpdatedLm(lightMapCoords);
    vec3 lmColor = genLmColor(updatedLm);

    vec3 nor = normalize(texture2D(colortex1, texCoords).rgb * 2.0 - 1.0);
    float nDotL = max(0.0, dot(nor, normalize(sunPosition)));

    vec3 diffuse = albedo * (lmColor + nDotL + KA);
    
    // bluer
    // vec3 blueTintDiffuse = vec3(diffuse.r * 0.8, diffuse.g * 0.8, diffuse.b * 1.4);

    // Final 
    outColor0 = vec4(diffuse, 1.0);
    // outColor0 = vec4(blueTintDiffuse, 1.0);
    // outColor0 = vec4(updatedLm, 0.0, 0.0);
}