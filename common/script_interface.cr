import std;
import list;
import rl;
import yaml; // TODO: remove reliance on yaml from this file so script won't need it!

c:`
typedef struct Element Element;
// extern float LastKeyframeTime(Element*, char*, float);
`;

/// -----------------------------------------
// base args for @fx_fn's
struct FxArgs {
	Vec2 pos;
	Vec2 scale;
	float rotation;
	Color color;
	float local_time; // alias lt?
	float composition_time; // alias ct?
	// TODO: local-time, global-time, proportion_done, inverse_proportion_done

	c:Element^ _element; // NOTE: dangerous - only use if you know what you're doing, otherwise stick to the non-underscored APIs!!

	// float LastKeyframeTime(char^ key_name) -> c:LastKeyframeTime(_element, key_name, local_time);
}

// struct CustomStructMemberTypeInt {}
struct CustomStructMemberTypeFloat {}
struct CustomStructMemberTypeDouble {}

struct CustomStructMemberTypeBool {}

struct CustomStructMemberTypeUChar {}
struct CustomStructMemberTypeChar {}
struct CustomStructMemberTypeUShort {}
struct CustomStructMemberTypeShort {}
struct CustomStructMemberTypeUInt {}
struct CustomStructMemberTypeInt {}
struct CustomStructMemberTypeULong {}
struct CustomStructMemberTypeLong {}

struct CustomStructMemberTypeStr {} // (i.e. char^)
struct CustomStructMemberTypeVec2 {}
struct CustomStructMemberTypeColor {}

struct CustomStructMemberTypeList {
	// TODO: delete() !!!!!! (NOTE: MEMORY LEAK)
	CustomStructMemberType^ elem_t; // malloced!!

	// not-serialized
	void^ list_ptr; // type-erased List<...>^

	// TODO: delete()
}

struct CustomStructMemberTypeCustomStruct {
	CustomStructHandle^ handle; // NOTE: malloced!
	char^ type_name_str;

	// TODO: delete()
}

// struct CustomStructMemberTypeBool {}
// struct CustomStructMemberTypeCustomStruct {
// 	CustomStructHandle handle;
// }

// Vec2 -> two Float fields
choice CustomStructMemberType {
	CustomStructMemberTypeFloat,
	CustomStructMemberTypeDouble,

	CustomStructMemberTypeBool,

	CustomStructMemberTypeUChar,
	CustomStructMemberTypeChar,
	CustomStructMemberTypeUShort,
	CustomStructMemberTypeShort,
	CustomStructMemberTypeUInt,
	CustomStructMemberTypeInt,
	CustomStructMemberTypeULong,
	CustomStructMemberTypeLong,

	CustomStructMemberTypeStr,
	CustomStructMemberTypeVec2,
	CustomStructMemberTypeColor,

	CustomStructMemberTypeList, // has members!
	// CustomStructMemberTypeCustomStruct,
	;

	bool operator:==(Self& other) {
		return match (this) {
			CustomStructMemberTypeFloat -> other is CustomStructMemberTypeFloat,
			CustomStructMemberTypeDouble -> other is CustomStructMemberTypeDouble,
			CustomStructMemberTypeBool -> other is CustomStructMemberTypeBool,
			CustomStructMemberTypeUChar -> other is CustomStructMemberTypeUChar,
			CustomStructMemberTypeChar -> other is CustomStructMemberTypeChar,
			CustomStructMemberTypeUShort -> other is CustomStructMemberTypeUShort,
			CustomStructMemberTypeShort -> other is CustomStructMemberTypeShort,
			CustomStructMemberTypeUInt -> other is CustomStructMemberTypeUInt,
			CustomStructMemberTypeInt -> other is CustomStructMemberTypeInt,
			CustomStructMemberTypeULong -> other is CustomStructMemberTypeULong,
			CustomStructMemberTypeLong -> other is CustomStructMemberTypeLong,
			CustomStructMemberTypeStr -> other is CustomStructMemberTypeStr,
			CustomStructMemberTypeVec2 -> other is CustomStructMemberTypeVec2,
			CustomStructMemberTypeColor -> other is CustomStructMemberTypeColor,
			CustomStructMemberTypeList it -> other is CustomStructMemberTypeList && *(it.elem_t) == *(other as CustomStructMemberTypeList.elem_t),
		};
	}

	static Self Deserialize(yaml_serializer& s) {
		assert(s.is_load, "s.is_load please");

		string which = string(s.obj.get_str("which"));

		if (which == .("float")) { return CustomStructMemberTypeFloat{}; }
		if (which == .("double")) { return CustomStructMemberTypeDouble{}; }
		if (which == .("bool")) { return CustomStructMemberTypeBool{}; }
		if (which == .("uChar")) { return CustomStructMemberTypeUChar{}; }
		if (which == .("char")) { return CustomStructMemberTypeChar{}; }
		if (which == .("uShort")) { return CustomStructMemberTypeUShort{}; }
		if (which == .("short")) { return CustomStructMemberTypeShort{}; }
		if (which == .("uInt")) { return CustomStructMemberTypeUInt{}; }
		if (which == .("int")) { return CustomStructMemberTypeInt{}; }
		if (which == .("uLong")) { return CustomStructMemberTypeULong{}; }
		if (which == .("long")) { return CustomStructMemberTypeLong{}; }
		if (which == .("str")) { return CustomStructMemberTypeStr{}; }
		if (which == .("vec2")) { return CustomStructMemberTypeVec2{}; }
		if (which == .("color")) { return CustomStructMemberTypeColor{}; }
		if (which == .("list")) {
			let elem_t_s = s.into_obj("elem_t");
			return CustomStructMemberTypeList{
				.elem_t = Box<Self>.Make(Deserialize(elem_t_s)),
				.list_ptr = NULL,
			}; 
		}

		panic("unreachable - CustomStructMemberType::Deserialize");
		CustomStructMemberTypeFloat _;
		return _;
	}

	void SerializeStore(yaml_serializer& s) {
		assert(!s.is_load, "!s.is_load please");
		
		switch (this) {
			CustomStructMemberTypeFloat -> { s.obj.put_literal("which", "float"); },
			CustomStructMemberTypeDouble -> { s.obj.put_literal("which", "double"); },
			CustomStructMemberTypeBool -> { s.obj.put_literal("which", "bool"); },
			CustomStructMemberTypeUChar -> { s.obj.put_literal("which", "uchar"); },
			CustomStructMemberTypeChar -> { s.obj.put_literal("which", "char"); },
			CustomStructMemberTypeUShort -> { s.obj.put_literal("which", "ushort"); },
			CustomStructMemberTypeShort -> { s.obj.put_literal("which", "short"); },
			CustomStructMemberTypeUInt -> { s.obj.put_literal("which", "uint"); },
			CustomStructMemberTypeInt -> { s.obj.put_literal("which", "int"); },
			CustomStructMemberTypeULong -> { s.obj.put_literal("which", "ulong"); },
			CustomStructMemberTypeLong -> { s.obj.put_literal("which", "long"); },
			CustomStructMemberTypeStr -> { s.obj.put_literal("which", "str"); },
			CustomStructMemberTypeVec2 -> { s.obj.put_literal("which", "Vec2"); },
			CustomStructMemberTypeColor -> { s.obj.put_literal("which", "Color"); },
			CustomStructMemberTypeList it -> {
				s.obj.put_literal("which", "list"); 
				
				let elem_t_s = s.into_obj("elem_t");
				it.elem_t#SerializeStore(elem_t_s);
				// list_ptr not-serialized
			},
		}
	}
}

struct CustomStructMemberHandle {
	char^ name;
	void^ ptr;
	CustomStructMemberType t;
	bool is_list() -> t is CustomStructMemberTypeList;

	void delete() {
		// if (t is CustomStructMemberTypeCustomStruct) {
		// 	(t as CustomStructMemberTypeCustomStruct).handle.delete();
		// }
	}
}

struct CustomStructHandle {
	List<CustomStructMemberHandle> members;
	void^ ptr; // ptr malloced

	Opt<CustomStructMemberHandle> GetMember(char^ name) {
		for (let& member in members) { // NOTE: ref? -> choice?
			if (str_eq(member.name, name)) {
				return member;
			}
		}
		return none;
	}

	void delete() {
		for (let& member in members) {
			member.delete();
		}
		members.delete();
		free(ptr);
	}
}

struct CustomFnHandle {
	void^ ptr;
	char^ custom_arg_t_name; // = NULL, when none
}

struct EditScript {
	string[] fx_fns = {};
	string[] fx_args = {};

	void delete() {
		for str in fx_fns { str.delete(); }
		fx_fns.delete();

		for str in fx_args { str.delete(); }
		fx_args.delete();
	}

	void register_fxfn(char^ name) {
		fx_fns.add(.(strdup(name)));
	}

	void register_fxargs(char^ name) {
		fx_args.add(.(strdup(name)));
	}
}
// -------
