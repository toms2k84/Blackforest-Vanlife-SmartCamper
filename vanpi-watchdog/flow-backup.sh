#!/bin/bash
# Wöchentliche Sicherung der Node-RED-Flows (seit 15.11.2026). Behält die letzten 8 Stände.
ziel="$HOME/flow-backups"
mkdir -p "$ziel"
stamp=$(date +%F)
cp "$HOME/.node-red/flows_pekaway.json" "$ziel/flows-$stamp.json"
[ -f "$HOME/.node-red/flows_pekaway_cred.json" ] && cp "$HOME/.node-red/flows_pekaway_cred.json" "$ziel/cred-$stamp.json"
ls -1t "$ziel"/flows-*.json 2>/dev/null | tail -n +9 | xargs -r rm -f
ls -1t "$ziel"/cred-*.json 2>/dev/null | tail -n +9 | xargs -r rm -f
