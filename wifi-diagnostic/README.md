# Diagnostic de lenteur Wi-Fi

Scripts **en lecture seule** (ils ne modifient ni l'ordinateur ni le routeur).
Ils produisent un fichier `rapport-wifi.txt`.

- Windows : `powershell -ExecutionPolicy Bypass -File diagnostic-wifi.ps1`
- macOS / Linux : `bash diagnostic-wifi.sh`

Lance-le idéalement **à l'endroit où le Wi-Fi est lent**, puis une seconde fois
**à côté du routeur** : la comparaison dit si le problème vient de la portée.

## Lire le rapport

| Mesure | Normal | Problème probable |
|---|---|---|
| Signal (RSSI) | > -65 dBm / > 70 % | < -75 dBm : trop loin, murs, interférences |
| Bande | 5 GHz ou 6 GHz | 2,4 GHz : lent et encombré |
| Débit négocié (Tx/Rx rate) | > 300 Mbit/s | < 100 : signal faible ou vieille norme |
| Ping vers le routeur | < 5 ms, 0 % perte | > 20 ms ou pertes : problème **Wi-Fi** |
| Ping vers Internet | < 30 ms | élevé alors que le routeur est OK : problème **box/FAI** |
| Ping sous charge | +< 30 ms | +100 ms ou plus : **bufferbloat** → activer SQM/QoS |
| DNS | < 50 ms | > 200 ms : changer de DNS (1.1.1.1, 9.9.9.9) |
| Réseaux voisins sur ton canal | 0–2 | beaucoup : changer de canal (2,4 GHz : 1, 6 ou 11) |
| Appareils | ceux que tu reconnais | appareil inconnu : changer le mot de passe Wi-Fi (WPA2/WPA3) |

## À vérifier dans l'interface du routeur (souvent http://192.168.1.1 ou http://192.168.1.254)

1. Mise à jour du firmware.
2. Largeur de canal : 80 MHz (5 GHz), 20 MHz (2,4 GHz).
3. Canal automatique ou canal le moins encombré d'après le rapport.
4. Appareils connectés : repère les gros consommateurs (téléchargements, caméras, sauvegardes cloud).
5. Désactive le mode de compatibilité 802.11b/g s'il est actif.
6. QoS / SQM activé si le test de bufferbloat est mauvais.
7. Redémarre la box si elle n'a pas redémarré depuis des semaines.
