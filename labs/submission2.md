# Lab 2 — Submission

## Artifacts
- `labs/lab2/baseline/threagile-model.yaml` (without HTTPS delta change applied)
- `labs/lab2/secure/threagile-model.https.yaml` (pulled for 2nd task)
- `labs/lab2/threagile-model2.yaml` (with HTTPS delta change applied)
- `labs/lab2/secure/report.pdf` (auto-generated)
- `labs/lab2/secure/risks.json` and `labs/lab2/secure/stats.json` (after delta run)
- `labs/lab2/secure/technical-assets.json`
- `labs/lab2/secure/data-flow-diagram.png` (Diagram)
- `labs/lab2/secure/data-asset-diagram.png` (Diagram)
- `labs/lab2/baseline/report.pdf` (auto-generated)
- `labs/lab2/baseline/risks.json` and `labs/lab2/baseline/stats.json` (after delta run)
- `labs/lab2/baseline/technical-assets.json`
- `labs/lab2/baseline/data-flow-diagram.png` (Diagram)
- `labs/lab2/baseline/data-asset-diagram.png` (Diagram)

---

## Task 1

## Top 5 Risks (Before Delta Run)

| Severity   | Category                   | Asset        | Likelihood   | Impact | Score |
|------------|----------------------------|--------------|--------------|--------|-------|
| Elevated   | Unencrypted Communication  | User Browser | Likely       | High   | 433   |
| Elevated   | Unencrypted Communication  | User Browser | Likely       | High   | 433   |
| Elevated   | Unencrypted Communication  | Reverse Proxy| Likely       | Medium | 432   |
| Elevated   | Missing Authentication     | Juice Shop   | Likely       | Medium | 432   |
| Elevated   | Cross-Site Scripting (XSS) | Juice Shop   | Likely       | Medium | 432   |

**Notes:**  
- Composite score formula: Severity mult. 100 + Likelihood mult. 10 + Impact.  
- Two separate unencrypted communication risks (browser -> app and browser -> proxy) tied for first place.  
- Authentication and XSS issues remain among the most severe.  

---

## Top 5 Risks (After Delta Run)

| Severity   | Category                   | Asset        | Likelihood   | Impact | Score |
|------------|----------------------------|--------------|--------------|--------|-------|
| Elevated   | Unencrypted Communication  | User Browser | Likely       | High   | 433   |
| Elevated   | Unencrypted Communication  | Reverse Proxy| Likely       | Medium | 432   |
| Elevated   | Missing Authentication     | Juice Shop   | Likely       | Medium | 432   |
| Elevated   | Cross-Site Scripting (XSS) | Juice Shop   | Likely       | Medium | 432   |
| Medium     | Cross-Site Request Forgery | Juice Shop   | Very-Likely  | Low    | 241   |

**Notes:**  
- After enforcing HTTPS on one flow, the browser -> proxy unencrypted risk was removed.  
- Top 4 risks remain consistent: unencrypted communication, missing authentication, and XSS.  

---

## Stats Snapshot

**Before Delta Run:**  
- Elevated: 5  
- Medium: 12  
- Low: 5  

**After Delta Run:**  
- Elevated: 4  
- Medium: 13  
- Low: 5  

---

## Delta Run

- Configured communication between Browser and Reverse Proxy to use HTTPS. Medium risks increased by 1, reflecting model recalculation.  

- Enabling HTTPS mitigates critical exposure of credentials/tokens during browser-to-proxy communication. This confirms the positive security impact of encryption even on internal segments.  

---

## Conclusion

The combined results show that OWASP Juice Shop deployment is primarily at risk from insecure communication, missing authentication layers, and classic OWASP Top 10 issues(XSS, CSRF). The delta run demonstrated how a simple architectural change (enabling HTTPS) reduced critical risks.

## Task 2 

| Category | Baseline | Secure | Δ |
|---|---:|---:|---:|
| container-baseimage-backdooring | 1 | 1 | 0 |
| cross-site-request-forgery | 2 | 2 | 0 |
| cross-site-scripting | 1 | 1 | 0 |
| missing-authentication | 1 | 1 | 0 |
| missing-authentication-second-factor | 2 | 2 | 0 |
| missing-build-infrastructure | 1 | 1 | 0 |
| missing-hardening | 1 | 2 | 1 |
| missing-identity-store | 1 | 1 | 0 |
| missing-vault | 1 | 1 | 0 |
| missing-waf | 1 | 1 | 0 |
| server-side-request-forgery | 3 | 2 | -1 |
| unencrypted-asset | 1 | 1 | 0 |
| unencrypted-communication | 3 | 0 | -3 |
| unnecessary-data-transfer | 2 | 2 | 0 |
| unnecessary-technical-asset | 2 | 2 | 0 |

## Delta Run Summary

- 3 unencrypted-communication risks mitigated (HTTPS enabled).

- 1 SSRF risk reduced (from 3 -> 2).

- 1 missing-hardening risk increased (from 1 -> 2), model flagged new security requirements.

**Total Elevated risks:** 5 -> 4

## Bonus — GitHub Social Interactions

Stars and follows on GitHub help show which projects are trusted and widely used. They also make it easier to build collaboration and visibility in open source and team projects, since people can quickly discover and connect with active contributors. Networking makes a huge profit to the projects impacts in the community.

I have starred the course repository, followed 3 of my classmates, course instructor and 2 TA's. 

---



