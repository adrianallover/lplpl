@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "ERRORLEVEL="
rem A separate worker lets this console display an unexpected CMD exit.
rem No administrator prompt or automatic elevation is performed.
if defined NQ_BATCH_WORKER goto :NQ_WORKER
set "NQ_SELF=%~f0"
set "NQ_BATCH_WORKER=1"
set "NQ_CMD=%SystemRoot%\System32\cmd.exe"
if exist "%SystemRoot%\Sysnative\cmd.exe" set "NQ_CMD=%SystemRoot%\Sysnative\cmd.exe"
rem Only the child launch uses delayed expansion; the worker disables it immediately.
rem This expands the filename once without reinterpreting literal percent signs or bangs.
"%NQ_CMD%" /d /e:on /v:on /s /c ""!NQ_SELF!""
set "NQ_EXIT=%errorlevel%"
echo(
if not "%NQ_EXIT%"=="0" echo    [FAILED] Script returned exit code %NQ_EXIT%. Review the messages above.
echo    [DONE] Press any key to close this script.
pause >nul
endlocal & exit /b %NQ_EXIT%

:NQ_WORKER
set "NQ_SELF=%~f0"
set "NQ_BIN=%SystemRoot%\System32"
set "NQ_PS=%NQ_BIN%\WindowsPowerShell\v1.0\powershell.exe"
set "NQ_OK=0"
set "NQ_FAIL=0"
set "NQ_SKIP=0"
title NetLatency Tuner v4 - ping / jitter / packet loss / bufferbloat
rem ASCII / CRLF, no BOM. CMD never executes the PowerShell payload below.
rem The loader reads the payload as data; paths and application names are not code.
rem In literal batch configuration, write %% to store a single percent sign.

rem ==========================================================================================
rem  WHAT THIS DOES - every change has a measurable mechanism on current Windows 10 and 11, and
rem  nothing here spends CPU time that a game thread could have used:
rem   * FINDS THE LOSS FIRST: timed pings to the router and the internet, a UDP test that sees
rem     what game packets see, Windows' own drop counters, link-drop and driver-reset events,
rem     Wi-Fi signal, channel congestion and disconnects read from the Windows Wi-Fi API
rem   * FPS GUARD: interrupt moderation, checksum and segmentation offloads, RSS queues,
rem     RSC, URO and packet coalescing all back to their CPU-saving defaults; network
rem     throttling back to 10; hidden single-core RSS overrides removed; MSI, interrupt
rem     load, traffic shapers, packet filters and security suites in the packet path reported
rem   * LINK POWER SAVING OFF: EEE, green and idle modes on every vendor's own keyword, Intel
rem     DMA coalescing off, idle power-down only while nobody uses the PC, NIC kept powered
rem   * WI-FI AT FULL STRENGTH: transmit power and roaming back to the driver default on
rem     every vendor, MIMO and U-APSD power save off, 5 GHz preferred only where its signal
rem     is good, 20 MHz on 2.4 GHz, no hunting for other networks while connected
rem   * RECEIVE RING up to 2048 descriptors, oversized transmit ring back to default
rem   * DSCP 46 for games - automatically withdrawn if this line drops marked packets
rem   * BACKGROUND TRANSFERS CAPPED: Windows Update, Store and OneDrive, in fixed KB/s when
rem     your line speed is entered below
rem   * REPAIRS of harmful leftovers from other optimizers: low TTL, SACK off, tiny socket
rem     buffers, early TCP give-up, oversized MTU, disabled DNS client, NLA or connectivity
rem     probing, unbound QoS scheduler, CTCP or NewReno congestion control
rem
rem  v4 against v3.1 - fixes found by per-vendor driver research:
rem   * MediaTek (AMD RZ6xx) Wi-Fi counts transmit power 0 = highest, 2 = lowest: the old
rem     "maximum number" rule set the LOWEST power. Power now returns to the driver default
rem   * "Idle Power Down Restriction" was switched the wrong way by name matching; now 1
rem   * roaming back to default on Intel, Realtek, MediaTek and Qualcomm keywords - "lowest"
rem     keeps the PC on a weak access point, and steering routers then force it off
rem   * vendor keyword tables instead of English display names, so non-English Windows works
rem   * Intel I225 check now targets the real erratum revision; I226 driver check added;
rem     1 Gbps and faster Speed and Duplex choices no longer raise a false mismatch warning
rem   * RSC, URO, packet coalescing and network throttling back to Windows defaults: none of
rem     them delays a game packet, and turning them off only cost CPU during downloads
rem   * voice-app marking off: on Wi-Fi, Windows sends DSCP 34 in the same queue as the game
rem
rem  DELIBERATELY EXCLUDED - placebo, obsolete, unproven or harmful on current Windows:
rem   * interrupt moderation off, offloads off, RSS off, MSI mode or affinity pinning: each
rem     saves microseconds and costs CPU time on the cores the game runs on
rem   * TcpNoDelay, TcpDelAckTicks, TcpWindowSize, GlobalMaxTcpWindowSize, MaxUserPort,
rem     IRPStackSize, LargeSystemCache, DefaultTTL tuning: ignored, TCP-only or server-only
rem   * NonBestEffortLimit 0: the reserved-20-percent-bandwidth story is a myth
rem   * NetworkThrottlingIndex off: games never reach the 10 packets per ms cap, and the cap
rem     stops download DPC bursts from stealing frame time
rem   * SystemResponsiveness: a CPU reservation for media, not a network setting
rem   * auto-tuning disabled, CTCP, chimney, DCA, NetDMA: removed from Windows or harmful
rem   * BBR2: loopback stalls on Windows 11 23H2 and 24H2; LEDBAT for all TCP demotes games
rem   * disabling IPv6, Teredo, NetBIOS, LLMNR, NCSI probing: breaks features, no ping change
rem   * DNS flush, Winsock or IP reset, ARP or cache clearing: forbidden here, no in-game effect
rem   * power plans and powercfg: out of scope by design
rem   * changing DNS servers: only affects name lookups before a match, never in-game ping
rem   * WLAN AutoConfig off: stops scans but also every reconnect after a drop or reboot
rem   * PnPCapabilities on Wi-Fi: breaks Modern Standby; Wi-Fi idle is handled per keyword
rem   * flow control off: pause frames stop the NIC dropping frames when a switch falls behind
rem   * 802.1p priority tags: some routers and modems drop tagged frames outright
rem   * forcing 5 or 6 GHz channel width, wireless mode or 802.11 standard: the router decides
rem ==========================================================================================

rem ==========================================================================================
rem  CONFIG      1 = on      0 = off
rem ==========================================================================================
rem  Your connection speed from a speed test, in whole Mbit/s. With these filled in, Windows
rem  Update, Store and OneDrive get firm KB/s caps and cloud-sync apps an upload cap.
rem  0 = unknown - percentage caps are used instead.
set "NQ_DOWN_MBPS=0"
set "NQ_UP_MBPS=0"

rem  Game executables whose packets get DSCP-marked. Semicolon separated, exe name only.
rem  On Wi-Fi, Windows sends DSCP 46 in the WMM video queue, ahead of ordinary traffic; SQM
rem  routers running CAKE put it in their priority tin. A game not installed costs nothing.
rem  Minecraft Java runs as javaw.exe; add it only if you accept marking every Java program.
set "NQ_GAMES=cs2.exe;VALORANT-Win64-Shipping.exe;FortniteClient-Win64-Shipping.exe;r5apex.exe;r5apex_dx12.exe;cod.exe;Overwatch.exe;RainbowSix.exe;RainbowSix_Vulkan.exe;dota2.exe;League of Legends.exe;RocketLeague.exe;TslGame.exe;Marvel-Win64-Shipping.exe;Discovery.exe;EscapeFromTarkov.exe;destiny2.exe;RustClient.exe;HaloInfinite.exe;RobloxPlayerBeta.exe;Minecraft.Windows.exe;GTA5.exe;GTA5_Enhanced.exe;DeadByDaylight-Win64-Shipping.exe;Warframe.x64.exe;Wow.exe;ffxiv_dx11.exe;LostArk.exe;osu!.exe;deadlock.exe;tf_win64.exe;StreetFighter6.exe;Polaris-Win64-Shipping.exe;BF2042.exe;HuntGame.exe;aces.exe;WorldOfTanks.exe;SquadGame.exe;FallGuys_client_game.exe;GenshinImpact.exe;NarakaBladepoint.exe;Brawlhalla.exe"
set "NQ_DSCP=1"
set "NQ_DSCP_VALUE=46"
rem  Withdraw game marking when the UDP test shows this connection dropping marked packets.
set "NQ_DSCP_AUTO=1"

rem  Voice apps. Off by default: Discord also carries screen share and uploads, and on Wi-Fi
rem  Windows would queue them with the game. When on: DSCP 26, UDP only - ordinary WMM queue.
set "NQ_VOICE=Discord.exe;TeamSpeak.exe;ts3client_win64.exe;mumble.exe"
set "NQ_DSCP_VOICE=0"
set "NQ_VOICE_DSCP=26"

rem  FPS guard: CPU-saving NIC features back to their driver defaults, hidden single-core RSS
rem  overrides removed. Leave at 1.
set "NQ_FPS_GUARD=1"

rem  Interrupt moderation off. 0 = driver default, batched interrupts. 1 = one interrupt per
rem  packet: a fraction of a millisecond sooner, at a CPU cost that lowered FPS in testing.
set "NQ_INTMOD_OFF=0"

rem  Receive ring raised to the driver maximum, at most 2048 descriptors. Never lowered.
set "NQ_RX_MAX=1"

rem  Explicit Congestion Notification for TCP flows.
set "NQ_ECN=1"

rem  Wired adapters: clear "Allow the computer to turn off this device". An idle NIC that powers
rem  down - USB adapters especially - delays or drops the first packets after a quiet moment.
set "NQ_NIC_POWER_OFF=1"

rem  Intel I225 first revision linked at 2.5 Gbps: advertise 1 Gbps, Intel's own workaround
rem  for the frame drops of that chip. Nothing happens on any other adapter.
set "NQ_I225_1G=1"

rem  Wi-Fi radio: MIMO and U-APSD power save off, vendor sleep modes off, and Windows stops
rem  hunting for other networks while connected. Transmit power and roaming always return to
rem  the driver default.
set "NQ_WIFI_TUNE=1"

rem  Wi-Fi band preference: 5 = prefer 5 GHz, 6 = prefer 6 GHz where offered, 0 = leave.
rem  Skipped automatically where the router's 5 GHz signal is too weak.
set "NQ_WIFI_BAND=5"

rem  2.4 GHz links only: channel width 20 MHz instead of 40, fewer corrupted frames.
set "NQ_WIFI_24_20MHZ=1"

rem  Background-scan blocking on older Intel drivers that still show it:
rem  1 = only while the signal is good, 2 = always, which also blocks finding a better AP.
set "NQ_WIFI_BGSCAN=1"

rem  Return what v3.0 changed to driver or Windows defaults: wireless mode, wired Adaptive IFS
rem  and the Ethernet interface metric 10. Settings already at default report SAME.
set "NQ_UNDO_V30=1"

rem  Stop the Windows location service on Wi-Fi PCs, so apps cannot trigger Wi-Fi scans for
rem  positioning. Apps lose location. Your FPS script may already turn it off.
set "NQ_WIFI_LOCATION_OFF=0"

rem  Diagnostics before any change, about 60 seconds: pings to the router, the first ISP hops
rem  and three internet hosts at once, hop-by-hop loss, path MTU. Targets must be IPv4
rem  addresses. Put your game server's IP in NQ_TRACE_TARGET to trace that route instead.
set "NQ_PATH_TEST=1"
set "NQ_PING_TARGETS=1.1.1.1;8.8.8.8;9.9.9.9"
set "NQ_TRACE_TARGET="
set "NQ_DIAG_SECONDS=30"

rem  Loaded-latency test: fills the download, then the upload, for 8 seconds each over HTTPS
rem  (speed.cloudflare.com) and measures how far ping rises - your bufferbloat grade. Moves
rem  up to 0.5 GB on fast lines; skipped automatically on metered connections and while a
rem  listed game runs. 0 = off.
set "NQ_LOAD_TEST=1"

rem  UDP loss test: DNS queries to this resolver, unmarked and DSCP-marked - the loss game
rem  packets see, and whether this line drops marked packets. About 10 seconds.
set "NQ_UDP_TEST=1"
set "NQ_UDP_TARGET=1.1.1.1"

rem  Stop and disable SmartByte, Rivet and Killer prioritization services if installed.
set "NQ_SHAPERS_OFF=1"

rem  Background Windows Update and Store downloads: at most N percent of the line. 0 = leave.
set "NQ_DO_BG_PCT=50"

rem  OneDrive uploads: at most N percent of the upload, 10-99. 0 = leave.
set "NQ_ONEDRIVE_UP_PCT=50"

rem  Per-interface TcpAckFrequency=1. Only helps TCP-based games such as WoW or FFXIV.
rem  Doubles ACK packets during large TCP downloads, so leave 0 on slow-upload connections.
set "NQ_TCP_ACK1=0"

rem  Move NIC receive processing, the RSS base CPU, off CPU 0. Situational: enable only if
rem  LatencyMon shows CPU 0 already overloaded with interrupt and DPC work.
set "NQ_RSS_OFF_CPU0=0"

rem  Upload cap in kbit/s for the sync apps below. 0 = 60 percent of NQ_UP_MBPS when that
rem  is set, otherwise no cap.
set "NQ_UPCAP_KBPS=0"
set "NQ_BULK_APPS=OneDrive.exe;Dropbox.exe;GoogleDriveFS.exe"

rem  Dry run: start the script with NQ_DRYRUN=1 in the environment to see every change it
rem  would make without making any. Normal runs leave this at 0.
if not defined NQ_DRYRUN set "NQ_DRYRUN=0"
rem ==========================================================================================

if "%NQ_DRYRUN%"=="1" goto :NQ_BANNER
"%NQ_BIN%\fltmc.exe" >nul 2>&1
if not errorlevel 1 goto :NQ_BANNER
echo(
echo    [FAILED] Administrator rights are required. Right-click the script and choose
echo             Run as administrator. Nothing was changed.
exit /b 1

:NQ_BANNER
echo(
echo  ==========================================================================================
echo    NetLatency Tuner v4 - in-game ping, jitter, lag spikes, packet loss, bufferbloat
echo  ==========================================================================================
if "%NQ_DRYRUN%"=="1" echo    DRY RUN: every change is reported and nothing is modified.
echo    About 90 seconds of read-only tests run first. Changed adapters are restarted at the
echo    end: expect a 5-15 second disconnect.
echo    Rebinding QoS can also reconnect an adapter earlier in the original sequence.
echo    Do not run this mid-match or over Remote Desktop.
echo(
echo    Press any key to start, or close this window to abort.
pause >nul

rem Windows build, read from VER so it does not depend on the display language.
set "NQ_BUILD=0"
for /f "tokens=6 delims=[]. " %%A in ('ver') do set "NQ_BUILD=%%A"
set "NQ_BUILDN="
set /a "NQ_BUILDN=NQ_BUILD" >nul 2>&1
if not defined NQ_BUILDN set "NQ_BUILDN=0"
rem An unreadable build is treated as current, so nothing is silently skipped.
if "%NQ_BUILDN%"=="0" set "NQ_BUILDN=99999"

echo(
echo  -- [1/3] Windows TCP/IP and UDP stack
call :NETSH "int tcp set global autotuninglevel=normal" "TCP receive auto-tuning = normal - undoes the throughput-killing 'disabled' myth"
call :NETSH "int tcp set global rss=enabled" "Receive Side Scaling on - NIC receive work spread across cores, fewer ring overflows"
call :NETSH "int tcp set global rsc=enabled" "TCP Receive Segment Coalescing at the Windows default - it only merges segments inside one receive pass, so it adds no delay, and turning it off burns CPU during downloads"
if "%NQ_ECN%"=="1" call :NETSH "int tcp set global ecncapability=enabled" "ECN on - AQM/SQM routers can signal congestion without dropping packets"
if %NQ_BUILDN% GEQ 17763 goto :NQ_LOSSREC
call :NQ_SKIPMSG "HyStart and PRR: not available before Windows 10 1809"
goto :NQ_LOSSREC_DONE
:NQ_LOSSREC
call :NETSH "int tcp set global hystart=enabled" "HyStart on - TCP slow start exits before it overfills the modem queue and drops packets"
call :NETSH "int tcp set global prr=enabled" "Proportional Rate Reduction on - loss recovery without burst retransmissions or timeouts"
:NQ_LOSSREC_DONE
call :NETSH "int ip set global taskoffload=enabled" "IP task offload on - undoes CPU-burning 'offload off' tweaks"
if %NQ_BUILDN% GEQ 26100 goto :NQ_URO
call :NQ_SKIPMSG "UDP Receive Offload: not present before Windows 11 24H2"
goto :NQ_URO_DONE
:NQ_URO
call :NETSH "int udp set global uro=enabled" "UDP Receive Offload at the Windows default - game sockets never receive merged datagrams, so turning it off only costs CPU"
:NQ_URO_DONE

echo(
echo  -- [2/3] Throttling and background-traffic policy
call :REG "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" REG_DWORD 10 "MMCSS network throttling at the Windows default 10 - games send far below 10 packets/ms, and the cap keeps download DPC bursts from stealing frame time"
call :REG "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" "Do not use NLA" REG_SZ 1 "QoS DSCP policies enforced on non-domain PCs"
call :REG "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" REG_DWORD 0 "Delivery Optimization P2P off - PC stops seeding updates over your uplink"


echo(
echo  -- [3/3] Adapter, driver, QoS engine and repairs
if not exist "%NQ_PS%" goto :NQ_PS_MISSING
"%NQ_PS%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try{ $text=[IO.File]::ReadAllText($env:NQ_SELF); $tag=[Environment]::NewLine+':NQ_POWERSHELL'+[Environment]::NewLine; $at=$text.IndexOf($tag,[StringComparison]::Ordinal); if($at -lt 0){throw 'Embedded PowerShell marker not found'}; . ([scriptblock]::Create($text.Substring($at+$tag.Length))) }catch{ [Console]::WriteLine('     [FAILED] PowerShell engine: '+$_.Exception.Message); exit 1 }"
set "NQ_ENGINE_EXIT=%errorlevel%"
if not "%NQ_ENGINE_EXIT%"=="0" echo    [FAILED] Adapter/QoS engine returned exit code %NQ_ENGINE_EXIT%.
goto :NQ_FINISH

:NQ_PS_MISSING
echo    [FAILED] Windows PowerShell is unavailable. Adapter/QoS stage could not run.
set "NQ_ENGINE_EXIT=1"

:NQ_FINISH
echo(
echo  ==========================================================================================
echo    [DONE] Processing finished. Review each OK, FAILED, SAME, SKIP and WARNING above.
echo    Reboot once so successful stack and driver changes are fully active.
echo    Then run it again: the diagnostics print loss as "lost of sent" with a 95 percent
echo    range, say where any remaining loss starts - Wi-Fi or cable, the ISP line, or beyond -
echo    and grade bufferbloat. A loss range that stays under 1 percent means the goal is met.
echo    In-game net graphs count lost game packets, not pings: compare them after the reboot.
echo  ==========================================================================================
if "%NQ_DRYRUN%"=="1" echo    DRY RUN: nothing was changed.
if not "%NQ_FAIL%"=="0" exit /b 1
if not "%NQ_ENGINE_EXIT%"=="0" exit /b 1
exit /b 0

:NETSH
rem NETSH arguments below come only from the fixed call sites in this file.
set "NQ_ARGS=%~1"
set "NQ_TEXT=%~2"
setlocal EnableDelayedExpansion
echo(     [NETSH] Applying: !NQ_TEXT!
echo(             netsh !NQ_ARGS!
endlocal
if "%NQ_DRYRUN%"=="1" goto :NQ_WOULD
"%NQ_BIN%\netsh.exe" %NQ_ARGS%
set "NQ_RC=%errorlevel%"
if not "%NQ_RC%"=="0" goto :NETSH_FAILED
set /a NQ_OK+=1 >nul
setlocal EnableDelayedExpansion
echo(     [OK] !NQ_TEXT!
endlocal
exit /b 0
:NETSH_FAILED
set /a NQ_FAIL+=1 >nul
setlocal EnableDelayedExpansion
echo(     [FAILED] !NQ_TEXT!; exit code !NQ_RC!. See the NETSH response above.
endlocal
exit /b 0

:REG
set "NQ_KEY=%~1"
set "NQ_VALUE=%~2"
set "NQ_TYPE=%~3"
set "NQ_DATA=%~4"
set "NQ_TEXT=%~5"
setlocal EnableDelayedExpansion
echo(     [REGISTRY] Applying: !NQ_TEXT!
echo(                !NQ_KEY! : !NQ_VALUE! = !NQ_DATA! [!NQ_TYPE!]
endlocal
if "%NQ_DRYRUN%"=="1" goto :NQ_WOULD
"%NQ_BIN%\reg.exe" add "%NQ_KEY%" /v "%NQ_VALUE%" /t "%NQ_TYPE%" /d "%NQ_DATA%" /f >nul
set "NQ_RC=%errorlevel%"
if not "%NQ_RC%"=="0" goto :REG_FAILED
set /a NQ_OK+=1 >nul
setlocal EnableDelayedExpansion
echo(     [OK] !NQ_TEXT!
endlocal
exit /b 0
:REG_FAILED
set /a NQ_FAIL+=1 >nul
setlocal EnableDelayedExpansion
echo(     [FAILED] !NQ_TEXT!; exit code !NQ_RC!.
endlocal
exit /b 0

:NQ_WOULD
rem Dry run: count and report the change without making it.
set /a NQ_OK+=1 >nul
setlocal EnableDelayedExpansion
echo(     [WOULD] !NQ_TEXT!
endlocal
exit /b 0

:NQ_SKIPMSG
set "NQ_TEXT=%~1"
set /a NQ_SKIP+=1 >nul
setlocal EnableDelayedExpansion
echo(     [SKIP] !NQ_TEXT!
endlocal
exit /b 0

rem All batch paths terminate above. Only the loader parses the remaining text.
:NQ_POWERSHELL
# ==========================================================================================
#  PowerShell engine: adapter, driver, QoS and repair work. Only runs when launched by the
#  batch part. Every NIC setting is addressed by its language-independent RegistryKeyword and
#  is only written if the driver exposes that keyword AND offers the target value; vendor
#  power-saving modes under unknown keywords are found by display name as a second pass.
#  Every write passes through Change, so NQ_DRYRUN=1 reports the full plan and writes nothing.
# ==========================================================================================
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$script:NQ_Applied = [int]$env:NQ_OK
$script:NQ_Failed  = [int]$env:NQ_FAIL
$script:NQ_Skipped = [int]$env:NQ_SKIP
$script:NQ_Same    = 0
$script:NQ_Warned  = 0
$script:NQ_Dry     = ([string]$env:NQ_DRYRUN -eq '1')
$script:NqViaWifi  = $false
$script:NqEfDropped = $false
$script:NqRunStart  = Get-Date
$script:NqWifi      = @{}

function Flag ([string]$n) { return ([Environment]::GetEnvironmentVariable($n) -eq '1') }
function Num ([string]$n, [int]$fallback) {
    $v = 0
    if ([int]::TryParse([string][Environment]::GetEnvironmentVariable($n), [ref]$v)) { return $v }
    return $fallback
}
function Say ([string]$t) { Write-Host $t -ForegroundColor White }
function Info ([string]$t) { Write-Host ('     [INFO] ' + $t) -ForegroundColor Gray }
function Head ([string]$t) { Write-Host ''; Write-Host ('  [SECTION] ' + $t) -ForegroundColor Cyan }
function Doing ([string]$tag, [string]$t) { Write-Host ('     [' + $tag + '] ' + $t) -ForegroundColor Cyan }
function Ok ([string]$t) {
    $script:NQ_Applied++
    if ($script:NQ_Dry) { Write-Host ('     [WOULD] ' + $t) -ForegroundColor Magenta }
    else { Write-Host ('     [OK] ' + $t) -ForegroundColor Green }
}
function Same ([string]$t) { $script:NQ_Same++; Write-Host ('     [SAME] ' + $t) -ForegroundColor DarkGreen }
function Skip ([string]$t) { $script:NQ_Skipped++; Write-Host ('     [SKIP] ' + $t) -ForegroundColor DarkGray }
function Warn ([string]$t) { $script:NQ_Warned++; Write-Host ('     [WARNING] ' + $t) -ForegroundColor Yellow }
function Failed ([string]$t) { $script:NQ_Failed++; Write-Host ('     [FAILED] ' + $t) -ForegroundColor Red }

# Every write passes through Change. A dry run skips the write and still prints the result.
function Change ([scriptblock]$NqWrite) { if (-not $script:NQ_Dry) { & $NqWrite } }

# A failed read produces no invented state and does not abort later stages.
function Read-Nq ([string]$title, [scriptblock]$action) {
    try { & $action } catch { Failed ($title + ': ' + $_.Exception.Message) }
}

# An optional capability: a driver or build without the feature is a skip, never a failure.
function Probe ([scriptblock]$action) {
    try { & $action } catch { $null }
}

# Keywords a driver does not expose are counted one by one but reported on a single line per
# adapter, so the real results are not buried under dozens of identical skip lines.
$script:NqMissing = New-Object System.Collections.Generic.List[string]
function Missing ([string]$kw) { $script:NQ_Skipped++; [void]$script:NqMissing.Add($kw) }

# ==========================================================================================
#  Diagnostics: read-only loss / latency measurement
#  Target: Windows PowerShell 5.1 (.NET Framework 4.5+), Windows 10/11. Nothing here writes
#  to disk, the registry or any network setting. The only process-wide change is adding
#  TLS 1.2 to [Net.ServicePointManager]::SecurityProtocol for the optional load test.
#
#  Entry point: Invoke-NqDiagnostics (about 55-60 s with the load test, about 37 s without).
#  Pieces: Invoke-NqPathDiagnostic (loss + hop localisation), Invoke-NqLoadedLatency
#  (bufferbloat), Test-NqPathMtu (DF sweep), Get-NqLinkEvents (event logs by provider/ID),
#  Get-NqCpuSnapshot / Compare-NqCpuSnapshot (per-core DPC + ISR load), counter deltas.
# ==========================================================================================

# ---------------------------------------------------------------------------------------
#  C# 5 probe engine. One scheduler thread fires every probe on its own timetable through
#  Ping.SendPingAsync (a fresh Ping per probe, so probes never queue behind a timeout);
#  every result records when it was sent, so streams can be correlated in time afterwards.
#  Loader saturates the line over HTTPS with a hard byte cap and a hard time limit.
# ---------------------------------------------------------------------------------------
$script:NqEngineSource = @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Net.NetworkInformation;
using System.Threading;
using System.Threading.Tasks;

namespace NqDiag
{
    public sealed class ProbeSpec
    {
        public string Name = "";
        public string Target = "";
        public int Ttl = 64;
        public int IntervalMs = 1000;
        public int OffsetMs = 0;
        public int StopMs = 30000;
        public int Size = 32;
        public bool DontFragment = true;
        public int TimeoutMs = 1000;
    }

    public sealed class ProbeResult
    {
        public int Stream;
        public int Seq;
        public double DueMs;
        public double SendMs = -1;
        public double RttMs = -1;      // ICMP round trip for echo replies, stopwatch for TTL-expired replies
        public double ElapsedMs = -1;  // stopwatch from send to completion
        public int Status = -2;        // -2 not sent, -1 local error, otherwise IPStatus
        public string From = "";
    }

    public sealed class ProbeRun
    {
        private readonly ProbeSpec[] specs;
        private readonly IPAddress[] addrs;
        private readonly byte[][] buffers;
        private readonly PingOptions[] options;
        private readonly ProbeResult[] results;
        private readonly Stopwatch clock = new Stopwatch();
        private readonly ManualResetEvent finished = new ManualResetEvent(false);
        private Thread worker;
        private volatile bool stopRequested;
        private volatile bool scheduleDone;
        private int outstanding;

        public ProbeRun(ProbeSpec[] specs)
        {
            this.specs = specs;
            addrs = new IPAddress[specs.Length];
            buffers = new byte[specs.Length][];
            options = new PingOptions[specs.Length];
            List<ProbeResult> list = new List<ProbeResult>();
            for (int i = 0; i < specs.Length; i++)
            {
                ProbeSpec s = specs[i];
                addrs[i] = IPAddress.Parse(s.Target);
                byte[] b = new byte[Math.Max(0, s.Size)];
                for (int j = 0; j < b.Length; j++) { b[j] = (byte)(0x61 + (j % 23)); }
                buffers[i] = b;
                options[i] = new PingOptions(Math.Max(1, Math.Min(255, s.Ttl)), s.DontFragment);
                int interval = Math.Max(10, s.IntervalMs);
                int seq = 0;
                for (long t = Math.Max(0, s.OffsetMs); t < s.StopMs; t += interval)
                {
                    ProbeResult r = new ProbeResult();
                    r.Stream = i;
                    r.Seq = seq;
                    r.DueMs = t;
                    seq++;
                    list.Add(r);
                }
            }
            results = list.ToArray();
            double[] keys = new double[results.Length];
            for (int i = 0; i < keys.Length; i++) { keys[i] = results[i].DueMs; }
            Array.Sort(keys, results);
        }

        public ProbeResult[] Results { get { return results; } }
        public double ElapsedMs { get { return clock.Elapsed.TotalMilliseconds; } }
        public bool IsFinished { get { return finished.WaitOne(0); } }

        public void Start()
        {
            clock.Start();
            worker = new Thread(Schedule);
            worker.IsBackground = true;
            worker.Name = "NqProbeScheduler";
            worker.Start();
        }

        public bool Wait(int ms) { return finished.WaitOne(ms); }
        public void Stop() { stopRequested = true; }

        private void Schedule()
        {
            try
            {
                for (int i = 0; i < results.Length; i++)
                {
                    if (stopRequested) { break; }
                    ProbeResult r = results[i];
                    double wait = r.DueMs - clock.Elapsed.TotalMilliseconds;
                    if (wait >= 1) { Thread.Sleep((int)wait); }
                    Fire(r);
                }
            }
            finally
            {
                scheduleDone = true;
                if (Interlocked.CompareExchange(ref outstanding, 0, 0) == 0) { finished.Set(); }
            }
        }

        private void Fire(ProbeResult r)
        {
            int i = r.Stream;
            Ping ping = new Ping();
            Interlocked.Increment(ref outstanding);
            long t0 = clock.ElapsedTicks;
            r.SendMs = clock.Elapsed.TotalMilliseconds;
            Task<PingReply> task;
            try
            {
                task = ping.SendPingAsync(addrs[i], specs[i].TimeoutMs, buffers[i], options[i]);
            }
            catch (Exception)
            {
                r.Status = -1;
                ping.Dispose();
                Done();
                return;
            }
            ProbeResult rr = r;
            Ping pp = ping;
            task.ContinueWith(delegate(Task<PingReply> t) { Complete(t, rr, pp, t0); },
                TaskContinuationOptions.ExecuteSynchronously);
        }

        private void Complete(Task<PingReply> t, ProbeResult r, Ping ping, long t0)
        {
            double el = (clock.ElapsedTicks - t0) * 1000.0 / Stopwatch.Frequency;
            try
            {
                if (t.IsFaulted || t.IsCanceled)
                {
                    AggregateException ignored = t.Exception;
                    r.Status = -1;
                }
                else
                {
                    PingReply rep = t.Result;
                    r.Status = (int)rep.Status;
                    r.ElapsedMs = el;
                    if (rep.Address != null) { r.From = rep.Address.ToString(); }
                    if (rep.Status == IPStatus.Success) { r.RttMs = rep.RoundtripTime; }
                    else if (rep.Status == IPStatus.TtlExpired) { r.RttMs = el; }
                }
            }
            catch (Exception) { r.Status = -1; }
            finally
            {
                try { ping.Dispose(); } catch (Exception) { }
                Done();
            }
        }

        private void Done()
        {
            if (Interlocked.Decrement(ref outstanding) == 0 && scheduleDone) { finished.Set(); }
        }
    }

    // Parallel HTTPS download (GET url?bytes=N) or upload (POST N bytes) until Stop() is called,
    // the byte cap is reached, or too many requests fail. Data is read into one buffer and
    // discarded; nothing is stored.
    public sealed class Loader
    {
        private readonly string url;
        private readonly bool upload;
        private readonly int streams;
        private readonly long chunk;
        private readonly long cap;
        private readonly Stopwatch clock = new Stopwatch();
        private readonly List<HttpWebRequest> active = new List<HttpWebRequest>();
        private Thread[] threads;
        private volatile bool stopRequested;
        private long bytes;
        private int errors;
        private int requests;
        public string LastError = "";

        public Loader(string url, bool upload, int streams, long chunkBytes, long capBytes)
        {
            this.url = url;
            this.upload = upload;
            this.streams = Math.Max(1, streams);
            this.chunk = Math.Max(65536, chunkBytes);
            this.cap = Math.Max(chunkBytes, capBytes);
            int sp = (int)ServicePointManager.SecurityProtocol;
            if (sp != 0 && (sp & 3072) == 0)
            {
                ServicePointManager.SecurityProtocol = (SecurityProtocolType)(sp | 3072);
            }
            ServicePoint point = ServicePointManager.FindServicePoint(new Uri(url));
            if (point.ConnectionLimit < this.streams + 2) { point.ConnectionLimit = this.streams + 2; }
            point.Expect100Continue = false;
            point.UseNagleAlgorithm = false;
        }

        public long Bytes { get { return Interlocked.Read(ref bytes); } }
        public int Errors { get { return Thread.VolatileRead(ref errors); } }
        public int Requests { get { return Thread.VolatileRead(ref requests); } }
        public double ElapsedMs { get { return clock.Elapsed.TotalMilliseconds; } }
        public bool CapReached { get { return Interlocked.Read(ref bytes) >= cap; } }

        public void Start()
        {
            clock.Start();
            threads = new Thread[streams];
            for (int i = 0; i < streams; i++)
            {
                threads[i] = new Thread(Work);
                threads[i].IsBackground = true;
                threads[i].Name = "NqLoader";
                threads[i].Start();
            }
        }

        public void Stop()
        {
            stopRequested = true;
            lock (active)
            {
                foreach (HttpWebRequest r in active) { try { r.Abort(); } catch (Exception) { } }
            }
            if (threads != null)
            {
                foreach (Thread t in threads) { t.Join(3000); }
            }
            clock.Stop();
        }

        private bool ShouldStop()
        {
            return stopRequested || Interlocked.Read(ref bytes) >= cap || Thread.VolatileRead(ref errors) >= 8;
        }

        private void Work()
        {
            byte[] buf = new byte[65536];
            while (!ShouldStop())
            {
                HttpWebRequest req = null;
                bool early = false;
                try
                {
                    if (upload)
                    {
                        req = (HttpWebRequest)WebRequest.Create(url);
                        req.Method = "POST";
                        req.ContentType = "application/octet-stream";
                        req.ContentLength = chunk;
                        req.AllowWriteStreamBuffering = false;
                    }
                    else
                    {
                        // Cloudflare's __down endpoint takes the size as ?bytes=N (below 1e8);
                        // any other URL (a static test file) is fetched as it is.
                        string u = url.IndexOf("__down", StringComparison.OrdinalIgnoreCase) >= 0
                            ? url + "?bytes=" + chunk.ToString(CultureInfo.InvariantCulture) : url;
                        req = (HttpWebRequest)WebRequest.Create(u);
                        req.AutomaticDecompression = DecompressionMethods.None;
                    }
                    req.Timeout = 15000;
                    req.ReadWriteTimeout = 15000;
                    req.KeepAlive = true;
                    req.UserAgent = "NetLatencyTuner-diagnostic";
                    lock (active) { active.Add(req); }
                    Interlocked.Increment(ref requests);
                    if (upload)
                    {
                        Stream s = req.GetRequestStream();
                        long left = chunk;
                        while (left > 0)
                        {
                            if (ShouldStop()) { early = true; break; }
                            int n = (int)Math.Min(buf.Length, left);
                            s.Write(buf, 0, n);
                            left -= n;
                            Interlocked.Add(ref bytes, n);
                        }
                        if (early) { req.Abort(); }
                        else
                        {
                            s.Close();
                            using (WebResponse resp = req.GetResponse()) { }
                        }
                    }
                    else
                    {
                        using (WebResponse resp = req.GetResponse())
                        {
                            Stream s = resp.GetResponseStream();
                            int n;
                            while ((n = s.Read(buf, 0, buf.Length)) > 0)
                            {
                                Interlocked.Add(ref bytes, n);
                                if (ShouldStop()) { early = true; break; }
                            }
                            if (early) { req.Abort(); } else { s.Close(); }
                        }
                    }
                }
                catch (Exception e)
                {
                    if (!stopRequested && !early)
                    {
                        Interlocked.Increment(ref errors);
                        LastError = e.Message;
                        Thread.Sleep(250);
                    }
                }
                finally
                {
                    if (req != null) { lock (active) { active.Remove(req); } }
                }
            }
        }
    }
}
'@

function Initialize-NqProbeEngine {
    if ('NqDiag.ProbeRun' -as [type]) { return $true }
    try {
        # -IgnoreWarnings: Add-Type otherwise turns compiler warnings into a failed compile.
        Add-Type -TypeDefinition $script:NqEngineSource -Language CSharp -IgnoreWarnings -WarningAction SilentlyContinue -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# ---------------------------------------------------------------------------------------
#  Output. Uses the v3.1 engine's Warn / Info when present; standalone fallbacks otherwise.
# ---------------------------------------------------------------------------------------
function Write-NqFinding ([string]$Level, [string]$Text) {
    if ($Level -eq 'WARN') {
        if (Get-Command -Name Warn -CommandType Function -ErrorAction SilentlyContinue) { Warn $Text }
        else { Write-Host ('     [WARNING] ' + $Text) -ForegroundColor Yellow }
    } elseif ($Level -eq 'GOOD') {
        Write-Host ('     [GOOD] ' + $Text) -ForegroundColor Green
    } else {
        if (Get-Command -Name Info -CommandType Function -ErrorAction SilentlyContinue) { Info $Text }
        else { Write-Host ('     [INFO] ' + $Text) -ForegroundColor Gray }
    }
}

function Format-NqNum ([double]$v, [int]$digits = 1) {
    return ([math]::Round($v, $digits)).ToString([Globalization.CultureInfo]::InvariantCulture)
}

# ---------------------------------------------------------------------------------------
#  Statistics
# ---------------------------------------------------------------------------------------
# Wilson score interval for a binomial proportion, returned in percent. Unlike the plain
# p +- z*sqrt(p(1-p)/n) interval it stays valid at 0 or 1 lost probes, which is exactly the
# range the 0-1 percent goal lives in.
function Get-NqWilson ([int]$Lost, [int]$Sent, [double]$Z = 1.96) {
    if ($Sent -le 0) { return [pscustomobject]@{ Low = 0.0; High = 100.0 } }
    $n = [double]$Sent
    $p = $Lost / $n
    $z2 = $Z * $Z
    $den = 1.0 + $z2 / $n
    $c = ($p + $z2 / (2.0 * $n)) / $den
    $h = ($Z * [math]::Sqrt(($p * (1.0 - $p) / $n) + ($z2 / (4.0 * $n * $n)))) / $den
    return [pscustomobject]@{
        Low  = [math]::Round(100.0 * [math]::Max(0.0, $c - $h), 2)
        High = [math]::Round(100.0 * [math]::Min(1.0, $c + $h), 2)
    }
}

# Pooled two-proportion z statistic: positive when stream 1 lost a larger share than stream 2.
function Get-NqZ ([int]$Lost1, [int]$Sent1, [int]$Lost2, [int]$Sent2) {
    if (($Sent1 -le 0) -or ($Sent2 -le 0)) { return 0.0 }
    $p1 = $Lost1 / [double]$Sent1
    $p2 = $Lost2 / [double]$Sent2
    $p = ($Lost1 + $Lost2) / [double]($Sent1 + $Sent2)
    $se = [math]::Sqrt($p * (1.0 - $p) * ((1.0 / $Sent1) + (1.0 / $Sent2)))
    if ($se -le 0) { return 0.0 }
    return ($p1 - $p2) / $se
}

function Get-NqPercentile ([double[]]$Sorted, [double]$Pct) {
    if (-not $Sorted -or $Sorted.Count -eq 0) { return 0.0 }
    $idx = [int][math]::Ceiling($Pct / 100.0 * $Sorted.Count) - 1
    if ($idx -lt 0) { $idx = 0 }
    if ($idx -ge $Sorted.Count) { $idx = $Sorted.Count - 1 }
    return $Sorted[$idx]
}

# Groups a ProbeRun's results by stream once, in send order.
function Split-NqResults ($Results) {
    $by = @{}
    foreach ($r in $Results) {
        if (-not $by.ContainsKey($r.Stream)) { $by[$r.Stream] = New-Object 'System.Collections.Generic.List[object]' }
        $by[$r.Stream].Add($r)
    }
    foreach ($k in @($by.Keys)) { $by[$k] = @($by[$k] | Sort-Object Seq) }
    return $by
}

# Loss, RTT and jitter for one stream inside a time window. -Hop counts TTL-expired replies
# as answers. Jitter is the mean absolute difference of consecutive answered RTTs (RFC 3550
# interarrival-jitter idea without the 1/16 smoothing), the figure v3.1 already reports.
function Get-NqStreamStats ($Rows, [double]$FromMs = 1000, [double]$ToMs = [double]::MaxValue, [switch]$Hop) {
    $rtts = New-Object 'System.Collections.Generic.List[double]'
    $lostAt = New-Object 'System.Collections.Generic.List[double]'
    $from = @{}
    $sent = 0; $lost = 0; $burst = 0; $maxBurst = 0
    foreach ($r in @($Rows)) {
        if ($r.Status -eq -2) { continue }
        if (($r.SendMs -lt $FromMs) -or ($r.SendMs -ge $ToMs)) { continue }
        $sent++
        $ok = ($r.Status -eq 0) -or ($Hop -and ($r.Status -eq 11013))
        if ($ok) {
            $rtts.Add([double]$r.RttMs)
            $burst = 0
            if ($r.From) { if ($from.ContainsKey($r.From)) { $from[$r.From]++ } else { $from[$r.From] = 1 } }
        } else {
            $lost++; $burst++
            if ($burst -gt $maxBurst) { $maxBurst = $burst }
            $lostAt.Add([double]$r.SendMs)
        }
    }
    $ci = Get-NqWilson $lost $sent
    $o = [pscustomobject]@{
        Sent = $sent; Lost = $lost; LossPct = 0.0; CiLow = $ci.Low; CiHigh = $ci.High
        Min = 0.0; Median = 0.0; P95 = 0.0; Max = 0.0; Avg = 0.0; Jitter = 0.0
        MaxBurst = $maxBurst; From = ''; LostAt = $lostAt.ToArray(); Received = $rtts.Count
    }
    if ($sent -gt 0) { $o.LossPct = [math]::Round(100.0 * $lost / $sent, 2) }
    if ($from.Count -gt 0) { $o.From = @($from.GetEnumerator() | Sort-Object Value -Descending)[0].Key }
    if ($rtts.Count -gt 0) {
        $arr = $rtts.ToArray()
        $sorted = [double[]]($arr | Sort-Object)
        $o.Min = [math]::Round($sorted[0], 1)
        $o.Max = [math]::Round($sorted[$sorted.Count - 1], 1)
        $o.Median = [math]::Round((Get-NqPercentile $sorted 50), 1)
        $o.P95 = [math]::Round((Get-NqPercentile $sorted 95), 1)
        $o.Avg = [math]::Round(($arr | Measure-Object -Average).Average, 1)
        if ($arr.Count -gt 1) {
            $sum = 0.0
            for ($i = 1; $i -lt $arr.Count; $i++) { $sum += [math]::Abs($arr[$i] - $arr[$i - 1]) }
            $o.Jitter = [math]::Round($sum / ($arr.Count - 1), 1)
        }
    }
    return $o
}

# "Significant" = at least 3 lost and at least 0.5 percent: enough to be worth locating.
# "Above goal"  = the Wilson lower bound is above 1 percent: confidently worse than the goal.
function Test-NqSignificant ($s) { return (($s.Lost -ge 3) -and ($s.LossPct -ge 0.5)) }
function Test-NqAboveGoal ($s)   { return ($s.CiLow -gt 1.0) }

function Merge-NqStats ([object[]]$List) {
    $sent = 0; $lost = 0
    foreach ($s in $List) { $sent += $s.Sent; $lost += $s.Lost }
    $ci = Get-NqWilson $lost $sent
    $pct = 0.0
    if ($sent -gt 0) { $pct = [math]::Round(100.0 * $lost / $sent, 2) }
    return [pscustomobject]@{ Sent = $sent; Lost = $lost; LossPct = $pct; CiLow = $ci.Low; CiHigh = $ci.High }
}

function Test-NqPrivateIPv4 ([string]$ip) {
    return ($ip -match '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.|169\.254\.)')
}

# ---------------------------------------------------------------------------------------
#  Route: the IPv4 default route with the lowest total metric, its adapter and next hop.
# ---------------------------------------------------------------------------------------
function Get-NqDefaultRoute {
    try {
        $best = Get-NetRoute -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop | ForEach-Object {
            $ifm = [int](Get-NetIPInterface -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction Stop).InterfaceMetric
            [pscustomobject]@{ Index = [int]$_.ifIndex; Metric = ([int]$_.RouteMetric + $ifm); NextHop = [string]$_.NextHop }
        } | Sort-Object Metric | Select-Object -First 1
        if (-not $best) { return $null }
        $ad = Get-NetAdapter -InterfaceIndex $best.Index -ErrorAction SilentlyContinue
        $wifi = $false; $phys = $false; $name = ''
        if ($ad) {
            $name = [string]$ad.Name
            $wifi = (([string]$ad.PhysicalMediaType -match '802\.11') -or ($ad.NdisPhysicalMedium -eq 9))
            $phys = [bool]$ad.HardwareInterface
        }
        $gw = $best.NextHop
        if ($gw -eq '0.0.0.0') { $gw = '' }
        return [pscustomobject]@{ Index = $best.Index; Gateway = $gw; Adapter = $name; IsWifi = $wifi; IsPhysical = $phys }
    } catch { return $null }
}

# ---------------------------------------------------------------------------------------
#  Hop discovery: TTL 1..MaxTtl sent at once toward the trace target, twice, 1.1 s apart
#  (Linux-based routers rate-limit Time Exceeded to about 1 per second per source with a
#  burst of 6, so two rounds a second apart are always answered if the hop answers at all).
# ---------------------------------------------------------------------------------------
function Find-NqHops ([string]$Target, [int]$MaxTtl = 16) {
    $specs = New-Object 'System.Collections.Generic.List[NqDiag.ProbeSpec]'
    for ($t = 1; $t -le $MaxTtl; $t++) {
        $s = New-Object NqDiag.ProbeSpec
        $s.Name = 'ttl' + $t; $s.Target = $Target; $s.Ttl = $t
        $s.IntervalMs = 1100; $s.OffsetMs = ($t - 1) * 5; $s.StopMs = 2200; $s.TimeoutMs = 1000
        $specs.Add($s)
    }
    $run = New-Object NqDiag.ProbeRun (, $specs.ToArray())
    $run.Start()
    [void]$run.Wait(6000)
    $by = Split-NqResults $run.Results
    $hops = New-Object 'System.Collections.Generic.List[object]'
    $destTtl = 0
    for ($t = 1; $t -le $MaxTtl; $t++) {
        $rows = @($by[$t - 1])
        $addr = @{}
        $reached = $false
        foreach ($r in $rows) {
            if (($r.Status -eq 11013) -or ($r.Status -eq 0)) {
                if ($addr.ContainsKey($r.From)) { $addr[$r.From]++ } else { $addr[$r.From] = 1 }
                if (($r.Status -eq 0) -and ($r.From -eq $Target)) { $reached = $true }
            }
        }
        $ip = ''
        if ($addr.Count -gt 0) { $ip = @($addr.GetEnumerator() | Sort-Object Value -Descending)[0].Key }
        $hops.Add([pscustomobject]@{ Ttl = $t; Address = $ip; Answered = ($addr.Count -gt 0) })
        if ($reached) { $destTtl = $t; break }
    }
    return [pscustomobject]@{ Hops = $hops.ToArray(); DestTtl = $destTtl }
}

# ---------------------------------------------------------------------------------------
#  Path diagnostic. All streams run concurrently for $Seconds (default 30):
#    router echo              10/s -> about 290 analysed probes
#    up to 2 hops past it      8/s -> about 232 each (direct echo: the access line)
#    3 internet targets        4/s -> about 116 each, about 348 pooled
#    next 6 hops, TTL-limited  1/s -> about 29 each (mini-MTR view; never above 1/s per hop,
#                                     the Linux default Time Exceeded rate limit)
#  Total at most 44 probes/s (about 2.6 KB/s each way), under the 50/s default threshold of
#  consumer-router ICMP-flood filters.
#  The first second of every stream is discarded (ARP/NAT/Wi-Fi wake-up warm-up).
# ---------------------------------------------------------------------------------------
function Invoke-NqPathDiagnostic {
    param(
        [string]$Gateway = '',
        [string[]]$Targets = @('1.1.1.1', '8.8.8.8', '9.9.9.9'),
        [string]$TraceTarget = '',
        [int]$Seconds = 30,
        [int]$MaxHopStreams = 6,
        [bool]$ViaWifi = $false,
        [scriptblock]$WhileRunning = $null
    )
    if (-not $TraceTarget) { $TraceTarget = $Targets[0] }
    $stopMs = [int]($Seconds * 1000)
    $trace = Find-NqHops $TraceTarget 16
    $hops = @($trace.Hops)
    $destTtl = $trace.DestTtl
    if ($destTtl -le 0) { $destTtl = [math]::Min(16, $hops.Count + 1) }

    $specs = New-Object 'System.Collections.Generic.List[NqDiag.ProbeSpec]'
    $role = @{}
    function Add-Spec ([string]$name, [string]$target, [int]$ttl, [int]$interval, [int]$offset) {
        $s = New-Object NqDiag.ProbeSpec
        $s.Name = $name; $s.Target = $target; $s.Ttl = $ttl; $s.IntervalMs = $interval
        $s.OffsetMs = $offset; $s.StopMs = $stopMs; $s.TimeoutMs = 1000; $s.Size = 32
        $role[$name] = $specs.Count
        $specs.Add($s)
    }
    if ($Gateway) { Add-Spec 'gw' $Gateway 64 100 0 }
    # Access hops: the first two answering hops past the router that are not the
    # destination, pinged directly (echo replies are not rate-limited like Time Exceeded).
    $access = @($hops | Where-Object { ($_.Ttl -ge 2) -and ($_.Ttl -lt $destTtl) -and $_.Answered -and ($_.Address -ne $Gateway) } | Select-Object -First 2)
    $ai = 0
    foreach ($h in $access) { Add-Spec ('acc' + $h.Ttl) $h.Address 64 125 (37 + 61 * $ai); $ai++ }
    $ti = 0
    foreach ($t in $Targets) { Add-Spec ('tgt' + $ti) $t 64 250 (13 + 83 * $ti); $ti++ }
    # TTL-limited view of the hops after the access hops (those already have echo streams).
    $first = 2
    if ($access.Count -gt 0) { $first = [int]$access[$access.Count - 1].Ttl + 1 }
    $last = [math]::Min($destTtl - 1, $first + $MaxHopStreams - 1)
    for ($k = $first; $k -le $last; $k++) { Add-Spec ('ttl' + $k) $TraceTarget $k 1000 (($k * 97) % 1000) }

    $run = New-Object NqDiag.ProbeRun (, $specs.ToArray())
    $startTime = Get-Date
    $run.Start()
    if ($WhileRunning) { try { & $WhileRunning } catch { } }
    [void]$run.Wait($stopMs + 5000)
    $run.Stop()
    $by = Split-NqResults $run.Results

    $gwStats = $null
    if ($role.ContainsKey('gw')) { $gwStats = Get-NqStreamStats $by[$role['gw']] 1000 }
    $accStats = @()
    foreach ($h in $access) {
        $accStats += [pscustomobject]@{ Kind = 'acc'; Ttl = $h.Ttl; Address = $h.Address; Stats = (Get-NqStreamStats $by[$role['acc' + $h.Ttl]] 1000) }
    }
    $tgtStats = @()
    for ($i = 0; $i -lt $Targets.Count; $i++) {
        $tgtStats += [pscustomobject]@{ Target = $Targets[$i]; Stats = (Get-NqStreamStats $by[$role['tgt' + $i]] 1000); Excluded = '' }
    }
    $hopStats = @()
    for ($k = $first; $k -le $last; $k++) {
        $hopStats += [pscustomobject]@{ Ttl = $k; Stats = (Get-NqStreamStats $by[$role['ttl' + $k]] 1000 -Hop); Tag = '' }
    }

    $v = Get-NqPathVerdict -Gateway $Gateway -GatewayStats $gwStats -Access $accStats -Targets $tgtStats -HopView $hopStats
    return [pscustomobject]@{
        StartTime = $startTime; Seconds = $Seconds; Gateway = $Gateway; ViaWifi = $ViaWifi
        TraceTarget = $TraceTarget; DestTtl = $trace.DestTtl; HopsFound = $hops
        GatewayStats = $gwStats; Access = $accStats; Targets = $tgtStats; Internet = $v.Internet
        HopView = $hopStats; Location = $v.Location; LocationHop = $v.LocationHop; LastCleared = $v.LastCleared; Artefacts = $v.Artefacts
        PartialLan = $v.PartialLan; Coincident = $v.Coincident; InternetLostCount = $v.InternetLostCount; CoincidenceChance = $v.CoincidenceChance
    }
}

# Pure analysis of the per-stream statistics (no probing), so it can be tested offline.
# Targets items: Target, Stats, Excluded (set here). HopView items: Ttl, Stats, Tag (set here).
function Get-NqPathVerdict {
    param([string]$Gateway = '', $GatewayStats = $null, [object[]]$Access = @(), [object[]]$Targets = @(), [object[]]$HopView = @())
    $gwStats = $GatewayStats; $accStats = @($Access); $tgtStats = @($Targets); $hopStats = @($HopView)
    # ---- Internet loss, robust to any one target's ICMP policy -------------------------
    # High outlier: a target losing significantly more (z >= 2.58, 99%) and at least twice
    # the others' rate + 1 point is limiting ping replies itself. Low outlier: if the best
    # target loses significantly less than the rest, the rest are inflated by ICMP policy
    # and the best one alone is the path figure (real path loss hits every target).
    foreach ($t in $tgtStats) { if ($t.Stats.Received -eq 0) { $t.Excluded = 'no-reply' } }
    foreach ($t in $tgtStats) {
        if ($t.Excluded) { continue }
        $others = @($tgtStats | Where-Object { ($_ -ne $t) -and (-not $_.Excluded) })
        if ($others.Count -eq 0) { continue }
        $o = Merge-NqStats @($others | ForEach-Object { $_.Stats })
        $z = Get-NqZ $t.Stats.Lost $t.Stats.Sent $o.Lost $o.Sent
        if (($z -ge 2.58) -and ($t.Stats.LossPct -ge (2 * $o.LossPct + 1.0))) { $t.Excluded = 'icmp-limited' }
    }
    $used = @($tgtStats | Where-Object { -not $_.Excluded })
    if ($used.Count -ge 2) {
        $best = @($used | Sort-Object { $_.Stats.LossPct })[0]
        $rest = Merge-NqStats @($used | Where-Object { $_ -ne $best } | ForEach-Object { $_.Stats })
        $z = Get-NqZ $best.Stats.Lost $best.Stats.Sent $rest.Lost $rest.Sent
        if (($z -le -2.58) -and ($rest.LossPct -ge (2 * $best.Stats.LossPct + 1.0))) {
            foreach ($t in $used) { if ($t -ne $best) { $t.Excluded = 'icmp-limited' } }
            $used = @($best)
        }
    }
    $D = $null
    if ($used.Count -gt 0) { $D = Merge-NqStats @($used | ForEach-Object { $_.Stats }) }

    # ---- Per-hop artefact tagging: loss that later hops do not show is not real -------
    for ($i = 0; $i -lt $hopStats.Count; $i++) {
        $h = $hopStats[$i]
        if ($h.Stats.Received -eq 0) { $h.Tag = 'silent'; continue }
        if ($h.Stats.Lost -lt 2) { continue }
        $later = @($hopStats | Where-Object { ($_.Ttl -gt $h.Ttl) -and ($_.Stats.Received -gt 0) } | ForEach-Object { $_.Stats.LossPct })
        if ($D) { $later += $D.LossPct }
        if ($later.Count -gt 0) {
            $minLater = ($later | Measure-Object -Minimum).Minimum
            if ($h.Stats.LossPct -ge ($minLater + 5.0)) { $h.Tag = 'rate-limited' }
        }
    }

    # ---- Localisation -----------------------------------------------------------------
    # Real forwarding loss on a segment appears in every probe that crosses it. Each point on
    # the way out (router, then the access hops) is classified against the internet figure:
    #   clears   - significantly LOWER (z <= -1.96): the loss is further out than this point,
    #              and so it is further out than every point before it too
    #   artefact - significant AND significantly HIGHER (z >= 2.58, +1 point), or showing loss
    #              that a later point contradicts by clearing: its own ping responder drops
    #              replies, so it says nothing about forwarding
    #   accounts - significant and at least half the internet loss: the loss is at or before
    #              this point (and after the last point that cleared)
    #   open     - none of these (too few probes to decide); the verdict does not guess.
    $location = 'none'; $locHop = $null; $artefacts = @(); $partial = $null; $lastCleared = $null
    if ($D -and (Test-NqSignificant $D)) {
        $chain = @()
        if ($gwStats) { $chain += [pscustomobject]@{ Kind = 'gw'; Ttl = 1; Address = $Gateway; Stats = $gwStats } }
        $chain += $accStats
        $cls = @()
        foreach ($c in $chain) {
            $k = 'open'
            if ($c.Stats.Received -gt 0) {
                $z = Get-NqZ $c.Stats.Lost $c.Stats.Sent $D.Lost $D.Sent
                $sig = Test-NqSignificant $c.Stats
                if ($sig -and ($z -ge 2.58) -and ($c.Stats.LossPct -gt ($D.LossPct + 1.0))) { $k = 'artefact' }
                elseif ($sig -and ($c.Stats.LossPct -ge (0.5 * $D.LossPct))) { $k = 'accounts' }
                elseif ($z -le -1.96) { $k = 'clears'; if (($c.Kind -eq 'gw') -and $sig) { $partial = $c } }
            }
            $cls += $k
        }
        # A later point overrides an earlier "accounts" only when it lost significantly less
        # than that earlier point itself (z <= -2.58); a weak disagreement keeps the earlier
        # verdict, so real local loss is not pushed out to the ISP by chance.
        for ($i = 0; $i -lt $chain.Count; $i++) {
            if ($cls[$i] -ne 'accounts') { continue }
            for ($j = $i + 1; $j -lt $chain.Count; $j++) {
                if (($cls[$j] -eq 'clears') -and ((Get-NqZ $chain[$j].Stats.Lost $chain[$j].Stats.Sent $chain[$i].Stats.Lost $chain[$i].Stats.Sent) -le -2.58)) { $cls[$i] = 'artefact'; break }
            }
        }
        for ($i = 0; $i -lt $chain.Count; $i++) { if ($cls[$i] -eq 'artefact') { $artefacts += $chain[$i] } }
        $found = $false; $L = -1
        for ($i = 0; $i -lt $chain.Count; $i++) {
            if ($cls[$i] -eq 'clears') { $L = $i; $lastCleared = $chain[$i]; continue }
            if ($cls[$i] -ne 'accounts') { continue }
            $locHop = $chain[$i]; $found = $true
            if ($chain[$i].Kind -eq 'gw') { $location = 'lan' } elseif ($L -ge 0) { $location = 'access' } else { $location = 'upto-access' }
            break
        }
        if (-not $found) {
            if (($L -ge 0) -and ($L -eq ($chain.Count - 1))) { $location = 'beyond'; $locHop = $chain[$L] }
            elseif ($L -ge 0) { $location = 'unclear-after'; $locHop = $chain[$L + 1] }
            else { $location = 'unclear-start'; if ($chain.Count -gt 0) { $locHop = $chain[0] } }
        }
    } elseif ($gwStats -and (Test-NqSignificant $gwStats) -and $D) {
        $z = Get-NqZ $gwStats.Lost $gwStats.Sent $D.Lost $D.Sent
        if ($z -ge 2.58) { $artefacts += [pscustomobject]@{ Kind = 'gw'; Ttl = 1; Address = $Gateway; Stats = $gwStats } }
    }

    # Internet losses that happened within 150 ms of a lost router ping (same dropout).
    $coinc = 0; $inetLost = 0; $chance = 0.0
    if ($gwStats -and $D) {
        $gwLost = @($gwStats.LostAt)
        foreach ($t in $used) {
            foreach ($ms in @($t.Stats.LostAt)) {
                $inetLost++
                foreach ($g in $gwLost) { if ([math]::Abs($g - $ms) -le 150) { $coinc++; break } }
            }
        }
        $pg = 0.0
        if ($gwStats.Sent -gt 0) { $pg = $gwStats.Lost / [double]$gwStats.Sent }
        $chance = 1.0 - [math]::Pow(1.0 - $pg, 3)
    }

    return [pscustomobject]@{
        Internet = $D; Location = $location; LocationHop = $locHop; LastCleared = $lastCleared; Artefacts = $artefacts
        PartialLan = $partial; Coincident = $coinc; InternetLostCount = $inetLost; CoincidenceChance = $chance
    }
}

function Show-NqPathFindings ($P) {
    if (-not $P) { return }
    $f = { param($s) ([string]$s.Lost + ' of ' + [string]$s.Sent + ' lost (' + (Format-NqNum $s.LossPct 1) + '%, 95% range ' + (Format-NqNum $s.CiLow 1) + '-' + (Format-NqNum $s.CiHigh 1) + '%)') }
    $g = $P.GatewayStats
    $D = $P.Internet
    if ($g) {
        if ($g.Received -eq 0) { Write-NqFinding 'INFO' ('The router (' + $P.Gateway + ') does not answer pings, so the local link cannot be measured on its own') }
        else { Write-NqFinding 'INFO' ('Router ' + $P.Gateway + ': ' + (& $f $g) + ', ' + (Format-NqNum $g.Min) + '/' + (Format-NqNum $g.Median) + '/' + (Format-NqNum $g.P95) + ' ms min/median/95th, jitter ' + (Format-NqNum $g.Jitter) + ' ms') }
    }
    foreach ($a in $P.Access) {
        if ($a.Stats.Received -eq 0) { Write-NqFinding 'INFO' ('Hop ' + $a.Ttl + ' (' + $a.Address + ') answers traceroute but not direct pings - left out'); continue }
        Write-NqFinding 'INFO' ('Hop ' + $a.Ttl + ' ' + $a.Address + ': ' + (& $f $a.Stats) + ', median ' + (Format-NqNum $a.Stats.Median) + ' ms')
    }
    foreach ($t in $P.Targets) {
        if ($t.Excluded -eq 'no-reply') { Write-NqFinding 'INFO' ($t.Target + ' did not answer any ping (ICMP blocked on the way or by that server) - left out'); continue }
        Write-NqFinding 'INFO' ('Internet ' + $t.Target + ': ' + (& $f $t.Stats) + ', ' + (Format-NqNum $t.Stats.Min) + '/' + (Format-NqNum $t.Stats.Median) + '/' + (Format-NqNum $t.Stats.P95) + ' ms min/median/95th, jitter ' + (Format-NqNum $t.Stats.Jitter) + ' ms')
    }
    if ($D) {
        foreach ($t in @($P.Targets | Where-Object { $_.Excluded -eq 'icmp-limited' })) {
            Write-NqFinding 'INFO' ($t.Target + ' lost ' + (Format-NqNum $t.Stats.LossPct) + '% of pings while the other internet targets lost ' + (Format-NqNum $D.LossPct) + '%: that server limits or deprioritises ping replies, so its figure is left out of the verdict')
        }
    }
    $showHops = ($D -and (Test-NqSignificant $D)) -or (@($P.HopView | Where-Object { $_.Tag -eq 'rate-limited' }).Count -gt 0)
    if ($showHops) {
        foreach ($h in $P.HopView) {
            if ($h.Tag -eq 'silent') { Write-NqFinding 'INFO' ('Hop ' + $h.Ttl + ': does not answer traceroute probes (normal for many ISP routers)'); continue }
            $line = 'Hop ' + $h.Ttl + ' ' + $h.Stats.From + ': ' + $h.Stats.Lost + ' of ' + $h.Stats.Sent + ' traceroute probes unanswered, median ' + (Format-NqNum $h.Stats.Median) + ' ms'
            if ($h.Tag -eq 'rate-limited') { $line += ' - this router limits its traceroute replies; later hops lose less, so this is not real loss' }
            Write-NqFinding 'INFO' $line
        }
    } elseif ($P.HopView.Count -gt 0) {
        Write-NqFinding 'INFO' ('Route to ' + $P.TraceTarget + ': hops ' + $P.HopView[0].Ttl + '-' + $P.HopView[$P.HopView.Count - 1].Ttl + ' checked with traceroute probes, none shows loss that continues to the destination')
    }

    if (-not $D) {
        if (-not $g -or $g.Received -eq 0) { Write-NqFinding 'INFO' 'No host answered pings (ICMP blocked by a firewall or VPN) - packet loss cannot be measured this way'; return }
        if (Test-NqSignificant $g) {
            $lvl = 'INFO'; if (Test-NqAboveGoal $g) { $lvl = 'WARN' }
            Write-NqFinding $lvl ('Pings to the router were lost (' + (& $f $g) + '). No internet host answered pings, so this could not be cross-checked; the router may simply be answering pings slowly')
        }
        return
    }
    foreach ($a in $P.Artefacts) {
        if ($a.Kind -eq 'gw') {
            Write-NqFinding 'INFO' ('The router dropped ' + (Format-NqNum $a.Stats.LossPct) + '% of pings addressed to itself, but only ' + (Format-NqNum $D.LossPct) + '% of pings that passed through it were lost. Routers answer pings with spare CPU time only, so this is not loss on your link - ignore it')
        } else {
            Write-NqFinding 'INFO' ('Hop ' + $a.Ttl + ' (' + $a.Address + ') dropped ' + (Format-NqNum $a.Stats.LossPct) + '% of pings addressed to it but forwards traffic with less loss (' + (Format-NqNum $D.LossPct) + '% to the internet): it deprioritises pings - not a fault')
        }
    }
    $level = 'INFO'
    if (Test-NqAboveGoal $D) { $level = 'WARN' }
    $dTxt = [string]$D.Lost + ' of ' + [string]$D.Sent + ' internet pings lost = ' + (Format-NqNum $D.LossPct) + '%, 95% range ' + (Format-NqNum $D.CiLow) + '-' + (Format-NqNum $D.CiHigh) + '%'
    if (($D.Lost -le 1) -and ($D.Sent -ge 200)) {
        Write-NqFinding 'GOOD' ('No measurable packet loss: ' + $dTxt + '. The 0-1% goal is met on an idle line')
        return
    }
    if ($D.Lost -le 1) {
        Write-NqFinding 'INFO' ('No loss seen, but only ' + $D.Sent + ' internet pings were sent (' + $dTxt + ') - too few to confirm the 0-1% goal')
        return
    }
    if (-not (Test-NqSignificant $D)) {
        Write-NqFinding 'INFO' ('Slight loss: ' + $dTxt + '. That is consistent with the 0-1% goal and too little to locate in ' + $P.Seconds + ' s; run the test again if games report loss')
        return
    }
    $h = $P.LocationHop
    $gTxt = ''
    if ($g -and $g.Received -gt 0) { $gTxt = 'the router lost ' + $g.Lost + ' of ' + $g.Sent + ' pings' }
    switch ($P.Location) {
        'lan' {
            $media = 'On a cable: swap the cable and try another router port.'
            if ($P.ViaWifi) { $media = 'On Wi-Fi: move closer or remove obstacles, use 5 or 6 GHz, or use a cable - a cable is the only complete fix.' }
            $burst = ''
            if ($g.MaxBurst -ge 3) { $burst = ' Up to ' + $g.MaxBurst + ' pings in a row were lost (' + ($g.MaxBurst * 100) + ' ms dropouts).' }
            Write-NqFinding $level ('Packet loss starts on the link between this PC and the router: ' + $g.Lost + ' of ' + $g.Sent + ' pings to the router were lost (' + (Format-NqNum $g.LossPct) + '%), a share comparable to the internet (' + $dTxt + '). Every game packet crosses this link, so no ISP or Windows setting can fix it.' + $burst + ' ' + $media)
        }
        'access' {
            $what = 'your modem/ONT, the line into the house, or the ISP''s first router. Restart the modem once; if the loss stays, give the ISP these numbers and the time of the test'
            if ((Test-NqPrivateIPv4 $h.Address) -and ($h.Address -notmatch '^100\.')) {
                $what = 'the stretch between your router and ' + $h.Address + '. That is a private address, so it is probably a second router or the ISP modem in router mode: check the cable between the two boxes and restart that device; if the loss stays, it is the line into the house or the ISP - give the ISP these numbers'
            }
            $lc = $P.LastCleared
            $after = 'your router: it lost ' + $lc.Stats.Lost + ' of ' + $lc.Stats.Sent + ' pings'
            if ($lc.Kind -eq 'acc') { $after = 'hop ' + $lc.Ttl + ' (' + $lc.Address + '): it lost ' + $lc.Stats.Lost + ' of ' + $lc.Stats.Sent + ' pings' }
            Write-NqFinding $level ('Packet loss starts after ' + $after + ', but hop ' + $h.Ttl + ' (' + $h.Address + ') lost ' + $h.Stats.Lost + ' of ' + $h.Stats.Sent + ' (' + (Format-NqNum $h.Stats.LossPct) + '%), comparable to the internet (' + $dTxt + '). The loss is in ' + $what)
        }
        'upto-access' {
            Write-NqFinding $level ('Packet loss occurs between this PC and hop ' + $h.Ttl + ' (' + $h.Address + '): it lost ' + (Format-NqNum $h.Stats.LossPct) + '%, comparable to the internet (' + $dTxt + '). The router''s own ping replies are not reliable enough to tell whether it is your local link or the line to the ISP - run the test again over a cable to separate the two')
        }
        'beyond' {
            $past = 'your router'
            if ($h -and ($h.Kind -eq 'acc')) { $past = 'your router and hop ' + $h.Ttl + ' (' + $h.Address + '), the ISP''s first routers' }
            Write-NqFinding $level ('Packet loss appears only beyond ' + $past + ' (' + $dTxt + '). Nothing in the house causes it. If it persists at different times of day, report it to the ISP with the hop list above')
        }
        'unclear-after' {
            $lc = $P.LastCleared
            $after = 'your router'
            if ($lc.Kind -eq 'acc') { $after = 'hop ' + $lc.Ttl + ' (' + $lc.Address + ')' }
            Write-NqFinding $level ('Packet loss starts after ' + $after + ' (' + $dTxt + '), but ' + $P.Seconds + ' s was not enough to tell whether it is at hop ' + $h.Ttl + ' (' + $h.Address + ') - the line to the ISP - or further out. Run the test again, or with a longer duration')
        }
        default {
            $gPart = 'The router does not answer pings'
            if ($g -and ($g.Received -gt 0)) { $gPart = 'The router lost ' + $g.Lost + ' of ' + $g.Sent + ' pings (' + (Format-NqNum $g.LossPct) + '%)' }
            Write-NqFinding $level ('Packet loss: ' + $dTxt + '. ' + $gPart + ', so this test cannot tell whether the loss starts on your local link or beyond the router. Run it again - over a cable if you use Wi-Fi - to separate the two')
        }
    }
    if ($P.PartialLan) {
        Write-NqFinding 'INFO' ('Part of it is already on the link to the router: ' + $P.PartialLan.Stats.Lost + ' of ' + $P.PartialLan.Stats.Sent + ' router pings lost (' + (Format-NqNum $P.PartialLan.Stats.LossPct) + '%)')
    }
    if (($P.InternetLostCount -ge 3) -and ($P.Coincident -ge [math]::Ceiling(0.5 * $P.InternetLostCount)) -and (($P.Coincident / [double]$P.InternetLostCount) -gt (3 * $P.CoincidenceChance))) {
        Write-NqFinding 'INFO' ([string]$P.Coincident + ' of ' + [string]$P.InternetLostCount + ' lost internet pings were lost at the same moment as a ping to the router - short dropouts on the local link (Wi-Fi scan, interference or roaming), not the ISP')
    }
}

function Show-NqJitterFindings ($P) {
    $g = $null
    if ($P) { $g = $P.GatewayStats }
    if ($g -and ($g.Received -ge 20)) {
        $jLimit = 2; $pLimit = 10
        if ($P.ViaWifi) { $jLimit = 10; $pLimit = 50 }
        if (($g.Jitter -gt $jLimit) -or ($g.P95 -gt $pLimit)) {
            Write-NqFinding 'WARN' ('Unstable link to the router: jitter ' + (Format-NqNum $g.Jitter) + ' ms, 95th-percentile ping ' + (Format-NqNum $g.P95) + ' ms (limits ' + $jLimit + ' / ' + $pLimit + ' ms) - the delay is added before your packets even leave the house')
        }
    }
}

# ---------------------------------------------------------------------------------------
#  Counters that show loss inside this PC, read as a delta across the test window.
# ---------------------------------------------------------------------------------------
function Get-NqCounterSnapshot ([int[]]$IfIndex) {
    $nic = @{}
    foreach ($i in $IfIndex) {
        try {
            $ad = Get-NetAdapter -InterfaceIndex $i -ErrorAction Stop
            $st = Get-NetAdapterStatistics -Name $ad.Name -ErrorAction Stop
            $nic[$i] = [pscustomobject]@{
                Name = $ad.Name; IsWifi = (([string]$ad.PhysicalMediaType -match '802\.11') -or ($ad.NdisPhysicalMedium -eq 9))
                RxDiscard = [double]$st.ReceivedDiscardedPackets; RxError = [double]$st.ReceivedPacketErrors
                TxDiscard = [double]$st.OutboundDiscardedPackets; TxError = [double]$st.OutboundPacketErrors
                RxPackets = [double]$st.ReceivedUnicastPackets + [double]$st.ReceivedMulticastPackets + [double]$st.ReceivedBroadcastPackets
            }
        } catch { }
    }
    $udpErr = 0.0
    foreach ($c in @('Win32_PerfRawData_Tcpip_UDPv4', 'Win32_PerfRawData_Tcpip_UDPv6')) {
        try { $udpErr += [double](@(Get-CimInstance -ClassName $c -ErrorAction Stop)[0].DatagramsReceivedErrors) } catch { }
    }
    return [pscustomobject]@{ Nic = $nic; UdpRxErrors = $udpErr; Time = Get-Date }
}

function Show-NqCounterDelta ($A, $B, [string]$Window) {
    if (-not $A -or -not $B) { return }
    foreach ($k in $A.Nic.Keys) {
        if (-not $B.Nic.ContainsKey($k)) { continue }
        $a = $A.Nic[$k]; $b = $B.Nic[$k]
        $dd = $b.RxDiscard - $a.RxDiscard; $de = ($b.RxError - $a.RxError) + ($b.TxError - $a.TxError)
        $dp = $b.RxPackets - $a.RxPackets
        # Some drivers count filtered frames as discards all the time, so a handful is noise:
        # at least 50 and at least 0.1 percent of the packets received in the window.
        if (($dd -ge 50) -and ($dp -gt 0) -and (($dd / $dp) -ge 0.001)) {
            Write-NqFinding 'WARN' ($a.Name + ': the adapter discarded ' + [string]$dd + ' of ' + [string]$dp + ' received packets during ' + $Window + ' - this PC itself dropped them (receive ring full, or a CPU core too busy to empty it). This is the one kind of loss a Windows setting fixes: Receive Buffers at the driver maximum, RSS on')
        }
        if ($de -ge 10) {
            if ($a.IsWifi) { Write-NqFinding 'INFO' ($a.Name + ': ' + [string]$de + ' damaged frames during ' + $Window + ' - radio interference or a weak signal (Wi-Fi drivers also count some retries here)') }
            else { Write-NqFinding 'WARN' ($a.Name + ': ' + [string]$de + ' damaged frames during ' + $Window + ' - a physical fault: cable, connector or port. Replace the cable and try another router port') }
        }
    }
    $du = $B.UdpRxErrors - $A.UdpRxErrors
    if ($du -ge 5) {
        Write-NqFinding 'INFO' ('Windows dropped ' + [string]$du + ' incoming UDP datagrams during ' + $Window + ' before a program read them (socket buffer full or filtered by security software)')
    }
}

# ---------------------------------------------------------------------------------------
#  Per-logical-CPU interrupt + DPC load from the raw WMI counters (class and property names
#  are the same in every Windows language). PercentDPCTime / PercentInterruptTime are
#  100-ns timers: pct = 100 * dValue / dTimestamp_Sys100NS. InterruptsPersec is a
#  PERF_COUNTER_COUNTER: rate = dValue / (dTimestamp_PerfTime / Frequency_PerfTime).
# ---------------------------------------------------------------------------------------
function Get-NqCpuSnapshot {
    try {
        $rows = @(Get-CimInstance -ClassName Win32_PerfRawData_Counters_ProcessorInformation -ErrorAction Stop | Where-Object { [string]$_.Name -notmatch '_Total' })
        $h = @{}
        foreach ($r in $rows) {
            $h[[string]$r.Name] = [pscustomobject]@{
                Dpc = [double]$r.PercentDPCTime; Isr = [double]$r.PercentInterruptTime; Ints = [double]$r.InterruptsPersec
                T100 = [double]$r.Timestamp_Sys100NS; TPerf = [double]$r.Timestamp_PerfTime; Freq = [double]$r.Frequency_PerfTime
            }
        }
        return $h
    } catch { return $null }
}

function Compare-NqCpuSnapshot ($A, $B) {
    if (-not $A -or -not $B) { return @() }
    $out = @()
    foreach ($k in $A.Keys) {
        if (-not $B.ContainsKey($k)) { continue }
        $a = $A[$k]; $b = $B[$k]
        $dt = $b.T100 - $a.T100
        $dp = $b.TPerf - $a.TPerf
        if (($dt -le 0) -or ($dp -le 0) -or ($a.Freq -le 0)) { continue }
        $dpc = [math]::Max(0.0, [math]::Min(100.0, 100.0 * ($b.Dpc - $a.Dpc) / $dt))
        $isr = [math]::Max(0.0, [math]::Min(100.0, 100.0 * ($b.Isr - $a.Isr) / $dt))
        $ips = ($b.Ints - $a.Ints) / ($dp / $a.Freq)
        $out += [pscustomobject]@{ Cpu = $k; DpcPct = [math]::Round($dpc, 1); IsrPct = [math]::Round($isr, 1); Busy = [math]::Round($dpc + $isr, 1); IntsPerSec = [math]::Round($ips, 0) }
    }
    return @($out | Sort-Object Busy -Descending)
}

function Show-NqCpuFindings ($Idle, $Load) {
    if ($Idle -and $Idle.Count -gt 0) {
        $top = $Idle[0]
        if ($top.Busy -ge 10) {
            Write-NqFinding 'INFO' ('At idle, CPU ' + $top.Cpu + ' spends ' + (Format-NqNum $top.Busy) + '% of its time in interrupts and DPCs - some driver is busy even without traffic; LatencyMon shows which one')
        }
    }
    if ($Load -and $Load.Count -gt 1) {
        $top = $Load[0]
        $rest = @($Load | Select-Object -Skip 1 | ForEach-Object { $_.Busy } | Sort-Object)
        $med = $rest[[int][math]::Floor(($rest.Count - 1) / 2)]
        $idleTop = 0.0
        if ($Idle) { $m = @($Idle | Where-Object { $_.Cpu -eq $top.Cpu }); if ($m.Count -gt 0) { $idleTop = $m[0].Busy } }
        if ($top.Busy -ge 80) {
            Write-NqFinding 'WARN' ('CPU ' + $top.Cpu + ' spent ' + (Format-NqNum $top.Busy) + '% of its time in interrupts and DPCs while downloading - at this level the adapter can drop packets and games stutter. Check that Receive Side Scaling is enabled and update the network and chipset drivers')
        } elseif (($top.Busy -ge 30) -and ($top.Busy -ge 3 * [math]::Max(1.0, $med)) -and (($top.Busy - $idleTop) -ge 20)) {
            Write-NqFinding 'INFO' ('Network work during the download ran mostly on CPU ' + $top.Cpu + ' (' + (Format-NqNum $top.Busy) + '% interrupts + DPCs, other cores around ' + (Format-NqNum $med) + '%). It is not causing loss at this level; it only costs FPS if that core is also the game''s busiest thread')
        }
    }
}

# ---------------------------------------------------------------------------------------
#  Path MTU: DF-bit echo sweep. 1472 bytes of payload = a 1500-byte IP packet. A router
#  that cannot forward the size answers "fragmentation needed" (IPStatus PacketTooBig);
#  silence instead of that answer is a black hole. Silence is retried, and a black hole is
#  only reported when a second target shows the same limit.
# ---------------------------------------------------------------------------------------
function Send-NqDfProbe ([string]$Target, [int]$Payload, [int]$Tries = 2) {
    $ping = New-Object System.Net.NetworkInformation.Ping
    $opt = New-Object System.Net.NetworkInformation.PingOptions(64, $true)
    $buf = New-Object byte[] $Payload
    $res = 'timeout'
    try {
        for ($i = 0; $i -lt $Tries; $i++) {
            try {
                $r = $ping.Send($Target, 700, $buf, $opt)
                if ($r.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) { return 'ok' }
                if ($r.Status -eq [System.Net.NetworkInformation.IPStatus]::PacketTooBig) { return 'toobig' }
            } catch { $res = 'error' }
        }
    } finally { $ping.Dispose() }
    return $res
}

# Binary search 1200..1472 bytes of payload. "ok" and "too big" answers are definitive after
# one probe; only silence is retried, so a PPPoE line takes about 1 s and a black hole about
# 8 s worst case (700 ms timeout).
function Find-NqMtuOn ([string]$Target) {
    $top = Send-NqDfProbe $Target 1472 3
    if ($top -eq 'ok') { return [pscustomobject]@{ Target = $Target; Mtu = 1500; Signal = 'ok' } }
    if ((Send-NqDfProbe $Target 1200 3) -ne 'ok') { return [pscustomobject]@{ Target = $Target; Mtu = 0; Signal = 'unusable' } }
    $lo = 1200; $hi = 1472; $sawTooBig = ($top -eq 'toobig')
    while (($hi - $lo) -gt 1) {
        $mid = [int][math]::Floor(($lo + $hi) / 2)
        $r = Send-NqDfProbe $Target $mid 2
        if ($r -eq 'ok') { $lo = $mid } else { $hi = $mid; if ($r -eq 'toobig') { $sawTooBig = $true } }
    }
    $signal = 'toobig'
    if (-not $sawTooBig) { $signal = 'silent' }
    return [pscustomobject]@{ Target = $Target; Mtu = ($lo + 28); Signal = $signal }
}

# Second opinion on a suspected black hole: the size just under the limit must pass and
# the size 8 bytes over it must vanish on another target too.
function Confirm-NqMtuOn ([string]$Target, [int]$Mtu) {
    if ((Send-NqDfProbe $Target ($Mtu - 28) 3) -ne 'ok') { return $false }
    return ((Send-NqDfProbe $Target ([math]::Min(1472, $Mtu - 28 + 8)) 3) -eq 'timeout')
}

function Test-NqPathMtu ([string]$Gateway, [bool]$GatewayAnswers, [string[]]$Targets, [int]$IfIndex) {
    $local = 0
    try { $local = [int](Get-NetIPInterface -InterfaceIndex $IfIndex -AddressFamily IPv4 -ErrorAction Stop).NlMtu } catch { }
    $lan = $null
    if ($Gateway -and $GatewayAnswers) {
        $r = Send-NqDfProbe $Gateway 1472 3
        if ($r -eq 'ok') { $lan = [pscustomobject]@{ Target = $Gateway; Mtu = 1500; Signal = 'ok' } }
        else { $lan = Find-NqMtuOn $Gateway }
    }
    $first = $null; $confirmed = $false; $confirmBy = ''
    foreach ($t in $Targets) {
        if (-not $first) {
            $m = Find-NqMtuOn $t
            if ($m.Signal -eq 'unusable') { continue }
            $first = $m
            if (($m.Mtu -ge 1500) -or ($m.Signal -eq 'toobig')) { break }
            continue
        }
        if (Confirm-NqMtuOn $t $first.Mtu) { $confirmed = $true; $confirmBy = $t }
        break
    }
    return [pscustomobject]@{ LocalMtu = $local; Lan = $lan; First = $first; Confirmed = $confirmed; ConfirmedBy = $confirmBy }
}

function Show-NqMtuFindings ($M) {
    if (-not $M -or -not $M.First) { Write-NqFinding 'INFO' 'Path MTU could not be measured (no target answers large pings)'; return }
    if (($M.LocalMtu -gt 0) -and ($M.LocalMtu -lt 1500)) {
        Write-NqFinding 'INFO' ('This PC''s interface MTU is ' + $M.LocalMtu + ' instead of the default 1500 - usually left over from an "MTU tweak" or set by a VPN. It gives no ping benefit; Windows finds the path limit by itself')
    }
    if ($M.Lan -and ($M.Lan.Mtu -gt 0) -and ($M.Lan.Mtu -lt 1500) -and ($M.LocalMtu -ge 1500)) {
        Write-NqFinding 'WARN' ('Full-size packets do not reach the router (largest that passes: ' + $M.Lan.Mtu + ' bytes) - a switch, powerline adapter, mesh backhaul or router setting on the local network has a smaller MTU than 1500. Large transfers fragment or stall')
    }
    $f = $M.First
    if ($f.Mtu -ge 1500) { Write-NqFinding 'GOOD' 'Path MTU 1500 - full-size packets reach the internet unfragmented'; return }
    if ($f.Signal -eq 'toobig') {
        Write-NqFinding 'INFO' ('Path MTU ' + $f.Mtu + ' bytes (PPPoE or tunnel overhead), and the network correctly reports the limit, so Windows adapts automatically. Normal - do not lower the PC''s MTU, it gives no ping benefit')
        return
    }
    if ($M.Confirmed) {
        Write-NqFinding 'WARN' ('Packets larger than ' + $f.Mtu + ' bytes vanish without the "fragmentation needed" reply Windows needs to adapt (MTU black hole, same limit to ' + $f.Target + ' and ' + $M.ConfirmedBy + '). Large TCP packets - downloads, patches, some logins - stall and retransmit; small game packets are not affected. Fix it on the router: WAN MTU ' + $f.Mtu + ' or MSS clamping; if the router belongs to the ISP, report it')
    } else {
        Write-NqFinding 'INFO' ('Pings larger than ' + $f.Mtu + ' bytes to ' + $f.Target + ' went unanswered without an error, but a second target did not confirm the limit - most likely that server filters large pings, not a path problem')
    }
}

# ---------------------------------------------------------------------------------------
#  Link-level evidence from the event logs, by provider and event ID only (no message text).
# ---------------------------------------------------------------------------------------
function Get-NqEvents ([string]$Log, [string]$XPath) {
    try { return @(Get-WinEvent -LogName $Log -FilterXPath $XPath -ErrorAction Stop) }
    catch { return @() }
}

# EventData as name -> text. Classic (non-manifest) events have unnamed Data elements; they
# are returned as p0, p1, ... GetElementsByTagName avoids the PowerShell XML adapter, which
# turns attribute-less elements into plain strings.
function Get-NqEventData ($Event) {
    $h = @{}
    try {
        $x = New-Object System.Xml.XmlDocument
        $x.LoadXml($Event.ToXml())
        $i = 0
        foreach ($d in $x.GetElementsByTagName('Data')) {
            $name = $d.GetAttribute('Name')
            if (-not $name) { $name = 'p' + $i }
            $h[$name] = [string]$d.InnerText
            $i++
        }
    } catch { }
    return $h
}

function Get-NqLinkEvents ([int]$Days = 7, $Adapters = @()) {
    $ms = [int64]$Days * 86400000
    $time = 'TimeCreated[timediff(@SystemTime) <= ' + $ms + ']'
    # Power transitions: every adapter reports a link loss around them, so drops within
    # 120 s of one are ignored. Kernel-General 12/13 = OS start/shutdown, Kernel-Power 42 =
    # entering sleep, 107 = resume, 506/507 = Modern Standby enter/exit,
    # Power-Troubleshooter 1 = resume from sleep.
    $pwrXPath = "*[System[((Provider[@Name='Microsoft-Windows-Kernel-General'] and (EventID=12 or EventID=13)) or " +
                "(Provider[@Name='Microsoft-Windows-Kernel-Power'] and (EventID=42 or EventID=107 or EventID=506 or EventID=507)) or " +
                "(Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and EventID=1)) and " + $time + "]]"
    $power = @(Get-NqEvents 'System' $pwrXPath | ForEach-Object { $_.TimeCreated })
    $nearPower = {
        param($t)
        foreach ($p in $power) { if ([math]::Abs(($t - $p).TotalSeconds) -le 120) { return $true } }
        return $false
    }
    $cut24 = (Get-Date).AddHours(-24)

    # Wi-Fi (Microsoft-Windows-WLAN-AutoConfig/Operational). 8003 = disconnected, 8002 =
    # connect failed, 11001 = association succeeded. ReasonCode is a WLAN_REASON_CODE;
    # 0x38002-0x38014 (WLAN_REASON_CODE_MSM_CONNECT_BASE + 2..20: association and security
    # failures/timeouts, roaming failure, driver disconnected, driver operation failure,
    # disconnect timeout, no visible AP) are drops the user did not ask for. Only events of
    # the physical Wi-Fi adapters count (not the Wi-Fi Direct / hotspot virtual adapter).
    $wifiGuids = @{}
    foreach ($a in @($Adapters)) {
        if ((([string]$a.PhysicalMediaType -match '802\.11') -or ($a.NdisPhysicalMedium -eq 9)) -and $a.InterfaceGuid) {
            $wifiGuids[([string]$a.InterfaceGuid).Trim('{}').ToLowerInvariant()] = $true
        }
    }
    $wlanXPath = '*[System[(EventID=8002 or EventID=8003 or EventID=11001) and ' + $time + ']]'
    $wlan = @(Get-NqEvents 'Microsoft-Windows-WLAN-AutoConfig/Operational' $wlanXPath)
    $drops = @(); $fails = @(); $assocByConn = @{}
    foreach ($e in $wlan) {
        $d = Get-NqEventData $e
        $guid = ''
        if ($d['InterfaceGuid']) { $guid = ([string]$d['InterfaceGuid']).Trim('{}').ToLowerInvariant() }
        elseif ($d['DeviceGuid']) { $guid = ([string]$d['DeviceGuid']).Trim('{}').ToLowerInvariant() }
        if (($wifiGuids.Count -gt 0) -and $guid -and (-not $wifiGuids.ContainsKey($guid))) { continue }
        $rc = 0
        if ($d['ReasonCode']) { try { $rc = [int64]$d['ReasonCode'] } catch { $rc = 0 } }
        $unexpected = (($rc -ge 0x38002) -and ($rc -le 0x38014))
        if (($e.Id -eq 8003) -and $unexpected -and -not (& $nearPower $e.TimeCreated)) { $drops += $e.TimeCreated }
        elseif (($e.Id -eq 8002) -and $unexpected -and -not (& $nearPower $e.TimeCreated)) { $fails += $e.TimeCreated }
        elseif (($e.Id -eq 11001) -and ($e.TimeCreated -ge $cut24)) {
            $cid = [string]$d['ConnectionId']
            if ($assocByConn.ContainsKey($cid)) { $assocByConn[$cid]++ } else { $assocByConn[$cid] = 1 }
        }
    }
    # Re-associations: association successes beyond the first within one connection
    # (ConnectionId) - roaming between access points or mesh nodes, or a reassociation.
    $reassoc = 0
    foreach ($k in $assocByConn.Keys) { if ($assocByConn[$k] -gt 1) { $reassoc += $assocByConn[$k] - 1 } }

    # NDIS 10400 = "the network interface has begun resetting" (the driver asked NDIS to
    # reset hardware that stopped responding). Counted only when the event names one of the
    # physical adapters, so Hyper-V and other virtual adapters cannot raise it.
    $descs = @{}
    foreach ($a in @($Adapters)) { if ($a.InterfaceDescription) { $descs[[string]$a.InterfaceDescription] = [string]$a.Name } }
    $ndisXPath = "*[System[Provider[@Name='NDIS' or @Name='Microsoft-Windows-NDIS'] and EventID=10400 and " + $time + "]]"
    $resetNames = @()
    foreach ($e in @(Get-NqEvents 'System' $ndisXPath)) {
        if (& $nearPower $e.TimeCreated) { continue }
        $d = Get-NqEventData $e
        foreach ($v in $d.Values) { if ($descs.ContainsKey([string]$v)) { $resetNames += $descs[[string]$v]; break } }
    }

    # Wired link-down events logged by the NIC driver under its own service name: Intel
    # e1*/e2* "express" drivers event 27 (network link is disconnected), Realtek rt640x64
    # event 1 at Warning level (disconnected from network). Other drivers are not covered.
    $wired = @()
    foreach ($a in @($Adapters)) {
        if (([string]$a.PhysicalMediaType -match '802\.11') -or ($a.NdisPhysicalMedium -eq 9)) { continue }
        $svc = ''
        try { $svc = [string](Get-CimInstance -ClassName Win32_NetworkAdapter -Filter ('InterfaceIndex=' + [int]$a.ifIndex) -ErrorAction Stop).ServiceName } catch { }
        if (-not $svc) { continue }
        $x = $null
        if ($svc -match '^e[0-9a-z]+express$') { $x = "*[System[Provider[@Name='" + $svc + "'] and EventID=27 and " + $time + "]]" }
        elseif ($svc -eq 'rt640x64') { $x = "*[System[Provider[@Name='" + $svc + "'] and EventID=1 and Level=3 and " + $time + "]]" }
        if (-not $x) { continue }
        $ev = @(Get-NqEvents 'System' $x | Where-Object { -not (& $nearPower $_.TimeCreated) })
        $wired += [pscustomobject]@{ Adapter = [string]$a.Name; Service = $svc; Count = $ev.Count; Last24 = @($ev | Where-Object { $_.TimeCreated -ge $cut24 }).Count }
    }

    return [pscustomobject]@{
        Days = $Days
        WifiDrops = $drops.Count; WifiDrops24 = @($drops | Where-Object { $_ -ge $cut24 }).Count
        WifiFails = $fails.Count; Reassoc24 = $reassoc; WlanEvents = $wlan.Count
        NdisResets = $resetNames.Count; NdisResetAdapters = @($resetNames | Select-Object -Unique); Wired = $wired
    }
}

function Show-NqLinkEventFindings ($E) {
    if (-not $E) { return }
    if (($E.WifiDrops24 -ge 3) -or ($E.WifiDrops -ge 10)) {
        Write-NqFinding 'WARN' ('Wi-Fi dropped ' + $E.WifiDrops24 + ' times in the last 24 hours (' + $E.WifiDrops + ' in ' + $E.Days + ' days) for driver or access-point reasons, not sleep or a user disconnect (WLAN-AutoConfig event 8003). Each drop is seconds of 100% loss. Update the Wi-Fi driver from the chip maker, move closer to the router, or use a cable')
    } elseif ($E.WifiDrops -ge 1) {
        Write-NqFinding 'INFO' ('Wi-Fi dropped ' + $E.WifiDrops + ' time(s) in ' + $E.Days + ' days for driver or access-point reasons (WLAN-AutoConfig event 8003)')
    }
    if ($E.Reassoc24 -ge 10) {
        Write-NqFinding 'INFO' ('Wi-Fi re-associated ' + $E.Reassoc24 + ' times in 24 hours without a full reconnect (WLAN-AutoConfig event 11001) - roaming between access points or mesh nodes; each roam costs 50-500 ms of delay or loss. Keep the PC on one node and one band if possible')
    }
    if ($E.NdisResets -eq 1) {
        Write-NqFinding 'INFO' (($E.NdisResetAdapters -join ', ') + ' was reset once by Windows in ' + $E.Days + ' days because it stopped responding (NDIS event 10400)')
    } elseif ($E.NdisResets -ge 2) {
        Write-NqFinding 'WARN' (($E.NdisResetAdapters -join ', ') + ' was reset by Windows ' + $E.NdisResets + ' time(s) in ' + $E.Days + ' days because it stopped responding (NDIS event 10400). Each reset drops the link for seconds. Install the newest driver from the chip maker; if it continues, the adapter is faulty')
    }
    foreach ($w in @($E.Wired)) {
        if ($w.Count -ge 2) {
            Write-NqFinding 'WARN' ($w.Adapter + ': the Ethernet link went down ' + $w.Count + ' times in ' + $E.Days + ' days outside sleep and shutdown (' + $w.Service + ' driver events). A loose or damaged cable, a bad port or switch, or Energy-Efficient Ethernet - replace the cable and try another router port')
        } elseif ($w.Count -eq 1) {
            Write-NqFinding 'INFO' ($w.Adapter + ': the Ethernet link went down once in ' + $E.Days + ' days outside sleep and shutdown')
        }
    }
}

# ---------------------------------------------------------------------------------------
#  Loaded latency (bufferbloat). Probes run the whole time; download then upload saturate
#  the line over HTTPS for up to $PhaseSeconds each, with hard byte caps. Latency added
#  under load = median(loaded, ramp second dropped) - median(idle).
#  Grades (Waveform bufferbloat test): A+ <5, A <30, B <60, C <200, D <400, F >=400 ms.
# ---------------------------------------------------------------------------------------
function Test-NqMetered {
    try {
        $null = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime]
        $prof = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile()
        if (-not $prof) { return $false }
        $cost = $prof.GetConnectionCost()
        $type = [string]$cost.NetworkCostType
        return (($type -eq 'Fixed') -or ($type -eq 'Variable') -or $cost.Roaming -or $cost.OverDataLimit)
    } catch { return $false }
}

function Get-NqGrade ([double]$Added) {
    if ($Added -lt 5) { return 'A+' }
    if ($Added -lt 30) { return 'A' }
    if ($Added -lt 60) { return 'B' }
    if ($Added -lt 200) { return 'C' }
    if ($Added -lt 400) { return 'D' }
    return 'F'
}

function Invoke-NqLoadedLatency {
    param(
        [string]$Gateway = '',
        [string]$Target = '1.1.1.1',
        [double]$IdleMedian = -1,
        [double]$IdleGatewayMedian = -1,
        [int]$PhaseSeconds = 8,
        [int]$Streams = 4,
        [int]$DownCapMB = 400,
        [int]$UpCapMB = 100,
        [string]$DownUrl = 'https://speed.cloudflare.com/__down',
        [string]$UpUrl = 'https://speed.cloudflare.com/__up',
        [string]$DownFallbackUrl = 'https://nbg1-speed.hetzner.com/1GB.bin',
        [switch]$SampleCpu
    )
    $phase = [int]($PhaseSeconds * 1000)
    # Upper bound only; the run is stopped explicitly 1 s after the upload phase. Timeout 3 s
    # so that a badly bloated line shows up as high latency, not as loss.
    $total = 2000 + $phase + 2000 + $phase + 10000
    $specs = New-Object 'System.Collections.Generic.List[NqDiag.ProbeSpec]'
    $s = New-Object NqDiag.ProbeSpec
    $s.Name = 'tgt'; $s.Target = $Target; $s.IntervalMs = 50; $s.OffsetMs = 0; $s.StopMs = $total; $s.TimeoutMs = 3000
    $specs.Add($s)
    if ($Gateway) {
        $g = New-Object NqDiag.ProbeSpec
        $g.Name = 'gw'; $g.Target = $Gateway; $g.IntervalMs = 100; $g.OffsetMs = 25; $g.StopMs = $total; $g.TimeoutMs = 3000
        $specs.Add($g)
    }
    $run = New-Object NqDiag.ProbeRun (, $specs.ToArray())
    $run.Start()
    $cpuA = $null; $cpuB = $null
    $phases = @(@{ Name = 'down'; Url = $DownUrl; Up = $false; Cap = [int64]$DownCapMB * 1MB; Chunk = 25000000 },
                @{ Name = 'up'; Url = $UpUrl; Up = $true; Cap = [int64]$UpCapMB * 1MB; Chunk = 10000000 })
    $loads = @{}
    $at = 2000
    foreach ($ph in $phases) {
        while ($run.ElapsedMs -lt $at) { Start-Sleep -Milliseconds 20 }
        $ld = New-Object NqDiag.Loader ($ph.Url, $ph.Up, $Streams, $ph.Chunk, $ph.Cap)
        $t0 = $run.ElapsedMs
        $ld.Start()
        # Download only: if the primary server delivers nothing within 2 s, use the fallback
        # (there is no comparable public upload endpoint, so the upload phase has none).
        if ((-not $ph.Up) -and $DownFallbackUrl) {
            while ((($run.ElapsedMs - $t0) -lt 2000) -and ($ld.Bytes -eq 0)) { Start-Sleep -Milliseconds 50 }
            if (($ld.Bytes -eq 0) -and ($ld.Errors -gt 0)) {
                $ld.Stop()
                $ld = New-Object NqDiag.Loader ($DownFallbackUrl, $false, $Streams, $ph.Chunk, $ph.Cap)
                $t0 = $run.ElapsedMs
                $ld.Start()
            }
        }
        $trace = New-Object 'System.Collections.Generic.List[double[]]'
        $cpuTaken = $false
        while (($run.ElapsedMs - $t0) -lt $phase) {
            Start-Sleep -Milliseconds 50
            $trace.Add([double[]]@($run.ElapsedMs, [double]$ld.Bytes))
            if ($SampleCpu -and (-not $cpuTaken) -and ($ph.Name -eq 'down') -and (($run.ElapsedMs - $t0) -ge 500)) { $cpuA = Get-NqCpuSnapshot; $cpuTaken = $true }
            if ($ld.CapReached -or ($ld.Errors -ge 8)) { break }
        }
        if ($cpuTaken) { $cpuB = Get-NqCpuSnapshot }
        $t2 = $run.ElapsedMs; $b2 = [double]$ld.Bytes
        $ld.Stop()
        # Ramp-up (TCP slow start, TLS) is left out: the first second, or the first quarter
        # of the phase when a fast line hits the byte cap sooner.
        $ramp = [math]::Min(1000.0, 0.25 * ($t2 - $t0))
        $t1 = $t0; $b1 = 0.0
        foreach ($pt in $trace) { if ($pt[0] -ge ($t0 + $ramp)) { $t1 = $pt[0]; $b1 = $pt[1]; break } }
        if (($t2 - $t1) -lt 100) { $t1 = $t0; $b1 = 0.0 }
        $mbps = 0.0
        if ($t2 -gt $t1) { $mbps = [math]::Round((($b2 - $b1) * 8.0) / (($t2 - $t1) * 1000.0), 1) }
        $loads[$ph.Name] = [pscustomobject]@{ From = $t0 + $ramp; To = $t2; Seconds = [math]::Round(($t2 - $t0) / 1000.0, 1); Mbps = $mbps; Bytes = $b2; CapHit = $ld.CapReached; Errors = $ld.Errors; LastError = $ld.LastError; Requests = $ld.Requests }
        $at = [int]$t2 + 2000
    }
    $end = $run.ElapsedMs + 1000
    while ($run.ElapsedMs -lt $end) { Start-Sleep -Milliseconds 20 }
    $run.Stop()
    [void]$run.Wait(4000)
    $by = Split-NqResults $run.Results
    $idleT = Get-NqStreamStats $by[0] 300 2000
    $idleG = $null
    if ($Gateway) { $idleG = Get-NqStreamStats $by[1] 300 2000 }
    $baseT = $idleT.Median; if ($IdleMedian -ge 0) { $baseT = [math]::Min($IdleMedian, $idleT.Median) }
    if ($idleT.Received -eq 0) { $baseT = $IdleMedian }
    $baseG = -1.0
    if ($idleG -and $idleG.Received -gt 0) { $baseG = $idleG.Median; if ($IdleGatewayMedian -ge 0) { $baseG = [math]::Min($IdleGatewayMedian, $idleG.Median) } }
    $res = @{}
    foreach ($name in @('down', 'up')) {
        $l = $loads[$name]
        if (-not $l) { continue }
        $st = Get-NqStreamStats $by[0] $l.From $l.To
        $gs = $null
        if ($Gateway) { $gs = Get-NqStreamStats $by[1] $l.From $l.To }
        $added = -1.0; $gAdded = -1.0; $grade = ''
        if (($st.Received -ge 10) -and ($baseT -ge 0) -and ($l.Mbps -ge 1)) {
            $added = [math]::Round([math]::Max(0.0, $st.Median - $baseT), 1)
            $grade = Get-NqGrade $added
        }
        if ($gs -and ($gs.Received -ge 10) -and ($baseG -ge 0)) { $gAdded = [math]::Round([math]::Max(0.0, $gs.Median - $baseG), 1) }
        $res[$name] = [pscustomobject]@{ Load = $l; Stats = $st; Gateway = $gs; Added = $added; GatewayAdded = $gAdded; Grade = $grade; IdleMedian = $baseT }
    }
    $cpu = @()
    if ($cpuA -and $cpuB) { $cpu = @(Compare-NqCpuSnapshot $cpuA $cpuB) }
    return [pscustomobject]@{ Target = $Target; Idle = $idleT; Down = $res['down']; Up = $res['up']; CpuLoad = $cpu }
}

function Show-NqLoadedFindings ($L, [bool]$ViaWifi, $IdleLoss) {
    if (-not $L) { return }
    $speeds = @{}
    foreach ($name in @('down', 'up')) {
        $r = $L.Down; $label = 'download'
        if ($name -eq 'up') { $r = $L.Up; $label = 'upload' }
        if (-not $r) { continue }
        if (-not $r.Grade) {
            $why = 'only ' + $r.Stats.Received + ' ping replies arrived while the line was full'
            if (($r.Load.Errors -gt 0) -and ($r.Load.Mbps -lt 1) -and (-not $r.Load.CapHit)) { $why = 'the transfer failed (' + $r.Load.LastError + ')' }
            elseif (($r.Load.Mbps -lt 1) -and (-not $r.Load.CapHit)) { $why = 'the transfer reached only ' + (Format-NqNum $r.Load.Mbps) + ' Mbit/s' }
            elseif ($r.Load.CapHit -and ($r.Stats.Received -lt 10)) { $why = 'the line moved the whole data cap in ' + (Format-NqNum $r.Load.Seconds) + ' s (about ' + (Format-NqNum $r.Load.Mbps 0) + ' Mbit/s), too briefly to measure; at this speed bufferbloat is rarely the problem' }
            Write-NqFinding 'INFO' ('Loaded-latency test, ' + $label + ': ' + $why + ' - not graded')
            continue
        }
        $speeds[$name] = $r.Load.Mbps
        $txt = 'Loaded latency, ' + $label + ' at ' + (Format-NqNum $r.Load.Mbps) + ' Mbit/s: ' + $L.Target + ' ' + (Format-NqNum $r.IdleMedian) + ' -> ' + (Format-NqNum $r.Stats.Median) + ' ms median (+' + (Format-NqNum $r.Added) + ' ms, 95th ' + (Format-NqNum $r.Stats.P95) + ' ms) - bufferbloat grade ' + $r.Grade
        if ($r.Added -ge 60) {
            Write-NqFinding 'WARN' ($txt + '. Latency rises by ' + (Format-NqNum $r.Added) + ' ms whenever the ' + $label + ' is full: the router or modem queues packets (bufferbloat), so any download, update, upload or stream during a match causes lag spikes and loss. Fix: turn on SQM / Smart Queue / Adaptive QoS (cake or fq_codel) on the router with limits at about 90% of the speeds measured here')
        } elseif ($r.Added -ge 30) {
            Write-NqFinding 'INFO' ($txt + '. Mild bufferbloat - noticeable only while something else uses the line; SQM on the router would remove it')
        } else {
            Write-NqFinding 'GOOD' $txt
        }
        if (($r.GatewayAdded -ge 15) -and ($r.Added -gt 0) -and ($r.GatewayAdded -ge 0.5 * $r.Added)) {
            $where = 'the cable link or this PC''s network adapter'
            if ($ViaWifi) { $where = 'Wi-Fi airtime' }
            Write-NqFinding 'INFO' ('Most of that delay (+' + (Format-NqNum $r.GatewayAdded) + ' ms) already appears on the way to the router, so the queue is on ' + $where + ', not the modem. SQM on the internet side will not remove this part')
        }
        $idleLost = 0; $idleSent = 0; $idleTxt = 'not measured'
        if ($IdleLoss) { $idleLost = $IdleLoss.Lost; $idleSent = $IdleLoss.Sent; $idleTxt = (Format-NqNum $IdleLoss.LossPct) + '%' }
        if (($r.Stats.CiLow -gt 1.0) -and (($idleSent -eq 0) -or ((Get-NqZ $r.Stats.Lost $r.Stats.Sent $idleLost $idleSent) -ge 2.58))) {
            Write-NqFinding 'WARN' ('While the ' + $label + ' was full, ' + $r.Stats.Lost + ' of ' + $r.Stats.Sent + ' pings were lost (' + (Format-NqNum $r.Stats.LossPct) + '%; idle: ' + $idleTxt + ') - packets are dropped when the queue overflows, so any download or upload during a match causes loss. SQM with limits at about 90% of line speed prevents this')
        }
    }
    if ($speeds.Count -eq 2) {
        Write-NqFinding 'INFO' ('Measured about ' + (Format-NqNum $speeds['down'] 0) + ' Mbit/s down and ' + (Format-NqNum $speeds['up'] 0) + ' Mbit/s up; SQM limits of ' + (Format-NqNum (0.9 * $speeds['down']) 0) + ' / ' + (Format-NqNum (0.9 * $speeds['up']) 0) + ' Mbit/s are a good starting point')
    }
}

# ---------------------------------------------------------------------------------------
#  Orchestration, about 55-60 s: hop discovery 3 s, path test 30 s (event-log reads run
#  while it measures), MTU 1-5 s, loaded test about 21 s. Read only; runs in a dry run too.
# ---------------------------------------------------------------------------------------
function Invoke-NqDiagnostics {
    param(
        [string[]]$Targets = @('1.1.1.1', '8.8.8.8', '9.9.9.9'),
        [string]$TraceTarget = '',
        [int]$Seconds = 30,
        [bool]$LoadTest = $true,
        [string[]]$GameExes = @()
    )
    if (-not (Initialize-NqProbeEngine)) {
        Write-NqFinding 'INFO' 'The probe engine could not be compiled (Add-Type blocked by policy) - diagnostics skipped'
        return $null
    }
    $route = Get-NqDefaultRoute
    if (-not $route) { Write-NqFinding 'INFO' 'No IPv4 default route - diagnostics skipped'; return $null }
    if (-not $route.IsPhysical) { Write-NqFinding 'INFO' ('Internet traffic leaves through ' + $route.Adapter + ' (VPN or virtual adapter): the results below describe the tunnel, not your line') }
    $gw = ''
    if ($route.IsPhysical) { $gw = $route.Gateway }
    $phys = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' })

    $cnt0 = Get-NqCounterSnapshot @($phys | ForEach-Object { [int]$_.ifIndex })
    $cpu0 = Get-NqCpuSnapshot
    # The event-log reads run on this thread while the probe engine measures on its own.
    $box = @{ Events = $null }
    $whileRunning = { $box.Events = Get-NqLinkEvents 7 $phys }
    $path = Invoke-NqPathDiagnostic -Gateway $gw -Targets $Targets -TraceTarget $TraceTarget -Seconds $Seconds -ViaWifi $route.IsWifi -WhileRunning $whileRunning
    $cpu1 = Get-NqCpuSnapshot
    $cnt1 = Get-NqCounterSnapshot @($phys | ForEach-Object { [int]$_.ifIndex })

    Show-NqPathFindings $path
    Show-NqJitterFindings $path
    Show-NqCounterDelta $cnt0 $cnt1 'the path test'
    Show-NqLinkEventFindings $box.Events

    $gwAnswers = [bool]($path.GatewayStats -and ($path.GatewayStats.Received -gt 0))
    $mtu = Test-NqPathMtu $gw $gwAnswers $Targets $route.Index
    Show-NqMtuFindings $mtu

    $idleCpu = @(Compare-NqCpuSnapshot $cpu0 $cpu1)
    $loaded = $null
    if ($LoadTest) {
        $running = @()
        if ($GameExes.Count -gt 0) {
            $names = @(Get-Process -ErrorAction SilentlyContinue | ForEach-Object { ([string]$_.ProcessName).ToLowerInvariant() + '.exe' })
            $running = @($GameExes | Where-Object { $names -contains $_.ToLowerInvariant() })
        }
        if ($running.Count -gt 0) { Write-NqFinding 'INFO' ('Loaded-latency test skipped: ' + ($running -join ', ') + ' is running and the test fills the line for about 20 s') }
        elseif (Test-NqMetered) { Write-NqFinding 'INFO' 'Loaded-latency test skipped: this connection is set as metered, and the test transfers up to about 0.5 GB' }
        else {
            $tgt = $Targets[0]
            $idleMed = -1.0; $idleGw = -1.0
            $pick = @($path.Targets | Where-Object { (-not $_.Excluded) -and ($_.Stats.Received -gt 0) } | Sort-Object { $_.Stats.Median } | Select-Object -First 1)
            if ($pick.Count -gt 0) { $tgt = $pick[0].Target; $idleMed = $pick[0].Stats.Median }
            if ($path.GatewayStats -and $path.GatewayStats.Received -gt 0) { $idleGw = $path.GatewayStats.Median }
            $cnt2 = Get-NqCounterSnapshot @($phys | ForEach-Object { [int]$_.ifIndex })
            $loaded = Invoke-NqLoadedLatency -Gateway $gw -Target $tgt -IdleMedian $idleMed -IdleGatewayMedian $idleGw -SampleCpu
            $cnt3 = Get-NqCounterSnapshot @($phys | ForEach-Object { [int]$_.ifIndex })
            Show-NqLoadedFindings $loaded $route.IsWifi $path.Internet
            Show-NqCounterDelta $cnt2 $cnt3 'the load test'
        }
    }
    $loadCpu = @()
    if ($loaded) { $loadCpu = @($loaded.CpuLoad) }
    Show-NqCpuFindings $idleCpu $loadCpu
    return [pscustomobject]@{ Route = $route; Path = $path; Mtu = $mtu; Loaded = $loaded; Events = $box.Events; IdleCpu = $idleCpu }
}

function Invoke-NqEngine {
if (-not (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue)) {
    Failed 'NetAdapter module not found - the adapter stage cannot run.'
    return
}

$Restart = @{}
$Cache   = @{}

# Power-saving link modes: standard and vendor keywords first, then any other property whose
# English display name names a power-saving mode. Wake-on-LAN and sleep features are excluded:
# they only act while the PC sleeps and have no effect on a running game.
$PowerKeys    = @('*EEE','EEELinkAdvertisement','AdvancedEEE','EnableGreenEthernet','GreenEthernet',
                  'PowerSavingMode','AutoDisableGigabit','AutoPowerSaveModeEnabled','SipsEnabled','ULPMode',
                  '*SelectiveSuspend','EnableExtraPowerSaving','EnableAdaptiveLinkCap','UsbPowerSave',
                  'BatteryModeLinkSpeed','APSmode')
$PowerNames   = '(?i)green|energy.?eff|power.?sav|\bEEE\b|ASPM|idle power|low.?power|battery|selective suspend|ultra low'
$PowerExclude = '(?i)wake|\bWOL\b|WoWLAN|shutdown|MIMO|SMPS|restriction|max support|timeout'

$Nics = @(Read-Nq 'Enumerating physical network adapters' { Get-NetAdapter -Physical | Where-Object {
    ($_.Status -ne 'Disabled') -and ($_.Status -ne 'Not Present') -and
    ($_.InterfaceDescription -notmatch 'Bluetooth') -and ($_.PhysicalMediaType -notmatch 'BlueTooth')
} })
if ($Nics.Count -eq 0) { Skip 'No eligible physical adapters returned; adapter stage skipped.'; return }

function IsWifi ($n) { return (($n.PhysicalMediaType -match '802\.11') -or ($n.NdisPhysicalMedium -eq 9)) }
function IsUsb ($n) { return ([string]$n.PnPDeviceID -like 'USB\*') }

# One read of every advanced property per adapter; all later decisions use this cache.
foreach ($n in $Nics) {
    $h = @{}
    foreach ($p in @(Read-Nq ('Reading driver properties: ' + $n.Name) { Get-NetAdapterAdvancedProperty -Name $n.Name })) {
        if ($p.RegistryKeyword) { $h[[string]$p.RegistryKeyword] = $p }
    }
    $Cache[$n.Name] = $h
}

function ValidOf ($p) {
    if ($p.ValidRegistryValues) { return @($p.ValidRegistryValues | ForEach-Object { [string]$_ }) }
    return @()
}

function DispOf ($p, [string]$rv) {
    $r = @(ValidOf $p)
    $d = @()
    if ($p.ValidDisplayValues) { $d = @($p.ValidDisplayValues) }
    for ($i = 0; $i -lt $r.Count; $i++) {
        if (($r[$i] -eq $rv) -and ($i -lt $d.Count)) { return [string]$d[$i] }
    }
    return $rv
}

function Set-Adv ($n, [string]$kw, [string]$val) {
    $p = $Cache[$n.Name][$kw]
    if (-not $p) { Missing $kw; return }
    $name = $kw
    if ($p.DisplayName) { $name = [string]$p.DisplayName }
    $cur   = [string](@($p.RegistryValue)[0])
    $valid = @(ValidOf $p)
    if ($valid.Count -gt 0) {
        if ($valid -notcontains $val) { Skip ($name + ': driver does not offer value ' + $val); return }
    } elseif ($p.NumericParameterMaxValue -gt 0) {
        [int64]$v = 0
        if (-not [int64]::TryParse($val, [ref]$v)) { Failed ($n.Name + ': ' + $kw + ' requires a numeric value'); return }
        if (($v -lt [int64]$p.NumericParameterMinValue) -or ($v -gt [int64]$p.NumericParameterMaxValue)) {
            Skip ($name + ': ' + $val + ' outside driver range'); return
        }
    }
    if ($cur -eq $val) { Same ($name + ' = ' + (DispOf $p $val)); return }
    Doing 'NIC' ($n.Name + ': setting ' + $name + ' [' + $kw + '] to ' + $val + ' (' + (DispOf $p $val) + ')')
    try {
        Change { Set-NetAdapterAdvancedProperty -Name $n.Name -RegistryKeyword $kw -RegistryValue $val -NoRestart -ErrorAction Stop }
        $Restart[$n.Name] = $true
        Ok ($name + ': ' + (DispOf $p $cur) + ' -> ' + (DispOf $p $val))
    } catch {
        Failed ($n.Name + ': ' + $name + ': ' + $_.Exception.Message)
    }
}

# Picks the lowest (default) or highest (-Max) value the driver allows for a keyword.
function Set-AdvEdge ($n, [string]$kw, [switch]$Max) {
    $p = $Cache[$n.Name][$kw]
    if (-not $p) { Missing $kw; return }
    $nums = @()
    $valid = @(ValidOf $p)
    if ($valid.Count -gt 0) {
        foreach ($s in $valid) { [int64]$x = 0; if ([int64]::TryParse($s, [ref]$x)) { $nums += $x } }
    } elseif ($p.NumericParameterMaxValue -gt 0) {
        $nums = @([int64]$p.NumericParameterMinValue, [int64]$p.NumericParameterMaxValue)
    }
    if ($nums.Count -eq 0) { Skip ($n.Name + ': ' + $kw + ' exposes no numeric choices or range'); return }
    if ($Max) { $t = [int64](($nums | Measure-Object -Maximum).Maximum) }
    else      { $t = [int64](($nums | Measure-Object -Minimum).Minimum) }
    Set-Adv $n $kw ([string]$t)
}

# Selects an enum entry by its display text, for vendor keywords whose numeric codes vary.
function Set-AdvByText ($n, [string]$kw, [string]$pattern) {
    $p = $Cache[$n.Name][$kw]
    if (-not $p) { Missing $kw; return }
    if (-not $p.ValidDisplayValues) { Skip ($n.Name + ': ' + $kw + ' exposes no display choices'); return }
    $d = @($p.ValidDisplayValues)
    $r = @(ValidOf $p)
    for ($i = 0; $i -lt $d.Count; $i++) {
        if (($d[$i] -match $pattern) -and ($i -lt $r.Count)) { Set-Adv $n $kw $r[$i]; return }
    }
    Skip ($n.Name + ': ' + $kw + ' offers no display value matching ' + $pattern)
}

# First exposed keyword from a list, else the first property whose display name matches.
function Find-Kw ($n, [string[]]$keys, [string]$namePattern) {
    foreach ($k in $keys) { if ($Cache[$n.Name][$k]) { return $k } }
    if ($namePattern) {
        foreach ($p in @($Cache[$n.Name].Values)) {
            if ([string]$p.DisplayName -match $namePattern) { return [string]$p.RegistryKeyword }
        }
    }
    return $null
}

function Test-Offers ($n, [string]$kw, [string]$pattern) {
    $p = $Cache[$n.Name][$kw]
    if ((-not $p) -or (-not $p.ValidDisplayValues)) { return $false }
    return (@($p.ValidDisplayValues | Where-Object { [string]$_ -match $pattern }).Count -gt 0)
}

# Returns a keyword to the value its driver ships with. Silent when the driver lacks it.
function Set-AdvDefault ($n, [string]$kw) {
    $p = $Cache[$n.Name][$kw]
    if (-not $p) { return }
    $def = [string]$p.DefaultRegistryValue
    if (-not $def) { Skip ($n.Name + ': ' + $kw + ' has no driver default to return to'); return }
    Set-Adv $n $kw $def
}

# FPS guard. Each keyword below saves CPU time while it is on; other optimizers switch them
# off for a latency gain of microseconds, paid for with extra interrupts and per-packet work on
# the cores that also run the game. Any value that differs from the driver default goes back.
$CpuKeys    = @('*InterruptModeration','ITR','IMR','*PacketCoalescing','*RscIPv4','*RscIPv6','*UdpRsc',
                '*IPChecksumOffloadIPv4','*TCPChecksumOffloadIPv4','*TCPChecksumOffloadIPv6',
                '*UDPChecksumOffloadIPv4','*UDPChecksumOffloadIPv6','*LsoV1IPv4','*LsoV2IPv4','*LsoV2IPv6')
# Receive queue and processor counts only come back when forced BELOW the default; a higher
# count spreads receive work over more cores and is left as chosen.
$CpuMinKeys = @('*NumRssQueues','*MaxRssProcessors')
function Restore-CpuDefaults ($n) {
    $atDefault = 0
    $keys = @($CpuKeys)
    if (Flag 'NQ_INTMOD_OFF') { $keys = @($keys | Where-Object { @('*InterruptModeration', 'ITR', 'IMR') -notcontains $_ }) }
    foreach ($kw in $keys) {
        $p = $Cache[$n.Name][$kw]
        if ((-not $p) -or (-not [string]$p.DefaultRegistryValue)) { continue }
        if ([string](@($p.RegistryValue)[0]) -eq [string]$p.DefaultRegistryValue) { $atDefault++; continue }
        Set-Adv $n $kw ([string]$p.DefaultRegistryValue)
    }
    foreach ($kw in $CpuMinKeys) {
        $p = $Cache[$n.Name][$kw]
        if (-not $p) { continue }
        [int64]$c = 0; [int64]$d = 0
        if (-not ([int64]::TryParse([string](@($p.RegistryValue)[0]), [ref]$c) -and [int64]::TryParse([string]$p.DefaultRegistryValue, [ref]$d))) { continue }
        if ($c -lt $d) { Set-Adv $n $kw ([string]$d) } else { $atDefault++ }
    }
    if ($atDefault -gt 0) { $script:NQ_Same++; Write-Host ('     [SAME] ' + $n.Name + ': ' + $atDefault + ' CPU-saving features already at their driver defaults (interrupt moderation, offloads, coalescing, RSS queues)') -ForegroundColor DarkGreen }
}

# A driver keyword written only when the driver exposes it. Vendor tables list keywords of
# several chip makers, so an absent one is normal and is not reported.
function Set-AdvIf ($n, [string]$kw, [string]$val) { if ($Cache[$n.Name][$kw]) { Set-Adv $n $kw $val } }

# PCI or USB vendor, device and revision from the Plug and Play ID, plus the driver service.
function Get-NqChip ($n) {
    $id = [string]$n.PnPDeviceID
    $o = [pscustomobject]@{ Ven = ''; Dev = ''; Rev = ''; Svc = ''; Ver = $null }
    if ($id -match 'VID_([0-9A-F]{4})&PID_([0-9A-F]{4})') { $o.Ven = $Matches[1]; $o.Dev = $Matches[2] }
    elseif ($id -match 'VEN_([0-9A-F]{4})&DEV_([0-9A-F]{4})') { $o.Ven = $Matches[1]; $o.Dev = $Matches[2] }
    if ($id -match '&REV_([0-9A-F]{2})') { $o.Rev = $Matches[1] }
    $v = $null
    if ([version]::TryParse([string]$n.DriverVersionString, [ref]$v)) { $o.Ver = $v }
    $o.Svc = [string](Probe { (Get-ItemProperty -LiteralPath ('HKLM:\SYSTEM\CurrentControlSet\Enum\' + $id) -Name Service -ErrorAction Stop).Service })
    return $o
}

# Sleep, resume and boot times of the last 7 days: link drops within 3 minutes of one are
# normal power transitions, not faults.
$script:NqPowerTimes = @()
function Test-NearPower ([datetime]$t) {
    foreach ($p in $script:NqPowerTimes) { if ([math]::Abs(($t - $p).TotalSeconds) -le 180) { return $true } }
    return $false
}

# Wi-Fi link facts from the Native Wifi API, so nothing depends on the display language.
# Only cached data is read: no scan is ever requested. Offsets follow wlanapi.h (x64).
function Get-NqWlanInfo {
    $out = @{}
    if (-not ('NqWlan' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class NqWlan {
    [DllImport("wlanapi.dll")] public static extern uint WlanOpenHandle(uint v, IntPtr r, out uint n, out IntPtr h);
    [DllImport("wlanapi.dll")] public static extern uint WlanCloseHandle(IntPtr h, IntPtr r);
    [DllImport("wlanapi.dll")] public static extern uint WlanEnumInterfaces(IntPtr h, IntPtr r, out IntPtr l);
    [DllImport("wlanapi.dll")] public static extern uint WlanQueryInterface(IntPtr h, ref Guid g, uint op, IntPtr r, out uint sz, out IntPtr d, IntPtr t);
    [DllImport("wlanapi.dll")] public static extern uint WlanGetNetworkBssList(IntPtr h, ref Guid g, IntPtr s, int t, bool sec, IntPtr r, out IntPtr l);
    [DllImport("wlanapi.dll")] public static extern void WlanFreeMemory(IntPtr p);
}
'@ -IgnoreWarnings -WarningAction SilentlyContinue
    }
    $M = [Runtime.InteropServices.Marshal]
    $h = [IntPtr]::Zero; $nv = [uint32]0; $sz = [uint32]0; $d = [IntPtr]::Zero; $il = [IntPtr]::Zero
    if ([NqWlan]::WlanOpenHandle(2, [IntPtr]::Zero, [ref]$nv, [ref]$h) -ne 0) { return $out }
    try {
        if ([NqWlan]::WlanEnumInterfaces($h, [IntPtr]::Zero, [ref]$il) -ne 0) { return $out }
        try {
            $count = $M::ReadInt32($il, 0)
            for ($i = 0; $i -lt $count; $i++) {
                $e = [IntPtr]($il.ToInt64() + 8 + 532 * $i)
                $gb = New-Object byte[] 16
                $M::Copy($e, $gb, 0, 16)
                $g = New-Object Guid (, $gb)
                if ($M::ReadInt32($e, 528) -ne 1) { continue }
                $w = [pscustomobject]@{ Loc = $true; Phy = -1; TxK = -1; MHz = 0; Rssi = $null; Quality = -1; Ssid = ''; Bssid = ''; Profile = ''; Bss = @() }
                # Realtime quality (Windows 11 24H2+): frequency and RSSI without location access.
                if ([NqWlan]::WlanQueryInterface($h, [ref]$g, 19, [IntPtr]::Zero, [ref]$sz, [ref]$d, [IntPtr]::Zero) -eq 0) {
                    try {
                        $w.Phy = $M::ReadInt32($d, 0); $w.TxK = $M::ReadInt32($d, 12)
                        if ($M::ReadInt32($d, 20) -gt 0) {
                            $f = [double]$M::ReadInt32($d, 28)
                            if ($f -gt 100000) { $f = $f / 1000 }
                            $w.MHz = [int]$f; $w.Rssi = $M::ReadInt32($d, 36)
                        }
                    } finally { [NqWlan]::WlanFreeMemory($d) }
                }
                $rc = [NqWlan]::WlanQueryInterface($h, [ref]$g, 7, [IntPtr]::Zero, [ref]$sz, [ref]$d, [IntPtr]::Zero)
                if ($rc -eq 5) { $w.Loc = $false }
                elseif ($rc -eq 0) {
                    try {
                        $w.Profile = $M::PtrToStringUni([IntPtr]($d.ToInt64() + 8))
                        $sl = [math]::Min(32, $M::ReadInt32($d, 520))
                        $sb = New-Object byte[] $sl
                        if ($sl -gt 0) { $M::Copy([IntPtr]($d.ToInt64() + 524), $sb, 0, $sl) }
                        $w.Ssid = [Text.Encoding]::UTF8.GetString($sb)
                        $mb = New-Object byte[] 6
                        $M::Copy([IntPtr]($d.ToInt64() + 560), $mb, 0, 6)
                        $w.Bssid = [BitConverter]::ToString($mb)
                        $w.Phy = $M::ReadInt32($d, 568); $w.Quality = $M::ReadInt32($d, 576); $w.TxK = $M::ReadInt32($d, 584)
                    } finally { [NqWlan]::WlanFreeMemory($d) }
                }
                if (($null -eq $w.Rssi) -and ([NqWlan]::WlanQueryInterface($h, [ref]$g, 0x10000102, [IntPtr]::Zero, [ref]$sz, [ref]$d, [IntPtr]::Zero) -eq 0)) {
                    try { $w.Rssi = $M::ReadInt32($d, 0) } finally { [NqWlan]::WlanFreeMemory($d) }
                }
                $bl = [IntPtr]::Zero
                if ($w.Loc -and ([NqWlan]::WlanGetNetworkBssList($h, [ref]$g, [IntPtr]::Zero, 3, $false, [IntPtr]::Zero, [ref]$bl) -eq 0)) {
                    try {
                        $list = New-Object System.Collections.Generic.List[object]
                        $nb = $M::ReadInt32($bl, 4)
                        for ($j = 0; $j -lt $nb; $j++) {
                            $b = [IntPtr]($bl.ToInt64() + 8 + 360 * $j)
                            $util = -1
                            $ieLen = $M::ReadInt32($b, 356)
                            if (($ieLen -gt 0) -and ($ieLen -lt 65536)) {
                                $ie = New-Object byte[] $ieLen
                                $M::Copy([IntPtr]($b.ToInt64() + $M::ReadInt32($b, 352)), $ie, 0, $ieLen)
                                for ($k = 0; ($k + 1) -lt $ie.Length; $k += 2 + $ie[$k + 1]) {
                                    if (($ie[$k] -eq 11) -and ($ie[$k + 1] -ge 5) -and (($k + 4) -lt $ie.Length)) { $util = [int][math]::Round($ie[$k + 4] * 100 / 255) }
                                }
                            }
                            $sl = [math]::Min(32, $M::ReadInt32($b, 0))
                            $sb = New-Object byte[] $sl
                            if ($sl -gt 0) { $M::Copy([IntPtr]($b.ToInt64() + 4), $sb, 0, $sl) }
                            $mb = New-Object byte[] 6
                            $M::Copy([IntPtr]($b.ToInt64() + 40), $mb, 0, 6)
                            $list.Add([pscustomobject]@{ Ssid = [Text.Encoding]::UTF8.GetString($sb); Bssid = [BitConverter]::ToString($mb); Rssi = $M::ReadInt32($b, 56); MHz = [int]($M::ReadInt32($b, 92) / 1000); Util = $util })
                        }
                        $w.Bss = $list.ToArray()
                    } finally { [NqWlan]::WlanFreeMemory($bl) }
                }
                # Without the realtime query, frequency comes from our own BSS entry.
                if (($w.MHz -eq 0) -and $w.Bssid) {
                    $own = @($w.Bss | Where-Object { $_.Bssid -eq $w.Bssid }) | Select-Object -First 1
                    if ($own) { $w.MHz = $own.MHz; if ($null -eq $w.Rssi) { $w.Rssi = $own.Rssi } }
                }
                $out[$g.ToString('B').ToUpperInvariant()] = $w
            }
        } finally { [NqWlan]::WlanFreeMemory($il) }
    } finally { [void][NqWlan]::WlanCloseHandle($h, [IntPtr]::Zero) }
    return $out
}

function Get-NqBand ([int]$mhz) {
    if ($mhz -le 0) { return '' }
    if ($mhz -lt 3000) { return '2.4' }
    if ($mhz -lt 5925) { return '5' }
    return '6'
}
function Get-NqChannel ([int]$mhz) {
    if ($mhz -le 0) { return 0 }
    if ($mhz -eq 2484) { return 14 }
    if ($mhz -lt 3000) { return [int](($mhz - 2407) / 5) }
    if ($mhz -lt 5925) { return [int](($mhz - 5000) / 5) }
    return [int](($mhz - 5950) / 5)
}

# Receive ring: raised to the driver maximum but at most 2048 descriptors - about 25 ms of
# back-to-back frames at 1 Gbps, enough to ride out any burst. Never lowered.
function Set-RxRing ($n) {
    $p = $Cache[$n.Name]['*ReceiveBuffers']
    if (-not $p) { return }
    $nums = @()
    foreach ($s in @(ValidOf $p)) { [int64]$x = 0; if ([int64]::TryParse($s, [ref]$x)) { $nums += $x } }
    $step = 1
    if (($nums.Count -eq 0) -and ($p.NumericParameterMaxValue -gt 0)) {
        $nums = @([int64]$p.NumericParameterMinValue, [int64]$p.NumericParameterMaxValue)
        if ([int64]$p.NumericParameterStepValue -gt 1) { $step = [int64]$p.NumericParameterStepValue }
    }
    if ($nums.Count -eq 0) { return }
    [int64]$cur = 0
    [void][int64]::TryParse([string](@($p.RegistryValue)[0]), [ref]$cur)
    $cap = [int64]2048
    $max = [int64](($nums | Measure-Object -Maximum).Maximum)
    if (@(ValidOf $p).Count -gt 0) {
        $fit = @($nums | Where-Object { $_ -le $cap })
        if ($fit.Count -eq 0) { return }
        $target = [int64](($fit | Measure-Object -Maximum).Maximum)
    } else {
        $min = [int64](($nums | Measure-Object -Minimum).Minimum)
        $target = [math]::Min($max, $cap)
        $target = $target - (($target - $min) % $step)
    }
    if ($cur -ge $target) { Same ([string]$p.DisplayName + ' = ' + $cur); return }
    Set-Adv $n '*ReceiveBuffers' ([string]$target)
}

# Transmit ring above the driver default: Windows has no byte queue limit, so a long send ring
# is pure queueing delay whenever the NIC's own link is the bottleneck.
function Set-TxRingDefault ($n) {
    $p = $Cache[$n.Name]['*TransmitBuffers']
    if (-not $p) { return }
    [int64]$c = 0; [int64]$d = 0
    if (-not ([int64]::TryParse([string](@($p.RegistryValue)[0]), [ref]$c) -and [int64]::TryParse([string]$p.DefaultRegistryValue, [ref]$d))) { return }
    if ($c -gt $d) { Set-Adv $n '*TransmitBuffers' ([string]$d) }
}

# 100 Mbps hardware: named Fast Ethernet, a known 10/100 USB chip (Realtek RTL8152, ASIX
# AX88772 family), or a speed list that tops out at 100 Mbps.
# Driver-reported link speed is not trusted: some USB 2.0 adapters report 1 Gbps or more.
function IsFastEthernet ($n) {
    if ([string]$n.InterfaceDescription -match 'Fast Ethernet|10/100(?!0)') { return $true }
    if ([string]$n.PnPDeviceID -match 'VID_0BDA&PID_8152|VID_0B95&PID_(7720|772A|772B|7E2B)') { return $true }
    foreach ($kw in @('*SpeedDuplex', 'ConnectionType', 'SpeedDuplex')) {
        $p = $Cache[$n.Name][$kw]
        if ((-not $p) -or (-not $p.ValidDisplayValues)) { continue }
        $all = (@($p.ValidDisplayValues) -join '|')
        if (($all -match '100') -and ($all -notmatch '1000|Gbps|Gigabit|1\.0 ?G|2\.5 ?G|5 ?G|10 ?G')) { return $true }
    }
    return $false
}

# Registry DWORD write with SAME detection; the key is created when missing.
function Set-RegDword ([string]$key, [string]$name, [int64]$value, [string]$text) {
    $cur = Probe { (Get-ItemProperty -LiteralPath $key -Name $name -ErrorAction Stop).$name }
    if (($null -ne $cur) -and ([int64]$cur -eq $value)) { Same $text; return }
    Doing 'POLICY' ($name + ' = ' + $value)
    try {
        Change {
            if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force -ErrorAction Stop | Out-Null }
            New-ItemProperty -LiteralPath $key -Name $name -PropertyType DWord -Value $value -Force -ErrorAction Stop | Out-Null
        }
        Ok $text
    } catch { Failed ($name + ': ' + $_.Exception.Message) }
}

# Removes a value only when present; an absent value is already the wanted state.
function Remove-RegValue ([string]$key, [string]$name, [string]$text) {
    $cur = Probe { (Get-ItemProperty -LiteralPath $key -Name $name -ErrorAction Stop).$name }
    if ($null -eq $cur) { return }
    Doing 'POLICY' ('Removing ' + $name + ' = ' + $cur)
    try { Change { Remove-ItemProperty -LiteralPath $key -Name $name -ErrorAction Stop }; Ok $text }
    catch { Failed ('Removing ' + $name + ': ' + $_.Exception.Message) }
}

# The adapter's driver key under Control\Class, where INF defaults and overrides live.
function Get-NqDriverKey ($n) {
    $drv = Probe { [string](Get-ItemProperty -LiteralPath ('HKLM:\SYSTEM\CurrentControlSet\Enum\' + $n.PnPDeviceID) -Name Driver -ErrorAction Stop).Driver }
    if (-not $drv) { return $null }
    return ('HKLM:\SYSTEM\CurrentControlSet\Control\Class\' + $drv)
}

# RSS limits written straight into the driver key by tuning tools, with no matching entry in
# the driver's own parameter list, never show up in the adapter properties. A limit of one
# queue or one processor pins all receive work of that adapter to a single core.
function Repair-HiddenRss ($n) {
    $key = Get-NqDriverKey $n
    if (-not $key) { return }
    $v = Probe { Get-ItemProperty -LiteralPath $key -ErrorAction Stop }
    if (-not $v) { return }
    foreach ($kw in @('*NumRssQueues', '*MaxRssProcessors', '*RssBaseProcNumber', '*RssMaxProcNumber')) {
        $val = $v.$kw
        if ($null -eq $val) { continue }
        if (Test-Path -LiteralPath ($key + '\Ndi\Params\' + $kw)) { continue }
        if ((@('*NumRssQueues', '*MaxRssProcessors') -contains $kw) -and ([string]$val -eq '1')) {
            Doing 'RSS' ($n.Name + ': removing hidden ' + $kw + ' = 1')
            try {
                Change { Remove-ItemProperty -LiteralPath $key -Name $kw -ErrorAction Stop }
                $Restart[$n.Name] = $true
                Ok ($n.Name + ': hidden ' + $kw + ' = 1 removed - receive work can spread across cores again')
            } catch { Failed ($n.Name + ': removing hidden ' + $kw + ': ' + $_.Exception.Message) }
        } else {
            Info ($n.Name + ': hidden driver override ' + $kw + ' = ' + $val + ' set outside the adapter properties - left as found')
        }
    }
}

# UDP loss probe: DNS queries to a public resolver from two sockets, one left unmarked and one
# marked with a DSCP value through the qWAVE API, sent in alternating order. Game traffic is
# UDP and ping is ICMP, which routers often deprioritise, so this is the loss games actually
# see. Result: 0 plain sent, 1 plain lost, 2 marked sent, 3 marked lost, 4 error code,
# 5 plain RTT sum (ms), 6 marked RTT sum (ms).
function Invoke-NqUdpProbe ([string]$server, [int]$pairs, [int]$dscp) {
    if (-not ('NqUdpProbe' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Threading;
public static class NqUdpProbe {
    [StructLayout(LayoutKind.Sequential)] struct QOS_VERSION { public ushort Major; public ushort Minor; }
    [DllImport("qwave.dll", SetLastError = true)] static extern bool QOSCreateHandle(ref QOS_VERSION v, out IntPtr h);
    [DllImport("qwave.dll", SetLastError = true)] static extern bool QOSCloseHandle(IntPtr h);
    [DllImport("qwave.dll", SetLastError = true)] static extern bool QOSAddSocketToFlow(IntPtr h, IntPtr s, IntPtr dest, int trafficType, uint flags, ref uint flowId);
    [DllImport("qwave.dll", SetLastError = true)] static extern bool QOSSetFlow(IntPtr h, uint flowId, int op, uint size, ref uint value, uint flags, IntPtr ov);
    [DllImport("qwave.dll", SetLastError = true)] static extern bool QOSRemoveSocketFromFlow(IntPtr h, IntPtr s, uint flowId, uint flags);

    static byte[] Query(ushort id) {
        byte[] q = { 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0,
                     7, 101, 120, 97, 109, 112, 108, 101, 3, 99, 111, 109, 0, 0, 1, 0, 1 };
        q[0] = (byte)(id >> 8); q[1] = (byte)(id & 0xFF);
        return q;
    }

    // Sends one query and waits for the answer with the same ID. Returns the RTT in ms, or -1.
    static int Ask(Socket s, ushort id, int timeoutMs, byte[] buf) {
        Stopwatch clock = Stopwatch.StartNew();
        try { s.Send(Query(id)); } catch (SocketException) { return -1; }
        while (true) {
            long left = timeoutMs - clock.ElapsedMilliseconds;
            if (left <= 0) { return -1; }
            try {
                if (!s.Poll((int)(left * 1000), SelectMode.SelectRead)) { return -1; }
                int n = s.Receive(buf);
                if ((n >= 12) && (buf[0] == (byte)(id >> 8)) && (buf[1] == (byte)(id & 0xFF)) && ((buf[2] & 0x80) != 0)) {
                    return (int)clock.ElapsedMilliseconds;
                }
            } catch (SocketException) { return -1; }
        }
    }

    public static int[] Run(string server, int pairs, int dscp) {
        int[] r = new int[7];
        IPAddress ip = IPAddress.Parse(server);
        IPEndPoint ep = new IPEndPoint(ip, 53);
        Socket plain = new Socket(ip.AddressFamily, SocketType.Dgram, ProtocolType.Udp);
        Socket marked = new Socket(ip.AddressFamily, SocketType.Dgram, ProtocolType.Udp);
        IntPtr h = IntPtr.Zero;
        uint flow = 0;
        bool added = false;
        try {
            plain.Connect(ep);
            marked.Connect(ep);
            QOS_VERSION v = new QOS_VERSION(); v.Major = 1; v.Minor = 0;
            if (!QOSCreateHandle(ref v, out h)) { r[4] = Marshal.GetLastWin32Error(); if (r[4] == 0) { r[4] = -1; } return r; }
            if (!QOSAddSocketToFlow(h, marked.Handle, IntPtr.Zero, 0, 2, ref flow)) { r[4] = Marshal.GetLastWin32Error(); if (r[4] == 0) { r[4] = -1; } return r; }
            added = true;
            uint val = (uint)dscp;
            if (!QOSSetFlow(h, flow, 2, 4, ref val, 0, IntPtr.Zero)) { r[4] = Marshal.GetLastWin32Error(); if (r[4] == 0) { r[4] = -1; } return r; }
            byte[] buf = new byte[1500];
            ushort id = (ushort)(Environment.TickCount & 0x7FFF);
            Stopwatch total = Stopwatch.StartNew();
            for (int i = 0; i < pairs; i++) {
                if (total.ElapsedMilliseconds > 45000) { break; }
                for (int k = 0; k < 2; k++) {
                    bool useMarked = ((i + k) % 2) == 0;
                    id++;
                    int rtt = Ask(useMarked ? marked : plain, id, 800, buf);
                    if (useMarked) { r[2]++; if (rtt < 0) { r[3]++; } else { r[6] += rtt; } }
                    else { r[0]++; if (rtt < 0) { r[1]++; } else { r[5] += rtt; } }
                }
                if ((i == 9) && (r[1] == r[0]) && (r[3] == r[2])) { r[4] = -2; return r; }
                Thread.Sleep(40);
            }
        } finally {
            if (added) { QOSRemoveSocketFromFlow(h, IntPtr.Zero, flow, 0); }
            if (h != IntPtr.Zero) { QOSCloseHandle(h); }
            plain.Close();
            marked.Close();
        }
        return r;
    }
}
'@ -IgnoreWarnings -WarningAction SilentlyContinue
    }
    return [NqUdpProbe]::Run($server, $pairs, $dscp)
}

# "Allow the computer to turn off this device to save power" is bit 0x8 of PnPCapabilities
# (NDIS_DEVICE_DISABLE_PM) on the adapter's driver key; Set-NetAdapterPowerManagement cannot
# change it. Only that bit is set, so Wake-on-LAN choices are left exactly as they were.
function Set-NicPower ($n) {
    $pm = Probe { Get-NetAdapterPowerManagement -Name $n.Name -ErrorAction Stop }
    $state = ''
    if ($pm) { $state = [string]$pm.AllowComputerToTurnOffDevice }
    if ($state -eq 'Disabled') { Same ($n.Name + ': Allow the computer to turn off this device = off'); return }
    if ($state -ne 'Enabled') { Skip ($n.Name + ': device power management is not controllable (' + $state + ')'); return }
    try {
        $drv = [string](Get-ItemProperty -LiteralPath ('HKLM:\SYSTEM\CurrentControlSet\Enum\' + $n.PnPDeviceID) -Name Driver -ErrorAction Stop).Driver
        if (-not $drv) { throw 'the adapter has no driver key' }
        $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\' + $drv
        $cur = 0
        $raw = (Get-ItemProperty -LiteralPath $key -ErrorAction Stop).PnPCapabilities
        if ($null -ne $raw) { $cur = [int]$raw }
        $new = $cur -bor 8
        Doing 'POWER' ($n.Name + ': clearing Allow the computer to turn off this device (PnPCapabilities ' + $cur + ' -> ' + $new + ')')
        Change { New-ItemProperty -LiteralPath $key -Name PnPCapabilities -PropertyType DWord -Value $new -Force -ErrorAction Stop | Out-Null }
        $Restart[$n.Name] = $true
        Ok ($n.Name + ': no idle power-down - no wake-up delay or lost first packets after a quiet moment')
    } catch { Failed ($n.Name + ': device power management: ' + $_.Exception.Message) }
}

# ------------------------------------------------------------------------------------------
Head 'Link health check  (physical-layer and path faults that no software tweak can mask)'
# ------------------------------------------------------------------------------------------
$healthFailCount = $script:NQ_Failed
$healthWarnCount = $script:NQ_Warned
$flags = 0; $wifiUp = $false; $ethUp = $false
$since7 = (Get-Date).AddDays(-7)
$script:NqPowerTimes = @(@(Probe { Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-Power'; Id = 42, 107, 506, 507; StartTime = $since7 } -ErrorAction Stop }) +
                         @(Probe { Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-General'; Id = 12, 13; StartTime = $since7 } -ErrorAction Stop }) |
                         Where-Object { $_ } | ForEach-Object { $_.TimeCreated })
$wlan = @{}
if (@($Nics | Where-Object { IsWifi $_ }).Count -gt 0) {
    $wlan = Probe { Get-NqWlanInfo }
    if (-not $wlan) { $wlan = @{} }
}
foreach ($n in $Nics) {
    $wifi = IsWifi $n
    $chip = Get-NqChip $n
    $vd = $chip.Ven + ':' + $chip.Dev
    if (-not $wifi) {
        # Checked even while unplugged, so a slow spare dongle is caught before it is used.
        if (IsUsb $n) {
            Warn ($n.Name + ': USB network adapter - every packet crosses the USB bus in scheduled bulk transfers, adding latency and jitter an onboard or PCIe port does not have')
            $flags++
        }
        # Intel I225 v1 (PCI revision 01): an inter-packet gap below the IEEE minimum makes
        # link partners drop frames at 2.5 Gbps. Killer E3100 is the same silicon.
        if (($vd -match '^8086:(15F3|15F2|0D9F|5502|3100)$') -and ($chip.Rev -eq '01')) {
            $msg = $n.Name + ': Intel I225 first revision (v1) - it drops frames at 2.5 Gbps because of a documented inter-packet-gap erratum'
            if ($n.Speed -ge 2000000000) { $msg += '. The link runs at 2.5 Gbps right now; Intel''s workaround, a 1 Gbps link, is applied below when NQ_I225_1G = 1' }
            else { $msg += '. The link is below 2.5 Gbps, which avoids it' }
            Warn $msg
            $flags++
            if ($n.Speed -ge 2000000000) { $script:NqWifi['I225:' + $n.Name] = $true }
        }
        # Intel I226: Energy-Efficient Ethernet caused random disconnects until driver 2.1.3.15
        # (Windows 11) / 1.1.4.42 (Windows 10) together with board firmware NVM 2.22.
        if (($vd -match '^8086:(125C|125B|125D|5503)$') -and $chip.Ver) {
            $okVer = (($chip.Ver.Major -eq 2) -and ($chip.Ver -ge [version]'2.1.3.15')) -or (($chip.Ver.Major -eq 1) -and ($chip.Ver -ge [version]'1.1.4.42')) -or ($chip.Ver.Major -gt 2)
            if (-not $okVer) {
                Warn ($n.Name + ': Intel I226 driver ' + $chip.Ver + ' predates Intel''s disconnect fix - install 2.1.3.15 or newer (Windows 11) / 1.1.4.42 (Windows 10) and the board maker''s latest LAN firmware. EEE is turned off below either way')
                $flags++
            }
        }
        if (IsFastEthernet $n) {
            Warn ($n.Name + ': 100 Mbps Fast Ethernet hardware - downloads faster than 100 Mbps queue at the router port feeding this PC, which shows up as ping spikes and loss while anything downloads. A gigabit port or USB 3 gigabit adapter removes this bottleneck')
            $flags++
        }
        # Driver errors and warnings in the last 7 days (transmit hangs, hardware resets), by
        # provider only. Entries within 3 minutes of sleep, resume or boot are not counted.
        $drvErr = 0
        if ($chip.Svc) {
            $ev = @(Probe { Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = $chip.Svc; StartTime = $since7 } -ErrorAction Stop } | Where-Object { $_ -and ($_.TimeCreated -lt $script:NqRunStart) -and (-not (Test-NearPower $_.TimeCreated)) })
            $drvErr = @($ev | Where-Object { ($_.Level -ge 1) -and ($_.Level -le 3) -and (@(1, 27, 32, 33) -notcontains $_.Id) }).Count
        }
        if ($drvErr -ge 3) {
            Warn ($n.Name + ': the network driver logged ' + $drvErr + ' errors or warnings in 7 days (transmit hangs, hardware resets) - install the chip maker''s current driver')
            $flags++
        }
    }
    try {
        $dd = [datetime]::ParseExact([string]$n.DriverDate, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
        if ($dd -lt (Get-Date).AddYears(-4)) {
            Warn ($n.Name + ': driver dated ' + $n.DriverDate + ' - chip makers have fixed latency spikes and packet loss in newer releases; check Intel, Realtek, MediaTek or Qualcomm for a current driver')
            $flags++
        }
    } catch { }
    if ($n.Status -ne 'Up') { continue }
    if ($wifi) {
        $wifiUp = $true
        $wi = $wlan[([string]$n.InterfaceGuid).ToUpperInvariant()]
        $on24 = $false
        if ($wi) {
            $script:NqWifi[$n.Name] = $wi
            $band = Get-NqBand $wi.MHz
            $ch = Get-NqChannel $wi.MHz
            $on24 = ($band -eq '2.4')
            $desc = 'Wi-Fi link: '
            if ($band) { $desc += $band + ' GHz channel ' + $ch }
            if ($null -ne $wi.Rssi) { $desc += ', signal ' + $wi.Rssi + ' dBm' }
            if ($wi.TxK -gt 0) { $desc += ', transmit rate ' + [math]::Round($wi.TxK / 1000) + ' Mbit/s' }
            Info ($n.Name + ': ' + $desc)
            if (($null -ne $wi.Rssi) -and ($wi.Rssi -lt -75)) {
                Warn ($n.Name + ': signal ' + $wi.Rssi + ' dBm is very weak - frames are retried and dropped constantly. Move closer, remove obstacles, or add a wired access point or mesh node near the PC')
                $flags++
            } elseif (($null -ne $wi.Rssi) -and ($wi.Rssi -lt -67)) {
                Warn ($n.Name + ': signal ' + $wi.Rssi + ' dBm is below the -67 dBm that real-time traffic needs - expect retries, jitter and loss')
                $flags++
            }
            if (($wi.TxK -gt 0) -and ((($band -eq '2.4') -and ($wi.TxK -lt 58000)) -or ((($band -eq '5') -or ($band -eq '6')) -and ($wi.TxK -lt 72000)))) {
                Warn ($n.Name + ': the radio is transmitting at only ' + [math]::Round($wi.TxK / 1000) + ' Mbit/s - the lowest, most error-prone rates, a sign of weak signal or interference')
                $flags++
            }
            if (($wi.Phy -ge 1) -and ($wi.Phy -le 7)) {
                Warn ($n.Name + ': connected with an 802.11n or older link - no OFDMA scheduling, and latency under load is far worse than 802.11ac or ax. Check the router''s wireless mode')
                $flags++
            }
            if (($band -eq '5') -and ($ch -ge 52) -and ($ch -le 144)) {
                Info ($n.Name + ': channel ' + $ch + ' is a DFS channel - when the router detects radar it must leave the channel, which drops every client for up to a minute. Channels 36-48 or 149-165 avoid that')
            }
            if (-not $wi.Loc) {
                Info ($n.Name + ': Windows location permission hides the network list from desktop apps, so channel congestion could not be checked')
            } elseif ($wi.MHz -gt 0) {
                $others = @($wi.Bss | Where-Object { $_.Bssid -ne $wi.Bssid })
                $co = @($others | Where-Object { ($_.MHz -eq $wi.MHz) -and ($_.Rssi -ge -82) }).Count
                if ($co -ge 3) {
                    Warn ($n.Name + ': ' + $co + ' other networks share channel ' + $ch + ' within hearing range - every one of them takes turns with your router for airtime. Move the router to a quieter channel')
                    $flags++
                }
                if ($on24) {
                    $adj = @($others | Where-Object { ([math]::Abs($_.MHz - $wi.MHz) -ge 5) -and ([math]::Abs($_.MHz - $wi.MHz) -le 20) -and ($_.Rssi -ge -75) }).Count
                    if ($adj -ge 2) {
                        Warn ($n.Name + ': ' + $adj + ' strong networks sit on overlapping 2.4 GHz channels - their frames corrupt yours instead of waiting their turn. Only channels 1, 6 and 11 do not overlap')
                        $flags++
                    }
                    $five = @($others | Where-Object { ($_.Ssid -eq $wi.Ssid) -and ((Get-NqBand $_.MHz) -ne '2.4') } | Sort-Object Rssi -Descending | Select-Object -First 1)
                    if ($five.Count -gt 0) {
                        if ($five[0].Rssi -ge -70) {
                            Warn ($n.Name + ': your router''s 5 GHz network is in range at ' + $five[0].Rssi + ' dBm while this PC sits on 2.4 GHz - the preferred band is set to 5 GHz below')
                            $flags++
                        } else { Info ($n.Name + ': the router''s 5 GHz network only reaches ' + $five[0].Rssi + ' dBm here - 2.4 GHz is the steadier choice at this distance') }
                    }
                }
                $mine = @($wi.Bss | Where-Object { $_.Bssid -eq $wi.Bssid }) | Select-Object -First 1
                if ($mine -and ($mine.Util -ge 50)) {
                    Warn ($n.Name + ': your router reports its channel ' + $mine.Util + ' percent busy - airtime is the bottleneck, so frames wait and are dropped. A quieter channel or a 5/6 GHz link helps')
                    $flags++
                }
            }
        } else {
            # Fallback when the Wi-Fi API is unavailable: English netsh labels only.
            $w     = @(Probe { $result = @(& ($env:NQ_BIN + '\netsh.exe') wlan show interfaces); if ($LASTEXITCODE -ne 0) { throw ('NETSH returned exit code ' + $LASTEXITCODE) }; $result })
            $sig   = $w | Select-String -Pattern '^\s*Signal\s*:\s*(\d+)\s*%' | Select-Object -First 1
            $bandL = $w | Select-String -Pattern '^\s*Band\s*:\s*(.+?)\s*$'   | Select-Object -First 1
            if ($sig -and ([int]$sig.Matches[0].Groups[1].Value -lt 60)) {
                Warn ($n.Name + ': signal ' + $sig.Matches[0].Groups[1].Value + ' percent - weak links retransmit constantly, which shows up as jitter and loss')
                $flags++
            }
            if ($bandL) { $on24 = ($bandL.Matches[0].Groups[1].Value -match '2\.4') }
        }
        if ($on24) {
            Warn ($n.Name + ': connected on 2.4 GHz - the most congested band; use 5 or 6 GHz if the router offers it')
            $flags++
            # Bluetooth shares 2.4 GHz, and combo cards share one antenna between the two radios.
            $bt = @(Probe { Get-PnpDevice -Class Bluetooth -PresentOnly -Status OK -ErrorAction Stop })
            if ($bt.Count -gt 0) {
                Info ($n.Name + ': a Bluetooth radio is active - Bluetooth headsets and controllers share the 2.4 GHz band, and combo cards share one antenna, so the Wi-Fi link gets less airtime. On 5 or 6 GHz the two no longer collide')
            }
        }
        $script:NqWifi['On24:' + $n.Name] = $on24
    } else {
        $ethUp = $true
        if (($n.Speed -gt 0) -and ($n.Speed -lt 1000000000) -and (-not (IsFastEthernet $n))) {
            Warn ($n.Name + ': link negotiated at ' + $n.LinkSpeed + ' - on gigabit hardware this means a damaged cable, connector or port')
            $flags++
        }
        if ($n.FullDuplex -eq $false) {
            Warn ($n.Name + ': HALF duplex link - collisions and heavy packet loss; set Speed & Duplex to Auto on both ends')
            $flags++
        }
        # Only 10/100 and 1 Gbps half-duplex settings disable auto-negotiation; 1 Gbps full and
        # faster settings still negotiate and only limit the advertised speed.
        $sd = $Cache[$n.Name]['*SpeedDuplex']
        if ($sd) {
            $sdv = 0
            [void][int]::TryParse([string](@($sd.RegistryValue)[0]), [ref]$sdv)
            if (($sdv -ge 1) -and ($sdv -le 5)) {
                Warn ($n.Name + ': Speed & Duplex forced to "' + $sd.DisplayValue + '" - a forced end facing an auto-negotiating one ends in a duplex mismatch and heavy loss; use Auto')
                $flags++
            } elseif (($sdv -gt 5) -and (-not $script:NqWifi.ContainsKey('I225:' + $n.Name))) {
                Info ($n.Name + ': Speed & Duplex limited to "' + $sd.DisplayValue + '" - still auto-negotiated, so no mismatch risk')
            }
        }
    }
    # Frame errors are counted by the NIC itself: CRC and alignment errors are physical faults.
    $st = Probe { Get-NetAdapterStatistics -Name $n.Name -ErrorAction Stop }
    if ($st) {
        $pk = [double]$st.ReceivedUnicastPackets + [double]$st.ReceivedMulticastPackets + [double]$st.ReceivedBroadcastPackets +
              [double]$st.SentUnicastPackets + [double]$st.SentMulticastPackets + [double]$st.SentBroadcastPackets
        $er = [double]$st.ReceivedPacketErrors + [double]$st.OutboundPacketErrors
        if (($er -ge 20) -and ($pk -gt 0) -and (($er / $pk) -gt 0.0001)) {
            Warn ($n.Name + ': ' + [string]$er + ' frame errors in ' + [string]$pk + ' packets since the adapter started - a damaged cable, connector or port, or heavy interference on Wi-Fi')
            $flags++
        }
        # Discards are frames the NIC received intact but threw away, most often because the
        # receive ring was full during a burst. The ring is enlarged in the driver stage below.
        $rxPk = [double]$st.ReceivedUnicastPackets + [double]$st.ReceivedMulticastPackets + [double]$st.ReceivedBroadcastPackets
        $dis  = [double]$st.ReceivedDiscardedPackets
        if (($dis -ge 500) -and ($rxPk -gt 0) -and (($dis / $rxPk) -gt 0.005)) {
            Warn ($n.Name + ': ' + [string]$dis + ' received packets discarded in ' + [string]$rxPk + ' - the receive ring overflowed during bursts, or the driver drops frames it cannot use. The receive buffers are raised to the driver maximum below')
            $flags++
        }
    }
}
# Mobile Hotspot, wireless display (Miracast) and Wi-Fi Direct printers run on a hidden Wi-Fi
# Direct adapter. While one is connected, the Wi-Fi radio alternates between two channels.
if ($wifiUp) {
    $wfd = @(Probe { Get-NetAdapter -IncludeHidden -ErrorAction Stop } | Where-Object { ([string]$_.InterfaceDescription -match 'Wi-Fi Direct') -and ($_.Status -eq 'Up') })
    if ($wfd.Count -gt 0) {
        Warn ('A Wi-Fi Direct link is active (' + (@($wfd | ForEach-Object { $_.Name }) -join ', ') + ') - Mobile Hotspot, wireless display or a Wi-Fi Direct device makes the Wi-Fi radio split its airtime between two channels. Turn it off while playing')
        $flags++
    }
}
if ($wifiUp -and -not $ethUp) {
    Warn 'Gaming over Wi-Fi: airtime contention, retransmissions and periodic background scans are the #1 jitter/loss source. Ethernet or MoCA beats every tweak.'
    $flags++
}

# Which interface actually carries internet traffic right now.
$route = Probe {
    Get-NetRoute -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop | ForEach-Object {
        $ifm = [int](Get-NetIPInterface -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction Stop).InterfaceMetric
        [pscustomobject]@{ Index = $_.ifIndex; Metric = ([int]$_.RouteMetric + $ifm); NextHop = [string]$_.NextHop }
    } | Sort-Object Metric | Select-Object -First 1
}
if ($route) {
    $via = Probe { Get-NetAdapter -InterfaceIndex $route.Index -ErrorAction Stop }
    if ($via) {
        $physical = (@($Nics | Where-Object { $_.ifIndex -eq $via.ifIndex }).Count -gt 0)
        if (-not $physical) {
            Warn ('Internet traffic leaves through "' + $via.Name + '" (' + $via.InterfaceDescription + '). A VPN or virtual adapter adds its own hop, encryption and queue to every game packet - disconnect it while playing unless you have measured that it lowers your ping')
            $flags++
        } elseif ((IsWifi $via) -and $ethUp) {
            $script:NqViaWifi = $true
            Warn 'An Ethernet link is up but Windows routes internet traffic over Wi-Fi (lower interface metric). Reconnect the cable, or give Wi-Fi a higher interface metric than Ethernet'
            $flags++
        } else {
            if (IsWifi $via) { $script:NqViaWifi = $true }
            Info ('Internet traffic leaves through ' + $via.Name)
        }
    }
}

# ------------------------------------------------------------------------------------------
Head 'Background traffic right now  (it distorts every latency test)'
# ------------------------------------------------------------------------------------------
# Bytes through the internet adapter over 3 seconds. Per-CPU interrupt and DPC load is
# measured by the diagnostics below, idle and under load.
$script:NqBusyLine = $false
$viaNic = $null
if ($via) { $viaNic = @($Nics | Where-Object { $_.ifIndex -eq $via.ifIndex }) | Select-Object -First 1 }
$st0 = $null
if ($viaNic) { $st0 = Probe { Get-NetAdapterStatistics -Name $viaNic.Name -ErrorAction Stop } }
$clock = [Diagnostics.Stopwatch]::StartNew()
Start-Sleep -Seconds 3
$secs = $clock.Elapsed.TotalSeconds
$st1 = $null
if ($viaNic) { $st1 = Probe { Get-NetAdapterStatistics -Name $viaNic.Name -ErrorAction Stop } }
if ($st0 -and $st1 -and ($secs -gt 0)) {
    $down = 8.0 * ([double]$st1.ReceivedBytes - [double]$st0.ReceivedBytes) / $secs / 1000000
    $up   = 8.0 * ([double]$st1.SentBytes - [double]$st0.SentBytes) / $secs / 1000000
    Info ('Traffic on ' + $viaNic.Name + ' right now: ' + [math]::Round($down, 2) + ' Mbit/s down, ' + [math]::Round($up, 2) + ' Mbit/s up')
    if (($down -gt 2) -or ($up -gt 0.5)) {
        $script:NqBusyLine = $true
        Warn 'Something is transferring data while the script runs, so the tests below measure your line with that queue in it. Pause downloads, cloud sync and streams, then run again for clean numbers'
        $flags++
    }
}
$doAct = @(Probe { Get-DeliveryOptimizationStatus -ErrorAction Stop } | Where-Object { [string]$_.Status -eq 'Downloading' })
if ($doAct.Count -gt 0) { Info ('Windows Update or Store is downloading ' + $doAct.Count + ' file(s) - capped by the Delivery Optimization policy below') }
$bitsAct = @(Probe { Get-BitsTransfer -AllUsers -ErrorAction Stop } | Where-Object { [string]$_.JobState -eq 'Transferring' })
if ($bitsAct.Count -gt 0) { Info ('Background Intelligent Transfer Service jobs transferring: ' + $bitsAct.Count) }

# ------------------------------------------------------------------------------------------
Head 'Where packets are lost  (path test, hop by hop, path MTU, loaded latency)'
# ------------------------------------------------------------------------------------------
# About 350 internet probes over three targets, the router at 10 per second and the first
# hops past it, all at once: enough to tell a 0-1 percent line from a 3 percent one, and to
# see where loss starts. Every figure is printed as "lost of sent" with its 95 percent range.
# Then the path MTU, and latency while the line is full in each direction (bufferbloat).
# Read only, so it also runs in a dry run.
$diag = $null
$net = $null
if ((Flag 'NQ_PATH_TEST') -and $route) {
    $ptList = @()
    foreach ($t in @(([string]$env:NQ_PING_TARGETS) -split '[;, ]+')) {
        $ipT = $null
        if ($t -and [Net.IPAddress]::TryParse($t, [ref]$ipT) -and ($ipT.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork)) { $ptList += $t }
    }
    if ($ptList.Count -eq 0) { $ptList = @('1.1.1.1', '8.8.8.8', '9.9.9.9') }
    $trT = ([string]$env:NQ_TRACE_TARGET).Trim()
    $ipT = $null
    if ($trT -and (-not ([Net.IPAddress]::TryParse($trT, [ref]$ipT)))) { $trT = '' }
    $secs = [int](Num 'NQ_DIAG_SECONDS' 30)
    if ($secs -lt 15) { $secs = 15 }
    if ($secs -gt 120) { $secs = 120 }
    $gList = @(([string]$env:NQ_GAMES) -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    Info ('Measuring for about ' + ($secs + 30) + ' seconds - leave the network alone meanwhile')
    try { $diag = Invoke-NqDiagnostics -Targets $ptList -TraceTarget $trT -Seconds $secs -LoadTest (Flag 'NQ_LOAD_TEST') -GameExes $gList }
    catch { Info ('Diagnostics stopped early: ' + $_.Exception.Message) }
    if ($diag -and $diag.Path) { $net = $diag.Path.Internet }
    if ($script:NqBusyLine) { Info 'Background traffic was flowing during these tests (see above), so loss and latency figures include its queue' }
}

# UDP loss test: what game packets see, and whether this connection drops DSCP-marked ones.
# Some access networks police or black-hole marked packets; measurements find it on a few
# percent of home lines. Read only - the marking lives on this test's own socket.
if ((Flag 'NQ_UDP_TEST') -and $route) {
    $ut = ([string]$env:NQ_UDP_TARGET).Trim()
    $tv = [int](Num 'NQ_DSCP_VALUE' 46)
    $ipOk = $null
    if ($ut -and (-not [Net.IPAddress]::TryParse($ut, [ref]$ipOk))) { $ut = '' }
    if (-not $ut) { Skip 'UDP loss test: NQ_UDP_TARGET must be an IP address' }
    else {
        $u1 = $null; $uErr = ''
        try { $u1 = Invoke-NqUdpProbe $ut 100 $tv } catch { $uErr = $_.Exception.Message }
        if (-not $u1) { Info ('UDP loss test could not run: ' + $uErr) }
        elseif ($u1[4] -eq -2) { Info ('UDP loss test: ' + $ut + ' answered no DNS queries - port 53 may be blocked or redirected on this network') }
        elseif ($u1[4] -ne 0) { Info ('UDP loss test: Windows refused DSCP marking on the test socket (error ' + $u1[4] + ') - only the unmarked half could run, so it was skipped') }
        else {
            $pl = [int]$u1[1]; $ml = [int]$u1[3]; $ps = [int]$u1[0]; $ms = [int]$u1[2]
            # A suspicious first round is repeated before anything is concluded.
            if (($ml -ge 3) -and ($ml -ge 3 * ($pl + 1))) {
                $u2 = $null
                try { $u2 = Invoke-NqUdpProbe $ut 100 $tv } catch { }
                if ($u2 -and ($u2[4] -eq 0)) {
                    $pl += [int]$u2[1]; $ml += [int]$u2[3]; $ps += [int]$u2[0]; $ms += [int]$u2[2]
                    $u1[5] += $u2[5]; $u1[6] += $u2[6]
                }
            }
            $pPct = 0.0; $mPct = 0.0
            if ($ps -gt 0) { $pPct = [math]::Round(100.0 * $pl / $ps, 1) }
            if ($ms -gt 0) { $mPct = [math]::Round(100.0 * $ml / $ms, 1) }
            $pAvg = 0; $mAvg = 0
            if (($ps - $pl) -gt 0) { $pAvg = [math]::Round($u1[5] / ($ps - $pl)) }
            if (($ms - $ml) -gt 0) { $mAvg = [math]::Round($u1[6] / ($ms - $ml)) }
            Info ('UDP loss test to ' + $ut + ': unmarked ' + $pPct + ' percent lost (' + $pAvg + ' ms), DSCP ' + $tv + ' ' + $mPct + ' percent lost (' + $mAvg + ' ms)')
            if (($ms -ge 200) -and ($ml -ge 6) -and ($ml -ge 3 * ($pl + 1))) {
                $script:NqEfDropped = $true
                Warn ('This connection drops DSCP ' + $tv + ' packets: ' + $mPct + ' percent loss marked against ' + $pPct + ' percent unmarked. Game marking is withdrawn below (NQ_DSCP_AUTO)')
                $flags++
            } elseif ($pPct -ge 3) {
                Warn ('Real UDP loss of ' + $pPct + ' percent to the internet - the same loss your games see. The path test above shows whether it starts at the router (Wi-Fi or cable) or beyond it (modem or ISP)')
                $flags++
            } elseif ($net -and ($net.LossPct -gt 3) -and ($pPct -le 1)) {
                Info 'Ping loss without UDP loss: the path deprioritises ICMP. Game packets are arriving - ignore ping loss figures on this line'
            }
        }
    }
}

# Windows' own loss counters since boot, read through the language-independent WMI classes.
$tcp4 = Probe { @(Get-CimInstance -ClassName Win32_PerfRawData_Tcpip_TCPv4 -ErrorAction Stop)[0] }
$tcp6 = Probe { @(Get-CimInstance -ClassName Win32_PerfRawData_Tcpip_TCPv6 -ErrorAction Stop)[0] }
$sentSeg = 0.0; $retrSeg = 0.0
foreach ($c in @($tcp4, $tcp6)) { if ($c) { $sentSeg += [double]$c.SegmentsSentPersec; $retrSeg += [double]$c.SegmentsRetransmittedPersec } }
if ($sentSeg -ge 20000) {
    $rp = [math]::Round(100 * $retrSeg / $sentSeg, 2)
    if ($rp -gt 2) {
        Warn ('TCP retransmitted ' + $rp + ' percent of its segments since boot - packets are being lost somewhere on the path; the path test above shows where')
        $flags++
    } else { Info ('TCP retransmissions since boot: ' + $rp + ' percent of segments sent') }
}
$udp4 = Probe { @(Get-CimInstance -ClassName Win32_PerfRawData_Tcpip_UDPv4 -ErrorAction Stop)[0] }
$udp6 = Probe { @(Get-CimInstance -ClassName Win32_PerfRawData_Tcpip_UDPv6 -ErrorAction Stop)[0] }
$udpIn = 0.0; $udpErr = 0.0
foreach ($c in @($udp4, $udp6)) { if ($c) { $udpIn += [double]$c.DatagramsReceivedPersec; $udpErr += [double]$c.DatagramsReceivedErrors } }
if (($udpErr -ge 100) -and (($udpIn + $udpErr) -gt 0) -and (($udpErr / ($udpIn + $udpErr)) -gt 0.001)) {
    Warn ('Windows dropped ' + [string]$udpErr + ' incoming UDP datagrams before any application read them - usually a busy program''s socket buffer overflowing, or filtering by security software. Game traffic is UDP, so these are lost game packets')
    $flags++
}

# Filter drivers and virtual switches that sit in the packet path of each physical adapter.
foreach ($n in $Nics) {
    foreach ($b in @(Probe { Get-NetAdapterBinding -Name $n.Name -ErrorAction Stop } | Where-Object { $_.Enabled })) {
        if ([string]$b.ComponentID -eq 'vms_pp') {
            Warn ($n.Name + ': a Hyper-V external virtual switch is bound to this adapter - game traffic crosses the virtual switch first. Use an internal or NAT switch for VMs if you do not need bridging')
            $flags++
        } elseif ([string]$b.ComponentID -notmatch '^(ms_|vms_)') {
            Info ($n.Name + ': third-party network component in the packet path - ' + $b.DisplayName + ' [' + $b.ComponentID + ']. Unbind it in the adapter properties if you do not need it while gaming')
        }
    }
}

# ------------------------------------------------------------------------------------------
Head 'Software in the packet path  (shapers, filters and security suites)'
# ------------------------------------------------------------------------------------------
# Kernel drivers that inspect or queue every packet. Traffic shapers add their own queue and
# per-packet CPU work; none of them can make a packet arrive sooner than the line allows.
$drvHits = [ordered]@{
    'cfosspeed' = @('W', 'cFosSpeed traffic shaper (also sold as MSI Gaming LAN Manager, ASUS Turbo LAN and ASRock XFast LAN)')
    'nldrv'     = @('W', 'NetLimiter traffic shaper')
    'gwdrv'     = @('W', 'GlassWire network monitor')
    'kfeco'     = @('W', 'Killer traffic-control callout')
    'windivert' = @('W', 'WinDivert packet diverter (used by some game "boosters" and DPI tools)')
    'npcap'     = @('I', 'Npcap capture driver (Wireshark) - idle unless a capture runs; uninstall it if unused')
}
$running = @(Probe { Get-CimInstance -ClassName Win32_SystemDriver -Filter "State='Running'" -ErrorAction Stop })
$seen = @{}
foreach ($d in $running) {
    $leaf = ((([string]$d.PathName) -replace '^.*[\\/]', '') -replace '(?i)\.sys$', '').ToLowerInvariant()
    $dn = ([string]$d.Name).ToLowerInvariant()
    foreach ($k in $drvHits.Keys) {
        if ($seen.ContainsKey($k)) { continue }
        if (-not ($leaf.StartsWith($k) -or $dn.StartsWith($k))) { continue }
        $seen[$k] = $true
        if ($drvHits[$k][0] -eq 'W') {
            Warn ($drvHits[$k][1] + ' is running as a kernel driver - every packet passes through its queue and inspection. Uninstall it, or turn its shaping off, for gaming')
            $flags++
        } else { Info $drvHits[$k][1] }
    }
}
# Security suites with a web or network shield inspect game connections as well.
$sec = @(Probe { Get-CimInstance -Namespace 'root\SecurityCenter2' -ClassName AntiVirusProduct -ErrorAction Stop }) +
       @(Probe { Get-CimInstance -Namespace 'root\SecurityCenter2' -ClassName FirewallProduct -ErrorAction Stop })
$secNames = @($sec | ForEach-Object { [string]$_.displayName } | Where-Object { $_ -and ($_ -notmatch '(?i)defender') } | Select-Object -Unique)
if ($secNames.Count -gt 0) {
    Info ('Third-party security software: ' + ($secNames -join ', ') + ' - its network shield inspects game traffic. If spikes remain, exclude the game from it or test once with the shield off')
}
$mp = Probe { Get-MpPreference -ErrorAction Stop }
if ($mp -and ([int]$mp.EnableNetworkProtection -ne 0) -and (-not $mp.DisableDatagramProcessing)) {
    Info 'Microsoft Defender Network Protection is on and also inspects UDP datagrams, which Microsoft notes can affect network performance'
}
# Other non-Microsoft drivers that register Windows Filtering Platform callouts (VPNs, firewalls,
# security suites): found by the fwpkclnt.sys import in the driver image. Reported only.
$callouts = @()
foreach ($d in $running) {
    $pth = [string]$d.PathName
    if (-not $pth) { continue }
    $pth = $pth -replace '^\\\?\?\\', ''
    $pth = $pth -replace '(?i)^\\SystemRoot\\', ($env:SystemRoot + '\')
    $pth = $pth -replace '(?i)^system32\\', ($env:SystemRoot + '\System32\')
    if (-not (Test-Path -LiteralPath $pth -PathType Leaf)) { continue }
    $fi = Probe { Get-Item -LiteralPath $pth -ErrorAction Stop }
    if ((-not $fi) -or ($fi.Length -gt 30MB)) { continue }
    if ([string]$fi.VersionInfo.CompanyName -match '(?i)microsoft') { continue }
    $leaf = ([string]$fi.Name -replace '(?i)\.sys$', '').ToLowerInvariant()
    if (@($drvHits.Keys | Where-Object { $leaf.StartsWith($_) }).Count -gt 0) { continue }
    $raw = Probe { [IO.File]::ReadAllBytes($pth) }
    if (-not $raw) { continue }
    if ([Text.Encoding]::ASCII.GetString($raw).IndexOf('fwpkclnt.sys', [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $label = [string]$d.DisplayName
        if (-not $label) { $label = [string]$d.Name }
        $callouts += $label
    }
}
if ($callouts.Count -gt 0) {
    Info ('Third-party packet-filter drivers loaded: ' + ((@($callouts) | Select-Object -Unique) -join ', ') + ' - usually a VPN, firewall or security suite. Harmless when idle; uninstall any you no longer use')
}

# Interrupt delivery. Line-based interrupts (MSI forced off) and a single MSI vector both force
# every receive interrupt of the adapter onto one core; affinity pins are reported, not undone.
foreach ($n in $Nics) {
    $im = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $n.PnPDeviceID + '\Device Parameters\Interrupt Management'
    $msiP = Probe { Get-ItemProperty -LiteralPath ($im + '\MessageSignaledInterruptProperties') -ErrorAction Stop }
    if ($msiP -and ($null -ne $msiP.MSISupported) -and ([int]$msiP.MSISupported -eq 0)) {
        Warn ($n.Name + ': message-signalled interrupts are switched off for this adapter - line-based interrupts cost more CPU per packet and can be shared with other devices. Remove the MSISupported = 0 override (MSI mode tools) or reinstall the driver')
        $flags++
    } elseif ($msiP -and ($null -ne $msiP.MessageNumberLimit) -and ([int]$msiP.MessageNumberLimit -le 1) -and $Cache[$n.Name]['*RSS']) {
        Warn ($n.Name + ': the adapter is limited to one interrupt vector (MessageNumberLimit = 1), so Receive Side Scaling cannot spread receive work over cores')
        $flags++
    }
    $aff = Probe { Get-ItemProperty -LiteralPath ($im + '\Affinity Policy') -ErrorAction Stop }
    if ($aff -and ($null -ne $aff.DevicePolicy) -and ([int]$aff.DevicePolicy -ne 0)) {
        Info ($n.Name + ': interrupt affinity is pinned by a tuning tool (DevicePolicy ' + $aff.DevicePolicy + '). Keep it away from the cores your game uses most, never on CPU 0 alone')
    }
}

# Upload hogs running right now: a saturated upload is the most common home lag-spike cause.
$procs = @(Probe { Get-Process -ErrorAction Stop } | ForEach-Object { ([string]$_.ProcessName).ToLowerInvariant() } | Select-Object -Unique)
$torrent = @{ 'qbittorrent' = 'qBittorrent'; 'utorrent' = 'uTorrent'; 'bittorrent' = 'BitTorrent'; 'transmission-qt' = 'Transmission'; 'deluge' = 'Deluge'; 'tixati' = 'Tixati'; 'biglybt' = 'BiglyBT' }
$uploads = @{ 'onedrive' = 'OneDrive'; 'dropbox' = 'Dropbox'; 'googledrivefs' = 'Google Drive'; 'obs64' = 'OBS' }
$t1 = @($torrent.Keys | Where-Object { $procs -contains $_ } | ForEach-Object { $torrent[$_] })
if ($t1.Count -gt 0) {
    Warn ('Torrent client running: ' + ($t1 -join ', ') + ' - seeding keeps the upload saturated. Quit it or cap its upload while playing')
    $flags++
}
$t2 = @($uploads.Keys | Where-Object { $procs -contains $_ } | ForEach-Object { $uploads[$_] })
if ($t2.Count -gt 0) {
    Info ('Running now and able to saturate the upload: ' + ($t2 -join ', ') + ' - keep stream bitrate and sync uploads under about 70 percent of your upload speed')
}
$launch = @{ 'steam' = 'Steam'; 'epicgameslauncher' = 'Epic Games'; 'battle.net' = 'Battle.net'; 'eadesktop' = 'EA app'; 'upc' = 'Ubisoft Connect'; 'riotclientservices' = 'Riot Client'; 'xboxpcapp' = 'Xbox app' }
$t3 = @($launch.Keys | Where-Object { $procs -contains $_ } | ForEach-Object { $launch[$_] })
if ($t3.Count -gt 0) {
    Info ('Game launchers running: ' + ($t3 -join ', ') + ' - each can download updates in the background. Turn off downloads during gameplay, or set a download limit, in their settings')
}

$dc = Probe { (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' -Name DisabledComponents -ErrorAction Stop).DisabledComponents }
if (($null -ne $dc) -and (([int64]$dc -band 0xFF) -eq 0xFF)) {
    Info 'IPv6 is fully disabled by a registry tweak (DisabledComponents 0xFF). Microsoft supports 0x20 - prefer IPv4 - instead; full disabling breaks IPv6 paths some platforms use.'
}
# 802.1p priority tags from QoS policies of other tools: some routers, modems and switches drop
# tagged frames outright. This script never sets them.
$tagged = @(Probe { Get-NetQosPolicy -PolicyStore ActiveStore -ErrorAction Stop } | Where-Object {
    $pv = $_.PriorityValue8021Action
    if ($null -eq $pv) { $pv = $_.PriorityValue }
    ([string]$_.Name -notlike 'NQ-*') -and ($null -ne $pv) -and ([int]$pv -ge 0) -and ([int]$pv -le 7)
})
if ($tagged.Count -gt 0) {
    Warn ('QoS policies from another tool add 802.1p priority tags: ' + ((@($tagged) | ForEach-Object { [string]$_.Name }) -join ', ') + ' - some routers and modems drop tagged frames. Remove them unless your network needs them')
    $flags++
}
$ter = Probe { Get-NetTeredoConfiguration -ErrorAction Stop }
if ($ter -and ([string]$ter.Type -eq 'Disabled')) {
    Info 'Teredo is disabled - some Xbox-network PC games need it for multiplayer and party chat. It changes nothing for ping; re-enable it if such a game reports a Teredo error'
}
if (($script:NQ_Warned -eq $healthWarnCount) -and ($script:NQ_Failed -eq $healthFailCount)) { Same 'no physical-layer or path red flags detected' }

# ------------------------------------------------------------------------------------------
Head 'NIC drivers: link power saving off, CPU-saving defaults kept, Wi-Fi radio at full strength'
# ------------------------------------------------------------------------------------------
foreach ($n in $Nics) {
    $wifi = IsWifi $n
    $kind = 'Ethernet'; if ($wifi) { $kind = 'Wi-Fi' }
    if (IsUsb $n) { $kind += ' over USB' }
    Doing 'ADAPTER' ($n.Name + ' [' + $kind + ' | ' + $n.InterfaceDescription + ']')
    $script:NqMissing.Clear()

    # Energy-Efficient Ethernet (802.3az) and vendor green / low-power link modes. The PHY drops
    # into Low Power Idle between packets; on Intel I225/I226 and several Realtek chips that
    # triggers link drops and loss. Keywords: standard *EEE, Intel EEELinkAdvertisement,
    # SipsEnabled, AutoPowerSaveModeEnabled, ULPMode; Realtek AdvancedEEE, EnableGreenEthernet,
    # PowerSavingMode, AutoDisableGigabit and the USB idle modes; ASIX GreenEthernet,
    # UsbPowerSave; Killer APSmode; *SelectiveSuspend on USB and some PCIe NICs.
    foreach ($kw in $PowerKeys) { Set-AdvIf $n $kw '0' }
    # The same modes under vendor keywords the list does not know, found by display name.
    foreach ($p in @($Cache[$n.Name].Values)) {
        $dn = [string]$p.DisplayName
        if ((-not $dn) -or ($dn -notmatch $PowerNames) -or ($dn -match $PowerExclude)) { continue }
        if ($PowerKeys -contains [string]$p.RegistryKeyword) { continue }
        if (@('*IdleRestriction', 'IbssTxPower', 'TxPowerLevel', 'TxPwrLevel') -contains [string]$p.RegistryKeyword) { continue }
        Set-AdvByText $n ([string]$p.RegistryKeyword) '^(Disabled?|Off)$'
    }
    # Idle power-down only while nobody is using the PC. For *IdleRestriction, 1 restricts idle
    # to "user not present"; 0, which older name-based tweaks wrote, lets the adapter sleep
    # between packets during a game.
    Set-AdvIf $n '*IdleRestriction' '1'

    # FPS guard first, so a driver left half-configured by another tool is sane again.
    if (Flag 'NQ_FPS_GUARD') { Restore-CpuDefaults $n; Repair-HiddenRss $n }
    # Opt-in only: interrupt moderation off hands each packet over a fraction of a millisecond
    # sooner, at a CPU cost that showed up as lower FPS in testing.
    if (Flag 'NQ_INTMOD_OFF') { Set-Adv $n '*InterruptModeration' '0' }

    # Receive capacity: loss at the PC happens when the receive ring overflows during a burst.
    # A larger ring only holds packets while the CPU is behind, so it adds no latency.
    Set-AdvIf $n '*RSS' '1'
    if (Flag 'NQ_RX_MAX') { Set-RxRing $n }
    Set-TxRingDefault $n
    # Intel DMA coalescing holds received frames for up to 10 ms to save package power.
    Set-AdvIf $n 'DMACoalescing' '0'
    # Standard 1514-byte frames. Jumbo frames through consumer routers are dropped silently.
    if ($Cache[$n.Name]['*JumboPacket']) { Set-AdvEdge $n '*JumboPacket' }

    if (-not $wifi) {
        # Intel I225 v1 at 2.5 Gbps: Intel's documented workaround is a 1 Gbps link. Still
        # auto-negotiated - only the advertised speed changes.
        if ((Flag 'NQ_I225_1G') -and $script:NqWifi.ContainsKey('I225:' + $n.Name)) { Set-Adv $n '*SpeedDuplex' '6' }
        if (Flag 'NQ_NIC_POWER_OFF') { Set-NicPower $n }
        if (Flag 'NQ_UNDO_V30') { Set-AdvDefault $n 'AdaptiveIFS' }
    } else {
        $wi = $script:NqWifi[$n.Name]
        # Transmit power back to the driver default - the highest level on every vendor. The
        # scales run in opposite directions (Intel 100 = highest, MediaTek and Realtek
        # 0 = highest), so a "maximum number" rewrite by earlier tools set MediaTek to LOWEST.
        $txKeys = @('IbssTxPower', 'TxPowerLevel', 'TxPwrLevel')
        foreach ($p in @($Cache[$n.Name].Values | Where-Object { [string]$_.DisplayName -match '(?i)transmit power|tx ?power' })) {
            if ($txKeys -notcontains [string]$p.RegistryKeyword) { $txKeys += [string]$p.RegistryKeyword }
        }
        foreach ($kw in $txKeys) { Set-AdvDefault $n $kw }
        # Roaming back to the driver default on every vendor keyword. "Lowest" keeps the PC on
        # a weak access point or band until the signal collapses, and mesh or band-steering
        # routers then force it off: bursts of loss. At good signal the setting changes nothing.
        $roamKeys = @('RoamAggressiveness', 'RegRoamLevel', 'RegROAMSensitiveLevel', 'RoamIndicateTh', 'roamPolicy')
        foreach ($p in @($Cache[$n.Name].Values | Where-Object { [string]$_.DisplayName -match '(?i)roam(ing)?\s*(aggressiveness|sensitivity)' })) {
            if ($roamKeys -notcontains [string]$p.RegistryKeyword) { $roamKeys += [string]$p.RegistryKeyword }
        }
        foreach ($kw in $roamKeys) { Set-AdvDefault $n $kw }
        if (Flag 'NQ_WIFI_TUNE') {
            # Spatial-multiplexing power save shuts receive chains down (3 = No SMPS); U-APSD
            # buffers downlink frames at the access point; MediaTek LowPowerEnable and Realtek
            # LpsEn are the drivers' own sleep-between-beacons modes.
            Set-AdvIf $n 'MIMOPowerSaveMode' '3'
            Set-AdvIf $n 'uAPSDSupport' '0'
            Set-AdvIf $n 'LowPowerEnable' '0'
            Set-AdvIf $n 'LpsEn' '0'
        }
        # Preferred band, by each vendor's own value. Skipped when this router's 5 GHz signal
        # is too weak here: forcing a weak band raises loss instead of lowering it.
        $bandPref = Num 'NQ_WIFI_BAND' 0
        if (($bandPref -eq 5) -or ($bandPref -eq 6)) {
            $bandKeys = [ordered]@{ 'RoamingPreferredBandType' = '2'; 'PreferBand' = '2'; 'PreferredBand' = '2'; 'StaPreferredBand' = '3' }
            $bk = $null
            foreach ($k in $bandKeys.Keys) { if ($Cache[$n.Name][$k]) { $bk = $k; break } }
            $best5 = $null
            if ($wi -and $wi.Loc -and $wi.Ssid) {
                $best5 = @($wi.Bss | Where-Object { ($_.Ssid -eq $wi.Ssid) -and ((Get-NqBand $_.MHz) -ne '2.4') } | Sort-Object Rssi -Descending) | Select-Object -First 1
            }
            if (-not $bk) {
                $pb = Find-Kw $n @() 'Preferred Band'
                if ($pb -and (-not ($best5 -and ($best5.Rssi -lt -72)))) { Set-AdvByText $n $pb '(?i)prefer.*5|5 ?G.*first' }
            } elseif ($best5 -and ($best5.Rssi -lt -72)) {
                Info ($n.Name + ': the 5 GHz network only reaches ' + $best5.Rssi + ' dBm here, so no band is forced')
                Set-AdvDefault $n $bk
            } else {
                $bv = $bandKeys[$bk]
                if (($bandPref -eq 6) -and ($bk -eq 'RoamingPreferredBandType') -and (@(ValidOf $Cache[$n.Name][$bk]) -contains '4')) { $bv = '4' }
                Set-Adv $n $bk $bv
            }
        }
        # 2.4 GHz only: a 40 MHz channel spans two-thirds of the band and picks up every
        # neighbour on its second half. 20 MHz trades peak speed for fewer corrupted frames.
        if ((Flag 'NQ_WIFI_24_20MHZ') -and $script:NqWifi['On24:' + $n.Name]) {
            $w24 = [ordered]@{ 'ChannelWidth24' = '0'; 'BW40MHzFor2G' = '0'; 'BWSelection24G' = '1'; 'PreferredChanWidth2G' = '1' }
            foreach ($k in $w24.Keys) { Set-AdvIf $n $k $w24[$k] }
        }
        # Background-scan blocking, on the older Intel drivers that still expose it. "On Good
        # RSSI" keeps the scans that find a better access point once the signal weakens.
        $bgMode = Num 'NQ_WIFI_BGSCAN' 0
        if ($bgMode -gt 0) {
            $bs = $null
            if ($Cache[$n.Name]['BgScanGlobalBlocking']) { $bs = 'BgScanGlobalBlocking' } else { $bs = Find-Kw $n @() 'BG Scan|Background Scan' }
            if ($bs -and ($bgMode -ge 2)) { Set-AdvByText $n $bs 'Always' }
            elseif ($bs -eq 'BgScanGlobalBlocking') { Set-Adv $n $bs '1' }
            elseif ($bs) { Set-AdvByText $n $bs 'Good RSSI' }
        }
        # Undo v3.0: wireless mode back to the driver default, by keyword and by name.
        if (Flag 'NQ_UNDO_V30') {
            $modeKeys = @('IEEE11nMode', 'WirelessMode', 'WifiProtocol_2g', 'WifiProtocol_5g', 'WifiProtocol_6G', 'CurrPhyMode', 'StaWirelessMode')
            foreach ($p in @($Cache[$n.Name].Values | Where-Object { ([string]$_.DisplayName -match '(?i)wireless mode') -and ([string]$_.DisplayName -notmatch '(?i)ad ?hoc|ibss') })) {
                if ($modeKeys -notcontains [string]$p.RegistryKeyword) { $modeKeys += [string]$p.RegistryKeyword }
            }
            foreach ($kw in $modeKeys) { Set-AdvDefault $n $kw }
        }
        # "Connect to a more preferred network if available" makes Windows keep looking for
        # other networks while connected. Read from the profile XML, so it is language-free.
        if ((Flag 'NQ_WIFI_TUNE') -and $wi -and $wi.Profile) {
            $pdir = Join-Path $env:ProgramData ('Microsoft\Wlansvc\Profiles\Interfaces\' + [string]$n.InterfaceGuid)
            foreach ($f in @(Get-ChildItem -LiteralPath $pdir -Filter '*.xml' -ErrorAction SilentlyContinue)) {
                $x = Probe { [xml](Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop) }
                if ((-not $x) -or ([string]$x.WLANProfile.name -ne $wi.Profile)) { continue }
                if ([string]$x.WLANProfile.autoSwitch -ne 'true') { Same ($n.Name + ': profile "' + $wi.Profile + '" does not hunt for other networks'); break }
                Doing 'WLAN' ($n.Name + ': profile "' + $wi.Profile + '" autoSwitch -> no')
                try {
                    Change {
                        & ($env:NQ_BIN + '\netsh.exe') wlan set profileparameter ('name=' + $wi.Profile) ('interface=' + $n.Name) 'autoSwitch=no' | Out-Null
                        if ($LASTEXITCODE -ne 0) { throw ('NETSH returned exit code ' + $LASTEXITCODE) }
                    }
                    Ok ($n.Name + ': Windows no longer searches for other networks while connected to "' + $wi.Profile + '"')
                } catch { Failed ($n.Name + ': autoSwitch: ' + $_.Exception.Message) }
                break
            }
        }
    }
    if ($script:NqMissing.Count -gt 0) {
        Write-Host ('     [SKIP] ' + $n.Name + ': ' + $script:NqMissing.Count + ' settings not exposed by this driver - ' + ($script:NqMissing -join ', ')) -ForegroundColor DarkGray
    }
}

# ------------------------------------------------------------------------------------------
Head 'Receive Side Scaling (global)'
# ------------------------------------------------------------------------------------------
$g = Read-Nq 'Reading global offload settings' { Get-NetOffloadGlobalSetting }
if ($g) {
    if ([string]$g.ReceiveSideScaling -eq 'Enabled') { Same 'Receive Side Scaling (global) on' }
    else {
        Doing 'OFFLOAD' 'Setting ReceiveSideScaling = Enabled'
        try { Change { Set-NetOffloadGlobalSetting -ReceiveSideScaling Enabled -ErrorAction Stop }; Ok 'Receive Side Scaling (global): off -> on' }
        catch { Failed ('Global Receive Side Scaling: ' + $_.Exception.Message) }
    }
}

# ------------------------------------------------------------------------------------------
if (Flag 'NQ_TCP_ACK1') {
    Head 'TCP delayed-ACK off per interface  (TCP-based games)'
    $ifRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
    foreach ($n in $Nics) {
        $k = Join-Path $ifRoot ([string]$n.InterfaceGuid)
        try {
            if (-not (Test-Path -LiteralPath $k)) { Skip ($n.Name + ': interface registry key is absent'); continue }
            # An absent value is an ordinary unset state, not a failed key read.
            $cur = (Get-ItemProperty -LiteralPath $k).TcpAckFrequency
            if ($cur -eq 1) { Same ($n.Name + ': TcpAckFrequency = 1'); continue }
            Doing 'TCP' ($n.Name + ': setting TcpAckFrequency = 1')
            Change { New-ItemProperty -LiteralPath $k -Name TcpAckFrequency -PropertyType DWord -Value 1 -Force -ErrorAction Stop | Out-Null }
            $Restart[$n.Name] = $true
            Ok ($n.Name + ': TcpAckFrequency = 1 - every TCP segment ACKed at once, no 200 ms delayed-ACK stalls')
        } catch { Failed ($n.Name + ': TcpAckFrequency: ' + $_.Exception.Message) }
    }
}

# ------------------------------------------------------------------------------------------
if (Flag 'NQ_RSS_OFF_CPU0') {
    Head 'RSS: NIC receive DPCs moved off CPU 0'
    $lp = [Environment]::ProcessorCount
    if ($lp -lt 6) { Skip 'fewer than 6 logical CPUs - left alone' }
    else {
        foreach ($n in $Nics) {
            if (IsWifi $n) { continue }
            $r = Probe { Get-NetAdapterRss -Name $n.Name -ErrorAction Stop }
            if ((-not $r) -or (-not $r.Enabled)) { Skip ($n.Name + ': RSS not available'); continue }
            if ($r.BaseProcessorNumber -ge 2) { Same ($n.Name + ': RSS base CPU = ' + $r.BaseProcessorNumber); continue }
            Doing 'RSS' ($n.Name + ': setting base CPU = 2 and maximum CPU = ' + ($lp - 1))
            try {
                Change { Set-NetAdapterRss -Name $n.Name -BaseProcessorNumber 2 -MaxProcessorNumber ($lp - 1) -NoRestart -ErrorAction Stop }
                $Restart[$n.Name] = $true
                Ok ($n.Name + ': RSS base CPU ' + $r.BaseProcessorNumber + ' -> 2')
            } catch { Failed ($n.Name + ': RSS processor change: ' + $_.Exception.Message) }
        }
    }
}

# ------------------------------------------------------------------------------------------
Head 'Undo known-harmful leftovers from other optimizer scripts'
# ------------------------------------------------------------------------------------------
$tp = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
$undoFailCount = $script:NQ_Failed
$tv = Read-Nq 'Reading TCP/IP legacy overrides' { Get-ItemProperty -LiteralPath $tp }
$fixed = 0

# Each entry: value name, test that marks it harmful, and what removing it restores.
$tcpUndo = @(
    @('DisableTaskOffload',        { param($v) [int]$v -eq 1 },          'DisableTaskOffload=1 removed (it forced checksum and segmentation work onto the CPU)'),
    @('EnablePMTUDiscovery',       { param($v) [int]$v -eq 0 },          'Path-MTU discovery restored (0 forces 576-byte packets to every remote host)'),
    @('Tcp1323Opts',               { param($v) ([int]$v -band 1) -eq 0 }, 'Tcp1323Opts without window scaling removed (it capped every TCP window at 64 KB)'),
    @('DefaultTTL',                { param($v) [int]$v -lt 64 },         'Low DefaultTTL removed - packets to distant game servers expired in transit; back to 128'),
    @('TcpMaxDataRetransmissions', { param($v) [int]$v -lt 5 },          'Low TcpMaxDataRetransmissions removed - it dropped TCP game connections after a short loss burst'),
    @('SackOpts',                  { param($v) [int]$v -eq 0 },          'Selective ACK restored - without it one lost packet forces a whole window to be resent')
)
if ($tv) {
    foreach ($u in $tcpUndo) {
        $val = $tv.($u[0])
        if (($null -eq $val) -or (-not (& $u[1] $val))) { continue }
        Doing 'TCP' ('Removing ' + $u[0] + '=' + $val + ' override')
        try {
            Change { Remove-ItemProperty -LiteralPath $tp -Name $u[0] -ErrorAction Stop }
            Ok $u[2]; $fixed++
        } catch { Failed ('Removing ' + $u[0] + ': ' + $_.Exception.Message) }
    }
}

# Socket buffer defaults shrunk by old guides: a tiny UDP buffer overflows on the first burst.
$afd = 'HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters'
foreach ($name in @('DefaultReceiveWindow', 'DefaultSendWindow')) {
    $val = Probe { (Get-ItemProperty -LiteralPath $afd -Name $name -ErrorAction Stop).$name }
    if (($null -eq $val) -or ([int64]$val -ge 16384)) { continue }
    Doing 'AFD' ('Removing ' + $name + '=' + $val)
    try {
        Change { Remove-ItemProperty -LiteralPath $afd -Name $name -ErrorAction Stop }
        Ok ($name + '=' + $val + ' removed - sockets get the Windows default buffer again, so bursts are not dropped'); $fixed++
    } catch { Failed ('Removing ' + $name + ': ' + $_.Exception.Message) }
}

# An IP MTU above 1500 on an internet-facing adapter: the path drops or fragments those packets.
foreach ($n in $Nics) {
    if ($n.Status -ne 'Up') { continue }
    foreach ($af in @('IPv4', 'IPv6')) {
        $ipi = Probe { Get-NetIPInterface -InterfaceIndex $n.ifIndex -AddressFamily $af -ErrorAction Stop }
        if ((-not $ipi) -or ([int]$ipi.NlMtu -le 1500)) { continue }
        Doing 'MTU' ($n.Name + ': ' + $af + ' MTU ' + $ipi.NlMtu + ' -> 1500')
        try {
            Change { Set-NetIPInterface -InterfaceIndex $n.ifIndex -AddressFamily $af -NlMtuBytes 1500 -ErrorAction Stop }
            Ok ($n.Name + ': ' + $af + ' MTU ' + $ipi.NlMtu + ' -> 1500 - internet paths carry at most 1500-byte packets'); $fixed++
        } catch { Failed ($n.Name + ': ' + $af + ' MTU: ' + $_.Exception.Message) }
    }
}

# A disabled DNS Client makes every new connection wait on an uncached lookup.
$dnsStart = Probe { (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache' -Name Start -ErrorAction Stop).Start }
if ($dnsStart -eq 4) {
    Doing 'SERVICE' 'Re-enabling the DNS Client service'
    try {
        Change { Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache' -Name Start -Value 2 -ErrorAction Stop }
        Ok 'DNS Client re-enabled - active after the reboot'; $fixed++
    } catch { Failed ('DNS Client: ' + $_.Exception.Message) }
}

# Congestion control on the internet templates. Old tweak guides set CTCP; NewReno and DCTCP
# also appear. CUBIC is the Windows default since Windows 10 1709. BBR2 is left as chosen.
foreach ($ts in @(Probe { Get-NetTCPSetting -ErrorAction Stop })) {
    $tsn = [string]$ts.SettingName
    if (@('Internet', 'InternetCustom') -notcontains $tsn) { continue }
    $cp = [string]$ts.CongestionProvider
    if ($cp -match '^(CTCP|NewReno|DCTCP)$') {
        Doing 'TCP' ($tsn + ' template: congestion provider ' + $cp + ' -> CUBIC')
        try {
            Change {
                & ($env:NQ_BIN + '\netsh.exe') int tcp set supplemental ('template=' + $tsn.ToLowerInvariant()) 'congestionprovider=cubic' | Out-Null
                if ($LASTEXITCODE -ne 0) { throw ('NETSH returned exit code ' + $LASTEXITCODE) }
            }
            Ok ($tsn + ' template: ' + $cp + ' -> CUBIC, the Windows default congestion control'); $fixed++
        } catch { Failed ($tsn + ' congestion provider: ' + $_.Exception.Message) }
    } elseif ($cp -eq 'BBR2') {
        Info ($tsn + ' template uses BBR2 - left as chosen')
    }
}

# Network Location Awareness and the Network List Service give each connection its network
# profile; QoS policies and DSCP marking depend on it.
foreach ($sv in @(@('NlaSvc', 2, 'Network Location Awareness'), @('netprofm', 3, 'Network List Service'))) {
    $svKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\' + $sv[0]
    $svStart = Probe { (Get-ItemProperty -LiteralPath $svKey -Name Start -ErrorAction Stop).Start }
    if ($svStart -ne 4) { continue }
    Doing 'SERVICE' ('Re-enabling ' + $sv[2])
    try {
        Change { Set-ItemProperty -LiteralPath $svKey -Name Start -Value $sv[1] -ErrorAction Stop }
        Ok ($sv[2] + ' re-enabled - active after the reboot'); $fixed++
    } catch { Failed ($sv[2] + ': ' + $_.Exception.Message) }
}

# Active probing is how Windows tells "connected" from "no internet". Old guides switch it off;
# Microsoft's guidance is to leave it on, and without it launchers and stores misreport offline.
$ncsiKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet'
$probeOn = Probe { (Get-ItemProperty -LiteralPath $ncsiKey -Name EnableActiveProbing -ErrorAction Stop).EnableActiveProbing }
if (($null -ne $probeOn) -and ([int]$probeOn -eq 0)) {
    Doing 'NCSI' 'Re-enabling network connectivity active probing'
    try {
        Change { Set-ItemProperty -LiteralPath $ncsiKey -Name EnableActiveProbing -Value 1 -ErrorAction Stop }
        Ok 'Network connectivity probing restored - Windows and launchers detect the internet correctly again'; $fixed++
    } catch { Failed ('Connectivity probing: ' + $_.Exception.Message) }
}
$ncsiPol = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator'
$noProbe = Probe { (Get-ItemProperty -LiteralPath $ncsiPol -Name NoActiveProbe -ErrorAction Stop).NoActiveProbe }
if ($noProbe -eq 1) {
    Doing 'NCSI' 'Removing the NoActiveProbe policy'
    try {
        Change { Remove-ItemProperty -LiteralPath $ncsiPol -Name NoActiveProbe -ErrorAction Stop }
        Ok 'NoActiveProbe policy removed'; $fixed++
    } catch { Failed ('NoActiveProbe policy: ' + $_.Exception.Message) }
}

foreach ($n in $Nics) {
    $b = Read-Nq ('Reading QoS Packet Scheduler binding: ' + $n.Name) { Get-NetAdapterBinding -Name $n.Name -ComponentID ms_pacer }
    if ($b -and (-not $b.Enabled)) {
        Doing 'BINDING' ($n.Name + ': enabling QoS Packet Scheduler / ms_pacer')
        try {
            Change { Enable-NetAdapterBinding -Name $n.Name -ComponentID ms_pacer -ErrorAction Stop }
            Ok ($n.Name + ': QoS Packet Scheduler re-bound (required for DSCP marking)'); $fixed++
        } catch { Failed ($n.Name + ': enabling QoS Packet Scheduler: ' + $_.Exception.Message) }
    }
}
if (($fixed -eq 0) -and ($script:NQ_Failed -eq $undoFailCount)) { Same 'nothing harmful found' }

# ------------------------------------------------------------------------------------------
if (Flag 'NQ_UNDO_V30') {
    Head 'Undo v3.0: interface metrics back to automatic'
    # v3.0 pinned wired adapters to metric 10 with automatic metric off. Only that exact
    # signature is reverted; Windows then ranks adapters by link speed again.
    $mFixed = 0
    foreach ($n in @($Nics | Where-Object { -not (IsWifi $_) })) {
        foreach ($af in @('IPv4', 'IPv6')) {
            $ipi = Probe { Get-NetIPInterface -InterfaceIndex $n.ifIndex -AddressFamily $af -ErrorAction Stop }
            if ((-not $ipi) -or ([int]$ipi.InterfaceMetric -ne 10) -or ([string]$ipi.AutomaticMetric -ne 'Disabled')) { continue }
            Doing 'ROUTE' ($n.Name + ': ' + $af + ' interface metric 10 -> automatic')
            try {
                Change { Set-NetIPInterface -InterfaceIndex $n.ifIndex -AddressFamily $af -AutomaticMetric Enabled -ErrorAction Stop }
                Ok ($n.Name + ': ' + $af + ' automatic interface metric restored'); $mFixed++
            } catch { Failed ($n.Name + ': ' + $af + ' interface metric: ' + $_.Exception.Message) }
        }
    }
    if ($mFixed -eq 0) { Same 'no interface metric pinned by v3.0' }
}

if (Flag 'NQ_WIFI_LOCATION_OFF') {
    Head 'Wi-Fi scans caused by location requests'
    if (-not $script:NqViaWifi) {
        Skip 'internet traffic does not run over Wi-Fi - the location service is left alone'
    } else {
        # Windows finds its position by scanning for nearby Wi-Fi networks. Every location
        # request from weather, maps, time-zone or other apps takes the radio off your channel.
        $ls = Probe { Get-Service -Name lfsvc -ErrorAction Stop }
        if (-not $ls) { Skip 'the location service is not installed' }
        elseif (([string]$ls.StartType -eq 'Disabled') -and ([string]$ls.Status -ne 'Running')) { Same 'location service off' }
        else {
            Doing 'SERVICE' 'Stopping and disabling the Geolocation service (lfsvc)'
            try {
                Change {
                    if ([string]$ls.Status -eq 'Running') { Stop-Service -Name lfsvc -Force -ErrorAction Stop }
                    Set-Service -Name lfsvc -StartupType Disabled -ErrorAction Stop
                }
                Ok 'location service off - apps can no longer trigger Wi-Fi scans for positioning; apps lose location and automatic time zone'
            } catch { Failed ('location service: ' + $_.Exception.Message) }
        }
    }
}

# ------------------------------------------------------------------------------------------
Head 'Traffic priority: DSCP marking for games and voice apps'
# ------------------------------------------------------------------------------------------
if (-not (Get-Command New-NetQosPolicy -ErrorAction SilentlyContinue)) {
    Skip 'NetQos module unavailable on this edition - skipped'
} else {
    $dscp = Num 'NQ_DSCP_VALUE' 46
    if (($dscp -lt 0) -or ($dscp -gt 63)) { $dscp = 46 }
    $vdscp = Num 'NQ_VOICE_DSCP' 26
    if (($vdscp -lt 0) -or ($vdscp -gt 63)) { $vdscp = 26 }
    $cap = Num 'NQ_UPCAP_KBPS' 0

    # The complete wanted set. Policies this script owns (NQ-*) that are no longer wanted, or
    # differ, are replaced; identical ones are left alone so re-runs change nothing.
    $want  = @{}
    $order = New-Object System.Collections.Generic.List[string]
    $plan  = @()
    # One upload figure drives the cap when no explicit cap is set: 60 percent of the line.
    if (($cap -le 0) -and ((Num 'NQ_UP_MBPS' 0) -gt 0)) { $cap = [int]((Num 'NQ_UP_MBPS' 0) * 600) }
    $markGames = (Flag 'NQ_DSCP')
    if ($markGames -and $script:NqEfDropped -and (Flag 'NQ_DSCP_AUTO')) {
        Warn 'Game marking withdrawn: the UDP test above showed this connection dropping DSCP 46 packets. Unmarked game packets arrive more reliably here'
        $markGames = $false
    }
    if ($markGames)           { $plan += ,@([string]$env:NQ_GAMES,     'NQ-DSCP-',  $dscp,  [uint64]0, 'Both') }
    if (Flag 'NQ_DSCP_VOICE') { $plan += ,@([string]$env:NQ_VOICE,     'NQ-VOICE-', $vdscp, [uint64]0, 'UDP') }
    if ($cap -gt 0)           { $plan += ,@([string]$env:NQ_BULK_APPS, 'NQ-CAP-',   -1,     ([uint64]$cap * 1000), 'Both') }
    foreach ($row in $plan) {
        foreach ($exe in @(($row[0] -split ';') | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
            $pname = $row[1] + $exe
            if ($want.ContainsKey($pname)) { continue }
            $want[$pname] = [pscustomobject]@{ Exe = $exe; Dscp = [int]$row[2]; Rate = [uint64]$row[3]; Proto = [string]$row[4] }
            $order.Add($pname)
        }
    }

    $kept = @{}
    foreach ($h in @(Read-Nq 'Reading this script''s existing QoS policies' { Get-NetQosPolicy } | Where-Object { $_.Name -like 'NQ-*' })) {
        $w = $want[[string]$h.Name]
        $match = $false
        if ($w) {
            $match = ([string]$h.AppPathName -eq $w.Exe) -and ([string]$h.NetworkProfile -eq 'All')
            if ($w.Rate -gt 0) { $match = $match -and ([uint64]$h.ThrottleRate -eq $w.Rate) }
            else { $match = $match -and ([int]$h.DSCPValue -eq $w.Dscp) -and ([string]$h.IPProtocol -eq $w.Proto) }
        }
        if ($match) { $kept[[string]$h.Name] = $true; continue }
        $policyName = [string]$h.Name
        Doing 'QOS' ('Removing outdated policy ' + $policyName)
        try {
            Change { Remove-NetQosPolicy -Name $policyName -Confirm:$false -ErrorAction Stop }
            Ok ('Removed outdated policy ' + $policyName)
        } catch { Failed ('Removing policy ' + $policyName + ': ' + $_.Exception.Message) }
    }

    $made = 0
    foreach ($pname in $order) {
        if ($kept.ContainsKey($pname)) { continue }
        $w = $want[$pname]
        try {
            if ($w.Rate -gt 0) {
                Doing 'QOS' ('Capping ' + $w.Exe + ' upload at ' + ($w.Rate / 1000) + ' kbit/s')
                Change { New-NetQosPolicy -Name $pname -AppPathNameMatchCondition $w.Exe -ThrottleRateActionBitsPerSecond $w.Rate -NetworkProfile All -ErrorAction Stop | Out-Null }
                Ok ($w.Exe + ' upload capped at ' + ($w.Rate / 1000) + ' kbit/s')
            } else {
                Doing 'QOS' ('Marking ' + $w.Exe + ': DSCP = ' + $w.Dscp + ', ' + $w.Proto + ', all profiles')
                Change { New-NetQosPolicy -Name $pname -AppPathNameMatchCondition $w.Exe -IPProtocolMatchCondition $w.Proto -DSCPAction ([sbyte]$w.Dscp) -NetworkProfile All -ErrorAction Stop | Out-Null }
                Ok ($w.Exe + ': DSCP = ' + $w.Dscp)
            }
            $made++
        } catch { Failed ('QoS policy ' + $pname + ': ' + $_.Exception.Message) }
    }
    if ($kept.Count -gt 0) { Same ([string]$kept.Count + ' QoS policies already in place') }
    Say ('     [INFO] ' + [string]($kept.Count + $made) + ' of ' + $order.Count + ' QoS policies active. On Wi-Fi, Windows sends DSCP 32-47 in the WMM video queue, ahead of ordinary traffic')
}

# ------------------------------------------------------------------------------------------
Head 'Background transfers capped  (a full upload or download queue is the classic lag spike)'
# ------------------------------------------------------------------------------------------
# Windows Update, Store, Defender, Edge, Office and Game Pass downloads all run through Delivery
# Optimization. Its background transports let up to 60 ms of queueing build before backing off,
# so a hard cap is what keeps game packets out of that queue. With the line speed known, the
# cap is absolute; the percentage form then has to go, because Windows applies it on top.
$doKey  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
$doPct  = Num 'NQ_DO_BG_PCT' 0
$downMb = Num 'NQ_DOWN_MBPS' 0
$upMb   = Num 'NQ_UP_MBPS' 0
if ($doPct -le 0) { Skip 'Delivery Optimization cap turned off in the config' }
else {
    if ($doPct -gt 90) { $doPct = 90 }
    if ($downMb -gt 0) {
        $kbs = [int64]([math]::Max(64, [math]::Round($downMb * 125 * $doPct / 100)))
        Set-RegDword $doKey 'DOMaxBackgroundDownloadBandwidth' $kbs ('Background Windows downloads capped at ' + $kbs + ' KB/s (' + $doPct + ' percent of ' + $downMb + ' Mbit/s)')
        Remove-RegValue $doKey 'DOPercentageMaxBackgroundBandwidth' 'percentage cap removed - it would otherwise shrink the absolute cap further'
    } else {
        Set-RegDword $doKey 'DOPercentageMaxBackgroundBandwidth' $doPct ('Background Windows downloads capped at ' + $doPct + ' percent of measured bandwidth - set NQ_DOWN_MBPS for a firm cap')
        $abs = Probe { (Get-ItemProperty -LiteralPath $doKey -Name DOMaxBackgroundDownloadBandwidth -ErrorAction Stop).DOMaxBackgroundDownloadBandwidth }
        if ($null -ne $abs) { Info ('An absolute cap of ' + $abs + ' KB/s is also set; Windows applies the percentage to it') }
    }
}
# Mode 100 (Bypass) is deprecated on Windows 11 and can make downloads fail; the batch stage
# already sets mode 0. Deprecated caps from old guides are ignored by Windows and only reported.
foreach ($old in @('DOMaxUploadBandwidth', 'DOMaxDownloadBandwidth', 'DOPercentageMaxDownloadBandwidth')) {
    $ov = Probe { (Get-ItemProperty -LiteralPath $doKey -Name $old -ErrorAction Stop).$old }
    if ($null -ne $ov) { Info ($old + ' = ' + $ov + ' is ignored since Windows 10 2004 - the caps above replace it') }
}

# OneDrive. The percentage policy lets OneDrive upload unthrottled for a minute at a time, so
# with the upload speed known a fixed KB/s limit replaces it. That limit is a per-user policy:
# it goes to the signed-in user's hive, not to the administrator account running this script.
$odPct = Num 'NQ_ONEDRIVE_UP_PCT' 0
if ($odPct -le 0) { Skip 'OneDrive upload limit turned off in the config' }
else {
    if ($odPct -lt 10) { $odPct = 10 }
    if ($odPct -gt 99) { $odPct = 99 }
    $odPaths = @(($env:ProgramFiles + '\Microsoft OneDrive\OneDrive.exe'), (${env:ProgramFiles(x86)} + '\Microsoft OneDrive\OneDrive.exe'))
    $odPaths += @(Get-ChildItem -Path ($env:SystemDrive + '\Users\*\AppData\Local\Microsoft\OneDrive\OneDrive.exe') -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    $odFound = (@($odPaths | Where-Object { $_ -and (Test-Path -LiteralPath $_) }).Count -gt 0)
    $odKey = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
    $userKey = $null
    if ($upMb -gt 0) {
        $console = Probe { [string](Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).UserName }
        $sid = $null
        if ($console) { $sid = Probe { (New-Object System.Security.Principal.NTAccount($console)).Translate([System.Security.Principal.SecurityIdentifier]).Value } }
        if ($sid -and (Test-Path -LiteralPath ('Registry::HKEY_USERS\' + $sid))) { $userKey = 'Registry::HKEY_USERS\' + $sid + '\SOFTWARE\Policies\Microsoft\OneDrive' }
    }
    if (-not $odFound) { Skip 'OneDrive is not installed' }
    elseif ($userKey) {
        $odKbs = [int64]([math]::Min(100000, [math]::Max(50, [math]::Round($upMb * 125 * $odPct / 100))))
        Set-RegDword $userKey 'UploadBandwidthLimit' $odKbs ('OneDrive uploads limited to ' + $odKbs + ' KB/s (' + $odPct + ' percent of ' + $upMb + ' Mbit/s) for the signed-in user - takes effect when OneDrive restarts')
        Remove-RegValue $odKey 'AutomaticUploadBandwidthPercentage' 'OneDrive percentage limit removed - Microsoft says not to combine it with a fixed limit'
    } else {
        if ($upMb -gt 0) { Info 'The signed-in user could not be resolved, so OneDrive keeps the percentage limit' }
        Set-RegDword $odKey 'AutomaticUploadBandwidthPercentage' $odPct ('OneDrive uploads limited to ' + $odPct + ' percent of throughput - set NQ_UP_MBPS for a steadier fixed limit')
    }
    $odAuto = Probe { (Get-ItemProperty -LiteralPath $odKey -Name EnableAutomaticUploadBandwidthManagement -ErrorAction Stop).EnableAutomaticUploadBandwidthManagement }
    if ($odFound -and ($odAuto -eq 1)) { Info 'OneDrive automatic upload bandwidth management is on - it overrides the percentage limit' }
}

# ------------------------------------------------------------------------------------------
if (Flag 'NQ_SHAPERS_OFF') {
    Head 'Third-party traffic shapers known to add latency and loss'
    $serviceFailCount = $script:NQ_Failed
    $svcs = @(Read-Nq 'Reading installed third-party traffic shapers' { Get-Service | Where-Object {
        $_.DisplayName -match 'SmartByte|Rivet|Killer.*(Network|Analytic|Bandwidth|Smart|Intelligence|Prioriti)'
    } })
    if (($svcs.Count -eq 0) -and ($script:NQ_Failed -eq $serviceFailCount)) { Same 'none installed' }
    foreach ($s in $svcs) {
        Doing 'SERVICE' ('Stopping ' + $s.DisplayName)
        try { Change { Stop-Service -Name $s.Name -Force -ErrorAction Stop }; Ok ($s.DisplayName + ': stopped') }
        catch { Failed ($s.DisplayName + ': stop failed: ' + $_.Exception.Message) }
        Doing 'SERVICE' ('Disabling ' + $s.DisplayName)
        try { Change { Set-Service -Name $s.Name -StartupType Disabled -ErrorAction Stop }; Ok ($s.DisplayName + ': disabled') }
        catch { Failed ($s.DisplayName + ': disable failed: ' + $_.Exception.Message) }
    }
}

# ------------------------------------------------------------------------------------------
if ($Restart.Count -gt 0) {
    Head 'Applying: restarting changed adapters once (brief disconnect)'
    foreach ($name in @($Restart.Keys)) {
        Doing 'RESTART' ('Restarting changed adapter ' + $name)
        try   { Change { Restart-NetAdapter -Name $name -Confirm:$false -ErrorAction Stop }; Ok ($name + ' restarted') }
        catch { Failed ($name + ': restart failed - changes apply after reboot: ' + $_.Exception.Message) }
    }
    if (-not $script:NQ_Dry) { Start-Sleep -Seconds 4 }
} else {
    Head 'No adapter changes were needed - no restart'
}

# ------------------------------------------------------------------------------------------
Head 'Current driver values'
# ------------------------------------------------------------------------------------------
$show = @('*EEE','EEELinkAdvertisement','EnableGreenEthernet','PowerSavingMode','AdvancedEEE','*IdleRestriction',
          '*InterruptModeration','ITR','*PacketCoalescing','*ReceiveBuffers','*TransmitBuffers','DMACoalescing',
          '*JumboPacket','*RSS','*FlowControl','*SpeedDuplex','MIMOPowerSaveMode','uAPSDSupport','LowPowerEnable','LpsEn',
          'IbssTxPower','TxPowerLevel','TxPwrLevel','RoamAggressiveness','RegRoamLevel','RegROAMSensitiveLevel',
          'RoamIndicateTh','roamPolicy','RoamingPreferredBandType','PreferBand','PreferredBand','StaPreferredBand',
          'ChannelWidth24','BW40MHzFor2G','BWSelection24G','PreferredChanWidth2G','BgScanGlobalBlocking')
foreach ($n in $Nics) {
    Say ('     > ' + $n.Name)
    Read-Nq ('Reading final driver values: ' + $n.Name) { Get-NetAdapterAdvancedProperty -Name $n.Name } |
        Where-Object {
            $dn = [string]$_.DisplayName
            ($show -contains $_.RegistryKeyword) -or (($dn -match $PowerNames) -and ($dn -notmatch $PowerExclude)) -or ($dn -match 'BG Scan|Background Scan|Wireless Mode|Roaming|Transmit Power')
        } |
        Sort-Object DisplayName |
        ForEach-Object { Write-Host ('         {0,-38} {1}' -f $_.DisplayName, $_.DisplayValue) -ForegroundColor Gray }
    if (-not (IsWifi $n)) {
        $pm = Probe { Get-NetAdapterPowerManagement -Name $n.Name -ErrorAction Stop }
        if ($pm) { Write-Host ('         {0,-38} {1}' -f 'Allow computer to turn off device', [string]$pm.AllowComputerToTurnOffDevice) -ForegroundColor Gray }
    }
    $ipm = Probe { Get-NetIPInterface -InterfaceIndex $n.ifIndex -AddressFamily IPv4 -ErrorAction Stop }
    if ($ipm) { Write-Host ('         {0,-38} {1}' -f 'IPv4 interface metric', ([string]$ipm.InterfaceMetric + ' (automatic ' + [string]$ipm.AutomaticMetric + ')')) -ForegroundColor Gray }
}
if (Get-Command Get-NetQosPolicy -ErrorAction SilentlyContinue) {
    $qosReadFailures = $script:NQ_Failed
    $qc = @(Read-Nq 'Reading installed QoS policy count' { Get-NetQosPolicy } | Where-Object { $_.Name -like 'NQ-*' }).Count
    if ($script:NQ_Failed -eq $qosReadFailures) { Say ('     [INFO] QoS policies installed by this script: ' + $qc) }
    else { Say '     [INFO] QoS policy count unavailable because the query failed.' }
} else { Skip 'QoS policy count unavailable: NetQos module is missing.' }

}

try { Invoke-NqEngine }
catch { Failed ('Unexpected engine error: ' + $_.Exception.Message) }
finally {
    Write-Host ''
    Say ('  [SUMMARY] Applied: ' + $script:NQ_Applied + '  Failed: ' + $script:NQ_Failed + '  Same: ' + $script:NQ_Same + '  Skipped: ' + $script:NQ_Skipped + '  Warnings: ' + $script:NQ_Warned)
    if ($script:NQ_Dry) { Say '  DRY RUN - nothing was changed. Applied counts what a real run would change.' }
}
if ($script:NQ_Failed -gt 0) { exit 1 }
exit 0
