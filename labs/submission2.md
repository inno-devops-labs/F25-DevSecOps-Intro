### Top 5 risks

| Severity | Category                   | Asset         | Likelihood  | Impact |
|----------|----------------------------|---------------|-------------|--------|
| elevated | unencrypted-communication  | user-browser  | likely      | high   |
| elevated | unencrypted-communication  | reverse-proxy | likely      | medium |
| elevated | missing-authentication     | juice-shop    | likely      | medium |
| elevated | cross-site-scripting       | juice-shop    | likely      | medium |
| medium   | cross-site-request-forgery | juice-shop    | very-likely | low    |

## Category Delta (Baseline vs Secure)

| Category                             | Baseline | Secure |  Δ |
|--------------------------------------|---------:|-------:|---:|
| container-baseimage-backdooring      |        1 |      1 |  0 |
| cross-site-request-forgery           |        2 |      2 |  0 |
| cross-site-scripting                 |        1 |      1 |  0 |
| missing-authentication               |        1 |      1 |  0 |
| missing-authentication-second-factor |        2 |      2 |  0 |
| missing-build-infrastructure         |        1 |      1 |  0 |
| missing-hardening                    |        2 |      2 |  0 |
| missing-identity-store               |        1 |      1 |  0 |
| missing-vault                        |        1 |      1 |  0 |
| missing-waf                          |        1 |      1 |  0 |
| server-side-request-forgery          |        2 |      2 |  0 |
| unencrypted-asset                    |        2 |      1 | -1 |
| unencrypted-communication            |        2 |      0 | -2 |
| unnecessary-data-transfer            |        2 |      2 |  0 |
| unnecessary-technical-asset          |        2 |      2 |  0 |

## Delta Run

- **Change made:** In the secure variant, HTTPS was enabled for `User Browser → Reverse Proxy` and
  `Reverse Proxy → App`. For **Persistent Storage**, the setting was changed to `encryption: transparent` (baseline used
  `http` and `encryption: none`).
- **Result:** The number of risks in categories related to unencrypted traffic and storage decreased; some risks had
  their likelihood/impact reduced.
- **Why:** Encrypting traffic and storage reduces the risk of man-in-the-middle attacks, data leakage, and manipulation
  if the storage medium is compromised.
