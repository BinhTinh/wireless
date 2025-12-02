#!/bin/bash

# Research Context:
# Verify that the available Wi‑Fi interfaces on this Ubuntu host support the modes
# we need for the lab (AP mode for target, monitor mode for auditor).
# Audit Objective:
# - Confirm at least two interfaces (or one with virtual capabilities) where:
#   * One can operate as AP (hostapd)
#   * One can operate in monitor mode (airodump-ng / aireplay-ng)
# Expected Outcome: clear PASS/FAIL messages for each check and guidance for next steps.

set -euo pipefail

IW=$(command -v iw || true)
AWK=$(command -v awk || true)
GREP=$(command -v grep || true)

if [[ -z "$IW" ]]; then
  echo "[ERROR] 'iw' command not found. Install with: sudo apt install iw" >&2
  exit 2
fi

echo "# ====== Hardware capability check ======"

echo "Running: iw dev"
$IW dev

echo "\nRunning: iw list (this may be long)"
$IW list | sed -n '1,200p'

# Check for phy sections that support AP and monitor
AP_OK=0
MON_OK=0

# Look for Supported interface modes per phy
while read -r line; do
  if echo "$line" | $GREP -q "Supported interface modes:"; then
    modes=""
  fi
  if echo "$line" | $GREP -q "\* AP"; then
    AP_OK=1
  fi
  if echo "$line" | $GREP -q "\* monitor"; then
    MON_OK=1
  fi
done < <($IW list)

if [[ $AP_OK -eq 1 ]]; then
  echo "[PASS] At least one phy reports AP mode support"
else
  echo "[FAIL] No phy supports AP mode. hostapd won't run.\n  - Suggestion: try a different USB WiFi adapter or check drivers." >&2
fi

if [[ $MON_OK -eq 1 ]]; then
  echo "[PASS] At least one phy reports monitor mode support"
else
  echo "[FAIL] No phy supports monitor mode. Packet capture/injection won't work.\n  - Suggestion: use a different adapter or check for mac80211 driver support." >&2
fi

# Show interface list and suggest mapping
echo "\n# Interfaces found (iw dev):"
$IW dev | sed -n '1,200p'

cat <<'EOF'

Actionable next steps (for the report):
 - Choose which interface will act as TARGET (AP). Good candidate: wlo1 (built-in) if AP is supported.
 - Choose which interface will act as ATTACKER (monitor). Good candidate: the USB adapter (wlx...)
 - If you have only one physical adapter with both modes supported, you can still run both roles sequentially but it's cleaner to have two devices.
 - If using these scripts, run them step-by-step and capture screenshots per step for your report.
EOF

exit 0
