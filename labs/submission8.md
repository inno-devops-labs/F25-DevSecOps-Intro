# Lab 8 — Software Supply Chain Security: Signing, Verification, and Attestations

## Task 1 — Local Registry, Signing & Verification

- The image `bkimminich/juice-shop:v19.0.0` was pulled and pushed to the local registry `localhost:5000`.
- Cosign key pair generated (`cosign.key` private, `cosign.pub` public) and used to sign the image.
- Signature verification succeeded for the original digest:
  ```Verified OK for localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48```
- Tamper demonstration: re-tagged `busybox:latest` as `juice-shop:v19.0.0` and pushed. Verification failed for the new digest:
  ```Error: no signatures found```
- **Explanation:** Signing protects against tag tampering because the signature is bound to the image’s

---

## Task 2 — Attestations: SBOM (reuse) & Provenance

- **SBOM Attestation:**  
- CycloneDX SBOM generated from Syft (`juice-shop-syft-native.json`) and attached as a CycloneDX attestation.  
- Verified successfully:
  ```
  {"payload":"...","signatures":[{"sig":"MEUCIQCwlDxw/..."}]}
  ```
- **Information contained:** list of all components and dependencies of the image, including versions and licenses. Provides metadata about the software supply chain that was used to build the image.
- **Provenance Attestation:**  
- Minimal SLSA Provenance v1 predicate created and attached.  
- Verified successfully:
  ```
  {"payload":"eyJfdHlwZSI6Imh0dHBzOi8v...","signatures":[{"sig":"MEUCIQDb0VnxA/..."}]}
  ```
- **Information provided:** records build metadata including builder identity, build start time, parameters, and completeness. Enables tracing the origin and process of image creation, enhancing supply chain security.
- **Difference from signatures:** Attestations describe additional metadata and context (SBOM, provenance) beyond cryptographic validation of the image. Signatures verify integrity and authenticity, while attestations provide transparency and traceability.

---

## Task 3 — Artifact (Blob/Tarball) Signing

- Created a sample artifact `sample.tar.gz` containing `sample.txt`.  
- Artifact signed with Cosign `sign-blob` using a bundle (`sample.tar.gz.bundle`) and successfully verified:
  ``` Verified OK ```
- **Use cases:** signing non-container artifacts like release binaries, configuration files, or scripts ensures integrity and authenticity outside container images.  
- **Difference from container image signing:** blob signing applies to individual files or archives, whereas container image signing binds the signature to the image manifest and layers. Verification ensures the artifact has not been tampered with, similar to container image verification but for arbitrary files.

