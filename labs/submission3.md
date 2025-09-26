# Lab 3 — Secure Git Submission

## Task 1 — SSH Commit Signature Verification

### Summary: Why sign commits?
- Authenticity: ensures commits come from the claimed author, mitigating impersonation.
- Integrity: cryptographic signatures detect tampering after commit creation.
- Accountability: traceable provenance supports audits and secure SDLC.
- Supply-chain defense: reduces risk of malicious commits in CI/CD pipelines.

### Evidence of setup
- Add the ssh key in GitHub as Signing key
- `git config --global gpg.format ssh`
- `git config --global commit.gpgSign true`
- `git config --global user.signingkey <ssh-ed25519 key>`

### Analysis: Why is commit signing critical in DevSecOps?
Commit signing enforces trusted provenance of changes, enabling policy gates (e.g., only verified commits allowed) and incident forensics. It helps prevent unauthorized code injection and strengthens controls across code review, CI, and release promotion.

### Verification
Add a signed commit and verify the "Verified" badge on GitHub.
![asset](/assets/lab3/git-verify-commit.png)

## Task 2 — Pre-commit Secret Scanning

### Setup summary
- Configured a local Git `pre-commit` hook in `.git/hooks/pre-commit` to scan staged files.
- Uses Docker images `trufflesecurity/trufflehog:latest` and `zricethezav/gitleaks:latest`.
- Logic:
  - Collects staged files; splits into `lectures/` and non-lectures.
  - Runs TruffleHog only on non-lectures; any finding blocks the commit.
  - Runs Gitleaks per-file; findings in non-lectures block, findings under `lectures/` are allowed as educational content.

### Evidence: blocked commit (secret present)
Steps:
1) Created `tmp/secret-test.txt` with a fake AWS key and staged it.
2) Attempted to commit; hook blocked the commit due to detected secrets.

Output excerpt:
```text
🐷🔑🐷  TruffleHog. Unearth your secrets. 🐷🔑🐷

2025-09-26T14:26:19Z    info-0  trufflehog      running source  {"source_manager_worker_id": "EDqae", "with_units": true}
Found unverified result 🐷🔑❓
Detector Type: SlackWebhook
Decoder Type: BASE64
Raw result: here was a secret
Rotation_guide: https://howtorotate.com/docs/tutorials/slack-webhook/
File: tmp/secret-test.txt
Line: 8

2025-09-26T14:26:20Z    info-0  trufflehog      finished scanning       {"chunks": 2, "bytes": 5353, "verified_secrets": 0, "unverified_secrets": 1, "scan_duration": "979.983192ms", "trufflehog_version": "3.90.8", "verification_caching": {"Hits":0,"Misses":6,"HitsWasted":0,"AttemptsSaved":0,"VerificationTimeSpentMS":4308}}
```

### Evidence: successful commit (no secrets / lectures-only)
Steps:
1) Removed the secret test file from the index and disk.
2) Added a harmless note under `lectures/lec4.md` and committed.

Output excerpt:
```text
[pre-commit] scanning staged files for secrets…
[pre-commit] Files to scan: tmp/secret-test.txt
[pre-commit] Non-lectures files: tmp/secret-test.txt
[pre-commit] Lectures files: none
[pre-commit] TruffleHog scan on non-lectures files…
🐷🔑🐷  TruffleHog. Unearth your secrets. 🐷🔑🐷

2025-09-26T14:23:23Z    info-0  trufflehog      running source  {"source_manager_worker_id": "v8FVn", "with_units": true}
2025-09-26T14:23:23Z    info-0  trufflehog      finished scanning       {"chunks": 1, "bytes": 46, "verified_secrets": 0, "unverified_secrets": 0, "scan_duration": "1.022307ms", "trufflehog_version": "3.90.8", "verification_caching": {"Hits":0,"Misses":0,"HitsWasted":0,"AttemptsSaved":0,"VerificationTimeSpentMS":0}}
[pre-commit] ✓ TruffleHog found no secrets in non-lectures files
[pre-commit] Gitleaks scan on staged files…
[pre-commit] Scanning tmp/secret-test.txt with Gitleaks...
.git/hooks/pre-commit: line 70: [: missing `]'
.git/hooks/pre-commit: line 71: -n: command not found
[pre-commit] No secrets found in tmp/secret-test.txt

[pre-commit] === SCAN SUMMARY ===
TruffleHog found secrets in non-lectures files: false
Gitleaks found secrets in non-lectures files: false
Gitleaks found secrets in lectures files: false

✓ No secrets detected in non-excluded files; proceeding with commit.
.git/hooks/pre-commit: line 105: exit: 0:: numeric argument required
```

### Analysis: Why automated secret scanning matters
- Early prevention: Detects credentials and tokens before they leave the developer machine.
- Defense-in-depth: Complements server-side scanning and CI checks; failures block locally.
- Reduced incident risk: Avoids accidental key exposure, which can lead to account takeover and data breaches.
- Clear exceptions: Policy allows `lectures/` educational content while protecting all other paths.
