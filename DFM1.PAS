{ DFM1.pas }
{ PMS 3-January-1990 00:34 }

Program DFM1(input,output);

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   P.M.Sargent and M.F.Ashby        **************
   *************   January 1990                     **************
}

{	Be careful, the source code for these Units does not
	specify whether the 80x87 is to be used or not; so you
	have to make sure that you Build (not Make) the entire
	system and that you specify $N+ and $E+ for each unit.
	15-December-1989 02:17 PMS
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
  Dfmmain.main_procedure;
END.

{	end of DFM1.pas	}
