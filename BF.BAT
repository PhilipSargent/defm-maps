rem
rem PMS 5-December-1991 07:48 
rem /Ddebug /Ddetail, /Dcontour, /Dcntrfix, /Dindent are possible options
rem /G+ is 286 only, /E- means no emulation: needs x87
\tp\tpc /tc:\tp /uc:\tpus dfm290 /$R+/$S+/$N+/$E-/$G+ /b %1 %2 %3 %4
