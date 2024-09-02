Unit DfmEdits;
{ PMS 01-December-2020 18:29:44 }
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

PROCEDURE LIMIT_VARIABLES;

PROCEDURE NUMBER_FOR_PARAMETER (VAR number: Integer; ck: String);
{	Finds the parameter number given a parameter id	}

PROCEDURE NUMBER_FOR_VARIABLE (VAR number: Integer; ck: String);
{	Finds the variable number given a variable id	}

PROCEDURE SET_PARAMETERS (n: R_pars; VAR L,m,h: a_real);
PROCEDURE SET_VARIABLES  (n: R_vbls; VAR L,m,h: a_real);

FUNCTION GET_IMC(par_0: a_real): T_imc_classes;

PROCEDURE MAKE_PARAMETER_SET;
PROCEDURE MAKE_VARIABLE_SET;
PROCEDURE MAKE_REFERENCE_SET;
{ -- Creates a new set of reference info. -- }

PROCEDURE EDIT_PARAMETERS;
PROCEDURE EDIT_VARIABLES;
PROCEDURE EDIT_REFERENCES;


{===================================================================}

Implementation

Uses
	Crt,
	Dos,
	Printer,
	stringIO,
	DfmFiles;
	
CONST
	last_page1_parameter = 16;
TYPE
	T_page	=	(First, Second);
	a_real	=	double; {DUPLICATED because fpc has declaration conflict issue}
VAR
	escape		:	BOOLEAN;


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
		9 	: BEGIN L := 2;		m := 10;		h := maxcontournumber	END;
		10	: BEGIN L := 1e-14;	m := 1e-9;		h := 1.0e4		END;
		11	: BEGIN L := 1e-6;	m := 1e-4;		h := 1.0e4		END;
		12	: BEGIN L := 1;		m := par[1];	h := par[1]		END;
		13	: BEGIN L := 1;		m := 100;		h := par[1]		END;
		14	: BEGIN L := 2;		m := 10;			h := maxcontournumber	END;
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
	IF (vbl[2]  <  1.0E-4)			THEN vbl[2]	:= 1.0E-4; {i.e. 1e-10 meters}
	IF (vbl[2]  >  1.0E+4)			THEN vbl[2]	:= 1.0E+4;
	IF (vbl[3]  >  0.9*vbl[4])		THEN vbl[3]	:= 0.9*vbl[4];
	IF (vbl[5] >  vbl[6]-0.1)		THEN vbl[5]  := vbl[6]-0.1;
	IF (vbl[9] >  maxcontournumber)	THEN vbl[9]  := maxcontournumber;
	IF (vbl[14] >  maxcontournumber)	THEN vbl[14]  := maxcontournumber;
	IF (vbl[9] <  1)	THEN vbl[9]  := 1;
	IF (vbl[14] <  1)	THEN vbl[14]  := 1;

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
FUNCTION GET_IMC(par_0: a_real): T_imc_classes;
VAR
	imc	:	T_imc_classes;
BEGIN
	IF (par_0 > 100) OR (par_0 < 0) THEN
		imc := imc_error
	ELSE
		CASE round (par_0) OF
			-1:					imc := imc_error;
			1, 10:				imc := bcc_trans;		{	default metal	}
			2, 20:				imc := fcc_orderd;		{	default intermetallic	}
			3, 30:				imc := alumina_oxides;	{	default oxide	}
			4, 40:				imc := sphalerites;		{	default ceramic	}
			5, 50:				imc := ice;				{	default molecular compound	}
			6..9:				imc := imc_error;
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
	GET_IMC := imc;
END;	{	GET_IMC	}
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
	FOR index := 1 to ref_buflength DO
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
	REPEAT 
		Prompt_Edit;
	UNTIL	(answer in ['y','Y','n','N']);


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
PROCEDURE TEXT_EDIT_REFERENCE;

CONST
{	Codes for function keys After #0 read	}
	Home					=	#71;
	EndCh					=	#79;
	Ins					=	#82;
	Del					=	#83;
	AltD					=	#32;
	AltQ					=	#16;
	AltW					=	#17;
	CtrlPgUp				=	#132;
	CtrlPgDn				=	#118;

{	Codes invented just for this editor	}
	GoLeft	=	#200;
	GoRight	=	#201;
	GoDown	=	#202;
	GoUp		=	#203;
	GoHome	=	#204;
	GoEnd		=	#205;
	DoIns		=	#206;
	DoDel		=	#207;
	DoLnDel	=	#208;
	GoFirst	=	#209;
	GoLast	=	#210;
	WindUp	=	#211;

	r61		=	refchars;
	r1159		=	ref_buflength;

VAR
	x,y	:	Byte;
	ch		:	Char;
	i,index,last	:	R_refs;
	linenumber		:	R_lines;
	charnumber		:	0..refchars;
	text_present	:	BOOLEAN;


BEGIN
	Textbackground(C_back);
	gotoXY(1,24);  textcolor(C_bright);
	write ('                                                             ');
	gotoXY(1,24);
	write ('  Use the cursor keys,     Finish with "Alt-W".    ');
	textcolor(C_text);
	{	restrict Window so scrolling etc. works	}
	window(10,4,70,22);

	gotoXY(1,1);
	index := 1;

	REPEAT
		IF index + 1 < r1159 THEN	{	skip forbidden last position	}
			index := index + 1;		{	INCREMENTED here	}
		answer:=Readkey;
		IF (answer=CtrlC) {ctrl-C, ctrl-Break is disabled} THEN
			Finish(0);
		IF (answer = #0 ) THEN	{ function key }
			BEGIN
				answer := Readkey;		{	Gets AltD and AltW too	}

				CASE answer OF
					Left	:	answer := GoLeft;
					Right	:	answer := GoRight;
					Down	:	answer := GoDown;
					Up		:	answer := GoUp;
					Home	:	answer := GoHome;
					EndCh	:	answer := GoEnd;
					CtrlPgUp		:	answer := GoFirst;
					CtrlPgDn		:	answer := GoLast;
					Ins	:	answer := DoIns;
					Del	:	answer := DoDel;
					AltD	:	answer := DoLnDel;
					AltW,AltQ	:	answer := WindUp;
				ELSE
								answer := GoRight;	{	default action	}
				END;	{	Case	}
			END;

		CASE answer OF
			Tab
					:	BEGIN
							index := (index + 3) MOD r1159;
						END;
			Bksp
					:	BEGIN
							IF index > 2 THEN	{	already incremented once	}
								BEGIN
									ref[index - 1] := ' ';
									index := index - 2
								END;
						END;
			GoLeft, ^S
					:	BEGIN
							Dec(index);		{	take off increment	}
							IF index > 1 THEN
								Dec(index);
						END;
			GoDown, ^X
					:	BEGIN
							Dec(index);		{	take off increment	}
							index := (index + r61) MOD r1159;
						END;
			GoRight, ^D : ;	{	null, does this anyway	}
			GoUp, ^E
					:	BEGIN
							Dec(index);		{	take off increment	}
							index := (index + r1159 - r61) MOD r1159;
						END;
			GoHome, ^A:	BEGIN
							Dec(index);		{	take off increment	}
							IF ((index MOD r61) <> 0) THEN
								index :=  1 + r61*(index DIV r61)
							ELSE
								index := (index + r1159 - r61 +1) MOD r1159;
						END;
			GoEnd, ^F:	BEGIN
							Dec(index);		{	take off increment	}
							IF ((index MOD r61) <> 0) THEN
								index :=  r61*( 1 + (index DIV r61));
						END;
			GoFirst:	index :=  1;
			GoLast:	index :=  r1159 - 1;
			DoIns:	BEGIN
							index :=  1 + r61*(index DIV r61);
							FOR i := r1159 DOWNTO index+r61 DO
								ref[i] := ref[i-r61];
							FOR i := index TO index+r61-1 DO
								ref[i] := ' ';
							InsLine;
						END;
			^Y, DoLnDel:
						BEGIN
							index :=  1 + r61*(index DIV r61);
							FOR i := index TO r1159 - r61 DO
								ref[i] := ref[i+r61];
							FOR i := r1159 DOWNTO r1159 - r61 + 1 DO
								ref[i] := ' ';
							DelLine;
						END;
			DoDel, ^G:	BEGIN	{	scrolls back only on current line	}
							Dec(index);		{	take off increment	}
							last := r61*( 1 + (index DIV r61));
							FOR i := index TO last-1 DO
								BEGIN
									ref[i] := ref[i+1];
									write(ref[i]);
								END;
							ref[last] := ' ';
							IF (last <> r1159) THEN
								write(ref[last]);
						END;
			#32..#126	:	BEGIN
									Dec(index);		{	take off increment	}
									ref[index] := answer;
									write(ref[index]);
									Inc(index);
								END;
			CR: 
						BEGIN
						{	GoDown..	}
							Dec(index);		{	take off increment	}
							index := (index + r61) MOD r1159;
						{	GoHome..	}
							IF (index > 1) THEN
								Dec(index);
							index :=  1 + r61*(index DIV r61);
						END;

			ELSE		{	recover from an erroneous increment	}
						IF index > 1 THEN
							index := index - 1
		END;	{	Case	}

		IF index >= r1159 THEN	{	skip forbidden last position	}
			index := r1159-1;
		IF index <= 0 THEN			{	fix forbidden position	}
			index := r1159-1;
		ref[r1159] := ' ';	{	just to be sure	}

		charnumber := index MOD r61;
		linenumber := index DIV r61;
		IF (charnumber = 0) THEN
			charnumber := r61
		ELSE
			Inc(linenumber);
		gotoXY(charnumber ,linenumber);

	UNTIL (answer = WindUp);
	window(10,1,70,25);

{	find how many non-blank lines there are	}
	linenumber := reflines;
	text_present := FALSE;
	REPEAT
		Dec(linenumber);
		FOR i:= 1 TO r61 DO
			IF (ref[linenumber*r61+i] <> ' ') THEN
				text_present := TRUE;
	UNTIL (linenumber <= 0) OR text_present;
	ref_written := linenumber;

END;	{	TEXT_EDIT_REFERENCE	}
{-------------------------------------------------------------------}
PROCEDURE EDIT_REFERENCES;

BEGIN
	LIST_REFERENCES;
	REPEAT 
		Prompt_Edit;
	UNTIL	(answer in ['y','Y','n','N']);

	if answer in ['y','Y'] then
		BEGIN
			REPEAT
				TEXT_EDIT_REFERENCE;
				LIST_REFERENCES;			{	just in case the display gets wrong..}
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
	textcolor(C_text);
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

	FillChar(ref,SizeOf(ref),' ');
	TEXT_EDIT_REFERENCE;

{ ------- DON'T List the file for inspection and Editing, & Saving ------- }
	Prompt_Save;
	IF answer in ['y','Y'] then SAVE_MATL_REFERENCES;

END; {MAKE_REFERENCE_SET.   }
{-------------------------------------------------------------------}
End.	{	Unit DfmEdits	}

