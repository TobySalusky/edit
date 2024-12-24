#pragma once

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdbool.h>

// TODO: add tmalloc (temp malloc, with some t_reset function or something [eg. on frame boundaries])

// NOTE: sus
typedef struct dirent dirent;

extern FILE* html_out_target;

void println(const char* fmt, ...);
void html_out(const char* file); // callable
void html_f(const char* fmt, ...); // prob shouldn't be callable?

// system() exposed by stdlib/stdio?
void system_f(const char* fmt, ...); // danger!

char* malloc_sprintf(const char* fmt, ...);
char* talloc_sprintf(const char* fmt, ...);

void* talloc(int n);
void tfree(); // not thread safe (don't use temp-alloc from other threads!)

char* __tpp_internal_bool_to_string(bool b);

void __tpp_panic(char* msg);
void __tpp_assert(bool panic_condition, char* panic_msg);

typedef void* tpp_void_star;


int float_to_int(float f);
float int_to_float(int i);

typedef struct IndexRange { // TODO: include as .tpp impl
	int startInclusive; int endExclusive;
} IndexRange;
IndexRange __tpp_range(int startInclusive, int endExclusive);
