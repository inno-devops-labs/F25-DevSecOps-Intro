# Task 3 — Key metrics and findings (paraphrased)

## Open vs. Closed counts by severity


| Severity | Open | Closed |
| -------- | ----:| ------:|
| Critical |     8|       0|
| High     |    28|       0|
| Medium   |    41|       0|
| Low      |     1|       0|
| Info     |    12|       0|

These counts are taken from `labs/lab10/report/metrics-snapshot.md` . They reflect verified and active findings recorded in the snapshot; no closures were reported in that snapshot.

## Findings per tool

This section lists findings attributed to the primary scanners used in the assessment.

| Tool                | Findings |
| -------------------:| -------: |

| Grype (Anchore)     |      65  |
| Trivy               |       0  |
| Semgrep (JSON)      |      25  |
| Nuclei              |       0  |
| ZAP                 |       0* |

*ZAP shows no findings in the provided data set (or none were imported under the ZAP tool name).

## SLA breaches and short-term due items

- There are 8 open critical findings; the dataset shows these items with a deadline of 2025-11-19 (7 days from the capture date).
- Given the stated SLA, these critical items are at immediate risk of breaching if not triaged and remediated within the week.

## Top recurring CWE / OWASP categories (sorted by frequency)

The most frequently observed categories in the dataset are summarized below.

| CWE  | Count |
| ----:| -----:|

| (none/0) |   65 |
| 79       |    7 |
| 89       |    6 |
| 73       |    4 |
| 548      |    4 |
| 601      |    2 |
| 95       |    1 |
| 798      |    1 |

Note: many rows in the CSV use `0` or an empty field to indicate no CWE mapping; here that category is shown as `(none/0)`.

Note: a large fraction of findings did not map to a CWE identifier (listed as "(none)"), indicating either tool-specific categories, generic issues, or unmapped results.

## 3–5 concise observations (prose bullets)


- The open backlog is concentrated in higher severities: Critical (8) and High (28) should be treated as highest priority for triage.
- Anchore Grype is the dominant source of findings in the CSV (65 findings); Semgrep contributes important application-level findings (25). Trivy, Nuclei and ZAP entries are not present under those exact labels in the CSV sample.
- Eight critical items are due within one week (deadline 2025-11-19), representing an immediate SLA exposure that requires fast triage and assignment.
- A significant portion of records lack a CWE mapping (listed as `0` or empty), which reduces visibility into recurring weakness classes and complicates trend analysis.
- CWE-79 (Cross-Site Scripting) appears among the top identified CWEs and should be included in focused developer education and code review checks.

## Recommended next steps (brief)

1. Triage the 8 critical items immediately; apply containment or quick fixes where possible and assign owners.
2. Prioritize remediation work for Grype results affecting production images and infrastructure-as-code artifacts; reconcile any missing Trivy/Nuclei imports.
3. Normalize and enrich findings with CWE mappings and contextual metadata to enable better dashboards and trend analysis.
4. Re-run imports and verify that all expected scanner outputs (including any ZAP or Trivy reports) were ingested with correct tool mappings.

---

File prepared for submission. The tables above capture the requested counts and tool breakdowns; the short prose section provides a concise operational summary for reviewers.
