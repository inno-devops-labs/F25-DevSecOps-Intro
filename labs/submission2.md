# Lab 2 Submission - Threagile Threat Modeling


## Top 5 Risks Table (from labs/lab2/baseline/risks.json)

Counted by labs/lab2/baseline/composite-score-calc.py

| Category | Severity | Asset | Likelihood | Impact | Result |
|-----------|---------------------|---------------------|---------------|-----------------------|-----------|
| unencrypted-communication | elevated(4) | user-browser | likely(3) | high(3) | 433 |
| unencrypted-communication | elevated(4) | user-browser | likely(3) | high(3) | 433 |
| cross-site-scripting | elevated(4) | reverse-proxy | likely(3) | medium(2) | 432 |
| unencrypted-communication | elevated(4) | juice-shop | likely(3) | medium(2) | 432 |
| missing-authentication | elevated(4) | juice-shop | likely(3) | medium(2) | 432 |


```
Severity: critical (5) > elevated (4) > high (3) > medium (2) > low (1)
Likelihood: very-likely (4) > likely (3) > possible (2) > unlikely (1)
Impact: high (3) > medium (2) > low (1)
Composite score(Result column) = Severity*100 + Likelihood*10 + Impact (sort desc; use to break ties)
```
## Delta table (Category: Baseline vs Secure vs Δ)

| Category | Baseline | Secure | Δ |
|---|---|---|---|
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



***“Delta Run” explanation***

**Change made:** Enabled HTTPS encryption for all communication links and implemented disk-level encryption for persistent storage.

**Result:** Completely eliminated 3 unencrypted communication risks and reduced server-side request forgery risks by 1, but introduced 1 additional missing hardening risk.

**Why:** Encryption prevents eavesdropping and data interception attacks, but revealed additional hardening requirements for the secured infrastructure.