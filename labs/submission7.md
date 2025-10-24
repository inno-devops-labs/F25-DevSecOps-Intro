# Task 1

### Snyk issues

It was difficult to make Snyk scanning work. There is no information on what SNYK_TOKEN is. Here is what I did, apart
from signing up on Snyk:

1. Downloaded snyk on my machine with the command (is on their website, under "CLI Integration"):
```bash
curl https://static.snyk.io/cli/latest/snyk-linux -o snyk
chmod +x ./snyk
```
2. Ran `./snyk auth`, authenticated.
3. Found the config file in `~/.config/configstore/snyk.json`.
4. Ran the command from the lab, substituting the `-e SNYK_TOKEN` option with
```bash
-v ~/.config/configstore/snyk.json:/root/.config/configstore/snyk.json:ro
```

That worked.

### Top-5 security vulnerabilities

| CVE ID         | Affected Package | Severity | Impact                    |
|----------------|------------------|----------|---------------------------|
| CVE-2023-37903 | npm/vm2          | CRITICAL | OS command injection      |
| CVE-2023-37466 | npm/vm2          | CRITICAL | JS code injection         |
| CVE-2023-32314 | npm/vm2          | CRITICAL | General injection         |
| CVE-2019-10744 | npm/lodash       | CRITICAL | Prototype pollution       |
| CVE-2015-9235  | npm/jsonwebtoken | CRITICAL | Improper input validation |

### Dockle configuration findings

No FATAL or WARN findings. Check /labs/lab7/scanning/dockle-results.txt.

### Security Posture Assessment

Messages about root privileges are absent. It appears that the image does not run as root;
`docker image inspect bkimminich/juice-shop:v19.0.0` reports that the user is "65532".

# Task 2

### Summary statistics

| Severity | Count |
| -------- | ----- |
| PASS     | 24    |
| WARN     | 36    |
| FAIL     | 0     |
| INFO     | 87    |

Final score is 9.

### Analysis of Failures

No failures detected.

# Task 3

### Issues with the default seccomp profile

On my machine, the command for the `juice-production` container was returning an error:
```
opening seccomp profile (default) failed: open default: no such file or directory
```
So I downloaded the default profile from
`https://raw.githubusercontent.com/docker/labs/master/security/seccomp/seccomp-profiles/default.json` and used that
file.

### Configuration comparison table

| Container        | CapDrop    | SecurityOpt                        | Memory    | CPU | PIDs       | Restart    |
|------------------|------------|------------------------------------|-----------|-----|------------|------------|
| juice-default    | <no value> | <no value>                         | 0         | 0   | <no value> | no         |
| juice-hardened   | [ALL]      | [no-new-privileges]                | 536870912 | 0   | <no value> | no         |
| juice-production | [ALL]      | [no-new-privileges seccomp={....}] | 536870912 | 0   | 100        | on-failure |

### Security Measure Analysis

**a) `--cap-drop=ALL` and `--cap-add=NET_BIND_SERVICE`**
#### What are Linux capabilities? (Research this!)

According to `man capabilities`, capabilities are the various privileges of the `root` user which can be
independently granted to processes. This allows more granular control over permissions.

#### What attack vector does dropping ALL capabilities prevent?

This is the basic principle of least privilege. If the container is compromised, it prevents the attacker from causing
more harm.

#### Why do we need to add back NET_BIND_SERVICE?

According to `man capabilities`, CAP_NET_BIND_SERVICE allows a process to bind to a port less than 1024, e.g. system
ports. It is required to bind to port 80 (HTTP).

#### What's the security trade-off?

This makes the container able to bind to other ports, which may be undesirable.

**b) `--security-opt=no-new-privileges`**
#### What does this flag do? (Look it up!)

According to `man docker-run`, this option disables container processes from gaining additional privileges (from using
sudo).

#### What type of attack does it prevent?

It prevents privilege escalation where a process can escape to the host system.

#### Are there any downsides to enabling it?

The processes in the container will not be able to access some privileged functionality. Which is not really a downside.

OWASP recommends to always use this option in
`https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html`.

**c) `--memory=512m` and `--cpus=1.0`**
#### What happens if a container doesn't have resource limits?

In that case it can potentially DOS the system.

#### What attack does memory limiting prevent?

The kind of DOS attack where the process consumes all memory on the system and either slows it down or triggers the OOM
killer.

#### What's the risk of setting limits too low?

If the limit is too low, the container process may run out of the available memory.

**d) `--pids-limit=100`**
#### What is a fork bomb?

A fork bomb is a process that keeps forking (multiplying) and exhausts the available memory and process pool.

#### How does PID limiting help?

It sets a limit on how many processes can be spawned within the container so that the system is not overwhelmed.

#### How to determine the right limit?

I guess the only way is to analyze the behavior of the containerized application and see how many processes it spawns
usually.

**e) `--restart=on-failure:3`**
#### What does this policy do?

It means that the container restarts automatically if it returns a nonzero status, but no more than 3 times.
(`man docker-run`)

#### When is auto-restart beneficial? When is it risky?

It is good when the application can sometimes crash for reasons we cannot fix. But it is risky when there is a
persistent error that prevents the process from starting, in which case the container will keep restarting, consuming
resources.

#### Compare `on-failure` vs `always`

`on-failure` means that the container restarts when its main process exits with a nonzero status. `always` restarts
regardless of the exit status.

### Critical Thinking Questions

1. **Which profile for DEVELOPMENT? Why?**

For development, convenience is desirable. However, some things that work on the default (baseline) profile may break in
the production profile because of heavy restrictions. Therefore, I think that the hardened (the second) profile is
sufficient for development purposes.

2. **Which profile for PRODUCTION? Why?**

Of course, in production, we must make sure that the system is as secure as possible, so the last (production) profile
is probably ideal.

3. **What real-world problem do resource limits solve?**

They help against DOSing the host system, be it with RAM, CPU, or PID exhaustion.

4. **If an attacker exploits Default vs Production, what actions are blocked in Production?**

The attacker will not be able to:
- Escalate own privileges (--security-opt=no-new-privileges) and enter other containers or the host system
- DOS the system (--memory, --cpus, --pids-limit)
- Use any capabilities (--cap-drop=ALL) except listening on system ports (--cap-add=NET_BIND_SERVICE)

5. **What additional hardening would you add?**

I would remove all unneeded system utilities from the production image.
