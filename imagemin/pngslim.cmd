@echo off
	:user_settings
	:: Specify Zopfli Compression
	set "zopfli_compression=90"
	:: Specify number of KS-Flate trials
	set "compression_trials=4"
	:: Number of second(s) before give up in a filtering pass
	set "filtering_search=5
:pngslim
:: Global engine: 03.11.2013
setlocal enabledelayedexpansion
color 0f
set "name=pngslim"
set "version=08.11.2013"
set "lib=%~dp0lib\"
path %lib%;%path%
if "%~1" equ "thread" call:thread_run "%~2" %3 %4 & exit /b
set "script_name=%~0"
set "define_source_path=%~dp0"
set "temporary_folder=%temp%\pngslim\%random%\"
set "temporary_parent_folder=%temp%\pngslim\"
:script_check
if exist %temporary_parent_folder% goto:debug_session
if not exist %lib% goto:debug_lib_folder
:counters
set "current_png_number=0"
set "current_png_size=0"
set "total_png_number=0"
set "total_png_size=0"
set "change_png=0"
set "wait_in_ms=8000"
:params
set "png="
set "log_file=%temporary_folder%log_file.csv"
set "counters_png=%temporary_folder%countpng"
set "separe_bar=__________________________________________________________________________"
:thread_configuration
set "number_of_png_thread=1"
if %number_of_png_thread% equ 1 (set "multi_thread=0") else set "multi_thread=1"
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
echo  Formats : PNG
echo            ---
echo.
echo.
pause >nul
goto:eof
)
:check_folder
for %%a in (%*) do (
call:define_source "%%~a"
if defined is_a_png (
if not defined is_a_folder (
set /a "total_png_number+=1"
) else (
for /f "delims=" %%i in ('dir /b /s /a-d-h "%%~a\*.png" 2^>nul ^| find /c /v "" ') do set /a "total_png_number+=%%i"
)
)
)
if "%total_png_number%" equ "0" set "multi_thread=0"
set "params1="
for %%a in (%*) do (
set "err="
1>nul 2>nul dir "%%~a" || (
goto:eof
)
if not defined err (
call:define_source "%%~a"
if not defined is_a_png set "err=2"
if not defined err (
if defined is_a_png if not defined png call:png "%%~a"
set "params1=!params1! %%a"
)
)
)
if not defined params1 goto:debug_unsupported
:temporary_path
if not exist "%temporary_folder%" 1>nul 2>&1 md "%temporary_folder%"
if "%png%" equ "0" set "multi_thread=0"
if %multi_thread% neq 0 1>nul 2>&1 >"%log_file%" echo.
if not defined png set "png=0"
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
if defined is_a_png if "%png%" neq "0" call:png_in_folder "%%~a"
)
:thread_check_wait
set "thread="
for /l %%z in (1,1,%number_of_png_thread%) do if exist "%temporary_folder%threadpng%%z.lock" (set "thread=1") else call:echo_in_log & call:set_title
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
if /i "%2" equ "png" call:png_run %1 %3 & call:count_more "%counters_png%"
if exist "%temporary_folder%thread%2%3.lock" >nul 2>&1 del /f /q "%temporary_folder%thread%2%3.lock"
exit /b
:count_more
if %multi_thread% equ 0 exit /b
call:loop_wait "%~1.lock"
>"%~1.lock" echo.%~1
>>"%counters_png%" echo.1
1>nul 2>&1 del /f /q "%~1.lock"
exit /b
:loop_wait
if exist "%~1" (1>nul 2>&1 ping -n 1 -w %wait_in_ms% 127.255.255.255 & goto:loop_wait)
exit /b 0
:define_source
set "is_a_png="
set "is_a_folder="
1>nul 2>nul dir /ad "%~1" && set "is_a_folder=1"
if not defined is_a_folder (
if /i "%~x1" equ ".png" set "is_a_png=1"
) else (
1>nul 2>nul dir /b /s /a-d-h "%~1\*.png" && set "is_a_png=1"
)
exit /b
:png
set png=1
exit /b
:set_title
if "%png%" equ "0" (title %~1%name% %version% & exit /b)
if %multi_thread% neq 0 (
set "current_png_number=0"
for %%b in ("%counters_png%") do set /a "current_png_number=%%~zb/3" 2>nul
)
title %~1 [%current_png_number%/%total_png_number%] - %name% - %version%
exit /b
:png_in_folder
if defined is_a_folder (
for /f "delims=" %%i in ('dir /b /s /a-d-h "%~1\*.png" ') do (
call:thread_creation png %number_of_png_thread% "%%~fi"
set /a "current_png_number+=1" & call:set_title
)
) else (
call:thread_creation png %number_of_png_thread% "%~1"
set /a "current_png_number+=1" & call:set_title
)
exit /b
:png_run
call:copy_temporary "%~1"
if %png% equ 1 call:slim "%temporary_folder%%~nx1" >nul
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
) else (
set /a "total_png_size+=%change%"
if %change% equ 0 echo  Out: %~z1 Bytes
if %change% neq 0 echo  Out: %~z1 Bytes - %change% Bytes saved
echo %separe_bar%
echo.
)
exit /b
:end
set finish=%time%
title Finished - %name% - %version%
if "%png%" equ "0" 1>nul ping -n 1 -w %wait_in_ms% 127.255.255.255 2>nul
if %multi_thread% neq 0 for /f "usebackq tokens=1-5 delims=;" %%a in ("%log_file%") do (
if /i "%%~xa" equ ".png" set /a "total_png_size+=%%b" & set /a "current_png_size+=%%c"
)
set /a "change_png=%total_png_size%-%current_png_size%" 2>nul
set /a "change_png_kb=%change_png%/1024" 2>nul
echo.
echo  Total: %change_png_kb% KB [%change_png% Bytes] saved.
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

	:slim
	start /wait /low %lib%pngslimr.cmd "%~f1"
	exit /b