#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

// CUSTOM
uniform float size;
uniform float ring_width;

#define M_PI 3.1415926535897932384626433832795

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main()
{
    float outerRad = size / 2.0;
    vec2 pos = fragTexCoord * size;
    vec2 center = vec2(size, size) / 2.0;
    float hue = atan(-(fragTexCoord.y - 0.5), fragTexCoord.x - 0.5) / (M_PI * 2.0);
    float d = distance(center, pos);
    float innerRad = outerRad - ring_width;
    if (d <= outerRad && d >= innerRad) {
        finalColor = vec4(hsv2rgb(vec3(hue, 1.0, 1.0)), 1.0);
    } else {
        finalColor = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
