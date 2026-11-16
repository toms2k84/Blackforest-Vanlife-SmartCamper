# Pekaway VAN PI + Webasto Air Top Evo: Sollwert startet die Heizung

**🇩🇪 Deutsch** · [🇬🇧 English](#english)

## Problem

Mit dem **Pekaway VAN PI** (Node-RED, W-Bus) und einer **Webasto Air Top Evo 40/55** passiert Folgendes: Ändert man die **Solltemperatur**, während die Heizung **aus** ist (z. B. aus Home Assistant oder einem Display), **startet die Webasto**. Man merkt es daran, dass das Licht kurz flackert und die Heizung anläuft.

## Ursache

Im Pekaway-Flow läuft jede Sollwert-Änderung über die Function-Node **„Evo Buffer calculation Tempmode“**. Sie baut den W-Bus-Befehl `34 05 2A 21 FF <Temp+50> <XOR>`. **`0x21` ist der Befehl „Heizen mit Sollwert“**, also ein Start. Für eine reine Sollwert-Änderung gibt es keinen eigenen Befehl, deshalb startet die Heizung.

Auch der normale Start läuft über dieselbe Node („Start tempmode“ → „to settemp“), vorher wird aber der globale Merker `HeaterToggle_autoterm1` auf `true` gesetzt.

## Fix

In der Function-Node **„Evo Buffer calculation Tempmode“** direkt nach `let temp = msg.temp;` einfügen:

```javascript
// Nur senden, wenn die Webasto gestartet ist: der Befehl 0x21 startet sie sonst.
// Bei ausgeschalteter Heizung bleibt das Soll gespeichert und geht beim nächsten Start mit.
if (global.get("HeaterToggle_autoterm1") !== true) {
    node.status({ fill: "grey", shape: "ring", text: "Soll " + msg.temp + " °C gemerkt (Heizung aus)" });
    return null;
}
node.status({});
```

Ergebnis: Bei ausgeschalteter Heizung wird das Soll nur gemerkt, bei laufender Heizung sofort übernommen, und ein Start nimmt das gemerkte Soll mit. Getestet: Soll 30 → 31 °C bei „Aus (Pause)“, die Heizung blieb aus.

Hinweis: Die Namen der Nodes und des Merkers stammen aus dem Pekaway-Standardflow (Stand Nov. 2026). Vor dem Ändern ein Backup der Flows ziehen.

## Modus (Normal/Eco/Boost) bei laufender Heizung übernehmen

Im Standardflow speichert die Function-Node **„boost/eco“** den Modus nur – die laufende Heizung bekommt ihn erst beim nächsten Start. Fix: der Node einen **zweiten Ausgang** geben, ihn mit dem Link-Out **„Webasto_E“** (der zur „Evo Buffer calculation Tempmode“ führt) verbinden und am Ende der Funktion:

```javascript
if (global.get("HeaterToggle_autoterm1") !== true) return null;   // Heizung aus: nur merken
const evo = RED.util.cloneMessage(msg);
evo.payload = "Webasto_EVO";
evo.temp = parseInt(global.get("settemp_autoterm1"), 10);
return [msg, evo];   // Ausgang 1 wie bisher, Ausgang 2 = Soll-Frame mit neuem Modus
```

## Merker an den echten Zustand koppeln

Schaltet sich die Webasto **selbst** ab (Störung, Temperaturabschaltung …), bleibt `HeaterToggle_autoterm1` auf `true`. Eine spätere Soll- oder Modusänderung startet sie dann wieder. Abhilfe: eine Function-Node hinter der Node, die den W-Bus-Zustand als Text liefert („Zustand“), die den Merker nach 3 min „Aus…“ zurücksetzt:

```javascript
const s = String(msg.payload || "");
if (!s.startsWith("Aus")) { context.set("aus_seit", 0); return null; }
let seit = context.get("aus_seit") || 0;
if (!seit) { seit = Date.now(); context.set("aus_seit", seit); }
if (global.get("HeaterToggle_autoterm1") === true && Date.now() - seit > 180000) {
    global.set("HeaterToggle_autoterm1", false);
    node.warn("HeaterToggle_autoterm1 zurückgesetzt, Status seit 3 min: " + s);
}
return null;
```

**Auch umgekehrt koppeln:** Im **Eco**-Modus schaltet sich die Evo über dem Soll selbst ab (bei uns: Soll 24 °C, Fühler 26 °C) und kann später von selbst wieder anspringen. Dann steht der Merker auf `false` und Soll-/Modusänderungen werden ignoriert. Deshalb in derselben Node vor dem „Aus“-Teil: Läuft die Heizung **2 min am Stück** im „Regelbetrieb“, den Merker wieder auf `true` setzen (bei „Aus…“, „Nachlauf…“ oder „Abschaltung“ den Zähler zurücksetzen). Die 2 min verhindern, dass ein kurzes „Regelbetrieb“ direkt nach „Stopp“ zählt. Im Normal-Modus läuft die Evo über dem Soll auf kleiner Stufe weiter.

## Eco: Neustart nach Selbstabschaltung (Home Assistant)

Bei uns startete die Evo nach einer Eco-Selbstabschaltung **nicht** von allein wieder, auch nicht 1 K unter Soll bei fallender Raumtemperatur. Lösung in HA mit einem Helfer `input_boolean.webasto_eco_neustart` und zwei Automationen:

1. **Scharf/aus:** MQTT-Trigger auf das Start/Stop-Topic des VAN PI (bei uns `vanpi/webasto/command`, Payload `START`/`STOP`). START → Helfer an, STOP (auch Ende des Laufzeit-Timers) oder ein Status mit „Verriegelung/Störung/Fehler“ → Helfer aus. Voraussetzung: **alle** Start-/Stopp-Wege laufen über dieses Topic.
2. **Neustart:** Helfer an, Modus Eco, Status seit ≥ 10 min „Aus…“, Webasto-Fühler ≤ Soll − 1 K, Spannung > 12 V → `START` per `mqtt.publish` (nicht über ein Timer-Skript, damit eine laufende Laufzeit nicht neu beginnt). Kommt binnen 10 min kein „Regelbetrieb“, Helfer aus und Push.

## Wichtig: Deploy-Modus „Nur geänderte Nodes“

Der Node-RED-Editor des VAN PI stand bei uns auf **„Vollständig“**. Dann startet **jedes** Deploy alle Flows neu – auch den Webasto-Flow, und eine laufende Heizung ging dabei aus. Im Deploy-Menü (Pfeil neben „Übernahme“) auf **„Nur geänderte Nodes“** umstellen.

## Weitere Erkenntnisse zur Air Top Evo am VAN PI

- **„Lüften (Stufe)“** ist der W-Bus-Lüftungsmodus `0x22`, keine Gebläsestufe beim Heizen – die Evo regelt das Gebläse beim Heizen selbst. Lüften nur zulassen, wenn die Heizung aus ist.
- Einzelne Lüften-Befehle kommen auf dem Bus gelegentlich nicht an – nach ca. 10 s erneut senden hilft.
- Laufzeit-Timer in Home Assistant: Wird die Laufzeit während des Heizens geändert, den Timer **immer** neu starten (auch aus dem Dauerbetrieb heraus), sonst heizt sie ungewollt weiter.

---

<a name="english"></a>
## 🇬🇧 English

### Problem

With the **Pekaway VAN PI** (Node-RED, W-Bus) and a **Webasto Air Top Evo 40/55**, changing the **target temperature** while the heater is **off** (e.g. from Home Assistant or a display) **starts the heater**.

### Root cause

Every setpoint change runs through the function node **"Evo Buffer calculation Tempmode"**, which builds the W-Bus frame `34 05 2A 21 FF <temp+50> <XOR>`. **`0x21` is "heat with setpoint"**, i.e. a start command. There is no separate "set setpoint only" command. The normal start also goes through this node, but sets the global flag `HeaterToggle_autoterm1` to `true` first.

### Fix

In **"Evo Buffer calculation Tempmode"**, right after `let temp = msg.temp;`, insert:

```javascript
// Only send while the heater is running: command 0x21 would start it otherwise.
// With the heater off the setpoint is remembered and used on the next start.
if (global.get("HeaterToggle_autoterm1") !== true) {
    node.status({ fill: "grey", shape: "ring", text: "Setpoint " + msg.temp + " °C stored (heater off)" });
    return null;
}
node.status({});
```

Result: heater off → setpoint is only stored; heater on → applied immediately; a start uses the stored setpoint. Tested: setpoint 30 → 31 °C while "off (pause)" – the heater stayed off.

Node and flag names are from the Pekaway default flow (Nov 2026). Back up your flows first.

### Apply Normal/Eco/Boost while running

The stock **"boost/eco"** function only stores the mode; the running heater gets it on the next start. Give the node a **second output**, wire it to the link-out **"Webasto_E"** (leading to "Evo Buffer calculation Tempmode") and, while `HeaterToggle_autoterm1` is true, also return a clone with `payload = "Webasto_EVO"` and `temp = settemp_autoterm1` (code above).

### Couple the flag to the real state

If the Webasto shuts down **by itself**, `HeaterToggle_autoterm1` stays `true` and a later setpoint/mode change restarts it. A small function after the node that outputs the W-Bus state text resets the flag after 3 minutes of an "Aus…" (off) state (code above). Couple it the other way too: in **Eco** mode the Evo shuts itself down above the setpoint and may restart on its own, so set the flag back to `true` after **2 minutes** of continuous "Regelbetrieb" (controlled operation); reset that counter on "Aus…", "Nachlauf…" or "Abschaltung" so a brief "Regelbetrieb" right after a stop doesn't count. In Normal mode the Evo keeps running at low power above the setpoint.

### Eco: restart after self-shutdown (Home Assistant)

Ours did **not** restart by itself after an Eco self-shutdown, not even 1 K below the setpoint. Fix in HA: a helper `input_boolean.webasto_eco_neustart`, armed by `START` and disarmed by `STOP` (or a lockout/fault state) on the VAN PI command topic (ours: `vanpi/webasto/command`; all start/stop paths must use it). A second automation sends `START` via `mqtt.publish` when the helper is on, mode is Eco, the state has been "Aus…" for ≥ 10 min, the heater sensor is ≤ setpoint − 1 K and voltage > 12 V; if "Regelbetrieb" doesn't follow within 10 min it disarms and notifies.

### Deploy mode "Modified nodes"

Our VAN PI editor was set to **"Full"** deploy: every deploy restarted all flows, including the Webasto flow, and a running heater stopped. Switch the deploy menu to **"Modified Nodes"**.

### More Air Top Evo findings

- **"Ventilation (level)"** is W-Bus ventilation mode `0x22`, not a fan level while heating – only allow it while the heater is off.
- Single ventilation commands sometimes get lost on the bus – resending after ~10 s helps.
- Runtime timer in Home Assistant: when the runtime is changed while heating, **always** restart the timer (also from continuous mode), otherwise it keeps heating.
