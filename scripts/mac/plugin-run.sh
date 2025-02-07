./scripts/mac/plugin-gen.sh;
gcc -dynamiclib -std=gnu99 .\plugin_out\list.c .\plugin_out\map.c .\plugin_out\pair.c .\plugin_out\plugin.c .\plugin_out\plugin_core.c .\plugin_out\prelude.c .\plugin_out\slice.c .\plugin_out\std.c .\plugin_out\thread.c .\plugin_out\timer.c -I./plugin_out -current_version 1.0 -compatibility_version 1.0 -o plugin_out/rpp_plugin.dylib;
cp plugin_out/rpp_plugin.dylib test_src/plugins/rpp_plugin.dylib;
# how to gcc make dll windows???
