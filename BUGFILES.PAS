Unit BUGfiles;
{ PMS 19-April-1988 13:25 }
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
	BUGGlbls;

PROCEDURE MAKE_PARAMETER_FILE;

{ -- Creates a file on disk containing parameters for a chosen material -- }

PROCEDURE MAKE_VARIABLE_FILE;

{ -- Creates a file on disk containing variables for a chosen material -- }

PROCEDURE READ_PARAMETER_FILE;

{ -------- Read in the chosen  parameter file -------- }

PROCEDURE READ_VARIABLE_FILE;

{ -------- Read in the chosen variable file -------- }

PROCEDURE CHECK_PARAMETERS;

{ -------- Checks input data against limits -------- }

PROCEDURE INPUT_DATA_TO_PRINTER;

PROCEDURE INPUT_DATA_TO_FILE;

{===================================================================}

Implementation
{-------------------------------------------------------------------}
PROCEDURE SaveParFile (parfilename: String);
VAR
	infile	:	Text;
BEGIN
	Assign (infile, parfilename);      
	Rewrite (infile);
	FOR parnumber:= 1 TO numberofparameters DO
		BEGIN
			Labels_for_data;
			WRITELN(infile, par[parnumber],' ''',d,''' ''',u,'''');
		END;
	close (infile);
END;
{-------------------------------------------------------------------}
PROCEDURE SaveVblFile (vblfilename: String);
VAR
	infile	:	Text;
BEGIN
	Assign (infile, vblfilename);      
	Rewrite (infile);
	FOR vblnumber:= 1 TO numberofvariables DO
		BEGIN
			Labels_for_variables;
			WRITELN(infile, vbl[vblnumber],' ''',d,''' ''',u,'''');
		END;
	close (infile);
END;
{-------------------------------------------------------------------}
PROCEDURE Prompt_Finish;
BEGIN
	gotoXY(1,24);  textbackground(C_back);
	write('                                                             ');
	repeat   gotoXY(1,24);
		write  ('              FINISHED  EDITING ?   (Y/N) ');
		answer:=Readkey;
	until answer in ['y','Y','n','N',Esc];
	IF answer=Esc THEN Finish(0);
	textcolor(C_text);
END;	{	Prompt_Finish	}
{-------------------------------------------------------------------}
PROCEDURE Prompt_Save;
BEGIN
	{ -------- Save the modified file ? -------- }
	gotoXY(1,24);  textbackground(C_back);
	write('                                                             ');
	repeat     gotoXY(1,24);   textcolor(C_bright);
		write ('                 SAVE  THE  FILE ?    (Y/N) ');
		answer:=Readkey;   gotoXY(1,24);
	until answer in ['y','Y','n','N',Esc]; 
	IF answer=Esc THEN Finish(0);
	textcolor(C_text);

END;	{	Prompt_Save	}
{-------------------------------------------------------------------}
PROCEDURE Prompt_Edit;
BEGIN
	{ -------- Edit the modified file ? -------- }
	gotoXY(1,24);  textbackground(C_back);
	write('                                                             ');
	repeat   
		gotoXY(1,24);  textcolor(C_bright);
		write('               EDIT  THE  FILE ?    (Y/N) ');
		answer:=Readkey;
	until answer in ['y','Y','n','N',Esc];
	IF answer=Esc THEN Finish(0);
	textcolor(C_text);

END;	{	Prompt_Edit	}
{-------------------------------------------------------------------}
PROCEDURE EDIT_PARAMETERS;

BEGIN
	Prompt_Edit;

	if answer in ['y','Y'] then
		BEGIN
			repeat
				Textbackground(C_back);
				repeat   gotoXY(1,24);  textcolor(C_bright);
					write ('                                                             ');
					gotoXY(1,24); 
					write  ('              LINE  NUMBER  FOR  EDITING  ....');
					readln (parnumber);
				until parnumber in [1..17];  textcolor(C_text);

				LABELS_FOR_DATA;

				gotoXY(1,24);  textcolor(C_bright);
				write ('  ', parnumber:3,'  ', d, u, '  =  ');
				textcolor(C_warn);
				read (par[parnumber]);

				textcolor(C_bright);
				LowVideo;
				gotoXY(1,4 + parnumber);
				write ('  ',parnumber:3,'   ', d, u,' =');
				writeln( par[parnumber]:12);
				NormVideo;

				Prompt_Finish;
			until answer in ['y','Y'];

			Prompt_Save;
			IF answer in ['y','Y'] then SaveParFile(parfilename);
		END;

	textbackground(C_back);  gotoXY(1,2);
END;	{	EDIT_Parameters	}
{-------------------------------------------------------------------}
PROCEDURE EDIT_VARIABLES;

BEGIN
	Prompt_Edit;

	if answer in ['y','Y'] then
		BEGIN
			repeat
				Textbackground(C_back);
				repeat   gotoXY(1,24);  textcolor(C_bright);
					write ('                                                             ');
					gotoXY(1,24);
					write ('              LINE  NUMBER  FOR  EDITING  .... ');
					readln (vblnumber);
				until vblnumber in [1..17];  textcolor(C_text);

				LABELS_FOR_VARIABLES;

				gotoXY(1,24);  textcolor(C_bright);
				write ('  ', vblnumber:3,'  ', d, u, '  =  ');
				textcolor(C_warn);
				read (vbl[vblnumber]);

				textcolor(C_bright);
				LowVideo;
				gotoXY(1,4 + vblnumber);
				write ('  ',vblnumber:3,'   ', d, u,' =');
				writeln( vbl[vblnumber]:12);
				NormVideo;

				Prompt_Finish;
			until answer in ['y','Y'];

			Prompt_Save;
			IF answer in ['y','Y'] then SaveVblFile(vblfilename);
		END;

	textbackground(C_back);  gotoXY(1,2);
END;	{	EDIT_VARIABLES	}
{-------------------------------------------------------------------}
PROCEDURE MAKE_PARAMETER_FILE;

{ -- Creates a file on disk containing parameters for a chosen material -- }

BEGIN

	CLEAN_WINDOW;
	DATE_AND_TIME;

	textbackground(C_back);
	gotoXY(1,2);
	write  ('                                                             ');
	gotoXY(1,2);
	write(' ',Version,'    Creating a new file for   ',filename,'    ',date_string);

	gotoXY(1,5);
	for parnumber := 1 to numberofparameters do BEGIN
		LABELS_FOR_DATA;
		writeln ('  ',parnumber:3,'   ',d,u,'....');
	END;

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
			read(par[parnumber]);

			gotoXY (47,4+parnumber);
			TextBackground(C_back);  
			write('            ');

			gotoXY (47,4+parnumber);
			Textcolor(C_bright);
			write(par[parnumber]:12);
		END;

{ -------- Create default wherever zeros entered in parameter file --------}

	for parnumber := 1 to numberofparameters do
		BEGIN
			if par[parnumber] = 0.0 then
				BEGIN
					case parnumber of
						1 : par[1] := 1500;
						2 : par[2] := 1.3e-3;
						3 : par[3] := 0.033*par[1];
						4 : par[4] := 0.5;
						5 : par[5] := 6.0e-3;
						6 : par[6] := 6.0e-3;
						7 : par[7] := 1.8e-29;
						8 : par[8] := 1.0e-4;
						9 : par[9] := 18*R*par[1]/1000;
						10	: par[10] := exp(ln(par[7])/3)*par[8];
						11 : par[11] := 11*R*par[1]/1000;
						12 : par[12] := 1.0e-23;
						13 : par[13] := par[11];
						14 : par[14] := 3.0;
						15 : par[15] := 1000*par[5]*par[3]/2;
						16 : par[16] := par[9];
						17 : par[17] := 3.5e-10;
					END;	{	Case	}
				END;
		END;
	LIST_PARAMETERS;

{ -------- Save the file -------- }

	Prompt_Save;
	if answer in ['y','Y'] then SaveParFile(parfilename);

{ ------- List the file for inspection and Editing ------- }
	EDIT_PARAMETERS;

END; {MAKE_PARAMETER_FILE.    }
{-------------------------------------------------------------------}
PROCEDURE MAKE_VARIABLE_FILE;

{ -- Creates a file on disk containing variables for a chosen material -- }

BEGIN

	CLEAN_WINDOW;
	DATE_AND_TIME;

	textbackground(C_back);
	gotoXY(1,2);
	write  ('                                                             ');
	gotoXY(1,2);
	write(' ',Version,'    Creating a new file for   ',filename,'    ',date_string);

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
			read(vbl[vblnumber]);

			gotoXY (47,4+vblnumber);
			TextBackground(C_back);  
			write('            ');

			gotoXY (47,4+vblnumber);
			Textcolor(C_bright);
			write(vbl[vblnumber]:12);
		END;

{ -------- Create default wherever zeros entered in variable file --------}

	for vblnumber := 1 to numberofvariables do
		BEGIN
			if vbl[vblnumber] = 0.0 then
				BEGIN

					case vblnumber of
						1 : vbl[1] := 1;
						2 : vbl[2] := 0.0;
						3 : vbl[3] := 0.0;
						4 : vbl[4] := 0.0;
						5 : vbl[5] := 1.0e-4;	{100 microns}
						6 : vbl[6] := 0.0;
						7 : vbl[7] := 0.0;
						8 : vbl[8] := 1.0;
						9 : vbl[9] := 1.0e-4;
						10 : vbl[10] := 1.0e-1;
						11 : vbl[11] := 0.0;
						12 : vbl[12] := 0.0;
						13 : vbl[13] := 1.0;
						14 : vbl[14] := 1.0e-7;
						15 : vbl[15] := 10;
						16 : vbl[16] := 10;
						17 : vbl[17] := 40;

					END;	{	Case	}
					if (vbl[8] > 100) then vbl[8] := 100;
				END;
		END;
	LIST_VARIABLES;

{ -------- Save the file -------- }

	Prompt_Save;
	if answer in ['y','Y'] then SaveVblFile(vblfilename);

{ ------- List the file for inspection and Editing ------- }

	EDIT_VARIABLES;

END; {MAKE_VARIABLE_FILE.   }
{-------------------------------------------------------------------}
PROCEDURE READ_PARAMETER_FILE;

{ -------- Read in the chosen  parameter file -------- }
VAR
	infile	:	TEXT;
BEGIN
	Assign (infile,parfilename);    
	Reset (infile);

	FOR parnumber:= 1 TO numberofparameters DO
		READLN(infile, par[parnumber]);
	Close(infile);

{ ------- Display the file for inspection and editing ------- }

	IF NOT modefast THEN 
		BEGIN
			LIST_PARAMETERS;
			EDIT_PARAMETERS;
		END;

END;  {READ_PARAMETER_FILE.    }
{-------------------------------------------------------------------}
PROCEDURE READ_VARIABLE_FILE;

{ -------- Read in the chosen variable file -------- }

VAR
	infile	:	TEXT;
BEGIN
	Assign (infile,vblfilename);    
	Reset (infile);

	FOR vblnumber:= 1 TO numberofvariables DO
		READLN(infile, vbl[vblnumber]);
	Close(infile);

{ ------- Display the file for inspection and editing ------- }

	IF NOT modefast THEN 
		BEGIN
			LIST_VARIABLES;
			EDIT_VARIABLES;
		END;

END;  {READ_VARIABLE_FILE.    }
{-------------------------------------------------------------------}
PROCEDURE CHECK_PARAMETERS;

{ -------- Checks input data against limits -------- }
VAR
	lf	:	Text;

BEGIN

	CLEAN_WINDOW;

	textbackground(C_back);
	gotoXY(1,2);
	write  ('                                                             ');
	gotoXY(1,2);
	write(' ',Version,'     CHECK  ON  INPUT DATA  FOR   ');
	textcolor(C_bright);
	write(filename);
	gotoXY(1,5); 
	for parnumber := 1 to numberofparameters do
		BEGIN
			LABELS_FOR_DATA;

			case parnumber of
				1 : BEGIN L1 := 500;					L2 := 4000					END;
				2 : BEGIN L1 := 1.0e-4;				L2 := 0.1					END;
				3 : BEGIN L1 := 5;		 			L2 := 500				 	END;
				4 : BEGIN L1 := 0.1;					L2 := 0.95					END;
				5 : BEGIN L1 := 1.0e-4;				L2 := 0.1				 	END;
				6 : BEGIN L1 := 0.0;					L2 := 0.2					END;
				7 : BEGIN L1 := 1.0E-29;			L2 := 5.0E-29				END;
				8 : BEGIN L1 := 1.0E-10;			L2 := 1.0					END;
				9 : BEGIN L1 := 8*R*par[1]/1000;	L2 := 34*R*par[1]/1000;	END;
				10 : BEGIN L1 := 1.0E-17;			L2 := 1.0E-8				END;
				11 : BEGIN L1 := 0.38*par[9];		L2 := 1.0*par[9]			END;
				12 : BEGIN L1 := 1.0E-26;			L2 := 1.0E-20				END;
				13 : BEGIN L1 := 0.38*par[9];		L2 := par[9]				END;
				14 : BEGIN L1 := 3.0;				L2 := 15.0					END;
				15 : BEGIN L1 := 1.0e3*par[3]*par[2]/8;	
															L2 := 5.0e3*par[3]*par[2]	END;
				16 : BEGIN L1 := 0.6*par[9];		L2 := 2.0*par[9]			END;
				17 : BEGIN L1 := 2.0e-10;			L2 := 10.0e-10				END;
			END;

			if (par[parnumber] < L1) or (par[parnumber] > L2) then BEGIN
				modeconcern:=TRUE;
				writeln ('    ',d,'  outside expected range      ');
				writeln('       ',d,'=',par[parnumber]:12,'  ',u);
				writeln('       Anticipated  Range          =',L1:12,'  ',u);
				writeln('                                 to ',L2:12,'  ',u);
				IF modelist AND NOT modelistfile then
					BEGIN
						writeln(lst,'       PARAMETER',parnumber:3,' OUTSIDE EXPECTED RANGE.');
						writeln(lst,'       ',d,'=',par[parnumber]:12,'  ',u);
						writeln(lst,'       Anticipated  Range          =',L1:12,' to ',L2:12,'  ',u);
						writeln(lst);
					END;
				IF modelistfile THEN
					BEGIN
						Assign(lf,listfilename);
						Append(lf);
						writeln(lf,'       PARAMETER',parnumber:3,' OUTSIDE EXPECTED RANGE.');
						writeln(lf,'       ',d,'=',par[parnumber]:12,'  ',u);
						writeln(lf,'       Anticipated  Range          =',L1:12,' to ',L2:12,'  ',u);
						writeln(lf);
						Close(lf);
					END;
			END;
		END;

	for vblnumber := 1 to numberofvariables do
		BEGIN

			LABELS_FOR_VARIABLES;

			case vblnumber of
				1 : BEGIN L1 := 1;				L2 := 30		 END;
				2 : BEGIN L1 := 0.0;				L2 := 0.0	 END;
				3 : BEGIN L1 := 0.0;				L2 := 0.0	 END;
				4 : BEGIN L1 := 0.0;				L2 := 0.0	 END;
				5 : BEGIN L1 := 1.0E-8;			L2 := 1.0E-2;END;
				6 : BEGIN L1 := 0.0;				L2 := 0.0	 END;
				7 : BEGIN L1 := 0.0;				L2 := 0.0	 END;
				8 : BEGIN L1 := 0;				L2 := 1.0e6	 END;
				9 : BEGIN L1 := 1.0e-14;		L2 := 0.01	 END;
				10 : BEGIN L1 := 0.0001;		L2 := 1		 END;
				11 : BEGIN L1 := 0.0;			L2 := 0.0	 END;
				12 : BEGIN L1 := 0.0;			L2 := 0.9	 END;
				13 : BEGIN L1 := 0.1;			L2 := 1.0	 END;
				14 : BEGIN L1 := 1.0e-16; 		L2 := 1.0e3	 END;
				15 : BEGIN L1 := 1.1;			L2 := 1.0e4	 END;
				16 : BEGIN L1 := 1;				L2 := 30		 END;
				17 : BEGIN L1 := 10;				L2 := 300	 END;
			END;

			if (vbl[vblnumber] < L1) or (vbl[vblnumber] > L2) then
				BEGIN
					writeln ('   ',d,'  outside expected range     ');
					writeln('       ',d,'=',vbl[vblnumber]:12,'  ',u);
					writeln('       Anticipated  Range          =',L1:12,'  ',u);
					writeln('                                 to ',L2:12,'  ',u);
					IF modelist AND NOT modelistfile then
						BEGIN
							writeln(lst,'       VARIABLE ',vblnumber:3,' OUTSIDE EXPECTED RANGE.');
							writeln(lst,'       ',d,'=',vbl[vblnumber]:12,'  ',u);
							writeln(lst,'       Anticipated  Range          =',L1:12,' to ',L2:12,'  ',u);
							writeln(lst);
						END;
					IF modelistfile THEN
						BEGIN
							Assign(lf,listfilename);
							Append(lf);
							writeln(lf,'       VARIABLE ',vblnumber:3,' OUTSIDE EXPECTED RANGE.');
							writeln(lf,'       ',d,'=',vbl[vblnumber]:12,'  ',u);
							writeln(lf,'       Anticipated  Range          =',L1:12,' to ',L2:12,'  ',u);
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

BEGIN

	DATE_AND_TIME;

	writeln(lst,'      =============================================================');
	writeln(lst,'         ',Version,'     INPUT  PARAMETERS for  ',filename,'    ',Date_string);
	writeln(lst,'      =============================================================');
	writeln(lst);
	for parnumber := 1 to numberofparameters do BEGIN

	LABELS_FOR_DATA;

	writeln (lst,'        ',parnumber:3,'  ', d, u,' =', par[parnumber]:12);
	END;
	writeln(lst);
	writeln(lst,'       =============================================================');
	writeln(lst,'                                                      Time ',time_string);
	writeln(lst);  writeln(lst);  writeln(lst);  writeln(lst);

	writeln(lst,'      =============================================================');
	writeln(lst,'         ',Version,'     INPUT  VARIABLES for  ',filename,'     ',Date_string);
	writeln(lst,'      =============================================================');
	writeln(lst);
	for vblnumber := 1 to numberofvariables do BEGIN

	LABELS_FOR_VARIABLES;

	writeln (lst,'        ',vblnumber:3,'  ', d, u,' =', vbl[vblnumber]:12);
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

BEGIN

	DATE_AND_TIME;
	Assign(lf,listfilename);
	Rewrite(lf);

	writeln(lf,'      =============================================================');
	writeln(lf,'         ',Version,'     INPUT  PARAMETERS for  ',filename,'    ',Date_string);
	writeln(lf,'      =============================================================');
	writeln(lf);
	for parnumber := 1 to numberofparameters do BEGIN

	LABELS_FOR_DATA;

	writeln (lf,'        ',parnumber:3,'  ', d, u,' =', par[parnumber]:12);
	END;
	writeln(lf);
	writeln(lf,'       =============================================================');
	writeln(lf,'                                                      Time ',time_string);
	writeln(lf);  writeln(lf);  writeln(lf);  writeln(lf);

	writeln(lf,'      =============================================================');
	writeln(lf,'         ',Version,'     INPUT  VARIABLES for  ',filename,'     ',Date_string);
	writeln(lf,'      =============================================================');
	writeln(lf);
	for vblnumber := 1 to numberofvariables do BEGIN

	LABELS_FOR_VARIABLES;

	writeln (lf,'        ',vblnumber:3,'  ', d, u,' =', vbl[vblnumber]:12);
	END;
	writeln(lf);
	writeln(lf,'       =============================================================');
	writeln(lf,'                                                      Time ',time_string);
	writeln(lf);  writeln(lf);  writeln(lf);  writeln(lf);

	Close(lf);

END; {INPUT_DATA_TO_FILE.    }

End.	{	Unit BUGfiles	}
