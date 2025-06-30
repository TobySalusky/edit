import std;
import yaml;

struct GlobalSettings {
	static Path settings_path = .("saves/global_settings.yaml");
	static yaml_object obj = _InitObj();

	static yaml_object _InitObj() {
		// TODO:  very dirty!!!!!
		if (c:chdir("/Users/toby/dev/edit") == -1) {
			panic("setting cwd to /Users/toby/dev/edit failed... exiting!");
		}

		// TODO: /very dirty!!!!!

		if (io.file_exists(settings_path)) {
			println(f"successfully loaded existing GlobalSettings from {settings_path.str}");
			return yaml_parser{}.parse_file(settings_path);
		}
		println(f"failed to load existing GlobalSettings from {settings_path.str}, does this exist?");
		return {};
	}

	static bool get_bool(char^ name, bool default_value) {
		if (!obj.dict.has(name)) {
			obj.put_bool(name, default_value);
		}
		return obj.get_bool(name);
	}

	static float get_float(char^ name, float default_value) {
		if (!obj.dict.has(name)) {
			obj.put_float(name, default_value);
		}
		return obj.get_float(name);
	}

	static int get_int(char^ name, int default_value) {
		if (!obj.dict.has(name)) {
			obj.put_int(name, default_value);
		}
		return obj.get_int(name);
	}

	static char^ get_str(char^ name, char^ default_value) {
		if (!obj.dict.has(name)) {
			obj.put_literal(name, default_value);
		}
		return obj.get_str(name);
	}

	static void SaveUpdates() {
		obj.serialize_to(settings_path);
	}

	static int set_int(char^ name, int value) { obj.put_int(name, value); return value; }
	static float set_float(char^ name, float value) { obj.put_float(name, value); return value; }
	static bool set_bool(char^ name, bool value) { obj.put_bool(name, value); return value; }
	static char^ set_str(char^ name, char^ value) { obj.put_literal(name, value); return value; }
}

