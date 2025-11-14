# DefectDojo Vulnerability Management — Lab 10 Report

## Environment Setup and Configuration

DefectDojo was deployed locally using Docker Compose to centralize vulnerability data. After deployment:

- The admin account was set up and confirmed.
- The interface was accessible at http://localhost:8080.
- A product structure was created to organize all Juice Shop testing results.

This ensured all imported findings were properly categorized.

## Imported Security Data

Multiple scan outputs were uploaded into DefectDojo, including:

- A ZAP JSON report containing backup-file-related findings.
- Additional reports from Semgrep, Trivy, and Nuclei.

All uploaded files were stored under `labs/lab10/imports/`. DefectDojo processed and normalized the input from each scanner, grouping findings by severity and type.

## Observations from Combined Findings

Based on the 110 total active findings recorded in the DefectDojo metrics snapshot, several patterns became clear.

### 1. Severity Distribution

According to the metrics snapshot:

- **Critical findings:** 8.
- **High-severity findings:** 28.
- **Medium findings:** 42.
- **Low-severity finding:** 1.
- **Informational findings:** 31.

These numbers represent the full set of active issues across all imported tools.

### 2. Backup File Exposure

The imported ZAP report contributed several findings related to publicly exposed backup files (CWE-530). These are reflected primarily in the Medium and High severity categories.

### 3. Access Control Weaknesses

Among the High-severity issues, several relate to access control flaws such as restricted-resource bypass attempts.

### 4. Security Header Deficiencies

A number of Medium and Informational findings highlight missing or outdated security headers such as CSP or Feature-Policy, indicating gaps in client-side protection.

### 5. Findings Overview

All 110 findings remain active, unverified, and not mitigated, according to the metrics snapshot.

## Metrics and Reporting Output

After importing the results, DefectDojo was used to generate:

- A complete metrics summary based on the 110 active findings.
- Stakeholder-ready reports in PDF and HTML formats.
- A CSV export for extended data review.

These reports helped surface the most severe and frequent vulnerability categories.

## Risk Evaluation and Suggested Actions

The aggregated data shows several areas in need of attention. Recommended steps include:

- Strengthening CORS and other configuration-related controls.
- Securing or removing exposed backup files and archive directories.
- Improving access control checks to prevent unauthorized access.
- Implementing consistent, modern security headers across all endpoints.

Addressing these areas would reduce the overall security risk reflected in the 110 findings.
