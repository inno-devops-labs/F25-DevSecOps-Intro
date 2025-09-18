# Lab 2

## Task 1
### Top 5 Risks

| Severity | Category | Asset | Likelihood | Impact | Score |
|---|---|---|---|---|---|
| elevated | unencrypted-communication | user-browser | likely | high | 433 |
| elevated | unencrypted-communication | reverse-proxy | likely | medium | 432 |
| elevated | missing-authentication | juice-shop | likely | medium | 432 |
| elevated | cross-site-scripting | juice-shop | likely | medium | 432 |
| medium | cross-site-request-forgery | juice-shop | very-likely | low | 241 |

## Task 2
### Delta table

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
| unencrypted-communication | 2 | 1 | -1 |
| unnecessary-data-transfer | 2 | 2 | 0 |
| unnecessary-technical-asset | 2 | 2 | 0 |

**Change made:** Updated the secure model to enforce HTTPS for user browser → reverse proxy, and enabled disk-level encryption on persistent storage.  
**Result:** Counts for `unencrypted-asset` and `unencrypted-communication` decreased by 1 each.  
**Why:** These mitigations reduce the number of risks related to unencrypted data storage and transmission.
