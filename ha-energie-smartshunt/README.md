# Home Assistant Energie-Dashboard mit Victron SmartShunt (Landstrom-Lader + Akku)

**🇩🇪 Deutsch** · [🇬🇧 English](#english)

## Problem

Im Camper gibt es keinen „Netzanschluss-Zähler“. Das Energie-Dashboard von Home Assistant zeigte deshalb **keinen Landstrom**, obwohl das Ladegerät lud, und der Akku tauchte nur auf, wenn man passende Energie-Zähler (kWh) hat. Die Verteilungsgrafik ist außerdem **stündlich** – sie sieht nur „live“ aus, aktuelle Werte zeigt sie nicht.

## Lösung

Alles wird aus den **Messwerten des SmartShunts** (Spannung × Strom) bzw. des **Landstrom-Ladegeräts** (Victron Blue Smart IP22, Spannung × Strom) gerechnet – das ist genauer als Herstellerangaben.

1. **Leistungs-Helfer** (Template-Sensoren, W) – siehe [`energie-helfer.yaml`](energie-helfer.yaml):
   - `akku_ladeleistung` = max(U × I, 0), `akku_entladeleistung` = max(−U × I, 0)
   - `akku_leistung_energiefluss` = −U × I (positiv = Entladen, so erwartet es das Energie-Dashboard)
   - `landstrom_lader_leistung` = U × I des Ladegeräts
2. **Energie-Zähler** (Integral-Helfer, kWh, Methode „links“): `akku_ladeenergie`, `akku_entladeenergie`, `landstrom_energie`.
3. **Energie-Dashboard:** Netz = `landstrom_energie` (Leistung `landstrom_lader_leistung`), Batterie = Entladen `akku_entladeenergie` / Laden `akku_ladeenergie` (Leistung `akku_leistung_energiefluss`), PV wie gehabt.
4. **Live-Karte** [`energiefluss-karte.yaml`](energiefluss-karte.yaml) (custom:button-card): PV · Landstrom → Batterie · Verbrauch mit aktuellen Watt, Verbrauch = PV + Landstrom + Entladen. Tippen öffnet `/energy/now`.

Stolperfallen:
- Ab HA 2026.11 hat die Netz-Quelle im Energie-Dashboard ein flaches Format (`stat_energy_from`, `stat_rate`), das alte `flow_from` wird abgelehnt.
- `button-card`-Styles müssen Listen von Objekten sein (`- grid-template-areas: '"f"'`), Strings werden ignoriert.
- In Templates `states[id]` immer auf `undefined` prüfen, sonst bricht die Karte, wenn ein Gerät kurz offline ist.

---

<a name="english"></a>
## 🇬🇧 English

A camper has no grid meter, so the HA energy dashboard showed **no shore power** while the charger was charging, and the battery needs kWh counters. The distribution graph is **hourly**, it only looks live.

Solution: compute everything from the **SmartShunt** (V × A) and the **shore-power charger** (Victron IP22, V × A): template power helpers ([`energie-helfer.yaml`](energie-helfer.yaml)), integral helpers (kWh, left method), wire them into the energy dashboard (grid = shore power, battery charge/discharge, `stat_rate` positive = discharge), plus a **live card** ([`energiefluss-karte.yaml`](energiefluss-karte.yaml), custom:button-card) showing PV · shore power → battery · consumption in watts; tap opens `/energy/now`.

Pitfalls: HA 2026.11 uses a flat grid source format (`flow_from` is rejected); button-card styles must be lists of objects; guard `states[id]` against `undefined`.
