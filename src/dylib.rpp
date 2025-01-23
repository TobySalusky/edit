import std;
c:import "dynamic_lib.h";

c:c:`
#pragma GCC diagnostic push
#ifdef _WIN32
	#pragma GCC diagnostic ignored "-Wdiscarded-qualifiers" // issue w/ do_file_tree_dir_visit
#else
	#pragma GCC diagnostic ignored "-Wincompatible-pointer-types-discards-qualifiers" // issue w/ do_file_tree_dir_visit
#endif
`;

@extern
struct dynamic_lib_result {
	void^ handle;
	char^ error; // NOTE: should be const
}

@extern
dynamic_lib_result dynamic_lib_open(char^ file_path);

@extern
int dynamic_lib_close(void^ lib_handle);

@extern
dynamic_lib_result dynamic_lib_load_fn(void^ lib_handle, char^ fn_name);

@extern
char^ DYNAMIC_LIB_EXTENSION;

struct DyLib {
	void^ handle;

	// static Err<DyLib, char^> Load(Path dylib_path) {
	// 	void^ handle = c:dlopen(dylib_path.str, c:RTLD_LAZY);
	//
	// 	if (handle == NULL) {
	// 		char^ err = c:dlerror();
	// 		return err;
	// 	}
	//
	// 	return DyLib{ :handle };
	// }

	static DyLib LoadOrPanic(Path dylib_path) {
		let res = dynamic_lib_open(dylib_path);

		if (res.handle == NULL) {
			panic(t"LoadOrPanic({dylib_path.str}) failed: {res.error}");
		}

		return DyLib{ .handle = res.handle };
	}

	// static DyLib LoadOrPanic(Path dylib_path) {
	// 	let it = Self.Load(dylib_path);
	//
	// 	if (it is char^) {
	// 		panic(it as char^);
	// 	}
	//
	// 	return it as DyLib;
	// }

	Result<void^, char^> Sym(char^ fn_name) {
		let res = dynamic_lib_load_fn(handle, fn_name);
		if (res.handle == NULL) {
			return res.error;
		}

		return res.handle;
	}

	void^ SymOrPanic(char^ fn_name) {
		let it = this.Sym(fn_name);

		if (it is Err) {
			panic(t"SymOrPanic({fn_name}) failed: {it as Err}");
		}

		return it as Ok;
	}

	void Unload() {
		dynamic_lib_close(handle);
	}
}

c:c:`
#pragma GCC diagnostic pop
`;
