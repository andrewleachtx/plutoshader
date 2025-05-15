#version 330 compatibility
#include /lib/distort.glsl
#include /lib/util.glsl

uniform float viewWidth;
uniform float viewHeight;
uniform float worldTime;

uniform vec2 screenCoord;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D noisetex;

in vec2 texcoord;

const int shadowMapResolution = 2048;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);
const vec3 sunlightColor = vec3(1.0);
const vec3 ambientColor = vec3(0.1);
/*
- shadowtex0 contains everything that casts a shadow
- shadowtex1 contains only things which are fully opaque and cast a shadow
- shadowcolor0 contains the color (including how transparent it is) of things which cast a shadow.
*/
vec3 getShadow(vec3 shadowScreenPos) {
    // Gets the shadow value from the shadow map
    float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);

    if (transparentShadow == 1.0) {
        return vec3(1.0);
    }

    float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r);

    if (opaqueShadow == 0.0) {
        return vec3(0.0);
    }

    vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);

    return shadowColor.rgb * (1.0 - shadowColor.a);
}

vec4 getNoise(vec2 coord) {
    ivec2 screenCoord = ivec2(coord * vec2(viewWidth, viewHeight));
    ivec2 noiseCoord = screenCoord % 64;
    return texelFetch(noisetex, noiseCoord, 0);
}

// For each pixel, we can avg over the neighboring pixels' shadow values so borders are averaged
vec3 getSoftShadow(vec4 shadowClipPos) {
    const float range = SHADOW_SOFTNESS * 0.5; // how far away from the original position we take our samples from
    const float increment = range / SHADOW_QUALITY; // distance between each sample

    float noise = getNoise(texcoord).r;

    // Random angle (2pi * noise [0, 1])
    float theta = noise * radians(360.0); // random angle using noise value
    float cosTheta = cos(theta);
    float sinTheta = sin(theta);

    // (our 2D rotation matrix)
    mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta);

    vec3 shadowAccum = vec3(0.0); // sum of all shadow samples
    float samples = 0.0;

    float invShadowMapResolution = 1.0 / float(shadowMapResolution);

    for (float x = -range; x <= range; x += increment) {
        for (float y = -range; y <= range; y+= increment) {
            vec2 offset = rotation * vec2(x, y) * invShadowMapResolution; // we divide by the resolution so our offset is in terms of pixels
            vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0); // add offset
            offsetShadowClipPos.z -= 0.001; // apply bias // FIXME: If grass or translucent blocks appear weird, reduce this
            offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
            vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
            vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
            shadowAccum += getShadow(shadowScreenPos); // take shadow sample

            samples++;
        }
    }

    // Take the shadow and divide by the number of samples
    return shadowAccum / samples;
}

void main() {
    color = texture(colortex0, texcoord);
    color.rgb = pow(color.rgb, vec3(2.2));

    // The .r component of the depth texture is the depth from the camera
    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        return;
    }
     
    vec2 lightmap = texture(colortex1, texcoord).rg;
    vec3 encodedNormal = texture(colortex2, texcoord).rgb;
    vec3 normal = normalize((encodedNormal - 0.5) * 2.0);

    vec3 blocklight = lightmap.r * blocklightColor;
    vec3 skylight = lightmap.g * skylightColor;
    vec3 ambient = ambientColor;

    vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
    vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
    vec3 shadow = getSoftShadow(shadowClipPos);
    vec3 lightVector = normalize(shadowLightPosition);
    vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
    vec3 sunlight = sunlightColor * clamp(dot(normal, worldLightVector), 0.0, 1.0) * shadow;

    color.rgb *= blocklight + skylight + ambient + sunlight;
}