@echo off
:script_check
if .%1==. (
exit
)
if not defined temporary_folder exit
:pngslimr
setlocal enabledelayedexpansion
color 0f
set "name=pngslim"
set "version=08.11.2013"
title %name% - %version%
:settings
set "file_name=%~n1"
set "file_size=%~z1"
set "number_of_refresh=0"
set "number_of_trials=0"
set "number_of_pass_a=0"
set "number_of_pass_b=0"
set "mix_with_origine=0"
:settings_previous
if not defined zopfli_compression set "zopfli_compression=90"
if not defined compression_trials set "compression_trials=4"
if not defined filtering_search set "filtering_search=5"
call:refresh
:step_a
:: Check Interlacing files
if %file_size% lss 102400 goto:step_b
set "number_of_refresh=a" &call:refresh
truepng -f0 -i0 -g0 -a0 -md remove all -zc6 -zm9 -zs1 -quiet -force -y "%~f1" -out "%temporary_folder%%~n1-i0.png"
set "number_of_refresh=b" &call:refresh
truepng -f0 -i1 -g0 -a0 -md remove all -zc6 -zm9 -zs1 -quiet -force -y "%~f1" -out "%temporary_folder%%~n1-i1.png"
call:check_size "%temporary_folder%%~n1-i0.png" "%temporary_folder%%~n1-i1.png"
	if %size_b% lss %size_a% (
	set "number_of_refresh=7" &call:refresh
	pngzopfli "%temporary_folder%%~n1-i1.png" 2
	call:check_compare "%temporary_folder%%~n1-i1.png" "%temporary_folder%%~n1-i1.zopfli.png"
	deflopt -k -b -s "%temporary_folder%%~n1-i1.png" >nul
	1>nul 2>nul defluff < "%temporary_folder%%~n1-i1.png" > "%temporary_folder%%~n1-i1.tmp"
	call:check_move "%temporary_folder%%~n1-i1.png" "%temporary_folder%%~n1-i1.tmp"
	deflopt -k -b -s "%temporary_folder%%~n1-i1.png" >nul
	call:check_compare "%~f1" "%temporary_folder%%~n1-i1.png"
	exit
)

:step_b
:: Check huffman-only compression
for /f "tokens=1 delims=/c " %%i in ('pngout -l "%~f1"') do set "colortype=%%i"
if %colortype% neq 2 goto:step_01
set "number_of_refresh=c" &call:refresh
pngout -f5 -c2 -s2 -k0 -q -y -force "%~f1" "%temporary_folder%%~n1-s2.png"
set "number_of_refresh=d" &call:refresh
pngout -f5 -c2 -s3 -k0 -q -y -force "%~f1" "%temporary_folder%%~n1-s3.png"
call:check_size "%temporary_folder%%~n1-s2.png" "%temporary_folder%%~n1-s3.png"
if %size_b% lss %size_a% (
	set "number_of_refresh=e" &call:refresh
	for /l %%h in (1,1,15) do pngout -s3 -n%%h -q "%~f1"
	set "number_of_refresh=f" &call:refresh
	for %%i in (0,1) do pngout -s%%i -ks -q -y -force "%~f1" "%temporary_folder%%~n1-s%%i.png"
	for %%i in (0,1) do (
	deflopt -k -b -s "%temporary_folder%%~n1-s%%i.png" >nul
	1>nul 2>nul defluff < "%temporary_folder%%~n1-s%%i.png" > "%temporary_folder%%~n1-s%%i.tmp"
	call:check_compare "%temporary_folder%%~n1-s%%i.png" "%temporary_folder%%~n1-s%%i.tmp"
	deflopt -k -b -s "%temporary_folder%%~n1-s%%i.png" >nul
	)
	for %%i in (0,1) do huffmix -q "%~f1" "%temporary_folder%%~n1-s%%i.png" "%temporary_folder%%~n1-sf%%i.png"
	for %%i in (0,1) do call:check_compare "%~f1" "%temporary_folder%%~n1-sf%%i.png"
	exit
	)

:step_01
	set "number_of_refresh=1" &call:refresh
	:: Reductions with RGB data to 0,0,0 and tRNS intact
	truepng -f0,5 -i0 -g0 -a0 -md remove all -zc8-9 -zm3-9 -zs0-3 -quiet -force -y "%~f1" -out "%temporary_folder%%~n1-a0.png"
set "number_of_refresh=2" &call:refresh
:: Reductions with RGB data and tRNS modified
truepng -f0,5 -i0 -g0 -a1 -md remove all -zc8-9 -zm3-9 -zs0-3 -quiet -force -y "%~f1" -out "%temporary_folder%%~n1-a1.png"
	set "number_of_refresh=3" &call:refresh
	:: Compression trials to determine the smallest output
	advdef -z -3 -q "%temporary_folder%%~n1-a0.png"
	advdef -z -3 -q "%temporary_folder%%~n1-a1.png"
	call:check_compare "%temporary_folder%%~n1-a0.png" "%temporary_folder%%~n1-a1.png"

:step_02
	:: Fast search of filtering
	set "number_of_refresh=4" &call:refresh
	pngwolfz --in="%temporary_folder%%~n1-a0.png" --out="%temporary_folder%%~n1-f1.png" --exclude-singles --exclude-heuristic --zlib-level=8 --zlib-memlevel=8 --zlib-strategy=0 --max-time=1 --even-if-bigger >nul
	for /f "tokens=2 delims=/f " %%i in ('pngout -l "%temporary_folder%%~n1-f1.png"') do set "filtering=%%i"
	:: If filtering is none, stop searching
	if %filtering% equ 0 goto:step_03
set "number_of_refresh=5" &call:refresh
:: Search more
pngwolfz --in="%temporary_folder%%~n1-a0.png" --out="%temporary_folder%%~n1-f2.png" --zlib-level=9 --zlib-memlevel=9 --zlib-strategy=0 --max-stagnate-time=%filtering_search% --even-if-bigger >nul
	:: Comparing results
	call:check_compare "%temporary_folder%%~n1-f1.png" "%temporary_folder%%~n1-f2.png"
	call:check_compare "%temporary_folder%%~n1-a0.png" "%temporary_folder%%~n1-f1.png"

:step_03
for /f "tokens=1 delims=/c " %%b in ('pngout -l "%temporary_folder%%~n1-a0.png"') do set "colortype-c3=%%b"
	:: Colortype 3
	if %colortype-c3% neq 3 set "check_from_step_03=1" &goto:step_04
	if %compression_trials% equ 4 set "compression_trials=32"
	set "number_of_refresh=ba" &call:refresh
	pngout -c6 -s4 -q -y -force "%temporary_folder%%~n1-a0.png" "%temporary_folder%%~n1-pal.png"
	set "number_of_refresh=bb" &call:refresh
	pngout -c3 -d8 -k0 -q -y "%temporary_folder%%~n1-pal.png"
	set "number_of_refresh=bc" &call:refresh
	pngout -c3 -d0 -k0 -q -y "%temporary_folder%%~n1-pal.png"
:: Compare
pngout -f6 -k0 -kp -ks -q -y -force "%temporary_folder%%~n1-a0.png"
call:check_compare "%temporary_folder%%~n1-a0.png" "%temporary_folder%%~n1-pal.png"
for %%i in (1,2,3,4,5,6) do pngout -f6 -n%%i -ks -q -y "%temporary_folder%%~n1-a0.png" &set "number_of_refresh=b%%i" &call:refresh
call:check_compare "%~f1" "%temporary_folder%%~n1-a0.png"
:: More compression for paletted
if %zopfli_compression% equ 90 set "zopfli_compression=270"
set "check_from_step_03=0"
	
:step_04
if %check_from_step_03% equ 1 (
call:check_compare "%~f1" "%temporary_folder%%~n1-a0.png"
)
	set "number_of_refresh=6" &call:refresh
	call:refresh
	:: Run 4 trials
	for /L %%i in (1,1,4) do start /b /low /wait pngout -f6 -r -k0 -kp -ks -q -y -force "%~f1" "%temporary_folder%%~n1-%%i.png"
	:: Mix trials
	huffmix -q "%temporary_folder%%~n1-1.png" "%temporary_folder%%~n1-2.png" "%temporary_folder%%~n1-12.png"
	huffmix -q "%temporary_folder%%~n1-3.png" "%temporary_folder%%~n1-4.png" "%temporary_folder%%~n1-34.png"
	huffmix -q "%temporary_folder%%~n1-12.png" "%temporary_folder%%~n1-34.png" "%temporary_folder%%~n1-f.png"
		:: Optimize deflate stream
		call:deflate_optimizer "%temporary_folder%%~n1-f.png" >nul
	:: Save, check_compare
	1>nul 2>&1 copy /b /y "%temporary_folder%%~n1-f.png" "%temporary_folder%%~n1-x%number_of_pass_a%.png"
	REM call:check_compare "%~f1" "%temporary_folder%%~n1-f.png"
	:: Counters
	set /a "number_of_trials+=4"
	set /a "number_of_pass_a+=1"
		:: Pass mixing A
		if %number_of_pass_a% equ 4 (
		huffmix -q "%temporary_folder%%~n1-x0.png" "%temporary_folder%%~n1-x1.png" "%temporary_folder%%~n1-x01.png"
		huffmix -q "%temporary_folder%%~n1-x2.png" "%temporary_folder%%~n1-x3.png" "%temporary_folder%%~n1-x23.png"
		huffmix -q "%temporary_folder%%~n1-x01.png" "%temporary_folder%%~n1-x23.png" "%temporary_folder%%~n1-xf.png"
			call:deflate_optimizer "%temporary_folder%%~n1-xf.png" >nul
			1>nul 2>&1 copy /b /y "%temporary_folder%%~n1-xf.png" "%temporary_folder%%~n1-w%number_of_pass_b%.png"
		REM call:check_compare "%~f1" "%temporary_folder%%~n1-xf.png"
		1>nul 2>&1 del /f /q "%temporary_folder%%~n1-x*.png"
		set "number_of_pass_a=0"
		set /a "number_of_pass_b+=1"
		)
			:: Pass mixing B
			if %number_of_pass_b% equ 2 (
			huffmix -q "%temporary_folder%%~n1-w0.png" "%temporary_folder%%~n1-w1.png" "%temporary_folder%%~n1-w01.png"
			call:deflate_optimizer "%temporary_folder%%~n1-w01.png" >nul		
			call:check_size "%~f1" "%temporary_folder%%~n1-w01.png"
				1>nul 2>&1 copy /b /y "%temporary_folder%%~n1-w01.png" "%temporary_folder%%~n1-mix.png"
			call:check_compare "%~f1" "%temporary_folder%%~n1-w01.png"
			1>nul 2>&1 del /f /q "%temporary_folder%%~n1-w*.png"
			set "number_of_pass_b=0"
			)
				:: Mix with original file
				if %mix_with_origine% equ 1 (
				1>nul 2>&1 huffmix -q "%~f1" "%temporary_folder%%~n1-mix.png" "%temporary_folder%%~n1-z.png"
				if exist "%temporary_folder%%~n1-z.png" call:deflate_optimizer "%temporary_folder%%~n1-z.png" >nul
				if exist "%temporary_folder%%~n1-z.png" call:check_compare "%~f1" "%temporary_folder%%~n1-z.png"
				1>nul 2>&1 del /f /q "%temporary_folder%%~n1-*.png"
				set "mix_with_origine=0"
				)
	set "trial_size=%~z1"
	:: Exit if smaller
	if %number_of_trials% geq %compression_trials% goto:step_05
	goto:step_04

:step_05
set "number_of_refresh=7" &call:refresh
:: Zopfli Deflation
pngzopfli "%~f1" %zopfli_compression%
call:check_compare "%~f1" "%temporary_folder%%~n1.zopfli.png"
call:deflate_optimizer "%~f1"
exit

:deflate_optimizer
deflopt -k -b -s "%~f1" >nul
1>nul 2>nul defluff < "%~f1" > "%~f1.tmp"
call:check_move "%~f1" "%~f1.tmp"
deflopt -k -b -s "%~f1" >nul
exit /b

:: Comparators
:check_size
set "size_a=%~z1"
set "size_b=%~z2"
if %size_a% leq %size_b% set "mix_with_origine=1"
exit /b
:check_move
1>nul 2>&1 move /y %2 %1
exit /b
:check_compare
if %~z1 leq %~z2 (1>nul 2>&1 del /f /q %2) else (1>nul 2>&1 move /y %2 %1 || exit /b 1)
exit /b
:refresh
cls
title %file_name%.png
echo.
echo.
echo  %name% - %version%
echo.
echo.
echo  "%file_name%.png"
echo  In  : %file_size% Bytes
if %number_of_refresh% equ a echo  Out : %file_size% Bytes - Interlaced testing.
if %number_of_refresh% equ b echo  Out : %file_size% Bytes - Interlaced testing..
if %number_of_refresh% equ c echo  Out : %file_size% Bytes - Huffman only test.
if %number_of_refresh% equ d echo  Out : %file_size% Bytes - Huffman only test..
if %number_of_refresh% equ e echo  Out : %file_size% Bytes - Huffman only test...
if %number_of_refresh% equ f echo  Out : %file_size% Bytes - Huffman only test....
if %number_of_refresh% equ 1 echo  Out : %file_size% Bytes - Reducing file.
if %number_of_refresh% equ 2 echo  Out : %file_size% Bytes - Reducing file..
if %number_of_refresh% equ 3 echo  Out : %file_size% Bytes - Reducing file...
if %number_of_refresh% equ 4 echo  Out : %file_size% Bytes - Filtering file...
if %number_of_refresh% equ 5 echo  Out : %file_size% Bytes - Filtering with %filtering_search% seconds/trials
if %number_of_refresh% equ 6 echo  Out : %file_size% Bytes - Block trials... %number_of_trials%/%compression_trials%
if %number_of_refresh% equ 7 echo  Out : %file_size% Bytes - Compression with %zopfli_compression% iterations...
if %number_of_refresh% equ ba echo  Out : %file_size% Bytes - Palette generation.
if %number_of_refresh% equ bb echo  Out : %file_size% Bytes - Palette generation..
if %number_of_refresh% equ bc echo  Out : %file_size% Bytes - Palette generation...
if %number_of_refresh% equ b1 echo  Out : %file_size% Bytes - Palette sorting 1/6
if %number_of_refresh% equ b2 echo  Out : %file_size% Bytes - Palette sorting 2/6
if %number_of_refresh% equ b3 echo  Out : %file_size% Bytes - Palette sorting 3/6
if %number_of_refresh% equ b4 echo  Out : %file_size% Bytes - Palette sorting 4/6
if %number_of_refresh% equ b5 echo  Out : %file_size% Bytes - Palette sorting 5/6
if %number_of_refresh% equ b6 echo  Out : %file_size% Bytes - Palette sorting 6/6
echo.
exit /b