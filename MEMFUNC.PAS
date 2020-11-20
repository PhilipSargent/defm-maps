{	memfunct.pas	from DFMMODLS.pas	}
{ PMS 19-April-1990 16:48 }
{---------------------------------------------------------------------------}
FUNCTION StressFunction (SN: a_real): a_real;

{	This function is independent of temperature and so can be
	implemented as a memory function, i.e. if it already has
	been called once with that stress, return the value calculated
	the last time and don't recalculate.  It does depend on the
	stresses given being PRE-DEFINED and on KNOWING the current
	value of stress_step! Unclean, Unclean..}
CONST
	four_thirds		=	1.3333333;
	three_quarters	=	0.75;
VAR
	r, n	:	a_real;
BEGIN
	IF memory_enable AND (SN = stress_stash[stress_step, 1] ) THEN
		StressFunction := Stress_stash [stress_step, 2]
	ELSE
		BEGIN
			n :=	exp (three_quarters*ln(SN/tprls));
			IF (n < 1) THEN
				r	:= exp( four_thirds * ln (1 - n ) )
			ELSE	{	n >= 1	}
				r	:=	0.0;
			stress_stash [stress_step, 1] := SN;
			stress_stash [stress_step, 2] := r;
			StressFunction := r;
		END;
END;	{	StressFunction	}
{---------------------------------------------------------------------------}

