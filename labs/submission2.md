# Lab 2 — Threat Modeling (Threat Dragon + Threagile)
# Task 1
## Artifacts Generated

Ran with:
```
docker run --rm -v "$(pwd)":/app/work threagile/threagile \
  -model /app/work/labs/lab2/threagile-model.yaml \
  -output /app/work/labs/lab2/baseline \
  -generate-risks-excel=false -generate-tags-excel=false
  ```

**Baseline Data flow diagram:**
![Data Flow Screenshot](./lab2/baseline/data-flow-diagram.png)

## Top 5 Risks

| Rank | Severity | Category                   | Asset         | Likelihood  | Impact | Composite Score |
| ---- | -------- | -------------------------- | ------------- | ----------- | ------ | --------------- |
| 1    | elevated | unencrypted-communication  | user-browser  | likely      | high   | 433             |
| 2    | elevated | missing-authentication     | juice-shop    | likely      | medium | 432             |
| 3    | elevated | cross-site-scripting       | juice-shop    | likely      | medium | 432             |
| 4    | elevated | unencrypted-communication  | reverse-proxy | likely      | medium | 432             |
| 5    | medium   | cross-site-request-forgery | juice-shop    | very-likely | low    | 241             |


# Task 2
## Artifacts Generated

Ran with:
```
docker run --rm -v "$(pwd)":/app/work threagile/threagile \
  -model /app/work/labs/lab2/threagile-model.secure.yaml \
  -output /app/work/labs/lab2/secure \
  -generate-risks-excel=false -generate-tags-excel=false
  ```

**Secure Data flow diagram:**
![Data Flow Screenshot](./lab2/secure/data-flow-diagram.png)

## Delta table (Category: Baseline vs Secure vs Δ)
| Category                          | Baseline | Secure | Δ   |
|------------------------------------|---------:|-------:|----:|
| container-baseimage-backdooring    |        1 |      1 |   0 |
| cross-site-request-forgery         |        2 |      2 |   0 |
| cross-site-scripting               |        1 |      1 |   0 |
| missing-authentication             |        1 |      1 |   0 |
| missing-authentication-second-factor |      2 |      2 |   0 |
| missing-build-infrastructure       |        1 |      1 |   0 |
| missing-hardening                  |        2 |      2 |   0 |
| missing-identity-store             |        1 |      1 |   0 |
| missing-vault                      |        1 |      1 |   0 |
| missing-waf                        |        1 |      1 |   0 |
| server-side-request-forgery        |        2 |      2 |   0 |
| unencrypted-asset                  |        2 |      1 |  -1 |
| unencrypted-communication          |        2 |      0 |  -2 |
| unnecessary-data-transfer          |        2 |      2 |   0 |
| unnecessary-technical-asset        |        2 |      2 |   0 |

## Delta Run

**Change Made**: Implemented HTTPS encryption for communication links between User Browser, Reverse Proxy, and Juice Shop Application.

**Result**: Reduced unencrypted-communication risks from 2 to 0 (Δ = -2), while maintaining other risk categories at baseline levels.

**Why**: HTTPS encryption protects sensitive authentication data and improves the confidentiality of user credentials and session tokens.