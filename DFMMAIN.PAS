Unit Dfmmain;
{ PMS 15-December-1989 02:47 }

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   M.F.Ashby and P.M.Sargent        **************
   *************   January 1989                     **************
}
{$R+}    {Range checking on }
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N+}    {Use numeric coprocessor}
{$E+}		{Include copy of 8087 Emulator - default anyway}

Interface

Uses
	Crt,
	Dos,
	Printer,
	Graph,
	StringIO,
	Dfmglbls,
	Dfmfiles,
	Dfmplots;

PROCEDURE MAIN_PROCEDURE;

{===========================================================================}

Implementation

VAR
	index	:	INTEGER;
	pathfilelength	:	INTEGER;
	s	:	String[1];
	ch	:	CHAR;

{---------------------------------------------------------------------------}
PROCEDURE GiveExitCodes;
BEGIN
	WRITELN;
	WRITELN('Exit codes are:');
	WRITELN('0       Everything ran OK');
	WRITELN('1       Help or exit codes information only');
	WRITELN('2       Ran but input data gives cause for concern');
	WRITELN('4       Failed to write all output files correctly');
	WRITELN('6       Failed to open an input file');
	WRITELN('7       Error in command line options');
	WRITELN('8       Internal error, telephone +44 (223) 332627');
END;	{	GiveExitCodes	}

{---------------------------------------------------------------------------}
PROCEDURE PathError(s: String);

BEGIN
	Writeln(Version,' ',VersionDate,' ',copyright);
	WRITELN('Path string too long (>','pathlength',' chars):',s);
	Finish(7);
END;

{---------------------------------------------------------------------------}
PROCEDURE Warning;
VAR
	x, y	:	Byte;
BEGIN
	window(1,1,80,25);     textbackground(C_warn);    clrscr;
	textcolor(C_bright);

	FOR y:= 11 TO 14 DO 
		BEGIN
			gotoXY(29,y);
			write(Vert);
			gotoXY(51,y);
			write(Vert);
		END;
	gotoXY(30,10);
	FOR x:=30 TO 50 DO write(Horiz);
	gotoXY(30,15);
	FOR x:=30 TO 50 DO write(Horiz);

		gotoXY(29,10);
		write(TLC);
		gotoXY(51,10);
		write(TRC);
		gotoXY(29,15);
		write(BLC);
		gotoXY(51,15);
		write(BRC);

	gotoXY(35,12);
	write(' WARNING ! ');
	gotoXY(35,13);
	write('PROTOTYPE !');

	textcolor(C_warn);	{	make blinking cursor invisible	}
	gotoXY(1,1);

	Delay(300);
	textbackground(C_back);
	textcolor(C_text);
END;	{	Warning	}
{-------------------------------------------------------------------}
PROCEDURE Prompt_New_Name;
VAR
	name		:	String;
	escape	:	BOOLEAN;
BEGIN
	gotoXY(1,24); textbackground(C_screen);
	WRITE('                                                             ');
	REPEAT
		gotoXY(48,19);  Textbackground(C_bright);  WRITE('          ');
		gotoXY(49,19);  Textcolor(C_back);
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
				IF answer=Esc THEN Finish(0);
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
		gotoXY(48,19);  Textbackground(C_bright);  WRITE('          ');
		gotoXY(49,19);  Textcolor(C_back);
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
		WRITELN('          ========================================          ');
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

		WRITE('      Press  ');  Textcolor(C_bright);
		WRITE('Esc'); Textcolor(C_text);
		WRITE('  at any prompt to quit (discarding data) ');

		gotoXY(1,24);
		textbackground(C_back);
		write  ('                                                             ');

		REPEAT   
			gotoXY(1,24);    textcolor(C_bright);
			WRITE('                      MAKE  SELECTION');
			choice:=Readkey;
		UNTIL choice in ['a','A','c','C','r','R','s','S','d','D','h','H',Esc];
		textcolor(C_text);

		IF choice=Esc THEN Finish(0);					{ BUG! here, close(db) fails.. }
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

	IF choice in ['c','C']  THEN BEGIN
		REPEAT
			LIST_MATERIALS;

			gotoXY(1,19);  WRITE('      Enter  ');  Textcolor(C_bright);
			WRITE('NAME  ');
			Textcolor(C_text);  WRITE('for new material...');
			Prompt_New_Name;
		UNTIL answer in ['y','Y'];
	END;

{ ------- Make, edit and save a new files ------- }

	IF choice in ['c','C'] THEN
		BEGIN
			matl_ok := FALSE;	{	adding new material, index out of date	}
			MAKE_PARAMETER_SET;
			MAKE_VARIABLE_SET;
		END;

END;	{	GET_FILENAME	}

{---------------------------------------------------------------------------}
PROCEDURE HANDLE_STRESS_PLOT_OPTIONS;

BEGIN
	s :=Copy(ParamStr(index),3,1);
	ch:=s[1];

	CASE ch OF
			'-': 		modestrs:=FALSE;
			'l','L': BEGIN
							pathfilelength:=
								Length(ParamStr(index))-4;
							IF (pathfilelength > 0) AND
								(pathfilelength <= pathlength) THEN
									BEGIN
										ppicfilename:=
											Copy(ParamStr(index),5,pathfilelength);
										modeppic:=TRUE;
									END
							ELSE
								PathError(ParamStr(index));
						END;

			'g','G': BEGIN
							pathfilelength:=
								Length(ParamStr(index))-4;
							IF (pathfilelength>0) AND
								(pathfilelength <= pathlength) THEN
									BEGIN
										phpgfilename:=
											Copy(ParamStr(index),5,pathfilelength);
										modephpg:=TRUE;
									END
							ELSE
								PathError(ParamStr(index));
						END;

		END;	{	Case	}

END;	{	HANDLE_STRESS_PLOT_OPTIONS	}

{---------------------------------------------------------------------------}
PROCEDURE HANDLE_TEMPERATURE_PLOT_OPTIONS;

BEGIN
	s :=Copy(ParamStr(index),3,1);
	ch:=s[1];
	CASE ch OF
			'-': 		modetemp:=FALSE;
			'l','L': BEGIN
							pathfilelength:=
								Length(ParamStr(index))-4;
							IF (pathfilelength>0) AND
								(pathfilelength <= pathlength) THEN
									BEGIN
										tpicfilename:=
											Copy(ParamStr(index),5,pathfilelength);
										modetpic:=TRUE;
									END
							ELSE
								PathError(ParamStr(index));
						END;

			'g','G': BEGIN
							pathfilelength:=
								Length(ParamStr(index))-4;
							IF (pathfilelength>0) AND
								(pathfilelength <= pathlength) THEN
									BEGIN
										thpgfilename:=
											Copy(ParamStr(index),5,pathfilelength);
										modethpg:=TRUE;
									END
							ELSE
								PathError(ParamStr(index));
						END;

		END;	{	Case	}

END;	{	HANDLE_TEMPERATURE_PLOT_OPTIONS	}

{---------------------------------------------------------------------------}
PROCEDURE HANDLE_OPTIONS;

VAR
	SetError	:	BOOLEAN;
BEGIN
	modenamed:=FALSE;
	modefast:=FALSE;
	modedemo:=FALSE;
	modestrs:=TRUE;
	modetemp:=TRUE;
	modeppic:=FALSE;
	modetpic:=FALSE;
	modephpg:=FALSE;
	modethpg:=FALSE;
	modelist:=FALSE;
	modelistfile:=FALSE;
	modeconcern:=FALSE;
	mode400:=FALSE;
	modeCGA:=FALSE;
	matlname:='';
	listfilename:='';
	phpgfilename:='';
	thpgfilename:='';
	ppicfilename:='';
	tpicfilename:='';

	IF ParamCount<>0 THEN
	FOR index:=1 TO ParamCount DO
		BEGIN
{			WRITE(ParamStr(index),' ');	}
			s :=Copy(ParamStr(index),2,1);
			ch := s[1];

			IF ((Copy(ParamStr(index),1,1) = '/')
			OR  (Copy(ParamStr(index),1,1) = '-')) THEN
				CASE ch OF
					'h','H':	BEGIN 
									Writeln(Version,' ',VersionDate,' ',copyright);
									GiveCommandLineHelp; 
									Finish(1); 
								END;
					'e','E': BEGIN 
									Writeln(Version,' ',VersionDate,' ',copyright);
									GiveExitCodes; 
									Finish(1); 
								END;
					'f','F': modefast:=TRUE;
					'd','D': modedemo:=TRUE;
					'o','O': mode400 :=TRUE;
					'c','C': modeCGA :=TRUE;
					's','S': HANDLE_STRESS_PLOT_OPTIONS;
					't','T': HANDLE_TEMPERATURE_PLOT_OPTIONS;
					'w','W': BEGIN
									modelist:=TRUE;
									pathfilelength:=Length(ParamStr(index))-3;
									IF pathfilelength>0 THEN
										IF pathfilelength <= pathlength THEN
											BEGIN
												listfilename:=
													Copy(ParamStr(index),4,pathfilelength);
												modelistfile:=TRUE;
												modelist:=FALSE;
											END
										ELSE
											PathError(ParamStr(index));
								END;

				END	{	Case	}
			ELSE	{ a data name for vbl & par files }
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
{	WRITELN;	}

	IF (modephpg OR modeppic) OR  (modethpg OR modetpic) THEN
		BEGIN
			WRITELN('The PIC file and HPGL file options are not yet written.');
			Finish(7);
		END;

{	WRITELN('  modenamed:=FALSE ',modenamed);
	WRITELN('  matlname ',matlname);
	WRITELN('  modefast:=FALSE ',modefast);
	WRITELN('  modestrs:=TRUE ',modestrs);
	WRITELN('  modetemp:=TRUE ',modetemp);
	WRITELN('  modeppic:=FALSE ',modeppic);
	WRITELN('  modetpic:=FALSE ',modetpic);
	WRITELN('  modephpg:=FALSE ',modephpg);
	WRITELN('  modethpg:=FALSE ',modethpg);
	WRITELN('  modelist:=FALSE ',modelist);
	WRITELN('  modelistfile:=FALSE ',modelistfile);

	Finish(7);
}
	SetError:=FALSE;
	IF modelist THEN
		IF CannotOpen(listfilename) THEN
			SetError:=TRUE;

	IF modephpg THEN
		IF CannotOpen(phpgfilename) THEN
			SetError:=TRUE;

	IF modethpg THEN
		IF CannotOpen(thpgfilename) THEN
			SetError:=TRUE;

	IF modeppic THEN
		IF CannotOpen(ppicfilename) THEN
			SetError:=TRUE;

	IF modetpic THEN
		IF CannotOpen(tpicfilename) THEN
			SetError:=TRUE;

	IF SetError THEN
		BEGIN
			WRITELN('ERROR: Cannot open an Output File');
			WRITELN('   /w:  listfilename:=',listfilename);
			WRITELN('   /pg: phpgfilename:=',phpgfilename);
			WRITELN('   /tg: thpgfilename:=',thpgfilename);
			WRITELN('   /pl: ppicfilename:=',ppicfilename);
			WRITELN('   /tg: tpicfilename:=',tpicfilename);
			Finish(4);
		END;

	IF modethpg OR modetpic THEN
		modetemp:=TRUE;

	IF modephpg OR modeppic THEN
		modestrs:=TRUE;

	IF modedemo THEN
		modefast:=TRUE;
	clrscr;

END;	{	HANDLE_OPTIONS	}

{---------------------------------------------------------------------------}
PROCEDURE MAIN_PROCEDURE;

VAR
	comptime	:	a_real;
	name		:	String;

BEGIN
{	Disable the cntl-BREAK key whilst running the program	}
	CheckBreak:=FALSE;

	OldExitProc := ExitProc;                { save previous exit proc }
	ExitProc := @MyExitProc;                { insert our exit proc in chain }

	HANDLE_OPTIONS;
	CheckDeviceMono;
{		Warning;		}
	stash_index := 0;
	matl_ok := FALSE;

{ ----- Open DEBUG file	----- }
{$DEFINE debug}
{$IFDEF  debug}
	IF CannotOpen('debug.txt') THEN
		BEGIN
			Writeln(' *** Cannot Open Debug File ***');
			Finish(4);
		END
	ELSE
		BEGIN
			Assign(db,'debug.txt');
			Rewrite(db);
			Writeln(db, matlname);
			Writeln(db);
		END;
{$ENDIF}
	IF (NOT modenamed AND NOT modefast) THEN INTRODUCTION;

	REPEAT

		IF modenamed THEN
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
			{	Read in chosen files, don't need to if same material	}
				IF NOT (choice in ['s','S']) THEN	{	Same material	}
 					READ_MATL_DATA;
			END;
		
		IF modefast THEN
			BEGIN
				INTERPRET_PARAMETER_SET;
				INTERPRET_VARIABLE_SET;;
				IF (modelistfile) THEN INPUT_DATA_TO_FILE;
				CHECK_PARAMETERS;	{ which may involve listing	}
			END
		ELSE
			REPEAT
				IF choice in ['r','R'] THEN	{	Clean window first	}
					BEGIN
						CLEAN_WINDOW;

						INTERPRET_PARAMETER_SET;
						INTERPRET_VARIABLE_SET;;
						gotoXY(1,24); textbackground(C_screen);
						WRITE('                                                             ');
					END
				ELSE 
					IF choice in ['s','S'] THEN	
					{	Stash may be out of date, so don't re-interpret it,
						but do the editing directly, not from the INTERPRET_
						procedures.	}
					BEGIN
						CLEAN_WINDOW;
						LIST_PARAMETERS;
						EDIT_PARAMETERS;
						LIMIT_VARIABLES;
						LIST_VARIABLES;
						EDIT_VARIABLES;
						gotoXY(1,24); textbackground(C_screen);
						WRITE('                                                             ');
					END;
				choice := 'R';

	{ ----- Offer hardcopy of parameters, variables and data ----- }

				gotoXY(1,24); textbackground(C_back);
				WRITE('                                                             ');
				REPEAT   gotoXY(1,24);  textcolor(C_bright);
					WRITE('                HARDCOPY TO PRINTER ?  (Y/N)  ');
					hrdcopy:=Readkey;
					IF hrdcopy=Esc THEN
						Finish(0);
				UNTIL hrdcopy in ['y','Y','n','N'];   textcolor(C_text);
					gotoXY(1,24); textbackground(C_screen);
					WRITE('                                                             ');

				IF hrdcopy in ['y','Y'] THEN
						modelist:=TRUE
				ELSE
						modelist:=FALSE;

	{ ----- Put copy of data into a file if required. Must be written before
				check_parameters because it rewrites the file, check_parameters
				just appendsto the output text file . ----- }

				IF (modelistfile) THEN INPUT_DATA_TO_FILE;

				CHECK_PARAMETERS;	{ which may involve more listing	}

	{ ----- State the computation time and offer rerun ----- }

				comptime  := vbl[1]*vbl[1]*SpeedValue; WRITELN; WRITELN;
				WRITELN('    THE RUN-TIME PER MAP IS ROUGHLY =  ',
					         comptime:5:2,'  MINUTES');

				gotoXY(1,24);
				write  ('                                                             ');
				REPEAT    
					gotoXY(1,24);   textcolor(C_bright);
					WRITE('          RE-EDIT  FILES  BEFORE  PROCEEDING ?   (Y/N) ');
					answer:=Readkey;
					IF answer=Esc THEN
						Finish(0);
				UNTIL answer in ['y','Y','n','N'];  textcolor(C_text);

			UNTIL answer in ['n','N'];

		IF (modelist) THEN INPUT_DATA_TO_PRINTER;

		INITIALIZE;		{	graphics display	}


			{ when using Crt and graphics, turn off Crt's memory-mapped writes }
			DirectVideo := False;

{			IF modetemp THEN
				BEGIN
					  CALC_Indentation_MAP;

					IF modedemo THEN Delay(20000);

					IF NOT modefast THEN
						BEGIN
							REPEAT UNTIL keypressed;
						   answer:=Readkey; 	
						END;
				END;
}
		{	Stay in Graphics mode...	}
			IF modetemp THEN
				BEGIN
					  CALC_TEMPERATURE_MAP;

					IF modedemo THEN Delay(20000);

					IF NOT modefast THEN
						BEGIN
							REPEAT UNTIL keypressed;
						   answer:=Readkey; 	{ throw the answer away, never used }
						END;
				END;

		{	Close Graphics, remove MyExitProc from exit chain (by running
			it) and revert to Text mode, also closes debug file	}
			MyExitProc;

	{ ----- REPEAT the program UNTIL QUIT is input ----- }

		IF modefast THEN
			answer:='Q'
		ELSE
			BEGIN
				textbackground(C_screen);   clrscr;
				window(10,7,70,16);
				textbackground(C_back);    clrscr;
				textcolor(C_text);
				gotoXY(1,4);    WRITE('                 TO  QUIT  TYPE   "');
				textcolor(C_bright);    WRITE(' Q ');
				textcolor(C_text);    WRITE('"');
				gotoXY(1,7);
				WRITE('           TO  CONTINUE,  PRESS  ANY  OTHER  KEY.  ');
				gotoXY(1,10);
				REPEAT UNTIL keypressed;
				answer:=Readkey;
				IF answer=#0 THEN	{	pressed a function key	}
					answer:=Readkey;
			END;
	UNTIL answer in ['q','Q',Esc];

	IF answer <> Esc THEN	{	finish properly & restore colours	}
		BEGIN
			window(1,1,80,25);
			Textbackground(C_back);
			Textcolor(C_bright);
			clrscr;
		END;

	IF modeconcern THEN	{	use Halt because debug file & Exitproc OK now }
		Halt(2)
	ELSE
		Halt(0);

END;  {main_PROCEDURE}

END.  { Unit dfmMAIN }
