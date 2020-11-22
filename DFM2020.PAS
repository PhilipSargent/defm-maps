{ DFM2020.pas }
{ PMS 22 Nov 2020 20:07 }

Program DFM2020(input,output);
{---------------------------------------------------------------------------}
{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
   *************   Department, Cambridge, UK.       **************
   *************   P.M.Sargent and M.F.Ashby        **************
   *************   June 1993                        **************

   This is free software, you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published
   by the Free Software Foundation; either version 2 of the License,
   or (at your option) any later version.
	This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of 
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   General Public License for more details.
   The file COPYING enclosed with this software contains a copy of
   version 2 of the GNU General Public License which should not be
   altered in any way. If it is missing, write to the Free Software
   Foundation Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 ---------------------------------------------------------------------------}
{	Be careful, the source code for these Units does not
	specify whether the 80x87 is to be used or not; so you
	have to make sure that you Build (not Make) the entire
	system and that you specify $N+ and $E+ for each unit.
	15-December-1989 02:17 PMS
}
{	Renamed from DFM290 to DFM2020 when porting from TurboPascal 7
	under DOSBOX to fpc runnig natively on Windows10 with TP 
	emulation.
	22-November-2020 17:30 PMS
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

{	end of DFM2020.pas	}
