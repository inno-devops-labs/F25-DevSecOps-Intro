## Goal

Generate governance-ready artifacts and a concise metrics snapshot for Lab 10. Import scanner outputs into the local DefectDojo instance, capture current counts by severity, produce a findings CSV for spreadsheet analysis, and prepare a short submission summarizing top CWE/OWASP categories and SLA exposure.

## Changes

- Updated `labs/submission10.md` with a paraphrased English Key Metrics report that uses actual data from the lab artifacts.
- Populated `labs/lab10/report/metrics-snapshot.md` with verified active counts by severity (snapshot date: Nov. 8, 2025).
- Inspected `labs/lab10/report/findings.csv` and used it as the primary data source for per-tool counts and CWE frequency. No scanner output files were modified.

## Testing

- Verified severity counts by reading `labs/lab10/report/metrics-snapshot.md`:
  - Critical: 8, High: 28, Medium: 41, Low: 1, Informational: 12.
- Counted scanner occurrences in `labs/lab10/report/findings.csv`:
  - Anchore Grype: 65
  - Semgrep JSON Report: 25
  - Trivy: 0 (no entries under the exact label "Trivy" in this CSV)
  - Nuclei: 0 (no entries under the exact label "Nuclei Scan")
  - ZAP: 0
- Confirmed SLA exposure by searching for the deadline `2025-11-19` in `findings.csv`: eight critical findings share that deadline (7 days after the snapshot date).
- Commands used locally during verification (examples):
  - Count scanner rows:
    ```bash
    grep -cF "Anchore Grype" labs/lab10/report/findings.csv
    ```
  - Count critical rows:
    ```bash
    grep -c ',Critical,' labs/lab10/report/findings.csv
    ```
  - Extract and count CWE values:
    ```bash
    awk -F, '{print $9}' labs/lab10/report/findings.csv | sed 's/^$/(none)/' | sort | uniq -c | sort -rn | head
    ```

## Artifacts & Screenshots

- `labs/submission10.md` — English Key Metrics report (paraphrased, uses real counts).
- `labs/lab10/report/metrics-snapshot.md` — metrics snapshot (Nov. 8, 2025) with severity totals and a short note on verified vs mitigated counts.
- `labs/lab10/report/findings.csv` — findings exported/available for spreadsheet analysis; used as the data source for per-tool and CWE counts.
- Optional: browser-generated report PDF/HTML (not included here). If generated via the Engagement -> Reports UI, save as `labs/lab10/report/dojo-report.pdf`.

## Checklist
- [x] Clear title
- [x] Docs updated if needed — `labs/submission10.md` and `labs/lab10/report/metrics-snapshot.md` updated.
- [x] No secrets/large temp files — verification used local CSV and markdown files only; no API tokens or other secrets were stored in repository files.

---

This file was created to capture the lab deliverables and verification steps in one place. If you want automatic snapshot generation from the DefectDojo API or re-import assistance (for example to ingest missing Trivy/Nuclei scans), tell me and I will add scripts and instructions.
