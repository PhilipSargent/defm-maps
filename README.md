defm-maps
=========

Deformation Mechanism Maps

see https://en.wikipedia.org/wiki/Deformation_mechanism_map

This is a project to re-engineer the software used to produce the deformation mechanism maps published in the 
Frost & Ashby book. This was written in Turbo Pascal and runs under MS-DOS. It ported and extended
the Fortran software written by Harold Frost. Earlier maps in the book were generated using the Fortran code.

The new version is DFM2020, ported in November 2020 to run on Windows 10 using the Free Pascal Compiler. 
This newer version generates deformation mechanism maps as SVG files as well as producing an on-screen
image. It also generates Indentation Creep maps which show the dominant mechanisms over different 
time/temperature doamins of indentation creep. These indentaiotn mechanism maps are unpublished.


The DFM290.* files are the most recent documentation. They refer to the DOS version. 
They are being updated and replaced.


This repository also conatains a branch which is the original Turbo Pascal code, edited to run 
in the DOS shell in DOSBOX 0.74-3 running on Windows 10 (tested 19 Nov.2020). The DFM290.exe
runs, and the source code also compiles with Turbo Pascal 7.3.4 and produces the same results as the 1993 executable.
This Turbo Pascal and DOSbox combination is distributed by the TPWDB project
https://sourceforge.net/projects/turbopascal-wdb/ .
Change this setting in C:\TPWDB\Main\DOSBox\dosbox.conf
from:
cycles=auto
to:
cycles=max
as we want it to run as fast as possible and are not trying to match slow MS-DOS games.

This set of commits on github has been synthesized from a disparate colleciton of backups done over the years, 
some using ARC packaging format which does not preserve file timestamps. Fortunately I was using the
BRIEF editor for much of this work which had a macro to insert a timestamp into the code.
