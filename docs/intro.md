# CRUST INTRO

C-like language

You can approach it mostly as if it were C but had OOP-ish features like Java/C++/Rust ;)

Notable features (that you won't get just writing C):
* structs, enums, choices, interfaces
    - all of which can have methods, static vars/functions too!
    - don't need stinky typedef or semi-colon after
* Format strings (e.g. `f"check out this {variable}!"`)
* choice/enum exhaustive pattern matching with `match` or `switch`
* For-in loops (yay :D)
* References (e.g. `int& int_ref`) - works like those in C++
* Type inference for local variables (e.g. `let variable = something_of_determinable_type();`)
* Type induction for contextually-known expressions (e.g. anonymous struct/constructor/enum-variant syntaxes `{...}/.(...)/.xxx`)

See more about all these in the syntax-guide.md
