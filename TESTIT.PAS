{testit.pas}
{ PMS 26-May-1988 16:23 }

{$R-}    {Range checking off}
{$I+}    {I/O checking on}
{$N-}    {Do NOT use numeric coprocessor}


Program testit(input,output);

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   M.F.Ashby and P.M.Sargent        **************
   *************   April 1988                       **************
}
Uses
  convnum;

VAR
	n		:	REAL;
	i,j,k	:	Byte;
	code	:	Integer;
	s,
	s1,
	s2,
	s3	:	STRING;

BEGIN
		BEGIN
			WRITELN;
			n:= 0.0003;
			FOR i:= 1 to 7 DO
				BEGIN
					n := n*197;
					FOR j := 1 TO 2 DO
						BEGIN
							n:= -n;
							WRITE (n:15);
							convert_number (n,s1,-1);
							convert_number (n,s2,0);
							convert_number (n,s3,1);
							WRITELN ('  "',s1,'"    "',s2,'"    "',s3,'"');
						END;
				END;
		END;

	REPEAT
		WRITE('>');
		READLN (s);
		Val(s,n,code);
		IF (code = 0) THEN
			BEGIN
				convert_number (n,s1,-1);
				convert_number (n,s2,0);
				convert_number (n,s3,1);
				WRITELN ('  "',s1,'"    "',s2,'"    "',s3,'"');
			END
		ELSE
			BEGIN
				writeln(s);
				FOR i := 1 TO code-1 DO
					write (' ');
				writeln('^      ---- ERROR');
			END;

	UNTIL FALSE;

END.

{	end of testit.pas	}
