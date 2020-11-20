{ DFM290.pas }
{ PMS 12-June-1993 03:02 }

Program DFM290(input,output);
{---------------------------------------------------------------------------}
{ $Revision:   1.1  $
  $Date:   12 Jun 1993  4:11:14  $
  $Logfile:   C:/DFMAP/VCSFILES/DFM290.PAV  $
 ---------------------------------------------------------------------------}
{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
   *************     Department, Cambridge, UK.     **************
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
{ $Log:   C:/DFMAP/VCSFILES/DFM290.PAV  $
 * 
 *    Rev 1.1   12 Jun 1993  4:11:14   PMSargent
 * New headers
 ---------------------------------------------------------------------------}
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
