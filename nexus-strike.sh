#!/bin/bash

################################################################################
#              NEXUS-STRIKE - Advanced Pentesting Methodology                  #
#         Recon | Crawling | Pattern Matching | Targeted Exploitation         #
#                     Author: Vishal8736 | Version: 4.0                        #
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Changed folder name to nexus_results
RESULTS_DIR="${SCRIPT_DIR}/nexus_results_$(date +%Y%m%d_%H%M%S)"
LOGS_DIR="${RESULTS_DIR}/logs"
SCREENSHOTS_DIR="${RESULTS_DIR}/screenshots"

# Check for Root
if [ "$EUID" -ne 0 ]; then 
  echo -e "\033[0;31m[-] This script must be run as root (use sudo).\033[0m"
  exit 1
fi

mkdir -p "${RESULTS_DIR}" "${LOGS_DIR}" "${SCREENSHOTS_DIR}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Changed log file name to nexus.log
log() { echo -e "${BLUE}[*]${NC} $1" | tee -a "${LOGS_DIR}/nexus.log"; }
success() { echo -e "${GREEN}[+]${NC} $1" | tee -a "${LOGS_DIR}/nexus.log"; }
error() { echo -e "${RED}[-]${NC} $1" | tee -a "${LOGS_DIR}/nexus.log"; }
warn() { echo -e "${YELLOW}[! ]${NC} $1" | tee -a "${LOGS_DIR}/nexus.log"; }

################################################################################
#                       PRE-FLIGHT CHECK                                       #
################################################################################

check_dependencies() {
    log "Checking dependencies..."
    # Added katana, naabu, gf, commix, sstimap, sqlmap
    local dependencies=(nmap naabu katana gf commix sstimap sqlmap nikto nuclei httpx subfinder assetfinder)
    
    for tool in "${dependencies[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            warn "Tool '$tool' is not installed. Some phases may fail."
        fi
    done
}

################################################################################
#             PHASE 1: RECON & PORT SCANNING (ProjectDiscovery Stack)        #
################################################################################

phase_1_recon_scanning() {
    log "================= PHASE 1: RECON & PORT SCANNING ================="
    local target="$1"
    local recon_dir="${RESULTS_DIR}/1_recon"
    mkdir -p "$recon_dir"
    
    # 1.1 - Subdomain Enumeration
    log "[1.1] Subdomain Enumeration..."
    subfinder -d "$target" -all -silent > "$recon_dir/subfinder.txt" 2>/dev/null || true
    assetfinder --subs-only "$target" > "$recon_dir/assetfinder.txt" 2>/dev/null || true
    cat "$recon_dir"/*.txt 2>/dev/null | sort -u > "$recon_dir/all_subdomains.txt"
    
    # 1.2 - Live Host Detection (HTTPX)
    log "[1.2] Detecting Live Hosts (HTTPX)..."
    httpx -l "$recon_dir/all_subdomains.txt" -silent -title -tech-detect -o "$recon_dir/live_hosts.txt" 2>/dev/null || true
    
    # 1.3 - Port Scanning (Naabu - ProjectDiscovery)
    log "[1.3] High Speed Port Scanning (Naabu)..."
    if command -v naabu &> /dev/null; then
        naabu -host "$target" -p - -rate 1000 -silent -o "$recon_dir/naabu_ports.txt" 2>/dev/null || true
    else
        log "Naabu not found, falling back to Nmap..."
        nmap -p- --min-rate=1000 -Pn "$target" -oN "$recon_dir/nmap_ports.txt" 2>/dev/null || true
    fi

    success "Phase 1 completed"
}

################################################################################
#          PHASE 2: DEEP CRAWLING (Katana)                                   #
################################################################################

phase_2_crawling() {
    log "================ PHASE 2: DEEP CRAWLING (KATANA) =================="
    local crawl_dir="${RESULTS_DIR}/2_crawling"
    mkdir -p "$crawl_dir"
    
    local live_hosts="${RESULTS_DIR}/1_recon/live_hosts.txt"
    
    # Check if we have live hosts, else use target
    if [ ! -s "$live_hosts" ]; then
        echo "http://$1" > "$live_hosts"
    fi
    
    log "[2.1] Running Katana for deep crawling..."
    # Crawling JS, parameters, and endpoints
    katana -list "$live_hosts" -d 5 -jc -kf -aff -o "$crawl_dir/all_urls.txt" 2>/dev/null || true
    
    success "Phase 2 Crawling completed. URLs saved to $crawl_dir/all_urls.txt"
}

################################################################################
#          PHASE 3: PATTERN MATCHING & FILTERING (GF)                        #
################################################################################

phase_3_pattern_matching() {
    log "================ PHASE 3: PARAMETER FILTERING (GF) ==================="
    local crawl_file="${RESULTS_DIR}/2_crawling/all_urls.txt"
    local gf_dir="${RESULTS_DIR}/3_parameters"
    mkdir -p "$gf_dir"
    
    if [ ! -f "$crawl_file" ]; then
        error "No crawled URLs found. Skipping Phase 3."
        return
    fi
    
    log "[3.1] Filtering URLs for interesting parameters using GF..."
    
    # GF: SQL Injection
    cat "$crawl_file" | gf sqli > "$gf_dir/potential_sqli.txt" || true
    log " -> Found $(wc -l < "$gf_dir/potential_sqli.txt") potential SQLi endpoints"

    # GF: XSS
    cat "$crawl_file" | gf xss > "$gf_dir/potential_xss.txt" || true
    
    # GF: SSRF
    cat "$crawl_file" | gf ssrf > "$gf_dir/potential_ssrf.txt" || true
    
    # GF: RCE / Command Injection (Looking for params like cmd, exec)
    # If gf rce pattern doesn't exist, use grep fallback
    if gf -list | grep -q "rce"; then
        cat "$crawl_file" | gf rce > "$gf_dir/potential_rce.txt" || true
    else
        grep -E "cmd=|exec=|command=|ping=|query=|file=" "$crawl_file" > "$gf_dir/potential_rce.txt" || true
    fi
    
    # GF: LFI
    cat "$crawl_file" | gf lfi > "$gf_dir/potential_lfi.txt" || true
    
    success "Phase 3 Pattern Matching completed"
}

################################################################################
#          PHASE 4: VULNERABILITY SCANNING (Nuclei & Nikto)                  #
################################################################################

phase_4_vuln_scanning() {
    log "================ PHASE 4: GENERAL VULNERABILITY SCANNING ============="
    local scan_dir="${RESULTS_DIR}/4_vuln_scan"
    mkdir -p "$scan_dir"
    local live_hosts="${RESULTS_DIR}/1_recon/live_hosts.txt"

    # 4.1 - Nuclei
    log "[4.1] Running Nuclei (ProjectDiscovery)..."
    nuclei -l "$live_hosts" -t cves/ -t vulnerabilities/ -t misconfiguration/ \
           -o "$scan_dir/nuclei_results.txt" 2>/dev/null || true

    # 4.2 - Nikto
    log "[4.2] Running Nikto Web Scanner..."
    while IFS= read -r url; do
        safe_name=$(echo "$url" | sed 's/[:\/]/_/g')
        # Limiting Nikto time to avoid infinite scans
        nikto -h "$url" -maxtime 10m -o "$scan_dir/nikto_${safe_name}.txt" 2>/dev/null || true
    done < "$live_hosts"
    
    success "Phase 4 Vulnerability Scanning completed"
}

################################################################################
#          PHASE 5: TARGETED EXPLOITATION (SQLMap, Commix, SSTImap)          #
################################################################################

phase_5_exploitation() {
    log "================ PHASE 5: TARGETED EXPLOITATION ======================"
    local exploit_dir="${RESULTS_DIR}/5_exploitation"
    mkdir -p "$exploit_dir"
    local gf_dir="${RESULTS_DIR}/3_parameters"
    
    # 5.1 - SQLMap (SQL Injection)
    if [ -s "$gf_dir/potential_sqli.txt" ]; then
        log "[5.1] Testing for SQL Injection (SQLMap)..."
        # Taking top 20 URLs to avoid taking forever. You can remove 'head' for full scan.
        head -n 20 "$gf_dir/potential_sqli.txt" > "$exploit_dir/sqli_targets.txt"
        
        while IFS= read -r url; do
            log " -> SQLMap testing: $url"
            sqlmap -u "$url" --batch --dbs --random-agent --level 1 --risk 1 \
                   --output-dir="$exploit_dir/sqlmap_results" 2>/dev/null || true
        done < "$exploit_dir/sqli_targets.txt"
    else
        log "No SQLi candidates found to exploit."
    fi
    
    # 5.2 - Commix (Command Injection)
    if [ -s "$gf_dir/potential_rce.txt" ]; then
        log "[5.2] Testing for Command Injection (Commix)..."
        head -n 10 "$gf_dir/potential_rce.txt" > "$exploit_dir/rce_targets.txt"
        
        while IFS= read -r url; do
            log " -> Commix testing: $url"
            commix --url="$url" --batch --output-dir="$exploit_dir/commix_results" 2>/dev/null || true
        done < "$exploit_dir/rce_targets.txt"
    fi
    
    # 5.3 - SSTImap (Server Side Template Injection)
    # Using the same list as RCE/XSS as potential candidates if no specific SSTI list
    if [ -s "$gf_dir/potential_xss.txt" ]; then
        log "[5.3] Testing for SSTI (SSTImap)..."
        head -n 10 "$gf_dir/potential_xss.txt" > "$exploit_dir/ssti_targets.txt"
        
        while IFS= read -r url; do
            log " -> SSTImap testing: $url"
            sstimap -u "$url" --output "$exploit_dir/sstimap_results.txt" 2>/dev/null || true
        done < "$exploit_dir/ssti_targets.txt"
    fi

    success "Phase 5 Exploitation attempts completed"
}

################################################################################
#                         MAIN EXECUTION FLOW                                  #
################################################################################

if [ "$#" -ne 1 ]; then
    echo -e "${YELLOW}Usage: $0 <target_ip_or_domain>${NC}"
    exit 1
fi

TARGET="$1"
log "Starting NEXUS-STRIKE V4.0 (Full Stack) on target: $TARGET"

check_dependencies
phase_1_recon_scanning "$TARGET"
phase_2_crawling "$TARGET"
phase_3_pattern_matching
phase_4_vuln_scanning
phase_5_exploitation

success "ALL PHASES COMPLETED. Results saved in: $RESULTS_DIR"

