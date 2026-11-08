# CARAWATER ISP – Bluetooth-Protokoll & ESP32-Bridge für Home Assistant

**🇩🇪 Deutsch** · [🇬🇧 English](#english)

Die smarten Wohnmobil-Wasserpumpen **CARAWATER ISP 10 / 15 / 20** lassen sich nur per App bedienen. Hier ist das Bluetooth-Protokoll (mitgeschnitten am 08.11.2026 an einer ISP 15) und eine fertige **ESPHome-Bridge**, mit der Home Assistant die Pumpe **an/aus** schaltet und die **Druckstufe 1–3** setzt – unabhängig von der App.

Getestet: Aus → Druck fällt ab, An → Wasser kommt, Druckstufe 2 und zurück auf 1. Die Pumpe meldet ihren Zustand zurück.

## Protokoll

Die Pumpe meldet sich als `ISP_xx_xxxx`, Dienst **`FF00`** („BLE-UART“):

| Kanal | UUID | Handle (ISP 15) |
|---|---|---|
| Befehle schreiben | `0000ff02-0000-1000-8000-00805f9b34fb` | 0x0014 |
| Antworten (Notify) | `0000ff01-0000-1000-8000-00805f9b34fb` | 0x0011 (CCCD 0x0012) |

**Abfrage / Keepalive** (die App sendet sie alle 2 s, 5 Byte):
```
55 MM HH WT CS
```
`MM` = Minute, `HH` = Stunde, `WT` = Wochentag (Mo = 1 … So = 7), `CS` = Summe aller vorherigen Bytes & 0xFF.
Beispiel Sonntag 17:44 → `55 2c 11 07 99`

**Schaltbefehl** (60 Byte):
```
aa 39 MODE 00 00 00 MM HH WT 00 … 00 CS
```
Byte 0–8 wie oben, danach Nullen bis Byte 58, Byte 59 = Summe aller vorherigen Bytes & 0xFF.

**MODE:** Bit 0 = Pumpe an, Bits 5–6 = Druckstufe

| MODE | Bedeutung |
|---|---|
| `0x20` | aus (Stufe 1) |
| `0x21` | an, Stufe 1 |
| `0x41` | an, Stufe 2 |
| `0x61` | an, Stufe 3 |

**Antworten:** `55` als Quittung, danach Status `aa 45 MODE 00 00 00 83 00 00 00 12 01 a0 … 13 05` – Byte 2 ist der aktuelle MODE.

## ESPHome-Bridge

[`carawater-bridge.yaml`](carawater-bridge.yaml) für einen normalen **ESP32** (getestet mit ESP32-D0WD-V3, 4 MB):
- `ble_client` zur Pumpe, Statusabfrage alle 10 s
- Home Assistant: Schalter **„Wasserpumpe direkt“**, Auswahl **„Pumpe Druckstufe“** (1–3), Verbindungsstatus, Bluetooth-Signal, Neustart-Grund
- zusätzlich **Bluetooth-Proxy** für andere BLE-Geräte

Anpassen: MAC-Adresse der Pumpe (`pumpe_mac`), WLAN in `secrets.yaml`, API-Schlüssel.

## Stolperfallen

- **Nur eine Bluetooth-Verbindung:** Solange die CARAWATER-App verbunden ist, kommt die Bridge nicht dran. App danach ganz schließen.
- **Nichts beim Start senden:** `restore_mode: DISABLED` am Schalter, sonst schaltet ein Neustart der Bridge die Pumpe aus.
- **Stromversorgung:** An einer fest verbauten 12-V-USB-Dose stürzte der ESP nach Minuten ab (Safe-Mode). Ein eigener 12→5-V-Wandler (≥ 1 A) direkt an der Pumpe ist sicherer.
- **Reichweite:** Der HA-Rechner empfing die Pumpe nur mit −86 dBm; die Bridge 0,5 m daneben mit −60 dBm.

## So wurde mitgeschnitten

Android-Tablet → Entwickleroptionen → „Bluetooth-HCI-Snoop-Protokoll“ an → in der App schalten → `adb bugreport` → `FS/data/log/bt/btsnoop_hci.log` auswerten (ATT-Writes an Handle 0x0014, Notifies von 0x0011).

---

<a name="english"></a>
## 🇬🇧 English

The **CARAWATER ISP 10 / 15 / 20** smart motorhome water pumps are app-only. This is their Bluetooth protocol (captured on 2026-11-08 from an ISP 15) plus a ready-to-use **ESPHome bridge** that lets Home Assistant switch the pump **on/off** and set **pressure level 1–3** – without the app.

Tested: off → pressure drops, on → water flows, pressure level 2 and back to 1. The pump reports its state back.

### Protocol

The pump advertises as `ISP_xx_xxxx`, service **`FF00`** ("BLE UART"):

| Channel | UUID | Handle (ISP 15) |
|---|---|---|
| write commands | `0000ff02-0000-1000-8000-00805f9b34fb` | 0x0014 |
| responses (notify) | `0000ff01-0000-1000-8000-00805f9b34fb` | 0x0011 (CCCD 0x0012) |

**Poll / keepalive** (the app sends it every 2 s, 5 bytes): `55 MM HH WD CS` – minute, hour, weekday (Mon = 1 … Sun = 7), checksum = sum of previous bytes & 0xFF. Example Sunday 17:44 → `55 2c 11 07 99`.

**Switch command** (60 bytes): `aa 39 MODE 00 00 00 MM HH WD` + zeros up to byte 58, byte 59 = checksum (sum of previous bytes & 0xFF).

**MODE:** bit 0 = pump on, bits 5–6 = pressure level: `0x20` off, `0x21` on/level 1, `0x41` on/level 2, `0x61` on/level 3.

**Responses:** `55` as acknowledge, then status `aa 45 MODE …` – byte 2 is the current MODE.

### ESPHome bridge

[`carawater-bridge.yaml`](carawater-bridge.yaml) for a plain **ESP32**: `ble_client` to the pump, status poll every 10 s; Home Assistant gets a **switch**, a **pressure select** (1–3), connection status, BLE RSSI, reset reason; plus a **Bluetooth proxy**. Adjust the pump MAC (`pumpe_mac`), Wi-Fi in `secrets.yaml` and the API key.

### Pitfalls

- **Only one BLE connection:** while the CARAWATER app is connected the bridge can't connect. Fully close the app.
- **Don't send on boot:** `restore_mode: DISABLED` on the switch, otherwise a bridge reboot turns the pump off.
- **Power supply:** on a built-in 12 V USB socket the ESP crashed after minutes (safe mode). Use a dedicated 12→5 V converter (≥ 1 A) next to the pump.
- **Range:** the HA host saw the pump at −86 dBm; the bridge 0.5 m away at −60 dBm.

### How it was captured

Android tablet → developer options → "Bluetooth HCI snoop log" on → switch in the app → `adb bugreport` → analyse `FS/data/log/bt/btsnoop_hci.log` (ATT writes to handle 0x0014, notifications from 0x0011).
