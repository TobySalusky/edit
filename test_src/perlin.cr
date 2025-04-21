c:import "stb_perlin.h";

c:c:`
#define STB_PERLIN_IMPLEMENTATION
#include "stb_perlin.h"
`;

struct stb_perlin {
	float noise3(float x, float y, float z, int x_wrap, int y_wrap, int z_wrap) -> c:stb_perlin_noise3(x, y, z, x_wrap, y_wrap, z_wrap);
	float noise3_seed(float x, float y, float z, int x_wrap, int y_wrap, int z_wrap, int seed) -> c:stb_perlin_noise3_seed(x, y, z, x_wrap, y_wrap, z_wrap, seed);

	float ridge_noise3(float x, float y, float z, float lacunarity, float gain, float offset, int octaves) -> c:stb_perlin_ridge_noise3(x, y, z, lacunarity, gain, offset, octaves);
	float fbm_noise3(float x, float y, float z, float lacunarity, float gain, int octaves) -> c:stb_perlin_fbm_noise3(x, y, z, lacunarity, gain, octaves);
	float turbulence_noise3(float x, float y, float z, float lacunarity, float gain, int octaves) -> c:stb_perlin_turbulence_noise3(x, y, z, lacunarity, gain, octaves);

	// Typical values to start playing with:
	//     octaves    =   6     -- number of "octaves" of noise3() to sum
	//     lacunarity = ~ 2.0   -- spacing between successive octaves (use exactly 2.0 for wrapping output)
	//     gain       =   0.5   -- relative weighting applied to each successive octave
	//     offset     =   1.0?  -- used to invert the ridges, may need to be larger, not sure
}

struct Stb {
	stb_perlin perlin;
}

Stb stb = {
	.perlin = stb_perlin{}
};
