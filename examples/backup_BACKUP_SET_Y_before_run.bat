CLS
@echo off

goto:_check_Q


:_check_N
	if  exist  Q:\checkfile.txt goto:_unmount_Q
	goto :_eof

:_unmount_Q
	echo Unmount Q or cancel the backup!
	"C:\Program Files (x86)\TrueCrypt\TrueCrypt.exe"
	pause
	goto:_check_Q
	REM "C:\Program Files (x86)\TrueCrypt\TrueCrypt.exe" /dismount q /force /quit /silent
	REM "C:\Program Files (x86)\TrueCrypt\TrueCrypt.exe" /dismount q

:_eof








