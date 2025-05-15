#define PI 3.1415926535897932384626433832795
#define TWO_PI 6.283185307179586476925286766559

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
    vec4 homPos = projectionMatrix * vec4(position, 1.0);
    return homPos.xyz / homPos.w;
}
