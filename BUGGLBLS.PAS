{ BUGglbls.pas	}
{ PMS 19-April-1988 18:34 }

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   M.F.Ashby and P.M.Sargent        **************
   *************   April 1988                       **************
}
{$R-}    {Range checking off}
{$B+}	{Boolean complete evaluation on}
{$S+}	{Stack checking on}
{$I+}	{I/O checking on}

Unit BUGglbls;

Interface

Uses
	Crt,
	Dos,
	Printer,
	Graph;

CONST
	copyright = '(C) Copyright 1988 M.F.Ashby & P.M.Sargent';
	boltz					= 1.380662e-23;
	R						= 8.314408694;
	pi						= 3.141592654;
	Ln10					= 2.302585093;
	stringlength 		= 10;
	numberofparameters	= 17;
	numberofvariables		= 17;
	numberofmechanisms	= 4;
	desclength			= 28;
	unitlength			= 10;
	pathlength			= 30;
	avogadro				= 6.02e23;
	lbllength	 		= 16;
	Gamcrit		 		= 0.9;
	datalabellength	= 60;
	maxcontournumber	= 10;

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
{$IFOPT N-}
	Version				= 'DFM1s ';
	SpeedValue			= 3.28e-4;
{$ELSE}
	Version				= 'DFM1  ';
	SpeedValue			= 2.0e-4;
{$ENDIF}

TYPE
{$IFOPT N-}
	a_real	=	real;
{$ELSE}
	a_real	=	double;
{$ENDIF}
	filestring			= string[pathlength];
	parrange				= 1..numberofparameters;
	vblrange				= 1..numberofvariables;
	stringarray			= string[stringlength];
	descstring			= array[1..desclength] of char;
	unitstring			= array[1..unitlength] of char;
	lblstring				= array[1..lbllength] of char;
	chararray				= array[1..12] of char;
	datastring			= string[datalabellength];
	timer_string			= string[11];
	pararray				= array[parrange] of a_real;
	vblarray				= array[vblrange] of a_real;
	ratearray				= array[0..numberofmechanisms] of a_real;
	coordinatearray		= array[0..numberofmechanisms] of a_real;
	contourarray			= array[0..maxcontournumber] of a_real;

VAR
	I					:  integer;
	K					:  integer;
	coord1			:  integer;
	xoffset			:  integer;
	xlength			:  integer;
	index				:  integer;
	pointnumber		:  integer;
	contournumber	:  integer;
	J					:  integer;
	steps				:  integer;
	coord2			:  integer;
	yoffset			:  integer;
	ylength			:  integer;
	linenumber		:  integer;
	numberofpoints  :  integer;
	maptype			:  integer;
	flag				:  integer;
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
	modemono			:  BOOLEAN;

	tmelt				:  a_real;
	tobst				:  a_real;
	shmod				:  a_real;
	shtmp				:  a_real;
	tprls				:  a_real;
	del_f				:  a_real;
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
	Sfixed			:  a_real;
	SNlast			:  a_real;
	SNfirst			:  a_real;
	TNfirst			:  a_real;
	TNlast			:  a_real;
	cntrfirst		:  a_real;
	cntrfactor		:  a_real;

	TN					:	a_real;
	LgSN				:	a_real;

	L1, L2			:  a_real;
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
	d					:  descstring;
	title				:  stringarray;
	vbl				:  vblarray;
	filename			:  filestring;
	parfilename		:  filestring;
	listfilename	:  filestring;
	ppicfilename	:  filestring;
	tpicfilename	:  filestring;
	vblfilename		:  filestring;
	time_string		:  timer_string;
	date_string		:  timer_string;
	sumofI, sumofJ	:  coordinatearray;
	u					:  unitstring;
	par				:  pararray;
	vblnumber		:  vblrange;
	contour			:  contourarray;
	datalabel		:  datastring;
	datafilename	:  filestring;
	phpgfilename	:  filestring;
	thpgfilename	:  filestring;
	parnumber		:  parrange;
	pointcount		:  coordinatearray;

	db					:	TEXT;		{	debug file	}

PROCEDURE MyExitProc;		
{ Provides a procedure which intercepts the system exit for unplanned exit	}

PROCEDURE Finish(h: Byte);
{ A simple alternative to Halt which bypasses MyExitProc }

FUNCTION FileNotThere(name: String): BOOLEAN;

FUNCTION CannotOpen(name: String): BOOLEAN;

PROCEDURE DATE_AND_TIME;

PROCEDURE CLEAN_WINDOW;

Procedure LIST_DIRECTORY(directory_name:chararray);

{ This lists the directory defined by directory_name }

PROCEDURE GiveCommandLineHelp;

PROCEDURE HELP_1;

{ --- provides HELP at level 1 --- }

PROCEDURE HELP_2;

PROCEDURE HELP_3;

PROCEDURE INTRODUCTION;

PROCEDURE LABELS_FOR_DATA;

{ Sets up character strings with names of variables and their units }

PROCEDURE LABELS_FOR_VARIABLES;

{ Sets up character strings with names of variables and their units }

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
PROCEDURE CLEAN_WINDOW_TOP;

BEGIN
	CLEAN_WINDOW;
	window(1,24,80,25);    textbackground(C_screen);    clrscr;

	window(1,1,80,25);     
	textcolor(C_text);
	gotoXY(9,23);
	write(BLC);
	gotoXY(71,23);
	write(BRC);

	window(10,1,70,25);
	textcolor(C_text);
	textbackground(C_back);   
	
END;	{	CLEAN_WINDOW_TOP	}
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
	WRITELN('usage:  ',version,' <path><dataname> <options>');
{	WRITELN('e.g.    ',version,' \source\copper /f /w:\op\copper.lst /s- /tl:cut.pic');
}
	WRITELN('e.g.    ',version,' \source\copper /f /w:\op\copper.lst /s-');
	WRITELN;
	WRITELN('/h      help and information only');
	WRITELN('/f      fast option, no interaction with user');
{	WRITELN('/d      demonstration; as /f but waits 10s between plots');
}
	WRITELN('/e      display exit codes only');
	WRITELN('/s      options for stress map:');
{	WRITELN('        (<fn> denotes full path & filename):');
	WRITELN('/sl:<fn>  produce Lotus PIC files of the stress map plot');
	WRITELN('/sg:<fn>  produce HPGL Hewlett-Packard Graphics Language plot');
}
	WRITELN('          /s+     produce a stress map (default)');
	WRITELN('          /s-     do not produce a stress map at all');
	WRITELN('/t      options for temperature map (as for /s)');
	WRITELN('/w      produce a listing to the printer');
	WRITELN('/w:<fn> sends the listing to a file instead of the printer');
	WRITELN('        (<fn> denotes full path & filename)');
	WRITELN;
{	WRITELN('In case of conflict between options,');
	WRITELN('e.g. "/s- /sg:cuplot.hpg",');
	WRITELN('the default is for action rather than inaction,');
	WRITELN('so /s- would be ignored.');
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
	writeln('  the simplified equations given in ref. [1].  	            ');
	writeln('      Three classes of mechanism contribute to the total    ');
	writeln('  strain: plastic yielding, power-law creep, and diffusion. ');
	writeln('  The program uses rate equations for each mechanism,       ');
	writeln('  adding the rates when appropriate. ');
	writeln('  The results are presented as Stress / Temperature maps, or');
	writeln('  as Strain-Rate / Stress maps.                             ');
	writeln('                                                            ');
	writeln('  [1] H.J.Frost & M.F.Ashby, "Deformation Mechanism Maps",  ');
	writeln('      Pergamon Press, Oxford, UK. (1983).                   ');
	gotoXY(1,24);  textcolor(C_bright);
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
	gotoXY(1,7);
	writeln('     You start by creating a Parameter (.p ) file and a     ');
	writeln('  Data (.v ) file for the chosen material, or by Reading    ');
	writeln('  one from disk if the files already exist.  The data are   ');
	writeln('  automatically checked and suspicious values are flagged.  ');
	writeln('  The last parameter in the set is the number of program    ');
	writeln('  steps.  Choose  15  for a quick look,  100  for a really  ');
	writeln('  accurate map (it may take some time).                     ');
	writeln('                                                            ');
	writeln('     Remember: load GRAPHICS before loading ',Version,' if  ');
	writeln('  you want to dump the plot to the line-printer.            ');
	writeln('                                                            ');
	writeln('     You can get a hard copy of this by pressing (CAPS) and ');
	writeln('   (PRTSC) at the same time.                                ');
	writeln('                                                            ');
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
	write('               CREATING AND READING A FILES.                 ');
	write('               =============================                 ');
	write('                                                             ');
	write('     To be legal, a file name must have one through eight    ');
	write('  characters (either letters of the alphabet or numbers      ');
	write('  0 through 9), and the special characters % - () $ & # !.   ');
	write('  Thus                                                       ');
	write('                                                             ');
	write('     COPPER     MARBLE-5     TUNGSTEN    and    PMMA#1       ');
	write('                                                             ');
	write('  are all legal names.   Do not add an extension:  the       ');
	write('  automatically adds  .p    to parameter files, and  .v      ');
	write('  to data files.  You can find out which files already       ');
	write('  exist by typing  DIR *.p    in DOS, or  alt-F D followed   ');
	write('  by *.p   in Turbo4. Be careful when entering a file name   ');
	write('  to be Read, a file name which does not exist will not be   ');
	write('  accepted.                                                  ');

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
PROCEDURE LABELS_FOR_DATA;

{ Sets up character strings with names of variables and their units }

BEGIN

	case parnumber of
	1 : BEGIN d:='Melting Point               ';  u:='K         'END;
	2 : BEGIN d:='0K Flow Stress (obstacles)  ';  u:='          'END;
	3 : BEGIN d:='Shear Modulus               ';  u:='GPa       'END;
	4 : BEGIN d:='T-dependence of Modulus     ';  u:='          'END;
	5 : BEGIN d:='0K Flow Stress (lattice)    ';  u:='          'END;
	6 : BEGIN d:='Lattice Glide Actv. Energy  ';  u:='          'END;
	7 : BEGIN d:='Atomic Volume               ';  u:='m^3       'END;
	8 : BEGIN d:='Pre-exp. Volume Diffusion   ';  u:='m^2/s     'END;
	9 : BEGIN d:='Activ. energy, Vol. Diff.   ';  u:='kJ/mol    'END;
	10 : BEGIN d:='Pre-exp. Bdry Diffusion     ';  u:='m^3/s     'END;
	11 : BEGIN d:='Activ. energy, Bdry. Diff.  ';  u:='kJ/mol    'END;
	12 : BEGIN d:='Pre-exp. Core Diffusion     ';  u:='m^4/s     'END;
	13 : BEGIN d:='Activ. energy, Core  Diff.  ';  u:='kJ/mol    'END;
	14 : BEGIN d:='Power Law Creep Exponent    ';  u:='          'END;
	15 : BEGIN d:='Reference stress, P-L creep ';  u:='MPa       'END;
	16 : BEGIN d:='Activ. energy for P-L creep ';  u:='kJ/mol    'END;
	17 : BEGIN d:='Burgers vector              ';  u:='m         'END;
	END;

END;  {LABELS_FOR_DATA;    }

{-------------------------------------------------------------------}
PROCEDURE LABELS_FOR_VARIABLES;

{ Sets up character strings with names of variables and their units }

BEGIN

	case vblnumber of
	1 : BEGIN d:='IMC number                  ';  u:='          'END;
	2 : BEGIN d:='  <...unused...>            ';  u:='          'END;
	3 : BEGIN d:='  <...unused...>            ';  u:='          'END;
	4 : BEGIN d:='  <...unused...>            ';  u:='          'END;
	5 : BEGIN d:='Grain size                  ';  u:='m         'END;
	6 : BEGIN d:='  <...unused...>            ';  u:='          'END;
	7 : BEGIN d:='  <...unused...>            ';  u:='          'END;
	8 : BEGIN d:='Fixed Stress                ';  u:='MPa       'END;
	9 : BEGIN d:='Lower limit, S/SY axis      ';  u:='          'END;
	10 : BEGIN d:='Upper limit, S/SY axis      ';  u:='          'END;
	11 : BEGIN d:='  <...unused...>            ';  u:='          'END;
	12 : BEGIN d:='Lower limit, T/TM axis      ';  u:='          'END;
	13 : BEGIN d:='Upper limit, T/TM axis      ';  u:='          'END;
	14 : BEGIN d:='First strain-rate contour   ';  u:='1/s       'END;
	15 : BEGIN d:='Multiplier: strain rates    ';  u:='          'END;
	16 : BEGIN d:='Number strain-rate contours ';  u:='          'END;
	17 : BEGIN d:='Number of Program Steps     ';  u:='          'END;
	END;

END;  {LABELS_FOR_VARIABLES;     }

{-------------------------------------------------------------------}
PROCEDURE LIST_PARAMETERS;

{ -------- Prints out the material parameters as a table -------- }

BEGIN

	CLEAN_WINDOW;
	DATE_AND_TIME;

	gotoXY(1,2);
	textbackground(C_back);
	write('                                                             ');
	gotoXY(1,2);
	writeln(' ',Version,'       INPUT PARAMETERS FOR   ',filename,'     ',
		Date_string);

	gotoXY(1,5);
	for parnumber := 1 to numberofparameters do BEGIN

	LABELS_FOR_DATA;

	write ('  ',parnumber:3,'   ', d, u,' =');
	writeln( par[parnumber]:12);
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
	writeln(' ',Version,'      INPUT VARIABLES FOR   ',filename,'      ',
		Date_string);

	gotoXY(1,5);
	for vblnumber := 1 to numberofvariables do BEGIN

	LABELS_FOR_VARIABLES;

	write ('  ',vblnumber:3,'   ', d, u,' =');
	writeln( vbl[vblnumber]:12);
	END;

END;  {LIST_VARIABLES.    }
{-------------------------------------------------------------------}

End.	{	Unit BUGGlbls	}
