c:import <"math.h">;

float Sin01(float angle) {
	return (c:sin(angle) + 1) / 2;
}

float dabs(float x) {
	return c:fabsf(x);
}
