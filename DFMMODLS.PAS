 Unit DfmModls;
{ PMS 25-March-1990 00:41 }

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   P.M.Sargent and M.F.Ashby        **************
   *************   February 1990                    **************
}
{$IFDEF  contour}		{	ensure compiler directives are consistent	}
{$DEFINE  detail}
{$ENDIF}
{$IFDEF  detail}
{$DEFINE  debug}
{$ENDIF}
{.$R+}    {Range checking on}
{.$B+}    {Boolean complete evaluation on}
{.$S+}    {Stack checking on}
{.$I+}    {I/O checking on}
{.$N+}    {Use numeric coprocessor if present}
{.$E+}	 {Include copy of 8087 Emulator - default anyway}

Interface

Uses
	DfmGlbls;

PROCEDURE DEFINE_UNITS (VAR dud_steps: INTEGER; VAR dud_TN, dud_K: a_real);

PROCEDURE DIFFUSION_RATES;

{ ----- Calculates the rates of diffusion and the reference creep rate ----- }

PROCEDURE STRAIN_RATES (TN, LgSN: a_real;
								VAR Rate: a_real;
								VAR field: E_mech;
								VAR hint_stress : a_real);
{ ----- Calculate the strain rates due to each mechanism ----- }
{$IFDEF  debug}
PROCEDURE WRITE_FIELDNAME (field: E_mech);
{$ENDIF}

{===========================================================================}

Implementation

Uses
	Dos,
	Printer;

CONST
	HighRate	=	1.0e30;
	StrainRateLimit = 1.0e6;		{	maximum expected in a real material }
VAR
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
	phonon			:	a_real;
	electron			:	a_real;
	beta_breakdown	:	a_real;
	arzt_cuttoff	:	a_real;
	phase_change	:	a_real;

	value1				:  a_real;
	value2				:  a_real;
	value3				:  a_real;
	obst_energy			:	a_real;
	prls_energy			:	a_real;

	ref_const		:	a_real;
	ref_factor		:	a_real;
	ref_stress		:	a_real;
	glide_thresh	:	a_real;
	visco_mobility	:	a_real;
	beta_ref			:	a_real;
	a_prime			:	a_real;
	dorn 				:  a_real;
	dornLT1			:	a_real;
	dornLT2			:	a_real;
	b3_k				:	a_real;

	exp_limit		:	a_real;
	low_exp_limit	:	a_real;
	high_exp_limit	:	a_real;
	Low_Temp_limit	:	a_real;

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
	whether running with or without an 8087 chip, changed from a compile
	switch to a run-time check with TP5.5
	15-December-1989 00:38 PMS }

BEGIN
	IF (n < exp_limit) AND (n > -exp_limit) THEN
		exp := System.exp(n)
	ELSE
		BEGIN
			IF (n > exp_limit) THEN
				exp := high_exp_limit
			ELSE
				exp := low_exp_limit;
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
PROCEDURE DEFINE_UNITS (VAR dud_steps: INTEGER; VAR dud_TN, dud_K: a_real);

VAR
	lf		:	Text;
	mech	:	E_mech;
	qN		:	ARRAY [1..4] OF a_real;
	i		:	Byte;
	TNstep:	a_real;
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
	phonon			:= par[19];
	electron			:= par[20];
	beta_breakdown	:= par[21];
	arzt_cuttoff	:= par[22];
	phase_change	:= par[23];

{ ----- Assign program names to the plotting variables ----- }

	steps			:=  round(vbl[1]);
	Gsize			:=  vbl[2]/1e6;	{	microns to metres	}
	SNfirst		:=  vbl[3];
	SNlast		:=  vbl[4];
	TNfirst		:=  vbl[5];
	TNlast		:=  vbl[6];
	cntrfirst 	:=  vbl[7];
	cntrfactor	:=  vbl[8];
	contournumber :=  round(vbl[9]);
	RNtop			:=  vbl[10];
	RNbottom		:=  vbl[11];
	Tcntr_high	:=  vbl[12];
	Tcntr_diff	:=  vbl[13];
	Tcntr_number	:=  round(vbl[14]);

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

{	beta normalised terms of ref_stress instead of in terms of shear_modulus }
	beta_ref		:= beta_breakdown/ref_const;

{$IFDEF debug}
	writeln(db,' Normalised Ref.Stress : ',ref_const:7);
	writeln(db,' Inverted (Brown & Ashby) : ',(1/ref_const):7:3);
{$ENDIF}


{	Different classes of materials appear to have the same mechanisms, but
	with different interaction behavior between the mechanisms. There is
	presumably a continuum of interacting behaviour, but here we take the
	first approximation that mechanisms are either additive or alternative
	(sum or max).  Physical reasoning decides whether it is the maximum or
	the minimum strain rate that dominates, e.g. dislocation "drag"
	mechanisms are upper-bounds & therefore taking the minimum is the correct
	procedure.

	The mechanisms are grouped into diffusive, power-law, glide and
	drag groups.  (The default sets are for bcc metals.) Power-law creep
	is really just a kind of glide, so although the two types of power
	-law creep are additive, the result (S_plc) is an alternative to
	glide.

	The dominance and results of mixing groups of mechanisms is set to
	be the same for ALL crystalline materials.  The variations in
	behaviour between the isomechanical classes are handled by assigning
	different sets of mechanisms to these four invariant groups.

	15-December-1989 07:21
	PMS
}
	{ ----- Set up default sets for use with mechanism conjunction ----- }

	M_diffusion := [b_diff, v_diff];		{	maximum, sum	}
	M_plc			:= [plc_ht, plc_lt];		{	maximum, sum	}
	M_glide		:= [o_glide, S_plc];		{	maximum, max	}
	M_drag		:= [pls_drag, phn_drag, rel_drag];	{	minimum, min	}

	{ ----- The alumina_oxides have a problem with pls_drag and phn_drag.. }

	{ ----- Exceptionally, fcc metals display no Peierls stress (pls-drag).	}

	IF (imc = fcc) THEN
		BEGIN
			M_glide		:= [o_glide,S_plc];			{	maximum, max	}
			M_drag		:= [phn_drag, rel_drag];	{	minimum, min	}
		END;

{ -----	The sphalerites and similar materials have a very strong Peierls
			stress indeed, so the glide mechanism is always at the maximum
			that the Peierls stress allows }

	IF (imc IN [diamond_elements, sphalerites, wurtzites]) THEN
		BEGIN
			M_glide		:= [pls_drag, S_plc];	  	{	maximum, max	}
			M_drag		:= [phn_drag, rel_drag];	{	minimum, min	}
		END;

{ ---- Now follow the way of getting the dominant mechanism	}

	Ops_diffusion.dom	:=	max_op;
	Ops_plc.dom			:=	max_op;
	Ops_glide.dom		:= max_op;
	Ops_drag.dom		:= min_op;

{ ---- and the way of calculating the overall strain rate	}

	Ops_diffusion.all	:=	add_op;
	Ops_plc.all			:= add_op;
	Ops_glide.all		:= dom_op;
	Ops_drag.all		:= dom_op;

{ ----- Initialise the label indicators for the mechanisms ----- }

	FOR mech := null TO rel_drag DO
		mechID[mech] := mech;

{ ----- Calculate the temperature step, used below	----- }
	TNstep		:= (TNlast - TNfirst)/steps;

{ ----- Calculate the maximum to be used to set exp_fix later ----- }
	qN[1] := qvolmN;
	qN[2] := qbdryN;
	qN[3] := qcoreN;
	qN[4] := q_crpN;

	q_maxN := 0.0;
	FOR i := 1 TO 4 DO
		IF ( q_maxN < qN[i] ) THEN q_maxN := qN[i];

{	Proper fix depends on the maximum activation energy q_maxN and
	the smallest temperature, ie. the first temperature step:
	The value of exp_fix is adjusted so that, as much as possible,
	the exponentials are properly calculated at both high temperature
	and low-temperature extremes. HOWEVER, there is usually still a low-temp
	cuttoff below which larger activation energies don't work.
}
	fix := q_maxN/TNstep;
	dud_steps := 0;
	WHILE (fix > exp_limit) DO
		BEGIN
			Inc(dud_steps);
			fix := q_maxN/(TNstep*(dud_steps+1));
		END;

	exp_fix	:= exp(-fix);
	Low_Temp_Limit := TNstep * dud_steps;

	{	use different variable for VAR - called from another Unit	}
	dud_TN := Low_Temp_Limit;
	dud_K  := Low_Temp_Limit*Tmelt;

{$IFDEF debug}
	writeln(db,' Exponential fix number is: ',fix:10:4);
{$ENDIF}

	memory_enable	:= FALSE;

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

}

	IF ( TN <= 0.0 ) THEN
		BEGIN
			shear_mod	:= shmod* (1 + shtmp*300/tmelt);
			ref_stress	:= ref_const * shear_mod * 1.0e9;	{ in Pa	}
			diffusion1      := exp_fix;
			diffusion2      := exp_fix;
			diffusion3      := exp_fix;
			diffusion4      := exp_fix;
			kT				:= exp_fix;
			c1				:= exp_fix;
			dorn        := exp_fix;
			dornLT1		:= exp_fix;
			dornLT2		:= exp_fix;
			obst_energy	:=	exp_fix;
			visco_mobility	:=	exp_fix;
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

			kT				:= boltz*TN*tmelt;
			T				:= TN*tmelt;

{ ----- Safety check in case a large value of shtmp makes the modulus go -ve }
{ ----- Shear modulus at 0K then at current temperature ----- }
			IF (TN > phase_change/Tmelt) THEN
				shear_mod	:= shmod* (1 + shtmp*300/tmelt)*(1 - shtmp*phase_change/Tmelt)
			ELSE IF (TN < 0.999/shtmp) THEN
				shear_mod	:= shmod* (1 + shtmp*300/tmelt)*(1 - shtmp*TN)
			ELSE
				shear_mod	:= shmod* (1 + shtmp*300/tmelt)*(1 - 0.999);

{ ----- Evaluate diff. coefficient, normalised by R, at T;  units: /s ----- }
			c1				:= 42*atvol/kT;
			dorn			:= 1.0e-6*diffusion4;

			value1			:=    c1*dmeltvolm*diffusion1/(Gsize*Gsize);
			value2			:= pi*c1*dmeltbdry*diffusion2/(Gsize*Gsize*Gsize);

			visco_mobility	:=	1.0/(TN*Tmelt*phonon + electron);

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

{	Note that here the temperature-dependent shear modulus is used for the
	obstacle and Peierls-stress mechanisms, whereas	the old FORTRAN routine
	just used the 300K modulus since that "partially compensated"
	for the lack of temperature dependence of the burgers vector.
}
			obst_energy		:=	delFo*shear_mod*1.0e9*b3_k/T;

			prls_energy		:=	delFl*shear_mod*1.0e9*b3_k/T;

			ref_stress	:= ref_const * shear_mod * 1.0e9;	{ in Pa	}

		END;	{	IF TN <> 0 clause	}

{$IFDEF debug}
		Writeln(db);
		Writeln(db,' Normalised Temperature  ',TN:8:4);
		Writeln(db, ' diffusion2=',diffusion2:9,' diffusion1=',diffusion1:9);
		Writeln(db, ' diffusion4=',diffusion4:9,' diffusion3=',diffusion3:9);
		Writeln(db, ' dorn      =',dorn:9,      ' dornLT1   =',dornLT1:9,'  dornLT2   =',dornLT2:9);
{$ENDIF}
{$IFDEF detail}
		Write(db,'Stress&SN                 b_diff    v_diff    plc_ht    ');
		Write(db,'plc_lt    S_plc');
		Writeln(db,'     o_glide   pls_drag  S_glide     Rate      field');
{$ENDIF}

END;   {DIFFUSION_RATES.    }
{---------------------------------------------------------------------------}
FUNCTION any_null ( MechSet: T_mechset): BOOLEAN;
{	If, in the set of mechanisms given, any one is null, then this
	returns True.	}
VAR
	mech	:	E_mech;
	b		:	BOOLEAN;
BEGIN
	b := FALSE;
	FOR mech := null TO rel_drag DO
		IF (mech IN MechSet) AND (mechID [mech] = null ) THEN
			b := TRUE;

	any_null := b;
END;	{	any_null	}
{---------------------------------------------------------------------------}
PROCEDURE Conjoin_Mechanisms (StrRate: T_mecharray;
										MechSet: T_mechset;
										Op:	T_ops;
										VAR field: E_mech;
										VAR Rate: a_real);

{	This procedure is passed a SET of mechanisms together with parameters
	which tell it how to calculate:
	(a) the overall strain rate if only mechanisms in this set were active,
	(b) which is the dominant mechanism in the set.
	26-April-1988 18:38 PMS

   The important indirection of the line:
      result := mechID[mech]
   rather than
      result := mech;
   is so that the individual id of a mechanism is passed along, even if
   the "mechanism" being compared is actually a group such as S_plc.
   This algorithm ALSO implements another important function, that of
   ignoring all mechanisms which are set to NULL, whatever their value.
   This is sometimes very awkward. So it has been replaced by this:
		THEN IF (mech <> null) THEN
			result:=mechID [mech]
		ELSE
			result:=mech;
	The check for null mechanisms now has to be done explicitly, outside
	this procedure.  But I didn't like it, so I put it back again.
   15-December-1989 08:38
	PMS
}
VAR
	mech, result	:	E_mech;
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
FUNCTION Breakdown (Stress, power: a_real): a_real;

VAR
	sinh_term, tau	:	a_real;
BEGIN
{	The breakdown becomes significant at stresses above beta, so we could
	get a discontinuity at beta if we use beta as the changeover from one
	equation to the other.  If we use half-beta then the Sinh(x) will be damn
	near identical to (x), at x=0.5, sinh(x) is 0.52.
	PMS 3-February-1990 02:18
}
	tau := Stress/ref_stress;
	IF ( tau < 0.5* beta_ref) THEN
		Breakdown := exp(ln(tau)*power)
	ELSE
		BEGIN
			sinh_term := 0.5 * beta_ref *
								(exp(tau/beta_ref) - exp(-tau/beta_ref));
			Breakdown := exp(ln(sinh_term)*power);
		END;

END;	{	Breakdown	}
{---------------------------------------------------------------------------}
FUNCTION PhononDrag (SN: a_real): a_real;

BEGIN
	PhononDrag := visco_mobility * SN;

END;	{	PhononDrag	}
{---------------------------------------------------------------------------}
FUNCTION Relativistic (SN: a_real): a_real;
VAR
	slow_pd :	a_real;
BEGIN
	slow_pd := visco_mobility * SN;

	IF (slow_pd < 0.5 * StrainRateLimit) THEN		{fudge so not relativistic}
		Relativistic := slow_pd * 1.1
	ELSE
		Relativistic := slow_pd/Sqrt(1.0+Sqr(slow_pd/StrainRateLimit));

END;	{	Relativistic	}
{---------------------------------------------------------------------------}
PROCEDURE STRAIN_RATES (TN, LgSN: a_real;
								VAR Rate: a_real;
								VAR field: E_mech;
								VAR hint_stress : a_real);
{ ----- Calculate the strain rates due to each mechanism ----- }
VAR
	SN,
	Stress	:	a_real;
	fudge		:	a_real;
	StrRate	:	T_mecharray;
	mech		:	E_mech;
	field_diffusion, field_glide, field_drag, field_plc,field_dislcn	:	E_mech;
	Rate_diffusion, Rate_glide, Rate_drag, Rate_plc, Rate_dislcn		:	a_real;

BEGIN
	Inc(SRcount);
	FOR mech := null TO rel_drag DO
		mechID[mech] := mech;
	FOR mech := null TO rel_drag DO
		StrRate[mech] := 0.0;

{	SN is dimensionless, shear_mod is in GPa, we want Stress in Pa	}

	SN   := exp(LgSN*Ln10);
	Stress	:= SN * shear_mod * 1.0e9;

{ ====================== START CALCULATIONS ==================== }

	StrRate[b_diff]	:= multiply(Stress,value2);		{Boundary Diffusion}
	StrRate[v_diff]	:= multiply(Stress,value1); 		{Volume diffusion}

	{ HT & LT Power-Law Creep}
	StrRate[plc_ht]	:= dorn * Breakdown(Stress,n_crp);
	StrRate[plc_lt]	:= (dornLT1*dornLT2) * Breakdown(Stress,n_crp+2);

	StrRate[o_glide]	:= Obstacles(SN);		{	Obstacle glide	}
	StrRate[pls_drag]	:= Peierls(SN);		{	Peierls drag	}
	StrRate[phn_drag]	:= PhononDrag(SN);	{	Phonon Drag	}
	StrRate[rel_drag]	:= Relativistic(SN);	{	Relativistic Phonon Drag	}
{	StrRate[phn_drag]	:= 0.5e6;} {PhononDrag(SN);}	{	Phonon Drag	}
{	StrRate[rel_drag]	:= 0.7e6;} {Relativistic(SN);}	{	Relativistic Phonon Drag	}

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
		END
	ELSE 	IF ( TN <= Low_Temp_Limit ) THEN
		{	all bets off with activation energies	}
		BEGIN
			mechID [plc_ht] := null;
			mechID [plc_lt] := null;
			mechID [v_diff] := null;
			mechID [b_diff] := null;
			mechID [plc_ht] := null;
		END;

{ ----- Fix low-temp. and low-stress cutoffs ----- }
{	These otherwise distort the shapes of the curves and give
	the wrong dominant mechanisms	}

	FOR mech := null TO rel_drag DO
		IF ( StrRate[mech] < LowRate ) THEN
			BEGIN
		 		StrRate[mech] := LowRate;
				mechID [mech] := null;
			END;

	IF ( StrRate[plc_lt] = LowRate ) THEN { force plc-lt to be dominant }
		StrRate[plc_ht] := LowRate/2;

	IF ( StrRate[b_diff] = LowRate ) THEN { force b_diff to be dominant }
		StrRate[v_diff] := LowRate/2;


{ ----- Now merge mechanisms into sets and find dominant mechsnisms ----- }
{	First, set by set...	}
	Conjoin_Mechanisms (StrRate, M_diffusion, Ops_diffusion, field_diffusion, Rate_diffusion);
	mechID [S_diff] := field_diffusion;
	StrRate[S_diff] := Rate_diffusion;
	IF any_null (M_diffusion) THEN
		mechID [S_diff] := null;

	Conjoin_Mechanisms (StrRate, M_plc, Ops_plc, field_plc, Rate_plc);
	mechID [S_plc] := field_plc;
	StrRate[S_plc] := Rate_plc;
	{	NOTE the lack of a check for null participant mechanisms.
		This is because at low temperatures, plc_HT bottoms out and
		becomes NULL, which would cut-out plc_LT from being considered,
		which allows b_diff to dominate over a narrow temp. band.
		2-March-1990 04:13 PMS }

	Conjoin_Mechanisms (StrRate, M_glide, Ops_glide, field_glide, Rate_glide);
	mechID [S_glide] := field_glide;
	StrRate[S_glide] := Rate_glide;
	IF any_null (M_glide) THEN
		mechID [S_glide] := null;

{	a FIX for the alumina_oxides, YUKK!! to prevent a low pls_drag value
	being ignored because it is null.  For MOST other mechanisms, a null
   result means that it should be ignored.  This is not true for drag
   mechanisms (but the non-pls_drag mechanisms are never null, so it is
   easier just to reset this one. 	}
	mechID [pls_drag] := pls_drag;

	Conjoin_Mechanisms (StrRate, M_drag, Ops_drag, field_drag, Rate_drag);
	mechID [S_drag] := field_drag;
	StrRate[S_drag] := Rate_drag;
	{	NOTE the lack of a check for null participant mechanisms..	I have
		to allow them. The lack of symmetry pains me greatly, I strongly
		suspect something is wrong...15-December-1989 08:40 PMS	}

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
		BEGIN
			field := re_cryst;
	 		StrRate[field] := Rate;
			mechID [field] := field;
		END;

{$IFDEF detail}
	Write(db, Stress:8,' ',SN:7,'    ',StrRate[b_diff]:7, StrRate[v_diff]:7,
			StrRate[plc_ht]:7, StrRate[plc_lt]:7, StrRate[S_plc]:7, StrRate[o_glide]:7,
			StrRate[pls_drag]:7,StrRate[S_glide]:7,'  ',Rate:7,' ');

	WRITE_FIELDNAME (field);

{	IF (TN <= 0.0) THEN
		Writeln(db);
	IF (TN <= 0.0) THEN
		Write(db, Stress:8,' ', SN:7,'    ',Rate_drag:8, StrRate[S_drag]:8);
		Writeln(db, StrRate[pls_drag]:8, StrRate[phn_drag]:8, StrRate[rel_drag]:8);
	Writeln(db, SN:7,'    ', Rate_diffusion:8,StrRate[S_diff]:8,
			Rate_drag:8,StrRate[S_drag]:8, Rate_glide:8, Rate_dislcn:8,
			StrRate[S_plc]:8,StrRate[S_glide]:8);
}
{	Writeln(db,' obst_energy term ',(-obst_energy*(1-SN/tobst)):8);	}
{$ENDIF}

END;   {STRAIN_RATES.  }
{---------------------------------------------------------------------------}
{$IFDEF debug}
PROCEDURE WRITE_FIELDNAME (field: E_mech);
BEGIN
	CASE field OF
		null		:	Write(db,'NULL    ');
		re_cryst	:	Write(db,'re_cryst');
		b_diff	:	Write(db,'b_diff  ');
		v_diff	:	Write(db,'v_diff  ');
		plc_ht	:	Write(db,'plc_ht  ');
		plc_lt	:	Write(db,'plc_lt  ');
		o_glide	:	Write(db,'o_glide ');
		pls_drag	:	Write(db,'pls_drag');
		phn_drag	:	Write(db,'phn_drag');
		rel_drag	:	Write(db,'rel_drag');
		ELSE
						Write(db,'+error+ ');
	END;	{	Case	}
END;
{$ENDIF}
{---------------------------------------------------------------------------}
{ Unit Initialization }
BEGIN
{	no coprocessor present, using emulator,
	but this does NOT affect limits now.. so commented out.}

{	IF (System.Test8087=0) THEN
		BEGIN
			exp_limit		:=	87.0;
			high_exp_limit	:=	6.0760e37;
			low_exp_limit	:=	1.6458e-38;
		END
	ELSE
}
		BEGIN
			exp_limit		:=	227.0;
			high_exp_limit	:=	3.84457e98;
			low_exp_limit	:=	2.6011e-99;
		END;
END.
