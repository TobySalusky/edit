import std;
import hash;

@no_hr
HashMap<char^, void^> __crust_hr_map;

// TODO: this should not be in normal std/

// WARNING: anything before all globals are loaded (load_xx_begin / load_var) must be VERY CAREFUL about the globals they touch... since everything not no_hr will be null!!!!
void __crust_hr_load_globals_begin() {
	__crust_hr_map = .();

	let lines = io.lines_opt("./__crust_hr_vars.txt").! else return;
	defer lines.delete();

	for (let line in lines) {
		string str = .(line);

		int colon_index = str.index_of(":");
		if (colon_index != -1) {
			string name = str.substr_til(colon_index);
			// don't free name, b/c we want it to live in hr-map!

			string num_str = str.substr_from(colon_index + 1);
			defer num_str.delete();
			ulong ptr_ulong = c:atol(num_str.str);
			void^ ptr = ptr_ulong as void^;

			__crust_hr_map.insert(name, ptr);
		}
	}
}
void __crust_hr_load_globals_end() {
	for (let! kv in __crust_hr_map) {
		free(kv.key);
	}
	__crust_hr_map.delete();
}

void __crust_hr_save_globals_begin() {
	io.rm("./__crust_hr_vars.txt");
}
void __crust_hr_save_globals_end() {}

void^ __crust_hr_load_global(char^ name) {
	return __crust_hr_map.get_opt(name).! or NULL;
}

void __crust_hr_save_global(char^ name, void^ ptr) {
	println(t"save: {name}");
	io.append_file_text("./__crust_hr_vars.txt", t"{name}:{ptr as ulong}\n");
}
