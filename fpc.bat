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

REM -dCONTOUR OR -dDETAIL sets DEBUG on, which then crashes when it tries to open debug.txt
C:\FPC\3.2.0\bin\i386-win32\ppcrossx64 -Mtp dfm2020