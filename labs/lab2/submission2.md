
| Severity | Category | Asset | Likelihood | Impact | Score |
|---|---|---|---|---|---:|
| elevated | unencrypted-communication | user-browser | likely | high | 433 |
| elevated | unencrypted-communication | reverse-proxy | likely | medium | 432 |
| elevated | cross-site-scripting | juice-shop | likely | medium | 432 |
| elevated | missing-authentication | juice-shop | likely | medium | 432 |
| medium | cross-site-request-forgery | juice-shop | very-likely | low | 241 |

"| Category | Baseline | Secure | Δ |"
"|---|---:|---:|---:|"
"| container-baseimage-backdooring | 1 | 1 | 0 |"
"| cross-site-request-forgery | 2 | 2 | 0 |"
"| cross-site-scripting | 1 | 1 | 0 |"
"| missing-authentication | 1 | 1 | 0 |"
"| missing-authentication-second-factor | 2 | 2 | 0 |"
"| missing-build-infrastructure | 1 | 1 | 0 |"
"| missing-hardening | 2 | 2 | 0 |"
"| missing-identity-store | 1 | 1 | 0 |"
"| missing-vault | 1 | 1 | 0 |"
"| missing-waf | 1 | 1 | 0 |"
"| server-side-request-forgery | 2 | 2 | 0 |"
"| unencrypted-asset | 2 | 1 | -1 |"
"| unencrypted-communication | 2 | 0 | -2 |"
"| unnecessary-data-transfer | 2 | 2 | 0 |"
"| unnecessary-technical-asset | 2 | 2 | 0 |"

- **Change made:** Enabled TLS (`https`) on the links *Browser → App (no proxy)* and *Reverse Proxy → App*; set `encryption: transparent` for **Persistent Storage**.
- **Result:** The **Unencrypted Communication** risks disappeared; **Unencrypted Technical Assets** decreased due to storage encryption; other categories remained unchanged.
- **Why:** Encryption in transit and at rest protects confidentiality and integrity of traffic and reduces the impact in case of media co