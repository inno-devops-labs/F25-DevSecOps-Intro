# **Lab 9 — Falco and OPA Security Analysis**

## **Part 1: Falco Runtime Security**

### Baseline Alerts

1) **Terminal Shell in Container.** Falco detected that an interactive shell was spawned inside the running container:

    ```
        A shell was spawned in a container with an attache terminal 
        rule=Terminal shell in container 
        container=lab9-helper 
        user=root 
        process="sh -lc echo hello-from-shell"
    ```

Interactive shell access inside a container is unusual in production and often indicates debugging, misuse, or a potential compromise. Attackers frequently spawn shells to explore or modify the environment

2) **Container Drift – Write Under a Binary Directory.** A write operation to /usr/local/bin triggered Falco’s built-in drift detection rule:

    ```
    Write below binary dir detected 
    container=lab9-helper 
    file=/usr/local/bin/drift.txt
    ```

/usr/local/bin should contain only trusted executables. Writes here indicate “container drift” — unauthorized runtime modifications that may signal tampering, persistence mechanisms, or malware deployment

### Custom Rule Purpose 

This rule is designed to detect any file creation or modification under /usr/local/bin inside a container.Since this directory usually contains static binaries, any write operation is suspicious and may indicate:

- unauthorized drift or tampering

- dropped malicious binaries

**When the Rule Should Fire**

The rule triggers only when all of these conditions are true:

- A write-related syscall occurs: open, openat, openat2, or creat

- The file is opened with write permissions

- The file path starts with /usr/local/bin/

- The writer is a process inside a container, not on the host

**When the Rule Should Not Fire**

- Reads or non-write operations

- Writes to other directories (/tmp, /app, /var/log, etc.)

- Files written on the host rather than inside a container

- Containers with a read-only root filesystem (cannot write)

## Task 2 — Conftest Policy Analysis

The unhardened deployment contains multiple security and reliability issues. Conftest reported:

- 2 warnings

- 8 failures

## Violations summary

| **Violation** | **Description** | **Why It Matters for Security** |
| --- | --- | --- |
| Missing `livenessProbe` | No liveness check has been defined | Kubernetes won’t be able to detect when an application is stuck in a deadlock or has crashed. This reduces the system’s resilience and can allow compromised or non-functional pods to keep running, posing a security risk. |
| Missing `readinessProbe` | No readiness check has been defined | If there’s no readiness probe, traffic might be sent to a pod that isn’t fully ready to handle requests. This can lead to errors for users and potentially expose partially initialized services, which could be exploited. |
| Missing `resources.limits.cpu` | There’s no upper limit set for CPU usage | Without a CPU limit, a container might consume an excessive amount of CPU resources. This could lead to a denial-of-service situation for other workloads and poor isolation between tenants in a multi-tenant environment. |
| Missing `resources.limits.memory` | There’s no upper limit set for memory usage | If a pod consumes too much memory without any limits, it might get killed by the OOM (Out of Memory) killer, which can disrupt service availability. This scenario can also be exploited by attackers to exhaust system memory. |
| Missing `resources.requests.cpu` | No minimum CPU requirement has been declared | Without specifying a minimum CPU request, the scheduler might place a pod on a node that doesn’t have enough CPU resources available. This can result in the pod not functioning properly due to resource starvation. |
| Missing `resources.requests.memory` | No minimum memory requirement has been declared | If there’s no memory request specified, a pod might end up on a node with insufficient memory. This can cause instability and unpredictable behaviour in the application. |
| `allowPrivilegeEscalation` not set to `false` | The option to escalate privileges is still allowed | If privilege escalation is allowed, attackers could exploit setuid binaries or kernel vulnerabilities to gain higher-level privileges, compromising the system further. |
| `readOnlyRootFilesystem` not set to `true` | The root filesystem can be written to | A writable root filesystem allows attackers to modify system binaries, install malware, or establish a persistent presence within the container, which can lead to long-term compromises. |
| `runAsNonRoot` not set to `true` | The container is running with root (UID 0) privileges | Running a container as root increases the impact of a container breakout or misconfiguration. If an attacker gains access, they’ll have elevated privileges, making the breach more severe. |
| Uses `:latest` image tag | The image version isn’t pinned to a specific tag | Using the `:latest` tag means the system might pull in unverified or unexpected image versions. This introduces supply-chain risks, can lead to inconsistent deployments, and makes it harder to audit and track changes. |

### Hardening Changes

| **Issue Fixed** | **Hardened Configuration** | **How It Satisfies the Policy / Improves Security** |
| --- | --- | --- |
| Missing `livenessProbe` | Added `livenessProbe` with appropriate HTTP or TCP checks | By adding a liveness probe, Kubernetes can automatically detect when an application is unresponsive or stuck. This allows the system to restart faulty containers, improving overall resilience and ensuring that compromised or non-functional pods are not allowed to continue running. |
| Missing `readinessProbe` | Added `readinessProbe` to monitor the application’s readiness status | The readiness probe ensures that a pod only starts receiving traffic once it is fully operational and ready to handle requests. This prevents users from encountering errors and reduces the risk of exposing partially initialized services that could be vulnerable to attacks. |
| No CPU/memory limits | Added `resources.limits.cpu` and `resources.limits.memory` to set upper bounds | Defining resource limits prevents any single container from consuming excessive resources, which mitigates the risk of denial-of-service attacks against other workloads. It also enforces fair resource usage across tenants and helps maintain stable performance in a multi-tenant environment. |
| No CPU/memory requests | Added `resources.requests.cpu` and `resources.requests.memory` to specify minimum requirements | Specifying resource requests helps the Kubernetes scheduler place pods on nodes with sufficient resources, ensuring that applications have the necessary CPU and memory to function properly. This reduces the likelihood of performance instability and resource starvation issues. |
| `allowPrivilegeEscalation` allowed | Set `allowPrivilegeEscalation: false` in the security context | By disabling privilege escalation, the system blocks attackers from exploiting setuid binaries or kernel features to gain higher-level privileges. This limits an attacker’s ability to move laterally within the system and abuse elevated permissions. |
| Writable root filesystem | Set `readOnlyRootFilesystem: true` in the security context | Making the root filesystem read-only prevents attackers from modifying system binaries, installing malware, or making persistent changes to the container. This significantly reduces the risk of long-term compromises and unauthorized access. |
| Container ran as root | Added `runAsNonRoot: true` (and optionally `runAsUser` to specify a non-root UID) | Running the container process as a non-root user significantly reduces the impact of a potential breakout or misconfiguration. If an attacker gains access, they will not have elevated privileges, limiting the damage they can cause. |
| Image used `:latest` tag | Replaced `:latest` with a specific, pinned image tag (e.g., `juice:vX.Y.Z`) | Using a pinned image tag ensures that the same, verified version of the container image is used in every deployment. This provides consistency, makes it easier to audit and track changes, and protects against the risk of pulling in malicious or unintended updates from the image registry. |

### Docker Compose Security Checks

```
15 tests, 15 passed
```

This indicates that the Compose deployment obeys the policy requirements:

- no privileged containers

- no latest tag

- no writable host paths

- proper user settings

- secure volume usage

**Docker Compose** environment passes all hardening checks
