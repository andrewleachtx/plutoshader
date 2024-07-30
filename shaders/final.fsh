#version 330

uniform sampler2D colortex0;

/* DRAWBUFFERS:0 */
// outColor0 should go to the first color attachment draw buffer
layout (location = 0) out vec4 outColor0;

in vec2 texCoords;

void main() {
    // Take color from our last composite and just store it.
    outColor0 = (texture2D(colortex0, texCoords));
}