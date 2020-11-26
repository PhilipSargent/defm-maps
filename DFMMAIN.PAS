Unit Dfmmain;
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
{	ensure compiler directives are consistent	}
{$IFDEF  contour}		
{$DEFINE  detail}
{$ENDIF}
{$IFDEF  detail}
{$DEFINE  debug}
{$ENDIF}
{$R+}	{Range checking on}
{$B+}	{Boolean complete evaluation on}
{$S+}	{Stack checking on}
{$I+}	{I/O checking on}

Interface

PROCEDURE MAIN_PROCEDURE;

{===========================================================================}

Implementation

Uses
	Crt,
	Cp437,
	Dos,
	Printer,
	Graph,
	StringIO,
	Dfmglbls,
	Dfmfiles,
	Dfmedits,
	Dfmmodls,
	Dfmplots;

VAR
	index			:	INTEGER;
	pathfilelength	:	INTEGER;
	s		:	String[1];
	ch		:	CHAR;
	hrdcopy	:	char;

{---------------------------------------------------------------------------}
PROCEDURE GiveExitCodes;
BEGIN
	WRITELN;
	WRITELN('DFM Exit codes are:');
	WRITELN('0       Everything ran OK');
	WRITELN('1       Help or exit codes information only');
	WRITELN('2       Ran but input data gives a DATA CHECK message');
	WRITELN('4       Failed to write all output files correctly');
	WRITELN('6       Failed to open an input file');
	WRITELN('7       Error in command line options');
	WRITELN('8       Internal error, email philip.sargent@gmail.com');
END;	{	GiveExitCodes	}

{---------------------------------------------------------------------------}
PROCEDURE PathError(s: String);

BEGIN
	Writeln(Version,' v',Release);
	Writeln('       ',VersionDate,' ',copyright);
	WRITELN('Path string too long (>','pathlength',' chars):',s);
	Finish(7);
END;

{---------------------------------------------------------------------------}
PROCEDURE Quit_Message;
CONST
	xl = 10;
	xh = 70;
	yl = 7;
	yh = 16;
VAR
	x, y	:	Byte;
BEGIN
	Window(1,1,80,25);
	textbackground(C_screen);   ClrScr;
	textcolor(C_bright);

	FOR y:= yl TO yh DO
		BEGIN
			gotoXY(xl-1,y);
			WRITE(Vert);
			gotoXY(xh+1,y);
			WRITE(Vert);
		END;
	gotoXY(xl,yh+1);
	FOR x:=xl TO xh DO WRITE(Horiz);
	gotoXY(xl,yl-1);
	FOR x:=xl TO xh DO WRITE(Horiz);

	gotoXY(xl-1,yl-1);
	WRITE(TLC);
	gotoXY(xh+1,yl-1);
	WRITE(TRC);
	gotoXY(xl-1,yh+1);
	WRITE(BLC);
	gotoXY(xh+1,yh+1);
	WRITE(BRC);

	Window(xl,yl,xh,yh);
	textbackground(C_back);    ClrScr;

	textcolor(C_text);
	gotoXY(1,4);    WRITE('                 TO  QUIT  TYPE   "');
	textcolor(C_bright);    WRITE(' Q ');
	textcolor(C_text);    WRITE('"');
	gotoXY(1,7);
	WRITE('           TO  CONTINUE,  PRESS  ANY  OTHER  KEY.  ');
END;	{	Quit_Message	}
{-------------------------------------------------------------------}
PROCEDURE Prompt_New_Name;
VAR
	name		:	String;
	escape	:	BOOLEAN;
BEGIN
	gotoXY(1,24); textbackground(C_screen);
	WRITE('                                                             ');
	REPEAT
		gotoXY(51,19);  Textbackground(C_bright);  WRITE('          ');
		gotoXY(52,19);  Textcolor(C_back);
		name := Read_String(9,9,escape);
		IF escape THEN
			Finish(0);
		UpperCase(name);
		matlname:=name;
	UNTIL matlname <> '';

	gotoXY(1,19);   Textbackground(C_back);
	WRITE('                                                            ');
	IF ALREADY_EXISTS (matlname) THEN
		BEGIN
			gotoXY(1,24); textcolor(C_warn);
			WRITE('        THIS WILL OVER-WRITE AND DELETE EXISTING DATA');
			gotoXY(1,19);  Textcolor(C_text);
			WRITE('      Material: ');
			Textcolor(C_bright);  WRITE(matlname);  Textcolor(C_text);
			WRITE('.   IS THIS CORRECT (Y/N) ?  ');
			REPEAT
				REPEAT UNTIL keypressed; answer:=Readkey;
				IF answer=CtrlC THEN Finish(0);
			UNTIL answer in ['y','Y','n','N'];
		END
	ELSE
		answer := 'Y';
END;	{	Prompt_New_Name	}
{-------------------------------------------------------------------}
PROCEDURE Prompt_Old_Name;
VAR
	name		:	String;
	escape	:	BOOLEAN;
BEGIN
	gotoXY(1,24); textbackground(C_screen);
	WRITE('                                                             ');
	REPEAT
		gotoXY(51,19);  Textbackground(C_bright);  WRITE('          ');
		gotoXY(52,19);  Textcolor(C_back);
		name := Read_String(9,9,escape);
		IF escape THEN
			Finish(0);
		UpperCase(name);
		matlname:=name;
	UNTIL ALREADY_EXISTS (matlname);
	answer:='Y';
END;	{	Prompt_Old_Name	}
{-------------------------------------------------------------------}
PROCEDURE COPY_AND_RENAME;

BEGIN
{ ------- Get the material name to be copied ------- }
	LIST_MATERIALS;

	gotoXY(1,19);  WRITE('      Enter  ');  Textcolor(C_bright);
	WRITE('NAME  ');
	Textcolor(C_text);  WRITE('for material to be copied... ');
	Prompt_old_Name;

{ ------- Read in the data into the stash ------- }
	READ_MATL_DATA;

{ ------- Interpret the data into the par[] and vbl[] arrays ------- }
	modefast := TRUE;
	INTERPRET_PARAMETER_SET;
	INTERPRET_VARIABLE_SET;
	modefast := FALSE;

{ ------- Get the new material name  ------- }
	REPEAT
		LIST_MATERIALS;

		gotoXY(1,19);  WRITE('      Enter  ');  Textcolor(C_bright);
		WRITE('New NAME ');
		Textcolor(C_text);  WRITE('for the old material data... ');
		Prompt_New_Name;
	UNTIL answer in ['y','Y'];

{ ------- Save the data under the new name  ------- }

	gotoXY(1,19);   Textbackground(C_back);
	WRITE('                                                            ');
	gotoXY(1,24);
	WRITE('                                                            ');
	gotoXY(1,24);	Textcolor(C_text);
	WRITE('      Backing-up and Saving the Data');
	SAVE_MATL_PARAMETERS;
	SAVE_MATL_VARIABLES;
	SAVE_MATL_REFERENCES;

{ ----- Add the new name to the list of materials in matl_list ----- }
	matl_index := matl_index + 1;
	matl_list[matl_index] := matlname;

END;	{	COPY_AND_RENAME	}
{---------------------------------------------------------------------------}
PROCEDURE GET_FILENAME;
VAR
	ch	:	CHAR;
	name		:	String;
	escape	:	BOOLEAN;

BEGIN
	REPEAT

		CLEAN_WINDOW;      DATE_AND_TIME;

		gotoXY(1,2);
		textbackground(C_back);
		write  ('                                                             ');
		gotoXY(1,2);
		WRITELN('          ',version,'                         ',date_string);
		gotoXY(1,6);
		WRITELN('             CREATE OR READ A MATERIAL DATA SET             ');
	   write  ('             '); UnderLine(34);        writeln('            ');
		WRITELN;

		IF (matlname <> '') THEN
			BEGIN
				WRITE('      Press  ');  Textcolor(C_bright);
				WRITE('S'); Textcolor(C_text);
				WRITE('  for the same material.                      ');
				WRITELN;  WRITELN;
			END
		ELSE
			WRITELN;

		WRITE('      Press  ');  Textcolor(C_bright);
		WRITE('C'); Textcolor(C_text);
		WRITE('  to Create a data set for a new material.    ');
		WRITELN;  WRITELN;

		WRITE('      Press  ');  Textcolor(C_bright);
		WRITE('R'); Textcolor(C_text);
		WRITE('  to Read an existing data set.               ');
		WRITELN;  WRITELN;

		WRITE('      Press  ');  Textcolor(C_bright);
		WRITE('D'); Textcolor(C_text);
		WRITE('  to Duplicate data and give it a new name. ');
		WRITELN;  WRITELN; WRITELN;

		WRITE('      Press  ');  Textcolor(C_bright);
		WRITE('H'); Textcolor(C_text);
		WRITE('  for help.                                   ');
		WRITELN;

		WRITE('      Press  ');  Textcolor(C_bright);
		WRITE('A'); Textcolor(C_text);
		WRITE('  for additional command-line information.    ');
		WRITELN;

		WRITE('      Press ');  Textcolor(C_bright);
		WRITE('^C'); Textcolor(C_text);
		WRITE('  (control-C) to quit (discarding data) ');

		gotoXY(1,24);
		textbackground(C_back);
		write  ('                                                             ');

		REPEAT
			gotoXY(1,24);    textcolor(C_bright);
			WRITE('                      MAKE  SELECTION');
			choice:=Readkey;
		UNTIL choice in ['a','A','c','C','r','R','s','S','d','D','h','H',CtrlC];
		textcolor(C_text);

		IF choice=CtrlC THEN Finish(0);
		IF choice in ['h','H'] THEN      HELP_2;
		IF choice in ['a','A'] THEN      HELP_3;
		IF choice in ['d','D'] THEN		COPY_AND_RENAME;
	UNTIL choice in ['c','C','r','R','s','S'];
	numberofpoints  := 0;

{ ------- Read in name of existing material ------- }

	IF choice in ['r','R']  THEN BEGIN
		REPEAT
			LIST_MATERIALS;

			gotoXY(1,19);  WRITE('      Enter  ');  Textcolor(C_bright);
			WRITE('NAME  ');
			Textcolor(C_text);  WRITE('of Material ...');
			Prompt_Old_Name;

		UNTIL answer in ['y','Y'];
	END;

{ ------- Get new matlname for a new material ------- }

	IF choice in ['c','C']  THEN
		BEGIN
			REPEAT
				LIST_MATERIALS;

				gotoXY(1,19);  WRITE('      Enter  ');  Textcolor(C_bright);
				WRITE('NAME  ');
				Textcolor(C_text);  WRITE('for new material...');
				Prompt_New_Name;
			UNTIL answer in ['y','Y'];


{ ----- Add the new name to the list of materials in matl_list ----- }
{	Doing this means we don't have to set matl_ok := FALSE	}
			matl_index := matl_index + 1;
			matl_list[matl_index] := matlname;

{ ------- Make, edit and save a new files ------- }

			MAKE_PARAMETER_SET;
			MAKE_VARIABLE_SET;
			MAKE_REFERENCE_SET;
		END;

END;	{	GET_FILENAME	}

{---------------------------------------------------------------------------}
PROCEDURE HANDLE_TEMPERATURE_PLOT_OPTIONS;
{	Identify the type of map by the variable used for the CONTOURS	}
{	/t+ or /t- or /tL:output.hpg }
BEGIN
	s :=Copy(ParamStr(index),3,1);
	ch:=s[1];

	CASE ch OF
			'-': 		modetemp:=FALSE;

		END;	{	Case	}

END;	{	HANDLE_TEMPERATURE_PLOT_OPTIONS	}

{---------------------------------------------------------------------------}
PROCEDURE HANDLE_STRAIN_RATES_PLOT_OPTIONS;
{	Identify the type of map by the variable used for the CONTOURS	}
{	s+ or s- or /sL:output.hpg }
BEGIN
	s :=Copy(ParamStr(index),3,1);
	ch:=s[1];
	CASE ch OF
			'-': 		modestrate:=FALSE;

		END;	{	Case	}

END;	{	HANDLE_STRAIN_RATES_PLOT_OPTIONS	}

{---------------------------------------------------------------------------}
PROCEDURE HANDLE_Indentation_PLOT_OPTIONS;
{	Identify the type of map by the variable used for the CONTOURS	}
{	i+ or i- or /iL:output.hpg }
BEGIN
	s :=Copy(ParamStr(index),3,1);
	ch:=s[1];
	CASE ch OF
			'-': 		modeindt:=FALSE;

		END;	{	Case	}

END;	{	HANDLE_Indentation_PLOT_OPTIONS	}

{---------------------------------------------------------------------------}
PROCEDURE HANDLE_OPTIONS;

VAR
	SetError	:	BOOLEAN;
	stuf		:	String;
BEGIN
	modenamed:=FALSE;
	modefast:=FALSE;
	modedemo:=FALSE;
	modetemp:=FALSE;
	modestrate:=TRUE;
	modeindt:=FALSE;
	modelistfile:=FALSE;
	modeconcern:=FALSE;
	matlname:='';
	listfilename:='';

	IF ParamCount<>0 THEN
	FOR index:=1 TO ParamCount DO
		BEGIN
{			WRITE(ParamStr(index),' ');	}
			s :=Copy(ParamStr(index),2,1);
			ch := s[1];

			IF ((Copy(ParamStr(index),1,1) = '/')
			OR  (Copy(ParamStr(index),1,1) = '-')) THEN
				CASE ch OF
					'h','H',
					'?':		BEGIN
									GiveCommandLineHelp;
									Writeln('press <space bar> for more...');
									REPEAT UNTIL KeyPressed;
									answer := ReadKey;
									Writeln;
									Writeln('contact: Philip Sargent     e-mail: philip.sargent@gmail.com ');
									Finish(1);
								END;
					'e','E': BEGIN
									GiveExitCodes;
									GiveCommandLineHelp;
									Finish(1);
								END;
					'f','F': modefast:=TRUE;
					'd','D': modedemo:=TRUE;
					
					't','T': HANDLE_TEMPERATURE_PLOT_OPTIONS;
					's','S': HANDLE_STRAIN_RATES_PLOT_OPTIONS;
					'i','I': HANDLE_Indentation_PLOT_OPTIONS;
					'w','W': BEGIN	{ write a listing file }
									pathfilelength:=Length(ParamStr(index))-3;
									IF pathfilelength>0 THEN
										IF pathfilelength <= pathlength THEN
											BEGIN
												listfilename:=
													Copy(ParamStr(index),4,pathfilelength);
												modelistfile:=TRUE;
											END
										ELSE
											PathError(ParamStr(index));
								END;

				END	{	Case	}
			ELSE	{ a data name for matlpars and matlrefs files }
				BEGIN
					IF Length(ParamStr(index)) <= pathlength THEN
						BEGIN
							matlname:=ParamStr(index);
							modenamed:=TRUE;
						END
				ELSE
					PathError(ParamStr(index));
				END;
			END;	{ For loop along options	}

	SetError:=FALSE;
	IF modelistfile THEN
		IF CannotOpen(listfilename) THEN
			SetError:=TRUE;

	IF SetError THEN
		BEGIN
			WRITELN('ERROR: Cannot open one of these Output Files');
			WRITELN('   /l:  listfilename:=',listfilename);
			Finish(4); 
		END;

	IF modedemo THEN
		modefast:=TRUE;
	clrscr;

END;	{	HANDLE_OPTIONS	}

{---------------------------------------------------------------------------}

PROCEDURE MAIN_PROCEDURE;

CONST
	Screen	=	TRUE;
VAR
	comptime	:	a_real;
	name		:	String;
	dud_steps	: INTEGER;
	dud_TN, dud_K: a_real;

BEGIN
{	Disable the cntl-BREAK key whilst running the program.
	(actually we detect Ctrl-C ourselves and abort, but we tidy up first) }
	CheckBreak:=FALSE;

	OldExitProc := ExitProc;                { save previous exit proc }
	ExitProc := @MyExitProc;                { insert our exit proc in chain }
	HANDLE_OPTIONS;
	Delay(2500);

	stash_index := 0;
	matl_ok := FALSE;

	IF (NOT modenamed AND NOT modefast) THEN INTRODUCTION;

	{===================================================================}
	REPEAT	{	MAIN LOOP - only leave it when quitting	}


		IF modenamed THEN
			BEGIN
				Writeln('Checking material name given...');
				name := matlname;
				UpperCase(name);
				matlname:=name;
				CHECK_MATLNAME;
			END;

		IF modenamed THEN	{	if matlname was junk, then modenamed=FALSE	}
			BEGIN
				name := matlname;
				UpperCase(name);
				matlname:=name;
				choice:='R';
				CLEAN_WINDOW;
				READ_MATL_DATA;
			{	Reset the status so that this only works for the first
				iteration of editing/running the system.	}
				modenamed := FALSE;
			END
		ELSE
			BEGIN
				GET_FILENAME;
			{	Read in chosen files, don't need to if same material OR just created	}
				IF NOT (choice in ['s','S','c','C']) THEN	{	Same material	}
 					READ_MATL_DATA;
			END;

		Writeln(db, matlname);
		Writeln(db);

		IF modefast THEN
			BEGIN
				INTERPRET_PARAMETER_SET;
				INTERPRET_VARIABLE_SET;
				CHECK_PARAMETERS(Screen);	{ scrolls fast, no waiting	}
			END
		ELSE
			REPEAT
				IF choice in ['r','R'] THEN	{	Clean window first	}
					BEGIN
						CLEAN_WINDOW;

						INTERPRET_PARAMETER_SET;
						INTERPRET_VARIABLE_SET;
						EDIT_REFERENCES;
						gotoXY(1,24); textbackground(C_screen);
						WRITE('                                                             ');
					END
				ELSE IF choice in ['s','S'] THEN
					{	Stash may be out of date (S) or EMPTY (C), 
						so don't (re-)interpret it,
						but do the editing directly, not from the INTERPRET_
						procedures.	}
					BEGIN
						CLEAN_WINDOW;
						EDIT_PARAMETERS;
						LIMIT_VARIABLES;
						EDIT_VARIABLES;
						EDIT_REFERENCES;
						gotoXY(1,24); textbackground(C_screen);
						WRITE('                                                             ');
					END
				ELSE IF choice in ['c','C'] THEN
					{	Stash does not exist, so don't (re-)interpret it,
						in fact don't do anything	}
					BEGIN
						choice := 'S';	{	for safe editing or stuff in memory	}
					END;	{	choice can only be C, R or S	}

				CHECK_PARAMETERS(Screen);	{ which cannot involve listing	}

	{ ----- State the computation time and offer rerun ----- }
				SpeedValue := 0.0233;
				comptime  := vbl[1]*vbl[1]*SpeedValue; WRITELN; WRITELN;
				gotoXY(1,21);
				WRITELN('    The RUN-TIME for this map is ROUGHLY  ',
					         comptime:5:2,'  seconds');

				gotoXY(1,24);
				write  ('                                                             ');
				REPEAT
					gotoXY(1,24);   textcolor(C_bright);
					WRITE('          RE-EDIT  FILES  BEFORE  PROCEEDING ?   (Y/N) ');
					REPEAT UNTIL KeyPressed;
					answer:=Readkey;
					IF answer=CtrlC THEN
						Finish(0);
				UNTIL answer in ['y','Y','n','N'];  textcolor(C_text);

			UNTIL answer in ['n','N'];	{	Else clause, NOT modefast	}


		Dfmmodls.DEFINE_UNITS(dud_steps, dud_TN, dud_K);

		IF (dud_steps > 0) THEN
			DUD_TEMP_TO_DEBUG (dud_steps, dud_TN, dud_K);

	{ ----- Put copy of data into a file if required. Must be written before
				check_parameters because it rewrites the file, check_parameters
				just appends to the output text file . ----- }
		IF (modelistfile) THEN
			BEGIN
				gotoXY(1,24);
				WRITE('          WRITING FILE LISTING NOW                     ');
				INPUT_DATA_TO_FILE;
				IF (dud_steps > 0) THEN
					DUD_TEMP_TO_FILE (dud_steps, dud_TN, dud_K);
				CHECK_PARAMETERS(NOT Screen);	{ which may involve more listing	}
			END;

		gotoXY(1,24);
		WRITE('                                                       ');

		Window(1,1,80,25);
		textbackground(C_screen);   ClrScr;
		textcolor(C_text);

		Writeln(db, 'modestrate: ', modestrate);
		Writeln(db, 'modeindt:   ', modeindt);
		Writeln(db, 'modetemp:   ', modeindt);
		IF modestrate THEN
			BEGIN
				Initialize;		{	graphics display	}
				CALC_STRAIN_RATES_MAP;

				IF modedemo THEN Delay(20000);

				IF NOT modefast THEN
					BEGIN
						REPEAT UNTIL keypressed;
					   answer:=Readkey; 	{ throw the answer away, never used }
					END;
				CloseGraph;              { Shut down the graphics system }
			END;

		IF modeindt THEN		
			BEGIN
				Initialize;		{	graphics display	}
				CALC_Indentation_MAP;

				IF modedemo THEN Delay(20000);

				IF NOT modefast THEN
					BEGIN
						REPEAT UNTIL keypressed;
					   answer:=Readkey;
					END;
				CloseGraph;              { Shut down the graphics system }
			END;

	{ ----- REPEAT the program UNTIL Q (quit) is input ----- }

		IF modefast THEN
			answer:='Q'
		ELSE
			BEGIN
				Quit_Message;
				textcolor(C_text);
				REPEAT UNTIL keypressed;
				answer:=Readkey;
				IF answer=#0 THEN	{	pressed a function key	}
					answer:=Readkey;
			END;
	UNTIL answer in ['q','Q',CtrlC];	{	MAIN program loop	}
	{===================================================================}

	IF answer <> CtrlC THEN	{	finish properly & restore colours	}
		BEGIN
			window(1,1,80,25);
			Textbackground(C_back);
			Textcolor(C_bright);
			clrscr;
		END;

{	use Halt because debug file & Exitproc OK now }
	IF modeconcern THEN	{ grain size unusual so give an error code }
		Halt(2)
	ELSE
		Halt(0);

END;  {main_PROCEDURE}
{---------------------------------------------------------------------------}

END.  { Unit dfmMAIN }
