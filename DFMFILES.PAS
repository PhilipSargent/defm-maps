Unit dfmfiles;
{ PMS 26-March-1990 18:11 }

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   P.M.Sargent and M.F.Ashby        **************
   *************   January 1990                     **************
}
{$IFDEF  contour}		{	ensure compiler directives are consistent	}
{$DEFINE  detail}
{$ENDIF}
{$IFDEF  detail}
{$DEFINE  debug}
{$ENDIF}
{.$R+}    {Range checking on}
{.$B+}    {Boolean complete evaluation on}
{.$S+}    {Stack checking on}
{.$I+}    {I/O checking on}
{.$N+}    {Use numeric coprocessor}
{.$E+}		{Include copy of 8087 Emulator - default anyway}

Interface

Uses
	DfmGlbls;

FUNCTION ALREADY_EXISTS (name: T_matl_name): BOOLEAN;
{	This function returns TRUE if it is given a name which is
	already in the matl_list array, FALSE otherwise.	}

PROCEDURE LIST_MATERIALS;

{ This lists the available list of materials  }

PROCEDURE MAKE_PARAMETER_SET;
PROCEDURE MAKE_VARIABLE_SET;

PROCEDURE MAKE_REFERENCE_SET;
{ -- Creates a new set of reference info. -- }

PROCEDURE CHECK_MATLNAME;

PROCEDURE READ_MATL_DATA;

{ -------- Read in the chosen materials parameters into the stash -------- }

PROCEDURE EDIT_PARAMETERS;
PROCEDURE LIMIT_VARIABLES;
PROCEDURE EDIT_VARIABLES;

PROCEDURE EDIT_REFERENCES;

PROCEDURE INTERPRET_PARAMETER_SET;

{ -------- Interpret in the chosen  parameter set -------- }

PROCEDURE INTERPRET_VARIABLE_SET;

{ -------- Interpret in the chosen variable set -------- }

PROCEDURE SAVE_MATL_PARAMETERS;

PROCEDURE SAVE_MATL_VARIABLES;

PROCEDURE SAVE_MATL_REFERENCES;

PROCEDURE CHECK_PARAMETERS (Screen: BOOLEAN);

{ -------- Checks input data against limits -------- }

PROCEDURE INPUT_DATA_TO_PRINTER;
PROCEDURE OPEN_PRINTER (hrdcopy: CHAR);
PROCEDURE CLOSE_PRINTER (hrdcopy: CHAR);

PROCEDURE INPUT_DATA_TO_FILE;

{$IFDEF debug}
PROCEDURE DUD_TEMP_TO_DEBUG (dud_steps: INTEGER; dud_TN, dud_K: a_real);
{$ENDIF}

PROCEDURE DUD_TEMP_TO_PRINTER (dud_steps: INTEGER; dud_TN, dud_K: a_real);
PROCEDURE DUD_TEMP_TO_FILE (dud_steps: INTEGER; dud_TN, dud_K: a_real);
{===================================================================}

Implementation

Uses
	Crt,
	Dos,
	Printer,
	stringIO;

CONST
	last_page1_parameter = 16;
TYPE
	T_page	=	(First, Second);

VAR
	escape		:	BOOLEAN;
	reflength	:	R_refs;
	file_in	:	Text;
	file_out	:	Text;
	tempfile	:	String;
	bakfile	:	String;

{-------------------------------------------------------------------}
PROCEDURE SET_PARAMETERS (n: R_pars; VAR L,m,h: a_real);
VAR
	Q, guess	:	a_real;
	s	:	String;
	{----------------------------------------------------------------}
FUNCTION dDbdry: a_real;
BEGIN
	{	If the atomic volume is unset, then set it (recursive call)	}
	IF ( par[18] <= 0 ) THEN
		SET_PARAMETERS (18, L, par[18], h);

	{	cube-root of the atomic volume, times Dv0	}
	dDbdry := exp(ln(par[18])/3)*par[8];
END;	{	dDbdry	}
	{----------------------------------------------------------------}
BEGIN	{	SET_PARAMETERS	}
{	Default Set	}
	CASE n of
	0 : BEGIN	L := 1;				m := 14;				h := 59		END;
	1 : BEGIN	L := 500;			m := 1500;			h := 4000	END;
	2 : BEGIN	L := 0.06;			m := 0.5;			h := 0.95	END;
	3 : BEGIN	L := par[1]/100;	m := par[1]/30;	h := par[1]/10		END;
	4 : BEGIN	L := 1.0e-4;		m := 8.0e-3;		h := 0.1		END;
	5 : BEGIN	L := 1.0e-4;		m := 1.0e-3;		h := 0.1		END;
	6 : BEGIN	L := 0.001;			m := 0.1;		  	h := 0.2		END;
	7 : BEGIN	L := 0.2;			m := 0.5;			h := 1.0		END;
	8 : BEGIN	L := 1.0E-10;		m := 1.0e-4;		h := 1.0		END;
	9 : BEGIN Q := R*par[1]/1000;
					L := 8*Q;        	m := 18*Q;			h := 40*Q 	END;
	10 : BEGIN	L := 1.0E-17;		m := dDbdry;		h := 1.0E-8	END;
	11 : BEGIN	L := 0.38*par[9];	m := 0.6*par[9];	h := par[9]	END;
	12 : BEGIN	L := 1.0E-26;		m := 1.0e-23;		h := 1.0E-20	END;
	13 : BEGIN	L := 0.38*par[9];	m := par[11];		h := par[9]	END;
	14 : BEGIN	L := 3.0;			m := 3.0;			h := 15.0		END;
	15 : BEGIN guess := 1000*par[3]*par[5];
					L := guess/8;		m := guess/2;		h := guess*5	END;
	16 : BEGIN	L := 0.6*par[9];	m := par[9];		h := 2*par[9]	END;
	17 : BEGIN	L := 2.0e-10;		m := 3.5e-10;		h := 10.0e-10	END;
	18 : BEGIN	L := 1.0E-29;		m := 1.8E-29;		h := 5.0E-29	END;
	19 : BEGIN	L := 6.0E-11;		m := 6.0E-10;		h := 6.0E-9 	END;
	20 : BEGIN	L := 2.0E-9; 		m := 2.0E-8; 		h := 2.0E-7 	END;
	21 : BEGIN	L := 2.0E-4; 		m := 1.0E-3; 		h := 1.0E-1 	END;
	22 : BEGIN	L := 0.1;	 		m := 0.3; 			h := 0.9 		END;
	23 : BEGIN	L := 0;		 		m := par[1];		h := par[1] 	END;
	END;	{	Case	}

	Q := R*par[1]/1000;

 	CASE imc OF
		fcc:					BEGIN
	CASE n of
	9 : BEGIN	L := 16*Q;       	m := 18*Q;			h := 20*Q 	END;
	END;	{	Case	}
								END;
		hcp:					BEGIN
	CASE n of
	9 : BEGIN	L := 15*Q;       	m := 17*Q;			h := 19*Q 	END;
	END;	{	Case	}
								END;
		bcc_alkali:			BEGIN
	CASE n of
	1 : BEGIN	L := 302;			m := 370;			h := 452		END;
	2 : BEGIN	L := 0.28;       	m := 0.33;			h := 0.41 	END;
	3 : BEGIN	L := par[1]/521;	m := par[1]/309;	h := par[1]/122		END;
	6 : BEGIN	L := 0.01;       	m := 0.06;			h := 0.1 	END;
	7 : BEGIN	L := 0.2;       	m := 0.4;			h := 0.5 	END;
	9 : BEGIN	L := 13*Q;       	m := 15*Q;			h := 17*Q 	END;
	14 : BEGIN	L := 3;       		m := 5;				h := 7 	END;
	16 : BEGIN	L := 13*Q;       	m := 15*Q;			h := 17*Q 	END;
	17 : BEGIN	L := 3.04e-10;		m := 4.0e-10;		h := 5.32e-10	END;
	18 : BEGIN	L := 2.16E-29;		m := 7.2E-29;		h := 1.16E-28	END;
	END;	{	Case	}
								END;
		bcc_trans:			BEGIN
	CASE n of
	9 : BEGIN	L := 16*Q;       	m := 18*Q;			h := 20*Q 	END;
	END;	{	Case	}
								END;
		bcc_rare_earth:	BEGIN
	CASE n of
	9 : BEGIN	L := 7*Q;       	m := 9*Q;			h := 11*Q 	END;
	END;	{	Case	}
								END;
		bcc_rotator:		BEGIN
	CASE n of
	1 : BEGIN	L := 100;			m := 320;			h := 500		END;
	3 : BEGIN	L := par[1]/100;	m := par[1]/30;	h := par[1]/10		END;
	9 : BEGIN Q := R*par[1]/1000;
					L := 13*Q;        m := 15*Q;			h := 17*Q 	END;
	18 : BEGIN	L := 1.0E-27;		m := 1.8E-27;		h := 5.0E-27	END;
	END;	{	Case	}
								END;
		tetrag:				BEGIN
								END;
		trig:					BEGIN
								END;
		diamond_elements, sphalerites, wurtzites:
								BEGIN
	CASE n of
	1 : BEGIN	L := 500;			m := 3000;			h := 6000	END;
	2 : BEGIN	L := 0.06;			m := 0.1;			h := 0.5		END;
	3 : BEGIN	L := par[1]/50;	m := par[1]/30;	h := par[1]/10		END;
	4 : BEGIN	L := 0.01;			m := 0.06;			h := 0.1		END;
	6 : BEGIN	L := 0.001;			m := 0.1;		  	h := 0.2		END;
	9 : BEGIN Q := R*par[1]/1000;
					L := 20*Q;       	m := 36*Q;			h := 40*Q 	END;
	14 : BEGIN	L := 3.0;			m := 5.0;			h := 15.0		END;
	END;	{	Case	}
								END;
		alkali_halides:	BEGIN
	CASE n of
	1 : BEGIN	L := 200;			m := 750;			h := 1400	END;
	9 : BEGIN	L := 21*Q;       	m := 23*Q;			h := 25*Q 	END;
	END;	{	Case	}
								END;
		metal_carbides:	BEGIN
	CASE n of
	1 : BEGIN	L := 1000;			m := 3400;			h := 6000	END;
	9 : BEGIN	L := 21*Q;       	m := 24*Q;			h := 27*Q 	END;
	END;	{	Case	}
								END;
		magnesia_oxides, thoria_oxides, alumina_oxides, rutile_oxides: BEGIN
	CASE n of
	1 : BEGIN	L := 900;			m := 2000;			h := 4000	END;
	9 : BEGIN	L := 21*Q;       	m := 23*Q;			h := 25*Q 	END;
	END;	{	Case	}
								END;
		calcites:			BEGIN
	CASE n of
	9 : BEGIN	L := 21*Q;       	m := 23*Q;			h := 25*Q 	END;
	END;	{	Case	}
								END;
		ice:					BEGIN
	CASE n of
	9 : BEGIN	L := 25*Q;       	m := 26*Q;			h := 27*Q 	END;
	END;	{	Case	}
								END;
		ELSE
				BEGIN
				END;
	END; 	{	Case	}
END;	{	SET_PARAMETERS	}
{-------------------------------------------------------------------}
PROCEDURE SET_VARIABLES (n: R_vbls;	VAR L,m,h: a_real);
BEGIN
	CASE n OF
		1 	: BEGIN L := 10;		m := 40;		h := max_steps-1	 		END;
		2	: BEGIN L := 1.0E-2;	m := 1.0e+2;h := 1.0E+4;	END;
		3	: BEGIN L := 1.0e-14;m := 1.0e-6;h := 0.01		END;
		4 	: BEGIN L := 0.0001; m := 0.01;	h := 1			END;
		5 	: BEGIN L := 0.0;	  	m := 0.0;	h := 0.9			END;
		6 	: BEGIN L := 0.1;	  	m := 1.0;	h := 1.0			END;
		7 	: BEGIN L := 1.0e-16;m := 1.0e-7;h := 1.0e3		END;
		8 	: BEGIN L := 1.01;	m := 10;		h := 1.0e4		END;
		9 	: BEGIN L := 1;		m := 10;		h := maxcontournumber	END;
		10	: BEGIN L := 1e-14;	m := 1e-9;		h := 1.0e4		END;
		11	: BEGIN L := 1e-6;	m := 1e-4;		h := 1.0e4		END;
		12	: BEGIN L := 1;		m := par[1];	h := par[1]		END;
		13	: BEGIN L := 1;		m := 100;		h := par[1]		END;
		14	: BEGIN L := 1;		m := 10;			h := maxcontournumber	END;
		ELSE	{	several unset variables	}
				BEGIN L := 0.0;	  m := 0.0;		h := 0.0	 END;
	END;	{	Case	}
END;	{	SET_VARIABLES	}
{-------------------------------------------------------------------}
PROCEDURE LIMIT_VARIABLES;
{ ----- Ensure that variables have sensible values ----- }
BEGIN

	IF (vbl[1] <  2)					THEN vbl[1]  := 2;
	IF (vbl[1] >  max_steps-1)		THEN vbl[1]  := max_steps-1;
	IF (vbl[2]  <  1.0E-4)			THEN vbl[2]	:= 1.0E-4;
	IF (vbl[2]  >  1.0E+4)			THEN vbl[2]	:= 1.0E+4;
	IF (vbl[3]  >  0.9*vbl[4])		THEN vbl[3]	:= 0.9*vbl[4];
	IF (vbl[5] >  vbl[6]-0.1)		THEN vbl[5]  := vbl[6]-0.1;
	IF (vbl[9] >  maxcontournumber)	THEN vbl[9]  := maxcontournumber;
	IF (vbl[14] >  maxcontournumber)	THEN vbl[14]  := maxcontournumber;

END;	{	LIMIT_VARIABLES	}
{-------------------------------------------------------------------}
PROCEDURE NUMBER_FOR_PARAMETER (VAR number: Integer; ck: String);

{	Finds the parameter number given a parameter id	}
VAR
	i		:	Integer;
BEGIN
	i:= 0;
	REPEAT
		parnumber := i;
		LABELS_FOR_PARAMETERS;
		i := i+1;
	UNTIL (i > numberofparameters ) OR (ck=id);

	IF (i > numberofparameters) THEN
		number := -1
	ELSE
		number := parnumber;

END;  {NUMBER_FOR_PARAMETER;    }
{-------------------------------------------------------------------}
PROCEDURE NUMBER_FOR_VARIABLE (VAR number: Integer; ck: String);

{	Finds the variable number given a variable id	}
VAR
	i		:	Integer;
BEGIN
	i:= 1;
	REPEAT
		vblnumber := i;
		LABELS_FOR_VARIABLES;
		i := i+1;
	UNTIL (i > numberofvariables ) OR (ck=id);

	IF (i > numberofvariables) THEN
		number := -1
	ELSE
		number := vblnumber;

END;  {NUMBER_FOR_VARIABLE;    }
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

	IF CannotOpen(tempfile) THEN
		BEGIN
			WRITELN('ERROR: Cannot open an Output File');
			Writeln('Cannot open file "',tempfile,'"');
			Finish(4);
		END;

	Assign (file_in,main_datafile);
	Reset (file_in);
	Assign (file_out, tempfile);
	Rewrite (file_out);
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
			WRITELN('ERROR: Cannot open an Input File');
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
	index		:	R_refs;
BEGIN
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
		{	Shouldn't see Eof, only if error condition...	}
			IF Eof(file_in) THEN
				Finish(4)
			ELSE	{	Copy the rest of the file to output	}
				REPEAT
					READLN(file_in, buf);
					WRITELN(file_out, buf);
				UNTIL Eof(file_in);
		END;
	Close(file_in);

{ -----	Whether the ref. was in the old file or not, we append it	}
	Writeln(file_out,Esc,matlname);
	FOR index := 1 TO reflength DO
		write(file_out,ref[index]);
	Writeln(file_out);
	Writeln(file_out,Esc);

	Close (file_out);

	END_FILE_SAVE(reffilename);

END;	{	SAVE_MATL_REFERENCES	}
{-------------------------------------------------------------------}
PROCEDURE Prompt_Finish;
BEGIN
	gotoXY(1,24);  textbackground(C_back);
	write('                                                             ');
	REPEAT   gotoXY(1,24);
		write  ('              FINISHED  EDITING ?   (Y/N) ');
		answer:=Readkey;
	UNTIL answer in ['y','Y','n','N',CtrlC];
	IF answer=CtrlC THEN Finish(0);
	textcolor(C_text);
END;	{	Prompt_Finish	}
{-------------------------------------------------------------------}
PROCEDURE Prompt_Save;
BEGIN
	{ -------- Save the modified file ? -------- }
	gotoXY(1,24);  textbackground(C_back);
	write('                                                             ');
	REPEAT     gotoXY(1,24);   textcolor(C_bright);
		write ('                 SAVE  THE  DATA ?    (Y/N) ');
		answer:=Readkey;   gotoXY(1,24);
	UNTIL answer in ['y','Y','n','N',CtrlC];
	IF answer=CtrlC THEN Finish(0);
	textcolor(C_text);

END;	{	Prompt_Save	}
{-------------------------------------------------------------------}
PROCEDURE Prompt_Edit;
BEGIN
	{ -------- Edit the modified file ? -------- }
	gotoXY(1,24);  textbackground(C_back);
	write('                                                             ');
	REPEAT
		gotoXY(1,24);  textcolor(C_bright);
		write('               EDIT  THE  DATA ?    (Y/N) ');
		answer:=Readkey;
	UNTIL answer IN
		['y','Y','n','N', PageUp, PageDn, Up, Down, Left, Right, CtrlC];
	IF answer=CtrlC THEN Finish(0);
	textcolor(C_text);

END;	{	Prompt_Edit	}
{-------------------------------------------------------------------}
PROCEDURE POWER_LAW_CHECK (new_n: a_real);
{	This has to try to keep the power-law index and the
	reference stress in synch.	}
VAR
	p, pn	:	R_pars;
	old_n	:	a_real;
BEGIN
	{	parnumber is already set up	}
	pn := parnumber;
	LABELS_FOR_PARAMETERS;
	IF ( id = 'n-plc' ) THEN	{	change ref. stress	}
		BEGIN
			old_n	:= par [parnumber];
			p := 0;
			REPEAT
				p := p + 1;
				parnumber := p;
				LABELS_FOR_PARAMETERS;
			UNTIL (id = 'Srsplc') ;
			par[p] := exp( (old_n/new_n) * ln (par[p]) );

			textcolor(C_subdued);
			gotoXY(49,5 + p);
			WRITE_REAL (par[p]);

			textcolor(C_text);
			parnumber := pn;
		END;	{	if not n-plc, then no action.	}
END;
{-------------------------------------------------------------------}
PROCEDURE TEXT_EDIT_REFERENCE(linenumber: pagedepth);

CONST
	GoLeft	=	#200;
	GoRight	=	#201;
	GoDown	=	#202;
	GoUp		=	#203;
	GoHome	=	#204;
	DoIns		=	#205;
	DoDel		=	#206;

VAR
	x,y	:	Byte;
	i,index	:	R_refs;
	ch		:	Char;

BEGIN
	Textbackground(C_back);
	gotoXY(1,24);  textcolor(C_bright);
	write ('                                                             ');
	gotoXY(1,24);
	write ('  Use the cursor keys,     Finish with "Alt-W".    ');
	textcolor(C_text);
	{	restrict Window so scrolling etc. works	}
	window(10,4,70,22);

	gotoXY(1,linenumber);
	IF linenumber <= 1 THEN
		index := 1
	ELSE
		index    :=  61*(linenumber - 1);

	REPEAT
		IF index + 1 <= ref_buflength THEN
			index := index + 1
		ELSE
			index := 1;
		answer:=Readkey;
		IF (answer=CtrlC) {ctrl-C, ctrl-Break is disabled} THEN
			Finish(0);
		IF (answer = #0 ) THEN	{ function key }
			BEGIN
				answer := Readkey;

				CASE answer OF
					Left	:	answer := GoLeft;
					Right	:	answer := GoRight;
					Down	:	answer := GoDown;
					Up		:	answer := GoUp;
					Home	:	answer := GoHome;
					Ins	:	answer := DoIns;
					Del	:	answer := DoDel;
				END;	{	Case	}
			END;

		CASE answer OF
			Bksp
					:	BEGIN
							IF index > 1 THEN
								ref[index - 1] := ' ';
							IF index > 2 THEN
								index := index - 2
							ELSE
								index := ref_buflength;
						END;
			GoLeft
					:	BEGIN
							IF index > 2 THEN
								index := index - 2
							ELSE
								index := ref_buflength;
						END;
			GoDown : 	IF index + 60 <= ref_buflength THEN
					         index := index + 60
                      ELSE
                        index := index + 59 - ref_buflength;
			CR: 			IF index + 60 <= ref_buflength THEN
								BEGIN
									FOR i := index TO index + 59 DO
										ref[i] := ' ';
						         index := index + 60;
								END
                      ELSE
                        index := index + 59 - ref_buflength;
			GoRight : ;	{	null, does this anyway	}
			GoUp	:	IF index > 62 THEN
							index := (index - 62)
						ELSE
							index := (ref_buflength - 61);
			GoHome:	BEGIN
							index :=  1 + 61*(index DIV 61);
						END;
			DoIns:	BEGIN
							index :=  1 + 61*(index DIV 61);
							FOR i := ref_buflength DOWNTO index + 61 DO
								ref[i] := ref[i-61];
							FOR i := index TO index+61 DO
								ref[i] := ' ';
							InsLine;
						END;
			DoDel:	BEGIN
							index :=  1 + 61*(index DIV 61);
							FOR i := index TO ref_buflength - 61 DO
								ref[i] := ref[i+61];
							FOR i := ref_buflength DOWNTO ref_buflength - 61 DO
								ref[i] := ' ';
							DelLine;
						END;
			#32..#125	:	BEGIN
									ref[index] := answer;
									write(ref[index]);
								END;
			ELSE		{	recover from an erroneous increment	}
						IF index > 1 THEN
							index := index - 1
		END;	{	Case	}

		linenumber := 1 + (index DIV 61);
		IF (linenumber > 1) THEN
			gotoXY(1+(index MOD 61),linenumber)
		ELSE
			gotoXY(1+index ,linenumber);

	UNTIL (answer = AltW);
	window(10,1,70,25);

	index := ref_buflength;
	WHILE (ref[index] IN [' ', CR, LF]) AND (index > 1) DO
		BEGIN
			Dec(index);
			reflength := index;
		END;

END;	{	TEXT_EDIT_REFERENCES	}
{-------------------------------------------------------------------}
PROCEDURE EDIT_IMC_VALUE;
CONST
	Return	=	#13;
	Tab		=	#9;
	ShiftTab	=	#15;
VAR
	s			:	String;
BEGIN
	textcolor(C_bright); textbackground(C_back);
	gotoXY(1,24);
	write('       PRESS TAB KEY TO CHANGE CLASS, RETURN TO FINISH ');

	get_imc_string (imc,s);
	textcolor(C_back); textbackground(C_bright);
	GotoXY(43,5);
	Write(s);
	GotoXY(43,5);
	REPEAT
		REPEAT
			REPEAT UNTIL KeyPressed;
			answer:=Readkey;
			IF (answer=CtrlC) {ctrl-Break} THEN
				Finish(0);
			IF (answer = #0 ) THEN	{ function key, ignore	}
				answer := Readkey;
		UNTIL answer in [Tab, ShiftTab, Return];
		IF (answer=Tab) THEN
			BEGIN
				IF (imc=unknown) THEN
					imc := fcc
				ELSE
					imc := succ(imc);
				get_imc_string (imc,s);
				GotoXY(43,5);
				Write(s);
				GotoXY(43,5);
			END
		ELSE IF (answer=ShiftTab) THEN
			BEGIN
				IF (imc=fcc) THEN
					imc := unknown
				ELSE
					imc := pred(imc);
				get_imc_string (imc,s);
				GotoXY(43,5);
				Write(s);
				GotoXY(43,5);
			END;
	UNTIL (answer =Return);
	textcolor(C_bright); textbackground(C_back);
	GotoXY(43,5);
	Write(s);

{ ----- Now set par[0] for storage in the disc file ----- }
	CASE imc OF
		imc_error:			par[0] := -1;
		fcc:					par[0] := 11;
		hcp:					par[0] := 12;
		bcc_alkali:			par[0] := 13;
		bcc_trans:			par[0] := 14;
		bcc_rare_earth:	par[0] := 15;
		bcc_rotator:		par[0] := 52;
		tetrag:				par[0] := 16;
		trig:					par[0] := 17;
		diamond_elements:	par[0] := 41;
		sphalerites:		par[0] := 42;
		wurtzites:			par[0] := 43;
		alkali_halides:	par[0] := 46;
		ice:					par[0] := 51;
		ELSE
				par[0] := 0;
	END; 	{	Case	}
END;	{	EDIT_IMC_VALUE	}
{-------------------------------------------------------------------}
PROCEDURE LIST_PARAMETERS(Page: T_page);

{ -------- Prints out the material parameters as a table -------- }
VAR
	s	:	String;
	P_first, P_last, saved_parnumber	:	R_pars;
BEGIN

	CLEAN_WINDOW;
	DATE_AND_TIME;
   saved_parnumber := parnumber;

	gotoXY(1,2);
	textbackground(C_back);
	write('                                                             ');
	gotoXY(1,2);
	writeln(' ',Version,'      INPUT PARAMETERS FOR   ',matlname,'   ',
		Date_string);

	IF (Page = First) THEN
		BEGIN
			textbackground(C_screen);
			GotoXY(48,23);	Write('PgDn for more');
			textbackground(C_back);

			gotoXY(1,5);
			get_imc_string (imc,s);
			write ('    0   Isomechanical Class:');
			GotoXY(43,5);
			Writeln(s);

			P_first := 1;
			P_last  := last_page1_parameter;
		END;

	IF (Page = Second) THEN
		BEGIN
			textbackground(C_screen);
			GotoXY(48,23);	Write('PgUp for more');
			textbackground(C_back);
			P_first := last_page1_parameter + 1;
			P_last  := numberofparameters;
			GotoXY(1,5);
		END;

	FOR parnumber := P_first to P_last DO
		BEGIN
			LABELS_FOR_PARAMETERS;

			write ('  ',parnumber:3,'   ', d, u,' =');
			WRITE_REAL (par[parnumber]);
			writeln;
		END;
   parnumber := saved_parnumber;

END;  {LIST_PARAMETERS.     }

{-------------------------------------------------------------------}
PROCEDURE LIST_VARIABLES;

{ -------- Prints out the material variables as a table -------- }
BEGIN

	CLEAN_WINDOW;
	DATE_AND_TIME;

	gotoXY(1,2);
	textbackground(C_back);
	write('                                                             ');
	gotoXY(1,2);
	writeln(' ',Version,'      INPUT VARIABLES FOR   ',matlname,'    ',
		Date_string);

	gotoXY(1,5);
	FOR vblnumber := 1 to numberofvariables DO
		BEGIN
			LABELS_FOR_VARIABLES;
			write ('  ',vblnumber:3,'   ', d, u,' =');
			WRITE_REAL(vbl[vblnumber]);
			writeln;
		END;

END;  {LIST_VARIABLES.    }
{-------------------------------------------------------------------}
PROCEDURE LIST_REFERENCES;
VAR
	reffile	:  text;
	index		:	R_refs;

{ -------- Prints out the material variables as a table -------- }
BEGIN

	CLEAN_WINDOW;
	DATE_AND_TIME;

	gotoXY(1,2);
	textbackground(C_back);
	write('                                                             ');
	gotoXY(1,2);
	writeln(' ',Version,'  REFERENCE DESCRIPTION FOR ',matlname);

{ ------- Print out Reference Text as a page on screen ------- }

	textcolor(C_subdued);
	gotoXY(1,4);
	FOR index := 1 to reflength DO
		write(ref[index]);

END;  {LIST_REFERENCES.    }
{-------------------------------------------------------------------}
PROCEDURE EDIT_PARAMETERS;
VAR
	L1, L2, L3		:	a_real;
	new_value	:	a_real;
	line_number	:	1..25;
	Page			:	T_page;
	untouched	:	BOOLEAN;
	{----------------------------------------------------------------}
	PROCEDURE Do_A_Parameter;
	VAR
	i	:	Word;
	BEGIN
		Textbackground(C_back);
		gotoXY(1,24);  textcolor(C_bright);
		write ('                                                             ');
		gotoXY(1,24);
		write  ('              LINE  NUMBER  FOR  EDITING  ....');
		parnumber := Read_Int (0,numberofparameters,escape);
		IF escape THEN
			Finish(0);
		IF (parnumber <= last_page1_parameter) AND (Page = Second) THEN
			BEGIN
				Page := First;
				LIST_PARAMETERS(Page);
			END;
		IF (parnumber > last_page1_parameter) AND (Page = First) THEN
			BEGIN
				Page := Second;
				LIST_PARAMETERS(Page);
			END;

      CASE Page OF
			First		:	line_number := parnumber + 5;
			Second	:	line_number := parnumber - last_page1_parameter + 4;
      END; {    Case }

		IF (parnumber = 0) THEN	{	edit IMC field	}
			EDIT_IMC_VALUE
		ELSE
			BEGIN
 				Textbackground(C_back);
				textcolor(C_text);

				LABELS_FOR_PARAMETERS;

				textcolor(C_subdued);
				gotoXY(1,line_number);
				write ('  ',parnumber:3,'   ', d, u,' =');

				WRITE_REAL (par[parnumber] );
				writeln;

				textcolor(C_text);
 				Textbackground(C_back);
				gotoXY(1,24);
				write ('  ', parnumber:3,'  ', d, u, '  =  ');
				textcolor(C_warn);
				new_value := Read_Real(escape);
				IF escape THEN
					Finish(0);

				IF new_value = 0.0 then
			 		SET_PARAMETERS (parnumber, L1, new_value, L3);

				textcolor(C_bright);
				gotoXY(1,line_number);
				write ('  ',parnumber:3,'   ', d, u,' =');
				textcolor(C_subdued);

				WRITE_REAL (new_value );
				writeln;
				textcolor(C_text);

				POWER_LAW_CHECK (new_value);
				par[parnumber] := new_value;
			END;
	END;
	{----------------------------------------------------------------}
BEGIN	{	EDIT_PARAMETERS	}
	untouched := TRUE;
	Page	:= First;
	LIST_PARAMETERS(Page);
	REPEAT
		Prompt_Edit;
		IF (Page = Second) AND (answer in [PageUp, Up, Left]) THEN
			BEGIN
				Page := First;
				LIST_PARAMETERS(Page);
			END
		ELSE IF (Page = First) AND (answer in [PageDn, Down, Right]) THEN
			BEGIN
				Page := Second;
				LIST_PARAMETERS(Page);
			END;
		IF answer in ['y','Y'] THEN
			BEGIN
				Do_A_Parameter;
				untouched := FALSE;
			END;
	UNTIL answer in ['n','N'];

	IF NOT untouched THEN
		BEGIN
			Prompt_Save;
			IF answer in ['y','Y'] then SAVE_MATL_PARAMETERS;
		END;

	textbackground(C_back);  gotoXY(1,2);
END;	{	EDIT_Parameters	}
{-------------------------------------------------------------------}
PROCEDURE EDIT_VARIABLES;
VAR
	L1, L2, L3		:	a_real;
BEGIN
	LIST_VARIABLES;
	Prompt_Edit;

	if answer in ['y','Y'] then
		BEGIN
			REPEAT
				LIMIT_VARIABLES;
				Textbackground(C_back);
				gotoXY(1,24);  textcolor(C_bright);
				write ('                                                             ');
				gotoXY(1,24);
				write ('              LINE  NUMBER  FOR  EDITING  .... ');
				vblnumber := Read_Int (1,numberofvariables,escape);
				IF escape THEN
					Finish(0);

				Textbackground(C_back);
				textcolor(C_text);
				LABELS_FOR_VARIABLES;

				textcolor(C_bright);
				textcolor(C_subdued);
				gotoXY(1,4 + vblnumber);
				write ('  ',vblnumber:3,'   ', d, u,' =');

				WRITE_REAL (vbl[vblnumber] );
				writeln;
				textcolor(C_text);

 				Textbackground(C_back);
				gotoXY(1,24);
				write ('  ', vblnumber:3,'  ', d, u, '  =  ');
				textcolor(C_warn);
				vbl[vblnumber] := Read_Real(escape);
				IF escape THEN
					Finish(0);

				IF vbl[vblnumber] = 0.0 then
			 		SET_VARIABLES (vblnumber, L1, vbl[vblnumber], L3);

				Textbackground(C_back);
				textcolor(C_bright);
				gotoXY(1,4 + vblnumber);
				write ('  ',vblnumber:3,'   ', d, u,' =');
				textcolor(C_subdued);
				WRITE_REAL (vbl[vblnumber] );
				writeln;
				textcolor(C_text);

				Prompt_Finish;
			UNTIL answer in ['y','Y'];

			Prompt_Save;
			IF answer in ['y','Y'] then SAVE_MATL_VARIABLES;
		END;

	textbackground(C_back);  gotoXY(1,2);
END;	{	EDIT_VARIABLES	}
{-------------------------------------------------------------------}
PROCEDURE EDIT_REFERENCES;

BEGIN
	LIST_REFERENCES;
	Prompt_Edit;

	if answer in ['y','Y'] then
		BEGIN
			REPEAT
				TEXT_EDIT_REFERENCE(1);
				LIST_REFERENCES;			{	just in case the display gets worng..}
				Prompt_Finish;
			UNTIL answer in ['y','Y'];

			Prompt_Save;
			IF answer in ['y','Y'] then SAVE_MATL_REFERENCES;
		END;

	textbackground(C_back);  gotoXY(1,2);
END;	{	EDIT_REFERENCES	}
{-------------------------------------------------------------------}
PROCEDURE MAKE_PARAMETER_SET;

{ -- Creates a file on disk containing parameters for a chosen material -- }
VAR
	s	:	String;
   Line_number  : R_pars;
	L1, L2, L3		:	a_real;
	{----------------------------------------------------------------}
	PROCEDURE Parameter_Entry;
	BEGIN
		gotoXY (47,Line_number);
		TextBackground(C_bright);
		write('            ');

		gotoXY (47,Line_number);
		Textcolor(C_warn);
		par[parnumber] := Read_Real(escape);
		IF escape THEN
			Finish(0);

		gotoXY (47,Line_number);
		TextBackground(C_back);
		write('            ');

		IF par[parnumber] = 0.0 then
	 		SET_PARAMETERS (parnumber, L1, par[parnumber], L3);

		gotoXY (47,Line_number);
		Textcolor(C_bright);
		WRITE_REAL (par[parnumber] );
	END;
	{----------------------------------------------------------------}
BEGIN	{	MAKE_PARAMETER_SET	}

	CLEAN_WINDOW;
	DATE_AND_TIME;

	textbackground(C_back);
	gotoXY(1,2);
	write  ('                                                             ');
	gotoXY(1,2);
	write(' ',Version,'    Creating a new file for   ',matlname,'  ',date_string);

	imc := unknown;
	get_imc_string (imc,s);
	gotoXY(1,5);
	write ('    0   Isomechanical Class:');
	GotoXY(43,5);
	Writeln(s);

	for parnumber := 1 to last_page1_parameter do BEGIN
		LABELS_FOR_PARAMETERS;
		writeln ('  ',parnumber:3,'   ',d,u,'....');
	END;

	EDIT_IMC_VALUE;

	gotoXY(1,24);
	write  ('                                                             ');
	gotoXY(1,24);
	textcolor(C_bright);
	write('                     ENTER  PARAMETERS ');    textcolor(C_text);

	textcolor(C_text);
	for parnumber := 1 to last_page1_parameter do
      BEGIN
         Line_number := parnumber + 5;
         Parameter_Entry;
      END;

	Window(10,5,70,22);
	ClrScr;
	for parnumber := last_page1_parameter + 1 TO numberofparameters DO
		BEGIN
			LABELS_FOR_PARAMETERS;
			writeln ('  ',parnumber:3,'   ',d,u,'....');
		END;
	window(10,1,70,25);
	for parnumber := last_page1_parameter + 1 TO numberofparameters do
      BEGIN
         Line_number := parnumber - last_page1_parameter + 4;
         Parameter_Entry;
      END;

{	The estimate for the ref.stress is v.poor since it is based on the
	glide flow stress. It should be calculated such that it gives a
	strain rate of 1e-6 at Tm/2 when stress=ref.stress (par[15]).	}

{ ------- List the file for inspection and Editing, & Saving ------- }
	Prompt_Save;
	IF answer in ['y','Y'] then SAVE_MATL_PARAMETERS;

END; {MAKE_PARAMETER_SET.    }
{-------------------------------------------------------------------}
PROCEDURE MAKE_VARIABLE_SET;
VAR
	L1, L2, L3		:	a_real;

{ -- Creates a file on disk containing variables for a chosen material -- }

BEGIN

	CLEAN_WINDOW;
	DATE_AND_TIME;

	textbackground(C_back);
	gotoXY(1,2);
	write  ('                                                             ');
	gotoXY(1,2);
	write(' ',Version,'    Creating a new file for   ',matlname,'  ',date_string);

	gotoXY(1,5);
	for vblnumber := 1 to numberofvariables do BEGIN
			LABELS_FOR_VARIABLES;
			writeln ('  ',vblnumber:3,'   ',d,u,'....');
		END;

	gotoXY(1,24);
	write  ('                                                             ');
	gotoXY(1,24);
	textcolor(C_bright);
	write('                     ENTER  VARIABLES ');    textcolor(C_text);

	for vblnumber := 1 to numberofvariables do
		BEGIN
			gotoXY (47,4+vblnumber);
			TextBackground(C_bright);
			write('            ');

			gotoXY (47,4+vblnumber);
			Textcolor(C_warn);
			vbl[vblnumber] := Read_Real(escape);
			IF escape THEN
				Finish(0);

			gotoXY (47,4+vblnumber);
			TextBackground(C_back);
			write('            ');

			IF vbl[vblnumber] = 0.0 then
		 		SET_VARIABLES (vblnumber, L1, vbl[vblnumber], L3);

			gotoXY (47,4+vblnumber);
			Textcolor(C_bright);
			WRITE_REAL (vbl[vblnumber] );
		END;

	LIMIT_VARIABLES;
	Prompt_Save;
	IF answer in ['y','Y'] then SAVE_MATL_VARIABLES;

END; {MAKE_VARIABLE_SET.   }
{-------------------------------------------------------------------}
PROCEDURE MAKE_REFERENCE_SET;

{ -- Creates a new set of reference info. -- }
VAR
	index	:	R_refs;
BEGIN

	CLEAN_WINDOW;
	DATE_AND_TIME;

	textbackground(C_back);
	gotoXY(1,2);
	write  ('                                                             ');
	gotoXY(1,2);
	write(' ',Version,' Creating a new reference for ',matlname,'  ',date_string);

	gotoXY(1,24);
	write  ('                                                             ');
	gotoXY(1,24);
	textcolor(C_bright);
	write('                     ENTER  REFERENCES ');    textcolor(C_text);

	FOR index:= 1 TO ref_buflength DO
		ref[index] := ' ';
	reflength := 1;
	TEXT_EDIT_REFERENCE(1);

{ ------- DON'T List the file for inspection and Editing, & Saving ------- }
	Prompt_Save;
	IF answer in ['y','Y'] then SAVE_MATL_REFERENCES;

END; {MAKE_REFERENCE_SET.   }
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
	i,index		:	R_refs;
	len		:	Word;

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
					WHILE NOT ((Eof(file_ref))
					OR (buf[1] = Esc)
					OR (index >= ref_buflength-2)) DO
						BEGIN
							READLN(file_ref, buf);
							len :=Length(buf);
							IF (index + len > ref_buflength) THEN
								len := ref_buflength - index -1;
                     IF (len > 0) AND (buf[1] <> Esc) THEN
								BEGIN
                     		FOR i := 1 TO len DO
             	           	BEGIN
											ref[index] := buf[i];
											Inc(index);
										END;
								END;
							ref[index] := CR;
							ref[index+1] := LF;
							index := index +2;
						END;
				END;
			reflength := index-1;
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

	CASE round (par[0]) OF
		-1:					imc := imc_error;
		1, 10:				imc := bcc_trans;	{	default metal	}
		2, 20:				imc := fcc_orderd;	{	default intermetallic	}
		3, 30:				imc := alumina_oxides;	{	default oxide	}
		4, 40:				imc := sphalerites;	{	default ceramic	}
		5, 50:				imc := ice;	{	default molecular compound	}
		6..10:				imc := imc_error;
		11:					imc := fcc;
		12:					imc := hcp;
		13:					imc := bcc_alkali;
		14:					imc := bcc_trans;
		15:					imc := bcc_rare_earth;
		16:					imc := tetrag;
		17:					imc := trig;
		18..19:				imc := imc_error;
		21..29:				imc := fcc_orderd;
		31..39:				imc := alumina_oxides;
		41:					imc := diamond_elements;
		42:					imc := sphalerites;
		43..45:				imc := wurtzites;
		46..49:				imc := alkali_halides;
		51,53..59:			imc := ice;
		52:					imc := bcc_rotator;
	ELSE
				imc := unknown;
	END; 	{	Case	}

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
				modeconcern:=TRUE;
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
						IF modelist THEN
							BEGIN
								writeln(lst,'       PARAMETER',parnumber:3,' OUTSIDE EXPECTED RANGE.');
								writeln(lst,'       ',d,'=  ',s,'  ',u);
								writeln(lst,'       Anticipated  Range          =',s_lo,' to ',s_hi,'  ',u);
								writeln(lst);
							END;
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
							IF modelist THEN
								BEGIN
									writeln(lst,'       VARIABLE ',vblnumber:3,' OUTSIDE EXPECTED RANGE.');
									writeln(lst,'       ',d,'=  ',s,'  ',u);
									writeln(lst,'       Anticipated  Range          =  ',s_lo,' to ',s_hi,'  ',u);
									writeln(lst);
								END;
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
PROCEDURE OPEN_PRINTER (hrdcopy: CHAR);

BEGIN
	IF (hrdcopy in ['e','E']) THEN		{	reduced print Epson	}
		BEGIN
			write(lst,Esc,'@');		{	reset	}
	   	write(lst,#15); 			{ condensed printing }
			write(lst,Esc,'0');		{	1/8" lines	}
			write(lst,Esc,'C',#86);	{	86 lines per page	}
		END
	ELSE IF (hrdcopy in ['l','L']) THEN		{	reduced print HP laser	}
		BEGIN
			write(lst,Esc,'E');		{	reset	}
			write(lst,Esc,'&k2S');	{	condensed	}
			WRITE(Lst,Esc,'&18D'); 	{	1/8" lines	}
		END;
END;
{-------------------------------------------------------------------}
PROCEDURE INPUT_DATA_TO_PRINTER;

VAR
	s	:	STRING;
	r	:	REAL;
	index		:	R_refs;
	i, j, line	:	WORD;
BEGIN
	DATE_AND_TIME;
	Writeln(lst,'      ',Version,' v',Release,' (',VersionDate,')');
	Writeln(lst,'      ',copyright);
	writeln(lst,'      ',weekday,' ',Date_string,' ',time_string);
	writeln(lst);
	writeln(lst,'      =============================================================');
	writeln(lst,'      ',Version,'     INPUT  PARAMETERS for  ',matlname);
	writeln(lst,'      =============================================================');
	writeln(lst);

	get_imc_string (imc,s);
	writeln (lst,
		'          0  Isomechanical Class                  ',s);

	for parnumber := 1 to numberofparameters do
		BEGIN
			r := par[parnumber];	{	in case a_real is DOUBLE	}
			convert_number (r, s, -1);
			LABELS_FOR_PARAMETERS;

			writeln (lst,'        ',parnumber:3,'  ', d, u,' =  ', s);
		END;
	writeln(lst);
	writeln(lst,'      =============================================================');
	writeln(lst);  writeln(lst);  writeln(lst);  writeln(lst);

	writeln(lst,'      =============================================================');
	writeln(lst,'      ',Version,'     INPUT  VARIABLES for  ',matlname);
	writeln(lst,'      =============================================================');
	writeln(lst);
	for vblnumber := 1 to numberofvariables do
		BEGIN
			r := vbl[vblnumber];	{	in case a_real is DOUBLE	}
			convert_number (r, s, -1);
			LABELS_FOR_VARIABLES;

			writeln (lst,'        ',vblnumber:3,'  ', d, u,' =  ',s);
		END;
	writeln(lst);
	writeln(lst,'      =============================================================');
	writeln(lst);  writeln(lst);  writeln(lst);  writeln(lst);

{ ------- Print out Reference Text ------- }

	writeln(lst,'      ',Version,'  REFERENCE DESCRIPTION FOR ',matlname);
	writeln(lst,'      =============================================================');
	writeln(lst);

	line := 1 + ref_buflength DIV reflines;
	FOR i := 0 to reflines - 2 DO
		BEGIN
			write(lst,'      ');
			FOR j := 1 TO line DO
				write(lst,ref[i*line + j]);
			writeln(lst);
		END;
	write(lst,'      ');
	FOR index := (ref_buflength - line +2) TO ref_buflength DO
		write(lst,ref[index]);
	writeln(lst);

END; {OPEN_INPUT_DATA_TO_PRINTER.    }
{-------------------------------------------------------------------}
PROCEDURE CLOSE_PRINTER (hrdcopy: CHAR);
BEGIN
	write(lst,#12);		{	page throw	}

	IF (hrdcopy in ['e','E']) THEN		{	reduced print Epson	}
		BEGIN
			write(lst,Esc,'@');		{	reset	}
		END
	ELSE IF (hrdcopy in ['l','L']) THEN		{	reduced print HP laser	}
		BEGIN
			write(lst,Esc,'E');		{	reset	}
		END;

END; {CLOSE_INPUT_DATA_TO_PRINTER.    }
{-------------------------------------------------------------------}
PROCEDURE INPUT_DATA_TO_FILE;

VAR
	lf	:	Text;
	s	:	STRING;
	r	:	REAL;
	index		:	R_refs;
	i, j, line	:	WORD;

BEGIN

	DATE_AND_TIME;
	Assign(lf,listfilename);
	Rewrite(lf);

	Writeln(lf,'      ',Version,' v',Release,' (',VersionDate,')');
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

	line := 1 + ref_buflength DIV reflines;
	FOR i := 0 to reflines - 2 DO
		BEGIN
			write(lf,'      ');
			FOR j := 1 TO line DO
				write(lf,ref[i*line + j]);
			writeln(lf);
		END;
	write(lf,'      ');
	FOR index := (ref_buflength - line +2) TO ref_buflength DO
		write(lf,ref[index]);
	writeln(lf);

	Close(lf);

END; {INPUT_DATA_TO_FILE.    }

{---------------------------------------------------------------------------}
{$IFDEF debug}
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
{$ENDIF}
{---------------------------------------------------------------------------}
PROCEDURE DUD_TEMP_TO_PRINTER (dud_steps: INTEGER;
									dud_TN, dud_K: a_real);
BEGIN
	writeln(lst);
	writeln(lst,'   ========================================');
	writeln(lst,'   LOW TEMPERATURE CUTTOFF for  ',matlname);
	writeln(lst,'   ========================================');
	writeln(lst);
	writeln(lst,'   Due to floating-point inaccuracies,',
				'the diffusion rates');
	writeln(lst,'   can only be calculated properly above ',
				dud_TN:6:3,' Tm');
	writeln(lst,'   i.e., above ',
				dud_K:6:0,' degrees K.');
END;	{	DUD_TEMP_TO_PRINTER	}
{---------------------------------------------------------------------------}
PROCEDURE DUD_TEMP_TO_FILE (dud_steps: INTEGER;
									dud_TN, dud_K: a_real);
VAR
	lf	:	Text;

BEGIN
	Assign(lf,listfilename);
	Append(lf);
	writeln(lf,'   Due to floating-point inaccuracies,',
				'the diffusion rates');
	writeln(lf,'   can only be calculated properly above ',
				dud_TN:6:3,' Tm');
	writeln(lf,'   i.e., above ',
				dud_K:6:0,' degrees K.');
	writeln(lf);
	Close(lf);
END;	{	DUD_TEMP_TO_FILE	}
{-------------------------------------------------------------------}
End.	{	Unit Dfmfiles	}
