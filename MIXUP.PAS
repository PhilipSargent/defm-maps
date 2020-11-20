{-------------------------------------------------------------------}
{ PMS 25-June-1988 15:17 }
{	Mixup.pas	}
{	Takes a file of 34-character strings and mixes them up in
	a random order.	}
{-------------------------------------------------------------------}

{$N-}

Program Mixup(input,output);

Uses
	Dos;

CONST
	title		=	'Mixup v1.1   25 June 1988  (C) CUED Materials Group';
	lines		=	700;

TYPE
	T_line		=	String [34];
	T_data		=	ARRAY [1..lines] OF T_line;
	T_tag			=	ARRAY [1..lines] OF BOOLEAN;
	
VAR
	file_in, file_out	:	Text;
	line		:	T_line;
	pack		:	T_data;
	tag		:	T_tag;
	mixfile,packfile	:	String;
	i, n		:	Word;
	total, index		:	0..lines;

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

BEGIN	{ Program Mixup	}
	WRITELN(title);

	packfile:='matlpars.dat';
	mixfile :='matlpars.mix';
	IF ParamCount > 2 THEN
		BEGIN
			WRITELN ('Just type Mixup on its own, and');
			WRITELN
				('it automatically reads the file packdata.dat');
			WRITELN('or type Mixup <datafilename>');
			Halt(1);
		END
	ELSE IF ParamCount = 2 THEN
		BEGIN
			packfile:=ParamStr(1);
			mixfile:=ParamStr(2);
		END;

	IF FileNotThere(packfile) THEN
		BEGIN
			WRITELN('Cannot open data file:',packfile);
			Halt(2);
		END;

	IF CannotOpen(mixfile) THEN
		BEGIN
			WRITELN('Cannot open file for the mixed-up data "',mixfile,
				'" Disc full ?');
			Halt(2);
		END;

	Assign(file_in, packfile);
	Reset(file_in);

	index := 1;
	REPEAT
		READLN(file_in, pack[index]);
{		WRITELN(pack[index]);	}
		tag[index] := TRUE;
		index := index+1;
	UNTIL (index >lines) OR Eof(file_in);
	total := index - 1;

	IF NOT Eof(file_in) THEN
		WRITELN(' More than ',lines:6,' lines. Extra lost.');
	Close(file_in);

	Assign(file_out, mixfile);
	Rewrite(file_out);

{	Write a whole load of lines in random order, tag each one as
	FALSE once it is written.	}
	Randomize;
	FOR i := 1 TO total*4 DO
		BEGIN
			index := random(total);
			index := index+1;
			IF tag[index] THEN
				BEGIN
					WRITELN(file_out,pack[index]);
					tag[index] := FALSE;
				END;
		END;

{	Now write out all the remaining lines	}
	n:=0;
	FOR index := 1 TO total DO
		IF tag[index] THEN
			BEGIN
				WRITELN(file_out,pack[index]);
				n := n+1;
			END;
	WRITELN(n:3,' dropped through.. OK.');

{	WRITELN(file_out);	}
	Close(file_out);

END.	{	Program Mixup	}


