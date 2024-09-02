{loops.pas, from DfmPlots.pas	}
{ PMS 12-June-1993 03:03 }
{---------------------------------------------------------------------------}
{ $Revision:   1.1  $
  $Date:   12 Jun 1993  4:12:58  $
  $Logfile:   C:/DFMAP/VCSFILES/LOOPS.PAV  $
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
{ $Log:   C:/DFMAP/VCSFILES/LOOPS.PAV  $
 * 
 *    Rev 1.1   12 Jun 1993  4:12:58   PMSargent
 * New headers
 ---------------------------------------------------------------------------}
PROCEDURE Fields_Loop (temp_step: Word);

VAR
	field,
	field_now,
	field_last,
	next_down_now,
	next_up_now	:	E_mech;
	n_actual		:	E_n_stress;
	centroid	:	T_mecharray;
	spread	:	T_mecharray;
	Rate			:	a_real;
	LgSN			:	a_real;
	hint_stress	:	a_real;
	weight		:	a_real;
	top, bot		:	a_real;
	re_do			:	BOOLEAN;
	boundaries_exist	:	BOOLEAN;
	x_half, y_half, y_now:	Integer;
	c, i, j	 	:	E_n_stress;
	k				:	E_n_bndrys;
	s		:	Word;	{	stress_step	}

	{------------------------------------------------------------------------}
PROCEDURE Find_Boundaries;
VAR
	i, j, item 	:	E_n_stress;
BEGIN
	{ ----- Find the Field boundaries more accurately  ----- }
	{	Note the trouble we go to in order to keep the table sorted,
		so that we don't have to sort it later.	22-March-1990 }
	i := 0;				
	REPEAT
		IF (i+1 > C_num_cntrs) THEN
			Range_Check('Too many boundaries found on first pass')
		ELSE
			Inc(i);
		re_do := FALSE;
		WITH bndry_tabl[i] DO
			BEGIN
				IF ((Abs(stress_hi - stress_lo)/LgSNstep) > 0.5) THEN
					BEGIN
						re_do := TRUE;
						LgSN := stress_mn;
{$IFDEF detail}
						Writeln(db);
{$ENDIF}
						STRAIN_RATES (TN, LgSN, Rate, field, hint_stress);
						IF (field =id_hi) THEN
							stress_hi := LgSN
						ELSE IF(field =id_lo) THEN
							stress_lo := LgSN;
						IF (field <> id_hi)
						AND (field <> id_lo) THEN
							BEGIN	{	a new field in the middle ! }
								IF (n_bndrys+1 > C_num_bndrys) THEN
									Range_Check('Too many boundaries found on interpolation')
								ELSE
									Inc(n_bndrys);						{	make array bigger	}
								FOR item := n_bndrys DOWNTO i+1 DO
									BEGIN	{	Budge up..	happens infrequently	}
										bndry_tabl[item].stress_lo := bndry_tabl[item-1].stress_lo;
										bndry_tabl[item].id_lo 		:= bndry_tabl[item-1].id_lo;
										bndry_tabl[item].stress_hi := bndry_tabl[item-1].stress_hi;
										bndry_tabl[item].id_hi 		:= bndry_tabl[item-1].id_hi;
										bndry_tabl[item].stress_mn := bndry_tabl[item-1].stress_mn;
									END;
								{	..and now overwrite i+1	}
								bndry_tabl[i+1].stress_lo := LgSN;
								bndry_tabl[i+1].id_lo := field;
								bndry_tabl[i+1].stress_hi := stress_hi;
								bndry_tabl[i+1].id_hi := id_hi;
								bndry_tabl[i+1].stress_mn := (stress_hi + LgSN)/2.0;
								{	..and overwrite i	}
								stress_hi := LgSN;
								id_hi := field;
							END;
						stress_mn := (stress_hi + stress_lo)/2.0;
					END;
			END;	{	With block	}
		IF re_do THEN Dec(i);	{	re-do the last one..	}
	UNTIL ( i >= n_bndrys );	{	INCLUDING the new ones..	}

{$IFDEF detail}
	IF NOT (TN <= 0) THEN
		BEGIN
			Writeln(db);
			Writeln(db,'x_last=',x_last:4);
			IF (i >= 1) THEN
				FOR i := 1 to last_n_bndrys DO
					WITH last_bndry_tabl[i] DO
					BEGIN
						write(db,'Boundary:',i:2,' ');
						WRITE_FIELDNAME(id_lo);
						write(db,': ');
						WRITE_FIELDNAME(id_hi);
						write(db,' ',stress_lo:8:3);
						write(db,' ',stress_hi:8:3);
						write(db,' ',stress_mn:8:3);
						write(db,' ',(Abs(stress_hi - stress_lo)/LgSNstep):8:3);
						IF ((Abs(stress_hi - stress_lo)/LgSNstep) > 1.0) THEN
							BEGIN
								write(db,' FIX !');
							END;
						Writeln(db);
					END;
		END;
{$ENDIF}
{$IFDEF debug}
	Writeln(db);
	FOR i := 1 to n_bndrys DO
		WITH bndry_tabl[i] DO
			BEGIN
				write(db,'Boundary#',i:2,' ');
				WRITE_FIELDNAME(id_lo);
				write(db,': ');
				WRITE_FIELDNAME(id_hi);
				write(db,' ',stress_lo:8:3);
				write(db,' ',stress_hi:8:3);
				write(db,' ',stress_mn:8:3);
				write(db,' ',(Abs(stress_hi - stress_lo)/LgSNstep):8:3);
				IF ((Abs(stress_hi - stress_lo)/LgSNstep) > 1.0) THEN
					BEGIN
						write(db,' FIX !');
					END;
				Writeln(db);
			END;
{$ENDIF}

	{ ----- Draw a thick, dashed line for the field boundary  ----- }

	x_now := round(xlength*(TN - TNfirst)/	(TNlast - TNfirst));

	IF (TN <= 0) THEN
		x_last := 0
	ELSE
		FOR i := 1 TO n_bndrys DO
			FOR j := 1 TO last_n_bndrys DO
				WITH bndry_tabl[i] DO
					BEGIN
					{	XOR & AND so that even if both same, only draw once	}
						IF (id_lo = last_bndry_tabl[j].id_lo)
						XOR (id_hi = last_bndry_tabl[j].id_hi) THEN
							DRAW_FIELD_LINE(i,j);
						IF (id_lo = last_bndry_tabl[j].id_lo)
						AND (id_hi = last_bndry_tabl[j].id_hi) THEN
							DRAW_FIELD_LINE(i,j);
					END;
END;	{	Find_Boundaries	}
	{------------------------------------------------------------------------}
PROCEDURE Update_Centroids;
VAR
	i	 	:	E_n_stress;
	field	:	E_mech;
BEGIN
	{ ----- Keep track of mean position of field on the plot ----- }
	FOR field := null TO rel_drag DO
		BEGIN
			spread[field]:= 0;
			centroid[field]:= 0;
		END;

	{	Note that the stress limits on the plot, LgSNfirst & LgSNlast are used EXPLICITLY	}
	WITH bndry_tabl[1] DO
		BEGIN
			spread[id_lo]:= stress_mn - LgSNfirst;
			centroid[id_lo]:= spread[id_lo]/2 + LgSNfirst;
		END;
	FOR i := 2 to n_bndrys DO
		WITH bndry_tabl[i] DO
			BEGIN
				spread[id_lo]:= stress_mn - bndry_tabl[i-1].stress_mn;
				centroid[id_lo]:= spread[id_lo]/2 + bndry_tabl[i-1].stress_mn;
			END;
	WITH bndry_tabl[n_bndrys] DO
		BEGIN
			spread[id_hi]:= LgSNlast - stress_mn;
			centroid[id_hi]:= spread[id_lo]/2 + stress_mn;
		END;

	FOR field := null TO rel_drag DO
		BEGIN
			weight := steps * (spread[field]/(LgSNlast-LgSNfirst));
			temp_position[field]		:= temp_position[field] +
				temp_step *
					weight;	{ temperatures }
			stress_position[field]	:= stress_position[field] +
				((centroid[field] - LgSNfirst)/(LgSNlast-LgSNfirst)) *
					weight*steps;	{ stresses	}
			pointcount[field]			:= pointcount[field] + weight;
		END;

END;	{	Update_Centroids	}
	{------------------------------------------------------------------------}
BEGIN	{	Fields_Loop	}
	n_actual := contournumber + 1;

	FOR k := 1 to C_num_bndrys DO
		WITH bndry_tabl[k] DO
			BEGIN
				id_lo := null;
				id_hi := null;
				stress_lo := SNfirst;
				stress_hi := SNlast;
				stress_mn := (stress_hi + stress_lo)/2.0;
			END;

{	The algorithm assumes that the field_ids[] array is IN ORDER with respect
	to its .stress values, but this is not necessarily true since one or more
	of the contours may be off the plot, in which case its .stress value will
	be above the top-of-plot [n_actual].stress value, or below the [0].stress
	value.
	The solution is to RE-SET these 'sentinel' values [0] and [n_actual] to be
	equal to the highest and lowest contour values IFF they are off the plot.
	This has to be carefully documented because THIS PARTICULAR ALGORITHM as
	used in the rest of this procedure does not need these sentinel values to
	be correctly set to the values at the limits of the plot, whereas the
	algorithm which searched for the contours in the first place DID RELY on
	this.  
	Remember, all the stresses are Lg(normalised) and so -ve, hence the 
	comparison operators are the 'wrong' way round. 24-May-1990 17:00 PMS	}

	IF (field_ids[0].stress >= field_ids[1].stress) THEN
		field_ids[0] := field_ids[1];								{	ALL values	}

	IF (field_ids[n_actual].stress <= field_ids[contournumber].stress) THEN
		field_ids[n_actual] := field_ids[contournumber];	{	ALL values	}

	{ ----- Find the Field boundaries from the field_ids list  ----- }
	i := 0;

	FOR c := 1 to contournumber+1 DO
		BEGIN
			IF (field_ids[c].id <> field_ids[c-1].id) THEN
				BEGIN
					Inc(i);
					WITH bndry_tabl[i] DO
						BEGIN
							id_lo := field_ids[c-1].id;
							id_hi := field_ids[c].id;
							stress_lo := field_ids[c-1].stress;
							stress_hi := field_ids[c].stress;
							stress_mn := (stress_hi + stress_lo)/2.0;
						END;
				END;
		END;
	IF (i > 0) THEN
		BEGIN
			n_bndrys := i;
			boundaries_exist := TRUE;
		END
	ELSE						{	no boundaries !	}
		BEGIN
			n_bndrys := 1;
			boundaries_exist := FALSE;
{$IFDEF debug}
			Writeln(db, 'No field boundaries at this temperature');
{$ENDIF}
			{	Exit;	}	{	Cowards' way out ! Must still check for vertical boundary	}
		END;

	IF boundaries_exist THEN
		BEGIN
			Find_Boundaries;

			{	Should really write a proc. to do this update when there are
				no boundaries too, but a single step off all over for only
				one (pretty big) field should make no big difference.  If the
				whole map is only one field then it won't be labelled at all
				I would guess...24-May-1990 18:05 PMS	}
			Update_Centroids;	
		END;

	{ ----- Find and Mark VERTICAL field boundaries on the plot  ----- }

	{	This algorithm is based on matching up two arrays of boundaries
		each with hi and lo fields and the stress (stress_mn) of the
		boundary; one for this temp. and one for the previous temp. step.
		We increment stress and check each time if the field is the same
		here as it was last temp. If it is not, AND if the previous field
		is NOT one there is a transition to at a lower stress at the
		current temp., then we make a mark.  The reason for that refinement
		is to prevent the vertical algorithm stomping all over some nice
		smooth but steep curves. 22-March-1990 23:46 PMS	}

	{	The algorithm assumes that there is at least one boundary, since we
		removed the Exit statement, this may no longer be true, so we insert
		an sentinel value to catch this special case. 24-May-1990 17:12 PMS	}
	IF NOT boundaries_exist THEN
		BEGIN
			bndry_tabl[1].stress_mn := LgSNfirst;
			bndry_tabl[1].id_hi := field_ids[0].id;
			bndry_tabl[1].id_lo := field_ids[0].id;
			n_bndrys := 1;
		END;

	IF (TN <= 0) THEN
		x_last := 0
	ELSE
		BEGIN
			x_half := round((x_last + x_now)/2);
			i := 1;
			j := 1;
			FOR s := 1 TO steps*2 DO	{	2 * finer mesh	}
				BEGIN
					LgSN := LgSNfirst + 0.5*LgSNstep*(s - 0.5);
					y_half := round(ylength*(1 - (LgSN - LgSNfirst)/
								(LgSNlast - LgSNfirst)));
{$IFDEF detail}
					Write(db,s:3,' ',LgSN:8:3,' ');
					write(db,' ',i:3,j:3,' ');
{$ENDIF}
				{	stress starts low, almost certainly below the first boundary	}
					WHILE (LgSN > bndry_tabl[i].stress_mn) DO
						Inc(i);
					IF (i > n_bndrys) THEN	{	popped off the top	}
						BEGIN
							i := n_bndrys;
							field_now := bndry_tabl[i].id_hi;
							next_down_now := bndry_tabl[i].id_lo;
							next_up_now := field_now;
						END
					ELSE
						BEGIN
							field_now := bndry_tabl[i].id_lo;
							next_up_now := bndry_tabl[i].id_hi;
							IF (i > 1) THEN
								next_down_now := bndry_tabl[i-1].id_lo
							ELSE
								next_down_now := field_now;
						END;
{$IFDEF detail}
					write(db,' ');
					WRITE_FIELDNAME(field_now);
					WRITE_FIELDNAME(next_down_now);
					write(db,i:3);
{$ENDIF}

					WHILE (LgSN > last_bndry_tabl[j].stress_mn) DO
						Inc(j);
					IF (j > last_n_bndrys) THEN	{	popped off the top	}
						BEGIN
							j := last_n_bndrys;
							field_last := last_bndry_tabl[j].id_hi
						END
					ELSE
						field_last := last_bndry_tabl[j].id_lo;
{$IFDEF detail}
					write(db,' ');
					WRITE_FIELDNAME(field_last);
					write(db,j:3);
{$ENDIF}

					IF ( field_now	<> field_last)
					AND (next_down_now <> field_last)
					AND (next_up_now <> field_last) THEN
						{	try to NOT draw on genly sloping boundaries	}
						BEGIN
							DRAW_FIELD_BOUNDARY (x_half,y_half);
{$IFDEF detail}
							write(db,' **');
{$ENDIF}
						END;
{$IFDEF detail}
					writeln(db);
{$ENDIF}
				END;
	END;
	{ ----- Copy the table of boundary points to be used next time  ----- }

	x_last := x_now;
	last_n_bndrys := n_bndrys;
	FOR i := 1 to n_bndrys DO
		last_bndry_tabl[i] :=bndry_tabl[i];

END;	{	Fields_Loop	procedure }
{---------------------------------------------------------------------------}

