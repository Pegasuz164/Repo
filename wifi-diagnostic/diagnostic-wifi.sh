#!/usr/bin/env bash
# Diagnostic Wi-Fi en lecture seule (macOS / Linux). Ne modifie rien.
# Usage : bash diagnostic-wifi.sh   -> crée rapport-wifi.txt
OUT="rapport-wifi.txt"
exec > >(tee "$OUT") 2>&1
OS="$(uname)"
echo "=== Diagnostic Wi-Fi — $(date) — $OS ==="

section(){ echo; echo "----- $1 -----"; }

# 1. Passerelle (routeur)
section "Routeur (passerelle)"
if [ "$OS" = "Darwin" ]; then GW=$(route -n get default 2>/dev/null | awk '/gateway/{print $2}')
else GW=$(ip route 2>/dev/null | awk '/^default/{print $3; exit}'); fi
echo "Passerelle : ${GW:-introuvable}"

# 2. Signal, canal, bande, débit négocié
section "Connexion Wi-Fi (signal / canal / débit)"
if [ "$OS" = "Darwin" ]; then
  system_profiler SPAirPortDataType 2>/dev/null | sed -n '/Current Network Information/,/Other Local Wi-Fi Networks/p' | head -25
  echo; echo "Réseaux voisins (congestion des canaux) :"
  system_profiler SPAirPortDataType 2>/dev/null | sed -n '/Other Local Wi-Fi Networks/,$p' | grep -E "^\s+[^ ].*:$|Channel|Signal" | head -80
else
  IF=$(iw dev 2>/dev/null | awk '/Interface/{print $2; exit}')
  echo "Interface : ${IF:-?}"
  [ -n "$IF" ] && iw dev "$IF" link 2>/dev/null
  command -v nmcli >/dev/null && { echo; echo "Réseaux voisins :"; nmcli -f IN-USE,SSID,CHAN,FREQ,SIGNAL,RATE dev wifi list 2>/dev/null; }
fi

# 3. Latence et pertes : routeur vs Internet
section "Latence / pertes (30 pings)"
[ -n "$GW" ] && { echo "> Vers le routeur $GW"; ping -c 30 -i 0.2 "$GW" 2>/dev/null | tail -2; }
echo "> Vers Internet 1.1.1.1"; ping -c 30 -i 0.2 1.1.1.1 2>/dev/null | tail -2

# 4. Bufferbloat : latence pendant un téléchargement
section "Latence sous charge (bufferbloat)"
( curl -s -o /dev/null --max-time 15 https://speed.cloudflare.com/__down?bytes=200000000 ) &
sleep 2; ping -c 20 -i 0.5 1.1.1.1 2>/dev/null | tail -1; wait

# 5. DNS
section "Temps de résolution DNS"
for d in google.com wikipedia.org lemonde.fr; do
  t=$( { /usr/bin/time -p nslookup "$d" >/dev/null; } 2>&1 | awk '/real/{print $2}')
  echo "$d : ${t}s"
done

# 6. Débit
section "Débit descendant (fichier 50 Mo)"
curl -s -o /dev/null -w "Débit : %{speed_download} octets/s\n" --max-time 30 "https://speed.cloudflare.com/__down?bytes=50000000"

# 7. Appareils sur le réseau
section "Appareils connus sur le réseau (table ARP)"
[ -n "$GW" ] && { NET=${GW%.*}; for i in $(seq 1 254); do ping -c1 -W1 "$NET.$i" >/dev/null 2>&1 & done; wait; }
arp -a 2>/dev/null | grep -v incomplete
echo "Nombre d'appareils : $(arp -a 2>/dev/null | grep -vc incomplete)"

echo; echo "=== Fin. Rapport enregistré dans $OUT ==="
