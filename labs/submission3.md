# Lab 3 — Secure Git

## Task 1 — SSH Commit Signature Verification

### 1. Summary of Commit Signing Benefits
Signing commits provides a cryptographic guarantee of authenticity and integrity. Specifically, it:
- Confirms that the commit was made by the claimed author.
- Prevents tampering with the commit history.
- Enhances trust in collaborative workflows, especially in open-source or enterprise environments.
- Is a key practice in DevSecOps, helping to secure the software supply chain.

### 2. Evidence of SSH Key Setup and Configuration
- SSH key used: `ed25519`
- Git configuration:
```bash
git config --global user.signingkey ~/.ssh/id_ed25519
git config --global commit.gpgSign true
git config --global gpg.format ssh
```
- Public signing key added to GitHub Signing Keys.

### 3. Analysis: Importance in DevSecOps
Commit signing is critical in DevSecOps workflows because:
- It ensures that all changes are traceable to verified developers.
- Protects the software supply chain from malicious code injection.
- Provides auditability for compliance and security reviews.
- Encourages secure development practices across teams.

### 4. Verification
The commit is signed and verified on GitHub:
- Verified badge is displayed next to the commit in the repository.
https://github.com/KuchukbaevaRegina/F25-DevSecOps-Intro/blob/feature/lab3/labs/ScreenshotVerified.png

## Task 2 — Pre-commit Secret Scanning

### 1. Pre-commit Hook Setup
- Hook file created at `.git/hooks/pre-commit`
- Hook made executable:
```bash
chmod +x .git/hooks/pre-commit
```
- Configured to scan staged files using Dockerized TruffleHog and Gitleaks.
- Non-lectures files are strictly checked; lectures directory is excluded for educational content.

## 2. Evidence of Secret Detection
- Test secret added to test_secret.txt
- Commit attempt blocked:
https://github.com/KuchukbaevaRegina/F25-DevSecOps-Intro/blob/feature/lab3/labs/image.png
