File README.TXT supplied with DFM290
====================================

Version 0.88
12-June-1993 06:32 

THIS IS A PRE-RELEASE VERSION, CURRENTLY BEING DEBUGGED

The documentation is currently being written and edited, a current
incomplete draft should accompany this version.

CONTOURING PROBLEMS: READ THIS
==============================
Version 0.88 is supplied in TWO forms: DFM290.exe and DFMFIX.exe because
of bugs/inconveniences in the contour plotting routines.  Both forms are
identical in everything except the algorithms used to plot the strain-rate
contours.  Both are supplied because each has strong points and each has
failings.
The hardcopy output tells you which you ran, If it says:
   DFM290 v0.88 (24 May 1990)
   (Compiler options:+Debug+Contour+CntrFix)
   (C) Copyright 1980,1990 P.M.Sargent & M.F.Ashby
then you ran dfmFIX.exe, if it says
   (Compiler options:+Debug+Contour)
then you ran dfm290.exe.  When running, both say "DFM290" in headings.

UNCHECKED CALCULATIONS
======================
I have NOT CHECKED that the mechanism calculations are CORRECT yet.
In particular, I suspect problems with POWER-LAW BREAKDOWN.

The MECHANISM PRIORITY decisions are defined in a data table rather than
being embedded in a large number of IF..THEN statements.  Currently this
does not handle direct competition between DIFFUSION mechanisms and OBSTACLE
controlled glide as one might expect (fine-grained fcc materials develop
boundary-diffusion creep which is faster than phonon-controlled glide).

Low Temperature Power-Law Creep
-------------------------------
The program now uses the same constituitive equation as in the Frost & Ashby
book.  Note that this means that the values of AcDoc are correct with respect
to the materials in the book, but OUT BY A FACTOR OF Dov for the materials
Zirconium, Potassium, InSb, Cobalt etc., everything that was done using the
FORTRAN program as modified by me (Philip Sargent) AFTER the work done by
Harold Frost.

Stopping and Interrupting
-------------------------
If you press the <Ctrl-C> keys at any time the program will stop. 
Pressing <Ctrl-C> returns you to DOS; WITHOUT SAVING ANY WORK THAT YOU MAY 
HAVE DONE. 
If it is in the middle of a plot, you can temporarily halt it by pressing
<space bar>, and then pressing <space bar> to continue.  If you press <Esc>
instead, it will stop calculating and assume that you don't want that plot. 
Pressing <space-bar> then goes on to the next plot or, if it was the last 
one, back to the 'QUIT ?' message.
At any other time pressing <Esc> will have no effect.
Pressing <Ctrl-Break> has the same effect as <Ctrl-C>.

Special Option for Olivetti and AT&T
------------------------------------
PC-compatible machines from these manufacturers emulate the IBM CGA
adapter but can also produce graphics at twice the resolution.  This
facility can be activated by typing " /o" on the command line just
after you type "DFM290".  You will need to consult your MS-DOS manual
about printing the high resolution graphs, e.g. Olivetti machines
require that you type "GRAPHICS /D/U" instead of just "GRAPHICS"
before you run DFM290 (see User Manual section 7.4, page 49). 
This only works with copies of Olivetti's graphics.com dated 28 July 1986 
or later.

8087 
---- 
DFM290 does not need a 80x87 numeric coprocessor chip, but it will use 
one if it is present.

Display Adapters
----------------
There are 5 files on the supplied disc with the filename extension 'BGI'.
These contain the information needed to plot graphs on various different
graphics adapters.  The appropriate BGI file MUST be on the same disc (in
the same subdirectory) as the file DFM290.exe which you are using.

filename          size   Adapter

ATT.BGI     6269   2 May89 5:50 640x400 AT&T, Olivetti, Compaq (?)
CGA.BGI     6253   2 May89 5:50 640x200 CGA (IBM Color Graphics Adapter)
EGAVGA.BGI  5363   2 May89 5:50 640x350 EGA and 640x480 VGA (PS/2s)
HERC.BGI    6125   2 May89 5:50 720x340 Hercules
IBM8514.BGI 6665   2 May89 5:50 1024x780 IBM 8514 
PC3270.BGI  6029   2 May89 5:50 IBM 3270 terminal

In order to save trouble you are recommended to keep ALL of
them together although strictly speaking you only need the BGI file for
the adapter you are using, e.g. if you are using an IBM PC3270/G then you
only need the file PC3270.BGI.  If you have a VGA, you will still need the
file CGA.BGI if you want to run DFM290 in CGA mode (using the /c option).

If you do corrupt or delete a BGI file and discover later that you need it, 
then you can get them easily by buying a copy of Borland's Turbo Pascal 
Version 5.5; they come as part of that package. The sizes and dates and times
of the BGI files are given here so that you can identify Turbo 5.5 versions.

Space for Users' Files
----------------------
All the data is kept in two files, one for numeric data and one for the
bibliographic notes.  The system requires space for two copies of each 
of these files since it keeps a backup whenever it stores any
changes (the backup is invisibly deleted after a successful copy).
These data files are:

MATLPARS.DAT
MATLREFS.DAT

If you have a pre-release copy of the program, i.e. before v1.0, the
program will produce a debug file DEBUG.TXT on the disc. This may get very 
large and you should delete it.
Because of the size of the debug file, THIS VERSION WILL NOT RUN FROM THE
FLOPPY DISC ON WHICH IT IS DISTRIBUTED. You will have to copy it to your
hard disc first.

Losing Data
-----------
If you crash your computer (e.g. by turning off the power) while DFM290
is in the middle of re-writing the data files, the old copy of the data
will STILL be present in a MATL????.TMP file even if the MATL????.DAT files
get corrupted.  It is fail-safe.

Command Line Options
--------------------
usage:  DFM290 <matlname> <options>
e.g.    DFM290 copper /f /w:\op\copper.lst /p- 

<matlname> is a material already present in the datafile system
<options> are as below:

/h      help and information only
/f      fast option, no interaction with user
/d      demonstration, exactly as /f but pauses 2 seconds between maps
/e      display exit codes only
/s      options for stress map (<fn> denotes full path & filename):
          /s+     produce a pressure map (default)
          /s-     do not produce a pressure map at all

/t      options for temperature map (as for /p)
          /t+     produce a temperature map (default) NOT IMPLEMENTED YET
          /t-     do not produce a temperature map at all 

/l      produce a listing to the printer
/w:<fn> sends the listing to a file instead of the printer
        (<fn> denotes full path & filename)
/o  /c  for Olivetti or CGA display modes

All options MUST BE SEPARATED BY SPACES.

The example:
DFM290 copper /f /w:\op\copper.lst /t- 
takes it the copper data (from the files MATLPARS.DAT and MATLREFS.DAT on 
the current directory, or on a directory set up using the MS-DOS APPEND
command), does NOT run the menus which enable editing but goes directly 
to calculating the map (/f fast option), it produces a listing of the input 
data, and data check comments, in file COPPER.LST on directory \OP on the 
current drive. It does not produce any temperature map (/t- option).

If you have a PS/2 with a VGA graphics adapter (Model 50, 60) or a PS/2
with an MCGA adapter (Model 30) you will automatically get high-resolution
plots on the screen, but screen dumps will NOT work.  If you
wish to do screen dumps of plots you will have to force CGA mode by using
the /c option when you start running DFM290.  Alternatively you can upgrade
to MS-DOS 4.0 where the graphics.com file DOES handle VGA, OR you can use
a commercial screendump utility such as GRAPHPLUS with MS-DOS 3.0 and later.

EXIT CODES
----------
These can be detected by MS-DOS batch files and are:
0       Everything ran OK
1       Help or exit codes information only
2       Ran but input data gives cause for concern
4       Failed to write all output files correctly
6       Failed to open an input file
7       Error in command line options
>=8     Internal error, telephone +44 (223) 332627

 Philip Sargent                                   e-mail: pms@eng.cam.ac.uk

 Engineering Dept., Trumpington St.,
 CAMBRIDGE CB2 1PZ, England
 tel. +44 (223) 332627
 fax. +44 (223) 332662

<end of readme.txt>

