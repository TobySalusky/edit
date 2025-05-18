import std;
import yaml;
import rl;

Path global_storage_path = make_path(
	// TODO: un-hardcode!
	"/Users/toby/Documents/paint/" // bad location tbh
);

void setup_global_paint_storage() {
	io.mkdir_if_nonexistent(global_storage_path);

	io.mkdir_if_nonexistent(global_autosaves);
	io.mkdir_if_nonexistent(global_autosaves_imgs);
	io.mkdir_if_nonexistent(global_autosaves_projects);

	// TODO: should we just open empty yaml_object if fail to deserialize/load/read file?
	io.touch_if_nonexistent(global_settings_path);
	io.touch_if_nonexistent(global_meta_path);
}

struct GlobalSettings {
	char^ preferred_display_name;

	void load() -> this.serialize(true);
	void store() -> this.serialize(false);

	void serialize(bool is_load) {
		yaml_serializer settings = make_yaml_serializer(global_settings_path, is_load);
		defer settings.finish();

		settings.str_default(^preferred_display_name, "preferred_display_name", "anon");
	}
}
GlobalSettings global_settings;
Path global_settings_path = global_storage_path/"settings.yml";

struct GlobalMetaData {
	int next_project_id; // monotonically increasing, starts at 0 - use for autosaves & untitled projects :)

	void load() -> this.serialize(true);
	void store() -> this.serialize(false);

	void serialize(bool is_load) {
		yaml_serializer meta = make_yaml_serializer(global_meta_path, is_load);
		defer meta.finish();

		meta.int_default(^next_project_id, "next_project_id", 0);
	}

	// ---
	void initial_update() {
		// TODO: ? why here ?
		next_project_id++;
	}

	// ---

	Path get_autosave_img_path() {
		return global_autosaves_imgs/t"{next_project_id%D09}.png";
	}
}
GlobalMetaData global_meta_data;
Path global_meta_path = global_storage_path/"meta.yml";

// autosaves ---
Path global_autosaves = global_storage_path/"autosaves";
Path global_autosaves_imgs = global_storage_path/"autosaves/imgs";
Path global_autosaves_projects = global_storage_path/"autosaves/projects";
// -------------
