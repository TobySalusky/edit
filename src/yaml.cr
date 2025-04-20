import std;
import map;
import rl;

struct yaml_value {
	// TODO: union/choice
	char^ literal_value; // null if yaml_object
	yaml_object^ obj_value; // null if literal_value

	void delete() {
		if (literal_value != NULL) {
			free(literal_value);
		} else if (obj_value != NULL) {
			obj_value#delete();
			free(obj_value);
		}
	}

	void fpretty_print_internal(FILE^ f, char^ name, int tab) {
		char^ tabs = string("  ").repeat(tab);

		if (literal_value == NULL) {
			if (name == NULL) {
				f#println(t"{tabs}-");
			} else {
				f#println(t"{tabs}{name}:");
			}
			obj_value#fpretty_print_internal(f, tab + 1);
		} else {
			if (name == NULL) {
				f#println(t"{tabs}- {literal_value}");
			} else {
				f#println(t"{tabs}{name}: {literal_value}");
			}
		}
	}

	void pretty_print_internal(char^ name, int tab) {
		char^ tabs = string("  ").repeat(tab);

		if (literal_value == NULL) {
			if (name == NULL) {
				println(t"{tabs}-");
			} else {
				println(t"{tabs}{name}:");
			}
			obj_value#pretty_print_internal(tab + 1);
		} else {
			if (name == NULL) {
				println(t"{tabs}- {literal_value}");
			} else {
				println(t"{tabs}{name}: {literal_value}");
			}
		}
	}
}

struct yaml_object {
	// ----------- // TODO: make it so that generic fields don't need to be above method defs using them...
	StrMap<yaml_value> dict = {};
	List<yaml_value> list = {};
	// -----------

	construct() -> {};

	void delete() {
		for (yaml_value& val in list) { val.delete(); }
		list.delete();
		for (int i in 0..dict.size) { dict.values[i].delete(); } // must delete values of dict
		dict.delete();
	}

	void serialize_to(Path p) {
		FILE^ f = io.open(p, "w");
		defer f#close();

		this.fpretty_print(f);
	}

	void pretty_print_internal(int tab) {
		for (int i = 0; i != dict.size; i++;) {
			dict.values[i].pretty_print_internal(dict.keys[i], tab);
		}
		for (int i = 0; i != list.size; i++;) {
			list.get(i).pretty_print_internal(NULL, tab);
		}
	}

	void pretty_print() {
		this.pretty_print_internal(0);
	}

	void fpretty_print_internal(FILE^ f, int tab) {
		for (int i = 0; i != dict.size; i++;) {
			dict.values[i].fpretty_print_internal(f, dict.keys[i], tab);
		}
		for (int i = 0; i != list.size; i++;) {
			list.get(i).fpretty_print_internal(f, NULL, tab);
		}
	}

	void fpretty_print(FILE^ f) {
		return this.fpretty_print_internal(f, 0);
	}

	bool has_obj(char^ name) {
		return dict.has(name) && dict.get(name).obj_value != NULL;
	}

	void _err_not_literal_name(char^ name) {
		panic(t"yaml_object.{name} is a yaml_object, not literal value"); 	
	}
	void _err_not_literal_i(int i) {
		panic(t"yaml_object[{i}] is a yaml_object, not literal value"); 	
	}
	void _err_not_object_name(char^ name) {
		panic(t"yaml_object.{name} is a literal, not a yaml_object"); 	
	}
	void _err_not_object_i(int i) {
		panic(t"yaml_object[{i}] is a literal, not a yaml_object"); 	
	}

	yaml_object& get_obj(char^ name) {
		if (!dict.has(name)) { panic(t"no key '{name}' in yaml_object"); } // TODO: handle path (eg: a.b.c)
		yaml_value& v = dict.get(name);
		if (v.obj_value == NULL) { _err_not_object_name(name); }

		return *v.obj_value;
	}

	yaml_object& at_obj(int i) {
		if (i >= list.size) { panic(t"no index '{i=}' in yaml_object"); } // TODO: handle path (eg: a.b.c)
		yaml_value& v = list.get(i);
		if (v.obj_value == NULL) { _err_not_object_i(i); }

		return *v.obj_value;
	}

	int get_int(char^ name) {
		if (!dict.has(name)) { panic(t"no key '{name}' in yaml_object"); } // TODO: handle path (eg: a.b.c)
		yaml_value v = dict.get(name);
		if (v.literal_value == NULL) { _err_not_literal_name(name); }

		return c:atoi(v.literal_value);
	}

	// still errors in case of unexpected type...
	int get_int_default(char^ name, int default_value) {
		if (!dict.has(name)) {
			return default_value;
		} // TODO: handle path (eg: a.b.c)
		yaml_value v = dict.get(name);
		if (v.literal_value == NULL) { _err_not_literal_name(name); }

		return c:atoi(v.literal_value);
	}

	uchar get_uchar_default(char^ name, uchar default_value) {
		if (!dict.has(name)) {
			return default_value;
		} // TODO: handle path (eg: a.b.c)
		yaml_value v = dict.get(name);
		if (v.literal_value == NULL) { _err_not_literal_name(name); }

		return c:atoi(v.literal_value) as uchar;
	}

	float get_float(char^ name) {
		if (!dict.has(name)) { panic(t"no key '{name}' in yaml_object"); } // TODO: handle path (eg: a.b.c)
		yaml_value v = dict.get(name);
		if (v.literal_value == NULL) { _err_not_literal_name(name); }

		return c:atof(v.literal_value);
	}

	// still errors in case of unexpected type...
	float get_float_default(char^ name, float default_value) {
		if (!dict.has(name)) {
			return default_value;
		} // TODO: handle path (eg: a.b.c)
		yaml_value v = dict.get(name);
		if (v.literal_value == NULL) { _err_not_literal_name(name); }

		return c:atof(v.literal_value);
	}

	bool get_bool(char^ name) {
		if (!dict.has(name)) { panic(t"no key '{name}' in yaml_object"); } // TODO: handle path (eg: a.b.c)
		yaml_value v = dict.get(name);
		if (v.literal_value == NULL) { _err_not_literal_name(name); }

		return str_eq(v.literal_value, "true");
	}

	bool get_bool_default(char^ name, bool default_value) {
		if (!dict.has(name)) { return default_value; } // TODO: handle path (eg: a.b.c)
		yaml_value v = dict.get(name);
		if (v.literal_value == NULL) { _err_not_literal_name(name); }

		return str_eq(v.literal_value, "true");
	}

	// NOTE: gauranteed malloc
	char^ get_str(char^ name) {
		if (!dict.has(name)) { panic(t"no key '{name}' in yaml_object"); } // TODO: handle path (eg: a.b.c)
		yaml_value v = dict.get(name);
		if (v.literal_value == NULL) { _err_not_literal_name(name); }

		return strdup(v.literal_value);
	}

	// still errors in case of unexpected type...
	// NOTE: gauranteed malloc
	char^ get_str_default(char^ name, char^ default_value) {
		if (!dict.has(name)) {
			return strdup(default_value);
		} // TODO: handle path (eg: a.b.c)
		yaml_value v = dict.get(name);
		if (v.literal_value == NULL) { _err_not_literal_name(name); }

		return strdup(v.literal_value);
	}

	bool at_bool(int i) {
		if (i >= list.size) { panic(t"index i={i} OOB for yaml_object of {list.size} list entries"); } // TODO: handle path (eg: a.b.c)
		yaml_value v = list.get(i);
		if (v.literal_value == NULL) { _err_not_literal_i(i); }

		return str_eq(v.literal_value, "true");
	}

	float at_float(int i) {
		if (i >= list.size) { panic(t"index i={i} OOB for yaml_object of {list.size} list entries"); } // TODO: handle path (eg: a.b.c)
		yaml_value v = list.get(i);
		if (v.literal_value == NULL) { _err_not_literal_i(i); }

		return c:atof(v.literal_value);
	}

	float at_float_default(int i, float default_value) {
		if (i >= list.size) { return default_value; } // TODO: handle path (eg: a.b.c)
		yaml_value v = list.get(i);
		if (v.literal_value == NULL) { _err_not_literal_i(i); }

		return c:atof(v.literal_value);
	}

	uchar at_uchar(int i) {
		if (i >= list.size) { panic(t"index i={i} OOB for yaml_object of {list.size} list entries"); } // TODO: handle path (eg: a.b.c)
		yaml_value v = list.get(i);
		if (v.literal_value == NULL) { _err_not_literal_i(i); }

		return c:atoi(v.literal_value) as uchar;
	}

	uchar at_uchar_default(int i, uchar default_value) {
		if (i >= list.size) { return default_value; } // TODO: handle path (eg: a.b.c)
		yaml_value v = list.get(i);
		if (v.literal_value == NULL) { _err_not_literal_i(i); }

		return c:atoi(v.literal_value) as uchar;
	}

	char^ at_str(int i) {
		if (i >= list.size) { panic(t"index i={i} OOB for yaml_object of {list.size} list entries"); } // TODO: handle path (eg: a.b.c)
		yaml_value v = list.get(i);
		if (v.literal_value == NULL) { _err_not_literal_i(i); }

		return strdup(v.literal_value);
	}

	// still errors in case of unexpected type...
	// NOTE: gauranteed malloc
	char^ at_str_default(int i, char^ default_value) {
		if (i >= list.size) {
			return strdup(default_value);
		} // TODO: handle path (eg: a.b.c)
		yaml_value v = list.get(i);
		if (v.literal_value == NULL) { _err_not_literal_i(i); }

		return strdup(v.literal_value);
	}

	yaml_value object_to_value(yaml_object object) {
		yaml_object^ obj_ptr = malloc(sizeof<yaml_object>);
		*obj_ptr = object;

		return {
			.literal_value = NULL,
			.obj_value = obj_ptr
		};
	}

	yaml_value literal_to_value(char^ literal) {
		return {
			.literal_value = strdup(literal), // TODO: dup?
			.obj_value = NULL
		};
	}

	// mallocs object
	void put_obj(char^ name, yaml_object value) -> dict.put(name, this.object_to_value(value)); // TODO: remove old (memory-leak)
	void put_object(char^ name, yaml_object value) -> dict.put(name, this.object_to_value(value)); // TODO: remove old (memory-leak)
	yaml_object& put_empty(char^ name) {
		put_object(name, .());
		return get_obj(name);
	}

	void put_literal(char^ name, char^ value) -> dict.put(name, this.literal_to_value(value));
	void put_float(char^ name, float value) {
		char^ str = f"{value}";
		defer free(str);
		dict.put(name, this.literal_to_value(str));
	} 
	void put_int(char^ name, int value) {
		char^ str = f"{value}";
		defer free(str);
		dict.put(name, this.literal_to_value(str));
	}
	void put_bool(char^ name, bool value) {
		char^ str = f"{value}";
		defer free(str);
		dict.put(name, this.literal_to_value(str));
	}

	void push_obj(yaml_object value) -> list.add(this.object_to_value(value));
	void push_object(yaml_object value) -> list.add(this.object_to_value(value));
	yaml_object& push_empty() {
		push_object(.());
		return at_obj(list.size - 1);
	}

	void push_literal(char^ value) -> list.add(this.literal_to_value(value));
	void push_int(int value) {
		char^ str = f"{value}";
		defer free(str);
		push_literal(str);
	}
	void push_uchar(uchar value) {
		char^ str = f"{value as int}";
		defer free(str);
		push_literal(str);
	}
	void push_float(float value) {
		char^ str = f"{value}";
		defer free(str);
		push_literal(str);
	}
	void push_bool(bool value) {
		char^ str = f"{value}";
		defer free(str);
		push_literal(str);
	}
}

// expects 2-spacing, no real tabs!
struct yaml_parser {
	yaml_object parse_file(Path p) {
		Strings lines = io.lines(p);
		defer lines.delete();

		return this.parse_lines(lines);
	}

	yaml_object parse(char^ yaml_str) {
		Strings lines = split(yaml_str, "\n");
		defer lines.delete();

		return this.parse_lines(lines);
	}

	int count_tabs_at_start(char^ line) {
		int count = 0;
		for (int i = 0; i != strlen(line); i++;) {
			if (line[i] == ' ') { count++; }
		}
		return count / 2;
	}

	// returns -> next index
	int parse_into(yaml_object^ add_to, Strings content_lines, int start_i, int obj_tab) {
		string start_line = string(content_lines.at(start_i)).trim();
		int i = start_i + 1;

		bool is_list_entry = start_line.starts_with("-");
		char^ name = NULL;
		if (is_list_entry) { // non-object list entries
			string after_dash = start_line.substr_from(start_line.index_of("-") + 1).trim();
			if (!after_dash.is_empty()) {
				add_to#push_literal(after_dash);
				return i;
			}
		} else {
			int colon_idx = start_line.index_of(":");
			if (colon_idx == -1) {
				panic(t"unexpected, no named-entry on line {start_i}, content: '{start_line.into()}'");
			}
			name = start_line.substr_til(colon_idx);
			string content = start_line.substr_from(colon_idx+1).trim();

			if (!content.is_empty()) {
				add_to#put_literal(name, content);
				return i;
			}
		}

		yaml_object entry_obj = .();

		while (i < content_lines.n) {
			char^ line = content_lines.at(i);
			// println(t"line = '{line}', len = {strlen(line)} | {this.count_tabs_at_start(line)} | {obj_tab}");
			// TODO: if greater, also a problem! (invalid, basically?)   (???)
			if (this.count_tabs_at_start(line) < obj_tab) {
				// println(t"yo {i} {this.count_tabs_at_start(line)}"); 
				break; 
			} // object/list done

			i = this.parse_into(^entry_obj, content_lines, i, obj_tab + 1);
		}

		if (is_list_entry) {
			add_to#push_object(entry_obj);
		} else {
			add_to#put_object(name, entry_obj);
		}

		// println(t"obj {i}");
		return i;
	}

	yaml_object parse_lines(Strings lines) {
		Strings content_lines = lines.non_whitespace_only();
		defer content_lines.delete();

		yaml_object obj = .();

		int i = 0;
		while (i < content_lines.n) {
			// TODO: check that indentation isn't higher? that's bug/invalid?
			i = this.parse_into(^obj, content_lines, i, 1);
		}

		if (i != content_lines.n) {
			panic(t"internal parse_lines error - consumed only {i}/{content_lines.n} contentful lines!");
		}

		return obj;
	}
}

// bi-directional (loads on load, stores on store)
// * TODO: bi-directional w/ yaml_object (no io)
struct yaml_serializer {
	Path p;
	yaml_object& obj;
	bool is_load; // else, is store

	// if false: just for bi-directional storage w/ yaml_object
	// if true: for syncing straight from/to disk
	bool path_io;

	static yaml_serializer IO(Path p, bool is_load) -> {
		:p,
		.obj = *Box<yaml_object>.Make(is_load
				? yaml_parser{}.parse_file(p)
				| .()),
		:is_load,
		.path_io = true,
	};

	// NOTE: obj must exist (be held) externally
	// TODO: careful with realloc's from list holding it... (maybe ok b/c yaml_value indirection!)
	static yaml_serializer Obj(yaml_object& obj, bool is_load) -> {
		.p = Path(""),
		:obj,
		:is_load,
		.path_io = false,
	};

	yaml_serializer into_obj(char^ name) {
		if (is_load) {
			if (obj.has_obj(name)) {
				return Self.Obj(obj.get_obj(name), is_load);
			}
			return Self.Obj(obj.put_empty(name), is_load);
		} else {
			return Self.Obj(obj.put_empty(name), is_load);
		}
	}

	yaml_serializer into_obj_at(int i) {
		if (is_load) {
			if (obj.list.size > i) {
				return Self.Obj(obj.at_obj(i), is_load);
			}
			return Self.Obj(obj.push_empty(), is_load);
		} else {
			return Self.Obj(obj.push_empty(), is_load);
		}
	}

	// gauranteed malloc on-get
	char^ str_default(char^& ptr, char^ name, char^ default_val) {
		if (is_load) {
			ptr = obj.get_str_default(name, default_val); // malloced
		} else {
			obj.put_literal(name, ptr);
		}
		return ptr;
	}

	bool bool_default(bool& ptr, char^ name, bool default_val) {
		if (is_load) {
			ptr = obj.get_bool_default(name, default_val);
		} else {
			obj.put_literal(name, t"{ptr}");
		}
		return ptr;
	}

	int int_default(int& ptr, char^ name, int default_val) {
		if (is_load) {
			ptr = obj.get_int_default(name, default_val);
		} else {
			obj.put_literal(name, t"{ptr}");
		}
		return ptr;
	}

	Vec2 Vec2_default(Vec2& ptr, char^ name, Vec2 default_val) {
		if (is_load) {
			if (obj.has_obj(name)) {
				let& vec_obj = obj.get_obj(name);
				// NOTE: sus when partial... let's just hope that never happens!
				ptr = { vec_obj.at_float_default(0, 0), vec_obj.at_float_default(1, 0) };
			} else {
				ptr = default_val;
			}
		} else {
			let& vec_obj = obj.put_empty(name);
			vec_obj.push_float(ptr.x);
			vec_obj.push_float(ptr.y);
		}
		return ptr;
	}

	Color Color_default(Color& ptr, char^ name, Color default_val) {
		if (is_load) {
			if (obj.has_obj(name)) {
				let& color_obj = obj.get_obj(name);
				// NOTE: sus when partial... let's just hope that never happens!
				ptr = { color_obj.at_uchar_default(0, 0), color_obj.at_uchar_default(1, 0), color_obj.at_uchar_default(2, 0), color_obj.at_uchar_default(3, 255) };
			} else {
				ptr = default_val;
			}
		} else {
			let& color_obj = obj.put_empty(name);
			color_obj.push_uchar(ptr.r);
			color_obj.push_uchar(ptr.g);
			color_obj.push_uchar(ptr.b);
			color_obj.push_uchar(ptr.a);
		}
		return ptr;
	}

	uchar uchar_default(uchar& ptr, char^ name, uchar default_val) {
		if (is_load) {
			ptr = obj.get_uchar_default(name, default_val);
		} else {
			obj.put_literal(name, t"{ptr as int}");
		}
		return ptr;
	}

	float float_default(float& ptr, char^ name, float default_val) {
		if (is_load) {
			ptr = obj.get_float_default(name, default_val);
		} else {
			obj.put_literal(name, t"{ptr}");
		}
		return ptr;
	}

	// commits store
	void finish() {
		if (!path_io) {
			println("[WARNING]: non-path_io yaml_serializer should not call finish()!");
			return;
		}

		if (!is_load) { // store
			obj.serialize_to(p);
		}

		obj.delete();
		free(^obj);
	}
}

struct ListSerializer<T> {
	static List<T> Deserialize(yaml_serializer& s) {
		assert(s.is_load, "ListSerializer::Deserialize - s.is_load");
		List<T> res = {};

		for (int i in 0..s.obj.list.size) {
			let elem_s = s.into_obj_at(i);
			res.add(T.Deserialize(elem_s));
		}
		return res;
	}

	static yaml_object Serialize(List<T>& list) {
		yaml_object obj = {};
		for (let& elem in list) {
			obj.push_obj(elem.Serialize());
		}
		return obj;
	}
}
