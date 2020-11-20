{-------------------------------------------------------------------}
{ PMS 6-May-1988 18:55 }
{	fixvbl.pas	}
{-------------------------------------------------------------------}

{$N-}

Program FixVbl(input,output);

VAR
	file_out	:	Text;
	file_in	:	Text;
	n	:	real;
	d, u	:	String;
	i	:	Word;
	old	:	ARRAY [1..17] OF Real;

{-------------------------------------------------------------------}
PROCEDURE LABELS_FOR_VARIABLES (vblnumber: Word);

{ Sets up character strings with names of variables and their units }

BEGIN

	case vblnumber of
	1 : BEGIN d:='IMC number                  ';  u:='          'END;
	2 : BEGIN d:='                            ';  u:='          'END;
	3 : BEGIN d:='                            ';  u:='          'END;
	4 : BEGIN d:='                            ';  u:='          'END;
	5 : BEGIN d:='Grain size                  ';  u:='m         'END;
	6 : BEGIN d:='                            ';  u:='          'END;
	7 : BEGIN d:='                            ';  u:='          'END;
	8 : BEGIN d:='                            ';  u:='          'END;
	9 : BEGIN d:='Lower limit, S/SY axis      ';  u:='          'END;
	10 : BEGIN d:='Upper limit, S/SY axis      ';  u:='          'END;
	11 : BEGIN d:='                            ';  u:='          'END;
	12 : BEGIN d:='Lower limit, T/TM axis      ';  u:='          'END;
	13 : BEGIN d:='Upper limit, T/TM axis      ';  u:='          'END;
	14 : BEGIN d:='First strain-rate contour   ';  u:='1/s       'END;
	15 : BEGIN d:='Multiplier: strain rates    ';  u:='          'END;
	16 : BEGIN d:='Number strain-rate contours ';  u:='          'END;
	17 : BEGIN d:='Number of Program Steps     ';  u:='          'END;
	END;

END;  {LABELS_FOR_VARIABLES;     }
{-------------------------------------------------------------------}

BEGIN	{ Program Vbl_Text	}
	IF ParamCount <> 2 THEN
		BEGIN
			WRITELN ('Specify two filenames, e.g.');
			WRITELN ('FixVbl \olddata\copper.vbl \newdata\copper.vbl');
		END
	ELSE IF ParamStr(1) = ParamStr(2) THEN
		WRITELN ('The two filenames should be different.')
	ELSE
		BEGIN

			Assign(file_in, ParamStr(1));
			Reset(file_in);
			Assign(file_out, ParamStr(2));
			Rewrite(file_out);

			i:=1;
			REPEAT
				Labels_for_variables (i);
				READLN(file_in, n);
				old[i]:=n;
				CASE i OF
				9:		n:= 1.0e-6;
				10:	n:= 1.0e-2;
				END;	{	Case	}
				WRITELN(file_out, n,' ''',d,''' ''',u,'''');
				i:=i+1;
			UNTIL EOF(file_in);
			Close (file_in);
			Close (file_out);

		END;

END.	{	Program fixvbl	}

