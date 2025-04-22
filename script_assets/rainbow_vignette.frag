#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;
// -------------------------------------------

// CUSTOM
uniform float intensity;
uniform float zoom;
uniform float offset;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

int width = 1200;
int height = 900;

void main() {
	float a = intensity;
	float x = abs((fragTexCoord.x - 0.5) * zoom + offset * 2);
	int fx = int(floor(x));
	x -= fx;
	if (fx % 2 == 1) {
		x = 1-x;
	}

	float y = abs((fragTexCoord.y - 0.5) * zoom + offset * -1.5);
	int fy = int(floor(y));
	y -= fy;
	if (fy % 2 == 1) {
		y = 1-y;
	}

	float vignette_mult = length(fragTexCoord - vec2(0.5, 0.5));
	a *= vignette_mult * vignette_mult;
	finalColor = vec4(hsv2rgb(vec3(sin(x) + tan(y * cos(offset)), 1, 1)), a);
}
