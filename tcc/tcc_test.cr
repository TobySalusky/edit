// import std;
// import tcc;
// import timer;
//
// struct Unit {}
// struct Err {}
//
// Result<Unit, Err> DoIt(char^ expr) {
// 	let timer = timer();
// 	{ // crust compilation
// 		io.rmrf_if_existent("tcc_temp");
// 		io.mkdir("tcc_temp");
//
// 		let code = t"include path(\"../../std\");import std;\nint fn(int a) \{ return {expr}; }";
// 		io.write_file_text("tcc_temp/temp.cr", code);
//
// 		system(t"crust build tcc_temp -out-dir:tcc_tout -build-type:cgen -unity-build");
// 	}
//
// 	TCCState& tcc = *.new().! else return Err{};
// 	defer tcc.delete();
//
// 	tcc.set_options("-g");
// 	tcc.set_output_type(TCC_OUTPUT_MEMORY);
// 	// typedef int TCCBtFunc(void *udata, void *pc, const char *file, int line, const char* func, const char *msg);
// 	tcc.set_backtrace_func(NULL, (void^ udata, void^ pc, c:const_char_star file, int line, c:const_char_star func, c:const_char_star msg):int -> {
// 		println(t"backtrace from: {file as char^}");
// 		// panic("bad news bears");
//
// 		return 0;
// 	});
//
// 	{
// 		tcc.add_include_path("tcc_tout");
// 		tcc.add_file("tcc_tout/__unity__.c");
// 	}
// 	tcc.relocate().! else return Err{};
//
// 	fn_ptr<int(int)> fn = (tcc.get_symbol("fn").! else return Err{}) as ..;
//
// 	for i in 0..10 {
// 		println(t"{fn(i)=}");
// 	}
// 	
// 	return Unit{};
// }
//
// int main() {
// 	// DoIt("&{ if (a % 2 == 0) { return a * 20; } return a; }");
// 	// DoIt("&{ int[] il = {}; defer il.delete(); il.add(a * 2); return il[il.size/2] + 1; }");
// 	DoIt("&{ int^ np = NULL; return *np; }");
// 	// DoIt("&{ int a = 10; int b = 0; return a / b; }");
// 	
// 	return 0;
// }
