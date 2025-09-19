# Threat Modeling

## Task 1 — Threagile model & automated report

### Top 5 Risks

| Severity | Category                  | Asset         | Likelihood | Impact | Score |
| -------- | ------------------------- | ------------- | ---------- | ------ | ----- |
| Elevated | Unencrypted Communication | User Browser  | Likely     | High   | 433   |
| Elevated | Unencrypted Communication | User Browser  | Likely     | High   | 433   |
| Elevated | Missing Authentication    | Juice Shop    | Likely     | Medium | 432   |
| Elevated | Cross-Site Scripting      | Juice Shop    | Likely     | Medium | 432   |
| Elevated | Unencrypted Communication | Reverse Proxy | Likely     | Medium | 432   |

### Stats Snapshot

```json
{
  "total_risks": 23,
  "risks_critical": 0,
  "risks_elevated": 5,
  "risks_high": 0,
  "risks_medium": 13,
  "risks_low": 5
}
```


**After switching Reverse Proxy → App to HTTPS:**

### Top 5 risks

| Severity | Category                   | Asset        | Likelihood  | Impact | Score |
| -------- | -------------------------- | ------------ | ----------- | ------ | ----- |
| Elevated | Unencrypted Communication  | User Browser | Likely      | High   | 433   |
| Elevated | Unencrypted Communication  | User Browser | Likely      | High   | 433   |
| Elevated | Cross-Site Scripting       | Juice Shop   | Likely      | Medium | 432   |
| Elevated | Missing Authentication     | Juice Shop   | Likely      | Medium | 432   |
| Medium   | Cross-Site Request Forgery | Juice Shop   | Very Likely | Low    | 241   |

### Stats Snapshot

```json
{
  "total_risks": 22,
  "risks_critical": 0,
  "risks_elevated": 4,
  "risks_high": 0,
  "risks_medium": 13,
  "risks_low": 5
}
```

### Delta Run Analysis

**Before change:**
- Unencrypted communication: 3

**After change:**
- Unencrypted communication: 2

Changing the communication link from HTTP to HTTPS between Reverse Proxy and Juice Shop eliminated one unencrypted communication risk, as the data is now encrypted in transit vetween these internal components.

---
## Task 2 — HTTPS Variant & Risk Diff

### Risk Category Delta Table

| Category                             | Baseline | Secure |   Δ |
| ------------------------------------ | -------: | -----: | --: |
| container-baseimage-backdooring      |        1 |      1 |   0 |
| cross-site-request-forgery           |        2 |      2 |   0 |
| cross-site-scripting                 |        1 |      1 |   0 |
| missing-authentication               |        1 |      1 |   0 |
| missing-authentication-second-factor |        2 |      2 |   0 |
| missing-build-infrastructure         |        1 |      1 |   0 |
| missing-hardening                    |        2 |      2 |   0 |
| missing-identity-store               |        1 |      1 |   0 |
| missing-vault                        |        1 |      1 |   0 |
| missing-waf                          |        1 |      1 |   0 |
| server-side-request-forgery          |        2 |      2 |   0 |
| unencrypted-asset                    |        2 |      1 |  -1 |
| unencrypted-communication            |        2 |      0 |  -2 |
| unnecessary-data-transfer            |        2 |      2 |   0 |
| unnecessary-technical-asset          |        2 |      2 |   0 |

**Change made:** The communication links for "User Browser -> Reverse Proxy" and "Reverse Proxy -> Juice Shop App" were switched from `http` to `https`, the "Persistent Storage" asset encryption was set to `transparent`.

**Result:** The changes successfully eliminated 2 risks in the "unencrypted-communication" category and 1 risk in the "unencrypted-asset" category.

**Why:** Using HTTPS encrypts data in transit, mitigating the risk of eavesdropping on communication links. Enabling transparent encryption on the storage asset mitigates the risk of data exposure from physical media theft.

--- 

## Bonus Task

I starred the course repository and followed the course instructor, TAs and 3 of my classmates. 
Starring repositories allows to save useful projects and show appreciation to their creators. Following contributors keeps you updated on their work and helps you to discover new projects.