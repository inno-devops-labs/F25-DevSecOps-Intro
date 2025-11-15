# Submission 8 — Software Supply Chain Security (Cosign Signing & Attestations)

**Author:** Alexander Rozanov • CBS-02 • [al.rozanov@innopolis.university](mailto:al.rozanov@innopolis.university)
**Repo Branch:** `feature/lab8`
**Target App:** OWASP Juice Shop — `bkimminich/juice-shop:v19.0.0`
**Registry:** Local Docker registry `localhost:5000`
**Tooling:** Docker, local `registry:3`, Cosign, Syft (Docker), `jq`, `curl`, `tar`

---

## 1) Environment & Setup

### 1.1 Host environment

* Host OS: Arch - 257.4-1-arch
* Docker: Docker version 28.2.2, build e6534b4
* Container tools:

  * Local Docker registry: `registry:3`
  * SBOM generation: `anchore/syft:latest` (Docker image)
* Signing tools:

  * Cosign (installed locally, used for image & blob signing + attestations)
  * `jq` + `base64` for decoding Cosign attestation payloads

### 1.2 Lab directories & image

I used the directory structure from the lab handout:

```bash
mkdir -p labs/lab8/{registry,signing,attest,analysis,artifacts}
```

Main directories:

* `labs/lab8/registry/` — local registry-related notes (not strictly required)
* `labs/lab8/signing/` — Cosign keys
* `labs/lab8/attest/` — SBOM/provenance predicates + raw verification output
* `labs/lab8/analysis/` — digest references, decoded payloads, verification logs
* `labs/lab8/artifacts/` — non-container artifact (blob) + bundle

Target image & digests:

* Upstream image (Docker Hub):
  `bkimminich/juice-shop:v19.0.0`
* Local registry image (tagged + pushed):
  `localhost:5000/juice-shop:v19.0.0`
* Canonical digest reference (baseline, before tamper):

  ```text
  localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48
  ```

  This value is stored in:

  ```text
  labs/lab8/analysis/ref.txt
  ```

All subsequent signing, verification and attestations are done **by digest**, not by tag.

---

## 2) Task 1 — Local Registry, Signing & Verification (+ Tamper Demo)

**Objective:** Push the Juice Shop image into a local registry, sign it with Cosign, verify the signature by **digest**, then show how tag tampering breaks verification.

### 2.1 Steps: registry, tag, push, digest

1. **Pulled upstream image and started local registry**

   ```bash
   docker pull bkimminich/juice-shop:v19.0.0

   docker run -d --restart=always -p 5000:5000 --name registry registry:3
   ```

2. **Tagged and pushed image into local registry**

   ```bash
   docker tag bkimminich/juice-shop:v19.0.0 localhost:5000/juice-shop:v19.0.0
   docker push localhost:5000/juice-shop:v19.0.0
   ```

3. **Resolved tag → digest and stored canonical reference**

   ```bash
   DIGEST=$(curl -sI \
     -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
     http://localhost:5000/v2/juice-shop/manifests/v19.0.0 \
     | tr -d '\r' | awk -F': ' '/Docker-Content-Digest/ {print $2}')

   REF="localhost:5000/juice-shop@${DIGEST}"

   echo "Using digest ref: $REF" | tee labs/lab8/analysis/ref.txt
   ```

   In my case (see `ref.txt`):

   ```text
   Using digest ref: localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48
   ```

### 2.2 Cosign key pair & image signing

1. **Generated Cosign key pair**

   ```bash
   mkdir -p labs/lab8/signing
   cd labs/lab8/signing

   cosign generate-key-pair

   cd -
   ```

   This created two files:

   * `labs/lab8/signing/cosign.key` — private key (password-protected)
   * `labs/lab8/signing/cosign.pub` — public key

2. **Signed the image by digest**

   ```bash
   cosign sign --yes \
     --allow-insecure-registry \
     --key labs/lab8/signing/cosign.key \
     "$REF"
   ```

   Cosign prompted for the key password and published the signature in the local registry next to the manifest (`sigstore` layout).

### 2.3 Signature verification (baseline)

For signature verification I used the public key:

```bash
cosign verify \
  --allow-insecure-registry \
  --key labs/lab8/signing/cosign.pub \
  "$REF" | tee labs/lab8/analysis/verify-image.txt
```

The file `labs/lab8/analysis/verify-image.txt` contains:

* information about the signed subject (image reference),
* `subject.digest.sha256`, equal to the digest from `ref.txt`,
* information about the key/certificate that issued the signature,
* a line indicating that verification succeeded.

**Conclusion:** when addressing the image by **digest**, Cosign confirms that:

* this particular manifest (and its layers) has not been modified;
* the signature matches the public key from `cosign.pub`.

### 2.4 Tag tampering: overwriting the tag with busybox

To demonstrate the problem with **mutable tags**, I overwrote the `juice-shop:v19.0.0` tag with the `busybox:latest` image.

1. **Overwrote the tag with a new image**

   ```bash
   docker pull busybox:latest

   docker tag busybox:latest localhost:5000/juice-shop:v19.0.0
   docker push localhost:5000/juice-shop:v19.0.0
   ```

2. **Fetched the new digest for the same tag**

   ```bash
   DIGEST_AFTER=$(curl -sI \
     -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
     http://localhost:5000/v2/juice-shop/manifests/v19.0.0 \
     | tr -d '\r' | awk -F': ' '/Docker-Content-Digest/ {print $2}')

   REF_AFTER="localhost:5000/juice-shop@${DIGEST_AFTER}"

   echo "After tamper digest ref: $REF_AFTER" | tee labs/lab8/analysis/ref-after-tamper.txt
   ```

3. **Attempted to verify the new digest (expected failure)**

   ```bash
   cosign verify \
     --allow-insecure-registry \
     --key labs/lab8/signing/cosign.pub \
     "$REF_AFTER" | tee labs/lab8/analysis/verify-after-tamper.txt
   ```

   For `REF_AFTER`, Cosign **does not find a valid signature**, because we originally signed the manifest whose digest is in `ref.txt`, not the new `busybox` image.

4. **Verification for the original digest (expected success)**

   ```bash
   cosign verify \
     --allow-insecure-registry \
     --key labs/lab8/signing/cosign.pub \
     "$REF" | tee labs/lab8/analysis/verify-original-again.txt
   ```

   For the original `REF`, verification still succeeds.

### 2.5 How this protects against tag hijacking

Key ideas:

* Docker tags (`juice-shop:v19.0.0`) are **mutable pointers**. Anyone with push access can replace the image behind a tag.
* Cosign signs and verifies **digests**, not tags:

  * we sign `localhost:5000/juice-shop@sha256:...`;
  * at verification time Cosign checks the digest from the signature against the manifest’s digest.
* If the tag is hijacked and now points to a different image, it gets a **different digest** with **no** valid signature:

  * verification for the new digest (`REF_AFTER`) fails;
  * verification for the original digest (`REF`) still succeeds.

Practical conclusion:

> To defend against tag hijacking, CI/CD and deployment tooling must work with **immutable digests** rather than tags, and/or enforce signature checks by digest under the hood.

---

## 3) Task 2 — Attestations: SBOM & Provenance

**Objective:** Attach a CycloneDX SBOM and a simple SLSA-style provenance as attestations to the signed image, then extract and analyze the payloads.

### 3.1 SBOM attestation (CycloneDX)

#### 3.1.1 Generating SBOM with Syft

First, I generated an SBOM in `syft-json` format and then converted it to CycloneDX JSON:

```bash
mkdir -p labs/lab4/syft labs/lab8/attest

# 1) SBOM from the image by digest (REF)
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/tmp anchore/syft:latest \
  "$REF" -o syft-json=/tmp/labs/lab4/syft/juice-shop-syft-native.json

# 2) Convert to CycloneDX JSON
docker run --rm \
  -v "$(pwd)/labs/lab4/syft":/in:ro \
  -v "$(pwd)/labs/lab8/attest":/out \
  anchore/syft:latest \
  convert /in/juice-shop-syft-native.json -o cyclonedx-json=/out/juice-shop.cdx.json
```

Result:

* `labs/lab4/syft/juice-shop-syft-native.json` — “raw” SBOM from Syft.
* `labs/lab8/attest/juice-shop.cdx.json` — SBOM in CycloneDX format (used as the predicate).

#### 3.1.2 Attaching the SBOM attestation

I used Cosign to create an SBOM attestation, signed with the same key as the image:

```bash
cosign attest --yes \
  --allow-insecure-registry \
  --key labs/lab8/signing/cosign.key \
  --predicate labs/lab8/attest/juice-shop.cdx.json \
  --type cyclonedx \
  "$REF"
```

#### 3.1.3 Verifying SBOM attestation and decoding the payload

Verification:

```bash
cosign verify-attestation \
  --allow-insecure-registry \
  --key labs/lab8/signing/cosign.pub \
  --type cyclonedx \
  "$REF" \
  | tee labs/lab8/attest/verify-sbom-attestation.txt
```

Cosign returns a JSON array of attestations; each element has a `payload` field (base64-encoded). I decoded the first payload:

```bash
cat labs/lab8/attest/verify-sbom-attestation.txt \
  | jq -r '.[0].payload' \
  | base64 -d \
  | jq '.' > labs/lab8/analysis/sbom-attestation-decoded.json
```

In `labs/lab8/analysis/sbom-attestation-decoded.json` you can see:

* `_type` — in-toto statement type;
* `subject[0].name` — subject name (image reference in the local registry);
* `subject[0].digest.sha256` — image digest (same as in `ref.txt`);
* `predicateType` — CycloneDX schema URL;
* `predicate` — SBOM itself (`bomFormat`, `specVersion`, `components[]`, etc.).

**What this SBOM attestation provides:**

* A complete list of components in the image (OS packages, libraries, dependencies).
* Metadata about SBOM format/version.
* A binding between this SBOM and a specific **digest** (the exact image contents).

---

### 3.2 Provenance attestation (SLSA-style)

#### 3.2.1 Defining a simple SLSA provenance predicate

For simplicity I created a minimal JSON provenance predicate describing a “manual” build:

```bash
BUILD_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

cat > labs/lab8/attest/provenance.json << EOF
{
  "_type": "https://slsa.dev/provenance/v1",
  "buildType": "manual-local-demo",
  "builder": {"id": "student@local"},
  "invocation": {"parameters": {"image": "${REF}"}},
  "metadata": {
    "buildStartedOn": "${BUILD_TS}",
    "completeness": {"parameters": true}
  }
}
EOF
```

#### 3.2.2 Attaching the provenance attestation

```bash
cosign attest --yes \
  --allow-insecure-registry \
  --key labs/lab8/signing/cosign.key \
  --predicate labs/lab8/attest/provenance.json \
  --type slsaprovenance \
  "$REF"
```

#### 3.2.3 Verifying and decoding the provenance attestation

```bash
cosign verify-attestation \
  --allow-insecure-registry \
  --key labs/lab8/signing/cosign.pub \
  --type slsaprovenance \
  "$REF" \
  | tee labs/lab8/attest/verify-provenance.txt

cat labs/lab8/attest/verify-provenance.txt \
  | jq -r '.[0].payload' \
  | base64 -d \
  | jq '.' > labs/lab8/analysis/provenance-attestation-decoded.json
```

The decoded payload (`provenance-attestation-decoded.json`) contains:

* `subject[0].digest.sha256` — image digest (same as in `ref.txt`);
* `builder.id` — builder identity (`student@local`);
* `buildType` — build type string (`manual-local-demo`);
* `invocation.parameters.image` — the image the provenance refers to;
* `metadata.buildStartedOn` — UTC timestamp of when the build started;
* `completeness` flags describing which fields are included.

**Why provenance attestations matter:**

* They capture **who**, **when**, and **how** the artifact was produced.
* Policies (e.g. OPA/Gatekeeper, Kyverno) can enforce rules like:
  “Only run images with provenance from a trusted `builder.id`”
  or “Require SLSA-compatible provenance for all production workloads.”

---

### 3.3 Signatures vs. Attestations: what’s the difference

* **Signatures:**

  * Answer the question: *“Is this artifact authentic and unmodified?”*
  * Bind a digest to a key/identity.
  * Small, simple objects focused on **integrity and authenticity**.

* **Attestations (SBOM, provenance, policy/test results):**

  * Answer the question: *“What do we know about this artifact?”*

    * what it contains (SBOM),
    * how and by whom it was built (provenance),
    * which checks it passed (test/policy results).
  * Still bound to the same **digest**, but include a rich domain-specific `predicate`.
  * Multiple attestations can coexist for a single digest (SBOM + provenance + security test results, etc.).

Together they form a trust chain:

> Digest ↔ signature ↔ attestations
> (the image is unmodified, and all metadata describes exactly that content).

---

## 4) Task 3 — Artifact (Blob/Tarball) Signing

**Objective:** Sign and verify a non-container artifact (tarball) using Cosign `sign-blob` / `verify-blob`.

### 4.1 Steps: create, sign and verify the tarball

1. **Create a sample file and tarball**

   ```bash
   echo "sample content $(date -u)" > labs/lab8/artifacts/sample.txt

   tar -czf labs/lab8/artifacts/sample.tar.gz \
     -C labs/lab8/artifacts sample.txt
   ```

2. **Sign the tarball as a blob and produce a bundle**

   ```bash
   cosign sign-blob \
     --yes \
     --key labs/lab8/signing/cosign.key \
     --bundle labs/lab8/artifacts/sample.tar.gz.bundle \
     labs/lab8/artifacts/sample.tar.gz
   ```

3. **Verify the blob signature**

   ```bash
   cosign verify-blob \
     --key labs/lab8/signing/cosign.pub \
     --bundle labs/lab8/artifacts/sample.tar.gz.bundle \
     labs/lab8/artifacts/sample.tar.gz \
     | tee labs/lab8/artifacts/verify-blob.txt
   ```

`verify-blob.txt` confirms that:

* the digest of `sample.tar.gz` matches the signed content,
* the signature is valid for the public key.

### 4.2 Why sign non-container artifacts

Common use cases:

* Signed **release binaries** for CLIs, agents, desktop apps.
* **Configuration bundles** (e.g., Helm charts, YAML/JSON bundles).
* **Policy bundles** (Rego, templates) that must only be loaded from trusted sources.
* Source archives or other deliverables packaged as `.tar.gz`.

Benefits:

* Users and scripts can verify that files were not tampered with.
* CI/CD can block the use of unsigned or incorrectly signed artifacts.

### 4.3 Comparing image signing and blob signing

* **Image signing:**

  * Subject is an OCI image manifest (`repo@sha256:...`) stored in a container registry.
  * Signatures and attestations are stored alongside the manifest in the registry.

* **Blob signing:**

  * Subject is a **local file** (any format: tar, bin, yaml, etc.).
  * Signature is stored in a separate bundle file (`sample.tar.gz.bundle`), not in a registry.
  * Verification runs locally and requires the file, the bundle, and the public key.

Common ground:

* In both cases, the signature is bound to the **digest** of the content.
* The same key material (`cosign.key` / `cosign.pub`) can secure containers and arbitrary files.
* Easy to integrate into release pipelines: sign after build, verify at download/deploy time.

---

## 5) Repro & Artifacts

### 5.1 How to reproduce

1. **Setup branch & directories**

   ```bash
   git switch -c feature/lab8

   mkdir -p labs/lab8/{registry,signing,attest,analysis,artifacts}
   ```

2. **Repeat Task 1** — local registry, push, digest, signing and tamper demo:

   * Commands in **Sections 2.1–2.4**.
   * Ensure that:

     * `ref.txt` contains the original digest;
     * `ref-after-tamper.txt` contains the new digest after re-tagging;
     * `verify-image.txt` / `verify-original-again.txt` show successful verification;
     * `verify-after-tamper.txt` shows failed verification for the tampered digest.

3. **Repeat Task 2** — SBOM + provenance attestations:

   * Commands in **Sections 3.1 and 3.2**.
   * Check that:

     * `juice-shop.cdx.json` exists and looks like valid CycloneDX SBOM;
     * `verify-sbom-attestation.txt` and `sbom-attestation-decoded.json`
       contain `subject.digest.sha256` matching `ref.txt`;
     * `provenance.json` describes builder/id, timestamp and parameters;
     * `verify-provenance.txt` and `provenance-attestation-decoded.json`
       decode correctly and reference the same digest.

4. **Repeat Task 3** — blob signing:

   * Commands in **Section 4.1**.
   * Check that:

     * `sample.tar.gz` and `sample.tar.gz.bundle` exist;
     * `verify-blob.txt` confirms successful verification.

5. **Commit & push**

   ```bash
   git add labs/lab8/ labs/submission8.md
   git commit -m "docs: add lab8 submission — signing & attestations"
   git push -u origin feature/lab8
   ```

### 5.2 Key files committed for the lab

* **Digests & verification logs:**

  * `labs/lab8/analysis/ref.txt`
  * `labs/lab8/analysis/ref-after-tamper.txt`
  * `labs/lab8/analysis/verify-image.txt`
  * `labs/lab8/analysis/verify-after-tamper.txt`
  * `labs/lab8/analysis/verify-original-again.txt`

* **Attestations & decoded payloads:**

  * `labs/lab8/attest/juice-shop.cdx.json`
  * `labs/lab8/attest/verify-sbom-attestation.txt`
  * `labs/lab8/analysis/sbom-attestation-decoded.json`
  * `labs/lab8/attest/provenance.json`
  * `labs/lab8/attest/verify-provenance.txt`
  * `labs/lab8/analysis/provenance-attestation-decoded.json`

* **Blob signing artifacts:**

  * `labs/lab8/artifacts/sample.txt`
  * `labs/lab8/artifacts/sample.tar.gz`
  * `labs/lab8/artifacts/sample.tar.gz.bundle`
  * `labs/lab8/artifacts/verify-blob.txt`

This report describes how I:

1. Set up a local registry and signed the image by digest.
2. Demonstrated that tag tampering breaks verification of the new digest but does not affect the original one.
3. Added SBOM and provenance attestations tied to the same digest.
4. Extended the same trust model to non-container artifacts via Cosign `sign-blob` / `verify-blob`.
