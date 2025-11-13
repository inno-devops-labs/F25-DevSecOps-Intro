# Task 3
## Key metrics

### Open vs. Closed counts by severity.
| Severity | Open | Closed |
| -------- | ---- | ------ |
| Critical | 17   | 0      |
| High     | 55   | 0      |
| Medium   | 75   | 0      |
| Low      | 5    | 0      |
| Info     | 33   | 0      |

### Findings per tool (ZAP, Semgrep, Trivy, Nuclei, and Grype).
| Tool                | Findings |
| ------------------- | -------- |
| Anchore Grype       | 65       |
| Nuclei Scan         | 23       |
| Semgrep JSON Report | 25       |
| Trivy Scan          | 72       |

### Any SLA breaches or items due within the next 14 days.
The 17 critical findings are due in 7 days.

### Top recurring CWE/OWASP categories.

Here is the top-11 of OWASP categories:

| CWE  | count |
| ---- | ----- |
| None | 97    |
| 79   | 10    |
| 200  | 7     |
| 89   | 6     |
| 674  | 6     |
| 20   | 4     |
| 400  | 4     |
| 248  | 4     |
| 73   | 4     |
| 548  | 4     |
| 287  | 4     |

### Summary
- There is a substantial amount of High and Critical findings.
- Trivy reported the most findings.
- In 7 days, the devs will have to investigate 17 critical vulnerabilities to not violate the SLA.
- Most findings are not in the Common Weaknesses Enumeration; the most common **identified** category is #79 (Cross-Site
  Scripting)
