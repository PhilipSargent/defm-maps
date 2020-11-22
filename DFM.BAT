rem Makes %1
rem PMS 22-Nov-2020 15:04 
rem /Ddebug /Ddetail, /Dcontour, /Dindent are possible options

\TPWDB\BIN\tpc -T\TPWDB\BIN -U\TPWDB\UNITS %1 /$D+/$R+/$B+/$S+/$I+/$N+/$E+/$V+ /V /b /Dcontour /Ddebug /Ddetail
