include path("../raylib");
include path("../common");

import std;
import rl;
import script;
import perlin;

EditScript^ __edit_script_ptr;
EditScript& __edit_script() -> *__edit_script_ptr;

int main() {
	println("script.cr setup!");
	return 0;
}

void script_setup(EditScript& edit_script) { __edit_script_ptr = ^edit_script; main(); }
