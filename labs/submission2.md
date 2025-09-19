## Lab 2 — Submission

### Top 5 Risks (from labs/lab2/baseline/risks.json)


| Severity | Category | Asset | Likelihood | Impact |
|----------|----------|-------|------------|--------|
|elevated|unencrypted-communication|user-browser|likely|high|  
|elevated|unencrypted-communication|user-browser|likely|high|   
|elevated|missing-authentication|juice-shop|likely|medium|   
|elevated|unencrypted-communication|reverse-proxy|likely|medium|   
|elevated|cross-site-scripting|juice-shop|likely|medium| 

The data was sorted and presented using the formula: Composite score = Severity*100 + Likelihood*10 + Impact

| Category | Baseline | Secure | Δ |
|---|---:|---:|---:|
| container-baseimage-backdooring | 1 | 1 | 0 |
| cross-site-request-forgery | 2 | 2 | 0 |
| cross-site-scripting | 1 | 1 | 0 |
| missing-authentication | 1 | 1 | 0 |
| missing-authentication-second-factor | 2 | 2 | 0 |
| missing-build-infrastructure | 1 | 1 | 0 |
| missing-hardening | 1 | 1 | 0 |
| missing-identity-store | 1 | 1 | 0 |
| missing-vault | 1 | 1 | 0 |
| missing-waf | 1 | 1 | 0 |
| server-side-request-forgery | 3 | 3 | 0 |
| unencrypted-asset | 1 | 1 | 0 |
| unencrypted-communication | 3 | 1 | -2 |
| unnecessary-data-transfer | 2 | 2 | 0 |
| unnecessary-technical-asset | 2 | 2 | 0 |git checkout -b feature/lab1

Change made: Implemented encryption for previously unprotected communication channels.  
Result: Risk level for unencrypted-communication dropped from 3 to 1.  
Why: Encrypting sensitive traffic mitigates exposure to interception.