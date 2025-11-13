# Task 1 — Local Registry, Signing & Verification

## How signing protects against tag tampering

Container **tags are mutable**: `repo:tag` is just a pointer that can be moved to different content. An attacker (or misconfigured CI) can retag a trusted name to a malicious image.

**Cosign mitigates this with cryptographic signing bound to content**:

1. **Signature binding (repo + digest)**  
   Cosign signs the **repository identity** and the **manifest digest** (`sha256:…`), _not_ the tag. The tuple *(repo, digest)* is what’s being authenticated.

2. **Immutable reference**  
   The **digest** deterministically identifies the manifest (layers/config). Any change → new digest.

3. **Verification**  
   At verify-time, Cosign checks the **current digest** against the **signed subject**. If the tag was repointed, the digest won’t match the signature.

4. **Tamper detection**  
   Retagging `v19.0.0` to different bits yields a **digest mismatch** → `no signatures found` / verification fails.

**Key point**: Tags are for discovery; **trust is anchored in the signed digest**. Optionally, enable the **transparency log (Rekor)** to add auditability.

## What “subject digest” means

The **subject** in Cosign is the exact image identity:
- **Repository** (e.g., `127.0.0.1:5001/juice-shop`) **and**
- **Manifest digest** (e.g., `sha256:772d62…`)

This *(repo, digest)* pair is the **subject** (often loosely called “subject digest”). It’s **immutable**, **tag-independent**, and is the **anchor for verification** (`repo@sha256:…`).  
Best practice: resolve a tag to a digest, then **verify by digest**.

---

# Task 2 — Attestations: SBOM (reuse) & Provenance

## How attestations differ from signatures

- **Signatures**: prove **integrity & identity** of the image (repo+digest).  
  _Question answered:_ “Are these exact bits approved?”

- **Attestations**: **signed metadata** _about_ the image, wrapped in an **in-toto envelope**, stored alongside the image in the registry.  
  _Question answered:_ “**What** is in the image and **how** was it built?”

Attestations don’t change the image; they bind rich, verifiable facts (SBOM, provenance, policy results) to the same digest.

## What information the SBOM attestation contains (CycloneDX)

A **CycloneDX SBOM** attestation typically includes:
- **Components** (packages/libs) with **versions**
- **Relationships/dependencies** (graph)
- **Metadata** (hashes, suppliers, licenses when known)
- Optional **vuln references** and tool details

**Why it matters**: Enables precise vulnerability & license compliance checks **for the exact image digest**, faster incident scoping, and safe upgrades.

## What provenance attestations provide (SLSA v1)

**Provenance** captures **how** the image was produced:
- **Builder identity** (who/what built it)
- **Build type & parameters** (inputs, refs, config)
- **Timestamps** (e.g., `buildStartedOn`)
- Optional **materials/sources** and completeness hints

**Why it matters**: Forms the basis for **supply-chain policies** (“run only artifacts built by our CI from this repo/branch”), **tamper resistance**, and **auditable traceability** (SLSA).


# Task 3 — Artifact (Blob/Tarball) Signing

## Use cases for signing non-container artifacts
- **Release binaries & CLI tools**: ensure downloaded executables (`.pkg`, `.deb/.rpm`, `.exe`) haven’t been tampered with.
- **Configs & IaC**: Helm charts, Terraform modules, Kubernetes manifests, Ansible playbooks — protect infrastructure assets from silent edits.
- **Data & ML**: archives with datasets/model weights/DB exports — preserve reproducibility and data integrity.
- **Policies & reports**: scan results, compliance reports, SBOM/provenance stored outside registries — immutable evidence for audits.
- **Supply-chain evidence**: build logs, cache artifacts, intermediate outputs that aren’t OCI images.

## How blob signing differs from container image signing
- **What is signed**
  - *Blob*: a specific file/byte stream — signature binds to the file’s **content hash**.
  - *Container image*: the **image manifest** (layers + config) — signature binds to *(repository, manifest digest)* (`repo@sha256:…`).
- **Where signatures live**
  - *Blob*: alongside the file (e.g., `.sig` or `.bundle`) or in a separate artifact store.
  - *Image*: as OCI artifacts in the **same registry**, discoverable via the image digest.
- **Identity semantics**
  - *Blob*: no repository; identity is the **file hash** (tags don’t apply).
  - *Image*: identity is **repository + digest**; tags are only for lookup.
- **Verification tools**
  - *Blob*: `cosign sign-blob` / `cosign verify-blob` (optionally with Rekor bundle).
  - *Image*: `cosign sign` / `cosign verify`, `cosign verify-attestation`, `cosign tree`; policy enforcement in CI/admission.
- **Typical scenarios**
  - *Blob*: software releases, configs, data, reports — anything non-OCI.
  - *Image*: runtime artifacts for container platforms.

---