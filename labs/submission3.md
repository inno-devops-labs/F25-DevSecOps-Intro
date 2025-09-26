## Summary of the benefits of signing commits

1) Integrity. Commit signing guarantees that the code and metadata within a commit have not been altered since signing, maintaining data integrity
2) Authenticity. Signing proves the authenticity of the committer, showing that the commit truly originated from the stated author and not someone spoofing their identity (not faked by anyone setting their username and email to impersonate others)
3) Security. Signed commits are especially important in open-source and collaborative projects, adding a critical layer of security against malicious code insertion. Repositories can be configured to only accept signed commits, preventing unsigned or suspicious changes from being merged
4) Accountability. Signing commits ensures traceability and accountability, creating a verifiable audit trail of changes for compliance or regulatory needs

## Evidence of successful SSH key setup and configuration

**Key setup:**
![Key setup](/labs/lab3/image_1.png)

**Git config**
![Git config](/labs/lab3/image_2.png)

## Analysis

Commit signing is critical in DevSecOps because it creates a cryptographic chain of trust from developer identity through CI/CD to production, ensuring only authenticated, untampered changes can flow through automated pipelines

## Verification badge

![Verification badge](/labs/lab3/image_3.png)

## Pre-commit hook setup process and configuration

**Hook creation:**

![Hook creation](/labs/lab3/image_4.png)

**Hook configuration:**

![Hook configuration](/labs/lab3/image_5.png)

**Hook chmod:**

![Hook chmod](/labs/lab3/image_6.png)

## Evidence of successful secret detection blocking commits

**Commit blocked by hook:**

![Commit blocked by hook](/labs/lab3/image_7.png)

**Commit approved by hook:**

![Commit approved by hook](/labs/lab3/image_8.png)

## Analysis of how automated secret scanning prevents security incidents

Early detection removes credentials before they are commited and pushed to production, closing common intrusion paths that lead to data breaches.
