rem Using fpc 
rem PMS 20-Nov-2020 11:10 
echo off
rem uses fpc.cfg to include these units:
rem - standard crt unit in rtl-console
rem - standard printer unit in rtl-extra
rem - standard graph unit in graph


C:\FPC\3.2.0\bin\i386-win32\ppcrossx64 -Mtp  dfm290 
rem -FuC:\FPC\3.2.0\units\x86_64-win64\rtl-console -FuC:\FPC\3.2.0\units\x86_64-win64\rtl-extra -FuC:\FPC\3.2.0\units\x86_64-win64\graph

