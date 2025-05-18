# AUTOMATICALLY UPDATE COMPILATION VERSION
if [[ -f version.txt ]]; then
	version_num=$(cat version.txt);
	version_num=$((version_num + 1));
	echo "$version_num" > version.txt;
else
	echo "1" > version.txt
fi

# DO COMPILATION
./local-run.sh
