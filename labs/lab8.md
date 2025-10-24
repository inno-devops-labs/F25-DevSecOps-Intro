# Lab 8 — Software Supply Chain Security: Signing, Verification, and Attestations

![difficulty](https://img.shields.io/badge/difficulty-intermediate-orange)
![topic](https://img.shields.io/badge/topic-Supply%20Chain%20Security-blue)
![points](https://img.shields.io/badge/points-10-orange)

> Goal: Sign and verify container images, attach and verify attestations (SBOM/provenance), and optionally sign non-container artifacts — all locally, without code changes.
> Deliverable: A PR from `feature/lab8` with `labs/submission8.md` containing signing/verification logs, attestation evidence, and a short analysis. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Image signing/verification with Cosign against a local registry
- Attestations (SBOM and provenance) and payload inspection
- Optional artifact (blob) signing for non-container assets

Context: Cosign is a widely used OSS tool for image signing and attestations. If you produced SBOMs in Lab 4, reuse them here for attestations.

> Target application: `bkimminich/juice-shop:v19.0.0`

---

## Prerequisites

- Docker (Docker Desktop or Engine) and internet access
- `jq` for JSON processing
- Cosign installed (binary)
  - See: https://docs.sigstore.dev/cosign/system_config/installation/
  - Verify: `cosign version`

Install Cosign (quick start):

```bash
# Linux x86_64 (install to /usr/local/bin)
curl -sSL -o cosign "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
chmod +x cosign && sudo mv cosign /usr/local/bin/

# Verify
cosign version
```

Docs:
- Install guide: https://docs.sigstore.dev/cosign/system_config/installation/
- Releases: https://github.com/sigstore/cosign/releases/latest

Prepare working directories:
```bash
mkdir -p labs/lab8/{registry,signing,attest,analysis,artifacts}
```

---

## Tasks

### Task 1 — Local Registry, Signing & Verification (4 pts)
**Objective:** Push the image to a local registry, sign it with Cosign, and verify the signature, including a tamper demonstration.

#### 1.1: Pull and push to local registry
```bash
# Pull target image
docker pull bkimminich/juice-shop:v19.0.0

# Start local registry on localhost:5000 (Distribution v3)
docker run -d --restart=always -p 5000:5000 --name registry registry:3

# Tag and push the image to the local registry
docker tag bkimminich/juice-shop:v19.0.0 localhost:5000/juice-shop:v19.0.0
docker push localhost:5000/juice-shop:v19.0.0

# Recommended: use a digest reference (from the local registry) instead of a tag
DIGEST=$(curl -sI \
  -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
  http://localhost:5000/v2/juice-shop/manifests/v19.0.0 \
  | tr -d '\r' | awk -F': ' '/Docker-Content-Digest/ {print $2}')
REF="localhost:5000/juice-shop@${DIGEST}"
echo "Using digest ref: $REF" | tee labs/lab8/analysis/ref.txt
```

#### 1.2: Generate a Cosign key pair for signing
```bash
cd labs/lab8/signing
cosign generate-key-pair
cd -
# This creates cosign.key (private key) and cosign.pub (public key)
# You will be prompted to set a passphrase for the private key
```

#### 1.3: Sign and verify the image
```bash
# Sign the image using your private key
cosign sign --yes \
  --allow-insecure-registry \
  --tlog-upload=false \
  --key labs/lab8/signing/cosign.key \
  "$REF"

# Verify the signature using your public key and save the output
cosign verify \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  "$REF"
```

> Note for students:
> - This verify flow is valid for a local, insecure registry. You correctly use a digest reference and `--allow-insecure-registry`.
> - The warning appears because you signed with `--tlog-upload=false`. Using `--insecure-ignore-tlog` tells Cosign to skip Rekor transparency log verification in this lab context.
> - For production: remove `--insecure-ignore-tlog`, sign without `--tlog-upload=false` (so the signature is recorded in Rekor), avoid insecure registries, and always verify/sign by digest (not by tag).

#### 1.4: Tamper demonstration
```bash
docker pull busybox:latest
docker tag busybox:latest localhost:5000/juice-shop:v19.0.0
docker push localhost:5000/juice-shop:v19.0.0

# IMPORTANT: Re-resolve the tag to the NEW digest from the local registry
DIGEST_AFTER=$(curl -sI \
  -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
  http://localhost:5000/v2/juice-shop/manifests/v19.0.0 \
  | tr -d '\r' | awk -F': ' '/Docker-Content-Digest/ {print $2}')
REF_AFTER="localhost:5000/juice-shop@${DIGEST_AFTER}"
echo "After tamper digest ref: $REF_AFTER" | tee labs/lab8/analysis/ref-after-tamper.txt

# Verify should now FAIL for the new digest (not signed with your key)
cosign verify \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  "$REF_AFTER"

# Sanity check: verifying the ORIGINAL digest still succeeds (supply chain best practice)
cosign verify \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  "$REF"
```

In `labs/submission8.md`, explain how signing protects against tag tampering and what “subject digest” means.

---

### Task 2 — Attestations: SBOM (reuse) & Provenance (4 pts)

**Objective:** Attach and verify attestations (SBOM and simple provenance) to the image and inspect the attestation envelope.

```bash
mkdir -p labs/lab4/syft
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/tmp anchore/syft:latest \
  "$REF" -o syft-json=/tmp/labs/lab4/syft/juice-shop-syft-native.json
```

Generate CycloneDX SBOM for attestation:

```bash
# Option A: Convert Syft-native SBOM from Lab 4 → CycloneDX JSON
docker run --rm \
  -v "$(pwd)/labs/lab4/syft":/in:ro \
  -v "$(pwd)/labs/lab8/attest":/out \
  anchore/syft:latest \
  convert /in/juice-shop-syft-native.json -o cyclonedx-json=/out/juice-shop.cdx.json
```

#### 2.1: SBOM as an attestation (CycloneDX)
```bash
# Example using CycloneDX SBOM created above
cosign attest --yes \
  --allow-insecure-registry \
  --tlog-upload=false \
  --key labs/lab8/signing/cosign.key \
  --predicate labs/lab8/attest/juice-shop.cdx.json \
  --type cyclonedx \
  "$REF"

# Verify the SBOM attestation
cosign verify-attestation \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  --type cyclonedx \
  "$REF" \
  | tee labs/lab8/attest/verify-sbom-attestation.txt
```

#### 2.2: Simple provenance attestation

```bash
# Create a minimal, valid SLSA Provenance v1 predicate with a proper RFC3339 timestamp
BUILD_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat > labs/lab8/attest/provenance.json << EOF
{
  "_type": "https://slsa.dev/provenance/v1",
  "buildType": "manual-local-demo",
  "builder": {"id": "student@local"},
  "invocation": {"parameters": {"image": "${REF}"}},
  "metadata": {"buildStartedOn": "${BUILD_TS}", "completeness": {"parameters": true}}
}
EOF

cosign attest --yes \
  --allow-insecure-registry \
  --tlog-upload=false \
  --key labs/lab8/signing/cosign.key \
  --predicate labs/lab8/attest/provenance.json \
  --type slsaprovenance \
  "$REF"

# Verify the provenance attestation
cosign verify-attestation \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  --type slsaprovenance \
  "$REF" | tee labs/lab8/attest/verify-provenance.txt
```

In `labs/submission8.md`, document:
 - How attestations differ from signatures
 - What information the SBOM attestation contains
 - What provenance attestations provide for supply chain security
---

### Task 3 — Artifact (Blob/Tarball) Signing (2 pts)

**Objective:** Sign a non-container artifact (e.g., a tarball) and verify the signature.

```bash
echo "sample content $(date -u)" > labs/lab8/artifacts/sample.txt
tar -czf labs/lab8/artifacts/sample.tar.gz -C labs/lab8/artifacts sample.txt

# Option A: Cosign sign-blob using a bundle (recommended)
cosign sign-blob \
  --yes \
  --tlog-upload=false \
  --key labs/lab8/signing/cosign.key \
  --bundle labs/lab8/artifacts/sample.tar.gz.bundle \
  labs/lab8/artifacts/sample.tar.gz

cosign verify-blob \
  --key labs/lab8/signing/cosign.pub \
  --bundle labs/lab8/artifacts/sample.tar.gz.bundle \
  labs/lab8/artifacts/sample.tar.gz | tee labs/lab8/artifacts/verify-blob.txt
```

In `labs/submission8.md`, document:
 - Use cases for signing non-container artifacts (e.g., release binaries, configuration files)
 - How blob signing differs from container image signing

---

## Acceptance Criteria

- ✅ `labs/submission8.md` includes analysis and evidence for Tasks 1–3
- ✅ Image pushed to local registry; Cosign signature created and verified
- ✅ Tamper scenario demonstrated and explained
- ✅ At least one attestation attached and verified (SBOM or provenance); payload inspected with `jq`
- ✅ Artifact signing performed and verified
- ✅ All outputs saved under `labs/lab8/` and committed

---

## How to Submit

1. Create a branch for this lab and push it to your fork:

```bash
git switch -c feature/lab8
# create labs/submission8.md with your findings
git add labs/lab8/ labs/submission8.md
git commit -m "docs: add lab8 submission — signing + attestations"
git push -u origin feature/lab8
```

2. Open a PR from your fork’s `feature/lab8` → course repo’s `main`.
3. Include this checklist in the PR description:

```text
- [x] Task 1 — Local registry, signing, verification (+ tamper demo)
- [x] Task 2 — Attestations (SBOM or provenance) + payload inspection
- [x] Task 3 — Artifact signing (blob/tarball)
```

4. Submit the PR URL via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                                     | Points |
| ------------------------------------------------------------- | -----: |
| Task 1 — Local Registry, Signing & Verification               |    4.0 |
| Task 2 — SBOM/Provenance Attestations (verify + inspect)      |    4.0 |
| Task 3 — Artifact (Blob/Tarball) Signing                      |    2.0 |
| Total                                                         |   10.0 |

---

## Guidelines

- Use the Cosign binary (most widely tested in 2025 for local flows)
- Keep keys out of version control; commit only logs and reports
- Use strong passphrases; rotate and store securely
- Reuse your Lab 4 SBOM for attestation if possible; otherwise create a minimal predicate JSON

<details>
<summary>References</summary>

- Cosign install: https://docs.sigstore.dev/cosign/system_config/installation/
- in-toto/attestations: https://github.com/in-toto/attestation
- CycloneDX: https://cyclonedx.org/
- SPDX: https://spdx.dev/

</details>

</details>
