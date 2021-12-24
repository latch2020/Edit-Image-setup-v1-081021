@Echo off

color 1F 

echo ---------------------------------------------
echo.
echo Post image setup script, run as Administrator
echo.
echo		 Version v1 08.10.21
echo.
echo       For Media Composer 2021.9
echo. 
echo ---------------------------------------------
echo.
echo This does the following:
echo.
echo - Set hostname of machine
echo - Set DNS Suffix
echo - Turn off fast startup
echo - Turn off hibernate
echo - Turn off Windows Firewalls
echo - Runs nVidia installer (461.72)
echo - Runs Intel NIC drivers 
echo - Sets IP and DNS on Intel Pro 1000 adapter
echo - Disables IPv6
echo - Runs IO Driver installer (BMD 12.0 or None)
echo.
timeout 3 >nul
pause
cls

@echo off

SETLOCAL EnableDelayedExpansion

echo.
SET /P newhostname= Please enter an hostname:
echo powershell.exe -command "rename-Computer -Newname %newhostname%" > hostname.txt

cmd < hostname.txt
cls

echo.
echo Set DNS Suffix:
echo.
echo 1. nexis.vc
echo 2. None
echo 3. Other
echo.
SET /P dnssuffix=Select DNS suffix option 1,2 or 3:

if %dnssuffix%==1 goto option1
if %dnssuffix%==2 goto option2
if %dnssuffix%==3 goto option3


:option1
echo Nexis.vc DNS Suffix
echo Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\" -Name "NV Domain" -Value "nexis.vc" > vcdns.txt
powershell.exe < vcdns.txt
cls
goto next

:option2
echo No DNS Suffix
timeout 1 >nul
cls
goto next

:option3
echo Custom DNS Suffix
echo.
timeout 1 >nul
SET /P setdns=Type DNS suffix:
echo Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\" -Name "NV Domain" -Value "%setdns%" > setdns.txt
powershell.exe < setdns.txt
cls
goto next


:next
if exist hostname.txt del hostname.txt
if exist vcdns.txt del vcdns.txt 
if exist setdns.txt del setdns.txt

echo.
echo Hostname and DNS Suffix set
echo.
pause


::reg add turn off fast startup 

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f

:: Turn off hibernate

powercfg.exe -h off

:: Turn off firewall, all profiles

echo.
echo Would you like to turn off all firewalls
echo.
echo 1. Yes
echo 2. No
echo.
Set /P firewalloffon=Select 1 or 2:

if %firewalloffon%==1 goto fwoption1
if %firewalloffon%==2 goto fwoption2

:fwoption1

NetSh Advfirewall set allprofiles state off

:fwoption2
echo.
echo Firewalls not modified 

cls

:: nVidia Driver install - extrat installer

echo.
echo Extracting nVidia Driver
timeout 3 >nul

start /d "C:\Users\editor\Downloads\Post Install" 461.72-quadro-rtx-desktop-notebook-win10-64bit-international-dch-whql.exe

echo.
echo nVidia Driver 


:: Turn on Video Editing mode

REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global"  /v VideoEditingMode /t REG_DWORD /d 1 /f

echo Pleae check the nVidia Control Panel settings:
echo.
echo - nVidia Control Panel - Desktop - Enable Video editing
echo - Manage 3D setting - Power manamgnet mode - Prefer maximum performace
echo.
timeout 4 >nul
pause
cls 

echo.
echo Install intel nic drivers
timeout 3 >nul

:: Intel Drivers: 

start /d "C:\Users\editor\Downloads\Post Install" Wired_PROSet_26.4_x64.exe
cls

:: Delete reminder

del "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Reminder.bat"
cls

:: Set IP Address

echo.
echo Would you like to set Default Videocraft address on first intel Pro 1000
echo.
echo 1. Yes
echo 2. No
echo.
Set /P vcipsetup=Select 1 or 2:

if %vcipsetup%==1 goto ipoption1
if %vcipsetup%==2 goto ipoption2

:ipoption1

echo.
echo Setting  default Vidoecraft IP this might make a few seconds
echo.
timeout 2 >nul
echo  Rename-NetAdapter -InterfaceDescription "Intel(R) PRO/1000 PT Dual Port Server Adapter" -NewName "NEXIS" > nicname.txt
powershell.exe < nicname.txt
cls

powershell.exe -command Disable-NetAdapterBinding -Name NEXIS -ComponentID ms_tcpip6

set /P ipset=Set IP Address 10.240.10.

echo netsh interface ipv4 set address name="NEXIS" static 10.240.10.%ipset% 255.255.255.0 10.240.10.254 >vcip.txt

cmd < vcip.txt

netsh interface ipv4 set dns name="NEXIS" static 10.240.10.10
cls

goto ipend


:ipoption2
Echo.
echo No default Vidoecraft IP set
timeout 2 >nul
cls

goto ipend


:ipend
if exist nicname.txt del nicname.txt
if exist vcip.txt del vcip.txt

:: Install Crowdstrike sensor with CID

echo.
echo Would you like to install Crowdstrike sensor
echo.
echo 1. Yes
echo 2. No
echo.
Set /P csinstall=Select 1 or 2:

if %csinstall%==1 goto csoption1
if %csinstall%==2 goto csoption2

:csoption1

Echo.
echo Installing Crowdstrike sensor... please be patient
timeout 5 >nul
echo.
cls

 "C:\Users\editor\Downloads\Post Install\extras\WindowsSensor.MaverickGyr.exe" /install /quiet /norestart CID=63900221692E471380EFA4B9DB754D8F-01


:csoption2
Echo.
echo Crowdstrike sensor not installed
timeout 2 >nul
cls

echo.
echo Install I/O driver:
echo. 
echo 1. BMD 12.0 Driver
echo 2. None

set /p iodriver=select 1, 2 or 3:

if %iodriver%==1 goto option1
if %iodriver%==2 goto option2




:option1
echo.
echo BMD Desktop video 12.0
echo do not reboot when prompted
timeout 2 >nul

cd "C:\Users\editor\Downloads\Post Install\Blackmagic_Desktop_Video_Windows_12.0"
msiexec /i "Desktop Video Installer v12.0.msi"
cls
goto reboot

:option2

echo.
echo none
timeout 1 >nul
cls
goto reboot


:: reboot prompt

:reboot

echo Would you like to reboot now?
echo.
echo 1: Yes
echo 2: No


set /p reboot=select 1 or 2:

if %reboot%==1 goto reboot1
if %reboot%==2 goto reboot2

:reboot1

echo.
echo Rebooting now
timeout 2 >nul

shutdown /r /t 0

exit

:reboot2

goto end


pause

:end
echo.
echo ---------------------------------------------------------------
echo.
echo Thankyou come again...
echo.
echo ---------------------------------------------------------------



