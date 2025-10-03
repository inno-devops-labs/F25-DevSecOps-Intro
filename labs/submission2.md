# Lab 2 Submission — Baseline & Secure Run

## Top 5 Risks (Baseline)
| Severity | Category | Asset | Likelihood | Impact |
|---------:|---------|-------|------------|-------|
| Elevated | Missing Authentication | Juice Shop | Likely | Medium |
| Elevated | Cross-Site Scripting | Juice Shop | Likely | Medium |
| Elevated | Unencrypted Communication | Direct To App | Likely | High |
| Elevated | Unencrypted Communication | To Reverse Proxy | Likely | High |
| Medium   | Unencrypted Technical Asset | Juice Shop | Unlikely | Medium |

## Delta Table (Baseline - Secure)
| Category | Baseline | Secure | Δ |
|----------|---------:|-------:|--:|
| unencrypted-communication | 3 | 0 | -3 |
| missing-authentication | 1 | 0 | -1 |
| missing-authentication-second-factor | 2 | 0 | -2 |
| unencrypted-asset | 1 | 0 | -1 |
