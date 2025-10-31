# Lab 8 — Software Supply Chain Security: Signing, Verification, and Attestations

## Task 1 — Local Registry, Signing & Verification


### Signing as Supply Chain Defense

- **How signing protects against tag tampering:**  
Signing "pins" trust to the immutable *digest* of the container image, not to the mutable tag. Even if the tag points to new, malicious content, the signature for the original digest remains valid only for the unmodified image.  
Verification fails for any altered or replaced image unless it is resigned with the same (compromised) key.

- **Subject digest meaning:**  
A "subject digest" is the unique cryptographic hash of an image's content. Cosign signatures are always tied to this digest, not to a human-readable tag. Supply chain tools and registries should always enforce verification *by digest*.



## Task 2 — Attestations: SBOM (reuse) & Provenance


### SBOM Attestation

- Generated a Syft-native SBOM JSON file for the signed image digest `$REF`.
- Converted the Syft SBOM to CycloneDX format, a widely adopted standard for SBOM attestations.
- Attached the CycloneDX SBOM as an attestation to the image via Cosign using the signing key.
- Verified the SBOM attestation was correctly attached and valid using Cosign’s verification command.
- This attestation provides detailed component and dependency information linked cryptographically to the image, enabling supply chain consumers to audit contents reliably.

### Provenance Attestation

- Created a minimal SLSA Provenance v1 JSON predicate with metadata entailing build type, builder identity, invocation parameters, and timestamp.
- Attached the provenance attestation to the image using Cosign and the same signing key.
- Verified the provenance attestation is intact and associated with the image digest.
- Provenance attestations document the source and build context of the artifact, enabling detection of unauthorized or unexpected image modifications, which strengthens trust in the software supply chain.

### Key Differences Between Signatures and Attestations

- **Signatures** authenticate the image integrity and signer identity but do not convey additional metadata.
- **Attestations** carry structured metadata about the image (e.g., SBOM, build provenance) and are cryptographically bound to the image, providing forensic, compliance, and audit value beyond simple signature verification.

---


## Task 3 — Artifact (Blob/Tarball) Signing
### Use Cases for Signing Non-Container Artifacts

- Signing release binaries, scripts, configuration files, or any other distribution artifacts to provide authenticity guarantees.
- Enabling recipients to verify the integrity and origin of important files independently of container ecosystems.
- Extending supply chain security practices beyond container images to all critical software assets.

### How Blob Signing Differs from Container Image Signing

- Blob signing directly targets arbitrary files or archives without container-specific metadata or manifests.
- Container image signing typically works with OCI registries, image manifests, and layers, and supports attestation of runtime-relevant information.
- Blob signing is simpler and more generic, useful for artifacts outside container registries, but does not involve image digest or manifest semantics.