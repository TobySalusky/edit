c:import <"pthread.h">;
c:import <"sys/types.h">;
c:import <"unistd.h">;
import std;

// return pid?
void go(c:void^ fn) {
	c:pthread_t tid;
	c:pthread_create(^tid, NULL, fn, NULL);
}

void go_with(c:void^ fn, void^ user_data) {
	c:pthread_t tid;
	c:pthread_create(^tid, NULL, fn, user_data);
}

void threads_join_all() {
	c:pthread_exit(NULL);
}

@extern struct pthread_mutex_t {
	int init() -> c:pthread_mutex_init(^this, NULL);
	int lock() -> c:pthread_mutex_lock(^this);
	int unlock() -> c:pthread_mutex_unlock(^this);
}
