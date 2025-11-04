# Lab 8

### vl.kuznetsov@innopolis.university

## Task 1

### Explanation: How Signing Protects Against Tag Tampering and What “Subject Digest” Means

When an image is **signed with Cosign**, the signature is bound to its **digest**, not its tag.  
A *tag* (like `:v19.0.0`) is just a movable pointer that can later be reassigned to a different image — for example, an
attacker could push a malicious image to the same tag.

However, the **digest** (the long `sha256:...` value) uniquely identifies the exact image manifest and its layers.  
Cosign calculates this digest and signs it; that digest becomes the **“subject digest”** in the signature metadata — the
specific content the signature refers to.

During verification, Cosign recomputes the digest of the pulled image and compares it with the signed subject digest.  
If the tag was retargeted to a different image, the digest changes, and verification fails.  
This ensures that only the original, untampered image is trusted — protecting against tag tampering and providing strong
integrity guarantees.

## Task 2 — Attestations (SBOM & Provenance)

### How Attestations Differ from Signatures

- **Signatures** only prove **integrity and authenticity** of an artifact — confirming *who* signed it and that the
  artifact’s **content (digest)** hasn’t changed.
- **Attestations** extend that idea by attaching **structured metadata** (facts or evidence) *about* the artifact, such
  as how it was built or what dependencies it contains.
- In short:
    - **Signature →** “I built and trust this exact image.”
    - **Attestation →** “Here’s verifiable evidence and context for how and with what this image was built.”

### What the SBOM Attestation Contains

- The SBOM (Software Bill of Materials) attestation embeds a **CycloneDX JSON document** listing all components and
  dependencies inside the container image.
- Key fields from the attestation envelope:
    - `predicateType`: identifies the SBOM type (e.g., `https://cyclonedx.org/schema`).
    - `subject`: the image name and **digest** the SBOM applies to.
    - `predicate`: includes fields like:
        - `bomFormat` → format of the SBOM (CycloneDX)
        - `specVersion` → SBOM spec version (e.g., `1.6`)
        - `components` → list of packages, versions, and licenses.
- This allows downstream verifiers to check *exactly which software* is in the image — improving transparency and
  vulnerability tracking.

### What Provenance Attestations Provide

- **Provenance** attestation records **how, when, and by whom** an artifact was built.
- Common elements:
    - `buildType` → describes the build process (manual, CI/CD, etc.)
    - `builder.id` → who performed the build (identity or service)
    - `invocation.parameters` → what inputs or build args were used
    - `metadata.buildStartedOn` → timestamp of build creation
- Provenance strengthens the supply chain by providing **traceability** — proving the artifact was built in a trusted
  environment using expected sources and parameters.
- Combined with signatures, provenance helps prevent **build forgery** and **tampering between source and binary**,
  aligning with frameworks like **SLSA (Supply-chain Levels for Software Artifacts)**.

## Task 3 — Artifact (Blob/Tarball) Signing

### Use Cases for Signing Non-Container Artifacts

- **Release binaries:** ensure that distributed executables or CLI tools (e.g., `.tar.gz`, `.zip`, `.exe`) are genuine
  and unmodified.
- **Configuration files or manifests:** protect sensitive configuration, deployment YAMLs, or policy bundles so
  consumers can verify integrity.
- **Documentation or data packages:** verify authorship of datasets, models, or reports used in CI/CD or data pipelines.
- **Firmware or embedded images:** validate authenticity before installation on devices.

Signing such standalone artifacts with Cosign (via `sign-blob`) provides the same trust guarantees outside of container
registries.

### How Blob Signing Differs from Container Image Signing

| Aspect           | Container Image Signing                                          | Blob / File Signing                                       |
|------------------|------------------------------------------------------------------|-----------------------------------------------------------|
| **Storage**      | Signature stored in OCI registry (alongside the image)           | Signature stored locally as a `.sig` or `.bundle` file    |
| **Reference**    | Identified by immutable **digest** (`sha256:` of image manifest) | Identified by local **file hash**                         |
| **Purpose**      | Protects container images pushed to registries                   | Protects any arbitrary file (tarballs, binaries, configs) |
| **Verification** | Uses `cosign verify` with image reference                        | Uses `cosign verify-blob` with file path and bundle       |
| **Transport**    | Works with OCI registries (remote)                               | Works offline or in any file system context               |

**In summary:**  
Container signing secures artifacts within registries, while blob signing secures any file outside that ecosystem — both
providing integrity and authenticity guarantees using the same key pair and cryptographic process.
