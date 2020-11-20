{-------------------------------------------------------------------}
{ PMS 7-April-1988 19:42 }
{	par-txt.pas	}
{ Takes a textised copy of a HIP material data file and "converts"
  it to be a first-stab material data file for a defm.map           }
{-------------------------------------------------------------------}

{$N-}

Program par_Text(input,output);

VAR
	file_out	:	Text;
	file_in	:	Text;
	n	:	real;
	d, u	:	String;
	i	:	Word;
	old	:	ARRAY[1..17] OF Real;

{-------------------------------------------------------------------}
PROCEDURE LABELS_FOR_DATA (parnumber: Word);

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

BEGIN	{ Program par_Text	}
	IF ParamCount <> 2 THEN
		BEGIN
			WRITELN ('Specify two filenames, e.g.');
			WRITELN ('txt-real \olddata\copper.ppp \textdata\copper.p');
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
				Labels_for_data (i);
				READLN(file_in, n);
				old[i]:=n;
				CASE i OF
				2:	n:=1.3e-3;
				3:	n:=0.33*n;
				5:	n:=6.0e-3;
				6:	n:=6.0e-2;
				12:	n:=1.0e-23;
				13:	n:=old[11];
				17:	n:=exp(0.333*ln(old[7]/1.3));
				END;	{	Case	}
				WRITELN(file_out, n,' ''',d,''' ''',u,'''');
				i:=i+1;
			UNTIL EOF(file_in);
			Close (file_in);
			Close (file_out);

		END;

END.	{	Program par-txt	}

