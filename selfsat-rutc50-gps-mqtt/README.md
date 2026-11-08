# SELFSAT MWR 6550 / Teltonika RUTC50: GPS per MQTT in Home Assistant

**🇩🇪 Deutsch** · [🇬🇧 English](#english)

Der Camper-Router **SELFSAT MWR 6550** ist intern ein **Teltonika RUTC50** (RutOS). Er hat GPS, die SELFSAT-Oberfläche bietet aber keine Weitergabe an. Die RutOS-Funktion **„Data to Server“** ist trotzdem vorhanden – nur ohne Menüpunkt. Sie lässt sich über die Router-REST-API einrichten (mit der Sitzung des angemeldeten Browsers).

> Tipp aus der Praxis: Unsere erste GPS-Antenne war defekt (kein Fix, auch schlechtere LTE-Raten). Nach dem Tausch: Fix mit 8 Satelliten und deutlich bessere Datenraten.

## 1. Data to Server einrichten (Router-API)

Im Browser am Router angemeldet, in der Konsole der Router-Seite:

```javascript
const sid = localStorage.getItem('selfsat_last_sid');   // Sitzung der Oberfläche
const H = {Authorization: 'Bearer ' + sid, 'Content-Type': 'application/json'};
const api = (m, p, d) => fetch(p, {method: m, headers: H, body: d && JSON.stringify({data: d})}).then(r => r.json());

// Sammlung anlegen – Ein- und Ausgang werden automatisch mit angelegt
const c = await api('POST', '/api/data_to_server/collections/config', {name: 'gps_ha'});
// c.data.input = [<id>], c.data.output = <id>
await api('PUT', '/api/data_to_server/data/config/' + c.data.input[0], {plugin: 'gps', name: 'gps_ha_gps'});
await api('PUT', '/api/data_to_server/servers/config/' + c.data.output, {
  plugin: 'mqtt', mqtt_host: '<HA-IP>', mqtt_port: '1883', mqtt_topic: 'camper/gps',
  mqtt_qos: '0', mqtt_keepalive: '60', mqtt_tls: '0', mqtt_client_id: 'selfsat-gps'});
await api('PUT', '/api/data_to_server/collections/config/' + c.data.id, {enabled: '1', period: '30'});
```

Ergebnis alle 30 s auf `camper/gps`:
```json
{"gps_ha_gps":{"latitude":47.1234,"longitude":8.5678,"altitude":420.0,"angle":0,"speed":0,
 "accuracy":0.4,"satellites":8,"fix_status":1,"timestamp":1794084042, "...": "..."}}
```

## 2. Home Assistant per MQTT-Discovery

Retained auf `homeassistant/device_tracker/womo_gps/config` u. a.:
```json
{"name":"Womo","unique_id":"womo_gps_tracker","json_attributes_topic":"camper/gps",
 "json_attributes_template":"{% set g = value_json.gps_ha_gps %}{% if g.fix_status|int(0) >= 1 %}{{ {'latitude': g.latitude|float, 'longitude': g.longitude|float, 'gps_accuracy': [5, (g.accuracy|float(1) * 5)|round(0)]|max, 'altitude': g.altitude|float(0), 'speed': g.speed|float(0)} | tojson }}{% else %}{{ {'fix': false} | tojson }}{% endif %}",
 "source_type":"gps"}
```
Dazu Sensoren für Geschwindigkeit (`value_json.gps_ha_gps.speed`), Höhe, Satelliten und `fix_status`.

## 3. Was wir daraus machen

- **Standort folgt dem Camper:** Steht er 10 min und ist > 2 km vom HA-Standort weg → `homeassistant.set_location`. Damit passen Wetter (Open-Meteo „Home“), Forecast.Solar (Standort „home“) und Sonnenauf-/-untergang überall.
- **Fährt** (> 8 km/h): Abfahrt-Check (Grauwasserventil/Tür/Garage offen?), Bewegungsalarm bei Fahrt ohne Motor (D+ aus, Starterspannung < 13,3 V), Fahrtenbuch aus GPS-Punkten.
- **Markise:** stündliche Böen-Vorhersage am Standort, Push über der Windgrenze.

---

<a name="english"></a>
## 🇬🇧 English

The **SELFSAT MWR 6550** camper router is a **Teltonika RUTC50** (RutOS) inside. It has GPS, but the SELFSAT UI offers no way to forward it. The RutOS feature **"Data to Server"** is still there – just without a menu entry. You can set it up through the router REST API using the logged-in browser session (see the JavaScript above: create a collection, set the input plugin to `gps`, the output plugin to `mqtt` with host/port/topic, enable it with a 30 s period).

The router then publishes JSON to `camper/gps` every 30 s. In Home Assistant we use retained MQTT discovery for a `device_tracker` (JSON attributes template shown above) plus speed/altitude/satellites/fix sensors.

What we use it for: Home Assistant's location follows the camper (`homeassistant.set_location` after parking > 10 min and > 2 km away, so weather, solar forecast and sun follow), departure check, movement alarm while the engine is off, trip log, and an awning wind warning from the hourly gust forecast at the current location.

Field note: our first GPS antenna was faulty (no fix, also worse LTE speeds). After replacing it: 8 satellites and clearly better data rates.
