Unit Dfmfiles;
{ PMS 28-June-1988 17:40 }

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   M.F.Ashby and P.M.Sargent        **************
   *************   June 1988                        **************
}
{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}

Interface

Uses
	Crt,
	Dos,
	Printer,
	stringIO,
	DfmGlbls;

FUNCTION ALREADY_EXISTS (name: T_matl_name): BOOLEAN;
{	This function returns TRUE if it is given a name which is
	already in the matl_list array, FALSE otherwise.	}

PROCEDURE LIST_MATERIALS;

{ This lists the available list of materials  }

PROCEDURE MAKE_PARAMETER_SET;

{ -- Creates a file on disk containing parameters for a chosen material -- }

PROCEDURE MAKE_VARIABLE_SET;

{ -- Creates a file on disk containing variables for a chosen material -- }

PROCEDURE READ_MATL_DATA;

{ -------- Read in the chosen materials parameters into the stash -------- }

PROCEDURE EDIT_PARAMETERS;
PROCEDURE LIMIT_VARIABLES;
PROCEDURE EDIT_VARIABLES;

PROCEDURE INTERPRET_PARAMETER_SET;

{ -------- Interpret in the chosen  parameter set -------- }

PROCEDURE INTERPRET_VARIABLE_SET;

{ -------- Interpret in the chosen variable set -------- }

PROCEDURE SAVE_MATL_PARAMETERS;

PROCEDURE SAVE_MATL_VARIABLES;

PROCEDURE CHECK_PARAMETERS;

{ -------- Checks input data against limits -------- }

PROCEDURE INPUT_DATA_TO_PRINTER;

PROCEDURE INPUT_DATA_TO_FILE;

{===================================================================}

Implementation

VAR
	escape	:	BOOLEAN;

{-------------------------------------------------------------------}
PROCEDURE SET_PARAMETERS (n: parrange; VAR L,m,h: a_real);
VAR
	Q, guess	:	a_real;
	{----------------------------------------------------------------}
FUNCTION dDbdry: a_real;
BEGIN	
	{	If the atomic vloume is unset, then set it (recursive call)	}
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
	9 : BEGIN	L := 13*Q;       	m := 15*Q;			h := 17*Q 	END;
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
	9 : BEGIN	L := 21*Q;       	m := 23*Q;			h := 25*Q 	END;
	END;	{	Case	}
								END;
		metal_carbides:	BEGIN
	CASE n of
	9 : BEGIN	L := 21*Q;       	m := 24*Q;			h := 27*Q 	END;
	END;	{	Case	}
								END;
		magnesia_oxides, thoria_oxides, alumina_oxides, rutile_oxides: BEGIN
	CASE n of
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
PROCEDURE SET_VARIABLES (n: vblrange;	VAR L,m,h: a_real);
BEGIN
	CASE n OF
		1 	: BEGIN L := 10;		m := 40;		h := max_steps-1	 		END;
		2	: BEGIN L := 1.0E-8;	m := 1.0e-4;h := 1.0E-2;	END;
		3	: BEGIN L := 1.0e-14;m := 1.0e-6;h := 0.01		END;
		4 	: BEGIN L := 0.0001; m := 0.01;	h := 1			END;
		5 	: BEGIN L := 0.0;	  	m := 0.0;	h := 0.9			END;
		6 	: BEGIN L := 0.1;	  	m := 1.0;	h := 1.0			END;
		7 	: BEGIN L := 1.0e-16;m := 1.0e-7;h := 1.0e3		END;
		8 	: BEGIN L := 1.01;	m := 10;		h := 1.0e4		END;
		9 	: BEGIN L := 1;		m := 10;		h := maxcontournumber	END;
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
	IF (vbl[2]  <  1.0E-10)			THEN vbl[2]	:= 1.0E-10;
	IF (vbl[2]  >  1.0E-2)			THEN vbl[2]	:= 1.0E-2;
	IF (vbl[3]  >  0.9*vbl[4])		THEN vbl[2]	:= 0.9*vbl[4];
	IF (vbl[5] >  vbl[6]-0.1)		THEN vbl[5]  := vbl[6]-0.1;
	IF (vbl[9] >  10)					THEN vbl[9]  := 10;

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
	UNTIL (i > numberofparameters+1 ) OR (ck=id);

	IF (i > numberofparameters+1) THEN
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
	UNTIL (i > numberofvariables+1 ) OR (ck=id);

	IF (i > numberofvariables+1) THEN
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
END;
{-------------------------------------------------------------------}
PROCEDURE SAVE_MATL_PARAMETERS;
VAR
	file_in	:	Text;
	file_out	:	Text;
	tempfile	:	String;
	bakfile	:	String;
	line, buf:	String;
	material	:	String;
	pad_m		:	String;
	pad_id	:	String;
	parid		:	String;
	number	:	Integer;
BEGIN
	gotoXY(1,24); textbackground(C_back); textcolor(C_bright);
	WRITE('                                                             ');
	gotoXY(1,24);  WRITE('               SAVING  THE  DATA  TO  DISC');
	textcolor(C_text);

{	Set the temporary filename by replacing the extension by .TMP	}
	tempfile	:= parfilename;
	delete(tempfile,pos('.',tempfile),4);
	bakfile	:= tempfile+'.BAK';
	tempfile := tempfile+'.TMP';

{	What we do here is to copy ALL the data which is either for
	materials not currently under consideration, OR for parameters
	which may be in the datafile but which this program does not
	concern itself.	We copy it to the temporary file.	}

	Assign (file_in,parfilename);
	Reset (file_in);
	Assign (file_out, tempfile);
	Rewrite (file_out);

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

{	Now, playing safe, we erase any backup file, rename the .DAT file
	as a backup .BAK file, and rename the .TMP file as the .DAT file	}

	IF NOT FileNotThere (bakfile) THEN
		BEGIN
			Assign (file_out, bakfile);
			Erase (file_out);
		END;

	Assign (file_out, parfilename);
	Rename (file_out, bakfile);

	Assign (file_out, tempfile);
	Rename (file_out, parfilename);

END;	{	SAVE_MATL_PARAMETERS	}
{-------------------------------------------------------------------}
PROCEDURE SAVE_MATL_VARIABLES;
VAR
	file_in	:	Text;
	file_out	:	Text;
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
	gotoXY(1,24); textbackground(C_back); textcolor(C_bright);
	WRITE('                                                             ');
	gotoXY(1,24);  WRITE('               SAVING  THE  DATA  TO  DISC');
	textcolor(C_text);

{	Set the temporary filename by replacing the extension by .TMP	}
	tempfile	:= parfilename;
	delete(tempfile,pos('.',tempfile),4);
	bakfile	:= tempfile+'.BAK';
	tempfile := tempfile+'.TMP';

{	What we do here is to copy ALL the data which is either for
	materials not currently under consideration, OR for variables
	which may be in the datafile but which this program does not
	concern itself.	We copy it to the temporary file.	}

	Assign (file_in,parfilename);
	Reset (file_in);
	Assign (file_out, tempfile);
	Rewrite (file_out);

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

{	Now, playing safe, we erase any backup file, rename the .DAT file
	as a backup .BAK file, and rename the .TMP file as the .DAT file	}

	IF NOT FileNotThere (bakfile) THEN
		BEGIN
			Assign (file_out, bakfile);
			Erase (file_out);
		END;

	Assign (file_out, parfilename);
	Rename (file_out, bakfile);

	Assign (file_out, tempfile);
	Rename (file_out, parfilename);

END;	{	SAVE_MATL_VARIABLES	}
{-------------------------------------------------------------------}
PROCEDURE Prompt_Finish;
BEGIN
	gotoXY(1,24);  textbackground(C_back);
	write('                                                             ');
	REPEAT   gotoXY(1,24);
		write  ('              FINISHED  EDITING ?   (Y/N) ');
		answer:=Readkey;
	UNTIL answer in ['y','Y','n','N',Esc];
	IF answer=Esc THEN Finish(0);
	textcolor(C_text);
END;	{	Prompt_Finish	}
{-------------------------------------------------------------------}
PROCEDURE Prompt_Save;
BEGIN
	{ -------- Save the modified file ? -------- }
	gotoXY(1,24);  textbackground(C_back);
	write('                                                             ');
	REPEAT     gotoXY(1,24);   textcolor(C_bright);
		write ('                 SAVE  THE  FILE ?    (Y/N) ');
		answer:=Readkey;   gotoXY(1,24);
	UNTIL answer in ['y','Y','n','N',Esc];
	IF answer=Esc THEN Finish(0);
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
		write('               EDIT  THE  FILE ?    (Y/N) ');
		answer:=Readkey;
	UNTIL answer in ['y','Y','n','N',Esc];
	IF answer=Esc THEN Finish(0);
	textcolor(C_text);

END;	{	Prompt_Edit	}
{-------------------------------------------------------------------}
PROCEDURE POWER_LAW_CHECK (new_n: a_real);
{	This has to try to keep the power-law index and the
	reference stress in synch.	}
VAR
	p, pn	:	parrange;
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

			textcolor(C_bright);	LowVideo;
			gotoXY(49,4 + p);
			WRITE_REAL (par[p]);

			NormVideo;
			parnumber := pn;
		END;	{	if not n-plc, then no action.	}
END;
{-------------------------------------------------------------------}
PROCEDURE EDIT_IMC_VALUE;
CONST
	Return	=	#13;
	Tab		=	#9;
VAR
	s			:	String;
BEGIN
	textcolor(C_bright); textbackground(C_back);
	gotoXY(1,24);  
	write('       PRESS TAB KEY TO CHANGE CLASS, RETURN TO FINISH ');

	get_imc_string (imc,s);
	textcolor(C_back); textbackground(C_bright);
	GotoXY(43,4);
	Write(s);
	GotoXY(43,4);
	REPEAT
		REPEAT
			REPEAT UNTIL KeyPressed;
			answer:=Readkey;
			IF (answer=Esc) OR (answer=#3) {ctrl-Break} THEN
				Finish(0);
			IF (answer = #0 ) THEN	{ function key, ignore	}
				answer := Readkey;
		UNTIL answer in [Tab, Return];
		IF (answer=Tab) THEN
			BEGIN
				IF (imc=unknown) THEN
					imc := fcc
				ELSE
					imc := succ(imc);
				get_imc_string (imc,s);
				GotoXY(43,4);
				Write(s);
				GotoXY(43,4);
			END;
	UNTIL (answer =Return);
	textcolor(C_bright); textbackground(C_back);
	GotoXY(43,4);
	Write(s);

{ ----- Now set par[0] for storage in the disc file ----- }
	CASE imc OF
		imc_error:			par[0] := -1;
		fcc:					par[0] := 11;
		hcp:					par[0] := 12;
		bcc_alkali:			par[0] := 13;
		bcc_trans:			par[0] := 14;
		bcc_rare_earth:	par[0] := 15;
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
PROCEDURE EDIT_PARAMETERS;
VAR
	new_value	:	a_real;
BEGIN
	Prompt_Edit;

	if answer in ['y','Y'] then
		BEGIN
			REPEAT
				Textbackground(C_back);
				gotoXY(1,24);  textcolor(C_bright);
				write ('                                                             ');
				gotoXY(1,24);
				write  ('              LINE  NUMBER  FOR  EDITING  ....');
				parnumber := Read_Int (0,numberofparameters,escape);
				IF escape THEN
					Finish(0);

				IF (parnumber = 0) THEN	{	edit IMC field	}
					EDIT_IMC_VALUE
				ELSE
					BEGIN
		 				Textbackground(C_back);
						textcolor(C_text);

						LABELS_FOR_PARAMETERS;

						textcolor(C_bright);
						LowVideo;
						gotoXY(1,4 + parnumber);
						write ('  ',parnumber:3,'   ', d, u,' =');

						WRITE_REAL (par[parnumber] );
						writeln;
						NormVideo;

		 				Textbackground(C_back);
						gotoXY(1,24);  
						write ('  ', parnumber:3,'  ', d, u, '  =  ');
						textcolor(C_warn);
						new_value := Read_Real(escape);
						IF escape THEN
							Finish(0);

						IF new_value = 0.0 then
					 		SET_PARAMETERS (parnumber, L1, new_value, L3);

						Textbackground(C_back);
						textcolor(C_bright);
						gotoXY(1,4 + parnumber);
						write ('  ',parnumber:3,'   ', d, u,' =');
						LowVideo;

						WRITE_REAL (new_value );
						writeln;
						NormVideo;

						POWER_LAW_CHECK (new_value);
						par[parnumber] := new_value;
					END;

				Prompt_Finish;
			UNTIL answer in ['y','Y'];

			Prompt_Save;
			IF answer in ['y','Y'] then SAVE_MATL_PARAMETERS;
		END;

	textbackground(C_back);  gotoXY(1,2);
END;	{	EDIT_Parameters	}
{-------------------------------------------------------------------}
PROCEDURE EDIT_VARIABLES;

BEGIN
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
				LowVideo;
				gotoXY(1,4 + vblnumber);
				write ('  ',vblnumber:3,'   ', d, u,' =');

				WRITE_REAL (vbl[vblnumber] );
				writeln;
				NormVideo;

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
				LowVideo;
				WRITE_REAL (vbl[vblnumber] );
				writeln;
				NormVideo;

				Prompt_Finish;
			UNTIL answer in ['y','Y'];

			Prompt_Save;
			IF answer in ['y','Y'] then SAVE_MATL_VARIABLES;
		END;

	textbackground(C_back);  gotoXY(1,2);
END;	{	EDIT_VARIABLES	}
{-------------------------------------------------------------------}
PROCEDURE MAKE_PARAMETER_SET;

{ -- Creates a file on disk containing parameters for a chosen material -- }
VAR
	s	:	String;
BEGIN

	CLEAN_WINDOW;
	DATE_AND_TIME;

	textbackground(C_back);
	gotoXY(1,2);
	write  ('                                                             ');
	gotoXY(1,2);
	write(' ',Version,'    Creating a new file for   ',matlname,'    ',date_string);

	imc := unknown;
	get_imc_string (imc,s);
	gotoXY(1,4);
	write ('    0   Isomechanical Class:');
	GotoXY(43,4);
	Writeln(s);

	for parnumber := 1 to numberofparameters do BEGIN
		LABELS_FOR_PARAMETERS;
		writeln ('  ',parnumber:3,'   ',d,u,'....');
	END;

	EDIT_IMC_VALUE;

	gotoXY(1,24);
	write  ('                                                             ');
	gotoXY(1,24);
	textcolor(C_bright);
	write('                     ENTER  PARAMETERS ');    textcolor(C_text);

	for parnumber := 1 to numberofparameters do
		BEGIN
			gotoXY (47,4+parnumber);
			TextBackground(C_bright);
			write('            ');

			gotoXY (47,4+parnumber);
			Textcolor(C_warn);
			par[parnumber] := Read_Real(escape);
			IF escape THEN
				Finish(0);

			gotoXY (47,4+parnumber);
			TextBackground(C_back);
			write('            ');

			IF par[parnumber] = 0.0 then
		 		SET_PARAMETERS (parnumber, L1, par[parnumber], L3);

			gotoXY (47,4+parnumber);
			Textcolor(C_bright);
			WRITE_REAL (par[parnumber] );
		END;

{	The estimate for the ref.stress is v.poor since it is based on the
	glide flow stress. It should be calculated such that it gives a
	strain rate of 1e-6 at Tm/2 when stress=ref.stress (par[15]).	}

	LIST_PARAMETERS;

{ -------- Save the file -------- }

	Prompt_Save;
	if answer in ['y','Y'] then SAVE_MATL_PARAMETERS;

{ ------- List the file for inspection and Editing ------- }
	EDIT_PARAMETERS;

END; {MAKE_PARAMETER_SET.    }
{-------------------------------------------------------------------}
PROCEDURE MAKE_VARIABLE_SET;

{ -- Creates a file on disk containing variables for a chosen material -- }

BEGIN

	CLEAN_WINDOW;
	DATE_AND_TIME;

	textbackground(C_back);
	gotoXY(1,2);
	write  ('                                                             ');
	gotoXY(1,2);
	write(' ',Version,'    Creating a new file for   ',matlname,'    ',date_string);

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
	LIST_VARIABLES;

{ -------- Save the file -------- }

	Prompt_Save;
	if answer in ['y','Y'] then SAVE_MATL_VARIABLES;

{ ------- List the file for inspection and Editing ------- }

	EDIT_VARIABLES;

END; {MAKE_VARIABLE_SET.   }
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
			'. Too many data items for this material, extra ignored.');
		END;
END;	{	STASH_DATA_LINE	}
{-------------------------------------------------------------------}
PROCEDURE READ_MATL_DATA;

{ -------- Read in the chosen material parameters and variables -------- }
VAR
	file_in	:	Text;
	line, buf:	String;
	material	:	String;

BEGIN
	gotoXY(1,24); textbackground(C_back); textcolor(C_bright);
	WRITE('                                                             ');
	gotoXY(1,24);  WRITE('                   READING  THE  DATA         ');
	textcolor(C_text);

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
	check		:	ARRAY [parrange] OF BOOLEAN;
	i			:	1..stash_max;
BEGIN
	FOR parnumber := 0 TO numberofparameters DO
		check[parnumber] := FALSE;

	FOR i := 1 TO stash_index DO
			BEGIN
		{	Read a line, check if it is a parameter we know about..	}
				line := stash[i];
				parid  := get_next_token(line);
				NUMBER_FOR_PARAMETER (number,parid);
				IF (number >= 0) THEN

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

{	If we have some parameters without values, then take defaults.	}
	FOR parnumber:= 0 TO numberofparameters DO
		IF NOT check[parnumber] THEN
			BEGIN
				SET_PARAMETERS (parnumber, L,m,h);
				par[parnumber] := m;
			END;

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
		51..59:				imc := ice;
	ELSE
				imc := unknown;
	END; 	{	Case	}

{ ------- Display the file for inspection and editing ------- }

	IF NOT modefast THEN
		BEGIN
			LIST_PARAMETERS;
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
	check		:	ARRAY [vblrange] OF BOOLEAN;
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
				IF (number > 0) THEN

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
			LIST_VARIABLES;
			EDIT_VARIABLES;
		END;

END;  {INTERPRET_VARIABLE_SET.    }
{-------------------------------------------------------------------}
PROCEDURE CHECK_PARAMETERS;

{ -------- Checks input data against limits -------- }
VAR
	lf	:	Text;
	s, s_lo, s_hi	:	STRING;
	r, r_lo, r_hi	:	REAL;

BEGIN

	CLEAN_WINDOW;

	textbackground(C_back);
	gotoXY(1,2);
	write  ('                                                             ');
	gotoXY(1,2);
	write(' ',Version,'     CHECK  ON  INPUT DATA  FOR   ');
	textcolor(C_bright);
	write(matlname);
	gotoXY(1,5);
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
				writeln ('    ',d,'  outside expected range      ');
				writeln('       ',d,'=  ',s,'  ',u);
				writeln('       Anticipated  Range          =',s_lo,'  ',u);
				writeln('                                 to ',s_hi,'  ',u);
				IF modelist AND NOT modelistfile then
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
					writeln ('   ',d,'  outside expected range     ');
					writeln('       ',d,'=  ',s,'  ',u);
					writeln('       Anticipated  Range          =  ',s_lo,'  ',u);
					writeln('                                 to ',s_hi,'  ',u);
					IF modelist AND NOT modelistfile then
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
				END;
		END;	{	for vblnumber := 1 to numberofvariables do	}


	textcolor(C_text);  writeln;
	write ('     ------------  DATA  CHECK  COMPLETE  ------------');
	writeln;

END;  {CHECK_PARAMETERS.     }

{-------------------------------------------------------------------}
PROCEDURE INPUT_DATA_TO_PRINTER;

VAR
	s	:	STRING;
	r	:	REAL;
BEGIN

	DATE_AND_TIME;

	writeln(lst,'      =============================================================');
	writeln(lst,'         ',Version,'     INPUT  PARAMETERS for  ',matlname,'    ',Date_string);
	writeln(lst,'      =============================================================');
	writeln(lst);

	get_imc_string (imc,s);
	writeln (lst,'    0   Isomechanical Class:              ',s);

	for parnumber := 1 to numberofparameters do
		BEGIN
			r := par[parnumber];	{	in case a_real is DOUBLE	}
			convert_number (r, s, -1);
			LABELS_FOR_PARAMETERS;

			writeln (lst,'        ',parnumber:3,'  ', d, u,' =  ', s);
		END;
	writeln(lst);
	writeln(lst,'       =============================================================');
	writeln(lst,'                                                      Time ',time_string);
	writeln(lst);  writeln(lst);  writeln(lst);  writeln(lst);

	writeln(lst,'      =============================================================');
	writeln(lst,'         ',Version,'     INPUT  VARIABLES for  ',matlname,'     ',Date_string);
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
	writeln(lst,'       =============================================================');
	writeln(lst,'                                                      Time ',time_string);
	writeln(lst);  writeln(lst);  writeln(lst);  writeln(lst);

END; {INPUT_DATA_TO_PRINTER.    }
{-------------------------------------------------------------------}
PROCEDURE INPUT_DATA_TO_FILE;

VAR
	lf	:	Text;
	s	:	STRING;
	r	:	REAL;

BEGIN

	DATE_AND_TIME;
	Assign(lf,listfilename);
	Rewrite(lf);

	writeln(lf,'      =============================================================');
	writeln(lf,'         ',Version,'     INPUT  PARAMETERS for  ',matlname,'    ',Date_string);
	writeln(lf,'      =============================================================');
	writeln(lf);

	get_imc_string (imc,s);
	writeln (lf,'          0   Isomechanical Class:              ',s);

	for parnumber := 1 to numberofparameters do
		BEGIN
			r := par[parnumber];	{	in case a_real is DOUBLE	}
			convert_number (r, s, -1);
			LABELS_FOR_PARAMETERS;

			writeln (lf,'        ',parnumber:3,'  ', d, u,' =  ', s);
		END;
	writeln(lf);
	writeln(lf,'       =============================================================');
	writeln(lf,'                                                      Time ',time_string);
	writeln(lf);  writeln(lf);  writeln(lf);  writeln(lf);

	writeln(lf,'      =============================================================');
	writeln(lf,'         ',Version,'     INPUT  VARIABLES for  ',matlname,'     ',Date_string);
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
	writeln(lf,'       =============================================================');
	writeln(lf,'                                                      Time ',time_string);
	writeln(lf);  writeln(lf);  writeln(lf);  writeln(lf);

	Close(lf);

END; {INPUT_DATA_TO_FILE.    }

End.	{	Unit Dfmfiles	}
