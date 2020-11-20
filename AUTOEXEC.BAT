rem    pms                 autoexec.pms
rem 29-March-1988 12:04 PMS
rem The ORDER of the items in this autoexec file is CRITICAL.
prompt $p$g
c:
path c:\cpqdos;c:\utils;c:\turbo4;c:\word;c:\windows
set comspec=c:\command.com
echo off
set bpath=c:\brief\macros
set bhelp=c:\brief\help
set bbackup=.
set bcpas="tpc /tc:\turbo4 %%s"
set bcm=cm
set bpackages=pas,txt,itf,m:r;doc:r,wp
set bflags=-ai120rz -mPMS
set xtree=C1
set tmp=c:\c\junk
set temp=c:\c\junk
keybuk
\utility\mace\rxbak
echo on
cache-at /w
mouse
cd\utils
minder
cd\
whatday

