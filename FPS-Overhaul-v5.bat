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
rem  v5 against v4:
rem    * embedded PowerShell library: CPU clock / boost caps and throttling, AMD PPM
rem      and Intel APO/DTT drivers, Arrow Lake build and microcode, Resizable BAR and
rem      PCIe link on AMD and Intel cards, HAGS support read from the driver, video
rem      memory in use at the desktop, memory pressure and commit, RAM optimizers,
rem      games on hard disks or USB, drive health, BypassIO, compressed game folders,
rem      DPC / interrupt load, shared IRQs, overlays and background recorders,
rem      background CPU / disk / GPU hogs, shader cache integrity, audio mix rate
rem    * more tweak-pack leftovers reversed: dynamic tick, memory caps, pool sizes,
rem      DPC kernel values, raw-mouse throttle off, system-process priority
rem      overrides, TDR off, GPU preemption off, HungApp / AutoEndTasks values
rem    * HAGS only where the NVIDIA driver reports support; MPO opt-in also covers
rem      24H2; SysMain off only on SSD with 32 GB or more; power throttling off only
rem      on non-hybrid desktops; global timer resolution only on Windows 11
rem    * Steam background recording, Lively fullscreen pause and HWiNFO fast polling
rem      fixed when those apps are closed; X3D per-game cache preference
rem    * removed as unproven or harmful: MMCSS task values Windows ignores,
rem      NoLazyMode, IoPriority / PagePriority keys, undocumented GPU
rem      DevicePriority, forced shutdown timeouts
rem    * automatic maintenance moved to 3 AM instead of disabled; nag and
rem      cross-device background features off
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
rem auto = SysMain off only on an SSD system drive with 32 GB RAM or more
set "CFG_SYSMAIN_OFF=auto"
rem 1 = turn a deleted pagefile back on ^(system managed^)
set "CFG_PAGEFILE_RESTORE=1"
rem auto = power throttling off only on desktops without hybrid P/E cores
set "CFG_POWER_THROTTLING_OFF=auto"
rem Phone Link / cross-device resume background features off
set "CFG_CROSSDEVICE_OFF=1"
rem Steam, Lively, HWiNFO settings that cost frames ^(only while those apps are closed^)
set "CFG_THIRDPARTY=1"
rem 1 = disable automatic maintenance entirely; 0 = move it to CFG_MAINTENANCE_HOUR
set "CFG_MAINTENANCE_OFF=0"
set "CFG_MAINTENANCE_HOUR=3"
rem 1 = Memory Integrity ^(HVCI^) off. Security trade-off, see phase 15. Default 0.
set "CFG_HVCI_OFF=0"
rem scheduled task / automatic maintenance
set "CFG_TASKS=1"
rem 38 = 0x26. Windows client default = 2
set "CFG_PRIORITY_SEPARATION=38"
rem Windows client default = 20
set "CFG_SYSTEM_RESPONSIVENESS=10"
rem  Semicolon separated game executables to High CPU priority ^(and the 3D V-Cache
rem  CCD on dual-CCD X3D Ryzen^).
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
set "D_HAGSOK=-1"
set "FPS_USID="
set "FPS_PS_TITLE=Windows version detection"
set "FPS_PS_BODY=$b=0; $ubr=0; $name='unknown'; $rel='n/a'; try{ $o=Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'; [void][int]::TryParse([string]$o.CurrentBuildNumber,[ref]$b); if($b -lt 0){$b=0}; [void][int]::TryParse([string]$o.UBR,[ref]$ubr); if($ubr -lt 0){$ubr=0}; if($o.ProductName){$name=[string]$o.ProductName}; if($o.DisplayVersion){$rel=[string]$o.DisplayVersion} }catch{ Report 'FAILED' 'Reading Windows version' $_.Exception.Message }; Write-FpsData 'OSBUILD' $b; Write-FpsData 'D_UBR' $ubr; Write-FpsData 'IS_W11' ([int]($b -ge 22000)); Write-FpsData 'IS_24H2' ([int]($b -ge 26100)); Write-FpsData 'HAS_PERPROC_TIMER' ([int]($b -ge 19041)); Report 'INFO' ('OS: '+$name+'; build '+$b+'.'+$ubr+' ('+$rel+')')"
call :PS_RUN
set "FPS_PS_TITLE=CPU, memory and GPU detection"
set "FPS_PS_BODY=$ram=0; $cores=0; [void][int]::TryParse($env:NUMBER_OF_PROCESSORS,[ref]$cores); if($cores -lt 0){$cores=0}; $threads=$cores; $cpu='unknown'; $gpu='unknown'; $chassis='DESKTOP'; try{ $cs=@(Get-CimInstance Win32_ComputerSystem)[0]; if($null -eq $cs){throw 'No computer-system data returned'}; $ram=[math]::Round($cs.TotalPhysicalMemory / 1GB); try{ $pm=[double](@(Get-CimInstance Win32_PhysicalMemory) | Measure-Object -Property Capacity -Sum).Sum; if($pm -gt 0){ $ram=[math]::Round($pm/1GB) } }catch{} }catch{ Report 'FAILED' 'Reading installed memory' $_.Exception.Message }; $cman=''; try{ $c=@(Get-CimInstance Win32_Processor)[0]; if($null -eq $c){throw 'No processor data returned'}; $cpu=([string]$c.Name).Trim(); $cman=[string]$c.Manufacturer; $cores=[int]$c.NumberOfCores; $threads=[int]$c.NumberOfLogicalProcessors }catch{ Report 'FAILED' 'Reading processor data' $_.Exception.Message }; try{ $g=@(Get-CimInstance Win32_VideoController); if($g.Count){$gpu=$g.Name -join ' + '} }catch{ Report 'FAILED' 'Reading display adapters' $_.Exception.Message }; try{ if(@(Get-CimInstance Win32_Battery).Count -gt 0){$chassis='LAPTOP'} }catch{ Report 'FAILED' 'Reading battery / form factor' $_.Exception.Message }; Write-FpsData 'D_RAMGB' $ram; Write-FpsData 'D_CORES' $cores; Write-FpsData 'D_THREADS' $threads; Write-FpsData 'D_CHASSIS' $chassis; Write-FpsData 'GPU_NV' ([int]($gpu -match 'nvidia|geforce|rtx|gtx')); Write-FpsData 'GPU_AMD' ([int]($gpu -match 'amd|radeon')); Write-FpsData 'GPU_INTEL' ([int]($gpu -match 'Intel|\bArc\b|Iris|UHD')); $ca=($cman -eq 'AuthenticAMD') -or ((-not $cman) -and ($cpu -match 'amd|ryzen|threadripper|epyc')); $ci=($cman -eq 'GenuineIntel') -or ((-not $cman) -and ($cpu -match 'intel|xeon')); Write-FpsData 'CPU_AMD' ([int]$ca); Write-FpsData 'CPU_INTEL' ([int]$ci); Report 'INFO' ('CPU: '+$cpu); Report 'INFO' ('Topology: '+$cores+' cores / '+$threads+' threads'); Report 'INFO' ('Memory: '+$ram+' GB'); Report 'INFO' ('GPU: '+$gpu); Report 'INFO' ('Form factor: '+$chassis)"
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
set "DO_SYSMAIN_OFF=0"
if "%D_SYSDISK%"=="SSD" if /i "%CFG_SYSMAIN_OFF%"=="1" set "DO_SYSMAIN_OFF=1"
if "%D_SYSDISK%"=="SSD" if /i "%CFG_SYSMAIN_OFF%"=="auto" if %D_RAMGB% GEQ 32 set "DO_SYSMAIN_OFF=1"
echo(

rem ================================================================ BOTTLENECKS
rem Read only. These are the limits no registry value can lift, reported first
rem because each is usually worth more FPS than everything below combined.
echo  [ PHASE 0b ]  FPS bottleneck check - read only
echo  ---------------------------------------------------------------------------
set "FPS_PS_TITLE=FPS bottleneck check"
set "FPS_PS_BODY=$warn=0; try{ Add-Type -AssemblyName System.Windows.Forms; $pw=[System.Windows.Forms.SystemInformation]::PowerStatus; if([string]$pw.BatteryChargeStatus -notmatch 'NoSystemBattery'){ if([string]$pw.PowerLineStatus -eq 'Offline'){ Report 'WARNING' 'Running on battery - Windows and the firmware cut CPU and GPU clocks. Plug in to game.'; $warn++ }else{ Report 'INFO' 'Power source: plugged in' } } }catch{}; try{ $ap=[string](Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name 'ActivePowerScheme' -ErrorAction SilentlyContinue).ActivePowerScheme; if($ap -and ($ap -ne '381b4222-f694-41f0-9685-ff5bb260df2e')){ if($ap -eq 'a1841308-3541-4fab-bc81-f71556f20b4a'){ Report 'WARNING' 'Active power plan: Power saver. It caps CPU clocks. This script never changes power settings.'; $warn++ }else{ Report 'INFO' ('Active power plan: '+$ap+' (not Balanced, so the power mode slider does not apply)') }; throw 'skip-overlay' }; $ov=[string](Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name 'ActiveOverlayAcPowerScheme' -ErrorAction SilentlyContinue).ActiveOverlayAcPowerScheme; $mode='Balanced'; if($ov -eq 'ded574b5-45a0-4f42-8737-46345c09c238'){$mode='Best performance'} elseif($ov -eq '961cc777-2547-4f9d-8174-7d86181b8a7a'){$mode='Best power efficiency'}; if($mode -eq 'Best performance'){ Report 'INFO' 'Windows power mode when plugged in: Best performance' }else{ Report 'WARNING' ('Windows power mode when plugged in: '+$mode+'. Settings, System, Power, Power mode: Best performance holds higher sustained CPU and GPU clocks. This script never changes power settings.'); $warn++ } }catch{}; try{ $mods=@(Get-CimInstance Win32_PhysicalMemory); if($mods.Count){ $rated=[int](($mods | Measure-Object -Property Speed -Maximum).Maximum); $conf=[int](($mods | Measure-Object -Property ConfiguredClockSpeed -Minimum).Minimum); $gb=[math]::Round((($mods | Measure-Object -Property Capacity -Sum).Sum)/1GB); Report 'INFO' ('Memory: '+$mods.Count+' module(s), '+$gb+' GB, running '+$conf+' MT/s, rated '+$rated+' MT/s'); if($mods.Count -eq 1){ Report 'WARNING' 'Only one memory module is reported. Single-channel memory halves bandwidth, which costs integrated graphics a large share of its FPS and lowers CPU-bound 1 percent lows; a second matching module enables dual channel. Some laptops with soldered memory report one module while running dual channel.'; $warn++ }; if(($rated -gt 0) -and ($conf -gt 0) -and ($conf -lt ($rated*0.9)) -and ($env:D_CHASSIS -ne 'LAPTOP')){ Report 'WARNING' ('Memory runs at '+$conf+' MT/s but is rated '+$rated+' MT/s. Enable XMP or EXPO in the BIOS.'); $warn++ } } }catch{}; try{ foreach($v in @(Get-CimInstance Win32_VideoController)){ if(-not $v.DriverDate){continue}; $dd=[datetime]$v.DriverDate; $age=((Get-Date)-$dd).Days; Report 'INFO' ('Graphics driver: '+$v.Name+' '+$v.DriverVersion+', dated '+$dd.ToString('yyyy-MM-dd')); if($age -gt 548){ Report 'WARNING' ($v.Name+' driver is '+[math]::Round($age/30)+' months old. New graphics drivers regularly bring game-specific FPS fixes; update from the GPU maker.'); $warn++ } } }catch{}; try{ $bg=@(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(wallpaper32|wallpaper64|webwallpaper32|Lively|Lively\.PlayerWebView2|Deskscapes)$' } | ForEach-Object { $_.ProcessName } | Select-Object -Unique); if($bg.Count){ Report 'WARNING' ('Animated wallpaper running ('+($bg -join ', ')+'): it keeps rendering behind games and takes GPU time, most of all on integrated graphics. Set it to pause whenever another app is fullscreen or maximized.'); $warn++ } }catch{}; if(-not $warn){ Report 'INFO' 'No power, memory, driver or background-rendering bottleneck found' }"
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
set "FPS_PS_BODY=$warn=0; $cpu=''; try{ $cpu=([string]@(Get-CimInstance Win32_Processor)[0].Name).Trim() }catch{}; $b=[int]$env:OSBUILD; $ubr=[int]$env:D_UBR; if($env:D_HYBRID -eq '1'){ if($b -lt 22000){ Report 'WARNING' ('Hybrid CPU ('+$env:D_PCORES+' performance + '+$env:D_ECORES+' efficiency cores) on Windows 10. Windows 10 has no Thread Director support, so game threads regularly land on efficiency cores and 1 percent lows suffer. Windows 11 schedules this CPU correctly.'); $warn++ }else{ Report 'INFO' 'Hybrid CPU on Windows 11 - Thread Director scheduling available' } }; if($env:D_X3D -eq '2'){ $drv=@(); try{ $drv=@(Get-CimInstance Win32_SystemDriver | Where-Object { $_.Name -like '*3dvcache*' }) + @(Get-CimInstance Win32_Service | Where-Object { $_.Name -like '*3dvcache*' }) }catch{}; if($drv.Count){ Report 'INFO' ('AMD 3D V-Cache Performance Optimizer present: '+(@($drv | ForEach-Object { [string]$_.Name+' '+[string]$_.State }) -join ', ')) }else{ Report 'WARNING' 'Dual-CCD 3D V-Cache CPU without the AMD 3D V-Cache Performance Optimizer driver. Install the current AMD chipset driver, or games can be scheduled on the CCD without the extra cache. CPPC and CPPC Preferred Cores must also be enabled in the BIOS.'; $warn++ }; $gb=$null; try{ $gb=@(Get-AppxPackage -AllUsers -Name 'Microsoft.XboxGamingOverlay' -ErrorAction Stop) }catch{ try{ $gb=@(Get-AppxPackage -Name 'Microsoft.XboxGamingOverlay' -ErrorAction Stop) }catch{} }; if(($null -ne $gb) -and ($gb.Count -eq 0)){ Report 'WARNING' 'Xbox Game Bar is not installed. AMD CCD parking on dual-CCD 3D V-Cache CPUs relies on Game Bar recognising the game; reinstall Xbox Game Bar from the Microsoft Store.'; $warn++ }; try{ $ap=[string](Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name 'ActivePowerScheme' -ErrorAction Stop).ActivePowerScheme; if($ap -and ($ap -ne '381b4222-f694-41f0-9685-ff5bb260df2e')){ Report 'WARNING' 'The active power plan is not Balanced. AMD CCD parking on dual-CCD 3D V-Cache CPUs only works under the Balanced plan; High and Ultimate Performance keep both CCDs awake. This script never changes power plans.'; $warn++ } }catch{} }; if(($env:CPU_AMD -eq '1') -and ($cpu -match 'Ryzen')){ $fixed=($b -ge 26100) -or ((($b -eq 22621) -or ($b -eq 22631)) -and ($ubr -ge 4112)); if(-not $fixed){ if($b -lt 22000){ Report 'WARNING' 'Ryzen on Windows 10: the branch-prediction scheduling optimization AMD and Microsoft shipped in 2024 for Zen 3, Zen 4 and Zen 5 exists only for Windows 11 (24H2, or 23H2 with KB5041587). The measured gains are in CPU-bound games.' }else{ Report 'WARNING' ('Ryzen on build '+$b+'.'+$ubr+': update Windows to 24H2, or to 23H2 build 22631.4112 or later (KB5041587), which carries the AMD branch-prediction optimization for Zen 3, Zen 4 and Zen 5.') }; $warn++ }else{ Report 'INFO' ('Ryzen branch-prediction optimization included in build '+$b+'.'+$ubr) } }; if(($env:D_HYPERVISOR -eq '1') -and ($env:D_VBS -ne 'RUNNING')){ Report 'INFO' 'A hypervisor is running (Hyper-V, WSL 2, Virtual Machine Platform or Windows Sandbox). Windows then runs beside it, which costs a few percent in some CPU-bound games. Left untouched.' }; if(-not $warn){ Report 'INFO' 'No CPU scheduling problem found' }"
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
set "FPS_PS_BODY=try{ $sus=[ordered]@{ 'ASUS Armoury Crate / Aura'='^(ArmouryCrate|ArmouryCrate\.Service|ArmourySocketServer|LightingService|AacAmbientLighting)$'; 'Corsair iCUE'='^(iCUE|Corsair\.Service|CorsairDeviceControlService)$'; 'NZXT CAM'='^NZXT CAM$'; 'SignalRGB'='^SignalRgb$'; 'Razer Synapse'='^(RazerCentralService|Razer Synapse Service|Razer Synapse Service Process)$'; 'MSI Center'='^(MSI\.CentralServer|MSI_Central_Service)$'; 'HWiNFO sensor polling'='^HWiNFO(64|32)$'; 'AIDA64 sensor polling'='^aida64$'; 'Lian Li L-Connect 3'='^L-Connect 3$'; 'Logitech G HUB'='^(lghub|lghub_agent|lghub_system_tray)$'; 'SteelSeries GG'='^(SteelSeriesGG|SteelSeriesEngine)$'; 'Razer Synapse 4'='^RazerAppEngine$'; 'Gigabyte Control Center / RGB Fusion'='^(GCC|RGBFusion)$'; 'OpenRGB'='^OpenRGB$'; 'MSI Mystic Light'='^MysticLight' }; $pn=@(Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $_.ProcessName } | Select-Object -Unique); $run=@(); foreach($nm in $sus.Keys){ $rx=$sus[$nm]; if(@($pn | Where-Object { $_ -match $rx }).Count){ $run+=$nm } }; if($run.Count){ Report 'WARNING' ('Running: '+($run -join ', ')+'. RGB and sensor suites poll hardware on a timer and are a recurring cause of periodic stutter and DPC latency spikes. If you see regular hitches, test once with them fully closed.') }else{ Report 'INFO' 'No RGB or sensor-polling suite running' } }catch{}; try{ $ent=@(); $srcs=@(@('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'),@('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32')); if($env:FPS_USID){ $ur='Registry::HKEY_USERS\'+$env:FPS_USID+'\Software\Microsoft\Windows\CurrentVersion\'; $srcs+=,@(($ur+'Run'),($ur+'Explorer\StartupApproved\Run')) }; foreach($pair in $srcs){ if(-not (Test-Path -LiteralPath $pair[0])){ continue }; $rk=Get-Item -LiteralPath $pair[0]; $ak=$null; if(Test-Path -LiteralPath $pair[1]){ $ak=Get-Item -LiteralPath $pair[1] }; foreach($vn in @($rk.GetValueNames() | Where-Object { $_ })){ $on=$true; if($ak){ $bytes=$ak.GetValue($vn); if(($bytes -is [byte[]]) -and $bytes.Length -and ($bytes[0] -band 1)){ $on=$false } }; if($on){ $ent+=$vn } } }; if($ent.Count){ Report 'INFO' ('Startup programs enabled: '+$ent.Count+' - '+(@($ent | Select-Object -Unique -First 12) -join ', ')+'. Each keeps running beside your games; disable the ones you do not need in Task Manager, Startup apps.') }else{ Report 'INFO' 'No startup programs enabled in the Run keys' } }catch{}"
call :PS_RUN
set "FPS_PS_TITLE=CPU clocks and platform drivers"
set "FPS_PS_BODY=Test-FpsCpuClocks; Invoke-FpsCpuPlatform"
call :PS_LIB
set "FPS_PS_TITLE=Graphics card platform"
set "FPS_PS_BODY=Invoke-FpsGpuPlatform; Test-FpsVramHeadroom"
call :PS_LIB
set "FPS_PS_TITLE=Memory"
set "FPS_PS_BODY=Test-FpsMemoryPressure; Invoke-FpsRamOptimizerCheck"
call :PS_LIB
set "FPS_PS_TITLE=Storage and game libraries"
set "FPS_PS_BODY=Test-FpsGameStorage; Invoke-FpsStorageCheck"
call :PS_LIB
set "FPS_PS_TITLE=Driver interrupts and DPCs"
set "FPS_PS_BODY=Invoke-FpsDpcCheck"
call :PS_LIB
set "FPS_PS_TITLE=Background load, overlays and audio"
set "FPS_PS_BODY=Test-FpsBackgroundLoad; Test-FpsOverlays; Invoke-FpsAudioCheck"
call :PS_LIB
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
rem disabledynamictick keeps the timer ticking on idle cores; no frametime gain
rem is measured on current builds and it raises power and heat.
call :BCD "disabledynamictick" "Removing the disabledynamictick override"
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
call :BCD "truncatememory" "Removing the truncatememory memory cap"
call :BCD "removememory" "Removing the removememory memory cap"

rem IoPageLockLimit has been ignored by the memory manager since XP.
call :RDEL "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "IoPageLockLimit"
rem LargeSystemCache=1 starves application working sets on a client OS.
call :RS "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" REG_DWORD "0"
rem DpcWatchdogProfileOffset belongs to the DPC watchdog. It does not move DPCs
rem off CPU 0 as tweak lists claim, and no benchmark shows it changing DPC
rem latency. v1 of this script set it; the value is removed again.
call :RDEL "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "DpcWatchdogProfileOffset"
rem Undocumented or obsolete DPC and timer values from tweak packs. None has a
rem reproducible benchmark; several change how the kernel batches DPCs.
for %%V in (ThreadDpcEnable SerializeTimerExpiration EnablePerCpuClockTickScheduling ForceForegroundBoostDecay DpcQueueDepth MinimumDpcRate IdealDpcRate AdjustDpcThreshold) do (
    call :RDEL "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "%%V"
)
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
set "FPS_PS_TITLE=Leftovers from tweak packs"
set "FPS_PS_BODY=Invoke-FpsMemoryLeftovers; Invoke-FpsInputLeftovers; Invoke-FpsShellLeftovers; Invoke-FpsSystemIfeoLeftovers; Invoke-FpsGpuLeftovers"
call :PS_LIB
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
if "%IS_W11%"=="1" (
    call :RS "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "GlobalTimerResolutionRequests" REG_DWORD "1"
    set "REBOOT_REQ=1"
) else (
    echo    [SKIP] GlobalTimerResolutionRequests is read only by Windows 11 - build %OSBUILD%
    set /a CNT_SKIP+=1 >nul
)

rem Power throttling / EcoQoS lets the scheduler demote threads it believes
rem are background work. Engine worker and audio threads are regularly
rem misclassified, producing periodic frametime spikes. Registry-only, no
rem power plan is touched. Revert value: 0 or delete the value.
rem Hybrid P/E-core CPUs rely on these hints to keep background work off the
rem performance cores, so it is only switched off on non-hybrid desktops.
set "DO_PT=0"
if "%CFG_POWER_THROTTLING_OFF%"=="1" set "DO_PT=1"
if /i "%CFG_POWER_THROTTLING_OFF%"=="auto" if "%D_HYBRID%"=="0" if not "%D_CHASSIS%"=="LAPTOP" set "DO_PT=1"
if "%DO_PT%"=="1" (
    call :RS "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" REG_DWORD "1"
) else (
    call :RDEL "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff"
)

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

rem The "Games" MMCSS task is what a title joins when it calls
rem AvSetMmThreadCharacteristics. Scheduling Category High gives those threads
rem the MMCSS real-time priority band. Microsoft documents GPU Priority,
rem Affinity, Background Only and SFIO Priority as unused, so they are not written.
set "MMTASK=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
call :RS "%MMTASK%" "Scheduling Category" REG_SZ "High"

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

rem Prefetcher / SysMain. On an SSD the superfetch prefetch passes cost more
rem in background CPU and random I/O than the launch-time saving is worth,
rem and those passes are exactly what fires during a loading screen. On an
rem HDD the opposite is true, so this is left fully enabled there.
rem v5: prefetch is only switched off together with SysMain ^(SSD and 32 GB+^).
if "%DO_SYSMAIN_OFF%"=="1" (
    call :RS "%MM%\PrefetchParameters" "EnablePrefetcher" REG_DWORD "0"
    call :RS "%MM%\PrefetchParameters" "EnableSuperfetch" REG_DWORD "0"
    echo        SSD with 32 GB+: both prefetcher values = 0. Revert value for both: 3
) else if "%D_SYSDISK%"=="SSD" (
    call :RS "%MM%\PrefetchParameters" "EnablePrefetcher" REG_DWORD "3"
    call :RS "%MM%\PrefetchParameters" "EnableSuperfetch" REG_DWORD "3"
    echo        SSD below 32 GB: prefetcher back to the Windows default 3.
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
rem keeps the normal heap. Programs already shimmed are listed. Takes effect at
rem the next program start. Revert value: 1
if not "%CFG_FTH_OFF%"=="1" goto :PH4_FTH_DONE
set "FPS_PS_TITLE=Fault Tolerant Heap"
set "FPS_PS_BODY=$k='HKLM:\SOFTWARE\Microsoft\FTH'; if(-not (Test-Path -LiteralPath $k)){ Report 'SKIP' 'Fault Tolerant Heap is not present on this build'; return }; $shim=@(); if(Test-Path -LiteralPath ($k+'\State')){ $shim=@((Get-Item -LiteralPath ($k+'\State')).GetValueNames() | Where-Object { $_ }) }; if($shim.Count){ Report 'INFO' ('Programs already running with FTH heap mitigations: '+(@($shim | Select-Object -First 8 | ForEach-Object { [IO.Path]::GetFileName($_) }) -join ', ')) }; $cur=(Get-ItemProperty -LiteralPath $k -Name 'Enabled' -ErrorAction SilentlyContinue).Enabled; if(($cur -eq 0) -and (-not $shim.Count)){ Report 'SKIP' 'Fault Tolerant Heap already off'; return }; if($cur -eq 0){ Apply 'Clearing existing FTH heap shims' { & ($env:SystemRoot+'\System32\rundll32.exe') 'fthsvc.dll,FthSysprepSpecialize' }; return }; Apply 'Turning Fault Tolerant Heap off - Enabled = 0' { Set-ItemProperty -LiteralPath $k -Name 'Enabled' -Value 0 -Type DWord }; if($shim.Count){ Apply 'Clearing existing FTH heap shims' { & ($env:SystemRoot+'\System32\rundll32.exe') 'fthsvc.dll,FthSysprepSpecialize' }; Write-FpsData 'REBOOT_REQ' 1 }"
call :PS_RUN
:PH4_FTH_DONE

rem Pagefile. A deleted or undersized pagefile makes games that commit more
rem memory stall or crash; a system-managed one is restored when none is active.
set "FPS_PS_TITLE=Pagefile and memory commit"
set "FPS_PS_BODY=Invoke-FpsPagefile"
call :PS_LIB

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
rem Windows 10 and 11 print an NTFS line and then a ReFS line, so the NTFS line is
rem found by name; older builds print a single line, which is used instead.
set "FPS_PS_TITLE=TRIM status"
set "FPS_PS_BODY=$old=$ErrorActionPreference; $ErrorActionPreference='Continue'; $lines=@(& ($env:FPS_BIN+'\fsutil.exe') behavior query DisableDeleteNotify 2>&1); $rc=$LASTEXITCODE; $ErrorActionPreference=$old; if($rc -ne 0){ if($env:FPS_DRYRUN -eq '1'){ Report 'SKIP' 'TRIM query needs administrator rights (dry run)' }else{ Report 'FAILED' 'Querying TRIM / DisableDeleteNotify' ('exit code '+$rc) }; return }; $hit=''; $first=''; foreach($line in $lines){ $t=([string]$line).Trim(); if(-not $t){ continue }; if(-not $first){ $first=$t }; if((-not $hit) -and ($t -match '(?i)^NTFS\s+DisableDeleteNotify')){ $hit=$t } }; if(-not $first){ Report 'FAILED' 'Querying TRIM / DisableDeleteNotify' 'No query output returned'; return }; if(-not $hit){ $hit=$first }; if($hit -match 'DisableDeleteNotify\s*=\s*1'){ if($env:D_SYSDISK -eq 'SSD'){ if($env:FPS_DRYRUN -eq '1'){ Report 'WOULD' 'Re-enabling TRIM - DisableDeleteNotify = 0'; return }; Report 'APPLY' 'Re-enabling TRIM - DisableDeleteNotify = 0'; $ErrorActionPreference='Continue'; $result=@(& ($env:FPS_BIN+'\fsutil.exe') behavior set DisableDeleteNotify 0 2>&1); $rc=$LASTEXITCODE; $ErrorActionPreference=$old; if($rc -eq 0){Report 'OK' 'TRIM re-enabled'}else{Report 'FAILED' 'Re-enabling TRIM' ('exit code '+$rc)} }else{ Report 'SKIP' 'TRIM change requires a detected SSD' } }else{ Report 'SKIP' 'TRIM query did not report = 1; left unchanged' }"
call :PS_RUN

rem Cap NTFS paged-pool growth behaviour at the default. Explicitly reset if a
rem previous tool set NtfsMemoryUsage=2, which starves other paged pool users.
call :RDEL "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" "NtfsMemoryUsage"
set "FPS_PS_TITLE=Scheduled drive optimization"
set "FPS_PS_BODY=Invoke-FpsDefragTask"
call :PS_LIB
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
rem v5: written only on NVIDIA when the driver reports support ^(DLSS frame
rem generation needs it^); every other GPU keeps its current setting.
set "DO_HAGS=0"
if "%GPU_NV%"=="1" if not "%D_HAGSOK%"=="0" set "DO_HAGS=1"
if %OSBUILD% GEQ 19041 (
    if "%DO_HAGS%"=="1" (
        call :RS "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" REG_DWORD "2"
        set "REBOOT_REQ=1"
    ) else (
        echo    [SKIP] HAGS left as it is - only NVIDIA cards with driver support are switched on.
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

rem Message-signalled interrupts for the display
rem adapter. MSI removes the shared line-based IRQ handshake and is one of the
rem few changes that shows up directly in DPC latency measurements. This only
rem writes where the interrupt-management key already exists, so it never
rem creates MSI state on a device whose stack does not advertise it.
if "%CFG_GPU_MSI%"=="1" (
    set "FPS_PS_TITLE=GPU interrupt policy"
    set "FPS_PS_BODY=$found=0; foreach($v in @(Get-CimInstance Win32_VideoController)){ $id=[string]$v.PNPDeviceID; if($id -and $id.StartsWith('PCI')){ $found++; $b='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$id+'\Device Parameters\Interrupt Management'; $m=$b+'\MessageSignaledInterruptProperties'; try{ if(Test-Path -LiteralPath $m){ $ms=(Get-ItemProperty -LiteralPath $m -Name 'MSISupported' -ErrorAction SilentlyContinue).MSISupported; if($ms -eq 1){ Report 'SKIP' ('GPU MSI already on: '+$v.Name) }else{ Apply ('Enabling GPU MSI: '+$v.Name+'; MSISupported = 1') { Set-ItemProperty -LiteralPath $m -Name 'MSISupported' -Value 1 -Type DWord } } }else{Report 'SKIP' ('MSI key absent: '+$v.Name)} }catch{Report 'FAILED' ('Checking GPU MSI key: '+$v.Name) $_.Exception.Message} } }; if(-not $found){Report 'SKIP' 'No eligible PCI display adapters found'}"
    call :PS_RUN
    echo        Revert: MSISupported=0.
    set "REBOOT_REQ=1"
)
set "FPS_PS_TITLE=GPU interrupt priority cleanup"
set "FPS_PS_BODY=Invoke-FpsGpuPriorityCleanup"
call :PS_LIB

rem Vendor background agents. These are telemetry and updater processes, not
rem the graphics driver itself. The driver, control panel and overlay stay.
if "%GPU_NV%"=="1" (
    echo    NVIDIA detected - trimming vendor background agents
    call :SVC "NvTelemetryContainer" disabled
    call :RSE "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" "OptInOrOutPreference" REG_DWORD "0"
    call :RSE "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" "EnableRID44231" REG_DWORD "0"
    call :RSE "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" "EnableRID64640" REG_DWORD "0"
    call :RSE "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" "EnableRID66610" REG_DWORD "0"
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
set "FPS_PS_TITLE=Shader cache integrity"
set "FPS_PS_BODY=Invoke-FpsShaderCacheCheck"
call :PS_LIB

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
set "FPS_PS_BODY=$n=0; foreach($t in @(Get-ScheduledTask)){ $tn=$t.TaskName; if($tn -like 'NvTm*' -or $tn -like 'NvNode*' -or $tn -like 'NvDriverUpdate*' -or $tn -like '*Intel*Telemetry*' -or $tn -like 'AMD*Telemetry*' -or $tn -like '*User Experience Program*'){ $n++; Apply ('Disabling vendor telemetry task: '+$t.TaskPath+$tn) { Disable-ScheduledTask -TaskName $tn -TaskPath $t.TaskPath } } }; if(-not $n){Report 'SKIP' 'No matching vendor telemetry tasks found'}"
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
    echo    [SKIP] Fullscreen Optimizations left as they are - correct on current builds
    set /a CNT_SKIP+=1 >nul
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
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" REG_DWORD "0"
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
call :RSE "HKLM\SYSTEM\CurrentControlSet\Services\USB" "DisableSelectiveSuspend" REG_DWORD "1"

rem Per-device: clear "allow the computer to turn off this device to save
rem power" for mice, keyboards and HID devices only. Storage and network
rem devices are deliberately untouched.
set "FPS_PS_TITLE=Input device power management"
set "FPS_PS_BODY=$n=0; foreach($d in @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue)){ if($d.Class -eq 'Mouse' -or $d.Class -eq 'Keyboard' -or $d.Class -eq 'HIDClass'){ $k='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$d.InstanceId+'\Device Parameters'; try{ if(Test-Path -LiteralPath $k){ $dp=Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue; foreach($property in @('EnhancedPowerManagementEnabled','SelectiveSuspendEnabled','AllowIdleIrpInD3')){ $cv=$dp.$property; if(($null -eq $cv) -or ([int64]$cv -eq 0)){ continue }; $n++; $pn=$property; Apply ('Input device '+$d.InstanceId+': '+$pn+' = 0') { Set-ItemProperty -LiteralPath $k -Name $pn -Value 0 -Type DWord } } } }catch{Report 'FAILED' ('Checking input device: '+$d.InstanceId) $_.Exception.Message} } }; if(-not $n){Report 'SKIP' 'No input device has idle power-down values switched on'}"
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
rem of fullscreen focus.
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" "ScoobeSystemSettingEnabled" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested" "Enabled" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.BackupReminder" "Enabled" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" "EnableAccountNotifications" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_AccountNotifications" REG_DWORD "0"
call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSyncProviderNotifications" REG_DWORD "0"

rem Cross-device experiences ^(Phone Link resume, mobile device pairing^) keep
rem background hosts polling. Revert: delete these values.
if "%CFG_CROSSDEVICE_OFF%"=="1" (
    call :RS "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableMmx" REG_DWORD "0"
    call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" "IsResumeAllowed" REG_DWORD "0"
    call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Mobility" "CrossDeviceEnabled" REG_DWORD "0"
    call :RS "HKCU\Software\Microsoft\Windows\CurrentVersion\Mobility" "OptedIn" REG_DWORD "0"
    set "REBOOT_REQ=1"
)

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
set "FPS_PS_TITLE=Windows AI Fabric"
set "FPS_PS_BODY=Invoke-FpsAiFabric"
call :PS_LIB
echo(

:PH10B
rem ==========================================================================
rem PHASE 10b - THIRD-PARTY SOFTWARE SETTINGS THAT COST FRAMES
rem ==========================================================================
if not "%CFG_THIRDPARTY%"=="1" ( echo  [ PHASE 10b ]  skipped by config & echo( & goto :PH11 )
echo  [ PHASE 10b ]  Third-party software
echo  ---------------------------------------------------------------------------
set "FPS_PS_TITLE=Third-party software"
set "FPS_PS_BODY=Invoke-FpsThirdParty"
call :PS_LIB
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

rem SysMain is only removed on an SSD with 32 GB or more. Below that, memory
rem compression - which runs inside SysMain - keeps games out of the pagefile,
rem so a SysMain disabled by an earlier run is started again.
if "%DO_SYSMAIN_OFF%"=="1" (
    call :SVC "SysMain" disabled
    echo        SSD with 32 GB+: SysMain disabled. Revert: sc config SysMain start= auto
) else (
    set "FPS_PS_TITLE=SysMain"
    set "FPS_PS_BODY=Invoke-FpsSysMainRestore"
    call :PS_LIB
)
set "FPS_PS_TITLE=Game, controller and audio services"
set "FPS_PS_BODY=Invoke-FpsGameServices"
call :PS_LIB

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
echo        Left alone: ScheduledDefrag ^(issues TRIM on SSDs^), Compatibility Appraiser, ProactiveScan,
echo        UpdateOrchestrator, Defender scans.

for %%T in (
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
) do ( call :TSK %%T )

rem SysMain's own tasks are pointless once phase 12 has disabled SysMain on an
rem SSD, and the indexer's maintenance task once indexing is off.
if "%CFG_SERVICES%"=="1" if "%DO_SYSMAIN_OFF%"=="1" (
    call :TSK "\Microsoft\Windows\Sysmain\ResPriStaticDbSync"
    call :TSK "\Microsoft\Windows\Sysmain\WsSwapAssessmentTask"
)
if "%CFG_SERVICES%"=="1" if "%CFG_DISABLE_SEARCH%"=="1" call :TSK "\Microsoft\Windows\Shell\IndexerAutomaticMaintenance"

set "FPS_PS_TITLE=Compatibility Appraiser"
set "FPS_PS_BODY=Invoke-FpsAppraiserCheck"
call :PS_LIB

rem Automatic Maintenance fires on idle detection, and a menu screen or a
rem loading pause reads as idle. By default v5 moves it to a night hour
rem instead of switching it off, so SSD retrim and servicing still run.
if "%CFG_MAINTENANCE_OFF%"=="1" (
    call :RS "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" "MaintenanceDisabled" REG_DWORD "1"
    echo        Automatic maintenance disabled by config. Revert value: 0
    goto :PH13_MAINT_DONE
)
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
echo  [ PHASE 14 ]  Per-title CPU priority
echo  ---------------------------------------------------------------------------
if not defined CFG_GAME_EXES (
    echo    [SKIP] no executables listed. Edit CFG_GAME_EXES near the top of this file,
    echo        for example: set "CFG_GAME_EXES=cs2.exe;r5apex.exe;Cyberpunk2077.exe"
    set /a CNT_SKIP+=1 >nul
) else (
    rem Read executable names as data; semicolons separate entries, spaces stay literal.
    set "FPS_PS_TITLE=Per-title CPU priority"
    set "FPS_PS_BODY=Invoke-FpsGameKeys"
    call :PS_LIB
    echo        Revert: delete the matching key under Image File Execution Options.
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
    for %%K in (OSBUILD IS_W11 IS_24H2 HAS_PERPROC_TIMER D_RAMGB D_CORES D_THREADS D_CHASSIS D_SYSDISK D_HVCI D_VBS D_PRINTERS GPU_NV GPU_AMD GPU_INTEL CPU_AMD CPU_INTEL FPS_USID D_UBR D_HYBRID D_PCORES D_ECORES D_L3N D_X3D D_SMT D_HYPERVISOR REBOOT_REQ D_HAGSOK) do (
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
# ==========================================================================================
#  FPS Overhaul embedded PowerShell library (Windows PowerShell 5.1). Loaded by :PS_LIB
#  steps after the common helpers Report, Apply and Write-FpsData. Nothing here runs by
#  itself: each batch step calls one function by name.
# ==========================================================================================

function Test-FpsDry { return ($env:FPS_DRYRUN -eq '1') }

# ==========================================================================================
#  Modules. Read-only checks report findings; changes go through Apply, which honours
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


function FpsNum([double]$v,[int]$d=1){ return $v.ToString('F'+$d,[Globalization.CultureInfo]::InvariantCulture) }

function Get-FpsUserRegRoot {
    $sid=[string]$env:FPS_USID
    if($sid -and (Test-Path -LiteralPath ('Registry::HKEY_USERS\'+$sid))){ return ('Registry::HKEY_USERS\'+$sid) }
    return 'HKCU:'
}

# Drive letter -> @{Media='SSD'|'HDD'|'UNKNOWN'; Bus=<MSFT BusType>; Model; FreeGB; SizeGB; FreePct}
# UNKNOWN (never warned on) for Storage Spaces, RAID, virtual disks and unreported media.
function Get-FpsDriveTable {
    $out=@{}
    try{
        $ns='root\Microsoft\Windows\Storage'
        $phys=@{}
        foreach($pd in @(Get-CimInstance -Namespace $ns -ClassName 'MSFT_PhysicalDisk' -ErrorAction Stop)){
            $mt=[int]$pd.MediaType; $bt=[int]$pd.BusType; $sp=[int64]$pd.SpindleSpeed; $m='UNKNOWN'
            if($mt -eq 3){ $m='HDD' }
            elseif(($mt -eq 4) -or ($mt -eq 5)){ $m='SSD' }
            elseif($bt -eq 17){ $m='SSD' }
            elseif(($sp -ge 3000) -and ($sp -le 20000)){ $m='HDD' }
            $phys[[string]$pd.DeviceId]=@{ Media=$m; Bus=$bt; Model=([string]$pd.FriendlyName).Trim() }
        }
        $virt=@{}
        foreach($dk in @(Get-CimInstance -Namespace $ns -ClassName 'MSFT_Disk' -ErrorAction SilentlyContinue)){
            if(@(8,14,15,16) -contains [int]$dk.BusType){ $virt[[string]$dk.Number]=$true }
        }
        foreach($pt in @(Get-CimInstance -Namespace $ns -ClassName 'MSFT_Partition' -ErrorAction Stop)){
            $dl=[string]$pt.DriveLetter
            if($dl -notmatch '^[A-Za-z]$'){ continue }
            $k=[string]$pt.DiskNumber
            if($virt.ContainsKey($k) -or -not $phys.ContainsKey($k)){ continue }
            $src=$phys[$k]
            $out[$dl.ToUpperInvariant()]=@{ Media=$src.Media; Bus=$src.Bus; Model=$src.Model; FreeGB=-1; SizeGB=-1; FreePct=-1 }
        }
    }catch{}
    try{
        foreach($ld in @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction Stop)){
            $dl=([string]$ld.DeviceID).Substring(0,1).ToUpperInvariant()
            if(-not $out.ContainsKey($dl)){ $out[$dl]=@{ Media='UNKNOWN'; Bus=0; Model=''; FreeGB=-1; SizeGB=-1; FreePct=-1 } }
            if([double]$ld.Size -gt 0){
                $out[$dl].FreeGB=[double]$ld.FreeSpace/1GB
                $out[$dl].SizeGB=[double]$ld.Size/1GB
                $out[$dl].FreePct=100*[double]$ld.FreeSpace/[double]$ld.Size
            }
        }
    }catch{}
    return $out
}

# Reads the plugged-in value of a processor power setting of the active scheme from the
# registry: the user's own value first, then the scheme default. -1 when absent. Read only.
function Get-FpsPowerAcValue([string]$setting){
    $sub='54533251-82be-4824-96c1-47b60b740d00'
    $root='HKLM:\SYSTEM\CurrentControlSet\Control\Power'
    try{
        $act=[string](Get-ItemProperty -LiteralPath ($root+'\User\PowerSchemes') -Name 'ActivePowerScheme' -ErrorAction Stop).ActivePowerScheme
        if(-not $act){ return -1 }
        foreach($k in @(($root+'\User\PowerSchemes\'+$act+'\'+$sub+'\'+$setting), ($root+'\User\Default\PowerSchemes\'+$act+'\'+$sub+'\'+$setting), ($root+'\PowerSettings\'+$sub+'\'+$setting+'\DefaultPowerSchemeValues\'+$act))){
            $v=(Get-ItemProperty -LiteralPath $k -Name 'ACSettingIndex' -ErrorAction SilentlyContinue).ACSettingIndex
            if($null -ne $v){ return [int64]$v }
        }
    }catch{}
    return -1
}

# ------------------------------------------------------------------------------------------
# 1. CPU clocks and throttling: power-plan caps, 1 s single-thread load test, PPM limit, ACPI zones
# ------------------------------------------------------------------------------------------
function Test-FpsCpuClocks {
    $warn=0
    $boost=Get-FpsPowerAcValue 'be337238-0d82-4146-a960-4f3749d470c7'
    $caps=@()
    $v=Get-FpsPowerAcValue 'bc5038f7-23e0-4960-96da-33abaf5935ec'; if(($v -ge 0) -and ($v -lt 100)){ $caps+=('maximum processor state '+$v+'%') }
    $v=Get-FpsPowerAcValue '75b0ae3f-bce0-45a7-8c89-c9611c25e100'; if($v -gt 0){ $caps+=('maximum processor frequency '+$v+' MHz') }
    if($env:D_HYBRID -eq '1'){
        $v=Get-FpsPowerAcValue 'bc5038f7-23e0-4960-96da-33abaf5935ed'; if(($v -ge 0) -and ($v -lt 100)){ $caps+=('maximum state for performance cores '+$v+'%') }
        $v=Get-FpsPowerAcValue '75b0ae3f-bce0-45a7-8c89-c9611c25e101'; if($v -gt 0){ $caps+=('maximum frequency for performance cores '+$v+' MHz') }
    }
    if($boost -eq 0){ Report 'WARNING' 'Processor performance boost mode is Disabled in the active power plan (plugged in). The CPU never goes above its base clock, which costs a large share of FPS in CPU-bound games. Set Processor performance boost mode back to Enabled or Aggressive. This script never changes power settings.'; $warn++ }
    if($caps.Count){ Report 'WARNING' ('The active power plan caps the CPU when plugged in: '+($caps -join ', ')+'. Anything below 100% (or a MHz cap) switches turbo off. Set it back to 100% / 0 in Power Options, Processor power management. This script never changes power settings.'); $warn++ }

    $onBatt=$false
    try{ foreach($b in @(Get-CimInstance Win32_Battery -ErrorAction Stop)){ if([int]$b.BatteryStatus -eq 1){ $onBatt=$true } } }catch{}
    $props='Name','PercentProcessorTime','PercentProcessorPerformance','PercentProcessorPerformance_Base','PercentPerformanceLimit','PerformanceLimitFlags','Timestamp_Sys100NS'
    $cls='Win32_PerfRawData_Counters_ProcessorInformation'
    if($onBatt){
        Report 'INFO' 'On battery - CPU clock test skipped'
    }else{
        try{
            $a=@(Get-CimInstance -ClassName $cls -Property $props -ErrorAction Stop)
            $sw=[Diagnostics.Stopwatch]::StartNew(); $n=0
            while($sw.ElapsedMilliseconds -lt 1000){ $n++ }
            $bb=@(Get-CimInstance -ClassName $cls -Property $props -ErrorAction Stop)
            $ia=@{}; foreach($x in $a){ $ia[[string]$x.Name]=$x }
            $maxPerf=0.0; $bestBusy=0.0; $minLim=100; $flags=0
            foreach($y in $bb){
                $nm=[string]$y.Name
                if(($nm -match '_Total') -or -not $ia.ContainsKey($nm)){ continue }
                $x=$ia[$nm]
                $dts=[double]$y.Timestamp_Sys100NS-[double]$x.Timestamp_Sys100NS
                if($dts -le 0){ continue }
                $busy=100-100*(([double]$y.PercentProcessorTime-[double]$x.PercentProcessorTime)/$dts)
                $db=[double]$y.PercentProcessorPerformance_Base-[double]$x.PercentProcessorPerformance_Base
                $perf=-1.0
                if($db -gt 0){ $perf=([double]$y.PercentProcessorPerformance-[double]$x.PercentProcessorPerformance)/$db }
                if(($busy -ge 30) -and ($perf -gt $maxPerf) -and ($perf -lt 400)){ $maxPerf=$perf }
                if($busy -gt $bestBusy){ $bestBusy=$busy }
                $lim=[int]$y.PercentPerformanceLimit
                if(($lim -gt 0) -and ($lim -lt $minLim)){ $minLim=$lim; $flags=[int]$y.PerformanceLimitFlags }
            }
            $base=0; try{ $base=[int]@(Get-CimInstance Win32_Processor -ErrorAction Stop)[0].MaxClockSpeed }catch{}
            if(($bestBusy -ge 50) -and ($maxPerf -gt 5)){
                $mhz=''; if($base -gt 0){ $mhz=' (about '+[int]($base*$maxPerf/100)+' MHz vs '+$base+' MHz base)' }
                if($maxPerf -lt 55){
                    Report 'WARNING' ('Under a 1-second single-core load the CPU reached only '+[int]$maxPerf+'% of its rated base clock'+$mhz+'. Something is holding the clocks down: overheating (dust, a loose cooler, dried thermal paste), a firmware power or current limit (BD PROCHOT, a weak or wrong laptop charger) or a vendor power-saving mode. Check clocks and temperatures under load with HWiNFO.'); $warn++
                }else{
                    Report 'INFO' ('CPU load test: busiest core ran at '+[int]$maxPerf+'% of base clock'+$mhz)
                }
            }
            if($minLim -lt 90){
                $why=@(); if($flags -band 1){ $why+='thermal' }; if($flags -band 2){ $why+='power / current' }; if($flags -band 4){ $why+='shared-clock domain' }
                if($why.Count){ Report 'WARNING' ('Windows reports the CPU held to '+$minLim+'% of its maximum performance by the platform (reason: '+($why -join ', ')+'). Check cooling and the power supply or charger, and load BIOS defaults if you changed power limits.'); $warn++ }
                else{ Report 'INFO' ('Windows reports a CPU performance limit of '+$minLim+'% with no reason flag (often a plan or vendor utility setting)') }
            }
        }catch{ Report 'INFO' 'Processor performance counters are unavailable - CPU clock test skipped' }
    }
    try{
        $hot=-1.0
        foreach($z in @(Get-CimInstance -ClassName 'Win32_PerfRawData_Counters_ThermalZoneInformation' -ErrorAction Stop)){
            $pl=[int]$z.PercentPassiveLimit; $tr=[int]$z.ThrottleReasons; $tk=[double]$z.Temperature
            $zn=([string]$z.Name) -replace '^.*\\',''
            if((($tr -band 3) -ne 0) -or (($pl -gt 0) -and ($pl -lt 100))){
                $r='passive cooling'; if($tr -band 1){ $r='temperature' } elseif($tr -band 2){ $r='electrical current' }
                Report 'WARNING' ('Firmware thermal zone '+$zn+' is throttling the processor right now ('+$pl+'% allowed, reason: '+$r+'). The machine is overheating at the desktop already - clean the fans and heatsink and check the cooler and airflow.'); $warn++
            }
            if(($tk -ge 283) -and ($tk -le 393) -and (($tk-273.15) -gt $hot)){ $hot=$tk-273.15 }
        }
        if($hot -gt 0){ Report 'INFO' ('Hottest ACPI thermal zone: '+[int]$hot+' C (firmware sensor, often not the CPU core itself)') }
    }catch{}
    if(-not $warn){ Report 'INFO' 'No CPU clock cap or throttling found' }
}

# ------------------------------------------------------------------------------------------
# 2. Background CPU / disk / GPU hogs right now, plus known offenders and live video encoding
# ------------------------------------------------------------------------------------------
function Get-FpsHogAdvice([string]$n){
    if($n -match '^(TiWorker|TrustedInstaller|MoUsoCoreWorker|usocoreworker|wuauclt|WaaSMedicAgent|SIHClient|UsoClient)$'){ return 'Windows Update is installing - let it finish and restart before you play' }
    if($n -match '^(CompatTelRunner|DeviceCensus)$'){ return 'Microsoft compatibility telemetry appraisal - it runs for several minutes, wait for it to finish' }
    if($n -match '^(SearchIndexer|SearchProtocolHost|SearchFilterHost)$'){ return 'Windows Search is indexing - it settles once indexing completes' }
    if($n -match '^(MsMpEng|MpDefenderCoreService|NisSrv|MpCmdRun)$'){ return 'Microsoft Defender is scanning - let the scan finish (do not turn protection off)' }
    if($n -match '^(chrome|msedge|firefox|brave|opera|opera_gx|vivaldi|msedgewebview2|Discord)$'){ return 'close the busy tabs or windows before playing' }
    if($n -match '^(OneDrive|Dropbox|GoogleDriveFS|MEGAsync|iCloudDrive|iCloudServices)$'){ return 'cloud sync is transferring files - pause syncing while playing' }
    if($n -match '^(steam|steamwebhelper|steamservice|EpicGamesLauncher|EpicWebHelper|Battle\.net|Agent|EADesktop|EABackgroundService|upc|UbisoftConnect|GalaxyClient|RiotClientServices)$'){ return 'a game launcher is downloading or updating - pause downloads while playing' }
    if($n -match '^(obs64|obs32|Streamlabs OBS|XSplit\.Core|Medal|MedalEncoder)$'){ return 'recording or streaming software is working' }
    if($n -eq 'Memory Compression'){ return 'Windows is compressing memory because RAM is short - close programs or add RAM' }
    if($n -eq 'System'){ return 'kernel and driver work - see the interrupt / DPC check' }
    if($n -match '^(msiexec|OfficeClickToRun|setup|GoogleUpdate|MicrosoftEdgeUpdate|updater)$'){ return 'an installer or updater is running' }
    return 'close it before playing if you do not need it'
}

function Test-FpsBackgroundLoad([int]$WindowMs=2000){
    $lp=[Environment]::ProcessorCount; if($lp -lt 1){ $lp=1 }
    $skipPid=@{ 0=1; ([int]$PID)=1 }
    try{ $skipPid[[int](Get-CimInstance Win32_Process -Filter ('ProcessId='+$PID) -ErrorAction Stop).ParentProcessId]=1 }catch{}
    $pp='Name','IDProcess','PercentProcessorTime','IODataBytesPersec','Timestamp_Sys100NS','Timestamp_PerfTime','Frequency_PerfTime'
    $gp='Name','RunningTime','Timestamp_Sys100NS'
    $gcls='Win32_PerfRawData_GPUPerformanceCounters_GPUEngine'
    $sw=[Diagnostics.Stopwatch]::StartNew()
    try{ $pa=@(Get-CimInstance -ClassName 'Win32_PerfRawData_PerfProc_Process' -Property $pp -ErrorAction Stop) }catch{ Report 'INFO' 'Process counters unavailable - background load check skipped'; return }
    $ga=@(); $gOk=$true
    try{ $ga=@(Get-CimInstance -ClassName $gcls -Property $gp -ErrorAction Stop) }catch{ $gOk=$false }
    $gt0=$sw.Elapsed.TotalMilliseconds
    $rest=$WindowMs-[int]$sw.ElapsedMilliseconds; if($rest -lt 300){ $rest=300 }
    Start-Sleep -Milliseconds $rest
    $pb=@(Get-CimInstance -ClassName 'Win32_PerfRawData_PerfProc_Process' -Property $pp -ErrorAction SilentlyContinue)
    $gs=$sw.Elapsed.TotalMilliseconds
    $gb=@(); if($gOk){ $gb=@(Get-CimInstance -ClassName $gcls -Property $gp -ErrorAction SilentlyContinue) }
    $gElapsed100ns=(($gs+$sw.Elapsed.TotalMilliseconds)/2-$gt0)*10000

    $pname=@{}; $ia=@{}
    foreach($x in $pa){ $ia[[int]$x.IDProcess]=$x }
    $agg=@{}
    foreach($y in $pb){
        $id=[int]$y.IDProcess; $nm=([string]$y.Name) -replace '#\d+$',''
        if(($nm -eq '_Total') -or ($nm -eq 'Idle')){ continue }
        $pname[$id]=$nm
        if($skipPid.ContainsKey($id) -or -not $ia.ContainsKey($id)){ continue }
        $x=$ia[$id]
        if((([string]$x.Name) -replace '#\d+$','') -ne $nm){ continue }
        $dts=[double]$y.Timestamp_Sys100NS-[double]$x.Timestamp_Sys100NS; if($dts -le 0){ continue }
        $cores=([double]$y.PercentProcessorTime-[double]$x.PercentProcessorTime)/$dts
        $dpt=([double]$y.Timestamp_PerfTime-[double]$x.Timestamp_PerfTime)/[double]$y.Frequency_PerfTime
        $io=0.0; if($dpt -gt 0){ $io=([double]$y.IODataBytesPersec-[double]$x.IODataBytesPersec)/$dpt }
        if($cores -lt 0){ $cores=0 }; if($io -lt 0){ $io=0 }
        if(-not $agg.ContainsKey($nm)){ $agg[$nm]=@{ Name=$nm; Cores=0.0; IO=0.0; N=0 } }
        $agg[$nm].Cores+=$cores; $agg[$nm].IO+=$io; $agg[$nm].N++
    }
    $warn=0
    $rows=@($agg.Values | Where-Object { $_.Name -ne 'WmiPrvSE' })
    $known='^(TiWorker|TrustedInstaller|MoUsoCoreWorker|usocoreworker|wuauclt|WaaSMedicAgent|CompatTelRunner|DeviceCensus|SearchIndexer|SearchProtocolHost|SearchFilterHost|MsMpEng|MpDefenderCoreService)$'
    foreach($r in @($rows | Sort-Object { $_.Cores } -Descending | Select-Object -First 5)){
        $pct=100*$r.Cores/$lp
        if(($r.Cores -ge 0.5) -or ($pct -ge 10) -or (($r.Name -match $known) -and ($r.Cores -ge 0.25))){
            Report 'WARNING' ('Background CPU load: '+$r.Name+' is using '+(FpsNum $r.Cores)+' CPU threads ('+[int]$pct+'% of the CPU) right now - '+(Get-FpsHogAdvice $r.Name)+'. Every busy background thread competes with the game and lowers 1% lows.'); $warn++
        }
    }
    foreach($r in @($rows | Sort-Object { $_.IO } -Descending | Select-Object -First 3)){
        if($r.IO -ge 20MB){
            Report 'WARNING' ('Background disk / data load: '+$r.Name+' is moving '+[int]($r.IO/1MB)+' MB/s right now - '+(Get-FpsHogAdvice $r.Name)+'. Heavy background I/O causes loading and asset-streaming hitches.'); $warn++
        }
    }
    $upd=@($pname.Values | Where-Object { $_ -match '^(TiWorker|TrustedInstaller|MoUsoCoreWorker|usocoreworker|wuauclt)$' } | Select-Object -Unique)
    if($upd.Count){ Report 'INFO' ('Windows servicing is active ('+($upd -join ', ')+'). Updates install in the background with high disk and CPU use; let them finish and restart before gaming or benchmarking.') }
    if(@($pname.Values | Where-Object { $_ -match '^(CompatTelRunner|DeviceCensus)$' }).Count){ Report 'INFO' 'Microsoft Compatibility Telemetry (CompatTelRunner) is running. It scans installed programs for several minutes with heavy disk and CPU use; wait for it to finish before playing.' }

    if($gOk -and $gb.Count){
        $gi=@{}; foreach($x in $ga){ $gi[[string]$x.Name]=$x }
        $g3d=@{}; $genc=@{}; $gdec=@{}
        foreach($y in $gb){
            $nm=[string]$y.Name
            if($nm -notmatch '^pid_(\d+)_luid_.*_engtype_(.*)$'){ continue }
            $id=[int]$Matches[1]; $et=$Matches[2]
            if(-not $gi.ContainsKey($nm)){ continue }
            $x=$gi[$nm]
            $dt=[double]$y.Timestamp_Sys100NS-[double]$x.Timestamp_Sys100NS
            if($dt -le 0){ $dt=$gElapsed100ns }
            if($dt -le 0){ continue }
            $u=100*([double]$y.RunningTime-[double]$x.RunningTime)/$dt
            if(($u -le 0) -or ($u -gt 110)){ continue }
            $t=$g3d
            if($et -match 'Encode'){ $t=$genc } elseif($et -match 'Decode|Codec|VideoProcessing'){ $t=$gdec }
            if((-not $t.ContainsKey($id)) -or ($t[$id] -lt $u)){ $t[$id]=$u }
        }
        $gx='^(dwm|csrss|System|Idle|audiodg|WmiPrvSE)$'
        foreach($id in @(@($g3d.Keys)+@($genc.Keys)+@($gdec.Keys) | Select-Object -Unique)){
            if(-not $pname.ContainsKey($id)){ $gp2=Get-Process -Id $id -ErrorAction SilentlyContinue; if($gp2){ $pname[$id]=[string]$gp2.ProcessName } }
        }
        foreach($id in @($g3d.Keys)){
            $n=[string]$pname[$id]
            if((-not $n) -or ($n -match $gx) -or $skipPid.ContainsKey([int]$id)){ continue }
            if($g3d[$id] -ge 10){ Report 'WARNING' ('Background GPU load: '+$n+' keeps '+[int]$g3d[$id]+'% of a GPU engine busy right now - '+(Get-FpsHogAdvice $n)+'. The game only gets what is left of the GPU.'); $warn++ }
        }
        foreach($id in @($genc.Keys)){
            $n=[string]$pname[$id]; if(-not $n){ $n='a process that has since exited' }
            if($genc[$id] -ge 1){ Report 'WARNING' ('Continuous video encoding by '+$n+' ('+[int]$genc[$id]+'% of the video encoder) while no game is running: background recording / instant replay is on (NVIDIA Instant Replay, AMD Instant Replay, OBS replay buffer, Medal or similar). It records non-stop and costs FPS and video memory; turn it off unless you use it.'); $warn++ }
        }
        $brw=@()
        foreach($id in @($gdec.Keys)){ $n=[string]$pname[$id]; if(($gdec[$id] -ge 1) -and ($n -match '^(chrome|msedge|firefox|brave|opera|opera_gx|vivaldi|msedgewebview2|Discord|Spotify)$')){ $brw+=$n } }
        if($brw.Count){ Report 'INFO' ('Video is playing in '+(@($brw | Select-Object -Unique) -join ', ')+' (GPU video decoder active). Pause it while gaming, especially on integrated graphics or a GPU with little video memory.') }
    }
    if(-not $warn){
        $top=@($rows | Sort-Object { $_.Cores } -Descending | Select-Object -First 1)
        $t=''; if($top.Count){ $t=' (busiest: '+$top[0].Name+' at '+(FpsNum $top[0].Cores 2)+' CPU threads)' }
        Report 'INFO' ('No background CPU, disk or GPU hog right now'+$t)
    }
}

# ------------------------------------------------------------------------------------------
# 3. Games on hard disks, USB drives or nearly full drives
# ------------------------------------------------------------------------------------------
function Get-FpsGameInstalls {
    $list=New-Object System.Collections.ArrayList
    $seen=@{}
    function Add-FpsGame([string]$store,[string]$name,[string]$path){
        if(-not $path){ return }
        $p=($path.Trim().Trim('"') -replace '/','\').TrimEnd('\')
        if($p -notmatch '^[A-Za-z]:\\'){ return }
        $k=$p.ToLowerInvariant()
        if($seen.ContainsKey($k)){ return }
        if(-not (Test-Path -LiteralPath $p -PathType Container)){ return }
        $seen[$k]=1
        if(-not $name){ $name=Split-Path -Leaf $p }
        [void]$list.Add(@{ Store=$store; Name=$name; Path=$p; Drive=$p.Substring(0,1).ToUpperInvariant() })
    }
    $ur=Get-FpsUserRegRoot
    # Steam: libraryfolders.vdf + appmanifest_*.acf
    try{
        $steam=''
        try{ $steam=[string](Get-ItemProperty -LiteralPath ($ur+'\Software\Valve\Steam') -Name 'SteamPath' -ErrorAction Stop).SteamPath }catch{}
        if(-not $steam){ try{ $steam=[string](Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -Name 'InstallPath' -ErrorAction Stop).InstallPath }catch{} }
        if($steam){
            $steam=$steam.Replace('/','\'); $libs=@($steam)
            $vdf=Join-Path $steam 'steamapps\libraryfolders.vdf'
            if(Test-Path -LiteralPath $vdf){ foreach($ln in [IO.File]::ReadAllLines($vdf)){ if($ln -match '^\s*"path"\s+"(.+)"'){ $libs+=($Matches[1] -replace '\\\\','\') } } }
            foreach($l in @($libs | Select-Object -Unique)){
                $sa=Join-Path $l 'steamapps'
                foreach($acf in @(Get-ChildItem -LiteralPath $sa -Filter 'appmanifest_*.acf' -File -ErrorAction SilentlyContinue)){
                    $txt=[IO.File]::ReadAllText($acf.FullName); $nm=''; $dir=''
                    if($txt -match '"name"\s+"([^"]*)"'){ $nm=$Matches[1] }
                    if($txt -match '"installdir"\s+"([^"]*)"'){ $dir=$Matches[1] }
                    if($dir -and ($nm -notmatch 'Redistributable|Proton|Steam Linux Runtime|SteamVR')){ Add-FpsGame 'Steam' $nm (Join-Path $sa ('common\'+$dir)) }
                }
            }
        }
    }catch{}
    # Epic: manifest .item files (JSON)
    try{
        $man=Join-Path $env:ProgramData 'Epic\EpicGamesLauncher\Data\Manifests'
        foreach($f in @(Get-ChildItem -LiteralPath $man -Filter '*.item' -File -ErrorAction SilentlyContinue)){
            try{ $j=[IO.File]::ReadAllText($f.FullName) | ConvertFrom-Json; Add-FpsGame 'Epic' ([string]$j.DisplayName) ([string]$j.InstallLocation) }catch{}
        }
    }catch{}
    # Xbox / Microsoft Store: X:\.GamingRoot = 'RGBX' + UInt32 count + UTF-16 folder names
    try{
        foreach($ld in @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction Stop)){
            $gr=[string]$ld.DeviceID+'\.GamingRoot'
            if(-not [IO.File]::Exists($gr)){ continue }
            $b=[IO.File]::ReadAllBytes($gr)
            if(($b.Length -lt 10) -or ([Text.Encoding]::ASCII.GetString($b,0,4) -ne 'RGBX')){ continue }
            foreach($rel in ([Text.Encoding]::Unicode.GetString($b,8,$b.Length-8) -split [string][char]0)){
                if(-not $rel.Trim()){ continue }
                $root=[string]$ld.DeviceID+'\'+$rel.Trim().TrimStart('\')
                foreach($g in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)){ Add-FpsGame 'Xbox' $g.Name $g.FullName }
            }
        }
    }catch{}
    # Ubisoft, GOG, older EA registry keys
    try{ foreach($k in @(Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\WOW6432Node\Ubisoft\Launcher\Installs' -ErrorAction SilentlyContinue)){ Add-FpsGame 'Ubisoft' '' ([string]$k.GetValue('InstallDir')) } }catch{}
    try{ foreach($k in @(Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games' -ErrorAction SilentlyContinue)){ Add-FpsGame 'GOG' ([string]$k.GetValue('gameName')) ([string]$k.GetValue('path')) } }catch{}
    try{ foreach($k in @(Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\WOW6432Node\EA Games' -ErrorAction SilentlyContinue)){ Add-FpsGame 'EA' $k.PSChildName ([string]$k.GetValue('Install Dir')) } }catch{}
    # Riot: product_settings.yaml
    try{
        foreach($f in @(Get-ChildItem -LiteralPath (Join-Path $env:ProgramData 'Riot Games\Metadata') -Filter '*.product_settings.yaml' -File -Recurse -Depth 1 -ErrorAction SilentlyContinue)){
            if($f.Name -match '^Riot Client'){ continue }
            foreach($ln in [IO.File]::ReadAllLines($f.FullName)){ if($ln -match '^\s*product_install_full_path:\s*"?([^"]+)"?\s*$'){ Add-FpsGame 'Riot' '' $Matches[1] } }
        }
    }catch{}
    # Uninstall entries: Battle.net, EA app, Riot, Ubisoft, GOG, Rockstar and similar (Steam entries skipped - covered above)
    $uk=@('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',($ur+'\Software\Microsoft\Windows\CurrentVersion\Uninstall'))
    foreach($root in $uk){
        foreach($k in @(Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue)){
            try{
                if($k.PSChildName -match '^Steam App '){ continue }
                $loc=[string]$k.GetValue('InstallLocation'); if(-not $loc){ continue }
                $pub=[string]$k.GetValue('Publisher'); $un=[string]$k.GetValue('UninstallString'); $dn=[string]$k.GetValue('DisplayName')
                if($dn -match '^(Battle\.net|EA app|EA|Origin|Ubisoft Connect|Uplay|GOG GALAXY|Riot Client|Riot Vanguard|Rockstar Games Launcher|Rockstar Games Social Club|Bethesda\.net Launcher|Blizzard Battle\.net App)$'){ continue }
                if(($pub -match 'Blizzard|Riot Games|Electronic Arts|Ubisoft|Rockstar Games|Bethesda|Activision|GOG\.com|CD PROJEKT') -or ($un -match 'Battle\.net|RiotClientServices|EADesktop|EAInstaller|upc\.exe|Uplay|GalaxyClient')){ Add-FpsGame 'Launcher' $dn $loc }
            }catch{}
        }
    }
    return ,$list
}

function Test-FpsGameStorage {
    $games=Get-FpsGameInstalls
    if(-not $games.Count){ Report 'INFO' 'No installed games found in Steam, Epic, Xbox, Battle.net, EA, Ubisoft, GOG or Riot locations'; return }
    $media=Get-FpsDriveTable
    $sys=([string]$env:SystemDrive).Substring(0,1).ToUpperInvariant()
    $warn=0; $sum=@()
    foreach($grp in @($games | Group-Object { $_.Drive } | Sort-Object Name)){
        $dl=[string]$grp.Name; $m=$null; if($media.ContainsKey($dl)){ $m=$media[$dl] }
        $kind='unknown drive type'; if($m -and ($m.Media -ne 'UNKNOWN')){ $kind=$m.Media }
        if($m -and ($m.Bus -eq 7)){ $kind='USB '+$kind }
        $sum+=($dl+': '+$grp.Count+' on '+$kind)
        $ex=(@($grp.Group | Select-Object -First 4 | ForEach-Object { $_.Name }) -join ', ')
        $model=''; if($m -and $m.Model){ $model=' ('+$m.Model+')' }
        if($m -and ($m.Media -eq 'HDD')){
            Report 'WARNING' ([string]$grp.Count+' game(s) are installed on the hard disk '+$dl+':'+$model+', e.g. '+$ex+'. Hard disks cause long loads and streaming stutter (texture pop-in, traversal hitches) in modern and open-world games, and DirectStorage titles expect an SSD. Move the games you play to an SSD (Steam: Properties, Installed Files, Move install folder; Xbox app: Manage, Files, Move).'); $warn++
        }elseif($m -and ($m.Bus -eq 7)){
            Report 'INFO' ([string]$grp.Count+' game(s) on USB drive '+$dl+':'+$model+'. USB storage has higher latency than an internal SSD; keep the games you play most on an internal drive.')
        }
        if($m -and ($m.FreeGB -ge 0) -and ($dl -ne $sys)){
            if((($m.FreePct -lt 10) -and ($m.FreeGB -lt 50)) -or ($m.FreeGB -lt 15)){
                Report 'WARNING' ('Game drive '+$dl+': is nearly full: '+[int]$m.FreeGB+' GB free ('+[int]$m.FreePct+'%). Game patches and shader caches need free space, a nearly full SSD writes much slower and a nearly full hard disk fragments game files. Free up space or move games.'); $warn++
            }
        }
    }
    Report 'INFO' ('Installed games found: '+$games.Count+' - '+($sum -join '; '))
    if(-not $warn){ Report 'INFO' 'No game drive problem found' }
}

# ------------------------------------------------------------------------------------------
# 4. Memory pressure: installed vs usable RAM, available RAM, commit headroom, paging, pagefile
# ------------------------------------------------------------------------------------------
function Test-FpsMemoryPressure {
    $warn=0
    try{
        $os=@(Get-CimInstance Win32_OperatingSystem -ErrorAction Stop)[0]
        $mp='AvailableBytes','CommittedBytes','CommitLimit','PagesInputPersec','Timestamp_PerfTime','Frequency_PerfTime'
        $m1=@(Get-CimInstance -ClassName 'Win32_PerfRawData_PerfOS_Memory' -Property $mp -ErrorAction Stop)[0]
        Start-Sleep -Milliseconds 1000
        $m2=@(Get-CimInstance -ClassName 'Win32_PerfRawData_PerfOS_Memory' -Property $mp -ErrorAction Stop)[0]
    }catch{ Report 'INFO' 'Memory counters unavailable - memory check skipped'; return }
    $vis=[double]$os.TotalVisibleMemorySize*1KB
    $avail=[double]$m2.AvailableBytes; $commit=[double]$m2.CommittedBytes; $limit=[double]$m2.CommitLimit
    $dt=([double]$m2.Timestamp_PerfTime-[double]$m1.Timestamp_PerfTime)/[double]$m2.Frequency_PerfTime
    $hard=0.0; if($dt -gt 0){ $hard=([double]$m2.PagesInputPersec-[double]$m1.PagesInputPersec)/$dt }
    $inst=0.0; try{ $inst=[double](@(Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop) | Measure-Object -Property Capacity -Sum).Sum }catch{}
    if(($inst -gt 0) -and ($inst -le 8.5GB)){ Report 'WARNING' ('Only '+[int][math]::Round($inst/1GB)+' GB of RAM installed. Current games plus Windows regularly need more, so the system pages to disk mid-game and 1% lows collapse. 16 GB (2 x 8 GB, dual channel) is the practical minimum, 32 GB for the heaviest titles.'); $warn++ }
    if(($inst -gt 0) -and ($vis -gt 0)){
        $gap=$inst-$vis
        if(($gap -gt 2GB) -and ($gap -gt 0.2*$inst)){ Report 'WARNING' ('Windows can use only '+(FpsNum ($vis/1GB))+' GB of the '+[int][math]::Round($inst/1GB)+' GB installed. Unless this is a deliberate integrated-graphics memory reservation, check that msconfig, Boot, Advanced options, Maximum memory is unticked, that BIOS memory remapping is on, and that the modules are seated correctly.'); $warn++ }
    }
    $apct=0.0; if($vis -gt 0){ $apct=100*$avail/$vis }
    if(($vis -gt 0) -and (($avail -lt 2.5GB) -or ($apct -lt 15))){
        $top=''
        try{ $top=(@(Get-Process -ErrorAction SilentlyContinue | Group-Object ProcessName | ForEach-Object { New-Object PSObject -Property @{ N=$_.Name; B=[double]($_.Group | Measure-Object -Property PrivateMemorySize64 -Sum).Sum } } | Sort-Object B -Descending | Select-Object -First 4 | ForEach-Object { $_.N+' '+(FpsNum ($_.B/1GB))+' GB' }) -join ', ') }catch{}
        Report 'WARNING' ('Only '+(FpsNum ($avail/1GB))+' GB of RAM ('+[int]$apct+'%) is free before any game starts. Close memory-heavy programs first (largest now: '+$top+').'); $warn++
    }
    $cpct=0.0; if($limit -gt 0){ $cpct=100*$commit/$limit }
    $pfu=@(); try{ $pfu=@(Get-CimInstance Win32_PageFileUsage -ErrorAction Stop) }catch{}
    $auto=$false; try{ $auto=[bool]@(Get-CimInstance Win32_ComputerSystem -ErrorAction Stop)[0].AutomaticManagedPagefile }catch{}
    $fixed=$false; $pfMax=0.0
    try{ foreach($s in @(Get-CimInstance Win32_PageFileSetting -ErrorAction Stop)){ if([double]$s.MaximumSize -gt 0){ $fixed=$true; $pfMax+=[double]$s.MaximumSize } } }catch{}
    if($auto){ $fixed=$false }
    if(($limit -gt 0) -and (($cpct -ge 90) -or ((($limit-$commit) -lt 6GB) -and ($fixed -or -not $pfu.Count)))){
        Report 'WARNING' ('Committed memory is '+(FpsNum ($commit/1GB))+' GB of a '+(FpsNum ($limit/1GB))+' GB limit ('+[int]$cpct+'%) before any game starts. A game that needs more will stall while the pagefile grows or fail with out-of-memory errors; close programs or use a System managed pagefile.'); $warn++
    }
    if(($hard -ge 500) -and ($apct -lt 25)){ Report 'WARNING' ('Windows is reading '+[int]$hard+' pages per second back from disk at the desktop - RAM is already overcommitted. Close programs before playing.'); $warn++ }
    Report 'INFO' ('Memory now: '+(FpsNum ($avail/1GB))+' GB available of '+(FpsNum ($vis/1GB))+' GB; commit '+(FpsNum ($commit/1GB))+' / '+(FpsNum ($limit/1GB))+' GB ('+[int]$cpct+'%); hard page reads '+[int]$hard+'/s; pagefile '+(@($pfu | ForEach-Object { [string]$_.Name+' '+[int]$_.AllocatedBaseSize+' MB' }) -join ', '))
    if(-not $warn){ Report 'INFO' 'No memory-pressure problem found' }
}

# ------------------------------------------------------------------------------------------
# 5. Overlays, recorders and injectors
# ------------------------------------------------------------------------------------------
function Test-FpsOverlays {
    $warn=0
    $pn=@(); try{ $pn=@(Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $_.ProcessName } | Select-Object -Unique) }catch{}
    $has={ param($rx) return (@($pn | Where-Object { $_ -match $rx }).Count -gt 0) }
    $prof=Get-FpsUserProfile
    # NVIDIA Instant Replay (NVIDIA App / GeForce Experience share settings)
    $ir=$false
    foreach($rel in @('AppData\Local\NVIDIA Corporation\NVIDIA Overlay\ShareSettings.json','AppData\Local\NVIDIA Corporation\NVIDIA Share\ShareSettings.json')){
        if(-not $prof){ continue }
        try{ $f=Join-Path $prof $rel; if(Test-Path -LiteralPath $f){ if([IO.File]::ReadAllText($f) -match '"irEnabled"\s*:\s*true'){ $ir=$true } } }catch{}
    }
    if($ir){ Report 'WARNING' 'NVIDIA Instant Replay is on. It records the screen non-stop with the video encoder, which costs a few percent of FPS and some video memory in every game. Turn it off in the NVIDIA overlay (Alt+Z, Instant Replay) unless you use it.'; $warn++ }
    elseif(& $has '^(NVIDIA Overlay|NVIDIA Share)$'){ Report 'INFO' 'NVIDIA in-game overlay is enabled (Instant Replay off). Its cost is small; if you do not use it, switch it off in the NVIDIA App settings.' }
    if(& $has '^(amdow|AMDRSServ|RadeonSoftware)$'){ Report 'INFO' 'AMD Software overlay / recording service is running. In AMD Software, Record and Stream, keep Instant Replay and In-Game Replay off unless you use them - they record continuously.' }
    if(& $has '^(Discord|DiscordPTB|DiscordCanary)$'){ Report 'INFO' 'Discord is running. Its game overlay is a window on top of the game, which turns off G-SYNC / FreeSync in that game - disable it in Discord, User Settings, Game Overlay, unless you use it.' }
    if(& $has '^RTSS$'){ Report 'INFO' 'RivaTuner Statistics Server is hooking games. Its frame limiter is one of the best tools for even frame times - keep it if you use it (cap a few FPS below refresh, and use only one limiter); otherwise close it.' }
    if(& $has '^MSIAfterburner$'){ Report 'INFO' 'MSI Afterburner is monitoring hardware. Set its hardware polling period to 1000 ms or more; fast polling of some GPU and power sensors causes periodic stutter.' }
    $inj=@()
    if(& $has '^(Overwolf|OverwolfBrowser)$'){ $inj+='Overwolf' }
    if(& $has '^(Medal|MedalEncoder)$'){ $inj+='Medal (background clipping)' }
    if(& $has '^Blitz$'){ $inj+='Blitz' }
    if(& $has '^RazerCortex$'){ $inj+='Razer Cortex' }
    if(& $has '^(NahimicSvc64|NahimicSvc32|Nahimic3)$'){ $inj+='Nahimic audio (injects NahimicOSD into games)' }
    if($inj.Count){ Report 'WARNING' ('Game-injecting overlays or recorders are running: '+($inj -join ', ')+'. They hook every game frame (and clip recorders encode continuously), a known source of stutter and crashes. Close or disable the ones you do not need and test the difference.'); $warn++ }
    # OBS: CPU (x264) encoding in the active profile
    try{
        $obs=''; if($prof){ $obs=Join-Path $prof 'AppData\Roaming\obs-studio' }
        if($obs -and (Test-Path -LiteralPath $obs)){
            $act=''
            foreach($g in @('user.ini','global.ini')){
                $f=Join-Path $obs $g
                if((-not $act) -and (Test-Path -LiteralPath $f)){ foreach($ln in [IO.File]::ReadAllLines($f)){ if($ln -match '^ProfileDir=(.+)$'){ $act=$Matches[1].Trim(); break } } }
            }
            $ini=@()
            if($act){ $ini=@(Join-Path $obs ('basic\profiles\'+$act+'\basic.ini')) }else{ $ini=@(Get-ChildItem -LiteralPath (Join-Path $obs 'basic\profiles') -Filter 'basic.ini' -File -Recurse -Depth 1 -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }) }
            $x264=$false
            foreach($f in $ini){
                if(-not (Test-Path -LiteralPath $f)){ continue }
                $sec=''; $mode='Simple'; $enc=@()
                foreach($ln in [IO.File]::ReadAllLines($f)){
                    if($ln -match '^\[(.+)\]'){ $sec=$Matches[1]; continue }
                    if(($sec -eq 'Output') -and ($ln -match '^Mode=(.+)$')){ $mode=$Matches[1].Trim() }
                    if(($sec -eq 'SimpleOutput') -and ($ln -match '^(StreamEncoder|RecEncoder)=(.+)$')){ $enc+=('S|'+$Matches[2].Trim()) }
                    if(($sec -eq 'AdvOut') -and ($ln -match '^(Encoder|RecEncoder)=(.+)$')){ $enc+=('A|'+$Matches[2].Trim()) }
                }
                foreach($e in $enc){ if((($mode -eq 'Advanced') -and ($e -match '^A\|obs_x264$')) -or (($mode -ne 'Advanced') -and ($e -match '^S\|x264'))){ $x264=$true } }
            }
            $run=& $has '^(obs64|obs32)$'
            if($x264){
                $st='WARNING'; if(-not $run){ $st='INFO' }
                Report $st 'OBS is set to x264 software encoding. x264 occupies several CPU cores while you stream or record and drags down game FPS and 1% lows; switch OBS Settings, Output to the hardware encoder (NVIDIA NVENC, AMD AMF / HEVC or Intel QuickSync).'
                if($run){ $warn++ }
            }elseif($run){ Report 'INFO' 'OBS is running with a hardware encoder. For OBS game capture, a capped game frame rate leaves headroom for the capture.' }
        }
    }catch{}
    if(-not $warn){ Report 'INFO' 'No costly overlay or background recorder found' }
}

# ------------------------------------------------------------------------------------------
# 6b. Video memory already in use at the desktop (DXGI adapter size + GPU Adapter Memory counters)
# ------------------------------------------------------------------------------------------

function Test-FpsVramHeadroom {
    $FpsDxgiSource=@'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class FpsDxgi {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct AdapterDesc1 {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string Description;
        public uint VendorId; public uint DeviceId; public uint SubSysId; public uint Revision;
        public UIntPtr DedicatedVideoMemory; public UIntPtr DedicatedSystemMemory; public UIntPtr SharedSystemMemory;
        public uint LuidLow; public int LuidHigh; public uint Flags;
    }
    [ComImport, Guid("29038f61-3839-4626-91fd-086879011a05"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAdapter1 {
        void SetPrivateData(); void SetPrivateDataInterface(); void GetPrivateData(); void GetParent();
        void EnumOutputs(); void GetDesc(); void CheckInterfaceSupport();
        [PreserveSig] int GetDesc1(out AdapterDesc1 desc);
    }
    [ComImport, Guid("770aae78-f26f-4dba-a829-253c83d1b387"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IFactory1 {
        void SetPrivateData(); void SetPrivateDataInterface(); void GetPrivateData(); void GetParent();
        void EnumAdapters(); void MakeWindowAssociation(); void GetWindowAssociation(); void CreateSwapChain(); void CreateSoftwareAdapter();
        [PreserveSig] int EnumAdapters1(uint index, out IAdapter1 adapter);
    }
    [DllImport("dxgi.dll")]
    static extern int CreateDXGIFactory1(ref Guid riid, [MarshalAs(UnmanagedType.IUnknown)] out object factory);
    public static string[] List() {
        List<string> r = new List<string>();
        Guid g = typeof(IFactory1).GUID;
        object o;
        if (CreateDXGIFactory1(ref g, out o) != 0 || o == null) { return r.ToArray(); }
        IFactory1 f = (IFactory1)o;
        for (uint i = 0; i < 16; i++) {
            IAdapter1 a;
            if (f.EnumAdapters1(i, out a) != 0 || a == null) { break; }
            AdapterDesc1 d;
            if (a.GetDesc1(out d) == 0) {
                r.Add(d.Description + "|" + d.DedicatedVideoMemory.ToUInt64().ToString() + "|" + d.LuidHigh.ToString("X8") + "|" + d.LuidLow.ToString("X8") + "|" + d.Flags.ToString() + "|" + d.VendorId.ToString("X4"));
            }
            Marshal.ReleaseComObject(a);
        }
        Marshal.ReleaseComObject(f);
        return r.ToArray();
    }
}
'@
    $ad=@()
    try{
        if(-not ('FpsDxgi' -as [type])){ Add-Type -TypeDefinition $FpsDxgiSource -ErrorAction Stop }
        $ad=@([FpsDxgi]::List())
    }catch{}
    if(-not $ad.Count){ Report 'INFO' 'Graphics adapters could not be listed through DXGI - video memory check skipped'; return }
    $mem=@(); $pm=@()
    try{ $mem=@(Get-CimInstance -ClassName 'Win32_PerfRawData_GPUPerformanceCounters_GPUAdapterMemory' -Property 'Name','DedicatedUsage' -ErrorAction Stop) }catch{ Report 'INFO' 'GPU memory counters are unavailable on this build - video memory check skipped'; return }
    try{ $pm=@(Get-CimInstance -ClassName 'Win32_PerfRawData_GPUPerformanceCounters_GPUProcessMemory' -Property 'Name','DedicatedUsage' -ErrorAction Stop) }catch{}
    $names=@{}; try{ foreach($p in @(Get-Process -ErrorAction SilentlyContinue)){ $names[[int]$p.Id]=$p.ProcessName } }catch{}
    $warn=0; $seen=@{}
    foreach($line in $ad){
        $f=([string]$line).Split('|'); if($f.Count -lt 6){ continue }
        $desc=$f[0].Trim(); $ded=[double]$f[1]; $flags=[int]$f[4]
        if(($flags -band 2) -or ($ded -lt 1GB)){ continue }
        $key=('luid_0x'+$f[2]+'_0x'+$f[3]).ToLowerInvariant()
        if($seen.ContainsKey($key)){ continue }; $seen[$key]=1
        $used=0.0
        foreach($m in $mem){ if(([string]$m.Name).ToLowerInvariant().StartsWith($key)){ $used+=[double]$m.DedicatedUsage } }
        $pct=100*$used/$ded
        $holders=@{}
        foreach($m in $pm){
            $nm=([string]$m.Name).ToLowerInvariant()
            if(($nm -match '^pid_(\d+)_(.*)$') -and $Matches[2].StartsWith($key)){
                $id=[int]$Matches[1]; $pn=[string]$names[$id]; if(-not $pn){ $pn='pid '+$id }
                if(-not $holders.ContainsKey($pn)){ $holders[$pn]=0.0 }; $holders[$pn]+=[double]$m.DedicatedUsage
            }
        }
        $top=@($holders.Keys | Where-Object { ($holders[$_] -ge 100MB) -and ($_ -notmatch '^(dwm|csrss)$') } | Sort-Object { $holders[$_] } -Descending | Select-Object -First 4 | ForEach-Object { $_+' '+(FpsNum ($holders[$_]/1GB))+' GB' })
        $tt=''; if($top.Count){ $tt=' Largest users (per-process figures can over-read): '+($top -join ', ')+'.' }
        if(($pct -ge 60) -or (($pct -ge 40) -and ($used -ge 1.5GB))){
            Report 'WARNING' ($desc+': '+(FpsNum ($used/1GB))+' GB of its '+(FpsNum ($ded/1GB))+' GB video memory ('+[int]$pct+'%) is already in use at the desktop. A game then runs out of video memory sooner, spills into system RAM and stutters badly.'+$tt+' Close browsers, launchers, wallpaper engines and recorders before playing.'); $warn++
        }else{
            Report 'INFO' ($desc+': '+(FpsNum ($ded/1GB))+' GB video memory, '+(FpsNum ($used/1GB))+' GB ('+[int]$pct+'%) in use at the desktop')
        }
        if($ded -le 4.5GB){ Report 'INFO' ($desc+' has '+(FpsNum ($ded/1GB) 0)+' GB of video memory. Keep texture quality at a level that fits - exceeding video memory causes the worst 1% lows of any setting.') }
    }
    if(-not $seen.Count){ Report 'INFO' 'No graphics adapter with dedicated video memory found' }
}


# Drive letter of a path -> SSD, HDD, USB or UNKNOWN, from the drive table (read once).
$script:FpsDriveCache = $null
function Get-FpsDriveMedia ([string]$path) {
    if ((-not $path) -or ($path.Length -lt 2) -or ($path[1] -ne ':')) { return 'UNKNOWN' }
    if ($null -eq $script:FpsDriveCache) { $script:FpsDriveCache = Get-FpsDriveTable }
    $L = $path.Substring(0, 1).ToUpperInvariant()
    if (-not $script:FpsDriveCache.ContainsKey($L)) { return 'UNKNOWN' }
    $e = $script:FpsDriveCache[$L]
    if ($e.Bus -eq 7) { return 'USB' }
    return [string]$e.Media
}

# ------------------------------------------------------------------------------------------
#  Phase 0b: CPU platform extras (read only)
# ------------------------------------------------------------------------------------------
function Invoke-FpsCpuPlatform {
    $warn = 0
    $cpu = ''
    try { $cpu = ([string]@(Get-CimInstance Win32_Processor)[0].Name).Trim() } catch { }
    $b = [int]$env:OSBUILD; $ubr = [int]$env:D_UBR
    # Every multi-CCD Ryzen - not only X3D - gets game-time core parking from the AMD PPM
    # Provisioning File Driver in the chipset package.
    if (($env:CPU_AMD -eq '1') -and ([int]$env:D_L3N -ge 2)) {
        $ppm = @(Get-CimInstance Win32_PnPEntity -Filter "Name LIKE '%PPM Provisioning%'" -ErrorAction SilentlyContinue)
        if ($ppm.Count -eq 0) { Report 'WARNING' 'Multi-CCD Ryzen without the AMD PPM Provisioning File Driver. Install the current AMD chipset driver: games then stay on one CCD instead of crossing between them'; $warn++ }
        else { Report 'INFO' 'AMD PPM Provisioning File Driver present - game-time CCD parking available' }
    }
    # Intel Application Optimization runs inside Dynamic Tuning Technology (Windows 11 only).
    if (($env:CPU_INTEL -eq '1') -and ($env:D_HYBRID -eq '1') -and ($b -ge 22000)) {
        if (($cpu -match '14[0-9]{3}(K|KF|KS|HX)\b') -or ($cpu -match 'Ultra [579] 2[0-9]{2}') -or ([int]$env:D_PCORES -ge 6)) {
            $dtt = @(Get-CimInstance Win32_PnPEntity -Filter "Name LIKE '%Innovation Platform Framework%' OR Name LIKE '%Dynamic Tuning%'" -ErrorAction SilentlyContinue)
            if ($dtt.Count -eq 0) { Report 'INFO' 'Intel Application Optimization (APO) is unavailable: it runs inside Intel Dynamic Tuning Technology. Enable DTT in the BIOS and install the board maker''s DTT / Innovation Platform Framework driver - up to 14 percent in supported games' }
            else { Report 'INFO' 'Intel Dynamic Tuning Technology present - Application Optimization can run in supported games' }
        }
    }
    # Core Ultra 200S/HX (Arrow Lake) needed a Windows power-management package and new microcode.
    if ($cpu -match 'Core\(TM\) Ultra [579] 2[0-9]{2}(?!V)') {
        $okBuild = ($b -gt 26200) -or ((($b -eq 26100) -or ($b -eq 26200)) -and ($ubr -ge 2161))
        if (-not $okBuild) { Report 'WARNING' ('Core Ultra 200 (Arrow Lake) on build ' + $b + '.' + $ubr + ': install the latest Windows 11 24H2 or newer update (26100.2161 or later). It adds the power-management package these CPUs need for full gaming performance'); $warn++ }
        try {
            $ur = (Get-ItemProperty -LiteralPath 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' -Name 'Update Revision' -ErrorAction Stop).'Update Revision'
            if (($ur -is [byte[]]) -and ($ur.Length -ge 8)) {
                $rev = [BitConverter]::ToUInt32($ur, 4)
                if (($rev -gt 0) -and ($rev -lt 0x114)) { Report 'WARNING' ('Arrow Lake microcode 0x' + $rev.ToString('X') + ' is older than 0x114, which fixed its gaming performance. Update the BIOS'); $warn++ }
            }
        } catch { }
    }
    # Firmware speed limits (thermal, power or VRM) are logged as Kernel-Processor-Power event 37.
    $thr = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-Processor-Power'; Id = 37; StartTime = (Get-Date).AddDays(-7) } -ErrorAction SilentlyContinue)
    if ($thr.Count -ge 10) { Report 'WARNING' ('The firmware limited CPU speed ' + $thr.Count + ' times in the last 7 days (Kernel-Processor-Power event 37: thermal, power or VRM limits). Check cooling, dust and BIOS power limits - throttling hits 1% lows first'); $warn++ }
    elseif ($thr.Count -gt 0) { Report 'INFO' ('The firmware limited CPU speed ' + $thr.Count + ' time(s) in the last 7 days (event 37) - usually brief, at boot or under heavy load') }
    # CPPC off in the BIOS removes preferred-core ranking (event 55, English text only).
    $e55 = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-Processor-Power'; Id = 55 } -MaxEvents 1 -ErrorAction SilentlyContinue)
    if ($e55.Count -and ([string]$e55[0].Message -match 'Performance state type') -and ([string]$e55[0].Message -notmatch 'Collaborative')) {
        Report 'WARNING' 'CPPC (Collaborative Processor Performance Control) appears to be off in the BIOS, so Windows cannot rank preferred cores. Enable CPPC and CPPC Preferred Cores in the BIOS'; $warn++
    }
    if (-not $warn) { Report 'INFO' 'No further CPU platform problem found' }
}

# ------------------------------------------------------------------------------------------
#  Phase 0b: memory optimizers (read only)
# ------------------------------------------------------------------------------------------
function Invoke-FpsRamOptimizerCheck {
    $rx = '(?i)EmptyStandbyList|RAMMap|memreduct|Mem Reduct|ISLC|standby list cleaner|CleanMem|WiseMemoryOptim|MemoryCleaner'
    $hits = @()
    foreach ($p in @(Get-Process -ErrorAction SilentlyContinue)) { if ([string]$p.ProcessName -match $rx) { $hits += ([string]$p.ProcessName + ' (running)') } }
    try {
        foreach ($t in @(Get-ScheduledTask -ErrorAction Stop)) {
            if ([string]$t.State -eq 'Disabled') { continue }
            foreach ($a in @($t.Actions)) { if (([string]$a.Execute + ' ' + [string]$a.Arguments) -match $rx) { $hits += ('task ' + $t.TaskName); break } }
        }
    } catch { }
    $runKeys = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run')
    if ($env:FPS_USID) { $runKeys += ('Registry::HKEY_USERS\' + $env:FPS_USID + '\Software\Microsoft\Windows\CurrentVersion\Run') }
    foreach ($rk in $runKeys) {
        if (-not (Test-Path -LiteralPath $rk)) { continue }
        $k = Get-Item -LiteralPath $rk
        foreach ($vn in @($k.GetValueNames())) { if (([string]$vn + ' ' + [string]$k.GetValue($vn)) -match $rx) { $hits += ('startup ' + $vn) } }
    }
    $hits = @($hits | Select-Object -Unique)
    if ($hits.Count) {
        Report 'WARNING' ('Memory "optimizer" found: ' + ($hits -join ', ') + '. Purging the standby list throws away cached game data, which comes back as hitches; ISLC also forces the timer resolution. Remove it unless a specific game leaks memory')
    } else { Report 'INFO' 'No standby-list cleaner or RAM optimizer found' }
}

# ------------------------------------------------------------------------------------------
#  Phase 0b: storage, game libraries and DirectStorage prerequisites (read only)
# ------------------------------------------------------------------------------------------
function Invoke-FpsStorageCheck {
    $warn = 0
    try {
        foreach ($pd in @(Get-PhysicalDisk -ErrorAction Stop)) {
            $nm = ([string]$pd.FriendlyName).Trim()
            if ([string]$pd.HealthStatus -match '^(Warning|Unhealthy|1|2)$') { Report 'WARNING' ('Drive ' + $nm + ' reports health ' + $pd.HealthStatus + ' - back up and replace it; failing drives stall game loading'); $warn++ }
            $rc = $null
            try { $rc = $pd | Get-StorageReliabilityCounter -ErrorAction Stop } catch { }
            if (-not $rc) { continue }
            if (($null -ne $rc.Wear) -and ([int]$rc.Wear -ge 90)) { Report 'WARNING' ('Drive ' + $nm + ' has used ' + $rc.Wear + ' percent of its rated write endurance'); $warn++ }
            if (($null -ne $rc.ReadErrorsUncorrected) -and ([int64]$rc.ReadErrorsUncorrected -gt 0)) { Report 'WARNING' ('Drive ' + $nm + ' has ' + $rc.ReadErrorsUncorrected + ' uncorrected read errors - back it up'); $warn++ }
            if (($null -ne $rc.Temperature) -and ([int]$rc.Temperature -ge 70)) { Report 'WARNING' ('Drive ' + $nm + ' is at ' + $rc.Temperature + ' C while the PC is idle; it will throttle under load. Improve its airflow or fit a heatsink'); $warn++ }
        }
    } catch { }

    $games = @(Get-FpsGameInstalls)
    $gameDrives = @($games | ForEach-Object { $_.Drive } | Select-Object -Unique)

    # BypassIO (Windows 11): lets DirectStorage reads skip parts of the file-system stack. A
    # third-party filter driver or a non-Microsoft storage driver blocks it. Only driver file
    # names are read from the output, so the display language does not matter.
    if (([int]$env:OSBUILD -ge 22000) -and ($env:FPS_DRYRUN -ne '1')) {
        $drives = @($gameDrives) + @($env:SystemDrive.Substring(0, 1))
        foreach ($dl in @($drives | ForEach-Object { $_.ToUpperInvariant() } | Select-Object -Unique)) {
            if ((Get-FpsDriveMedia ($dl + ':')) -ne 'SSD') { continue }
            $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            $txt = (@(& ($env:SystemRoot + '\System32\fsutil.exe') bypassio state ($dl + ':\') 2>$null) -join ' ')
            $ErrorActionPreference = $old
            $bad = @()
            foreach ($m in [regex]::Matches($txt, '(?i)\b([A-Za-z0-9_\-]+\.sys)\b')) {
                $f = Join-Path $env:SystemRoot ('System32\drivers\' + $m.Groups[1].Value)
                if (-not (Test-Path -LiteralPath $f)) { continue }
                $co = [string](Get-Item -LiteralPath $f).VersionInfo.CompanyName
                if ($co -and ($co -notmatch '(?i)microsoft')) { $bad += ($m.Groups[1].Value + ' (' + $co.Trim() + ')') }
            }
            $bad = @($bad | Select-Object -Unique)
            if ($bad.Count) { Report 'WARNING' ('BypassIO on ' + $dl + ': is blocked by ' + ($bad -join ', ') + '. DirectStorage games then read through the full file-system stack at a higher CPU cost; Intel RST/VMD drivers and some security or monitoring filters cause this'); $warn++ }
        }
    }

    # Compressed game folders: NTFS compression, or Windows Overlay (CompactGUI / compact /exe)
    # on the game executables. Reported, never changed.
    if (-not ('FpsFileSize' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class FpsFileSize {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern uint GetCompressedFileSizeW(string name, out uint high);
    public static long OnDisk(string name) {
        uint high;
        uint low = GetCompressedFileSizeW(name, out high);
        if ((low == 0xFFFFFFFF) && (Marshal.GetLastWin32Error() != 0)) { return -1; }
        return ((long)high << 32) + low;
    }
}
'@ -ErrorAction SilentlyContinue
    }
    $ntfs = @(); $wof = @()
    foreach ($gm in @($games | Select-Object -First 200)) {
        $g = [string]$gm.Path
        $di = Get-Item -LiteralPath $g -ErrorAction SilentlyContinue
        if (-not $di) { continue }
        if ($di.Attributes -band [IO.FileAttributes]::Compressed) { $ntfs += $di.Name; continue }
        if (-not ('FpsFileSize' -as [type])) { continue }
        $exe = @(Get-ChildItem -LiteralPath $g -Filter '*.exe' -File -Recurse -Depth 3 -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 1)
        if ($exe.Count -and ($exe[0].Length -gt 1MB)) {
            $od = [FpsFileSize]::OnDisk($exe[0].FullName)
            if (($od -ge 0) -and ($od -lt (0.9 * $exe[0].Length))) { $wof += $di.Name }
        }
    }
    if ($ntfs.Count) { Report 'WARNING' ('NTFS-compressed game folders: ' + (@($ntfs | Select-Object -First 6) -join ', ') + '. Every read is decompressed on the CPU while the game streams assets; uncompress them in folder Properties, Advanced'); $warn++ }
    if ($wof.Count) { Report 'INFO' ('Games compressed with CompactGUI or compact /exe: ' + (@($wof | Select-Object -First 6) -join ', ') + '. It saves space but costs CPU while loading; undo with compact /u /s /exe in the game folder if loading stutters') }
    if (-not $warn) { Report 'INFO' 'Drive health, DirectStorage prerequisites and game-folder compression look fine' }
}

# ------------------------------------------------------------------------------------------
#  Phase 0b: interrupt and DPC load (read only)
# ------------------------------------------------------------------------------------------
function Get-FpsCpuSnap {
    $rows = @()
    try { $rows = @(Get-CimInstance -ClassName Win32_PerfRawData_Counters_ProcessorInformation -ErrorAction Stop | Where-Object { [string]$_.Name -notmatch '_Total' }) } catch { }
    if (-not $rows.Count) { try { $rows = @(Get-CimInstance -ClassName Win32_PerfRawData_PerfOS_Processor -ErrorAction Stop | Where-Object { [string]$_.Name -ne '_Total' }) } catch { } }
    $h = @{}
    foreach ($r in $rows) { $h[[string]$r.Name] = @([double]$r.PercentDPCTime, [double]$r.PercentInterruptTime, [double]$r.InterruptsPersec, [double]$r.Timestamp_Sys100NS, [double]$r.Timestamp_PerfTime, [double]$r.Frequency_PerfTime) }
    return $h
}
function Get-FpsMedian ([double[]]$v) {
    if (-not $v -or $v.Count -eq 0) { return 0.0 }
    $s = [double[]]($v | Sort-Object)
    return $s[[int][math]::Floor(($s.Count - 1) / 2)]
}
function Invoke-FpsDpcCheck {
    # Three 2-second windows; each CPU's median decides, so one spike never raises a flag.
    $snaps = @(Get-FpsCpuSnap)
    for ($i = 0; $i -lt 3; $i++) { Start-Sleep -Seconds 2; $snaps += ,(Get-FpsCpuSnap) }
    $load = @{}; $ints = @{}
    for ($i = 1; $i -lt $snaps.Count; $i++) {
        $a = $snaps[$i - 1]; $b = $snaps[$i]
        foreach ($k in @($b.Keys)) {
            if (-not $a.ContainsKey($k)) { continue }
            $x = $a[$k]; $y = $b[$k]
            $dt = $y[3] - $x[3]; $dp = $y[4] - $x[4]
            if (($dt -le 0) -or ($dp -le 0) -or ($y[5] -le 0)) { continue }
            if (-not $load.ContainsKey($k)) { $load[$k] = @(); $ints[$k] = @() }
            $load[$k] += (100.0 * (($y[0] - $x[0]) + ($y[1] - $x[1])) / $dt)
            $ints[$k] += (($y[2] - $x[2]) / ($dp / $y[5]))
        }
    }
    if ($load.Count -eq 0) { Report 'SKIP' 'Processor performance counters are unavailable - interrupt and DPC load not measured' }
    else {
        $med = @{}; $imed = @{}
        foreach ($k in $load.Keys) { $med[$k] = Get-FpsMedian ([double[]]$load[$k]); $imed[$k] = Get-FpsMedian ([double[]]$ints[$k]) }
        $all = [math]::Max(0.5, (Get-FpsMedian ([double[]]@($med.Values))))
        $hot = @($med.Keys | Where-Object { $med[$_] -ge 10 } | Sort-Object { $med[$_] } -Descending)
        $warm = @($med.Keys | Where-Object { ($med[$_] -ge 3) -and ($med[$_] -lt 10) -and ($med[$_] -ge 3 * $all) })
        $storm = @($imed.Keys | Where-Object { $imed[$_] -ge 30000 })
        if ($hot.Count) { Report 'WARNING' ('CPU ' + (@($hot | ForEach-Object { $_ + ' ' + [math]::Round($med[$_], 1) + '%' }) -join ', ') + ' spends that much time in driver interrupts and DPCs on an idle desktop. Game threads scheduled there stutter; LatencyMon names the driver - usually network, audio, storage, RGB or an outdated chipset driver') }
        elseif ($warm.Count) { Report 'INFO' ('CPU ' + (@($warm | ForEach-Object { $_ + ' ' + [math]::Round($med[$_], 1) + '%' }) -join ', ') + ' carries most of the driver interrupt and DPC work - fine unless you see periodic stutter') }
        else { Report 'INFO' ('Driver interrupt and DPC load is low on every CPU (highest ' + [math]::Round((@($med.Values) | Measure-Object -Maximum).Maximum, 1) + '%)') }
        if ($storm.Count) { Report 'INFO' ('CPU ' + ($storm -join ', ') + ' takes more than 30,000 interrupts per second at idle - a device is interrupting constantly; LatencyMon shows which') }
    }

    # Line-based interrupts shared by PCI devices. MSI interrupts appear as numbers of 2^31 and up.
    try {
        $cls = @{}
        foreach ($e in @(Get-CimInstance Win32_PnPEntity -ErrorAction Stop)) { $cls[[string]$e.DeviceID] = @([string]$e.PNPClass, [string]$e.Name) }
        $byIrq = @{}
        foreach ($a in @(Get-CimInstance Win32_PNPAllocatedResource -ErrorAction Stop)) {
            # Only IRQ resources carry IRQNumber; memory, port and DMA references do not.
            $irqv = $a.Antecedent.IRQNumber
            if ($null -eq $irqv) { continue }
            $irq = [int64]$irqv
            $dev = [string]$a.Dependent.DeviceID
            if (($irq -ge 2147483648) -or ($dev -notlike 'PCI\*')) { continue }
            if (-not $byIrq.ContainsKey($irq)) { $byIrq[$irq] = @() }
            $byIrq[$irq] += $dev
        }
        $crit = @('Display', 'USB', 'MEDIA', 'HDC', 'SCSIAdapter')
        foreach ($irq in @($byIrq.Keys)) {
            $devs = @($byIrq[$irq] | Select-Object -Unique)
            if ($devs.Count -lt 2) { continue }
            $names = @($devs | ForEach-Object { if ($cls.ContainsKey($_)) { $cls[$_][1] } else { $_ } })
            $nCrit = @($devs | Where-Object { $cls.ContainsKey($_) -and ($crit -contains $cls[$_][0]) }).Count
            if ($nCrit -ge 2) { Report 'WARNING' ('IRQ ' + $irq + ' is shared by ' + ($names -join ' + ') + '. Each interrupt makes Windows ask every device on the line; updating the drivers usually switches them to MSI') }
            else { Report 'INFO' ('IRQ ' + $irq + ' is shared by ' + ($names -join ' + ')) }
        }
    } catch { }

    # Interrupt affinity pins left by tuning tools that name no existing CPU.
    $n = [Environment]::ProcessorCount
    $valid = [uint64]0
    if ($n -ge 64) { $valid = [uint64]::MaxValue } else { $valid = [uint64]([math]::Pow(2, $n) - 1) }
    foreach ($e in @(Get-ChildItem -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Enum\PCI' -ErrorAction SilentlyContinue)) {
        foreach ($inst in @(Get-ChildItem -LiteralPath $e.PSPath -ErrorAction SilentlyContinue)) {
            $ap = Join-Path $inst.PSPath 'Device Parameters\Interrupt Management\Affinity Policy'
            $pol = Get-ItemProperty -LiteralPath $ap -ErrorAction SilentlyContinue
            if ((-not $pol) -or ([int]$pol.DevicePolicy -ne 4) -or (-not ($pol.AssignmentSetOverride -is [byte[]]))) { continue }
            $mb = New-Object byte[] 8
            [Array]::Copy($pol.AssignmentSetOverride, $mb, [math]::Min(8, $pol.AssignmentSetOverride.Length))
            $mask = [BitConverter]::ToUInt64($mb, 0)
            if (($mask -band $valid) -eq 0) { Report 'WARNING' ('Interrupt affinity for ' + $e.PSChildName + ' is pinned to CPUs that do not exist (mask 0x' + $mask.ToString('X') + '). Delete its Affinity Policy values under Device Parameters\Interrupt Management') }
        }
    }
}

# ------------------------------------------------------------------------------------------
#  Phase 0b: audio (read only; the audio service owns these keys)
# ------------------------------------------------------------------------------------------
function Invoke-FpsAudioCheck {
    $root = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'
    $found = 0
    foreach ($ep in @(Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue)) {
        $st = (Get-ItemProperty -LiteralPath $ep.PSPath -Name DeviceState -ErrorAction SilentlyContinue).DeviceState
        if ([int]$st -ne 1) { continue }
        $props = Get-Item -LiteralPath (Join-Path $ep.PSPath 'Properties') -ErrorAction SilentlyContinue
        if (-not $props) { continue }
        $name = [string]$props.GetValue('{a45c254e-df1c-4efd-8020-67d146a850e0},2')
        if (-not $name) { $name = 'audio output' }
        $fmt = $props.GetValue('{f19f064d-082c-4e27-bc73-6882a1bb8e4c},0')
        if (($fmt -is [byte[]]) -and ($fmt.Length -ge 16)) {
            $rate = [BitConverter]::ToUInt32($fmt, 12)
            if (($rate -ge 8000) -and ($rate -le 768000)) {
                $found++
                if ($rate -gt 48000) { Report 'INFO' ($name + ' mixes at ' + $rate + ' Hz. Games render at 48000 Hz, so every stream is resampled and mixed at the higher rate; 48000 Hz in Sound settings, device properties, is enough for games') }
            }
        }
    }
    if (-not $found) { Report 'SKIP' 'No active audio output format could be read' }
}

# ------------------------------------------------------------------------------------------
#  Phase 1: leftovers from tweak packs
# ------------------------------------------------------------------------------------------
function Invoke-FpsMemoryLeftovers {
    $k = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    $it = Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue
    $n = 0
    # Pool and cache sizes have been dynamic since Vista; the kernel reads cache sizes from CPUID.
    foreach ($v in @('SecondLevelDataCache', 'PagedPoolSize', 'NonPagedPoolSize', 'PagedPoolQuota', 'NonPagedPoolQuota', 'SystemPages')) {
        $cur = $it.$v
        if (($null -eq $cur) -or ([int64]$cur -eq 0)) { continue }
        $n++
        Apply ('Resetting ' + $v + ' from ' + $cur + ' to the Windows default 0') { Set-ItemProperty -LiteralPath $k -Name $v -Value 0 -Type DWord }
    }
    foreach ($v in @('PoolUsageMaximum', 'LargePageMinimum')) {
        if ($null -eq $it.$v) { continue }
        $n++
        Apply ('Removing ' + $v + ' - not a client memory-manager setting') { Remove-ItemProperty -LiteralPath $k -Name $v }
    }
    $sm = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $si = Get-ItemProperty -LiteralPath $sm -ErrorAction SilentlyContinue
    foreach ($v in @('HeapDeCommitFreeBlockThreshold', 'HeapDeCommitTotalFreeThreshold')) {
        if ($null -eq $si.$v) { continue }
        $n++
        Apply ('Removing ' + $v + ' - a server heap setting with no gaming effect') { Remove-ItemProperty -LiteralPath $sm -Name $v }
    }
    if (-not $n) { Report 'SKIP' 'No memory-manager leftovers from tweak packs found' }
}

function Invoke-FpsInputLeftovers {
    $root = 'HKCU:'
    if ($env:FPS_USID) { $root = 'Registry::HKEY_USERS\' + $env:FPS_USID }
    # Windows 11 limits background raw-mouse listeners (Discord, overlays, mouse and RGB tools)
    # to about 125 Hz, which fixed game stutter with 1000 Hz+ mice. 0 turns that fix off.
    $mk = $root + '\Control Panel\Mouse'
    $rt = (Get-ItemProperty -LiteralPath $mk -Name RawMouseThrottleEnabled -ErrorAction SilentlyContinue).RawMouseThrottleEnabled
    if (($null -ne $rt) -and ([int]$rt -eq 0)) {
        Apply 'Restoring background raw-mouse throttling - RawMouseThrottleEnabled removed' { Remove-ItemProperty -LiteralPath $mk -Name RawMouseThrottleEnabled }
    } else { Report 'SKIP' 'Background raw-mouse throttling is at the Windows default' }
    # Filter Keys on with an acceptance delay: every key must be held that long to register.
    $fk = Get-ItemProperty -LiteralPath ($root + '\Control Panel\Accessibility\Keyboard Response') -ErrorAction SilentlyContinue
    if ($fk) {
        $fl = 0; $dl = 0
        [void][int]::TryParse([string]$fk.Flags, [ref]$fl)
        [void][int]::TryParse([string]$fk.DelayBeforeAcceptance, [ref]$dl)
        if (($fl -band 1) -and ($dl -gt 0)) { Report 'WARNING' ('Filter Keys is on: every key press must be held ' + $dl + ' ms before it counts. Turn it off in Settings, Accessibility, Keyboard unless you need it') }
    }
}

# ------------------------------------------------------------------------------------------
#  Phase 4: pagefile and commit
# ------------------------------------------------------------------------------------------
function Invoke-FpsPagefile {
    $cs = @(Get-CimInstance Win32_ComputerSystem)[0]
    $auto = [bool]$cs.AutomaticManagedPagefile
    $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB)
    $usage = @(Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue)
    $sets = @(Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue)
    $warn = 0
    $live = @($usage | Where-Object { [int64]$_.AllocatedBaseSize -ge 64 })
    if ((-not $auto) -and ($live.Count -eq 0)) {
        $warn++
        Report 'WARNING' 'No pagefile is active. The commit limit then equals physical memory, and games that commit more stall or crash with out-of-memory errors'
        $free = 0
        try { $free = [math]::Round(@(Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='" + $env:SystemDrive + "'"))[0].FreeSpace / 1GB) } catch { }
        if ($env:CFG_PAGEFILE_RESTORE -ne '1') { Report 'SKIP' 'CFG_PAGEFILE_RESTORE is 0 - pagefile left off' }
        elseif ($free -lt 16) { Report 'SKIP' ('Only ' + $free + ' GB free on ' + $env:SystemDrive + ' - free space first, then re-enable the pagefile') }
        else {
            Apply 'Re-enabling a system-managed pagefile (active after the reboot)' { Set-CimInstance -InputObject $cs -Property @{ AutomaticManagedPagefile = $true } }
            if (-not (Test-FpsDry)) { Write-FpsData 'REBOOT_REQ' 1 }
        }
    }
    if ((-not $auto) -and ($sets.Count -gt 0)) {
        $sysManaged = @($sets | Where-Object { ([int64]$_.InitialSize -eq 0) -and ([int64]$_.MaximumSize -eq 0) }).Count
        $maxMB = [int64](@($sets | ForEach-Object { [int64]$_.MaximumSize }) | Measure-Object -Sum).Sum
        $need = 4096
        if ($ramGB -le 8) { $need = 16384 } elseif ($ramGB -le 16) { $need = 8192 }
        if ((-not $sysManaged) -and ($maxMB -gt 0) -and ($maxMB -lt $need)) {
            Report 'WARNING' ('The pagefile is fixed at ' + $maxMB + ' MB with ' + $ramGB + ' GB of RAM. Current games commit 20 GB and more; set it to System managed size'); $warn++
        }
        foreach ($u in $live) {
            if (([int64]$u.PeakUsage -gt 0) -and ([int64]$u.PeakUsage -ge 0.9 * [int64]$u.AllocatedBaseSize)) {
                Report 'WARNING' ('Pagefile ' + $u.Name + ' has been ' + [math]::Round(100 * $u.PeakUsage / $u.AllocatedBaseSize) + ' percent full since boot - enlarge it or set System managed size'); $warn++
            }
        }
    }
    if (-not ('FpsPerf' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class FpsPerf {
    [StructLayout(LayoutKind.Sequential)]
    public struct PI {
        public uint cb; public UIntPtr CommitTotal; public UIntPtr CommitLimit; public UIntPtr CommitPeak;
        public UIntPtr PhysicalTotal; public UIntPtr PhysicalAvailable; public UIntPtr SystemCache;
        public UIntPtr KernelTotal; public UIntPtr KernelPaged; public UIntPtr KernelNonpaged;
        public UIntPtr PageSize; public uint HandleCount; public uint ProcessCount; public uint ThreadCount;
    }
    [DllImport("psapi.dll", SetLastError = true)]
    static extern bool GetPerformanceInfo(out PI pi, uint cb);
    public static ulong[] Read() {
        PI p;
        if (!GetPerformanceInfo(out p, (uint)Marshal.SizeOf(typeof(PI)))) { return new ulong[0]; }
        ulong ps = p.PageSize.ToUInt64();
        return new ulong[] { p.CommitTotal.ToUInt64() * ps, p.CommitLimit.ToUInt64() * ps, p.CommitPeak.ToUInt64() * ps };
    }
}
'@ -ErrorAction SilentlyContinue
    }
    if ('FpsPerf' -as [type]) {
        $c = [FpsPerf]::Read()
        if ($c.Count -eq 3 -and $c[1] -gt 0) {
            $pct = [math]::Round(100.0 * $c[2] / $c[1])
            Report 'INFO' ('Memory commit: peak ' + [math]::Round($c[2] / 1GB, 1) + ' GB of a ' + [math]::Round($c[1] / 1GB, 1) + ' GB limit since boot')
            if ($pct -ge 85) { Report 'WARNING' ('Commit peaked at ' + $pct + ' percent of the limit since boot - close to the point where Windows refuses allocations. Enlarge the pagefile or add RAM'); $warn++ }
        }
    }
    $ex = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Resource-Exhaustion-Detector'; Id = 2004; StartTime = (Get-Date).AddDays(-30) } -ErrorAction SilentlyContinue)
    if ($ex.Count) { Report 'WARNING' ('Windows ran low on virtual memory ' + $ex.Count + ' time(s) in the last 30 days (event 2004). Games stall or crash when it happens; enlarge or re-enable the pagefile'); $warn++ }
    if ($live.Count -and ($env:D_SYSDISK -eq 'SSD')) {
        $hdd = @($live | Where-Object { (Get-FpsDriveMedia ([string]$_.Name)) -eq 'HDD' })
        if ($hdd.Count -eq $live.Count) { Report 'INFO' ('Every pagefile is on a hard disk (' + (@($hdd | ForEach-Object { $_.Name }) -join ', ') + ') while the system drive is an SSD. Put a system-managed pagefile on the SSD') }
    }
    if (-not $warn) { Report 'SKIP' 'Pagefile and memory commit are healthy' }
}

# ------------------------------------------------------------------------------------------
#  Phase 5: scheduled drive optimization (SSD retrim) back on if another tool disabled it
# ------------------------------------------------------------------------------------------
function Invoke-FpsDefragTask {
    $t = Get-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag\' -TaskName 'ScheduledDefrag' -ErrorAction SilentlyContinue
    if (-not $t) { Report 'SKIP' 'Scheduled drive optimization task not present'; return }
    if ([string]$t.State -ne 'Disabled') { Report 'SKIP' 'Scheduled drive optimization is on - it re-trims SSDs'; return }
    Apply 'Re-enabling scheduled drive optimization - SSD retrim' { Enable-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag\' -TaskName 'ScheduledDefrag' | Out-Null }
}

# ------------------------------------------------------------------------------------------
#  Phase 6: shader cache integrity (read only)
# ------------------------------------------------------------------------------------------
function Invoke-FpsShaderCacheCheck {
    $prof = Get-FpsUserProfile
    $local = Join-Path $prof 'AppData\Local'
    $paths = [ordered]@{
        'DirectX' = (Join-Path $local 'D3DSCache'); 'NVIDIA DirectX' = (Join-Path $local 'NVIDIA\DXCache'); 'NVIDIA OpenGL' = (Join-Path $local 'NVIDIA\GLCache')
        'AMD DirectX 11' = (Join-Path $local 'AMD\DxCache'); 'AMD DirectX 12' = (Join-Path $local 'AMD\DxcCache'); 'AMD Vulkan' = (Join-Path $local 'AMD\VkCache')
        'Intel' = (Join-Path $local 'Intel\ShaderCache'); 'Intel (LocalLow)' = (Join-Path $prof 'AppData\LocalLow\Intel\ShaderCache')
    }
    $bad = 0; $seen = 0
    foreach ($nm in $paths.Keys) {
        $p = $paths[$nm]
        if (-not (Test-Path -LiteralPath $p)) { continue }
        $seen++
        $it = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
        if (-not $it) { continue }
        if (-not $it.PSIsContainer) { Report 'WARNING' ($nm + ' shader cache path is a file, which blocks the cache - games recompile shaders every launch. Delete that file'); $bad++; continue }
        if ($it.Attributes -band [IO.FileAttributes]::ReparsePoint) { Report 'WARNING' ($nm + ' shader cache is redirected elsewhere (' + (@($it.Target) -join ' ') + '). If that is a RAM disk, the cache is lost at every boot and games recompile shaders'); $bad++ }
        try {
            $deny = @((Get-Acl -LiteralPath $p -ErrorAction Stop).Access | Where-Object { [string]$_.AccessControlType -eq 'Deny' })
            if ($deny.Count) { Report 'WARNING' ($nm + ' shader cache folder has a Deny permission entry - drivers cannot write the cache. Remove it in the folder''s Security tab'); $bad++ }
        } catch { }
        if ($it.Attributes -band [IO.FileAttributes]::Compressed) { Report 'INFO' ($nm + ' shader cache folder is NTFS-compressed - every cache read costs CPU; uncompress it') }
    }
    # AMD: the driver's own shader-cache switch. 30 00 is off; other values are left alone.
    foreach ($k in @(Get-ChildItem -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue)) {
        if ($k.PSChildName -notmatch '^\d{4}$') { continue }
        $v = (Get-ItemProperty -LiteralPath (Join-Path $k.PSPath 'UMD') -Name ShaderCache -ErrorAction SilentlyContinue).ShaderCache
        if (($v -is [byte[]]) -and ($v.Length -ge 1) -and ($v[0] -eq 0x30)) { Report 'WARNING' 'AMD shader cache is turned off in the driver. In AMD Software, Graphics, set Shader Cache to AMD optimized - games otherwise compile shaders again every launch'; $bad++ }
    }
    if ($env:FPS_USID) {
        $sp = Get-ItemProperty -LiteralPath ('Registry::HKEY_USERS\' + $env:FPS_USID + '\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy') -ErrorAction SilentlyContinue
        if ($sp -and ([int]$sp.'01' -eq 1)) { Report 'INFO' 'Storage Sense is on. It can still empty the DirectX shader cache on its own schedule - if games recompile shaders after a clean-up, turn Storage Sense off' }
    }
    if ($seen -and (-not $bad)) { Report 'SKIP' ([string]$seen + ' shader cache folders found, all writable and local') }
    elseif (-not $seen) { Report 'SKIP' 'No shader cache folders exist yet' }
}

# ------------------------------------------------------------------------------------------
#  Phase 6: undocumented GPU interrupt priority written by v4 and tweak packs
# ------------------------------------------------------------------------------------------
function Invoke-FpsGpuPriorityCleanup {
    $n = 0
    foreach ($v in @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue)) {
        $id = [string]$v.PNPDeviceID
        if (-not $id.StartsWith('PCI')) { continue }
        $ap = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $id + '\Device Parameters\Interrupt Management\Affinity Policy'
        $dp = (Get-ItemProperty -LiteralPath $ap -Name DevicePriority -ErrorAction SilentlyContinue).DevicePriority
        if (($null -eq $dp) -or ([int]$dp -ne 3)) { continue }
        $n++
        Apply ('Removing undocumented DevicePriority = 3 from ' + $v.Name) { Remove-ItemProperty -LiteralPath $ap -Name DevicePriority }
    }
    if (-not $n) { Report 'SKIP' 'No GPU DevicePriority override present' }
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

# Services games and controllers need, back to manual start if another tool disabled them.
function Invoke-FpsGameServices {
    $n = 0
    $list = @(
        @('XboxGipSvc', 'Xbox Accessory Management', 'Manual'), @('GameInputSvc', 'GameInput', 'Manual'),
        @('bthserv', 'Bluetooth Support', 'Manual'), @('hidserv', 'Human Interface Device Service', 'Manual'),
        @('XblAuthManager', 'Xbox Live Auth Manager', 'Manual'), @('XblGameSave', 'Xbox Live Game Save', 'Manual'),
        @('GamingServices', 'Gaming Services', 'Automatic'), @('MMCSS', 'Multimedia Class Scheduler', 'Automatic'),
        @('Audiosrv', 'Windows Audio', 'Automatic'), @('AudioEndpointBuilder', 'Windows Audio Endpoint Builder', 'Automatic'))
    foreach ($it in $list) {
        $s = @(Get-CimInstance Win32_Service -Filter ("Name='" + $it[0] + "'") -ErrorAction SilentlyContinue)
        if ((-not $s.Count) -or ([string]$s[0].StartMode -ne 'Disabled')) { continue }
        $n++
        $sn = $it[0]; $st = $it[2]
        Apply ($it[1] + ' re-enabled - ' + $st + ' start, as Windows ships it') { Set-Service -Name $sn -StartupType $st }
    }
    if (-not $n) { Report 'SKIP' 'Controller, audio, MMCSS and Xbox services are not disabled' }
}

# SysMain back to automatic start where this script no longer disables it (below 32 GB of
# RAM): memory compression and page combining run inside SysMain.
function Invoke-FpsSysMainRestore {
    $s = @(Get-CimInstance Win32_Service -Filter "Name='SysMain'" -ErrorAction SilentlyContinue)
    if (-not $s.Count) { Report 'SKIP' 'SysMain is not installed'; return }
    if ([string]$s[0].StartMode -ne 'Disabled') { Report 'SKIP' ('SysMain starts ' + $s[0].StartMode + ' - memory compression available'); return }
    Apply 'SysMain back to automatic start - memory compression works again' {
        Set-Service -Name 'SysMain' -StartupType Automatic
        Start-Service -Name 'SysMain' -ErrorAction SilentlyContinue
    }
}

function Invoke-FpsAppraiserCheck {
    $t = @(Get-ScheduledTask -TaskPath '\Microsoft\Windows\Application Experience\' -ErrorAction SilentlyContinue | Where-Object { ([string]$_.TaskName -like 'Microsoft Compatibility Appraiser*') -and ([string]$_.State -eq 'Disabled') })
    if ($t.Count) { Report 'INFO' 'The Microsoft Compatibility Appraiser task is disabled (an earlier version of this script did that). If Windows Update stops offering a new Windows version, re-enable it in Task Scheduler - it refreshes feature-update eligibility' }
}

# ------------------------------------------------------------------------------------------
#  Phase 14: per-title settings
# ------------------------------------------------------------------------------------------
function Invoke-FpsGameKeys {
    $list = @()
    foreach ($raw in ([string]$env:CFG_GAME_EXES -split ';')) {
        $g = $raw.Trim().Trim([char]34)
        if (-not $g) { continue }
        if (($g.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) -or ($g -eq '.') -or ($g -eq '..') -or $g.EndsWith('.') -or $g.EndsWith(' ')) {
            Report 'FAILED' ('Game priority: ' + $g) 'Use an executable filename, not a path or invalid Windows filename'; continue
        }
        $list += $g
    }
    foreach ($g in $list) {
        # High CPU priority class. Game Mode resets it for titles it recognises, so this matters
        # for the rest. I/O priority above Normal is not applied through this key, and page
        # priority 5 is already the default, so neither is written.
        $keyName = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\' + $g + '\PerfOptions'
        Apply ('Game ' + $g + ': CpuPriorityClass = 3 (High)') {
            $key = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($keyName)
            if ($null -eq $key) { throw 'Cannot create PerfOptions key' }
            try { $key.SetValue('CpuPriorityClass', 3, [Microsoft.Win32.RegistryValueKind]::DWord) } finally { $key.Dispose() }
        }
        # Debugging leftovers under the same key slow the game far more than any tweak gains.
        $ifeo = Get-ItemProperty -LiteralPath ('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\' + $g) -ErrorAction SilentlyContinue
        if ($ifeo) {
            $gf = [int64]0
            if ($null -ne $ifeo.GlobalFlag) { try { if ($ifeo.GlobalFlag -is [string]) { $gf = [Convert]::ToInt64(($ifeo.GlobalFlag -replace '^0[xX]', ''), 16) } else { $gf = [int64]$ifeo.GlobalFlag } } catch { } }
            if (($gf -band 0x02000000) -or ($null -ne $ifeo.VerifierDlls) -or ($null -ne $ifeo.Debugger)) {
                Report 'WARNING' ($g + ' runs with page heap, Application Verifier or a debugger attached through Image File Execution Options. Remove GlobalFlag, VerifierDlls and Debugger from its key unless you are debugging it')
            }
        }
    }
    # Dual-CCD 3D V-Cache: listed games that Game Bar does not recognise still get the cache CCD.
    if (($env:D_X3D -eq '2') -and $list.Count) {
        $pref = 'HKLM:\SYSTEM\CurrentControlSet\Services\amd3dvcache\Preferences'
        if (-not (Test-Path -LiteralPath $pref)) { Report 'SKIP' 'AMD 3D V-Cache driver preferences not present - per-game cache preference not written'; return }
        $known = @{}
        foreach ($k in @(Get-ChildItem -LiteralPath (Join-Path $pref 'App') -ErrorAction SilentlyContinue)) {
            $e = [string]$k.GetValue('EndsWith')
            if ($e) { $known[$e.ToLowerInvariant()] = $true }
        }
        foreach ($g in $list) {
            if ($known.ContainsKey($g.ToLowerInvariant())) { Report 'SKIP' ($g + ' already has a 3D V-Cache preference'); continue }
            Apply ('3D V-Cache: ' + $g + ' prefers the cache CCD') {
                $kp = Join-Path $pref ('App\FPS_' + $g)
                if (-not (Test-Path -LiteralPath $kp)) { New-Item -Path $kp -Force | Out-Null }
                New-ItemProperty -LiteralPath $kp -Name 'EndsWith' -Value $g -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $kp -Name 'Type' -Value 1 -PropertyType DWord -Force | Out-Null
            }
        }
    }
}

# ------------------------------------------------------------------------------------------
#  Phase 0b: GPU platform (read only). Resizable BAR and PCIe link for AMD and Intel cards
#  (NVIDIA is covered by the nvidia-smi check), HAGS support from the driver itself, and a
#  documented bad driver / Windows combination.
# ------------------------------------------------------------------------------------------
function Invoke-FpsGpuPlatform {
    $warn = 0
    if (-not ('FpsGpu' -as [type])) {
        try {
            Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public static class FpsGpu {
  // ---------- cfgmgr32: BAR windows and PCIe link (no vendor tools, no admin needed) ----------
  [StructLayout(LayoutKind.Sequential)] struct DEVPROPKEY { public Guid fmtid; public uint pid; }
  [DllImport("cfgmgr32.dll", CharSet=CharSet.Unicode)] static extern int CM_Locate_DevNodeW(out uint dn, string id, uint flags);
  [DllImport("cfgmgr32.dll", CharSet=CharSet.Unicode)] static extern int CM_Get_Device_IDW(uint dn, StringBuilder buf, int len, uint flags);
  [DllImport("cfgmgr32.dll")] static extern int CM_Get_Parent(out uint parent, uint dn, uint flags);
  [DllImport("cfgmgr32.dll", CharSet=CharSet.Unicode)] static extern int CM_Get_DevNode_PropertyW(uint dn, ref DEVPROPKEY key, out uint type, byte[] buf, ref uint size, uint flags);
  [DllImport("cfgmgr32.dll")] static extern int CM_Get_First_Log_Conf(out IntPtr lc, uint dn, uint flags);
  [DllImport("cfgmgr32.dll")] static extern int CM_Get_Next_Res_Des(out IntPtr next, IntPtr cur, uint forRes, out uint resId, uint flags);
  [DllImport("cfgmgr32.dll")] static extern int CM_Get_Res_Des_Data_Size(out uint size, IntPtr rd, uint flags);
  [DllImport("cfgmgr32.dll")] static extern int CM_Get_Res_Des_Data(IntPtr rd, byte[] buf, uint size, uint flags);
  [DllImport("cfgmgr32.dll")] static extern int CM_Free_Res_Des_Handle(IntPtr rd);
  [DllImport("cfgmgr32.dll")] static extern int CM_Free_Log_Conf_Handle(IntPtr lc);
  static readonly Guid PciProps = new Guid("3ab22e31-8264-4b4e-9af5-a8d2d8e33e62");

  // Largest memory range currently assigned to the device (ResType_Mem=1, ResType_MemLarge=7).
  // MEM_DES / MEM_LARGE_DES: DWORD Count, DWORD Type, DWORDLONG Alloc_Base (offset 8), DWORDLONG Alloc_End (offset 16).
  // ALLOC_LOG_CONF (2) only: BOOT_LOG_CONF is the firmware assignment from before Windows resizes the BAR.
  public static long LargestWindow(string instanceId) {
    uint dn; IntPtr lc;
    if (CM_Locate_DevNodeW(out dn, instanceId, 0) != 0) return -1;
    if (CM_Get_First_Log_Conf(out lc, dn, 2) != 0) return -1;
    long best = 0; IntPtr cur = lc;
    try {
      while (true) {
        IntPtr next; uint type;
        if (CM_Get_Next_Res_Des(out next, cur, 0, out type, 0) != 0) break;
        if (cur != lc) CM_Free_Res_Des_Handle(cur);
        cur = next;
        if (type != 1 && type != 7) continue;
        uint size;
        if (CM_Get_Res_Des_Data_Size(out size, next, 0) != 0 || size < 24) continue;
        byte[] d = new byte[size];
        if (CM_Get_Res_Des_Data(next, d, size, 0) != 0) continue;
        ulong b = BitConverter.ToUInt64(d, 8), e = BitConverter.ToUInt64(d, 16);
        if (e > b && (long)(e - b + 1) > best) best = (long)(e - b + 1);
      }
      if (cur != lc) CM_Free_Res_Des_Handle(cur);
    } finally { CM_Free_Log_Conf_Handle(lc); }
    return best;
  }

  static int U32Prop(uint dn, uint pid) {
    DEVPROPKEY k = new DEVPROPKEY(); k.fmtid = PciProps; k.pid = pid;
    uint t; uint sz = 4; byte[] b = new byte[4];
    if (CM_Get_DevNode_PropertyW(dn, ref k, out t, b, ref sz, 0) != 0 || sz != 4) return -1;
    return (int)BitConverter.ToUInt32(b, 0);
  }
  static string DevId(uint dn) { StringBuilder sb = new StringBuilder(512); return CM_Get_Device_IDW(dn, sb, sb.Capacity, 0) == 0 ? sb.ToString() : ""; }

  // {CurrentWidth, MaxWidth, CurrentSpeed, MaxSpeed, SlotMaxSpeed} of the card's link to the slot. Speed 1..6 = PCIe gen 1..6.
  // Radeon (RX 5000+) and Arc sit behind an internal PCIe switch of their own vendor: the endpoint only reports
  // its link to that switch, so walk up through same-vendor switch ports (DeviceType 9 upstream / 10 downstream)
  // and stop before the root port (8) or any third-party switch.
  public static int[] Link(string instanceId) {
    uint dn; if (CM_Locate_DevNodeW(out dn, instanceId, 0) != 0) return null;
    string ven = instanceId.Length >= 12 ? instanceId.Substring(0, 12).ToUpperInvariant() : "";
    while (true) {
      uint p; if (CM_Get_Parent(out p, dn, 0) != 0) break;
      string pid = DevId(p).ToUpperInvariant();
      int dt = U32Prop(p, 1);
      if (ven.Length == 12 && pid.StartsWith(ven) && (dt == 9 || dt == 10)) dn = p; else break;
    }
    uint rp; int rpMax = CM_Get_Parent(out rp, dn, 0) == 0 ? U32Prop(rp, 11) : -1;   // slot (root/switch port) max speed
    return new int[] { U32Prop(dn, 10), U32Prop(dn, 12), U32Prop(dn, 9), U32Prop(dn, 11), rpMax };
  }

  // ---------- D3DKMT: HAGS capability, VRAM, adapter name, LUID ----------
  [StructLayout(LayoutKind.Sequential)] struct ENUMADAPTERS2 { public uint NumAdapters; public IntPtr pAdapters; }
  [StructLayout(LayoutKind.Sequential)] struct ADAPTERINFO { public uint hAdapter; public uint LuidLow; public int LuidHigh; public uint NumOfSources; public int bPrecisePresentRegionsPreferred; }
  [StructLayout(LayoutKind.Sequential)] struct QUERYADAPTERINFO { public uint hAdapter; public int Type; public IntPtr pData; public uint DataSize; }
  [StructLayout(LayoutKind.Sequential)] struct CLOSEADAPTER { public uint hAdapter; }
  [DllImport("gdi32.dll")] static extern int D3DKMTEnumAdapters2(ref ENUMADAPTERS2 e);
  [DllImport("gdi32.dll")] static extern int D3DKMTQueryAdapterInfo(ref QUERYADAPTERINFO q);
  [DllImport("gdi32.dll")] static extern int D3DKMTCloseAdapter(ref CLOSEADAPTER c);

  public class Adapter {
    public string Name = ""; public string Luid = "";
    public long DedicatedVram = -1;   // D3DKMT_SEGMENTSIZEINFO.DedicatedVideoMemorySize
    public int AdapterType = -1;      // D3DKMT_ADAPTERTYPE bits: 0 Render, 1 Display, 2 Software, 4 HybridDiscrete, 5 HybridIntegrated
    public int Hags = -1;             // D3DKMT_WDDM_2_7_CAPS: bit0 HwSchSupported, bit1 HwSchEnabled, bit2 HwSchEnabledByDefault
  }
  static int Query(uint h, int type, byte[] buf) {
    GCHandle g = GCHandle.Alloc(buf, GCHandleType.Pinned);
    try {
      QUERYADAPTERINFO q = new QUERYADAPTERINFO(); q.hAdapter = h; q.Type = type;
      q.pData = g.AddrOfPinnedObject(); q.DataSize = (uint)buf.Length;
      return D3DKMTQueryAdapterInfo(ref q);
    } finally { g.Free(); }
  }
  public static Adapter[] Adapters() {
    List<Adapter> list = new List<Adapter>();
    ENUMADAPTERS2 e = new ENUMADAPTERS2();
    if (D3DKMTEnumAdapters2(ref e) != 0 || e.NumAdapters == 0) return list.ToArray();
    int sz = Marshal.SizeOf(typeof(ADAPTERINFO));
    e.pAdapters = Marshal.AllocHGlobal(sz * (int)e.NumAdapters);
    try {
      if (D3DKMTEnumAdapters2(ref e) != 0) return list.ToArray();
      for (int i = 0; i < e.NumAdapters; i++) {
        ADAPTERINFO ai = (ADAPTERINFO)Marshal.PtrToStructure(new IntPtr(e.pAdapters.ToInt64() + i * sz), typeof(ADAPTERINFO));
        Adapter a = new Adapter();
        a.Luid = string.Format("luid_0x{0:X8}_0x{1:X8}", ai.LuidHigh, ai.LuidLow);
        byte[] reg = new byte[4 * 260 * 2];                       // KMTQAITYPE_ADAPTERREGISTRYINFO = 8
        if (Query(ai.hAdapter, 8, reg) == 0) a.Name = Encoding.Unicode.GetString(reg, 0, 520).TrimEnd('\0').Split('\0')[0];
        byte[] seg = new byte[24];                                // KMTQAITYPE_GETSEGMENTSIZE = 3
        if (Query(ai.hAdapter, 3, seg) == 0) a.DedicatedVram = BitConverter.ToInt64(seg, 0);
        byte[] at = new byte[4];                                  // KMTQAITYPE_ADAPTERTYPE = 15
        if (Query(ai.hAdapter, 15, at) == 0) a.AdapterType = BitConverter.ToInt32(at, 0);
        byte[] c27 = new byte[4];                                 // KMTQAITYPE_WDDM_2_7_CAPS = 70 (Windows 10 2004+)
        if (Query(ai.hAdapter, 70, c27) == 0) a.Hags = BitConverter.ToInt32(c27, 0) & 7;
        CLOSEADAPTER c = new CLOSEADAPTER(); c.hAdapter = ai.hAdapter; D3DKMTCloseAdapter(ref c);
        list.Add(a);
      }
    } finally { Marshal.FreeHGlobal(e.pAdapters); }
    return list.ToArray();
  }
}
'@ -ErrorAction Stop
        } catch { Report 'SKIP' 'GPU helper could not be compiled - Resizable BAR, PCIe and HAGS checks skipped'; return }
    }
    $ig = 'Intel.*(UHD|Iris|HD Graphics)|Intel\(R\) Graphics|Intel\(R\) Arc\(TM\) Graphics|Radeon\(TM\) (Graphics|[0-9]+M)|Radeon Vega'
    $cls = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\'
    $gpus = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { ([string]$_.PNPDeviceID -like 'PCI\*') -and ([string]$_.Name -notmatch $ig) })
    $adapters = @()
    try { $adapters = @([FpsGpu]::Adapters()) } catch { }
    foreach ($v in $gpus) {
        $id = [string]$v.PNPDeviceID
        if ($id -match 'VEN_10DE') { continue }
        $vram = [int64]0
        try {
            $drv = (Get-PnpDeviceProperty -InstanceId $id -KeyName 'DEVPKEY_Device_Driver' -ErrorAction Stop).Data
            $q = (Get-ItemProperty -LiteralPath ($cls + $drv) -Name 'HardwareInformation.qwMemorySize' -ErrorAction Stop).'HardwareInformation.qwMemorySize'
            if ($q -is [byte[]]) { $vram = [BitConverter]::ToInt64($q, 0) } else { $vram = [int64]$q }
        } catch { }
        if ($vram -le 0) { $a = @($adapters | Where-Object { $_.Name -eq $v.Name }); if ($a.Count) { $vram = [int64]$a[0].DedicatedVram } }
        $win = [int64]-1
        try { $win = [FpsGpu]::LargestWindow($id) } catch { }
        if (($win -gt 0) -and ($vram -ge 2GB)) {
            $arc = ($id -match 'VEN_8086') -and ($v.Name -match 'Arc\(TM\) (Pro )?[AB][0-9]{2,3}')
            $cap = $arc -or (($id -match 'VEN_1002') -and ($v.Name -match 'RX\s*(6|7|9)[0-9]{3}'))
            if ($win -gt 512MB) { Report 'INFO' ($v.Name + ': Resizable BAR on (' + [math]::Round($win / 1GB, 1) + ' GB window)') }
            elseif ($arc) { Report 'WARNING' ($v.Name + ': Resizable BAR is OFF. Intel Arc depends on it - average FPS and especially 1% lows drop sharply without it. In the BIOS: Above 4G Decoding and Re-Size BAR on, CSM off'); $warn++ }
            elseif ($cap) { Report 'WARNING' ($v.Name + ': Smart Access Memory / Resizable BAR is off. Enable Above 4G Decoding and Re-Size BAR in the BIOS (UEFI boot, CSM off); supported games gain several percent'); $warn++ }
        }
        $l = $null
        try { $l = [FpsGpu]::Link($id) } catch { }
        if ($l -and ($l[0] -gt 0) -and ($l[1] -gt 0)) {
            if (($l[0] -lt $l[1]) -and ($env:D_CHASSIS -ne 'LAPTOP')) { Report 'WARNING' ($v.Name + ' runs at PCIe x' + $l[0] + ' of x' + $l[1] + '. Use the top full-length slot; M.2 drives sharing lanes and riser cables also cause this'); $warn++ }
            elseif (($l[1] -le 8) -and ($l[4] -gt 0) -and ($l[3] -gt $l[4])) { Report 'INFO' ($v.Name + ' is an x' + $l[1] + ' card (PCIe ' + $l[3] + '.0) in a PCIe ' + $l[4] + '.0 slot - it loses bandwidth there, most when video memory fills up') }
        }
    }
    # HAGS support as the driver reports it; the batch writes HwSchMode only on NVIDIA cards
    # that support it - DLSS frame generation needs it there.
    $ad = @($adapters | Where-Object { ($_.Hags -ge 0) -and (-not ($_.AdapterType -band 4)) })
    $nv = @($ad | Where-Object { $_.Name -match 'NVIDIA' })
    if ($nv.Count) { Write-FpsData 'D_HAGSOK' ([int](@($nv | Where-Object { $_.Hags -band 1 }).Count -gt 0)) }
    foreach ($a in $ad) {
        if (-not ($a.Hags -band 1)) { continue }
        $st = 'off'; if ($a.Hags -band 2) { $st = 'on' }
        Report 'INFO' ($a.Name + ': hardware-accelerated GPU scheduling supported, currently ' + $st)
    }
    # October 2025 Windows update (UBR 6899+) with an NVIDIA driver older than 581.94: some
    # games lost up to half their frame rate until the 581.94 hotfix.
    if ((($env:OSBUILD -eq '26100') -or ($env:OSBUILD -eq '26200')) -and ([int]$env:D_UBR -ge 6899)) {
        foreach ($v in @($gpus | Where-Object { [string]$_.PNPDeviceID -match 'VEN_10DE' })) {
            $d = ([string]$v.DriverVersion) -replace '\.', ''
            if ($d.Length -lt 5) { continue }
            $nvv = [int]$d.Substring($d.Length - 5)
            if ($nvv -lt 58194) { Report 'WARNING' ($v.Name + ': driver ' + [math]::Floor($nvv / 100) + '.' + ('{0:D2}' -f ($nvv % 100)) + ' predates 581.94. With the October 2025 Windows update this combination lost up to half the frame rate in some games - install 581.94 or newer'); $warn++ }
        }
    }
    if (-not $warn) { Report 'INFO' 'No further GPU platform problem found' }
}

# ------------------------------------------------------------------------------------------
#  Phase 1: more leftovers from tweak packs and earlier versions
# ------------------------------------------------------------------------------------------
function Invoke-FpsShellLeftovers {
    $d = (Get-FpsUserRegRoot) + '\Control Panel\Desktop'
    $it = Get-ItemProperty -LiteralPath $d -ErrorAction SilentlyContinue
    $n = 0
    if ($it -and ([string]$it.AutoEndTasks -eq '1')) {
        $n++
        Apply 'AutoEndTasks back to 0 - Windows asks again before closing apps with unsaved work' { Set-ItemProperty -LiteralPath $d -Name 'AutoEndTasks' -Value '0' -Type String }
    }
    foreach ($v in @('HungAppTimeout', 'WaitToKillAppTimeout', 'LowLevelHooksTimeout')) {
        if ((-not $it) -or ($null -eq $it.$v)) { continue }
        $n++
        $vn = $v
        Apply ('Removing ' + $vn + ' = ' + $it.$vn + ' - back to the Windows default') { Remove-ItemProperty -LiteralPath $d -Name $vn }
    }
    if (-not $n) { Report 'SKIP' 'No shutdown or input-hook timeout leftovers' }
}

function Invoke-FpsSystemIfeoLeftovers {
    $base = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
    $n = 0
    foreach ($exe in @('csrss.exe', 'dwm.exe', 'audiodg.exe', 'lsass.exe', 'svchost.exe', 'SearchIndexer.exe', 'smss.exe', 'wininit.exe', 'winlogon.exe', 'services.exe', 'fontdrvhost.exe', 'ctfmon.exe')) {
        $k = $base + '\' + $exe + '\PerfOptions'
        if (-not (Test-Path -LiteralPath $k)) { continue }
        $n++
        $kk = $k
        Apply ('Removing priority overrides from system process ' + $exe) { Remove-Item -LiteralPath $kk -Recurse }
    }
    if (-not $n) { Report 'SKIP' 'No priority overrides on Windows system processes' }
}

function Invoke-FpsGpuLeftovers {
    $n = 0
    $gd = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
    $g = Get-ItemProperty -LiteralPath $gd -ErrorAction SilentlyContinue
    if ($g -and ($null -ne $g.TdrLevel) -and ([int]$g.TdrLevel -eq 0)) {
        $n++
        Apply 'Removing TdrLevel = 0 - a hung GPU recovers again instead of freezing the PC' { Remove-ItemProperty -LiteralPath $gd -Name 'TdrLevel' }
    }
    if ($g -and ($null -ne $g.TdrDelay) -and ([int]$g.TdrDelay -gt 10)) { Report 'INFO' ('TdrDelay is ' + $g.TdrDelay + ' s - no FPS effect, and some creative apps need it raised, so it is left as found') }
    $sch = $gd + '\Scheduler'
    $ep = (Get-ItemProperty -LiteralPath $sch -Name 'EnablePreemption' -ErrorAction SilentlyContinue).EnablePreemption
    if (($null -ne $ep) -and ([int]$ep -eq 0)) {
        $n++
        Apply 'Removing EnablePreemption = 0 - long GPU work can no longer block the desktop compositor' { Remove-ItemProperty -LiteralPath $sch -Name 'EnablePreemption' }
    }
    foreach ($k in @(Get-ChildItem -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue)) {
        if ($k.PSChildName -notmatch '^\d{4}$') { continue }
        $p = Get-ItemProperty -LiteralPath $k.PSPath -ErrorAction SilentlyContinue
        if (-not $p) { continue }
        $dn = [string]$p.DriverDesc
        foreach ($pair in @(@('KMD_EnableComputePreemption', 0), @('DisablePreemption', 1), @('DisableCudaContextPreemption', 1), @('RMHdcpKeyglobZero', 1))) {
            $cur = $p.($pair[0])
            if (($null -eq $cur) -or ([int64]$cur -ne [int64]$pair[1])) { continue }
            $n++
            $vn = [string]$pair[0]; $kp = $k.PSPath
            Apply ('Removing ' + $vn + ' from ' + $dn) { Remove-ItemProperty -LiteralPath $kp -Name $vn }
        }
        $clk = @(@('PerfLevelSrc', 'DisableDynamicPstate', 'PowerMizerEnable', 'PowerMizerLevel', 'PowerMizerLevelAC') | Where-Object { $null -ne $p.$_ })
        if ($clk.Count) { Report 'INFO' ($dn + ': clock-locking values ' + ($clk -join ', ') + ' are set. They hold maximum clocks and add idle power and heat without helping GPU-bound games; left as found') }
    }
    if ($env:CFG_DISABLE_MPO -ne '1') {
        $ot = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name 'OverlayTestMode' -ErrorAction SilentlyContinue).OverlayTestMode
        $do = (Get-ItemProperty -LiteralPath $gd -Name 'DisableOverlays' -ErrorAction SilentlyContinue).DisableOverlays
        if (([int]$ot -eq 5) -or ([int]$do -eq 1)) { Report 'INFO' 'Multi-plane overlay is switched off by an earlier tweak (OverlayTestMode 5 or DisableOverlays 1). Windowed and borderless games then always go through desktop composition; unless you set it to fix flicker, delete those values' }
    }
    $gc = Get-ItemProperty -LiteralPath ((Get-FpsUserRegRoot) + '\System\GameConfigStore') -ErrorAction SilentlyContinue
    if (($env:CFG_DISABLE_FSO -ne '1') -and $gc -and ([int]$gc.GameDVR_FSEBehaviorMode -eq 2) -and ([int]$gc.GameDVR_HonorUserFSEBehaviorMode -eq 1)) {
        Report 'INFO' 'Fullscreen optimizations are off for every game (GameConfigStore FSEBehaviorMode 2 with HonorUserFSEBehaviorMode 1, which earlier versions of this script also wrote). Games then use legacy exclusive fullscreen - fine in older DX9 / DX11 titles, but it blocks Auto HDR and the windowed-game flip model. To restore the Windows default, set GameDVR_HonorUserFSEBehaviorMode to 0'
    }
    if (-not $n) { Report 'SKIP' 'No GPU driver leftovers from tweak packs' }
}
