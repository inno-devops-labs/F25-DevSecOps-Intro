# Reporting & Program Metrics

- **Open vs Closed Findings (182 / 0)**:
  - Critical: 17
  - High: 55
  - Medium: 76
  - Low: 5
  - Informational: 29
  - Note: backlog remains entirely open; triage pipeline should prioritize the critical/high group.

- **Findings by ingestion source**:
  - ZAP: 0 (no authenticated scan in this batch)
  - Semgrep: 25
  - Trivy: 74
  - Nuclei: 18
  - Grype: 65
  - Observation: Container and dependency scanning account for ~76% of results.

- **Tickets approaching SLA**:
  - 17 items either past due or due within the next 14 days; coordinate with product owners for remediation plans.

- **Recurring CWE / OWASP themes**:
  - CWE-89 (SQL Injection)
  - CWE-79 (Cross-Site Scripting)
  - CWE-73 (External File Access)
  - CWE-548 (Information Exposure via Directory Listing)
  - CWE-674 (Uncontrolled Recursion)
  - Additional note: concentration of CWE-79 findings in Semgrep output suggests shared remediation guidance could accelerate fixes.
