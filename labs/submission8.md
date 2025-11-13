## Task 1

**Tag tampering**: an intentional act of replacing the image a given tag refers to or a reassignment of a tag to another image.

> Question:
> How does signing protect against tag tampering?

Signing enables the consumers to verify the **authenticity of the image content** by comparing the original author's digest against the freshly computed image digest. The signing process is as follows:

1. The author computes the image digest after building the image.
2. The author encrypts the image digest using the private key, resulting in a signature.
3. The author publishes the image, the signature, and the public key associated with the previously used private key.

The signature verification process is as follows:

1. The consumer downloads the image, the signature, and the public key of the publisher
2. The consumer computes the received image's digest
3. The consumer decrypts the downloaded signature using the downloaded public key, obtaining the original digest
4. The consumer compares the original digest to the received image's digest, concluding authenticity or non-authenticity

> Question:
> What is a "subject digest"?

Term "subject digest" refers to a cryptographic hash, usually SHA256, of the image manifest or the image layers that serve to uniquely identify the image content.

The cryptographic properties of the chosen hash function ensure that any practically implementable form of tampering will alter the digest, thus making it a reliable indicator of authenticity.

## Task 2

*Note: `--type slsaprovenance` flag was replaced with `--type slsaprovenance1` because the suggested `provenance.json` used SLSA v1.0 predicate. Additionally, `provenance.json` itself was rewritten to account for the up-to-date requirements.*

> Question:
> How do attestations differ from signatures?

Signatures are a cryptographic mechanism for ensuring authenticity and authorship of data. An attestation, on the other hand, is structured data that is signed by a signature in order to communicate some property of a software build in a verifiable manner.

> Question:
> What information does the SBOM attestation contain?

SBOM attestation contains:
- All software components, libraries, and dependencies, including versions and metadata.
- Source, origin, and build environment information.
- Digests of components.
- Links to known vulnerabilities, patches, and security status.
- License types and compliance details.
- Dependencies and nested component structure.
- Signature.
- Time and authority that issued the attestation.

> Question:
> What do provenance attestations provide for supply chain security?

**Provenance attestations provide:**
- Verifiable transparency into the origin and lifecycle of software artifacts.
- Exact sources, build processes, tools, and environments used to create the artifact.
- Protection from tampering or unauthorized changes.
- Simplified compliance and trust through standardisation of metadata.
- Increased traceability and simplified auditing through dependency tracking.

Thus, the main advantage of provenance attestations is the clarity on every important aspect of software metadata that affects compliance, security, and trust.

## Task 3

> Question:
> What are the use cases for signing non-container artifacts?

The use cases extend to any files that are in danger of tampering or manipulation by threat actors, such as executables, JAR files, bash scripts, configuration files (Helm charts, YAML manifests), CI/CD configuration, incident logs, etc.

> Question:
> How does blob signing differ from container image signing?

Blob signing, unlike image signing, uses the raw content to produce a digest instead of separate image layers, but may used specialized digest computation procedures for some file types.
