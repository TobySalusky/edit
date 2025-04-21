c:`#ifndef NO_PLUGIN_CORE_INCLUDES`;
import std;
import list;
c:`#endif // NO_PLUGIN_CORE_INCLUDES`;

int CurrentPluginSpecVersion() -> 1;

struct PluginInfoWhenParseTime {}
choice PluginInfoWhen {
	PluginInfoWhenParseTime;
}

struct PluginInfoDependencyLocalSyntax {} // NOTE: just the node the annotation is on!
choice PluginInfoDependency {
	PluginInfoDependencyLocalSyntax; 	
}

struct PluginInfo {
	char^ annotation_name; // @xxx (must be unique within project/usage)

	char^ title;
	char^ description;
	int version;

	PluginInfoWhen when;
	PluginInfoDependency dep; // TODO: make dep -> deps (list)

	List<PluginSyntaxRequestedArg> params;

	// static void yo() {
	// 
	// }

	// construct(int a) -> { ... };
	// static Self make() -> { ... };
	// void destruct() { }

	// void doit() {
		// PluginInfo(.title = 0);
	// }
}

struct PluginCodegenLocationAfter {}

// TODO:
// struct PluginCodegenLocationAppendInside {} // TODO: after or at time (eg. when using mult. annotations, do others process this???)
// struct PluginCodegenLocationSpecific {
	// file/line/column - (TODO: how w/ mult plugins??)
// }

choice PluginCodegenLocation {
	PluginCodegenLocationAfter 
}

struct PluginCodegen {
	PluginCodegenLocation location;
	char^ code;
}

struct PluginCodegenError {
	char^ message;
}

choice PluginCodegenResult {
	PluginCodegen,
	PluginCodegenError,
	;
}

struct PluginSyntaxExprVar {
	char^ name;
}

struct PluginSyntaxExprStringLiteral {
	char^ content;
}

struct PluginSyntaxExprInterpolatedStringLiteral {
	// TODO:
}

enum PluginSyntaxExprBopType {
	// TODO:
}

struct PluginSyntaxExprBop {
	PluginSyntaxExpr& lhs;
	PluginSyntaxExprBopType bop;	
	PluginSyntaxExpr& rhs;
}

struct PluginSyntaxExprUnimpl {}

choice PluginSyntaxExpr {
	PluginSyntaxExprVar,
	PluginSyntaxExprStringLiteral,
	PluginSyntaxExprInterpolatedStringLiteral,
	PluginSyntaxExprBop,
	PluginSyntaxExprUnimpl,
}


struct PluginSyntaxStatementVarDecl {
	char^ type_str; // TODO: proper type structure??
	char^ name;
	PluginSyntaxExpr expr;
}

struct PluginSyntaxRequestedArg {
	char^ type_str;
	char^ name;
}

struct PluginSyntaxStatementFnDecl {
	char^ ret_type_str; // TODO: proper type structure??
	char^ name;
	List<PluginSyntaxRequestedArg> args;
	List<PluginSyntaxStatement> statements;
}

struct PluginSyntaxStatementFor {
	// TODO: !!! (for)
	List<PluginSyntaxStatement> statements;
}

struct PluginSyntaxStatementWhile {
	// TODO: !!! (for)
	List<PluginSyntaxStatement> statements;
}

struct PluginSyntaxStatementAssignment {
	PluginSyntaxExpr lhs;
	PluginSyntaxExpr rhs;
}

// TODO: if_else vs sep. if/else ????
// struct PluginSyntaxStatementIf {
// 	// TODO: !!! (for)
// 	List<PluginSyntaxStatement> statements;
// }

struct PluginSyntaxStatementExpr {
	PluginSyntaxExpr expr;
}

struct PluginSyntaxStatementStructure {
	char^ name;
	// TODO: generic stuff?

	// TODO: kind - struct / interface / enum / choice
	List<PluginSyntaxStatement> statements;

	List<PluginSyntaxStatementFnDecl> fn_decls() {
		let decls = List<PluginSyntaxStatementFnDecl>();

		for (let& s in statements) {
			if (s is PluginSyntaxStatementFnDecl) {
				decls.add(s as PluginSyntaxStatementFnDecl);
			}
		}

		return decls;
	}

	List<PluginSyntaxStatementVarDecl> var_decls() {
		let decls = List<PluginSyntaxStatementVarDecl>();

		for (let& s in statements) {
			if (s is PluginSyntaxStatementVarDecl) {
				decls.add(s as PluginSyntaxStatementVarDecl);
			}
		}

		return decls;
	}
}

struct PluginSyntaxStatementUnimpl {}

choice PluginSyntaxStatement {
	PluginSyntaxStatementVarDecl,
	PluginSyntaxStatementStructure,
	PluginSyntaxStatementFnDecl,
	PluginSyntaxStatementExpr,
	PluginSyntaxStatementFor,
	PluginSyntaxStatementWhile,
	PluginSyntaxStatementAssignment,
	PluginSyntaxStatementUnimpl,
}

choice PluginSyntax {
	PluginSyntaxStatement, PluginSyntaxExpr;
}

struct PluginCodegenArgs {
	PluginSyntax syntax_node;
}
