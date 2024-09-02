{	old_cntr.pas	from dfmplots.pas }
{ PMS 27 Nov 2020 21:21 }
{---------------------------------------------------------------------------}
{ $Revision:   1.1  $
  $Date:   12 Jun 1993  4:13:12  $
  $Logfile:   C:/DFMAP/VCSFILES/OLD_CNTR.PAV  $
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
{ $Log:   C:/DFMAP/VCSFILES/OLD_CNTR.PAV  $
 * 
 *    Rev 1.1   12 Jun 1993  4:13:12   PMSargent
 * New headers
 ---------------------------------------------------------------------------}
{$DEFINE  debug} {	always on, pending removal of directive	}

PROCEDURE Contours_Loop (temp_step: Word);
CONST
	fudge	=	0.3;
VAR
	k, field,
	lastfield 	:	E_mech;

	c				:	E_n_stress;
	n_actual		:	E_n_stress;
	x_half, y_half, y_now:	Integer;
	Rate			:	a_real;
	LgSN			:	a_real;
	hint_stress	:	a_real;
	last_Rate	:	a_real;
	mark			:	a_real;
	last_mark	:	a_real;
	mark_step	:	a_real;
	increment	:	a_real;
	min_rate_on_plot	:	a_real;
	max_rate_on_plot	:	a_real;
	stress_step			:	Word;

BEGIN
	last_Rate	:=	0.0;
	last_mark	:=	0.0;
	mark_step := LgSNstep/(LgSNlast - LgSNfirst);

	lastfield  := null;
	n_actual	:= contournumber+1;

	STRAIN_RATES (TN, LgSNlast, Rate, field, hint_stress);
	field_ids[n_actual].stress := LgSNlast;
	field_ids[n_actual].id     := field;
	max_rate_on_plot := Rate;
{$IFDEF detail}
	Writeln(db);
{$endif}
	STRAIN_RATES (TN, LgSNfirst, Rate, field, hint_stress);
	field_ids[0].stress := LgSNfirst;
	field_ids[0].id     := field;
	min_rate_on_plot := Rate;
{$IFDEF detail}
	Writeln(db);
	Writeln(db);
{$endif}
{ ========== S T A R T == T H E == S T R E S S == L O O P ========= }
	FOR stress_step := steps DOWNTO 1 DO
		BEGIN
		{ ----- Calculate strain rates for LgSN > LgSNfirst ----- }

			LgSN := LgSNfirst + LgSNstep*(stress_step - 0.5);
			STRAIN_RATES (TN, LgSN, Rate, field, hint_stress);

			mark := (LgSN - LgSNfirst)/(LgSNlast - LgSNfirst);
		{ ----- Identify the appropriate contour ----- }
{$IFDEF detail}
			Writeln(db);
{$endif}
			FOR c := 1 TO contournumber DO
				BEGIN
{$IFDEF detail}
					Write(db,c:2,' ');
{$endif}
					IF (( Rate >= contour[c]/sqrt_factor)
					AND ( Rate <  contour[c]*sqrt_factor )) THEN
					{ ---	Now we know that the strain rate is closer
							to this particular contour than to any other --- }
						BEGIN
							contourmark[c] := mark;

							{	We don't want the interpolation for the fields id	}
							field_ids[c].id     := field;
							field_ids[c].stress := LgSN;

						{ ---	Now some interpolation to shift the position
								of the contour in the right direction --- }
	                  IF (Rate <> 0.0) THEN
   	                  IF (Rate < contour[c]) THEN
									contourmark[c] := mark + mark_step*fudge*
										(contour[c]/Rate)/sqrt_factor
								ELSE
									contourmark[c] := mark - mark_step*fudge*
										(contour[c]/Rate)/sqrt_factor;
						{ ---	End of little interpolation section	--- }

{$IFDEF detail}
							Writeln(db,'within sqrt range, OK ');
{$endif}
						END
					ELSE
					{ ---	Now we check if we have skipped a contour --- }
						BEGIN
{$IFDEF detail}
							Write(db,'NOT within sqrt range ');
{$endif}
							IF ((last_Rate > contour[c]*sqrt_factor)
							AND (Rate < contour[c]/sqrt_factor)) THEN
							{	Descending stress	}
								BEGIN
								{	We don't want the interpolation for the fields id	}
									field_ids[c].id     := field;
									field_ids[c].stress := LgSN;
									IF ((last_Rate <> 0.0)
     			            	AND (Rate <> 0.0)) THEN
										contourmark[c] := last_mark - mark_step*
											(Ln(last_Rate) - Ln(contour[c]))/
											(Ln(last_Rate) - Ln(Rate))
									ELSE
										contourmark[c] := last_mark - mark_step*0.5;
{$IFDEF detail}
									Writeln(db,' but skipped, OK ');
{$endif}
								END
							ELSE	{	unset contours are off the plot	}
								BEGIN
{$IFDEF detail}
									Write(db,' but off the plot.. ');
{$endif}
									IF (Rate <= min_rate_on_plot) THEN
										BEGIN
											field_ids[c].id     := field_ids[0].id;
											field_ids[c].stress := field_ids[0].stress;
{$IFDEF detail}
											Writeln(db,' under the bottom, OK ');
{$endif}
										END
									ELSE IF (Rate >= max_rate_on_plot) THEN
										BEGIN
											field_ids[c].id     :=
												field_ids[n_actual].id;
											field_ids[c].stress :=
												field_ids[n_actual].stress;
{$IFDEF detail}
											Writeln(db,' over the top, OK ');
{$endif}
										END
									ELSE
										BEGIN
{$IFDEF detail}
											Writeln(db,' missed this time, OK ');
{$endif}
										END;	{	catchall Else block	}
								END;	{	unset contours off plot	}
						END;		{	check if we missed a contour	}

				END;	{	For loop c: 1 -> contournumber	}

			last_Rate	:=	Rate;
			last_mark	:= mark;

			{ ----- Identify changes of mechanism ----- }
			IF (lastfield  <> field) THEN
				BEGIN
					lastfield := field;

{$IFDEF detail}
					IF (stress_step < steps) THEN
							Write(db,'  x');
{$ENDIF}
				END;

{$IFDEF detail}
			Writeln(db);
{$ENDIF}

		END;	{	stress_step For loop	}
{ ========== E N D == T H E == S T R E S S == L O O P ========= }

{	Overwrite contour ids if they are off the bottom	}
	FOR c := contournumber-1 DOWNTO 1 DO
		BEGIN
		{	other tests don't work, .stress is not [0].stress but -5.92 instead of -6	}
			IF (contourmark[c] <= 0.0) THEN	
				field_ids[c].id     := field_ids[c+1].id;
		END;

{	Quick fix-up of contours which are never seen by the search algorithm because
	they are off the top, uses a slightly different method from the above,
	24-May-1990 14:14 PMS	}
	FOR c := 1 TO contournumber DO
		IF (field_ids[c].stress < field_ids[c-1].stress) THEN	{	out of sequence!	}
			BEGIN
				field_ids[c] := field_ids[n_actual];			{	all fields	}
				field_ids[c].id := field_ids[n_actual].id;			{	all fields	}
			END;

{$IFDEF contour}
	Writeln(db,'[c]   LgCntr    C''mark     stress    rate        visible field');
	FOR c := n_actual DOWNTO 0 DO
		WITH field_ids[c] DO
		BEGIN	{	For loop & With block	}
			IF (c>=n_actual) OR (c<=0) THEN
				Write(db, c:3,'     --limit--        ',stress:8:3,' ')
			ELSE
				Write(db, c:3,' ',(Ln(contour[c])/Ln10):8:1,
					'  ',contourmark[c]:9:5,
					'  ',stress:8:3,' ');
			Write(db, rate:12,' ');
			IF visible THEN 
				Write(db,'  Visible ') 
			ELSE 
				Write(db,'Invisible ');
			WRITE_FIELDNAME(id);
			WriteLn(db);
		END;	{	For loop & With block	}
	WriteLn(db);
{$endif}

END;	{	Contours_Loop	procedure }
{---------------------------------------------------------------------------}

