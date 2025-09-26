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
![local-evidence](/labs/sub2/local-evidence.png)


### 1.3 Analysis: Why is commit signing critical in DevSecOps workflows?

Commit signing is essential in DevSecOps because:
* **Supply Chain Security**: Verifies code changes come from trusted sources before deployment

* **Audit Compliance**: Provides cryptographic evidence for regulatory requirements

* **CI/CD Pipeline Trust**: Ensures automated pipelines process only authenticated code

* **Attack Prevention**: Mitigates insider threats and repository compromise risks

* **Accountability**: Creates clear responsibility for changes in team environments
