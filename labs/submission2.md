# Task 1

## Top-5 risks

A small comment regarding tie-breaking: it makes no sense to expect the
composite score of rows to be different when the severity, likelihood, and
impact are identical because the composite score only depends on these values.
Tie-breaking here is impossible to accomplish using the suggested method.

-------------------------------------------------------------------------------------------
| **Severity** | **Category**               | **Asset**     | **Likelihood** | **Impact** |
-------------------------------------------------------------------------------------------
| elevated     | unencrypted-communication  | user-browser  | likely         | high       |
-------------------------------------------------------------------------------------------
| elevated     | missing-authentication     | juice-shop    | likely         | medium     |
-------------------------------------------------------------------------------------------
| elevated     | cross-site-scripting       | juice-shop    | likely         | medium     |
-------------------------------------------------------------------------------------------
| elevated     | unencrypted-communication  | reverse-proxy | likely         | medium     |
-------------------------------------------------------------------------------------------
| medium       | cross-site-request-forgery | juice-shop    | very-likely    | low        |
-------------------------------------------------------------------------------------------

# Task 2

Pasted output of jq:

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

Pretty form:

| Category                             | Baseline | Secure | Δ  |
|--------------------------------------|---------:|-------:|---:|
| container-baseimage-backdooring      | 1        | 1      | 0  |
| cross-site-request-forgery           | 2        | 2      | 0  |
| cross-site-scripting                 | 1        | 1      | 0  |
| missing-authentication               | 1        | 1      | 0  |
| missing-authentication-second-factor | 2        | 2      | 0  |
| missing-build-infrastructure         | 1        | 1      | 0  |
| missing-hardening                    | 2        | 2      | 0  |
| missing-identity-store               | 1        | 1      | 0  |
| missing-vault                        | 1        | 1      | 0  |
| missing-waf                          | 1        | 1      | 0  |
| server-side-request-forgery          | 2        | 2      | 0  |
| unencrypted-asset                    | 2        | 1      | -1 |
| unencrypted-communication            | 2        | 0      | -2 |
| unnecessary-data-transfer            | 2        | 2      | 0  |
| unnecessary-technical-asset          | 2        | 2      | 0  |

## Explanation

* Change made:  Changed the protocol from `http` to `https` in communication links and set the app's storage encryption.
* Result (example):  3 warnings about unencrypted communication (2) and asset (1) have disappeared.
* Why:  The communication and the asset are now encrypted.
