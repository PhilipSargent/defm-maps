{ Dfmglbls.pas	}
{ PMS 28-June-1988 17:51 }

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   M.F.Ashby and P.M.Sargent        **************
   *************   June  1988                       **************
}
{$R-}    {Range checking off}
{$B+}	{Boolean complete evaluation on}
{$S+}	{Stack checking on}
{$I+}	{I/O checking on}

Unit Dfmglbls;

Interface

Uses
	Crt,
	Dos,
	Printer,
	StringIO,
	Graph;

CONST
	copyright = '(C) Copyright 1988 M.F.Ashby & P.M.Sargent';
	avogadro				= 6.022045e23;
	boltz					= 1.380662e-23;
	R						= 8.314408694;
	pi						= 3.141592654;
	Ln10					= 2.302585093;
	numberofparameters	= 18;
	numberofvariables		= 9;
	parfilename			=	'matlpars.dat';

	matl_name_length	=	9;
	parm_name_length	=	6;
	desclength			= 28;
	unitlength			= 10;

	pathlength			= 30;
	lbllength	 		= 16;
	datalabellength	= 60;
	maxcontournumber	= 20;
	max_steps			= 300;
	stash_max			= 150;
	stash_width			= 85;
	list_max				= 150;

	Gamcrit		 		= 0.9;

	Esc					= #27;
	TLC					= #218;
	TRC					= #191;
	BLC					= #192;
	BRC					= #217;
	MLC					= #195;
	MRC					= #180;

	C_text				= yellow;
	C_screen				= blue;
	C_back				= black;
	C_bright				= white;
	C_warn				= red;

	Horiz					= #196;
	Vert					= #179;

	VersionDate			= '27th June 1988';
{$IFOPT N-}
	Version				= 'DFM1s ';
	SpeedValue			= 3.28e-4;
	max_real				= 1.0e37;
	min_real				= 1.0e-37;
	max_mult				= 1.0e12;
{$ELSE}
	Version				= 'DFM1  ';
	SpeedValue			= 2.0e-4;
	max_real				= 1.0e308;
	min_real				= 1.0e-324;
	max_mult				= 1.0e100;
{$ENDIF}
	
TYPE
{$IFOPT N-}
	a_real	=	real;
{$ELSE}
	a_real	=	double;
{$ENDIF}
	T_dominance			=	(max_op, min_op);
	T_overall			=	(add_op, dom_op, mean_op);
	T_ops					=	RECORD
									dom : T_dominance;
									all : T_overall;
								END;
	T_mech				=	(null, S_diff, S_plc, S_glide, S_drag, re_cryst,
									b_diff, v_diff, plc_ht, plc_lt, o_glide,
									pls_drag, phn_drag, rel_drag);
	T_mech_range		=	null..rel_drag;
	T_mecharray			=	ARRAY [T_mech_range] OF a_real;
	T_mechID				=	ARRAY [T_mech_range] OF T_mech;
	T_validity			=	ARRAY [T_mech_range] OF BOOLEAN;
	T_mechset			=	SET OF T_mech;
	T_imc_classes		= (imc_error,
								fcc,
								hcp,
								bcc_alkali,
								bcc_trans,
								bcc_rare_earth,
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

	T_matl_name			=	String[matl_name_length];
	T_id_string			= String[parm_name_length];
	T_descstring		= String[desclength];
	T_unitstring		= String[unitlength];

	filestring			= string[pathlength];
	parrange				= 0..numberofparameters;
	vblrange				= 1..numberofvariables;

	lblstring			=	array[1..lbllength] of char;
	chararray			= array[1..12] of char;
	datastring			= string[datalabellength];
	timer_string		= string[11];
	pararray				= array[parrange] of a_real;
	vblarray				= array[vblrange] of a_real;

VAR
	imc				:	T_imc_classes;
	mechID			:	T_mechID;

	stash				:	ARRAY [1..stash_max] OF String[stash_width];
	stash_index		:	0..stash_max;

	matl_list		:	ARRAY [1..list_max] OF T_matl_name;
	matl_index		:	0..list_max;
	matl_ok			:	BOOLEAN;	{	Status of material name list	}

	stress_step		:	Word;
	xoffset			:  integer;
	xlength			:  integer;
	yoffset			:  integer;
	ylength			:  integer;
	pointnumber		:  integer;
	contournumber	:  integer;
	steps				:  integer;
	linenumber		:  integer;
	numberofpoints  :  integer;

	OldExitProc		:  Pointer;  { Saves exit procedure address }
	modenamed		:  BOOLEAN;
	modefast			:  BOOLEAN;
	modedemo			:  BOOLEAN;
	modeppic			:  BOOLEAN;
	modephpg			:  BOOLEAN;
	modetpic			:  BOOLEAN;
	modethpg			:  BOOLEAN;
	modestrs			:  BOOLEAN;
	modetemp			:  BOOLEAN;
	modelist			:  BOOLEAN;
	modelistfile	:  BOOLEAN;
	modeconcern		:  BOOLEAN;
	mode400			:  BOOLEAN;
	modeCGA			:	BOOLEAN;
	modemono			:  BOOLEAN;

	tmelt				:  a_real;
	tobst				:  a_real;
	shmod				:  a_real;
	shtmp				:  a_real;
	tprls				:  a_real;
	delFl				:  a_real;
	delFo				:  a_real;
	atvol				:  a_real;
	dovol				:  a_real;
	dlbdy				:	a_real;
	qvolm				:  a_real;
	qbdry				:  a_real;
	acdoc				:  a_real;
	qcore				:  a_real;
	n_crp				:  a_real;
	S_crp				:  a_real;
	q_crp				:  a_real;
	burgv				:  a_real;

	Gsize				:  a_real;
	SNlast			:  a_real;
	SNfirst			:  a_real;
	TNfirst			:  a_real;
	TNlast			:  a_real;
	cntrfirst		:  a_real;
	cntrfactor		:  a_real;
	LowRate			:	a_real;

	TN					:	a_real;
	LgSN				:	a_real;

	L1, L2, L3		:  a_real;
	P					:  a_real;
	DI					:  a_real;
	P_force2			:  a_real;
	S_force2			:  a_real;
	SNeff				:  a_real;
	SN_T				:  a_real;
	SN_crp			:  a_real;

	choice			:  char;
	hrdcopy			:  char;
	answer			:  char;

	d					:  T_descstring;
	u					:  T_unitstring;
	id					:	T_id_string;
	vbl				:  vblarray;
	matlname			:  filestring;
	listfilename	:  filestring;
	ppicfilename	:  filestring;
	tpicfilename	:  filestring;
	time_string		:  timer_string;
	date_string		:  timer_string;
	par				:  pararray;
	vblnumber		:  vblrange;
	datalabel		:  datastring;
	datafilename	:  filestring;
	phpgfilename	:  filestring;
	thpgfilename	:  filestring;
	parnumber		:  parrange;

	db					:	TEXT;		{	debug file	}

PROCEDURE MyExitProc;		
{ Provides a procedure which intercepts the system exit for unplanned exit	}

PROCEDURE Finish(h: Byte);
{ A simple alternative to Halt which bypasses MyExitProc }

FUNCTION FileNotThere(name: String): BOOLEAN;

FUNCTION CannotOpen(name: String): BOOLEAN;

PROCEDURE DATE_AND_TIME;

PROCEDURE CLEAN_WINDOW;

PROCEDURE SCAN_DATA_FILE (scribble: BOOLEAN);
{	This scane the data file for the list of materials is contains.
	It is run whenever it can be slipped in without the user noticing	}

PROCEDURE GiveCommandLineHelp;

PROCEDURE HELP_1;

{ --- provides HELP at level 1 --- }

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

PROCEDURE LIST_PARAMETERS;

{ -------- Prints out the material parameters as a table -------- }

PROCEDURE LIST_VARIABLES;

{ -------- Prints out the material variables as a table -------- }

{===========================================================================}

Implementation

{$F+}
{---------------------------------------------------------------------------}
PROCEDURE Finish(h: Byte);
{	This should only be called when the system is in text mode, and
	never when it is in graphics mode since it does not close down
	the graphics properly.	}
BEGIN
	ExitProc := OldExitProc; { Restore exit PROCEDURE address }
	Halt(h);
END;	{	Finish	}
{---------------------------------------------------------------------------}
PROCEDURE MyExitProc;
BEGIN
	ExitProc := OldExitProc; { Restore exit PROCEDURE address }
	CloseGraph;              { Shut down the graphics system }
	DirectVideo := True;
	textmode(LastMode);
	Textbackground(black);
	Textcolor(white);

END; { MyExitProc }
{$F-}
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
	writeln(f,'...Attempting to open file:"',name,'"');
	Close(f);
	{$I+}
	CannotOpen:= NOT ((IOResult=0) AND (name <> ''));
END;
{-------------------------------------------------------------------}
PROCEDURE DATE_AND_TIME;

var
	regs			                  :  Registers;
	hour,min,sec,frac             :  integer;
	year,month,day                :  integer;
	hour_st,min_st,sec_st,frac_st :  timer_string;
	year_st,month_st,day_st       :  timer_string;

BEGIN

	with regs do
	BEGIN
		AX := $2C00;     {2C sets current time settings in registers CX and DX}
		MsDos(regs);
		hour := hi(CX);       {CX and DX are two-byte registers:}
		min := lo(CX);
		sec := hi(DX);        {CX is bytes CH (15-8) and CL (7-0),}
		frac := lo(DX);       {DX is bytes DH (15-8) and DL (7-0).}

		AX := $2A00;     {2A sets current date settings in registers CX and DX}
		MsDos(regs);
		year := CX;           {MsDos(---) is a standard turbo PROCEDURE}
		month := hi(DX);
		day := lo(DX);
	END;

	{Convert time and date integer values into strings, and write them}

	Str(hour,hour_st); Str(min,min_st); Str(sec,sec_st); Str(frac,frac_st);
	time_string := hour_st+':'+min_st+'      ';

	Str(year,year_st); Str(month,month_st); Str(day,day_st);
	date_string := day_st+'-'+month_st+'-'+year_st;

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
{	This scane the data file for the list of materials is contains.
	It is run whenever it can be slipped in without the user
	noticing	}
VAR
	file_in	:	Text;
	line, buf:	String;
	material	:	String;
	found		:	BOOLEAN;
	i			:	Word;
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
	matl_ok := TRUE;
END;	{	SCAN_DATA_FILE	}
{-------------------------------------------------------------------}
PROCEDURE CLEAN_WINDOW;
VAR
	i	:	Word;

BEGIN
	window(1,1,80,25);     textbackground(C_screen);    clrscr;
	window(10,4,70,22);    textbackground(C_back);    clrscr;
	
	window(10,1,70,25);
	textbackground(C_back);
	gotoXY(1,2);
	write  ('                                                             ');
	gotoXY(1,24);
	write  ('                                                             ');

	IF modemono THEN
		BEGIN
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
		END;

	window(10,1,70,25);
	textcolor(C_text);
	textbackground(C_back);

END;     {CLEAN_WINDOW.    }
{-------------------------------------------------------------------}
PROCEDURE LIST_DIRECTORY(directory_name:chararray);

{ This lists the directory defined by directory_name }

type
	String20             = string[20];

var
	Regs                 : Registers;
	DTA                  : array [ 1..43 ] of Byte;
	Mask                 : chararray;
	NamR                 : String20;
	Error, I             : Integer;

BEGIN                      { main body of PROCEDURE LIST_DIRECTORY }

	FillChar(DTA,SizeOf(DTA),0);        { Initialize the DTA buffer }
	FillChar(NamR,SizeOf(NamR),0);      { Initialize the file name }
	FillChar(Mask,SizeOf(Mask),0);      { Initialize the mask }

	CLEAN_WINDOW;
	gotoXY(1,2);

	WriteLn('           THE  DIRECTORY  CURRENTLY  CONTAINS:              ');
	gotoXY(1,6);
	Regs.AX := $1A00;         { Function used to set the DTA }
	Regs.DS := Seg(DTA);      { store the parameter segment in DS }
	Regs.DX := Ofs(DTA);      {   "    "      "     offset in DX }
	MSDos(Regs);              { Set DTA location }
	Error := 0;
	Mask := directory_name;    { Search directory required }
	Regs.AX := $4E00;          { Get first directory entry }
	Regs.DS := Seg(Mask);      { Point to the file Mask }
	Regs.DX := Ofs(Mask);
	Regs.CX := 22;             { Store the option }
	MSDos(Regs);               { Execute MSDos call }
	Error := Regs.AX and $FF;  { Get Error return }
	I := 1;                    { initialize 'I' to the first element }
	if (Error = 0) then
	repeat
		NamR[I] := Chr(Mem[Seg(DTA):Ofs(DTA)+29+I]);
		I := I + 1;
	until not (NamR[I-1] in [' '..'~']) or (I>20);

	NamR[0] := Chr(I-1);          { set string length because assigning }
	delete(NamR,pos('.',NamR),4);    { by element does not set length }
	write(NamR:20);
	while (Error = 0) do BEGIN
	Error := 0;
	Regs.AX := $4F00;           { Function used to get the next }
		                          { directory entry }
	Regs.CX := 22;              { Set the file option }
	MSDos(Regs);              { Call MSDos }
	Error := Regs.AX and $FF;   { get the Error return }
	I := 1;
	repeat
		NamR[I] := Chr(Mem[Seg(DTA):Ofs(DTA)+29+I]);
		I := I + 1;
	until not (NamR[I-1] in [' '..'~'] ) or (I > 20);
	NamR[0] := Chr(I-1);
	if (Error = 0) then BEGIN
		delete(NamR,pos('.',NamR),4);
		Write(NamR:20);
	END;
	END;
END; { LIST_DIRECTORY.   }
{---------------------------------------------------------------------------}
PROCEDURE GiveCommandLineHelp;

BEGIN
	WRITELN(' usage:  ',version,' <path><dataname> <options>');
{	WRITELN(' e.g.    ',version,' \source\copper /f /w:\op\copper.lst /s- /tl:cut.pic');
}
	WRITELN(' e.g.    ',version,' \source\copper /f /w:\op\copper.lst /s-');
	WRITELN;
	WRITELN(' /h      help and information only');
	WRITELN(' /f      fast option, no interaction with user');
{	WRITELN(' /d      demonstration; as /f but waits 10s between plots');
}
	WRITELN(' /e      display exit codes only');
	WRITELN(' /s      options for stress map:');
{	WRITELN(' /sl:<fn>  produce Lotus PIC files of the stress map plot');
	WRITELN(' /sg:<fn>  produce HPGL Hewlett-Packard Graphics Language plot');
	WRITELN('         (<fn> denotes full path & filename):');
}
	WRITELN('           /s+     produce a stress map (default)');
	WRITELN('           /s-     do not produce a stress map at all');
	WRITELN(' /t      options for temperature map (as for /s)');
	WRITELN(' /w      produce a listing to the printer');
	WRITELN(' /w:<fn> sends the listing to a file instead of the printer');
	WRITELN('         (<fn> denotes full path & filename)');	
	WRITELN(' /o  /c  produces an Olivetti or CGA plot');
	WRITELN;
{	WRITELN(' In case of conflict between options,');
	WRITELN(' e.g. "/s- /sg:cuplot.hpg",');
	WRITELN(' the default is for action rather than inaction,');
	WRITELN('  so /s- would be ignored.');
}
END;	{	GiveCommandLineHelp	}
{-------------------------------------------------------------------}
PROCEDURE HELP_1;

VAR
	ch	:	CHAR;
{ --- provides HELP at level 1 --- }

BEGIN

	DATE_AND_TIME;

	CLEAN_WINDOW;
	LowVideo;

	gotoXY(1,2);
	writeln('                    HELP  SCREEN  1:1                        ');
	gotoXY(1,6);
	writeln('       M E C H A N I S M    M A P S :     ',version,'       ');
	writeln('               P. M. Sargent,   ',date_string,'             ');
	writeln('       =============================================        ');
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
	gotoXY(1,24);  textcolor(C_bright);

	SCAN_DATA_FILE (FALSE);

	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	NormVideo;
	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=Esc THEN Finish(0);
	textcolor(C_text);

	CLEAN_WINDOW;
	LowVideo;

	gotoXY(1,2);
	writeln('                    HELP  SCREEN  1:2                        ');
	gotoXY(1,5);
	write('                PARAMETER AND VARIABLES FILES                ');
	write('                =============================                ');
	writeln('                                                            ');
	writeln('  You start by creating a Data Set for the chosen material, ');
	writeln('  or by Reading an existing Data Set from disc.             ');
	writeln('  The data are automatically checked and suspicious values  ');
	writeln('  are flagged.                                              ');
	writeln('  The first parameter on the second page is the number of   ');
	writeln('  program steps.  Choose  15  for a quick look,  100  for   ');
	writeln('  a really accurate map (it may take some time).            ');
	writeln('                                                            ');
	gotoXY(1,24);   textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	NormVideo;
	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=Esc THEN Finish(0);
	textcolor(C_text);

	CLEAN_WINDOW;
	LowVideo;

	gotoXY(1,2);
	writeln('                    HELP  SCREEN  1:3                        ');
	gotoXY(1,5);
	write('                PRINTING PLOTS ON A PRINTER                  ');
	write('                ===========================                  ');
	writeln('                                                            ');
	writeln('     Remember: run GRAPHICS  BEFORE running ',Version,' if  ');
	writeln('  you want to dump the plot to a dot-matrix or laser        ');
	writeln('  printer.  Do this by running the program GRAPHICS.COM     ');
	writeln('  supplied with the MS-DOS operating system which came with ');
	writeln('  your computer, or try the copy on this disc.              ');
	writeln('                                                            ');
	writeln('     You can get a hard copy of the screen by pressing the  ');
	writeln('  <PRT SCR> key when the plot has finished and is labelled  ');
	writeln('  on the screen.  This key may require the SHIFT key to be  ');
	writeln('  pressed to be effective.                                  ');
	writeln('                                                            ');
	writeln('     Users of PS/2 and machines with EGA graphics adapters  ');
	writeln('  may need to run the program with the /c option to get     ');
	writeln('  the lower resolution graphics: e.g. type "',Version,' /c" to ');
	writeln('  run the mapping program.                                  ');
	gotoXY(1,24);   textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	NormVideo;
	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=Esc THEN Finish(0);
	textcolor(C_text);

	CLEAN_WINDOW;
	LowVideo;

	gotoXY(1,2);
	writeln('                    HELP  SCREEN  1:4                        ');
	gotoXY(1,5);
	write('                PRINTING PLOTS ON A PRINTER (Cont.)          ');
	write('                ===================================          ');
	writeln('                                                            ');
	writeln('     If you have an Olivetti or AT&T computer then you can  ');
	writeln('  get higher resolution plots on the screen by using the /o ');
	writeln('  option when you run the program, e.g. "',Version,' /o" .  ');
	writeln('  (This may also work with some Compaq computers.)          ');
	writeln('                                                            ');
	writeln('     If you want to do screen dumps of these plots your     ');
	writeln('  will need to read your MS-DOS documentation of the        ');
	writeln('  GRAPHICS command very carefully.                          ');
	writeln('                                                            ');
	writeln('     If you have a HERCULES graphics adapter then the       ');
	writeln('  appropriate screen dump program is HGC.COM, instead of    ');
	writeln('  graphics.com.                                             ');
	gotoXY(1,24);   textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	NormVideo;
	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=Esc THEN Finish(0);
	textcolor(C_text);

END;   { HELP_1.   }

{-------------------------------------------------------------------}
PROCEDURE HELP_2;
VAR
	ch	:	CHAR;
BEGIN

	CLEAN_WINDOW;
	LowVideo;

	gotoXY(1,2);
	writeln('                     HELP  SCREEN  2                         ');
	gotoXY(1,5);
	write('               CREATING AND READING DATA SETS                ');
	write('               ==============================                ');
	write('                                                             ');
	write('     To be legal, a material name must have one through nine ');
	write('  characters (either letters of the alphabet or numbers      ');
	write('  0 through 9), and the special characters % - () $ & # !.   ');
	write('  Thus                                                       ');
	write('                                                             ');
	write('     COPPER     MARBLE-5     TUNGSTEN    and    PMMA#1       ');
	write('                                                             ');
	write('  are all legal names.   Do not add an "extension" (such as  ');
	write('  ".dat"). The data sets are all stored in the same file     ');
	write('  "matlpars.dat".  This file can be edited using any plain-  ');
	write('  text editor or most word-processors in non-document" mode. ');
	write('  If you do edit the data file directly, it is sensible to   ');
	write('  do this on a copy and to keep a backup of your original.   ');
	write('                                                             ');

	gotoXY(1,24);  textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	NormVideo;
	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=Esc THEN Finish(0);
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
	LowVideo;

	gotoXY(1,2);
	writeln('                     HELP  SCREEN  3                         ');
	gotoXY(1,5);
	write('                    Command Line Options                     ');
	write('                    ====================                     ');
	write('                                                             ');

	GiveCommandLineHelp;

	gotoXY(1,24);  textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	NormVideo;
	repeat until keypressed;
	Ch:=ReadKey;
	If Ch=Esc THEN Finish(0);
	textcolor(C_text);
	textbackground(C_screen);  gotoXY(1,24);
	write('                                                             ');

END;    {HELP_3. }
{-------------------------------------------------------------------}
PROCEDURE INTRODUCTION;

BEGIN

	CLEAN_WINDOW;     DATE_AND_TIME;
	

	gotoXY(1,2);
	writeln('          ',version,'                        ',
		date_string,'            ');
	gotoXY(1,6);
	writeln('       ==============================================       ');
	writeln('       M E C H A N I S M    M A P S :     ',version,'       ');
	writeln('               P. M. Sargent,  Cambridge University         ');
	writeln('       ==============================================       ');
	writeln;  writeln;
	LowVideo;
	writeln('   This program calculates and plots Deformation Mechanism  ');
	writeln('   Maps.  Details of the equations and of the models on     ');
	writeln('   which they are based are given in:                       ');
	writeln('                                                            ');
	writeln('   1.  H.J.Frost & M.F.Ashby, "Deformation Mechanism Maps", ');
	writeln('         Pergamon Press, Oxford, UK. (1983).                ');
	writeln('                                                            ');
	writeln('                                                            ');
	writeln('                                                            ');
	writeln('    Press   H   for help, including some useful hints       ');

	gotoXY(1,24);   textcolor(C_bright);
	write  ('                PRESS ANY KEY TO CONTINUE                    ');
	NormVideo;

	answer:=Readkey;  gotoXY(1,22);
	textcolor(C_text);
	if answer in ['h','H'] then HELP_1;
	if answer = Esc then Finish(0);

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
	END;

END;  {LABELS_FOR_PARAMETERS;    }

{-------------------------------------------------------------------}
PROCEDURE LABELS_FOR_VARIABLES;

{ Sets up character strings with names of variables and their units }

BEGIN

	case vblnumber of
	1	: BEGIN id:='DfmStN'; d:='Number of Program Steps     ';  u:='          'END;
	2	: BEGIN id:='DfmGsz'; d:='Grain size                  ';  u:='m         'END;
	3	: BEGIN id:='DfmSy-'; d:='Lower limit, S/SY axis      ';  u:='          'END;
	4  : BEGIN id:='DfmSy+'; d:='Upper limit, S/SY axis      ';  u:='          'END;
	5  : BEGIN id:='DfmT-';  d:='Lower limit, T/TM axis      ';  u:='          'END;
	6  : BEGIN id:='DfmT+';  d:='Upper limit, T/TM axis      ';  u:='          'END;
	7  : BEGIN id:='DfmCn1'; d:='First strain-rate contour   ';  u:='1/s       'END;
	8  : BEGIN id:='DfmCn*'; d:='Multiplier: strain rates    ';  u:='          'END;
	9  : BEGIN id:='DfmCnN'; d:='Number strain-rate contours ';  u:='          'END;
	END;
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
PROCEDURE LIST_PARAMETERS;

{ -------- Prints out the material parameters as a table -------- }
VAR
	s	:	String;
BEGIN

	CLEAN_WINDOW;
	DATE_AND_TIME;

	gotoXY(1,2);
	textbackground(C_back);
	write('                                                             ');
	gotoXY(1,2);
	writeln(' ',Version,'       INPUT PARAMETERS FOR   ',matlname,'     ',
		Date_string);

	get_imc_string (imc,s);
	gotoXY(1,4);
	write ('    0   Isomechanical Class:');
	GotoXY(43,4);
	Writeln(s);

	for parnumber := 1 to numberofparameters do BEGIN

	LABELS_FOR_PARAMETERS;

	write ('  ',parnumber:3,'   ', d, u,' =');
	WRITE_REAL (par[parnumber]);
	writeln;
	END;

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
	writeln(' ',Version,'      INPUT VARIABLES FOR   ',matlname,'      ',
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

End.	{	Unit DfmGlbls	}
