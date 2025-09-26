# Task 1

## Summary of security benefits by signing commits

Commit signatures allow anyone to verify that the author of the commit is who
they claim they are. Anyone can set
```bash
git config user.name 'Richard Stallman'
git config user.email 'ric123@mail.ru'
```
But it would be impossible to forge the signature of the real Richard Stallman
without having his private keys.

## SSH key evidence

I already had a few SSH keys that GitHub knows of: `ls ~/.ssh` outputs
```
authorized_keys
id_ed25519
id_ed25519_innop
id_ed25519_innop.pub
id_ed25519.pub
id_rsa
id_rsa.pub
known_hosts
known_hosts.old
```

I decided to use the `id_ed25519_innop` key pair; here is the public key:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBzC5rm0B2NSqDWbpTMsvtsV2rhIMoELLbtlJebChC0q t.usmanov@innopolis.university
```

## Analysis: "Why is commit signing critical in DevSecOps workflows?"        

Signed commits are impossible to forge. Therefore, attackers cannot push
malicious code to production if the repository's branches are configured to
reject unverified commits. This is critical: if there is no such configuration,
arbitrary code could be pushed and then probably executed if someone gets
unauthorized access to the repository.

## Screenshots
![Verified commit](/labs/submission3/verified.png)
