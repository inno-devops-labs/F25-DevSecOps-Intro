# Lab 3 — Secure Git Practices Implementation

## Task 1: SSH Commit Signature Verification


### 1.1 Benefits of Commit Signing

Commit signing provides cryptographic verification that:

**Authenticity**: Confirms the commit was made by the claimed author

**Integrity**: Guarantees the commit hasn't been tampered with after signing

**Non-repudiation**: Prevents authors from denying their commits

**Trust**: Establishes verifiable identity in collaborative environments

### 1.2 SSH Key Setup Evidence

``` bash
ssh-keygen -t ed25519 -C "aminovvolna2005@gmail.com"
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgSign true
git config --global gpg.format ssh

```
Evidence of successful SSH key setup and configuration:
```
git config --global --list
```
![local-evidence](/labs/sub3/local-evidence.png)


Verified evidence:

```
git checkout -b feature/lab3
git add .
git commit -S -m "docs: add commit signing summary"
git push origin feature/lab3
```
![verified](/labs/sub3/verified-evidence.png)

### 1.3 Analysis: Why is commit signing critical in DevSecOps workflows?

Commit signing is essential in DevSecOps because:
* **Supply Chain Security**: Verifies code changes come from trusted sources before deployment

* **Audit Compliance**: Provides cryptographic evidence for regulatory requirements

* **CI/CD Pipeline Trust**: Ensures automated pipelines process only authenticated code

* **Attack Prevention**: Mitigates insider threats and repository compromise risks

* **Accountability**: Creates clear responsibility for changes in team environments



## Task 2: Pre-commit Secret Scanning

### 2.1 Pre-commit Hook Setup Process and Configuration

**Setup Process:**
1. **Created hook file** in `.git/hooks/pre-commit` using nano editor
2. **Made hook executable** with `chmod +x .git/hooks/pre-commit`
3. **Implemented dual-scanning approach** with TruffleHog and Gitleaks
4. **Tested hook functionality** with various secret patterns

**Configuration Details:**
- **Hook Type**: Bash script executed before each commit
- **Scanning Tools**: 
  - TruffleHog v3.90.8 (Dockerized) - for comprehensive secret detection
  - Gitleaks latest (Dockerized) - for pattern-based scanning
- **File Filtering**: Excludes `lectures/` directory from blocking
- **Execution Flow**:
  1. Collects staged files using `git diff --cached`
  2. Separates lectures vs non-lectures files
  3. Runs TruffleHog on non-lectures files
  4. Runs Gitleaks on all staged files
  5. Blocks commit if secrets detected in non-excluded files

**Docker Configuration:**
```bash
# TruffleHog scan command
docker run --rm -v "$(pwd):/repo" -w /repo trufflesecurity/trufflehog:latest filesystem

# Gitleaks scan command  
docker run --rm -v "$(pwd):/repo" -w /repo zricethezav/gitleaks:latest detect
```
### 2.2 Secret Detection Testing

**Test 1: Blocked Commit with Secrets**
```bash
# Added test AWS keys to file
echo "AWS_KEY=AKIA0123456789ABCDEF" > labs/test_secret.txt
git add labs/test_secret.txt
git commit -m "test: secret detection"
```
 **RESULT**: Commit blocked by Gitleaks:

 ``` bash
 ⚡ramil ❯❯ git commit -m "test: secret detection"
[pre-commit] scanning staged files for secrets…
[pre-commit] Files to scan: labs/sub3/verified-evidence.png labs/submission3.md labs/test_secret.txt
[pre-commit] Non-lectures files: labs/sub3/verified-evidence.png labs/submission3.md labs/test_secret.txt
[pre-commit] Lectures files: none
[pre-commit] TruffleHog scan on non-lectures files…
🐷🔑🐷  TruffleHog. Unearth your secrets. 🐷🔑🐷

2025-09-26T10:13:08Z    info-0  trufflehog      running source  {"source_manager_worker_id": "KJzFw", "with_units": true}
2025-09-26T10:13:08Z    info-0  trufflehog      finished scanning       {"chunks": 2, "bytes": 1638, "verified_secrets": 0, "unverified_secrets": 0, "scan_duration": "1.232483ms", "trufflehog_version": "3.90.8", "verification_caching": {"Hits":0,"Misses":0,"HitsWasted":0,"AttemptsSaved":0,"VerificationTimeSpentMS":0}}
[pre-commit] ✓ TruffleHog found no secrets in non-lectures files
[pre-commit] Gitleaks scan on staged files…
[pre-commit] Scanning labs/sub3/verified-evidence.png with Gitleaks...
[pre-commit] No secrets found in labs/sub3/verified-evidence.png
[pre-commit] Scanning labs/submission3.md with Gitleaks...
[pre-commit] No secrets found in labs/submission3.md
[pre-commit] Scanning labs/test_secret.txt with Gitleaks...
Gitleaks found secrets in labs/test_secret.txt:
Finding:     AWS_KEY=AKIA0123456789ABCDEF
Secret:      AKIA0123456789ABCDEF
RuleID:      generic-api-key
Entropy:     4.084184
File:        labs/test_secret.txt
Line:        1
Fingerprint: labs/test_secret.txt:generic-api-key:1

10:13AM INF scanned ~28 bytes (28 bytes) in 20.9ms
10:13AM WRN leaks found: 1
---
✖ Secrets found in non-excluded file: labs/test_secret.txt

[pre-commit] === SCAN SUMMARY ===
TruffleHog found secrets in non-lectures files: false
Gitleaks found secrets in non-lectures files: true
Gitleaks found secrets in lectures files: false

✖ COMMIT BLOCKED: Secrets detected in non-excluded files.
Fix or unstage the offending files and try again.
 ```

**Test 2: Commit without Secrets**
```bash
# Remove AWS key from file
echo "No secrets" > labs/test_secret.txt
git add labs/test_secret.txt
git commit -m "test: clean commit"
```
**Result:**
``` bash
 ⚡ramil ❯❯ git commit -m "test: clean commit"
[pre-commit] scanning staged files for secrets…
[pre-commit] Files to scan: labs/sub3/verified-evidence.png labs/test_secret.txt
[pre-commit] Non-lectures files: labs/sub3/verified-evidence.png labs/test_secret.txt
[pre-commit] Lectures files: none
[pre-commit] TruffleHog scan on non-lectures files…
🐷🔑🐷  TruffleHog. Unearth your secrets. 🐷🔑🐷

2025-09-26T10:25:41Z    info-0  trufflehog      running source  {"source_manager_worker_id": "6JbQs", "with_units": true}
2025-09-26T10:25:41Z    info-0  trufflehog      finished scanning       {"chunks": 1, "bytes": 11, "verified_secrets": 0, "unverified_secrets": 0, "scan_duration": "914.889µs", "trufflehog_version": "3.90.8", "verification_caching": {"Hits":0,"Misses":0,"HitsWasted":0,"AttemptsSaved":0,"VerificationTimeSpentMS":0}}
[pre-commit] ✓ TruffleHog found no secrets in non-lectures files
[pre-commit] Gitleaks scan on staged files…
[pre-commit] Scanning labs/sub3/verified-evidence.png with Gitleaks...
[pre-commit] No secrets found in labs/sub3/verified-evidence.png
[pre-commit] Scanning labs/test_secret.txt with Gitleaks...
[pre-commit] No secrets found in labs/test_secret.txt

[pre-commit] === SCAN SUMMARY ===
TruffleHog found secrets in non-lectures files: false
Gitleaks found secrets in non-lectures files: false
Gitleaks found secrets in lectures files: false

✓ No secrets detected in non-excluded files; proceeding with commit.
[feature/lab3 8d0d4b2] test: clean commit
 3 files changed, 1 insertion(+)
 rename labs/{sub2 => sub3}/local-evidence.png (100%)
 create mode 100644 labs/sub3/verified-evidence.png
 create mode 100644 labs/test_secret.txt
```

### 2.3 Analysis: How Automated Secret Scanning Prevents Security Incidents

- **Prevention**
    - Blocks secrets before they reach remote repos
    - Prevents accidental exposure at source

- **Cost Saving**
    - Avoids expensive secret rotation
    - Eliminates breach remediation costs

- **Compliance**
    - Automated policy enforcement
    - Audit-ready security controls

 **Core Advantage — Shift-Left Security:**

Moves protection from post-commit detection to pre-commit prevention.