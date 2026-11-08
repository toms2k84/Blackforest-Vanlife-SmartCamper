# Waveshare ESP32-P4 7" Touch-Panel als Camper-Zentrale (ESPHome + LVGL)

**🇩🇪 Deutsch** · [🇬🇧 English](#english)

**Waveshare ESP32-P4-WIFI6-Touch-LCD-7B** (1024 × 600, GT911, WLAN über ESP32-C6) mit ESPHome und LVGL. Konfiguration: [`camper-panel.yaml`](camper-panel.yaml) – Seiten Übersicht, Wasser, Energie, Klima; Lichter, Pumpe mit Druckstufen, Grauwasserventil, Webasto, Klimaanlage, Boiler, Powerstation.

## Hardware-Teil (ESPHome 2026.10)

- `esp32_hosted` (C6): reset 54, cmd 19, clk 18, d0–d3 14–17
- `esp_ldo` 2,5 V Kanal 3, `psram` hex 200 MHz
- I2C SDA 7, SCL 8; GT911 Reset GPIO23; Backlight LEDC GPIO32 invertiert
- `mipi_dsi` Modell `WAVESHARE-ESP32-P4-WIFI6-TOUCH-LCD-7B`, reset 33

## Stolperfallen, die uns Zeit gekostet haben

1. **Schrift kaum sichtbar:** Labels ohne explizite `text_color` werden vom Standard-Theme fast in Kachelfarbe gezeichnet. **Jedem Label eine `text_color` geben.** (Es lag weder an Schriftgewicht, bpp noch Drehung.)
2. **Bild auf dem Kopf:** Drehung in `lvgl:` (`rotation: 180`), nicht am Display – dann am Touch `mirror_x`/`mirror_y: true`.
3. `byte_order` muss zum Display passen (`little_endian`).
4. HA-`binary_sensor` brauchen `trigger_on_initial_state: true`, sonst fehlt der Zustand, der beim Verbinden schon anliegt.
5. `select.select_next` mit `cycle: "true"` (String) lehnt HA ab – weglassen.
6. In Flow-Mappings brechen `${substitutions}` – dort feste Hex-Werte nutzen; einfache Anführungszeichen in `!lambda '…'` verdoppeln.
7. **Stromversorgung:** Am Netzteil des VAN PI brach dessen MQTT alle ~20 s ab – das Panel braucht ein eigenes 5-V-Netzteil (≥ 3 A).
8. Icons: Material Design Icons als Schrift (`@mdi/font` 7.4.47), Glyphen als `\U000Fxxxx`.
9. Hintergrundbild als SVG mit eingebettetem JPEG (`image:`, `type: RGB565`) – nicht im Repo enthalten (`bfvl-bg.svg` ersetzen oder Bild-Widgets entfernen).

---

<a name="english"></a>
## 🇬🇧 English

**Waveshare ESP32-P4-WIFI6-Touch-LCD-7B** (1024 × 600, GT911, Wi-Fi via ESP32-C6) with ESPHome and LVGL. Config: [`camper-panel.yaml`](camper-panel.yaml) – overview, water, energy and climate pages.

Pitfalls that cost us time:
1. **Nearly invisible text:** labels without an explicit `text_color` are drawn by the default theme almost in the tile color. Give **every** label a `text_color`.
2. **Upside-down image:** rotate in `lvgl:` (`rotation: 180`), not on the display; then set `mirror_x`/`mirror_y: true` on the touchscreen.
3. `byte_order` must match the display (`little_endian`).
4. Home Assistant `binary_sensor`s need `trigger_on_initial_state: true`.
5. Home Assistant rejects `cycle: "true"` (string) for `select.select_next` – omit it.
6. `${substitutions}` break inside flow mappings; double single quotes inside `!lambda '…'`.
7. **Power:** on the VAN PI's supply the Pi's MQTT dropped every ~20 s – give the panel its own 5 V supply (≥ 3 A).
8. Icons via the Material Design Icons font, glyphs as `\U000Fxxxx`.
9. Background image (`bfvl-bg.svg`) is not included – replace it or remove the image widgets.
