./scripts/mac/gen.sh && cmake --build build && cp ./build/libscript.dylib test_resource && ./build/edit.app/Contents/MacOS/edit $@ # && open build/edit.app $@
