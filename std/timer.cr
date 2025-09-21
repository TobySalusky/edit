c:import <"time.h">;

struct timer { 
	int start;

	construct() -> {
		.start = c:clock()
	};

	float time() {
		float f = (c:clock() - start);
		return f / c:CLOCKS_PER_SEC;
	}

	void print(char^ name) {
		printf("%s took %f seconds\n", name, this.time());
	}
}

timer start_timer() -> {
	.start = c:clock()
};
