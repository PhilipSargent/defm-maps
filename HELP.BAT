rem DFM290 0.8  HELP file
rem 23-March-1990 11:50 
echo off
echo Expecting floppy to be in drive A: ..
pause
a:
readme
cls

echo Now loading the program with an information option, wait a bit...
dfm290 -e
pause
echo Now loading the program with the HELP option, wait a bit...
dfm290 -h

echo RUN the program by typing DFM

