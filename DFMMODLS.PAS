 Unit DfmModls;
{ PMS 28-June-1988 18:08 }

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
	DfmGlbls;

PROCEDURE DEFINE_UNITS;

PROCEDURE DIFFUSION_RATES;

{ ----- Calculates the rates of diffusion and the reference creep rate ----- }

PROCEDURE STRAIN_RATES (TN, LgSN: a_real;
								VAR Rate: a_real;
								VAR field: T_mech;
								VAR hint_stress : a_real);
{ ----- Calculate the strain rates due to each mechanism ----- }

{===========================================================================}

Implementation

CONST
	HighRate	=	1.0e30;
VAR
	stress_flag	:	BOOLEAN;	{	Used by the Peirls Stress memory function	}
	stress_stash:	ARRAY [1..max_steps, 1..2] OF a_real;
	kT			:	a_real;
	correct	:	a_real;
	exp_fix	:	a_real;
	fix		:	a_real;
	qvolmN			:  a_real;
	qbdryN			:  a_real;
	qcoreN			:  a_real;
	q_crpN			:  a_real;
	q_maxN			:	a_real;
	dmeltvolm		:  a_real;
	dmeltbdry		:  a_real;
	dmeltcore		:  a_real;
	dmelt_crp		:  a_real;
	shear_mod		:	a_real;

	value1				:  a_real;
	value2				:  a_real;
	value3				:  a_real;
	obst_energy			:	a_real;
	prls_energy			:	a_real;

	ref_const		:	a_real;
	ref_factor		:	a_real;
	ref_stress		:	a_real;
	glide_thresh	:	a_real;
	a_prime			:	a_real;
	dorn 				:  a_real;
	dornLT1			:	a_real;
	dornLT2			:	a_real;
	b3_k				:	a_real;

	M_diffusion		:	T_mechset;
	M_plc				:  T_mechset;
	M_glide			:	T_mechset;
	M_drag			:  T_mechset;

	Ops_diffusion	:	T_ops;
	Ops_glide		:	T_ops;
	Ops_plc			:	T_ops;
	Ops_drag			:	T_ops;

{---------------------------------------------------------------------------}
FUNCTION exp(n	:	a_real): a_real;
{	To prevent under/over-flow errors. Different limits depending on
	whether running with or without an 8087 chip,
	3-May-1988 15:59 PMS	}
CONST
{$IFOPT N-}
	limit			=	87.0;
	high_limit	=	6.0760e37;
	low_limit	=	1.6458e-38;
{$ELSE}
	limit			=	227.0;
	high_limit	=	3.84457e98;
	low_limit	=	2.6011e-99;
{$ENDIF}

BEGIN
	IF (n < limit) AND (n > -limit) THEN
		exp := System.exp(n)
	ELSE
		BEGIN
			IF (n > limit) THEN
				exp := high_limit
			ELSE
				exp := low_limit;
		END;
END;	{	private exp() function	}
{---------------------------------------------------------------------------}
FUNCTION multiply (a,b: a_real): a_real;
{	A safe multiply function to prevent overflows	}
VAR
	s	:	Integer;
BEGIN
	IF (b >= max_real/a ) THEN
		multiply := max_real
	ELSE
		BEGIN
			IF (b < max_mult) AND (a < max_mult) THEN
				multiply := a * b
			ELSE
				BEGIN
					s := 1;
					IF ( a < 0 ) THEN
						s := -1;
					IF ( b < 0 ) THEN
						s := -1 * s;
					multiply := s * exp(ln(Abs(a))+ln(Abs(b)));
				END;
		END;
END;	{	multiply	}
{---------------------------------------------------------------------------}
PROCEDURE DEFINE_UNITS;

VAR
	mech	:	T_mech;
	qN		:	ARRAY [1..4] OF a_real;
	i		:	Byte;
BEGIN


{ ----- Assign program names to the parameters ----- }

	tmelt		:=par[1];			
	shtmp		:=par[2];
	shmod		:=par[3];			
	tprls		:=par[4];			
	tobst		:=par[5];
	delFl		:=par[6];
	delFo		:=par[7];			
	dovol		:=par[8];
	qvolm		:=par[9];			
	dlbdy		:=par[10];
	qbdry		:=par[11];			
	acdoc		:=par[12];
	qcore		:=par[13];			
	n_crp		:=par[14];
	S_crp		:=par[15];			
	q_crp		:=par[16];
	burgv		:=par[17];
	atvol		:=par[18];			

{ ----- Assign program names to the plotting variables ----- }

	steps			:=  round(vbl[1]);
	Gsize			:=  vbl[2];
	SNfirst		:=  vbl[3];
	SNlast		:=  vbl[4];
	TNfirst		:=  vbl[5];
	TNlast		:=  vbl[6];
	cntrfirst 	:=  vbl[7];
	cntrfactor	:=  vbl[8];
	contournumber :=  round(vbl[9]);

{ ----- Compute normalised diffusion rates ----- }

	qvolmN	:=  1000*qvolm/(R*tmelt);
	qbdryN	:=  1000*qbdry/(R*tmelt);
	qcoreN	:=  1000*qcore/(R*tmelt);
	q_crpN	:=  1000*q_crp/(R*tmelt);

	dmeltvolm	:=	dovol*exp(-qvolmN);
	dmeltbdry	:=	dlbdy*exp(-qbdryN);
	dmeltcore	:=	acdoc*exp(-qcoreN);
	correct		:=	exp(-qvolmN*(-1));
	ref_factor	:= exp(2*q_crpN);
	b3_k			:= burgv*burgv*burgv/boltz;

	glide_thresh	:= tobst/2;

{ ----- Both S_crp and divisor are in MPa. Calculate the constant
	by dividing the ref. stress by the shear modulus at half the
	melting point.	}

	ref_const	:= S_crp/(1.0e3*shmod*(1 - shtmp*0.5));	
{	writeln(db,' Normalised Ref.Stress : ',ref_const:7);
	writeln(db,' Inverted (Brown & Ashby) : ',(1/ref_const):7:3);
}
{ ----- Set up default sets of mechanisms for use with mechanism conjunction ----- }

	M_diffusion := [b_diff, v_diff];		{	maximum, sum	}
	M_plc			:= [plc_ht, plc_lt];		{	maximum, sum	}
	M_glide		:= [o_glide, S_plc];		{	maximum, max	}
	M_drag		:= [pls_drag, phn_drag, rel_drag];	{	minimum, min	}

	IF (imc = fcc) THEN
		BEGIN
			M_glide		:= [o_glide,S_plc];			{	maximum, max	}
			M_drag		:= [phn_drag, rel_drag];	{	minimum, min	}
		END;

	IF (((imc = diamond_elements)
	OR (imc = sphalerites ))
	OR (imc = wurtzites)) THEN
		BEGIN
			M_glide		:= [S_plc,pls_drag];	  		{	maximum, max	}
			M_drag		:= [phn_drag, rel_drag];	{	minimum, min	}
		END;

	Ops_diffusion.dom	:=	max_op;
	Ops_plc.dom			:=	max_op;
	Ops_glide.dom		:= max_op;
	Ops_drag.dom		:= min_op;

	Ops_diffusion.all	:=	add_op;
	Ops_plc.all			:= add_op;
	Ops_glide.all		:= dom_op;
	Ops_drag.all		:= dom_op;

{ ----- Initialise the label indicators for the mechanisms ----- }

	FOR mech := null TO rel_drag DO
		mechID[mech] := mech;

{ ----- Calculate the maximum to be used to set exp_fix later ----- }
	qN[1] := qvolmN;
	qN[2] := qbdryN;
	qN[3] := qcoreN;
	qN[4] := q_crpN;

	q_maxN := 0.0;
	FOR i := 1 TO 4 DO
		IF ( q_maxN < qN[i] ) THEN q_maxN := qN[i];

{ ----- Default exp_fix, make bigger and smaller depending on Temp. ----- }
	fix		:=	25.0;
	exp_fix	:= exp(-fix);

	stress_flag := FALSE;

END;  {DEFINE_UNITS.     }
{---------------------------------------------------------------------------}
PROCEDURE DIFFUSION_RATES;

{ ----- Calculates the rates of diffusion and the reference creep rate ----- }

VAR
	diffusion1	:	a_real;
	diffusion2	:	a_real;
	diffusion3	:	a_real;
	diffusion4	:	a_real;
	dornLT		:	a_real;
	c1	 			:	a_real;
	T				:	a_real;

BEGIN

{ ----- Evaluate exponent and temperature T.
	Because the arguments of the exponential functions are largish
	negative numbers, there is a real danger that an underflow will
	occur, which will cut-off a mechanism below a critical temperature.
	Therefore all arguments have fix added to them, and the results are
	multiplied by exp(-fix), which is the value of the constant exp_fix.
	The value of exp_fix is adjusted so that the exponentials are 
	properly calculated at both high temperature and low-temperature
	extremes.
}

	IF ( TN <= 0.0 ) THEN
		BEGIN
			shear_mod	:= shmod;
			ref_stress	:= ref_const * shear_mod * 1.0e9;	{ in Pa	}
			diffusion1      := exp_fix;
			diffusion2      := exp_fix;
			diffusion3      := exp_fix;
			diffusion4      := exp_fix;
			kT				:= exp_fix;
			c1				:= exp_fix;
			dorn			:= exp_fix;
			obst_energy	:=	exp_fix;
		END
	ELSE
		BEGIN

			diffusion1      := exp_fix * exp(fix-qvolmN*(1/TN - 1));
			diffusion2      := exp_fix * exp(fix-qbdryN*(1/TN - 1));
			IF (qbdry = qcore) THEN
				diffusion3 := diffusion2
			ELSE
				diffusion3      := exp_fix * exp(fix-qcoreN*(1/TN - 1));

			IF (qvolm = q_crp) THEN
		{		diffusion4 := diffusion1 * exp(-qvolmN*(-1))	}
				diffusion4 := diffusion1 * correct
			ELSE
				diffusion4      := exp_fix * exp(fix-q_crpN*(1/TN - 2));

{ ----- Evaluate diff. coefficient, normalised by R, at T;  units: /s ----- }
			shear_mod	:= shmod*(1 - shtmp*TN);
			kT				:= boltz*TN*tmelt;
			T				:= TN*tmelt;
			c1				:= 42*atvol/kT;
			dorn			:= 1.0e-6*diffusion4;

			value1			:=    c1*dmeltvolm*diffusion1/(Gsize*Gsize);
			value2			:= pi*c1*dmeltbdry*diffusion2/(Gsize*Gsize*Gsize);

{	The following calculations have to be done in the best order to
	prevent the intermediate values producing arithmetic underflows
	and hence unwanted zeros.
	The factor dornLT is bothersome because it gets very small at low
	temperatures, but is multiplied by a huge stress term (later). So we split
	dornLT into two small numbers and defer multiplying them until we have
	the stress term as well; in procedure STRAIN_RATES.
}

{	The following are the theoretical values for the parameters, the realities
	of underflows etc. mean that they are re-phrased below.	

	value3		:=    10*dmeltcore*diffusion3/(burgv*burgv);
	a_prime		:= (1.0e-6*boltz*0.5*tmelt/(dovol*shear_mod*burgv))*ref_factor;
	dornLT		:= a_prime*(shear_mod*burgv/kT)*((ref_const*ref_const))*value3;
	obst_energy		:=	delFo*mu.b-cubed/kT
	prls_energy		:=	delFo*mu.b-cubed/kT
}
{			dornLT		:=	1.0e-6*0.5*tmelt*ref_factor*10*dmeltcore*diffusion3 
									*ref_const*ref_const/(dovol*burgv*burgv);
}
			dornLT1		:=	diffusion3;	{	we can mix and match LT1 and LT2	}
			dornLT2		:=	1.0e-6*0.5*tmelt*ref_factor*10*dmeltcore
									*ref_const*ref_const/(dovol*burgv*burgv);

			obst_energy		:=	delFo*shear_mod*1.0e9*b3_k/T;

			prls_energy		:=	delFl*shear_mod*1.0e9*b3_k/T;

			ref_stress	:= ref_const * shear_mod * 1.0e9;	{ in Pa	}

		END;	{	IF TN <> 0 clause	}

{		Writeln(db);
		Writeln(db,' Normalised Temperature  ',TN:8:4);
		Writeln(db, ' diffusion2=',diffusion2:9,' diffusion1=',diffusion1:9);
		Writeln(db, ' diffusion4=',diffusion4:9,' diffusion3=',diffusion3:9);
		Writeln(db, ' dorn      =',dorn:9,      ' dornLT1   =',dornLT1:9,'  dornLT2   =',dornLT2:9);
		Writeln(db,
'           [b_diff][v_diff][plc_ht][plc_lt][S_plc][o_glide][pls_drag][S_glide]  Rate   field');
}

END;   {DIFFUSION_RATES.    }
{---------------------------------------------------------------------------}
PROCEDURE Conjoin_Mechanisms (StrRate: T_mecharray;
										MechSet: T_mechset;
										Op:	T_ops;
										VAR field: T_mech;
										VAR Rate: a_real);

{	This procedure is passed a SET of mechanisms together with parameters
	which tell it how to calculate:
	(a) the overall strain rate if only mechanisms in this set were active,
	(b) which is the dominant mechanism in the set.
	26-April-1988 18:38 PMS	}
VAR
	mech, result	:	T_mech;
BEGIN
{ ----- Maximum OR Minimum of the strain rates for
	individual mechanisms in order to find dominant mechanism ----- }

	CASE Op.dom OF
		max_op:		BEGIN
							result	:= null;
							StrRate[null]:=0.0;
							FOR mech := null TO rel_drag DO
								IF (mech IN MechSet) THEN

									IF (StrRate[mech] >= StrRate[result] )
										THEN result:=mechID [mech];
						END;

		min_op:		BEGIN
							result	:= null;
							StrRate[null]:=HighRate;
							FOR mech := null TO rel_drag DO
								IF (mech IN MechSet) THEN

									IF (StrRate[mech] <= StrRate[result] )
										THEN result:=mechID [mech];
						END;
	END;	{	Case	}

	IF (StrRate[result] > 0.0) THEN
		field := result
	ELSE
		field := null;

{ ----- Add up OR take Maximum OR take Minimum of the strain rates to
	get the overall strain-rate for this set of mechanisms ----- }

	CASE Op.all OF
		dom_op:	BEGIN
					{	overall strain rate is that due only to 
						the dominant mechanism	}
						Rate := StrRate [result];
					END;

		add_op:	BEGIN
					{	overall strain rate is the sum of all the strain rates	}
						Rate := 0.0;
						FOR mech := null TO rel_drag DO
							IF (mech IN MechSet) THEN
								Rate   := Rate + StrRate[mech];
					END;

		mean_op:	BEGIN
					{	overall strain rate is the geometric mean of all the strain rates	}
						Rate := 0.0;
						FOR mech := null TO rel_drag DO
							IF ((mech IN MechSet)
							AND (StrRate[mech] <> 0.0)) THEN
									Rate   := Rate + 1/StrRate[mech];
						Rate := 1/Rate;
					END;
	END;	{	Case	}

END;	{	Conjoin_mechanisms	}
{---------------------------------------------------------------------------}
FUNCTION StressFunction (SN: a_real): a_real;

{	This function is independent of temperature and so can be
	implemented as a memory function, i.e. if it already has
	been called once with that stress, return the value calculated
	the last time and don't recalculate}
CONST
	four_thirds		=	1.3333333;
	three_quarters	=	0.75;
VAR
	r, n	:	a_real;
BEGIN
	IF (SN = stress_stash[stress_step, 1] ) THEN
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
FUNCTION Peierls (SN: a_real): a_real;

VAR
	n	:	a_real;
BEGIN
	n	:=	SN*SN*exp(-prls_energy * StressFunction(SN));
	Peierls	:=	multiply( 1.0e+11, n);
END;	{	Peierls	}
{---------------------------------------------------------------------------}
FUNCTION Obstacles (SN: a_real): a_real;

VAR
	n	:	a_real;
BEGIN
	IF ( SN > glide_thresh ) THEN
		BEGIN
			n	:=	exp(-obst_energy*(1-SN/tobst));
			Obstacles := multiply( 1.0e6, n);
		END
	ELSE
		Obstacles := LowRate;

END;	{	Obstacles	}
{---------------------------------------------------------------------------}
PROCEDURE STRAIN_RATES (TN, LgSN: a_real;
								VAR Rate: a_real;
								VAR field: T_mech;
								VAR hint_stress : a_real);
{ ----- Calculate the strain rates due to each mechanism ----- }
VAR
	SN, 
	Stress	:	a_real;
	fudge		:	a_real;
	StrRate	:	T_mecharray;
	mech		:	T_mech;
	field_diffusion, field_glide, field_drag, field_plc,field_dislcn	:	T_mech;
	Rate_diffusion, Rate_glide, Rate_drag, Rate_plc, Rate_dislcn		:	a_real;

BEGIN
	FOR mech := null TO rel_drag DO StrRate[mech] := 0.0;

{	SN is dimensionless, shear_mod is in GPa, we want Stress in Pa	}

	SN   := exp(LgSN*Ln10);
	Stress	:= SN * shear_mod * 1.0e9;

{ ====================== START CALCULATIONS ==================== }

	StrRate[b_diff]	:= multiply(Stress,value2);		{Boundary Diffusion}
	StrRate[v_diff]	:= multiply(Stress,value1); 		{Volume diffusion}
	StrRate[plc_ht]	:= dorn * 
									exp(ln(Stress/ref_stress)*n_crp);	{HT Power-Law Creep}
	StrRate[plc_lt]	:= (dornLT1*dornLT2) * 
									exp(ln(Stress/ref_stress)*(n_crp+2));	{LT Power-Law Creep}
	StrRate[o_glide]	:= Obstacles(SN);	{	Obstacle glide	}
	StrRate[pls_drag]	:= Peierls(SN);	{	Peierls drag	}
	StrRate[phn_drag]	:= 0.5e6;	{	Phonon Drag	}
	StrRate[rel_drag]	:= 0.7e6;	{	Relativistic Phonon Drag	}

	IF (TN <= 0.0) THEN
		BEGIN
			FOR mech := null TO rel_drag DO StrRate[mech] := 0.0;

			StrRate[phn_drag]	:= 0.5e6;	{	Phonon Drag	}
			StrRate[rel_drag]	:= 0.7e6;	{	Relativistic Phonon Drag	}
			IF (SN >= tobst) THEN
				StrRate[o_glide]	:= HighRate
			ELSE
				StrRate[o_glide]	:= LowRate;

			IF (SN >= tprls) THEN
				StrRate[pls_drag]	:= HighRate
			ELSE
				StrRate[pls_drag]	:= LowRate;
		END;

{ ----- Fix low-temp. and low-stress cutoffs ----- }
{	These otherwise distort the shapes of the curves and give 
	the wrong dominant mechanisms	}

	FOR mech := null TO rel_drag DO
		IF ( StrRate[mech] < LowRate ) THEN
			StrRate[mech] := LowRate;

	IF ( StrRate[plc_lt] = LowRate ) THEN
		StrRate[plc_ht] := LowRate/2;

	IF ( StrRate[b_diff] = LowRate ) THEN
		StrRate[v_diff] := LowRate/2;


{ ----- Now merge mechanisms into sets and find dominant mechsnisms ----- }
{	First, set by set...	}
	Conjoin_Mechanisms (StrRate, M_diffusion, Ops_diffusion, field_diffusion, Rate_diffusion);
	mechID [S_diff] := field_diffusion;
	StrRate[S_diff] := Rate_diffusion;

	Conjoin_Mechanisms (StrRate, M_plc, Ops_plc, field_plc, Rate_plc);
	mechID [S_plc] := field_plc;
	StrRate[S_plc] := Rate_plc;

	Conjoin_Mechanisms (StrRate, M_glide, Ops_glide, field_glide, Rate_glide);
	mechID [S_glide] := field_glide;
	StrRate[S_glide] := Rate_glide;

	Conjoin_Mechanisms (StrRate, M_drag, Ops_drag, field_drag, Rate_drag);	
	mechID [S_drag] := field_drag;
	StrRate[S_drag] := Rate_drag;

{	Then, the sets together...}

	IF (Rate_drag < Rate_glide) THEN
		BEGIN
			Rate_dislcn := Rate_drag;
			field_dislcn := field_drag;
		END
	ELSE
		BEGIN
			Rate_dislcn := Rate_glide;
			field_dislcn := field_glide;
		END;

	Rate := Rate_diffusion + Rate_dislcn;
	IF (Rate_diffusion >= Rate_dislcn) THEN
		field := field_diffusion
	ELSE
		field := field_dislcn;

{ ----- Final catch-all, to be replaced by proper treatment later ----- }

	IF ( Rate <= LowRate ) THEN
		field := null;

{	Now a FUDGE to implement dynamic-recrystallisation without
	actually giving it a mechanism or changing any strain-rates in
	any way	}

	fudge := ln(Rate)/Ln10 ;

	IF ((( fudge < (-2 -10*(1-TN)/0.2) )
	AND (TN > 0.3 ))
	AND (fudge > -12 )) THEN
		field := re_cryst;

{	Write(db, SN:7,'    ',StrRate[b_diff]:7, StrRate[v_diff]:7,
			StrRate[plc_ht]:7, StrRate[plc_lt]:7, StrRate[S_plc]:7, StrRate[o_glide]:7, 
			StrRate[pls_drag]:7,StrRate[S_glide]:7,'  ',Rate:7,' ');

	CASE field OF
		null		:	Write(db,'null  ');
		re_cryst	:	Write(db,'re_cryst');
		b_diff	:	Write(db,'b_diff');
		v_diff	:	Write(db,'v_diff');
		plc_ht	:	Write(db,'plc_ht');
		plc_lt	:	Write(db,'plc_lt');
		o_glide	:	Write(db,'o_glide');
		pls_drag	:	Write(db,'pls_drag');
		phn_drag	:	Write(db,'phn_drag');
		rel_drag	:	Write(db,'rel_drag');
		ELSE
			Write(db,'+ error +');
	END;	}{	Case	}

{	IF (TN <= 0.0) THEN
		Writeln(db);
	IF (TN <= 0.0) THEN
		Writeln(db, SN:7,'    ',Rate_drag:8, StrRate[S_drag]:8, StrRate[pls_drag]:8, StrRate[phn_drag]:8, StrRate[rel_drag]:8);
		Writeln(db, SN:7,'    ', Rate_diffusion:8,StrRate[S_diff]:8,
			Rate_drag:8,StrRate[S_drag]:8, Rate_glide:8, Rate_dislcn:8,
			StrRate[S_plc]:8,StrRate[S_glide]:8);
}
{	Write(db,' ',(-obst_energy*(1-SN/tobst)):8);	}

END;   {STRAIN_RATES.  }
{---------------------------------------------------------------------------}

End.
