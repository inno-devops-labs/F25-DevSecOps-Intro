# Lab 1 — Setup OWASP Juice Shop & PR Workflow

![difficulty](https://img.shields.io/badge/difficulty-beginner-success)
![topic](https://img.shields.io/badge/topic-AppSec%20Basics-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Run an OWASP Juice Shop locally, complete a triage report, and standardize PR submissions.
> **Deliverable:** A PR from `feature/lab1` containing `labs/submission1.md`, issues created, and the PR template in place.

---

## Overview

In this lab you will practice:

* Launching a **Juice Shop App**.
* Capturing a **triage report** — version, URL, health check, exposure, risks, and next actions.
* Bootstrapping a **repeatable PR workflow** with a template.

> We **do not** copy Juice Shop code into the repo. You’ll run the official Docker image and keep **only lab artifacts** in your fork. Run instructions come from Juice Shop’s docs; we’ll pin a known release tag. ([pwning.owasp-juice.shop][1], [GitHub][2], [Docker Hub][3])

---

## Tasks

### Task 1 — Triage (Juice Shop) (6 pts)

**Objective:** Run a Juice Shop locally and complete a Triage report to capture the deployment, quick health, exposure, and top risks.

1. **Create the submission file**

   * Create `labs/submission1.md` with these fields:

     * `image: bkimminich/juice-shop:19.0.0`
     * release date (from GitHub Releases) and a link to the release notes.

2. **Run the container (detached)**

   ```bash
   docker run -d --name juice-shop \
     -p 127.0.0.1:3000:3000 \
     bkimminich/juice-shop:19.0.0
   ```

   * Browse to `http://localhost:3000` and confirm the app loads.

3. **Quick health check**

   * Verify the API responds:

     ```bash
     curl -s http://127.0.0.1:3000/rest/products | head
     ```
   * Take a screenshot of the home page or paste the first 5–10 JSON lines from the API.

4. **Fill the Triage report**

   * In `labs/submission1.md`, copy/paste this template and fill it out:

   ```markdown
   # Triage Report — OWASP Juice Shop

   ## Scope & Asset
   - Asset: OWASP Juice Shop (local lab instance)
   - Image: bkimminich/juice-shop:19.0.0
   - Release link/date: <link> — <date>
   - Image digest (optional): <sha256:...>

   ## Environment
   - Host OS: <e.g., macOS 14.5 / Ubuntu 22.04>
   - Docker: <e.g., 24.0.x>

   ## Deployment Details
   - Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:19.0.0`
   - Access URL: http://127.0.0.1:3000
   - Network exposure: 127.0.0.1 only [ ] Yes  [ ] No  (explain if No)

   ## Health Check
   - Page load: attach screenshot of home page (path or embed)
   - API check: first 5–10 lines from `curl -s http://127.0.0.1:3000/rest/products | head`

   ## Surface Snapshot (Triage)
   - Login/Registration visible: [ ] Yes  [ ] No — notes: <...>
   - Product listing/search present: [ ] Yes  [ ] No — notes: <...>
   - Admin or account area discoverable: [ ] Yes  [ ] No — notes: <...>
   - Client-side errors in console: [ ] Yes  [ ] No — notes: <...>
   - Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present? notes: <...>

   ## Risks Observed (Top 3)
   1) <risk + 1‑line rationale>
   2) <risk + 1‑line rationale>
   3) <risk + 1‑line rationale>

   ```

> Resources: Juice Shop Docker image on Docker Hub; official run docs. ([Docker Hub][3], [pwning.owasp-juice.shop][1])

---

### Task 2 — PR Template (4 pts)

**Objective:** Standardize submissions so every lab PR has the same sections and checks.

> ⚠️ **One-time bootstrap:** GitHub loads PR templates from the **default branch of your fork (`main`)**. Add the template to `main` first, then open your lab PR from `feature/lab1`.

#### Steps

1. **Create the PR template on `main`**
   Path: `.github/pull_request_template.md`
   Commit message: `docs: add PR template`
   Include exactly these sections and checklist:

   * Sections: **Goal**, **Changes**, **Testing**, **Artifacts & Screenshots**
   * Checklist (3 items): clear title, docs updated if needed, no secrets/large temp files

2. **Create your lab branch, add your submission file, open PR**

   ```bash
   git checkout -b feature/lab1
   # add labs/submission1.md
   git add labs/submission1.md
   git commit -m "docs(lab1): add submission1 triage report"
   git push -u origin feature/lab1
   ```

   * Open a PR from `feature/lab1` → `main` **in your fork**.

3. **Verify the template is applied**

   * The PR description should auto-fill with your sections & checklist.
   * Fill in **Goal / Changes / Testing / Artifacts & Screenshots** and tick the checkboxes.
   * Ensure your screenshots and API snippet are embedded or referenced in `labs/submission1.md`.

### Acceptance Criteria

* ✅ `labs/submission1.md` exists and includes: image `bkimminich/juice-shop:19.0.0` with release link/date; environment; deployment details; access URL; working health check evidence (screenshot or API snippet); surface snapshot; top 3 risks.
* ✅ 3–5 **Issues** exist in the repo labeled `backlog` (derived from your triage next actions) and linked from `labs/submission1.md`.
* ✅ `.github/pull_request_template.md` exists on **`main`**.
* ✅ A PR from `feature/lab1` → `main` is open and **auto-filled** with the template, including **Goal / Changes / Testing / Artifacts & Screenshots** (boxes ticked).
* ✅ **No Juice Shop source code** is copied into the repo—only lab artifacts.

---

## How to Submit

1. Complete all tasks.
2. Push `feature/lab1` to your fork.
3. Open a PR from `feature/lab1` → `main` in **your fork**.
4. In the PR description, include:

   ```text
   - [x] Task 1 done
   - [x] Task 2 done
   - [x] Screenshots attached
   ```

---

## Rubric (10 pts)

| Criterion                                                 | Points |
| --------------------------------------------------------- | -----: |
| Task 1 — Triage in `labs/submission1.md` + image running |  **6** |
| Task 2 — PR template in effect + PR opened                |  **4** |
| **Total**                                                 | **10** |

---

## Hints

> 📌 **Why pin the version?** Juice Shop changes challenges between releases; pinning (e.g., `:19.0.0`) keeps labs reproducible for everyone. Check the **GitHub Releases** page for the date and notes. ([GitHub][2])\
> 🧪 **Health check tip:** The official guide uses `-p 127.0.0.1:3000:3000`; always include `127.0.0.1` to avoid exposing the app beyond localhost by accident. ([pwning.owasp-juice.shop][1])\
> 🚫 **Don’t add app code:** All labs use the official Docker image from Docker Hub—your repo holds configs, reports, and CI only. ([Docker Hub][3])

---

[1]: https://pwning.owasp-juice.shop/companion-guide/latest/part1/running.html?utm_source=chatgpt.com "Running OWASP Juice Shop"
[2]: https://github.com/juice-shop/juice-shop/releases/?utm_source=chatgpt.com "Releases · juice-shop/juice-shop - GitHub"
[3]: https://hub.docker.com/r/bkimminich/juice-shop/?utm_source=chatgpt.com "bkimminich/juice-shop - Docker Image | Docker Hub"
