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

1. Login SQL injection enables the attacker to access any user account while only knowing the username
	- [Corresponding GitHub issue](https://github.com/DmitriyProkopyev/F25-DevSecOps-Intro/issues/1)
2. Login credentials bruteforce enables the attacker to access any user account if the username is known and the password is weak
	- [Corresponding GitHub issue](https://github.com/DmitriyProkopyev/F25-DevSecOps-Intro/issues/2)
3. Reverse password lookup enables the attacker to acquire the password of any user if the credentials storage (hashes) is leaked or a JWT token (regardless of expiration date) is stolen, and the password is weak
	- [Corresponding GitHub issue](https://github.com/DmitriyProkopyev/F25-DevSecOps-Intro/issues/3)

___

# PR Template Setup

PR markdown template was created according to the lab specifications:

```markdown
## Goal


## Changes


## Testing


## Artifacts & Screenshots


## Checklist
- [ ] Clear title provided
- [ ] Documentation updated if needed
- [ ] No secrets or large temporary files included
```

To verify the template, a pull request from the fork's `feature/lab1` branch to the fork's `main` branch was created. As expected, the template was autofilled:

![](https://i.ibb.co/84RFNFvH/Pasted-image-20251009183204.png)

> PR templates enhance the development teams ability to follow the established guidelines and rules for contributing changes to the codebase. Due to this effect the team lead / tech lead will have a greater control over the development process and thus a greater ability to deliver the expected results.

