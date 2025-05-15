#version 330 compatibility

uniform sampler2D colortex0;

in vec2 texcoord;

const int shadowMapResolution = 2048;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

const float invGammaCorrection = 1.0 / 2.2;

/*
const int colortex0Format = RGB16
*/
void main() {
    color = texture(colortex0, texcoord);
    // color.rgb = pow(color.rgb, vec3(1.0 / 2.2));
    color.rgb = pow(color.rgb, vec3(invGammaCorrection));
}