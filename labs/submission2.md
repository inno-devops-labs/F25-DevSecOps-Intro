## Task 1 - Top 5 Risks

## Baseline

| Severity | Category | Asset | Likelihood | Impact | Score |
|----------|----------|-------|------------|--------|-------|
| elevated | unencrypted-communication | user-browser | likely | high | 433 |
| elevated | unencrypted-communication | reverse-proxy | likely | medium | 432 |
| elevated | missing-authentication | juice-shop | likely | medium | 432 |
| elevated | cross-site-scripting | juice-shop | likely | medium | 432 |
| medium | cross-site-request-forgery | juice-shop | very-likely | low | 241 |

## Secure

| Severity | Category | Asset | Likelihood | Impact | Score |
|----------|----------|-------|------------|--------|-------|
| elevated | missing-authentication | juice-shop | likely | medium | 432 |
| elevated | cross-site-scripting | juice-shop | likely | medium | 432 |
| medium | cross-site-request-forgery | juice-shop | very-likely | low | 241 |
| medium | cross-site-request-forgery | juice-shop | very-likely | low | 241 |
| elevated | missing-authentication-second-factor | juice-shop | possible | medium | 232 |

## Task 2 - Risk Delta

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

**Delta Run Explanation**

**Change made:** Enabled HTTPS for all communication links (User Browser to App and Reverse Proxy to App) and implemented transparent disk encryption for Persistent Storage.

**Result:** Completely mitigated all `unencrypted-communication` risks (-2) and reduced `unencrypted-asset` risks by one (-1). All other risks related to application logic and configuration remained unchanged.

**Why:** HTTPS protects data in transit, and disk encryption protects data at rest. These changes specifically target risks to data confidentiality but do not address risks in other domains like authentication, input validation, or supply chain security.

## Bonus Task

I have starred the course repository and followed the instructor, teaching assistants, and other guys. Starring the repository is for easy access and acknowledges the creators' work, while following users facilitates staying informed of their activities and discovering related projects.