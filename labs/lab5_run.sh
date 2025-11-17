#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
OUT="$ROOT/labs/lab5"
SEM_OUT="$OUT/semgrep"
ZAP_OUT="$OUT/zap"
NUC_OUT="$OUT/nuclei"
NIK_OUT="$OUT/nikto"
SQL_OUT="$OUT/sqlmap"
ANA_OUT="$OUT/analysis"


# ---------- Task 2: DAST
echo "[+] Starting Juice Shop on :3000..."
docker rm -f juice-shop-lab5 >/dev/null 2>&1 || true
docker run -d --name juice-shop-lab5 -p 3000:3000 bkimminich/juice-shop:v19.0.0

echo "[+] Waiting for app to be ready..."
for i in {1..30}; do
  if docker run --rm --network host curlimages/curl:latest -fsS http://localhost:3000 >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "[+] Nuclei scan..."
docker run --rm --network host -v "$NUC_OUT":/app projectdiscovery/nuclei:latest \
  -u http://localhost:3000 -jsonl -o /app/nuclei-results.json

echo "[+] Nikto scan..."
docker run --rm --network host -v "$NIK_OUT":/tmp frapsoft/nikto:latest \
  -h http://localhost:3000 -o /tmp/nikto-results.txt

echo "[+] SQLmap probe..."
docker run --rm --network host -v "$SQL_OUT":/output parrotsec/sqlmap:latest \
  -u "http://localhost:3000/rest/products/search?q=apple" \
  --batch --level=3 --risk=2 --threads=5 \
  --output-dir=/output

# ---------- Analyses (jq required)
if ! command -v jq >/dev/null 2>&1; then
  echo "[!] 'jq' not found — analysis summaries will be minimal."
else
  echo "[+] Building SAST analysis..."
  {
    echo "=== SAST Analysis Report ==="
    echo -n "Semgrep results: "
    jq '.results | length' "$SEM_OUT/semgrep-results.json" 2>/dev/null || echo "0"
    echo
    echo "Top findings (rule_id : severity : file:line)"
    jq -r '.results[] | "\(.check_id) : \(.extra.severity) : \(.path):\(.start.line) — \(.extra.message)"' \
      "$SEM_OUT/semgrep-results.json" 2>/dev/null | head -n 20
  } > "$ANA_OUT/sast-analysis.txt"

  echo "[+] Building DAST analysis..."
  {
    echo "=== DAST Analysis Report ==="
    echo -n "ZAP findings: "
    jq '[.site[].alerts] | flatten | length' "$ZAP_OUT/zap-report.json" 2>/dev/null || echo "0"
    echo -n "Nuclei findings: "
    wc -l < "$NUC_OUT/nuclei-results.json" 2>/dev/null || echo "0"
    echo -n "Nikto findings: "
    (grep -c "^+" "$NIK_OUT/nikto-results.txt" 2>/dev/null) || echo "0"
    echo "SQLmap: see $SQL_OUT/"
  } > "$ANA_OUT/dast-analysis.txt"

  echo "[+] Building SAST/DAST correlation..."
  {
    echo "=== SAST/DAST Correlation Report ==="
    echo -n "SAST findings (Semgrep): "
    jq '.results | length' "$SEM_OUT/semgrep-results.json" 2>/dev/null || echo "0"
    echo -n "ZAP findings: "
    jq '[.site[].alerts] | flatten | length' "$ZAP_OUT/zap-report.json" 2>/dev/null || echo "0"
    echo -n "Nuclei findings: "
    wc -l < "$NUC_OUT/nuclei-results.json" 2>/dev/null || echo "0"
    echo -n "Nikto findings: "
    (grep -c "^+" "$NIK_OUT/nikto-results.txt" 2>/dev/null) || echo "0"
    echo "SQLmap: see $SQL_OUT/"
  } > "$ANA_OUT/correlation.txt"
fi

echo "[+] Stopping Juice Shop..."
docker rm -f juice-shop-lab5 >/dev/null 2>&1 || true

echo "[✓] Done. Artifacts in labs/lab5/"
