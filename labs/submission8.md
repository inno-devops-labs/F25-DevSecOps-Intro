# Task 1 — Local Registry, Signing & Verification

Simulated tag replacement attack by pushing BusyBox image under same Juice Shop tag. Verification of new digest failed as expected since it was never signed. Original digest verification continued to succeed, demonstrating signature persistence.

**New Digest After Tampering:**

```
localhost:5000/juice-shop@sha256:be49435f6288f9c5cce0357c2006cc266cb5c450dbd6dc8e3a3baec10c46b065
```

### Analysis of Tag Tampering Protection

**How signing protects against tag tampering:**

- Cosign signatures are bound to the image digest, not the tag
- When image content changes, its digest changes accordingly
- The signature becomes invalid for the new digest, even if the tag remains the same
- This prevents attacks where a malicious actor replaces an image under the same tag

**What "subject digest" means:**

- Subject digest is a hash identifier of the image content (typically SHA256)
- Digest is unique to specific image content
- Changing any bit in the image results in a different digest
- Cosign binds signatures to digests, ensuring content integrity

# Task 2 — Attestations: SBOM (reuse) & Provenance

Created minimal SLSA v1 provenance attestation with builder identity, build timestamp, and parameters. Attached as signed attestation with successful verification.

### Differences Between Attestations and Signatures

**Signatures:**

- Guarantee image integrity and authenticity
- Confirm that the image hasn't been modified after signing
- Are directly bound to the image digest

**Attestations:**

- Contain additional metadata about the image
- Can include SBOMs, provenance, security scan results
- Are signed separately from the image
- Allow adding verifiable claims about the image

### Information Contained in SBOM Attestation

The SBOM attestation contains:

- Complete inventory of software components
- Dependency information
- Component versions
- License information

### Value of Provenance for Supply Chain Security

Provenance attestations provide:

- **Traceability**: Tracking the artifact's origin
- **Build Authenticity**: Confirmation of who, when, and how the artifact was built
- **Reproducibility**: Ability to recreate the build process
- **Trust**: Verifiable information about the creation process

# Task 3 — Artifact (Blob/Tarball) Signing

### Analysis: Blob Signing Use Cases

**Non-Container Artifact Signing Applications:**

- Release binaries 
- Configuration files
- Build artifacts
- Documentation
- Dependencies and third-party libraries
- Infrastructure as Code
- Security artifacts
### Differences Between Blob Signing and Container Image Signing

**Container Image Signing:**

- Integrated with OCI registries
- Automatically bound to image digest
- Supports attestations through separate manifests

**Blob Signing:**

- Works with arbitrary files
- Requires explicit file specification for signing
- Uses bundle files to store signatures
- More universal but requires manual signature management
