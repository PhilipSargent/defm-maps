rem This just makes the recently changed bits of the system.
rem PMS 24-May-1990 17:17 
rem /Ddebug /Ddetail, /Dcontour, /Dindent are possible options
rem /L uses disc for link buffer
tpc /tc:\tp55 /uc:\opro dfm290 /$D+/$R+/$B+/$S+/$I+/$N+/$E+/$V+ /V /m /Ddebug %1 %2 %3 %4
