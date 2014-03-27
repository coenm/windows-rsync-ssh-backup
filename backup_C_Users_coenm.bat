@echo off
REM
REM VERSION 2
REM 
set currentfilename=%0

REM ------------------------------------
REM -- START EDITING AFTER THIS LINE
REM ------------------------------------

REM Directory to backup
set localdir=C:\Users\coenm\

REM Directory to backup
REM This will be something like.. ssh user@host/{global dir}/remotedir
REM username, host, global dir can be edited at the backupfilename (i.e. _rsync_backup.bat)
set remotedir=C_Users_coenm

REM Name of the backup script in this folder
set backupfilename=_rsync_backup.bat


set doPause=true

REM ------------------------------------
REM -- DO NOT EDIT AFTER THIS LINE
REM ------------------------------------

set _argcActual=0
for %%i in (%*) do set /A _argcActual+=1
if %_argcActual% == 1 (
  set doPause=%1
)

if  exist  %backupfilename% call %backupfilename% %currentfilename% %localdir% %remotedir%

if %doPause% == true (
  pause
)