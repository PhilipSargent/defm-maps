rem bf-ind.bat
rem PMS 12-June-1993 04:45 
rem $Revision:   1.0  $
rem $Date:   12 Jun 1993  4:46:08  $
rem /Ddebug /Ddetail, /Dcontour, /Dindent are possible options
\tp\tpc /tc:\tp /uc:\tpus dfm290 /$R+/$B+/$S+/$N+ /V /b /Ddebug /Dindent 
rem /L uses disc for link buffer
rem /G+ is 286 only, /E- means no emulation: needs x87
copy dfm290.exe junk&
\tp\tpc /tc:\tp /uc:\tpus dfm290 /$R+/$S+/$N+/$E-/$G+/$I+/$D+ /b /Ddebug /Dcontour /Dindent %1 %2 %3
del dfm-ind.exe
ren dfm290.exe dfm-ind.exe
ren junk& dfm290.exe
