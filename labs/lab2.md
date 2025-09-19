# Lab 2 — Threat Modeling with Threagile

![difficulty](https://img.shields.io/badge/difficulty-beginner–intermediate-yellow)
![topic](https://img.shields.io/badge/topic-Threat%20Modeling%20(Threagile)-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Model the **OWASP Juice Shop `bkimminich/juice-shop:19.0.0`** deployment and generate an **automation-first** threat model with Threagile.  
> **Deliverable:** A PR from `feature/lab2` with Threagile outputs and a short risk summary.

---

## Overview

In this lab you will practice:

* Creating an **as-code** model with **Threagile** and automatically generating a **risk report + diagrams** from YAML (great for CI).
* Making a small, security-relevant model change and demonstrating how it **changes the risk set**.

> Keep using the Juice Shop from Lab 1 (`:19.0.0`).

---

## Tasks

### Task 1 — Threagile model & automated report (6 pts)

**Objective:** Use the provided Threagile model to generate a PDF report + diagrams and document the results in `labs/submission2.md`.

1) **Use the provided YAML**

- `labs/lab2/threagile-model.yaml` is provided. Do not restructure it for this task.

2) **Generate outputs (risks + diagrams + PDF)**

Create output folders and run Threagile:

```bash
mkdir -p labs/lab2/baseline labs/lab2/secure
docker run --rm -v "$(pwd)":/app/work threagile/threagile \
  -model /app/work/labs/lab2/threagile-model.yaml \
  -output /app/work/labs/lab2/baseline \
  -generate-risks-excel=false -generate-tags-excel=false
```

What you get in `labs/lab2/baseline/`:

* `report.pdf` — full PDF report (includes diagrams)
* Diagrams: data-flow & data-asset diagrams (PNG)
* Risk exports: `risks.json`, plus `stats.json`, `technical-assets.json`

3. **Create `labs/submission2.md`**

Include:

* **Top 5 Risks** (from `labs/lab2/baseline/risks.json`): table with — Severity, Category, Asset, Likelihood, Impact.

  * Ranking: Sort by these weights:

    * Severity: critical (5) > elevated (4) > high (3) > medium (2) > low (1)
    * Likelihood: very-likely (4) > likely (3) > possible (2) > unlikely (1)
    * Impact: high (3) > medium (2) > low (1)
    * **Composite score** = `Severity*100 + Likelihood*10 + Impact` (sort desc; use to break ties)

> Practical: open `labs/lab2/baseline/risks.json`, scan fields `severity`, `exploitation_likelihood`, `exploitation_impact`, `category`, `most_relevant_technical_asset`, and pick the Top 5 using the weights.

---

### Task 2 — HTTPS Variant & Risk Diff (4 pts)

**Objective:** Create a secure variant of the model and show how risk categories change.

* Secure communications
* Unencrypted asset

1. **Create a secure variant YAML**

Copy the baseline model and make exactly these edits:

* **User Browser → communication_links → Direct to App (no proxy)**: set `protocol: https`
* **Reverse Proxy → communication_links**: set `protocol: https`
* **Persistent Storage**: set `encryption: transparent` (to represent disk-level encryption)

Save as: `labs/lab2/threagile-model.secure.yaml`.

2. **Run Threagile: secure variant**

```bash
docker run --rm -v "$(pwd)":/app/work threagile/threagile \
  -model /app/work/labs/lab2/threagile-model.secure.yaml \
  -output /app/work/labs/lab2/secure \
  -generate-risks-excel=false -generate-tags-excel=false
```

3. **Produce a Markdown delta table (Category: Baseline vs Secure vs Δ)**

Paste this **jq** command (works on jq 1.6+), then copy the output table into `labs/submission2.md`:

```bash
jq -n \
  --slurpfile b labs/lab2/baseline/risks.json \
  --slurpfile s labs/lab2/secure/risks.json '
  def tally(x):
    (x | group_by(.category) | map({ (.[0].category): length }) | add) // {};
  (tally($b[0])) as $B |
  (tally($s[0])) as $S |
  (($B + $S) | keys | sort) as $cats |
  [
    "| Category | Baseline | Secure | Δ |",
    "|---|---:|---:|---:|"
  ] + (
    $cats | map(
      "| " + . + " | " +
      (($B[.] // 0) | tostring) + " | " +
      (($S[.] // 0) | tostring) + " | " +
      (((($S[.] // 0) - ($B[.] // 0))) | tostring) + " |"
    )
  ) | .[]'
```

4. **Write a 2–4 line “Delta Run” explanation**

* Change made:
* Result (example):
* Why:

---

## Deliverables

Commit/push:

* `labs/lab2/threagile-model.yaml` (baseline)
* `labs/lab2/threagile-model.secure.yaml` (your secure variant)
* `labs/lab2/baseline/*diagram*.png` (at least the data-flow diagram)
* `labs/lab2/secure/*diagram*.png` (at least the data-flow diagram)
* `labs/submission2.md` (Top 5 table + Delta table + short explanations)

---

## Quality checklist (pass/fail hints)

* Report opens and diagrams render in both **baseline** and **secure** runs.
* Top 5 risks table present and legible; ties broken sensibly.
* Category **Markdown delta table** included (baseline/secure/Δ).
* Delta explanation is short and accurate (only the two intended changes).
* Folder structure present: `labs/lab2/baseline/` and `labs/lab2/secure/`.

> Resources: Threagile site (auto risk rules, diagrams, CI-friendly), CLI usage (Docker examples), sample outputs. ([threagile.io][3], [GitHub][6], [juanvvc.github.io][4])

---

## How to Submit

1. Create `feature/lab2`, commit the new files, push, and open a PR.
2. In the PR description, fill your template sections and include:

```text
- [x] Task 1: Threagile baseline model + report + diagrams + submission2.md (Top 5)
- [x] Task 2: HTTPS Variant + secure run + Category delta table + delta explanation
```

---

## Rubric (10 pts)

| Criterion                                                                 | Points |
| ------------------------------------------------------------------------- | -----: |
| **Task 1** — Threagile baseline: report/diagrams + Top 5 risks table      |  **6** |
| **Task 2** — HTTPS Variant & Risk Diff: secure run + Markdown delta table |  **4** |
| **Total**                                                                 | **10** |

---

## Hints

> 🧭 **Model the lab reality.** Use exactly the architecture you’re running from Lab 1 (localhost, optional proxy).
>
> ⚙️ **Threagile flags:** You can generate a stub (`-create-stub-model`), list enums (`-list-types`), and run analysis with `-model ... -output ...`; it emits report/DFDs and risk exports—handy for CI. ([Go Packages][1], [Kali Linux Tutorials][2])
>
> 📑 **Keep it short:** One-page summaries beat walls of text—use bullets and paste the tables.
>
> 🔁 **Consistent IDs:** Use the same asset/link names between baseline and secure models so your diffs line up.

---

[1]: https://pkg.go.dev/github.com/threagile/threagile?utm_source=chatgpt.com "threagile command - github.com/threagile/threagile - Go Packages"
[2]: https://kalilinuxtutorials.com/threagile/?utm_source=chatgpt.com "Threagile : Agile Threat Modeling Toolkit 2020!Kalilinuxtutorials"
[3]: https://threagile.io/?utm_source=chatgpt.com "Threagile — Agile Threat Modeling Toolkit"
[4]: https://juanvvc.github.io/securecoding/images/threatmod/threagile/report.pdf?utm_source=chatgpt.com "Threat Model Report: Some Example Application"
[6]: https://github.com/Threagile/threagile "GitHub - Threagile/threagile: Agile Threat Modeling Toolkit"
