# Top 5 Risks

| Title | Severity | Category | Asset | Likelihood | Impact | Composite Score |
|----------|----------|----------|-------|------------|--------|------------------|
| Unencrypted Communication named Direct to App (no proxy) between User Browser and Juice Shop Application transferring authentication data (like credentials, token, session-id, etc.) | elevated | unencrypted-communication | user-browser | likely | high | 433 |
| Unencrypted Communication named To App between Reverse Proxy and Juice Shop Application | elevated | unencrypted-communication | reverse-proxy | likely | medium | 432 |
| Missing Authentication covering communication link To App from Reverse Proxy to Juice Shop Application | elevated | missing-authentication | juice-shop | likely | medium | 432 |
| Missing Authentication covering communication link To App from Reverse Proxy to Juice Shop Application | elevated | missing-authentication | juice-shop | likely | medium | 432 |
| Cross-Site Request Forgery (CSRF) risk at Juice Shop Application via Direct to App (no proxy) from User Browser | medium | cross-site-request-forgery | juice-shop | very-likely | low | 241 |


## Task 2
| Title | Severity | Category | Asset | Likelihood | Impact | Composite Score |
|----------|----------|----------|-------|------------|--------|------------------|
| Missing Authentication covering communication link To App from Reverse Proxy to Juice Shop Application | elevated | missing-authentication | juice-shop | likely | medium | 432 |
| Cross-Site Scripting (XSS) risk at Juice Shop Application | elevated | cross-site-scripting | juice-shop | likely | medium | 432 |
| Cross-Site Request Forgery (CSRF) risk at Juice Shop Application via Direct to App (no proxy) from User Browser | medium | cross-site-request-forgery | juice-shop | very-likely | low | 241 |
| Cross-Site Request Forgery (CSRF) risk at Juice Shop Application via To App from Reverse Proxy | medium | cross-site-request-forgery | juice-shop | very-likely | low | 241 |
| Missing Hardening risk at Juice Shop Application | medium | missing-hardening | juice-shop | likely | low | 231 |

## Notes:
It has been noted that the vulnerability "Unencrypted Communication" is no longer mentioned in the report. Because communication link changed to HTTPS protocol.



## Category Delta Table
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

----
Change made: Selected https protocol instead http

Result: no unencrypted-communication vulnerability

Why: https has SSL layer

Change made: Used transparent encyption for Persistent storage

Result: no unencrypted-asset vulnerability

Why: We enabled encryption for disk

