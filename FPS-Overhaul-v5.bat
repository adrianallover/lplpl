@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "ERRORLEVEL="
rem A parent CMD survives an unexpected worker exit and holds the results open.
rem No elevation or privilege changes are performed by this launcher.
if defined FPS_OVERHAUL_WORKER goto :FPS_WORKER
set "FPS_SELF=%~f0"
set "FPS_OVERHAUL_WORKER=1"
set "FPS_LAUNCH_CMD=%SystemRoot%\System32\cmd.exe"
if exist "%SystemRoot%\Sysnative\cmd.exe" set "FPS_LAUNCH_CMD=%SystemRoot%\Sysnative\cmd.exe"
rem Expand the filename once in the child; its percent signs and bangs stay literal.
rem The worker immediately disables delayed expansion on entry.
"%FPS_LAUNCH_CMD%" /d /e:on /v:on /s /c ""!FPS_SELF!""
set "FPS_WORKER_RC=%errorlevel%"
echo(
if not "%FPS_WORKER_RC%"=="0" echo    [FAILED] Worker returned exit code %FPS_WORKER_RC%. Review the results above.
echo    [DONE] Press any key to close this script.
pause >nul
endlocal & exit /b %FPS_WORKER_RC%

:FPS_WORKER
set "ERRORLEVEL="
set "FPS_SELF=%~f0"
set "FPS_BIN=%SystemRoot%\System32"
set "FPS_PS=%FPS_BIN%\WindowsPowerShell\v1.0\powershell.exe"
title FPS Overhaul v5 - Frametime / 1%% Low / Latency Tuner
rem mode.com reads and discards all of stdin. Given its own empty input, it cannot
rem swallow the answers meant for the start pause and the reboot prompt.
"%FPS_BIN%\mode.com" con: cols=110 lines=52 <nul >nul 2>&1
rem This file is ASCII with CRLF line endings and has no BOM.
rem Dynamic device names and game names never become CMD command text.
rem Delayed expansion is enabled only inside the isolated display helpers.
rem PowerShell bodies are single lines passed through environment variables.
rem A command succeeding means it was accepted; it does not prove an FPS gain.

rem ===========================================================================
rem  FPS OVERHAUL v5  -  local gaming performance configuration for Windows 10/11
rem  ---------------------------------------------------------------------
rem  Scope, by design:
rem    * kernel scheduling, timer behaviour, MMCSS, memory manager, NTFS,
rem      GPU interrupt/scheduling policy, windowed-game presentation, DWM and
rem      shell cost, input stack latency, background services, scheduled tasks,
rem      telemetry agents, UWP background execution, per-title process priority.
rem  Deliberately NOT included:
rem    * network / TCP-IP stack tuning        * powercfg or power plan changes
rem    * temp-file or disk "cleaning"         * restore points, exports, logs
rem    * any security weakening: Defender, firewall, UAC, SmartScreen,
rem      VBS, CPU speculative-execution mitigations and LSA protection
rem      are READ AND REPORTED ONLY, never modified. The single exception is
rem      Memory Integrity ^(HVCI^): an opt-in switch, OFF by default, that
rem      mirrors Microsoft's own published gaming guidance. See CFG_HVCI_OFF.
rem    * debunked placebo tweaks ^(useplatformclock, IoPageLockLimit,
rem      LargeSystemCache=1, "one svchost", MaxConnectionsPerServer,
rem      DpcWatchdogProfileOffset, tiny mouse/keyboard queues, etc.^) -
rem      several are DETECTED AND REVERSED.
rem
rem  v2 against v1:
rem    * desktop, mouse and keyboard settings are applied to the running session
rem      as well as the registry, and written to the signed-in user's hive, so a
rem      later sign-out can no longer put the old values back
rem    * Windows 11 optimizations for windowed games: flip-model presentation for
rem      DX10/11 windowed and borderless titles
rem    * Recall snapshot capture off on Copilot+ PCs
rem    * scheduled tasks absent from this build, a stopped print spooler, a
rem      disabled SysMain and the protected Widgets button are skips, not failures
rem    * DpcWatchdogProfileOffset dropped and removed if v1 set it; the hidden
rem      power-setting UI unhiding dropped, it changed nothing
rem    * administrator check up front, and a dry run: FPS_DRYRUN=1 reports every
rem      change without making it
rem
rem  v3 against v2:
rem    * every display switched to the highest refresh rate Windows lists for its
rem      current resolution, test-validated by the driver before it is applied
rem    * hybrid-graphics laptops: installed Steam, Epic, Xbox and Riot games are
rem      assigned to the discrete GPU; single-GPU systems are detected and skipped
rem    * Fault Tolerant Heap off: Windows no longer bolts slower heap mitigations
rem      onto a game that crashed a few times; already-shimmed programs are listed
rem    * FPS bottleneck report: battery power, power mode, memory channels and
rem      speed, graphics driver age, animated wallpaper apps - read only
rem    * the Device Information census tasks disabled
rem    * Win32PrioritySeparation comment corrected: 38 is short, variable, 3:1,
rem      the same as the client default, and is kept as a guard only
rem    * fixed: mode.com drained stdin at start-up, so a Yes to the reboot prompt
rem      supplied through redirected input was lost and it always defaulted to No
rem
rem  v4 against v3:
rem    * CPU topology detection straight from the Windows scheduler tables:
rem      performance / efficiency cores, SMT, L3 domains ^(CCDs^) and their
rem      sizes, 3D V-Cache layout. It drives the new platform checks below.
rem    * platform check, read only: monitor cable in the motherboard instead of
rem      the graphics card, Resizable BAR and PCIe link width on NVIDIA, hybrid
rem      Intel CPUs on Windows 10, dual-CCD X3D prerequisites ^(AMD driver,
rem      Game Bar, Balanced plan^), the Ryzen branch-prediction update, a full
rem      system drive, Driver Verifier and heap-debugging flags left on, RGB /
rem      sensor suites known for periodic stutter, enabled startup programs
rem    * DirectX shader cache protected from automatic cleanup, so games stop
rem      recompiling shaders after Windows tidies the disk
rem    * more harmful leftovers reversed: BCD onecpu, groupsize, maxgroup,
rem      groupaware, legacy APIC / x2APIC / MSI / PCI config overrides - all
rem      outside BitLocker's BCD validation; svchost split threshold; mouse
rem      and keyboard input queues shrunk below the stock 100 entries; a
rem      policy that stopped the search indexer backing off while you play
rem    * USB host controllers and hubs, not just mice and keyboards, are kept
rem      out of device power-down, through the same switch Device Manager uses
rem    * Sticky / Filter / Toggle Keys hotkeys off: Shift pressed five times
rem      no longer throws a dialog over a fullscreen game
rem    * ETW telemetry autologgers, Intel Computing Improvement Program, Office
rem      telemetry, Copilot, Click to Do, activity history, advertising ID,
rem      typing-data harvesting and more background tasks removed
rem    * third-party auto-updater services moved to manual start
rem    * opt-in: Windows Update no longer swaps your GPU driver for an older one
rem    * opt-in: Memory Integrity off, per Microsoft's gaming guidance
rem    * fixed: a missing line break in phase 11 glued an echo onto a registry
rem      write, which corrupted that value and dropped the note
rem    * BCD values are matched by exact name, so a short name such as msi can
rem      never match part of a longer one
rem
rem  v5 against v4 - everything v4 sets is kept exactly as it was; v5 only adds:
rem    * Fault Tolerant Heap shims already attached to crash-prone games are cleared
rem    * Steam background game recording to on-demand, Lively Wallpaper paused behind
rem      fullscreen games, HWiNFO sensor polling faster than 1 s slowed to 2 s -
rem      each only while that app is closed, detected per user
rem    * Nahimic audio overlay injection off where it is installed
rem    * Windows Dynamic Lighting background RGB control off
rem    * Windows AI Fabric model hosts no longer start at boot
rem    * suggestion, account and backup nag toasts, Smart Clipboard actions and
rem      cross-device resume / Phone Link background hosts off
rem    * more telemetry tasks off, and the input settings-sync tasks, so a sync
rem      from another PC cannot overwrite the mouse and keyboard values here
rem    * dual-CCD 3D V-Cache Ryzen: listed games pinned to the cache CCD through
rem      AMD's own driver preference list
rem    * opt-in: Virtual Machine Platform off ^(Microsoft gaming guidance^),
rem      Microsoft Store automatic app updates off, automatic maintenance moved
rem      to a night hour instead of disabled
rem    * MPO opt-in also covers 24H2, where OverlayTestMode alone stopped working
rem    * fixed: the TRIM check read the ReFS line on some builds
rem
rem  Every write records the stock default in a comment next to it so you can
rem  reverse anything by hand. Reboot when finished.
rem ===========================================================================

rem ####################  USER CONFIG  ########################################
rem  1 = apply, 0 = skip, auto = decide from hardware detection
rem quantum / priority separation / timer res
set "CFG_SCHEDULER=1"
rem multimedia class scheduler game profile
set "CFG_MMCSS=1"
rem memory manager + prefetcher behaviour
set "CFG_MEMORY=1"
rem auto = disable when RAM is at least 32 GB; original numeric gate preserved
set "CFG_MEMCOMPRESSION=auto"
rem NTFS metadata write reduction + TRIM check
set "CFG_FILESYSTEM=1"
rem HAGS + vendor telemetry agents
set "CFG_GPU=1"
rem keep Windows' automatic cleanup away from the DirectX shader cache
set "CFG_SHADER_CACHE_KEEP=1"
rem message-signalled interrupts + DevicePriority
set "CFG_GPU_MSI=1"
rem switch every display to the highest refresh rate listed at its resolution
set "CFG_MAX_REFRESH=1"
rem hybrid graphics laptops: installed games assigned to the discrete GPU
set "CFG_HYBRID_GPU=1"
rem Game Mode on / Game DVR + overlay off
set "CFG_GAMEBAR=1"
rem force-disable Fullscreen Optimizations ^(see notes^)
set "CFG_DISABLE_FSO=0"
rem disable multi-plane overlay ^(stutter fix only^)
set "CFG_DISABLE_MPO=0"
rem Windows 11 optimizations for windowed games ^(flip model, VRR^)
set "CFG_WINDOWED_OPT=1"
rem DWM animations, transparency, shell latency
set "CFG_SHELL=1"
rem USB selective suspend + HID power management
set "CFG_INPUT=1"
rem disable pointer acceleration
set "CFG_MOUSE_ACCEL_OFF=1"
rem USB host controllers and hubs kept out of device power-down ^(with CFG_INPUT^)
set "CFG_USB_POWER=1"
rem Sticky / Filter / Toggle Keys hotkey pop-ups off ^(the features stay usable^)
set "CFG_ACCESS_HOTKEYS_OFF=1"
rem Fault Tolerant Heap off ^(no slow-heap shims on crash-prone games^)
set "CFG_FTH_OFF=1"
rem UWP background apps, content delivery, widgets
set "CFG_BACKGROUND=1"
rem Recall snapshot capture off ^(Copilot+ PCs, 24H2 and later^)
set "CFG_RECALL_OFF=1"
rem telemetry agents and appraiser workloads
set "CFG_TELEMETRY=1"
rem background service trimming
set "CFG_SERVICES=1"
rem 1 = disable Windows Search indexing entirely
set "CFG_DISABLE_SEARCH=0"
rem only acts if no physical printer is installed
set "CFG_DISABLE_SPOOLER=1"
rem browser and vendor auto-updater services to manual start ^(updates still run^)
set "CFG_UPDATERS_MANUAL=1"
rem 1 = Windows Update stops delivering drivers, so it cannot replace your GPU driver
set "CFG_BLOCK_WU_DRIVERS=0"
rem 1 = Memory Integrity ^(HVCI^) off. Security trade-off, see phase 15. Default 0.
set "CFG_HVCI_OFF=0"
rem Steam, Lively Wallpaper, HWiNFO settings that cost frames ^(only while closed^)
set "CFG_THIRDPARTY=1"
rem Nahimic audio overlay services and tasks off where installed
set "CFG_NAHIMIC_OFF=1"
rem Windows Dynamic Lighting background RGB control off ^(Windows 11 23H2+^)
set "CFG_DYNAMIC_LIGHTING_OFF=1"
rem Phone Link / cross-device resume background features off
set "CFG_CROSSDEVICE_OFF=1"
rem 1 = Virtual Machine Platform off ^(breaks WSL 2 and Android apps^). Default 0.
set "CFG_VMP_OFF=0"
rem 1 = Microsoft Store stops updating apps in the background. Default 0.
set "CFG_STORE_AUTOUPDATE_OFF=0"
rem scheduled task / automatic maintenance
set "CFG_TASKS=1"
rem 1 = automatic maintenance disabled ^(v4^); 0 = moved to CFG_MAINTENANCE_HOUR
set "CFG_MAINTENANCE_OFF=1"
set "CFG_MAINTENANCE_HOUR=3"
rem 38 = 0x26. Windows client default = 2
set "CFG_PRIORITY_SEPARATION=38"
rem Windows client default = 20
set "CFG_SYSTEM_RESPONSIVENESS=10"
rem  Semicolon separated game executables to High CPU + High I/O priority, and to
rem  the 3D V-Cache CCD on dual-CCD X3D Ryzen.
rem  Example: set "CFG_GAME_EXES=cs2.exe;r5apex.exe;Cyberpunk2077.exe"
rem Use semicolons between filenames. Spaces and punctuation stay within a name.
rem In a literal batch assignment, write %% to store one percent sign.
set "CFG_GAME_EXES="
rem  Dry run: start the script with FPS_DRYRUN=1 in the environment to see every
rem  change it would make without making any. Normal runs leave this at 0.
if not defined FPS_DRYRUN set "FPS_DRYRUN=0"
rem ###########################################################################

set "CNT_OK=0"
set "CNT_FAIL=0"
set "CNT_SKIP=0"
set "REBOOT_REQ=0"
set "FPS_PS_COMMON=function Report([string]$state,[string]$label,[string]$detail=''){ $text=$label; if($detail){$text+=' - '+$detail}; [Console]::WriteLine($state+'|'+($text -replace '[^\x20-\x7E]','?')) }; function Apply([string]$label,[scriptblock]$action){ if($env:FPS_DRYRUN -eq '1'){ Report 'WOULD' $label; return }; Report 'APPLY' $label; try{ & $action | Out-Null; Report 'OK' $label }catch{ Report 'FAILED' $label $_.Exception.Message } }; function Write-FpsData([string]$name,$value){ [Console]::WriteLine('DATA|'+$name+'='+$value) }; if($env:FPS_PS_USELIB -eq '1'){ $fpsNl=[string][char]13+[string][char]10; $fpsMark=$fpsNl+':FPS_PS_LIBRARY'+$fpsNl; $fpsText=[IO.File]::ReadAllText($env:FPS_SELF); $fpsAt=$fpsText.IndexOf($fpsMark,[StringComparison]::Ordinal); if($fpsAt -lt 0){ throw 'Embedded PowerShell library not found' }; . ([scriptblock]::Create($fpsText.Substring($fpsAt+$fpsMark.Length))) }"

rem Administrator rights are checked before anything runs. A dry run only reads.
set "FPS_ISADMIN=0"
"%FPS_BIN%\fltmc.exe" <nul >nul 2>&1
if not errorlevel 1 set "FPS_ISADMIN=1"
if "%FPS_ISADMIN%"=="1" goto :FPS_START
if "%FPS_DRYRUN%"=="1" goto :FPS_START
echo(
echo    [FAILED] Administrator rights are required. Right-click the script and choose
echo             Run as administrator. Nothing was changed.
exit /b 1

:FPS_START
cls
echo(
echo  ===========================================================================
echo    FPS OVERHAUL v5   frametime consistency / 1%% + 0.1%% lows / avg framerate
echo  ===========================================================================
if "%FPS_DRYRUN%"=="1" echo    DRY RUN: every change is reported and nothing is modified.
echo(

rem ================================================================ DETECTION
echo  [ PHASE 0 ]  Hardware and OS detection
echo  ---------------------------------------------------------------------------

rem Reset all detection fields so inherited environment values cannot gate tweaks.
set "OSBUILD=0"
set "IS_W11=0"
set "IS_24H2=0"
set "HAS_PERPROC_TIMER=0"
set "D_RAMGB=0"
set "D_CORES=0"
set "D_THREADS=0"
set "D_SYSDISK=UNKNOWN"
set "D_CHASSIS=DESKTOP"
set "D_PRINTERS=-1"
set "D_HVCI=UNKNOWN"
set "D_VBS=UNKNOWN"
set "GPU_NV=0"
set "GPU_AMD=0"
set "GPU_INTEL=0"
set "CPU_AMD=0"
set "CPU_INTEL=0"
set "D_UBR=0"
set "D_HYBRID=0"
set "D_PCORES=0"
set "D_ECORES=0"
set "D_L3N=0"
set "D_X3D=0"
set "D_SMT=0"
set "D_HYPERVISOR=0"
set "FPS_USID="
set "FPS_PS_TITLE=Windows version detection"
set "FPS_PS_BODY=$b=0; $ubr=0; $name='unknown'; $rel='n/a'; try{ $o=Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'; [void][int]::TryParse([string]$o.CurrentBuildNumber,[ref]$b); if($b -lt 0){$b=0}; [void][int]::TryParse([string]$o.UBR,[ref]$ubr); if($ubr -lt 0){$ubr=0}; if($o.ProductName){$name=[string]$o.ProductName}; if($o.DisplayVersion){$rel=[string]$o.DisplayVersion} }catch{ Report 'FAILED' 'Reading Windows version' $_.Exception.Message }; Write-FpsData 'OSBUILD' $b; Write-FpsData 'D_UBR' $ubr; Write-FpsData 'IS_W11' ([int]($b -ge 22000)); Write-FpsData 'IS_24H2' ([int]($b -ge 26100)); Write-FpsData 'HAS_PERPROC_TIMER' ([int]($b -ge 19041)); Report 'INFO' ('OS: '+$name+'; build '+$b+'.'+$ubr+' ('+$rel+')')"
call :PS_RUN
set "FPS_PS_TITLE=CPU, memory and GPU detection"
set "FPS_PS_BODY=$ram=0; $cores=0; [void][int]::TryParse($env:NUMBER_OF_PROCESSORS,[ref]$cores); if($cores -lt 0){$cores=0}; $threads=$cores; $cpu='unknown'; $gpu='unknown'; $chassis='DESKTOP'; try{ $cs=@(Get-CimInstance Win32_ComputerSystem)[0]; if($null -eq $cs){throw 'No computer-system data returned'}; $ram=[math]::Round($cs.TotalPhysicalMemory / 1GB) }catch{ Report 'FAILED' 'Reading installed memory' $_.Exception.Message }; try{ $c=@(Get-CimInstance Win32_Processor)[0]; if($null -eq $c){throw 'No processor data returned'}; $cpu=([string]$c.Name).Trim(); $cores=[int]$c.NumberOfCores; $threads=[int]$c.NumberOfLogicalProcessors }catch{ Report 'FAILED' 'Reading processor data' $_.Exception.Message }; try{ $g=@(Get-CimInstance Win32_VideoController); if($g.Count){$gpu=$g.Name -join ' + '} }catch{ Report 'FAILED' 'Reading display adapters' $_.Exception.Message }; try{ if(@(Get-CimInstance Win32_Battery).Count -gt 0){$chassis='LAPTOP'} }catch{ Report 'FAILED' 'Reading battery / form factor' $_.Exception.Message }; Write-FpsData 'D_RAMGB' $ram; Write-FpsData 'D_CORES' $cores; Write-FpsData 'D_THREADS' $threads; Write-FpsData 'D_CHASSIS' $chassis; Write-FpsData 'GPU_NV' ([int]($gpu -match 'nvidia|geforce|rtx|gtx')); Write-FpsData 'GPU_AMD' ([int]($gpu -match 'amd|radeon')); Write-FpsData 'GPU_INTEL' ([int]($gpu -match 'intel|arc|iris|uhd')); Write-FpsData 'CPU_AMD' ([int]($cpu -match 'amd|ryzen|threadripper|epyc')); Write-FpsData 'CPU_INTEL' ([int]($cpu -match 'intel|core|xeon')); Report 'INFO' ('CPU: '+$cpu); Report 'INFO' ('Topology: '+$cores+' cores / '+$threads+' threads'); Report 'INFO' ('Memory: '+$ram+' GB'); Report 'INFO' ('GPU: '+$gpu); Report 'INFO' ('Form factor: '+$chassis)"
call :PS_RUN
rem CPU topology comes from the same tables the Windows scheduler uses:
rem GetLogicalProcessorInformationEx. Per core it gives the efficiency class
rem ^(hybrid CPUs report two or more^) and SMT; per cache it gives the L3
rem domains, which on Ryzen are the CCDs, and their sizes, which expose an
rem asymmetric 3D V-Cache part. Nothing here is written.
set "FPS_PS_TITLE=CPU topology detection"
set "FPS_PS_BODY=$c='using System; using System.Runtime.InteropServices; public static class FpsTopo { [DllImport(~kernel32.dll~, SetLastError=true)] static extern bool GetLogicalProcessorInformationEx(int rel, IntPtr buf, ref int len); public static byte[] Read(int rel) { int len = 0; GetLogicalProcessorInformationEx(rel, IntPtr.Zero, ref len); if (len <= 0) { return new byte[0]; } IntPtr p = Marshal.AllocHGlobal(len); try { if (GetLogicalProcessorInformationEx(rel, p, ref len) == false) { return new byte[0]; } byte[] b = new byte[len]; Marshal.Copy(p, b, 0, len); return b; } finally { Marshal.FreeHGlobal(p); } } }'.Replace('~',[string][char]34); Add-Type -TypeDefinition $c; $cpu=''; try{ $cpu=([string]@(Get-CimInstance Win32_Processor)[0].Name).Trim() }catch{}; $cls=@{}; $smt=0; $cores=0; $buf=[FpsTopo]::Read(0); $o=0; while(($o+10) -le $buf.Length){ $sz=[BitConverter]::ToInt32($buf,$o+4); if($sz -le 0){break}; if([BitConverter]::ToInt32($buf,$o) -eq 0){ $cores++; if($buf[$o+8] -band 1){$smt++}; $ec=[int]$buf[$o+9]; if($cls.ContainsKey($ec)){$cls[$ec]++}else{$cls[$ec]=1} }; $o+=$sz }; $l3=@(); $buf=[FpsTopo]::Read(2); $o=0; while(($o+20) -le $buf.Length){ $sz=[BitConverter]::ToInt32($buf,$o+4); if($sz -le 0){break}; if(([BitConverter]::ToInt32($buf,$o) -eq 2) -and ($buf[$o+8] -eq 3)){ $l3+=[int][math]::Round([BitConverter]::ToUInt32($buf,$o+12)/1MB) }; $o+=$sz }; if(-not $cores){ Report 'INFO' 'CPU topology could not be read - topology checks will be skipped'; return }; $hyb=0; $pc=$cores; $ecn=0; if($cls.Count -gt 1){ $hyb=1; $top=[int](@($cls.Keys) | Sort-Object -Descending | Select-Object -First 1); $pc=[int]$cls[$top]; $ecn=$cores-$pc }; $x3d=0; if($cpu -match 'X3D'){ if(($l3.Count -ge 2) -and (@($l3 | Select-Object -Unique).Count -gt 1)){ $x3d=2 }else{ $x3d=1 } }; Write-FpsData 'D_HYBRID' $hyb; Write-FpsData 'D_PCORES' $pc; Write-FpsData 'D_ECORES' $ecn; Write-FpsData 'D_L3N' $l3.Count; Write-FpsData 'D_X3D' $x3d; Write-FpsData 'D_SMT' ([int]($smt -gt 0)); $t='CPU topology: '+$cores+' cores'; if($hyb){ $t='CPU topology: '+$pc+' performance + '+$ecn+' efficiency cores' }; if($smt){ $t+=', SMT on '+$smt+' of them' }else{ $t+=', no SMT' }; if($l3.Count){ $t+='; L3: '+$l3.Count+' domain(s), '+(@($l3 | ForEach-Object { [string]$_+' MB' }) -join ' + ') }; if($x3d -eq 2){ $t+='; asymmetric 3D V-Cache (one cache CCD)' }elseif($x3d -eq 1){ $t+='; 3D V-Cache' }; Report 'INFO' $t"
call :PS_RUN
rem Printers are read from the registry, so a stopped or disabled spooler cannot fail the check.
set "FPS_PS_TITLE=Storage, security and printer detection"
set "FPS_PS_BODY=$dt='UNKNOWN'; try{ $sd=$env:SystemDrive.Substring(0,1); $dn=[string](Get-Partition -DriveLetter $sd).DiskNumber; foreach($p in @(Get-PhysicalDisk)){ if([string]$p.DeviceId -eq $dn){ if($p.MediaType -eq 'SSD' -or $p.BusType -eq 'NVMe'){$dt='SSD'} elseif($p.MediaType -eq 'HDD'){$dt='HDD'} } } }catch{ Report 'FAILED' 'Reading system drive type' $_.Exception.Message }; $hv='UNKNOWN'; $vb='UNKNOWN'; try{ $dg=@(Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' -ClassName Win32_DeviceGuard)[0]; if($dg){ $services=@($dg.SecurityServicesRunning); if($services -contains 2){$hv='ENABLED'}else{$hv='DISABLED'}; if($dg.VirtualizationBasedSecurityStatus -eq 2){$vb='RUNNING'}else{$vb='OFF'} } }catch{ Report 'FAILED' 'Reading VBS / HVCI status' $_.Exception.Message }; $pp=0; try{ $pk='HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers'; if(Test-Path -LiteralPath $pk){ foreach($pr in @(Get-ChildItem -LiteralPath $pk)){ if($pr.PSChildName -notmatch 'PDF|XPS|Fax|OneNote'){$pp++} } } }catch{ $pp=-1; Report 'SKIP' 'Installed printers could not be read' $_.Exception.Message }; $hy=0; try{ if(@(Get-CimInstance Win32_ComputerSystem)[0].HypervisorPresent){$hy=1} }catch{}; Write-FpsData 'D_SYSDISK' $dt; Write-FpsData 'D_HVCI' $hv; Write-FpsData 'D_VBS' $vb; Write-FpsData 'D_PRINTERS' $pp; Write-FpsData 'D_HYPERVISOR' $hy; Report 'INFO' ('System drive: '+$dt); Report 'INFO' ('Physical printers: '+$pp); Report 'INFO' ('VBS / HVCI: '+$vb+' / '+$hv+'; hypervisor present: '+$hy)"
call :PS_RUN
rem Per-user values belong to the account signed in at the desktop. When the elevation
rem prompt was answered with another administrator account, HKCU would be that account.
set "FPS_PS_TITLE=Signed-in user detection"
set "FPS_PS_BODY=$sid=''; try{ foreach($p in @(Get-CimInstance Win32_Process -Filter 'Name=''explorer.exe''')){ if($p.SessionId -ne 0){ $o=Invoke-CimMethod -InputObject $p -MethodName GetOwnerSid; if($o.Sid){ $sid=[string]$o.Sid; break } } } }catch{}; if(($sid -notmatch '^S-1-5-21-[0-9-]+$') -or -not (Test-Path -LiteralPath ('Registry::HKEY_USERS\'+$sid))){ $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value }; $who=$sid; try{ $who=(New-Object Security.Principal.SecurityIdentifier($sid)).Translate([Security.Principal.NTAccount]).Value }catch{}; Write-FpsData 'FPS_USID' $sid; Report 'INFO' ('Per-user settings target: '+$who)"
call :PS_RUN
set "FPS_UHIVE=HKCU"
if defined FPS_USID set "FPS_UHIVE=HKU\%FPS_USID%"
echo(

rem ================================================================ BOTTLENECKS
rem Read only. These are the limits no registry value can lift, reported first
rem because each is usually worth more FPS than everything below combined.
echo  [ PHASE 0b ]  FPS bottleneck check - read only
echo  ---------------------------------------------------------------------------
set "FPS_PS_TITLE=FPS bottleneck check"
set "FPS_PS_BODY=$warn=0; try{ Add-Type -AssemblyName System.Windows.Forms; $pw=[System.Windows.Forms.SystemInformation]::PowerStatus; if([string]$pw.BatteryChargeStatus -notmatch 'NoSystemBattery'){ if([string]$pw.PowerLineStatus -eq 'Offline'){ Report 'WARNING' 'Running on battery - Windows and the firmware cut CPU and GPU clocks. Plug in to game.'; $warn++ }else{ Report 'INFO' 'Power source: plugged in' } } }catch{}; try{ $ov=[string](Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name 'ActiveOverlayAcPowerScheme' -ErrorAction SilentlyContinue).ActiveOverlayAcPowerScheme; $mode='Balanced'; if($ov -eq 'ded574b5-45a0-4f42-8737-46345c09c238'){$mode='Best performance'} elseif($ov -eq '961cc777-2547-4f9d-8174-7d86181b8a7a'){$mode='Best power efficiency'}; if($mode -eq 'Best performance'){ Report 'INFO' 'Windows power mode when plugged in: Best performance' }else{ Report 'WARNING' ('Windows power mode when plugged in: '+$mode+'. Settings, System, Power, Power mode: Best performance holds higher sustained CPU and GPU clocks. This script never changes power settings.'); $warn++ } }catch{}; try{ $mods=@(Get-CimInstance Win32_PhysicalMemory); if($mods.Count){ $rated=[int](($mods | Measure-Object -Property Speed -Maximum).Maximum); $conf=[int](($mods | Measure-Object -Property ConfiguredClockSpeed -Minimum).Minimum); $gb=[math]::Round((($mods | Measure-Object -Property Capacity -Sum).Sum)/1GB); Report 'INFO' ('Memory: '+$mods.Count+' module(s), '+$gb+' GB, running '+$conf+' MT/s, rated '+$rated+' MT/s'); if($mods.Count -eq 1){ Report 'WARNING' 'Only one memory module is reported. Single-channel memory halves bandwidth, which costs integrated graphics a large share of its FPS and lowers CPU-bound 1 percent lows; a second matching module enables dual channel. Some laptops with soldered memory report one module while running dual channel.'; $warn++ }; if(($rated -gt 0) -and ($conf -gt 0) -and ($conf -lt ($rated*0.9)) -and ($env:D_CHASSIS -ne 'LAPTOP')){ Report 'WARNING' ('Memory runs at '+$conf+' MT/s but is rated '+$rated+' MT/s. Enable XMP or EXPO in the BIOS.'); $warn++ } } }catch{}; try{ foreach($v in @(Get-CimInstance Win32_VideoController)){ if(-not $v.DriverDate){continue}; $dd=[datetime]$v.DriverDate; $age=((Get-Date)-$dd).Days; Report 'INFO' ('Graphics driver: '+$v.Name+' '+$v.DriverVersion+', dated '+$dd.ToString('yyyy-MM-dd')); if($age -gt 548){ Report 'WARNING' ($v.Name+' driver is '+[math]::Round($age/30)+' months old. New graphics drivers regularly bring game-specific FPS fixes; update from the GPU maker.'); $warn++ } } }catch{}; try{ $bg=@(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(wallpaper32|wallpaper64|webwallpaper32|Lively|Lively\.PlayerWebView2|Deskscapes)$' } | ForEach-Object { $_.ProcessName } | Select-Object -Unique); if($bg.Count){ Report 'WARNING' ('Animated wallpaper running ('+($bg -join ', ')+'): it keeps rendering behind games and takes GPU time, most of all on integrated graphics. Set it to pause whenever another app is fullscreen or maximized.'); $warn++ } }catch{}; if(-not $warn){ Report 'INFO' 'No power, memory, driver or background-rendering bottleneck found' }"
call :PS_RUN

rem Display path. On a desktop with both an integrated and a discrete GPU, a
rem monitor cable in the motherboard port makes the integrated GPU scan out
rem every frame - either rendering it or copying it across PCIe - and it is the
rem largest single FPS loss a gaming PC can have. The adapter that drives a
rem display is the one reporting a current resolution. On NVIDIA, nvidia-smi
rem also reports the BAR1 aperture - 256 MB means Resizable BAR is off - and
rem the negotiated PCIe link width against the card's maximum.
set "FPS_PS_TITLE=Platform check - display path and GPU link"
set "FPS_PS_BODY=$warn=0; try{ $vc=@(Get-CimInstance Win32_VideoController); $dg=@($vc | Where-Object { $_.Name -match 'NVIDIA|GeForce|Quadro|RTX|Radeon RX|Radeon Pro|Arc\(TM\) [AB][0-9]' }); $ig=@($vc | Where-Object { $_.Name -match 'Intel.*(UHD|Iris|HD Graphics)|Intel\(R\) Arc\(TM\) Graphics|Intel\(R\) Graphics|Radeon\(TM\) Graphics|Radeon\(TM\) [0-9]+M|Radeon Vega' }); if($dg.Count -and $ig.Count -and ($env:D_CHASSIS -ne 'LAPTOP')){ $dOut=@($dg | Where-Object { $_.CurrentHorizontalResolution -gt 0 }); $iOut=@($ig | Where-Object { $_.CurrentHorizontalResolution -gt 0 }); if($iOut.Count -and -not $dOut.Count){ Report 'WARNING' ('The monitor is driven by the integrated graphics ('+$iOut[0].Name+') while '+$dg[0].Name+' is installed. Move the display cable from the motherboard to the graphics card - this alone can cost well over half the frame rate.'); $warn++ }elseif($iOut.Count){ Report 'INFO' ('A display is also attached to the integrated graphics ('+$iOut[0].Name+'). Keep the gaming monitor on '+$dg[0].Name+'.') }else{ Report 'INFO' ('Displays are driven by '+$dg[0].Name) } } }catch{}; try{ $smi=$env:SystemRoot+'\System32\nvidia-smi.exe'; if(($env:GPU_NV -eq '1') -and (Test-Path -LiteralPath $smi)){ $old=$ErrorActionPreference; $ErrorActionPreference='Continue'; $q=@(& $smi '--query-gpu=name,memory.total,pcie.link.width.current,pcie.link.width.max' '--format=csv,noheader,nounits' 2>$null); $mem=@(& $smi '-q' '-d' 'MEMORY' 2>$null); $ErrorActionPreference=$old; $bar=@(); $inBar=$false; foreach($ln in $mem){ $s=[string]$ln; if($s -match 'BAR1 Memory Usage'){ $inBar=$true; continue }; if($inBar -and ($s -match 'Total\s*:\s*([0-9]+)')){ $bar+=[int]$Matches[1]; $inBar=$false } }; $gi=0; foreach($row in $q){ $f=@(([string]$row) -split ','); if($f.Count -lt 4){ continue }; $nm=$f[0].Trim(); $vr=0; $wc=0; $wm=0; [void][int]::TryParse($f[1].Trim(),[ref]$vr); [void][int]::TryParse($f[2].Trim(),[ref]$wc); [void][int]::TryParse($f[3].Trim(),[ref]$wm); if($gi -lt $bar.Count){ $b1=$bar[$gi]; if(($b1 -le 256) -and ($vr -ge 4096)){ Report 'WARNING' ($nm+': Resizable BAR is off - the CPU can map '+$b1+' MB of '+$vr+' MB video memory. Enable Above 4G Decoding and Re-Size BAR Support in the BIOS (UEFI boot, CSM off); supported games gain several percent.'); $warn++ }elseif($b1 -gt 256){ Report 'INFO' ($nm+': Resizable BAR on ('+$b1+' MB aperture)') } }; if(($wm -gt 0) -and ($wc -gt 0) -and ($wc -lt $wm) -and ($env:D_CHASSIS -ne 'LAPTOP')){ Report 'WARNING' ($nm+' runs at PCIe x'+$wc+' of x'+$wm+'. Check it sits in the top full-length slot; M.2 drives sharing lanes and riser cables also cause this.'); $warn++ }elseif($wc -gt 0){ Report 'INFO' ($nm+': PCIe link x'+$wc+' of x'+$wm) }; $gi++ } } }catch{}; if(-not $warn){ Report 'INFO' 'No display-path or GPU-link problem found' }"
call :PS_RUN

rem CPU scheduling prerequisites. Each item below is a documented, benchmarked
rem cause of low 1%% lows that no registry value can fix: a hybrid Intel CPU on
rem Windows 10, which has no Thread Director support; a dual-CCD 3D V-Cache
rem Ryzen missing one of the three things AMD's CCD parking depends on - the
rem 3D V-Cache Performance Optimizer driver, Xbox Game Bar game detection and
rem the Balanced plan; and a Ryzen still waiting for the 2024 branch-prediction
rem scheduling update. The power plan is read, never changed.
set "FPS_PS_TITLE=Platform check - CPU scheduling"
set "FPS_PS_BODY=$warn=0; $cpu=''; try{ $cpu=([string]@(Get-CimInstance Win32_Processor)[0].Name).Trim() }catch{}; $b=[int]$env:OSBUILD; $ubr=[int]$env:D_UBR; if($env:D_HYBRID -eq '1'){ if($b -lt 22000){ Report 'WARNING' ('Hybrid CPU ('+$env:D_PCORES+' performance + '+$env:D_ECORES+' efficiency cores) on Windows 10. Windows 10 has no Thread Director support, so game threads regularly land on efficiency cores and 1 percent lows suffer. Windows 11 schedules this CPU correctly.'); $warn++ }else{ Report 'INFO' 'Hybrid CPU on Windows 11 - Thread Director scheduling available' } }; if($env:D_X3D -eq '2'){ $drv=@(); try{ $drv=@(Get-CimInstance Win32_SystemDriver | Where-Object { $_.Name -like '*3dvcache*' }) + @(Get-CimInstance Win32_Service | Where-Object { $_.Name -like '*3dvcache*' }) }catch{}; if($drv.Count){ Report 'INFO' ('AMD 3D V-Cache Performance Optimizer present: '+(@($drv | ForEach-Object { [string]$_.Name+' '+[string]$_.State }) -join ', ')) }else{ Report 'WARNING' 'Dual-CCD 3D V-Cache CPU without the AMD 3D V-Cache Performance Optimizer driver. Install the current AMD chipset driver, or games can be scheduled on the CCD without the extra cache.'; $warn++ }; $gb=$null; try{ $gb=@(Get-AppxPackage -AllUsers -Name 'Microsoft.XboxGamingOverlay' -ErrorAction Stop) }catch{ try{ $gb=@(Get-AppxPackage -Name 'Microsoft.XboxGamingOverlay' -ErrorAction Stop) }catch{} }; if(($null -ne $gb) -and ($gb.Count -eq 0)){ Report 'WARNING' 'Xbox Game Bar is not installed. AMD CCD parking on dual-CCD 3D V-Cache CPUs relies on Game Bar recognising the game; reinstall Xbox Game Bar from the Microsoft Store.'; $warn++ }; try{ $ap=[string](Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name 'ActivePowerScheme' -ErrorAction Stop).ActivePowerScheme; if($ap -and ($ap -ne '381b4222-f694-41f0-9685-ff5bb260df2e')){ Report 'WARNING' 'The active power plan is not Balanced. AMD CCD parking on dual-CCD 3D V-Cache CPUs only works under the Balanced plan; High and Ultimate Performance keep both CCDs awake. This script never changes power plans.'; $warn++ } }catch{} }; if(($env:CPU_AMD -eq '1') -and ($cpu -match 'Ryzen')){ $fixed=($b -ge 26100) -or ((($b -eq 22621) -or ($b -eq 22631)) -and ($ubr -ge 4112)); if(-not $fixed){ if($b -lt 22000){ Report 'WARNING' 'Ryzen on Windows 10: the branch-prediction scheduling optimization AMD and Microsoft shipped in 2024 for Zen 3, Zen 4 and Zen 5 exists only for Windows 11 (24H2, or 23H2 with KB5041587). The measured gains are in CPU-bound games.' }else{ Report 'WARNING' ('Ryzen on build '+$b+'.'+$ubr+': update Windows to 24H2, or to 23H2 build 22631.4112 or later (KB5041587), which carries the AMD branch-prediction optimization for Zen 3, Zen 4 and Zen 5.') }; $warn++ }else{ Report 'INFO' ('Ryzen branch-prediction optimization included in build '+$b+'.'+$ubr) } }; if(($env:D_HYPERVISOR -eq '1') -and ($env:D_VBS -ne 'RUNNING')){ Report 'INFO' 'A hypervisor is running (Hyper-V, WSL 2, Virtual Machine Platform or Windows Sandbox). Windows then runs beside it, which costs a few percent in some CPU-bound games. Left untouched.' }; if(-not $warn){ Report 'INFO' 'No CPU scheduling problem found' }"
call :PS_RUN

rem System state. A nearly full system SSD, Driver Verifier or heap-debugging
rem flags left behind by troubleshooting each cost more than any tweak here
rem recovers. They are reported with the fix, not changed: someone who set
rem them on purpose is still debugging.
set "FPS_PS_TITLE=Platform check - system state"
set "FPS_PS_BODY=$warn=0; try{ $ld=@(Get-CimInstance Win32_LogicalDisk -Filter ('DeviceID='''+$env:SystemDrive+''''))[0]; if($ld -and ($ld.Size -gt 0)){ $pct=[math]::Round(100*$ld.FreeSpace/$ld.Size); $fg=[math]::Round($ld.FreeSpace/1GB); if((($pct -lt 10) -and ($fg -lt 100)) -or ($fg -lt 20)){ Report 'WARNING' ('System drive '+$env:SystemDrive+' has '+$fg+' GB free ('+$pct+' percent). A nearly full SSD writes slower and leaves the pagefile and shader caches no room to grow. Uninstall what you do not use.'); $warn++ }else{ Report 'INFO' ('System drive free space: '+$fg+' GB ('+$pct+' percent)') } } }catch{}; try{ $mm=Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -ErrorAction Stop; $vd=([string]$mm.VerifyDrivers).Trim(); $vl=[int64]0; if($null -ne $mm.VerifyDriverLevel){ $vl=[int64]$mm.VerifyDriverLevel }; if($vd -or ($vl -ne 0)){ Report 'WARNING' 'Driver Verifier is active. It adds checks to every call into the verified drivers and causes heavy stutter. Unless you are chasing a crash, run verifier /reset and reboot.'; $warn++ } }catch{}; $mask=0x020038F0; try{ $gfv=(Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'GlobalFlag' -ErrorAction SilentlyContinue).GlobalFlag; if($null -ne $gfv){ $gfn=[int64]$gfv -band $mask; if($gfn){ Report 'WARNING' ('System-wide heap or stack-trace debugging flags are set (GlobalFlag bits 0x'+$gfn.ToString('X')+'). They slow allocations in every process; clear them with gflags unless you are debugging.'); $warn++ } } }catch{}; try{ $hits=@(); foreach($k in @(Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options' -ErrorAction Stop)){ $g=$k.GetValue('GlobalFlag'); if($null -eq $g){ continue }; $gn=[int64]0; try{ if($g -is [string]){ $gn=[Convert]::ToInt64(($g -replace '^0[xX]',''),16) }else{ $gn=[int64]$g } }catch{}; if($gn -band $mask){ $hits+=$k.PSChildName } }; if($hits.Count){ Report 'WARNING' ('Heap debugging (page heap or heap checks) is on for: '+(@($hits | Select-Object -First 8) -join ', ')+'. Those programs run far slower; remove GlobalFlag for them under Image File Execution Options, or run gflags /p /disable with the program name.'); $warn++ } }catch{}; if(-not $warn){ Report 'INFO' 'Free space, Driver Verifier and debugging flags are fine' }"
call :PS_RUN

rem Background residency. RGB and sensor suites poll the SMBus and embedded
rem controller on a timer and are a recurring, well-documented cause of
rem periodic hitching and DPC latency spikes. They are listed, not closed:
rem some also run fan curves. Startup programs are listed the same way.
set "FPS_PS_TITLE=Platform check - background residency"
set "FPS_PS_BODY=try{ $sus=[ordered]@{ 'ASUS Armoury Crate / Aura'='^(ArmouryCrate|ArmouryCrate\.Service|ArmourySocketServer|LightingService|AacAmbientLighting)$'; 'Corsair iCUE'='^(iCUE|Corsair\.Service|CorsairDeviceControlService)$'; 'NZXT CAM'='^NZXT CAM$'; 'SignalRGB'='^SignalRgb$'; 'Razer Synapse'='^(RazerCentralService|Razer Synapse Service|Razer Synapse Service Process)$'; 'MSI Center'='^(MSI\.CentralServer|MSI_Central_Service)$'; 'HWiNFO sensor polling'='^HWiNFO(64|32)$'; 'AIDA64 sensor polling'='^aida64$' }; $pn=@(Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $_.ProcessName } | Select-Object -Unique); $run=@(); foreach($nm in $sus.Keys){ $rx=$sus[$nm]; if(@($pn | Where-Object { $_ -match $rx }).Count){ $run+=$nm } }; if($run.Count){ Report 'WARNING' ('Running: '+($run -join ', ')+'. RGB and sensor suites poll hardware on a timer and are a recurring cause of periodic stutter and DPC latency spikes. If you see regular hitches, test once with them fully closed.') }else{ Report 'INFO' 'No RGB or sensor-polling suite running' } }catch{}; try{ $ent=@(); $srcs=@(@('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'),@('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32')); if($env:FPS_USID){ $ur='Registry::HKEY_USERS\'+$env:FPS_USID+'\Software\Microsoft\Windows\CurrentVersion\'; $srcs+=,@(($ur+'Run'),($ur+'Explorer\StartupApproved\Run')) }; foreach($pair in $srcs){ if(-not (Test-Path -LiteralPath $pair[0])){ continue }; $rk=Get-Item -LiteralPath $pair[0]; $ak=$null; if(Test-Path -LiteralPath $pair[1]){ $ak=Get-Item -LiteralPath $pair[1] }; foreach($vn in @($rk.GetValueNames() | Where-Object { $_ })){ $on=$true; if($ak){ $bytes=$ak.GetValue($vn); if(($bytes -is [byte[]]) -and $bytes.Length -and ($bytes[0] -band 1)){ $on=$false } }; if($on){ $ent+=$vn } } }; if($ent.Count){ Report 'INFO' ('Startup programs enabled: '+$ent.Count+' - '+(@($ent | Select-Object -Unique -First 12) -join ', ')+'. Each keeps running beside your games; disable the ones you do not need in Task Manager, Startup apps.') }else{ Report 'INFO' 'No startup programs enabled in the Run keys' } }catch{}"
call :PS_RUN
echo(

if "%D_RAMGB%"=="0" echo    NOTE: memory size could not be read; the original 0 GB fallback will gate memory tweaks.
if "%D_SYSDISK%"=="UNKNOWN" echo    NOTE: drive type unknown; SSD-gated tweaks will be skipped for safety.
echo(
echo  Press any key to begin. Close this window now to abort.
pause >nul
echo(

rem ==========================================================================
rem PHASE 1 - REVERSE KNOWN-HARMFUL AND KNOWN-PLACEBO LEGACY TWEAKS
rem ==========================================================================
echo  [ PHASE 1 ]  Reversing harmful / obsolete tweaks left by other tools
echo  ---------------------------------------------------------------------------

rem useplatformclock forces the HPET as the primary timer source. On every
rem modern CPU this REDUCES performance and increases timer read cost.
call :BCD "useplatformclock" "Removing forced HPET timer useplatformclock"
call :BCD "useplatformtick" "Removing forced platform tick useplatformtick"
call :BCD "tscsyncpolicy" "Removing tscsyncpolicy override"
rem Some optimizers cap the usable core count. Always remove a detected cap.
call :BCD "numproc" "Removing the numproc core cap"
call :BCD "onecpu" "Removing the onecpu single-processor boot flag"
rem groupsize, maxgroup and groupaware split the processors into several
rem processor groups. Most games schedule their threads inside one group only,
rem so a split leaves cores idle.
call :BCD "groupsize" "Removing the groupsize processor-group split"
call :BCD "maxgroup" "Removing the maxgroup processor-group override"
call :BCD "groupaware" "Removing the groupaware driver test mode"
rem Forced legacy xAPIC mode, a disabled x2APIC and physical destination mode
rem all send interrupts down slower paths than the platform default.
call :BCD "uselegacyapicmode" "Removing forced legacy APIC mode"
call :BCD "x2apicpolicy" "Removing the x2APIC policy override"
call :BCD "usephysicaldestination" "Removing forced physical APIC destination mode"
rem msi ForceDisable switches message-signalled interrupts off for every device;
rem DisallowMmConfig forces the slow legacy PCI configuration access path.
call :BCD "msi" "Removing the global MSI override"
call :BCD "configaccesspolicy" "Removing the PCI configuration access override"
rem All of the above are hardware and HAL elements that BitLocker's default BCD
rem validation profile ignores, so removing them cannot trigger BitLocker
rem recovery. The kernel debugger flag is deliberately NOT touched for that
rem reason: BitLocker validates it, and changing it can demand the recovery key.
call :BCD_MEMORY

rem IoPageLockLimit has been ignored by the memory manager since XP.
call :RDEL "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "IoPageLockLimit"
rem LargeSystemCache=1 starves application working sets on a client OS.
call :RS "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" REG_DWORD "0"
rem DpcWatchdogProfileOffset belongs to the DPC watchdog. It does not move DPCs
rem off CPU 0 as tweak lists claim, and no benchmark shows it changing DPC
rem latency. v1 of this script set it; the value is removed again.
call :RDEL "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "DpcWatchdogProfileOffset"
rem "One svchost": raising SvcHostSplitThresholdInKB above installed RAM merges
rem services back into shared svchost processes. It saves a little memory, no
rem benchmark shows a frame-rate change, and one crashing service then takes
rem its neighbours down with it. Restored to the Windows default only where changed.
set "FPS_PS_TITLE=Svchost split threshold"
set "FPS_PS_BODY=$k='HKLM:\SYSTEM\CurrentControlSet\Control'; $v=(Get-ItemProperty -LiteralPath $k -Name 'SvcHostSplitThresholdInKB' -ErrorAction SilentlyContinue).SvcHostSplitThresholdInKB; if($null -eq $v){ Report 'SKIP' 'SvcHostSplitThresholdInKB not set - Windows default in effect'; return }; if([int64]$v -eq 3670016){ Report 'SKIP' 'SvcHostSplitThresholdInKB already at the Windows default 3670016'; return }; Apply ('Restoring SvcHostSplitThresholdInKB from '+$v+' to the Windows default 3670016') { Set-ItemProperty -LiteralPath $k -Name 'SvcHostSplitThresholdInKB' -Value 3670016 -Type DWord }"
call :PS_RUN
rem Input queues. Tweak lists shrink MouseDataQueueSize and KeyboardDataQueueSize
rem to 16-50 for "lower input lag". The queue is a buffer, not a delay: a
rem smaller one cannot deliver input sooner, but a 4000-8000 Hz mouse can
rem overflow it and drop movement. Values under 64 go back to the default 100.
set "FPS_PS_TITLE=Mouse and keyboard input queues"
set "FPS_PS_BODY=foreach($q in @(@('mouclass','MouseDataQueueSize'),@('kbdclass','KeyboardDataQueueSize'))){ $k='HKLM:\SYSTEM\CurrentControlSet\Services\'+$q[0]+'\Parameters'; $qn=$q[1]; if(-not (Test-Path -LiteralPath $k)){ Report 'SKIP' ($q[0]+' parameters key absent'); continue }; $v=(Get-ItemProperty -LiteralPath $k -Name $qn -ErrorAction SilentlyContinue).($qn); if($null -eq $v){ Report 'SKIP' ($qn+' not set - Windows default 100 in effect'); continue }; if([int64]$v -ge 64){ Report 'SKIP' ($qn+' = '+$v+' - large enough, left alone'); continue }; Apply ('Restoring '+$qn+' from '+$v+' to the Windows default 100') { Set-ItemProperty -LiteralPath $k -Name $qn -Value 100 -Type DWord } }"
call :PS_RUN
rem The "Disable indexer backoff" policy keeps Windows Search indexing at full
rem speed while you are using the PC - which includes playing. Removed if set.
call :RDEL "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableBackoff"
rem Ensure the pagefile was not deleted by an "optimizer" - that causes hard hitches.
set "FPS_PS_TITLE=Pagefile configuration check"
set "FPS_PS_BODY=$k=Get-Item -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; $p=$k.GetValue('PagingFiles'); if(($p -join ' ') -match 'pagefile.sys'){ Report 'SKIP' 'Pagefile present - left untouched' }else{ Report 'WARNING' 'No pagefile configured. Re-enable it (System-managed). A missing pagefile can cause commit-limit stalls.' }"
call :PS_RUN
echo(

rem ==========================================================================
rem PHASE 2 - KERNEL SCHEDULING, QUANTUM, TIMER RESOLUTION, THROTTLING
rem ==========================================================================
if not "%CFG_SCHEDULER%"=="1" ( echo  [ PHASE 2 ]  skipped by config & echo( & goto :PH3 )
echo  [ PHASE 2 ]  CPU scheduling, thread quantum, timer resolution
echo  ---------------------------------------------------------------------------

rem Win32PrioritySeparation controls quantum length, quantum type and the
rem foreground priority boost ratio. 38 ^(0x26^) decodes to short, variable
rem quantums with a 3:1 foreground boost - exactly what the client default 2
rem already means. It is written as a guard: other optimizers leave server-style
rem long or fixed quantums here, which weaken the foreground game's share.
rem Revert value: 2
call :RS "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" REG_DWORD "%CFG_PRIORITY_SEPARATION%"

rem Since Windows 10 2004 the 1 ms timer resolution a game requests only
rem applies to that process. Games that raise the timer for their own frame
rem pacing no longer affect the rest of the system, and several engines
rem regress because of it. This restores the pre-2004 global behaviour.
if "%HAS_PERPROC_TIMER%"=="1" (
    call :RS "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "GlobalTimerResolutionRequests" REG_DWORD "1"
    set "REBOOT_REQ=1"
) else (
    echo    [SKIP] GlobalTimerResolutionRequests not applicable on build %OSBUILD%
    set /a CNT_SKIP+=1 >nul
)

rem Power throttling / EcoQoS lets the scheduler demote threads it believes
rem are background work. Engine worker and audio threads are regularly
rem misclassified, producing periodic frametime spikes. Registry-only, no
rem power plan is touched. Revert value: 0 or delete the value.
call :RS "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" REG_DWORD "1"
if "%D_CHASSIS%"=="LAPTOP" echo        note: on a laptop this raises idle power draw. Set to 0 to revert.

rem Fast Startup hibernates the kernel and drivers, so driver state, GPU
rem scheduler state and timer state accumulate across "shutdowns". Disabling
rem it gives a clean kernel every boot. Registry-only. Revert value: 1
call :RS "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" REG_DWORD "0"
set "REBOOT_REQ=1"
echo(

:PH3
rem ==========================================================================
rem PHASE 3 - MULTIMEDIA CLASS SCHEDULER SERVICE ^(MMCSS^)
rem ==========================================================================
if not "%CFG_MMCSS%"=="1" ( echo  [ PHASE 3 ]  skipped by config & echo( & goto :PH4 )
echo  [ PHASE 3 ]  MMCSS game profile
echo  ---------------------------------------------------------------------------

rem SystemResponsiveness is the percentage of CPU MMCSS reserves for
rem low-priority background work. Client default is 20. Dropping to 10 hands
rem that headroom back to registered multimedia threads. 0 is avoided on
rem purpose: it can starve the audio engine and produce crackling.
rem Revert value: 20
call :RS "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" REG_DWORD "%CFG_SYSTEM_RESPONSIVENESS%"
call :RS "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NoLazyMode" REG_DWORD "1"

rem The "Games" MMCSS task is what a title joins when it calls
rem AvSetMmThreadCharacteristics. These values raise the GPU share, thread
rem priority and scheduled-file-I-O class for those threads.
set "MMTASK=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
call :RS "%MMTASK%" "Affinity" REG_DWORD "0"
call :RS "%MMTASK%" "Background Only" REG_SZ "False"
call :RS "%MMTASK%" "BackgroundPriority" REG_DWORD "0"
call :RS "%MMTASK%" "Clock Rate" REG_DWORD "10000"
call :RS "%MMTASK%" "GPU Priority" REG_DWORD "8"
call :RS "%MMTASK%" "Priority" REG_DWORD "6"
call :RS "%MMTASK%" "Scheduling Category" REG_SZ "High"
call :RS "%MMTASK%" "SFIO Priority" REG_SZ "High"

rem Keep the Audio profile sane so the low SystemResponsiveness value cannot
rem cause buffer underruns, which present as hitching in-game.
set "MMAUD=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio"
"%FPS_BIN%\reg.exe" query "%MMAUD%" <nul >nul 2>&1
if not errorlevel 1 (
    call :RS "%MMAUD%" "Scheduling Category" REG_SZ "High"
) else (
    echo    [SKIP] Audio MMCSS profile not found or could not be queried.
    set /a CNT_SKIP+=1 >nul
)
set "REBOOT_REQ=1"
echo(

:PH4
rem ==========================================================================
rem PHASE 4 - MEMORY MANAGER
rem ==========================================================================
if not "%CFG_MEMORY%"=="1" ( echo  [ PHASE 4 ]  skipped by config & echo( & goto :PH5 )
echo  [ PHASE 4 ]  Memory manager and prefetcher
echo  ---------------------------------------------------------------------------

set "MM=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

rem DisablePagingExecutive keeps kernel and driver code resident instead of
rem allowing it to be trimmed to the pagefile. Paged-out driver code being
rem faulted back in mid-frame is a classic source of isolated 0.1%% low
rem spikes. Gated on ^>= 16 GB because on smaller systems it costs more than
rem it returns. Revert value: 0
if %D_RAMGB% GEQ 16 (
    call :RS "%MM%" "DisablePagingExecutive" REG_DWORD "1"
    set "REBOOT_REQ=1"
) else (
    echo    [SKIP] DisablePagingExecutive skipped - needs 16 GB or more ^(found %D_RAMGB% GB^)
    rem If a previous tool set it on a low-memory machine, undo that.
    call :RS "%MM%" "DisablePagingExecutive" REG_DWORD "0"
)

rem No shutdown-time pagefile scrub. Costs seconds of I/O, returns nothing.
call :RS "%MM%" "ClearPageFileAtShutdown" REG_DWORD "0"

rem Prefetcher / SysMain. On an SSD the superfetch prefetch passes cost more
rem in background CPU and random I/O than the launch-time saving is worth,
rem and those passes are exactly what fires during a loading screen. On an
rem HDD the opposite is true, so this is left fully enabled there.
if "%D_SYSDISK%"=="SSD" (
    call :RS "%MM%\PrefetchParameters" "EnablePrefetcher" REG_DWORD "0"
    call :RS "%MM%\PrefetchParameters" "EnableSuperfetch" REG_DWORD "0"
    echo        SSD policy requests both prefetcher values = 0. Revert value for both: 3
) else if "%D_SYSDISK%"=="HDD" (
    call :RS "%MM%\PrefetchParameters" "EnablePrefetcher" REG_DWORD "3"
    call :RS "%MM%\PrefetchParameters" "EnableSuperfetch" REG_DWORD "3"
    echo        HDD policy requests both prefetcher values = 3.
) else (
    echo    [SKIP] drive type unknown - prefetcher left at current setting
    set /a CNT_SKIP+=1 >nul
)

rem Memory compression and page combining trade CPU cycles for RAM. With
rem plenty of physical memory that trade is a straight loss: the compression
rem worker competes with game threads. MMAgent must be reconfigured BEFORE
rem SysMain is disabled in phase 12, or the cmdlets have no service to talk to.
rem On a re-run SysMain is already off, which is reported as a skip.
set "DOMC=0"
if /i "%CFG_MEMCOMPRESSION%"=="1" set "DOMC=1"
if /i "%CFG_MEMCOMPRESSION%"=="auto" if %D_RAMGB% GEQ 32 set "DOMC=1"
if "%DOMC%"=="1" (
    set "FPS_PS_TITLE=Memory compression and page combining"
    set "FPS_PS_BODY=if([string](Get-Service SysMain -ErrorAction SilentlyContinue).Status -ne 'Running'){ Report 'SKIP' 'SysMain is not running, so MMAgent cannot be configured - these features run inside SysMain'; return }; Apply 'Disabling memory compression' { Disable-MMAgent -MemoryCompression }; Apply 'Disabling page combining' { Disable-MMAgent -PageCombining }"
    call :PS_RUN
    echo        Revert: Enable-MMAgent -MemoryCompression -PageCombining
    set "REBOOT_REQ=1"
) else (
    echo    [SKIP] Memory compression left unchanged by config / RAM gate.
    set /a CNT_SKIP+=1 >nul
)

rem Application prelaunch spends I/O and CPU speculatively launching UWP apps.
set "FPS_PS_TITLE=Application prelaunch"
set "FPS_PS_BODY=if([string](Get-Service SysMain -ErrorAction SilentlyContinue).Status -ne 'Running'){ Report 'SKIP' 'SysMain is not running, so application prelaunch is already inactive'; return }; Apply 'Disabling UWP application prelaunch' { Disable-MMAgent -ApplicationPreLaunch }"
call :PS_RUN

rem Fault Tolerant Heap. After a program crashes a few times, Windows silently
rem attaches heap mitigations to it for good - extra checks on every allocation,
rem which costs CPU time in allocation-heavy engines. Off means a crash-prone game
rem keeps the normal heap. Shims already attached to programs are cleared too,
rem so a game that crashed earlier gets the normal heap back. Takes effect at
rem the next program start. Revert value: 1
if not "%CFG_FTH_OFF%"=="1" goto :PH4_FTH_DONE
set "FPS_PS_TITLE=Fault Tolerant Heap"
set "FPS_PS_BODY=$k='HKLM:\SOFTWARE\Microsoft\FTH'; if(-not (Test-Path -LiteralPath $k)){ Report 'SKIP' 'Fault Tolerant Heap is not present on this build'; return }; $shim=@(); if(Test-Path -LiteralPath ($k+'\State')){ $shim=@((Get-Item -LiteralPath ($k+'\State')).GetValueNames() | Where-Object { $_ }) }; if($shim.Count){ Report 'INFO' ('Programs already running with FTH heap mitigations: '+(@($shim | Select-Object -First 8 | ForEach-Object { [IO.Path]::GetFileName($_) }) -join ', ')) }; $cur=(Get-ItemProperty -LiteralPath $k -Name 'Enabled' -ErrorAction SilentlyContinue).Enabled; if(($cur -eq 0) -and (-not $shim.Count)){ Report 'SKIP' 'Fault Tolerant Heap already off'; return }; if($cur -eq 0){ Apply 'Clearing existing FTH heap shims' { & ($env:SystemRoot+'\System32\rundll32.exe') 'fthsvc.dll,FthSysprepSpecialize' }; return }; Apply 'Turning Fault Tolerant Heap off - Enabled = 0' { Set-ItemProperty -LiteralPath $k -Name 'Enabled' -Value 0 -Type DWord }; if($shim.Count){ Apply 'Clearing existing FTH heap shims' { & ($env:SystemRoot+'\System32\rundll32.exe') 'fthsvc.dll,FthSysprepSpecialize' } }"
call :PS_RUN
:PH4_FTH_DONE

echo(

:PH5
rem ==========================================================================
rem PHASE 5 - FILESYSTEM METADATA COST
rem ==========================================================================
if not "%CFG_FILESYSTEM%"=="1" ( echo  [ PHASE 5 ]  skipped by config & echo( & goto :PH6 )
echo  [ PHASE 5 ]  NTFS metadata write reduction
echo  ---------------------------------------------------------------------------

rem Last-access timestamps force a metadata write for every file a game
rem touches. A shader cache or asset streamer opening thousands of files per
rem loading transition turns that into real I/O. 1 = user disabled.
rem Revert: fsutil behavior set disablelastaccess 2   ^(system-managed default^)
echo    [FILESYSTEM] Disabling NTFS last-access updates - disablelastaccess = 1
if "%FPS_DRYRUN%"=="1" goto :PH5_LA_DRY
"%FPS_BIN%\fsutil.exe" behavior set disablelastaccess 1 <nul >nul 2>&1
set "OP_RC=%errorlevel%"
if "%OP_RC%"=="0" (
    set /a CNT_OK+=1 >nul
    echo    [OK] NTFS last-access updates disabled.
    set "REBOOT_REQ=1"
) else (
    set /a CNT_FAIL+=1 >nul
    echo    [FAILED] Setting disablelastaccess to 1; exit code %OP_RC%.
)
goto :PH5_LA_DONE
:PH5_LA_DRY
set /a CNT_OK+=1 >nul
echo    [WOULD] NTFS last-access updates disabled.
:PH5_LA_DONE

rem 8.3 short name generation adds a directory-index write per file creation.
rem Revert value: 2  ^(per-volume default^)
call :RS "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsDisable8dot3NameCreation" REG_DWORD "1"
echo        note: a small number of very old installers still expect 8.3 names.

rem TRIM is verified rather than assumed. A drive with TRIM switched off
rem degrades into write-amplification stalls, which is one of the few
rem storage-side causes of genuine in-game hitching.
rem Keep the original gate: examine the last nonempty query line, then SSD.
set "FPS_PS_TITLE=TRIM status"
set "FPS_PS_BODY=$old=$ErrorActionPreference; $ErrorActionPreference='Continue'; $lines=@(& ($env:FPS_BIN+'\fsutil.exe') behavior query DisableDeleteNotify 2>&1); $rc=$LASTEXITCODE; $ErrorActionPreference=$old; if($rc -ne 0){ if($env:FPS_DRYRUN -eq '1'){ Report 'SKIP' 'TRIM query needs administrator rights (dry run)' }else{ Report 'FAILED' 'Querying TRIM / DisableDeleteNotify' ('exit code '+$rc) }; return }; $hit=''; $first=''; foreach($line in $lines){ $t=([string]$line).Trim(); if(-not $t){ continue }; if(-not $first){ $first=$t }; if((-not $hit) -and ($t -match '(?i)^NTFS\s+DisableDeleteNotify')){ $hit=$t } }; if(-not $first){ Report 'FAILED' 'Querying TRIM / DisableDeleteNotify' 'No query output returned'; return }; if(-not $hit){ $hit=$first }; if($hit -match 'DisableDeleteNotify\s*=\s*1'){ if($env:D_SYSDISK -eq 'SSD'){ if($env:FPS_DRYRUN -eq '1'){ Report 'WOULD' 'Re-enabling TRIM - DisableDeleteNotify = 0'; return }; Report 'APPLY' 'Re-enabling TRIM - DisableDeleteNotify = 0'; $ErrorActionPreference='Continue'; $result=@(& ($env:FPS_BIN+'\fsutil.exe') behavior set DisableDeleteNotify 0 2>&1); $rc=$LASTEXITCODE; $ErrorActionPreference=$old; if($rc -eq 0){Report 'OK' 'TRIM re-enabled'}else{Report 'FAILED' 'Re-enabling TRIM' ('exit code '+$rc)} }else{ Report 'SKIP' 'TRIM change requires a detected SSD' } }else{ Report 'SKIP' 'TRIM query did not report = 1; left unchanged' }"
call :PS_RUN

rem Cap NTFS paged-pool growth behaviour at the default. Explicitly reset if a
rem previous tool set NtfsMemoryUsage=2, which starves other paged pool users.
call :RDEL "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsMemoryUsage"
echo(

:PH6
rem ==========================================================================
rem PHASE 6 - GPU SCHEDULING, INTERRUPTS, VENDOR AGENTS
rem ==========================================================================
if not "%CFG_GPU%"=="1" ( echo  [ PHASE 6 ]  skipped by config & echo( & goto :PH7 )
echo  [ PHASE 6 ]  GPU scheduling and interrupt policy
echo  ---------------------------------------------------------------------------

rem Hardware-accelerated GPU scheduling moves queue management onto the GPU's
rem own scheduler, cutting CPU-side submission overhead. On NVIDIA and Arc it
rem is neutral-to-positive and is a prerequisite for several latency features.
rem On Radeon the community results are genuinely mixed, so the existing
rem setting is left alone there for you to A/B test yourself.
rem Revert value: 1 ^(off^) / 2 ^(on^)
set "DO_HAGS=0"
if "%GPU_NV%"=="1" set "DO_HAGS=1"
if "%GPU_INTEL%"=="1" if "%GPU_AMD%"=="0" set "DO_HAGS=1"
if %OSBUILD% GEQ 19041 (
    if "%DO_HAGS%"=="1" (
        call :RS "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" REG_DWORD "2"
        set "REBOOT_REQ=1"
    ) else (
        echo    [SKIP] HAGS left at current value for this GPU - test both settings yourself.
        set /a CNT_SKIP+=1 >nul
    )
) else (
    echo    [SKIP] HAGS unavailable on build %OSBUILD%.
    set /a CNT_SKIP+=1 >nul
)

rem Multi-plane overlay. Leaving MPO on is correct for most systems. It is
rem only worth disabling on the specific mixed-refresh multi-monitor setups
rem that flicker or micro-stutter on the desktop, because disabling it forces
rem full DWM composition and costs performance elsewhere.
rem From 24H2 OverlayTestMode alone no longer disables MPO; DisableOverlays does.
if not "%CFG_DISABLE_MPO%"=="1" goto :PH6_MPO_KEEP
call :RS "HKLM\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" REG_DWORD "5"
if %OSBUILD% GEQ 26100 call :RS "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "DisableOverlays" REG_DWORD "1"
echo        Config requests MPO disabled. Revert: delete OverlayTestMode and DisableOverlays.
set "REBOOT_REQ=1"
goto :PH6_MPO_DONE
:PH6_MPO_KEEP
echo    [SKIP] MPO left enabled - correct default
:PH6_MPO_DONE

rem Message-signalled interrupts and device interrupt priority for the display
rem adapter. MSI removes the shared line-based IRQ handshake and is one of the
rem few changes that shows up directly in DPC latency measurements. This only
rem writes where the interrupt-management key already exists, so it never
rem creates MSI state on a device whose stack does not advertise it.
if "%CFG_GPU_MSI%"=="1" (
    set "FPS_PS_TITLE=GPU interrupt policy"
    set "FPS_PS_BODY=$found=0; foreach($v in @(Get-CimInstance Win32_VideoController)){ $id=[string]$v.PNPDeviceID; if($id -and $id.StartsWith('PCI')){ $found++; $b='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$id+'\Device Parameters\Interrupt Management'; $m=$b+'\MessageSignaledInterruptProperties'; try{ if(Test-Path -LiteralPath $m){ Apply ('Enabling GPU MSI: '+$v.Name+'; MSISupported = 1') { Set-ItemProperty -LiteralPath $m -Name 'MSISupported' -Value 1 -Type DWord } }else{Report 'SKIP' ('MSI key absent: '+$v.Name)} }catch{Report 'FAILED' ('Checking GPU MSI key: '+$v.Name) $_.Exception.Message}; $a=$b+'\Affinity Policy'; try{ if(Test-Path -LiteralPath $b){ Apply ('Setting GPU interrupt priority: '+$v.Name+'; DevicePriority = 3') { if(-not (Test-Path -LiteralPath $a)){ $key=[Microsoft.Win32.Registry]::LocalMachine.CreateSubKey('SYSTEM\CurrentControlSet\Enum\'+$id+'\Device Parameters\Interrupt Management\Affinity Policy'); if($null -eq $key){throw 'Cannot create Affinity Policy key'}; $key.Dispose() }; Set-ItemProperty -LiteralPath $a -Name 'DevicePriority' -Value 3 -Type DWord } }else{Report 'SKIP' ('Interrupt Management key absent: '+$v.Name)} }catch{Report 'FAILED' ('Checking interrupt policy: '+$v.Name) $_.Exception.Message} } }; if(-not $found){Report 'SKIP' 'No eligible PCI display adapters found'}"
    call :PS_RUN
    echo        Revert: MSISupported=0 and delete the Affinity Policy subkey.
    set "REBOOT_REQ=1"
)

rem Vendor background agents. These are telemetry and updater processes, not
rem the graphics driver itself. The driver, control panel and overlay stay.
if "%GPU_NV%"=="1" (
    echo    NVIDIA detected - trimming vendor background agents
    call :SVC "NvTelemetryContainer" disabled
    call :RS "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" "OptInOrOutPreference" REG_DWORD "0"
    call :RS "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" "EnableRID44231" REG_DWORD "0"
    call :RS "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" "EnableRID64640" REG_DWORD "0"
    call :RS "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" "EnableRID66610" REG_DWORD "0"
)

rem DirectX shader cache. Windows' automatic cleanup - Storage Sense and the
rem SilentCleanup maintenance task - empties the DirectX shader cache together
rem with temporary files. Every game then rebuilds its shaders on the next
rem launch: the compilation stutter that wrecks 0.1%% lows in the first minutes
rem of play. Autorun 0 takes the cache out of automatic runs only; Disk Cleanup
rem can still empty it when you choose to. Revert value: 1
if not "%CFG_SHADER_CACHE_KEEP%"=="1" goto :PH6_SC_DONE
call :RSE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\D3D Shader Cache" "Autorun" REG_DWORD "0"
:PH6_SC_DONE

rem Windows Update driver delivery. Windows Update regularly offers an older
rem OEM graphics driver and installs it over the one you chose, silently losing
rem game-specific fixes. Opt-in, because it stops every other driver update
rem through Windows Update as well. Revert: delete ExcludeWUDriversInQualityUpdate.
if "%CFG_BLOCK_WU_DRIVERS%"=="1" (
    call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "ExcludeWUDriversInQualityUpdate" REG_DWORD "1"
) else (
    echo    [SKIP] Windows Update driver delivery left on - set CFG_BLOCK_WU_DRIVERS=1 to stop it
    set /a CNT_SKIP+=1 >nul
)

rem Refresh rate. A high-refresh panel left at 60 Hz caps what you can see at 60
rem frames and adds up to 10 ms of display latency - the most common "my new
rem monitor feels the same" cause. Only modes Windows itself lists for the
rem display's current resolution and colour depth are considered, interlaced
rem modes are ignored, and the driver must accept the mode in a test pass
rem before it is applied. Revert: Settings, Display, Advanced display.
if not "%CFG_MAX_REFRESH%"=="1" goto :PH6_HZ_DONE
set "FPS_PS_TITLE=Display refresh rate"
set "FPS_PS_BODY=$c='using System; using System.Runtime.InteropServices; public static class FpsDisplay { [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)] public struct DEVMODE { [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmDeviceName; public short dmSpecVersion; public short dmDriverVersion; public short dmSize; public short dmDriverExtra; public int dmFields; public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmDisplayFixedOutput; public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption; public short dmCollate; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmFormName; public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight; public int dmDisplayFlags; public int dmDisplayFrequency; public int dmICMMethod; public int dmICMIntent; public int dmMediaType; public int dmDitherType; public int dmReserved1; public int dmReserved2; public int dmPanningWidth; public int dmPanningHeight; } [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)] public struct DISPLAY_DEVICE { public int cb; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string DeviceName; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string DeviceString; public int StateFlags; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string DeviceID; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string DeviceKey; } [DllImport(~user32.dll~, CharSet=CharSet.Ansi)] static extern bool EnumDisplayDevices(string dev, uint i, ref DISPLAY_DEVICE dd, uint f); [DllImport(~user32.dll~, CharSet=CharSet.Ansi)] static extern bool EnumDisplaySettings(string dev, int mode, ref DEVMODE dm); [DllImport(~user32.dll~, CharSet=CharSet.Ansi)] static extern int ChangeDisplaySettingsEx(string dev, ref DEVMODE dm, IntPtr h, uint f, IntPtr l); static DEVMODE Blank() { DEVMODE d = new DEVMODE(); d.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE)); return d; } public static string Scan() { string o = ~~; for (uint i = 0; i < 16; i++) { DISPLAY_DEVICE dd = new DISPLAY_DEVICE(); dd.cb = Marshal.SizeOf(typeof(DISPLAY_DEVICE)); if (EnumDisplayDevices(null, i, ref dd, 0) == false) { break; } if ((dd.StateFlags & 1) == 0) { continue; } DEVMODE cur = Blank(); if (EnumDisplaySettings(dd.DeviceName, -1, ref cur) == false) { continue; } int best = cur.dmDisplayFrequency; DEVMODE m = Blank(); for (int k = 0; EnumDisplaySettings(dd.DeviceName, k, ref m); k++) { if (m.dmPelsWidth == cur.dmPelsWidth && m.dmPelsHeight == cur.dmPelsHeight && m.dmBitsPerPel == cur.dmBitsPerPel && (m.dmDisplayFlags & 2) == 0 && m.dmDisplayFrequency > best) { best = m.dmDisplayFrequency; } m = Blank(); } o += dd.DeviceName + ~,~ + cur.dmPelsWidth + ~,~ + cur.dmPelsHeight + ~,~ + cur.dmBitsPerPel + ~,~ + cur.dmDisplayFrequency + ~,~ + best + ~;~; } return o; } public static int Set(string dev, int w, int h, int bpp, int hz) { DEVMODE m = Blank(); for (int k = 0; EnumDisplaySettings(dev, k, ref m); k++) { if (m.dmPelsWidth == w && m.dmPelsHeight == h && m.dmBitsPerPel == bpp && m.dmDisplayFrequency == hz && (m.dmDisplayFlags & 2) == 0) { m.dmFields = 0x40000 | 0x80000 | 0x100000 | 0x400000; int t = ChangeDisplaySettingsEx(dev, ref m, IntPtr.Zero, 2, IntPtr.Zero); if (t == 0) { return ChangeDisplaySettingsEx(dev, ref m, IntPtr.Zero, 1, IntPtr.Zero); } return t; } m = Blank(); } return -100; } }'.Replace('~',[string][char]34); Add-Type -TypeDefinition $c; $list=@(([FpsDisplay]::Scan()) -split ';' | Where-Object { $_ }); if(-not $list.Count){ Report 'SKIP' 'No active display could be read'; return }; foreach($e in $list){ $p=$e -split ','; $dev=$p[0]; $w=[int]$p[1]; $h=[int]$p[2]; $bpp=[int]$p[3]; $cur=[int]$p[4]; $best=[int]$p[5]; if($cur -le 1){ Report 'SKIP' ($dev+' reports only a hardware-default refresh rate'); continue }; if($best -le $cur){ Report 'SKIP' ($dev+' already runs its highest refresh rate: '+$cur+' Hz at '+$w+'x'+$h); continue }; Apply ($dev+' refresh rate '+$cur+' Hz to '+$best+' Hz at '+$w+'x'+$h) { $rc=[FpsDisplay]::Set($dev,$w,$h,$bpp,$best); if($rc -ne 0){ throw ('the display driver rejected the mode, code '+$rc) } } }"
call :PS_RUN
:PH6_HZ_DONE

rem Hybrid graphics. On laptops with an integrated and a discrete GPU, Windows
rem decides per program which GPU renders, and games regularly land on the
rem integrated one at a fraction of the frame rate. Installed games found in
rem Steam libraries, Epic, Xbox and Riot folders get the same per-app choice as
rem Settings, Display, Graphics: High performance. Existing per-app entries
rem such as Auto HDR are kept. Single-GPU systems are detected and skipped.
rem Revert: Settings, Display, Graphics, per app - Let Windows decide.
if not "%CFG_HYBRID_GPU%"=="1" goto :PH6_HYB_DONE
set "FPS_PS_TITLE=Hybrid graphics game assignment"
set "FPS_PS_BODY=$names=@(); try{ $names=@(Get-CimInstance Win32_VideoController | ForEach-Object { [string]$_.Name }) }catch{}; $dg=@($names | Where-Object { $_ -match 'NVIDIA|GeForce|Quadro|RTX|Radeon RX|Radeon Pro|Arc\(TM\) [AB][0-9]' }); $ig=@($names | Where-Object { $_ -match 'Intel.*(UHD|Iris|HD Graphics)|Intel\(R\) Arc\(TM\) Graphics|Intel\(R\) Graphics|Radeon\(TM\) Graphics|Radeon\(TM\) [0-9]+M|Radeon Vega' }); if(-not ($dg.Count -and $ig.Count)){ Report 'SKIP' ('Single-GPU system, nothing to assign: '+($names -join ' + ')); return }; if(-not $env:FPS_USID){ Report 'SKIP' 'Signed-in user unknown - per-app GPU choice not written'; return }; $steam=''; try{ $steam=[string](Get-ItemProperty -LiteralPath ('Registry::HKEY_USERS\'+$env:FPS_USID+'\Software\Valve\Steam') -Name 'SteamPath' -ErrorAction Stop).SteamPath }catch{}; if(-not $steam){ $steam=${env:ProgramFiles(x86)}+'\Steam' }; $steam=$steam.Replace('/','\'); $libs=@($steam); $vdf=$steam+'\steamapps\libraryfolders.vdf'; if(Test-Path -LiteralPath $vdf){ foreach($ln in @(Get-Content -LiteralPath $vdf -ErrorAction SilentlyContinue)){ if($ln -match '^\s*\x22path\x22\s+\x22(.+)\x22'){ $libs+=($Matches[1] -replace '\\\\','\') } } }; $roots=@(); foreach($l in @($libs | Select-Object -Unique)){ $cm=$l+'\steamapps\common'; if(Test-Path -LiteralPath $cm){ $roots+=@(Get-ChildItem -LiteralPath $cm -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }) } }; foreach($x in @(($env:ProgramFiles+'\Epic Games'),($env:SystemDrive+'\XboxGames'),($env:SystemDrive+'\Riot Games'))){ if(Test-Path -LiteralPath $x){ $roots+=@(Get-ChildItem -LiteralPath $x -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }) } }; $skip='unins|setup|install|redist|dxsetup|directx|dotnet|crash|report|helper|updat|launcher|bootstrap|cleanup|easyanticheat|battleye|beservice|prereq|notification|webhelper|cefprocess|service|repair|config|editor|server'; $exes=@(); foreach($r in $roots){ $exes+=@(Get-ChildItem -LiteralPath $r -Filter '*.exe' -File -Recurse -Depth 5 -ErrorAction SilentlyContinue | Where-Object { $_.BaseName -notmatch $skip } | ForEach-Object { $_.FullName }) }; $exes=@($exes | Select-Object -Unique | Select-Object -First 500); if(-not $exes.Count){ Report 'SKIP' 'Hybrid graphics detected, but no installed games were found in Steam, Epic, Xbox or Riot folders'; return }; $sub=$env:FPS_USID+'\Software\Microsoft\DirectX\UserGpuPreferences'; $rk=[Microsoft.Win32.Registry]::Users.OpenSubKey($sub); $plan=@(); foreach($e in $exes){ $cur=''; if($rk){ $v=$rk.GetValue($e); if($v){ $cur=[string]$v } }; $map=[ordered]@{}; foreach($pair in ($cur -split ';')){ $kv=$pair -split '=',2; if(($kv.Count -eq 2) -and $kv[0]){ $map[$kv[0]]=$kv[1] } }; if($map['GpuPreference'] -eq '2'){ continue }; $map['GpuPreference']='2'; $plan+=,@($e,((@($map.Keys | ForEach-Object { $_+'='+$map[$_] }) -join ';')+';')) }; if($rk){ $rk.Close() }; Report 'INFO' ('Hybrid graphics: '+($dg -join ' + ')+' with '+($ig -join ' + ')+'; '+$exes.Count+' game executables in '+$roots.Count+' install folders'); if(-not $plan.Count){ Report 'SKIP' 'Every detected game executable already uses the high-performance GPU'; return }; Apply ('High-performance GPU assigned to '+$plan.Count+' game executables, for example '+(@($plan | ForEach-Object { [IO.Path]::GetFileName($_[0]) } | Select-Object -Unique | Select-Object -First 4) -join ', ')) { $wk=[Microsoft.Win32.Registry]::Users.CreateSubKey($sub); if($null -eq $wk){ throw 'Cannot open the per-app GPU preference key' }; try{ foreach($it in $plan){ $wk.SetValue([string]$it[0],[string]$it[1],[Microsoft.Win32.RegistryValueKind]::String) } }finally{ $wk.Close() } }"
call :PS_RUN
:PH6_HYB_DONE

set "FPS_PS_TITLE=Vendor telemetry tasks"
set "FPS_PS_BODY=$n=0; foreach($t in @(Get-ScheduledTask)){ $tn=$t.TaskName; if($tn -like 'NvTm*' -or $tn -like 'NvProfileUpdater*' -or $tn -like 'NvNode*' -or $tn -like 'NvDriverUpdate*' -or $tn -like '*Intel*Telemetry*' -or $tn -like 'AMD*Telemetry*' -or $tn -like '*User Experience Program*'){ $n++; Apply ('Disabling vendor telemetry task: '+$t.TaskPath+$tn) { Disable-ScheduledTask -TaskName $tn -TaskPath $t.TaskPath } } }; if(-not $n){Report 'SKIP' 'No matching vendor telemetry tasks found'}"
call :PS_RUN

echo(

:PH7
rem ==========================================================================
rem PHASE 7 - GAME MODE, GAME DVR, GAME BAR, FULLSCREEN BEHAVIOUR
rem ==========================================================================
if not "%CFG_GAMEBAR%"=="1" ( echo  [ PHASE 7 ]  skipped by config & echo( & goto :PH8 )
echo  [ PHASE 7 ]  Game Mode on, Game DVR and overlay capture off
echo  ---------------------------------------------------------------------------

rem Game Mode and Game DVR are frequently confused. Game Mode is kept ON:
rem on modern builds it deprioritises background work and measurably tightens
rem 1%% lows, most visibly on lower core-count CPUs. Game DVR is the
rem always-armed background recorder and it costs frames in every title that
rem it hooks, so it goes.
call :RS "HKCU\Software\Microsoft\GameBar" "AllowAutoGameMode" REG_DWORD "1"
call :RS "HKCU\Software\Microsoft\GameBar" "AutoGameModeEnabled" REG_DWORD "1"
call :RS "HKCU\Software\Microsoft\GameBar" "UseNexusForGameBarEnabled" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\GameBar" "ShowStartupPanel" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\GameBar" "GamePanelStartupTipIndex" REG_DWORD "3"

call :RS "HKCU\System\GameConfigStore" "GameDVR_Enabled" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" "HistoricalCaptureEnabled" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" "value" REG_DWORD "0"

rem Fullscreen Optimizations. On current builds FSO is a flip-model borderless
rem path that is usually equal or better than legacy exclusive fullscreen, and
rem it is required for Auto HDR. It is therefore NOT disabled by default. Set
rem CFG_DISABLE_FSO=1 only if you are chasing latency in older DX9/DX11 titles.
if "%CFG_DISABLE_FSO%"=="1" (
    call :RS "HKCU\System\GameConfigStore" "GameDVR_FSEBehaviorMode" REG_DWORD "2"
    call :RS "HKCU\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" REG_DWORD "1"
    call :RS "HKCU\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" REG_DWORD "1"
    call :RS "HKCU\System\GameConfigStore" "GameDVR_EFSEFeatureFlags" REG_DWORD "0"
    echo        Config requests FSO disabled. Revert: FSEBehaviorMode=2, HonorUser=0.
) else (
    rem Honour per-title overrides so the compatibility tab still works.
    call :RS "HKCU\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" REG_DWORD "1"
    echo    [SKIP] Fullscreen Optimizations left enabled - correct on current builds
)

rem Optimizations for windowed games ^(Windows 11^). DX10/11 titles running in a
rem window or borderless are moved from the legacy blt presentation model to
rem flip model: less latency, working VRR, steadier frame pacing. It is the same
rem switch as Settings, Display, Graphics. Existing entries in the value, such
rem as Auto HDR, are kept. Revert: set SwapEffectUpgradeEnable=0 there.
if not "%CFG_WINDOWED_OPT%"=="1" goto :PH7_WIN_DONE
if not "%IS_W11%"=="1" (
    echo    [SKIP] Optimizations for windowed games need Windows 11.
    set /a CNT_SKIP+=1 >nul
    goto :PH7_WIN_DONE
)
set "FPS_PS_TITLE=Optimizations for windowed games"
set "FPS_PS_BODY=$k='HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'; if($env:FPS_USID){ $k='Registry::HKEY_USERS\'+$env:FPS_USID+'\Software\Microsoft\DirectX\UserGpuPreferences' }; $cur=''; if(Test-Path -LiteralPath $k){ $v=(Get-ItemProperty -LiteralPath $k -Name 'DirectXUserGlobalSettings' -ErrorAction SilentlyContinue).DirectXUserGlobalSettings; if($v){ $cur=[string]$v } }; $map=[ordered]@{}; foreach($pair in ($cur -split ';')){ $kv=$pair -split '=',2; if($kv.Count -eq 2 -and $kv[0]){ $map[$kv[0]]=$kv[1] } }; if(($map['SwapEffectUpgradeEnable'] -eq '1') -and ($map['VRROptimizeEnable'] -eq '1')){ Report 'SKIP' 'Optimizations for windowed games already on'; return }; $map['SwapEffectUpgradeEnable']='1'; $map['VRROptimizeEnable']='1'; $new=(@($map.Keys | ForEach-Object { $_+'='+$map[$_] }) -join ';')+';'; Apply ('Optimizations for windowed games on - '+$new) { if(-not (Test-Path -LiteralPath $k)){ New-Item -Path $k -Force | Out-Null }; Set-ItemProperty -LiteralPath $k -Name 'DirectXUserGlobalSettings' -Value $new -Type String }"
call :PS_RUN
:PH7_WIN_DONE
echo(

:PH8
rem ==========================================================================
rem PHASE 8 - DWM, VISUAL EFFECTS, SHELL RESPONSIVENESS
rem ==========================================================================
if not "%CFG_SHELL%"=="1" ( echo  [ PHASE 8 ]  skipped by config & echo( & goto :PH9 )
echo  [ PHASE 8 ]  Compositor cost and shell responsiveness
echo  ---------------------------------------------------------------------------

rem Acrylic/mica transparency is a real per-frame DWM blur pass. Removing it
rem returns GPU time, which matters most on integrated and entry-level parts
rem and during alt-tab transitions in borderless titles.
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" REG_DWORD "0"

rem Custom visual-effects profile: animations off, ClearType and thumbnails
rem kept. VisualFXSetting 3 = custom. Revert value: 0 ^(let Windows choose^).
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" REG_DWORD "3"
set "VFX=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
for %%E in (AnimateMinMax ComboBoxAnimation ControlAnimations CursorShadow DragFullWindows DropShadow ListBoxSmoothScrolling ListviewShadow MenuAnimation SelectionFade TaskbarAnimations TooltipAnimation) do (
    call :RS "%VFX%\%%E" "DefaultApplied" REG_DWORD "0"
)
call :RS "%VFX%\ThumbnailsOrIcon" "DefaultApplied" REG_DWORD "1"
call :RS "%VFX%\FontSmoothing" "DefaultApplied" REG_DWORD "1"

rem UserPreferencesMask 90 12 03 80 10 00 00 00 is the performance profile
rem that still leaves font smoothing intact. Windows default is 9E1E078012000000.
call :RS "HKCU\Control Panel\Desktop" "UserPreferencesMask" REG_BINARY "9012038010000000"
call :RS "HKCU\Control Panel\Desktop" "DragFullWindows" REG_SZ "0"
call :RS "HKCU\Control Panel\Desktop" "MenuShowDelay" REG_SZ "0"
call :RS "HKCU\Control Panel\Desktop\WindowMetrics" "MinAnimate" REG_SZ "0"
call :RS "HKCU\Control Panel\Desktop" "FontSmoothing" REG_SZ "2"
call :RS "HKCU\Control Panel\Desktop" "FontSmoothingType" REG_DWORD "2"
call :RS "HKCU\Control Panel\Desktop" "AutoEndTasks" REG_SZ "1"
call :RS "HKCU\Control Panel\Desktop" "HungAppTimeout" REG_SZ "2000"
call :RS "HKCU\Control Panel\Desktop" "WaitToKillAppTimeout" REG_SZ "3000"
call :RS "HKCU\Control Panel\Desktop" "LowLevelHooksTimeout" REG_SZ "1000"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" REG_DWORD "0"
call :RS "HKLM\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" REG_SZ "5000"
echo(

:PH9
rem ==========================================================================
rem PHASE 9 - INPUT STACK LATENCY
rem ==========================================================================
if not "%CFG_INPUT%"=="1" ( echo  [ PHASE 9 ]  skipped by config & echo( & goto :PH9_SESSION )
echo  [ PHASE 9 ]  USB and HID input latency
echo  ---------------------------------------------------------------------------

rem Selective suspend lets the USB stack idle a device down between reports.
rem On a high-polling-rate mouse that produces the first-movement-after-idle
rem delay and occasional dropped report batches. Registry-only, no power plan.
rem Revert value: 0
call :RS "HKLM\SYSTEM\CurrentControlSet\Services\USB" "DisableSelectiveSuspend" REG_DWORD "1"

rem Per-device: clear "allow the computer to turn off this device to save
rem power" for mice, keyboards and HID devices only. Storage and network
rem devices are deliberately untouched.
set "FPS_PS_TITLE=Input device power management"
set "FPS_PS_BODY=$n=0; foreach($d in @(Get-PnpDevice)){ if($d.Class -eq 'Mouse' -or $d.Class -eq 'Keyboard' -or $d.Class -eq 'HIDClass'){ $k='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$d.InstanceId+'\Device Parameters'; try{ if(Test-Path -LiteralPath $k){ $n++; foreach($property in @('EnhancedPowerManagementEnabled','SelectiveSuspendEnabled','AllowIdleIrpInD3')){ Apply ('Input device '+$d.InstanceId+': '+$property+' = 0') { New-ItemProperty -LiteralPath $k -Name $property -Value 0 -PropertyType DWord -Force } } }else{Report 'SKIP' ('Input Device Parameters key absent: '+$d.InstanceId)} }catch{Report 'FAILED' ('Checking input device: '+$d.InstanceId) $_.Exception.Message} } }; if(-not $n){Report 'SKIP' 'No eligible input device parameter keys found'}"
call :PS_RUN

rem USB host controllers and hubs. The mouse's own power setting is not enough:
rem the root hub or controller above it can still be powered down, and waking
rem it costs the first report after idle. This uses MSPower_DeviceEnable - the
rem exact switch behind Device Manager's "Allow the computer to turn off this
rem device to save power" - for USB, mouse, keyboard and HID devices only.
rem Storage, network and audio devices are not touched. Revert: tick the box
rem again in Device Manager, Power Management tab.
if not "%CFG_USB_POWER%"=="1" goto :PH9_USB_DONE
set "FPS_PS_TITLE=USB controller and hub power management"
set "FPS_PS_BODY=$want=@{}; foreach($d in @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue)){ if(@('USB','Mouse','Keyboard','HIDClass') -contains [string]$d.Class){ $want[([string]$d.InstanceId).ToUpperInvariant()]=[string]$d.FriendlyName } }; if(-not $want.Count){ Report 'SKIP' 'No present USB or input devices found'; return }; $pm=@(); try{ $pm=@(Get-CimInstance -Namespace 'root\wmi' -ClassName 'MSPower_DeviceEnable' -ErrorAction Stop) }catch{ Report 'SKIP' 'Device power management could not be read on this system'; return }; $n=0; $off=0; foreach($e in $pm){ $id=(([string]$e.InstanceName) -replace '_[0-9]+$','').ToUpperInvariant(); if(-not $want.ContainsKey($id)){ continue }; $n++; if(-not $e.Enable){ $off++; continue }; $nm=$want[$id]; if(-not $nm){ $nm=$id }; Apply ('Device power-down off: '+$nm) { Set-CimInstance -InputObject $e -Property @{Enable=$false} } }; if(-not $n){ Report 'SKIP' 'No USB or input device offers a power-down switch' }elseif($off -eq $n){ Report 'SKIP' ('Power-down already off on all '+$n+' USB and input devices') }elseif($off){ Report 'INFO' ([string]$off+' more USB or input device(s) already had power-down off') }"
call :PS_RUN
if "%D_CHASSIS%"=="LAPTOP" echo        note: on a laptop this raises idle power draw slightly.
:PH9_USB_DONE

rem Accessibility hotkeys. Shift pressed five times, right Shift held for eight
rem seconds or Num Lock held for five seconds opens a dialog that drops a
rem fullscreen game to the desktop mid-match. Only the hotkey bit is cleared -
rem whether Sticky, Filter or Toggle Keys is on stays exactly as it was.
rem Stock values: StickyKeys 510, Keyboard Response 126, ToggleKeys 62.
if not "%CFG_ACCESS_HOTKEYS_OFF%"=="1" goto :PH9_ACC_DONE
set "FPS_PS_TITLE=Accessibility hotkeys"
set "FPS_PS_BODY=$root='HKCU:'; if($env:FPS_USID){ $root='Registry::HKEY_USERS\'+$env:FPS_USID }; foreach($it in @(@('StickyKeys',510),@('Keyboard Response',126),@('ToggleKeys',62))){ $k=$root+'\Control Panel\Accessibility\'+$it[0]; $cur=[int]$it[1]; if(Test-Path -LiteralPath $k){ $v=(Get-ItemProperty -LiteralPath $k -Name 'Flags' -ErrorAction SilentlyContinue).Flags; $pv=0; if(($null -ne $v) -and [int]::TryParse([string]$v,[ref]$pv)){ $cur=$pv } }; if(-not ($cur -band 4)){ Report 'SKIP' ($it[0]+' hotkey already off (Flags '+$cur+')'); continue }; $nv=[string]($cur -band (-bnot 4)); Apply ($it[0]+' hotkey off - Flags '+$cur+' to '+$nv) { if(-not (Test-Path -LiteralPath $k)){ New-Item -Path $k -Force | Out-Null }; Set-ItemProperty -LiteralPath $k -Name 'Flags' -Value $nv -Type String } }"
call :PS_RUN
:PH9_ACC_DONE

rem Pointer acceleration. Removing it makes the mouse-to-view transfer
rem function linear, which is what every aim-consistency workflow assumes.
if "%CFG_MOUSE_ACCEL_OFF%"=="1" (
    call :RS "HKCU\Control Panel\Mouse" "MouseSpeed" REG_SZ "0"
    call :RS "HKCU\Control Panel\Mouse" "MouseThreshold1" REG_SZ "0"
    call :RS "HKCU\Control Panel\Mouse" "MouseThreshold2" REG_SZ "0"
    echo        Revert: MouseSpeed=1, MouseThreshold1=6, MouseThreshold2=10.
)
call :RS "HKCU\Control Panel\Keyboard" "KeyboardDelay" REG_SZ "0"
call :RS "HKCU\Control Panel\Keyboard" "KeyboardSpeed" REG_SZ "31"
set "REBOOT_REQ=1"
echo(

:PH9_SESSION
rem Registry writes alone do not change the running desktop, and a sign-out can
rem save the running values back over them - which is how v1's mouse, keyboard
rem and animation settings were lost. Each one is applied to the live session too.
rem The registry already holds the values, so these calls only broadcast them.
set "FPS_SESS=0"
if "%CFG_SHELL%"=="1" set "FPS_SESS=1"
if "%CFG_INPUT%"=="1" set "FPS_SESS=1"
if not "%FPS_SESS%"=="1" goto :PH10
echo  [ PHASE 9b ]  Desktop and input settings applied to the running session
echo  ---------------------------------------------------------------------------
set "FPS_PS_TITLE=Applying settings to the running session"
set "FPS_PS_BODY=$q=[char]34; $sig='[DllImport('+$q+'user32.dll'+$q+', SetLastError=true)] public static extern bool SystemParametersInfo(uint a, uint p, IntPtr v, uint w); [DllImport('+$q+'user32.dll'+$q+', EntryPoint='+$q+'SystemParametersInfoW'+$q+', SetLastError=true)] public static extern bool SystemParametersInfoArr(uint a, uint p, int[] v, uint w); [DllImport('+$q+'user32.dll'+$q+', CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageTimeout(IntPtr h, uint m, UIntPtr w, string l, uint f, uint t, out UIntPtr r);'; Add-Type -Namespace FpsV2 -Name Session -MemberDefinition $sig; $f=2; $ops=@(); if($env:CFG_INPUT -eq '1'){ if($env:CFG_MOUSE_ACCEL_OFF -eq '1'){ $ops+=,@('pointer acceleration off',{ [FpsV2.Session]::SystemParametersInfoArr(0x0004,0,[int[]](0,0,0),$f) }) }; $ops+=,@('keyboard repeat delay 0',{ [FpsV2.Session]::SystemParametersInfo(0x0017,0,[IntPtr]::Zero,$f) }); $ops+=,@('keyboard repeat rate 31',{ [FpsV2.Session]::SystemParametersInfo(0x000B,31,[IntPtr]::Zero,$f) }); if($env:CFG_ACCESS_HOTKEYS_OFF -eq '1'){ foreach($acc in @(@('Sticky Keys hotkey off',0x003A,0x003B,2),@('Filter Keys hotkey off',0x0032,0x0033,6),@('Toggle Keys hotkey off',0x0034,0x0035,2))){ $ga=[uint32]$acc[1]; $sa=[uint32]$acc[2]; $cnt=[int]$acc[3]; $ops+=,@($acc[0],{ $sp=New-Object 'int[]' $cnt; $sp[0]=4*$cnt; if(-not [FpsV2.Session]::SystemParametersInfoArr($ga,[uint32](4*$cnt),$sp,0)){ return $false }; $sp[1]=$sp[1] -band (-bnot 4); [FpsV2.Session]::SystemParametersInfoArr($sa,[uint32](4*$cnt),$sp,$f) }.GetNewClosure()) } } }; if($env:CFG_SHELL -eq '1'){ $ops+=,@('menu show delay 0',{ [FpsV2.Session]::SystemParametersInfo(0x006B,0,[IntPtr]::Zero,$f) }); $ops+=,@('window contents while dragging off',{ [FpsV2.Session]::SystemParametersInfo(0x0025,0,[IntPtr]::Zero,$f) }); $ops+=,@('minimize and maximize animation off',{ [FpsV2.Session]::SystemParametersInfoArr(0x0049,8,[int[]](8,0),$f) }); foreach($pair in @(@(0x1003,'menu animation'),@(0x1005,'combo box animation'),@(0x1007,'list box smooth scrolling'),@(0x1015,'selection fade'),@(0x1017,'tooltip animation'),@(0x101B,'cursor shadow'),@(0x1025,'drop shadow'),@(0x1043,'client area animation'))){ $act=[uint32]$pair[0]; $ops+=,@(($pair[1]+' off'),{ [FpsV2.Session]::SystemParametersInfo($act,0,[IntPtr]::Zero,$f) }.GetNewClosure()) }; $ops+=,@('transparency change announced to the shell',{ $r=[UIntPtr]::Zero; [void][FpsV2.Session]::SendMessageTimeout([IntPtr]0xffff,0x1A,[UIntPtr]::Zero,'ImmersiveColorSet',2,3000,[ref]$r); $true }) }; foreach($o in $ops){ $call=$o[1]; Apply ('Live session: '+$o[0]) { if(-not (& $call)){ throw ('Windows refused the change, error '+[Runtime.InteropServices.Marshal]::GetLastWin32Error()) } } }"
call :PS_RUN
echo(

:PH10
rem ==========================================================================
rem PHASE 10 - BACKGROUND EXECUTION AND CONTENT DELIVERY
rem ==========================================================================
if not "%CFG_BACKGROUND%"=="1" ( echo  [ PHASE 10 ]  skipped by config & echo( & goto :PH10B )
echo  [ PHASE 10 ]  UWP background execution, content delivery, widgets
echo  ---------------------------------------------------------------------------

call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" REG_DWORD "1"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" "BackgroundAppGlobalToggle" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" REG_DWORD "2"

set "CDM=HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
for %%V in (ContentDeliveryAllowed FeatureManagementEnabled OemPreInstalledAppsEnabled PreInstalledAppsEnabled PreInstalledAppsEverEnabled SilentInstalledAppsEnabled SoftLandingEnabled SystemPaneSuggestionsEnabled RotatingLockScreenOverlayEnabled SubscribedContentEnabled) do (
    call :RS "%CDM%" "%%V" REG_DWORD "0"
)
for %%V in (SubscribedContent-310093Enabled SubscribedContent-338387Enabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-338393Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled SubscribedContent-353698Enabled SubscribedContent-88000326Enabled) do (
    call :RS "%CDM%" "%%V" REG_DWORD "0"
)
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" REG_DWORD "1"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableSoftLanding" REG_DWORD "1"

rem Nag and suggestion toasts: each one wakes the shell and can pull a game out
rem of fullscreen focus. Revert: delete these values.
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" "ScoobeSystemSettingEnabled" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested" "Enabled" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.BackupReminder" "Enabled" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" "EnableAccountNotifications" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_AccountNotifications" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSyncProviderNotifications" REG_DWORD "0"

rem Smart Clipboard suggested actions scan everything you copy. Windows 11 only.
if "%IS_W11%"=="1" call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\SmartActionPlatform\SmartClipboard" "Disabled" REG_DWORD "1"

rem Dynamic Lighting ^(Windows 11 23H2+^): Windows drives every LampArray RGB
rem device from a background host. Off hands RGB back to the device's own
rem firmware or app. Revert: Settings, Personalization, Dynamic Lighting.
if not "%CFG_DYNAMIC_LIGHTING_OFF%"=="1" goto :PH10_DL_DONE
if %OSBUILD% GEQ 22631 (
    call :RS "HKCU\Software\Microsoft\Lighting" "AmbientLightingEnabled" REG_DWORD "0"
) else (
    echo    [SKIP] Dynamic Lighting does not exist before Windows 11 23H2.
    set /a CNT_SKIP+=1 >nul
)
:PH10_DL_DONE

rem Cross-device experiences ^(Phone Link resume, mobile device pairing^) keep
rem background hosts polling. Revert: delete these values.
if "%CFG_CROSSDEVICE_OFF%"=="1" (
    call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableMmx" REG_DWORD "0"
    call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" "IsResumeAllowed" REG_DWORD "0"
    call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Mobility" "CrossDeviceEnabled" REG_DWORD "0"
    call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Mobility" "OptedIn" REG_DWORD "0"
    set "REBOOT_REQ=1"
)

rem Microsoft Store app updates download and install in the background, games
rem included. Opt-in, because apps then update only when you open the Store.
rem Revert: delete AutoDownload.
if "%CFG_STORE_AUTOUPDATE_OFF%"=="1" call :RS "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" "AutoDownload" REG_DWORD "2"

rem Widgets runs a WebView2 host that polls and renders continuously. The
rem AllowNewsAndInterests policy removes Widgets entirely. On 24H2 and later
rem Windows protects the TaskbarDa button value itself, so it is not written there.
if "%IS_W11%"=="1" (
    call :RS "HKLM\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" REG_DWORD "0"
    if "%IS_24H2%"=="1" (
        echo    [SKIP] TaskbarDa is protected by Windows on 24H2 and later - the policy above already removes Widgets.
        set /a CNT_SKIP+=1 >nul
    ) else (
        call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" REG_DWORD "0"
    )
    call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" REG_DWORD "0"
) else (
    call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" REG_DWORD "0"
)

rem Recall ^(Copilot+ PCs^) captures and analyses screen snapshots in the
rem background. This policy stops snapshot saving; on PCs without Recall it
rem is inert. Revert: delete DisableAIDataAnalysis.
rem Click to Do, the on-screen analysis companion to Recall, is a per-user
rem policy. Revert: delete DisableClickToDo.
if "%CFG_RECALL_OFF%"=="1" (
    if "%IS_24H2%"=="1" (
        call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" REG_DWORD "1"
        call :RS "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" REG_DWORD "1"
        call :RS "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" "DisableClickToDo" REG_DWORD "1"
    ) else (
        echo    [SKIP] Recall and Click to Do do not exist before Windows 11 24H2.
        set /a CNT_SKIP+=1 >nul
    )
)

rem Copilot. Up to 23H2 it is a shell-hosted WebView that this policy removes;
rem from 24H2 it is an ordinary app and Windows ignores the policy, so it is
rem harmless there. Revert: delete TurnOffWindowsCopilot.
call :RS "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" REG_DWORD "1"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" REG_DWORD "1"
if "%IS_W11%"=="1" call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" REG_DWORD "0"

rem Search box web suggestions send every keystroke typed into Start to Bing
rem and render the results, keeping the search host busy. Local search stays.
call :RS "HKCU\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" REG_DWORD "1"

rem Spotlight and "tailored experiences" download and rotate content in the
rem background. Revert: delete both values.
call :RS "HKCU\Software\Policies\Microsoft\Windows\CloudContent" "DisableWindowsSpotlightFeatures" REG_DWORD "1"
call :RS "HKCU\Software\Policies\Microsoft\Windows\CloudContent" "DisableTailoredExperiencesWithDiagnosticData" REG_DWORD "1"

rem Start menu web results keep SearchApp.exe resident and busy.
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" REG_DWORD "1"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" REG_DWORD "0"

rem Browsers that keep a background host alive after the window is closed.
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Edge" "BackgroundModeEnabled" REG_DWORD "0"
"%FPS_BIN%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome" <nul >nul 2>&1
if not errorlevel 1 (
    call :RS "HKLM\SOFTWARE\Policies\Google\Chrome" "BackgroundModeEnabled" REG_DWORD "0"
)
rem Windows AI Fabric ^(24H2+ Copilot+ PCs^) starts its model hosts at boot and
rem holds several GB of memory. Manual start keeps the AI features on demand.
set "FPS_PS_TITLE=Windows AI Fabric"
set "FPS_PS_BODY=Invoke-FpsAiFabric"
call :PS_LIB
echo(

:PH10B
rem ==========================================================================
rem PHASE 10b - THIRD-PARTY SOFTWARE THAT COSTS FRAMES
rem ==========================================================================
if not "%CFG_THIRDPARTY%"=="1" ( echo  [ PHASE 10b ]  skipped by config & echo( & goto :PH11 )
echo  [ PHASE 10b ]  Third-party software
echo  ---------------------------------------------------------------------------
rem Steam background recording is a continuous video encode like Game DVR;
rem Lively Wallpaper set to keep rendering behind fullscreen games takes GPU
rem time; HWiNFO polling faster than once a second adds driver time. Each file
rem is edited only while that program is closed, since it rewrites its own
rem settings on exit.
set "FPS_PS_TITLE=Third-party software"
set "FPS_PS_BODY=Invoke-FpsThirdParty"
call :PS_LIB
if not "%CFG_NAHIMIC_OFF%"=="1" goto :PH10B_NAH_DONE
rem Nahimic injects its NahimicOSD overlay into games; game developers list it
rem as a cause of crashes and stutter. Revert: set its services back to automatic.
set "FPS_PS_TITLE=Nahimic audio overlay"
set "FPS_PS_BODY=Invoke-FpsNahimic"
call :PS_LIB
:PH10B_NAH_DONE
echo(

:PH11
rem ==========================================================================
rem PHASE 11 - TELEMETRY AND DIAGNOSTIC WORKLOADS
rem ==========================================================================
if not "%CFG_TELEMETRY%"=="1" ( echo  [ PHASE 11 ]  skipped by config & echo( & goto :PH12 )
echo  [ PHASE 11 ]  Telemetry and diagnostic workloads
echo  ---------------------------------------------------------------------------
echo        Target here is the background CPU and disk cost of the agents,
echo        not Windows Update, Defender or any security telemetry.

call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "DoNotShowFeedbackNotifications" REG_DWORD "1"
call :RS "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "AITEnable" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "DisableInventory" REG_DWORD "1"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "DisableUAR" REG_DWORD "1"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "DisablePCA" REG_DWORD "1"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" "CEIPEnable" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" "Disabled" REG_DWORD "1"
call :RS "HKCU\Software\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags" "AITEnable" REG_DWORD "0"
echo        note: on Home and Pro, AllowTelemetry is floored at Required by
echo        Windows. Stopping the DiagTrack service below is what actually
echo        removes the background work.

rem Diagnostic log and dump uploads, and OneSettings configuration downloads
rem that re-arm diagnostic collection. All three are documented policies.
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "LimitDiagnosticLogCollection" REG_DWORD "1"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "LimitDumpCollection" REG_DWORD "1"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "DisableOneSettingsDownloads" REG_DWORD "1"

rem Activity history writes a record of every app and document you open.
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" REG_DWORD "1"

rem Typing and inking personalisation: the text input host otherwise keeps
rem harvesting typed text, ink and contacts to train its models.
call :RS "HKCU\Software\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" REG_DWORD "1"
call :RS "HKCU\Software\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" REG_DWORD "1"
call :RS "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" REG_DWORD "0"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC" "PreventHandwritingDataSharing" REG_DWORD "1"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports" "PreventHandwritingErrorReports" REG_DWORD "1"

rem ETW autologger sessions start at boot and stay armed whether or not anything
rem reads them. These three exist only to feed the telemetry pipeline. Written
rem only where Windows created them. Revert value: 1
call :RSE "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener" "Start" REG_DWORD "0"
call :RSE "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Diagtrack-Listener" "Start" REG_DWORD "0"
call :RSE "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\SQMLogger" "Start" REG_DWORD "0"

rem Microsoft Office telemetry, only where Office is installed. Revert: delete
rem both values. The matching Office telemetry agent tasks go in phase 13.
"%FPS_BIN%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" <nul >nul 2>&1
if errorlevel 1 "%FPS_BIN%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Office\16.0" <nul >nul 2>&1
if errorlevel 1 "%FPS_BIN%\reg.exe" query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\16.0" <nul >nul 2>&1
if errorlevel 1 goto :PH11_OFFICE_ABSENT
call :RS "HKCU\Software\Policies\Microsoft\Office\16.0\Common\ClientTelemetry" "DisableTelemetry" REG_DWORD "1"
call :RS "HKCU\Software\Policies\Microsoft\Office\16.0\Common\ClientTelemetry" "SendTelemetry" REG_DWORD "3"
goto :PH11_OFFICE_DONE
:PH11_OFFICE_ABSENT
echo    [SKIP] Microsoft Office is not installed - Office telemetry policy not written.
set /a CNT_SKIP+=1 >nul
:PH11_OFFICE_DONE
echo(

:PH12
rem ==========================================================================
rem PHASE 12 - BACKGROUND SERVICES
rem ==========================================================================
if not "%CFG_SERVICES%"=="1" ( echo  [ PHASE 12 ]  skipped by config & echo( & goto :PH13 )
echo  [ PHASE 12 ]  Background services
echo  ---------------------------------------------------------------------------
echo        Untouched on purpose: Defender, firewall, Windows Update, BITS,
echo        Xbox Live services ^(Game Pass saves^), Bluetooth, audio, touch input.

call :SVC "DiagTrack" disabled
call :SVC "dmwappushservice" disabled
call :SVC "diagnosticshub.standardcollector.service" disabled
call :SVC "diagsvc" demand
call :SVC "WerSvc" demand
call :SVC "PcaSvc" disabled
call :SVC "TrkWks" disabled
call :SVC "MapsBroker" disabled
call :SVC "lfsvc" disabled
call :SVC "RetailDemo" disabled
call :SVC "Fax" disabled
call :SVC "WMPNetworkSvc" disabled
call :SVC "stisvc" demand
call :SVC "SEMgrSvc" demand
call :SVC "WalletService" demand
call :SVC "WpcMonSvc" demand
call :SVC "wisvc" demand
call :SVC "RemoteRegistry" disabled
call :SVC "gupdate" demand
call :SVC "gupdatem" demand

rem Intel Computing Improvement Program: two services, installed silently with
rem some Intel driver packages, that sample system activity and upload it.
call :SVC "ESRV_SVC_QUEENCREEK" disabled
call :SVC "SystemUsageReportSvc_QUEENCREEK" disabled

rem Browser and vendor auto-updaters run as services from boot. On manual start
rem they still update: their own scheduled tasks start them when needed. Only
rem services currently set to start automatically are changed.
rem Revert: sc config NAME start= auto
if not "%CFG_UPDATERS_MANUAL%"=="1" goto :PH12_UPD_DONE
set "FPS_PS_TITLE=Updater services to manual start"
set "FPS_PS_BODY=$rx='^(edgeupdate|edgeupdatem|GoogleUpdaterService.*|GoogleUpdaterInternalService.*|brave|bravem|AdobeARMservice)$'; $n=0; foreach($s in @(Get-CimInstance Win32_Service | Where-Object { $_.Name -match $rx })){ $n++; $sn=[string]$s.Name; if([string]$s.StartMode -ne 'Auto'){ Report 'SKIP' ($sn+' already starts '+$s.StartMode); continue }; Apply ('Updater service to manual start: '+$sn) { Set-Service -Name $sn -StartupType Manual } }; if(-not $n){ Report 'SKIP' 'No browser or vendor updater services installed' }"
call :PS_RUN
:PH12_UPD_DONE

rem SysMain is only worth removing on solid state storage. This runs after the
rem MMAgent work in phase 4 for the reason noted there.
if "%D_SYSDISK%"=="SSD" (
    call :SVC "SysMain" disabled
    echo        SSD policy requests SysMain disabled. Revert: sc config SysMain start= auto
) else (
    echo    [SKIP] SysMain left running - correct on HDD or unknown media
    set /a CNT_SKIP+=1 >nul
)

rem Windows Search indexing produces periodic disk and CPU bursts that land
rem squarely in the 0.1%% low bucket. Off by default because it costs you
rem Start-menu file search.
if "%CFG_DISABLE_SEARCH%"=="1" (
    call :SVC "WSearch" disabled
    echo        Search policy requests indexing disabled. Revert: sc config WSearch start= delayed-auto
) else (
    echo    [SKIP] Windows Search left enabled - set CFG_DISABLE_SEARCH=1 to remove it
    set /a CNT_SKIP+=1 >nul
)

rem Print Spooler only if there is genuinely nothing to print to.
if "%CFG_DISABLE_SPOOLER%"=="1" (
    if "%D_PRINTERS%"=="0" (
        call :SVC "Spooler" disabled
        echo        no physical printer detected. Revert: sc config Spooler start= auto
    ) else (
        echo    [SKIP] Spooler left running - %D_PRINTERS% printer^(s^) detected
        set /a CNT_SKIP+=1 >nul
    )
)
echo(

:PH13
rem ==========================================================================
rem PHASE 13 - SCHEDULED TASKS AND AUTOMATIC MAINTENANCE
rem ==========================================================================
if not "%CFG_TASKS%"=="1" ( echo  [ PHASE 13 ]  skipped by config & echo( & goto :PH14 )
echo  [ PHASE 13 ]  Scheduled tasks and automatic maintenance
echo  ---------------------------------------------------------------------------
echo        Left alone: ScheduledDefrag ^(issues TRIM on SSDs^), ProactiveScan,
echo        UpdateOrchestrator, Defender scans.

for %%T in (
 "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
 "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
 "\Microsoft\Windows\Application Experience\StartupAppTask"
 "\Microsoft\Windows\Application Experience\PcaPatchDbTask"
 "\Microsoft\Windows\Application Experience\MareBackup"
 "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
 "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
 "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask"
 "\Microsoft\Windows\Autochk\Proxy"
 "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
 "\Microsoft\Windows\Device Information\Device"
 "\Microsoft\Windows\Device Information\Device User"
 "\Microsoft\Windows\Feedback\Siuf\DmClient"
 "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
 "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
 "\Microsoft\Windows\Maintenance\WinSAT"
 "\Microsoft\Windows\PI\Sqm-Tasks"
 "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem"
 "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask"
 "\Microsoft\Windows\Shell\FamilySafetyMonitor"
 "\Microsoft\Windows\Shell\FamilySafetyRefreshTask"
 "\Microsoft\Windows\Retail Demo\CleanupOfflineContent"
 "\Microsoft\Windows\Speech\SpeechModelDownloadTask"
 "\Microsoft\Windows\Application Experience\AitAgent"
 "\Microsoft\Windows\Application Experience\PcaWallpaperAppDetect"
 "\Microsoft\Windows\DiskFootprint\Diagnostics"
 "\Microsoft\Windows\Diagnosis\RecommendedTroubleshootingScanner"
 "\Microsoft\Windows\Diagnosis\Scheduled"
 "\Microsoft\Windows\ErrorDetails\EnableErrorDetailsUpdate"
 "\Microsoft\Windows\ErrorDetails\ErrorDetailsUpdate"
 "\Microsoft\Windows\Flighting\OneSettings\RefreshCache"
 "\Microsoft\Windows\Location\Notifications"
 "\Microsoft\Windows\Location\WindowsActionDialog"
 "\Microsoft\Windows\Maps\MapsToastTask"
 "\Microsoft\Windows\Maps\MapsUpdateTask"
 "\Microsoft\Office\OfficeTelemetryAgentLogOn2016"
 "\Microsoft\Office\OfficeTelemetryAgentFallBack2016"
 "\Microsoft\Office\OfficeTelemetryAgentLogOn"
 "\Microsoft\Office\OfficeTelemetryAgentFallBack"
 "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting"
 "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing"
 "\Microsoft\Windows\Flighting\FeatureConfig\BootstrapUsageDataReporting"
 "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReceiver"
 "\Microsoft\Windows\Sustainability\SustainabilityTelemetry"
 "\Microsoft\Windows\AccountHealth\RecoverabilityToastTask"
 "\Microsoft\Windows\Diagnosis\UnexpectedCodepath"
 "\Microsoft\Windows\Windows Media Sharing\UpdateLibrary"
 "\Microsoft\Windows\Input\LocalUserSyncDataAvailable"
 "\Microsoft\Windows\Input\MouseSyncDataAvailable"
 "\Microsoft\Windows\Input\PenSyncDataAvailable"
 "\Microsoft\Windows\Input\TouchpadSyncDataAvailable"
 "\Microsoft\Windows\Input\InputSettingsRestoreDataAvailable"
) do ( call :TSK %%T )

rem SysMain's own tasks are pointless once phase 12 has disabled SysMain on an
rem SSD, and the indexer's maintenance task once indexing is off.
if "%CFG_SERVICES%"=="1" if "%D_SYSDISK%"=="SSD" (
    call :TSK "\Microsoft\Windows\Sysmain\ResPriStaticDbSync"
    call :TSK "\Microsoft\Windows\Sysmain\WsSwapAssessmentTask"
)
if "%CFG_SERVICES%"=="1" if "%CFG_DISABLE_SEARCH%"=="1" call :TSK "\Microsoft\Windows\Shell\IndexerAutomaticMaintenance"

rem Automatic Maintenance is the single biggest cause of "my framerate
rem collapsed for thirty seconds and I have no idea why". It fires on idle
rem detection, and a menu screen or a loading pause reads as idle.
rem Revert value: 0
if "%CFG_MAINTENANCE_OFF%"=="1" (
    call :RS "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" "MaintenanceDisabled" REG_DWORD "1"
    goto :PH13_MAINT_DONE
)
rem CFG_MAINTENANCE_OFF=0: maintenance keeps running, but only at the set hour.
call :RDEL "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" "MaintenanceDisabled"
set "MHN=3"
set /a MHN=%CFG_MAINTENANCE_HOUR% 2>nul
if %MHN% LSS 0 set "MHN=3"
if %MHN% GTR 23 set "MHN=3"
set "MHP=0%MHN%"
set "MHP=%MHP:~-2%"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\Task Scheduler\Maintenance" "Activation Boundary" REG_SZ "2000-01-01T%MHP%:00:00"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\Task Scheduler\Maintenance" "Randomized" REG_DWORD "1"
call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\Task Scheduler\Maintenance" "Random Delay" REG_SZ "PT1H"
echo        Automatic maintenance moved to %MHP%:00. Revert: delete these three values.
:PH13_MAINT_DONE
echo(

:PH14
rem ==========================================================================
rem PHASE 14 - PER-TITLE PROCESS PRIORITY
rem ==========================================================================
echo  [ PHASE 14 ]  Per-title CPU and I/O priority
echo  ---------------------------------------------------------------------------
if not defined CFG_GAME_EXES (
    echo    [SKIP] no executables listed. Edit CFG_GAME_EXES near the top of this file,
    echo        for example: set "CFG_GAME_EXES=cs2.exe;r5apex.exe;Cyberpunk2077.exe"
    set /a CNT_SKIP+=1 >nul
) else (
    rem Read executable names as data; semicolons separate entries, spaces stay literal.
    set "FPS_PS_TITLE=Per-title CPU, I/O and page priority"
    set "FPS_PS_BODY=foreach($raw in ($env:CFG_GAME_EXES -split ';')){ $g=$raw.Trim(); if($g.Length -ge 2 -and $g[0] -eq [char]34 -and $g[$g.Length-1] -eq [char]34){$g=$g.Substring(1,$g.Length-2)}; if(-not $g){continue}; if($g.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or $g -eq '.' -or $g -eq '..' -or $g.EndsWith('.') -or $g.EndsWith(' ')){ Report 'FAILED' ('Game priority: '+$g) 'Use an executable filename, not a path or invalid Windows filename'; continue }; $keyName='SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\'+$g+'\PerfOptions'; foreach($p in @(@('CpuPriorityClass',3),@('IoPriority',3),@('PagePriority',5))){ Apply ('Game '+$g+': '+$p[0]+' = '+$p[1]) { $key=[Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($keyName); if($null -eq $key){throw 'Cannot create PerfOptions key'}; try{ $key.SetValue([string]$p[0],[int]$p[1],[Microsoft.Win32.RegistryValueKind]::DWord) }finally{ $key.Dispose() } } } }"
    call :PS_RUN
    echo        Revert: delete the matching key under Image File Execution Options.
    if "%D_X3D%"=="2" (
        set "FPS_PS_TITLE=3D V-Cache game preference"
        set "FPS_PS_BODY=Invoke-FpsX3dPrefs"
        call :PS_LIB
    )
)
echo(

rem ==========================================================================
rem PHASE 15 - SECURITY POSTURE REPORT  ^(READ ONLY^)
rem ==========================================================================
echo  [ PHASE 15 ]  Security posture - reported; Memory Integrity only on opt-in
echo  ---------------------------------------------------------------------------
echo        Virtualization Based Security ... %D_VBS%
echo        Memory Integrity / HVCI ......... %D_HVCI%
set "D_HYPTXT=NO"
if "%D_HYPERVISOR%"=="1" set "D_HYPTXT=YES"
echo        Hypervisor running .............. %D_HYPTXT%
if /i not "%D_HVCI%"=="ENABLED" goto :PH15_HVCI_DONE
if "%CFG_HVCI_OFF%"=="1" goto :PH15_HVCI_OPTIN
echo(
echo        Memory Integrity is on. In CPU-bound titles it is usually the
echo        largest single performance variable left on this machine, often
echo        a good deal more than everything this script just changed.
echo        It stays on: turning it off is a real reduction in kernel exploit
echo        resistance, so it is your call, not a default. Microsoft's own
echo        gaming guidance lists it as an option. To take the trade, set
echo        CFG_HVCI_OFF=1 near the top of this file, or use Windows Security,
echo        Device security, Core isolation.
goto :PH15_HVCI_DONE
:PH15_HVCI_OPTIN
rem Opt-in only. This is the same value the Core isolation toggle writes. It is
rem refused when Group Policy or MDM manages Memory Integrity, or when it is
rem UEFI-locked, because Windows would put it straight back. VBS itself,
rem Credential Guard and every other protection stay as they are.
rem Revert: Windows Security, Device security, Core isolation, Memory integrity on.
set "FPS_PS_TITLE=Memory Integrity opt-in"
set "FPS_PS_BODY=$k='HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'; $pol=$null; try{ $pol=(Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard' -Name 'HypervisorEnforcedCodeIntegrity' -ErrorAction Stop).HypervisorEnforcedCodeIntegrity }catch{}; if($null -ne $pol){ Report 'SKIP' 'Memory Integrity is managed by Group Policy or MDM on this PC - change it there'; return }; $cur=Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue; if($cur -and ($cur.Locked -eq 1)){ Report 'SKIP' 'Memory Integrity is UEFI-locked on this PC and cannot be switched off from Windows'; return }; if($cur -and ($null -ne $cur.Enabled) -and ($cur.Enabled -eq 0)){ Report 'SKIP' 'Memory Integrity is already set to off and goes away at the next reboot'; return }; Apply 'Memory Integrity off - HypervisorEnforcedCodeIntegrity Enabled = 0, after a reboot' { if(-not (Test-Path -LiteralPath $k)){ New-Item -Path $k -Force | Out-Null }; Set-ItemProperty -LiteralPath $k -Name 'Enabled' -Value 0 -Type DWord }"
call :PS_RUN
set "REBOOT_REQ=1"
echo        CFG_HVCI_OFF=1: security trade-off accepted in the configuration.
:PH15_HVCI_DONE
echo(
echo        Also intentionally untouched: Defender real-time protection,
echo        SmartScreen, firewall, UAC, LSA protection, and the CPU
echo        speculative-execution mitigations. Disabling mitigations via
echo        FeatureSettingsOverride does buy framerate on older silicon, and
echo        it is still a security downgrade, so it is out of scope here.
echo(

rem Virtual Machine Platform. Microsoft's Windows 11 gaming guidance lists turning
rem it off together with Memory Integrity. Only WSL 2, the Android subsystem and
rem some emulators need it. Opt-in. Revert: Windows Features, Virtual Machine Platform.
if not "%CFG_VMP_OFF%"=="1" goto :PH15_VMP_DONE
set "FPS_PS_TITLE=Virtual Machine Platform opt-in"
set "FPS_PS_BODY=Invoke-FpsVmp"
call :PS_LIB
:PH15_VMP_DONE
echo(

rem ==========================================================================
rem SUMMARY
rem ==========================================================================
echo  ===========================================================================
echo    COMPLETE     applied: %CNT_OK%     failed: %CNT_FAIL%     skipped: %CNT_SKIP%
echo  ===========================================================================
echo(
echo    What to do next
echo    ---------------
echo    1. Reboot. Scheduler, timer, memory-manager, HAGS and MSI changes are
echo       all boot-time reads and do nothing until you do.
echo    2. Benchmark properly or you will not know what worked. Capture
echo       frametimes over a repeatable run and compare 1%% and 0.1%% lows,
echo       not the average. Three runs per configuration, minimum.
echo    3. A/B the two settings this script deliberately did not decide for
echo       you: HAGS on Radeon, and CFG_DISABLE_FSO for older DX9/DX11 titles.
echo    4. Things worth more than any registry value and not scriptable:
echo       resizable BAR, XMP/EXPO memory profile, chipset driver version,
echo       GPU driver version, and shader cache size in your driver panel.
echo    5. Fix every WARNING from the phase 0 platform checks first. A monitor
echo       on the motherboard port, Resizable BAR off, a missing X3D driver or a
echo       hybrid CPU on Windows 10 each outweighs this whole script.
echo    6. The first launch of each game after the reboot may still compile
echo       shaders once. From then on Windows no longer throws that cache away.
echo    7. A 4000-8000 Hz mouse costs CPU time. Compare 1%% lows at 1000-2000 Hz.
echo    8. NVIDIA Shader Cache Size: Driver Default or 10 GB+, never Disabled.
echo(
if "%FPS_DRYRUN%"=="1" (
    echo    DRY RUN: nothing was changed, so no reboot is offered.
    goto :DONE
)
if not "%REBOOT_REQ%"=="1" goto :DONE
"%FPS_BIN%\choice.exe" /C YN /N /T 30 /D N /M "    Reboot now to apply everything?  [Y/N]  "
set "CHOICE_RC=%errorlevel%"
if "%CHOICE_RC%"=="2" goto :DONE
if not "%CHOICE_RC%"=="1" (
    echo    [FAILED] Reboot prompt returned an error or was interrupted. No reboot requested.
    set /a CNT_FAIL+=1 >nul
    goto :DONE
)
echo    [REBOOT] Requesting restart in 5 seconds.
"%FPS_BIN%\shutdown.exe" /r /t 5 /c "FPS Overhaul - applying boot-time changes"
if errorlevel 1 (
    echo    [FAILED] Restart request failed. Reboot manually to apply successful changes.
    set /a CNT_FAIL+=1 >nul
) else (
    echo    [OK] Restart requested.
)

:DONE
echo(
echo    [DONE] Applied: %CNT_OK%   Failed: %CNT_FAIL%   Skipped: %CNT_SKIP%
if "%FPS_DRYRUN%"=="1" echo    DRY RUN - Applied counts what a real run would change.
if not "%CNT_FAIL%"=="0" exit /b 1
exit /b 0

rem ==========================================================================
rem HELPERS
rem ==========================================================================
:RS
rem All callers pass fixed keys / values or the numeric configuration entries.
set "R_KEY=%~1"
set "R_NAME=%~2"
set "R_TYPE=%~3"
set "R_DATA=%~4"
rem Per-user values go to the signed-in user's hive, not the elevating account's.
if /i "%R_KEY:~0,5%"=="HKCU\" call set "R_KEY=%%FPS_UHIVE%%\%%R_KEY:~5%%"
setlocal EnableDelayedExpansion
echo(   [REGISTRY] Setting !R_NAME! to !R_DATA!
echo(       Key: !R_KEY!
endlocal
if "%FPS_DRYRUN%"=="1" goto :RS_WOULD
"%FPS_BIN%\reg.exe" add "%R_KEY%" /v "%R_NAME%" /t "%R_TYPE%" /d "%R_DATA%" /f <nul >nul
set "OP_RC=%errorlevel%"
if not "%OP_RC%"=="0" goto :RS_FAILED
set /a CNT_OK+=1 >nul
setlocal EnableDelayedExpansion
echo(   [OK] !R_NAME! = !R_DATA!
endlocal
exit /b 0
:RS_FAILED
set /a CNT_FAIL+=1 >nul
setlocal EnableDelayedExpansion
echo(   [FAILED] Setting !R_NAME! to !R_DATA!; exit code !OP_RC!.
endlocal
exit /b 0
:RS_WOULD
set /a CNT_OK+=1 >nul
setlocal EnableDelayedExpansion
echo(   [WOULD] !R_NAME! = !R_DATA!
endlocal
exit /b 0

:RSE
rem Self-detecting write: the value is set only where Windows or the vendor
rem already created the key, so an absent component is a skip, never a new key.
set "RSE_KEY=%~1"
set "RSE_NAME=%~2"
if /i "%RSE_KEY:~0,5%"=="HKCU\" call set "RSE_KEY=%%FPS_UHIVE%%\%%RSE_KEY:~5%%"
"%FPS_BIN%\reg.exe" query "%RSE_KEY%" <nul >nul 2>&1
if not errorlevel 1 goto :RSE_PRESENT
set /a CNT_SKIP+=1 >nul
setlocal EnableDelayedExpansion
echo(   [SKIP] !RSE_NAME! not written - key not present on this system:
echo(       !RSE_KEY!
endlocal
exit /b 0
:RSE_PRESENT
call :RS "%~1" "%~2" "%~3" "%~4"
exit /b 0

:RDEL
set "R_KEY=%~1"
set "R_NAME=%~2"
set "FPS_PS_TITLE=Removing an obsolete registry value"
set "FPS_PS_BODY=$path='Registry::'+$env:R_KEY; if($path.StartsWith('Registry::HKLM\')){$path='Registry::HKEY_LOCAL_MACHINE\'+$env:R_KEY.Substring(5)}; if(-not (Test-Path -LiteralPath $path)){Report 'SKIP' ('Registry key absent: '+$env:R_KEY); return}; $key=Get-Item -LiteralPath $path; if($key.GetValueNames() -notcontains $env:R_NAME){Report 'SKIP' ('Registry value already absent: '+$env:R_NAME); return}; Apply ('Removing obsolete registry value: '+$env:R_NAME+' from '+$env:R_KEY) { Remove-ItemProperty -LiteralPath $path -Name $env:R_NAME }"
call :PS_RUN
exit /b 0

:BCD
set "BCD_NAME=%~1"
set "BCD_TEXT=%~2"
echo    [BOOT] Checking BCD %BCD_NAME%.
"%FPS_BIN%\bcdedit.exe" /enum {current} <nul >nul 2>&1
set "OP_RC=%errorlevel%"
if not "%OP_RC%"=="0" goto :BCD_QUERY_FAILED
rem Matched by exact element name at the start of the line, followed by spaces,
rem so a short name such as msi cannot match inside a longer one.
"%FPS_BIN%\bcdedit.exe" /enum {current} <nul 2>nul | "%FPS_BIN%\findstr.exe" /i /r /c:"^%BCD_NAME%  *[^ ]" >nul
if errorlevel 1 (
    echo    [SKIP] BCD %BCD_NAME% already absent.
    set /a CNT_SKIP+=1 >nul
    exit /b 0
)
echo    [BOOT] %BCD_TEXT%.
if "%FPS_DRYRUN%"=="1" goto :BCD_WOULD
"%FPS_BIN%\bcdedit.exe" /deletevalue %BCD_NAME% <nul >nul 2>&1
set "OP_RC=%errorlevel%"
if not "%OP_RC%"=="0" goto :BCD_DELETE_FAILED
set /a CNT_OK+=1 >nul
set "REBOOT_REQ=1"
echo    [OK] Removed BCD %BCD_NAME%.
exit /b 0
:BCD_WOULD
set /a CNT_OK+=1 >nul
echo    [WOULD] Removed BCD %BCD_NAME%.
exit /b 0
:BCD_QUERY_FAILED
if "%FPS_DRYRUN%"=="1" if not "%FPS_ISADMIN%"=="1" goto :BCD_DRY_NOADMIN
set /a CNT_FAIL+=1 >nul
echo    [FAILED] Reading BCD %BCD_NAME%; exit code %OP_RC%. No deletion attempted.
exit /b 0
:BCD_DRY_NOADMIN
set /a CNT_SKIP+=1 >nul
echo    [SKIP] BCD %BCD_NAME%: reading boot settings needs administrator rights - dry run.
exit /b 0
:BCD_DELETE_FAILED
set /a CNT_FAIL+=1 >nul
echo    [FAILED] Removing BCD %BCD_NAME%; exit code %OP_RC%.
exit /b 0

:BCD_MEMORY
echo    [BOOT] Checking BCD memory caps.
"%FPS_BIN%\bcdedit.exe" /enum {current} <nul >nul 2>&1
set "OP_RC=%errorlevel%"
if "%OP_RC%"=="0" goto :BCD_MEMORY_READ
if "%FPS_DRYRUN%"=="1" if not "%FPS_ISADMIN%"=="1" (
    echo    [SKIP] BCD memory caps: reading boot settings needs administrator rights - dry run.
    set /a CNT_SKIP+=1 >nul
    exit /b 0
)
echo    [FAILED] Reading BCD memory caps; exit code %OP_RC%. No deletion attempted.
set /a CNT_FAIL+=1 >nul
exit /b 0
:BCD_MEMORY_READ
"%FPS_BIN%\bcdedit.exe" /enum {current} <nul 2>nul | "%FPS_BIN%\findstr.exe" /i "truncatememory removememory" >nul
if errorlevel 1 (
    echo    [SKIP] BCD memory truncation already absent.
    set /a CNT_SKIP+=1 >nul
    exit /b 0
)
rem Preserve both deletion attempts and their original order when either is found.
call :BCD_MEMORY_DELETE "truncatememory"
call :BCD_MEMORY_DELETE "removememory"
exit /b 0
:BCD_MEMORY_DELETE
echo    [BOOT] Removing BCD %~1.
if "%FPS_DRYRUN%"=="1" (
    echo    [WOULD] Removed BCD %~1.
    set /a CNT_OK+=1 >nul
    exit /b 0
)
"%FPS_BIN%\bcdedit.exe" /deletevalue %~1 <nul >nul 2>&1
set "OP_RC=%errorlevel%"
if not "%OP_RC%"=="0" (
    echo    [FAILED] Removing BCD %~1; exit code %OP_RC%. The value may already be absent.
    set /a CNT_FAIL+=1 >nul
    exit /b 0
)
set "REBOOT_REQ=1"
set /a CNT_OK+=1 >nul
echo    [OK] Removed BCD %~1.
exit /b 0

:SVC
set "SVC_NAME=%~1"
set "SVC_START=%~2"
echo    [SERVICE] Setting %SVC_NAME% start type to %SVC_START%.
"%FPS_BIN%\sc.exe" query "%SVC_NAME%" <nul >nul 2>&1
set "OP_RC=%errorlevel%"
if "%OP_RC%"=="1060" (
    echo    [SKIP] Service %SVC_NAME% is not installed.
    set /a CNT_SKIP+=1 >nul
    exit /b 0
)
if not "%OP_RC%"=="0" (
    echo    [FAILED] Querying service %SVC_NAME%; exit code %OP_RC%.
    set /a CNT_FAIL+=1 >nul
    exit /b 0
)
if "%FPS_DRYRUN%"=="1" goto :SVC_WOULD
"%FPS_BIN%\sc.exe" config "%SVC_NAME%" start= %SVC_START% <nul >nul 2>&1
set "OP_RC=%errorlevel%"
if not "%OP_RC%"=="0" (
    echo    [FAILED] Setting %SVC_NAME% start type to %SVC_START%; exit code %OP_RC%.
    set /a CNT_FAIL+=1 >nul
    exit /b 0
)
set /a CNT_OK+=1 >nul
echo    [OK] %SVC_NAME% start type = %SVC_START%.
echo    [SERVICE] Sending a stop request to %SVC_NAME%.
"%FPS_BIN%\sc.exe" stop "%SVC_NAME%" <nul >nul 2>&1
set "OP_RC=%errorlevel%"
if "%OP_RC%"=="1062" (
    echo    [SKIP] Service %SVC_NAME% is already stopped.
    set /a CNT_SKIP+=1 >nul
    exit /b 0
)
if not "%OP_RC%"=="0" (
    echo    [FAILED] Stopping %SVC_NAME%; exit code %OP_RC%. The start-type change succeeded.
    set /a CNT_FAIL+=1 >nul
    exit /b 0
)
echo    [OK] Stop request accepted for %SVC_NAME%.
set /a CNT_OK+=1 >nul
exit /b 0
:SVC_WOULD
set /a CNT_OK+=1 >nul
echo    [WOULD] %SVC_NAME% start type = %SVC_START%.
exit /b 0

:TSK
set "TASK_NAME=%~1"
echo    [TASK] Disabling scheduled task %TASK_NAME%.
rem A task that is not part of this Windows build is a skip, not a failure.
"%FPS_BIN%\schtasks.exe" /Query /TN "%TASK_NAME%" <nul >nul 2>&1
if errorlevel 1 (
    echo    [SKIP] %TASK_NAME% is not present on this Windows build.
    set /a CNT_SKIP+=1 >nul
    exit /b 0
)
if "%FPS_DRYRUN%"=="1" (
    echo    [WOULD] Disabled %TASK_NAME%.
    set /a CNT_OK+=1 >nul
    exit /b 0
)
"%FPS_BIN%\schtasks.exe" /Change /TN "%TASK_NAME%" /Disable <nul >nul
set "OP_RC=%errorlevel%"
if not "%OP_RC%"=="0" (
    echo    [FAILED] Disabling %TASK_NAME%; exit code %OP_RC%. See the task error above.
    set /a CNT_FAIL+=1 >nul
    exit /b 0
)
echo    [OK] Disabled %TASK_NAME%.
set /a CNT_OK+=1 >nul
exit /b 0

:PS_LIB
rem Runs FPS_PS_BODY with the embedded PowerShell library loaded first. The library
rem is read from this file as data, after the FPS_PS_LIBRARY marker at the end.
set "FPS_PS_USELIB=1"
call :PS_RUN
set "FPS_PS_USELIB="
exit /b 0

:PS_RUN
rem Only the fixed launcher is parsed by CMD. The authored body is read as data.
rem PUSHD gives FOR /F a fixed relative executable, avoiding nested path quoting.
set "FPS_PS_ENDED=0"
if not exist "%FPS_PS%" goto :PS_UNAVAILABLE
pushd "%FPS_BIN%\WindowsPowerShell\v1.0" >nul 2>&1
if errorlevel 1 goto :PS_UNAVAILABLE
for /f "tokens=1,* delims=|" %%A in ('.\powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; . ([scriptblock]::Create($env:FPS_PS_COMMON)); try{ . ([scriptblock]::Create($env:FPS_PS_BODY)) }catch{ Report 'FAILED' $env:FPS_PS_TITLE $_.Exception.Message }; [Console]::WriteLine('END|done')" ^<nul') do (
    set "FPS_PS_STATE=%%A"
    set "FPS_PS_TEXT=%%B"
    call :PS_RECORD
)
popd
if not "%FPS_PS_ENDED%"=="1" (
    echo    [FAILED] PowerShell did not finish: %FPS_PS_TITLE%.
    set /a CNT_FAIL+=1 >nul
)
set "FPS_PS_BODY="
exit /b 0
:PS_UNAVAILABLE
echo    [FAILED] Windows PowerShell is unavailable: %FPS_PS_TITLE%.
set /a CNT_FAIL+=1 >nul
set "FPS_PS_BODY="
exit /b 0

:PS_RECORD
rem FOR captures text with delayed expansion off; expansion below is output-only.
setlocal EnableDelayedExpansion
if "!FPS_PS_STATE!"=="END" goto :PS_RECORD_END
if "!FPS_PS_STATE!"=="DATA" goto :PS_RECORD_DATA
echo(   [!FPS_PS_STATE!] !FPS_PS_TEXT!
if "!FPS_PS_STATE!"=="OK" goto :PS_RECORD_OK
if "!FPS_PS_STATE!"=="WOULD" goto :PS_RECORD_OK
if "!FPS_PS_STATE!"=="FAILED" goto :PS_RECORD_FAILED
if "!FPS_PS_STATE!"=="SKIP" goto :PS_RECORD_SKIP
endlocal
exit /b 0
:PS_RECORD_END
endlocal
set "FPS_PS_ENDED=1"
exit /b 0
:PS_RECORD_OK
endlocal
set /a CNT_OK+=1 >nul
exit /b 0
:PS_RECORD_FAILED
endlocal
set /a CNT_FAIL+=1 >nul
exit /b 0
:PS_RECORD_SKIP
endlocal
set /a CNT_SKIP+=1 >nul
exit /b 0
:PS_RECORD_DATA
rem DATA contains only these generated numeric fields, uppercase enum values and the user SID.
for /f "tokens=1,* delims==" %%C in ("!FPS_PS_TEXT!") do (
    for %%K in (OSBUILD IS_W11 IS_24H2 HAS_PERPROC_TIMER D_RAMGB D_CORES D_THREADS D_CHASSIS D_SYSDISK D_HVCI D_VBS D_PRINTERS GPU_NV GPU_AMD GPU_INTEL CPU_AMD CPU_INTEL FPS_USID D_UBR D_HYBRID D_PCORES D_ECORES D_L3N D_X3D D_SMT D_HYPERVISOR REBOOT_REQ) do (
        if "%%C"=="%%K" (
            endlocal
            set "%%C=%%D"
            exit /b 0
        )
    )
)
endlocal
exit /b 0

rem All batch paths end above. The text below is PowerShell, read as data by :PS_LIB.
:FPS_PS_LIBRARY
function Test-FpsDry { return ($env:FPS_DRYRUN -eq '1') }

# ==========================================================================================
#  FPS modules. Every change goes through Apply, which honours
#  FPS_DRYRUN. Every hardware- or software-dependent step detects its component first.
# ==========================================================================================

# ------------------------------------------------------------------------------------------
#  Shared helpers
# ------------------------------------------------------------------------------------------
# Profile folder of the account signed in at the desktop (FPS_USID), not the elevated one.
function Get-FpsUserProfile {
    if (-not $env:FPS_USID) { return $env:USERPROFILE }
    try {
        $p = [string](Get-ItemProperty -LiteralPath ('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' + $env:FPS_USID) -Name ProfileImagePath -ErrorAction Stop).ProfileImagePath
        if ($p -and (Test-Path -LiteralPath $p)) { return [Environment]::ExpandEnvironmentVariables($p) }
    } catch { }
    return $env:USERPROFILE
}

function Test-FpsProcess ([string[]]$names) {
    foreach ($nm in $names) { if (@(Get-Process -Name $nm -ErrorAction SilentlyContinue).Count -gt 0) { return $true } }
    return $false
}

# Text files are rewritten in the encoding they were read in; a UTF-8 byte order mark is kept
# only if the file had one.
function Read-FpsText ([string]$path) {
    $bytes = [IO.File]::ReadAllBytes($path)
    $bom = ($bytes.Length -ge 3) -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
    $enc = New-Object System.Text.UTF8Encoding($bom)
    $text = $enc.GetString($bytes)
    if ($bom) { $text = $text.Substring(1) }
    return [pscustomobject]@{ Text = $text; Bom = $bom }
}
function Write-FpsText ([string]$path, [string]$text, [bool]$bom) {
    [IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($bom)))
}

# Steam install folder and library folders of the signed-in user.
function Get-FpsSteamRoots {
    $steam = ''
    if ($env:FPS_USID) {
        try { $steam = [string](Get-ItemProperty -LiteralPath ('Registry::HKEY_USERS\' + $env:FPS_USID + '\Software\Valve\Steam') -Name SteamPath -ErrorAction Stop).SteamPath } catch { }
    }
    if (-not $steam) { $steam = ${env:ProgramFiles(x86)} + '\Steam' }
    $steam = $steam.Replace('/', '\')
    $libs = @()
    if (Test-Path -LiteralPath $steam) { $libs += $steam }
    $vdf = $steam + '\steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
        foreach ($ln in @(Get-Content -LiteralPath $vdf -ErrorAction SilentlyContinue)) {
            if ($ln -match '^\s*"path"\s+"(.+)"') { $libs += ($Matches[1] -replace '\\\\', '\') }
        }
    }
    return [pscustomobject]@{ Steam = $steam; Libraries = @($libs | Where-Object { $_ } | Select-Object -Unique) }
}

# ------------------------------------------------------------------------------------------
#  Third-party software that costs frames
# ------------------------------------------------------------------------------------------
function Invoke-FpsThirdParty {
    $prof = Get-FpsUserProfile
    $local = Join-Path $prof 'AppData\Local'
    $roam = Join-Path $prof 'AppData\Roaming'

    # Steam Game Recording "record in background" encodes video the whole time a game runs,
    # like Game DVR: about 6 percent average FPS in CS2. 2 = record on demand keeps the hotkey.
    # Steam rewrites localconfig.vdf when it exits, so the file is only edited while it is closed.
    $sr = Get-FpsSteamRoots
    $cfgs = @()
    if ($sr.Steam -and (Test-Path -LiteralPath ($sr.Steam + '\userdata'))) {
        $cfgs = @(Get-ChildItem -LiteralPath ($sr.Steam + '\userdata') -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'config\localconfig.vdf' } | Where-Object { Test-Path -LiteralPath $_ })
    }
    $bg = @()
    foreach ($c in $cfgs) {
        $f = Read-FpsText $c
        if ($f.Text -match '"BackgroundRecordMode"\s+"1"') { $bg += $c }
    }
    if ($cfgs.Count -eq 0) { Report 'SKIP' 'Steam Game Recording: Steam is not installed for this user' }
    elseif ($bg.Count -eq 0) { Report 'SKIP' 'Steam Game Recording is not recording in the background' }
    elseif (Test-FpsProcess @('steam')) {
        Report 'WARNING' 'Steam Game Recording records in the background, a continuous video encode that costs frames (about 6 percent in CS2). Close Steam and run this script again, or set Steam, Settings, Game Recording to Record on demand'
    } else {
        foreach ($c in $bg) {
            Apply ('Steam Game Recording: background recording to on-demand in ' + (Split-Path (Split-Path (Split-Path $c -Parent) -Parent) -Leaf)) {
                $f = Read-FpsText $c
                $new = [regex]::Replace($f.Text, '("BackgroundRecordMode"\s+)"1"', '$1"2"')
                Write-FpsText $c $new $f.Bom
            }
        }
    }

    # Lively Wallpaper: 0 = pause while a fullscreen app runs (default), 1 = keep rendering.
    $lively = @((Join-Path $local 'Lively Wallpaper\Settings.json'))
    $lively += @(Get-ChildItem -Path (Join-Path $local 'Packages\*LivelyWallpaper*\LocalCache\Local\Lively Wallpaper\Settings.json') -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    foreach ($lf in @($lively | Where-Object { Test-Path -LiteralPath $_ })) {
        $f = Read-FpsText $lf
        if ($f.Text -notmatch '"AppFullscreenPause"\s*:\s*1\b') { Report 'SKIP' 'Lively Wallpaper already pauses behind fullscreen games'; continue }
        if (Test-FpsProcess @('Lively')) { Report 'WARNING' 'Lively Wallpaper keeps rendering behind fullscreen games. In Lively, Settings, Performance, set Fullscreen to Pause'; continue }
        Apply 'Lively Wallpaper: pause while a fullscreen game runs' {
            $f = Read-FpsText $lf
            Write-FpsText $lf ([regex]::Replace($f.Text, '("AppFullscreenPause"\s*:\s*)1\b', '${1}0')) $f.Bom
        }
    }

    # HWiNFO sensor polling faster than once a second: every poll of embedded-controller and
    # SMBus sensors is a burst of DPC time. Only raised to the 2000 ms default while it is closed.
    $hwDirs = @((Join-Path $env:ProgramFiles 'HWiNFO64'))
    foreach ($uk in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HWiNFO64_is1', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\HWiNFO64_is1')) {
        try { $il = [string](Get-ItemProperty -LiteralPath $uk -Name InstallLocation -ErrorAction Stop).InstallLocation; if ($il) { $hwDirs += $il.TrimEnd('\') } } catch { }
    }
    foreach ($hi in @($hwDirs | Select-Object -Unique | ForEach-Object { Join-Path $_ 'HWiNFO64.INI' } | Where-Object { Test-Path -LiteralPath $_ })) {
        $raw = [IO.File]::ReadAllText($hi, [Text.Encoding]::Default)
        $m = [regex]::Match($raw, '(?m)^SensorInterval=(\d+)\s*$')
        if ((-not $m.Success) -or ([int]$m.Groups[1].Value -ge 1000)) { continue }
        if (Test-FpsProcess @('HWiNFO64', 'HWiNFO32')) { Report 'WARNING' ('HWiNFO polls sensors every ' + $m.Groups[1].Value + ' ms - each poll is a burst of driver time that can cause stutter. Set the scan interval to 2000 ms in its sensor settings'); continue }
        Apply ('HWiNFO sensor polling ' + $m.Groups[1].Value + ' ms to 2000 ms') {
            $raw = [IO.File]::ReadAllText($hi, [Text.Encoding]::Default)
            [IO.File]::WriteAllText($hi, [regex]::Replace($raw, '(?m)^SensorInterval=\d+(\s*)$', 'SensorInterval=2000$1'), [Text.Encoding]::Default)
        }
    }

    # Wallpaper Engine: read-only report of its fullscreen playback rule.
    foreach ($lib in $sr.Libraries) {
        $we = Join-Path $lib 'steamapps\common\wallpaper_engine\config.json'
        if (-not (Test-Path -LiteralPath $we)) { continue }
        $f = Read-FpsText $we
        $mm = [regex]::Match($f.Text, '"playbackfullscreen"\s*:\s*"([^"]*)"')
        if ($mm.Success -and ($mm.Groups[1].Value -match '(?i)keep|play|run')) {
            Report 'WARNING' 'Wallpaper Engine keeps playing behind fullscreen games. In Wallpaper Engine, Settings, Performance, set Other application fullscreen to Stop (free memory)'
        } elseif ($mm.Success) {
            Report 'INFO' ('Wallpaper Engine fullscreen rule: ' + $mm.Groups[1].Value + ' - Stop (free memory) also releases its video memory')
        }
        break
    }
}


# ------------------------------------------------------------------------------------------
#  Phase 10 / 12 / 13 helpers
# ------------------------------------------------------------------------------------------
# Windows AI Fabric (24H2/25H2 Copilot+ PCs) can start eight model hosts at boot, about 5 GB.
function Invoke-FpsAiFabric {
    $s = @(Get-CimInstance Win32_Service -Filter "Name='WSAIFabricSvc'" -ErrorAction SilentlyContinue)
    if (-not $s.Count) { Report 'SKIP' 'Windows AI Fabric service not present'; return }
    if ([string]$s[0].StartMode -ne 'Auto') { Report 'SKIP' ('Windows AI Fabric service already starts ' + $s[0].StartMode); return }
    Apply 'Windows AI Fabric service to manual start - AI features start on demand' { Set-Service -Name 'WSAIFabricSvc' -StartupType Manual }
}

# Nahimic (bundled with MSI, ASUS, Dell, Lenovo and other boards and laptops) injects its
# NahimicOSD overlay DLL into games; game developers have listed it as a cause of crashes and
# stutter. Its services and logon tasks are switched off where present. Windows audio itself
# is untouched - only the Nahimic sound effects stop.
function Invoke-FpsNahimic {
    $n = 0
    foreach ($s in @(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object { ([string]$_.Name -match '(?i)^nahimic') -or ([string]$_.PathName -match '(?i)\\nahimic') })) {
        $n++
        $sn = [string]$s.Name
        if ([string]$s.StartMode -eq 'Disabled') { Report 'SKIP' ('Nahimic service already disabled: ' + $sn); continue }
        Apply ('Nahimic service disabled: ' + $sn) {
            Set-Service -Name $sn -StartupType Disabled
            Stop-Service -Name $sn -Force -ErrorAction SilentlyContinue
        }
    }
    foreach ($t in @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { [string]$_.TaskName -match '(?i)nahimic' })) {
        $n++
        if ([string]$t.State -eq 'Disabled') { continue }
        $tn = [string]$t.TaskName; $tp = [string]$t.TaskPath
        Apply ('Nahimic logon task disabled: ' + $tp + $tn) { Disable-ScheduledTask -TaskName $tn -TaskPath $tp | Out-Null }
    }
    if (-not $n) { Report 'SKIP' 'Nahimic is not installed' }
}

# Virtual Machine Platform: Microsoft's own gaming guidance for Windows 11 lists turning it off
# together with Memory Integrity. It is needed only by WSL 2, the Android subsystem and some
# emulators. Opt-in; takes effect after the reboot.
function Invoke-FpsVmp {
    $f = $null
    try { $f = Get-WindowsOptionalFeature -Online -FeatureName 'VirtualMachinePlatform' -ErrorAction Stop } catch { Report 'SKIP' 'Virtual Machine Platform state could not be read'; return }
    if (-not $f) { Report 'SKIP' 'Virtual Machine Platform is not part of this Windows edition'; return }
    if ([string]$f.State -ne 'Enabled') { Report 'SKIP' ('Virtual Machine Platform already ' + $f.State); return }
    Apply 'Virtual Machine Platform off - active after the reboot' { Disable-WindowsOptionalFeature -Online -FeatureName 'VirtualMachinePlatform' -NoRestart -WarningAction SilentlyContinue | Out-Null }
    if (-not (Test-FpsDry)) { Write-FpsData 'REBOOT_REQ' 1 }
}

# Dual-CCD 3D V-Cache Ryzen: games in CFG_GAME_EXES that Game Bar does not recognise are
# added to the AMD 3D V-Cache driver's own preference list, so they run on the cache CCD.
function Invoke-FpsX3dPrefs {
    $list = @()
    foreach ($raw in ([string]$env:CFG_GAME_EXES -split ';')) {
        $g = $raw.Trim().Trim([char]34)
        if ((-not $g) -or ($g.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0)) { continue }
        $list += $g
    }
    if (-not $list.Count) { return }
    $pref = 'HKLM:\SYSTEM\CurrentControlSet\Services\amd3dvcache\Preferences'
    if (-not (Test-Path -LiteralPath $pref)) { Report 'SKIP' 'AMD 3D V-Cache driver preferences not present - install the AMD chipset driver'; return }
    $known = @{}
    foreach ($k in @(Get-ChildItem -LiteralPath (Join-Path $pref 'App') -ErrorAction SilentlyContinue)) {
        $e = [string]$k.GetValue('EndsWith')
        if ($e) { $known[$e.ToLowerInvariant()] = $true }
    }
    foreach ($g in $list) {
        if ($known.ContainsKey($g.ToLowerInvariant())) { Report 'SKIP' ($g + ' already has a 3D V-Cache preference'); continue }
        $gn = $g
        Apply ('3D V-Cache: ' + $gn + ' runs on the cache CCD') {
            $kp = Join-Path $pref ('App\FPS_' + $gn)
            if (-not (Test-Path -LiteralPath $kp)) { New-Item -Path $kp -Force | Out-Null }
            New-ItemProperty -LiteralPath $kp -Name 'EndsWith' -Value $gn -PropertyType String -Force | Out-Null
            New-ItemProperty -LiteralPath $kp -Name 'Type' -Value 1 -PropertyType DWord -Force | Out-Null
        }
    }
}
