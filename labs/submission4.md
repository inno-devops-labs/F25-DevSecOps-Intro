# Task 1

**Comparison of Syft and Trivy**

### Package Type Distribution

Syft has reported a `binary` package type that Trivy does not mention. The
category only contains 1 package.

Apart from this, package types are the same across the two software tools:
what Syft names `deb` and `npm`, Trivy calls `debian 12.11` and `Node.js`,
respectively.

### Dependency Discovery Analysis

Syft found 3 more `Node.js` packages and 1 more `binary` package than Trivy.
Assuming that the reported packages are indeed used, Syft retrieved better data
than Trivy.

### License Discovery Analysis

Trivy separates licenses of OS packages from licenses of Node packages while
Syft does not.

The sets of license kinds that the tools report differ. Furthermore, the
reported numbers of packages that have a some license differ; for example,
according to Syft, 888 packages have the MIT license, but Trivy reports 878. It
is difficult to conclude that one tool is better than the other.


# Task 2

### SCA Tool Comparison

Both tools (Grype and Trivy) could report vulnerable dependencies, and they
agree on the number of critical vulnerabilities (8). Trivy has detected 3 more
vulnerabilities than Grype.

Grype provides the "fix" field in the json reports that tells what version of
the package is safe. Trivy does not.

### Critical Vulnerabilities Analysis

Since Grype provides the rememdiation explicitly, I will use its report
(`labs/lab4/syft/grype-vuln-results.json`) here.

Interestingly, the json report contains duplicates, so there are exactly 5 distinct
critical vulnerabilities; I discarded the duplicates. I put the `marsdb` vulnerability at
number 1 because it is still not fixed; to remedy it, the developers would have to
invest much time to remove the dependency.

| Number     | Package      | Description                                                                                            | Remediation: Upgrade to     |
| ---------- | ------------ | ------------------------------------------------------------------------------------------------------ | --------------------------- |
| 1          | marsdb       | Command Injection in marsdb                                                                            | (No fix)                    |
| 2          | vm2          | vm2 Sandbox Escape vulnerability                                                                       | 3.9.18                      |
| 3          | jsonwebtoken | Verification Bypass in jsonwebtoken                                                                    | 4.2.2                       |
| 4          | lodash       | Prototype Pollution in lodash                                                                          | 4.17.12                     |
| 5          | crypto-js    | crypto-js PBKDF2 1,000 times weaker than specified in 1993 and 1.3M times weaker than current standard | 4.2.0                       |

### License Compliance Assessment

Trivy categorizes licenses by severity:

| License                             | Severity |
| ----------------------------------- | -------- |
| WTFPL                               | CRITICAL |
| GPL-1.0-only                        | HIGH     |
| GPL-1.0-or-later                    | HIGH     |
| GPL-2.0-only                        | HIGH     |
| GPL-2.0-or-later                    | HIGH     |
| GPL-3.0-only                        | HIGH     |
| LGPL-2.0-or-later                   | HIGH     |
| LGPL-2.1-only                       | HIGH     |
| LGPL-3.0-only                       | HIGH     |
| MPL-2.0                             | MEDIUM   |
| 0BSD                                | LOW      |
| Apache-2.0                          | LOW      |
| Artistic-2.0                        | LOW      |
| BSD-2-Clause                        | LOW      |
| (BSD-2-Clause OR MIT OR Apache-2.0) | LOW      |
| BSD-3-Clause                        | LOW      |
| ISC                                 | LOW      |
| MIT                                 | LOW      |
| (MIT OR Apache-2.0)                 | LOW      |
| (MIT OR WTFPL)                      | LOW      |
| Unlicense                           | LOW      |
| WTFPL OR ISC                        | LOW      |
| (WTFPL OR MIT)                      | LOW      |
| ad-hoc                              | UNKNOWN  |
| BlueOak-1.0.0                       | UNKNOWN  |
| GFDL-1.2-only                       | UNKNOWN  |
| MIT/X11                             | UNKNOWN  |
| public-domain                       | UNKNOWN  |

(Information from `labs/lab4/trivy/trivy-licenses.json`)

No compliance recommendations were given. I assume the developers need to
manually review UNKNOWN-severity licenses, and consider ditching HIGH-severity
dependencies or use them with care. Also, it is unclear why the WTFPL is
considered a critical license since it is very permissive ;)

### Additional Security Features

Trivy has found 4 secrets: 2 (HIGH) asymmetric private keys in
`/juice-shop/build/lib/insecurity.js` and `/juice-shop/lib/insecurity.ts` and
2 (MEDIUM) JWT-tokens in
`/juice-shop/frontend/src/app/app.guard.spec.ts` and
`/juice-shop/frontend/src/app/last-login-ip/last-login-ip.component.spec.ts`.

# Task 3

### Accuracy Analysis

1126 dependencies overlap in the reports, which is 98.1% of the number of
dependencies found by at least one of the tools (1148). Therefore, any of the
tools may be used without the other.

Only 13 CVEs were reported by both tools, which is 9.9% of the number of CVEs
found by at least one of the tools (131). Therefore, to catch more
vulnerabilities, it is necessary to use both programs.

### Tool Strengths and Weaknesses

**Strengths:**

| Syft+Grype                               | Trivy                     |
| ---------------------------------------- | ------------------------- |
| Provides known fixes for vulnerabilities | Is an integrated solution |
|                                          | Reports license severity  |
|                                          | Scans for secrets         |

The weaknesses of each toolchain are that they don't have the other one's
strengths.

### Use Case Recommendations

Trivy:
- Scanning for secrets

Syft+Grype:
- Main focus is on vulnerability scanning and fast patching

Overall, based on my limited experience, I found the two toolchains very
similar.

### Integration Considerations

As has been shown in the lab, both toolchains are very script-friendly since
they can be ran from the shell with docker, and they output json reports which
are easily parseable. Both are suitable for CI/CD pipelines.
