# Lab 8 Submission — Software Supply Chain Security: Signing, Verification, and Attestations

## How signing protects against tag tampering and what "subject digest" means

**Tag tampering protection:** Container image signing with Cosign creates cryptographic signatures that bind to the specific image content via its digest (SHA-256 hash). When an attacker attempts to replace an image with a malicious one (even if using the same tag), the digest changes, causing signature verification to fail. This prevents tag-based attacks where an attacker could push a compromised image with the same tag name.

**Subject digest:** The "subject digest" refers to the SHA-256 hash of the image manifest, which uniquely identifies the exact image content. In the verification output, we can see `"docker-manifest-digest":"sha256:547bd3fef4a6d7e25e131da68f454e6dc4a59d281f8793df6853e6796c9bbf58"`. This digest ensures that the signature is cryptographically bound to the specific image content, not just the tag name.

## Analysis: Differences between attestations and signatures, SBOM attestation content, and provenance attestation purpose

**How attestations differ from signatures:**

- **Signatures** provide cryptographic proof that an artifact was signed by a specific key holder, establishing authenticity and integrity.
- **Attestations** provide additional contextual information about the artifact, such as what it contains (SBOM) or how it was built (provenance). They are signed statements that can be verified independently. 

**SBOM attestation content:**
The SBOM attestation contains a comprehensive CycloneDX-formatted bill of materials including:

- Package names, versions, and licenses
- File paths and hashes
- Dependency relationships
- Build metadata and timestamps
- Over 200 packages with detailed security and licensing information

**Provenance attestations provide for supply chain security:**
Provenance attestations document the build process and supply chain metadata, including:

- Builder identity and build type
- Build parameters and environment
- Timestamps and completeness information
- This enables supply chain verification, audit trails, and detection of unauthorized modifications to build processes.

## Analysis: Use cases for signing non-container artifacts and how blob signing differs from container image signing

**Use cases for signing non-container artifacts:**

- Release binaries and executables
- Configuration files and deployment manifests
- Software packages and installers
- Firmware updates and IoT device software
- Documentation and legal contracts
- Any file that needs authenticity and integrity verification

**How blob signing differs from container image signing:**

- **Container signing** uses OCI registry integration and signs manifest digests, supporting complex multi-layer images
- **Blob signing** signs individual files directly using cryptographic hashes, creating portable signature bundles that can be distributed separately from the content
- Container signing integrates with registry APIs and supports attestations, while blob signing is more generic and can be used for any file type
