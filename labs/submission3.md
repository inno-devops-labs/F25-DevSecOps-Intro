# Submission 3 — Secure Git (Signed Commits + Secret Scanning)

---
Alexander Rozanov / CBS-02 / al.rozanov@innopolis.university
---

## 1) Repository & Environment (concise)
- Fork: `https://github.com/Rozanalex/F25-DevSecOps-Intro`
- Branch: `feature/lab3`
- Host OS: Arch - 257.4-1-arch

> SSH key used for signing: **~/.ssh/lab3** (public: **~/.ssh/lab3.pub**). The private key stays local and is **never** committed.

---

## 2) What I Did — Step by Step (only what the lab requires)

### 2.1 Enable SSH‑signed commits (using key `lab3`)
```bash
git config user.name "Alexander Rozanov"
git config user.email "al.rozanov@innopolis.university"
git config gpg.format ssh
git config user.signingkey ~/.ssh/lab3.pub
git config commit.gpgSign true
```
Add `~/.ssh/lab3.pub` on GitHub → **Settings → SSH and GPG keys → New SSH key → Type: Signing Key**.

Create a signed commit and verify:
```bash
echo "Lab3 Secure Git" > labs/lab3/README.md
git add labs/lab3/README.md
git commit -S -m "lab3: init (SSH‑signed commit)"
git log --show-signature -1   # expect: Good "git signed ssh signature"
```

### 2.2 Pre‑commit secret scanning (Gitleaks + TruffleHog)
Create `.pre-commit-config.yaml` in repo root:
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-merge-conflict
      - id: end-of-file-fixer
      - id: trailing-whitespace

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.4
    hooks:
      - id: gitleaks
        args: ["protect", "--staged", "--verbose"]

  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.78.0
    hooks:
      - id: trufflehog
        args: ["filesystem", "--fail", "--no-update", "--since-commit", "HEAD~1", "."]
```
Enable hooks:
```bash
pre-commit install
```

### 2.3 Simulate a leak → blocked commit → fix → green commit
```bash
mkdir -p labs/lab3/demo
cat > labs/lab3/demo/leaky.txt <<'EOF'
# demo only — fake secret
API_KEY=AKIAIOSFODNN7EXAMPLE
GH_PAT=ghp_0123456789abcdefghijklmnopqrstuvwxyzAB
EOF

git add labs/lab3/demo/leaky.txt
git commit -S -m "lab3: demo(secret): add fake keys"   # expected: blocked by pre-commit
```
Fix and commit:
```bash
git restore --staged labs/lab3/demo/leaky.txt
sed -i 's/EXAMPLE/REDACTED/g' labs/lab3/demo/leaky.txt
sed -i 's/ghp_[0-9a-zA-Z]*/REDACTED/g' labs/lab3/demo/leaky.txt
git add labs/lab3/demo/leaky.txt
git commit -S -m "lab3: fix: remove fake secrets (pre-commit passes)"
```

### 2.4 CI: GitHub Actions (Gitleaks on push/PR)
`.github/workflows/secret-scan.yml`:
```yaml
name: secret-scan
on:
  pull_request:
  push:
    branches: ["feature/lab3", "main"]
jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Install gitleaks
        run: |
          curl -sSL https://raw.githubusercontent.com/gitleaks/gitleaks/main/install.sh | bash
          sudo mv gitleaks /usr/local/bin/
      - name: Run gitleaks
        run: gitleaks detect --source . --no-git --verbose --redact
```

---

## 3) Evidence
- **Signature check:** output of `git log --show-signature -1` with `Good "git signed ssh signature"`.
- **Blocked commit:** pre‑commit log showing Gitleaks/TruffleHog findings.
- **Passed commit:** pre‑commit log where all hooks are `Passed`.
- (Optional) Badge in README:
  `![secret-scan](https://github.com/<owner>/<repo>/actions/workflows/secret-scan.yml/badge.svg)`

---

## 4) Notes (personal & concise)
- Signing key: `~/.ssh/lab3` (private) and `~/.ssh/lab3.pub` (public). **Private key is local only** and added to `~/.gitignore` if it ever appears in the repo path.
- If the key was ever committed, rotate it and purge from history; otherwise continue with the new signed commits.

---

## 5) Conclusion
I enabled SSH‑signed commits with my `lab3` key, enforced local secret scanning via pre‑commit (Gitleaks + TruffleHog), demonstrated a blocked commit on a fake leak and a successful commit after remediation, and added CI secret scanning for pushes and PRs.
