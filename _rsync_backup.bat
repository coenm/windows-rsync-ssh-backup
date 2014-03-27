@echo off
call:_addExtraSlashWin currentDirWin %CD%

REM Arguments:
REM 0: this batch filename, (not used)
REM 1: filename for backup (bat), used as prefix for pre and after actions and for include file and exclude file
REM 2: local directory to backup.
REM 3: remote directory name suffix for the root at the server
REM
REM filenames used:
REM - 
REM
REM %~0 means param 0 without quotes ("), %0 means param 0 with quotes
REM %CD% is global var with the current directory.



REM ------------------------------------
REM -- START EDITING AFTER THIS LINE
REM ------------------------------------

	REM ssh vars
	set ssh_username=coen
	set ssh_host=backupserver.my-own-domain.com
	set ssh_port=22

	REM location of the private key.
	set ssh_key_win=K:\id_rsa

	REM executables
	set exe_rsync=%currentDirWin%bin\rsync.exe
	set exe_ssh=%currentDirWin%bin\ssh.exe
	set exe_date=%currentDirWin%bin\date.exe
	
	REM root dir for all backups
	set backup_base_dir=/data/backups/my-laptop/

	REM at the end, a symbolic link will be created to the last backup. 
	set name_symlink_current=current
	set name_dir_partial=partial
	set name_dir_incomplete=incomplete

	REM RSync options; see http://ss64.com/bash/rsync_options.html OR http://ss64.com/bash/rsync.html  for more info.
	REM Show what would have been transferred.
	set rsync_option_dry_run=0

	REM only use file size when determining if a file should be transferred
	set rsync_option_size_only=0

	REM keep partially transferred files
	set rsync_option_partial=1

	REM show progress during transfer
	set rsync_option_show_progress=1

	REM increase verbosity
	set rsync_option_verbose=1

	REM give some file transfer stats
	set rsync_option_stats=1

	REM compress file data (useful on slow links)
	set rsync_option_compress=1

	REM copy whole files, no incremental checks
	set rsync_option_whole_file=0

REM ------------------------------------
REM -- DO NOT EDIT AFTER THIS LINE
REM ------------------------------------




REM -------------------------------------------
REM	Check if the number of arguments are correct and if the private key exists
REM -------------------------------------------
set _argcActual=0
set _argcExpected=3

for %%i in (%*) do set /A _argcActual+=1

if %_argcActual% NEQ %_argcExpected% (
	call:_ShowUsage %0
	goto:_EOF
)

if not exist  %ssh_key_win%  (
	call:_NoSshKeyFound %ssh_key_win%
	goto:_EOF
)


REM -------------------------------------
REM 	Get arguments
REM -------------------------------------
	set backupfilename=%~1
	set local_backup_root=%~2
	set server_dir=%~3

	REM check if backupfilename contains at least one backslash, if not, prefix with current dir.
	set tmp=%backupfilename:\=%
	if %tmp%==%backupfilename% set backupfilename=%currentDirWin%%backupfilename%

	title Backup %local_backup_root% using rsync ....

REM -------------------------------------------
REM	Set vars
REM -------------------------------------------
	set exe_ssh_slashed=%exe_ssh:\=/%
	call:_convertDirName ssh_key_cygwin %ssh_key_win%
	set backup_remote_dir=%backup_base_dir%%server_dir%/

	set cur_date=
	for /f "delims=" %%a in ('%exe_date% +%%Y.%%m.%%d_%%H.%%M.%%S') do set cur_date=%%a

	set curdirCygwin=%currentDirWin%
	call:_convertDirName curdirCygwin %currentDirWin%

	set rsync_option_exclude_from=
	call:_get_excludes rsync_option_exclude_from %currentDirWin% %backupfilename%

	set rsync_option_include_from=
	call:_get_includes rsync_option_include_from %currentDirWin% %backupfilename%

	set rsync_backup_from=
	call:_addExtraSlashWin rsync_backup_from %local_backup_root%
	call:_convertDirName rsync_backup_from %rsync_backup_from%

	set rsync_link_to_current=%backup_remote_dir%%name_symlink_current%
	set rsync_backup_to_partial=%backup_remote_dir%%name_dir_partial%
	set rsync_backup_to_incomplete=%backup_remote_dir%%name_dir_incomplete%
	set rsync_backup_to_complete=%backup_remote_dir%%cur_date%

	set rsync_options=
	if %rsync_option_dry_run%==1 (
		set rsync_options=%rsync_options% "--dry-run"
	)
	if %rsync_option_size_only%==1 (
		set rsync_options=%rsync_options% "--size-only"
	)
	if %rsync_option_partial%==1 (
		set rsync_options=%rsync_options% "--partial" "--partial-dir=%rsync_backup_to_partial%" 
	)
	if %rsync_option_show_progress%==1 (
		set rsync_options=%rsync_options% "--progress"
	)
	if %rsync_option_verbose%==1 (
		set rsync_options=%rsync_options% "-v"
	)
	if %rsync_option_stats%==1 (
		set rsync_options=%rsync_options% "--stats"
	)
	if %rsync_option_compress%==1 (
		set rsync_options=%rsync_options% "--compress"
	)
	if %rsync_option_whole_file%==1 (
		set rsync_options=%rsync_options% "--whole-file"
	) else (
		set rsync_options=%rsync_options% "--no-whole-file"
	)

	set rsync_default_options="-rlt" "--hard-links" "--delete" "--delete-excluded" "--link-dest=%rsync_link_to_current%" "--no-perms" "--chmod=u+rwx,go=rx,o-rwx"
	set ssh_args=-p %ssh_port% -i %ssh_key_cygwin% -o StrictHostKeyChecking=no -o PreferredAuthentications=hostbased,publickey -o NumberOfPasswordPrompts=0




REM -------------------------------------------
REM	Start Process
REM -------------------------------------------

	echo.
	echo Run batch before backup.
	call:_run_pre_post pre %backupfilename%

	echo.
	echo Create working dir for rsync backup.
	%exe_ssh% %ssh_username%@%ssh_host% %ssh_args%      "mkdir -p %rsync_backup_to_incomplete% && mkdir -p %rsync_link_to_current%"

	echo.
	echo Start RSync backup.
	%exe_rsync% ^
          %rsync_default_options% ^
          %rsync_options% ^
          %rsync_option_exclude_from% ^
          %rsync_option_include_from% ^
	  "-e" ""%exe_ssh_slashed%" %ssh_args%" ^
	  "--exclude=/cygdrive" ^
	  "--exclude=/proc" ^
	  %rsync_backup_from% ^
	  "%ssh_username%@%ssh_host%:%rsync_backup_to_incomplete%"

	echo.	
	echo Rename working directory to '%cur_date%/' directory and create symbolic link 'current/' to '%cur_date%/'
	%exe_ssh% %ssh_username%@%ssh_host% %ssh_args%  ^
	     "mv %rsync_backup_to_incomplete% %rsync_backup_to_complete%  && rm -rf %rsync_link_to_current%  && cd %backup_remote_dir% && ln -s %cur_date% %name_symlink_current%"


	echo.
	echo Run batch after backup.
	call:_run_pre_post post %backupfilename%

	echo.
	goto:_EOF



REM -------------------------------------------
REM	'FUNCTIONS'
REM -------------------------------------------
:_NoSshKeyFound
	SETLOCAL
	echo.
	echo ERROR
	echo No SSH key found (%~1)
	echo RSync backup canceled!
	echo.
	ENDLOCAL
	goto:eof


:_ShowUsage
	SETLOCAL
	echo.
	echo ERROR
	echo The number of arguments do not match.
	echo Uage: %~1 [filename of orig batch file] [local direcotry to backup] [server directory suffix]
	echo.
	ENDLOCAL
	goto:eof


:_addExtraSlashWin
	REM -- %~1: return variable reference and converted input
	REM -- %~2: input
	SETLOCAL
	set "output=%~1"
	set "input=%~2"
	set tmp=%input:~-1%
	IF  "%tmp%"=="\"   (
  		set tmp=%input%
	) ELSE (
		set "tmp=%input%\"
	)
	( ENDLOCAL
		set "%~1=%tmp%"
	)
	goto:eof

:_run_pre_post
	SETLOCAL
	set "backupFileNameWin=%~2"
	set backupFileNameWinWithoutExtension=%backupFileNameWin:~0,-4%
	
	IF %~1 == pre (
		if exist %backupFileNameWinWithoutExtension%_before_run.bat (
			call %backupFileNameWinWithoutExtension%_before_run.bat 
		) ELSE (
			if  exist %backupFileNameWin%_before_run.bat (
				call %backupFileNameWin%_before_run.bat
			)
		)
	)

	IF %~1 == post (
		if exist %backupFileNameWinWithoutExtension%_after_run.bat (
			call %backupFileNameWinWithoutExtension%_after_run.bat 
		) ELSE (
			if  exist %backupFileNameWin%_after_run.bat (
				call %backupFileNameWin%_after_run.bat
			)
		)
	)

	ENDLOCAL
	goto:eof


:_convertDirName
	REM -- %~1: return variable reference and converted input
	REM -- %~2: input
	SETLOCAL
	set "output=%~1"
	set "input=%~2"
	set tmp=%input%

	REM removes ':'
	set tmp=%tmp::=%

	REM replaces backslash for normal slash
	set tmp=%tmp:\=/%

	REM add prefix '/cygdrive/' 
	set tmp=/cygdrive/%tmp:\=/%

	REM set output
	( ENDLOCAL
		set "%~1=%tmp%"
	)
	goto:eof


:_get_excludes
	REM -- %~1: return variable reference
	REM -- %~2: currentWinDir
	REM -- %~3: backupFilename
	SETLOCAL
	set "currentDirWin=%~2"
	set "backupFileNameWin=%~3"
	set tmpReturn1=notset
	set tmpReturn2=notset
	set tmpReturn=

	if  exist  %currentDirWin%rsync_exclude_default.txt (
		call:_convertDirName tmpReturn1 %currentDirWin%rsync_exclude_default.txt
	)
	if %tmpReturn1% NEQ notset ( 
		set tmpReturn1="--exclude-from=%tmpReturn1%"
	) ELSE (
		set tmpReturn1=
	)

	REM assume .bat extension.
	set backupFileNameWinWithoutExtension=%backupFileNameWin:~0,-4%
	if  exist  %backupFileNameWinWithoutExtension%_exclude.txt (
		call:_convertDirName tmpReturn2 %backupFileNameWinWithoutExtension%_exclude.txt 
	) ELSE (
		if  exist  %backupFileNameWin%_exclude.txt (
			call:_convertDirName tmpReturn2 %backupFileNameWin%_exclude.txt
		)
	)
	if %tmpReturn2% NEQ notset ( 
		set tmpReturn2="--exclude-from=%tmpReturn2%"
	)  ELSE (
		set tmpReturn2=
	)

	set tmpReturn=%tmpReturn1% %tmpReturn2%

	REM set output
	( ENDLOCAL
		set "%~1=%tmpReturn%"
	)
	goto:eof


:_get_includes
	REM -- %~1: return variable reference
	REM -- %~2: currentWinDir
	REM -- %~3: backupFilename
	SETLOCAL
	set "currentDirWin=%~2"
	set "backupFileNameWin=%~3"
	set tmpReturn2=notset
	set tmpReturn=

	REM assume .bat extension.
	set backupFileNameWinWithoutExtension=%backupFileNameWin:~0,-4%

	if  exist  %backupFileNameWinWithoutExtension%_include.txt (
		call:_convertDirName tmpReturn2 %backupFileNameWinWithoutExtension%_include.txt 
	) ELSE (
		if  exist  %backupFileNameWin%_include.txt (
			call:_convertDirName tmpReturn2 %backupFileNameWin%_include.txt
		)
	)
	if %tmpReturn2% NEQ notset ( 
		set tmpReturn2="--include-from=%tmpReturn2%"
	)  ELSE (
		set tmpReturn2=
	)
	set tmpReturn=%tmpReturn2%

	REM set output
	( ENDLOCAL
		set "%~1=%tmpReturn%"
	)
	goto:eof


:_EOF
	echo We are done..
	echo.