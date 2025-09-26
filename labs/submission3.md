# Lab Submission 3: Commit Signing with GPG/SSH Keys

## Summary: Benefits of Signing Commits for Security

Signing commits ensures that code contributions are **authentic and tamper-proof**. It allows developers and reviewers to:

- Verify the identity of the commit author.
- Prevent unauthorized changes from being introduced into the codebase.
- Improve trust in collaborative environments and CI/CD pipelines.
- Enhance auditability, especially for security-sensitive projects.

Signed commits are a critical part of maintaining integrity and accountability in software projects.

## Analysis: Why Commit Signing is Critical in DevSecOps Workflows##

In DevSecOps, security is integrated into every stage of the software development lifecycle. Commit signing is critical because it:

- Prevents supply chain attacks: Verifies that code changes are from trusted contributors.

- Supports automated compliance checks: CI/CD pipelines can enforce that only signed commits are merged.

- Increases accountability: Each contribution can be traced to a verified developer, reducing insider threat risks.

- Facilitates trust in open-source contributions: Particularly important when integrating external libraries or modules.

Overall, signed commits strengthen the security posture and integrity of the development process.

Verified commit:
![](lab3/image.png)

git add secret.txt
git commit -m "test secret detection"
[pre-commit] scanning staged files for secrets…
[pre-commit] Files to scan: secret.txt
[pre-commit] Non-lectures files: secret.txt
[pre-commit] Lectures files: none
[pre-commit] TruffleHog scan on non-lectures files…
docker: permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Head "http://%2Fvar%2Frun%2Fdocker.sock/_ping": dial unix /var/run/docker.sock: connect: permission denied

Run 'docker run --help' for more information
[pre-commit] ✖ TruffleHog detected potential secrets in non-lectures files
[pre-commit] Gitleaks scan on staged files…
[pre-commit] Scanning secret.txt with Gitleaks...
[pre-commit] No secrets found in secret.txt

[pre-commit] === SCAN SUMMARY ===
TruffleHog found secrets in non-lectures files: true
Gitleaks found secrets in non-lectures files: false
Gitleaks found secrets in lectures files: false

✖ COMMIT BLOCKED: Secrets detected in non-excluded files.
Fix or unstage the offending files and try again.




Success (after deleting files):
[r3taker@r3taker-pc F25-DevSecOps-Intro]git commit -S -m "test commit after removing secret"
[pre-commit] scanning staged files for secrets…
[pre-commit] Files to scan: labs/submission3.md
[pre-commit] Non-lectures files: labs/submission3.md
[pre-commit] Lectures files: none
[pre-commit] TruffleHog scan on non-lectures files…
Unable to find image 'trufflesecurity/trufflehog:latest' locally
latest: Pulling from trufflesecurity/trufflehog
9824c27679d3: Already exists
4ba05507e91a: Pulling fs layer
4f4fb700ef54: Pulling fs layer
220ea09697b6: Pulling fs layer
0fd16777440c: Pulling fs layer
0fd16777440c: Waiting
4f4fb700ef54: Verifying Checksum
4f4fb700ef54: Download complete
0fd16777440c: Download complete
220ea09697b6: Verifying Checksum
220ea09697b6: Download complete
4ba05507e91a: Verifying Checksum
4ba05507e91a: Download complete
4ba05507e91a: Pull complete
4f4fb700ef54: Pull complete
220ea09697b6: Pull complete
0fd16777440c: Pull complete
Digest: sha256:5dc064868ba7933601b5cbaea6954954d524ddd5dc6222a9667acea70068bf7d
Status: Downloaded newer image for trufflesecurity/trufflehog:latest
🐷🔑🐷  TruffleHog. Unearth your secrets. 🐷🔑🐷

2025-09-26T18:11:37Z	info-0	trufflehog	running source	{"source_manager_worker_id": "BjGjh", "with_units": true}
2025-09-26T18:11:37Z	info-0	trufflehog	finished scanning	{"chunks": 1, "bytes": 2420, "verified_secrets": 0, "unverified_secrets": 0, "scan_duration": "1.16996ms", "trufflehog_version": "3.90.8", "verification_caching": {"Hits":0,"Misses":0,"HitsWasted":0,"AttemptsSaved":0,"VerificationTimeSpentMS":0}}
[pre-commit] ✓ TruffleHog found no secrets in non-lectures files
[pre-commit] Gitleaks scan on staged files…
[pre-commit] Scanning labs/submission3.md with Gitleaks...
^[[A^[[B^[[D^[[C[pre-commit] No secrets found in labs/submission3.md

[pre-commit] === SCAN SUMMARY ===
TruffleHog found secrets in non-lectures files: false
Gitleaks found secrets in non-lectures files: false
Gitleaks found secrets in lectures files: false

