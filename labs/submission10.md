# Lab 10 — Vulnerability Management & Response with DefectDojo

## 1. Environment & DefectDojo Setup

- **Platform:** OWASP DefectDojo (docker-compose, local)
- **Host:** Local Docker environment
- **Containers running (excerpt from `docker ps`):**
    - `defectdojo/defectdojo-nginx:latest` (port mappings: 8080→8080, 8443→8443)
    - `defectdojo/defectdojo-django:latest` for:
        - `django-defectdojo-uwsgi-1`
        - `django-defectdojo-celeryworker-1`
        - `django-defectdojo-celerybeat-1`
    - `postgres:18.0-alpine` as the Dojo database backend
    - `redis:7.2.11-alpine` as the message broker

- **Startup steps followed:**
    - Cloned upstream repo to `labs/lab10/setup/django-DefectDojo`:
        - `git clone https://github.com/DefectDojo/django-DefectDojo.git labs/lab10/setup/django-DefectDojo`
    - From that directory:
        - `docker compose build`
        - `docker compose up -d`
    - Verified health via:
        - `docker compose ps` (all core services up and healthy)
        - UI accessible at `http://localhost:8080`

- **Admin access:**
    - Retrieved the auto-generated admin password from initializer logs:
        - `docker compose logs -f initializer`
        - Then extracted with:
            - `docker compose logs initializer | grep "Admin password:"`
    - Logged in to the UI with:
        - **Username:** `admin`
        - **Password:** value printed by the initializer

---

## 2. Product / Engagement Structure

The engagement is organized around a single product within a dedicated product type:

- **Product Type:** `Engineering`
- **Product:** `Juice Shop`
- **Engagement:** `Labs Security Testing`

The import script was configured with:

```bash
export DD_PRODUCT_TYPE="Engineering"
export DD_PRODUCT="Juice Shop"
export DD_ENGAGEMENT="Labs Security Testing"
````

The importer auto-created this structure (Product Type → Product → Engagement) when it did not exist and reused it on
subsequent runs.

---

## 3. Tool Imports via `run-imports.sh`

All prior lab scan outputs were imported using the provided script:

```bash
bash labs/lab10/imports/run-imports.sh
```

The script:

* Auto-detected importer names from the local DefectDojo instance.
* Auto-created the Product Type, Product, and Engagement where needed.
* Imported any scan reports present at the expected paths.
* Saved responses to JSON under `labs/lab10/imports/`.

### 3.1 Imported Tools and Resulting Finding Counts

Based on the import response JSON files:

| Tool    | DefectDojo Scan Type  | File (lab path)                            | Total Findings | Critical | High | Medium | Low | Info |
|---------|-----------------------|--------------------------------------------|---------------:|---------:|-----:|-------:|----:|-----:|
| Semgrep | `Semgrep JSON Report` | `labs/lab5/semgrep/semgrep-results.json`   |             25 |        0 |    7 |     18 |   0 |    0 |
| Trivy   | `Trivy Scan`          | `labs/lab4/trivy/trivy-vuln-detailed.json` |             74 |        9 |   28 |     33 |   4 |    0 |
| Nuclei  | `Nuclei Scan`         | `labs/lab5/nuclei/nuclei-results.json`     |             19 |        0 |    0 |      1 |   0 |   18 |
| Grype   | `Anchore Grype`       | `labs/lab4/syft/grype-vuln-results.json`   |             65 |        8 |   21 |     23 |   1 |   12 |

> Note: Counts are taken directly from the stats in the import responses (per test) before any deduplication across
> tools.

### 3.2 Engagement-Level Totals (Before Deduplication)

Aggregating across the four imported tools:

* **Total findings:** 183
* **By severity (Active):**

    * Critical: 17
    * High: 56
    * Medium: 75
    * Low: 5
    * Informational: 30

These values are the sum of each scan’s `statistics.after` section in the import responses and represent the initial,
pre-deduplication state for the engagement.

### 3.3 Verification Status

From the import statistics:

* **Trivy Scan**

    * 74 active findings total.
    * 70 are already marked **Verified** (4 low, 31 medium, 26 high, 9 critical).
    * None are yet marked as Mitigated.
* **Semgrep, Nuclei, Grype**

    * Findings are imported as **Active** and **not yet verified/mitigated**.
    * These still require manual triage (validation, false-positive marking, or mitigation workflow).

---

## 4. Metrics Snapshot & Reporting Artifacts

### 4.1 Metrics Snapshot (`labs/lab10/report/metrics-snapshot.md`)

The snapshot file captures a simple baseline of current risk posture. The version used for this lab is:

* **Date captured:** 2025-11-18 (adjust if you captured the snapshot on a different day).
* **Active findings (pre-deduplication across the four tools):**

    * 17 Critical
    * 56 High
    * 75 Medium
    * 5 Low
    * 30 Informational
* **Verified vs Mitigated:**

    * 70 Trivy findings marked Verified.
    * 0 findings currently marked Mitigated.
    * Remaining findings are Active and not yet verified.

This file lives at:

```text
labs/lab10/report/metrics-snapshot.md
```

### 4.2 DefectDojo Engagement Report

From the engagement’s **Reports** page:

* A human-readable report (Executive/Detailed template) was generated and exported as:

    * `labs/lab10/report/dojo-report.pdf` (or `dojo-report.html`, depending on format chosen)

This report provides:

* High-level overview for non-technical stakeholders.
* Severity breakdown charts.
* Finding lists grouped by severity, status, and (where available) CWE.

### 4.3 Findings CSV Export

From the same Reports page, the **“Findings list (CSV)”** export was downloaded and saved as:

```text
labs/lab10/report/findings.csv
```

This CSV can be used for:

* Spreadsheet-based analysis (pivot tables by severity, tool, CWE, status).
* Trend tracking across future imports.
* Additional metrics (e.g., mean time to verify/mitigate once you start updating status over time).

---

## 5. Key Metrics & Governance Summary

Below are the 3–5 bullet points summarizing program-level metrics and insights, as requested in Task 3.3:

* **Open vs. closed by severity:**
  Across the engagement, DefectDojo currently tracks **183 Active findings** (17 critical, 56 high, 75 medium, 5 low,
  and 30 informational). No findings have yet been marked as Mitigated, so all risk is still considered open and
  outstanding at this snapshot. Trivy findings show progress on triage via their Verified status, but not on actual
  remediation closure.

* **Findings per tool:**
  The pipeline consolidates results from multiple tools into a single engagement: **74 findings from Trivy**, **65 from
  Grype**, **25 from Semgrep**, and **19 from Nuclei**. This demonstrates the value of aggregating SAST (Semgrep),
  SCA/container (Trivy, Grype), and DAST/service-level checks (Nuclei) into one consistent view for stakeholders.

* **SLA / due-date outlook:**
  For this lab exercise, explicit SLAs and due dates were not configured, so DefectDojo does not currently display
  overdue item warnings. In a real program, the 17 critical and 56 high findings would be prime candidates for
  aggressive SLAs (e.g., 7–14 days for critical, 30 days for high) to ensure these issues are tracked to closure with
  clear timelines.

* **Top recurring categories (CWE/OWASP-style themes):**
  The majority of imported findings come from Trivy and Grype and represent dependency and component vulnerabilities,
  which naturally map to **OWASP A06:2021 — Vulnerable and Outdated Components**. Semgrep and Nuclei contribute a
  smaller but important set of application and service-level issues, such as possible misconfigurations and patterns
  related to injection or insecure defaults.

* **Readiness for stakeholders:**
  With the engagement report (`dojo-report.pdf`/`.html`), the metrics snapshot, and `findings.csv` all checked into
  `labs/lab10/report/`, non-technical stakeholders can quickly understand overall risk (how many high/critical issues
  exist), where that risk lives (dependencies vs. code vs. services), and which findings have already been verified and
  are ready for remediation work.

---

## 6. Artifact Summary

The following artifacts are created and tracked in the repository under `labs/lab10/` as required:

* **Setup evidence**

    * `labs/lab10/setup/django-DefectDojo/` (local clone and docker-compose setup)
* **Imports**

    * `labs/lab10/imports/` (JSON responses from Semgrep, Trivy, Nuclei, Grype imports and context creation)
* **Reporting**

    * `labs/lab10/report/metrics-snapshot.md`
    * `labs/lab10/report/dojo-report.pdf` (or `.html`)
    * `labs/lab10/report/findings.csv`
* **Submission summary**

    * `labs/submission10.md` (this file)