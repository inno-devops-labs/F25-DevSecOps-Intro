## Task 1 - SAST

### SAST Tool Effectiveness

The tool reported 25 vulnerabilities in the code. Most of them are HTML- or
SQL-injections, or unsanitized paths.

### Critical Vulnerability Analysis
Below are 5 of the 6 vulnerabilities that have a "HIGH" likelihood AND impact:

1. `/src/data/static/codefixes/dbSchemaChallenge_1.ts`: Detected a sequelize
   statement that is tainted by user-input. This could lead to SQL injection if
the variable is user-controlled and is not properly sanitized. In order to
prevent SQL injection, it is recommended to use parameterized queries or
prepared statements.

2. `/src/data/static/codefixes/dbSchemaChallenge_3.ts`: Detected a sequelize
   statement that is tainted by user-input. This could lead to SQL injection if
the variable is user-controlled and is not properly sanitized. In order to
prevent SQL injection, it is recommended to use parameterized queries or
prepared statements.

3. `src/data/static/codefixes/unionSqlInjectionChallenge_1.ts`: Detected a
   sequelize statement that is tainted by user-input. This could lead to SQL
injection if the variable is user-controlled and is not properly sanitized. In
order to prevent SQL injection, it is recommended to use parameterized queries
or prepared statements.

4. `/src/data/static/codefixes/unionSqlInjectionChallenge_3.ts` Detected a
   sequelize statement that is tainted by user-input. This could lead to SQL
injection if the variable is user-controlled and is not properly sanitized. In
order to prevent SQL injection, it is recommended to use parameterized queries
or prepared statements.

5. `/src/routes/login.ts` Detected a sequelize statement that is tainted by
   user-input. This could lead to SQL injection if the variable is
user-controlled and is not properly sanitized. In order to prevent SQL
injection, it is recommended to use parameterized queries or prepared
statements.

## Task 2 - DAST

### Tool Comparison

| Tool   | Findings |
| ------ | -------- |
| ZAP    | 15       |
| Nuclei | 23       |
| Nikto  | 14       |
| SQLmap | 1        |

This table shows that Nuclei has the most findings. SQLmap has only found 1.

### Tool Strengths

- **SQLmap** looks for possibilities of SQL injection vulnerabilities. It has
found one in the search endpoint.
- **Nuclei** seemingly outputs juice-shop's properties rather than
vulnerabilities.
- **Nikto** finds interesting headers and endpoints.
- **ZAP** actually outputs vulnerabilities.

### DAST Findings

1. **ZAP**: "`"alert": "Bypassing 403"`": There is a way to access a file that
   normally returns 403 FORBIDDEN.
2. **Nuclei**: "`"template":"http/exposures/apis/swagger-api.yaml"`": the
   endpoint `http://localhost:3000/api-docs/swagger.yaml` exposes the API.
3. **Nikto**: "`+ GET //ftp/: File/dir '/ftp/' in robots.txt returned a
   non-forbidden or redirect HTTP code (200)`": The `/ftp/` URL was forbidden in
   `/robots.txt`, but actually was available.
4. **SQLmap**: "`http://localhost:3000/rest/products/search?q=apple,GET,q,BT,`":
   The search endpoint accepts a query that is probably not properly escaped
before putting into an SQL query.

## Task 3

### SAST vs DAST Findings

**SAST** unique findings:
- Hardcoded credentials (in `/src/lib/insecurity.js`)
- Various unescaped HTML
- Path traversal in `/src/router/{keyServer,logfileServer}.ts`

**DAST** unique findings:
- CORS misconfiguration
- Exposed timestamps, inodes of files

### Integrated Security Recommendations

I think the only logical way to use both approachces is to set up a CI/CD
pipeline that checks the code **statically** (SAST) and launches **dynamic**
testing (DAST) in a staging environment on every pull request to a `devel`
branch, for example.
