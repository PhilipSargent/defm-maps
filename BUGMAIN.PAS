Unit BUGmain;
{ PMS 20-April-1988 19:34 }

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   M.F.Ashby and P.M.Sargent        **************
   *************   April 1988                       **************
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
	Graph,
	BUGglbls,
	BUGfiles,
	BUGmodls,
	BUGplots;

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
	textbackground(C_back);

	textcolor(C_back);	{	make blinking cursor invisible	}
	gotoXY(1,1);
	write(' ');
	Delay(2000);
	textcolor(C_text);
END;	{	Warning	}
{---------------------------------------------------------------------------}
PROCEDURE UpperCase (VAR s : filestring);
VAR
	i	:	Byte;
BEGIN
	FOR i:= 1 TO Length(s) DO
		IF (s[i] IN ['a'..'z']) THEN
			s[i]:= Chr( Ord(s[i])-Ord('a')+Ord('A') );
END;	{	UpperCase	}
{---------------------------------------------------------------------------}
PROCEDURE GET_FILENAME;
VAR
	ch	:	CHAR;

BEGIN
	REPEAT

		CLEAN_WINDOW;      DATE_AND_TIME;

		gotoXY(1,2);
		textbackground(C_back);
		write  ('                                                             ');
		gotoXY(1,2);
		WRITELN('          ',version,'                         ',date_string);
		gotoXY(1,6);
		WRITELN('          CREATE OR READ A PARAMETER AND DATA FILE          ');
		WRITELN('       ==============================================       ');
		WRITELN;  WRITELN;

		IF NOT (FileNotThere(filename+'.p  ')
		OR FileNotThere(filename+'.v  ')) THEN
			BEGIN
				WRITE('      Press  ');  Textcolor(C_bright);
				WRITE('S'); Textcolor(C_text);
				WRITE('  for the same file as the last run.          ');
				WRITELN;  WRITELN;  WRITELN;
			END;

		WRITE('      Press  ');  Textcolor(C_bright);
		WRITE('C'); Textcolor(C_text);
		WRITE('  to create a new parameter and data file.    ');
		WRITELN;  WRITELN;

		WRITE('      Press  ');  Textcolor(C_bright);
		WRITE('R'); Textcolor(C_text);
		WRITE('  to read an existing set of files.           ');
		WRITELN;  WRITELN;

		WRITE('      Press  ');  Textcolor(C_bright);
		WRITE('H'); Textcolor(C_text);
		WRITE('  for help.                                   ');
		WRITELN;  WRITELN;

		WRITE('      Press  ');  Textcolor(C_bright);
		WRITE('A'); Textcolor(C_text);
		WRITE('  for additional command-line information.    ');

		gotoXY(1,24);
		textbackground(C_back);
		write  ('                                                             ');

		REPEAT   
			gotoXY(1,24);    textcolor(C_bright);
			WRITE('                      MAKE  SELECTION');
			choice:=Readkey;
		UNTIL choice in ['a','A','c','C','r','R','s','S','h','H',Esc];
		textcolor(C_text);

		IF choice=Esc THEN Finish(0);
		IF choice in ['h','H'] THEN      HELP_2;
		IF choice in ['a','A'] THEN      HELP_3;
	UNTIL choice in ['c','C','r','R','s','S'];
	numberofpoints  := 0;

{ ------- Read in name of existing files ------- }

	IF choice in ['r','R']  THEN BEGIN
		REPEAT
			LIST_DIRECTORY('????????.p  ');

			gotoXY(1,19);  WRITE('      Enter  ');  Textcolor(C_bright);
			WRITE('NAME  ');
			Textcolor(C_text);  WRITE('of file (max. 8 symbols)...');
			gotoXY(1,24); textbackground(C_screen);
			WRITE('                                                             ');
			gotoXY(48,19);  Textbackground(C_bright);  WRITE('          ');
			gotoXY(49,19);  Textcolor(C_back);
			readln(filename);
			IF filename[1]=Esc THEN Finish(0);

			answer:='Y';
			IF FileNotThere(filename+'.p  ') THEN
				answer:='N';
			IF FileNotThere(filename+'.v  ') THEN
				answer:='N';

		{	Erase the filename prompt line	}
			Textcolor(C_back);
			gotoXY(1,19);   Textbackground(C_back);
			WRITE('                                                            ');

			IF NOT (answer in ['y','Y']) THEN
				BEGIN
				{	Clear the line for writing error message	}
					gotoXY(1,24); Textbackground(C_back); Textcolor(C_back);
					Textcolor(C_bright);
					WRITE('                                                             ');
					gotoXY(1,24);
					WRITE('      File name ');
					Textcolor(C_text);  WRITE(filename);  Textcolor(C_bright);
					WRITE(' not valid (press a key to re-try)   ');
					REPEAT UNTIL keypressed; ch:=Readkey;
					IF ch=Esc THEN Finish(0);
					gotoXY(10,24); textbackground(C_screen); textcolor(C_text);
					WRITE('                                      ');
				END;

		UNTIL answer in ['y','Y'];
	END;

{ ------- Get new filename for a new file ------- }

	IF choice in ['c','C']  THEN BEGIN
		REPEAT
			LIST_DIRECTORY('????????.p  ');

			gotoXY(1,19);  WRITE('      Enter  ');  Textcolor(C_bright);
			WRITE('NAME  ');
			Textcolor(C_text);  WRITE('of file (max. 8 symbols)...');
			gotoXY(1,24); textbackground(C_screen);
			WRITE('                                                             ');
			gotoXY(48,19);  Textbackground(C_bright);  WRITE('          ');
			gotoXY(49,19);  Textcolor(C_back);
			readln(filename);

			gotoXY(1,19);   Textbackground(C_back);
			WRITE('                                                            ');
			gotoXY(1,19);  Textcolor(C_text);
			WRITE('      Name of file   ');
			Textcolor(C_bright);  WRITE(filename);  Textcolor(C_text);
			WRITE('.   IS THIS CORRECT (Y/N) ?  ');
			REPEAT
				REPEAT UNTIL keypressed; answer:=Readkey;
				IF answer=Esc THEN Finish(0);
			UNTIL answer in ['y','Y','n','N'];
		UNTIL answer in ['y','Y'];
	END;

	parfilename   := filename + '.p  ';
	vblfilename   := filename + '.v  ';

{ ------- Make, edit and save a new files ------- }

	IF choice in ['c','C'] THEN BEGIN
		MAKE_PARAMETER_FILE;
		MAKE_VARIABLE_FILE;
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
	filename:='';
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
					'h','H':	BEGIN GiveCommandLineHelp; Finish(1); END;
					'e','E': BEGIN GiveExitCodes; Finish(1); END;
					'f','F': modefast:=TRUE;
					'd','D': modedemo:=TRUE;
					'o','O': mode400 :=TRUE;
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
						SetError:=FALSE;
						filename:=ParamStr(index);
						IF FileNotThere(filename+'.p  ') THEN
							BEGIN
								WRITELN('ERROR: ',filename,'.p does not exist');
								SetError:=TRUE;
							END;
						IF FileNotThere(filename+'.v  ') THEN
							BEGIN
								WRITELN('ERROR: ',filename,'.v does not exist');
								SetError:=TRUE;
							END;
						IF SetError THEN
							Finish(6)
						ELSE
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
	WRITELN('  filename ',filename);
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

BEGIN
{	Disable the cntl-BREAK key whilst running the program	}
	CheckBreak:=FALSE;

	OldExitProc := ExitProc;                { save previous exit proc }
	ExitProc := @MyExitProc;                { insert our exit proc in chain }

	HANDLE_OPTIONS;

{	CheckDeviceMono;
	Warning;
}
{	IF (NOT modenamed AND NOT modefast) THEN INTRODUCTION;
 }
	REPEAT

		IF modenamed THEN
			CALC_TEMPERATURE_MAP
		ELSE
			CALC_TEMPERATURE_MAP;
		REPEAT UNTIL keypressed;
		answer:=Readkey;


	UNTIL answer in ['q','Q',Esc];

	IF modeconcern THEN
		Finish(2)
	ELSE
		Finish(0);

END;  {main_PROCEDURE}

END.  { Unit HIPMAIN }
