# Task 1 — Local Registry, Signing & Verification

## How signing protects against tag tampering

Container registry tags function as changeable references that may be updated to point to different image versions. This introduces vulnerabilities enabling adversaries to hijack well-known tags and redirect them toward compromised container images.

**Cosign mitigates this threat using cryptographic authentication**:

1. **Digest-based signatures**: Cosign binds cryptographic signatures to image content digests (SHA256 checksums) rather than variable tag identifiers
2. **Content-based addressing**: Image digests serve as unique fingerprints that automatically change when image layers are altered
3. **Digest comparison**: Verification procedures validate the present digest against the originally signed content reference
4. **Unauthorized change detection**: When tags reference different image contents, digest mismatches trigger verification rejections

**Security mechanism**: Despite tag reassignment attempts, cryptographic signatures block unauthorized image acceptance, defending software supply chains from image substitution threats.

## What "subject digest" means

**Subject digest** refers to the cryptographic content identifier for container images:

- **SHA256 content hash** that serves as a unique content fingerprint
- **Content-immutable identifier** that automatically updates when image contents change
- **Tag-agnostic reference** that remains stable independent of tag naming conventions
- **Verification binding point** - Cosign verification outputs display the subject field indicating the precise image version that received cryptographic signing

This content-based identifier establishes trust foundations for container images by generating tamper-proof associations between cryptographic signatures and particular image revisions.

---

# Task 2 — Attestations: SBOM (reuse) & Provenance

## How attestations differ from signatures

**Signatures** establish fundamental authenticity verification:
- **Objective**: Confirm image origin and content integrity
- **Signed content**: Cryptographic hash of the image digest
- **Output format**: Digital signature cryptographic data exclusively
- **Verification query**: "Does this match the intended, untampered image?"

**Attestations** attach structured metadata claims:
- **Objective**: Associate cryptographically verified information describing the image
- **Signed content**: Hash values computed from predicate document files (JSON payloads)
- **Output format**: Standardized JSON structure containing type declarations, predicate data, and subject references
- **Verification query**: "What are the build details and component contents?"

## What information the SBOM attestation contains

SBOM attestations deliver detailed software composition documentation:

- **Exhaustive component catalog**: Complete enumeration of installed packages, frameworks, and transitive dependencies
- **Component details**: Version numbers, license information, and file checksums
- **Component origins**: Repository sources and artifact retrieval locations
- **Analysis metadata**: Scanner tool versions and execution environment details
- **Regulatory information**: License specifications and security advisory cross-references

This documentation supports security vulnerability management, license compliance verification, and software dependency lifecycle tracking.

## What provenance attestations provide for supply chain security

Provenance attestations supply essential build process visibility:

- **Build attribution**: Identity of build operators and timestamp information
- **Build process records**: Input parameters, execution commands, and build-time dependencies
- **Material tracking**: Precise source code versions and parent image references employed
- **Build environment attestation**: Validation of authorized build infrastructure usage
- **Historical documentation**: Complete activity logs supporting regulatory compliance and incident investigation

This documentation guarantees that images originate from legitimate build processes operating within authorized environments utilizing verified source materials.

---

# Task 3 — Artifact (Blob/Tarball) Signing

## Use cases for signing non-container artifacts

Cryptographic signing extends protection mechanisms to diverse critical file types:

- **Executable releases**: Authenticate genuine software distributions from verified publishers
- **Distribution packages**: Block malicious code insertion during software distribution processes
- **Deployment configurations**: Shield infrastructure manifests from unapproved modifications
- **Source code archives**: Maintain codebase and dependency transfer integrity
- **Policy documents**: Authenticate security procedures and operational guidelines
- **Archive backups**: Preserve data integrity guarantees during archival and recovery operations

## How blob signing differs from container image signing

**Container image signing**:
- **Function**: Authenticate container image integrity within registry ecosystems
- **Applicable formats**: Open Container Initiative compliant container images
- **Signature storage**: Digital signatures embedded within container registry metadata
- **Verification workflow**: Native integration with container management tools and registry service interfaces
- **Format restrictions**: Applicable exclusively to standardized container image structures

**Blob signing**:
- **Function**: Authenticate arbitrary file content regardless of format
- **Applicable formats**: Generic files including executables, compressed archives, configuration files, and other formats
- **Signature storage**: Independent signature bundle files distributed alongside original artifacts
- **Verification workflow**: Manual verification procedures requiring simultaneous access to both artifact files and signature bundles
- **Format restrictions**: Universally applicable across all file format types without structural limitations

Blob signing provides generalized protection across diverse artifact types while container signing delivers specialized workflow integration within containerized software ecosystems.