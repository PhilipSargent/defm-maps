Unit StringIO;
{ PMS 25-March-1990 00:30 }
{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   P.M.Sargent                      **************
   *************   June 1988                        **************
}

{ &&R+}    {Range checking on}
{ &&B+}		{Boolean complete evaluation on}
{ &&S+}		{Stack checking on}
{ &&I+}		{I/O checking on}
{ &&N+}    {Use numeric coprocessor}
{ &&E+}		{Include copy of 8087 Emulator - default anyway}

Interface
Uses
	Crt;

	CONST
	C_Esc	=	#27;		{	Escape key	}
	C_CtrlC	=	#3;  	{	^C, 'Break' key	}
	C_blank	=	' ';	{	blank character to show width	}

TYPE
{$IFOPT N-}
	a_real	=	REAL;
{$ELSE}
	a_real	=	DOUBLE;
{$ENDIF}

PROCEDURE UpperCase (VAR s : String);
{	This changes a string all to upper case	}

PROCEDURE convert_number(number : a_real; 
				VAR display_number : STRING;
				justify : INTEGER);

FUNCTION Read_String (width, len: Byte; VAR escape: BOOLEAN): String;
{	Bullet-proof input for strings in a given field-width.  The width
	and string length are both given because I am planning a new
	version which scrolls longer strings within a smaller width	}

FUNCTION Read_Int (min,max: INTEGER; VAR escape: BOOLEAN): INTEGER;

FUNCTION Read_Real(VAR escape: BOOLEAN): a_real;

FUNCTION	strip	(s: String): String;
{	strips the leading spaces from a string	}

FUNCTION get_next_token (VAR line: String): String;
{	returns the first space/tab delimited string from 'line' as the
	result of the function.  Also returns what remains of 'line', after
	removing the first token, as the VAR parameter.	}
{===========================================================================}
IMPLEMENTATION

TYPE
	T_set_chars	=	SET OF #0..#255;

CONST
	copyright = '(C) Copyright June 1988 P.M.Sargent';
	Max_length	=	15;
	C_length		=	10;
	C_loge10		=	2.302585093;
	S_spaces: T_set_chars	
					=	[ ' ', #9 ];			{ space or tab	}
{$IFOPT N-}
	max_real				= 1.0e37;
	min_real				= 1.0e-37;
{$ELSE}
	max_real				= 1.0e308;
	min_real				= 1.0e-324;
{$ENDIF}

VAR
	j				:	INTEGER;
	pad, 
	pad_left,
	pad_right	:	Byte;
	left_just	:	BOOLEAN;
	centre_just	:	BOOLEAN;
	factor		:	LongInt;
	result_buffer	: STRING[Max_length];

{---------------------------------------------------------------------------}
PROCEDURE UpperCase (VAR s : String);
VAR
	i	:	Byte;
BEGIN
	FOR i:= 1 TO Length(s) DO
		s[i]:= UpCase(s[i]);
END;	{	UpperCase	}
{-------------------------------------------------------------------}
FUNCTION Read_String (width, len: Byte; VAR escape: BOOLEAN): String;
{	Bullet-proof input for strings in a given field-width.  The width
	and string length are both given because I am planning a new
	version which scrolls longer strings within a smaller width	}
CONST
	k_BS	=	#8;	{	Back-Space, backwards delete	}
	k_CR	=	#13;	{	Carridge-Return	}
	k_L	=	#75;	{	Left arrow, function key	}
	k_H	=	#71;	{	Home, function key	}
	k_B	=	#3;	{	Break or cntrl-C, function key	}
	k_D	=	#83;	{	Delete, function key	}
VAR
	c			:	Char;
	buf		:	String;
	index		:	Byte;
	x_next,x_start, y_start	:	Byte;
	flag		:	(getchr, backsp, delete, endup);
	action	:	(addchr, delchr, delstr, nothing);

	{----------------------------------------------------------------}
PROCEDURE Clear_Field;
VAR
	i	:	Byte;
BEGIN
	GotoXY(x_start,y_start);
	FOR i := 1 TO width DO
		write(C_blank);
	GotoXY(x_start,y_start);
	index := 0;
	x_next := x_start;
	buf[0]:= #0;
END;	{	Clear_Field	}
	{----------------------------------------------------------------}

BEGIN	{	Read_String	}
{	Now find out where we are on the screen so that we can get back
	to it after deleting any bad input	}
	x_start:= WhereX;
	y_start:= WhereY;

	IF (width < 1) THEN
		width := 1;
	IF (len < 1) THEN
		len := 1;

	Clear_Field;
	escape := FALSE;
	REPEAT

{ ----- Detect the key press and classify it ----- }
		flag := getchr;
		c := Readkey;

		IF (c = C_CtrlC) THEN 
			BEGIN
				escape := TRUE;
				Exit;
			END;

		IF (c = #0) THEN	{	function key	}
			BEGIN
				c := Readkey;
				CASE c OF
					k_L			:	flag := backsp;
					k_H,k_D		:	flag := delete;
				END;	{	Case	}
			END
		ELSE
			CASE c OF
				k_BS			:	flag := backsp;
				k_CR			:	flag := endup;
				k_B			:	flag := delete;
			END;	{	Case	}

{ ----- Update the contents of the string buffer based on the input ----- }
		CASE flag OF
			backsp	:	IF (index >= 1) THEN 
								BEGIN
						{	Delete a character and update string length in [0]	}
									index := index-1;
									action := delchr;
									buf[0] := Chr(index);
								END;
			delete	:	BEGIN index := 0; action := delstr; END;
			endup	:	BEGIN Read_String := buf; Exit; END;
			getchr	:
				BEGIN
					IF (index < len) THEN
						BEGIN
						{	Add a character and update string length in [0]	}
							index := index + 1;
							buf[index] := c;
							buf[0] := Chr(index);
							action := addchr;
						END
					ELSE
						action := nothing;
				END;
			ELSE	{ error	} writeln('*** error ***');
		END;	{	Case	}

{ ----- Now display the updated string (no scrolling yet) ----- }
		CASE action OF
			delchr	:	BEGIN 
								x_next := x_next -1;
								GotoXY(x_next, y_start);
								Write (C_blank);
								GotoXY(x_next, y_start);
							END;
			delstr	:	Clear_Field;
			addchr	:	BEGIN 
								GotoXY(x_next, y_start);
								Write (buf[index]); 
								x_next := x_next + 1; 
							END;
			nothing	:	BEGIN { nothing }	END;
			ELSE	{ error	} writeln('*** error ***');
		END;	{	Case	}

	UNTIL FALSE;

END;	{	Read_String	}
{-------------------------------------------------------------------}
FUNCTION Read_Int (min,max: INTEGER; VAR escape: BOOLEAN): INTEGER;

{	Bullet-proof input for integers in a given range. If you want to
	read "long" integers, i.e. > 32767, then it would need re-writing.
	At the moment you cannot pass it a max value greater than 32767
	and so long as your m,ax values are integer constants nothing can
	go wrong.	}
VAR
	i		:	Integer;
	s		:	String;
	code	:	Integer;
	r, decimals	:	a_real;
	c, len, x_start, y_start	:	Byte;
BEGIN
{	Check that we have a valid range, or will loop forever	}
	IF ( max < min ) THEN 
		max := min;

{	Now find out where we are on the screen so that we can get back
	to it after deleting any bad input	}
	x_start:= WhereX;
	y_start:= WhereY;

	len	:= 10;
	escape := FALSE;
	REPEAT
	{	Delete the previous attempt at input	}
		GotoXY(x_start,y_start);
		FOR c := 1 TO len DO
			write(C_blank);
		GotoXY(x_start,y_start);

	{	read a trial string and set variables to be used in checking it	}
	{	we used to use the line:		readln (s);
		but it allowed the user to type in too many characters and muddied
		the screen. Now we use bullet-proof string input:	}

		s := Read_String(10,10,escape);
		IF escape THEN
			Exit;
		Val (s, r, code);
		IF (code = 0) THEN
		{	Have to check that we won't break Trunc()	}
			IF ( r > 2147483647 ) OR ( r < -2147483647 ) THEN
				decimals :=1
			ELSE
				BEGIN
					decimals := r - Trunc(r);
					i := Round(r);
				END;

		len := Length(s);
	UNTIL ((code = 0) AND (decimals = 0 ))
	AND ((i <= max) AND (i >= min));
	Read_Int := i;
END;	{	Read_Int	}
{-------------------------------------------------------------------}
FUNCTION Read_Real(VAR escape: BOOLEAN): a_real;
VAR
	r		:	a_real;
	s		:	String;
	code	:	Integer;
	c, len, x_start, y_start	:	Byte;
BEGIN
	x_start:= WhereX;
	y_start:= WhereY;
	len	:= 10;
	REPEAT
		GotoXY(x_start,y_start);
		FOR c := 1 TO len DO
			write(C_blank);
		GotoXY(x_start,y_start);

	{	we used to use the line:		readln (s);
		but it allowed the user to type in too many characters and muddied
		the screen. Now we use bullet-proof string input:	}

		s := Read_String(10,10,escape);
		IF escape THEN
			Exit;

		Val (s, r, code);
		len := Length(s);
	UNTIL (code = 0) ;
	Read_Real := r;
END;	{	Read_Real	}
{-------------------------------------------------------------------}
{-------------------------------------------------------------------}
PROCEDURE convert_number(number : a_real; 
				VAR display_number : STRING;
				justify : INTEGER);
{ Formally this was TRACE task96 }

VAR { PUBLIC }
	not_negative	: a_real;

{----------------------------------------------------------------------------}

FUNCTION pospower ( num_used : LongInt; num_times : INTEGER ) : a_real;
	{ multiplies number ** exponent in full
		Called by eformat }	

VAR { PUBLIC }
	product,
	multiplier 	: a_real;

BEGIN
	product := 1;
	multiplier := num_used;

	FOR j := 1 TO num_times DO
		BEGIN
			product := product * multiplier;
		END;
	pospower := product
END;

{----------------------------------------------------------------------------}

FUNCTION num_places ( n_number : LongInt; max_places : INTEGER ) : INTEGER;
	{ finds the number of significant places ( from a maximum )
		Called by eformat, simpleform }

VAR { PUBLIC }
	f_number 	: LongInt;

BEGIN
	j := max_places;
	f_number := n_number;

	WHILE ( f_number MOD C_length ) = 0 DO
		BEGIN
			f_number := f_number DIV C_length;
			j := j - 1
		END;
	num_places := j
END;

{----------------------------------------------------------------------------}

PROCEDURE simpleform;
	{ Called by convert_number }

VAR { PUBLIC }
	frontend,
	decimal 		: LongInt;
	integer_places,
	max_d_places,
	decimal_places 	: INTEGER;

BEGIN	{ simpleform }

	frontend := Trunc ( not_negative );
	decimal := Round ( ( not_negative - frontend ) * factor );

	IF  decimal = 0 THEN	{ no decimal part found }
		decimal_places := 0
	ELSE
		BEGIN
			IF frontend > 0 THEN	{ no integer part found }
				integer_places := ( trunc ( LN ( frontend ) / C_loge10 ) ) + 1
			ELSE
				integer_places := 0;

		 	max_d_places := C_length - integer_places - 2;	{ 2 => . and sign }

			IF max_d_places <= 0 THEN
				decimal_places := 0
			ELSE
				BEGIN			{ maximum of C_length-3 decimal places allowed }
					decimal_places := num_places ( decimal, C_length-3 );
					IF decimal_places > max_d_places THEN
						decimal_places := max_d_places
				END
	 END;
	{ END IF }
	IF left_just THEN
		Str ( number : 1 : decimal_places, result_buffer )
	ELSE
		Str ( number : C_length : decimal_places, result_buffer ) ;

	{ adjust for Str's tendency to overshoot it's boundaries }
	IF ( Ord(result_buffer[0]) >  C_length ) THEN
		result_buffer[0] := Chr(C_length)
END;	{ simpleform }

{----------------------------------------------------------------------------}

PROCEDURE eformat;
	{ Called by convert_number }

VAR { PUBLIC }
	tenpower,
	e_decimal_places,
	work_power 		: INTEGER;
	powerinfull,
	realdigit 		: a_real;
	fourdigit 		: LongInt;
	epart 			: STRING[2];
	exponent 		: STRING[3];
	stdform 			: STRING[6];
	four				:	Byte;
	divide			:	Word;

BEGIN	{ eformat }
	four := C_length - 6;	{	so-called because it is 4 when C_length is 10	}

	CASE	four OF
		4	:	divide := 1000;
		3	:	divide := 100;
		2	:	divide := 10;
		1	:	divide := 1;
		ELSE	divide := 1;
	END;	{	Case	}

	IF ( not_negative < 1) THEN
		IF (  not_negative <= min_real*10000 ) THEN
			BEGIN	{	the eformat algorithm overflows, so..	}
				Str ( number : C_length, result_buffer );
				Exit;
			END;

	tenpower := TRUNC ( LN ( not_negative ) / C_loge10 );
	IF tenpower > 99 THEN
		result_buffer[1] := '*' { TOO BIG }
	ELSE

		BEGIN
			{ get the (C_length-6) significant digits }
			IF ABS ( number ) < 1 THEN
				BEGIN
				{	There can be a real problem here with numbers < 1e-35
				because this algorithm tries to multiply 1e+39... & overflows	}
					work_power := ABS ( tenpower ) + four;	
					powerinfull := pospower ( 10, work_power );
					fourdigit := ROUND ( number * powerinfull );
				END
			ELSE
				BEGIN
					tenpower := tenpower + 1;
					work_power := ABS ( tenpower - four );
					powerinfull := pospower ( 10, work_power );
					fourdigit := ROUND ( number / powerinfull );
				END;

			{ put the 4 digit number into output string }
			e_decimal_places := num_places ( fourdigit, four-1 ); { max of 3 d.places}
			realdigit := fourdigit / divide;
			IF e_decimal_places < 1 THEN
				e_decimal_places := 1;		{ at least 1 dec. place }
			IF left_just THEN
				Str ( realdigit : 1 : e_decimal_places, stdform )
			ELSE
				Str ( realdigit : 6 : e_decimal_places, stdform );
			result_buffer := Concat ( result_buffer, stdform );

			epart := 'E+';
			IF ABS ( number ) < 1 THEN
				epart[2] := '-';
			result_buffer := Concat ( result_buffer, epart );

			tenpower := ABS ( tenpower - 1 );
			Str ( tenpower : 2, exponent ) ;
			IF tenpower < 10 THEN	{ force 2 digit exponent }
				exponent[1] := '0';
			result_buffer := Concat ( result_buffer, exponent )
		END;
END;	{ eformat }

{----------------------------------------------------------------------------}

BEGIN { procedure convert_number }
	centre_just := False;
	CASE	justify	OF
		-1	:	left_just := FALSE;
		0	:	BEGIN left_just := TRUE; centre_just := TRUE END;
		1	:	left_just := TRUE;
		ELSE	left_just := FALSE;
	END;	{	Case	}

{	IF (C_length < 7 ) THEN
		C_length := 7;

	IF (C_length >= Max_length ) THEN
		C_length := Max_length-1;
}
	CASE C_length OF
		12	:	factor := 1000000000;
		11	:	factor := 100000000;
		10	:	factor := 10000000;
		9	:	factor := 1000000;
		8	:	factor := 100000;
		7	:	factor := 10000;
		ELSE	factor := 1000000000;
	END;	{	Case	}

	not_negative := ABS ( number );
	result_buffer[0]:=CHR(0);

	IF ( (not_negative < (factor*100)) AND (not_negative>0.009) )
		OR (not_negative=0) THEN
		simpleform		{ -iii,iii,iii or -dddd.nnnn }
	ELSE
		eformat;			{ -n.nnnE+nn }

	IF result_buffer[ Ord(result_buffer[0]) ] = '.' THEN
		IF left_just THEN
			result_buffer[0]:=Chr( Ord(result_buffer[0]) -1 )
		ELSE
			BEGIN
				FOR j := C_length DOWNTO 2 DO
					result_buffer[j] := result_buffer[j-1];
				result_buffer[1] := ' '
			END;

{	Centring procedure, take the left-justified string and pad both ends	}
	IF centre_just THEN
		BEGIN
			pad := C_length - Length(result_buffer);
			pad_right := pad DIV 2;
			pad_left := pad - pad_right;
			IF pad_left >= 1 THEN
				FOR j := 1 TO pad_left DO
					result_buffer := Concat(' ',result_buffer);
			IF pad_right >= 1 THEN
				FOR j := 1 TO pad_right DO
					result_buffer := Concat(result_buffer,' ');
		END
	ELSE
	{	pad out the right of the left-justified number with blanks	}
		IF left_just THEN
			WHILE Length(result_buffer) < C_length DO
				result_buffer := Concat(result_buffer,' ');

	display_number := result_buffer;

END; { procedure convert_number }
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
{----------------------------------------------------------------------------}
BEGIN  {main_PROCEDURE}
	{	no initialisation code	}
END. { Of Unit StringIO }
