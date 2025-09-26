import std;
import hotkey; // Env

struct EditPaths {
	static Path temp_projects = Env.edit_global_dir/"temp_projects";
	static Path temp_crust_in = Env.edit_global_dir/"temp_crust_in";
	static Path temp_c_out = Env.edit_global_dir/"temp_c_out";
}
