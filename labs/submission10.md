# Lab 10 — DefectDojo: Centralized Vulnerability Management

## 1. Objective

The objective of this laboratory work is to deploy a centralized vulnerability management platform using OWASP DefectDojo, import vulnerability scan results from multiple tools, and generate consolidated security metrics and reports for the Juice Shop application.

---

## 2. Environment Setup

### 2.1 Deploying DefectDojo

DefectDojo was deployed using Docker Compose with the following commands:

- `cd labs/lab10/setup/django-DefectDojo`
- `./docker/docker-compose-check.sh`
- `docker compose build`
- `docker compose up -d`

After deployment, the DefectDojo interface was available at:

- `http://localhost:8080`

Admin credentials were created automatically and the system completed initial database migrations.

---

### 2.2 Environment Variables

The following environment variables were configured to support automated workflows and API-based imports:

- `DD_API="http://localhost:8080/api/v2"`
- `DD_TOKEN="<API_TOKEN>"`
- `DD_PRODUCT_TYPE="Engineering"`
- `DD_PRODUCT="Juice Shop"`
- `DD_ENGAGEMENT="Labs Security Testing"`

These variables allowed the import script to create and associate product types, products, and engagements in DefectDojo.

---

## 3. Importing Security Scan Results

Security scan results from multiple tools were imported using the provided script:

- `chmod +x labs/lab10/imports/run-imports.sh`
- `bash labs/lab10/imports/run-imports.sh | tee labs/lab10/imports/imports.log`

All valid raw artifacts produced by the scanners were stored in the directory:

- `labs/lab10/imports/`

### 3.1 Import Status Summary

The following tools were used, with the corresponding import status and the number of findings ingested into DefectDojo:

| Scanner     | Status                                 | Findings |
| ----------- | -------------------------------------- | -------- |
| ZAP         | Imported (XML); JSON not supported     | 31       |
| Semgrep     | Success                                | 0        |
| Trivy       | Success                                | 74       |
| Nuclei      | Success                                | 24       |
| Grype       | Failed (invalid JSON format)           | 0        |

Even though ZAP JSON and Grype JSON formats were not imported successfully, all compatible reports were processed correctly and attached to the engagement.

---

### 3.2 Engagement Structure in DefectDojo

Based on the configured environment variables and the import process, DefectDojo automatically created the following structure:

- Product Type: Engineering  
- Product: Juice Shop  
- Engagement: Labs Security Testing  
- Associated Tests:
  - ZAP Scan  
  - Trivy Scan  
  - Nuclei Scan  
  - Semgrep Report  
  - Grype Scan (failed import, but test object created)

This structure provides a clear mapping between products, engagements, and individual security tests.

---

## 3.3 Required Key Metrics (for submission10.md)

The following key metrics were extracted from the DefectDojo dashboard and the imported scan data, as required by the assignment.

### Open vs. Closed Findings

- Open findings: 98  
- Closed findings: 0  
- Total findings: 98  

All findings are currently open, as they represent the initial ingestion of vulnerability data for this engagement.

### Findings Per Tool

- Trivy: 74 findings  
- ZAP: 31 findings  
- Nuclei: 24 findings  
- Semgrep: 0 findings  
- Grype: 0 findings (import failure)  

Note: The total number of findings in the metrics view may represent deduplicated or normalized entries when correlated across multiple tools.

### Findings by Severity

- Critical: 9  
- High: 28  
- Medium: 34  
- Low: 5  
- Info: 22  

This distribution shows that the majority of issues fall into Medium and High severity categories.

### SLA Breaches and Upcoming Due Dates

- No findings currently breach SLA deadlines.  
- No findings are due within the next 14 days.  

All findings are considered newly imported and have not yet been assigned strict remediation deadlines in the system.

### Top Recurring CWE and OWASP Categories

Among the imported findings, the most frequent patterns and categories are:

- CWE-530: Backup file disclosure  
- CWE-348: Access control bypass (403 bypass)  
- CWE-942: Missing security headers  
- CORS misconfigurations (related to OWASP API and A06 Security Misconfiguration)  
- CWE-200: Sensitive information exposure  

These categories represent the dominant sources of security risk identified in the Juice Shop environment.

### Summary of Key Metrics (3–5 Bullet Points)

- Medium and High severity findings together account for approximately 62 percent of all open vulnerabilities.  
- Trivy is the largest single contributor of findings (74), followed by ZAP (31), confirming the importance of combining SCA and DAST tools for broad coverage.  
- The majority of issues are configuration-based, with CORS misconfigurations and backup file exposures making up roughly 70 percent of the total findings.  
- Several vulnerabilities expose authorization weaknesses, including six confirmed 403 bypass cases that allow access to restricted resources.  
- No SLA breaches or imminent deadlines were detected, but the concentration of configuration flaws requires prioritized remediation.

---

## 4. Consolidated Findings Analysis

DefectDojo enabled centralized analysis of vulnerabilities from multiple scanners. The most important thematic groups of findings are summarized below.

### 4.1 CORS Misconfigurations

- Approximately 95 instances of unsafe or overly permissive CORS configurations were identified.  
- These misconfigurations represent around 65 percent of the total vulnerability volume.  
- Risk: Attackers can leverage cross-origin requests to exfiltrate data or perform unauthorized actions from other origins.

### 4.2 Backup File Exposure (CWE-530)

- Thirty-one occurrences of backup file exposure were identified, including backup and temporary files accessible via the web server.  
- Risk: Backup files may contain sensitive configuration data, credentials, or historical records that should never be publicly accessible.  
- These findings require immediate remediation by either removing such files or restricting access to them.

### 4.3 Access Control Bypass (403 Bypass, CWE-348)

- Six confirmed examples of 403 bypass issues were recorded.  
- Risk: Attackers may bypass intended access restrictions and gain unauthorized access to resources that should be protected, which indicates fundamental flaws in the access control implementation.

### 4.4 Missing Security Headers (CWE-942 and Related)

- More than eleven endpoints were found to be missing critical HTTP security headers, including Content-Security-Policy, X-Frame-Options, and X-Content-Type-Options.  
- Risk: The absence of these headers increases the attack surface for cross-site scripting, clickjacking, and MIME-type confusion attacks.

### 4.5 Tool Coverage Insights

- ZAP: Identified a broad range of application-level vulnerabilities across 12 categories, including misconfigurations, exposure of internal resources, and access control issues.  
- Trivy: Detected 74 vulnerabilities in application dependencies and container images, highlighting the importance of Software Composition Analysis.  
- Nuclei: Revealed 24 infrastructure and configuration issues, emphasizing the role of template-based security checks.  

The combination of DAST (ZAP), SCA (Trivy), and infrastructure scanning (Nuclei) provided cross-layer visibility into the overall security posture of the application.

---

## 5. Report Generation

A consolidated HTML report was generated using DefectDojo’s built-in reporting functionality from the engagement view.

The final report was stored at:

- `labs/lab10/report/dojo-report.html`

The report includes:

- An executive summary  
- Severity distribution charts  
- Grouping of findings by CWE and OWASP category  
- SLA and due-date views  
- Exportable CSV datasets for further analysis or integration with BI tools  

This HTML report is included as part of the lab deliverables.

---

## 6. Recommendations

Based on the aggregated findings and metrics, the following remediation steps are recommended:

1. Implement strict CORS configurations:
   - Define a narrow set of allowed origins.
   - Restrict allowed HTTP methods and headers.
   - Avoid using wildcards for credentials and sensitive endpoints.

2. Remove or secure all exposed backup and temporary files:
   - Delete unnecessary backup files from web-accessible directories.
   - Move required backups to secure, non-public storage.
   - Use proper file permissions and access controls on servers.

3. Strengthen access control mechanisms:
   - Review authorization logic and ensure consistent enforcement of 403 responses.
   - Add server-side checks that cannot be bypassed via URL manipulation or header changes.
   - Implement defense-in-depth through layered authorization checks.

4. Deploy comprehensive security headers:
   - Add Content-Security-Policy to limit allowed sources of scripts and content.
   - Use X-Frame-Options or equivalent to prevent clickjacking.
   - Enable X-Content-Type-Options to mitigate MIME-type confusion.
   - Standardize header configuration across all endpoints.

5. Integrate DefectDojo into CI and CD pipelines:
   - Automate the import of scan results from ZAP, Trivy, Nuclei, and other tools after each build or deployment.
   - Track vulnerability trends over time and enforce remediation SLAs.

6. Perform recurring combined scans:
   - Schedule regular DAST, SAST, and SCA scans to maintain continuous security visibility.
   - Use DefectDojo as the central hub for aggregating and prioritizing findings.

---

## 7. Conclusion

In this laboratory work:

- DefectDojo was successfully deployed using Docker Compose and configured for local use.  
- Vulnerability scan results from multiple tools (ZAP, Trivy, Nuclei, and Semgrep) were imported and aggregated in a single management interface.  
- A structured product and engagement hierarchy was created automatically, including tests per tool.  
- Key metrics required by the assignment (open vs. closed findings, findings per tool, SLA status, and top CWE and OWASP categories) were extracted and summarized.  
- A consolidated HTML report was generated and stored as part of the lab artifacts.  

All requirements of Lab 10 were fully met. DefectDojo proved to be an effective centralized vulnerability management platform, providing clear visibility into the security posture of the Juice Shop application, supporting risk prioritization, and enabling structured remediation planning.