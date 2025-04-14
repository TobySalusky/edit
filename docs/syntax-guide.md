# CRUST SYNTAX

> this documentation doesn't cover everything yet, but should be enough to get you started
> feel free to look at any of the .cr files in the project to get a better feel for the language!

Builtin types:   `void, bool, char, short, int, long, uchar, ushort, uint, ulong, float, double`

Pointer types:   `char^` (AKA string, like in C)
* for struct pointers: e.g. `CoolStruct^`, access members using `#`, instead of `->`, as `cool_struct_ptr#fn_or_var`

Reference types: `int&` (works same as C++ mutable references)
* use as if `int`, assign as if `int pointer` (i.e. effects value of whatever it is a reference to)

Functions:
```c
int cool_fn1() { // no need for cool_fn1(void) for no-params like in C
    return 7;
}
int cool_fn2() -> 7; // -> <value>; shorthand for single-expression returning functions!

void do_io(int a, float f) { // params are as you'd expect
    println(t"check out {a} and {f}!");
    // cool format string ^ will see more of later :)
}
```

```cr
enum StructQuality {
    Wow, Amazing, Cool, Terrible;

    char^ Emote() -> match (this) {
        .Wow      -> "0:",
        .Amazing  -> "(:",
        .Cool     -> "L:",
        .Terrible -> "D:",
    };
}

struct SimpleStruct {
    int a; int b;
}

struct CoolStruct {
    float f;
    SubStruct other_member

    construct(float f) -> {
        :f, // :<name>, when name is same!
        .other_member = {
            .a = 1,
            .b = 2,
        }
    };

    static int ClassWideVar = 3;
    static Self MakeCool(SimpleStruct ss) -> { // use Self to reference the type you're in (e.g. CoolStruct, here)
        .f = Self.ClassWideVar,
        .other_member = ss
    };
}

int main() {
    // constructor syntax! (calls to static `construct`) -- these 3 are the same
    CoolStruct cs = CoolStruct(-7.3);
    CoolStruct cs = .(-7.3); // type-induced
    let cs = CoolStruct(-7.3); // type-inferred

    // enums -- these 3 are the same
    StructQuality q = StructQuality.Wow;
    StructQuality q = .Wow; // type-induced
    let q = StructQuality.Wow; // type-inferred

    // enum method!
    println(t"quality of struct makes me feel {cs.Emote()}");

    return 0;
}
```

Loops:
```c++
import std;

List<int> list = .(); // default constructs an empty list - from import std;

int main() {
    list.add(1);
    list.add(2);
    list.add(5);

    for (int i = 0; i < list.size; i++;) { // note semicolon before end-of-for header! (will get rid of eventually...)
        println(t"{i}: {list.get(i)}");
    }
    // 0: 1
    // 1: 2
    // 2: 5

    for (int elem in list) { // for-in loop!
        println(t"{list.get(i)}");
    }

    for (int& elem in list) { // elem is mutable (effects real list elems)
        elem++;
        println(t"{elem}");
    }
    // 2
    // 3
    // 6

    // list=[2,3,6]

    while (true) { // same as C

    }

    return 0;
}
```

importing:
```c++
// filenames are globally unique within each R++ project, so to include, is just:
import file_name;
// ^ required to use the definitions from the file properly!

// e.g:
import map;

void func() {
    StrMap<int> age_map = .(); // lookup {char^: int} - from map.cr;
    age_map.put("Adrian", 19);

    age_map.has("Adrian"); // -> true
    age_map.get("Adrian"); // -> 19

    panic("error message"); // crash the program ;)
}
```

Current limitations/grossities
* currently generics are only struct/class/enum-wide (i.e. no method generics -- coming soon!)
* type-checking for templates/generics is done at instantiation-time
    - so while writing `CoolList<T>`, until you've started using `CoolList<int>`, for example, you will not get any errors even if incorrect (type-wise), since they are checked per-use-type (basically same as C++)
