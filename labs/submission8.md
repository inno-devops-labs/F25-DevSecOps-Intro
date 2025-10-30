# Task 1

### How signing protects against tag tampering

Signing images prevents an attacker from substituting our image with a malicious one because we verify that the image is
original. So we do not trust the image tag.

### What “subject digest” means

Subject digest is a hash of the image. It allows to tell different images apart even if they differ only slightly.

# Task 2

### How attestations differ from signatures

Signatures only allow to check if the image is unmodified (by comparing the hash). A signature is only the hash of the
image encrypted by the author's private key.

An attestation allows to attach additional information about the image, in this case the SBOM and provenance.

### What information the SBOM attestation contains

It lists metadata (hash, version, description, name, other properties) of all components of the program (dependencies,
packages, the app itself).

### What provenance attestations provide for supply chain security

Among other things, it records the build author (whom to blame) and the correct way to invoke the image (prevents
typos or misconfigurations).

# Task 3

### Use cases for signing non-container artifacts

It makes sense to sign runtime artifacts, that is, built programs and their configs. They could be publicly available
(linux packages are signed) or not.

### How blob signing differs from container image signing

When signing images, the signature is stored with the image in the registry. Also, the image just needs to be in the
remote registry.

Signing arbitrary files produces a bundle file that contains the signature, and the file must be available in the file
system.
