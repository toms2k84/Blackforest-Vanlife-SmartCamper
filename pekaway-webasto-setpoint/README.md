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

### More Air Top Evo findings

- **"Ventilation (level)"** is W-Bus ventilation mode `0x22`, not a fan level while heating – only allow it while the heater is off.
- Single ventilation commands sometimes get lost on the bus – resending after ~10 s helps.
- Runtime timer in Home Assistant: when the runtime is changed while heating, **always** restart the timer (also from continuous mode), otherwise it keeps heating.
