./scripts/mac/plugin-gen.sh;
gcc -dynamiclib -std=gnu99 $(find plugin_out -type f -name \*.c) -I./plugin_out -current_version 1.0 -compatibility_version 1.0 -o plugin_out/rpp_plugin.dylib;
cp plugin_out/rpp_plugin.dylib test_src/plugins/rpp_plugin.dylib;
