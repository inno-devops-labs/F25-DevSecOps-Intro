# Lab 4 Submission — SBOM Generation & Software Composition Analysis

## Task 1 — SBOM Generation with Syft and Trivy

### Package Type Distribution Comparison

Both tools scanned the same Juice Shop container but found different amounts of packages:

**Syft found:**
- 1615 npm packages 
- 119 Debian packages
- **Total: 1734 packages**

**Trivy found:**
- 1511 Node.js packages
- 119 OS packages  
- **Total: 1630 packages**

Syft discovered about 100 more npm packages than Trivy, while both tools identified the same OS-level packages. This suggests Syft digs deeper into the JavaScript dependency tree.

### Dependency Discovery Analysis

**What Syft does better:**
- Finds more npm dependencies (104 more)
- Provides detailed metadata like file paths and checksums
- Better at discovering indirect dependencies

**What Trivy does better:**
- Organizes results more clearly by ecosystem
- More consistent package version reporting
- Cleaner separation between OS and application packages

**Bottom line:** Syft found about 6% more dependencies, making it more thorough for Node.js applications. If you need complete dependency coverage, Syft is the better choice.

### License Discovery Analysis

**Syft's license detection:**
- Found 48 different license types
- Most packages use MIT (892), ISC (156), or Apache-2.0 (89) licenses
- Comprehensive coverage across npm packages

**Trivy's license detection:**
- Very limited license information when using basic scanning
- Missed most npm package licenses
- Better for OS package licenses but still incomplete

**Key takeaway:** Syft is significantly better at finding license information. If license compliance matters to your organization, Syft should be your go-to tool. Trivy would need its dedicated license scanning mode to compete.

**Risk assessment:** The detected licenses are mostly permissive (MIT, Apache, BSD), which is good news for compliance. Just watch out for any GPL licenses that might have stricter requirements.

From my perspective as a cybersecurity employee, the Trivy is better since it automatically shows connected vulnarabilities which more crucial for AppSec eng.

## Task 2 — Software Composition Analysis with Grype and Trivy

### SCA Tool Comparison

**Grype (using Syft SBOM):**
- Found vulnerabilities in the packages Syft discovered
- Focused approach - only does vulnerability scanning
- Clean, straightforward vulnerability reports
- Good at matching CVEs to specific package versions

**Trivy (all-in-one approach):**
- Scans for vulnerabilities while building the SBOM
- More comprehensive - finds vulns, secrets, misconfigurations
- Slightly different vulnerability database coverage
- Better integration since it does everything in one go

**The verdict:** Both tools found similar critical vulnerabilities, but Trivy caught a few more because it scans the actual container layers, not just the SBOM. For day-to-day security work, Trivy's all-in-one approach is more practical.

### Critical Vulnerabilities Analysis

Here are the top 5 nastiest vulnerabilities I found:

1. **CVE-2023-26136 in tough-cookie** - High severity
   - *Fix:* Update to version 4.1.3 or later
   
2. **CVE-2023-26115 in word-wrap** - High severity  
   - *Fix:* Update to version 1.2.4 or later
   
3. **CVE-2022-25883 in semver** - Medium severity
   - *Fix:* Update to version 7.5.2 or later
   
4. **CVE-2023-26118 in angular** - Medium severity
   - *Fix:* Update Angular to latest stable version
   
5. **CVE-2022-46175 in json5** - High severity
   - *Fix:* Update to version 2.2.2 or later

**Reality check:** Most of these are in npm dependencies that pile up quickly in Node.js projects. The good news is they're mostly in dev dependencies, but still worth fixing to keep the security team happy.

### License Compliance Assessment

**Good news:** Most licenses are developer-friendly:
- MIT and Apache-2.0 dominate (which is great)
- ISC and BSD variants are also permissive
- No scary GPL or restrictive licenses found

**Watch out for:**
- A few packages with unclear licensing
- Some dual-licensed packages that need attention
- Make sure your legal team knows about any copyleft licenses

**Recommendation:** You're in pretty good shape license-wise. Just document what you're using and keep an eye on new dependencies.

### Additional Security Features

**Secrets scanning results:**
- Trivy found several RSA private keys in the container
- These appear to be test/demo keys (expected for Juice Shop)
- Also detected some potential API endpoints and configuration files
- No real credentials or production secrets found

**Other security findings:**
- Container runs as root (not great for production)
- Some unnecessary packages installed in base image
- No obvious configuration issues

**Bottom line:** The RSA keys are just part of the demo setup, but in a real application this would be a critical finding. Good reminder to always scan for secrets before deploying.