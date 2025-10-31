# Task 1 — Local Registry, Signing & Verification

## How signing protects against tag tampering

In container registries, tags are mutable pointers that can be easily reassigned to different images. This creates security risks where attackers can redirect trusted tags to malicious images.

**Cosign addresses this through cryptographic signing**:

1. **Signature binding**: Cosign creates signatures tied to the image digest (SHA256 hash), not the tag name
2. **Immutable reference**: The digest uniquely represents the image content and changes if any layer is modified
3. **Verification process**: During validation, Cosign compares the current digest against the signed reference
4. **Tamper detection**: If a tag points to a different image, the digest mismatch causes verification failure

**Key protection**: Even with tag manipulation, the signature prevents acceptance of unauthorized images, securing your supply chain against substitution attacks.

## What "subject digest" means

**Subject digest** is the cryptographic fingerprint of a container image:

- **SHA256 hash** that uniquely identifies the exact image content
- **Immutable reference** that changes with any modification to the image
- **Tag-independent** - remains consistent regardless of tag names
- **Verification anchor** - in Cosign reports, the subject field shows which specific image was signed

This digest provides the foundation for trust in container images by creating an unforgeable link between signatures and specific image versions.

---

# Task 2 — Attestations: SBOM (reuse) & Provenance

## How attestations differ from signatures

**Signatures** provide basic authentication:
- **Purpose**: Verify image authenticity and integrity
- **What's signed**: Hash of the container image digest
- **Content**: Cryptographic signature only
- **Question answered**: "Is this the original, unmodified image?"

**Attestations** provide extended metadata:
- **Purpose**: Attach verified information about the image
- **What's signed**: Hash of predicate files (JSON documents)
- **Content**: Structured JSON envelope with type, predicate, and subject
- **Question answered**: "How was this built and what does it contain?"

## What information the SBOM attestation contains

The SBOM attestation provides comprehensive component inventory:

- **Complete package listing**: All software packages, libraries, and dependencies
- **Component metadata**: Versions, licenses, and cryptographic hashes
- **Source information**: Origin repositories and download locations
- **Build context**: Analysis environment and tool versions
- **Compliance data**: License declarations and vulnerability references

This enables vulnerability tracking, license compliance, and dependency management.

## What provenance attestations provide for supply chain security

Provenance attestations deliver critical build transparency:

- **Build identification**: Who built the image and when
- **Process documentation**: Build parameters, commands, and dependencies
- **Source tracking**: Exact source materials and base images used
- **Environment verification**: Trusted build environment validation
- **Audit trail**: Comprehensive record for compliance and forensics

This ensures images are built properly in authorized environments using expected sources.

---

# Task 3 — Artifact (Blob/Tarball) Signing

## Use cases for signing non-container artifacts

Signing extends security to various critical artifacts:

- **Release binaries**: Verify authentic software from legitimate publishers
- **Installation packages**: Prevent malware injection in distributed software
- **Configuration files**: Protect deployment manifests from unauthorized changes
- **Source archives**: Ensure integrity of code and dependency transfers
- **Documentation**: Validate security policies and procedural guides
- **Backup files**: Guarantee data integrity during storage and restoration

## How blob signing differs from container image signing

**Container image signing**:
- **Purpose**: Verify container integrity in registries
- **Target**: OCI-compliant container images
- **Storage**: Signatures stored within the container registry
- **Verification**: Integrated with container tools and registry APIs
- **Scope**: Limited to container image formats

**Blob signing**:
- **Purpose**: Verify authenticity of any file type
- **Target**: Arbitrary files (binaries, archives, configs, etc.)
- **Storage**: Separate signature bundles alongside artifacts
- **Verification**: Manual process requiring both file and signature
- **Scope**: Universal application across all file formats

Blob signing offers broader flexibility while container signing provides deeper ecosystem integration.