# Task 1
This is mainly done to confirm that the commit was made by the author. It's easy to change the authorship information in unsigned commits. Additionally, it guarantees that the commit hasn't been modified.

These are all security measures in various organizations and even in open source projects.

# Task 2

Attempt to make commit with fake api key:

```bash
bulatgazizov@fedora:~/Projects/F25-DevSecOps-Intro$ nano .env
bulatgazizov@fedora:~/Projects/F25-DevSecOps-Intro$ git add .env
bulatgazizov@fedora:~/Projects/F25-DevSecOps-Intro$ git commit -m "test commit with fake api key"
[pre-commit] scanning staged files for secrets…
[pre-commit] Files to scan: .env
[pre-commit] Non-lectures files: .env
[pre-commit] Lectures files: none
[pre-commit] TruffleHog scan on non-lectures files…
🐷🔑🐷  TruffleHog. Unearth your secrets. 🐷🔑🐷

2025-09-26T19:14:54Z    info-0  trufflehog      running source  {"source_manager_worker_id": "AAeNp", "with_units": true}
2025-09-26T19:14:54Z    info-0  trufflehog      finished scanning       {"chunks": 1, "bytes": 41, "verified_secrets": 0, "unverified_secrets": 0, "scan_duration": "729.724µs", "trufflehog_version": "3.90.8", "verification_caching": {"Hits":0,"Misses":0,"HitsWasted":0,"AttemptsSaved":0,"VerificationTimeSpentMS":0}}
[pre-commit] ✓ TruffleHog found no secrets in non-lectures files
[pre-commit] Gitleaks scan on staged files…
[pre-commit] Scanning .env with Gitleaks...
Gitleaks found secrets in .env:
Finding:     API_KEY=**************
Secret:      **************
RuleID:      generic-api-key
Entropy:     4.413910
File:        .env
Line:        1
Fingerprint: .env:generic-api-key:1

7:14PM INF scanned ~41 bytes (41 bytes) in 22.3ms
7:14PM WRN leaks found: 1
---
✖ Secrets found in non-excluded file: .env

[pre-commit] === SCAN SUMMARY ===
TruffleHog found secrets in non-lectures files: false
Gitleaks found secrets in non-lectures files: true
Gitleaks found secrets in lectures files: false

✖ COMMIT BLOCKED: Secrets detected in non-excluded files.
Fix or unstage the offending files and try again.
```

Without key:

```bash
bulatgazizov@fedora:~/Projects/F25-DevSecOps-Intro$ git rm -f .env
bulatgazizov@fedora:~/Projects/F25-DevSecOps-Intro$ touch .env
bulatgazizov@fedora:~/Projects/F25-DevSecOps-Intro$ git add .env
bulatgazizov@fedora:~/Projects/F25-DevSecOps-Intro$ git commit -m "test commit without api key"
[pre-commit] scanning staged files for secrets…
[pre-commit] Files to scan: .env
[pre-commit] Non-lectures files: .env
[pre-commit] Lectures files: none
[pre-commit] TruffleHog scan on non-lectures files…
🐷🔑🐷  TruffleHog. Unearth your secrets. 🐷🔑🐷

2025-09-26T19:19:25Z    info-0  trufflehog      running source  {"source_manager_worker_id": "78lLX", "with_units": true}
2025-09-26T19:19:25Z    info-0  trufflehog      finished scanning       {"chunks": 0, "bytes": 0, "verified_secrets": 0, "unverified_secrets": 0, "scan_duration": "648.754µs", "trufflehog_version": "3.90.8", "verification_caching": {"Hits":0,"Misses":0,"HitsWasted":0,"AttemptsSaved":0,"VerificationTimeSpentMS":0}}
[pre-commit] ✓ TruffleHog found no secrets in non-lectures files
[pre-commit] Gitleaks scan on staged files…
[pre-commit] Scanning .env with Gitleaks...
[pre-commit] No secrets found in .env

[pre-commit] === SCAN SUMMARY ===
TruffleHog found secrets in non-lectures files: false
Gitleaks found secrets in non-lectures files: false
Gitleaks found secrets in lectures files: false

✓ No secrets detected in non-excluded files; proceeding with commit.
[feature/lab3 20997ac] test commit without api key
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 .env
 ```