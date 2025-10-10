# Lab 5

## vl.kuznetsov@innopolis.university

# Task 1 – SAST with Semgrep

### Tool Used

For Static Application Security Testing (SAST), we used Semgrep (version 1.138.0). Semgrep is an open-source static
analysis tool that scans source code for security issues, misconfigurations, and anti-patterns.

### Results Summary

The scan detected 25 security findings across multiple files sast-analysis.

### Categories of Vulnerabilities

Based on the Semgrep rules and CWE/OWASP mappings,
the findings fall into the following categories:

- SQL Injection (Sequelize)
    - Multiple instances in /src/routes/login.ts, /src/routes/search.ts, and dbSchemaChallenge_*.ts files.
    - Severity: High (Error)
    - CWE-89 / OWASP A01: Injection.
- Cross-Site Scripting (XSS)
    - Unquoted template variables in Angular/Handlebars (`navbar.component.html`, `purchase-basket.component.html`,
      `dataErasureForm.hbs`).
    - Raw HTML injection in `/src/routes/chatbot.ts`
    - Script tag injection risk in `/src/routes/videoHandler.ts`
    - Severity: Ranges from Low–High depending on context.
- Path Traversal
    - Use of res.sendFile with user input in /src/routes/fileServer.ts, /src/routes/keyServer.ts, etc.
    - Severity: Medium–High.
- Open Redirect
    - /src/routes/redirect.ts allows user-controlled redirects without validation.
    - Severity: Medium.
- Hard-coded Secrets
    - JWT private key hard-coded in /src/lib/insecurity.ts.
    - CWE-798 / OWASP A07: Identification & Authentication Failures.
    - Severity: High.
- Dangerous Functions (eval injection)
    - Use of eval() in /src/routes/userProfile.ts.
    - CWE-95 / OWASP A03: Injection.
    - Severity: High.
- Security Misconfiguration
    - Directory listing enabled in /src/server.ts.
    - CWE-548 / OWASP A06: Security Misconfiguration.
    - Severity: Medium.

------------

### Example Critical Findings

* **SQL Injection:**

  ```typescript
  models.sequelize.query(`SELECT * FROM Users WHERE email = '${req.body.email}' AND ...`)
  ```

  This directly concatenates unvalidated input into SQL queries.

* **Hardcoded JWT Secret:**

  ```typescript
  export const authorize = (user = {}) => jwt.sign(user, privateKey, { expiresIn: '6h' })
  ```

  Secrets must be stored securely, not in source code.

* **Path Traversal:**

  ```typescript
  res.sendFile(path.resolve('ftp/', file))
  ```

  Without sanitization, attackers can request arbitrary system files.

## Evaluation of Semgrep’s Effectiveness

* **Strengths:**

    * Detected multiple classes of vulnerabilities: injections, XSS, misconfigurations, hardcoded secrets.
    * Mapped findings to CWE and OWASP Top 10 categories.
    * Pinpointed exact vulnerable lines and provided remediation guidance.

* **Limitations:**

    * Some findings had low confidence (e.g., unquoted attributes) and may produce false positives.
    * Syntax errors in some files reduced coverage.
    * Semgrep cannot confirm exploitability (only flags suspicious patterns).

Overall, Semgrep provided valuable insights, catching **high-impact vulnerabilities** (SQL injection, hard-coded
secrets, unsafe `eval`) and reinforcing secure coding practices.

# Task 2 – Dynamic Application Security Testing (DAST)

In this task, four dynamic analysis tools were used against OWASP Juice Shop: **Nuclei**, **Nikto**, **ZAP**, and *
*SQLmap**. Each tool revealed different insights into the application’s runtime behavior.

---

## Tool Results Overview

| Tool       | Findings               | Key Vulnerabilities                                                            |
|------------|------------------------|--------------------------------------------------------------------------------|
| **ZAP**    | 0                      | No findings (scan failed due to proxy connection issues)                       |
| **Nuclei** | 19 (18 info, 1 medium) | Public Swagger API exposure (`/api-docs/swagger.yaml`)                         |
| **Nikto**  | 14                     | Server info leaks, uncommon headers, directory indexing on `/ftp/`, `/public/` |
| **SQLmap** | 1 confirmed            | Boolean-based SQL Injection on `q` parameter in `/rest/products/search`        |

---

## Key Findings Per Tool

### 🔹 Nuclei

- **Public Swagger API Exposure** (CWE-200: Information Exposure).
    - Endpoint: `http://localhost:3000/api-docs/swagger.yaml`
    - Severity: Medium.
    - Risk: Attackers can map the entire API surface, aiding further exploitation.
    - Recommendation: Restrict access to API docs in production or require authentication.

Other findings were **informational**, such as server banners and headers, useful for reconnaissance but less critical.

---

### 🔹 Nikto

- Reported **14 issues**, including:
    - Directory indexing enabled (`/ftp/`, `/public/`, `/css`) → CWE-548: Information Disclosure.
    - Server leaking inode values via ETags.
    - Misconfigured or uncommon security headers (`x-recruiting`, `feature-policy`).
- Severity: Mostly **low/medium**.
- Recommendation: Disable directory listing unless intentional; review and harden HTTP headers.

---

### 🔹 ZAP

- **No findings** were produced because the full scan failed with proxy connection errors.
- This highlights a **limitation of automated DAST tools**: operational stability and correct network configuration are
  critical.

---

### 🔹 SQLmap

- **Confirmed SQL Injection** in search functionality:
    - URL: `http://localhost:3000/rest/products/search?q=`
    - Parameter: `q` (GET)
    - Technique: **Boolean-based blind (BT)**
    - Severity: **High** (CWE-89: SQL Injection).
    - Impact: An attacker can extract or manipulate database contents.
    - Recommendation: Use parameterized queries (prepared statements) and ORM query binding.

---

## Comparison of Tools

- **Breadth vs Depth**:
    - Nuclei and Nikto excel at **surface mapping** (exposures, headers, directory indexing).
    - SQLmap focuses on **depth**, confirming active exploitation of injection flaws.
    - ZAP, while capable of broad scanning, failed here due to connectivity issues.

- **Unique Strengths**:
    - **Nuclei**: Lightweight, fast, rules-based scanning for known exposures.
    - **Nikto**: Traditional web server scanner, finds misconfigurations and directory listings.
    - **SQLmap**: Specialized and powerful for SQL injection testing and exploitation.
    - **ZAP**: Normally a broad web app scanner, but operationally sensitive.

- **Limitations**:
    - Nuclei/Nikto: Many low-severity or noisy findings.
    - ZAP: Requires stable setup; prone to connection/proxy issues.
    - SQLmap: Narrow scope (SQL injection only) but provides strong evidence.

---

## Conclusion

Each DAST tool contributed different perspectives:

- **Nuclei & Nikto** revealed surface-level exposures and misconfigurations.
- **SQLmap** delivered a critical confirmed SQL injection finding.
- **ZAP** produced no results in this setup, highlighting operational considerations.

Together, these tools demonstrate the **complementary nature of DAST approaches**: broad coverage for exposures,
detailed misconfiguration detection, and deep vulnerability exploitation.

## Task 3 — SAST/DAST Correlation and Security Assessment

### 3.1 Correlation Analysis

* **SAST findings (Semgrep):** 25 issues detected, including SQL injection patterns, hardcoded JWT secrets, use of
  `eval`, unquoted HTML template variables (potential XSS), path traversal risks, and directory listing exposure.
* **DAST findings:**

    * **ZAP:** 0 findings (scan failed due to proxy connection issues).
    * **Nuclei:** 19 findings, mostly informational exposures. A key issue was a **public Swagger API endpoint** (
      `/api-docs/swagger.yaml`) disclosing API documentation.
    * **Nikto:** 14 findings, including **directory indexing** (`/ftp/`, `/public/`), server information leaks, and
      unusual HTTP headers.
    * **SQLmap:** Confirmed a **real SQL Injection vulnerability** in the parameter `q` of `/rest/products/search`,
      using Boolean-based blind techniques.

### 3.2 SAST vs DAST Findings

* **Unique SAST findings:** Hardcoded secrets, `eval` usage (possible code injection), unsafe file serving (
  `res.sendFile` leading to path traversal), and insecure HTML template variables. These can only be detected by
  analyzing the source code.
* **Unique DAST findings:** Public Swagger API exposure (Nuclei), directory indexing and header issues (Nikto), and the
  confirmed SQL Injection exploit (SQLmap). These vulnerabilities require runtime testing and cannot be easily inferred
  from static code alone.
* **Overlap:** Semgrep flagged raw SQL queries as injection-prone, and SQLmap validated this by successfully exploiting
  one of them. This demonstrates the complementary nature of SAST (prediction) and DAST (confirmation).

### 3.3 Integrated Security Recommendations

* **Integrate SAST into CI/CD pipelines:** Run Semgrep automatically on pull requests to prevent insecure code from
  being merged.
* **Run DAST regularly on staging environments:** Tools like Nuclei, Nikto, ZAP, and SQLmap should be scheduled against
  deployed builds to catch runtime issues.
* **Correlate findings:** Prioritize issues confirmed by both approaches (e.g., SQL Injection found by SAST and
  validated by SQLmap) as critical.
* **Reduce false positives:** Filter Semgrep and Nikto results and focus remediation on high-confidence, high-impact
  vulnerabilities.
* **DevSecOps adoption:** Use SAST for developer feedback during development, and DAST for operational validation before
  release, ensuring continuous and layered security coverage.
