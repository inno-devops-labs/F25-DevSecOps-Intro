# Lab 8 — Software Supply Chain Security: Signing, Verification, and Attestations

## Task 1 — Local Registry, Signing & Verification

### 1.1 Local Registry Setup and Image Push

The target image `bkimminich/juice-shop:v19.0.0` was pulled and pushed to a local Docker registry running on `localhost:5000`. Using a digest-based reference ensures content-addressable verification:

**Digest Reference (Original)**:
```
localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48
```

**Why use digest references?**
- **Immutability**: Digest references point to a specific, immutable content
- **Security**: Prevents tag-based attacks where malicious actors push different content to the same tag
- **Verification**: Enables cryptographic verification tied to the exact image content

### 1.2 Cosign Key Pair Generation

A cryptographic key pair was generated using Cosign:
- **Private key**: `labs/lab8/signing/cosign.key` (protected with passphrase)
- **Public key**: `labs/lab8/signing/cosign.pub` (committed for verification)

**Key pair generation command**:
```bash
cosign generate-key-pair
```

This creates an Ed25519 key pair suitable for signing container images and attestations.

### 1.3 Image Signing and Verification

**Signing Command**:
```bash
cosign sign --yes \
  --allow-insecure-registry \
  --tlog-upload=false \
  --key labs/lab8/signing/cosign.key \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

**Verification Command**:
```bash
cosign verify \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

Signature verified for the original digest.

### 1.4 Tamper Demonstration

To demonstrate how signing protects against tampering, a different image (`busybox:latest`) was pushed to the same tag `localhost:5000/juice-shop:v19.0.0`, creating a new digest:

**Digest After Tamper**:
```
localhost:5000/juice-shop@sha256:be49435f6288f9c5cce0357c2006cc266cb5c450dbd6dc8e3a3baec10c46b065
```

**Tamper Verification Attempt**:
```bash
cosign verify \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  "localhost:5000/juice-shop@sha256:be49435f6288f9c5cce0357c2006cc266cb5c450dbd6dc8e3a3baec10c46b065"
```

No signature found for the tampered digest. This demonstrates that signing protects against tag tampering.

**Original Digest Re-verification**:
```bash
cosign verify \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

The original signed digest still verifies correctly.

### Analysis: How Signing Protects Against Tag Tampering

**Tag Tampering Attack Scenario**:
1. Attacker pulls an image, modifies it maliciously, and pushes it with the same tag
2. Without signing, users pulling by tag get the malicious image
3. With signing, the signature is tied to the **subject digest** (the image's cryptographic hash)

**Protection Mechanism**:
- **Subject Digest**: Each signature includes the SHA256 digest of the image content
- **Digest Immutability**: Changing the image content changes its digest
- **Signature Binding**: Signatures are cryptographically bound to the specific digest
- **Tamper Detection**: Modified images have different digests and cannot be verified with the original signature



**Subject Digest Explanation**:
The "subject digest" is the SHA256 cryptographic hash of the container image manifest. It uniquely identifies the exact content of the image:
- **Immutable**: Same content = same digest (deterministic)
- **Cryptographic**: Computationally infeasible to find collisions
- **Content-addressable**: Enables verification without relying on mutable tags

## Task 2 — Attestations: SBOM & Provenance

### 2.1 Attestations vs. Signatures

**Signatures**:
- **Purpose**: Verify the authenticity and integrity of the image
- **What they prove**: The image was signed by the holder of the private key
- **Scope**: Only attests to the image's identity and integrity
- **Format**: Cryptographic signature appended to the image

**Attestations**:
- **Purpose**: Provide additional metadata about the image (SBOM, provenance, test results, etc.)
- **What they prove**: Additional information about the image's composition and build process
- **Scope**: Can include SBOM, build provenance, security scans, compliance reports
- **Format**: In-toto attestation statements signed with the same key

**Key Differences**:
- Signatures prove **what** (the image itself)
- Attestations prove **how, what, and where** (build process, components, origin)

### 2.2 SBOM Attestation

**SBOM Generation**:
A CycloneDX SBOM was generated from the Syft scan results from Lab 4:
- **Source**: `labs/lab4/syft/juice-shop-syft-native.json`
- **Converted to**: CycloneDX format (`juice-shop.cdx.json`)
- **Format**: CycloneDX JSON (industry-standard SBOM format)

**SBOM Attestation Command**:
```bash
cosign attest --yes \
  --allow-insecure-registry \
  --tlog-upload=false \
  --key labs/lab8/signing/cosign.key \
  --predicate labs/lab8/attest/juice-shop.cdx.json \
  --type cyclonedx \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

**SBOM Verification**:
```bash
cosign verify-attestation \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  --type cyclonedx \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

SBOM attestation verified.

**SBOM Attestation Content**:

Extracted from the verified attestation:
- **Subject Digest**: `sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48`
- **Predicate Type**: `https://cyclonedx.org/bom`
- **Payload**: Contains full CycloneDX SBOM with:
  - **Component inventory**: All packages and dependencies in the image
  - **Package metadata**: Names, versions, licenses, and relationships
  - **Vulnerability data**: Known CVEs and security issues
  - **Composition**: Hierarchical structure of components

**SBOM Attestation Benefits**:
1. **Supply Chain Transparency**: Know exactly what components are in the image
2. **Vulnerability Management**: Identify and track vulnerable dependencies
3. **License Compliance**: Understand license obligations
4. **Incident Response**: Quickly identify affected components during security incidents
5. **Compliance**: Meet regulatory requirements for software transparency

### 2.3 Provenance Attestation

**Provenance Creation**:
A minimal SLSA Provenance v1 predicate was created:

```json
{
  "_type": "https://slsa.dev/provenance/v1",
  "buildType": "manual-local-demo",
  "builder": {"id": "student@local"},
  "invocation": {
    "parameters": {
      "image": "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
    }
  },
  "metadata": {
    "buildStartedOn": "2025-11-02T14:45:30Z",
    "completeness": {
      "parameters": true
    }
  }
}
```

**Provenance Attestation Command**:
```bash
cosign attest --yes \
  --allow-insecure-registry \
  --tlog-upload=false \
  --key labs/lab8/signing/cosign.key \
  --predicate labs/lab8/attest/provenance.json \
  --type slsaprovenance \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

**Provenance Verification**:
```bash
cosign verify-attestation \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  --type slsaprovenance \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

Provenance attestation verified.

**Verified Provenance Details**:
- **Predicate Type**: `https://slsa.dev/provenance/v0.2`
- **Subject Digest**: `sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48`
- **Builder ID**: `student@local`
- **Build Type**: `manual-local-demo`
- **Build Timestamp**: `2025-11-02T14:45:30Z`

### What Provenance Attestations Provide for Supply Chain Security

**1. Build Process Transparency**:
- **Who built it**: Identifies the builder and build system
- **When built**: Timestamp of build execution
- **How built**: Build parameters and configuration
- **What sources**: Source code and dependencies used

**2. Supply Chain Integrity**:
- **Authenticity**: Verifies the build origin
- **Non-repudiation**: Builder cannot deny creating the artifact
- **Chain of custody**: Tracks the artifact from source to deployment

**3. Security Benefits**:
- **Trust verification**: Verify images came from trusted builders
- **Tamper detection**: Detect unauthorized modifications
- **Audit trail**: Maintain records for compliance and forensics
- **Incident response**: Quickly identify build origins during security incidents

**4. Compliance and Governance**:
- **Regulatory compliance**: Meet requirements for software traceability
- **Policy enforcement**: Ensure images meet organizational policies
- **Risk assessment**: Evaluate supply chain risks based on build provenance

**5. Production Use Cases**:
- **Automated builds**: CI/CD systems generate provenance automatically
- **Multi-stage builds**: Track builds through complex pipelines
- **Distributed builds**: Verify builds from multiple sources
- **Third-party validation**: Independently verify build claims

## Task 3 — Artifact (Blob/Tarball) Signing

### 3.1 Artifact Creation and Signing

**Artifact Created**:
```
File: labs/lab8/artifacts/sample.txt
Content: sample content Sun Nov  2 02:45:50 PM UTC 2025
```

**Tarball Creation**:
```bash
tar -czf labs/lab8/artifacts/sample.tar.gz -C labs/lab8/artifacts sample.txt
```

**Blob Signing**:
```bash
cosign sign-blob \
  --yes \
  --tlog-upload=false \
  --key labs/lab8/signing/cosign.key \
  --bundle labs/lab8/artifacts/sample.tar.gz.bundle \
  labs/lab8/artifacts/sample.tar.gz
```

**Blob Verification**:
```bash
cosign verify-blob \
  --key labs/lab8/signing/cosign.pub \
  --bundle labs/lab8/artifacts/sample.tar.gz.bundle \
  labs/lab8/artifacts/sample.tar.gz
```
Blob signature verified.

### 3.2 Use Cases for Signing Non-Container Artifacts

**1. Release Binaries**:
- **Executable files**: Sign application binaries, installers, and packages
- **Distribution security**: Verify binaries haven't been tampered with during download
- **User trust**: Users can verify binaries before execution
- **Example**: Sign `.deb`, `.rpm`, `.exe`, `.dmg`, `.apk` files

**2. Configuration Files**:
- **Infrastructure as Code**: Sign Terraform, Ansible, CloudFormation files
- **Policy files**: Sign security policies and compliance configurations
- **Kubernetes manifests**: Sign YAML files before applying to clusters
- **Prevents**: Unauthorized configuration changes

**3. Release Artifacts**:
- **Source code tarballs**: Sign source distributions
- **Documentation**: Sign PDFs, release notes, and documentation
- **Checksums**: Sign checksum files themselves
- **Package repositories**: Sign package index files

**4. Compliance and Audit**:
- **Audit logs**: Sign log files for integrity verification
- **Compliance reports**: Sign compliance and security scan reports
- **Certificates**: Sign certificate files and keys
- **Legal documents**: Sign contracts and agreements

**5. Software Distribution**:
- **Package managers**: Sign packages for npm, PyPI, Maven repositories
- **Operating system packages**: Sign system updates and patches
- **Container registries**: Sign Helm charts, OCI artifacts
- **Git repositories**: Sign tags and commits

### 3.3 How Blob Signing Differs from Container Image Signing

**1. Target Artifact**:
- **Container images**: Signed through OCI registry with integrated signature storage
- **Blobs**: Signed independently, requiring separate bundle file storage

**2. Signature Storage**:
- **Container images**: Signatures stored in the registry alongside the image
- **Blobs**: Signatures stored in separate bundle files (`.bundle` files)

**3. Verification Flow**:
- **Container images**: Registry provides signature automatically during pull
- **Blobs**: Verification requires explicit bundle file alongside the artifact

**4. Registry Integration**:
- **Container images**: Leverage OCI registry capabilities for signature distribution
- **Blobs**: No registry integration; must distribute bundle separately

**5. Use Cases**:
- **Container images**: Designed for containerized deployments
- **Blobs**: Generic for any file type (binaries, configs, archives, etc.)

**6. Distribution Model**:
- **Container images**: Centralized through registries
- **Blobs**: Decentralized, bundle files can be distributed via any method

**7. Tooling**:
- **Container images**: Integrated with Docker, Podman, containerd
- **Blobs**: Standalone verification, often integrated into CI/CD pipelines

**8. Security Model**:
- **Container images**: Signatures tied to image digest (content-addressable)
- **Blobs**: Signatures tied to file content hash (similar concept)

**Key Similarities**:
- Both use the same cryptographic signing mechanism (Ed25519)
- Both support the same key management approaches
- Both enable tamper detection and authenticity verification
- Both can integrate with transparency logs (Rekor)


