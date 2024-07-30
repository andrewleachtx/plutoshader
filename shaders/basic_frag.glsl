#version 330

// Atlases or maps based on UV data
uniform sampler2D gtexture;
uniform sampler2D lightmap;

/* DRAWBUFFERS:0 */
// outColor0 should go to the first color attachment draw buffer
layout (location = 0) out vec4 outColor0;

in vec2 texCoords;
in vec3 foliageColor;
in vec2 lightMapCoords;

void main() {
    // Get the color of light
    vec3 lightColor = pow(texture(lightmap, lightMapCoords).rgb, vec3(2.2));

    // Our current color is grayscaled
    vec4 outputColorTexture = pow(texture(gtexture, texCoords), vec4(2.2));
    vec3 outputColor = outputColorTexture.rgb * pow(foliageColor, vec3(2.2)) * lightColor;
    float transparency = outputColorTexture.a;

    // Account for transparent values
    if (transparency < 0.1) {
        discard;
    }

    outColor0 = pow(vec4(outputColor, transparency), vec4(1 / 2.2));
}