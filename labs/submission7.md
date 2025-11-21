## Task 1

### Top 5 Critical/High Vulnerabilities

- **CVE-2023-37903**
	- Affected package: vm2 (npm)
	- Severity: Critical (CVSS 9.8)
	- Impact: Remote Code Execution (RCE)
- **CVE-2023-37466**
	- Affected package: vm2 (npm)
	- Severity: Critical (CVSS 9.8)
	- Impact: Remote Code Execution (RCE)
- **CVE-2023-32314**
	- Affected package: vm2 (npm)
	- Severity: Critical (CVSS 9.8)
	- Impact: Remote Code Execution (RCE)[](https://www.twingate.com/blog/tips/cve-2023-37466)​
- **CVE-2019-10744**
	- Affected package: lodash (npm)
	- Severity: Critical (CVSS 9.8)
	- Impact: Remote Code Execution (Sandbox Escape)
- **CVE-2020-8203**
	- Affected package: lodash (npm)
	- Severity: Critical (CVSS 7.4)
	- Impact: Prototype Pollution

### Configuration Assessment

> Despite the task statement, `dockle` results suggest that Juice Shop v19.0.0 is relatively well configured:

```bash
docker run --rm --user root \
  -v /var/run/docker.sock:/var/run/docker.sock \
  goodwithtech/dockle:latest \
  bkimminich/juice-shop:v19.0.0 | tee scanning/dockle-results.txt
SKIP    - DKL-LI-0001: Avoid empty password
        * failed to detect etc/shadow,etc/master.passwd
INFO    - CIS-DI-0005: Enable Content trust for Docker
        * export DOCKER_CONTENT_TRUST=1 before docker pull/build
INFO    - CIS-DI-0006: Add HEALTHCHECK instruction to the container image
        * not found HEALTHCHECK statement
INFO    - DKL-LI-0003: Only put necessary files
        * unnecessary file : juice-shop/node_modules/extglob/lib/.DS_Store
        * unnecessary file : juice-shop/node_modules/micromatch/lib/.DS_Store
```

- **FATAL/WARN** issues about running as root
	- Not found, images since **v7.3.0** do not run as root
- Exposed secrets in environment variables
	- Not found
- Missing security configurations
	- Not found
- File permission issues
	- Nor found

### Security Posture Assessment

> Does the image run as root?
 
- According to `dockle` scan results, no

> What security improvements would you recommend?

The key security improvement is to upgrade the vulnerable dependencies as recommended by Snyk:

```snyk scan result
  Upgrade check-dependencies@1.1.1 to check-dependencies@2.0.0 to fix
  ✗ Excessive Platform Resource Consumption within a Loop [High Severity][https://security.snyk.io/vuln/SNYK-JS-BRACES-6838727] in braces@2.3.2
    introduced by check-dependencies@1.1.1 > findup-sync@2.0.0 > micromatch@3.1.10 > braces@2.3.2
  ✗ Prototype Pollution [High Severity][https://security.snyk.io/vuln/SNYK-JS-UNSETVALUE-2400660] in unset-value@1.0.0
    introduced by check-dependencies@1.1.1 > findup-sync@2.0.0 > micromatch@3.1.10 > snapdragon@0.8.2 > base@0.11.2 > cache-base@1.0.1 > unset-value@1.0.0 and 4 other path(s)

  Upgrade express-jwt@0.1.3 to express-jwt@6.0.0 to fix
  ✗ Authorization Bypass [High Severity][https://security.snyk.io/vuln/SNYK-JS-EXPRESSJWT-575022] in express-jwt@0.1.3
    introduced by express-jwt@0.1.3
  ✗ Directory Traversal [High Severity][https://security.snyk.io/vuln/SNYK-JS-MOMENT-2440688] in moment@2.0.0
    introduced by express-jwt@0.1.3 > jsonwebtoken@0.1.0 > moment@2.0.0
  ✗ Uninitialized Memory Exposure [High Severity][https://security.snyk.io/vuln/npm:base64url:20180511] in base64url@0.0.6
    introduced by jsonwebtoken@0.4.0 > jws@0.2.6 > base64url@0.0.6 and 3 other path(s)
  ✗ Authentication Bypass [High Severity][https://security.snyk.io/vuln/npm:jsonwebtoken:20150331] in jsonwebtoken@0.1.0
    introduced by express-jwt@0.1.3 > jsonwebtoken@0.1.0 and 1 other path(s)
  ✗ Forgeable Public/Private Tokens [High Severity][https://security.snyk.io/vuln/npm:jws:20160726] in jws@0.2.6
    introduced by jsonwebtoken@0.4.0 > jws@0.2.6 and 1 other path(s)

  Upgrade jsonwebtoken@0.4.0 to jsonwebtoken@5.0.0 to fix
  ✗ Uninitialized Memory Exposure [High Severity][https://security.snyk.io/vuln/npm:base64url:20180511] in base64url@0.0.6
    introduced by jsonwebtoken@0.4.0 > jws@0.2.6 > base64url@0.0.6 and 3 other path(s)
  ✗ Authentication Bypass [High Severity][https://security.snyk.io/vuln/npm:jsonwebtoken:20150331] in jsonwebtoken@0.1.0
    introduced by express-jwt@0.1.3 > jsonwebtoken@0.1.0 and 1 other path(s)
  ✗ Forgeable Public/Private Tokens [High Severity][https://security.snyk.io/vuln/npm:jws:20160726] in jws@0.2.6
    introduced by jsonwebtoken@0.4.0 > jws@0.2.6 and 1 other path(s)

  Upgrade multer@1.4.5-lts.2 to multer@2.0.2 to fix
  ✗ Uncaught Exception [High Severity][https://security.snyk.io/vuln/SNYK-JS-MULTER-10773732] in multer@1.4.5-lts.2
    introduced by multer@1.4.5-lts.2
  ✗ Uncaught Exception [High Severity][https://security.snyk.io/vuln/SNYK-JS-MULTER-10185673] in multer@1.4.5-lts.2
    introduced by multer@1.4.5-lts.2
  ✗ Missing Release of Memory after Effective Lifetime [High Severity][https://security.snyk.io/vuln/SNYK-JS-MULTER-10185675] in multer@1.4.5-lts.2
    introduced by multer@1.4.5-lts.2
  ✗ Uncaught Exception [Critical Severity][https://security.snyk.io/vuln/SNYK-JS-MULTER-10299078] in multer@1.4.5-lts.2
    introduced by multer@1.4.5-lts.2

  Upgrade pdfkit@0.11.0 to pdfkit@0.12.2 to fix
  ✗ Use of Weak Hash [High Severity][https://security.snyk.io/vuln/SNYK-JS-CRYPTOJS-6028119] in crypto-js@3.3.0
    introduced by pdfkit@0.11.0 > crypto-js@3.3.0

  Upgrade sanitize-html@1.4.2 to sanitize-html@1.7.1 to fix
  ✗ Code Injection [High Severity][https://security.snyk.io/vuln/SNYK-JS-LODASH-1040724] in lodash@2.4.2
    introduced by sanitize-html@1.4.2 > lodash@2.4.2
  ✗ Prototype Pollution [High Severity][https://security.snyk.io/vuln/SNYK-JS-LODASH-450202] in lodash@2.4.2
    introduced by sanitize-html@1.4.2 > lodash@2.4.2
  ✗ Prototype Pollution [High Severity][https://security.snyk.io/vuln/SNYK-JS-LODASH-608086] in lodash@2.4.2
    introduced by sanitize-html@1.4.2 > lodash@2.4.2
  ✗ Prototype Pollution [High Severity][https://security.snyk.io/vuln/SNYK-JS-LODASH-6139239] in lodash@2.4.2
    introduced by sanitize-html@1.4.2 > lodash@2.4.2
  ✗ Prototype Pollution [High Severity][https://security.snyk.io/vuln/SNYK-JS-LODASH-73638] in lodash@2.4.2
    introduced by sanitize-html@1.4.2 > lodash@2.4.2

  Upgrade socket.io@3.1.2 to socket.io@4.7.0 to fix
  ✗ Denial of Service (DoS) [High Severity][https://security.snyk.io/vuln/SNYK-JS-WS-7266574] in ws@7.4.6
    introduced by socket.io@3.1.2 > engine.io@4.1.2 > ws@7.4.6
  ✗ Uncaught Exception [High Severity][https://security.snyk.io/vuln/SNYK-JS-SOCKETIO-7278048] in socket.io@3.1.2
    introduced by socket.io@3.1.2
  ✗ Denial of Service (DoS) [High Severity][https://security.snyk.io/vuln/SNYK-JS-ENGINEIO-3136336] in engine.io@4.1.2
    introduced by socket.io@3.1.2 > engine.io@4.1.2
```

## Task 2

### Audit of Docker host configuration against CIS Docker Benchmark

#### Total Counts

- PASS: 28;
- WARN: 22;
- FAIL: 0;
- INFO: 64;

#### Concise Coverage of Weak Points

- **Issue:** Without a dedicated filesystem, the Docker root can fill up and take the host down or hinder incident response due to log/data contention​
	- Remediation: Separate partition for /var/lib/docker from the rest of the system
- **Issue:** Lateral movement is easier when containers can talk freely over the default bridge; hardening requires disabling default ICC or isolating workloads by network
	- Remediation: Restrict inter-container communications on default bridge
- **Issue:** Container root may map to host root, increasing blast radius of escapes and file permission risks; userns-remap reduces this by mapping to an unprivileged host UID/GID​
	- Remediation: Enable user namespaces
- **Issue:** No policy gate on Docker API actions means any user with daemon access can perform sensitive operations without plugin-based allow/deny controls
	- Remediation: Enable authorization for client commands
- **Issue:** Daemon restarts can disrupt workloads and increase unplanned downtime; enabling live-restore preserves running containers across daemon outages
	- Remediation: Enable live restore
- **Issue:** Userland proxy can introduce unnecessary complexity and exposure paths in port publishing; disabling reduces attack surface in favor of kernel NAT​
	- Remediation: Disable userland proxy not
- **Issue:** Without no_new_privs, setuid/setcap binaries or exec transitions could elevate privileges inside containers if combined with other weaknesses
	- Remediation: Enforce “no new privileges”
- **Issue:** Unsigned images increase supply-chain risk
	- Remediation: Enable docker content trust


## Task 3

### Configuration Comparison Table

| Characteristic / Hardening Level    | default                               | hardened                                                        | production                                                             |
| ----------------------------------- | ------------------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Capabilities (dropped/added)        | None dropped, all enabled, not secure | All dropped, none enabled, more secure                          | All dropped, none enabled, more secure                                 |
| Security options                    | no protections                        | enforces `[no-new-privileges]`, preventing privelege escalation | uses strict seccomp profile, whitelisting safer system calls           |
| Resource limits (memory, CPU, PIDs) | no limits on resources and processes  | memory usage constrained to 512 MiB                             | memory usage restricted to 512 MiB, process spawning restricted to 100 |
| Restart policy                      | does not restart                      | does not restart                                                | restarts on failure, improving availability                            |

### Security Measure Analysis

Research and explain EACH security flag:

**a) `--cap-drop=ALL` and `--cap-add=NET_BIND_SERVICE`**

> `--cap-drop` flag restricts specified capabilities for a process, while `--cap-add` grants them

- What are Linux capabilities?
	- Answer: Linux capabilities are fine-grained permission units used in alignment with the least privilege principle. Using them instead of running processes as `root` significantly reduces impact surface.
- What attack vector does dropping ALL capabilities prevent?
	- Answer: Privilege escalation. Without any privileged action, processes cannot operate outside of their own scope.
- Why do we need to add back NET_BIND_SERVICE?
	- Answer: Juice Shop app listens on some port < 1024, and this binding would fail without `NET_BIND_SERVICE` capability, since binding to ports below 1024 is considered to be a privileged action
- What's the security trade-off?
	- Answer: Restricting capabilities reduces impact surface of an attack on the given process, but it also limits the process'es flexibility and requires extra time investment to hand-pick minimally sufficient capabilities

**b) `--security-opt=no-new-privileges`**

- What does this flag do?
	- Answer: It prevents a process from gaining any more privileges than what it started with by setting 'no new privileges' Linux bit
- What type of attack does it prevent?
	- Answer: Privilege escalation via `setuid/setgid` usage
- Are there any downsides to enabling it?
	- Answer: Legitimate processes can be broken by this limitation if they used runtime privilege acquisition, however this is a discouraged practice nowadays, so actual downsides tend to zero as time passes

**c) `--memory=512m` and `--cpus=1.0`**

- What happens if a container doesn't have resource limits?
	- Answer: When no limits are enforced, a single process can consume all resources, starving the other processes and possible destabilizing the host system by triggering the memory
- What attack does memory limiting prevent?
	- Answer: Memory limiting can prevent denial of service (DoS) attacks by stopping the system from allocating too many resources for a process and thus destabilising the system
- What's the risk of setting limits too low?
	- Answer: Resource limits also act as scalability limits. If set too low, they will make the system unavailable when the users are more active then anticipated.

**d) `--pids-limit=100`**

- What is a fork bomb?
	- Answer: It is a method of causing denial of service by making the process infinitely replicate itself to overwhelm the operating system and prevent the legitimate service from running
- How does PID limiting help?
	- Answer: The `--pids-limit` flag enforces a hard limit on the number of processes a given process can spawn, thus making infinite replication impossible
- How to determine the right limit?
	- Answer: The limit needs to be sufficiently higher than the normally observed maximum number of child processes, but also significantly lower than the number of processes the system cannot handle. Best to determine experimentally based on the usage predictions and actual load per process.

**e) `--restart=on-failure:3`**

- What does this policy do?
	- Answer: It tells docker to restart the container up to three times in the event of failure (non 0 exit code). If the container exits successfully (0 exit code) or dies more than three times, docker will mark this container as stopped
- When is auto-restart beneficial? When is it risky?
	- Answer: It is beneficial for services with minimal side effects and low to moderate resource consumption in production environment, to ensure maximum availability. However, if a service produces side effects (like changing a database or overwriting files), is currently being debugged, or consumes a lot of resources, constant restarts might lead to data corruption, confusion in development, or system instability respectively
- Compare `on-failure` vs `always`
	- Answer: `on-failure` policy restarts the container in case of a failure (non 0 exit code), while `always` restarts the container whenever it stopped regardless of the reason

### Critical Thinking Questions

1. **Which profile for DEVELOPMENT? Why?**
	- Answer: 
		- Allow all capabilities for convenience OR limit capabilities in advance to avoid accidentally building logic which relies on dangerous capabilities, but be careful not to hinder debugging tools
		- Skip security options to avoid breaking the debugging tools
		- Do NOT set resource limits to avoid killing development and debugging tools
		- Disable restarts to avoid confusion during debugging
2. **Which profile for PRODUCTION? Why?**
	- Answer:
		- Hand pick the necessary capabilities and disable everything else to minimize attack impact and privilege escalation surface
		- Skip security options to avoid breaking the debugging tools
		- Set strict resource limits to protect against DoS attacks but be careful to not hinder dynamic scalability
		- Set `always` restart policy for lightweight no-side-effects background services and `on-failure` restart policy for everything else
3. **What real-world problem do resource limits solve?**
	- Answer: Resource limits allow DevOps engineers to ensure system stability in high-load conditions where the system load can spike AND it allows cloud services to effectively isolate the client deployments from each other to minimize cross-environment-impact in case of an attack or load spike
4. **If an attacker exploits Default vs Production, what actions are blocked in Production?**
	- Answer: Production profile, unlike development profile, prevents privilege escalation and DoS attacks, which would endanger the entire system. Therefore, the key difference is enhanced protection of the host system
5. **What additional hardening would you add?**
	- Answer: I would additionally enforce non-root run for all containers, read only filesystem for static volumes (or I would separate static volumes from those expected to be changed), use minimal base images to minimize attack surface, use a dedicated secret management tool instead of raw environment variables, and setup a monitoring system if the environment is suitable and the performance limits are not too strict
