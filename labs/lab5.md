# Lab 5 — Security Analysis: SAST & DAST of OWASP Juice Shop

![difficulty](https://img.shields.io/badge/difficulty-intermediate-orange)
![topic](https://img.shields.io/badge/topic-SAST%20%26%20DAST-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Perform Static Application Security Testing (SAST) using Semgrep and Dynamic Application Security Testing (DAST) using multiple tools (ZAP, Nuclei, Nikto, SQLmap) against OWASP Juice Shop to identify security vulnerabilities and compare tool effectiveness.  
> **Deliverable:** A PR from `feature/lab5` to the course repo with `labs/submission5.md` containing SAST findings, DAST results from multiple tools, and security recommendations. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Performing **Static Application Security Testing (SAST)** with **Semgrep** using Docker containers
- Conducting **Dynamic Application Security Testing (DAST)** using multiple specialized tools
- **Tool comparison analysis** between different DAST tools (ZAP, Nuclei, Nikto, SQLmap)
- **Vulnerability correlation** between SAST and DAST findings
- **Security tool selection** for different vulnerability types

These skills are essential for DevSecOps integration and security testing automation.

> Use the OWASP Juice Shop (`bkimminich/juice-shop:v19.0.0`) as your target application, with access to its source code for SAST analysis.

---

## Tasks

### Task 1 — Static Application Security Testing with Semgrep (3 pts)

**Objective:** Perform SAST analysis using Semgrep to identify security vulnerabilities in the OWASP Juice Shop source code.

#### 1.1: Setup SAST Environment

1. **Prepare Working Directory and Clone Source:**

   ```bash
   mkdir -p labs/lab5/{semgrep,zap,nuclei,nikto,sqlmap,analysis}
   git clone https://github.com/juice-shop/juice-shop.git --depth 1 --branch v19.0.0 labs/lab5/semgrep/juice-shop
   ```

#### 1.2: SAST Analysis with Semgrep

1. **Run Semgrep Security Scan:**

   ```bash
   docker run --rm -v "$(pwd)/labs/lab5/semgrep/juice-shop":/src \
     -v "$(pwd)/labs/lab5/semgrep":/output \
     semgrep/semgrep:latest \
     semgrep --config=p/security-audit --config=p/owasp-top-ten \
     --json --output=/output/semgrep-results.json /src

   # Generate human-readable security report
   docker run --rm -v "$(pwd)/labs/lab5/semgrep/juice-shop":/src \
     -v "$(pwd)/labs/lab5/semgrep":/output \
     semgrep/semgrep:latest \
     semgrep --config=p/security-audit --config=p/owasp-top-ten \
     --text --output=/output/semgrep-report.txt /src
   ```

#### 1.3: SAST Results Analysis

1. **Analyze SAST Results:**

   ```bash
   echo "=== SAST Analysis Report ===" > labs/lab5/analysis/sast-analysis.txt
   jq '.results | length' labs/lab5/semgrep/semgrep-results.json >> labs/lab5/analysis/sast-analysis.txt
   ```

In `labs/submission5.md`, document:
- **SAST Tool Effectiveness** - Semgrep's detection capabilities
- **Critical Vulnerability Analysis** - 5 SAST findings with file locations

---

### Task 2 — Dynamic Application Security Testing with Multiple Tools (5 pts)

**Objective:** Perform DAST analysis using ZAP and specialized tools (Nuclei, Nikto, SQLmap) to compare their effectiveness.

#### 2.1: Setup DAST Environment

1. **Start OWASP Juice Shop:**

   ```bash
   docker run -d --name juice-shop-lab5 -p 3000:3000 bkimminich/juice-shop:v19.0.0
   ```

#### 2.2: OWASP ZAP Scanning

1. **ZAP Full Scan:**

   ```bash
   docker run --rm -v "$(pwd)/labs/lab5/zap":/zap/wrk/:rw \
     --network host zaproxy/zap-stable:latest \
     zap-full-scan.py -t http://localhost:3000 -J zap-report.json
   ```

#### 2.3: Multi-Tool Specialized Scanning

1. **Nuclei Template-Based Scan:**

   ```bash
   docker run --rm --network host \
     -v "$(pwd)/labs/lab5/nuclei":/app \
     projectdiscovery/nuclei:latest \
     -u http://localhost:3000 \
     -jsonl -o /app/nuclei-results.json
   ```

2. **Nikto Web Server Scan:**

   ```bash
   docker run --rm --network host \
     -v "$(pwd)/labs/lab5/nikto":/tmp \
     frapsoft/nikto:latest \
     -h http://localhost:3000 -o /tmp/nikto-results.txt
   ```

3. **SQLmap SQL Injection Test:**

   ```bash
   docker run --rm --network host \
     -v "$(pwd)/labs/lab5/sqlmap":/output \
     parrotsec/sqlmap:latest \
     -u "http://localhost:3000/rest/products/search?q=apple" \
     --batch \
     --level=3 \
     --risk=2 \
     --threads=5 \
     --output-dir=/output
   ```

#### 2.4: DAST Results Analysis

1. **Compare Tool Results:**

   ```bash
   echo "=== DAST Analysis Report ===" > labs/lab5/analysis/dast-analysis.txt
   
   # Count findings from each tool
   zap_count=$(jq '.site[].alerts | length' labs/lab5/zap/zap-report.json 2>/dev/null || echo "0")
   nuclei_count=$(wc -l < labs/lab5/nuclei/nuclei-results.json 2>/dev/null || echo "0")
   nikto_count=$(grep -c "+ " labs/lab5/nikto/nikto-results.txt 2>/dev/null || echo "0")
   
   echo "ZAP findings: $zap_count" >> labs/lab5/analysis/dast-analysis.txt
   echo "Nuclei findings: $nuclei_count" >> labs/lab5/analysis/dast-analysis.txt
   echo "Nikto findings: $nikto_count" >> labs/lab5/analysis/dast-analysis.txt
   echo "SQLmap: Check output directory for results" >> labs/lab5/analysis/dast-analysis.txt
   ```



In `labs/submission5.md`, document:
- **Tool Comparison** - effectiveness of ZAP vs Nuclei vs Nikto vs SQLmap
- **Tool Strengths** - what each tool excels at detecting
- **DAST Findings** - explain at least 1 finding from each tools

---

### Task 3 — SAST/DAST Correlation and Security Assessment (2 pts)

**Objective:** Correlate findings from SAST and DAST approaches to provide comprehensive security assessment.

#### 3.1: SAST/DAST Correlation

1. **Create Correlation Analysis:**

   ```bash
   echo "=== SAST/DAST Correlation Report ===" > labs/lab5/analysis/correlation.txt
   
   # Count all findings
   sast_count=$(jq '.results | length' labs/lab5/semgrep/semgrep-results.json 2>/dev/null || echo "0")
   zap_count=$(jq '.site[].alerts | length' labs/lab5/zap/zap-report.json 2>/dev/null || echo "0")
   nuclei_count=$(wc -l < labs/lab5/nuclei/nuclei-results.json 2>/dev/null || echo "0")
   
   echo "SAST findings: $sast_count" >> labs/lab5/analysis/correlation.txt
   echo "ZAP findings: $zap_count" >> labs/lab5/analysis/correlation.txt
   echo "Nuclei findings: $nuclei_count" >> labs/lab5/analysis/correlation.txt
   echo "Nikto findings: $(grep -c '+ ' labs/lab5/nikto/nikto-results.txt 2>/dev/null || echo '0')" >> labs/lab5/analysis/correlation.txt
   echo "SQLmap: Check results in sqlmap directory" >> labs/lab5/analysis/correlation.txt
   ```



In `labs/submission5.md`, document:
- **SAST vs DAST Findings** - unique discoveries from each approach, describe obvious diff
- **Integrated Security Recommendations** - how to use both approaches effectively

---

## Acceptance Criteria

- ✅ Branch `feature/lab5` exists with commits for each task.
- ✅ File `labs/submission5.md` contains required analysis for Tasks 1-3.
- ✅ SAST analysis completed with Semgrep.
- ✅ DAST analysis completed with ZAP and specialized tools.
- ✅ SAST/DAST correlation analysis completed.
- ✅ All generated reports, configurations, and analysis files committed.
- ✅ PR from `feature/lab5` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.

---

## How to Submit

1. Create a branch for this lab and push it to your fork:

   ```bash
   git switch -c feature/lab5
   # create labs/submission5.md with your findings
   git add labs/submission5.md labs/lab5/
   git commit -m "docs: add lab5 submission - SAST/multi-approach DAST security analysis"
   git push -u origin feature/lab5
   ```

2. Open a PR from your fork's `feature/lab5` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 done — SAST Analysis with Semgrep
   - [x] Task 2 done — DAST Analysis (ZAP + Nuclei + Nikto + SQLmap)
   - [x] Task 3 done — SAST/DAST Correlation
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Rubric (10 pts)

| Criterion                                                        | Points |
| ---------------------------------------------------------------- | -----: |
| Task 1 — SAST with Semgrep + basic analysis                     |  **3** |
| Task 2 — DAST analysis (ZAP + Nuclei + Nikto + SQLmap) + comparison |  **5** |
| Task 3 — SAST/DAST correlation + recommendations               |  **2** |
| **Total**                                                        | **10** |

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission5.md`.
- Document all commands used and any issues encountered with different tools.
- Focus on practical insights about when to use each tool in a DevSecOps workflow.
- Provide actionable security recommendations based on findings.

> **Tool Comparison**  
> 1. **ZAP**: Comprehensive web application scanner with integrated reporting  
> 2. **Nuclei**: Fast template-based vulnerability scanner  
> 3. **Nikto**: Web server vulnerability scanner  
> 4. **SQLmap**: Specialized SQL injection testing tool  
> 5. **Semgrep**: Static analysis for code-level vulnerability detection

> **Tool Selection Guidelines**  
> 1. **ZAP**: Best for comprehensive web app testing  
> 2. **Nuclei**: Fast scanning with community templates  
> 3. **Nikto**: Web server specific vulnerabilities  
> 4. **SQLmap**: SQL injection focused testing  
> 5. **Semgrep**: Code-level security analysis
