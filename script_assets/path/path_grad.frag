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
uniform int path_radius;
uniform int texture_mode;

uniform sampler2D grass_texture;
uniform sampler2D brick_texture;

// vec3 hsv2rgb(vec3 c)
// {
//     vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
//     vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
//     return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
// }

int width = 1200;
int height = 900;

vec4 lerp(vec4 from, vec4 to, float proportion) {
	return from * (1 - proportion) + to * proportion;
}

void main() {
	vec2 closest_v = vec2(0, 0);
	float closest_f = 10000;
	bool has_closest = false;
	int stride = 1;
	if (path_radius > 10) { stride = 3; }
	if (path_radius > 20) { stride = 5; }
	if (path_radius > 20) { stride = 7; }
	for (int i = -path_radius; i <= path_radius; i += stride) {
		for (int j = -path_radius; j <= path_radius; j += stride) {
			vec2 diff = vec2(i, j);
			vec4 pixel = texture(texture0, fragTexCoord + diff / vec2(width, height));
			float diff_f = length(diff);
			if (pixel.a > 0.9 && diff_f <= path_radius && diff_f < closest_f) {
				closest_f = diff_f;
				closest_v = diff;
				has_closest = true;
			}
		}
	}

	if (texture_mode == 0) {
		if (has_closest) {
			finalColor = vec4(closest_f / path_radius, 0, 0, 1);
		} else {
			finalColor = vec4(0, 0, 0, 0);
		}
	} else {
		if (has_closest) {
			float amt = (closest_f / path_radius) / 2;
			finalColor = lerp(texture(brick_texture, fragTexCoord * 7), vec4(0,0,0,1), amt);
		} else {
			finalColor = texture(grass_texture, fragTexCoord * 3);
		}
	}
}
