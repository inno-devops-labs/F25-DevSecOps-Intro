
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

- **Change made:** включён TLS (`https`) на линках *Browser → App (no proxy)* и *Reverse Proxy → App*; для **Persistent Storage** установлено `encryption: transparent`.
- **Result:** риски **Unencrypted Communication** исчезли; **Unencrypted Technical Assets** уменьшились за счёт шифрования хранилища; остальные категории без заметных изменений.
- **Why:** шифрование в транзите и at rest защищает конфиденциальность/целостность трафика и снижает Impact при компрометации носителя.
