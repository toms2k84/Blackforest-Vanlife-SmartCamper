# Blackforest Vanlife – Smart Camper

**🇩🇪 Deutsch** · [🇬🇧 English](#english)

Erkenntnisse, Konfigurationen und Workarounds aus dem Smart-Home-Ausbau unseres Wohnmobils (Home Assistant, ESPHome, Pekaway VAN PI, Node-RED). Alles hier ist im echten Camper im Einsatz und getestet. Persönliche Daten (Adressen, Schlüssel, Seriennummern) sind entfernt.

| Thema | Worum es geht |
|---|---|
| [CARAWATER ISP Bluetooth](carawater-isp-ble/) | Bluetooth-Protokoll der smarten Wasserpumpe CARAWATER ISP 10/15/20 entschlüsselt, ESP32-Bridge für Home Assistant (an/aus, 3 Druckstufen) |
| [Pekaway + Webasto Sollwert](pekaway-webasto-setpoint/) | Ändern der Solltemperatur startet die Webasto Air Top Evo ungewollt – Ursache und Node-RED-Fix |
| [VIOFO A329T in Home Assistant](viofo-a329t-homeassistant/) | Station-Modus geht nach jedem Neustart verloren – Lösung mit Hotspot und Raspberry Pi als Brücke, auch bei Tailscale-Subnetz-Überschneidung |
| [SELFSAT / Teltonika GPS → MQTT](selfsat-rutc50-gps-mqtt/) | GPS des SELFSAT MWR 6550 (Teltonika RUTC50) per „Data to Server“ an Home Assistant, Wetter und Standort folgen dem Camper |
| [M5Stack Dial als Camper-Fernbedienung](m5stack-dial-camper/) | ESPHome/LVGL-Drehknopf: Heizung, Klima, Licht, Wasser, Szenen, Nachtuhr, Warnring |
| [Waveshare ESP32-P4 7" Panel](waveshare-esp32-p4-panel/) | ESPHome/LVGL-Touchpanel und die Stolperfallen (unsichtbare Schrift, Drehung, Touch) |
| [VAN PI Watchdog](vanpi-watchdog/) | Selbstheilung, wenn die SD-Karte hängt und keine Relais mehr schalten |

Fragen, Fehler, Ergänzungen: gerne als Issue. Nutzung auf eigene Gefahr – siehe [Lizenz](LICENSE) (MIT).

---

<a name="english"></a>
## 🇬🇧 English

Findings, configurations and workarounds from the smart-home build of our motorhome (Home Assistant, ESPHome, Pekaway VAN PI, Node-RED). Everything here runs and was tested in the real camper. Personal data (addresses, keys, serial numbers) has been removed.

| Topic | What it is about |
|---|---|
| [CARAWATER ISP Bluetooth](carawater-isp-ble/) | Reverse-engineered Bluetooth protocol of the CARAWATER ISP 10/15/20 smart water pump, ESP32 bridge for Home Assistant (on/off, 3 pressure levels) |
| [Pekaway + Webasto setpoint](pekaway-webasto-setpoint/) | Changing the target temperature starts the Webasto Air Top Evo unintentionally – root cause and Node-RED fix |
| [VIOFO A329T in Home Assistant](viofo-a329t-homeassistant/) | Station mode is lost after every reboot – solution with hotspot mode and a Raspberry Pi as bridge, also with Tailscale subnet overlap |
| [SELFSAT / Teltonika GPS → MQTT](selfsat-rutc50-gps-mqtt/) | GPS of the SELFSAT MWR 6550 (Teltonika RUTC50) via "Data to Server" into Home Assistant; weather and location follow the camper |
| [M5Stack Dial as camper remote](m5stack-dial-camper/) | ESPHome/LVGL rotary knob: heater, A/C, lights, water, scenes, night clock, warning ring |
| [Waveshare ESP32-P4 7" panel](waveshare-esp32-p4-panel/) | ESPHome/LVGL touch panel and its pitfalls (invisible text, rotation, touch) |
| [VAN PI watchdog](vanpi-watchdog/) | Self-healing when the SD card hangs and relays stop switching |

Questions, bugs, additions: open an issue. Use at your own risk – see [license](LICENSE) (MIT).
