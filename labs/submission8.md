# Lab 8 — Container Signing and Supply Chain Security (DevSecOps Intro)

## 1. Goal
Demonstrate secure image signing, tamper detection, and supply chain attestation using **Cosign**, **Syft**, and a local registry.

---

## 2. Environment
- Local registry: `localhost:5000`
- Target image: `bkimminich/juice-shop:latest`
- Final digest:  
  `sha256:4954f3665503c67e0a63232554082d0ed1b2904ddabb068628b02213e26f8bd3`
- Cosign keypair: generated with password `"lab8"`

---

## 3. Image Signing and Verification

### Signing
```bash
cosign sign \
  --key labs/lab8/signing/cosign.key \
  --tlog-upload=false \
  --allow-insecure-registry \
  localhost:5000/juice-shop@sha256:4954f3665503c67e0a63232554082d0ed1b2904ddabb068628b02213e26f8bd3
````

### Verification

```bash
cosign verify \
  --key labs/lab8/signing/cosign.pub \
  --allow-insecure-registry
```

✅ **Result:** Signature verified successfully against the public key.

---

## 4. Tamper Simulation (Tag Overwrite)

1. Tag overwritten by another image:

   ```bash
   docker tag alpine:3.20 localhost:5000/juice-shop:lab8
   docker push localhost:5000/juice-shop:lab8
   ```

   → **Digest:** `sha256:efd3b1132b3f9ae882363e03eb41953f7f8e8412a1b7e533d676cf30c78538f3`

2. Verification by digest — ✅ Passed
   Verification by tag — ❌ Failed (`no signatures found`)

3. Tag restored:

   ```bash
   docker push localhost:5000/juice-shop:lab8
   ```

   → **Digest restored:** `sha256:4954f3665503c67e0a63232554082d0ed1b2904ddabb068628b02213e26f8bd3`

---

## 5. SBOM Generation and Attestation

### SBOM

Generated via Syft in CycloneDX format:

```bash
syft scan docker:localhost:5000/juice-shop@sha256:4954...bd3 -o cyclonedx-json \
  > labs/lab8/attest/sbom.cdx.json
```

SBOM contains **3,533 components**.
Example packages: `express`, `jsonwebtoken`, `@babel/parser`, `lodash`, `@noble/curves`.

### Attestation

```bash
cosign attest \
  --key labs/lab8/signing/cosign.key \
  --type cyclonedx \
  --predicate labs/lab8/attest/sbom.cdx.json \
  --allow-insecure-registry \
  --tlog-upload=false \
  localhost:5000/juice-shop@sha256:4954...bd3
```

### Verification

```bash
cosign verify-attestation \
  --key labs/lab8/signing/cosign.pub \
  --type cyclonedx \
  --allow-insecure-registry \
  --insecure-ignore-tlog=true \
  --output json
```

✅ Extracted subject digest:

```
IMAGE_DIGEST=sha256:4954f3665503c67e0a63232554082d0ed1b2904ddabb068628b02213e26f8bd3
SUBJECT_DIGEST=sha256:4954f3665503c67e0a63232554082d0ed1b2904ddabb068628b02213e26f8bd3
→ Match confirmed ✅
```

---

## 6. Provenance Attestation (SLSA)

Manual provenance file (`provenance.json`) was created and signed as `slsaprovenance`.
Verification confirms the same subject digest (`4954f3...bd3`).

---

## 7. Blob Signing and Verification

SBOM archive (`sample-blob.tar.gz`) created and signed:

```bash
cosign sign-blob \
  --key labs/lab8/signing/cosign.key \
  --tlog-upload=false \
  --output-signature labs/lab8/artifacts/sample-blob.tar.gz.sig \
  labs/lab8/artifacts/sample-blob.tar.gz

cosign verify-blob \
  --key labs/lab8/signing/cosign.pub \
  --signature labs/lab8/artifacts/sample-blob.tar.gz.sig \
  labs/lab8/artifacts/sample-blob.tar.gz
```

✅ Verification passed — blob signature matches the public key.
SHA256 of blob:

```
7804429f05a1c21ca937f6ae5a5dc8ae5f0ebbaa0b27fdf84b19f1750f349734
```

---

## 8. Conclusions

* Cosign successfully signed and verified container image by digest.
* Tampering via tag overwrite was detected — digest verification prevented false trust.
* SBOM and provenance attestations were generated and validated.
* Local blob signing and verification succeeded.
* Supply chain integrity (signatures + attestations) confirmed end-to-end.