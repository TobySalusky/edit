// --------------------
// static-site-gen html
//
// NOTE: uses temp-memory (t"")
// NOTE: non-threadable (global current_context + temp-mem)... [easy enough to remove]
// --------------------

include path("../std");

import std;

enum ssghtml_tag {
	div,
	span,
	p,
	a,
	h1,
	h2,
	h3,
	h4,
	h5,
	h6,
	html,

	link,
	img,
	; // ------------------------------------------------

	bool is_self_closing() -> match (this) {
		.link -> true,
		.img  -> true,
		else  -> false
	};
}

struct ssghtml_element_config {
	ssghtml_tag tag = .div;
	char^ class = NULL;
	char^ style = NULL;
	char^ href = NULL;
	char^ src = NULL;
	char^ alt = NULL;
}

struct ssghtml_context {
	ssghtml_tag[] tag_stack;
	FILE^ file;
	// TODO: mem-arena

	// -------------------------
	static Self CreateFileContext(char^ out_file_path) -> {
		.tag_stack = {},
		.file = io.fopen_opt(out_file_path, "w").! else panic(t"ssghtml_context.CreateFile({out_file_path}) failed!"),
	};

	void out(char^ text) {
		if (file == NULL) {
			panic("ssghtml_context.file == NULL... are you writing html outside an $html block???");
		}
		io.fappend_file_text(file, text);
	}
}

struct __ssghtml_internal {
	static ssghtml_context current_context; // TODO: current_context() fn?

	static void BeginElement(using ssghtml_context& ctx, using ssghtml_element_config config) {
		tag_stack.add(tag);

		out(t"<{tag.name()}");

		// TODO: sanitizing eg \"..!
		if (class != NULL) { out(t" class=\"{class}\""); }
		if (style != NULL) { out(t" style=\"{style}\""); }
		if (href != NULL) { out(t" href=\"{href}\""); }
		if (src != NULL) { out(t" src=\"{src}\""); }
		if (alt != NULL) { out(t" alt=\"{alt}\""); }

		out(">");
	}

	static void EndElement(using ssghtml_context& ctx, ssghtml_tag tag) {
		if (tag_stack.is_empty()) {
			panic("ssg_html.EndElement(): tag_stack empty... did you pop too many elements??");
		}
		let popped = tag_stack.pop_back();
		if (tag != popped) {
			panic(t"ssg_html.EndElement(): tag does not match back of tag_stack... what in the world did you do? {tag.name()=} {popped.name()=}");
		}

		if (!tag.is_self_closing()) {
			out(t"</{tag.name()}>");
		}
	}
}

bool html__begin(ssghtml_context new_ctx) {
	__ssghtml_internal.current_context = new_ctx;
	let& ctx = __ssghtml_internal.current_context;
	ctx.out("<!DOCTYPE html>");
	__ssghtml_internal.BeginElement(ctx, { .tag = .html });
	return true; // TODO: return ptr/ref to ctx?
}

void html__end(bool _, ssghtml_context& ctx = __ssghtml_internal.current_context) {
	// using let em = __ssghtml_internal.current_context; // TODO: using for decls!
	__ssghtml_internal.EndElement(ctx, .html);
	io.close(ctx.file);
}

ssghtml_tag div__begin(ssghtml_element_config config = {}, ssghtml_context& ctx = __ssghtml_internal.current_context) {
	ssghtml_tag tag = .div;
	__ssghtml_internal.BeginElement(ctx, config with { :tag });
	return tag;
}
void div__end(ssghtml_tag tag, ssghtml_context& ctx = __ssghtml_internal.current_context) -> __ssghtml_internal.EndElement(ctx, tag);

ssghtml_tag span__begin(ssghtml_element_config config = {}, ssghtml_context& ctx = __ssghtml_internal.current_context) {
	ssghtml_tag tag = .span;
	__ssghtml_internal.BeginElement(ctx, config with { :tag });
	return tag;
}
void span__end(ssghtml_tag tag, ssghtml_context& ctx = __ssghtml_internal.current_context) -> __ssghtml_internal.EndElement(ctx, tag);

// add to inner_text of outer element
void text(char^ content, using ssghtml_context& ctx = __ssghtml_internal.current_context) {
	out(content);
	// TODO: html-sanitize (ie: replace <> w &lt;/&gt; ...etc)
}


ssghtml_tag p(char^ content, ssghtml_element_config config = {}, ssghtml_context& ctx = __ssghtml_internal.current_context) {
	ssghtml_tag tag = .p;
	__ssghtml_internal.BeginElement(ctx, config with { :tag });
	text(content);
	__ssghtml_internal.EndElement(ctx, tag);
	return tag;
}

ssghtml_tag a__begin(char^ href, ssghtml_element_config config = {}, ssghtml_context& ctx = __ssghtml_internal.current_context) {
	// TODO:
	ssghtml_tag tag = .a;
	__ssghtml_internal.BeginElement(ctx, config with { :tag, :href });
	return tag;
}
void a__end(ssghtml_tag tag, ssghtml_context& ctx = __ssghtml_internal.current_context) -> __ssghtml_internal.EndElement(ctx, tag);


void img(char^ src, char^ alt = NULL, ssghtml_element_config config = {}, ssghtml_context& ctx = __ssghtml_internal.current_context) {
	// TODO:
	ssghtml_tag tag = .img;
	__ssghtml_internal.BeginElement(ctx, config with { :tag, :src, :alt });
	__ssghtml_internal.EndElement(ctx, tag);
}




// ------------------------------------------------------------------------------------------------------------------------
int main() {
	$html(.CreateFileContext("./website.html")) {
		div__begin();
		{
			$span(){
				text("hi");
				text("bype");
				p("more text");
			};
			$a("http://cool-link.com"){ text("Cool Link [Click Me!]"); };
			img("https://media1.tenor.com/m/xozzV0FyDYoAAAAC/uma-musume-teio.gif", "dumb idiot horse");

			for (int i in 1..=10) {
				p(t"you have {i} days to live");
			}
		}
		div__end(.div);
	};

	return 0;
}
