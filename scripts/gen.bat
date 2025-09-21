REM DO NOT -include-c-file:include/tinyfiledialogs.c due to <windows.h> use + unity-build!!
crust build src -out-dir:out -build-type:cgen -unity-build -include-h-file:include/clay.h -include-c-file:include/clay_renderer_raylib.c
