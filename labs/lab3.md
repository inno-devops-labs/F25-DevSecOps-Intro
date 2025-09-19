# Lab 3 — Secure Git

![difficulty](https://img.shields.io/badge/difficulty-beginner-success)
![topic](https://img.shields.io/badge/topic-DevOps%20Basics-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Practice secure Git fundamentals: signed commits, pre-commit secret scanning, and standardized PRs.  
> **Deliverable:** A PR from `feature/lab3` with all checklist items completed.

---

## Overview

In this lab you will practice:
- Verifying commit authenticity with **SSH commit signing**.  
- Preventing secrets with **pre-commit scanning** (TruffleHog + Gitleaks).  
- Standardizing collaboration with a **PR template & checklist**.  

These are the foundation of collaboration and trust in DevOps teams.

---

## Tasks

### Task 1 — SSH Commit Signature Verification (5 pts)

**Objective:** Understand the importance of signed commits and set up SSH commit signature verification.

1. **Explore the Importance of Signed Commits**  
   - Research why commit signing is crucial for verifying the integrity and authenticity of commits.  
   - Resources:  
     - [GitHub Docs on SSH Commit Verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)  
     - [Atlassian Guide to SSH and Git](https://confluence.atlassian.com/bitbucketserver/sign-commits-and-tags-with-ssh-keys-1305971205.html)  
   - Create a file `labs/submission3.md` with a short summary explaining the benefits of signing commits.

2. **Set Up SSH Commit Signing**  
   - **Option 1:** Use an existing SSH key and add it to GitHub.  
   - **Option 2 (recommended):** Generate a new key (ed25519)  
     ```sh
     ssh-keygen -t ed25519 -C "your_email@example.com"
     ```  
     Then add the public key to your GitHub account.

   - Configure Git to use your SSH key for signing:  
     ```sh
     git config --global user.signingkey <YOUR_SSH_KEY>
     git config --global commit.gpgSign true
     git config --global gpg.format ssh
     ```

3. **Make a Signed Commit**  
   - Create and sign a commit with your `submission3.md` file:  
     ```sh
     git commit -S -m "docs: add commit signing summary"
     ```  
   - Push this commit to your `feature/lab3` branch.

---
### Task 2 — Pre-commit Hooks (4 pts)

**Objective:** Add a local Git pre-commit hook that scans staged changes for secrets using Dockerized TruffleHog and Gitleaks. The commit must be blocked if any secrets are found.

1. Create the pre-commit hook file
   - Path: `.git/hooks/pre-commit`
   - Contents:
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

2. Make the hook executable
   ```bash
   chmod +x .git/hooks/pre-commit
   ```

3. Verify the hook blocks secrets
   - Add a test secret (e.g., a fake AWS key) to a file, stage it, and try to commit. The commit should be blocked by TruffleHog or Gitleaks.
   - Remove/redact the secret or unstage the file, then commit again to confirm it succeeds.

---
### Task 3 — PR Template & Checklist (1 pt)

**Objective:** Standardize pull requests with a reusable template so reviewers see the same sections and a clear checklist every time.

> ⚠️ **One-time bootstrap:** GitHub loads PR templates from the **default branch of the base repo** (your fork’s `main`). Add the template to `main` first, then open your lab PR from `feature/lab3`.

#### Steps

1. **Create (or source) a template on `main`**  
   Path: `.github/pull_request_template.md`  
   Commit message: `docs: add PR template`  
   - **Option A (discover):** Find a concise PR template from a reputable open-source project or GitHub docs and adapt it.  
   - **Option B (write your own):** Create a minimal template with these sections and a 3-item checklist:
     - Sections: **Goal**, **Changes**, **Testing**  
     - Checklist (3 items): clear title, docs/README updated if needed, no secrets/large temp files  
   - Keep it short and practical (aim for ≤ 30 lines).

2. **Create your lab branch and open a PR**  
   ```bash
   git checkout -b feature/lab3
   # make a change (add labs/submission3.md)
   git add .
   git commit -m "docs: add lab3 submission stub"
   git push -u origin feature/lab3
   ```

Open a PR from `feature/lab3` → `main` **in your fork**.

3. **Verify the template is applied**

   * The PR **description auto-fills** with your sections and the **3-item checklist**.
   * Fill in *Goal / Changes / Testing* and tick the checkboxes.

#### Acceptance Criteria

* ✅ Branch `feature/lab3` exists with changes committed.
* ✅ `labs/submission3.md` is present and at least one commit in the PR shows **“Verified”** (signed via SSH) on GitHub.
* ✅ A local `.git/hooks/pre-commit` runs TruffleHog and Gitleaks via Docker and blocks commits on detected secrets.
* ✅ File `.github/pull_request_template.md` exists on the **main** branch.
* ✅ A PR from `feature/lab3` → `main` is open and **auto-filled** with the template, including **Goal / Changes / Testing** and the **3-item checklist** (boxes ticked).

---

## How to Submit

1. Complete all tasks.
2. Push `feature/lab3` to your fork.
3. Open a PR to your fork’s `main`.
4. In the PR description, include:

   ```text
   - [x] Task 1 done
   - [x] Task 2 done
   - [x] Task 3 done
   - [x] Screenshots attached (if applicable)
   ```

---

## Rubric (10 pts)

| Criterion                                         | Points |
| ------------------------------------------------- | -----: |
| Task 1 — SSH commit signing setup + summary       |  **5** |
| Task 2 — Pre-commit secrets scanning in effect    |  **4** |
| Task 3 — PR template & checklist applied          |  **1** |
| **Total**                                         | **10** |

---

## Hints

> 🔐 **Signed commit not showing “Verified”?** Ensure the email on your commits matches your GitHub account and that `gpg.format` is set to `ssh`.\
> 🔎 **Docker required for scans:** The pre-commit hook uses Docker images for TruffleHog and Gitleaks; ensure Docker Desktop/Engine is running.\
> 📝 **Template didn’t load?** Confirm the path is `.github\pull_request_template.md` **on `main`** before opening the PR; re-open the PR description after adding it.\
> ✂️ **Keep it short:** Reviewers read many PRs—concise templates get filled, long ones get ignored.
