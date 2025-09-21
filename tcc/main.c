// /*
//  * Simple Test program for libtcc
//  *
//  * libtcc can be useful to use tcc as a "backend" for a code generator.
//  */
// #include <stdlib.h>
// #include <stdio.h>
// #include "libtcc.h"
//
// void handle_error(void *opaque, const char *msg)
// {
//     fprintf(opaque, "%s\n", msg);
// }
//
// /* this function is called by the generated code */
// int add(int a, int b)
// {
//     return a + b;
// }
//
// /* this strinc is referenced by the generated code */
// const char hello[] = "Hello World!";
//
// char my_program[] =
// "#include <tcclib.h>\n" /* include the "Simple libc header for TCC" */
// "int my_var;"
// "int foo(int n)\n"
// "{\n"
// 	"my_var = 7;"
// "    printf(\"foo(%d)\\n\", n);\n"
// "    return 0;\n"
// "}\n"
// "void get(void) { printf(\"my_var = %d!\\n\", my_var);}";
//
//
//
// char my_program_more[] =
// "#include <tcclib.h>\n" /* include the "Simple libc header for TCC" */
// "extern int my_var;"
// // "void yo() {}"
// "void bar(int baz) { foo(1); my_var = 13; printf(\"baz(%d)!!!\", baz + 3); }"
// ;
//
// int main(int argc, char **argv)
// {
//     TCCState *s;
//     int i;
//     int (*func)(int);
//     void (*get)(void);
//
// 	for (int j = 0; j < 3; j++) {
// 		printf("==========\n");
// 		s = tcc_new();
// 		if (!s) {
// 			fprintf(stderr, "Could not create tcc state\n");
// 			exit(1);
// 		}
//
// 		/* set custom error/warning printer */
// 		tcc_set_error_func(s, stderr, handle_error);
//
// 		/* if tcclib.h and libtcc1.a are not installed, where can we find them */
// 		for (i = 1; i < argc; ++i) {
// 			char *a = argv[i];
// 			if (a[0] == '-') {
// 				if (a[1] == 'B')
// 					tcc_set_lib_path(s, a+2);
// 				else if (a[1] == 'I')
// 					tcc_add_include_path(s, a+2);
// 				else if (a[1] == 'L')
// 					tcc_add_library_path(s, a+2);
// 			}
// 		}
//
// 		/* MUST BE CALLED before any compilation */
// 		tcc_set_output_type(s, TCC_OUTPUT_MEMORY);
//
// 		if (tcc_compile_string(s, my_program) == -1)
// 			return 1;
//
// 		// /* relocate the code */
// 		// if (tcc_relocate(s) < 0)
// 		// 	return 1;
//
//
//
// 		// {
// 		// 	/* get entry symbol */
// 		// 	func = tcc_get_symbol(s, "foo");
// 		// 	if (!func)
// 		// 		return 1;
// 		//
// 		// 	/* run the code */
// 		// 	func(32);
// 		// }
// 		//
// 		// {
// 		// 	/* get entry symbol */
// 		// 	get = tcc_get_symbol(s, "get");
// 		// 	if (!get)
// 		// 		return 1;
// 		//
// 		// 	/* run the code */
// 		// 	get();
// 		// }
//
//
//
// 		if (tcc_compile_string(s, my_program_more) == -1)
// 			return 1;
//
// 		// /* as a test, we add symbols that the compiled program can use.
// 		//    You may also open a dll with tcc_add_dll() and use symbols from that */
// 		// tcc_add_symbol(s, "add", add);
// 		// tcc_add_symbol(s, "hello", hello);
//
// 		/* relocate the code */
// 		if (tcc_relocate(s) < 0)
// 			return 1;
//
// 		{
// 			/* get entry symbol */
// 			func = tcc_get_symbol(s, "bar");
// 			if (!func)
// 				return 1;
//
// 			/* run the code */
// 			func(18);
// 		}
//
// 		{
// 			/* get entry symbol */
// 			get = tcc_get_symbol(s, "get");
// 			if (!get)
// 				return 1;
//
// 			/* run the code */
// 			get();
// 		}
//
// 		/* delete the state */
// 		tcc_delete(s);
// 	}
//
//     return 0;
// }

#include <stdio.h>
#include <stdlib.h>
#include "libtcc.h"

// The custom backtrace handler function
int my_backtrace_handler(void *udata, void *pc, const char *file, int line, const char *func, const char *msg) {
    printf("--- Custom Backtrace Handler Called ---\n");
    printf("User Data: %s\n", (char*)udata);
    printf("Error: %s\n", msg);
    printf("Location: %s:%d in function '%s'\n", file, line, func);
    printf("PC: %p\n", pc);
    printf("---------------------------------------\n");
    
    // Returning 0 stops the backtrace
    return 0; 
}

int main(void) {
    TCCState *s = tcc_new();
    if (!s) {
        fprintf(stderr, "Could not create TCC state\n");
        return 1;
    }

    tcc_set_output_type(s, TCC_OUTPUT_MEMORY);

    // Set the custom backtrace function
    char *user_data_msg = "My custom error data.";
    tcc_set_backtrace_func(s, user_data_msg, my_backtrace_handler);

    // Source code that will cause a runtime exception (division by zero)
    const char *source_code = 
        "int main() {\n"
        "    int a = 10;\n"
        "    int b = 0;\n"
        "    int c = a / b; // This will cause a division-by-zero error\n"
        "    return c;\n"
        "}\n";

    if (tcc_compile_string(s, source_code) == -1) {
        fprintf(stderr, "Failed to compile the code\n");
        tcc_delete(s);
        return 1;
    }

    // Relocate the code into memory
    if (tcc_relocate(s) < 0) {
        fprintf(stderr, "Failed to relocate the code\n");
        tcc_delete(s);
        return 1;
    }

    // Get the entry point of the compiled code
    int (*main_func)(void);
    main_func = tcc_get_symbol(s, "main");
    if (!main_func) {
        fprintf(stderr, "Could not find main function\n");
        tcc_delete(s);
        return 1;
    }

    printf("Calling compiled code...\n");
    
    // Call the compiled function, which will trigger the custom backtrace handler
    main_func();

    printf("Backtrace handler should have been called.\n");

    tcc_delete(s);
    return 0;
}

