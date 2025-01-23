# Edit

Editing software with a mixed approach to video consisting of graphical programming/procedural style + standard visual editing/clipping/keying.

Notable Structure:
* `install/`           - everything you need to work with R++ (rpp exe w/ lsp support & vscode extension)
* `scripts/`           - important setup & run scripts
* `docs/`              - learning materials (e.g. for R++) - more to come
* `src/`               - .rpp code for edit program
* `test_src/`          - .rpp code for user-loaded script in edit program (see: `cool_effect` in `script.rpp`)
* `test_src/external/` - files copied from `src/`'s raylib & std sub-modules (DO NOT EDIT, since changes will be overriden)
* `include/`           - c header files accessible for include (c:import) from .rpp
* `local-run.bat`'s    - common run command(s) I use, depending on the directory (notably `./`, `src`, & `test_src`)
Build/Temp:
* `out/`               - generated c code from src
* `test_out/`          - generated c code from test_src
* `test_resource/`     - used for the runtime-created .dlls for hot-reloading :D
* `build/`             - cmake build files for both src & test_src
* `build/edit.exe`     - the actual executable we create!
---

## Guide: Getting Proper C Environment setup!

### Compiler Setup (MinGW)
* Download `w64devkit-x64-2.0.0.exe` (first one) from downloads @ [github:skeeto/w64devkit](https://github.com/skeeto/w64devkit/releases)
* Run the exe, and extract to wherever you want that to sit :)
* add to PATH: `<path-to>\w64devkit\bin`

> w64devkit contains the `gcc` (C compiler) we'll use, as well as many other helpful unix-like tools (`gdb`, `ls`, `mkdir`, ...)

### CMAKE
Install `CMake` (using winget [`winget install CMake`])

add environment variable
CMAKE_GENERATOR=`MinGW Makefiles`

---

## Guide: Getting R++ (.rpp) setup!

### Install
add to PATH: `<path-to-this-repo>\install\win\bin`
add environment variable
RPP_INSTALL_PATH=`<path-to-this-repo>\install`

---

## Guide: Setting up .rpp VSCode Support (technically optional, but recommended :D)
* Open VSCode to Extensions Tab
* At top-right, hit 3-dots...
* "Install from .VSIX" (bottom option)
* Select `<path-to-this-repo>\install\vscode\rpp-0.0.1.vsix`

If your `rpp` is installed correctly, you should be good to go! :DDD

## Guide: Setting up this project!

### Running the Program

> note: all scripts in `scripts/` must be invoked from repo top-level (here).

Run init script
`.\scripts\init.bat`

> should only be needed once, but if your files ever get out-of-sync or cmake fails strangely (likely due to cache issues), you would delete the `build/` folder and re-run the init script.

Now to run or re-compile the program:
`.\scripts\run.bat`
> also available as `src\local-run.bat`

> this may take a decent bit the first time, since cmake may need to download/build raylib, but after that, it should be pretty quick!

NOTE: The generated C-code from `rpp` creates a .gitignored project `out/` folder, which we execute `cmake` on to create `build/`
* On Windows, it's important that the output executable `.\build\edit.exe` has `libraylib.dll` in the same immediate directory -- otherwise it will silently crash D: (due to shared-lib dependency)

### Hot-reload Compiling the Test Code

While the program is running, you can make changes to the rendering code in `test_src\script.rpp's` `cool_effect(...)` function!

Use `.\scripts\test-run.bat` or `test_src\local-run.bat` - which (if things work correctly), should produce a `newlibscript.dll` into `test_resource/`, to be loaded by .\edit.exe at runtime

---

## Language-Tool/Extension Functionality to Expect (Currently)
LSP features provided:
* diagnostics (errors / warnings)
    - for certain critical mistakes in writing .rpp, there will appear a single warning at the very top of the file (generally, though, you should be able to see multiple errors at once)
* syntax highlighting (technically not from LSP, but within the same extension :D)
* goto-definition, goto references, & rename (highly recommend!)  --there are a few places like generic-heavy code where these might be iffy, but they work pretty well otherwise
* hover - basic type or field information on expressions & statements

## IMPORTANT NOTE REGARDING VSCODE LSP:
Currently, the lsp (which provides the errors), only works correctly when your root is either of the `*src` directories
> this is because it will currently recognize both src & test_src as belonging to the same code-base, which causes errors since they 

> I plan to address this as soon as I reasonably can, but for now I recommend keeping 2 VSCode's open: in `src/` & `test_src/`

## Next Up

check out `intro.md` and `syntax-guide.md` in `docs/`
