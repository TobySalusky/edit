#pragma once

#ifdef _WIN32

#ifdef __cplusplus
extern "C" {
#endif

struct HINSTANCE__ { int unused; };
struct HINSTANCE__* LoadLibraryA(const char* file_path);
extern "C" int FreeLibrary(struct HINSTANCE__* lib_handle);
long long (*GetProcAddress(struct HINSTANCE__* lib_handle, const char* fn_name))();

#ifdef __cplusplus
}
#endif

#elif __APPLE__
#include <dlfcn.h>
#elif __linux__
// TODO: implement for linux!
#endif

typedef struct dynamic_lib_result_t {
	void* handle;
	const char* error; // NULL if none
} dynamic_lib_result;

static inline dynamic_lib_result dynamic_lib_open(const char* file_path) {
#ifdef _WIN32
	void* handle = (void*) LoadLibraryA(file_path);
	return (dynamic_lib_result) {
		.handle = handle,
		.error = handle == 0 ? "dynamic_lib_open(...) failed (WINDOWS: reason unknown)" : 0,
	};
#elif __APPLE__
	void* handle = dlopen(file_path, RTLD_LAZY);
	char* error = handle == 0 ? dlerror() : 0;
	return (dynamic_lib_result) {
		.handle = handle,
		.error = error,
	};
#elif __linux
	return (dynamic_lib_result) {
		.handle = 0,
		.error = "Unsupported OS (LINUX SUPPORT TODO)",
	};
#else
	return (dynamic_lib_result) {
		.handle = 0,
		.error = "Unsupported OS",
	};
#endif
}

// 1 == success
// 0 == failure
static inline int dynamic_lib_close(void* lib_handle) {
#ifdef _WIN32
	struct HINSTANCE__* win_lib_handle = (struct HINSTANCE__*) lib_handle;
	return (FreeLibrary(win_lib_handle) == 0) ? 0 : 1;
#elif __APPLE__
	return (dlclose(lib_handle) == 0) ? 1 : 0;
#elif __linux
	// TODO: implement linux
	return 0;
#else
	// nothing happens (not defined for OS)
	return 0;
#endif
}

static inline dynamic_lib_result dynamic_lib_load_fn(void* lib_handle, const char* fn_name) {
#ifdef _WIN32
	struct HINSTANCE__* win_lib_handle = (struct HINSTANCE__*) lib_handle;
	void* handle = (void*) GetProcAddress(win_lib_handle, fn_name);
	return (dynamic_lib_result) {
		.handle = handle,
		.error = handle == 0 ? "dynamic_lib_load_fn(...) failed (WINDOWS: reason unknown)" : 0,
	};
#elif __APPLE__
	void* handle = dlsym(lib_handle, fn_name);
	char* error = handle == 0 ? dlerror() : 0;
	return (dynamic_lib_result) {
		.handle = handle,
		.error = error,
	};
#elif __linux
	return (dynamic_lib_result) {
		.handle = 0,
		.error = "Unsupported OS (LINUX SUPPORT TODO)",
	};
#else
	return (dynamic_lib_result) {
		.handle = 0,
		.error = "Unsupported OS",
	};
#endif
}

// returns: dll|dylib|so
static inline const char* dynamic_lib_extension(void) {
#ifdef _WIN32
	return "dll";
#elif __APPLE__
	return "dylib";
#elif __linux
	return "so";
#else
	return 0;
#endif
}
