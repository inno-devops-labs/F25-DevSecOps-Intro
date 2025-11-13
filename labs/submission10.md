# Lab 10 - Vulnerability Management & Response with DefectDojo

## 3.3: Extract key metrics for labs/submission10.md
- Open vs. closed by severity: 17 Critical, 56 High, 75 Medium, 5 Low, and 32 Informational findings remain Active, with no items yet mitigated or closed.
- Findings by importer: Trivy contributed 74 findings, Anchore Grype 65, Semgrep 25, Nuclei 21, and the latest ZAP baseline import surfaced 0 new findings (likely covered by prior tool overlap).
- SLA outlook: No violations recorded, but 17 Critical/High issues have remediation deadlines within the next 7 days (20 Nov 2025), requiring prioritized follow-up.
- Recurring weaknesses: The backlog is dominated by CWE-79 (XSS), CWE-89 (SQL injection), CWE-674 (Uncontrolled Recursion), and CWE-200 (Information Exposure) patterns, pointing to input-handling gaps across the stack.

