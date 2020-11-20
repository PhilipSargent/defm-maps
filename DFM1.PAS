{ DFM1s.pas - non 80x87 options }
{ PMS 7-April-1988 17:22 }

{$R-}    {Range checking off}
{$I+}    {I/O checking on}
{$N-}    {Do NOT use numeric coprocessor}


Program DFM1s(input,output);

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   M.F.Ashby and P.M.Sargent        **************
   *************   April 1988                       **************
}
{	Be careful, the source code for these Units does not
	specify whether the 80x87 is to be used or not; so you
	have to make sure that you Build (not Make) the entire
	system and that you specify SOFTware arithmetic options 
	and not Hardware. PMS 11-January-1988 15:54 
}

Uses
  Crt,
  Dos,
  Printer,
  Dfmglbls,
  Dfmfiles,
  Dfmmodls,
  Dfmplots,
  Dfmmain;

BEGIN
  main_procedure;
END.

{	end of DFM1s.pas	}
