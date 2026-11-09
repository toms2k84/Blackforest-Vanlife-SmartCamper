# Pekaway VAN PI: Selbstheilung bei hängender SD-Karte

**🇩🇪 Deutsch** · [🇬🇧 English](#english)

## Was passiert ist

Die mitgelieferte SD-Karte des **VAN PI CORE PRO** lieferte plötzlich `Input/output error`, das Dateisystem wurde schreibgeschützt. **Node-RED lief weiter und sendete Sensorwerte, aber kein Relais schaltete mehr** – Node-RED startet dafür kleine Programme, und die ließen sich nicht mehr laden. Im Camper ging kein Licht. Ein **harter Neustart** (Strom kurz trennen) behob es sofort.

## Lösung: Hardware-Watchdog + Gesundheitscheck

**1. Hardware-Watchdog** (Neustart, wenn das ganze System hängt):
```bash
sudo mkdir -p /etc/systemd/system.conf.d
printf '[Manager]\nRuntimeWatchdogSec=15\nRebootWatchdogSec=2min\n' | sudo tee /etc/systemd/system.conf.d/watchdog.conf
```

**2. Gesundheitscheck** [`vanpi-health.sh`](vanpi-health.sh) als Dienst [`vanpi-health.service`](vanpi-health.service): prüft alle 20 s, ob ein Programm startet und das Dateisystem nicht schreibgeschützt ist – über `/proc/mounts`, **ohne selbst auf die Karte zu schreiben**. Nach 4 Fehlschlägen in Folge startet er den Pi **direkt über den Kernel** neu (`/proc/sysrq-trigger`, nur Bash-Bordmittel – funktioniert auch, wenn keine Programme mehr laden). In den ersten 10 Minuten nach dem Start greift er nicht ein (keine Neustart-Schleife bei wirklich toter Karte).

```bash
sudo install -m 755 vanpi-health.sh /usr/local/bin/
sudo install -m 644 vanpi-health.service /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now vanpi-health.service
```

> Erste Version mit `Type=notify` + `systemd-notify`: blieb auf „activating“ hängen und hätte im Fehlerfall ohnehin nicht funktioniert, weil `systemd-notify` selbst ein Programm ist. Deshalb die sysrq-Variante.

## Außerdem

- **log2ram** ist beim VAN PI schon aktiv (Logs im RAM) – gut gegen Kartenverschleiß.
- **Komplettes Image** der Karte ziehen (vom Mac aus, Node-RED kann weiterlaufen):
  ```bash
  ssh pi@<vanpi> "sudo dd if=/dev/mmcblk0 bs=4M status=progress | gzip -1" > vanpi.img.gz
  ```
  Passt das Image nicht auf die neue Karte (gleiche Nenngröße, ein paar MB kleiner), lässt es sich am Mac mit `e2fsprogs` (`resize2fs`) und angepasster Partitionstabelle verkleinern.
- **Schreiblast prüfen:** `a=$(awk '$3=="mmcblk0"{print $10}' /proc/diskstats); sleep 120; b=$(awk '$3=="mmcblk0"{print $10}' /proc/diskstats); echo $(( (b-a)/2 )) KB` zeigt, was in 2 min wirklich auf die Karte geht. Bei uns waren es 1,2 MB (~850 MB/Tag): Pekaways `~/.node-red/settings.js` enthält `flushIntervall: 3600` – ein Tippfehler (richtig: `flushInterval`). Dadurch schreibt Node-RED seine Kontextdateien alle 30 s statt stündlich. Korrektur: `sed -i 's/flushIntervall: 3600/flushInterval: 3600/' ~/.node-red/settings.js`, dann Node-RED neu starten.
- **Ersatzkarte** mit dem Image im Fahrzeug liegen haben. Für Dauerbetrieb Marken-„High Endurance“-Karten verwenden.

---

<a name="english"></a>
## 🇬🇧 English

### What happened

The stock SD card of the **VAN PI CORE PRO** suddenly threw `Input/output error` and the filesystem went read-only. **Node-RED kept running and publishing sensor values, but no relay switched anymore** – Node-RED spawns small programs for that, and they could no longer be loaded. No lights in the camper. A **hard power cycle** fixed it immediately.

### Solution: hardware watchdog + health check

1. **Hardware watchdog** (reboot if the whole system hangs): `RuntimeWatchdogSec=15` in `/etc/systemd/system.conf.d/watchdog.conf` (see above).
2. **Health check** [`vanpi-health.sh`](vanpi-health.sh) as [`vanpi-health.service`](vanpi-health.service): every 20 s it checks that a program can start and the root filesystem is not read-only – via `/proc/mounts`, **without writing to the card itself**; after 4 consecutive failures it reboots **directly via the kernel** (`/proc/sysrq-trigger`, bash built-ins only – works even when no binaries can be loaded). No action in the first 10 minutes after boot (avoids a reboot loop with a truly dead card).

A first attempt with `Type=notify` + `systemd-notify` hung in "activating" and wouldn't have worked anyway, since `systemd-notify` is itself a binary.

Also: log2ram is already active on the VAN PI; take a full image of the card (`dd … | gzip` over SSH, Node-RED may keep running); if the image doesn't fit a new card of the same nominal size, shrink it with `e2fsprogs` (`resize2fs`) and an adjusted partition table; check real SD writes via `/proc/diskstats` (ours: 1.2 MB per 2 min) – Pekaway's `settings.js` has the typo `flushIntervall: 3600` (should be `flushInterval`), so Node-RED rewrites its context files every 30 s instead of hourly; fix with `sed` as shown above; keep a spare card with the image in the vehicle; prefer brand-name "high endurance" cards.
