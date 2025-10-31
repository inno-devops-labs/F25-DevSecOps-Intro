# Lab 8

## How Signing Protects Against Tag Tampering

Container tags (e.g., `latest`, `v1.0.0`) are mutable — they can point to different image digests at any time.  
When an image is signed with **Cosign**, the signature is bound not to a tag, but to the **immutable digest** of the image (its content hash).  
This means even if a tag is later reassigned to a different image, the original signed digest remains verifiable.

Therefore, verification by digest ensures **integrity and authenticity** of the specific image content, protecting against tag tampering or image replacement.

---

## What “Subject Digest” Means

The **subject digest** refers to the **SHA-256 hash of the image manifest** that uniquely identifies a specific image version.  
It acts as the immutable identifier for the signed content — the "subject" of the signature or attestation.  
Cosign stores this digest in the signature metadata to ensure that verification can only succeed if the image manifest matches exactly.

---

## How Attestations Differ from Signatures

| Aspect | Signature | Attestation |
|---------|------------|-------------|
| **Purpose** | Confirms the authenticity and integrity of an artifact | Adds structured metadata or statements *about* an artifact |
| **Content** | Cryptographic proof of authorship | Metadata such as SBOM, build provenance, or policy results |
| **Format** | Minimal, only signature and digest | Uses the [in-toto](https://in-toto.io) statement format with a payload and predicate type |
| **Verification** | Checks that the artifact hasn’t been altered | Checks both authenticity and the validity of attached metadata |

In short, **signatures prove “who built this”**, while **attestations prove “what this is and how it was built.”**

---

## What the SBOM Attestation Contains

An **SBOM (Software Bill of Materials)** attestation contains a detailed inventory of software components within the container image, including:
- Packages, dependencies, and libraries  
- Versions and licenses  
- Component relationships  
- Metadata such as supplier and build environment  

This information enables vulnerability scanning, license auditing, and traceability of dependencies.

---

## What Provenance Attestations Provide

A **provenance attestation** documents how and where an artifact was produced.  
It may include:
- Source repository and commit hash  
- Build tool and environment  
- Build start and finish timestamps  
- Builder identity or CI/CD system  

Such provenance ensures **supply chain transparency**, allowing consumers to verify that an artifact was built from trusted source code in a controlled environment.

---

## Use Cases for Signing Non-Container Artifacts

Cosign and Sigstore tools can sign artifacts other than container images, such as:
- **Release binaries** — ensuring users download the authentic build.  
- **Configuration files and policies** — protecting critical deployment files from tampering.  
- **Manifests and Helm charts** — ensuring integrity of deployment artifacts.  
- **Source archives or scripts** — confirming authorship and trustworthiness.  

This extends supply chain security beyond containers to all distributed software assets.

---

## How Blob Signing Differs from Container Image Signing

- **Blob signing** allows signing *any arbitrary file or data blob*, such as a binary, configuration file, or document.  
  Example:  
  ```bash
  cosign sign-blob --key cosign.key ./release.tar.gz
  cosign verify-blob --key cosign.pub --signature release.tar.gz.sig ./release.tar.gz
