CLS
@echo 

REM -- Force Truecypt and Keepass to quit (if open) so container files will be closed
"C:\Program Files (x86)\TrueCrypt\TrueCrypt.exe" /dismount o /force /quit /silent
"C:\Program Files (x86)\KeePass Password Safe 2\KeePass.exe" --exit-all


REM -- Remove latex compiled output files.
set sourceDir="C:\Users\coenm\latex\"

echo --- Deleting junk files from windows and/or Mac OS. ---
del /s %sourceDir%thumbs.db
del /s %sourceDir%.DS_Store

echo --- Deleting files created by latex. ---
del /s /q  %sourceDir%*.aux
del /s /q  %sourceDir%*.bbl
del /s /q  %sourceDir%*.out
del /s /q  %sourceDir%*.*.bak
del /s /q  %sourceDir%*.toc
del /s /q  %sourceDir%*.blg
del /s /q  %sourceDir%*.dvi
del /s /q  %sourceDir%*.log
del /s /q  %sourceDir%*.ps
del /s /q  %sourceDir%*.tdo
del /s /q  %sourceDir%*.*.sav
del /s /q  %sourceDir%*.glo
del /s /q  %sourceDir%*.ist
del /s /q  %sourceDir%*.lof
del /s /q  %sourceDir%*.lot
del /s /q  %sourceDir%*.brf
del /s /q  %sourceDir%*.ilg
del /s /q  %sourceDir%*.ind
del /s /q  %sourceDir%*.idx
