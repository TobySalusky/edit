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
		let em = s(fn.args.get(1).type_str);
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

PluginCodegen fx_args_codegen(PluginCodegenArgs args) {
	PluginCodegen err = {
		.code = f"int err = \"@fx_args - error\";", 
		.location = PluginCodegenLocationAfter{}
	};
	PluginSyntaxStatementStructure structure = (args.syntax_node as PluginSyntaxStatement else { return err;}) as PluginSyntaxStatementStructure else { return err; };

	char^ member_contents = "";

	int ii = 0;
	for (let& decl in structure.var_decls()) {
		if (decl.type_str == NULL) { return { .code = f"cooked;", .location = PluginCodegenLocationAfter{} }; }

		// NOTE: List<...> not explicitly initialized, since 0 (from calloc) == .()
		if (str_eq(decl.type_str, "float")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeFloat{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "double")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeDouble{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "bool")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeBool{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "uchar")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeUChar{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "char")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeChar{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "ushort")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeUShort{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "short")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeShort{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "uint")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeUInt{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "int")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeInt{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "ulong")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeULong{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "long")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeLong{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "Vec2")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeVec2{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "Color")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeColor{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "char^")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeStr{'{'}{'}'} {'}'});";
		} else if (str_eq(decl.type_str, "List<float>")) {
			// TODO: carefull of list memory leak!!!
			
			// char^ v_name = t"v_{ii}";
			// TODO: mem-leak due to Box<..>
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeList{'{'} .elem_t = Box<CustomStructMemberType>.Make(CustomStructMemberTypeFloat{'{'}{'}'}), .list_ptr = ^(ptr#{decl.name}) {'}'} {'}'});";
		} else if (str_eq(decl.type_str, "List<char^>")) {
			member_contents = t"{member_contents} members.add({'{'} .name = f\"{decl.name}\", .ptr = ^(ptr#{decl.name}), .t = CustomStructMemberTypeList{'{'} .elem_t = Box<CustomStructMemberType>.Make(CustomStructMemberTypeStr{'{'}{'}'}), .list_ptr = ^(ptr#{decl.name}) {'}'} {'}'});";
		} else {
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
