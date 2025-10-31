# Task 1

Cosign solves tag tampering by signing the content of the image, not the tag.

When registry stores image, it creates cryptographic digest. This digest is the true, immutable identity of that exact image.

Cosign signs the degest. It states "The holder of the private key cosign.key attests to the integrity and trustworthiness of the image"

Now we can verify authenticity of image by public key.

Subject digest is a cryptographic hash (like SHA-256) of the exact image manifest. It's calculated from the entire contents of the image. If even a single byte in the image changes, the digest will be completely different.

# Task 2

## How attestations differ from signatures


The attestation is also signed against the image digest, but its core value is the attached predicate file (the SBOM or provenance data). You are essentially creating a signed metadata document that travels with the image.

## What information the SBOM attestation contains

Metadata: A unique identifier (BOM-ref), the tool that created it (Syft), and the timestamp.

Operating System Packages, Application Dependencies

## What provenance attestations provide for supply chain security

It creates a non-repudiable, signed record of the build process. If a vulnerability is discovered, you can use the provenance to trace it back to the exact build and its parameters, enabling faster root cause analysis and remediation.

# Task 3

Use case: 
Release Binaries & Installers:

- Scenario: You download myapp-v1.2.0-linux-amd64.tar.gz directly from a project's GitHub releases page.

- Risk: An attacker could compromise the GitHub account or the server hosting the files, replacing the legitimate binary with a malicious one.

- Solution: The project maintainers sign the tarball. Before installation, you verify the signature against their public key, ensuring you are running the exact binary they built and published.

## How blob signing differs from container image signing

Blob signing extends the trust model of Cosign to the vast universe of files that don't live in container registries, but it places the burden of managing and distributing the signature bundle on the user. Container image signing is more integrated and automated, leveraging the existing OCI registry infrastructure.