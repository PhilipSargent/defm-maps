{contours.pas, from DfmPlots.pas	}
{ PMS 12-June-1993 03:01 }
{---------------------------------------------------------------------------}
{ $Revision:   1.1  $
  $Date:   12 Jun 1993  4:13:24  $
  $Logfile:   C:/DFMAP/VCSFILES/CONTOURS.PAV  $
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
{ $Log:   C:/DFMAP/VCSFILES/CONTOURS.PAV  $
 * 
 *    Rev 1.1   12 Jun 1993  4:13:24   PMSargent
 * New headers
 ---------------------------------------------------------------------------}
PROCEDURE Contours_Init;
VAR
	c	:	E_n_stress;
BEGIN
	FOR c := 0 TO C_num_cntrs DO
		BEGIN
			field_ids[c].stress := -1.0;
			field_ids[c].id     := null;
			field_ids[c].rate   := 1.0e-20;
			field_ids[c].visible:= FALSE;
			field_ids[c].converged:= FALSE;
		END;
END;	{	Contours_Init	procedure }
{---------------------------------------------------------------------------}
{$IFDEF cntrfix }
{$I \dfmap\old_cntr.pas	}
{$ELSE}
PROCEDURE Contours_Loop (temp_step: Word);
VAR
	field			:	E_mech;

	c,cc,
	n_actual		:	E_n_stress;
	root_factor	:	a_real;
	Rate			:	a_real;
	LgSN			:	a_real;
	LgRatio	  	:	a_real;
	hint_stress	:	a_real;
	mark_step	:	a_real;
	min_rate_on_plot	:	a_real;
	max_rate_on_plot	:	a_real;
	prev_stress, prev_rate	:	a_real;

	{------------------------------------------------------------------------}
{$IFDEF contour}
PROCEDURE Contours_debug;
VAR
	c	:	E_n_stress;
BEGIN
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
			IF converged THEN 
				Write(db,'  ') 
			ELSE 
				Write(db,' *');
			WriteLn(db);
		END;	{	For loop & With block	}
	WriteLn(db);
END;	{	Contours_debug	}
{$ENDIF}
	{------------------------------------------------------------------------}
PROCEDURE Iterate_One_Contour(previous_stress, previous_rate, LgSN: a_real; 
																				c: E_n_stress);
CONST
	iter_limit	=	13;
VAR
	RateRatio, SNdiff, strain_rate		:	a_real;
	step, factor	:	a_real;
	n	:	Byte;
		{---------------------------------------------------------------------}
PROCEDURE Bisect;
VAR
	Rate_ratio	:	a_real;
BEGIN
	LgSN := (LgSN + previous_stress)/2.0;
	SNdiff := LgSN - previous_stress;

{	Another (better) estimate, if everything is NOT weird	}
	IF ((previous_rate > contour[1]) 
		AND (previous_rate < contour[contournumber]))
 	AND ((strain_rate > contour[1]) 
		AND (strain_rate < contour[contournumber])) THEN
		BEGIN
			Rate_ratio	:= (contour[c] - previous_rate)/(strain_rate - previous_rate);
			LgSN := previous_stress + (LgSN - previous_stress)*Rate_ratio;
{$IFDEF contour}
			Write(db,' !!');
{$ENDIF}
		END;

	SNdiff := LgSN - previous_stress;
END;	{	Bisect	}
		{---------------------------------------------------------------------}
BEGIN		{	Iterate_One_Contour	}
{$IFDEF contour}
		WriteLn(db);
{$ENDIF}
	step := 1.0;
	n := 0;
	SNdiff := LgSN - previous_stress;
	REPEAT	

		STRAIN_RATES (TN, LgSN, strain_rate, field, hint_stress);
		RateRatio := (strain_rate/contour[c]);
		IF (RateRatio < 1) THEN
			RateRatio := 1/RateRatio;
		Inc(n);
{$IFDEF detail}
		Flush(db);
		WriteLn(db);
{$ENDIF}
{$IFDEF contour}
		WriteLn(db,
			' c =',c:2,
			' Rates:   ',previous_rate:12,'->',field_ids[c].rate:12,' ->',strain_rate:12,
			' LgSN :   ',previous_stress:8:3,'->',field_ids[c].stress:8:3,' ->',LgSN:8:3);
		Write(db,
			' SNdiff =',SNdiff:8:3,
			' factor =',factor:8:3,
			' (rate/contour)=',(strain_rate/contour[c]):12,
			' inv.=',RateRatio:12);
{$ENDIF}
		field_ids[c].id		:= field;				{	and update..	}

		IF ((contour[c] > strain_rate) AND (contour[c] < previous_rate)) 
		OR ((contour[c] < strain_rate) AND (contour[c] > previous_rate)) THEN
			BEGIN
			{	Throw away the field_ids[c].stress, keep previous (& current)	}
				field_ids[c].rate			:= strain_rate;
				field_ids[c].stress		:= LgSN;
				Bisect;
{$IFDEF contour}
				WriteLn(db,' BISECT- ');
{$ENDIF}
			END
		ELSE
		IF ((contour[c] > strain_rate) AND (contour[c] < field_ids[c].rate)) 
		OR ((contour[c] < strain_rate) AND (contour[c] > field_ids[c].rate)) THEN
			BEGIN
			{	Throw away the previous_stress, keep field_ids[c].stress (& current)	}
				previous_rate			:= field_ids[c].rate;
				previous_stress		:= field_ids[c].stress;
				field_ids[c].rate			:= strain_rate;
				field_ids[c].stress		:= LgSN;
				{	previous is now 'really' field_ids[c].stress	}
				Bisect;
{$IFDEF contour}
				WriteLn(db,' BISECT+ ');
{$ENDIF}
			END
	{		Split to the limits of the plot (if the contour is going to appear on
			the plot, biasing heavily towards the current value of stress.	}
		ELSE 
			BEGIN		{ ==========	extrapolation options ==========	}
				{	'previous' values are not relevant or interesting here	}
				previous_rate			:= field_ids[c].rate;
				field_ids[c].rate		:= strain_rate;

				previous_stress		:= field_ids[c].stress;
				field_ids[c].stress	:= LgSN;

				IF ((strain_rate > contour[c]) AND (contour[c] > field_ids[0].rate)) THEN
					BEGIN
						LgSN := (5 * field_ids[c].stress + field_ids[0].stress)/6.0;
{$IFDEF contour}
						WriteLn(db,' DROP    ');
{$ENDIF}
					END
				ELSE IF ((strain_rate < contour[c]) AND (contour[c] < field_ids[n_actual].rate)) THEN
					BEGIN
						LgSN := (5 * field_ids[c].stress + field_ids[n_actual].stress)/6.0;
{$IFDEF contour}
						WriteLn(db,' PUSH UP ');
{$ENDIF}
					END
				ELSE	{	catchall - very slow	}
					BEGIN
						factor := 1.0 + step;
						step := step/1.3;
						IF (strain_rate > contour[c]) THEN
							LgSN := field_ids[c].stress * factor	{	since it is -ve	}
						ELSE
							LgSN := field_ids[c].stress / factor;	{	since it is -ve	}
{$IFDEF detail}
						WriteLn(db,' FACTOR  ');
{$ENDIF}
					END;
				SNdiff := LgSN - field_ids[c].stress;
			END;	{ ==========	extrapolation options ==========	}

	UNTIL	
		{	((Abs(SNdiff) < 0.5*mark_step) 
		AND (RateRatio < root_factor))	}
	(RateRatio < root_factor)
	OR (n >= iter_limit);
	{	Convergence when we are closer in strain rate than any other
		contour (for low temperatures), or closer in stress than the
		'step length' on the map (high temperatures).

		Note that we have to be quite careful that the values of .stress
		and .rate in field_ids[c] are the ones that the loop actually
		converged on, and not the values set up for the 'next' iteration.
		30-April-1990 23:34 PMS
	}
		IF (n >= iter_limit) THEN		{	exit this loop	}
			BEGIN
				field_ids[c].converged := FALSE;
{$IFDEF contour}
				Writeln(db,' EXIT LOOP');
{$ENDIF}
			END
		ELSE
			field_ids[c].converged := TRUE;

END;	{	Iterate_One_Contour	}
	{------------------------------------------------------------------------}
PROCEDURE Iterate_All_Contours;
{	This procedure assumes that field_ids contains some kind of estimate
	of the stress and strain rate, but a very poor one.  The main routine
	Contours_Loop assumes that we have a very good estimate.	
	PMS 27-April-1990 00:45 }
VAR
	c	:	E_n_stress;
	previous_stress, previous_rate	:	a_real;
BEGIN
{$IFDEF contour}
	Writeln(db,'Stress incr.target:',{0.5*}mark_step:8:3,
					' RateRatio target: ',root_factor:8:3);
	Writeln(db);
{$ENDIF}
	FOR c := contournumber DOWNTO 1 DO
		BEGIN
		{	start them off at a self-consistent point, either the top limit
			or the previous (solved) contour	}

			previous_stress := field_ids[c+1].stress;		
			previous_rate := field_ids[c+1].rate;			
			LgSn := previous_stress * 1.01 ;	{	guess, larger -ve so lower stress	}

			Iterate_One_Contour(previous_stress, previous_rate, LgSN, c);
		END;
END;	{	Iterate_All_Contours	}
	{------------------------------------------------------------------------}
PROCEDURE Finish_Contours;
VAR
	c	:	E_n_stress;
BEGIN
	FOR c := contournumber DOWNTO 1 DO
		contourmark[c] := (field_ids[c].stress - LgSNfirst)/(LgSNlast - LgSNfirst);
{$IFDEF detail}
	Writeln(db,'Final values for this call to Contours_Loop');
	Contours_debug;
{$ENDIF}
END;	{	Finish_Contours	}
	{------------------------------------------------------------------------}
BEGIN	{	Procedure Contours_Loop	}
	
	n_actual := contournumber + 1;
	root_factor := sqrt(cntrfactor);
	mark_step := LgSNstep/(LgSNlast - LgSNfirst);

	STRAIN_RATES (TN, LgSNlast, Rate, field, hint_stress);
	field_ids[n_actual].stress := LgSNlast;
	field_ids[n_actual].id     := field;
	field_ids[n_actual].rate   := Rate;
	max_rate_on_plot := Rate;
{$IFDEF detail}
	Writeln(db);
{$ENDIF}

	STRAIN_RATES (TN, LgSNfirst, Rate, field, hint_stress);
	field_ids[0].stress := LgSNfirst;
	field_ids[0].id     := field;
	field_ids[0].rate   := Rate;
	min_rate_on_plot := Rate;
{$IFDEF detail}
	Writeln(db);
{$ENDIF}
{$IFDEF contour}
	Writeln(db);
	Writeln(db,'Values with LIMITS overwritten');
	Contours_debug;
{$ENDIF}

	IF (TN <= 0.0) THEN	{	at 0 K	}
		BEGIN

			STRAIN_RATES (TN, (LgSNfirst+LgSNlast)/2, Rate, field, hint_stress);
{$IFDEF detail}
	Writeln(db);
	Writeln(db,'  <- 0 K HINT CALC');
	Writeln(db,'TN=',TN:8:3,'  (0 K) hint stress is',hint_stress:8:3);
{$ENDIF}
			FOR c := 1 TO contournumber DO
				BEGIN
					field_ids[c].stress := hint_stress;		{	Obst or Peierls stress	}
					field_ids[c].id     := field;
					field_ids[c].rate   := contour[c];
					field_ids[c].visible:= TRUE;
				END;
{			field_ids[n_actual].rate   := field_ids[n_actual-1].rate;	}
			Finish_Contours;
			Exit;					{	***	return from Contours_Loop here	***	}
		END;

	IF (TN > 0.0) 
	AND (temp_step < 1) THEN		{	No previous calcs., but not at 0 K	}
		BEGIN
			LgSN := (LgSNfirst+LgSNlast)/2;
			STRAIN_RATES (TN, LgSN, Rate, field, hint_stress);
{$IFDEF detail}
			Writeln(db,'  <- HINT ');
{$ENDIF}
{			FOR c := 0 TO n_actual DO	}
			FOR c := 1 TO contournumber DO	
				BEGIN
					field_ids[c].stress := LgSN;		
					field_ids[c].id     := field;
					field_ids[c].rate   := Rate;
					field_ids[c].visible:= TRUE;
				END;
			Iterate_All_Contours;
			Finish_Contours;
			Exit;					{	***	return from Contours_Loop here	***	}
		END

	ELSE IF (temp_step = 1) 
	AND (TNfirst <= 0.0) THEN		{	previous step was at 0 K	}
		BEGIN
			Iterate_All_Contours;
			Finish_Contours;
			Exit;					{	***	return from Contours_Loop here	***	}
		END;
{%%%%%%%%%%%%%%%%%%%%%%%%%%%finish%%%%%%%%%%%%%%%%%%%%}
{	IF (temp_step >= 15) THEN Halt(1);						}
	
{ ========== S T A R T == T H E == S E T U P == L O O P ========= }
	{	Do a first pass, using the LgSN values for the PREVIOUS temperature,
		first, check which contours were visible at the PREVIOUS temperature.	}

{	Only bother if we are not on the first temp.	which is temp_step = 0	}
	IF (temp_step >= 1) THEN	
	FOR c := 1 TO contournumber DO
		BEGIN	
			{	This assumes that the last temp. got consistent stresses & strain_rates	}
			IF (field_ids[c].stress <= LgSNlast)
			AND (field_ids[c].stress >= LgSNfirst) THEN
				field_ids[c].visible := TRUE
			ELSE
				field_ids[c].visible := FALSE;

			LgSN := field_ids[c].stress;				{	previous value	}
			STRAIN_RATES (TN, LgSN, Rate, field, hint_stress);
			field_ids[c].id     := field;				{	and update..	}
			field_ids[c].rate   := Rate;
{$IFDEF detail}
			Writeln(db);
{$ENDIF}
		END;

{	Set id for those that dropped off the bottom	}
	FOR c := contournumber DOWNTO 1 DO
		BEGIN
			IF NOT field_ids[c].visible THEN
				field_ids[c].id :=  field_ids[c+1].id; 	{	OK, n_actual preset }
		END;

{	Set id for those that popped off the top	}
	FOR c := 1 TO contournumber DO
		BEGIN
			IF NOT field_ids[c].visible THEN
				field_ids[c].id :=  field_ids[c-1].id; 	{	OK, 0 is preset	}
		END;
{ ========== E N D == T H E == S E T U P == L O O P ========= }
{$IFDEF contour}
	Writeln(db);
	Writeln(db,'Values after the SETUP loop');
	Contours_debug;
{$ENDIF}

{ ========== S T A R T == T H E == C O N T O U R == L O O P ========= }
{	Find stress which gives Rate closest to the required contour	}
	FOR c := 1 TO contournumber DO
		IF field_ids[c].visible THEN
			BEGIN
				cc := n_actual;
				REPEAT
					Dec(cc);
{$IFDEF contour}
					Writeln(db,'c:cc Loop',c:3,cc:3,' ',contour[c]:12,' ',field_ids[cc].rate:12);
{$ENDIF}
				UNTIL (contour[c] >= field_ids[cc].rate) OR (cc = 0);

				IF (contour[c] <= field_ids[0].rate) THEN
				{	contour is off the bottom..	}
					BEGIN
						field_ids[c].id     := field_ids[0].id;	{	and update..	}
						field_ids[c].rate   := field_ids[0].rate;
						field_ids[c].stress := field_ids[0].stress;
{$IFDEF contour}
						Writeln(db,' Contour ',c:2,' under the bottom, OK ');
{$ENDIF}
					END
				ELSE IF (contour[c] >= field_ids[n_actual].rate) THEN
				{	contour is off the top..	}
					BEGIN
						field_ids[c].id     := field_ids[n_actual].id;	{	and update..	}
						field_ids[c].rate   := field_ids[n_actual].rate;
						field_ids[c].stress := field_ids[n_actual].stress;
{$IFDEF contour}
						Writeln(db,' Contour ',c:2,' off the top, OK ');
{$ENDIF}
					END
				ELSE IF (contour[c] = field_ids[cc].rate) THEN
				{	easy, but have to check for it explicitly	}
					BEGIN
						field_ids[c].id     := field_ids[cc].id;	{	and update..	}
						field_ids[c].rate   := field_ids[cc].rate;
						field_ids[c].stress := field_ids[cc].stress;
{$IFDEF contour}
						Writeln(db,' Contour ',c:2,' exact ! OK ');
{$ENDIF}
					END
				ELSE IF (contour[c] > field_ids[cc].rate) THEN
				{	Now interpolate	}
					BEGIN
						prev_rate		:= field_ids[cc].rate;
						prev_stress		:= field_ids[cc].stress;
						LgRatio	:= (contour[c] - prev_rate)/(field_ids[cc+1].rate - prev_rate);
						LgSN := prev_stress + (field_ids[cc+1].stress - prev_stress)*LgRatio;
						Iterate_One_Contour(prev_stress, prev_rate, LgSN, c);
					END
				ELSE
					BEGIN
{$IFDEF debug}
						Writeln(db,' Should never get here ! In DfmPlots.Contour_Loops');
{$ENDIF}
					END;
				contourmark[c] := (field_ids[c].stress - LgSNfirst)/(LgSNlast - LgSNfirst);
			END;	{	For c loop	}

{	It converges EACH contour individually before going on to the next.
	This is inefficient, it should do one pass over all contours, then
	continue passing and updating until all are converged since it uses
	adjacent contours to get an estimate.	}
{ ========== E N D == T H E == C O N T O U R == L O O P ========= }

{$IFDEF detail}
	Writeln(db,'Final values for this call to Contours_Loop');
	Contours_debug;
{$ENDIF}

END;	{	Contours_Loop	procedure }
{$ENDIF}		{	end of IFDEF cntrfix section	}
{---------------------------------------------------------------------------}

