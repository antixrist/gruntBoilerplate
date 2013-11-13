@echo off
	:user_settings
	:: ScriptJPG will run automatically if autorun=1
	set "autorun=0"
	:: If it runs automatically, specify default option
	set "default_option=1"
:scriptjpg
:: Global engine: 04.11.2013
setlocal enabledelayedexpansion
color 0f
set "name=ScriptJPG"
set "version=04.11.2013"
set "lib=%~dp0lib\"
path %lib%;%path%
if "%~1" equ "thread" call:thread_run "%~2" %3 %4 & exit /b
set "script_name=%~0"
set "define_source_path=%~dp0"
set "temporary_folder=%temp%\ScriptJPG\%random%\"
set "temporary_parent_folder=%temp%\ScriptJPG\"
:script_check
if exist %temporary_parent_folder% goto:debug_session
if not exist %lib% goto:debug_lib_folder
:counters
set "current_jpg_number=0"
set "current_jpg_size=0"
set "total_jpg_number=0"
set "total_jpg_size=0"
set "change_jpg=0"
set "wait_in_ms=500"
:params
set "jpg="
set "log_file=%temporary_folder%log_file.csv"
set "counters_jpg=%temporary_folder%countjpg"
set "separe_bar=__________________________________________________________________________"
:thread_configuration
set "number_of_jpg_thread=4"
if %number_of_jpg_thread% equ 1 (set "multi_thread=0") else set "multi_thread=1"
if "%~1" neq "" (
set "params=%*"
) else (
title Usage - %name% - %version%
echo.
echo.
echo  Usage   : To use %name%, just drag-and-drop your files
echo.
echo            on the %name% file
echo.
echo.
echo            ---
echo  Formats : JPG
echo            ---
echo.
echo.
echo  Extra   : s = delete all non-displayed data
echo.
echo.
pause >nul
goto:eof
)
:check_folder
for %%a in (%*) do (
call:define_source "%%~a"
if defined is_a_jpg (
if not defined is_a_folder (
set /a "total_jpg_number+=1"
) else (
for /f "delims=" %%i in ('dir /b /s /a-d-h "%%~a\*.jpg" 2^>nul ^| find /c /v "" ') do set /a "total_jpg_number+=%%i"
)
)
)
if "%total_jpg_number%" equ "0" set "multi_thread=0"
set "params1="
for %%a in (%*) do (
set "err="
1>nul 2>nul dir "%%~a" || (
goto:eof
)
if not defined err (
call:define_source "%%~a"
if not defined is_a_jpg set "err=2"
if not defined err (
if defined is_a_jpg if not defined jpg call:user_interface "%%~a"
set "params1=!params1! %%a"
)
)
)
if not defined params1 goto:debug_unsupported
:temporary_path
if not exist "%temporary_folder%" 1>nul 2>&1 md "%temporary_folder%"
if "%jpg%" equ "0" set "multi_thread=0"
if %multi_thread% neq 0 1>nul 2>&1 >"%log_file%" echo.
if not defined jpg set "jpg=0"
:first_echo
cls
echo.
echo.
echo  %name% - %version%
echo.
echo.
call:set_title
set start=%time%
for %%a in (%params1%) do (
call:define_source "%%~a"
if defined is_a_jpg if "%jpg%" neq "0" call:jpg_in_folder "%%~a"
)
:thread_check_wait
set "thread="
for /l %%z in (1,1,%number_of_jpg_thread%) do if exist "%temporary_folder%threadjpg%%z.lock" (set "thread=1") else call:echo_in_log & call:set_title
if defined thread >nul 2>&1 ping -n 1 -w %wait_in_ms% 127.255.255.255 & goto:thread_check_wait
call:end
pause>nul & exit /b
:thread_creation
if %2 equ 1 call:thread_run "%~3" %1 1 & call:echo_in_log & exit /b
for /l %%z in (1,1,%2) do (
if not exist "%temporary_folder%thread%1%%z.lock" (
call:echo_in_log
>"%temporary_folder%thread%1%%z.lock" echo : %~3
start "" /b /low cmd.exe /c ""%script_name%" thread "%~3" %1 %%z "
exit /b
)
)
1>nul 2>&1 ping -n 1 -w %wait_in_ms% 127.255.255.255
goto:thread_creation
:echo_in_log
if %multi_thread% equ 0 exit /b
if exist "%temporary_folder%echo_in_log.lock" exit /b 
>"%temporary_folder%echo_in_log.lock" echo.echo_in_log %echo_file_log%
if not defined echo_file_log set "echo_file_log=1"
for /f "usebackq skip=%echo_file_log% tokens=1-5 delims=;" %%b in ("%log_file%") do (
echo  "%%~b"
echo  In  : %%c Bytes
if %%d geq %%c (
echo  Out : %%d Bytes
)
if %%d lss %%c (
echo  Out : %%d Bytes - %%e Bytes saved
)
echo  %separe_bar%
echo.
set /a "echo_file_log+=1"
)
1>nul 2>&1 del /f /q "%temporary_folder%echo_in_log.lock"
exit /b
:thread_run
if /i "%2" equ "jpg" call:jpg_run %1 %3 & call:count_more "%counters_jpg%"
if exist "%temporary_folder%thread%2%3.lock" >nul 2>&1 del /f /q "%temporary_folder%thread%2%3.lock"
exit /b
:count_more
if %multi_thread% equ 0 exit /b
call:loop_wait "%~1.lock"
>"%~1.lock" echo.%~1
>>"%counters_jpg%" echo.1
1>nul 2>&1 del /f /q "%~1.lock"
exit /b
:loop_wait
if exist "%~1" (1>nul 2>&1 ping -n 1 -w %wait_in_ms% 127.255.255.255 & goto:loop_wait)
exit /b 0
:define_source
set "is_a_jpg="
set "is_a_folder="
1>nul 2>nul dir /ad "%~1" && set "is_a_folder=1"
if not defined is_a_folder (
if /i "%~x1" equ ".jpg" set "is_a_jpg=1"
) else (
1>nul 2>nul dir /b /s /a-d-h "%~1\*.jpg" && set "is_a_jpg=1"
)
exit /b
:set_title
if "%jpg%" equ "0" (title %~1%name% %version% & exit /b)
if %multi_thread% neq 0 (
set "current_jpg_number=0"
for %%b in ("%counters_jpg%") do set /a "current_jpg_number=%%~zb/3" 2>nul
)
title %~1 [%current_jpg_number%/%total_jpg_number%] - %name% - %version%
exit /b
:user_interface
if %autorun% equ 1 (
if "%default_option%" neq "1" if "%default_option%" neq "2" if "%default_option%" neq "3" if "%default_option%" neq "4" if "%default_option%" neq "5" if "%default_option%" neq "6" if "%default_option%" neq "7" if "%default_option%" neq "8" if "%default_option%" neq "9" if "%default_option%" neq "s" set "jpg=1" & exit /b
set "jpg=%default_option%
exit /b
)
title %name% - %version%
cls
echo.
echo.
echo  %name% - %version%
echo.
echo.
echo.
echo  [1] Losslessly        [2] Quality 95        [3] Quality 90
echo.
echo.
echo  [4] Quality 85        [5] Quality 80        [6] Quality 75
echo.
echo.
echo  [7] Quality 70        [8] Quality 65        [9] Quality 60
echo.
echo.
echo.
set jpg=
set /p jpg=# Enter an option: 
echo.
if "%jpg%" equ "" goto:user_interface
if "%jpg%" neq "1" if "%jpg%" neq "2" if "%jpg%" neq "3" if "%jpg%" neq "4" if "%jpg%" neq "5" if "%jpg%" neq "6" if "%jpg%" neq "7" if "%jpg%" neq "8" if "%jpg%" neq "9" if "%jpg%" neq "s" goto:user_interface
exit /b
:jpg_in_folder
if defined is_a_folder (
for /f "delims=" %%i in ('dir /b /s /a-d-h "%~1\*.jpg" ') do (
call:thread_creation jpg %number_of_jpg_thread% "%%~fi"
set /a "current_jpg_number+=1" & call:set_title
)
) else (
call:thread_creation jpg %number_of_jpg_thread% "%~1"
set /a "current_jpg_number+=1" & call:set_title
)
exit /b
:jpg_run
call:copy_temporary "%~1"
if %jpg% equ 1 call:jpg_lossless "%temporary_folder%%~nx1" >nul
if %jpg% equ 2 set "jpg_quality=95" & call:jpg_lossy "%temporary_folder%%~nx1" >nul
if %jpg% equ 3 set "jpg_quality=90" & call:jpg_lossy "%temporary_folder%%~nx1" >nul
if %jpg% equ 4 set "jpg_quality=85" & call:jpg_lossy "%temporary_folder%%~nx1" >nul
if %jpg% equ 5 set "jpg_quality=80" & call:jpg_lossy "%temporary_folder%%~nx1" >nul
if %jpg% equ 6 set "jpg_quality=75" & call:jpg_lossy "%temporary_folder%%~nx1" >nul
if %jpg% equ 7 set "jpg_quality=70" & call:jpg_lossy "%temporary_folder%%~nx1" >nul
if %jpg% equ 8 set "jpg_quality=65" & call:jpg_lossy "%temporary_folder%%~nx1" >nul
if %jpg% equ 9 set "jpg_quality=60" & call:jpg_lossy "%temporary_folder%%~nx1" >nul
if %jpg% equ s set "stream=1" & goto:clean_jpg_data
	:clean_jpg_data
	if %stream% equ 1 (
	:: Delete all unnecessary data
	jscl -r -j -cp "%temporary_folder%%~nx1" >nul
	)
call:check_compare "%~f1" "%temporary_folder%%~nx1" >nul
call:save_log "%~f1" !file_size_origine!
exit /b
:copy_temporary
if %multi_thread% equ 0 (
echo  "%~nx1"
echo  In:  %~z1 Bytes
)
set "file_size_origine=%~z1"
1>nul 2>&1 copy /b /y "%~f1" "%temporary_folder%%~nx1"
exit /b
:save_log
set /a "change=%2-%~z1"
if %multi_thread% neq 0 (
if exist "%temporary_folder%echo_in_log.lock" (1>nul 2>&1 ping -n 1 -w %wait_in_ms% 127.255.255.255 & goto:save_log)
1>nul 2>&1 >"%temporary_folder%echo_in_log.lock" echo.save_log %~1
1>nul 2>&1 >>"%log_file%" echo.%~nx1;%2;%~z1;%change%
1>nul 2>&1 del /f /q "%temporary_folder%echo_in_log.lock"
)
exit /b
:end
set finish=%time%
title Finished - %name% - %version%
if "%jpg%" equ "0" 1>nul ping -n 1 -w %wait_in_ms% 127.255.255.255 2>nul
if %multi_thread% neq 0 for /f "usebackq tokens=1-5 delims=;" %%a in ("%log_file%") do (
if /i "%%~xa" equ ".jpg" set /a "total_jpg_size+=%%b" & set /a "current_jpg_size+=%%c"
)
set /a "change_jpg=%total_jpg_size%-%current_jpg_size%" 2>nul
set /a "change_jpg_kb=%change_jpg%/1024" 2>nul
echo.
echo  Total: %change_jpg_kb% KB [%change_jpg% Bytes] saved.
echo.
echo.
echo  Started  at : %start%
echo  Finished at : %finish%
echo.
1>nul 2>&1 rd /s /q "%temporary_parent_folder%"
exit /b
:debug_unsupported
title Error - %name% - %version%
cls
echo.
echo.
echo  %name% does not support this format.
echo.
echo.
pause >nul
goto:eof
:debug_lib_folder
title Error - %name% - %version%
cls
echo.
echo.
echo  %name% can not find lib folder.
echo.
echo.
pause >nul
goto:eof
:debug_session
for /f "tokens=* delims=" %%a in ('tasklist /v /fi "imagename eq cmd.exe" ^| find /c "%name%" ') do (
if %%a equ 1 exit
)
1>nul 2>&1 rd /s /q "%temporary_parent_folder%"
1>nul ping -n 1 -w %wait_in_ms% 127.255.255.255 2>nul
goto:user_settings
exit

:: Comparators ::

:check_compare
if %~z1 leq %~z2 (1>nul 2>&1 del /f /q %2) else (1>nul 2>&1 move /y %2 %1 || exit /b 1)
exit /b
:check_move
1>nul 2>&1 move /y %2 %1
exit /b

:: Optimization routines ::

	:jpg_lossless
	:: Check if JPG can be grayscale
	pngout -s4 -c0 -q -y -force "%~f1"
	:: If JPG can be grayscale, encode to it
	if "%errorlevel%"=="0" jpegtran -grayscale "%~f1" "%~f1"
	:: Optimize JPG with jpegrescan script
	miniperl "%lib%jpegrescan.pl" jpegtran "%~f1" "%~f1"
	set "stream=1"
	exit /b
	
	:jpg_lossy
	:: Convert to specified quality
	jpegoptim --force --max=%jpg_quality% --quiet "%~f1" "%~f1"
	pngout -s4 -c0 -q -y -force "%~f1"
	if "%errorlevel%"=="0" jpegtran -grayscale "%~f1" "%~f1"
	miniperl "%lib%jpegrescan.pl" jpegtran "%~f1" "%~f1"
	set "stream=1"
	exit /b