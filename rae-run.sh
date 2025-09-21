# AUTOMATICALLY UPDATE COMPILATION VERSION
# if [[ -f version.txt ]]; then
# 	version_num=$(cat version.txt);
# 	version_num=$((version_num + 1));
# 	echo "$version_num" > version.txt;
# else
# 	echo "1" > version.txt
# fi

# DO COMPILATION
# ./local-run.sh
./scripts/mac/gen.sh;
cmake --build build;
lldb ./build/edit_app.app/Contents/MacOS/edit_app -o r;
