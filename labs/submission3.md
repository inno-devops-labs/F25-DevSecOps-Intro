# Task 1
## 1. Benefits of signing commits for security

Using unsigned commit is unsafe because everyone could use commands ```git config user.name "YourName"``` and email to make changes from your account name or rewrite history of repository by using ```git push --force```. CI/CD pipeline also in danger of attacks from random user, which could be signed as an owner of project.  

Signed commits gives oppotunity to have verifired commits with badge (only you from your device could get this badge in your own repository). 

Signature contains also hash of content of the commit. So if someone will change even 1 byte of information - the whole commit will be invalid.

Also we could add the rule to allow only signed commits to CI/CD pipeline, what gives more reliable system and guarantee that unsecure code will not come to production.  

In open sourse projects hard to detect replacement if there is no signatures, but adding verification of commits resolve this pronlem, because all commits of owner is checked by verified badge



## 2. Evidence of successful config
```
marinalavrova@MacBook-Pro-Marina F25-DevSecOps-Intro % git config --global user.name
mc_lavrushka
marinalavrova@MacBook-Pro-Marina F25-DevSecOps-Intro % git config --global user.email
mc.lavrushka@gmail.com
marinalavrova@MacBook-Pro-Marina F25-DevSecOps-Intro % git config --global gpg.format
ssh
marinalavrova@MacBook-Pro-Marina F25-DevSecOps-Intro % git config --global user.signingkey
/Users/marinalavrova/.ssh/id_ed25519.pub
marinalavrova@MacBook-Pro-Marina F25-DevSecOps-Intro % git config --global commit.gpgSign
true
```

## 3. Why is commit signing critical in DevSecOps workflows?"

DevSecOps is a worklow, when we try integrate security in each step of development lifecycle.  
So, the commits is an inseparable part of development and to provide more reliable workflow is crutial to sign commits. First of all to prevent fake commits and change of commits from the third parties. 
Also it is good for CI/CD pipeline, becuase it also part of development and we want to make it secure. So, the adding the rule to allow only signed commits will give us guarantee that only our team could publish code to production. 