### Lab 2 — Top 5 Risks

Ranked by composite score: Severity*100 + Likelihood*10 + Impact (desc).

| Rank | Severity | Category | Asset | Likelihood | Impact |
|---:|---|---|---|---|---|
| 1 | elevated | unencrypted-communication | user-browser | likely | high |
| 2 | elevated | unencrypted-communication | reverse-proxy | likely | medium |
| 3 | elevated | cross-site-scripting | juice-shop | likely | medium |
| 4 | elevated | missing-authentication | juice-shop | likely | medium |
| 5 | medium | cross-site-request-forgery | juice-shop | very-likely | low |


### Category Delta — Baseline vs Secure

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

Delta Run

- Change made: Switched `User Browser` links to `protocol: https` and set `Persistent Storage` `encryption: transparent`.
- Result: Unencrypted categories reduced (communication -1, asset -1); all others unchanged.
- Why: HTTPS removes in-transit plaintext exposures; disk-level encryption addresses unencrypted asset on storage.


