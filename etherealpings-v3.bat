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
title NetLatency Tuner v3 - ping / jitter / packet loss / bufferbloat
rem ASCII / CRLF, no BOM. CMD never executes the PowerShell payload below.
rem The loader reads the payload as data; paths and application names are not code.
rem In literal batch configuration, write %% to store a single percent sign.

rem ==========================================================================================
rem  WHAT THIS CHANGES - each item has a measurable mechanism on current Windows 10 and 11:
rem   * TCP/UDP stack: receive batching off, ECN on, HyStart and PRR loss recovery kept on
rem   * MMCSS network throttling off, background Windows Update capped, update seeding off
rem   * NIC drivers: power-saving and green modes off, interrupt moderation and packet
rem     coalescing off, receive ring at the driver maximum, standard 1514-byte frames
rem   * wired adapters kept powered: no idle power-down, no wake-up delay on first packets
rem   * Wi-Fi: MIMO power save and U-APSD off, roaming scans minimised, 5 GHz preferred,
rem     transmit power at maximum, driver background-scan blocking where the driver has it
rem   * DSCP marking for games and a lower class for voice apps - Wi-Fi WMM and SQM routers
rem     prioritise it on the upload side, where home bufferbloat is usually worst
rem   * OneDrive uploads limited so cloud sync cannot fill the modem upload queue
rem   * repairs of harmful leftovers from other optimizers: low TTL, SACK off, tiny socket
rem     buffers, early TCP give-up, oversized MTU, disabled DNS client, unbound QoS scheduler
rem   * diagnosis of what software cannot fix: USB and 100 Mbps adapters, weak or 2.4 GHz
rem     Wi-Fi, legacy Wi-Fi standards, forced duplex, frame errors, stale drivers,
rem     VPN or Wi-Fi routing, Hyper-V switches, filter drivers, torrent seeding
rem
rem  v3 against v2:
rem   * path test: 30 timed pings to the router and 30 to an internet host show where loss
rem     and jitter start - on the local link or beyond the router - before anything changes
rem   * packet-loss counters read from Windows itself: NIC receive discards, UDP datagrams
rem     dropped before reaching the game, and the TCP retransmission rate since boot
rem   * Intel I225-V early steppings (B1/B2, known for link drops) and Wi-Fi Direct links
rem     (Mobile Hotspot, Miracast) that split the Wi-Fi radio's airtime are flagged
rem   * Ethernet is preferred over Wi-Fi whenever both are connected, by interface metric
rem   * Wi-Fi: wireless mode restored to the highest standard the driver offers when an
rem     old tweak capped it; roaming sensitivity lowered on Realtek and MediaTek drivers too;
rem     location requests, which make Windows scan for Wi-Fi networks, stopped on Wi-Fi PCs
rem   * wired: Adaptive Inter-Frame Spacing held off, the half-duplex collision workaround
rem     that inserts gaps between frames
rem   * frametime guard: interrupt moderation stays at the driver default on CPUs with fewer
rem     than 6 threads, so extra network interrupts never compete with game threads there
rem   * repairs: CTCP, NewReno or DCTCP left on the internet TCP templates goes back to the
rem     Windows default CUBIC; disabled Network Location Awareness, which QoS policies rely
rem     on, is re-enabled
rem   * 18 more games in the DSCP list
rem
rem  DELIBERATELY EXCLUDED - placebo, obsolete, unproven or harmful on current Windows:
rem   * TcpWindowSize, GlobalMaxTcpWindowSize, TCPNoDelay, TTL and MaxUserPort tuning:
rem     ignored since Vista or irrelevant to latency; applications control Nagle per socket
rem   * NonBestEffortLimit 0: the reserved-20-percent-bandwidth story is a myth
rem   * auto-tuning disabled, CTCP, chimney, DCA, NetDMA: removed from Windows or harmful
rem   * BBR2 congestion control: still experimental on Windows, with reported regressions
rem   * TCP pacing profiles: a real mechanism without reliable Windows benchmarks yet
rem   * disabling IPv6, Teredo, NetBIOS or LLMNR: breaks features, no ping change
rem   * Large Send or checksum offload off: more CPU per packet, no latency gain
rem   * DNS flush, Winsock or IP reset, ARP or cache clearing: forbidden here, no in-game effect
rem   * power plans and powercfg: out of scope by design
rem   * changing DNS servers: only affects name lookups before a match, never in-game ping
rem   * WLAN AutoConfig off: stops Windows' own Wi-Fi scans but also every reconnect after a
rem     drop or reboot - too costly to set from a script
rem   * transmit ring at maximum: a bigger send queue in the NIC is bufferbloat, not a cure
rem   * flow control off: pause frames are what stop the NIC dropping frames when a switch
rem     or the PC falls behind, so it stays at the driver default
rem   * larger global socket buffers: more nonpaged memory per socket; games size their own
rem ==========================================================================================

rem ==========================================================================================
rem  CONFIG      1 = on      0 = off
rem ==========================================================================================
rem  Game executables whose packets get DSCP-marked. Semicolon separated, exe name only.
rem  Wi-Fi WMM honours the mark on the air - game packets win airtime contention - and so does
rem  any router running SQM/CAKE diffserv or a DSCP-aware gaming-priority feature.
rem  Minecraft Java runs as javaw.exe; add it only if you accept marking every Java program.
rem  A listed game that is not installed costs nothing: its policy simply never matches.
set "NQ_GAMES=cs2.exe;VALORANT-Win64-Shipping.exe;FortniteClient-Win64-Shipping.exe;r5apex.exe;r5apex_dx12.exe;cod.exe;Overwatch.exe;RainbowSix.exe;RainbowSix_Vulkan.exe;dota2.exe;League of Legends.exe;RocketLeague.exe;TslGame.exe;Marvel-Win64-Shipping.exe;Discovery.exe;EscapeFromTarkov.exe;destiny2.exe;RustClient.exe;HaloInfinite.exe;RobloxPlayerBeta.exe;Minecraft.Windows.exe;GTA5.exe;GTA5_Enhanced.exe;DeadByDaylight-Win64-Shipping.exe;Warframe.x64.exe;Wow.exe;ffxiv_dx11.exe;LostArk.exe;osu!.exe;deadlock.exe;tf_win64.exe;StreetFighter6.exe;Polaris-Win64-Shipping.exe;BF2042.exe;HuntGame.exe;aces.exe;WorldOfTanks.exe;SquadGame.exe;FallGuys_client_game.exe;GenshinImpact.exe;NarakaBladepoint.exe;Brawlhalla.exe;MK12.exe;HLL-Win64-Shipping.exe;DayZ_x64.exe;SoTGame.exe;Diablo IV.exe;eldenring.exe;MonsterHunterWilds.exe;helldivers2.exe;NewWorld.exe;BlackDesert64.exe;Gw2-64.exe;StarCitizen.exe;osclient.exe;ArmaReforgerSteam.exe;DeltaForceClient-Win64-Shipping.exe;PathOfExile.exe;PathOfExileSteam.exe;PathOfExile_x64Steam.exe"
set "NQ_DSCP=1"
rem  46 = Expedited Forwarding, the standard real-time class.
set "NQ_DSCP_VALUE=46"

rem  Voice and party-chat apps, marked one class BELOW games - AF41, DSCP 34 - so a Discord
rem  screen share can never crowd game packets out of the priority queue.
set "NQ_VOICE=Discord.exe;TeamSpeak.exe;ts3client_win64.exe;mumble.exe"
set "NQ_DSCP_VOICE=1"
set "NQ_VOICE_DSCP=34"

rem  NIC interrupt moderation off: packets are handed to the stack immediately instead of
rem  being batched by a timer. Extra interrupt cost only appears while saturating the link.
rem  1 = off on CPUs with 6 or more threads, left at the driver default below that so network
rem  interrupts never compete with game threads for frame time; 2 = always off; 0 = leave.
set "NQ_INTMOD_OFF=1"

rem  NIC receive ring raised to the driver maximum: bursts are absorbed instead of dropped.
set "NQ_RX_MAX=1"

rem  Explicit Congestion Notification for TCP flows.
set "NQ_ECN=1"

rem  Wired adapters: clear "Allow the computer to turn off this device". An idle NIC that powers
rem  down - USB adapters especially - delays or drops the first packets after a quiet moment.
set "NQ_NIC_POWER_OFF=1"

rem  Wi-Fi: No SMPS, no U-APSD, transmit power at maximum. Only values the driver exposes.
set "NQ_WIFI_TUNE=1"

rem  Wi-Fi band preference: 5 = prefer 5 GHz, 6 = prefer 6 GHz where offered, 0 = leave.
rem  2.4 GHz is the most congested band and the usual source of Wi-Fi jitter and loss.
set "NQ_WIFI_BAND=5"

rem  Driver background-scan blocking, on drivers that expose it:
rem  2 = always, 1 = only while the signal is good, 0 = leave.
set "NQ_WIFI_BGSCAN=2"

rem  Intel Wi-Fi roaming aggressiveness set to lowest: fewer roam scans, fewer spikes.
rem  Set to 0 if you use a MESH system and move between nodes while playing.
set "NQ_WIFI_LOW_ROAM=1"

rem  Wi-Fi wireless mode: restore the highest 802.11 standard the driver offers when an old
rem  tweak capped it at 802.11n, b/g or similar. "Auto" settings are left alone.
set "NQ_WIFI_MODE_FIX=1"

rem  On a PC whose internet traffic runs over Wi-Fi: stop the Windows location service. Each
rem  location request - weather, maps, time zone - makes Windows scan for nearby Wi-Fi
rem  networks, taking the radio off your channel. Apps lose location; set 0 to keep it.
set "NQ_WIFI_LOCATION_OFF=1"

rem  With Ethernet and Wi-Fi both connected, give Ethernet interface metric 10 so internet
rem  traffic always takes the cable. Wi-Fi stays as the automatic fallback.
set "NQ_PREFER_ETHERNET=1"

rem  Path test before any change: 30 timed pings to the router and 30 to the host below.
rem  Loss or jitter to the router = local link problem; only beyond it = modem, ISP or route.
set "NQ_PATH_TEST=1"
set "NQ_PING_TARGET=1.1.1.1"

rem  Stop and disable SmartByte / Killer prioritization services if they are installed.
set "NQ_SHAPERS_OFF=1"

rem  Cap BACKGROUND Windows Update downloads to N percent of measured bandwidth. 0 = leave.
set "NQ_DO_BG_PCT=50"

rem  Limit OneDrive uploads to N percent of measured upload throughput, 10-99. 0 = leave.
rem  A saturated upload is the classic trigger of home bufferbloat.
set "NQ_ONEDRIVE_UP_PCT=50"

rem  Per-interface TcpAckFrequency=1. Only helps TCP-based games such as WoW, OSRS, older MMOs.
rem  Doubles ACK packets during large TCP downloads, so leave 0 on slow-upload connections.
set "NQ_TCP_ACK1=0"

rem  Move NIC receive processing, the RSS base CPU, off CPU 0. Situational: enable only if
rem  LatencyMon or xperf shows CPU 0 already overloaded with ISR and DPC work.
set "NQ_RSS_OFF_CPU0=0"

rem  Upload cap in kbit/s for the bulk sync apps listed below. Use about 70 percent of your
rem  measured upload to stop cloud sync from bloating the modem upload queue. 0 = no cap.
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
echo    NetLatency Tuner v3 - in-game ping, jitter, lag spikes, packet loss, bufferbloat
echo  ==========================================================================================
if "%NQ_DRYRUN%"=="1" echo    DRY RUN: every change is reported and nothing is modified.
echo    Changed adapters are restarted at the end: expect a 5-15 second disconnect.
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
call :NETSH "int tcp set global rsc=disabled" "TCP Receive Segment Coalescing off - no batching delay on TCP game and voice streams"
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
call :NETSH "int udp set global uro=disabled" "UDP Receive Offload off - Win11 24H2+ NICs stop merging game datagrams"
:NQ_URO_DONE

echo(
echo  -- [2/3] Throttling and background-traffic policy
call :REG "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" REG_DWORD 0xffffffff "MMCSS network throttling off - no 10 packets/ms cap on non-media traffic while audio plays"
call :REG "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" "Do not use NLA" REG_SZ 1 "QoS DSCP policies enforced on non-domain PCs"
call :REG "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" REG_DWORD 0 "Delivery Optimization P2P off - PC stops seeding updates over your uplink"
if not "%NQ_DO_BG_PCT%"=="0" call :REG "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DOPercentageMaxBackgroundBandwidth" REG_DWORD "%NQ_DO_BG_PCT%" "Background Windows Update downloads capped at %NQ_DO_BG_PCT% percent of measured bandwidth"


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
echo    Verify with waveform.com/tools/bufferbloat - the loaded-latency numbers - plus a
echo    10-minute ping to your game server while something downloads. Spikes and loss matter
echo    far more than the idle average.
echo    Run it again after the reboot: the path test and loss counters show whether the drops
echo    are gone, and whether any that remain start at the router or beyond it.
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
$script:NqLp       = [Environment]::ProcessorCount
$script:NqViaWifi  = $false
$script:NqEthUp    = $false

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
$PowerKeys    = @('*EEE','EEELinkAdvertisement','AdvancedEEE','EnableGreenEthernet','GigaLite',
                  'PowerSavingMode','AutoDisableGigabit','SipsEnabled','ULPMode','*SelectiveSuspend')
$PowerNames   = '(?i)green|energy.?eff|power.?sav|\bEEE\b|ASPM|idle power|low.?power|battery|selective suspend|ultra low'
$PowerExclude = '(?i)wake|\bWOL\b|WoWLAN|shutdown|MIMO|SMPS'

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

# Scores the 802.11 standards named in a wireless-mode choice, so "802.11a/b/g/n/ac/ax"
# outranks "802.11ac" and "Dual Band 802.11a/b/g" outranks "802.11b/g".
function Get-WifiStdScore ([string]$text) {
    $rank = @{ 'b' = 1; 'a' = 2; 'g' = 3; 'n' = 4; 'ac' = 5; 'ax' = 6; 'be' = 7 }
    $score = 0
    foreach ($m in [regex]::Matches($text, '(?i)802\.11\s*([a-z]+(?:\s*/\s*[a-z]+)*)')) {
        foreach ($part in ($m.Groups[1].Value -split '/')) {
            $k = $part.Trim().ToLowerInvariant()
            if ($rank.ContainsKey($k)) { $score += $rank[$k] }
        }
    }
    return $score
}

# 100 Mbps hardware: named Fast Ethernet, or a speed list that tops out at 100 Mbps.
# Driver-reported link speed is not trusted: some USB 2.0 adapters report 1 Gbps or more.
function IsFastEthernet ($n) {
    if ([string]$n.InterfaceDescription -match 'Fast Ethernet|10/100(?!0)') { return $true }
    foreach ($kw in @('*SpeedDuplex', 'ConnectionType', 'SpeedDuplex')) {
        $p = $Cache[$n.Name][$kw]
        if ((-not $p) -or (-not $p.ValidDisplayValues)) { continue }
        $all = (@($p.ValidDisplayValues) -join '|')
        if (($all -match '100') -and ($all -notmatch '1000|Gbps|Gigabit|1\.0 ?G|2\.5 ?G|5 ?G|10 ?G')) { return $true }
    }
    return $false
}

# Timed pings with the .NET Ping class, 100 ms apart. Jitter is the mean difference between
# consecutive round trips, the way RFC 3550 describes interarrival jitter.
function Measure-NqPath ([string]$target, [int]$count) {
    $pinger = New-Object System.Net.NetworkInformation.Ping
    $opts = New-Object System.Net.NetworkInformation.PingOptions(64, $true)
    $data = New-Object byte[] 32
    $rtts = New-Object System.Collections.Generic.List[double]
    $lost = 0
    try {
        for ($i = 0; $i -lt $count; $i++) {
            $clock = [Diagnostics.Stopwatch]::StartNew()
            $ok = $false
            try {
                $reply = $pinger.Send($target, 1000, $data, $opts)
                if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) { $rtts.Add([double]$reply.RoundtripTime); $ok = $true }
            } catch { }
            if (-not $ok) { $lost++ }
            $pause = 100 - [int]$clock.ElapsedMilliseconds
            if ($pause -gt 0) { Start-Sleep -Milliseconds $pause }
        }
    } finally { $pinger.Dispose() }
    return (Get-NqPathStats $rtts.ToArray() $lost $count)
}

function Get-NqPathStats ([double[]]$rtts, [int]$lost, [int]$count) {
    $recv = $rtts.Count
    $o = [pscustomobject]@{ Sent = $count; Received = $recv; Lost = $lost; LossPct = 0.0; Min = 0.0; Avg = 0.0; Max = 0.0; Jitter = 0.0 }
    if ($count -gt 0) { $o.LossPct = [math]::Round(100.0 * $lost / $count, 1) }
    if ($recv -eq 0) { return $o }
    $m = $rtts | Measure-Object -Minimum -Maximum -Average
    $o.Min = [math]::Round([double]$m.Minimum, 1)
    $o.Max = [math]::Round([double]$m.Maximum, 1)
    $o.Avg = [math]::Round([double]$m.Average, 1)
    if ($recv -gt 1) {
        $sum = 0.0
        for ($i = 1; $i -lt $recv; $i++) { $sum += [math]::Abs($rtts[$i] - $rtts[$i - 1]) }
        $o.Jitter = [math]::Round($sum / ($recv - 1), 1)
    }
    return $o
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
$flags = 0; $wifiUp = $false; $ethUp = $false
foreach ($n in $Nics) {
    $wifi = IsWifi $n
    if (-not $wifi) {
        # Checked even while unplugged, so a slow spare dongle is caught before it is used.
        if (IsUsb $n) {
            Warn ($n.Name + ': USB network adapter - every packet crosses the USB bus in scheduled bulk transfers, adding latency and jitter an onboard or PCIe port does not have')
            $flags++
        }
        # Intel I225-V steppings B1 and B2 (PCI revision 01 and 02) drop the link and lose
        # packets at 2.5 Gbps; Intel fixed it in the B3 stepping and the I226.
        if (([string]$n.PnPDeviceID -match 'VEN_8086&DEV_15F3&') -and ([string]$n.PnPDeviceID -match 'REV_0[12]')) {
            Warn ($n.Name + ': Intel I225-V early stepping (B1/B2) - known for link drops and packet loss at 2.5 Gbps. Energy-Efficient Ethernet is turned off below; the newest Intel driver, or a 1 Gbps link, avoids the rest')
            $flags++
        }
        if (IsFastEthernet $n) {
            Warn ($n.Name + ': 100 Mbps Fast Ethernet hardware - downloads faster than 100 Mbps queue at the router port feeding this PC, which shows up as ping spikes and loss while anything downloads. A gigabit port or USB 3 gigabit adapter removes this bottleneck')
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
        $w     = @(Read-Nq ('Reading Wi-Fi link status: ' + $n.Name) { $result = @(& ($env:NQ_BIN + '\netsh.exe') wlan show interfaces 2>&1); if ($LASTEXITCODE -ne 0) { throw ('NETSH returned exit code ' + $LASTEXITCODE) }; $result })
        $sig   = $w | Select-String -Pattern '^\s*Signal\s*:\s*(\d+)\s*%' | Select-Object -First 1
        $band  = $w | Select-String -Pattern '^\s*Band\s*:\s*(.+?)\s*$'   | Select-Object -First 1
        $chan  = $w | Select-String -Pattern '^\s*Channel\s*:\s*(\d+)'    | Select-Object -First 1
        $radio = $w | Select-String -Pattern '^\s*Radio type\s*:\s*(\S+)' | Select-Object -First 1
        if ($sig -and ([int]$sig.Matches[0].Groups[1].Value -lt 60)) {
            Warn ($n.Name + ': signal ' + $sig.Matches[0].Groups[1].Value + ' percent - weak links retransmit constantly, which shows up as jitter and loss')
            $flags++
        }
        $on24 = $false
        if ($band)     { $on24 = ($band.Matches[0].Groups[1].Value -match '2\.4') }
        elseif ($chan) { $on24 = ([int]$chan.Matches[0].Groups[1].Value -le 14) }
        if ($on24) {
            Warn ($n.Name + ': connected on 2.4 GHz - the most congested band; use 5 or 6 GHz if the router offers it')
            $flags++
            # Bluetooth shares 2.4 GHz, and combo cards share one antenna between the two radios.
            $bt = @(Probe { Get-PnpDevice -Class Bluetooth -PresentOnly -Status OK -ErrorAction Stop })
            if ($bt.Count -gt 0) {
                Info ($n.Name + ': a Bluetooth radio is active - Bluetooth headsets and controllers share the 2.4 GHz band, and combo cards share one antenna, so the Wi-Fi link gets less airtime. On 5 or 6 GHz the two no longer collide')
            }
        }
        if ($radio -and ($radio.Matches[0].Groups[1].Value -match '^802\.11[abgn]$')) {
            Warn ($n.Name + ': connected with ' + $radio.Matches[0].Groups[1].Value + ' - a legacy Wi-Fi standard without OFDMA scheduling; latency under load is far worse than 802.11ac or ax')
            $flags++
        }
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
        $sd = $Cache[$n.Name]['*SpeedDuplex']
        if (-not $sd) { $sd = $Cache[$n.Name]['ConnectionType'] }
        if ($sd -and ([string](@($sd.RegistryValue)[0]) -ne '0')) {
            Warn ($n.Name + ': Speed & Duplex forced to "' + $sd.DisplayValue + '" - forced vs auto mismatch causes duplex errors and loss; use Auto unless deliberate')
            $flags++
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
$script:NqEthUp = $ethUp
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

# Path test: timed pings to the router, then to an internet host. Loss or jitter that starts at
# the router is a local-link fault (Wi-Fi or cable); loss that only appears beyond it is the
# modem, the ISP or the route. Read only, so it also runs in a dry run.
if ((Flag 'NQ_PATH_TEST') -and $route) {
    $viaWifi = $false
    $viaPhys = $false
    if ($via) {
        $viaPhys = (@($Nics | Where-Object { $_.ifIndex -eq $via.ifIndex }).Count -gt 0)
        $viaWifi = IsWifi $via
    }
    $targets = @()
    if ($viaPhys -and $route.NextHop -and ($route.NextHop -ne '0.0.0.0')) { $targets += ,@('router', $route.NextHop) }
    $pt = ([string]$env:NQ_PING_TARGET).Trim()
    if ($pt) { $targets += ,@('internet', $pt) }
    $res = @{}
    foreach ($t in $targets) {
        $r = Probe { Measure-NqPath $t[1] 30 }
        if (-not $r) { Info ('Path test to ' + $t[1] + ' could not run'); continue }
        $res[$t[0]] = $r
        if ($r.Received -eq 0) { Info ('Path test: ' + $t[1] + ' (' + $t[0] + ') did not answer any ping - it may block ICMP'); continue }
        Info ('Path test, ' + $t[0] + ' ' + $t[1] + ': ' + $r.LossPct + ' percent loss, ' + $r.Min + '/' + $r.Avg + '/' + $r.Max + ' ms min/avg/max, jitter ' + $r.Jitter + ' ms')
    }
    $gw = $res['router']
    $net = $res['internet']
    if ($gw -and ($gw.Received -gt 0)) {
        $jLimit = 2; $mLimit = 10
        if ($viaWifi) { $jLimit = 10; $mLimit = 50 }
        if ($gw.Lost -gt 0) {
            Warn ('Packet loss between this PC and the router (' + $gw.LossPct + ' percent) - the local link is dropping packets: Wi-Fi signal or interference, or a cable, port or adapter fault. No internet-side setting can fix it')
            $flags++
        } elseif (($gw.Jitter -gt $jLimit) -or ($gw.Max -gt $mLimit)) {
            Warn ('Unstable link to the router: jitter ' + $gw.Jitter + ' ms, worst ping ' + $gw.Max + ' ms - the delay is added before your packets even leave the house')
            $flags++
        }
        if ($net -and ($net.Received -gt 0) -and ($gw.Lost -eq 0) -and ($net.LossPct -gt 3)) {
            Warn ('Loss appears only beyond the router (' + $net.LossPct + ' percent to ' + $pt + ') - the modem, the ISP or the route. If it persists on a quiet line, report it to the ISP with these numbers')
            $flags++
        }
    }
    if ($net -and ($net.Received -gt 0)) {
        Info 'The path test measures an idle line. Bufferbloat only shows under load: test it at waveform.com/tools/bufferbloat'
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

$dc = Probe { (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' -Name DisabledComponents -ErrorAction Stop).DisabledComponents }
if (($null -ne $dc) -and (([int64]$dc -band 0xFF) -eq 0xFF)) {
    Info 'IPv6 is fully disabled by a registry tweak (DisabledComponents 0xFF). Microsoft supports 0x20 - prefer IPv4 - instead; full disabling breaks IPv6 paths some platforms use.'
}
if (($flags -eq 0) -and ($script:NQ_Failed -eq $healthFailCount)) { Same 'no physical-layer or path red flags detected' }

# ------------------------------------------------------------------------------------------
Head 'NIC drivers: power saving off, receive batching off, receive ring maxed, Wi-Fi radio tuned'
# ------------------------------------------------------------------------------------------
foreach ($n in $Nics) {
    $wifi = IsWifi $n
    $kind = 'Ethernet'; if ($wifi) { $kind = 'Wi-Fi' }
    if (IsUsb $n) { $kind += ' over USB' }
    Doing 'ADAPTER' ($n.Name + ' [' + $kind + ' | ' + $n.InterfaceDescription + ']')
    $script:NqMissing.Clear()

    # Energy-Efficient Ethernet (802.3az) and vendor green / low-power link modes.
    # The PHY drops into Low Power Idle between packets; every wake adds delay, and on several
    # Intel I219/I225 and Realtek chips it triggers periodic spikes or full link renegotiation.
    # Keywords: standard *EEE, Intel EEELinkAdvertisement/SipsEnabled/ULPMode,
    # Realtek AdvancedEEE/EnableGreenEthernet/GigaLite/PowerSavingMode/AutoDisableGigabit,
    # USB adapters *SelectiveSuspend.
    foreach ($kw in $PowerKeys) { Set-Adv $n $kw '0' }
    # The same modes under vendor keywords the list does not know, found by display name.
    foreach ($p in @($Cache[$n.Name].Values)) {
        $dn = [string]$p.DisplayName
        if ((-not $dn) -or ($dn -notmatch $PowerNames) -or ($dn -match $PowerExclude)) { continue }
        if ($PowerKeys -contains [string]$p.RegistryKeyword) { continue }
        Set-AdvByText $n ([string]$p.RegistryKeyword) '^(Disabled?|Off)$'
    }

    # Receive batching: every mechanism below holds packets to save CPU or power.
    Set-Adv $n '*PacketCoalescing' '0'
    $imMode = Num 'NQ_INTMOD_OFF' 0
    if (($imMode -ge 2) -or (($imMode -eq 1) -and ($script:NqLp -ge 6))) { Set-Adv $n '*InterruptModeration' '0' }
    elseif (($imMode -eq 1) -and $Cache[$n.Name]['*InterruptModeration']) {
        Skip ($n.Name + ': interrupt moderation left at the driver default on a ' + $script:NqLp + '-thread CPU, so extra network interrupts never compete with game threads for frame time')
    }
    $rsc = Probe { Get-NetAdapterRsc -Name $n.Name -ErrorAction Stop }
    if (-not $rsc) { Skip ($n.Name + ': the driver has no Receive Segment Coalescing to turn off') }
    elseif (-not ($rsc.IPv4Enabled -or $rsc.IPv6Enabled)) { Same 'Receive Segment Coalescing (adapter) off' }
    else {
        Doing 'NIC' ($n.Name + ': disabling adapter Receive Segment Coalescing')
        try {
            Change { Disable-NetAdapterRsc -Name $n.Name -NoRestart -ErrorAction Stop }
            $Restart[$n.Name] = $true
            Ok 'Receive Segment Coalescing (adapter): on -> off'
        } catch { Failed ($n.Name + ': disabling Receive Segment Coalescing: ' + $_.Exception.Message) }
    }

    # Receive capacity: packet loss at the PC happens when the receive ring overflows during
    # bursts (downloads, voice, game state floods). A larger ring only holds packets when the
    # CPU is behind, so it adds no latency in the normal case.
    Set-Adv $n '*RSS' '1'
    if (Flag 'NQ_RX_MAX') { Set-AdvEdge $n '*ReceiveBuffers' -Max }

    # Standard 1514-byte frames. Jumbo frames through consumer switches/routers that do not
    # support them are dropped silently.
    Set-AdvEdge $n '*JumboPacket'

    # Adaptive Inter-Frame Spacing widens the gap between transmitted frames to ride out
    # collisions, which only exist on half-duplex links. On full duplex it only adds delay.
    if (-not $wifi) { Set-Adv $n 'AdaptiveIFS' '0' }

    if ($wifi -and (Flag 'NQ_WIFI_TUNE')) {
        # Spatial-multiplexing power save shuts down receive chains; waking them costs airtime.
        Set-AdvByText $n 'MIMOPowerSaveMode' 'No SMPS'
        # Unscheduled Automatic Power Save Delivery buffers downlink frames at the AP.
        Set-Adv $n 'uAPSDSupport' '0'
        # Transmit power at the driver maximum: weak uplink frames are the ones retried and lost.
        $tx = Find-Kw $n @('IbssTxPower') 'Transmit Power|Tx Power'
        if ($tx) { Set-AdvEdge $n $tx -Max } else { Skip ($n.Name + ': no transmit power control exposed') }
    }
    if ($wifi) {
        # Band preference: 2.4 GHz is shared with every neighbour, Bluetooth and microwave oven.
        $bandPref = Num 'NQ_WIFI_BAND' 0
        if (($bandPref -eq 5) -or ($bandPref -eq 6)) {
            $pb = Find-Kw $n @('RoamingPreferredBandType') 'Preferred Band'
            if (-not $pb) { Skip ($n.Name + ': no preferred band control exposed') }
            elseif (($bandPref -eq 6) -and (Test-Offers $n $pb 'Prefer 6')) { Set-AdvByText $n $pb 'Prefer 6' }
            else { Set-AdvByText $n $pb 'Prefer 5' }
        }
        # Background scans take the radio off-channel for 50-300 ms: the classic periodic spike.
        $bgMode = Num 'NQ_WIFI_BGSCAN' 0
        if ($bgMode -gt 0) {
            $bs = Find-Kw $n @() 'BG Scan|Background Scan'
            if (-not $bs) { Skip ($n.Name + ': this driver exposes no background-scan blocking control') }
            elseif ($bgMode -ge 2) { Set-AdvByText $n $bs 'Always' }
            else { Set-AdvByText $n $bs 'Good RSSI' }
        }
        # Wireless mode capped by an old tweak at 802.11n, b/g or legacy-only: without 802.11ac
        # and ax the link loses OFDMA scheduling and wide channels, and latency under load climbs.
        if (Flag 'NQ_WIFI_MODE_FIX') {
            foreach ($wm in @($Cache[$n.Name].Values | Where-Object { ([string]$_.DisplayName -match '(?i)wireless mode') -and ([string]$_.DisplayName -notmatch '(?i)ad ?hoc|ibss') })) {
                $wd = @()
                if ($wm.ValidDisplayValues) { $wd = @($wm.ValidDisplayValues) }
                $wr = @(ValidOf $wm)
                if ($wd.Count -eq 0) { continue }
                $wCur = DispOf $wm ([string](@($wm.RegistryValue)[0]))
                if ($wCur -match '(?i)auto') { Same ([string]$wm.DisplayName + ' = ' + $wCur); continue }
                $best = -1; $bestRv = $null
                for ($i = 0; ($i -lt $wd.Count) -and ($i -lt $wr.Count); $i++) {
                    $sc = Get-WifiStdScore ([string]$wd[$i])
                    if ($sc -gt $best) { $best = $sc; $bestRv = [string]$wr[$i] }
                }
                if (($null -eq $bestRv) -or ($best -le (Get-WifiStdScore $wCur))) { Same ([string]$wm.DisplayName + ' = ' + $wCur); continue }
                Set-Adv $n ([string]$wm.RegistryKeyword) $bestRv
            }
        }
    }
    if ($wifi -and (Flag 'NQ_WIFI_LOW_ROAM')) {
        # Each roam-candidate scan takes the radio off-channel: classic 100-300 ms spike.
        # Intel calls it Roaming Aggressiveness; Realtek and MediaTek call it Roaming Sensitivity.
        $rk = Find-Kw $n @('RoamAggressiveness') '(?i)roam(ing)?\s*(aggressiveness|sensitivity)'
        if (-not $rk) { Missing 'RoamAggressiveness' }
        elseif ($rk -eq 'RoamAggressiveness') { Set-AdvEdge $n 'RoamAggressiveness' }
        elseif (Test-Offers $n $rk '(?i)lowest') { Set-AdvByText $n $rk '(?i)lowest' }
        elseif (Test-Offers $n $rk '(?i)^\s*(\d\.\s*)?low\b') { Set-AdvByText $n $rk '(?i)^\s*(\d\.\s*)?low\b' }
        else { Skip ($n.Name + ': ' + $rk + ' offers no Low or Lowest setting') }
    }
    if ((-not $wifi) -and (Flag 'NQ_NIC_POWER_OFF')) { Set-NicPower $n }
    if ($script:NqMissing.Count -gt 0) {
        Write-Host ('     [SKIP] ' + $n.Name + ': ' + $script:NqMissing.Count + ' settings not exposed by this driver - ' + ($script:NqMissing -join ', ')) -ForegroundColor DarkGray
    }
}

# ------------------------------------------------------------------------------------------
Head 'TCP/IP offload engine (global)'
# ------------------------------------------------------------------------------------------
$g = Read-Nq 'Reading global offload settings' { Get-NetOffloadGlobalSetting }
if ($g) {
    if ([string]$g.PacketCoalescingFilter -eq 'Disabled') { Same 'Packet Coalescing Filter off' }
    else {
        Doing 'OFFLOAD' 'Setting PacketCoalescingFilter = Disabled'
        try { Change { Set-NetOffloadGlobalSetting -PacketCoalescingFilter Disabled -ErrorAction Stop }; Ok 'Packet Coalescing Filter: on -> off (NIC stops holding filtered receives)' }
        catch { Failed ('Packet Coalescing Filter: ' + $_.Exception.Message) }
    }
    if ([string]$g.ReceiveSegmentCoalescing -eq 'Disabled') { Same 'Receive Segment Coalescing (global) off' }
    else {
        Doing 'OFFLOAD' 'Setting ReceiveSegmentCoalescing = Disabled'
        try { Change { Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Disabled -ErrorAction Stop }; Ok 'Receive Segment Coalescing (global): on -> off' }
        catch { Failed ('Global Receive Segment Coalescing: ' + $_.Exception.Message) }
    }
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
if (Flag 'NQ_PREFER_ETHERNET') {
    Head 'Internet path: Ethernet over Wi-Fi'
    if (-not ($script:NqViaWifi -and $script:NqEthUp)) {
        Same 'internet traffic is not taking Wi-Fi while a cable is connected'
    } else {
        # A manual metric of 10 beats every automatic metric Windows gives Wi-Fi (25 and up),
        # so the cable wins whenever it is connected and Wi-Fi takes over when it is not.
        foreach ($n in @($Nics | Where-Object { (-not (IsWifi $_)) -and ($_.Status -eq 'Up') })) {
            foreach ($af in @('IPv4', 'IPv6')) {
                $ipi = Probe { Get-NetIPInterface -InterfaceIndex $n.ifIndex -AddressFamily $af -ErrorAction Stop }
                if (-not $ipi) { continue }
                if (([int]$ipi.InterfaceMetric -le 10) -and ([string]$ipi.AutomaticMetric -eq 'Disabled')) { Same ($n.Name + ': ' + $af + ' interface metric ' + $ipi.InterfaceMetric); continue }
                Doing 'ROUTE' ($n.Name + ': ' + $af + ' interface metric ' + $ipi.InterfaceMetric + ' -> 10')
                try {
                    Change { Set-NetIPInterface -InterfaceIndex $n.ifIndex -AddressFamily $af -InterfaceMetric 10 -ErrorAction Stop }
                    Ok ($n.Name + ': ' + $af + ' metric 10 - internet traffic takes the cable whenever it is connected')
                } catch { Failed ($n.Name + ': ' + $af + ' interface metric: ' + $_.Exception.Message) }
            }
        }
    }
}

# ------------------------------------------------------------------------------------------
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
    $vdscp = Num 'NQ_VOICE_DSCP' 34
    if (($vdscp -lt 0) -or ($vdscp -gt 63)) { $vdscp = 34 }
    $cap = Num 'NQ_UPCAP_KBPS' 0

    # The complete wanted set. Policies this script owns (NQ-*) that are no longer wanted, or
    # differ, are replaced; identical ones are left alone so re-runs change nothing.
    $want  = @{}
    $order = New-Object System.Collections.Generic.List[string]
    $plan  = @()
    if (Flag 'NQ_DSCP')       { $plan += ,@([string]$env:NQ_GAMES,     'NQ-DSCP-',  $dscp,  [uint64]0) }
    if (Flag 'NQ_DSCP_VOICE') { $plan += ,@([string]$env:NQ_VOICE,     'NQ-VOICE-', $vdscp, [uint64]0) }
    if ($cap -gt 0)           { $plan += ,@([string]$env:NQ_BULK_APPS, 'NQ-CAP-',   -1,     ([uint64]$cap * 1000)) }
    foreach ($row in $plan) {
        foreach ($exe in @(($row[0] -split ';') | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
            $pname = $row[1] + $exe
            if ($want.ContainsKey($pname)) { continue }
            $want[$pname] = [pscustomobject]@{ Exe = $exe; Dscp = [int]$row[2]; Rate = [uint64]$row[3] }
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
            else { $match = $match -and ([int]$h.DSCPValue -eq $w.Dscp) -and ([string]$h.IPProtocol -eq 'Both') }
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
                Doing 'QOS' ('Marking ' + $w.Exe + ': DSCP = ' + $w.Dscp + ', UDP + TCP, all profiles')
                Change { New-NetQosPolicy -Name $pname -AppPathNameMatchCondition $w.Exe -IPProtocolMatchCondition Both -DSCPAction ([sbyte]$w.Dscp) -NetworkProfile All -ErrorAction Stop | Out-Null }
                Ok ($w.Exe + ': DSCP = ' + $w.Dscp)
            }
            $made++
        } catch { Failed ('QoS policy ' + $pname + ': ' + $_.Exception.Message) }
    }
    if ($kept.Count -gt 0) { Same ([string]$kept.Count + ' QoS policies already in place') }
    Say ('     [INFO] ' + [string]($kept.Count + $made) + ' of ' + $order.Count + ' QoS policies active - games DSCP ' + $dscp + ', voice apps DSCP ' + $vdscp + ', UDP + TCP, every network profile')
}

# ------------------------------------------------------------------------------------------
Head 'Cloud-sync upload limit  (a saturated upload is the classic bufferbloat trigger)'
# ------------------------------------------------------------------------------------------
$odPct = Num 'NQ_ONEDRIVE_UP_PCT' 0
if ($odPct -le 0) { Skip 'OneDrive upload limit turned off in the config' }
else {
    if ($odPct -lt 10) { $odPct = 10 }
    if ($odPct -gt 99) { $odPct = 99 }
    $odPaths = @(($env:ProgramFiles + '\Microsoft OneDrive\OneDrive.exe'), (${env:ProgramFiles(x86)} + '\Microsoft OneDrive\OneDrive.exe'))
    $odPaths += @(Get-ChildItem -Path ($env:SystemDrive + '\Users\*\AppData\Local\Microsoft\OneDrive\OneDrive.exe') -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    $odFound = (@($odPaths | Where-Object { $_ -and (Test-Path -LiteralPath $_) }).Count -gt 0)
    if (-not $odFound) { Skip 'OneDrive is not installed' }
    else {
        $odKey = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
        $odCur = Probe { (Get-ItemProperty -LiteralPath $odKey -Name AutomaticUploadBandwidthPercentage -ErrorAction Stop).AutomaticUploadBandwidthPercentage }
        if ($odCur -eq $odPct) { Same ('OneDrive uploads limited to ' + $odPct + ' percent of throughput') }
        else {
            Doing 'POLICY' ('Limiting OneDrive uploads to ' + $odPct + ' percent of measured upload throughput')
            try {
                Change {
                    if (-not (Test-Path -LiteralPath $odKey)) { New-Item -Path $odKey -Force -ErrorAction Stop | Out-Null }
                    New-ItemProperty -LiteralPath $odKey -Name AutomaticUploadBandwidthPercentage -PropertyType DWord -Value $odPct -Force -ErrorAction Stop | Out-Null
                }
                Ok ('OneDrive upload limited to ' + $odPct + ' percent of throughput - sync can no longer fill the modem upload queue')
            } catch { Failed ('OneDrive upload limit: ' + $_.Exception.Message) }
        }
    }
}

# ------------------------------------------------------------------------------------------
if (Flag 'NQ_SHAPERS_OFF') {
    Head 'Third-party traffic shapers known to add latency and loss'
    $serviceFailCount = $script:NQ_Failed
    $svcs = @(Read-Nq 'Reading installed third-party traffic shapers' { Get-Service | Where-Object {
        $_.DisplayName -match 'SmartByte|Killer.*(Network|Analytic|Bandwidth|Smart|Intelligence|Prioriti)'
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
$show = @('*EEE','EEELinkAdvertisement','EnableGreenEthernet','GigaLite','PowerSavingMode','AdvancedEEE',
          '*InterruptModeration','*PacketCoalescing','*ReceiveBuffers','*JumboPacket','*RSS',
          '*FlowControl','FlowControl','*SpeedDuplex','ConnectionType','MIMOPowerSaveMode','uAPSDSupport',
          'RoamAggressiveness','RoamingPreferredBandType','IbssTxPower','AdaptiveIFS')
foreach ($n in $Nics) {
    Say ('     > ' + $n.Name)
    Read-Nq ('Reading final driver values: ' + $n.Name) { Get-NetAdapterAdvancedProperty -Name $n.Name } |
        Where-Object {
            $dn = [string]$_.DisplayName
            ($show -contains $_.RegistryKeyword) -or (($dn -match $PowerNames) -and ($dn -notmatch $PowerExclude)) -or ($dn -match 'BG Scan|Background Scan|Wireless Mode|Roaming Sensitivity')
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
