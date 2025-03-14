import std;
import map;

import dylib;

c:`typedef void(*CustomScriptSetupFn)(void);`;

struct CodeManager {
	Path dylib_path;
	Path old_dylib_path;
	Path new_dylib_path;

	Opt<DyLib> code_handle;
	StrMap<Result<void^, char^>> fn_handles;

	construct(char^ result_dir) {
		Path dir = .(result_dir);
		return {
			.dylib_path =     dir/t"libscript.{DYNAMIC_LIB_EXTENSION}",
			.old_dylib_path = dir/t"oldlibscript.{DYNAMIC_LIB_EXTENSION}",
			.new_dylib_path = dir/t"newlibscript.{DYNAMIC_LIB_EXTENSION}",

			.code_handle = none,
			.fn_handles = .(),
		};
	}

	void Load() {
		code_handle = DyLib.LoadOrPanic(dylib_path);

		// reload function pointers!
		for (int i in 0..fn_handles.size) {
			let fn_name = fn_handles.keys[i];
			fn_handles.values[i] = this.Lib().Sym(fn_name);
		}

		let setup_fn_res = this.GetFn("script_setup"); 
		switch (setup_fn_res) {
			void^ fn_ptr -> {
				c:CustomScriptSetupFn setup_fn = fn_ptr;
				setup_fn();
			},
			char^ err -> {
				panic(t"Error loading `script_setup` function. Make sure this is correctly named in script_main.rpp! Error: {err}");
			}
		}
	}

	void PreLoadTakeCareOfPreppedReload() {
		if (!io.file_exists(new_dylib_path)) { return; }

		io.rm_if_existent(old_dylib_path);
		io.mv(dylib_path, old_dylib_path);
		io.mv(new_dylib_path, dylib_path);
	}

	void CheckModifiedTimeAndReloadIfNecessary() {
		if (!io.file_exists(new_dylib_path)) { return; }

		println("unloading script.dylib for hot-reload");
		this.Lib().Unload();

		io.rm_if_existent(old_dylib_path);
		io.mv(dylib_path, old_dylib_path);
		io.mv(new_dylib_path, dylib_path);
		println("reloading script.dylib for hot-reload");
		this.Load();
	}

	DyLib& Lib() {
		if (code_handle is Some) {
			return code_handle as Some;
		}
		panic("Lib() failed - not loaded!");
		// unreachable
		DyLib^ blah = NULL;
		return *blah;
	}

	// void Reload() {
	// 	this.Lib().Unload();
	// 	this.Load();
	// }
	//
	void Unload() {
		this.Lib().Unload();
		code_handle = none;
		fn_handles.delete();
	}

	Result<void^, char^> GetFn(char^ fn_name) {
		if (fn_handles.has(fn_name)) {
			return fn_handles.get(fn_name);
		}

		let res = this.Lib().Sym(fn_name);
		fn_handles.put(fn_name, res);

		return res;
	}
}

// NOTE: assumes program is run from git repo root (`edit/`)
CodeManager code_man = .("test_resource");
