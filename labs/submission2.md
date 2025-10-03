# Lab 2 Submission

## Task 1 - Threagile model & automated report

| Severity | Category | Number of Ricks | Asset | Likelihood | Impact | Score |
|----------|----------|-----------------|-------|------------|--------|-------|
| Elevated | Unencrypted Communication | 2 | Reverse Proxy | Likely | High | 433 |
| Elevated | XSS | 1 | Juice Shop Application | Likely | Medium | 432 |
| Elevated | Missing Authentication | 1 | Juice Shop Application | Likely | Medium | 432 |
| Medium | Cross-Site Request Forgery (CSRF) | 2 | Juice Shop Application | Very likely | Low | 241 |
| Medium | Missing Hardening | 2 | Persistent Storage | Likely | Low | 231 |

## Task 2 - HTTPS Variant & Risk Diff 

### Table - Baseline vs Secure vs Δ

| Category | Baseline | Secure | Δ |
|---|---:|---:|---:|
| container-baseimage-backdooring | 1 | 1 | 0 |
| cross-site-request-forgery | 2 | 2 | 0 |
| cross-site-scripting | 1 | 1 | 0 |
| missing-authentication | 1 | 1 | 0 |
| missing-authentication-second-factor | 2 | 2 | 0 |
| missing-build-infrastructure | 1 | 1 | 0 |
| missing-hardening | 2 | 2 | 0 |
| missing-identity-store | 1 | 1 | 0 |
| missing-vault | 1 | 1 | 0 |
| missing-waf | 1 | 1 | 0 |
| server-side-request-forgery | 2 | 2 | 0 |
| unencrypted-asset | 2 | 1 | -1 |
| unencrypted-communication | 2 | 0 | -2 |
| unnecessary-data-transfer | 2 | 2 | 0 |
| unnecessary-technical-asset | 2 | 2 | 0 |

### Delta Run Explanation

We changed the communication protocol to **HTTPS** and enabled **transparent encryption** on persistent storage.  
As a result, the risks related to **unencrypted communication** disappeared (–2) and **unencrypted asset** was reduced (–1).  
Other risk categories remained the same, which shows that only the intended security improvements affected the model.
