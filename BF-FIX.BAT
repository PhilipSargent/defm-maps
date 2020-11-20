rem
rem PMS 5-December-1991 02:09 
rem Includes the OLD contouring regime (/Dcntrfix) 
rem /Ddebug /Ddetail, /Dcontour, /Dcntrfix, /Dindent are possible options
rem /L uses disc for link buffer
rem /G+ is 286 only, /E- means no emulation: needs x87
copy dfm290.exe junk&
\tp\tpc /tc:\tp /uc:\tpus dfm290 /$R+/$S+/$N+/$E-/$G+ /b /Dcntrfix /Ddebug /Dcontour %1 %2 %3
del dfmfix.exe
ren dfm290.exe dfmfix.exe
ren junk& dfm290.exe
