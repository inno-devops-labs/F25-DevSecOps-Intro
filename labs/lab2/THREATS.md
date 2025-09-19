# THREATS.md — Juice Shop Lab

## Context
Local OWASP Juice Shop deployment in a Docker container (`bkimminich/juice-shop:19.0.0`).  
Users connect via browser on port 3000 or optionally through a reverse proxy with TLS and security headers.  
The application may persist logs/files on a host volume and send outbound requests to Email/SMS or webhook providers.  

Trust boundaries:
- Internet -> Host  
- Host -> Container Network  

---

## Top 5 Risks

| # | Title | STRIDE Category | Severity | Description | Mitigations |
|---|-------|-----------------|----------|-------------|-------------|
| 1 | Unencrypted traffic tampering | **Tampering** | High | Data between browser and server could be intercepted or modified if TLS is not enforced. | Require HTTPS via reverse proxy, set HSTS headers, block plaintext connections. |
| 2 | Injection and crafted payloads | **Tampering** | High | Attacker may inject SQL, XSS, or malicious payloads through crafted HTTP requests. | Input validation, parameterized queries, sanitization, WAF filters. |
| 3 | Data leakage from storage | **Information Disclosure** | High | Sensitive logs or user data could be exposed if volumes are world-readable or misconfigured. | Restrict storage access, enforce encryption at rest, audit log access. |
| 4 | Denial of Service attack | **Denial of Service** | High | Attacker could overload the container by sending a flood of requests, consuming CPU/memory. | Rate limiting, autoscaling, resource quotas in Docker/Kubernetes. |
| 5 | Spoofed user identity | **Spoofing** | Medium | An attacker could impersonate a legitimate user by forging session cookies or tokens. | Enforce strong authentication (JWT signatures, session expiry, TLS). |

---

## Notes
- All threats were generated using Threat Dragon’s STRIDE rule engine and triaged manually.  
- Risks are prioritized based on severity and relevance to a local Docker deployment.  
- Mitigations highlight realistic steps for securing the Juice Shop environment.
