# VIOFO A329T Dashcam in Home Assistant (Livebild + Aufnahmen)

**🇩🇪 Deutsch** · [🇬🇧 English](#english)

## Problem

Die **VIOFO A329T** kann sich im **Station-Modus** mit dem Camper-WLAN verbinden. Bei unserer Firmware ist der Station-Modus aber **nach jedem Neustart weg**: Die Kamera öffnet wieder ihren eigenen Hotspot (`VIOFO_A329T_xxxx`, Kamera unter `192.168.1.254`). Für Home Assistant ist sie damit nach jeder Fahrt verschwunden.

## Lösung: Hotspot lassen, Raspberry Pi als Brücke

Die Dashcam bleibt im Hotspot-Modus. Ein Raspberry Pi (bei uns der **Pekaway VAN PI**), der per **Kabel** im Camper-Netz hängt, verbindet sich mit seinem **WLAN-Modul** mit dem Dashcam-Hotspot und leitet weiter.

```
Home Assistant ──LAN── Router ──LAN── Pi (eth0) ── Pi (wlan0) ~~WLAN~~ VIOFO-Hotspot 192.168.1.254
```

### 1. Pi mit dem Hotspot verbinden (NetworkManager)

```bash
read -s -p "Dashcam-WLAN-Passwort: " PW; echo
sudo nmcli con add type wifi ifname wlan0 con-name viofo ssid VIOFO_A329T_xxxx \
  wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$PW" \
  ipv4.never-default yes ipv4.ignore-auto-dns yes ipv4.ignore-auto-routes yes ipv6.method disabled \
  connection.autoconnect yes connection.autoconnect-priority 50 connection.autoconnect-retries 0
unset PW
sudo nmcli con up viofo
```
- `never-default`: Der Pi geht über die Dashcam **nicht** ins Internet.
- `ignore-auto-routes`: Die Dashcam verteilt per DHCP Routen in fremde 10er-Netze – ignorieren.
- Bisherige WLAN-Verbindung auf wlan0 ggf. auf `connection.autoconnect no` stellen.

### 2. Weiterleitung auf dem Pi

```bash
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/90-dashcam.conf && sudo sysctl -p /etc/sysctl.d/90-dashcam.conf
sudo apt-get install -y iptables
```
Dienst `/etc/systemd/system/dashcam-nat.service` (oneshot, `RemainAfterExit=yes`):
```
iptables -t nat -A POSTROUTING -o wlan0 -d 192.168.1.0/24 -j MASQUERADE
iptables -I FORWARD -i eth0 -o wlan0 -d 192.168.1.0/24 -j ACCEPT
iptables -I FORWARD -i wlan0 -o eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

### 3. Route im Router – nur für die Dashcam

Statische Route **`192.168.1.254/32` über die LAN-IP des Pi**.

⚠️ **Tailscale/VPN mit 192.168.1.0/24:** Läuft auf dem Router Tailscale (z. B. Teltonika/SELFSAT) und wird dort ein fremdes 192.168.1.0/24 angenommen, gewinnt dessen Tabelle 52 (Regel 5270) vor der normalen Routing-Tabelle. Dann zusätzlich eine Regel mit höherer Priorität:
```bash
ip rule add to 192.168.1.254/32 lookup main priority 5200
uci add network rule; uci set network.@rule[-1].dest='192.168.1.254/32'
uci set network.@rule[-1].lookup='main'; uci set network.@rule[-1].priority='5200'; uci commit network
```
Prüfen: `ip route get 192.168.1.254 from <HA-IP> iif br-lan` muss über den Pi gehen, nicht über `tailscale0`. **Nie das ganze /24 umleiten.**

### 4. Home Assistant

- Generic Camera bzw. WebRTC-Karte: `rtsp://192.168.1.254`
- Aufnahmen: Der Pi reicht HTTP unter seiner eigenen IP durch (geht dann auch über Tailscale):
  ```
  iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8254 -j DNAT --to-destination 192.168.1.254:80
  ```
  → `http://<Pi-IP>:8254/DCIM/Movie/` (Achtung: Die Dateiliste enthält Löschen-Links `?del=1`).

---

<a name="english"></a>
## 🇬🇧 English

### Problem

The **VIOFO A329T** can join the camper Wi-Fi in **station mode**, but on our firmware station mode is **lost after every reboot**: the camera opens its own hotspot again (`VIOFO_A329T_xxxx`, camera at `192.168.1.254`). For Home Assistant it disappears after every drive.

### Solution: keep the hotspot, use a Raspberry Pi as bridge

The dashcam stays in hotspot mode. A Raspberry Pi (ours is the **Pekaway VAN PI**) that is **wired** to the camper LAN joins the dashcam hotspot with its **Wi-Fi** and forwards traffic.

1. **Join the hotspot** with NetworkManager (see commands above): `never-default` (no internet via the dashcam), `ignore-auto-routes` (the dashcam pushes routes to foreign 10.x networks), autoconnect with infinite retries.
2. **Forwarding on the Pi:** enable `ip_forward`, install `iptables`, and a oneshot systemd service with the MASQUERADE and FORWARD rules shown above.
3. **Router route – dashcam only:** static route **`192.168.1.254/32` via the Pi's LAN IP**. ⚠️ If Tailscale on the router accepts a foreign `192.168.1.0/24` (table 52, rule 5270 wins over the main table), add the priority-5200 rule shown above. Never redirect the whole /24.
4. **Home Assistant:** Generic Camera / WebRTC card `rtsp://192.168.1.254`; recordings via a DNAT on the Pi (`<Pi-IP>:8254` → `192.168.1.254:80`), which also works over Tailscale. Note: the file list contains delete links (`?del=1`).
