# APCloner v4.2 - WiFi Handshake Capture Tool

A non-intrusive wireless security assessment tool that captures WPA handshakes by creating cloned access point replicas. **Does not perform deauthentication attacks.**

## 📖 Description

APCloner creates multiple cloned replicas of a target access point, acting as WiFi honeypots to passively capture WPA handshakes when devices:
- Connect to the network for the first time
- Naturally reconnect due to signal fluctuations
- Perform periodic network checks

**Ethical Advantage:** Complies with wireless testing ethics by avoiding active client deauthentication.

## ✨ Features

- 🛡️ Stealth handshake capture methodology
- 📶 Creates 5 monitor interfaces
- 🎯 Automatic handshake detection & alerting
- 🖥️ Interactive menu and CLI modes
- 📊 Wireless network scanner integration
- 🎨 Colorized terminal interface
- 🔄 Automatic cleanup routines

## ⚠️ Legal Disclaimer

> **Warning:** This tool is intended for:
> - Educational purposes
> - Security research
> - Authorized penetration testing  
>
> Always obtain written permission before scanning or testing networks. Unauthorized use is illegal. Developers assume no liability for misuse.

## 📦 Dependencies

sudo apt install aircrack-ng xterm macchanger

⚙️ Installation

# 1. Clone repository
git clone https://github.com/deleyselem/apcloner.git
cd apcloner

# 2. Run installer
chmod +x install.sh
sudo ./install.sh

# 3. Start using
sudo apcloner

🚀 Usage
Interactive Mode

sudo apcloner

Follow the menu to:

    Scan for networks

    Select target AP

    Start cloning

Direct Execution

sudo apcloner [MAC] [SSID] [CHANNEL]

Example:
bash

sudo apcloner 00:11:22:33:44:55 "HomeWiFi" 6

Key Functions

    CTRL+C - Stop capture and clean up

    Handshakes saved as cap-*.cap

    Automatic process termination on successful capture

🔍 Technical Overview

![Screenshot From 2025-05-26 22-46-04](https://github.com/user-attachments/assets/b107e814-3daa-4e19-83be-42c33f713f08)


🤝 Contributing

    Fork the repository

    Create feature branch (git checkout -b feature/foo)

    Commit changes (git commit -am 'Add foo')

    Push branch (git push origin feature/foo)

    Open Pull Request

📜 License

GNU General Public License v3.0

Ethical Note: This tool demonstrates WPA vulnerability without network disruption. Always respect privacy laws and obtain proper authorization before use.


This README includes:
1. Clear ethical usage guidelines
2. Visual diagrams and formatting
3. Multiple installation/usage paths
4. Legal compliance warnings
5. Technical implementation details
6. Contribution guidelines
7. Dependency requirements

For complete functionality, users should add:
- Screenshots in `/assets`
- Detailed "Testing Methodology" section
- Wireless adapter compatibility list
- Troubleshooting guide
