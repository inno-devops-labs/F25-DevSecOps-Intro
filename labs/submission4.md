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