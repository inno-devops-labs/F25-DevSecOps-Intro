# Lab 8 — Software Supply Chain Security: Signing, Verification, and Attestations

## Task 1 - Local Registry, Signing & Verification

Container tags are mutable pointers — they can be moved to reference any underlying image. An attacker who compromises a registry can change the tag to point to a different manifest, effectively swapping out the image without changing the tag name

Signing protects against this because cosign never signs a tag — it signs a digest. A digest uniquely identifies the exact image manifest and cannot be changed without changing the content itself. Since the signature applies only to the original digest, verification of the tampered image will fail

**Subject digest** is the SHA-256 hash of the image’s manifest — the unique, immutable identity of the image that uniquely identifies the signed image

## Task 2 - Attestations: SBOM (reuse) & Provenance

**Comparison of Signatures and Attestations**

| **Aspect** | **Signatures** | **Attestations** |
| --- | --- | --- |
| **Purpose** | To prove the integrity and authenticity of an artifact. | To provide signed metadata describing the artifact. |
| **What is signed** | Only the artifact’s digest (the actual content). | A statement or predicate about the artifact (e.g., SBOM, provenance). |
| **Content size & complexity** | Very small; contains almost no metadata. | Can be large and rich (SBOMs, build info, dependency graphs). |
| **Answers the question** | «Is this the exact artifact the signer created?» | «What is inside this artifact?» and «How was it built?» |
| **Use cases** | Integrity checks, authenticity verification, deployment gating. | Vulnerability scanning, compliance, build transparency, policy enforcement. |

**What information the SBOM attestation contains**

- **Package list**:
  - every installed package or library
  - name, version, type (OS package, npm module, Python package, etc.)
- **hashes**: for each component (e.g., SHA256)
- **license**: information when available
- **:component relationships**: (e.g., which packages depend on which)
- **metadata**: about the scanner/tool (such as syft version and build info)
- **image metadata** (layers, architecture, distro, etc.)

**What provenance attestations provide for supply chain security**

Metadata improves supply chain security because it enables consumers to verify that:
   1. The artifact was built from the expected source (e.g., correct Git commit, not a modified repo)
   2. It was built in a trusted environment (e.g., GitHub Actions, Tekton, or a controlled builder)
   3. The build process has not been tampered with (detects malicious or unexpected build steps)
   4. Artifacts are reproducible and auditable

Without provenance, attackers could substitute binaries, hijack CI pipelines, or inject malicious dependencies

## Task 3 — Artifact (Blob/Tarball) Signing

**Use Cases for Signing Non-Container Artifacts**

1. **Release Binaries**
   - Ensures users download the authentic binary published by the project
   - Protects against supply-chain attacks on distribution websites or package mirrors

2. **Configuration Files and Policies**
   - Ensures that the configuration used by production systems has not been modified
   - Detects unauthorized policy changes

3. **Firmware or Embedded Device Updates**
   - Guarantees that devices install firmware that is trusted and not maliciously replaced

4. **Documents or Metadata Bundles**
   - SBOMs, vulnerability reports, test results, and compliance documents can be signed so they cannot be tampered with after generation

5. **Scripts and Automation Artifacts**
   - Build scripts, deployment scripts, and installer files can be signed to prevent injection attacks

6. **Any Standalone File Used in CI/CD Pipelines**
   - Helps enforce the rule «only signed inputs are allowed», reducing the risk of pipeline poisoning

**How blob signing differs from container image signing**

| Aspect | Container Image Signing | Blob Signing |
| --- | --- | --- |
| **Artifact type** | Signs the image manifest digest stored in an OCI registry | Signs a standalone file (binary, config, tarball) on disk |
| **Where signatures are stored** | Signature is stored in the container registry, next to the image as an OCI artifact | Signature is stored locally, since blobs are not inside registries |
| **How verification works** |  |  |
| Reference | Verified using the digest reference (image@sha256:…) | Verified using the local file path |
| Signature binding | The signature includes the manifest digest | The signature includes the blob’s file hash |
| Signature discovery | `cosign` finds signatures automatically in the registry | User must provide signature/bundle explicitly |
| **Metadata model** |  |  |
| OCI integration | Full OCI support (registry, index, referrers) | Not tied to OCI; works on any file |
| Attestations | Stored in registry as OCI artifacts | Stored locally (unless manually uploaded elsewhere) |
| **Intended use cases** | Production container deployments, Kubernetes admission policies | Release artifacts, firmware, configs, documents, CI/CD inputs |
