#include "prelude.h"

#include <stdarg.h>

FILE* html_out_target = NULL;

int talloc_chunk_size = 2048; // currently, anything over this size will guaranteed fail

void* talloc_ptr = NULL;
int talloc_size_remaining = 0;

void* old_talloc_ptrs[124];
int num_old_talloc_ptrs = 0;
int max_old_talloc_ptrs = 124;

void system_f(const char* fmt, ...) { // danger!
   va_list args;

   va_start(args, fmt);
   char* cmd = malloc_sprintf(fmt, args);
   va_end(args);

   system(cmd); // DANGER!!!
   free(cmd);
}

void println(const char* ln_str) {
	printf("%s\n", ln_str);
}

void panic_f(const char* fmt, ...) {
	va_list args;

	printf("\e[31m");

	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);

	printf("\e[0m\n");

	exit(1);
}

void html_out(const char* file) {
	if (html_out_target != NULL) {
		fclose(html_out_target);
	}

	html_out_target = fopen(file, "w");
	if (html_out_target == NULL) {
		panic_f("html_set_output failed for file %s", file);
	}
}

void html_f(const char* fmt, ...) {
   if (html_out_target == NULL) {
	   __tpp_panic("no html_target! (call `html_out(<file_name>)` before using any html!)");
   }

   va_list args;
   
   va_start(args, fmt);
   vfprintf(html_out_target, fmt, args);
   va_end(args);
}

// credit: https://stackoverflow.com/questions/3774417/sprintf-with-automatic-memory-allocation
char* malloc_sprintf(const char* fmt, ...) {
   va_list args;

   va_start(args, fmt);
   size_t needed = vsnprintf(NULL, 0, fmt, args) + 1; // +1 for null-term
   va_end(args);

   char* buffer = malloc(needed);

   va_start(args, fmt);
   vsnprintf(buffer, needed, fmt, args);
   va_end(args);

   buffer[needed - 1] = '\0';

   return buffer;
}

char* talloc_sprintf(const char* fmt, ...) {
   va_list args;

   va_start(args, fmt);
   size_t needed = vsnprintf(NULL, 0, fmt, args) + 1; // +1 for null-term
   va_end(args);

   char* buffer = talloc(needed);

   va_start(args, fmt);
   vsnprintf(buffer, needed, fmt, args);
   va_end(args);

   buffer[needed - 1] = '\0';

   return buffer;
}

void* talloc(int n) {
	if (n > talloc_chunk_size) {
		panic_f("tried to talloc %d bytes, which is impossible (TODO: allow larger talloc)", n);
	}
	if (talloc_ptr == NULL || n > talloc_size_remaining) {
		if (talloc_ptr != NULL) {
			old_talloc_ptrs[num_old_talloc_ptrs++] = talloc_ptr;
		}
		talloc_ptr = malloc(talloc_chunk_size);
		if (talloc_ptr == NULL) {
			__tpp_panic("talloc's malloc failed!");
		}
		talloc_size_remaining = talloc_chunk_size;
	}

	void* ret = talloc_ptr + (talloc_chunk_size - talloc_size_remaining);
	talloc_size_remaining -= n; // could combine this, and not modify talloc_ptr
	return ret;
}

void tfree() {
	for (int i = 0; i < num_old_talloc_ptrs; i++) {
		free(old_talloc_ptrs[i]);
	}
	free(talloc_ptr);
	talloc_ptr = NULL;
	talloc_size_remaining = 0;
	num_old_talloc_ptrs = 0;
}

char* __tpp_internal_bool_to_string(bool b) {
	return b ? "true" : "false";
}

void __tpp_panic(char* msg) {
	printf("\e[31m%s\e[0m\n", msg);
	exit(1);
}

void __tpp_assert(bool panic_condition, char* panic_msg) {
	if (panic_condition) {
		__tpp_panic(panic_msg);
	}
}

IndexRange __tpp_range(int startInclusive, int endExclusive) {
	return (IndexRange){ .startInclusive = startInclusive, .endExclusive = endExclusive };
}
