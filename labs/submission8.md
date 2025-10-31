# Lab 8 Submission — Software Supply Chain Security: Signing, Verification, and Attestations

**Student:** [Your Name]  
**Date:** October 31, 2025  
**Lab Points:** 10

---

## Executive Summary

This lab focused on implementing software supply chain security measures using Cosign for container image signing, verification, and attestation management. The lab demonstrated the importance of cryptographic signatures in protecting against supply chain tampering and establishing trust in software artifacts. All tasks were successfully completed using a local container registry and the OWASP Juice Shop application (`bkimminich/juice-shop:v19.0.0`).

---

## Task 1 — Local Registry, Signing & Verification (4 pts)

### 1.1 Registry Setup and Image Publishing

A local Docker registry was deployed on `localhost:5000` using the Distribution v3 image. The Juice Shop image was pulled, tagged, and pushed to the local registry:

```bash
docker pull bkimminich/juice-shop:v19.0.0
docker run -d --restart=always -p 5000:5000 --name registry registry:3
docker tag bkimminich/juice-shop:v19.0.0 localhost:5000/juice-shop:v19.0.0
docker push localhost:5000/juice-shop:v19.0.0
```

**Original Digest Reference:**
```
localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48
```

This digest-based reference is critical for supply chain security as it ensures immutability — the reference points to a specific image manifest rather than a mutable tag.

### 1.2 Key Pair Generation

A Cosign key pair was generated for signing operations:

```bash
cosign generate-key-pair
```

This created:
- `cosign.key` — Private key (password-protected)
- `cosign.pub` — Public key for verification

**Public Key:**
```
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEOV/fb3P4KOUiYf6g+Gu3aWfoScg9
SM04BdCbzAb1qBTaoa4Ow2TALXh15MXsvo6DKyMGXRWs5BYRZ2t9S+8FcQ==
-----END PUBLIC KEY-----
```

### 1.3 Image Signing and Verification

The image was signed using the private key:

```bash
cosign sign --yes \
  --allow-insecure-registry \
  --tlog-upload=false \
  --key labs/lab8/signing/cosign.key \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

Verification was performed using the public key:

```bash
cosign verify \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

**Result:** The signature verification succeeded, confirming the authenticity and integrity of the signed image.

### 1.4 Tamper Demonstration

To demonstrate supply chain protection, we simulated a tag replacement attack:

```bash
docker pull busybox:latest
docker tag busybox:latest localhost:5000/juice-shop:v19.0.0
docker push localhost:5000/juice-shop:v19.0.0
```

**New Digest After Tampering:**
```
localhost:5000/juice-shop@sha256:be49435f6288f9c5cce0357c2006cc266cb5c450dbd6dc8e3a3baec10c46b065
```

When attempting to verify the tampered image:

```bash
cosign verify \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  "localhost:5000/juice-shop@sha256:be49435f6288f9c5cce0357c2006cc266cb5c450dbd6dc8e3a3baec10c46b065"
```

**Result:** Verification **FAILED** because the new digest was never signed with our private key.

However, verifying the original digest still succeeds:

```bash
cosign verify \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

**Result:** Verification **SUCCEEDED** because the original image digest remains signed and unaltered.

### Analysis: How Signing Protects Against Tag Tampering

**Subject Digest:** The "subject digest" is a cryptographic hash (SHA-256) of the container image manifest. It uniquely identifies the exact content of the image, including all layers, metadata, and configuration.

**Protection Mechanism:**
1. **Immutability:** Unlike tags (which are mutable pointers), digests are content-addressed and immutable.
2. **Signature Binding:** The Cosign signature is cryptographically bound to the specific digest, not the tag.
3. **Verification Guarantee:** Even if an attacker replaces the image behind a tag, the signature verification will fail for the new digest because it was never signed.

**Best Practice:** Always use digest references (`@sha256:...`) in production for deployment and verification to ensure the exact artifact is being consumed, regardless of tag mutations.

---

## Task 2 — Attestations: SBOM & Provenance (4 pts)

### 2.1 SBOM Attestation (CycloneDX)

An SBOM (Software Bill of Materials) was generated using Syft and converted to CycloneDX format:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/tmp anchore/syft:latest \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48" \
  -o syft-json=/tmp/labs/lab4/syft/juice-shop-syft-native.json

docker run --rm \
  -v "$(pwd)/labs/lab4/syft":/in:ro \
  -v "$(pwd)/labs/lab8/attest":/out \
  anchore/syft:latest \
  convert /in/juice-shop-syft-native.json -o cyclonedx-json=/out/juice-shop.cdx.json
```

The SBOM was then attached as an attestation:

```bash
cosign attest --yes \
  --allow-insecure-registry \
  --tlog-upload=false \
  --key labs/lab8/signing/cosign.key \
  --predicate labs/lab8/attest/juice-shop.cdx.json \
  --type cyclonedx \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

**SBOM Attestation Verification:**

```bash
cosign verify-attestation \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  --type cyclonedx \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

**Result:** Verification succeeded. The attestation payload contains:
- **CycloneDX format:** Standard SBOM format for interoperability
- **Component inventory:** Complete list of all dependencies, libraries, and packages in the Juice Shop image
- **Cryptographic hashes:** SHA-1 and SHA-256 hashes for each component file
- **License information:** Metadata about component licenses
- **Vulnerability context:** Package versions that can be cross-referenced with vulnerability databases

**SBOM Content Summary:**
The SBOM includes thousands of components (Node.js packages, system libraries, configuration files) with detailed metadata. This enables:
- Vulnerability scanning and tracking
- License compliance verification
- Supply chain transparency
- Software composition analysis

### 2.2 Provenance Attestation (SLSA)

A minimal SLSA v1 provenance attestation was created:

```json
{
  "_type": "https://slsa.dev/provenance/v1",
  "buildType": "manual-local-demo",
  "builder": {"id": "student@local"},
  "invocation": {"parameters": {"image": "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"}},
  "metadata": {"buildStartedOn": "2025-10-31T13:56:43Z", "completeness": {"parameters": true}}
}
```

The provenance was attached as an attestation:

```bash
cosign attest --yes \
  --allow-insecure-registry \
  --tlog-upload=false \
  --key labs/lab8/signing/cosign.key \
  --predicate labs/lab8/attest/provenance.json \
  --type slsaprovenance \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

**Provenance Verification:**

```bash
cosign verify-attestation \
  --allow-insecure-registry \
  --insecure-ignore-tlog \
  --key labs/lab8/signing/cosign.pub \
  --type slsaprovenance \
  "localhost:5000/juice-shop@sha256:b029fa83327aa8a3bbcaf161af6269c18c80134942437cb90794233502554e48"
```

**Verification Output:**
```json
{
  "payload": "eyJfdHlwZSI6Imh0dHBzOi8vaW4tdG90by5pby9TdGF0ZW1lbnQvdjAuMSIsInByZWRpY2F0ZVR5cGUiOiJodHRwczovL3Nsc2EuZGV2L3Byb3ZlbmFuY2UvdjAuMiIsInN1YmplY3QiOlt7Im5hbWUiOiJsb2NhbGhvc3Q6NTAwMC9qdWljZS1zaG9wIiwiZGlnZXN0Ijp7InNoYTI1NiI6ImIwMjlmYTgzMzI3YWE4YTNiYmNhZjE2MWFmNjI2OWMxOGM4MDEzNDk0MjQzN2NiOTA3OTQyMzM1MDI1NTRlNDgifX1dLCJwcmVkaWNhdGUiOnsiYnVpbGRlciI6eyJpZCI6InN0dWRlbnRAbG9jYWwifSwiYnVpbGRUeXBlIjoibWFudWFsLWxvY2FsLWRlbW8iLCJpbnZvY2F0aW9uIjp7ImNvbmZpZ1NvdXJjZSI6e30sInBhcmFtZXRlcnMiOnsiaW1hZ2UiOiJsb2NhbGhvc3Q6NTAwMC9qdWljZS1zaG9wQHNoYTI1NjpiMDI5ZmE4MzMyN2FhOGEzYmJjYWYxNjFhZjYyNjljMThjODAxMzQ5NDI0MzdjYjkwNzk0MjMzNTAyNTU0ZTQ4In19LCJtZXRhZGF0YSI6eyJidWlsZFN0YXJ0ZWRPbiI6IjIwMjUtMTAtMzFUMTM6NTY6NDNaIiwiY29tcGxldGVuZXNzIjp7InBhcmFtZXRlcnMiOnRydWUsImVudmlyb25tZW50IjpmYWxzZSwibWF0ZXJpYWxzIjpmYWxzZX0sInJlcHJvZHVjaWJsZSI6ZmFsc2V9fX0=",
  "payloadType": "application/vnd.in-toto+json",
  "signatures": [{"sig": "MEUCIGs41aGJ7yLTWW/IheZeRuJZrn9PgO5LQ3lY/CPz1cscAiEAiiFxzDXephoruxKZIMAIFSqMUkA/aJdmGM8POwW6JXg="}]
}
```

**Result:** Verification succeeded. The provenance attestation confirms:
- **Builder identity:** `student@local`
- **Build timestamp:** 2025-10-31T13:56:43Z
- **Build parameters:** Image digest being signed
- **Cryptographic signature:** ECDSA signature verifying authenticity

### Analysis: Attestations vs. Signatures

**Signatures:**
- Sign the entire container image or artifact
- Provide authentication and integrity verification
- Answer: "Was this artifact signed by a trusted party?"

**Attestations:**
- Attach metadata statements about an artifact (SBOM, provenance, vulnerability scans, etc.)
- Provide context and supply chain transparency
- Answer: "What is this artifact made of?" and "How was it built?"

**SBOM Attestations Contain:**
- Complete dependency tree
- Component versions and licenses
- Vulnerability identification (through package versions)
- File-level hashes for verification

**Provenance Attestations Provide:**
- Build reproducibility information
- Builder identity and infrastructure details
- Source code commit references
- Build parameters and environment context
- Supply chain audit trail

**Supply Chain Security Value:**
Attestations enable policy enforcement (e.g., "only deploy images with signed SBOMs from trusted builders"), vulnerability management, and compliance verification without needing to scan artifacts repeatedly.

---

## Task 3 — Artifact (Blob/Tarball) Signing (2 pts)

### 3.1 Blob Creation and Signing

A sample artifact was created and signed:

```bash
echo "sample content $(date -u)" > labs/lab8/artifacts/sample.txt
tar -czf labs/lab8/artifacts/sample.tar.gz -C labs/lab8/artifacts sample.txt

cosign sign-blob \
  --yes \
  --tlog-upload=false \
  --key labs/lab8/signing/cosign.key \
  --bundle labs/lab8/artifacts/sample.tar.gz.bundle \
  labs/lab8/artifacts/sample.tar.gz
```

**Sample Content:**
```
sample content Пт 31 окт 2025 13:57:04 UTC
```

### 3.2 Blob Verification

The signed tarball was verified:

```bash
cosign verify-blob \
  --key labs/lab8/signing/cosign.pub \
  --bundle labs/lab8/artifacts/sample.tar.gz.bundle \
  labs/lab8/artifacts/sample.tar.gz
```

**Result:** Verification succeeded, confirming the authenticity and integrity of the tarball.

### Analysis: Blob Signing Use Cases

**Use Cases for Non-Container Artifact Signing:**
1. **Release binaries:** Sign executables, installers, and packages (e.g., `.deb`, `.rpm`, `.exe`)
2. **Configuration files:** Sign Kubernetes manifests, Terraform configurations, Ansible playbooks
3. **Build artifacts:** Sign compiled libraries, JARs, wheels, tarballs
4. **Documentation:** Sign compliance reports, audit logs, security scan results
5. **Dependencies:** Sign third-party libraries before internal distribution

**Differences from Container Image Signing:**

| Aspect | Container Image Signing | Blob/Artifact Signing |
|--------|------------------------|----------------------|
| **Target** | OCI image manifest (multi-layer) | Single file or archive |
| **Registry** | Requires OCI-compatible registry | Filesystem-based (bundle) |
| **Metadata** | Layered structure, tags, digests | Simple file hash |
| **Verification** | Registry-based signature lookup | Bundle file contains signature |
| **Distribution** | Registry push/pull | Direct file transfer, CDN, artifact repositories |

**Blob Signing Benefits:**
- **Flexibility:** Works with any file type without requiring container packaging
- **Portability:** Bundle file can be distributed alongside the artifact
- **Simplicity:** No registry infrastructure needed
- **Universal:** Can sign legacy artifacts, scripts, and documents

---

## Conclusion and Lessons Learned

This lab successfully demonstrated critical supply chain security practices:

1. **Cryptographic Signing:** Provides authentication and tamper detection for software artifacts
2. **Digest-Based References:** Immutable references prevent tag substitution attacks
3. **Attestations:** Extend signing to include metadata (SBOM, provenance) for transparency and policy enforcement
4. **Universal Signing:** Cosign supports both OCI images and arbitrary files

**Security Best Practices Reinforced:**
- Always verify signatures before deploying artifacts
- Use digest references in production (not tags)
- Maintain SBOM attestations for vulnerability management
- Implement provenance tracking for audit trails
- Sign all build outputs, not just container images

**Production Recommendations:**
- Use transparency logs (Rekor) for signature non-repudiation
- Implement keyless signing with OIDC for CI/CD pipelines
- Enforce admission policies (e.g., Kyverno, OPA) requiring signed images
- Automate SBOM generation and attestation in build pipelines
- Regularly rotate signing keys and use hardware security modules (HSMs) for key storage

---

## Acceptance Criteria Checklist

- [x] Task 1 — Local registry, signing, verification (+ tamper demo)
- [x] Task 2 — Attestations (SBOM and provenance) + payload inspection
- [x] Task 3 — Artifact signing (blob/tarball)
- [x] All outputs saved under `labs/lab8/` and committed
- [x] `labs/submission8.md` includes analysis and evidence for Tasks 1–3
- [x] Tamper scenario demonstrated and explained
- [x] Attestation envelope inspected with verification outputs

---

## References

- Cosign Documentation: https://docs.sigstore.dev/cosign/
- Sigstore Transparency Log (Rekor): https://docs.sigstore.dev/rekor/
- in-toto Attestation Framework: https://github.com/in-toto/attestation
- SLSA Provenance Specification: https://slsa.dev/provenance/
- CycloneDX SBOM Standard: https://cyclonedx.org/
- OWASP Juice Shop: https://owasp.org/www-project-juice-shop/

---

**End of Submission**

