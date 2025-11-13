# Pull Request: Lab 10 — Vulnerability Management & Response with DefectDojo

## Goal

Set up a local DefectDojo instance, import scan results from multiple tools (Anchore Grype, Nuclei, Semgrep, Trivy Operator), and produce stakeholder-ready reporting and a metrics snapshot. This PR adds the submission summary and includes the generated report artifacts.

## Changes

- Added `labs/submission10.md` — lab submission and summary (English).
- Added `labs/lab10/pr_report.md` — ready-to-paste PR body (this file).
- Artifacts included under `labs/lab10/report/` (examples: `dojo-report.html`, `findings.csv`, `metrics-snapshot.md`).
- Importer files and import results are present under `labs/lab10/imports/` (the import script and JSON files used for the lab run).

Files touched / added in this branch:

- labs/submission10.md (new)
- labs/lab10/report/dojo-report.html (existing; verified)
- labs/lab10/report/findings.csv (existing; verified)
- labs/lab10/report/metrics-snapshot.md (existing; verified)
- labs/lab10/imports/run-imports.sh (existing)
- labs/lab10/imports/* (existing import JSON artifacts)

## Testing

Reproduce locally:

1. Start DefectDojo locally:

```bash
cd labs/lab10/setup/django-DefectDojo
docker compose build
docker compose up -d
```

2. Ensure the UI is reachable at `http://localhost:8080` and obtain an API v2 token from the admin Profile → API v2 Key.

3. Run the importer (it detects supported files under `labs/lab10/imports/` and posts them to DefectDojo):

```bash
export DD_API="http://localhost:8080/api/v2"
export DD_TOKEN="<your-api-token>"
bash labs/lab10/imports/run-imports.sh
```

4. In the UI, navigate to Product → Juice Shop → Engagements → Labs Security Testing. Verify imports show up in Findings and that the counts match the included `labs/lab10/report/findings.csv` and `metrics-snapshot.md`.

5. Recreate the Report Builder export if desired: Engagement → Reports → Report Builder → configure widgets (Cover Page, Table Of Contents, Findings, etc.) → set Report type = PDF or HTML → Run → save artifact to `labs/lab10/report/`.

## Artifacts & Screenshots

Included in this branch under `labs/lab10/report/`:

- `dojo-report.html` — Report Builder export (HTML)
- `findings.csv` — exported findings list (CSV)
- `metrics-snapshot.md` — captured metrics snapshot

Screenshots (for reference):

- Engagement page and Findings view screenshots are available in the lab workspace (visible in the PR artifacts / lab screenshots). These show the engagement summary, counts per severity and sample critical findings.

## Checklist
- [ ] Clear PR title (suggested title below)
- [ ] Doc update needed (if you want to add a top-level README change)
- [ ] No secrets or temporary large files committed (verify before merge)
- [x] Task 1 — DefectDojo local setup and admin login
- [x] Task 2 — Imports completed for available tools (Anchore Grype, Nuclei, Semgrep, Trivy Operator)
- [x] Task 3 — Reporting & metrics package (metrics snapshot, findings CSV, Report Builder export)

Suggested PR title:

"lab10: DefectDojo import and reporting — submission and artifacts"

Suggested PR description (copy the contents of `labs/submission10.md` or paste this file):

 - Short summary: DefectDojo was started locally, scan outputs were imported with `run-imports.sh`, and reporting artifacts were generated and saved under `labs/lab10/report/`. See `labs/submission10.md` for details.

Notes / Remarks:

- Please verify there are no environment-specific secrets or large binaries included in the branch. The included artifacts are HTML/CSV/MD and import JSON files used for the lab exercise.
- If you want the Report Builder artifact as PDF instead of HTML, re-run Report Builder and choose PDF or convert the HTML to PDF via browser Print → Save as PDF and add it to `labs/lab10/report/`.
