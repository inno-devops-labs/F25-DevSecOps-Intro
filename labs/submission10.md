# DefectDojo Vulnerability Management — Lab 10 Report

## Setup

* DefectDojo deployed locally via Docker Compose (`labs/lab10/setup/django-DefectDojo`)
* Admin credentials obtained; UI at [http://localhost:8080](http://localhost:8080)
* Product hierarchy created: Product Type `Engineering`, Product `Juice Shop`, Engagement `Labs Security Testing`

---

## Imported Findings

| Tool           | Scan type     | Findings | Notes                              |
| -------------- | ------------- | -------- | ---------------------------------- |
| Anchore Grype  | Anchore Grype | 65       | Dependency/package vulnerabilities |
| Semgrep        | Semgrep JSON  | 25       | Code analysis findings             |
| Nuclei         | Nuclei Scan   | 20       | Mostly low severity                |
| Trivy Operator | Trivy Scan    | 0        | No findings this run               |

> Total active findings: 110 (`labs/lab10/report/findings.csv`)

---

## Observations

* **CORS issues**: 95 medium-severity misconfigurations
* **Backup file disclosure**: 31 cases (CWE-530)
* **Access control**: 6 instances of 403 bypass
* **Security headers**: missing or deprecated headers on multiple endpoints
* **Tool insights**: Majority of findings from Grype (dependencies), Semgrep (code), Nuclei (informational)

---

## Key Metrics

* **Open Findings by Severity**: Critical: 8, High: 28, Medium: 42, Low: 1, Informational: 31
* **Verified vs. Mitigated**: All 110 active; none mitigated
* **Findings per Tool**: Grype: 65, Semgrep: 25, Nuclei: 20, Trivy: 0
* **SLA / Upcoming**: No breaches; all within response window
* **Top Categories**: Dependency/package issues (Grype), code patterns (Semgrep); Critical/High ≈ 33%

---

## Recommendations

* Enforce strict CORS policies
* Secure/remove exposed backup directories
* Harden access control for restricted resources
* Apply modern security headers consistently
* Prioritize high-impact dependency/package updates
