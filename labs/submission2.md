# Top 5 Risks from labs/lab2/baseline/risks.json

| Severity | Category | Asset | Likelihood | Impact | Score |
|----------|-----------|-------|------------|--------|-------|
| elevated | unencrypted-communication | user-browser | likely | high | 433 |
| elevated | unencrypted-communication | user-browser | likely | high | 433 |
| elevated | missing-authentication | juice-shop | likely | medium | 432 |
| elevated | cross-site-scripting | juice-shop | likely | medium | 432 |
| elevated | unencrypted-communication | reverse-proxy | likely | medium | 432 |


"| Category | Baseline | Secure | Δ |"
"|---|---:|---:|---:|"
"| container-baseimage-backdooring | 1 | 1 | 0 |"
"| cross-site-request-forgery | 2 | 2 | 0 |"
"| cross-site-scripting | 1 | 1 | 0 |"
"| missing-authentication | 1 | 1 | 0 |"
"| missing-authentication-second-factor | 2 | 2 | 0 |"
"| missing-build-infrastructure | 1 | 1 | 0 |"
"| missing-hardening | 1 | 2 | 1 |"
"| missing-identity-store | 1 | 1 | 0 |"
"| missing-vault | 1 | 1 | 0 |"
"| missing-waf | 1 | 1 | 0 |"
"| server-side-request-forgery | 3 | 2 | -1 |"
"| unencrypted-asset | 1 | 1 | 0 |"
"| unencrypted-communication | 3 | 0 | -3 |"
"| unnecessary-data-transfer | 2 | 2 | 0 |"
"| unnecessary-technical-asset | 2 | 2 | 0 |"


in the secure model we switched all HTTP links to HTTPS and enabled transparent disk encryption on Persistent Storage. This eliminated the unencrypted-communication risks and reduced some server-side-request-forgery findings. All other risk categories remained unchanged, showing that encryption mainly mitigates transport-layer and storage-layer threats while leaving application-layer risks intact.