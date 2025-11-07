# Lab 8

## Task 1

### How Signing Protects Against Tag Tampering

**The Problem with Tags:**
Container image tags (like `v19.0.0` or `latest`) are mutable references that can point to different images over time. This creates a significant security vulnerability:

```bash
# An attacker can easily replace what a tag points to:
docker tag malicious-image localhost:5000/juice-shop:v19.0.0
docker push localhost:5000/juice-shop:v19.0.0
# Now the same tag points to a completely different (malicious) image!
```

**How Cosign Signing Solves This:**

1. **Digest-Based Signing**: Cosign signs the **immutable digest** (SHA256 hash) of the image manifest, not the mutable tag:
   ```
   Original image: localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48
   ```

2. **Cryptographic Verification**: The signature is created using asymmetric cryptography:
   - Private key signs the digest
   - Public key verifies the signature matches the digest
   - If content changes → digest changes → signature verification fails

3. **Tamper Detection**: When we demonstrated tampering by pushing `busybox` to the same tag:
   - The tag now pointed to a different image with a different digest
   - Cosign verification failed because the signature was for the original digest
   - The original digest verification still succeeded, proving immutability

### What "Subject Digest" Means

**Subject Digest** is the cryptographic fingerprint (SHA256 hash) of the exact image content that was signed:

- **Subject**: The container image being signed
- **Digest**: SHA256 hash of the image manifest (metadata describing all layers)
- **Immutability**: This digest uniquely identifies the exact bits of the image - if even one byte changes, the digest changes completely

**Example from our lab:**
```
Subject Digest: sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48
```

This means:
- Cosign signed exactly this image content
- Any verification must be against this exact digest
- No other image (even with same tag) can have this digest
- This provides cryptographic proof of image integrity

**Security Benefits:**
1. **Immutable Reference**: Unlike tags, digests never change
2. **Tamper Evidence**: Any modification results in different digest
3. **Precise Verification**: You verify exactly what was signed
4. **Supply Chain Integrity**: Guarantees the image hasn't been modified since signing

---

## Task 2 — Attestations: SBOM & Provenance

### How Attestations Differ from Signatures

**Signatures** provide:
- **Identity verification**: Proves WHO signed the artifact
- **Integrity assurance**: Proves the artifact hasn't been tampered with
- **Simple yes/no verification**: Either the signature is valid or it's not

**Attestations** provide:
- **Rich metadata**: Detailed information ABOUT the artifact
- **Supply chain transparency**: How, when, and where the artifact was built
- **Compliance evidence**: Structured data for audit and policy enforcement
- **Context and provenance**: The story behind the artifact

**Technical Difference:**
```bash
# Signature: Signs the artifact itself
cosign sign image@digest

# Attestation: Signs metadata ABOUT the artifact  
cosign attest --predicate metadata.json image@digest
```

### SBOM Attestation Information

The SBOM (Software Bill of Materials) attestation contains:

1. **Component Inventory**:
   - All software packages and their versions
   - Direct and transitive dependencies
   - Operating system packages

2. **Vulnerability Context**:
   - Known components that may have security issues
   - License information for compliance
   - Package relationships and dependencies

3. **Transparency Benefits**:
   - Complete visibility into what's inside the container
   - Foundation for vulnerability scanning and management
   - Legal compliance for license tracking

**Example SBOM Content** (from CycloneDX format):
- Component names (e.g., `nginx`, `openssl`)
- Exact versions (e.g., `1.25.3`, `3.0.8`)
- Package managers (e.g., `apt`, `npm`)
- Relationships between components

### Provenance Attestations for Supply Chain Security

**Provenance** provides evidence of:

1. **Build Integrity**:
   - WHO built the artifact (builder identity)
   - WHEN it was built (timestamp)
   - WHERE it was built (build environment)
   - HOW it was built (build process)

2. **Supply Chain Traceability**:
   - Source code repository and commit
   - Build system and tools used
   - Build parameters and configuration
   - Dependencies used during build

3. **Security Assurances**:
   - Non-repudiation (can't deny building it)
   - Build environment integrity
   - Reproducible builds validation
   - Compliance with security policies

**Our Lab Example** (SLSA Provenance v1):
```json
{
  "_type": "https://slsa.dev/provenance/v1",
  "buildType": "manual-local-demo",
  "builder": {"id": "student@local"},
  "invocation": {"parameters": {"image": "localhost:5000/juice-shop@sha256:..."}},
  "metadata": {"buildStartedOn": "2025-11-07T...", "completeness": {"parameters": true}}
}
```

This proves:
- The build was performed locally by a student
- Exact timestamp of the build
- Which image was the target
- Build completeness information

---

## Task 3 — Artifact (Blob/Tarball) Signing

### Use Cases for Signing Non-Container Artifacts

**Release Binaries**:
- Executable files (`.exe`, `.dmg`, `.deb`, `.rpm`)
- Ensures downloaded software hasn't been tampered with
- Proves authenticity of the software publisher

**Configuration Files**:
- Kubernetes manifests
- Infrastructure as Code templates
- Security policies and rules
- Prevents configuration tampering in CI/CD

**Documentation and Legal Files**:
- License agreements
- Security advisories
- Compliance reports
- Ensures document integrity for audit trails

**Software Packages**:
- npm tarballs, Python wheels
- Maven JARs, Go modules
- Source code archives
- Protects package registries from supply chain attacks

### How Blob Signing Differs from Container Image Signing

**Container Image Signing**:
- **Target**: OCI-compliant container images
- **Storage**: Signatures stored in the same registry as the image
- **Reference**: Uses image digest for verification
- **Ecosystem**: Integrated with container registries and Kubernetes
- **Metadata**: Rich manifest structure with layers and metadata

**Blob Signing**:
- **Target**: Any file or binary data
- **Storage**: Signature stored as separate bundle file or detached signature
- **Reference**: Direct file path or URL
- **Ecosystem**: Standalone, works with any file system or storage
- **Metadata**: Minimal - just the file content and signature

**Technical Differences**:

```bash
# Container signing - integrated with registry
cosign sign registry.com/image@sha256:abc123...
# Signature stored in registry as: registry.com/image:sha256-abc123.sig

# Blob signing - standalone bundle
cosign sign-blob --bundle file.tar.gz.bundle file.tar.gz  
# Signature stored in: file.tar.gz.bundle (local file)
```

**Verification Differences**:

```bash
# Container verification - queries registry
cosign verify --key cosign.pub image@digest

# Blob verification - uses local bundle
cosign verify-blob --key cosign.pub --bundle file.bundle file
```

**Security Considerations**:
- **Container signing**: Leverages registry infrastructure for signature distribution
- **Blob signing**: Requires separate mechanism for signature distribution and trust
- **Both**: Provide cryptographic integrity and authenticity guarantees

---

## Lab Summary

This lab demonstrated critical supply chain security practices:

1. **Cryptographic Signing**: Protecting artifact integrity with digital signatures
2. **Digest-Based Security**: Using immutable references instead of mutable tags
3. **Rich Attestations**: Providing transparency through SBOM and provenance metadata
4. **Comprehensive Coverage**: Securing both container images and arbitrary files

These techniques form the foundation of modern software supply chain security, enabling organizations to verify the integrity and provenance of all software artifacts in their environment.
