# Task 1

## Top-5 risks

A small comment regarding tie-breaking: it makes no sense to expect the
composite score of rows to be different when the severity, likelihood, and
impact are identical because the composite score only depends on these values.
Tie-breaking here is impossible to accomplish using the suggested method.

--------------------------------------------------------------------------------------------------------------------
| **Clarification**   | **Severity** | **Category**                | **Asset**       | **Likelihood** | **Impact** |
--------------------------------------------------------------------------------------------------------------------
| Direct-To-App http  |  elevated    |  unencrypted-communication  |  user-browser   |  likely        |  high      |
--------------------------------------------------------------------------------------------------------------------
| To-Reverse-Proxy    |  elevated    |  unencrypted-communication  |  user-browser   |  likely        |  high      |
--------------------------------------------------------------------------------------------------------------------
| To-App http         |  elevated    |  unencrypted-communication  |  reverse-proxy  |  likely        |  medium    |
--------------------------------------------------------------------------------------------------------------------
|                     |  elevated    |  cross-site-scripting       |  juice-shop     |  likely        |  medium    |
--------------------------------------------------------------------------------------------------------------------
| RevProxy->JuiceShop |  elevated    |  missing-authentication     |  juice-shop     |  likely        |  medium    |
--------------------------------------------------------------------------------------------------------------------
