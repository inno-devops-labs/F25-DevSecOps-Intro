
# Lab 10 — Vulnerability Management & Response with DefectDojo

**Open Findings by Severity:**

- **Critical:** 9 vulnerabilities
- **High:** 26 vulnerabilities
- **Medium:** 28 vulnerabilities
- **Low:** 4 vulnerabilities

**Key Security Issues Identified:**

- **Multiple Critical Library Vulnerabilities** - The application contains several critical dependencies with known security flaws, including `vm2` sandbox escape vulnerabilities (CVE-2023-32314, CVE-2023-37466, CVE-2023-37903), `jsonwebtoken` authentication bypass issues (CVE-2015-9235), and weak cryptographic implementation in `crypto-js` (CVE-2023-46233)
- **System-Level Security Risks** - The underlying Debian system shows multiple glibc vulnerabilities (CVE-2019-1010022, CVE-2025-4802) that could allow privilege escalation and stack protection bypass, affecting the container's base security posture
- **Recurring Vulnerability Patterns** - The assessment reveals consistent issues across multiple components including prototype pollution in `lodash` (CVE-2019-10744), regular expression denial of service in various packages, and insufficient input validation leading to potential XSS and code injection vulnerabilities

**Immediate Concerns:**

- All 67 findings are currently active and verified, requiring urgent remediation
- Several vulnerabilities have public exploits available and should be prioritized for patching
- The container base image requires updating to address systemic library vulnerabilities

**Recommendation:** Immediate dependency updates and container base image refresh are recommended to address the critical and high-severity vulnerabilities identified in this assessment.
