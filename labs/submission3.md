# Lab 3 — Secure Git Submission

## Task 1 — SSH Commit Signature Verification

### Summary: Why sign commits?
- Authenticity: ensures commits come from the claimed author, mitigating impersonation.
- Integrity: cryptographic signatures detect tampering after commit creation.
- Accountability: traceable provenance supports audits and secure SDLC.
- Supply-chain defense: reduces risk of malicious commits in CI/CD pipelines.

### Evidence of setup
- `git config --global gpg.format ssh`
- `git config --global commit.gpgSign true`
- `git config --global user.signingkey <ssh-ed25519 key>`

### Analysis: Why is commit signing critical in DevSecOps?
Commit signing enforces trusted provenance of changes, enabling policy gates (e.g., only verified commits allowed) and incident forensics. It helps prevent unauthorized code injection and strengthens controls across code review, CI, and release promotion.

### Verification
Add a signed commit and verify the "Verified" badge on GitHub.
![asset](/assets/lab3/git-verify-commit.png)