c:import <"pthread.h">;
c:import <"sys/types.h">;
c:import <"unistd.h">;

// return pid?
void go(c:tpp_void_star fn) {
	c:pthread_t tid;
	c:pthread_create(^tid, c:NULL, fn, c:NULL);
}

void go_with(c:tpp_void_star fn, c:tpp_void_star arg) {
	c:pthread_t tid;
	c:pthread_create(^tid, c:NULL, fn, arg);
}

void threads_join_all() {
	c:pthread_exit(c:NULL);
}
