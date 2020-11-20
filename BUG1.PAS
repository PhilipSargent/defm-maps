{ DFM1.pas - 80x87 options }
{ PMS 13-April-1988 16:09 }

{$R-}    {Range checking off}
{$I+}    {I/O checking on}
{$N+}    {Use numeric coprocessor}

Program DFM1(input,output);

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   M.F.Ashby and P.M.Sargent        **************
   *************   April 1988                       **************
}

{	Be careful, the source code for these Units does not
	specify whether the 80x87 is to be used or not; so you
	have to make sure that you Build (not Make) the entire
	system and that you specify Hardware arithmetic options 
	and not software. PMS 11-January-1988 15:54 
}

Uses
  Crt,
  Dos,
  Printer,
  BUGglbls,
  BUGfiles,
  BUGmodls,
  BUGplots,
  BUGmain;

BEGIN
  main_procedure;
END.

{	end of DFM1.pas	}
