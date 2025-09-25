# Lab 3 — Secure Git

![difficulty](https://img.shields.io/badge/difficulty-beginner-success)
![topic](https://img.shields.io/badge/topic-Secure%20Git-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Practice secure Git fundamentals: signed commits, pre-commit secret scanning, and standardized PRs.  
> **Deliverable:** A PR from `feature/lab3` to the course repo with `labs/submission3.md` containing secure Git practices implementation. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Verifying commit authenticity with **SSH commit signing**.
- Preventing secrets exposure with **pre-commit scanning** (TruffleHog + Gitleaks).
- Standardizing collaboration with **PR templates & checklists**.

These skills are fundamental for maintaining secure development workflows and preventing security incidents in collaborative environments.

---

## Tasks

### Task 1 — SSH Commit Signature Verification (5 pts)

**Objective:** Understand the importance of signed commits and set up SSH commit signature verification.

#### 1.1: Research Commit Signing Benefits

1. **Study Commit Signing Importance:**

   Research why commit signing is crucial for verifying the integrity and authenticity of commits using these resources:
   - [GitHub Docs on SSH Commit Verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)
   - [Atlassian Guide to SSH and Git](https://confluence.atlassian.com/bitbucketserver/sign-commits-and-tags-with-ssh-keys-1305971205.html)

#### 1.2: Configure SSH Commit Signing

1. **Generate SSH Key (Option A - Recommended):**

   ```sh
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **Use Existing SSH Key (Option B):**

   - Use an existing SSH key and add it to GitHub

3. **Configure Git for SSH Signing:**

   ```sh
   git config --global user.signingkey <YOUR_SSH_KEY>
   git config --global commit.gpgSign true
   git config --global gpg.format ssh
   ```

#### 1.3: Create Signed Commit

1. **Make a Signed Commit:**

   ```sh
   git commit -S -m "docs: add commit signing summary"
   ```

In `labs/submission3.md`, document:
- Summary explaining the benefits of signing commits for security
- Evidence of successful SSH key setup and configuration
- Analysis: "Why is commit signing critical in DevSecOps workflows?"
- Screenshots or verification of the "Verified" badge on GitHub

---

### Task 2 — Pre-commit Secret Scanning (4 pts)

**Objective:** Add a local Git pre-commit hook that scans staged changes for secrets using Dockerized TruffleHog and Gitleaks.

#### 2.1: Create Pre-commit Hook

1. **Setup Pre-commit Hook File:**

   Create `.git/hooks/pre-commit` with the following content:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   echo "[pre-commit] scanning staged files for secrets…"

   # Collect staged files (added/changed)
   mapfile -t STAGED < <(git diff --cached --name-only --diff-filter=ACM)
   if [ ${#STAGED[@]} -eq 0 ]; then
       echo "[pre-commit] no staged files; skipping scans"
       exit 0
   fi

   # Limit to existing regular files only
   FILES=()
   for f in "${STAGED[@]}"; do
       [ -f "$f" ] && FILES+=("$f")
   done
   if [ ${#FILES[@]} -eq 0 ]; then
       echo "[pre-commit] no regular files to scan; skipping"
       exit 0
   fi

   # Run TruffleHog in verbose mode
   echo "[pre-commit] TruffleHog scan…"
   if ! docker run --rm -v "$(pwd):/repo" -w /repo \
       trufflesecurity/trufflehog:latest \
       filesystem --fail --only-verified "${FILES[@]}" 
   then
       echo -e "\n✖ TruffleHog detected potential secrets. See output above for details." >&2
       echo "Fix or unstage the offending files and try again." >&2
       exit 1
   fi

   # Run Gitleaks and capture its output
   echo "[pre-commit] Gitleaks scan…"
   GITLEAKS_OUTPUT=$(docker run --rm -v "$(pwd):/repo" -w /repo \
       zricethezav/gitleaks:latest \
       detect --source="/repo" --verbose --exit-code=0 --no-banner || true)

   # Display the output
   echo "$GITLEAKS_OUTPUT"

   # Check if any non-lectures files have leaks
   if echo "$GITLEAKS_OUTPUT" | grep -q "File:" && ! echo "$GITLEAKS_OUTPUT" | grep -q "File:.*lectures/"; then
       echo -e "\n✖ Gitleaks detected potential secrets in non-excluded files." >&2
       echo "Fix or unstage the offending files and try again." >&2
       exit 1
   elif echo "$GITLEAKS_OUTPUT" | grep -q "File:.*lectures/"; then
       echo -e "\n⚠️ Gitleaks found potential secrets only in excluded directories (lectures/)." >&2
       echo "These findings are ignored based on your configuration." >&2
   fi

   echo "✓ No secrets detected; proceeding with commit."
   exit 0
   ```

2. **Make Hook Executable:**

   ```bash
   chmod +x .git/hooks/pre-commit
   ```

#### 2.2: Test Secret Detection

1. **Verify Hook Functionality:**

   - Add a test secret (e.g., fake AWS key) to a file and stage it
   - Attempt to commit - should be blocked by TruffleHog or Gitleaks
   - Remove/redact the secret, then commit again to confirm success

In `labs/submission3.md`, document:
- Pre-commit hook setup process and configuration
- Evidence of successful secret detection blocking commits
- Test results showing both blocked and successful commits
- Analysis of how automated secret scanning prevents security incidents

---

### Task 3 — PR Template & Checklist (1 pt)

**Objective:** Standardize pull requests with a reusable template for consistent collaboration workflows.

#### 3.1: Create PR Template

1. **Template Setup:**

   ```bash
   # Path: .github/pull_request_template.md
   # Commit message: docs: add PR template
   ```

2. **Template Options:**

   - **Option A (discover):** Find a concise PR template from a reputable open-source project and adapt it
   - **Option B (write your own):** Create template with these sections and 3-item checklist:
     - Sections: **Goal**, **Changes**, **Testing**
     - Checklist: clear title, docs updated if needed, no secrets/large temp files
   - Keep it short and practical (≤ 30 lines)

#### 3.2: Verify Template Application

1. **Create Lab Branch and PR:**

   ```bash
   git checkout -b feature/lab3
   git add labs/submission3.md
   git commit -m "docs: add lab3 submission stub"
   git push -u origin feature/lab3
   ```

2. **Template Verification:**

   - Open PR and verify description auto-fills with sections & checklist
   - Fill in *Goal / Changes / Testing* and tick checkboxes

In `labs/submission3.md`, document:
- PR template creation and setup process
- Evidence of template auto-filling functionality
- Analysis of how standardized templates improve code review workflows

> ⚠️ **One-time bootstrap:** GitHub loads PR templates from the **default branch of your fork (`main`)**. Add the template to `main` first, then open your lab PR from `feature/lab3`.

---

## Acceptance Criteria

- ✅ Branch `feature/lab3` exists with commits for each task.
- ✅ File `labs/submission3.md` contains required analysis for Tasks 1-3.
- ✅ At least one commit shows **"Verified"** (signed via SSH) on GitHub.
- ✅ Local `.git/hooks/pre-commit` runs TruffleHog and Gitleaks via Docker and blocks secrets.
- ✅ File `.github/pull_request_template.md` exists on the **main** branch.
- ✅ PR from `feature/lab3` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.

---

## How to Submit

1. Create a branch for this lab and push it to your fork:

   ```bash
   git switch -c feature/lab3
   # create labs/submission3.md with your findings
   git add labs/submission3.md
   git commit -m "docs: add lab3 submission"
   git push -u origin feature/lab3
   ```

2. Open a PR from your fork's `feature/lab3` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 done
   - [x] Task 2 done
   - [x] Task 3 done
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Rubric (10 pts)

| Criterion                                        | Points |
| ------------------------------------------------ | -----: |
| Task 1 — SSH commit signing setup + analysis    |  **5** |
| Task 2 — Pre-commit secrets scanning setup      |  **4** |
| Task 3 — PR template & checklist implementation |  **1** |
| **Total**                                        | **10** |

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission3.md`.
- Include both command outputs and written analysis for each task.
- Document security configurations and testing procedures thoroughly.
- Demonstrate both successful and blocked operations for secret scanning.

> **Security Configuration Notes**  
> 1. Ensure the email on your commits matches your GitHub account for proper verification.  
> 2. Verify `gpg.format` is set to `ssh` for proper signing configuration.  
> 3. Test pre-commit hooks thoroughly with both legitimate and test secret content.

> **Technical Requirements**  
> 1. Docker Desktop/Engine must be running for secret scanning tools.  
> 2. Confirm PR template path is `.github/pull_request_template.md` **on `main`**.  
> 3. Re-open PR description after adding template if it didn't auto-fill.  
> 4. Keep templates concise—reviewers prefer short, actionable checklists.