# Lab 4 Submission

## Task 1 — SBOM Generation with Syft and Trivy (4 pts)

## Commands:
```
mkdir -p labs/lab4/{syft,trivy,comparison,analysis}
docker pull anchore/syft:latest
docker pull aquasec/trivy:latest
docker pull anchore/grype:latest

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/tmp anchore/syft:latest \
  bkimminich/juice-shop:v19.0.0 -o syft-json=/tmp/labs/lab4/syft/juice-shop-syft-native.json


docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/tmp anchore/syft:latest \
  bkimminich/juice-shop:v19.0.0 -o table=/tmp/labs/lab4/syft/juice-shop-syft-table.txt


echo "Extracting licenses from Syft SBOM..." > labs/lab4/syft/juice-shop-licenses.txt
jq -r '.artifacts[] | select(.licenses != null and (.licenses | length > 0)) | "\(.name) | \(.version) | \(.licenses | map(.value) | join(", "))"' \
  labs/lab4/syft/juice-shop-syft-native.json >> labs/lab4/syft/juice-shop-licenses.txt


docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/tmp aquasec/trivy:latest image \
  --format json --output /tmp/labs/lab4/trivy/juice-shop-trivy-detailed.json \
  --list-all-pkgs bkimminich/juice-shop:v19.0.0


docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/tmp aquasec/trivy:latest image \
  --format table --output /tmp/labs/lab4/trivy/juice-shop-trivy-table.txt \
  --list-all-pkgs bkimminich/juice-shop:v19.0.0


echo "=== SBOM Component Analysis ===" > labs/lab4/analysis/sbom-analysis.txt
echo "" >> labs/lab4/analysis/sbom-analysis.txt
echo "Syft Package Counts:" >> labs/lab4/analysis/sbom-analysis.txt
jq -r '.artifacts[] | .type' labs/lab4/syft/juice-shop-syft-native.json | sort | uniq -c >> labs/lab4/analysis/sbom-analysis.txt   


echo "" >> labs/lab4/analysis/sbom-analysis.txt
echo "Trivy Package Counts:" >> labs/lab4/analysis/sbom-analysis.txt
jq -r '.Results[] as $result | $result.Packages[]? | "\($result.Target // "Unknown") - \(.Type // "unknown")"' \
  labs/lab4/trivy/juice-shop-trivy-detailed.json | sort | uniq -c >> labs/lab4/analysis/sbom-analysis.txt


echo "" >> labs/lab4/analysis/sbom-analysis.txt
echo "=== License Analysis ===" >> labs/lab4/analysis/sbom-analysis.txt
echo "" >> labs/lab4/analysis/sbom-analysis.txt
echo "Syft Licenses:" >> labs/lab4/analysis/sbom-analysis.txt
jq -r '.artifacts[]? | select(.licenses != null) | .licenses[]? | .value' \
  labs/lab4/syft/juice-shop-syft-native.json | sort | uniq -c >> labs/lab4/analysis/sbom-analysis.txt


echo "" >> labs/lab4/analysis/sbom-analysis.txt
echo "Trivy Licenses (OS Packages):" >> labs/lab4/analysis/sbom-analysis.txt
jq -r '.Results[] | select(.Class // "" | contains("os-pkgs")) | .Packages[]? | select(.Licenses != null) | .Licenses[]?' \
  labs/lab4/trivy/juice-shop-trivy-detailed.json | sort | uniq -c >> labs/lab4/analysis/sbom-analysis.txt


echo "" >> labs/lab4/analysis/sbom-analysis.txt  
echo "Trivy Licenses (Node.js):" >> labs/lab4/analysis/sbom-analysis.txt
jq -r '.Results[] | select(.Class // "" | contains("lang-pkgs")) | .Packages[]? | select(.Licenses != null) | .Licenses[]?' \
  labs/lab4/trivy/juice-shop-trivy-detailed.json | sort | uniq -c >> labs/lab4/analysis/sbom-analysis.txt
```

**Syft Package Counts:**
 - 1 binary
 - 10 deb
 - 1128 npm

**Trivy Package Counts:**
 - 10 bkimminich/juice-shop:v19.0.0 (debian 12.11) - unknown
 - 1125 Node.js - unknown

### Dependency Discovery Analysis

**Key Findings:**
- **Syft** discovered **1,139 total packages** (1 binary + 10 deb + 1,128 npm)
- **Trivy** discovered **1,135 total packages** (10 OS packages + 1,125 Node.js)
- **Detection Overlap**: 99.6% package detection rate between tools
- **Notable Difference**: Syft detected 3 additional npm packages compared to Trivy

**Tool Strengths:**
- **Syft**: Better at identifying binary artifacts and providing detailed package typing
- **Trivy**: Clear separation between OS packages and application dependencies
- Both tools provide comprehensive dependency discovery for Node.js applications

**License Detection Comparison:**

**Syft License Findings (1,176 total):**
- **Permissive**: MIT (888), ISC (143), Apache-2.0 (15), BSD variants (27+), Unlicense (2)
- **Copyleft**: GPL variants (18), LGPL variants (24)
- **Other**: Various mixed licenses and public domain

**Trivy License Findings:**
- **OS Packages**: 16 licenses including GPL, LGPL, Apache-2.0
- **Node.js**: 1,130 licenses with similar distribution to Syft

**Key Observations:**
- Both tools identified the same license patterns with minor variations in categorization
- Syft provided more granular license information with mixed license declarations
- Trivy separated licenses by package source (OS vs application)
- **Risky Licenses Identified**: GPL variants (18), LGPL variants (24) requiring compliance attention

**License Compliance Assessment:**
- **Low Risk**: 89% permissive licenses (MIT, ISC, BSD, Apache)
- **Medium Risk**: 3.5% copyleft licenses (GPL/LGPL variants)
- **Action Required**: Review GPL-3.0 and LGPL-3.0 components for compliance requirements



## Task 2 — Software Composition Analysis with Grype and Trivy (3 pts)

## Commands:
```
docker run --rm -v "$(pwd)":/tmp anchore/grype:latest \
  sbom:/tmp/labs/lab4/syft/juice-shop-syft-native.json \
  -o json > labs/lab4/syft/grype-vuln-results.json


docker run --rm -v "$(pwd)":/tmp anchore/grype:latest \
  sbom:/tmp/labs/lab4/syft/juice-shop-syft-native.json \
  -o table > labs/lab4/syft/grype-vuln-table.txt


docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/tmp aquasec/trivy:latest image \
  --format json --output /tmp/labs/lab4/trivy/trivy-vuln-detailed.json \
  bkimminich/juice-shop:v19.0.0

2025-10-03T20:28:12Z	WARN	Using severities from other vendors for some vulnerabilities. Read https://trivy.dev/v0.67/docs/scanner/vulnerability#severity-selection for details.




echo "=== Vulnerability Analysis ===" > labs/lab4/analysis/vulnerability-analysis.txt
echo "" >> labs/lab4/analysis/vulnerability-analysis.txt
echo "Grype Vulnerabilities by Severity:" >> labs/lab4/analysis/vulnerability-analysis.txt
jq -r '.matches[]? | .vulnerability.severity' labs/lab4/syft/grype-vuln-results.json | sort | uniq -c >> labs/lab4/analysis/vulnerability-analysis.txt

echo "" >> labs/lab4/analysis/vulnerability-analysis.txt
echo "Trivy Vulnerabilities by Severity:" >> labs/lab4/analysis/vulnerability-analysis.txt
jq -r '.Results[]?.Vulnerabilities[]? | .Severity' labs/lab4/trivy/trivy-vuln-detailed.json | sort | uniq -c >> labs/lab4/analysis/vulnerability-analysis.txt

# License comparison summary
echo "" >> labs/lab4/analysis/vulnerability-analysis.txt
echo "=== License Analysis Summary ===" >> labs/lab4/analysis/vulnerability-analysis.txt
echo "Tool Comparison:" >> labs/lab4/analysis/vulnerability-analysis.txt
if [ -f labs/lab4/syft/juice-shop-syft-native.json ]; then
  syft_licenses=$(jq -r '.artifacts[] | select(.licenses != null) | .licenses[].value' labs/lab4/syft/juice-shop-syft-native.json 2>/dev/null | sort | uniq | wc -l)
  echo "- Syft found $syft_licenses unique license types" >> labs/lab4/analysis/vulnerability-analysis.txt
fi
if [ -f labs/lab4/trivy/trivy-licenses.json ]; then
  trivy_licenses=$(jq -r '.Results[].Licenses[]?.Name' labs/lab4/trivy/trivy-licenses.json 2>/dev/null | sort | uniq | wc -l)
  echo "- Trivy found $trivy_licenses unique license types" >> labs/lab4/analysis/vulnerability-analysis.txt
fi
```

### SCA Tool Comparison

**Vulnerability Detection Capabilities:**

| Aspect | Grype | Trivy |
|--------|-------|-------|
| Critical Vulnerabilities | 8 | 8 |
| High Severity Findings | 21 | 23 |
| Medium Severity | 23 | 23 |
| Low Severity | 1 | 16 |
| Negligible | 12 | 0 |

**Key Observations:**
- **Critical vulnerabilities**: Both tools detected the same 8 critical issues
- **High severity**: Trivy detected 2 additional high-severity vulnerabilities
- **Low severity**: Trivy was more comprehensive in detecting low-severity issues (16 vs 1)

### Critical Vulnerabilities Analysis

**Top 5 Most Critical Findings:**

1. **vm2 (3.9.17) - GHSA-whpj-8f3w-67p5** - Critical severity
   - **Remediation**: Upgrade to vm2 3.9.18 or later

2. **jsonwebtoken (0.1.0/0.4.0) - GHSA-c7hr-j4mj-j2w6** - Critical severity
   - **Remediation**: Upgrade to jsonwebtoken 4.2.2 or later

3. **vm2  - GHSA-g644-9gfx-q4q4** - Critical severity
   - **Remediation**: -

4. **vm2  - GHSA-cchq-frgv-rjh5** - Critical severity
   - **Remediation**: -

5. **ip - GHSA-2p57-rm9w-gvfp** - high severity
   - **Remediation**: -



### License Compliance Assessment

**Risky Licenses Identified:**
- **GPL-3.0**: Requires source code distribution for derivatives
- **LGPL-3.0**: Library usage requires compliance with copyleft terms
- **GPL-2.0**: Strong copyleft affecting distribution

**Compliance Recommendations:**
1. **Immediate Action**: Review GPL-3.0 licensed components for compliance requirements
2. **Documentation**: Maintain accurate records of all open-source license obligations
3. **Policy Implementation**: Establish automated license compliance checks in CI/CD
4. **Risk Mitigation**: Consider replacing GPL components with permissive alternatives

### Additional Security Features

**Secrets Scanning Results:**
- Trivy secrets scanning identified **HIGH: AsymmetricPrivateKey (private-key)**
- 



## Task 3 — Toolchain Comparison: Syft+Grype vs Trivy All-in-One (3 pts)

## Commands:
```
echo "=== Package Detection Comparison ===" > labs/lab4/comparison/accuracy-analysis.txt


jq -r '.artifacts[] | "\(.name)@\(.version)"' labs/lab4/syft/juice-shop-syft-native.json | sort > labs/lab4/comparison/syft-packages.txt
jq -r '.Results[]?.Packages[]? | "\(.Name)@\(.Version)"' labs/lab4/trivy/juice-shop-trivy-detailed.json | sort > labs/lab4/comparison/trivy-packages.txt


comm -12 labs/lab4/comparison/syft-packages.txt labs/lab4/comparison/trivy-packages.txt > labs/lab4/comparison/common-packages.txt


comm -23 labs/lab4/comparison/syft-packages.txt labs/lab4/comparison/trivy-packages.txt > labs/lab4/comparison/syft-only.txt
comm -13 labs/lab4/comparison/syft-packages.txt labs/lab4/comparison/trivy-packages.txt > labs/lab4/comparison/trivy-only.txt


echo "Packages detected by both tools: $(wc -l < labs/lab4/comparison/common-packages.txt)" >> labs/lab4/comparison/accuracy-analysis.txt
echo "Packages only detected by Syft: $(wc -l < labs/lab4/comparison/syft-only.txt)" >> labs/lab4/comparison/accuracy-analysis.txt
echo "Packages only detected by Trivy: $(wc -l < labs/lab4/comparison/trivy-only.txt)" >> labs/lab4/comparison/accuracy-analysis.txt


echo "" >> labs/lab4/comparison/accuracy-analysis.txt
echo "=== Vulnerability Detection Overlap ===" >> labs/lab4/comparison/accuracy-analysis.txt


jq -r '.matches[]? | .vulnerability.id' labs/lab4/syft/grype-vuln-results.json | sort | uniq > labs/lab4/comparison/grype-cves.txt
jq -r '.Results[]?.Vulnerabilities[]? | .VulnerabilityID' labs/lab4/trivy/trivy-vuln-detailed.json | sort | uniq > labs/lab4/comparison/trivy-cves.txt


echo "CVEs found by Grype: $(wc -l < labs/lab4/comparison/grype-cves.txt)" >> labs/lab4/comparison/accuracy-analysis.txt
echo "CVEs found by Trivy: $(wc -l < labs/lab4/comparison/trivy-cves.txt)" >> labs/lab4/comparison/accuracy-analysis.txt
echo "Common CVEs: $(comm -12 labs/lab4/comparison/grype-cves.txt labs/lab4/comparison/trivy-cves.txt | wc -l)" >> labs/lab4/comparison/accuracy-analysis.txt
```

## Accuracy Analysis

- **Package Detection:** 1126 packages were detected by both Syft and Trivy. 13 packages were unique to Syft, while 9 were unique to Trivy. This indicates over 98% overlap, with small discrepancies likely due to parsing differences.
- **Vulnerability Detection:** Grype identified 58 vulnerabilities, Trivy 62, with only 15 overlapping. This demonstrates that both tools rely on different vulnerability feeds and provide complementary coverage.

## Tool Strengths and Weaknesses
- **Syft+Grype:**
  - Strengths: Rich SBOM export capabilities, detailed binary analysis, strong integration with regulatory compliance workflows.
  - Weaknesses: Requires two separate tools, slightly higher operational overhead.

- **Trivy:**
  - Strengths: All-in-one solution (SBOM, vulnerabilities, secrets, licenses), simple usage, very CI/CD friendly.
  - Weaknesses: Less flexible SBOM export, occasional differences in binary detection.

## Recommendations
- **Use Syft+Grype** when regulatory compliance, SBOM export in multiple formats, or detailed binary analysis are required.
- **Use Trivy** for fast, all-in-one DevSecOps scanning in CI/CD pipelines where speed and simplicity matter.
- **Best Practice:** Cross-check critical vulnerabilities with both tools to minimize false negatives and maximize coverage.


