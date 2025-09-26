## SSH Commit Signature Verification 
### How to verify the commit
Create new key for authentification:
```
F25-DevSecOps-Intro on  feature/lab3 [?] 
❯ ssh-keygen -t rsa -C "saddog.sec@gmail.com"
Generating public/private rsa key pair.
Enter file in which to save the key (/home/saddog/.ssh/id_rsa): /home/saddog/.ssh/id_rsa_git
Enter passphrase for "/home/saddog/.ssh/id_rsa_git" (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/saddog/.ssh/id_rsa_git
Your public key has been saved in /home/saddog/.ssh/id_rsa_git.pub
The key fingerprint is:
```
Read the public part of the key and add it to github, then:
```
F25-DevSecOps-Intro on  feature/lab3 [?] 
❯ git config --global user.signingkey /home/saddog/.ssh/id_rsa_git

F25-DevSecOps-Intro on  feature/lab3 [?] 
❯ git config --global commit.gpgSign true

F25-DevSecOps-Intro on  feature/lab3 [?] 
❯ git config --global gpg.format ssh


F25-DevSecOps-Intro on  feature/lab3 [?] 
❯ vim labs/submission3.md

F25-DevSecOps-Intro on  feature/lab3 [?] 
❯ git add labs/submission3.md 

F25-DevSecOps-Intro on  feature/lab3 [+?] 
❯ git commit -S -m "docs: add commit signing summary"
[feature/lab3 8b55b7e] docs: add commit signing summary
 1 file changed, 23 insertions(+)
 create mode 100644 labs/submission3.md

F25-DevSecOps-Intro on  feature/lab3 [?⇡] 
❯ git push origin feature/lab3
Enumerating objects: 6, done.
Counting objects: 100% (6/6), done.
Delta compression using up to 8 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 1.71 KiB | 1.71 MiB/s, done.
Total 4 (delta 1), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (1/1), completed with 1 local object.
To github.com:saddogsec/F25-DevSecOps-Intro.git
   25a969e..8b55b7e  feature/lab3 -> feature/lab3
```

<img width="1891" height="669" alt="image" src="https://github.com/user-attachments/assets/0a6e2828-9872-4b7a-92e1-143752478579" />

### Why commits must be verified
The main reasons, why signing commits is important is authencity and accountability. The signed commit cannot be tampered with. And assuming the owner of key didn't leaked it(In such case different mechanisms used), there's no good way for malicious actor to do something. Also signing ensures that every commit can be traced down to each person, reducing the risk of insider threat. DevSecOps frameworks usually forbids unsigned commits entirely.

## Pre-commit Secret Scanning
### Setup hook
It's easier to do than fail. Just copy paste into `.git/hooks/pre_commit`
```
F25-DevSecOps-Intro on  feature/lab3 [!?⇡] 
❯ vim .git/hooks/pre-commit


F25-DevSecOps-Intro on  feature/lab3 [!?⇡] 
❯ chmod +x .git/hooks/pre-commit
```
### Verify hook functionality (failed run)
First add some fake token and try to commit it:
```
F25-DevSecOps-Intro on  feature/lab3 [?] took 9s 
❯ echo "Some definitely not fake token: xoxp-1234567890-abcdefghijklmno-0987654321-pqrstuvwxyzabcdef
  " >> labs/submission3.md 

F25-DevSecOps-Intro on  feature/lab3 [+?] 
❯ git commit -S -m "trying to upload token"
[pre-commit] scanning staged files for secrets…
[pre-commit] Files to scan: labs/submission3.md
[pre-commit] Non-lectures files: labs/submission3.md
[pre-commit] Lectures files: none
[pre-commit] TruffleHog scan on non-lectures files…
🐷🔑🐷  TruffleHog. Unearth your secrets. 🐷🔑🐷

2025-09-26T09:55:46Z	info-0	trufflehog	running source	{"source_manager_worker_id": "K6Kdl", "with_units": true}
2025-09-26T09:55:46Z	info-0	trufflehog	finished scanning	{"chunks": 1, "bytes": 989, "verified_secrets": 0, "unverified_secrets": 0, "scan_duration": "2.009416ms", "trufflehog_version": "3.90.8", "verification_caching": {"Hits":0,"Misses":0,"HitsWasted":0,"AttemptsSaved":0,"VerificationTimeSpentMS":0}}
[pre-commit] ✓ TruffleHog found no secrets in non-lectures files
[pre-commit] Gitleaks scan on staged files…
[pre-commit] Scanning labs/submission3.md with Gitleaks...
Gitleaks found secrets in labs/submission3.md:
9:55AM INF scanned ~989 bytes (989 bytes) in 24.9ms
9:55AM WRN leaks found: 1
Finding:     ...definitely not fake token: xoxp-1234567890-abcdefghijklmno-0987654321-pqrstuvwxyzabcdef
Secret:      xoxp-1234567890-abcdefghijklmno-0987654321-pqrstuvwxyzabcdef
RuleID:      generic-api-key
Entropy:     5.094309
File:        labs/submission3.md
Line:        24
Fingerprint: labs/submission3.md:generic-api-key:24
---
✖ Secrets found in non-excluded file: labs/submission3.md

[pre-commit] === SCAN SUMMARY ===
TruffleHog found secrets in non-lectures files: false
Gitleaks found secrets in non-lectures files: true
Gitleaks found secrets in lectures files: false

✖ COMMIT BLOCKED: Secrets detected in non-excluded files.
Fix or unstage the offending files and try again.

```
### Verify hook functionality (successful run)
Remove token from submission3.md and run again
```
F25-DevSecOps-Intro on  feature/lab3 [+?] 
❯ vim labs/submission3.md 

F25-DevSecOps-Intro on  feature/lab3 [!+?] took 7s 
❯ git commit -S -m "trying to upload token"
[pre-commit] scanning staged files for secrets…
[pre-commit] Files to scan: labs/submission3.md
[pre-commit] Non-lectures files: labs/submission3.md
[pre-commit] Lectures files: none
[pre-commit] TruffleHog scan on non-lectures files…
🐷🔑🐷  TruffleHog. Unearth your secrets. 🐷🔑🐷

2025-09-26T09:57:10Z	info-0	trufflehog	running source	{"source_manager_worker_id": "ItPjG", "with_units": true}
2025-09-26T09:57:10Z	info-0	trufflehog	finished scanning	{"chunks": 1, "bytes": 928, "verified_secrets": 0, "unverified_secrets": 0, "scan_duration": "1.64849ms", "trufflehog_version": "3.90.8", "verification_caching": {"Hits":0,"Misses":0,"HitsWasted":0,"AttemptsSaved":0,"VerificationTimeSpentMS":0}}
[pre-commit] ✓ TruffleHog found no secrets in non-lectures files
[pre-commit] Gitleaks scan on staged files…
[pre-commit] Scanning labs/submission3.md with Gitleaks...
[pre-commit] No secrets found in labs/submission3.md

[pre-commit] === SCAN SUMMARY ===
TruffleHog found secrets in non-lectures files: false
Gitleaks found secrets in non-lectures files: false
Gitleaks found secrets in lectures files: false

✓ No secrets detected in non-excluded files; proceeding with commit.
[feature/lab3 489c8c4] trying to upload token
 1 file changed, 1 insertion(+)
```
