# M5Stack Dial als Camper-Fernbedienung (ESPHome + LVGL)

**🇩🇪 Deutsch** · [🇬🇧 English](#english)

Der **M5Stack Dial v1.1** (ESP32-S3, rundes 1,28"-Display GC9A01, Touch FT3267, Drehgeber, Taster) als Drehknopf fürs Bett oder mit Powerbank als Fernbedienung. Konfiguration: [`camper-dial.yaml`](camper-dial.yaml).

## Bedienung

- **Drehen** = verstellen/wählen (schnell gedreht doppelte Schritte), **kurz drücken** = schalten, **doppelt drücken** = Szenen (Nacht/Morgen/Weg), **lang drücken** = Menü (Heizung: Modus + Laufzeit + Start; Klima: Modus; Wasser: Ventil), **tippen** = nächste Seite bzw. Menü schließen.
- Seiten: **Übersicht** (Uhr, Batterie, Wasser, Temperaturen, Alarm) → **Licht** → **Webasto** → **Klima** → **Außen** (Temperatur, Böen, Markisen-/Außenlicht) → **Grauwasser** (Füllstand, Pumpe, Druckstufe, Ventil nur mit langem Druck).
- Ruhezustand: gedimmt, dann **Nachtuhr**; **Warnring** rot pulsierend bei Rauch, Wasserleck, Frost.

## Hardware-Pins (v1.1)

| Funktion | Pin |
|---|---|
| Display GC9A01 (`mipi_spi`, `invert_colors: true`) | CLK 6, MOSI 5, CS 7, DC 4, RST 8, Backlight 9 (LEDC) |
| Touch FT3267 (`ft63x6`) | I2C SDA 11, SCL 12, INT 14 |
| Drehgeber / Taster | 40 / 41, Taster 42 (invertiert, Pull-up) |
| Stromhaltung (v1.1) | **GPIO46 beim Start auf High** |

## Erkenntnisse

- **Eingebauter RFID-Leser (WS1850S):** Bei unserem Gerät ansprechbar, empfängt aber nie eine Kartenantwort – auch mit der M5Stack-Werksfirmware nicht → Garantiefall. Unter ESPHome gilt er generell als unzuverlässig; Alternative: PN532 am Grove-Port.
- Menüs ohne Änderung verlassen können (Tippen/lang drücken) – sonst nervt es.
- Status-Texte auf dem runden Display begrenzen (`width` + `long_mode: dot`), lange Texte laufen sonst über den Rand.
- Lokal bauen (ESPHome im venv auf dem Mac, Python ≥ 3.12) statt im HA-Add-on: Neubau ~15 s statt Minuten; Update per WLAN mit `esphome upload --device <IP>`.
- Startbild: eigenes Bild als SVG mit eingebettetem JPEG (`image:`, `resize: 240x240`) – nicht im Repo enthalten (Datei `bfvl-dial-splash.svg` durch eigenes Bild ersetzen oder den `image:`-Block entfernen).

---

<a name="english"></a>
## 🇬🇧 English

The **M5Stack Dial v1.1** (ESP32-S3, round 1.28" GC9A01 display, FT3267 touch, encoder, button) as a bedside knob or – with a power bank – a remote. Config: [`camper-dial.yaml`](camper-dial.yaml).

- **Controls:** rotate = adjust/select (fast = double steps), short press = toggle, double press = scenes, long press = menu (heater mode + runtime + start, A/C mode, grey-water valve), tap = next page / close menu.
- **Pages:** overview → lights → heater → A/C → outside (temperature, gusts, awning light) → grey water (level, pump, pressure level, valve only by long press). Idle: dimmed, then a night clock; a red pulsing warning ring for smoke, water leak, frost.
- **Pins:** see table above; **GPIO46 must be set high at boot** on v1.1.
- **Findings:** the built-in RFID reader (WS1850S) on our unit never receives a card response, not even with M5Stack's factory firmware → warranty; under ESPHome it is generally flaky – use a PN532 on the Grove port instead. Limit status text width on the round screen (`long_mode: dot`). Build locally (ESPHome in a venv, Python ≥ 3.12) – ~15 s rebuilds, OTA with `esphome upload --device <IP>`. The boot image (`bfvl-dial-splash.svg`) is not included – replace it or remove the `image:` block.
