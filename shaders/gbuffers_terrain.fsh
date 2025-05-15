#version 330
#include "/common.glsl"

// Atlases or maps based on UV data
uniform sampler2D gtexture;
uniform sampler2D lightmap;

/* DRAWBUFFERS:012 */
// outColor0 should go to the first color attachment draw buffer
layout (location = 0) out vec4 outColor0; // ALBEDO
layout (location = 1) out vec4 outColor1; // NORMAL
layout (location = 2) out vec4 outColor2; // LIGHTMAP

in vec2 texCoords;
in vec3 blockColor;
in vec2 lightMapCoords;
in vec3 vNor;

void main() {
    // Read from texture atlas -> apply foliage color
    vec4 texColor = texture(gtexture, texCoords);
    // vec3 lightColor = pow(texture(lightmap, lightMapCoords).rgb, vec3(GAMMA_CORRECTION));
    vec3 albedo = pow(texColor.rgb, vec3(GAMMA_CORRECTION)) * pow(blockColor, vec3(GAMMA_CORRECTION));

    // Omit see through fragments
    if (texColor.a < 0.1) {
        discard;
    }

    outColor0 = vec4(pow(albedo, vec3(1 / GAMMA_CORRECTION)), texColor.a);
    outColor1 = vec4(vNor * 0.5 + 0.5, 1.0);
    outColor2 = vec4(lightMapCoords, 0.0, 1.0);
}