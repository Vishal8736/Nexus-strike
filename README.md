# Nexus-strike
NEXUS-STRIKE ⚡ NEXUS-STRIKE is an advanced automated pentesting framework designed for speed 🚀 and precision 🎯. It streamlines the entire attack lifecycle—from deep reconnaissance 🌍 and crawling 🕷️ to pattern matching 🔍 and targeted exploitation 💥—into one seamless workflow. Crafted with excellence by Vishal &amp; Subhi ❤️✨






# ⚡ NEXUS-STRIKE

<p align="center">
  <img src="https://img.shields.io/badge/Made%20with-BASH-blueviolet?style=for-the-badge&logo=gnu-bash" alt="Bash">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20Termux-blue?style=for-the-badge" alt="Platform">
  <img src="https://img.shields.io/badge/Version-4.0-green?style=for-the-badge" alt="Version">
</p>

<p align="center">
  <b>Advanced Automated Pentesting Framework</b>
  <br>
  <i>Reconnaissance | Crawling | Pattern Matching | Exploitation</i>
</p>

---

## 📖 Description

**NEXUS-STRIKE** is an advanced automated pentesting framework designed for speed 🚀 and precision 🎯. It streamlines the entire attack lifecycle—from deep reconnaissance 🌍 and crawling 🕷️ to pattern matching 🔍 and targeted exploitation 💥—into one seamless workflow.

It leverages industry-standard tools (like Nuclei, Katana, SQLMap) to provide a comprehensive security assessment with a single command.

✨ **Crafted with excellence by [Vishal8736](https://github.com/vishal8736) & Subhi ❤️**

---

## 🚀 Features

* **🕵️ Automated Recon:** Subdomain enumeration & live host detection (HTTPX, Subfinder).
* **🕷️ Deep Crawling:** Advanced JS and parameter crawling using **Katana**.
* **🎯 Smart Filtering:** GF patterns to identify SQLi, XSS, SSRF, RCE, and LFI parameters.
* **🔥 Vulnerability Scanning:** Automated CVE and misconfiguration scanning with **Nuclei** & **Nikto**.
* **⚔️ Auto-Exploitation:** Targeted exploitation using **SQLMap** (SQLi), **Commix** (Command Injection), and **SSTImap**.
* **📂 Organized Output:** clean directory structure for logs and results.

---

## 🛠️ Installation

### Prerequisites
* Linux (Kali/Ubuntu/Debian) or Termux
* Root privileges (sudo)

### 1️⃣ Clone the Repository
Open your terminal and run:

```bash
git clone [https://github.com/vishal8736/NEXUS-STRIKE.git](https://github.com/vishal8736/NEXUS-STRIKE.git)
cd NEXUS-STRIKE



chmod +x setup.sh
./setup.sh


chmod +x nexus_strike.sh
sudo ./nexus_strike.sh target.com

example :-

sudo ./nexus_strike.sh example.com


📂 Output Structure
All results are saved in a timestamped folder: nexus_results_YYYYMMDD_HHMMSS

nexus_results_.../
├── 1_recon/            # Subdomains, Ports, Live Hosts
├── 2_crawling/         # All extracted URLs
├── 3_parameters/       # Filtered params (SQLi, XSS, RCE, etc.)
├── 4_vuln_scan/        # Nuclei & Nikto reports
├── 5_exploitation/     # SQLMap & Commix results
└── logs/               # Execution logs


⚠️ Disclaimer
This tool is developed for educational purposes and legal penetration testing only.
Do not use this tool on targets you do not have permission to test.
The authors (Vishal & Subhi) are not responsible for any misuse or damage caused by this tool.
<p align="center">
<b>Developed with ❤️ by <a href="https://www.google.com/url?sa=E&source=gmail&q=https://github.com/vishal8736">Vishal8736</a> & Subhi</b>
</p>
