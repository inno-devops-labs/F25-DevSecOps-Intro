# Lab 8 — Software Supply Chain Security: Signing, Verification, and Attestations

## Task 1 — Local Registry, Signing & Verification

### How signing protects against tag tampering
Signing creates a cryptographic signature tied to the specific image digest, not the tag. If someone replaces the image at the same tag, the digest changes and the signature verification fails.

```
cosign verify \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  "$REF_AFTER"
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.
Error: no signatures found
error during command execution: no signatures found

```

```
cosign verify \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  "$REF"
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.

Verification for ...


The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key

```

### What "subject digest" means
The subject digest is the SHA256 hash of the image manifest. It uniquely identifies the exact image content, making it more secure than using tags which can be moved.



## Task 2 — Attestations: SBOM (reuse) & Provenance

### SBOM Attestation Evidence
The SBOM attestation was successfully attached and verified. Key details:
- **Format:** CycloneDX 1.6
- **Generator:** Syft v1.33.0  
- **Timestamp:** 2025-10-31T12:05:26Z
- **Content:** Complete software inventory of juice-shop container

### Provenance Attestation Evidence  
The provenance attestation provides build transparency:
- **Build Type:** manual-local-demo
- **Builder:** student@local
- **Build Time:** 2025-10-31T12:06:41Z
- **Image:** localhost:5000/juice-shop@sha256:...
- **BuildStartedOn:** 2025-10-31T12:06:41Z
- **Completeness:** true
- **Standard:** SLSA Provenance v1

### Key Differences: Signatures vs Attestations

**Signatures** answer:
- ✅ **Who** created this artifact?
- ✅ **Is it authentic** and untampered?

**Attestations** answer:  
- ✅ **What** is inside? (SBOM - components, dependencies)
- ✅ **How** was it built? (provenance - build process, timing)
- ✅ **Why** should I trust it? (contextual evidence)

### Supply Chain Security Benefits

**SBOM Attestations enable:**
- Vulnerability management across all dependencies
- License compliance verification
- Software transparency and auditability

**Provenance Attestations enable:**
- Build process verification
- Builder identity confirmation  
- Temporal context for security incidents
- Detection of unauthorized build sources

## Task 3 — Artifact (Blob/Tarball) Signing

### Use Cases for Non-Container Artifact Signing

**Release Binaries:** Sign executables (.exe, .jar, .bin) to prevent tampering during distribution.

**Configuration Files:** Sign critical configs (Kubernetes manifests, Terraform) to ensure deployment integrity.

**Software Packages:** Sign source tarballs, npm/PyPI packages to prevent dependency confusion attacks.

**Scripts & Documentation:** Sign installation scripts and security advisories to prevent malicious modifications.

## How Blob Signing Differs from Container Image Signing

### **Image Signing**
- Used for **container images** stored in OCI registries (like Docker Hub or GHCR).
- Signature is stored **in the same registry** as an additional OCI artifact (`sha256:<digest>.sig`).
- Verification is done using the **image digest** and registry reference.
- Common in **CI/CD pipelines** and **deployment workflows**.
- Optional upload to a **transparency log (Rekor)** for public proof.
- Typical use: verifying published **container images** before deployment.

### **Blob (Tarball) Signing**
- Used for **any file** such as `.tar.gz`, `.zip`, `.yaml`, `.bin`, etc.
- Signature is stored **locally** as a separate file (e.g., `myfile.sig`).
- Verification is based on the **exact file contents** (recomputed hash).
- Works **outside of container registries** — great for signing binaries or config files.
- Optional transparency log upload available with `--tlog-upload`.
- Typical use: verifying **software release archives** or **local build artifacts**.


