{ DFM2020.pas }
{ PMS 01-December-2020 18:30:01 }

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

{	Renamed from DFM290 to DFM2020 when porting from TurboPascal 7
	under DOSBOX to fpc running natively on Windows10 with TP 
	emulation.
	22-November-2020 17:30 PMS
}
{$M 8000, 0, 655360}	{	stacksize, heapmin, heapmax	-  still valid in fpc} 
{$R+}	{Range checking on}
{$B+}	{Boolean complete evaluation on}
{$S+}	{Stack checking on}
{$I+}	{I/O checking on}
Uses
  Crt,
  Dos,
  Printer,
  Dfmglbls,
  Dfmfiles,
  Dfmmodls,
  Dfmplots,
  Dfmindnt,
  Dfmmain;

BEGIN
  Dfmmain.main_procedure;
END.

{	end of DFM2020.pas	}
