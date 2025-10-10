# Task 1
## SAST Tool Effectiveness
* capabilities
* coverage
## Critical Vulnerability Analysis

5 key SAST findings with file locations and severity levels:

1. SQL Injection: /src/data/static/codefixes/dbSchemaChallenge_1.ts - HIGH
severity: ERROR

2. JWT hard-coded credential: /src/lib/insecurity.ts
severity: WARNING

3. Found data from an Express or Next web request flowing to `eval`: /src/routes/userProfile.ts
severity: ERROR

4. User data flows into the host portion of this manually-constructed HTML: /src/routes/chatbot.ts
severity: WARNING

5. The application processes user-input, this is passed to res.sendFile: /src/routes/quarantineServer.ts
severity: WARNING


# Task 2

- ZAP findings: 15
- Nuclei findings: 22
- Nikto findings: 14
- SQLmap findings: 2

### Zap
Search common web vulnerabilities

Example: 
- CORS Misconfiguration \
severity: Medium. \
Description: <p>This CORS misconfiguration could allow an attacker to perform AJAX queries to the vulnerable website from a malicious page loaded by the victim's user agent.</p><p>In order to perform authenticated AJAX queries, the server must specify the header \"Access-Control-Allow-Credentials: true\" and the \"Access-Control-Allow-Origin\" header must be set to null or the malicious page's domain. Even if this misconfiguration doesn't allow authenticated AJAX requests, unauthenticated sensitive content can still be accessed (e.g intranet websites).</p><p>A malicious page can belong to a malicious website but also a trusted website with flaws (e.g XSS, support of HTTP without TLS allowing code injection through MITM, etc).</p>
					

### Nuclei
Mostly on web vulnerabilities

Example:
 - Prometheus metrics page was detected. \
severity: medium \
Description: Prometheus metrics accesible on http://localhost:3000/metrics

### Nikto
Detects outdated server software, vulnerabilities, and misconfigurations

Example:
 - GET //ftp/: File/dir '/ftp/' in robots.txt returned a non-forbidden or redirect HTTP code (200) \
 Description: Web server is allowing access to the /ftp/ directory, which may not align with desired security policies.

### SQLmap
Focused on sql injection vulnerabilities

Example:
 - Time-based blind: \
`SQLite > 2.0 AND time-based blind (heavy query)
    Payload: q=apple%' AND 2458=LIKE(CHAR(65,66,67,68,69,70,71),UPPER(HEX(RANDOMBLOB(500000000/2)))) AND 'nqUo%'='nqUo` \
    Description: This SQL injection payload demonstrates a sophisticated attempt to exploit a SQLite database through a time-based blind injection technique. 
