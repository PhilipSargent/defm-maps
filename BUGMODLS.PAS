 Unit BUGModls;
{ PMS 20-April-1988 12:50 }

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
	BUGGlbls;

PROCEDURE DEFINE_UNITS;     

PROCEDURE DIFFUSION_RATES;    

{ ----- Calculates the rates of diffusion and the reference creep rate ----- }

PROCEDURE STRAIN_RATES (TN, SN: a_real; 
								VAR Gamma: a_real; VAR GamRate: RateArray);

{ ----- Calculate the strain rates due to each mechanism ----- }

{===========================================================================}

Implementation

VAR
	kT			:	a_real;
	correct	:	a_real;
	e_20		:	a_real;
	qvolmN			:  a_real;
	qbdryN			:  a_real;
	qcoreN			:  a_real;
	q_crpN			:  a_real;
	dmeltvolm		:  a_real;
	dmeltbdry		:  a_real;
	dmeltcore		:  a_real;
	dmelt_crp		:  a_real;
	shear_mod		:	a_real;

	value1				:  a_real;
	value2				:  a_real;
	value3				:  a_real;
	dorn				:  a_real;

	ref_const		:	a_real;
	ref_factor		:	a_real;
	ref_stress		:	a_real;
	a_prime			:	a_real;
	dornLT			:	a_real;

{---------------------------------------------------------------------------}
{$IFOPT N-}
FUNCTION exp(n	:	Real): Real;
{	To prevent under/over-flow errors when running without an 8087 chip,
	PMS 27-January-1988 14:11 }
BEGIN
	IF (n < 87.0) AND (n > -87) THEN
		exp := System.exp(n)
	ELSE
		BEGIN
			IF (n > 87) THEN
				exp := 6.0760e37
			ELSE
				exp := 1.6458e-38;
		END;
END;	{	private exp() function	}
{$ENDIF}
{---------------------------------------------------------------------------}
PROCEDURE DEFINE_UNITS;     

BEGIN

{ ----- Ensure that variables have sensible values ----- }

	if (vbl[1]  <  1)             then vbl[1]   := 1;
	if (vbl[1]  >  30)            then vbl[1]   := 30;
{	if (vbl[3]  <  0.1)           then vbl[3]   := 0.1;	}
{	if (vbl[3]  >  0.999)         then vbl[3]   := 0.999;	}
	if (vbl[5]  <  1.0E-10)       then vbl[5]   := 1.0E-10;
	if (vbl[5]  >  1.0E-2)        then vbl[5]   := 1.0E-2;
{	if (vbl[6]  >  0.99*vbl[7])   then vbl[6]   := 0.99*vbl[7];	}
	if (vbl[8]  <  1.0e-6)        then vbl[8]   := 1.0e-6;
	if (vbl[9]  >  0.9*vbl[10])   then vbl[9]   := 0.9*vbl[10];
{	if (vbl[11] >  par[1])        then vbl[11]  := par[1];	}
	if (vbl[12] >  vbl[13]-0.1)   then vbl[12]  := vbl[13]-0.1;
	if (vbl[16] >  10)            then vbl[16]  := 10;
	if (vbl[17] <  2)             then vbl[17]  := 2;
	if (vbl[17] >  300)           then vbl[17]  := 300;

{ ----- Assign program names to the parameters ----- }

	tmelt		:=par[1];			tobst		:=par[2];
	shmod		:=par[3];			shtmp		:=par[4];
	tprls		:=par[5];			del_F		:=par[6];
	atvol		:=par[7];			dovol		:=par[8];
	qvolm		:=par[9];			dlbdy		:=par[10];
	qbdry		:=par[11];			acdoc		:=par[12];
	qcore		:=par[13];			n_crp		:=par[14];
	S_crp		:=par[15];			q_crp		:=par[16];
	burgv		:=par[17];

{ ----- Assign program names to the plotting variables ----- }

	Gsize         :=  vbl[5];            
	Sfixed        :=  vbl[8];
	SNfirst       :=  vbl[9];            
	SNlast        :=  vbl[10];
	TNfirst       :=  vbl[12];
	TNlast        :=  vbl[13];           
	cntrfirst     :=  vbl[14];
	cntrfactor    :=  vbl[15];           
	contournumber :=  round(vbl[16]);
	steps         :=  round(vbl[17]);

{ ----- Open DEBUG file	----- }
	Assign(db,'debug.txt');
	Rewrite(db);

{ ----- Compute normalised diffusion rates ----- }

	qvolmN        :=  1000*qvolm/(R*tmelt);
	qbdryN        :=  1000*qbdry/(R*tmelt);
	qcoreN        :=  1000*qcore/(R*tmelt);
	q_crpN        :=  1000*q_crp/(R*tmelt);

	dmeltvolm	:=	dovol*exp(-qvolmN);
	dmeltbdry	:=	dlbdy*exp(-qbdryN);
	dmeltcore	:=	acdoc*exp(-qcoreN);
	correct		:=	exp(-qvolmN*(-1));
	ref_factor	:= exp(2*q_crpN);

{ ----- Both S_crp and divisor are in MPa. Calculate the constant
	by dividing the ref. stress by the shear modulus at half the
	melting point.	}

	ref_const	:= S_crp/(1.0e3*shmod*(1 - shtmp*0.5));	
	writeln(db,' Normalised Ref.Stress : ',ref_const:7);
	writeln(db,' Inverted (Brown & Ashby) : ',(1/ref_const):7:3);

	e_20 := exp(-20);


END;  {DEFINE_UNITS.     }

{---------------------------------------------------------------------------}
PROCEDURE DIFFUSION_RATES;    

{ ----- Calculates the rates of diffusion and the reference creep rate ----- }

VAR
	diffusion1	:	a_real;
	diffusion2	:	a_real;
	diffusion3	:	a_real;
	diffusion4	:	a_real;
	c1	 	:	a_real;

BEGIN

{ ----- Evaluate exponent and temperature T.
	Because the arguments of the exponential functions are largish
	negative numbers, there is a real danger that an underflow will
	occur, which will cut-off a mechanism below a critical temperature.
	Therefore all arguments have 20 added to them, and the results are
	multiplied by exp(-20), which is the value of the constant e_20.
	PMS 20-April-1988 11:35 }

	diffusion1      := e_20 * exp(20-qvolmN*(1/TN - 1));
	diffusion2      := e_20 * exp(20-qbdryN*(1/TN - 1)); 
	IF (qbdry = qcore) THEN
		diffusion3 := diffusion2
	ELSE
		diffusion3      := e_20 * exp(20-qcoreN*(1/TN - 1));

	IF (qvolm = q_crp) THEN
{		diffusion4 := diffusion1 * exp(-qvolmN*(-1))	}
		diffusion4 := diffusion1 * correct
	ELSE
		diffusion4      := e_20 * exp(20-q_crpN*(1/TN - 2)); 

{ ----- Evaluate diff. coefficient, normalised by R, at T;  units: /s ----- }
	shear_mod	:= shmod*(1 - shtmp*TN);
	kT				:= boltz*TN*tmelt;
	c1				:= 42*atvol/kT;
	dorn			:= 1.0e-6*diffusion4;

	value1			:=    c1*dmeltvolm*diffusion1/(Gsize*Gsize);
	value2			:= pi*c1*dmeltbdry*diffusion2/(Gsize*Gsize*Gsize);

{	The following calculations have to be done in the best order to
	prevent the intermediate values producing arithmetic underflows
	and hence unwanted zeros	}
{	value3			:=    10*dmeltcore*diffusion3/(burgv*burgv);
	a_prime		:= (1.0e-6*boltz*0.5*tmelt/(dovol*shear_mod*burgv))*ref_factor;
	dornLT		:= a_prime*(shear_mod*burgv/kT)*((ref_const*ref_const))*value3;
}
	dornLT		:=	1.0e-6*0.5*tmelt*ref_factor*10*dmeltcore*diffusion3
							*ref_const*ref_const/(dovol*burgv*burgv);					

	ref_stress	:= ref_const * shear_mod * 1.0e9;	{ in Pa	}

{	writeln(db,(-qcoreN*(1/TN - 1)):7,' (-qcoreN*(1/TN - 1))');
	writeln(db,value3:7,dornLT:7,diffusion3:7,' value3, dornLT, diffusion3');
}
END;   {DIFFUSION_RATES.    }
{---------------------------------------------------------------------------}
PROCEDURE STRAIN_RATES (TN, SN: a_real; 
								VAR Gamma: a_real; VAR GamRate: RateArray);
{ ----- Calculate the strain rates due to each mechanism ----- }
VAR
	Stress	:	a_real;
	m			:	Byte;

BEGIN
	FOR m := 0 to numberofmechanisms DO Gamrate[m] := 0.0;

	{	SN is dimensionless, shear_mod is in GPa, we want Stress in Pa	}
	Stress	:= SN * shear_mod * 1.0e9;

{ ====================== START CALCULATIONS ==================== }

	GamRate[1]  := Stress*value1;			{Volume diffusion}
	GamRate[2]  := Stress*value2;		{Boundary Diffusion}
	GamRate[3]  := dorn*exp(ln(Stress/ref_stress)*n_crp);	{HT Power-Law Creep}
	GamRate[4]  := dornLT*exp(ln(Stress/ref_stress)*(n_crp*2));	{LT Power-Law Creep}

	Gamma := 0.0;
	FOR m := 1 to numberofmechanisms DO
		Gamma   := Gamma + GamRate[m];

END;   {STRAIN_RATES.  }
{---------------------------------------------------------------------------}

End.
