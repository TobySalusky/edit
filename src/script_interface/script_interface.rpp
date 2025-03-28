import std;
import list;
import rl;

/// -----------------------------------------
// base args for @fx_fn's
struct FxArgs {
	Vec2 pos;
	Vec2 scale;
	float rotation;
	Color color;
	// float lt;
	// TODO: local-time, global-time, proportion_done, inverse_proportion_done
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
	CustomStructMemberType^ elem_t; // malloced!!
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

	CustomStructMemberTypeList,
	// CustomStructMemberTypeCustomStruct,
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

// -------
