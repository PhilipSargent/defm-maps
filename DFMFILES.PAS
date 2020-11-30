Unit dfmfiles;
{ PMS 30-November-2020 17:18:20 }
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
{$R+}	{Range checking on}
{$B+}	{Boolean complete evaluation on}
{$S+}	{Stack checking on}
{$I+}	{I/O checking on}

Interface

Uses
	DfmGlbls;

FUNCTION ALREADY_EXISTS (name: T_matl_name): BOOLEAN;
{	This function returns TRUE if it is given a name which is
	already in the matl_list array, FALSE otherwise.	}

PROCEDURE LIST_MATERIALS;
{ This lists the available list of materials  }

PROCEDURE CHECK_MATLNAME;

PROCEDURE READ_MATL_DATA;
{ -------- Read in the chosen materials parameters into the stash -------- }

PROCEDURE INTERPRET_PARAMETER_SET;
{ -------- Interpret in the chosen  parameter set -------- }
PROCEDURE INTERPRET_VARIABLE_SET;
{ -------- Interpret in the chosen variable set -------- }

PROCEDURE SAVE_MATL_PARAMETERS;
PROCEDURE SAVE_MATL_VARIABLES;
PROCEDURE SAVE_MATL_REFERENCES;

PROCEDURE CHECK_PARAMETERS (Screen: BOOLEAN);
{ -------- Checks input data against limits -------- }
PROCEDURE INPUT_DATA_TO_FILE;

PROCEDURE DUD_TEMP_TO_DEBUG (dud_steps: INTEGER; dud_TN, dud_K: a_real);
PROCEDURE DUD_TEMP_TO_FILE (dud_steps: INTEGER; dud_TN, dud_K: a_real);
{===================================================================}

Implementation

Uses
	Crt,
	Dos,
	Printer,
	stringIO,
	DfmEdits;

VAR
	file_in	:	Text;
	file_out	:	Text;
	tempfile	:	String;
	bakfile	:	String;

TYPE
	a_real	=	double; {DUPLICATED because fpc has declaration conflict issue}

{-------------------------------------------------------------------}
FUNCTION ALREADY_EXISTS (name: T_matl_name): BOOLEAN;
{	This function returns TRUE if it is given a name which is
	already in the matl_list array, FALSE otherwise.	}
VAR
	i	:	1..list_max;
	b	:	BOOLEAN;
BEGIN
	b := FALSE;
	FOR i := 1 TO matl_index DO
		IF (name = matl_list [i]) THEN
			b := TRUE;
	already_exists := b;
END;	 {	ALREADY_EXISTS	}
{-------------------------------------------------------------------}
PROCEDURE Pad (VAR s: String; n: Byte);
{	Procedure to pad a string out to a given length with spaces	}
VAR
	i, len:	Byte;
BEGIN
	len := Length(s);
	IF (len < n ) THEN
		FOR i := len+1 TO n DO
			s := s + ' ';
END;	{	Pad	}
{-------------------------------------------------------------------}
PROCEDURE LIST_MATERIALS;
VAR
	i	:	1..list_max;
BEGIN
	CLEAN_WINDOW;
	gotoXY(1,2);

	WriteLn('           THE  DATA FILE  CURRENTLY  CONTAINS:              ');
	gotoXY(1,6);

	IF matl_ok THEN
		FOR i := 1 TO matl_index DO
			WRITE(matl_list[i]:20)
	ELSE
		BEGIN		{	Scan the data file	}
			gotoXY(1,24); textbackground(C_back); textcolor(C_bright);
			WRITE('                                                             ');
			gotoXY(1,24);  WRITE('                 SCANNING  THE   DATA         ');
			textcolor(C_text);
			gotoXY(1,6);
			SCAN_DATA_FILE (TRUE);	{	Scan & write out names	}
		END;


	gotoXY(1,24); textbackground(C_back); textcolor(C_bright);
	WRITE('                                                             ');
	textcolor(C_text);

END;	{	LIST_MATERIALS	}
{-------------------------------------------------------------------}
PROCEDURE BEGIN_FILE_SAVE (main_datafile:String);
BEGIN
	gotoXY(1,24); textbackground(C_back); textcolor(C_bright);
	WRITE('                                                             ');
	gotoXY(1,24);  WRITE('               SAVING  THE  DATA  TO  DISC');
	textcolor(C_text);

{	Set the temporary main_datafile by replacing the extension by .TMP	}
	tempfile	:= main_datafile;
	delete(tempfile,pos('.',tempfile),4);
	bakfile	:= tempfile+'.BAK';
	tempfile := tempfile+'.TMP';

	IF FileNotThere(main_datafile) THEN
		BEGIN
			WRITELN('ERROR: Cannot open an Input File:');
			Writeln('Cannot open file "',main_datafile,'"');
			Finish(4);
		END;
	Assign (file_in,main_datafile);
	Reset (file_in);

	IF CannotOpen(tempfile) THEN
		BEGIN
			WRITELN('ERROR: Cannot open a Temporary File:');
			Writeln('Cannot open file "',tempfile,'"');
			Finish(4);
		END;
	Assign (file_out, tempfile);
	Rewrite (file_out);
	Reset (file_out);


END;	{	BEGIN_FILE_SAVE	}
{-------------------------------------------------------------------}
PROCEDURE END_FILE_SAVE  (main_datafile:String);
BEGIN
{	Now, playing safe, we erase any backup file, rename the .DAT file
	as a backup .BAK file, and rename the .TMP file as the .DAT file	}

	IF NOT FileNotThere (bakfile) THEN
		BEGIN
			Assign (file_out, bakfile);
			Erase (file_out);
		END;

	IF NOT FileNotThere (main_datafile) THEN
		BEGIN
			Assign (file_out, main_datafile);
			Rename (file_out, bakfile);
		END;

{	And finally rename the temporary file as the ref file	}

	IF FileNotThere (tempfile) THEN
		BEGIN
			WRITELN('ERROR: Cannot open a Temporary Input File');
			Writeln('Something very odd, we just created "',tempfile,
				'" and now it cannot be found');
			Finish(4);
		END
	ELSE
		BEGIN
			Assign (file_out, tempfile);
			Rename (file_out, main_datafile);
		END;
END;	{	END_FILE_SAVE	}
{-------------------------------------------------------------------}
PROCEDURE SAVE_MATL_PARAMETERS;
VAR
	tempfile	:	String;
	bakfile	:	String;
	line, buf:	String;
	material	:	String;
	pad_m		:	String;
	pad_id	:	String;
	parid		:	String;
	number	:	Integer;
BEGIN
	BEGIN_FILE_SAVE(parfilename);

{	What we do here is to copy ALL the data which is either for
	materials not currently under consideration, OR for parameters
	which may be in the datafile but which this program does not
	concern itself.	We copy it to the temporary file.	}

	REPEAT
		READLN(file_in, buf);
		line := buf;
		material := get_next_token(line);
		UpperCase(material);

		IF (material = matlname) THEN
		{	OK, found one. Now check if it is a parameter we know about..	}
			BEGIN
				parid  := get_next_token(line);
				NUMBER_FOR_PARAMETER (number,parid);
				IF (number < 0) THEN

				{	No, it's not one of ours, so we copy it.	}
					WRITELN(file_out, buf);
			END
		ELSE
		{	Another material, copy it.	}
			WRITELN(file_out, buf);
	UNTIL Eof(file_in);
	Close(file_in);
	Close(file_out);

{	Now we Append the data for our material to the end of the tempfile.
	Note that we DO save ALL the fields, even if they have default values.
	This is because default values depend on other data and we could lose
	track.	}

	Append(file_out);
	pad_m := matlname;
	Pad(pad_m,matl_name_length);
	FOR parnumber:= 0 TO numberofparameters DO
		BEGIN
			LABELS_FOR_PARAMETERS;
			pad_id := id;
			Pad (pad_id,parm_name_length);
			IF (id <> '') THEN
				WRITELN(file_out, pad_m, ' ', pad_id, ' ', par[parnumber]);
		END;
	Close (file_out);

	END_FILE_SAVE(parfilename);

END;	{	SAVE_MATL_PARAMETERS	}
{-------------------------------------------------------------------}
PROCEDURE SAVE_MATL_VARIABLES;
VAR
	tempfile	:	String;
	bakfile	:	String;
	line, buf:	String;
	material	:	String;
	pad_m		:	String;
	pad_id	:	String;
	parid		:	String;
	number	:	Integer;
	L, m, h	:	a_real;
BEGIN
	BEGIN_FILE_SAVE(parfilename);

{	What we do here is to copy ALL the data which is either for
	materials not currently under consideration, OR for variables
	which may be in the datafile but which this program does not
	concern itself.	We copy it to the temporary file.	}

	REPEAT
		READLN(file_in, buf);
		line := buf;
		material := get_next_token(line);
		UpperCase(material);

		IF (material = matlname) THEN
		{	OK, found one. Now check if it is a parameter we know about..	}
			BEGIN
				parid  := get_next_token(line);
				NUMBER_FOR_VARIABLE (number,parid);
				IF (number < 0) THEN

				{	No, it's not one of ours, so we copy it.	}
					WRITELN(file_out, buf);
			END
		ELSE
		{	Another material, copy it.	}
			WRITELN(file_out, buf);
	UNTIL Eof(file_in);
	Close(file_in);
	Close(file_out);

{	Now we Append the data for our material to the end of the tempfile.
	Note that we don't save dummy fields (where id=''), NOR do we save
	fields whose values are the same as the defaults.	}

	Append(file_out);
	pad_m := matlname;
	Pad(pad_m,matl_name_length);
	FOR vblnumber:= 1 TO numberofvariables DO
		BEGIN
			LABELS_FOR_VARIABLES;
			pad_id := id;
			Pad (pad_id,parm_name_length);
			SET_VARIABLES (vblnumber, L,m,h);
			IF (id <> '') AND (vbl[vblnumber] <> m) THEN
				WRITELN(file_out, pad_m, ' ', pad_id, ' ', vbl[vblnumber]);
		END;
	Close (file_out);

	END_FILE_SAVE(parfilename);

END;	{	SAVE_MATL_VARIABLES	}
{-------------------------------------------------------------------}
PROCEDURE SAVE_MATL_REFERENCES;
VAR
	line, buf:	String;
	material	:	String;
	s			:	String[refchars];
	i,index	:	R_refs;
	lines		:	R_lines;
BEGIN
	Writeln(db,Esc,matlname);
	FOR lines := 0 TO ref_written DO
		BEGIN
			s[0] := Chr(refchars);
			FOR i:= 1 TO refchars DO
				s[i] := ref[lines*refchars+i];
			{	set length just to be sure	}
			IF (Length(s) > 0) THEN
				Writeln(db,s);
		END;
	Writeln(db,Esc);

	BEGIN_FILE_SAVE(reffilename);

{	What we do here is to copy ALL the text which is either for
	materials not currently under consideration,
	We copy it to the temporary file.	}

	REPEAT
		READLN(file_in, buf);
		line := Copy(buf,2,matl_name_length);
		material := get_next_token(line);
      UpperCase(material);
		IF NOT ((buf[1] = Esc) AND (material = matlname)) THEN
		{	No, it's not one of ours, so we copy it.	}
			WRITELN(file_out, buf);
	UNTIL Eof(file_in) OR ((buf[1] = Esc) AND (material = matlname));

	IF NOT Eof(file_in) THEN
		BEGIN		{	skip the old ref., and copy rest of input file to output	}
			REPEAT
				READLN(file_in, buf);
			UNTIL Eof(file_in) OR (buf[1] = Esc);
		{	Shouldn't see Eof, only if error condition,
			unless we are on last ref.	}
			IF NOT Eof(file_in) THEN
				{	Copy the rest of the file to output	}
				REPEAT
					READLN(file_in, buf);
					WRITELN(file_out, buf);
				UNTIL Eof(file_in);
		END;
	Close(file_in);

{ -----	Whether the ref. was in the old file or not, we append it	}
	Writeln(file_out,Esc,matlname);

{	Write out ref.	}
	FOR lines := 0 TO ref_written DO
		BEGIN
			s[0] := Chr(refchars);
			FOR i:= 1 TO refchars DO
				s[i] := ref[lines*refchars+i];
			IF (Length(s) > 0) THEN
				Writeln(file_out,s);
		END;
	Writeln(file_out,Esc);
	Close (file_out);

	END_FILE_SAVE(reffilename);

END;	{	SAVE_MATL_REFERENCES	}
{-------------------------------------------------------------------}
PROCEDURE STASH_DATA_LINE (line: String);
{	This routine uses a global array, declared in DFMglbls, to store
	the lines of data.	}
BEGIN
	stash_index := stash_index + 1;
	IF (stash_index <= stash_max ) THEN
		IF (Length(line) > stash_width) THEN
			stash [stash_index] := Copy(line, 1, stash_width)
		ELSE
			stash [stash_index] := Copy(line, 1, Length(line))
	ELSE
		BEGIN
			GotoXY(1,24);
			WRITE('Stash full at ',stash_max,
			'. Too many data items for this material.');
		END;
END;	{	STASH_DATA_LINE	}
{-------------------------------------------------------------------}
PROCEDURE CHECK_MATLNAME;
VAR
	i	:	Word;
	found	:	BOOLEAN;
BEGIN
	found := FALSE;
	SCAN_DATA_FILE(FALSE);
	FOR i := 1 TO matl_index DO
		IF (matlname = matl_list[i]) THEN
			found := TRUE;
	IF NOT found THEN
		modenamed := FALSE;
END;	{	CHECK_MATLNAME	}
{-------------------------------------------------------------------}
PROCEDURE READ_MATL_DATA;

{ -------- Read in the chosen material parameters and variables -------- }
VAR
	file_in	:	Text;
	file_ref	:	Text;
	line, buf:	String;
	material	:	String;
	refname	:	String;
	index		:	R_refs;

	{----------------------------------------------------------------}
PROCEDURE pad_ref_line;
VAR
	i,j,k		:	R_refs;
	len		:	Word;
BEGIN
	len :=Length(buf);
	k := index;
	FOR i := 1 TO refchars DO	{	blank out line	}
  		BEGIN
	 		ref[k] := ' ';
	 		Inc(k);
	 	END;
	j := index;
	IF (len>0) THEN	{	overwrite with text if present	}
		BEGIN
			FOR i := 1 TO len DO
				BEGIN
					ref[j] := buf[i];
					Inc(j);
				END;
		END;
	index := index + refchars;	{	re-set index to current length	}
END;	{	pad_ref_line	}
	{----------------------------------------------------------------}
BEGIN
	gotoXY(1,24); textbackground(C_back); textcolor(C_bright);
	WRITE('                                                             ');
	gotoXY(1,24);  WRITE('                   READING  THE  DATA         ');
	textcolor(C_text);

	IF FileNotThere (parfilename) THEN
		BEGIN
			gotoXY(1,24); textbackground(C_back); textcolor(C_warn);
			WRITE('                                                             ');
			gotoXY(1,24);  WRITE('      NO DATA FILE FOUND !! (matlpars.dat)    ');
			REPEAT UNTIL KeyPressed;
			answer:=Readkey;
			textcolor(C_text);
		END
	ELSE
		BEGIN
			Assign(file_in, parfilename);
			Reset(file_in);

		{	Read through the data file looking for lines relevant to this material	}
			REPEAT
				READLN(file_in, buf);
				line := buf;
				material := get_next_token(line);
				IF (material = matlname) THEN

				{	OK, found one. Now don't bother to look at it, just stash it.	}
					STASH_DATA_LINE (line);

			UNTIL Eof(file_in);
			Close(file_in);
		END;

{ ----- Read reference text -----}

	FOR index := 1 to ref_buflength DO
		ref[index] := ' ';
	IF FileNotThere (reffilename) THEN
		BEGIN
			gotoXY(1,24); textbackground(C_back); textcolor(C_warn);
			WRITE('                                                             ');
			gotoXY(1,24);  WRITE('      NO DATA FILE FOUND !! (matlrefs.dat)    ');
			textcolor(C_text);
			REPEAT UNTIL KeyPressed;
			answer:=Readkey;
		END
	ELSE
		BEGIN
			Assign(file_ref, reffilename);
			Reset(file_ref);
			REPEAT
				READLN(file_ref, buf);
				line := Copy(buf,2,matl_name_length);
				material := get_next_token(line);
            UpperCase(material);
			UNTIL Eof(file_ref) OR ((buf[1] = Esc) AND (material = matlname));
			IF Eof(file_ref) THEN
				BEGIN
					FillChar(ref,SizeOf(ref),' ');
				END
			ELSE
				BEGIN
               buf:=' ';
					index := 1;
					ref_written := 0;
					WHILE NOT ((Eof(file_ref))
					OR (buf[1] = Esc)
					OR (index >= ref_buflength)) DO
						BEGIN
							{	find how many non-blank lines there are	}
							Inc(ref_written);
							READLN(file_ref, buf);
							IF (index + refchars <= ref_buflength)
							AND (buf[1] <> Esc) THEN
								pad_ref_line;
						END;
					Dec(ref_written);
				END;
			Close(file_ref);
		END;

END;  {READ_MATL_DATA.    }
{-------------------------------------------------------------------}
PROCEDURE INTERPRET_PARAMETER_SET;
{	The reason for separating the reading of the data from the file,
	and the allocation of each parameter or variable to its proper place,
	is that the file reading is very quick compared to the time
	required for interpretation.	}
VAR
	parid		:	String;
	value		:	String;
	line		:	String;
	code		:	Integer;
	number	:	Integer;
	L,m,h,r	:	a_real;
	check		:	ARRAY [R_pars] OF BOOLEAN;
	i			:	1..stash_max;
BEGIN
	FOR parnumber := 0 TO numberofparameters DO
		check[parnumber] := FALSE;
{	This assumes the stash is not empty, i.e. that there was at least one
	material parameter or variable in it	}
	IF (stash_index < 1) THEN
		Finish(7);
	FOR i := 1 TO stash_index DO
			BEGIN
		{	Read a line, check if it is a parameter we know about..	}
				line := stash[i];
				parid  := get_next_token(line);
				NUMBER_FOR_PARAMETER (number,parid);
				IF ((number >= 0) AND (number <= numberofparameters)) THEN

				{	Yes, it's a known parameter. Is the value readable ?	}
					BEGIN
						value:=get_next_token(line);
						Val (value, r, code);
						IF (code = 0) THEN

						{	Yes. Read the value into the array of parameters	}
							BEGIN
								par[number] :=r;
								check[number]:=TRUE;
							END;
					END;
			END;	{	now looked through the stash completely	}
	imc := GET_IMC(par[0]);

{	If we have some parameters without values, then take defaults.	}
	FOR parnumber:= 1 TO numberofparameters DO
		IF NOT check[parnumber] THEN
			BEGIN
				SET_PARAMETERS (parnumber, L,m,h);
				par[parnumber] := m;
			END;

{ ------- Display the file for inspection and editing ------- }

	IF NOT modefast THEN
		BEGIN
			EDIT_PARAMETERS;
		END;

END;  {INTERPRET_PARAMETER_SET.    }
{-------------------------------------------------------------------}
PROCEDURE INTERPRET_VARIABLE_SET;
{	The reason for separating the reading of the data from the file,
	and the allocation of each parameter or variable to its proper place,
	is that the file reading is very quick compared to the time
	required for interpretation.	}
VAR
	vblid		:	String;
	value		:	String;
	line		:	String;
	code		:	Integer;
	number	:	Integer;
	L,m,h,r	:	a_real;
	check		:	ARRAY [R_vbls] OF BOOLEAN;
	i			:	1..stash_max;
BEGIN
	FOR vblnumber := 1 TO numberofvariables DO
		check[vblnumber] := FALSE;

	FOR i := 1 TO stash_index DO
			BEGIN
		{	Read a line, check if it is a variable we know about..	}
				line := stash[i];
				vblid  := get_next_token(line);
				NUMBER_FOR_VARIABLE (number,vblid);
				IF ((number > 0) AND (number <= numberofvariables)) THEN

				{	Yes, it's a known variable. Is the value readable ?	}
					BEGIN
						value:=get_next_token(line);
						Val (value, r, code);
						IF (code = 0) THEN

						{	Yes. Read the value into the array of variables	}
							BEGIN
								vbl[number] :=r;
								check[number]:=TRUE;
							END;
					END;
			END;	{	now looked through the stash completely	}

{	If we have some variables without values, then take defaults.	}
	FOR vblnumber:= 1 TO numberofvariables DO
		IF NOT check[vblnumber] THEN
			BEGIN
				SET_VARIABLES (vblnumber, L,m,h);
				vbl[vblnumber] := m;
			END;

{ ------- Display the file for inspection and editing ------- }

	IF NOT modefast THEN
		BEGIN
			LIMIT_VARIABLES;
			EDIT_VARIABLES;
		END;

END;  {INTERPRET_VARIABLE_SET.    }
{-------------------------------------------------------------------}
PROCEDURE CHECK_PARAMETERS (Screen: BOOLEAN);

{ -------- Checks input data against limits -------- }
VAR
	lf	:	Text;
	s, s_lo, s_hi	:	STRING;
	r, r_lo, r_hi	:	REAL;
	response			:	CHAR;
	L1, L2, L3		:	a_real;

BEGIN

	IF Screen THEN
		BEGIN
			CLEAN_WINDOW;

			textbackground(C_back);
			gotoXY(1,2);
			write  ('                                                             ');
			gotoXY(1,2);
			write(' ',Version,'     CHECK  ON  INPUT DATA  FOR   ');
			textcolor(C_bright);
			write(matlname);

			gotoXY(1,24);
			write ('                                                             ');
			gotoXY(1,24);
			write ('                PRESS SPACE BAR TO CONTINUE                  ');

			Window(10,5,70,22);
			gotoXY(1,1);
		END;	{	Screen block	}

	for parnumber := 0 to numberofparameters do
		BEGIN
			LABELS_FOR_PARAMETERS;
			SET_PARAMETERS (parnumber, L1,L2,L3);
			r := par[parnumber];	{	in case a_real is DOUBLE	}
			convert_number (r, s, -1);
			r_lo := L1;
			r_hi := L3;
			convert_number (r_lo, s_lo, -1);
			convert_number (r_hi, s_hi, -1);

			if (par[parnumber] < L1) or (par[parnumber] > L3) then BEGIN
				modeconcern:=TRUE; { only sets flag for exit error (warning) code }
				IF Screen THEN
					BEGIN
						writeln ('    ',d,'  outside expected range');
						writeln('       ',d,'=  ',s,'  ',u);
						writeln('       Anticipated  Range          =',s_lo,'  ',u);
						writeln('                                 to ',s_hi,'  ',u);
						writeln;
						IF (NOT modefast) THEN
							BEGIN
								REPEAT UNTIL KeyPressed;
								response:=Readkey;
							END;
					END
				ELSE	{	NOT Screen	}
					BEGIN
						IF modelistfile THEN
							BEGIN
								Assign(lf,listfilename);
								Append(lf);
								writeln(lf,'       PARAMETER',parnumber:3,' OUTSIDE EXPECTED RANGE.');
								writeln(lf,'       ',d,'=  ',s,'  ',u);
								writeln(lf,'       Anticipated  Range          =',s_lo,' to ',s_hi,'  ',u);
								writeln(lf);
								Close(lf);
							END;
					END;	{	NOT Screen block	}
			END;
		END;

	LIMIT_VARIABLES;

	for vblnumber := 1 to numberofvariables do
		BEGIN

			LABELS_FOR_VARIABLES;
			SET_VARIABLES (vblnumber, L1,L2,L3);
			r := vbl[vblnumber];	{	in case a_real is DOUBLE	}
			convert_number (r, s, -1);
			r_lo := L1;
			r_hi := L3;
			convert_number (r_lo, s_lo, -1);
			convert_number (r_hi, s_hi, -1);

			if (vbl[vblnumber] < L1) or (vbl[vblnumber] > L3) then
				BEGIN
					IF Screen THEN
						BEGIN
							writeln ('   ',d,'  outside expected range     ');
							writeln('       ',d,'=  ',s,'  ',u);
							writeln('       Anticipated  Range          =  ',s_lo,'  ',u);
							writeln('                                 to ',s_hi,'  ',u);
							IF (NOT modefast) THEN
								BEGIN
									REPEAT UNTIL KeyPressed;
									response:=Readkey;
								END;
						END
					ELSE	{	NOT Screen	}
						BEGIN
							IF modelistfile THEN
								BEGIN
									Assign(lf,listfilename);
									Append(lf);
									writeln(lf,'       VARIABLE ',vblnumber:3,' OUTSIDE EXPECTED RANGE.');
									writeln(lf,'       ',d,'=  ',s,'  ',u);
									writeln(lf,'       Anticipated  Range          =  ',s_lo,' to ',s_hi,'  ',u);
									writeln(lf);
									Close(lf);
								END;
						END;	{	end NOT Screen block	}
				END;	{	out of range block	}
		END;	{	for vblnumber := 1 to numberofvariables do	}


	IF Screen THEN
		BEGIN
			textcolor(C_text);  writeln;
			write ('     ------------  DATA  CHECK  COMPLETE  ------------');
			writeln;

			Window(10,1,70,25);
		END;	{	Screen block	}

END;  {CHECK_PARAMETERS.     }

{-------------------------------------------------------------------}
PROCEDURE INPUT_DATA_TO_FILE;

VAR
	lf	:	Text;
	s	:	STRING;
	r	:	REAL;
	buf		:	String[refchars];
	index		:	R_refs;
	i, j, line	:	WORD;
	lines	:	R_lines;

BEGIN

	DATE_AND_TIME;
	Assign(lf,listfilename);
	Rewrite(lf);

	Writeln(lf,'      ',Version,' v',Release,' (',VersionDate,')');
	Writeln(lf,'      (Compiler options:',compiler_opts,')');
	Writeln(lf,'      ',copyright);
	writeln(lf,'      ',weekday,' ',Date_string,' ',time_string);
	writeln(lf);
	writeln(lf,'      =============================================================');
	writeln(lf,'      ',Version,'     INPUT  PARAMETERS for  ',matlname);
	writeln(lf,'      =============================================================');
	writeln(lf);

	get_imc_string (imc,s);
	writeln (lf,
		'          0  Isomechanical Class                  ',s);

	for parnumber := 1 to numberofparameters do
		BEGIN
			r := par[parnumber];	{	in case a_real is DOUBLE	}
			convert_number (r, s, -1);
			LABELS_FOR_PARAMETERS;

			writeln (lf,'        ',parnumber:3,'  ', d, u,' =  ', s);
		END;
	writeln(lf);
	writeln(lf,'      =============================================================');
	writeln(lf);  writeln(lf);  writeln(lf);  writeln(lf);

	writeln(lf,'      =============================================================');
	writeln(lf,'      ',Version,'     INPUT  VARIABLES for  ',matlname);
	writeln(lf,'      =============================================================');
	writeln(lf);
	for vblnumber := 1 to numberofvariables do
		BEGIN
			r := vbl[vblnumber];	{	in case a_real is DOUBLE	}
			convert_number (r, s, -1);
			LABELS_FOR_VARIABLES;

			writeln (lf,'        ',vblnumber:3,'  ', d, u,' =  ',s);
		END;

	writeln(lf);
	writeln(lf,'      =============================================================');
	writeln(lf);  writeln(lf);  writeln(lf);  writeln(lf);

{ ------- Print out Reference Text, complex word-wrap, sorry ------- }

	writeln(lf,'      ',Version,'  REFERENCE DESCRIPTION FOR ',matlname);
	writeln(lf,'      =============================================================');
	writeln(lf);

	FOR lines := 0 TO ref_written DO
		BEGIN
			buf[0] := Chr(refchars);
			FOR i:= 1 TO refchars DO
				buf[i] := ref[lines*refchars+i];
			IF (Length(buf) > 0) THEN
				Writeln(lf,'      ',buf);
		END;
	writeln(lf,'      =============================================================');
	Close(lf);

END; {INPUT_DATA_TO_FILE.    }
{---------------------------------------------------------------------------}
PROCEDURE DUD_TEMP_TO_DEBUG (dud_steps: INTEGER;
									dud_TN, dud_K: a_real);
BEGIN
	writeln(db);
	writeln(db,' ========================================');
	writeln(db,' LOW TEMPERATURE CUTTOFF for  ',matlname);
	writeln(db);
	writeln(db,' Due to floating-point inaccuracies,',
				'the diffusion rates');
	writeln(db,' can only be calculated properly above ',
				dud_TN:6:3,' Tm');
	writeln(db,' i.e., above ',
				dud_K:6:0,' degrees K.');
	writeln(db,' Number of bad temperature steps is: ',dud_steps);
END;	{	DUD_TEMP_TO_DEBUG	}

{---------------------------------------------------------------------------}
PROCEDURE DUD_TEMP_TO_FILE (dud_steps: INTEGER;
									dud_TN, dud_K: a_real);
VAR
	lf	:	Text;

BEGIN
	Assign(lf,listfilename);
	Append(lf);
	writeln(lf);
	writeln(lf,'      ========================================');
	writeln(lf,'      LOW TEMPERATURE CUTTOFF for  ',matlname);
	writeln(lf,'      ========================================');
	writeln(lf);
	writeln(lf,'      Due to floating-point inaccuracies,',
				'the diffusion rates');
	writeln(lf,'      can only be calculated properly above ',
				dud_TN:6:3,' Tm');
	writeln(lf,'      i.e., above ',
				dud_K:6:0,' degrees K.');
	writeln(lf);
	Close(lf);
END;	{	DUD_TEMP_TO_FILE	}
{-------------------------------------------------------------------}
End.	{	Unit Dfmfiles	}
