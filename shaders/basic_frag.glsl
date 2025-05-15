#version 330
#include "common.glsl"

// Atlases or maps based on UV data
uniform sampler2D gtexture;
uniform sampler2D lightmap;

/* DRAWBUFFERS:0 */
// outColor0 should go to the first color attachment draw buffer
layout (location = 0) out vec4 outColor0;

in vec2 texCoords;
in vec3 blockColor;
in vec2 lightMapCoords;

void main() {
    // Get the color of light
    vec3 lightColor = pow(texture(lightmap, lightMapCoords).rgb, vec3(GAMMA_CORRECTION));

    // Our current color is grayscaled
    vec4 outputColorTexture = texture(gtexture, texCoords);
    vec3 outputColor = pow(outputColorTexture.rgb, vec3(GAMMA_CORRECTION)) * pow(blockColor, vec3(GAMMA_CORRECTION)) * lightColor;
    float transparency = outputColorTexture.a;

    // Account for transparent values
    if (transparency < 0.1) {
        discard;
    }

    outColor0 = vec4(pow(outputColor, vec3(1 / GAMMA_CORRECTION)), texture(gtexture, texCoords).a);
}