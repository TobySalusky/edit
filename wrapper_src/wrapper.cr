include path("../src/clay");
include path("../src/dylib.cr");

include path("../common/yaml.cr");
include path("../src/global_settings.cr");

import rl;

import std;
import dylib;
import hr_std;
import map;

Path lib_p = .("./build/libedit.dylib");
Path active_lib_p = .("./build/edit");

DyLib? lib = none;
fn_ptr<bool()> do_hr_fn = NULL;
fn_ptr<void()> tick_fn = NULL;
fn_ptr<void(char^)> warn_fn = NULL;

void void_call_or_err_msg(DyLib& lib, char^ fn_name) {
	println(t"dll-call: [[{fn_name}]]");
	switch (lib.Sym(fn_name)) {
		void^ fn_ptr -> {
			 let fn = fn_ptr as fn_ptr<void()>;
			 fn();
		},
		char^ err -> {
			println(t"{fn_name}: {err=}");
		}
	}
}

void LoadLib(int argc, char^^ argv, bool rebuild) {
	if (rebuild) {
		println("================================================================================");
		system("./scripts/mac/gen.sh && cmake --build build");
		println("================================================================================");

		if (!io.file_exists(lib_p)) {
			WarnEdit("failed to re-build");
			println("================================================================================");
			return;
		}

		@partial switch (lib) {
			DyLib l -> {
				void_call_or_err_msg(l, "__crust_hr_save_globals");
				l.Unload();
			}
		}
	}

	if (rebuild) {
		println("Re-build done!");
		println("================================================================================");
	}

	if (io.file_exists(lib_p)) {
		io.mv(lib_p, active_lib_p);
	}

	switch (DyLib.Load(active_lib_p)) {
		DyLib new_lib -> {
			void_call_or_err_msg(new_lib, "__crust_init_globals");
			if (lib is None) {
				(new_lib.SymOrPanic("Init") as fn_ptr<void(int, char^^)>)(argc, argv);
			} else {
				(new_lib.SymOrPanic("PostHotReload") as fn_ptr<void()>)();
			}

			lib = new_lib;

			do_hr_fn = lib.!.SymOrPanic("DoHotReload") as ..;
			tick_fn = lib.!.SymOrPanic("Tick") as ..;
			warn_fn = lib.!.SymOrPanic("ExternalHotReloadWarn") as ..;
		},
		char^ err -> {
			println(t"FAILED TO LOAD DYLIB: {err=}");
		}
	}
}

void WarnEdit(char^ msg) {
	if (warn_fn != NULL) {
		warn_fn(msg);
	}
	println("[WRAPPER-WARNING]:");
	println(msg);
}

int main(int argc, char^^ argv) {
	io.rm_if_existent("__crust_hr_vars.txt");

	rl.SetTraceLogLevel(rl.LogLevel.ALL);

	rl.SetConfigFlags(c:FLAG_VSYNC_HINT ~| c:FLAG_WINDOW_RESIZABLE ~| c:FLAG_MSAA_4X_HINT);
	rl.InitWindow(GlobalSettings.get_int("window_width", 500), GlobalSettings.get_int("window_height", 500), "edit");

	rl.SetTargetFPS(60);
	rl.SetExitKey(0);

	LoadLib(argc, argv, false);

	while (!rl.WindowShouldClose()) {
		if (do_hr_fn != NULL && do_hr_fn()) {
			LoadLib(argc, argv, true);
		}

		if (tick_fn == NULL) {

			rl.BeginDrawing();
				rl.ClearBackground(Colors.Blue);
				d.Text("Yabai... no tick_fn for wrapper :(", 30, 30, 32, Colors.White);
			rl.EndDrawing();
		} else {
			tick_fn();
		}
	}

	@partial switch (lib) {
		DyLib l -> {
			void_call_or_err_msg(l, "Deinit");
			l.Unload();
		}
	}

	io.rm_if_existent("__crust_hr_vars.txt");

	return 0;
}
