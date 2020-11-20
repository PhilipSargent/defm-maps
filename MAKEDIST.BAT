rem makedist.bat
rem PMS 12-June-1993 07:33 
rem This constructs the distribution files properly, but assumes that
rem everything has been compiled properly first.
cd \dfmap
rem these deletions might seem excessive, but single files witht he same
rem names as directories, with read-only permission set, make it needful.
IF EXIST distrib chmod -w distrib
chmod -w distrib\*.*
IF EXIST distrib\source chmod -w distrib\source
chmod -w distrib\source\*.*
del distrib\*.* <y.txt
del distrib\source\*.* <y.txt
\utils\db\rm /descend distrib
mkdir \dfmap\distrib
mkdir \dfmap\distrib\source
rem
IF NOT EXIST floppy\readme GOTO ERROR
xcopy floppy\*.* distrib
tdstrip dfm290.exe junk.exe
IF EXIST junk.exe exepack junk.exe distrib\dfm290.exe
IF NOT EXIST junk.exe copy dfm290.exe distrib
IF EXIST junk.exe del junk.exe
tdstrip dfmfix.exe junk.exe
IF EXIST junk.exe exepack junk.exe distrib\dfmfix.exe
IF NOT EXIST junk.exe copy dfmfix.exe distrib
IF EXIST junk.exe del junk.exe
copy makedist.bat distrib
IF NOT EXIST MATLPARS.DAT GOTO ERROR
IF NOT EXIST MATLREFS.DAT GOTO ERROR
IF NOT EXIST DFMAP.DOC GOTO ERROR
copy MATLPARS.DAT distrib
copy MATLREFS.DAT distrib
copy DEVELOP.TXT distrib\source
copy \tpus\stringio.pas distrib\source
copy \dfmap\vcs.cfg \dfmap\vcs-bak.cfg
copy \dfmap\vcs.cfg distrib\source
cd \dfmap\distrib\source
get -Q *.??v 
cd \dfmap\distrib
pkpak -a source.arc source\*.*
chmod -w distrib\source\*.*
del distrib\source\*.* <y.txt
IF NOT EXIST \dfmap\MISC\hpunit.pas GOTO ERROR
pkpak -a extras.arc \dfmap\misc\*.*
pkpak -a dfm-arc.arc *.*
makeboo dfm-arc.arc
move dfm-arc.arc \dfmap
move dfm-arc.boo \dfmap
cd \dfmap
chmod -w distrib\*.*
chmod -w distrib\*.*
chmod -w distrib\source\*.*
del distrib\*.* <y.txt
del distrib\source\*.* <y.txt
\utils\db\rm /descend distrib
goto ok
:error
echo FAILURE ! Some file missing
goto end
:ok
echo Everything seemed to work OK
:end

