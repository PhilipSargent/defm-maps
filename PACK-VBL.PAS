{-------------------------------------------------------------------}
{ PMS 25-June-1988 12:12 }
{	Pack-r.pas	}
{	Packs a load of VBL and PAR files	}
{-------------------------------------------------------------------}

{$N-}

Program Pack(input,output);

Uses
	Dos;

CONST
	title		=	'PACK-R v1.1   24 June 1988  (C) CUED Materials Group';

VAR
	packed_data	:	Text;
	pack_list	:	Text;
	file_input, file_out	:	Text;
	name		:	String[9];
	full_name:	String[13];
	listfile,packfile	:	String;
	real_number	:	real;
	dt				:	DateTime;


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
PROCEDURE LABELS_FOR_DATA (parnumber: Word; VAR d,u,id: String);

{ Sets up character strings with names of variables and their units }

BEGIN

	case parnumber of
	1 : BEGIN id:='T-melt'; d:='Melting Point               ';  u:='K         'END;
	2 : BEGIN id:='T-dep '; d:='T-dependence of Modulus     ';  u:='          'END;
	3 : BEGIN id:='ShrMod'; d:='Shear Modulus @ 0 K         ';  u:='GPa       'END;
	4 : BEGIN id:='LatSrs'; d:='0K Flow Stress (lattice)    ';  u:='          'END;
	5 : BEGIN id:='ObsSrs'; d:='0K Flow Stress (obstacles)  ';  u:='          'END;
	6 : BEGIN id:='LatErg'; d:='Lattice  Glide Actv. Energy ';  u:='(mu.b^3)  'END;
	7 : BEGIN id:='ObsErg'; d:='Obstacle Glide Actv.Energy  ';  u:='(mu.b^3)  'END;
	8 : BEGIN id:='VolD0 '; d:='Pre-exp. Volume Diffusion   ';  u:='m^2/s     'END;
	9 : BEGIN id:='VolErg'; d:='Activ. energy, Vol. Diff.   ';  u:='kJ/mol    'END;
	10 : BEGIN id:='BdyD0 '; d:='Pre-exp. Bdry Diffusion     ';  u:='m^3/s     'END;
	11 : BEGIN id:='BdyErg'; d:='Activ. energy, Bdry. Diff.  ';  u:='kJ/mol    'END;
	12 : BEGIN id:='CorD0 '; d:='Pre-exp. Core Diffusion     ';  u:='m^4/s     'END;
	13 : BEGIN id:='CorErg'; d:='Activ. energy, Core  Diff.  ';  u:='kJ/mol    'END;
	14 : BEGIN id:='n-plc '; d:='Power Law Creep Exponent    ';  u:='          'END;
	15 : BEGIN id:='Srsplc'; d:='Reference stress, P-L creep ';  u:='MPa       'END;
	16 : BEGIN id:='plcErg'; d:='Activ. energy for P-L creep ';  u:='kJ/mol    'END;
	17 : BEGIN id:='Burgr '; d:='Burgers vector              ';  u:='m         'END;
	18 : BEGIN id:='Omega '; d:='Atomic Volume               ';  u:='m^3       'END;
	END;

END;  {LABELS_FOR_DATA;    }
{-------------------------------------------------------------------}
PROCEDURE LABELS_FOR_VARIABLES (vblnumber: Word; VAR d,u,id: String);

{ Sets up character strings with names of variables and their units }

BEGIN

	case vblnumber of
	1	: BEGIN id:='IMC   '; d:='IMC number                  ';  u:='          'END;
	2	: BEGIN id:='';       d:='  <...unused...>            ';  u:='          'END;
	3	: BEGIN id:='';       d:='  <...unused...>            ';  u:='          'END;
	4	: BEGIN id:='';       d:='  <...unused...>            ';  u:='          'END;
	5	: BEGIN id:='DfmGsz'; d:='Grain size                  ';  u:='m         'END;
	6	: BEGIN id:='';       d:='  <...unused...>            ';  u:='          'END;
	7	: BEGIN id:='';       d:='  <...unused...>            ';  u:='          'END;
	8	: BEGIN id:='';       d:='  <...unused...>            ';  u:='          'END;
	9	: BEGIN id:='DfmSy-'; d:='Lower limit, S/SY axis      ';  u:='          'END;
	10 : BEGIN id:='DfmSy+'; d:='Upper limit, S/SY axis      ';  u:='          'END;
	11 : BEGIN id:='';       d:='  <...unused...>            ';  u:='          'END;
	12 : BEGIN id:='DfmT- '; d:='Lower limit, T/TM axis      ';  u:='          'END;
	13 : BEGIN id:='DfmT+ '; d:='Upper limit, T/TM axis      ';  u:='          'END;
	14 : BEGIN id:='DfmCn1'; d:='First strain-rate contour   ';  u:='1/s       'END;
	15 : BEGIN id:='DfmCn*'; d:='Multiplier: strain rates    ';  u:='          'END;
	16 : BEGIN id:='DfmCnN'; d:='Number strain-rate contours ';  u:='          'END;
	17 : BEGIN id:='DfmStN'; d:='Number of Program Steps     ';  u:='          'END;
	END;

END;  {LABELS_FOR_VARIABLES;     }
{-------------------------------------------------------------------}
PROCEDURE PutFileComplete(VAR f: Text; s: String; name: String);
VAR
	n, r, b		:	integer;
	real_number	:	Real;
	date_stamp	:	LongInt;
	i				:	Word;
	ff				:	FILE;
	id, d, u		:	String;

BEGIN
{ -----	Check file exists, & get Date. See Turbo 4.0 Manual pp464-465	}
	{$I-}
	Assign(ff,s);
	Reset(ff);
	GetFTime(ff,date_stamp);
	UnPackTime(date_stamp,dt);
	WRITE(' ',dt.hour:2,' ',dt.min:2,':',dt.sec:2);

	Close(ff);
	{$I+}
	IF NOT ((IOResult=0) AND (name <> '')) THEN
		BEGIN
			WRITELN('Cannot input data file:',s);
			Halt(2);
		END;

	Assign(file_input, s);
	Reset(file_input);


{ -----	Now write the data itself	}
	FOR i := 1 TO 18 DO
		BEGIN
			Labels_for_variables (i, d, u, id);
			READLN(file_input,real_number);
			IF (id <>'') THEN
				WRITELN(packed_data,name,' ',id,' ',real_number);
		END;
	Close(file_input);

END;	{	PutFileComplete	}

{-------------------------------------------------------------------}

BEGIN	{ Program Pack	}
	WRITELN(title);

	listfile:='packlist.lst';
	packfile:='packdata.vbl';
	IF ParamCount > 1 THEN
		BEGIN
			WRITELN ('Just type PACK on its own, and');
			WRITELN
				('it automatically reads the list of data names in packlist.lst');
			WRITELN('or type PACK <listfilename>');
			Halt(1);
		END
	ELSE IF ParamCount = 1 THEN
		listfile:=ParamStr(1);

	IF FileNotThere(listfile) THEN
		BEGIN
			WRITELN('Cannot open file containing list of filenames:',listfile);
			Halt(2);
		END;

	IF CannotOpen(packfile) THEN
		BEGIN
			WRITELN('Cannot open file for the packed data "',listfile,
				'" Disc full ?');
			Halt(2);
		END;

	Assign(pack_list, listfile);
	Reset(pack_list);
	Assign(packed_data, packfile);
	Rewrite(packed_data);

	REPEAT
		REPEAT
			READLN(pack_list, name);
		UNTIL (name<>'') OR Eof(pack_list);

		IF NOT Eof(pack_list) THEN
			BEGIN
		      write(name);

				full_name:=name+'.v';
				PutFileComplete(packed_data,full_name,name);

				WRITELN;
			END;
	UNTIL EOF(pack_list);
	Close(Pack_list);
	WRITELN(packed_data);
	Close(packed_data);

END.	{	Program pack	}

