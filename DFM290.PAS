{ DFM290.pas }
{ PMS 2-May-1990 01:06 }

Program DFM290(input,output);
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

{.$M 16384, 0, 655360}	{	stacksize, heapmin, heapmax	}
{$M 8000, 0, 655360}	{	stacksize, heapmin, heapmax	}

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

{	end of DFM290.pas	}
