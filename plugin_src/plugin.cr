import plugin_core;
import std;
import list;

int PluginVersion() -> 1; // personal

char^ tpp_plugin_prefixes() -> "fx_fn_,fx_args_"; // comma-sep (for now)

int tpp_plugin_spec_version() -> CurrentPluginSpecVersion();

PluginInfo fx_fn_info() -> {
	.annotation_name = "fx_fn",

	.title = "Edit Effect Arguments",
	.description = "Allows use of struct in edit keyframe/ui as a procedural drawing function parameter",
	.version = PluginVersion(),

	.when = PluginInfoWhenParseTime{},
	.dep = PluginInfoDependencyLocalSyntax{},

	.params = List<PluginSyntaxRequestedArg>()
};

PluginCodegen fx_fn_codegen(PluginCodegenArgs args) {
	PluginCodegen err = {
		.code = f"int err = \"@fx_fn - error\";", 
		.location = PluginCodegenLocationAfter{}
	};
	PluginSyntaxStatementFnDecl fn = (args.syntax_node as PluginSyntaxStatement else { return err;}) as.. else { return err; };

	char^ custom_arg_t_name = "NULL";
	if (fn.args.size >= 2) {
		let em = string(fn.args.get(1).type_str);
		if (em.ends_with("&")) {
			let type_without_ref = em.substr_til(em.len() - 1).str; // TODO: mem-leak!
			custom_arg_t_name = t"\"{type_without_ref}\"";
		} else {
			err.code = f"int err = \"@fx_fn - error - arg not ref!\";";
			return err;
		}

	}

	char^ code = f"CustomFnHandle __scriptgen_NewFxFn_{fn.name}() {'{'} c:void^ ptr = c:{fn.name}; return {'{'} :ptr, .custom_arg_t_name = {custom_arg_t_name}, {'}'}; {'}'}"; // TODO: mem-leak?

	return {
		:code,
		.location = PluginCodegenLocationAfter{}
	};
}

PluginInfo fx_args_info() -> {
	.annotation_name = "fx_args",

	.title = "Edit Effect Arguments",
	.description = "Allows use of struct in edit keyframe/ui as a procedural drawing function parameter",
	.version = PluginVersion(),

	.when = PluginInfoWhenParseTime{},
	.dep = PluginInfoDependencyLocalSyntax{},

	.params = List<PluginSyntaxRequestedArg>()
};

Opt<char^> simple_typestr_to_custom_t(char^ type_str) {
	if (str_eq(type_str, "float")) {
		return "CustomStructMemberTypeFloat";
	} else if (str_eq(type_str, "double")) {
		return "CustomStructMemberTypeDouble";
	} else if (str_eq(type_str, "bool")) {
		return "CustomStructMemberTypeBool";
	} else if (str_eq(type_str, "uchar")) {
		return "CustomStructMemberTypeUChar";
	} else if (str_eq(type_str, "char")) {
		return "CustomStructMemberTypeChar";
	} else if (str_eq(type_str, "ushort")) {
		return "CustomStructMemberTypeUShort";
	} else if (str_eq(type_str, "short")) {
		return "CustomStructMemberTypeShort";
	} else if (str_eq(type_str, "uint")) {
		return "CustomStructMemberTypeUInt";
	} else if (str_eq(type_str, "int")) {
		return "CustomStructMemberTypeInt";
	} else if (str_eq(type_str, "ulong")) {
		return "CustomStructMemberTypeULong";
	} else if (str_eq(type_str, "long")) {
		return "CustomStructMemberTypeLong";
	} else if (str_eq(type_str, "Vec2")) {
		return "CustomStructMemberTypeVec2";
	} else if (str_eq(type_str, "Color")) {
		return "CustomStructMemberTypeColor";
	} else if (str_eq(type_str, "char^")) {
		return "CustomStructMemberTypeStr";
	}
	return none;
}

PluginCodegen fx_args_codegen(PluginCodegenArgs args) {
	PluginCodegen err = {
		.code = f"int err = ERR_REASON;", 
		.location = PluginCodegenLocationAfter{}
	};
	PluginSyntaxStatementStructure structure = (args.syntax_node as PluginSyntaxStatement else { return err;}) as PluginSyntaxStatementStructure else { return err; };

	char^ member_contents = "";

	int ii = 0;
	for (let& decl in structure.var_decls()) {
		if (decl.type_str == NULL) { return { .code = f"cooked;", .location = PluginCodegenLocationAfter{} }; }

		// NOTE: List<...> not explicitly initialized, since 0 (from calloc) == .()
		let simple_t = simple_typestr_to_custom_t(decl.type_str);
		let type_str = string(decl.type_str);
		if (simple_t is Some) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = {simple_t as Some}{'{'}{'}'} {'}'});";
		} else if (type_str.starts_with("List<")) {
			int open_caret = type_str.index_of("<");
			int close_caret = type_str.last_index_of(">");
			if (open_caret == -1 || close_caret == -1) {
				// NOTE: shouldn't happen
				err.code = f"int err = ERR_REASON_IOOB;"; 
				return err;
			}
			string list_elem_type_str = type_str.substr(open_caret + 1, close_caret - open_caret - 1);
			defer list_elem_type_str.delete();

			let simple_elem_t = simple_typestr_to_custom_t(list_elem_type_str);
			if (simple_elem_t is Some) {
				// TODO: carefull of list memory leak!!!
				
				// char^ v_name = t"v_{ii}";
				// TODO: mem-leak due to Box<..>
				member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeList{'{'} .elem_t = Box<CustomStructMemberType>.Make({simple_elem_t as Some}{'{'}{'}'}), .list_ptr = ^(ptr#{decl.name}) {'}'} {'}'});";
			} else {
				err.code = f"int err = ERR_REASON_NON_SIMPLE_{list_elem_type_str.str};"; 
				return err;
			}
		} else {
			err.code = f"int err = ERR_REASON_UNKNOWN_T;"; 
			return err;
		}
	}

	char^ contents = t"{structure.name}^ ptr = c:calloc(1, sizeof<{structure.name}>); *ptr = {'{'}{'}'}; List<CustomStructMemberHandle> members = .(); {member_contents} return {'{'} :ptr, :members {'}'};";

	char^ code = f"CustomStructHandle __scriptgen_NewFxArgs_{structure.name}() {'{'}{contents}{'}'}"; // TODO: mem-leak?

	return {
		:code,
		.location = PluginCodegenLocationAfter{}
	};
}
