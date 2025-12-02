# Kiến trúc Lab Thực hành PSKracker

## 🏗️ Tổng quan Kiến trúc

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Ubuntu 24.04 Host Machine                     │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    PHYSICAL INTERFACES                          │ │
│  │                                                                  │ │
│  │  ┌──────────────┐              ┌──────────────┐                │ │
│  │  │   wlo1       │              │   wlan1      │                │ │
│  │  │ (Built-in    │              │ (USB WiFi    │                │ │
│  │  │  WiFi)       │              │  Adapter)    │                │ │
│  │  └──────┬───────┘              └──────┬───────┘                │ │
│  └─────────┼──────────────────────────────┼──────────────────────┘ │
│            │                              │                          │
│  ┌─────────▼──────────────┐    ┌─────────▼──────────────┐          │
│  │   TARGET ROLE          │    │   ATTACKER ROLE         │          │
│  │   (Victim AP)          │    │   (Auditor)             │          │
│  │                        │    │                         │          │
│  │  Mode: AP/Master       │    │  Mode: Monitor          │          │
│  │  Tool: hostapd         │    │  Tools: airodump-ng     │          │
│  │  SSID: Belkin_Target   │    │         aireplay-ng     │          │
│  │  BSSID: 08:86:3B:...   │    │         pskracker       │          │
│  │  PSK: [test password]  │    │         wireshark       │          │
│  └────────────────────────┘    └─────────────────────────┘          │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    SOC ANALYSIS LAYER                           │ │
│  │                                                                  │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │ │
│  │  │ Capture  │  │ Analyze  │  │ Detect   │  │ Report   │       │ │
│  │  │ (pcap)   │→ │(Wireshark│→ │ (Rules)  │→ │(Evidence)│       │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │ │
│  └────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────┘
```

## 📋 Workflow Chi tiết (5 Phases)

### **Phase 1: Environment Setup & Verification**
```
┌─────────────────────────────────────────────┐
│ 1. Check Hardware Capabilities             │
│    - iw list (check AP mode)               │
│    - iw list (check Monitor mode)          │
│                                             │
│ 2. Install Dependencies                     │
│    - hostapd, dnsmasq                      │
│    - aircrack-ng suite                     │
│    - pskracker                             │
│                                             │
│ 3. Stop Interfering Services               │
│    - NetworkManager                        │
│    - wpa_supplicant                        │
│                                             │
│ OUTPUT: screenshots/01_environment/         │
└─────────────────────────────────────────────┘
```

### **Phase 2: Target Simulation (Fake AP)**
```
┌─────────────────────────────────────────────┐
│ CASE A: Belkin Vulnerable Router           │
│                                             │
│ 1. Create hostapd config                   │
│    - BSSID: 08:86:3B:XX:XX:XX             │
│    - SSID: Belkin_Lab_Target              │
│    - PSK: [calculated by PSKracker]       │
│                                             │
│ 2. Start Access Point                      │
│    - hostapd -d config.conf               │
│                                             │
│ 3. Verify AP Broadcasting                  │
│    - Check with phone/laptop              │
│                                             │
│ OUTPUT: screenshots/02_target_belkin/       │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ CASE B: Netgear Dictionary-based Router    │
│                                             │
│ 1. Generate password dictionary            │
│    - adjective + noun + number            │
│                                             │
│ 2. Create hostapd config                   │
│    - SSID: Netgear_Lab_Target             │
│    - PSK: yellowishreportage287           │
│                                             │
│ 3. Start Access Point                      │
│                                             │
│ OUTPUT: screenshots/02_target_netgear/      │
└─────────────────────────────────────────────┘
```

### **Phase 3: Attack Execution (Reconnaissance + Exploit)**
```
┌─────────────────────────────────────────────┐
│ STEP 3.1: Passive Reconnaissance           │
│                                             │
│ 1. Enable Monitor Mode                     │
│    - airmon-ng start wlan1                │
│    → Creates wlan1mon                      │
│                                             │
│ 2. Scan for Targets                        │
│    - airodump-ng wlan1mon                 │
│    - Identify BSSID, Channel, OUI         │
│                                             │
│ 3. Focus on Target                         │
│    - airodump-ng -c 6 --bssid XX:XX:XX   │
│                                             │
│ OUTPUT: screenshots/03_recon/               │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ STEP 3.2: Credential Generation Attack     │
│                                             │
│ For Belkin:                                 │
│   ./pskracker -t belkin \                  │
│               -b 08:86:3B:XX:XX:XX         │
│                                             │
│ For Netgear:                                │
│   python3 gen_netgear_dict.py              │
│   aircrack-ng -w dict.txt capture.cap      │
│                                             │
│ OUTPUT: screenshots/04_attack/              │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ STEP 3.3: Capture Handshake (Optional)     │
│                                             │
│ 1. Start Capture                            │
│    - airodump-ng -c 6 -w capture \        │
│      --bssid XX:XX:XX wlan1mon            │
│                                             │
│ 2. Trigger Re-authentication                │
│    - aireplay-ng --deauth 5 \             │
│      -a [AP_MAC] wlan1mon                 │
│                                             │
│ 3. Verify Handshake Captured                │
│    - Look for "WPA handshake" message     │
│                                             │
│ OUTPUT: screenshots/04_attack/              │
│         captures/handshake.cap              │
└─────────────────────────────────────────────┘
```

### **Phase 4: SOC Analysis (Detection & Forensics)**
```
┌─────────────────────────────────────────────┐
│ STEP 4.1: Traffic Analysis                 │
│                                             │
│ 1. Open Wireshark                          │
│    wireshark captures/handshake.cap        │
│                                             │
│ 2. Apply Filters                            │
│    - wlan.fc.type_subtype == 0x0b (Deauth)│
│    - eapol (4-way handshake)              │
│    - wps (WPS probe responses)            │
│                                             │
│ 3. Analyze Packets                          │
│    - Extract BSSID from Beacon            │
│    - Check WPS IE for Serial leak         │
│    - Examine EAPOL MIC values             │
│                                             │
│ OUTPUT: screenshots/05_analysis/            │
│         wireshark_filters.txt               │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ STEP 4.2: IoC Detection                    │
│                                             │
│ 1. Create Detection Rules                  │
│    - Snort rule for deauth flood          │
│    - Suricata rule for WPS probing        │
│                                             │
│ 2. Run Python IoC Extractor                │
│    python3 extract_ioc.py capture.cap      │
│    → Outputs: suspicious MACs, patterns   │
│                                             │
│ 3. Create Alert Dashboard (concept)        │
│                                             │
│ OUTPUT: screenshots/05_analysis/            │
│         soc_artifacts/rules.txt             │
│         soc_artifacts/iocs.json             │
└─────────────────────────────────────────────┘
```

### **Phase 5: Hardening & Compliance**
```
┌─────────────────────────────────────────────┐
│ STEP 5.1: Demonstrate Mitigations          │
│                                             │
│ 1. Reconfigure AP with Strong Settings     │
│    - Change to WPA3-SAE                    │
│    - Disable WPS                           │
│    - Use strong random PSK                │
│                                             │
│ 2. Re-run PSKracker                        │
│    → Show it now FAILS                     │
│                                             │
│ 3. Document Best Practices                 │
│                                             │
│ OUTPUT: screenshots/06_hardening/           │
│         hardening_checklist.md              │
└─────────────────────────────────────────────┘
```

## 📁 Cấu trúc Thư mục Đề xuất

```
wireless/
├── README.md                          # Hướng dẫn tổng quan
├── ARCHITECTURE.md                    # File này
│
├── 01_setup/
│   ├── check_hardware.sh              # Script kiểm tra card WiFi
│   ├── install_dependencies.sh        # Cài đặt tools
│   └── stop_services.sh               # Dừng NetworkManager
│
├── 02_target/
│   ├── belkin/
│   │   ├── create_belkin_ap.sh       # Tạo Belkin fake AP
│   │   └── hostapd_belkin.conf       # Config template
│   └── netgear/
│       ├── create_netgear_ap.sh      # Tạo Netgear fake AP
│       ├── hostapd_netgear.conf      # Config template
│       └── gen_netgear_dict.py       # Generate password dict
│
├── 03_recon/
│   ├── enable_monitor.sh              # Enable monitor mode
│   ├── scan_networks.sh               # Passive scan
│   └── focus_target.sh                # Lock on specific AP
│
├── 04_attack/
│   ├── crack_belkin.sh                # Run PSKracker for Belkin
│   ├── crack_netgear.sh               # Dictionary attack for Netgear
│   └── capture_handshake.sh           # Capture 4-way handshake
│
├── 05_analysis/
│   ├── wireshark_filters.txt          # Pre-configured filters
│   ├── extract_ioc.py                 # Python script extract IoCs
│   ├── snort_rules.rules              # Snort detection rules
│   └── suricata_rules.yaml            # Suricata detection rules
│
├── 06_hardening/
│   ├── secure_ap_config.conf          # Hardened hostapd config
│   ├── compliance_checklist.md        # PCI-DSS checklist
│   └── test_mitigation.sh             # Verify PSKracker fails
│
├── captures/                           # Thư mục lưu .pcap files
│   └── .gitkeep
│
├── screenshots/                        # Thư mục ảnh báo cáo
│   ├── 01_environment/
│   ├── 02_target_belkin/
│   ├── 02_target_netgear/
│   ├── 03_recon/
│   ├── 04_attack/
│   ├── 05_analysis/
│   └── 06_hardening/
│
└── soc_artifacts/                      # Detection artifacts
    ├── iocs.json                       # Indicators of Compromise
    └── attack_timeline.md              # Timeline reconstruction
```

## 🎯 Execution Flow (Theo thứ tự chụp ảnh báo cáo)

### Scenario 1: Belkin Attack
```
1. Run: 01_setup/check_hardware.sh          → Screenshot 1
2. Run: 01_setup/install_dependencies.sh    → Screenshot 2
3. Run: 01_setup/stop_services.sh           → Screenshot 3
4. Run: 02_target/belkin/create_belkin_ap.sh → Screenshot 4
5. Run: 03_recon/enable_monitor.sh          → Screenshot 5
6. Run: 03_recon/scan_networks.sh           → Screenshot 6
7. Run: 04_attack/crack_belkin.sh           → Screenshot 7 ⭐
8. Open: Wireshark + apply filters          → Screenshot 8
9. Run: 05_analysis/extract_ioc.py          → Screenshot 9
10. Run: 06_hardening/test_mitigation.sh    → Screenshot 10
```

### Scenario 2: Netgear Attack
```
1-3. (Same setup as above)
4. Run: 02_target/netgear/gen_netgear_dict.py → Screenshot 11
5. Run: 02_target/netgear/create_netgear_ap.sh → Screenshot 12
6. Run: 04_attack/capture_handshake.sh         → Screenshot 13
7. Run: 04_attack/crack_netgear.sh             → Screenshot 14 ⭐
8. (Same analysis as above)
```

## 🔍 Key Verification Points (Để chụp ảnh)

| Phase | Command | Expected Output | Screenshot Purpose |
|-------|---------|-----------------|-------------------|
| Setup | `iw list` | "Supported interface modes: * AP * monitor" | Prove hardware capability |
| Setup | `which hostapd airmon-ng` | Paths to binaries | Show tools installed |
| Target | `hostapd -d config.conf` | "AP-ENABLED" | Prove AP is broadcasting |
| Recon | `airodump-ng wlan1mon` | Target AP visible with BSSID | Show reconnaissance |
| Attack | `./pskracker -t belkin -b XX:XX` | "Default Key: XXXXXXXX" | 🎯 KEY SCREENSHOT |
| Attack | `aircrack-ng -w dict.txt cap.cap` | "KEY FOUND! [password]" | 🎯 KEY SCREENSHOT |
| Analysis | Wireshark with `eapol` filter | 4-way handshake packets | Show traffic analysis |
| Analysis | `python3 extract_ioc.py` | JSON output with IoCs | Show SOC workflow |
| Hardening | `./pskracker` on secured AP | "Failed" or "No matches" | Prove mitigation works |

---

## 💡 Notes cho Báo cáo

- **Mỗi script chạy độc lập** → Dễ chụp ảnh từng bước
- **Output có màu sắc rõ ràng** → Screenshot đẹp
- **Có verify step** sau mỗi phase → Chứng minh thành công
- **Có cả success và failure cases** → Show critical thinking

---

## ⚠️ Disclaimer

Lab này chỉ thực hiện trên:
- ✅ Hardware của chính bạn
- ✅ Network do bạn tạo ra (hostapd)
- ❌ KHÔNG scan/attack mạng thật của người khác
