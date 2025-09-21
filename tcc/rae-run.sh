# gcc main.c -g -o main -L./ -ltcc && ./main # OLD
crust build . -out-dir:out -build-type:cgen -unity-build -include-h-file:libtcc.h && gcc out/__unity__.c -g -o main -L./ -ltcc && ./main
