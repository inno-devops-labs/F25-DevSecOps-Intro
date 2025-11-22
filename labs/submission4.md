## Task 1 - SBOM Generation with Syft and Trivy (4 pts)
After generating SBOM with Syft and Trivy and analyzing `lab4/analysis/sbom-analysis.txt' I found that Syft in general finds more.
* Package Type Distribution Comparison:
  * Syft identified 1 binary, 10 debian and 1128 npm packages, while trivy found 10 unknown base and 1125 nodejs packages. Which is both less packages found, and less packages identified by trivy
* Dependency Discovery Analysis
  * Same goes for dependency discovery analysis. Trivy classified many packages as unknown, while Syft detects dependencies even of native debian packages.
* Licence Discovery Analysis
  * Syft again found more licences than Trivy (888 vs 878 MIT, 15 vs 12 Apache-2.0 and so on). While it's a very small different, it still favors Syft.

Syft performed better than Trivy in all cases above.

## Task 2 
* SCA Tool Comparison:
  * Both tools detected same amount of critical vulnerabilities, but grype detected more High and Medium, and also pointed to negligble, while Trivy didn't
* Critical Vulnerabilities Analysis:

| Vulnerable Package | Installed Version | Fixed Version | Vulnerability ID | Risk Score | Remediation |
|:---:|:---:|:---:|:---:|:---:|:---:|
| vm2 | 3.9.17 | 3.9.18 | GHSA-whpj-8f3w-67p5 | 65.3 | Upgrade vm2 to 3.9.18 |
| jsonwebtoken | 0.1.0 | 4.2.2 | GHSA-c7hr-j4mj-j2w6 | 37.0 | Upgrade jsonwebtoken to 4.2.2 |
| jsonwebtoken | 0.4.0 | 4.2.2 | GHSA-c7hr-j4mj-j2w6 | 37.0 | Upgrade jsonwebtoken to 4.2.2 |
| vm2 | 3.9.17 | 3.9.19 | GHSA-g644-9gfx-q4q4 | 33.4 | Upgrade vm2 to 3.9.19 |
| vm2 | 3.9.17 | 3.9.19 | GHSA-cchq-frgv-rjh5 | 4.4 | Upgrade vm2 to 3.9.19 |

* License Compliance Assessment
  * Trivy found the following risky licenses and why they consideres so 

| License Name | Package(s) | Severity | Notes and Concerns |
|---|---|---|---|
| WTFPL | truncate-utf8-bytes | CRITICAL | Public domain-like but very permissive, no warranty or liability. Verify project policy acceptance. |
| GPL-2.0-or-later | base-files, gcc-12-base | HIGH | Strong copyleft license; requires derivative works to be open source under GPL. Commercial usage risks. |
| GPL-3.0-only | gcc-12-base | HIGH | More strict than GPL-2.0, including patent clauses. |
| GPL-2.0-only | gcc-12-base, libc6, netbase, fuzzball | HIGH | Legacy GPL with strong copyleft, impacts distribution. |
| LGPL-2.0-or-later | gcc-12-base | HIGH | Lesser copyleft, permits linking but modifications need sharing. |
| LGPL-2.1-only | libc6 | HIGH | Similar to LGPL-2.0, with clarifications and extensions. |
| GPL-1.0-or-later/only | libssl3 | HIGH | Very old GPL; impacts derivative works, requires disclosure. |
| LGPL-3.0-only | web3 and many of its sub-packages | HIGH | Modern LGPL version; allows linking but source changes must be shared. |

* Additional Security Features

  * Trivy found 4 secrets in

| Location | Type Severity | Sever |
|:---:|:---:|:---:|
| /juice-shop/build/lib/insecurity.js | AssymetricPrivateKey | HIGH  |
| /juice-shop/frontend/src/app/app.guard.spec.ts | JWT token | MEDIUM  |
| /juice-shop/frontend/src/app/last-login-ip/last-login-ip.component.spec.ts | JWT token | MEDIUM |
| /juice-shop/lib/insecurity.ts | AssymetricPrivateKey | HIGH  |

The obvious remediation from it, is to remove them all from codebase

## Task 3 - Toolchain Comparison: Syft+Grype vs Trivy All-in-One
####  Accuracy Analysis - package detection and vulnerability overlap quantified
  * Tools detected 1126 common packages and 13 syft unique and 9 Trivy unique. Very high overlap with minor difference, although syft worked good with all packages, including OS related, while Trivy struggles with them.
  * Grype found 58 CVE, and Trivy found 62. While there's only 15 common in report, they use different formats (CVE for Trivy and GHSA for Syft+Grype, taking vulnerabilities from different databases), so I cannot state how many common vulnerabilities they actually detected. But considering some CVE entries aren't present in GHSA and vice versa. It makes sense to use both tools to detect all vulnerabilities.

####  Tool Strengths and Weaknesses - practical observations from your testing
  *  Syft+Grype has better native packages support, provides detailed vulnerability risk skoring with epss estimate. But it doesn't provide licenses risks, may miss some CVE entries and packages.
  *  Trivy has more built-in functionality, such as secret scanning and multi-layer image support, good licence detection with metadata, better detects CVE. But may miss GHSA, lacks native packages support, classifies more packages a unknown.

####  Use Case Recommendations - when to choose Syft+Grype vs Trivy
  *  Trivy works better as AIO solution for container native environments, where broad coverage with false positives is acceptable.
  *  Syft+Grype work when very accurate (precise package classification, detailed vulnerability risk assessment with EPSS) report is preferred.
  *  But overall both tools can be used simultaneously.

####  Integration Considerations - CI/CD, automation, and operational aspects
Both tools suited for CI/CD integration, but while Trivy works out of the box, Syft+Grype may need more configuration.
