{-------------------------------------------------------------------}
{ PMS 3-May-1988 18:38 }
{	fixpar.pas	}
{ Takes a textised copy of a DFM material data file and fixes
	changes.	}
{-------------------------------------------------------------------}

{$N-}

Program fix(input,output);

VAR
	file_out	:	Text;
	file_in	:	Text;
	n			:	real;
	mu0		:	real;
	d, u		:	String;
	items, i	:	Word;
	new, old		:	ARRAY[1..17] OF Real;

{-------------------------------------------------------------------}
PROCEDURE LABELS_FOR_DATA (parnumber: Word);

{ Sets up character strings with names of variables and their units }

BEGIN

	case parnumber of
	1 : BEGIN d:='Melting Point               ';  u:='K         'END;
	2 : BEGIN d:='T-dependence of Modulus     ';  u:='          'END;
	3 : BEGIN d:='Shear Modulus @ 0 K         ';  u:='GPa       'END;
	4 : BEGIN d:='0K Flow Stress (lattice)    ';  u:='          'END;
	5 : BEGIN d:='0K Flow Stress (obstacles)  ';  u:='          'END;
	6 : BEGIN d:='Lattice  Glide Actv. Energy ';  u:='(mu.b^3)  'END;
	7 : BEGIN d:='Obstacle Glide Actv.Energy  ';  u:='(mu.b^3)  'END;
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
	18 : BEGIN d:='Atomic Volume               ';  u:='m^3       'END;
	END;

END;  {LABELS_FOR_DATA;    }
{-------------------------------------------------------------------}

BEGIN	{ Program par_Text	}
	IF ParamCount <> 2 THEN
		BEGIN
			WRITELN ('Specify two filenames, e.g.');
			WRITELN ('fixpar \olddata\copper.ppp \textdata\copper.p');
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
				READLN(file_in, n);
				old[i]:=n;
				i:=i+1;
			UNTIL EOF(file_in);
			items := i-1;
			Close (file_in);

			mu0 :=old[3]* (1+(300/old[1])*old[2]);

			i:=1;
			REPEAT
				Labels_for_data (i);
				n := old[i];
				CASE i OF
					3:	n:=mu0;
					2:	n:= old[2]*old[3]/mu0;
				END;	{	Case	}
				WRITELN(file_out, n,' ''',d,''' ''',u,'''');
				i:=i+1;
			UNTIL (i = items+1);

			Labels_for_data (i);	{	adding an item at the end	}
			n:=old[7];
			WRITELN(file_out, n,' ''',d,''' ''',u,'''');
			Close (file_out);

		END;

END.	{	Program fix	}

