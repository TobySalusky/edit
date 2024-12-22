rm -rf test_src/external && mkdir test_src/external && cp -r src/std test_src/external && cp -r src/raylib test_src/external && rpp build test_src -out-dir:test_out -build-type:cgen
