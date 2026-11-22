# Diagnostic Wi-Fi en lecture seule (Windows). Ne modifie rien.
# Usage : clic droit > "Exécuter avec PowerShell"  ou
#         powershell -ExecutionPolicy Bypass -File diagnostic-wifi.ps1
$Out = "rapport-wifi.txt"
Start-Transcript -Path $Out -Force | Out-Null
function Section($t){ Write-Host "`n----- $t -----" }
Write-Host "=== Diagnostic Wi-Fi — $(Get-Date) ==="

Section "Routeur (passerelle)"
$GW = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Sort-Object RouteMetric | Select-Object -First 1).NextHop
Write-Host "Passerelle : $GW"

Section "Connexion Wi-Fi (signal / canal / bande / débit)"
netsh wlan show interfaces

Section "Réseaux voisins (congestion des canaux)"
netsh wlan show networks mode=bssid | Select-String "SSID|Signal|Canal|Channel|Bande|Band"

Section "Latence / pertes (30 pings)"
Write-Host "> Vers le routeur $GW"; ping -n 30 $GW | Select-Object -Last 4
Write-Host "> Vers Internet 1.1.1.1"; ping -n 30 1.1.1.1 | Select-Object -Last 4

Section "Latence sous charge (bufferbloat)"
$job = Start-Job { Invoke-WebRequest "https://speed.cloudflare.com/__down?bytes=200000000" -UseBasicParsing -TimeoutSec 15 | Out-Null }
Start-Sleep 2; ping -n 20 1.1.1.1 | Select-Object -Last 4
Stop-Job $job -ErrorAction SilentlyContinue; Remove-Job $job -Force

Section "Temps de résolution DNS"
foreach($d in "google.com","wikipedia.org","lemonde.fr"){
  $t = (Measure-Command { Resolve-DnsName $d -DnsOnly -ErrorAction SilentlyContinue | Out-Null }).TotalMilliseconds
  Write-Host ("{0} : {1:N0} ms" -f $d, $t)
}

Section "Débit descendant (fichier 50 Mo)"
$f = Join-Path $env:TEMP "wifitest.bin"
$s = Measure-Command { Invoke-WebRequest "https://speed.cloudflare.com/__down?bytes=50000000" -OutFile $f -UseBasicParsing -TimeoutSec 60 }
Write-Host ("Débit : {0:N1} Mbit/s" -f (400 / $s.TotalSeconds)); Remove-Item $f -ErrorAction SilentlyContinue

Section "Appareils connus sur le réseau (table ARP)"
$net = $GW -replace '\.\d+$',''
$tasks = 1..254 | ForEach-Object { (New-Object System.Net.NetworkInformation.Ping).SendPingAsync("$net.$_", 1000) }
try { [System.Threading.Tasks.Task]::WaitAll($tasks) } catch {}
$n = Get-NetNeighbor -AddressFamily IPv4 | Where-Object { $_.State -in "Reachable","Stale" -and $_.IPAddress -like "$net.*" }
$n | Format-Table IPAddress, LinkLayerAddress, State
Write-Host "Nombre d'appareils : $($n.Count)"

Write-Host "`n=== Fin. Rapport enregistré dans $Out ==="
Stop-Transcript | Out-Null
