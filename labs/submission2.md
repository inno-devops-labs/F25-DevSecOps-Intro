# Task 1

### Top 5 Risks

|Composite Score | Severity  | Category                  | Asset           | Likelihood  | Impact  |
|----------------|-----------|---------------------------|-----------------|-------------|---------|
|      433       | elevated  | unencrypted-communication (between User Browser and Juice Shop) | user-browser    | likely      | high    |
|      433       | elevated  | unencrypted-communication (between User Browser and Reverse Proxy) | user-browser    | likely      | high    |
|      432       | elevated  | unencrypted-communication (betwee Reverse Proxy and Juice Shop) | reverse-proxy   | likely      | medium  |
|      432       | elevated  | cross-site-scripting      | juice-shop      | likely      | medium  |
|      432       | elevated  | missing-authentication    | juice-shop      | likely      | medium  |


Sorted by:  
`Composite score = Severity*100 + Likelihood*10 + Impact`  
(critical=5, elevated=4, high=3, medium=2, low=1; very-likely=4, likely=3, possible=2, unlikely=1; high=3, medium=2, low=1)


# Task 2

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
| unnecessary-technicalasset | 2 | 2 | 0 |

**Delta Run — Table Explanation**

1) **Changes Included:**
The following measures were implemented in the secure version of the model:
- HTTPS was enabled for data transfer channels between the User Browser (Direct to App no proxy), Reverse Proxy.
- Transparent encryption was enabled for Persistent Storage.

2) **Result:**
In the `unencrypted-communication` category, the number of risks decreased from 3 to 1 (Δ = -2). For the remaining categories, the number of risks remained unchanged.

3) **Explanation of Result:**
The implementation of HTTPS and encryption eliminated risks associated with unencrypted data transfer between components. The remaining risks remained unchanged, since they aren't fully related to transmission channels.