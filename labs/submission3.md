# Task 1

## Summary: benefits of signing commits

* **Authenticity of authorship:** These tags or commits are marked as verified on GitHub so other people can be confident that the changes come from a trusted source.
* **Integrity of code:** Any tampering after signing is detectable; altered commits fail verification.
* **Accountability & non-repudiation:** Authors can’t plausibly deny changes if the key is controlled and policies are enforced.
* **Provenance for CI/CD:** Build systems can trust only signed inputs, shrinking the attack surface for supply-chain attacks.
* **Policy enforcement:** Branch protections and server hooks can reject unsigned or unverified commits/merges.
* **Compliance support:** Helps meet SSDF/SLSA-style controls around source integrity and traceability.

## Evidence of successful SSH key setup & configuration

```
git config --global --get gpg.format          # -> ssh
git config --global --get user.signingkey     # -> ~/.ssh/id_ed25519.pub
git config --global --get commit.gpgsign      # -> true
```

## Analysis: Why commit signing is critical in DevSecOps workflows

1) It defends your first trust boundary.
DevSecOps automates everything—scanners, tests, builds, deploys. That means the source commit is the earliest control point. If you don’t verify commit provenance, a stolen credential or malicious actor can smuggle code that every automated step will happily build and ship.

2) Tamper-evidence from developer laptop -> production.
Signatures travel with commits. If a repo, cache, or artifact store is compromised, signature checks will fail, stopping the pipeline before bad code becomes a bad release.

3) Enforceable, machine-checkable policy.
You can make “only signed commits/merges allowed” a hard gate: branch protections, pre-receive hooks, and CI jobs (git verify-commit) can block unsigned or untrusted keys. This converts a human process into a technical control.

4) Supports compliance & forensics.
Signed history provides non-repudiation and traceability for audits (SSDF, SLSA, ISO 27001). Post-incident, you can rapidly scope which commits are trustworthy.

5) Fits modern, cloud-native supply chains.
Combine signed commits with signed tags/releases and artifact signing (e.g., container images). Your pipeline asserts integrity end-to-end, from Git to registry to runtime admission.

## Screenshots or verification of the "Verified" badge on GitHub
![alt text](IMG_3066.jpeg)

# Task 2 

## Pre-commit hook setup process and configuration
1. **Create `.git/hooks/pre-commit` with the following content:**

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
## Evidence of ~~successful~~ fail secret detection blocking commits

```
philarmonia@MacBook-Air-Aleksei F25-DevSecOps-Intro % cat demo.txt 
API_KEY = "verysecretapikey007"
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY%                                                                                                          
philarmonia@MacBook-Air-Aleksei F25-DevSecOps-Intro % git commit -S -m "test: add fake secret"
[pre-commit] scanning staged files for secrets…
[pre-commit] TruffleHog scan…
🐷🔑🐷  TruffleHog. Unearth your secrets. 🐷🔑🐷

2025-09-24T14:09:29Z    info-0  trufflehog      running source  {"source_manager_worker_id": "FCQOY", "with_units": true}
2025-09-24T14:09:30Z    info-0  trufflehog      finished scanning       {"chunks": 1, "bytes": 133, "verified_secrets": 0, "unverified_secrets": 0, "scan_duration": "757.139459ms", "trufflehog_version": "3.90.8", "verification_caching": {"Hits":0,"Misses":1,"HitsWasted":0,"AttemptsSaved":0,"VerificationTimeSpentMS":754}}
[pre-commit] Gitleaks scan…
2:09PM INF 14 commits scanned.
2:09PM INF scanned ~368868 bytes (368.87 KB) in 220ms
2:09PM WRN leaks found: 1
Finding:     API_KEY = "mysecretapikey123"  # anyone with sour...
Secret:      mysecretapikey123
RuleID:      generic-api-key
Entropy:     3.690116
File:        lectures/lec1.md
Line:        837
Commit:      2f235527f079d948d38f9d9e9cd04304c384231d
Author:      Dmitrii Creed
Email:       creeed22@gmail.com
Date:        2025-08-31T20:12:05Z
Fingerprint: 2f235527f079d948d38f9d9e9cd04304c384231d:lectures/lec1.md:generic-api-key:837
Link:        https://github.com/ph1larmon1a/F25-DevSecOps-Intro/blob/2f235527f079d948d38f9d9e9cd04304c384231d/lectures/lec1.md?plain=1#L837

⚠️ Gitleaks found potential secrets only in excluded directories (lectures/).
These findings are ignored based on your configuration.
✓ No secrets detected; proceeding with commit.
[feature/lab3 bf95bc7] test: add fake secret
 1 file changed, 3 insertions(+)
 create mode 100644 demo.txt
 ```

## Analysis: How Automated Secret Scanning Prevents Incidents
* **Stops exfiltration at the earliest point:** Secrets are blocked before they enter Git history (which is durable and replicated). This prevents exposure via forks, clones, CI logs, and cached artifacts.

* **Shrinks blast radius:** Even if a developer copies credentials by mistake, the hook prevents propagation to remote repos and CI/CD systems where they could be harvested.

* **Complements server-side & CI controls:** Local pre-commit scanning catches issues offline, while server-side/CI policy (e.g., push/merge checks) gives defense-in-depth.

* **Verified detection reduces noise:** TruffleHog’s --only-verified mode focuses on high-confidence findings, maintaining developer trust in the control.

* **Configurable exceptions:** Allow-listing folders like lectures/ prevents false alarms on known benign content (e.g., sample data), keeping the signal strong.

# Task 3

## Setup
- **Path:** `.github/pull_request_template.md`
- **Commit message:** `docs: add PR template`
- Added on **main** so GitHub auto-fills PR descriptions.

**Template (≤30 lines):**
```markdown
## Goal
<!-- What problem does this PR solve? Link issues/tickets if any. -->

## Changes
<!-- Short, scannable list of key changes. -->

## Testing
<!-- How did you test? Include commands, screenshots, or logs. -->

### Checklist
- [ ] PR has a clear and descriptive title
- [ ] Documentation updated if needed
- [ ] No secrets or large temporary files committed