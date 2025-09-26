# Secure Git

### Task 1 — SSH Commit Signature Verification

#### 1. Commit Signing Benefits

- Verifies commit author identity
- Ensures commits haven't been tampered with
- Prevents authors from denying their commits

#### 2. Configuration

![gitconfig](https://github.com/user-attachments/assets/4d964ced-ccb9-44b0-b216-12cd2e394b03)

**GitHub Setup:** Added SSH public key to GitHub Settings → SSH and GPG keys

![sshkey](https://github.com/user-attachments/assets/a0d753c9-3cdd-4b5c-9629-84e50623d723)

#### 3. Signed commit

![signingcommit](https://github.com/user-attachments/assets/f24bf066-11af-4509-afdb-c2ea0e6ca630)

#### 4. Why is commit signing critical in DevSecOps workflows?

- Provides audit trail for compliance
- Prevents unauthorized code changes
- Builds trust in collaborative environments

### Task 2 — Pre-commit Secret Scanning

#### 1. Pre-commit Hook Setup

Created `.git/hooks/pre-commit`:

- Scans staged files with TruffleHog (non-lectures only)
- Scans all files with Gitleaks
- Blocks commit if secrets detected in non-lectures files

```bash
chmod +x .git/hooks/pre-commit
```

#### 2. Testing Results

**Test 1: Blocked Commit**

![blocked](https://github.com/user-attachments/assets/0d2224bb-3ede-4976-a0d7-6455b2b5633a)

**Test 2: Successful Commit**

![successful](https://github.com/user-attachments/assets/e18f91b4-b745-4f00-9335-ad5e83a729e0)

**3. Security Benefits**

- **Prevention**: Stops secrets before reaching remote repos
- **Cost Saving**: Avoids expensive secret rotation procedures
- **Compliance**: Meets data protection requirements
