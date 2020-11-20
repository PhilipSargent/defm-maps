rem This just makes the recently changed bits of the system.
rem PMS 18-April-1990 02:16 
rem /Ddebug /Ddetail, /Dcontour, /Dindent are possible options
rem /L uses disc for link buffer
tpc /tc:\tp55 /uc:\opro dfm290 /$D+/$R+/$B+/$S+/$I+/$N+/$E+/$V+ /V /b /Ddebug %1 %2 %3 %4
