{ DfmGlbls.pas	}
{ PMS 26 Nov 2020 19:00 }
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
{$IFDEF contour}		{	ensure compiler directives are consistent	}
{$DEFINE  debug}
{$ENDIF}
{$IFDEF  detail}
{$DEFINE  debug}
{$ENDIF}

{$DEFINE  debug} {	always on, pending removal of directive	}

{$R+}	{Range checking on}
{$B+}	{Boolean complete evaluation on}
{$S+}	{Stack checking on}
{$I+}	{I/O checking on}

Unit Dfmglbls;

Interface
Uses
	Crt,
	Cp437; { seems to have no effect on Crt extended ascii symbols }

CONST
	copyright = '(C) Copyright 1980,1993 P.M.Sargent & M.F.Ashby; 2020 P.M.Sargent';
	VersionDate			= '22 Nov 2020';
	Version				= 'DFM2020';
	Release				= '0.91';
	DF						= -32768;		{	Default.. for floats, longint, int	}

	avogadro				= 6.022045e23;
	boltz					= 1.380662e-23;
	R						= 8.314408694;
	pi						= 3.141592654;
	Ln10					= 2.302585093;
	numberofparameters	= 23;
	numberofvariables	= 14;
	numberofmechanisms	= 10;		{	keep consistent with E_mech	}
	parfilename			=	'matlpars.dat';
	reffilename			=	'matlrefs.dat';
	dbgfilename			=	'dfmdebug.txt';

	matl_name_length	=	9;
	parm_name_length	=	6;
	desclength			= 28;
	unitlength			= 10;
	ref_buflength	 	= 1159;	{	refchars * reflines	}
	reflines			= 19;
	refchars			= 61;

	pathlength			= 30;
	lbllength	 		= 16;
	datalabellength		= 60;
	maxcontournumber	= 20;
	max_steps			= 300;
	stash_max			= 150;
	stash_width			= 85;
	list_max				= 150;

	Gamcrit		 		= 0.9;

{	fpc does not use the extended character set #128-#255 but cp437 should do }
	CtrlC				= #3;
	Esc					= #27;
	TLC					= '+'; {#218;}
	TRC					= '+'; {#191;}
	BLC					= '+'; {#192;}
	BRC					= '+'; {#217;}
	MLC					= '+'; {#195;}
	MRC					= '+'; {#180;}
	Horiz				= '-'; {#196;}
	Vert				= '|'; {#179;}
	Under				= '_'; {#205;}

	CR					=	#13;
	LF					=	#10;
	Bksp				=	#8;
	Tab					=	#9;

{	Codes for function keys After #0 read	}
	PageUp				=	#73;
	PageDn				=	#81;
	Left				=	#75;
	Right				=	#77;
	Down				=	#80;
	Up					=	#72;

	C_text				= yellow;
	C_screen			= blue;
	C_back				= black;
	C_bright			= white;
	C_subdued			= LightGray;
	C_warn				= red;

	max_real				= 1.0e308;
	min_real				= 1.0e-324;
	max_mult				= 1.0e100;

TYPE
	a_real				=	double;
	E_dominance			=	(max_op, min_op);
	E_overall			=	(add_op, dom_op, mean_op);
	T_ops					=	RECORD
									dom : E_dominance;
									all : E_overall;
								END;
	E_mech				=	(null, S_diff, S_plc, S_glide, S_drag, re_cryst,
									b_diff, v_diff, plc_ht, plc_lt, o_glide,
									pls_drag, phn_drag, rel_drag);
	R_mech_range		=	null..rel_drag;
	T_mecharray			=	ARRAY [R_mech_range] OF a_real;
	T_mechID				=	ARRAY [R_mech_range] OF E_mech;
	T_validity			=	ARRAY [R_mech_range] OF BOOLEAN;
	T_mechset			=	SET OF E_mech;
	T_imc_classes		= (imc_error,
								fcc,
								hcp,
								bcc_alkali,
								bcc_trans,
								bcc_rare_earth,
								bcc_rotator,
								tetrag,
								trig,
								fcc_orderd,
								alkali_halides,
								metal_carbides,
								magnesia_oxides,
								thoria_oxides,
								alumina_oxides,
								rutile_oxides,
								calcites,
								diamond_elements,
								sphalerites,
								wurtzites,
								ice,
								unknown);

	T_matl_name			= String[matl_name_length];
	T_id_string			= String[parm_name_length];
	T_descstring		= String[desclength];
	T_unitstring		= String[unitlength];

	filestring			= string[pathlength];
	R_pars				= 0..numberofparameters;
	R_vbls				= 1..numberofvariables;
	R_refs				= 0..ref_buflength;
	R_lines				= 0..reflines;

	lblstring			= array[1..lbllength] of char;
	chararray			= array[1..12] of char;
	datastring			= string[datalabellength];
	timer_string		= string[12];
	pararray			= array[R_pars] of a_real;
	vblarray			= array[R_vbls] of a_real;
	refarray			= array[R_refs] of char;

CONST	{	Typed constant, i.e. variables with a default	}
	xoffset			:  integer = DF;
	xlength			:  integer = DF;
	yoffset			:  integer = DF;
	ylength			:  integer = DF;
	pointnumber		:  integer = DF;
	contournumber	:  integer = DF;
	Tcntr_number	:  integer = DF;
	steps			:  integer = DF;
	linenumber		:  integer = DF;
	numberofpoints	:  integer = DF;

	tmelt				:  a_real = DF;
	tobst				:  a_real = DF;
	shmod				:  a_real = DF;
	shtmp				:  a_real = DF;
	tprls				:  a_real = DF;
	delFl				:  a_real = DF;
	delFo				:  a_real = DF;
	atvol				:  a_real = DF;
	dovol				:  a_real = DF;
	dlbdy				:  a_real = DF;
	qvolm				:  a_real = DF;
	qbdry				:  a_real = DF;
	acdoc				:  a_real = DF;
	qcore				:  a_real = DF;
	n_crp				:  a_real = DF;
	S_crp				:  a_real = DF;
	q_crp				:  a_real = DF;
	burgv				:  a_real = DF;

	Gsize				:  a_real = DF;
	SNlast			:  a_real = DF;
	SNfirst			:  a_real = DF;
	TN				:  a_real = DF;
	TNfirst			:  a_real = DF;
	TNlast			:  a_real = DF;
	cntrfirst		:  a_real = DF;
	cntrfactor		:  a_real = DF;
	RNbottom			:  a_real = DF;
	RNtop				:  a_real = DF;
	Tcntr_high		:  a_real = DF;
	Tcntr_diff		:  a_real = DF;

	LowRate			:	a_real = DF;
	LgSN				:	a_real = DF;

{	P					:  a_real = DF;	}
	P_force2			:  a_real = DF;
	S_force2			:  a_real = DF;
	SNeff				:  a_real = DF;
	SN_T				:  a_real = DF;
	SN_crp				:  a_real = DF;
VAR
	imc				:	T_imc_classes;
	mechID			:	T_mechID;

	stash				:	ARRAY [1..stash_max] OF String[stash_width];
	stash_index		:	0..stash_max;

	matl_list		:	ARRAY [1..list_max] OF T_matl_name;
	matl_index 		:	0..list_max;
	matl_ok			:	BOOLEAN;	{	Status of material name list	}

	SpeedValue		:	REAL;
	SRcount			:	Word;

	OldExitProc		:  Pointer;  { Saves exit procedure address }
	modenamed		:  BOOLEAN;
	modefast		:  BOOLEAN;
	modedemo		:  BOOLEAN;
	modetemp		:  BOOLEAN;
	modestrate		:  BOOLEAN;
	modeindt		:  BOOLEAN;
	modelistfile	:  BOOLEAN;
	modeconcern		:  BOOLEAN;

	choice			:  char;
	answer			:  char;

	d				:	T_descstring;
	u				: 	T_unitstring;
	id				:	T_id_string;
	par				:  pararray;
	vbl				:  vblarray;
	ref				:  refarray;
	parnumber		:  R_pars;
	vblnumber		:  R_vbls;
	ref_written_lines	:	R_lines;
	matlname			:  filestring;
	listfilename	:  filestring;
	time_string		:  timer_string;
	date_string		:  timer_string;
	weekday			:	timer_string;
	datalabel		:  datastring;
	datafilename	:  filestring;
	compiler_opts	:	String;
	db				:	TEXT;		{	debug file	}

PROCEDURE MyExitProc;
{ Provides a procedure which intercepts the system exit for unplanned exit	}

PROCEDURE Finish(h: Byte);
{ A simple alternative to Halt which bypasses MyExitProc }

FUNCTION FileNotThere(name: String): BOOLEAN;

FUNCTION CannotOpen(name: String): BOOLEAN;

PROCEDURE DATE_AND_TIME;

PROCEDURE CLEAN_WINDOW;

PROCEDURE UnderLine (n: Byte);

PROCEDURE SCAN_DATA_FILE (scribble: BOOLEAN);
{	This scans the data file for the list of materials is contains.
	It is run whenever it can be slipped in without the user noticing	}

PROCEDURE GiveCommandLineHelp;

PROCEDURE HELP_1;
{ --- provides HELP at level 1 --- }

PROCEDURE WARRANTY;
{ --- provides information on GNU Public License --- }

PROCEDURE COPYING;
{ --- provides information on GNU Public License --- }

PROCEDURE HELP_2;

PROCEDURE HELP_3;

PROCEDURE INTRODUCTION;

PROCEDURE WRITE_REAL (r: a_real);
{	writes a real number in flexible format	}

PROCEDURE LABELS_FOR_PARAMETERS;

{ Sets up character strings with names of variables and their units }

PROCEDURE LABELS_FOR_VARIABLES;

{ Sets up character strings with names of variables and their units }

PROCEDURE get_imc_string(imc: T_imc_classes; var s: String);


{===========================================================================}

Implementation

Uses
	Dos,
	Printer,
	StringIO,
	Graph;

{---------------------------------------------------------------------------}
{$IFOPT F+}
PROCEDURE Finish(h: Byte);
{$ELSE}
{$F+}
PROCEDURE Finish(h: Byte);
{$F-}
{$ENDIF}
{	This should only be called when the system is in text mode, and
	never when it is in graphics mode since it does not close down
	the graphics properly.	}
{	The checking on $F+ is so that if it is set by compiler directive,
	we do not then switch it off after this procedure by accident.}
BEGIN
	ExitProc := OldExitProc; { Restore exit PROCEDURE address }

	Close (db);
	Halt(h);
END;	{	Finish	}
{---------------------------------------------------------------------------}
{$IFOPT F+}
PROCEDURE MyExitProc;
{$ELSE}
{$F+}
PROCEDURE MyExitProc;
{$F-}
{$ENDIF}

VAR
	s	:	String;
{	The checking on $F+ is so that if it is set by compiler directive,
	we do not then switch it off after this procedure by accident.}
BEGIN
	ExitProc := OldExitProc; { Restore exit PROCEDURE address }
	CloseGraph;              { Shut down the graphics system }
	{DirectVideo := True;}
	textmode(LastMode);
	Textbackground(black);
	Textcolor(white);
	IF (ErrorAddr <> NIL) THEN 	{	run-time error	}
		BEGIN

			Writeln(Version,' detected:');
			CASE ExitCode OF
				4:	s:='Too many open files: CONFIG.SYS FILES=? is too small';
				200:	s:='Division by zero';
				201:	s:='Range Check error, re-boot computer';
				202:	s:='Stack Overflow error, Contact Philip Sargent';
				205:	s:='Floating point OVERflow error, re-boot computer';
				207:	s:='Floating point invalid operation, re-boot computer';
				100..106:	s:='File read/write error';
				150..158:	s:='Critical File i/o error';
				159:		s:='Printer out of paper';
				160..162:	s:='Critical disc-drive error';
				ELSE	s:='Contact Philip Sargent, or see Turbo Pascal 5.5 Reference manual pp467-472';
			END;	{	Case	}
			WriteLn(s);
			Writeln(db,Version,' detected:');
			WriteLn(db,s);
		END;
	Close (db);

END; { MyExitProc }
{-------------------------------------------------------------------}
FUNCTION FileNotThere(name: String): BOOLEAN;
	{	See Turbo 4.0 Manual pp464-465	}
VAR
	f	:	FILE;
BEGIN
	{$I-}
	Assign(f,name);
	Reset(f);
	Close(f);
	{$I+}
	FileNotThere:= NOT ((IOResult=0) AND (name <> ''));

END;
{-------------------------------------------------------------------}
FUNCTION CannotOpen(name: String):BOOLEAN;
VAR
	f	:	TEXT;
BEGIN
	{$I-}
	Assign(f,name);
	Rewrite(f);
	
	{Reset(f); required by fpc if read access required - incmpatibility -
	https://www.freepascal.org/docs-html/current/rtl/system/rewrite.html }
	writeln(f,'...Attempting to open file:"',name,'"');
	Close(f);
	{$I+}
	writeln('...Attempting to open file:"',name,'"');
	writeln('...IOResult:',IOResult);
	writeln('...NOT ((IOResult=0) AND (name <> '')):',NOT ((IOResult=0) AND (name <> '')));
	CannotOpen:= NOT ((IOResult=0) AND (name <> ''));
END;
{-------------------------------------------------------------------}
PROCEDURE DATE_AND_TIME;

var
	hour,min,sec,sec100			: Word;
	year,month,day,day_of_week	: Word;
	hour_st,min_st,sec_st		: timer_string;
	year_st,month_st,day_st		: timer_string;

BEGIN
	GetTime(hour,min,sec,sec100);

	{Convert time and date integer values into strings, and write them}

	Str(hour,hour_st); Str(min,min_st); Str(sec,sec_st);
	IF hour < 10 THEN
		hour_st := '0'+hour_st;
	IF min < 10 THEN
		min_st := '0'+min_st;
	IF sec < 10 THEN
		sec_st := '0'+sec_st;
	time_string := hour_st+':'+min_st+'      ';

	GetDate(year, month, day, day_of_week);
	Str(year,year_st); Str(month,month_st); Str(day,day_st);

	CASE day_of_week OF
		0:	weekday := 'Sunday   ';
		1:	weekday := 'Monday   ';
		2:	weekday := 'Tuesday  ';
		3:	weekday := 'Wednesday';
		4:	weekday := 'Thursday ';
		5:	weekday := 'Friday   ';
		6:	weekday := 'Saturday ';
		ELSE
			weekday := 'Turdsday';
	END;	{	Case	}

	CASE month OF
		1:	month_st := 'Jan.';
		2:	month_st := 'Feb.';
		3:	month_st := 'Mar.';
		4:	month_st := 'Apr.';
		5:	month_st := 'May ';
		6:	month_st := 'Jun.';
		7:	month_st := 'Jul.';
		8:	month_st := 'Aug.';
		9:	month_st := 'Sep.';
		10:month_st := 'Oct.';
		11:month_st := 'Nov.';
		12:month_st := 'Dec.';
		ELSE
			month_st := 'Jog.';
	END;	{	Case	}
	date_string := day_st+' '+month_st+' '+year_st;

END;   {DATE_AND_TIME.    }

{-------------------------------------------------------------------}
PROCEDURE WRITE_REAL (r: a_real);
{	Writes a real number to the screen at the current cursor position
	using the ConvNum Unit to format the number to get the maximum
	information into the field of 10 characters, right justified.
}
VAR
	s	:	STRING;
	r2	:	REAL;
BEGIN
	r2 := r;	{	in case a_real is DOUBLE	}
	convert_number (r2, s, -1);
	write (s);
END;	{	WRITE_REAL	}
{-------------------------------------------------------------------}
PROCEDURE SCAN_DATA_FILE (scribble: BOOLEAN);
{	This scans the data file for the list of materials is contains.
	It is run whenever it can be slipped in without the user
	noticing	}
VAR
	file_in	:	Text;
	line, buf:	String;
	material	:	String;
	found		:	BOOLEAN;
	i			:	Word;
BEGIN
	IF scribble THEN
		{	restrict Window so scrolling etc. works	}
		Window(10,5,70,22);

	IF FileNotThere (parfilename) THEN
		BEGIN
			matl_index :=1;
			matl_list[1] := 'DEFAULT';
			IF scribble THEN
				Write(matl_list[1]:20);
		END
	ELSE
		BEGIN
			Assign(file_in, parfilename);
			Reset(file_in);
			matl_index :=0;
			REPEAT
				READLN(file_in, buf);
				line := buf;
				material := get_next_token(line);
				UpperCase(material);

				found := FALSE;
				FOR i := 1 TO matl_index DO
					IF (material = matl_list[i]) THEN
						found := TRUE;

				IF NOT found THEN
					BEGIN
						matl_index := matl_index + 1;
						matl_list[matl_index] := material;
						IF scribble THEN
							Write(material:20);
					END;
			UNTIL Eof(file_in);
			Close(file_in);
		END;
	matl_ok := TRUE;
	IF scribble THEN
		Window(10,1,70,25);
END;	{	SCAN_DATA_FILE	}
{-------------------------------------------------------------------}
PROCEDURE CLEAN_WINDOW;
VAR
	i	:	Word;

BEGIN
	window(1,1,80,25);     textbackground(C_screen);    clrscr;
	window(10,4,70,22);    textbackground(C_back);    	clrscr;

	window(10,1,70,25);
	textbackground(C_back);
	textcolor(C_text);
	gotoXY(1,2);
	write  ('                                                             ');
	gotoXY(1,24);
	write  ('                                                             ');

	textbackground(C_screen);
	window(1,1,80,25);

	FOR i:=2 TO 24 DO
		BEGIN
			gotoXY(9,i);
			write(Vert);
			gotoXY(71,i);
			write(Vert);
		END;

	gotoXY(9,3);
	write(MLC);
	gotoXY(71,3);
	write(MRC);
	gotoXY(9,23);
	write(MLC);
	gotoXY(71,23);
	write(MRC);

	gotoXY(9,1);
	write(TLC);
	gotoXY(71,1);
	write(TRC);
	gotoXY(9,25);
	write(BLC);
	gotoXY(71,25);
	write(BRC);

	gotoXY(10,3);
	FOR i:=10 TO 70 DO write(Horiz);
	gotoXY(10,23);
	FOR i:=10 TO 70 DO write(Horiz);
	gotoXY(10,1);
	FOR i:=10 TO 70 DO write(Horiz);
	gotoXY(10,25);
	FOR i:=10 TO 70 DO write(Horiz);

	window(10,1,70,25);
	textbackground(C_back);

END;     {CLEAN_WINDOW.    }

{---------------------------------------------------------------------------}
PROCEDURE GiveCommandLineHelp;

BEGIN
	WRITELN(' usage:  ',version,' <dataname> <options>');

	WRITELN(' e.g.    ',version,' copper /f /w:\op\copper.lst /s-');
	WRITELN;
	WRITELN(' /h /?   help and information only');
	WRITELN(' /f      fast option, no interaction with user');
	WRITELN(' /d      demonstration; as /f but waits 10s between plots');

	WRITELN(' /e      display exit codes and command line options only');
	WRITELN(' /s      options for strain-rate map:');
	WRITELN('           /s+  produce, /s- don''t produce, a strain-rate map');
	WRITELN(' /t      options for temperature map (as for /s)');
	WRITELN('           /t+  produce, /t- don''t produce, a temperature map');
	WRITELN(' /i      options for temperature map (as for /s)');
	WRITELN('           /i+  produce, /i- don''t produce, a temperature map');
	WRITELN(' /w:<fn> write a listing to a file, <fn> is a full filename');
	WRITELN;


END;	{	GiveCommandLineHelp	}
{-------------------------------------------------------------------}
PROCEDURE UnderLine (n:Byte);

VAR
	i	:	Byte;
BEGIN
	FOR i := 1 TO n DO
		Write(Under);
END;	{	UnderLine	}
{-------------------------------------------------------------------}
PROCEDURE HELP_1;

VAR
	ch	:	CHAR;
{ --- provides HELP at level 1 --- }

BEGIN

	DATE_AND_TIME;

	CLEAN_WINDOW;
	textcolor(C_subdued);

	gotoXY(1,2);
	writeln('                    HELP  SCREEN  1:1                        ');
	gotoXY(1,6);
	write  ('       '); UnderLine(45); writeln('        ');
	writeln('       M E C H A N I S M    M A P S :     ',version,'       ');
	writeln('               P. M. Sargent,   ',date_string);
	write  ('       '); UnderLine(45); writeln('        ');
	writeln;
	writeln('      This program computes Deformation Mechanism maps from ');
	writeln('  the simplified equations given in ref. [1].               ');
	writeln('      Three classes of mechanism contribute to the total    ');
	writeln('  strain: plastic yielding, power-law creep, and diffusion. ');
	writeln('  The program uses rate equations for each mechanism,       ');
	writeln('  adding the rates when appropriate.                        ');
	writeln('  The results are presented as Stress / Temperature maps, or');
	writeln('  as Strain-Rate / Stress maps.                             ');
	writeln('                                                            ');
	writeln('  [1] H.J.Frost & M.F.Ashby, "Deformation Mechanism Maps",  ');
	writeln('      Pergamon Press, Oxford, UK. (1983).                   ');

	gotoXY(1,24);  textcolor(C_text);
	write  ('                WAIT...                                      ');
	SCAN_DATA_FILE (FALSE);
	gotoXY(1,24);  textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	textcolor(C_text);

	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=CtrlC THEN Finish(0);
	textcolor(C_text);

	CLEAN_WINDOW;
	textcolor(C_subdued);

	gotoXY(1,2);
	writeln('                    HELP  SCREEN  1:2                        ');
	gotoXY(1,5);
	write('                PARAMETER AND VARIABLES                      ');
	write('                ');
		UnderLine(23); 						  writeln('                     ');
	writeln('                                                            ');
	writeln('  You start by creating a Data Set for the chosen material, ');
	writeln('  or by Reading an existing Data Set from disc.             ');
	writeln('  The data are automatically checked and suspicious values  ');
	writeln('  are flagged.                                              ');
	writeln('  The first variable on the last data page is the number of ');
	writeln('  program steps.  Choose  15  for a quick look,  100  for   ');
	writeln('  a really accurate map (it may take some time).            ');
	writeln('                                                            ');
	gotoXY(1,24);   textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	textcolor(C_text);
	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=CtrlC THEN Finish(0);
	textcolor(C_text);

END;   { HELP_1.   }
{-------------------------------------------------------------------}
PROCEDURE WARRANTY;

VAR
	ch	:	CHAR;
{ --- provides information on GNU Public License --- }

BEGIN

	DATE_AND_TIME;

	CLEAN_WINDOW;
	textcolor(C_subdued);

	gotoXY(1,2);
	writeln('                    WARRANTY                                ');
	gotoXY(1,6);
	write  ('       '); UnderLine(45); writeln('        ');
	writeln('       Section from GNU Public License (Version 2)          ');
	writeln('                                                            ');
	write  ('       '); UnderLine(45); writeln('        ');
	writeln;
	writeln('  BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS  ');
	writeln('  NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY   ');
	writeln('  APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING  ');
	writeln('  THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE    ');
	writeln('  PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER      ');
	writeln('  EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE  ');
	writeln('  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A   ');
	writeln('  PARTICULAR PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY    ');
	writeln('  AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE    ');
	writeln('  PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL       ');
	writeln('  NECESSARY SERVICING, REPAIR OR CORRECTION.                ');

	gotoXY(1,24);  textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	textcolor(C_text);

	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=CtrlC THEN Finish(0);
	textcolor(C_text);

END;   { WARRANTY.   }
{-------------------------------------------------------------------}
PROCEDURE COPYING;

VAR
	ch	:	CHAR;
{ --- provides information on GNU Public License --- }

BEGIN

	DATE_AND_TIME;

	CLEAN_WINDOW;
	textcolor(C_subdued);

	gotoXY(1,2);
	writeln('                    COPYING                                 ');
	gotoXY(1,6);
	writeln(' You may copy and distribute the Program (or a work based   ');
	writeln(' on it, under Section 2) in object code or executable form  ');
	writeln(' under the terms of Sections 1 and 2 (of the complete GNU   ');
	writeln(' Public License) provided that you also do one of the       ');
	writeln(' following:                                                 ');
	writeln(' a) Accompany it with the complete corresponding            ');
	writeln(' machine-readable source code, which must be distributed    ');
	writeln(' under the terms of Sections 1 and 2 on a medium            ');
	writeln(' customarily used for software interchange; or,             ');
	writeln(' b) Accompany it with a written offer, valid for at least   ');
	writeln(' three years, to give any third party, for a charge no      ');
	writeln(' more than your cost of physically performing source        ');
	writeln(' distribution, a complete machine -readable copy of the     ');
	writeln(' corresponding source code, to be distributed under the     ');
	writeln(' terms of Sections 1 and 2 above on a medium customarily    ');
	writeln(' used for software interchange; or,                         ');

	gotoXY(1,24);  textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                   ');
	textcolor(C_text);

	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=CtrlC THEN Finish(0);
	textcolor(C_text);


	CLEAN_WINDOW;
	textcolor(C_subdued);

	gotoXY(1,2);
	writeln('                    COPYING continued                       ');
	gotoXY(1,5);
	writeln(' c) Accompany it with the information you received as to    ');
	writeln(' the offer to distribute corresponding source code.  (This  ');
	writeln(' alternative is allowed only for noncommercial              ');
	writeln(' distribution and only if you received the program in       ');
	writeln(' object code or executable form with such an offer, in      ');
	writeln(' accord with Subsection b above.)                           ');
	writeln('                                                            ');
	write  ('       '); UnderLine(45); writeln('        ');
	writeln('       Section from GNU Public License (Version 2)          ');
	writeln('                                                            ');
	write  ('       '); UnderLine(45); writeln('        ');
	writeln('                                                            ');
	gotoXY(1,24);   textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                   ');
	textcolor(C_text);
	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=CtrlC THEN Finish(0);
	textcolor(C_text);

END;   { COPYING.   }
{-------------------------------------------------------------------}
PROCEDURE HELP_2;
VAR
	ch	:	CHAR;
BEGIN

	CLEAN_WINDOW;
	textcolor(C_subdued);

	gotoXY(1,2);
	writeln('                     HELP  SCREEN  2                         ');
	gotoXY(1,5);
	write('               CREATING AND READING DATA SETS                ');
	write('               '); UnderLine(30);    writeln('               ');
	write('                                                             ');
	write('     To be valid, a material name must have one through nine ');
	write('  characters (either letters of the alphabet or numbers      ');
	write('  0 through 9), and the special characters % - () $ & # !.   ');
	write('  Thus                                                       ');
	write('                                                             ');
	write('     COPPER     MARBLE-5     TUNGSTEN    and    PMMA#1       ');
	write('                                                             ');
	write('  are all valid names.   Do not add an "extension" (such as  ');
	write('  ".dat"). The data sets are all stored in the same file     ');
	write('  "matlpars.dat".  This file can be edited using any plain-  ');
	write('  text editor or most word-processors in non-document" mode. ');
	write('  If you do edit the data file directly, it is sensible to   ');
	write('  do this on a copy and to keep a backup of your original.   ');
	write('                                                             ');

	gotoXY(1,24);  textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	textcolor(C_text);
	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=CtrlC THEN Finish(0);
	textcolor(C_text);
	textbackground(C_screen);  gotoXY(1,24);
	write('                                                             ');

END;    {HELP_2.     }

{-------------------------------------------------------------------}
PROCEDURE HELP_3;
VAR
	ch	:	CHAR;
BEGIN

	CLEAN_WINDOW;
	textcolor(C_subdued);

	gotoXY(1,2);
	writeln('                     HELP  SCREEN  3                         ');
	gotoXY(1,5);
	write('                    Command Line Options                     ');
	write('                    ');
		UnderLine(20);                      writeln('                    ');
	write('                                                             ');

	GiveCommandLineHelp;

	gotoXY(1,24);  textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	textcolor(C_text);
	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=CtrlC THEN Finish(0);
	textcolor(C_text);
	textbackground(C_screen);  gotoXY(1,24);
	write('                                                             ');

END;    {HELP_3. }

{-------------------------------------------------------------------}
PROCEDURE INTRODUCTION;

BEGIN

	CLEAN_WINDOW;     DATE_AND_TIME;


	gotoXY(1,2);
	writeln('          ',version,'                        ',date_string);
	gotoXY(1,6);
	write  ('       '); UnderLine(46);                    writeln('      ');
	writeln('       M E C H A N I S M    M A P S :     ',version,'       ');
	writeln('               P. M. Sargent,  Cambridge University         ');
	write  ('       '); UnderLine(46);                    writeln('      ');
	writeln;  writeln;
	textcolor(C_subdued);
	writeln('   This program calculates and plots Deformation Mechanism  ');
	writeln('   Maps.  Details of the equations and of the models on     ');
	writeln('   which they are based are given in:                       ');
	writeln('   H.J.Frost & M.F.Ashby, "Deformation Mechanism Maps",     ');
	writeln('   Pergamon Press, Oxford, UK. (1983).                      ');
	writeln('   This program comes with ABSOLUTELY NO WARRANTY but you   ');
	writeln('   have the right to distribute it under certain conditions ');
	writeln('    Press   W   for details on warranty                     ');
	writeln('    Press   C   for details on redistribution conditions    ');
	writeln('    Press   H   for help, including some useful hints       ');

	gotoXY(1,24);   textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	textcolor(C_text);

	answer:=Readkey;  gotoXY(1,22);
	textcolor(C_text);
	if answer in ['h','H'] then HELP_1;
	if answer in ['c','C'] THEN
		BEGIN
			COPYING;
			WARRANTY;
			HELP_1;
		END;
	if answer in ['w','W'] THEN
		BEGIN
			WARRANTY;
			COPYING;
			HELP_1;
		END;
	if answer = CtrlC THEN
		BEGIN
			ExitProc := OldExitProc;
			Finish(0);
		END;

END;   {INTRODUCTION.     }

{-------------------------------------------------------------------}
PROCEDURE LABELS_FOR_PARAMETERS;

{ Sets up character strings with names of variables and their units }

BEGIN

	case parnumber of
	0	: BEGIN id:='IMC';   d:='IMC number                  ';  u:='          'END;
	1	: BEGIN id:='T-melt';d:='Melting Point               ';  u:='K         'END;
	2	: BEGIN id:='T-dep';	d:='T-dependence of Modulus     ';  u:='          'END;
	3	: BEGIN id:='ShrMod';d:='Shear Modulus @ 0 K         ';  u:='GPa       'END;
	4	: BEGIN id:='LatSrs';d:='0K Flow Stress (lattice)    ';  u:='          'END;
	5	: BEGIN id:='ObsSrs';d:='0K Flow Stress (obstacles)  ';  u:='          'END;
	6	: BEGIN id:='LatErg';d:='Lattice  Glide Actv. Energy ';  u:='(mu.b^3)  'END;
	7	: BEGIN id:='ObsErg';d:='Obstacle Glide Actv.Energy  ';  u:='(mu.b^3)  'END;
	8	: BEGIN id:='VolD0';	d:='Pre-exp. Volume Diffusion   ';  u:='m^2/s     'END;
	9	: BEGIN id:='VolErg';d:='Activ. energy, Vol. Diff.   ';  u:='kJ/mol    'END;
	10 : BEGIN id:='BdyD0';	d:='Pre-exp. Bdry Diffusion     ';  u:='m^3/s     'END;
	11 : BEGIN id:='BdyErg';d:='Activ. energy, Bdry. Diff.  ';  u:='kJ/mol    'END;
	12 : BEGIN id:='CorD0';	d:='Pre-exp. Core Diffusion     ';  u:='m^4/s     'END;
	13 : BEGIN id:='CorErg';d:='Activ. energy, Core  Diff.  ';  u:='kJ/mol    'END;
	14 : BEGIN id:='n-plc';	d:='Power Law Creep Exponent    ';  u:='          'END;
	15 : BEGIN id:='Srsplc';d:='Reference stress, P-L creep ';  u:='MPa       'END;
	16 : BEGIN id:='plcErg';d:='Activ. energy for P-L creep ';  u:='kJ/mol    'END;
	17 : BEGIN id:='Burgr';	d:='Burgers vector              ';  u:='m         'END;
	18 : BEGIN id:='Omega';	d:='Atomic Volume               ';  u:='m^3       'END;
	19 : BEGIN id:='Phnon';	d:='Phonon Drag Coefficient     ';  u:='          'END;
	20 : BEGIN id:='Eltrn';	d:='Electron Drag Coefficient   ';  u:='          'END;
	21 : BEGIN id:='BrkDn';	d:='Power-Law Breakdown Stress  ';  u:='          'END;
	22 : BEGIN id:='DffCt';	d:='Diffusion Cut-off Stress    ';  u:='          'END;
	23 : BEGIN id:='PhsCh';	d:='Phase Change Temperature    ';  u:='K         'END;
	END;

END;  {LABELS_FOR_PARAMETERS;    }

{-------------------------------------------------------------------}
PROCEDURE LABELS_FOR_VARIABLES;

{ Sets up character strings with names of variables and their units }

BEGIN

	CASE vblnumber OF
	1	: BEGIN id:='DfmStN'; d:='Number of Program Steps     ';  u:='          'END;
	2	: BEGIN id:='DfmGsz'; d:='Grain size                  ';  u:=' microns  'END;
	3	: BEGIN id:='DfmSy-'; d:='Lower limit, S/SY axis      ';  u:='          'END;
	4  : BEGIN id:='DfmSy+'; d:='Upper limit, S/SY axis      ';  u:='          'END;
	5  : BEGIN id:='DfmT-';  d:='Lower limit, T/TM axis      ';  u:='          'END;
	6  : BEGIN id:='DfmT+';  d:='Upper limit, T/TM axis      ';  u:='          'END;
	7  : BEGIN id:='DfmCn1'; d:='First strain-rate contour   ';  u:=' 1/s      'END;
	8  : BEGIN id:='DfmCn*'; d:='Multiplier: strain rates    ';  u:='          'END;
	9  : BEGIN id:='DfmCnN'; d:='Number strain-rate contours ';  u:='          'END;
	10 : BEGIN id:='DfmR- '; d:='Lower limit, StrainRate axis';  u:=' 1/s      'END;
	11 : BEGIN id:='DfmR+ '; d:='Upper limit, StrainRate axis';  u:=' 1/s      'END;
	12 : BEGIN id:='DfmTn1'; d:='Highest temperature contour ';  u:=' K        'END;
	13 : BEGIN id:='DfmTnD'; d:='Temperature between contours';  u:=' K        'END;
	14 : BEGIN id:='DfmTnN'; d:='Number temparature contours ';  u:='          'END;
	ELSE
		BEGIN id:='ERROR '; d:='This is unrecognised.       ';  u:='          'END;
	END;	{	Case	}
END;  {LABELS_FOR_VARIABLES;     }
{-------------------------------------------------------------------}
PROCEDURE get_imc_string(imc: T_imc_classes; var s: String);

{	This routine returns the appropriate string when given an
	isomechanical class identifier.	}

BEGIN
	CASE imc of
		fcc              : s:='fcc             ';
		bcc_alkali       : s:='bcc_alkali      ';
		bcc_trans        : s:='bcc_trans       ';
		bcc_rare_earth   : s:='bcc_rare_earth  ';
		bcc_rotator		 : s:='bcc_rotator     ';
		hcp              : s:='hcp             ';
		tetrag           : s:='tetrag          ';
		trig             : s:='trig            ';
		fcc_orderd       : s:='fcc_orderd      ';
		alkali_halides   : s:='alkali_halides  ';
		metal_carbides   : s:='metal_carbides  ';
		magnesia_oxides  : s:='magnesia_oxides ';
		thoria_oxides    : s:='thoria_oxides   ';
		alumina_oxides   : s:='alumina_oxides  ';
		rutile_oxides    : s:='rutile_oxides   ';
		calcites         : s:='calcites        ';
		diamond_elements : s:='diamond_elements';
		sphalerites      : s:='sphalerites     ';
		wurtzites        : s:='wurtzites       ';
		unknown          : s:='unknown         ';
		ice              : s:='ice             ';
		imc_error        : s:='imc_error       ';
	ELSE	BEGIN
			s:='unrecognized value';
			imc := imc_error;
		END;
	END; { of CASE }
END;      {end of get_imc_string procedure}
{-------------------------------------------------------------------}
{ Unit Initialization }
BEGIN
	compiler_opts := '';
{$IFDEF  debug}
	compiler_opts := compiler_opts+'+Debug';
{$ENDIF}
{$IFDEF  contour}	  
	compiler_opts := compiler_opts+'+Contour';
{$ENDIF}
{$IFDEF cntrfix }
	compiler_opts := compiler_opts+'+CntrFix';
{$ENDIF}
{$IFDEF  detail}
	compiler_opts := compiler_opts+'+Detail';
{$ENDIF}
{
	Writeln(Version,' v',Release,' ',VersionDate,' Compiler options:',compiler_opts);
	Writeln('       ',copyright);
	Delay(1500);
}
	{ ----- Open DEBUG file	----- }
		IF CannotOpen(dbgfilename) THEN
			BEGIN
				Writeln(' *** Cannot Open Debug File ***');
				Halt(4); 
			END
		ELSE
			BEGIN
				Assign(db,dbgfilename);
				Rewrite(db);
				Writeln(db,Version,' v',Release,' (',VersionDate,')');
				Writeln(db,'       ',copyright);
				Writeln(db,'(DFM-specific Compiler options:',compiler_opts,')');
			END;

	{ ----- Check for DATA files	----- }
	IF FileNotThere (parfilename) THEN
		BEGIN
			WriteLn('***  DATA FILE matlpars.dat CANNOT BE FOUND !  ***');
		END;
	IF FileNotThere (reffilename) THEN
		BEGIN
			WriteLn('***  DATA FILE matlrefs.dat CANNOT BE FOUND !  ***');
		END;
	IF FileNotThere (reffilename)
	OR FileNotThere (parfilename)	THEN
		Halt(4);

	FOR	parnumber := 0 to numberofparameters DO
		par[parnumber] := DF;

	FOR	vblnumber := 1 to numberofvariables DO
		vbl[vblnumber] := DF;
End.	{	Unit DfmGlbls	}
