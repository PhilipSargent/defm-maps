echo off
rem PMS 22-Nov-2020 17:30
rem Using fpc 
rem uses fpc.cfg to include these units:
rem -FuC:\FPC\3.2.0\units\x86_64-win64\rtl-console -FuC:\FPC\3.2.0\units\x86_64-win64\rtl-extra -FuC:\FPC\3.2.0\units\x86_64-win64\graph
rem - standard crt unit in rtl-console
rem - standard printer unit in rtl-extra
rem - standard graph unit in graph

rem should use a make utility as this will not recompile units
del *.o
del *.ppu
del old.exe
del dfm2020.exe
del dfm2020dbg.exe

REM -dCONTOUR OR -dDETAIL sets DEBUG on, which then crashes when it tries to open debug.txt
C:\FPC\3.2.0\bin\i386-win32\ppcrossx64 -Mtp dfm2020

ren dfm2020.exe old.exe
del *.o
del *.ppu

C:\FPC\3.2.0\bin\i386-win32\ppcrossx64 -Mtp  -dDEBUG -dCONTOUR -dDETAIL dfm2020 
ren dfm2020.exe dfm2020dbg.exe
ren old.exe dfm2020.exe

REM Note that -dINDENT fails as there is a debug text writing problem