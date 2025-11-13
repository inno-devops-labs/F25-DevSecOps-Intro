# Lab 10 — Vulnerability Management & Response with DefectDojo

## Goal

The goal of this lab is to set up a local instance of OWASP DefectDojo, import vulnerability scan results from multiple security tools (ZAP, Semgrep, Trivy, Nuclei, and Grype), and generate a stakeholder-ready reporting and metrics package. This demonstrates the ability to aggregate findings, manage them across engagements, and communicate program status using metrics and reports.

## Setup summary

- DefectDojo was deployed locally using Docker Compose under `labs/lab10/setup/django-DefectDojo`.
- The initializer logs were used to obtain the admin credentials and the UI was reachable at `http://localhost:8080`.
- A Product Type (`Engineering`), Product (`Juice Shop`) and Engagement (`Labs Security Testing`) were created to store imported results.

## Imports overview

Imports were executed using the provided automation at `labs/lab10/imports/run-imports.sh`. The importer detected available scan files under `labs/lab10/imports/` and posted them to the DefectDojo API v2.

Tool | Scan type in Dojo | Findings imported | Notes
---|---:|---:|---
Anchore Grype | Anchore Grype | 65 | Anchore/Grype vulnerability results (package/container image vulnerabilities)
Nuclei | Nuclei Scan | 20 | Mostly informational/low severity template matches
Semgrep | Semgrep JSON | 25 | Rule-based code analysis findings
Trivy Operator | Trivy Scan | 0 | No findings in this particular Trivy Operator run

Combined, these imports created 110 active findings in the `Labs Security Testing` engagement (see `labs/lab10/report/findings.csv`).

> Note: ZAP was not present among the imports detected in `labs/lab10/imports/`. If you have a ZAP report, ensure it is exported in a supported format (XML for the community ZAP importer) and re-run the import script.

## Metrics snapshot

- Date captured: 2025-11-13
- Active findings (captured from Engagement dashboard):
  - Critical: 8
  - High: 28
  - Medium: 42
  - Low: 1
  - Informational: 31
- Verified vs Mitigated notes: Findings are in the active/verified state as imported; no mitigations were applied during this lab.

The metrics snapshot used to capture these numbers is saved at `labs/lab10/report/metrics-snapshot.md`.

## Key metrics and observations

- Open vs Closed: All 110 findings remain active after import; there are no mitigations or closures recorded in this lab exercise.
- Findings per tool: The majority of findings originate from Anchore Grype (65) and Semgrep (25), with Nuclei contributing 20 informational findings. Trivy Operator reported 0 findings for this run.
- SLA status: No SLA breaches observed — all findings are newly imported and fall within the initial response window.
- Severity distribution: Critical + High findings represent a meaningful portion of the total (36/110 ≈ 33%), indicating some high-impact dependency vulnerabilities.
- Top categories: Many findings are dependency and package-related issues (typical for Grype/Trivy), while Semgrep captures code-level patterns. These indicate remediation should prioritize dependency updates and image rebuilds.

## Deliverables included in this submission

- `labs/lab10/report/metrics-snapshot.md` — snapshot of counts captured from the Engagement dashboard.
- `labs/lab10/report/dojo-report.html` — Report Builder export (HTML).
- `labs/lab10/report/findings.csv` — exported findings list (CSV) for spreadsheet analysis.
- This submission file: `labs/submission10.md` — overview and summary bullets.

## How to reproduce

1. Start DefectDojo locally:

```bash
cd labs/lab10/setup/django-DefectDojo
docker compose build
docker compose up -d
```

2. Get an API token from the admin Profile → API v2 Key and export environment variables:

```bash
export DD_API="http://localhost:8080/api/v2"
export DD_TOKEN="<your-api-token>"
```

3. Run the importer (it will detect and import any supported files in `labs/lab10/imports/`):

```bash
bash labs/lab10/imports/run-imports.sh
```

4. Generate reports / export CSV from the UI: Engagement → select `Labs Security Testing` → Reports (Report Builder) or Findings → use the CSV / PDF buttons. Move saved artifacts to `labs/lab10/report/`.

## Notes / further work

- If you need an official PDF executive report, use the Report Builder and select `PDF` as the Report type (Report Builder screenshot and generated HTML are included in the lab report directory). 
- Next steps could include triage and mitigation (assign owners, create a timeline, and track fixes), and re-scanning images and code after fixes to validate remediation.

---

Lab completion checklist (for PR):

- [x] Task 1 — DefectDojo local setup and admin login
- [x] Task 2 — Imports completed for available tools (Anchore Grype, Nuclei, Semgrep, Trivy Operator)
- [x] Task 3 — Reporting & metrics package (metrics snapshot, findings CSV, Report Builder export)
