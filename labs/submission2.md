Вот полный отчёт в **Markdown** со всеми вставками — уже с заполненными таблицами **Top-5** (baseline и secure) и **дельтой по категориям**.

---

# Submission 2 — Threagile Threat Model (OWASP Juice Shop v19.0.0)

---
Alexander Rozanov / CBS-02 / al.rozanov@innopolis.university
---

## 1) Baseline Threat Model

### 1.1 How I Generated the Model & Reports

* **Model**: `labs/lab2/threagile-model.yaml` (mirrors Lab-1 localhost deployment).
* **Command**:

  ```bash
  docker run --rm -v "$(pwd)":/app/work threagile/threagile \
    -model /app/work/labs/lab2/threagile-model.yaml \
    -output /app/work/labs/lab2/baseline \
    -generate-risks-excel=false -generate-tags-excel=false
  ```
* **Artifacts (committed)**:

  * `labs/lab2/baseline/report.pdf` (full report with diagrams)
  * `labs/lab2/baseline/*.png` (data-flow / asset diagrams)
  * `labs/lab2/baseline/risks.json`, `stats.json`, `technical-assets.json`

### 1.2 Scoring Method (Composite)

* **Severity**: `critical=5`, `elevated=4`, `high=3`, `medium=2`, `low=1`
* **Likelihood**: `very-likely=4`, `likely=3`, `possible=2`, `unlikely=1`
* **Impact**: `high=3`, `medium=2`, `low=1`
* **Formula**: `Score = Severity*100 + Likelihood*10 + Impact`

### 1.3 Top-5 Baseline Risks (Composite)

*Source: `labs/lab2/baseline/risks.json`.*&#x20;

| Risk (title)                                                                                                                                                                           | Severity | Category                   | Asset         | Likelihood | Impact | Score |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------: | -------------------------- | ------------- | ---------: | -----: | ----: |
| Unencrypted Communication named **Direct to App (no proxy)** between **User Browser** and **Juice Shop Application** transferring authentication data (credentials, token, session-id) |        4 | unencrypted-communication  | user-browser  |          3 |      3 |   433 |
| Cross-Site Scripting (XSS) at **Juice Shop Application**                                                                                                                               |        4 | cross-site-scripting       | juice-shop    |          3 |      2 |   432 |
| Missing Authentication on link **To App** from **Reverse Proxy** to **Juice Shop Application**                                                                                         |        4 | missing-authentication     | juice-shop    |          3 |      2 |   432 |
| Unencrypted Communication **To App** between **Reverse Proxy** and **Juice Shop Application**                                                                                          |        4 | unencrypted-communication  | reverse-proxy |          3 |      2 |   432 |
| Cross-Site Request Forgery (CSRF) at **Juice Shop Application** via **Direct to App (no proxy)** from **User Browser**                                                                 |        2 | cross-site-request-forgery | juice-shop    |          4 |      1 |   241 |

**Key observations (concise):**
– The top risks cluster around **insecure transport** and **app-layer weaknesses**: two **unencrypted-communication** findings on links that carry authentication data, one **missing-authentication** on the reverse-proxy→app hop, plus classic **XSS** and **CSRF** in the web app.
– Risk concentrates on the **User Browser ↔ Direct to App (no proxy)** link and the **Reverse Proxy ↔ Juice Shop Application (To App)** link due to lack of TLS (and missing auth on the latter), exposing credentials/session tokens to interception and tampering. On the asset side, **juice-shop** dominates because **XSS** and **CSRF** attach to that application and to its handling of user sessions and sensitive flows.

**Diagrams (baseline):**
![](/labs/lab2/baseline/data-asset-diagram.png)
![](/labs/lab2/baseline/data-flow-diagram.png)

---

## 2) Secure Variant — Changes & Results

### 2.1 Model Changes (secure)

* **Created:** `labs/lab2/threagile-model.secure.yaml`
* **Changes applied:**

  * User-browser → app link protocol set to **HTTPS**
  * Reverse proxy → app link protocol set to **HTTPS** (if modeled)
  * Persistent storage: `encryption: transparent`
* **Command**:

  ```bash
  docker run --rm -v "$(pwd)":/app/work threagile/threagile \
    -model /app/work/labs/lab2/threagile-model.secure.yaml \
    -output /app/work/labs/lab2/secure \
    -generate-risks-excel=false -generate-tags-excel=false
  ```

### 2.2 Top-5 Secure Risks (Composite)

*Source: `labs/lab2/secure/risks.json`.*&#x20;

| Risk (title)                                                                                                                                | Severity | Category                    | Asset      | Likelihood | Impact | Score |
| ------------------------------------------------------------------------------------------------------------------------------------------- | -------: | --------------------------- | ---------- | ---------: | -----: | ----: |
| Missing Authentication on link **To App** from **Reverse Proxy** to **Juice Shop Application**                                              |        4 | missing-authentication      | juice-shop |          3 |      2 |   432 |
| Cross-Site Scripting (XSS) at **Juice Shop Application**                                                                                    |        4 | cross-site-scripting        | juice-shop |          3 |      2 |   432 |
| Cross-Site Request Forgery (CSRF) at **Juice Shop Application** via **Direct to App (no proxy)** from **User Browser**                      |        2 | cross-site-request-forgery  | juice-shop |          4 |      1 |   241 |
| Cross-Site Request Forgery (CSRF) at **Juice Shop Application** via **To App** from **Reverse Proxy**                                       |        2 | cross-site-request-forgery  | juice-shop |          4 |      1 |   241 |
| Server-Side Request Forgery (SSRF) at **Juice Shop Application** (server-side request to **Webhook Endpoint** via **To Challenge WebHook**) |        2 | server-side-request-forgery | juice-shop |          3 |      1 |   231 |

**What changed vs. baseline (short):**
– **Unencrypted-communication** risks disappeared after enabling **HTTPS** on both client→app and proxy→app links.
– The top set is now dominated by **app-layer** issues (**XSS/CSRF**) plus **missing-authentication** on the proxy→app hop (service-to-service auth was out of scope in this iteration).
– Appearance of **SSRF** reflects server-side web calls; several “hygiene” items (missing vault/build infra/hardening) remain in the long tail for future sprints.&#x20;

### 2.3 Category-Level Risk Delta (Baseline vs Secure)

*Calculated from `labs/lab2/baseline/risks.json` and `labs/lab2/secure/risks.json`.* &#x20;

| Category                             | Baseline | Secure |      Δ |
| ------------------------------------ | -------: | -----: | -----: |
| container-baseimage-backdooring      |        1 |      1 |      0 |
| cross-site-request-forgery           |        2 |      2 |      0 |
| cross-site-scripting                 |        1 |      1 |      0 |
| missing-authentication               |        1 |      1 |      0 |
| missing-authentication-second-factor |        2 |      2 |      0 |
| missing-build-infrastructure         |        1 |      1 |      0 |
| missing-hardening                    |        2 |      2 |      0 |
| missing-identity-store               |        1 |      1 |      0 |
| missing-vault                        |        1 |      1 |      0 |
| missing-waf                          |        1 |      1 |      0 |
| server-side-request-forgery          |        2 |      2 |      0 |
| **unencrypted-asset**                |    **2** |  **1** | **−1** |
| **unencrypted-communication**        |    **2** |  **0** | **−2** |
| unnecessary-data-transfer            |        2 |      2 |      0 |
| unnecessary-technical-asset          |        2 |      2 |      0 |

**Why it changed (one paragraph):**
Enabling **TLS in transit** eliminated *Unencrypted Communication Channel* findings entirely (−2), and turning on **transparent encryption at rest** removed one *Unencrypted Technical Asset* finding (now only the app-side item remains). Other categories stayed flat because they are unrelated to transport/data-at-rest (e.g., **XSS/CSRF**, **missing-authentication**, **SSRF**) and require separate controls (app-layer hardening and service-to-service authentication).

**Diagrams (secure):**
![](/labs/lab2/secure/data-asset-diagram.png)
![](/labs//lab2/secure/data-flow-diagram.png)
---

## 3) Conclusions

* Minimal controls (**TLS in transit** + **transparent encryption at rest**) produced a clear reduction/shift away from *Unencrypted Communication* and reduced *Unencrypted Technical Asset* findings.
* Residual risk now concentrates in **application** and **service-to-service** layers (XSS, CSRF, missing authentication on proxy→app).
* **Next steps (prioritized):**

  1. Introduce **mutual auth / token-based auth** on internal hops (reverse-proxy → app).
  2. Strengthen **web-app defenses**: output encoding, CSP, CSRF tokens/samesite cookies, authn/authz boundaries.
  3. Add **secrets management (vault)**, **build/CI hardening**, and baseline **system hardening** of technical assets.

---

## 4) Repro & Artifacts

* **Repro**: run the two docker commands above to regenerate `baseline/` and `secure/`.
* **Artifacts (committed)**:

  * `labs/lab2/baseline/{report.pdf, *.png, risks.json, stats.json, technical-assets.json}`
  * `labs/lab2/secure/{report.pdf, *.png, risks.json, stats.json, technical-assets.json}`

---

### Environment

- Host OS: Arch - 257.4-1-arch
- Docker: Docker version 28.2.2, build e6534b4yy
* Juice Shop: `v19.0.0` @ `127.0.0.1:3000` (per Lab-1)

---

