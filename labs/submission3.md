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

[r3taker@r3taker-pc F25-DevSecOps-Intro]$ echo "FAKE_AWS_KEY=ABCD1234" > secret.txt
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
