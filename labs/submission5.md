## SAST tool effectiveness

1) Tools demonstrated precise analysis of dataflow and parameterized queries. It detected multiple possible injections

2) The analysis provides front-end template coverage allowing XSS prevention

3) Analysis detected Open Redirect issues, showing good detection level for common misconfigurations and dangerous patterns in production

## Five critical findings

1) SQL injection via Sequelize raw queries **(HIGH)**. Multiple files construct SQL with string concatenation/template literals using user-controlled criteria, enabling injection. Locations: `dbSchemaChallenge_1.ts, dbSchemaChallenge_3.ts, unionSqlInjectionChallenge_1.ts, unionSqlInjectionChallenge_3.ts, routes/login.ts, routes/search.ts`

2) Open redirect in Express **(HIGH)**. Redirect target derived directly from user-supplied input without validation. Locations: `routes/redirect.ts`

3) Path traversal **(HIGH)**. User input influences paths passed to res.sendFile, risking arbitrary file reads. Locations: `routes/fileServer.ts, routes/keyServer.ts, routes/logfileServer.ts, routes/quarantineServer.ts`

4) Unsafe code execution via eval **(CRITICAL)**. Request-derived data reaches eval, allowing arbitrary code execution. Locations: `routes/userProfile.ts`

5) XSS via unquoted template attributes **(HIGH)**. Template variables used unquoted in attributes permit handler injection. Locations: `navbar.component.html, purchase-basket.component.html, search-result.component.html, and dataErasureForm.hbs`

## Tool Comparison

```
ZAP findings: 16
Nuclei findings: 22
Nikto findings: 14
SQLmap: 1
```

**Nuclei** has the most findings

## Tool Strengths

1) **ZAP**. Shows good results at automated end-to-end testing. Scans a broad variaty of OWASP vulnerabilities, provies deteiled description

2) **Nuclei**. Fast template-driven tool to scan common vulnerabilities like exposed exposed .env files. High speed makes it good for CI/CD pipelines or for cases where the scanning of multiple targets is needed

3) **Nikto**. Runs comprehensive tests against targets to identify exposed content, version-specific flaws, and risky HTTP options. Good for constant scanning on the server side

4) **SQLmap**. Looks for SQL injection points, traverses endpoints. Good for DB hardening and security

## DAST Findings

1) **ZAP**: backup file exposure. The file `http://localhost:3000/ftp/quarantine` is available by the URL. The vulnerability allows attacker to access backups of the app from several enpoints

2) **Nuclei**: path traversal. Via unsafely passing user input to `res.sendFile` allows arbitrary file reads outside the intended directories

3) **Nikto**: directory exposure. `/ftp/` appears directly accessible and was highlighted both from robots.txt and direct probing

4) **SQLmap**: sql injection risk. The scan indicates SQL injection risk on the search endpoint GET `http://localhost:3000/rest/products/search`, parameter q

## SAST vs DAST Findings

**SAST** provided a good analysis of static content exposure and code-level issues: secrets exposure, HTML risks, injexctions

**DAST** showed runtime vulnerabilities: headers misconfiguration, SQL injections

`Thus, SAST is good static analysis tool for static code scanning and DAST is a dynamic tool suitable for runtime vulnerabilities scanning`

## Integrated Security Recommendations

We may conclude that **SAST** is suitable for build-time pipeline checks. It will detect and expose code-level issues. Combined with automated E2E **DAST** scanning inside some custom environment for pre-release stages it will provide strong security for the application
