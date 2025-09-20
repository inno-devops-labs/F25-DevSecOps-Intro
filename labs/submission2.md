# Lab 2 — Threat Modeling with Threagile

## Top 5 Risks

| Severity | Category                  | Asset        | Likelihood | Impact | Score |
|----------|---------------------------|--------------|------------|--------|-------|
| elevated | unencrypted-communication | user-browser | likely     | high   | 433   |
| elevated | missing-authentication    | juice-shop   | likely     | medium | 432   |
| elevated | cross-site-scripting      | juice-shop   | likely     | medium | 432   |
| elevated | unencrypted-communication | reverse-proxy| likely     | medium | 432   |
| medium   | cross-site-request-forgery| juice-shop   | very-likely| low    | 241   |

---

## Risk Category Delta

| Category                         | Baseline | Secure | Δ  |
|----------------------------------|---------:|-------:|---:|
| container-baseimage-backdooring  |        1 |      1 |  0 |
| cross-site-request-forgery       |        2 |      2 |  0 |
| cross-site-scripting             |        1 |      1 |  0 |
| missing-authentication           |        1 |      1 |  0 |
| missing-authentication-second-factor |    2 |      2 |  0 |
| missing-build-infrastructure     |        1 |      1 |  0 |
| missing-hardening                |        2 |      2 |  0 |
| missing-identity-store           |        1 |      1 |  0 |
| missing-vault                    |        1 |      1 |  0 |
| missing-waf                      |        1 |      1 |  0 |
| server-side-request-forgery      |        2 |      2 |  0 |
| unencrypted-asset                |        2 |      1 | -1 |
| unencrypted-communication        |        2 |      0 | -2 |
| unnecessary-data-transfer        |        2 |      2 |  0 |
| unnecessary-technical-asset      |        2 |      2 |  0 |

---

## Delta Run Explanation

**Change made:** In the secure variant, all browser → proxy and proxy → app communication links were switched to HTTPS, and persistent storage was configured with transparent encryption.  
**Result:** The number of risks in the `unencrypted-communication` category decreased by 2, and `unencrypted-asset` decreased by 1.  
**Why:** These changes eliminate unencrypted traffic and insecure data storage, thus mitigating threats related to data confidentiality and integrity.  

