# OPERATORS ---

Access off Struct Pointer
C:   ->
crust: #

Bitwise And
C:   &
crust: ~&

Bitwise Or
C:   |
crust: ~|

Bitwise Xor
C:   ^
crust: ~^

---
# Other Syntax Differences ---

Ternary
C:   a ? b : c
crust: a ? b | c

---
Calling C Stuff RAW (Raw: meaning that you get no useful typechecking directly for anything that you do this for)

# Calling C Function Directly (Assuming it's definition is included `c:import "<library name/path/whatever>";`)
c:variable_that_is_defined_in_c

// OR BETTER:
@extern <type_of_the_c_variable> variable_that_is_defined_in_c;

# Calling C Function Directly (Assuming it's definition is included `c:import "<library name/path/whatever>";`)
c:function_that_is_defined_in_c(...)

// OR BETTER:
@extern <return_type_of_the_c_function> function_that_is_defined_in_c(<... argument types ...>);

# Refering to C type (Assuming it's definition is included `c:import "<library name/path/whatever>";`, and that there has been a typedef)
c:type_name_defined_in_c
