rem This just makes the recently changed bits of the system.
rem PMS 24-May-1990 17:27 
rem /Ddebug /Ddetail, /Dcontour, /Dindent are possible options

rem needed to add turbo.tpl and graph.tpu from the TP /BIN folder to this source folder
rem using the -T and -U options. Compiles fine with TP v7.0 !
rem PMS 19-Nov-2020 23:31 

\TPWDB\BIN\tpc -T\TPWDB\BIN -U\TPWDB\UNITS dfm290 /$D+/$R+/$B+/$S+/$I+/$N+/$E+/$V+ /V /b /Dcontour %1 %2
