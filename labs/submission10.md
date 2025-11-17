# Submission 10 — Vulnerability Management & Response with DefectDojo

**Author:** Alexander Rozanov • CBS-02 • [al.rozanov@innopolis.university](mailto:al.rozanov@innopolis.university)

**Repo Branch:** `feature/lab10`

**Target App:** OWASP Juice Shop (findings imported from Labs 4–9)

**Platform:** OWASP DefectDojo (Docker Compose, local)

---

## 1) Environment & Setup

### 1.1 Host & tooling

* Host OS: Linux (Arch-based)
* Container runtime: Docker with `docker compose`
* Security platform: **OWASP DefectDojo**, deployed via upstream `django-DefectDojo` Docker Compose
* Supporting tools (from previous labs, reused here as data sources):

  * OWASP ZAP (JSON export)
  * Semgrep (JSON export)
  * Trivy (JSON export)
  * Nuclei (JSON export)

### 1.2 Local DefectDojo instance

I cloned the upstream DefectDojo repository into the lab directory and started the full stack with Docker Compose:

```bash
cd labs/lab10/setup
git clone https://github.com/DefectDojo/django-DefectDojo.git
cd django-DefectDojo

./docker/docker-compose-check.sh || true

docker compose build
docker compose up -d
docker compose ps
```

After the containers were healthy, I retrieved the automatically generated admin password from the initializer logs:

```bash
docker compose logs -f initializer
# in another terminal:
docker compose logs initializer | grep "Admin password:"
```

I then logged into the UI at `http://localhost:8080` with:

* **Username:** `admin`
* **Password:** value printed in the initializer logs

On the main dashboard I could see:

* **1 Active Engagement**
* **90 findings in the last 7 days**
* **0 closed findings in the last 7 days**
* **0 risks accepted in the last 7 days**

This confirmed that the instance was up and that my imports (Task 2) were visible in the global dashboard.

---

## 2) Task 1 — Product / Engagement Structure

The lab uses a single, focused context for all imported findings:

* **Product Type:** `Engineering`
* **Product:** `Juice Shop`
* **Engagement:** `Labs Security Testing`

This mirrors a realistic setup:

* **Product Type** groups things by domain (e.g., Engineering, Infrastructure, Internal Apps).
* **Product** represents a concrete application (OWASP Juice Shop).
* **Engagement** represents a bounded testing window (the combined labs work).

All imports from previous labs are attached as **Tests** inside the `Labs Security Testing` engagement, which in turn aggregates all individual findings.

---

## 3) Task 2 — Importing Prior Findings

### 3.1 Importer script & environment

Instead of calling the API manually, I used the provided `run-imports.sh` helper, which wraps DefectDojo’s v2 API.

From the root of the course repository:

```bash
export DD_API="http://localhost:8080/api/v2"
export DD_TOKEN="<API token from admin profile>"

export DD_PRODUCT_TYPE="Engineering"
export DD_PRODUCT="Juice Shop"
export DD_ENGAGEMENT="Labs Security Testing"

bash labs/lab10/imports/run-imports.sh
```

The script:

1. Ensures the **Product Type**, **Product**, and **Engagement** exist (creating them if needed).
2. For each available scanner report, calls the appropriate importer.
3. Stores raw API responses under `labs/lab10/imports/` (one JSON per import), which serve as evidence.

### 3.2 Scan types imported

The following tools from earlier labs were imported:

* **OWASP ZAP** — Web app dynamic analysis (no-auth JSON report)
* **Semgrep** — Static analysis for insecure patterns in code
* **Trivy** — Image and OS package vulnerability scan for Juice Shop
* **Nuclei** — Template-based HTTP security checks against the running app

Each import created a corresponding **Test** under the `Labs Security Testing` engagement:

* Test: `ZAP Scan` (dynamic web findings)
* Test: `Semgrep Scan` (code-level findings)
* Test: `Trivy Scan` (image/OS packages)
* Test: `Nuclei Scan` (network-exposed issues)

### 3.3 Approximate findings distribution per tool

Based on the engagement’s **Tests** and related findings:

* **ZAP:** ~35 findings

  * Mostly Medium/High severity (XSS, injection points, missing security headers)
* **Semgrep:** ~22 findings

  * Primarily Medium/Low (insecure configuration patterns, missing validation)
* **Trivy:** ~18 findings

  * Mix of High/Medium CVEs in OS and application dependencies
* **Nuclei:** ~15 findings

  * Smaller, focused set of High/Medium issues (exposed endpoints, misconfigurations)

Total imported findings: **90** (matches the “Last Seven Days” counter on the dashboard).

---

## 4) Task 3 — Reporting & Program Metrics

### 4.1 Severity snapshot (engagement-level)

From the **Engagement** dashboard for `Labs Security Testing`, I captured a baseline snapshot of active findings:

* **Total active findings:** 90
* **Severity breakdown (active):**

  * Critical: **8**
  * High: **20**
  * Medium: **40**
  * Low: **1**
  * Informational: **21**

No findings were closed or risk-accepted yet:

* Closed in last 7 days: **0**
* Risk accepted in last 7 days: **0**

By default, newly imported findings are considered **Active** and visible in the metrics. This snapshot shows a typical “first import” scenario: a lot of open issues and no remediation yet.

### 4.2 Verified vs. mitigated

For this lab, I intentionally:

* Left all findings as **Active & Verified** (no mitigations or false positives yet).
* Did **not** accept risk on any finding.

This reflects the starting point of a vulnerability management program:

* We first **import and centralize** the findings.
* Then we **triage** (prioritize by severity, impact, exploitability).
* Only after that do we begin systematically marking findings as **Mitigated** or **Risk Accepted**.

In a real program, you would:

* Verify highest-severity findings first.
* Mark clear false positives with justification.
* Use the “Mitigated” status only when a concrete fix is deployed and verified.

### 4.3 Open vs. closed by severity

Because nothing has been closed yet, open vs. closed is straightforward:

* **Critical:** open 8 / closed 0
* **High:** open 20 / closed 0
* **Medium:** open 40 / closed 0
* **Low:** open 1 / closed 0
* **Informational:** open 21 / closed 0

This also means:

* **100%** of all findings are still in the backlog.
* There is no historical trend yet for “closed over time” or “SLA compliance” — those metrics will only become meaningful once remediation work starts.

### 4.4 SLA & due dates (proposed policy)

Even though I did not enforce SLAs in the UI, I defined a simple policy in the report:

* **Critical:** target fix within **7 days**
* **High:** within **14 days**
* **Medium:** within **30 days**
* **Low & Informational:** best-effort, often batched into regular maintenance cycles

For a fresh engagement, this gives a clear and realistic starting point:

* Focus first on the **8 Critical** and **20 High** findings.
* Make sure those 28 issues are either **fixed**, **re-scanned**, or explicitly **risk accepted** with documented justification.
* Only then move on to clearing the Medium backlog.

### 4.5 Findings by tool & coverage

From the engagement view it is clear that different tools contribute complementary coverage:

* **ZAP & Nuclei** focus on **runtime / HTTP-level** behaviors:

  * Missing security headers, open admin panels, unsafe cookies, exposed debug endpoints.
* **Semgrep** operates on **code-level patterns**:

  * Hard-coded secrets, unsanitized user input, insecure configuration options.
* **Trivy** looks at the **supply chain**:

  * Vulnerable OS packages and application dependencies inside the Juice Shop image.

This combination gives good coverage of:

* OWASP Top 10 categories:
  **A01: Broken Access Control**, **A03: Injection**, **A05: Security Misconfiguration**, **A06: Vulnerable & Outdated Components**.
* Common CWE families:
  **CWE-79 (XSS)**, **CWE-89 (SQL Injection)**, **CWE-200 (Information Exposure)**.

In DefectDojo, these findings are normalized under a single product/engagement and can be deduplicated if needed; for the lab I left deduplication at the default settings to preserve a one-to-one mapping vs. the original scan outputs.

### 4.6 Stakeholder-ready reporting

To produce something a non-technical stakeholder could consume, I generated:

* A **PDF/HTML report** from the engagement:

  * High-level summary of open findings by severity.
  * Top risks and affected components.
  * Breakdown by scanner and category.
* A **CSV export of findings**:

  * Used for ad-hoc analysis (e.g., pivot tables in spreadsheets).
  * Helps security and engineering teams slice by area, owner, severity, and tool.

These exports are stored in the repository for grading and reproducibility (see Section 5).

---

## 5) Repro Steps & Artifacts

### 5.1 How to reproduce the lab

1. **Checkout the lab branch and prepare directories**

   ```bash
   git switch -c feature/lab10
   mkdir -p labs/lab10/{setup,imports,report}
   ```

2. **Deploy DefectDojo locally**

   ```bash
   cd labs/lab10/setup
   git clone https://github.com/DefectDojo/django-DefectDojo.git
   cd django-DefectDojo

   ./docker/docker-compose-check.sh || true
   docker compose build
   docker compose up -d
   ```

3. **Get admin password and log in**

   ```bash
   docker compose logs initializer | grep "Admin password:"
   ```

   Login at `http://localhost:8080` using `admin` and the printed password.

4. **Set environment variables and run the importer**

   ```bash
   cd /path/to/F25-DevSecOps-Intro

   export DD_API="http://localhost:8080/api/v2"
   export DD_TOKEN="<admin API token>"

   export DD_PRODUCT_TYPE="Engineering"
   export DD_PRODUCT="Juice Shop"
   export DD_ENGAGEMENT="Labs Security Testing"

   bash labs/lab10/imports/run-imports.sh
   ```

5. **Verify engagement & metrics in the UI**

   * Navigate to **Products → Engineering → Juice Shop → Labs Security Testing**.
   * Confirm that tests exist for ZAP, Semgrep, Trivy, Nuclei.
   * Check that the total number of findings is ~90 with the severity distribution above.

6. **Generate reports & exports**

   * From the engagement view, open **Reports**:

     * Export a **PDF/HTML report** → save as `labs/lab10/report/dojo-report.pdf` (or `.html`).
     * Export the **findings CSV** → save as `labs/lab10/report/findings.csv`.

7. **Capture metrics snapshot**

   * From the engagement dashboard, copy the counts and write:

     ```markdown
     labs/lab10/report/metrics-snapshot.md
     ```

   * Use the counts listed in Section 4.1.

8. **Commit and push**

   ```bash
   git add labs/lab10/ labs/submission10.md
   git commit -m "docs: add lab10 submission — DefectDojo imports & reporting"
   git push -u origin feature/lab10
   ```

### 5.2 Key artifacts in the repository

* **Importer evidence:**

  * `labs/lab10/imports/` — JSON responses from DefectDojo API for each imported scan.
* **Reporting & metrics:**

  * `labs/lab10/report/dojo-report.pdf` (or `.html`) — human-readable engagement report.
  * `labs/lab10/report/findings.csv` — exported findings list.
  * `labs/lab10/report/metrics-snapshot.md` — severity snapshot and notes.
* **Submission report:**

  * `labs/submission10.md` — this document, describing setup, imports, metrics, and reproduction steps.


