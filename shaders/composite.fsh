#version 330
#include "/common.glsl"

// Uniforms
uniform mat4 modelViewMatrixInverse; // can eventually move to using defines.glsl, want to be as unambiguous as possible for now
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

// Input from other passes
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;

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

// w is < 1 right now, so to undo the perspective divide we divide and bring the xyz back up
// this applies for doing and undoing projections because of the state of w in the projection / proj inv
vec3 projectAndDivide(mat4 proj_mat, vec3 pos) {
    vec4 homogeneous_pos = proj_mat * vec4(pos, 1.0);
    return homogeneous_pos.xyz / homogeneous_pos.w;
}

// Compare closest fragment to sun (shadow buffer) to current fragment to sun. If the cur_frag is more negative than the depth_frag, you are shadowed
// The shadowtex stores it in shadowScreenPos
float isShadowed(void) {
    // Our goal is to get to from "player" screen space to "shadow" clip space.
    /*
        screen space = vec3(texCoords, texture2D(depthtex0, texCoords).x)
        ndc space = screen space * 2.0 - 1.0 because [0, 1] -> [-1, 1]
        view space = projectAndDivide(gbufferProjectionInverse, ndc space)

        feet player space = (gbufferModelViewInverse * vec4(view space, 1.0)).xyz
        shadow view space = (shadowModelView * vec4(feet player space, 1.0)).xyz
        shadow ndc space = projectAndDivide(shadowProjection, shadow view pos)
        shadow screen space = shadow ndc * 0.5 + 0.5
    */

    vec3 screen_pos = vec3(texCoords, texture2D(depthtex0, texCoords).x);
    vec3 ndc_pos = screen_pos * 2.0 - 1.0;
    vec3 view_pos = projectAndDivide(gbufferProjectionInverse, ndc_pos); // w is < 1 right now, so to undo the perspective divide we divide and bring the xyz back up

    vec3 feet_pos = (gbufferModelViewInverse * vec4(view_pos, 1.0)).xyz;
    vec3 shadow_view_pos = (shadowModelView * vec4(feet_pos, 1.0)).xyz;
    // vec4 shadow_clip_pos = shadowProjection * vec4(shadow_view_pos, 1.0);
    vec3 shadow_ndc_pos = projectAndDivide(shadowProjection, shadow_view_pos);
    vec3 shadow_screen_pos = shadow_ndc_pos * 0.5 + 0.5;

    // The fragment has a depth in shadow_screen_pos and the shadow map is in shadowtex0 wherever the u, v coords we stored earlier are
    return step(shadow_screen_pos.z - 0.001, texture2D(shadowtex0, shadow_screen_pos.xy).r);
}

void main() {
    // gbuffers_terrain has already updated foliage color and light
    vec3 albedo = texture2D(colortex0, texCoords).rgb;

    // Grab lightmap info
    vec2 lightMapCoords = texture2D(colortex2, texCoords).xy;
    vec2 updatedLm = genUpdatedLm(lightMapCoords);
    vec3 lmColor = genLmColor(updatedLm);

    // Grab shadow information
    float depth_frag = texture2D(depthtex0, texCoords).x;

    vec3 nor = normalize(texture2D(colortex1, texCoords).rgb * 2.0 - 1.0);
    float nDotL = max(0.0, dot(nor, normalize(sunPosition)));

    vec3 diffuse = albedo * (lmColor + isShadowed() + nDotL + KA);
    
    // bluer
    vec3 blueTintDiffuse = vec3(diffuse.r * 0.8, diffuse.g * 0.8, diffuse.b * 1.4);

    // Final 
    // outColor0 = vec4(diffuse, 1.0);
    outColor0 = vec4(blueTintDiffuse, 1.0);
    // outColor0 = vec4(updatedLm, 0.0, 0.0);
}