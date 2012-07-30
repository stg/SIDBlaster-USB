@echo off
gcc -c hardsid.c
gcc -shared -o hardsid2.dll -Wl,--export-all-symbols -Wl,--kill-at hardsid.o
del hardsid.o
strip hardsid.dll