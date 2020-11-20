{-------------------------------------------------------------------}
{ PMS 24-June-1988 21:41 }
{	Scan.pas	}
{	Reads a possibly mixed-up file (table) of data and scans for
	lines of interest.	}
{-------------------------------------------------------------------}

{$N-}

Program Scan(input,output);

Uses
	Dos, Crt;

TYPE
	T_set_chars	=	SET OF #0..#255;
	T_name		=	String[9];

	P_Stack		=	^T_Stack;
	T_Stack		=	RECORD
							s		:	String;
							next	:	P_Stack;
						END;

CONST
	title		=	'Scan v1.0   24 June 1988  (C) CUED Materials Group';
	S_spaces: T_set_chars	
					=	[ ' ', #9 ];			{ space or tab	}
	N_par		=	18;

VAR
	file_in, file_out	:	Text;
	S_buf		:	String;
	infile,outfile	:	String;
	i			:	Word;
	stack		: P_stack; 
	list		:	ARRAY [1..200] OF T_name;
	n_list	:	0..200;

{-------------------------------------------------------------------}
PROCEDURE LABELS_FOR_DATA (parnumber: Word; VAR id: String);

{ Sets up character strings with names of variables and their units }

BEGIN

	case parnumber of
		1 : id:='T-melt';
		2 : id:='T-dep'; 
		3 : id:='ShrMod';
		4 : id:='LatSrs';
		5 : id:='ObsSrs';
		6 : id:='LatErg';
		7 : id:='ObsErg';
		8 : id:='VolD0'; 
		9 : id:='VolErg';
		10 : id:='BdyD0';
		11 : id:='BdyErg';
		12 : id:='CorD0';
		13 : id:='CorErg';
		14 : id:='n-plc';
		15 : id:='Srsplc';
		16 : id:='plcErg';
		17 : id:='Burgr';
		18 : id:='Omega';
	END;

END;  {LABELS_FOR_DATA;    }
{-------------------------------------------------------------------}
PROCEDURE NUMBER_FOR_DATA (VAR parnumber: Word; id: String);

{	Finds the parameter number given a parameter id	}
VAR
	i		:	Word;
	ck		:	String;
BEGIN
	i:= 1;
	REPEAT
		Labels_for_data(i,ck);
		parnumber := i;
		i := i+1;
	UNTIL (i > N_par+1 ) OR (ck=id);

	IF (i > N_par+1) THEN
		parnumber := 0;

END;  {NUMBER_FOR_DATA;    }
{-------------------------------------------------------------------}
PROCEDURE Push_Str (VAR stack: P_stack; s: String);
VAR
	add	:	T_stack;
BEGIN
END;	{	Push_Str	}
{-------------------------------------------------------------------}
PROCEDURE Pop_Str (VAR stack: P_stack; VAR s: String);
BEGIN
END;	{	Pop_Str	}
{-------------------------------------------------------------------}
FUNCTION	strip	(s: String): String;
{	strips the leading spaces from a string	}
VAR
	i	:	Byte;
	s2	:	String;
BEGIN
{	Count the number of spaces at the beginning of the string.
	(	The trick with the index set to 0 is to prevent this function
		choking on strings exactly 254 characters long.)
}
	i := 0;
	WHILE ( s[i+1] IN S_spaces ) DO {	tabs or spaces	}
		i := i+1;

{	Now copy the string, starting at the first non-blank character	}
	s2 := Copy (s, i+1, Length(s)-i );
	strip := s2;
END;	{	strip	}
{-------------------------------------------------------------------}
FUNCTION get_next_token (VAR line: String): String;
{	returns the first space/tab delimited string from 'line' as the
	result of the function.  Also returns what remains of 'line', after
	removing the first token, as the VAR parameter.	}
VAR
	i		:	Byte;
	s, s2	:	String;

BEGIN
{	remove leading spaces, work with a copy of the buffer	}
	s := strip(line);

{	find next space, which will delimit the number	}
	i := 0;
	REPEAT
		i := i + 1;
	UNTIL ( s[i] IN S_spaces) OR (i = Length(s) );

	IF ( s[i] IN S_spaces) THEN
		i := i-1;

{	Copy the substring which contains the token	}
	s2 := Copy (s, 1, i);

{	Trim this substring from line, which is returned to the calling procedure	}
	IF ( i < Length(s) ) THEN
		line := Copy (s, i+1, Length(s)-i)
	ELSE
		line[0] := #0;	{	that was the last number, so line is empty	}

	get_next_token := s2;

END;	{	get_next_token	}
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
PROCEDURE Initialise;
BEGIN
	infile:='mixdata.dat';
	outfile :='scandata.dat';
	stack := NIL;
	n_list := 0;
	ClrScr;
	IF ParamCount > 1 THEN
		BEGIN
			WRITELN ('Just type Scan on its own, and');
			WRITELN
				('it automatically reads the file packdata.dat');
			WRITELN('or type Scan <datafilename>');
			Halt(1);
		END
	ELSE IF ParamCount = 1 THEN
		infile:=ParamStr(1);

	IF FileNotThere(infile) THEN
		BEGIN
			WRITELN('Cannot open data file:',infile);
			Halt(2);
		END;

	IF CannotOpen(outfile) THEN
		BEGIN
			WRITELN('Cannot open file for the output "',outfile,
				'" Disc full ?');
			Halt(2);
		END;
END;	{	Initialise	}
{-------------------------------------------------------------------}
PROCEDURE Process;
VAR
	material, parameter, value, line	:	String;
	parnumber	:	Word;
	found	:	BOOLEAN;
BEGIN
	line := S_buf;

	material := get_next_token(line);
	parameter := get_next_token(line);
	value     := get_next_token(line);

	number_for_data (parnumber, parameter);

	found := FALSE;
	FOR i := 1 TO n_list DO
		IF (material = list[i]) THEN
			found := TRUE;
	IF NOT found THEN
		BEGIN
			n_list := n_list + 1;
			list[n_list] := material;
		END;

	IF material=list[1] THEN
		BEGIN
			GotoXY(1,Byte(parnumber+2));
			WRITE(material,' ',parameter,' ',value);
		END;

{	So you can see that n_list is always the current number of different
	materials in list	}
END;	{	Process	}
{-------------------------------------------------------------------}

BEGIN	{ Program Scan	}
	WRITELN(title);
	Initialise;

	Assign(file_in, infile);
	Reset(file_in);

	REPEAT
		READLN(file_in, S_buf);
		Process;
	UNTIL Eof(file_in);
	Close(file_in);

	GotoXY(1,22);

{	Assign(file_out, outfile);
	Rewrite(file_out);

	Close(file_out);
}

END.	{	Program Scan	}


