c:import "libtcc.h";

@extern int TCC_OUTPUT_MEMORY; // output will be run in memory
@extern int TCC_OUTPUT_EXE; // executable file
@extern int TCC_OUTPUT_DLL; // dynamic library
@extern int TCC_OUTPUT_OBJ; // object file
@extern int TCC_OUTPUT_PREPROCESS; // only preprocess

c:`typedef const char* const_char_star;`;

@extern
struct TCCState {
	static void set_realloc(fn_ptr<void^(void^, ulong)> my_realloc) -> c:tcc_set_realloc(my_realloc);

	static Self^ new() -> c:tcc_new();

	void delete() -> c:tcc_delete(^this);
	void set_lib_path(char^ path) -> c:tcc_set_lib_path(^this, path);
	void set_error_func(void^ error_opaque, fn_ptr<void(void^, c:const_char_star)> error_func) -> c:tcc_set_error_func(^this, error_opaque, error_func);
	bool set_options(char^ str) -> c:tcc_set_options(^this, str) != -1;
	bool add_include_path(char^ pathname) -> c:tcc_add_include_path(^this, pathname) != -1;
	bool add_sysinclude_path(char^ pathname) -> c:tcc_add_sysinclude_path(^this, pathname) != -1;
	void define_symbol(char^ sym, char^ value) -> c:tcc_define_symbol(^this, sym, value);
	void undefine_symbol(char^ sym) -> c:tcc_undefine_symbol(^this, sym);
	bool add_file(char^ filename) -> c:tcc_add_file(^this, filename) != -1;
	bool compile_string(char^ buf) -> c:tcc_compile_string(^this, buf) != -1;
	bool set_output_type(int output_type) -> c:tcc_set_output_type(^this, output_type) != -1;
	bool add_library_path(char^ pathname) -> c:tcc_add_library_path(^this, pathname) != -1;
	bool add_library(char^ libraryname) -> c:tcc_add_library(^this, libraryname) != -1;
	bool add_symbol(char^ name, void^ val) -> c:tcc_add_symbol(^this, name, val) != -1;
	bool output_file(char^ filename) -> c:tcc_output_file(^this, filename) != -1;
	bool run(int argc, char^^ argv) -> c:tcc_run(^this, argc, argv) != -1;
	bool relocate() -> c:tcc_relocate(^this) >= 0;
	void^ get_symbol(char^ name) -> c:tcc_get_symbol(^this, name);

	void^ setjmp(void^ jmp_buf, void^ top_func, void^ longjmp) -> c:_tcc_setjmp(^this, jmp_buf, top_func, longjmp);
	void set_backtrace_func(void^ userdata, fn_ptr<int(void^, void^, c:const_char_star, int, c:const_char_star, c:const_char_star)> func) -> c:tcc_set_backtrace_func(^this, userdata, func);
}

