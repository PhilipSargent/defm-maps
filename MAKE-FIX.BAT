rem This just makes the recently changed bits of the system.
rem PMS 24-May-1990 14:58 
rem Includes the OLD contouring regime (/Dcntrfix) 
rem /Ddebug /Ddetail, /Dcontour, /Dindent are possible options
rem /L uses disc for link buffer
copy dfm290.exe junk&
tpc /tc:\tp55 dfm290 /$D+/$R+/$B+/$S+/$I+/$N+/$E+/$V+ /V /m /Dcntrfix /Ddebug /Dcontour %1 %2 %3 
del dfmfix.exe
ren dfm290.exe dfmfix.exe
ren junk& dfm290.exe

