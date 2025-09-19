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

