## Lab 2 — Submission

### Top 5 Risks (from labs/lab2/baseline/risks.json)

| Severity | Category | Asset | Likelihood | Impact |
|---|---|---|---|---|
| elevated | unencrypted-communication | user-browser | likely | high |
| elevated | unencrypted-communication | reverse-proxy | likely | medium |
| elevated | missing-authentication | juice-shop | likely | medium |
| elevated | cross-site-scripting | juice-shop | likely | medium |
| medium | cross-site-request-forgery | juice-shop | very-likely | low |

Notes:
- Ranking used composite score Severity*100 + Likelihood*10 + Impact with weights from the lab handout.
- Ties (score 432) were left in arbitrary but consistent order.

---

### Category Delta (Baseline vs Secure)

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

---

### Delta Run Explanation (2–4 lines)

- Change made: switched both browser→proxy and proxy→app links to HTTPS; enabled transparent encryption for persistent storage.
- Result: unencrypted-communication risks drop; some categories reduce in count; others unchanged.
- Why: transport encryption mitigates sniffing/TLS downgrades; storage encryption reduces data-at-rest exposure.


