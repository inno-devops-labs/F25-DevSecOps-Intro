# Lab 9 

## Task 1

### Evidence (baseline alerts observed)
Below are representative Falco alert lines copied from labs/lab9/falco/logs/falco.log showing the BusyBox helper container activity.

- Terminal shell in container (spawned shell inside helper):
```log
2025-11-07T15:43:29.873137308Z: Notice A shell was spawned in a container with an attached terminal | ... container_name=lab9-helper ... proc.cmdline="sh -lc echo hello-from-shell"
```

- Custom rule triggered when writing under /usr/local/bin (first write):
```log
2025-11-07T15:46:54.319108606Z: Warning Falco Custom: File write in /usr/local/bin (container=lab9-helper user=root file=/usr/local/bin/drift.txt flags=O_LARGEFILE|O_TRUNC|O_CREAT|O_WRONLY|FD_UPPER_LAYER)
```

- Custom rule triggered again for validation write:
```log
2025-11-07T15:47:02.792481161Z: Warning Falco Custom: File write in /usr/local/bin (container=lab9-helper user=root file=/usr/local/bin/custom-rule.txt flags=O_LARGEFILE|O_TRUNC|O_CREAT|O_WRONLY|O_F_CREATED|FD_UPPER_LAYER)
```

### Custom rule purpose
Rule name: Binary W Under UsrLocalBin

Purpose:
- Detect attempts to write/create files under /usr/local/bin inside any container, which is a common sign of container drift or post-deployment tampering (dropping binaries/scripts into binary paths).

Core logic (summary):
- Trigger on open/openat/openat2/creat events when opened for write
- fd.name startswith /usr/local/bin/
- container.id != host

This arises a WARNING when a process inside a container writes to /usr/local/bin.

### When the rule should fire
- Should fire when any process inside a container creates or writes a file under /usr/local/bin (suspicious for added/modified binaries).
- Expected during troubleshooting if a legitimate init process or CI step intentionally places binaries there — those should be accounted for with tuning or allowlists.

### When the rule should NOT fire (tuning guidance)
- Do not fire for known, trusted containers that legitimately manage /usr/local/bin (add explicit container.name or image allowlist).
- Avoid noisy alerts from ephemeral build containers by excluding images/names used for builds:
  - Example exclude condition: container.image.repository in ( "builder-image" ) or container.name in ( "ci-builder" )
- Optionally require user.name != "root" or add process filter to reduce false positives if writes by package managers are expected.
- Consider lowering priority to NOTICE or adding a rate limit/throttle in downstream alerting to reduce noise.

### Quick operational notes
- Falco auto-reloads rules from /etc/falco/rules.d; if changes aren't picked up, send SIGHUP to the Falco container:
  docker kill --signal=SIGHUP falco && sleep 2
- Validation performed:
  - Started helper container (alpine:3.19)
  - Triggered shell spawn -> observed "Terminal shell in container" notice
  - Wrote to /usr/local/bin inside container -> custom rule fired twice (drift and custom validation)

### Minimal next steps / recommendations
- Add allowlist exclusions for known builders or legitimate images to avoid false positives.
- Decide alert routing (Slack/Email/SIEM) and set severity mapping for this custom rule.
- Keep evidence lines (above) in the lab PR for grading.

## Task 2: Policy-as-Code with Conftest (Rego)

### Policy violations from unhardened manifest

Based on `conftest-unhardened.txt`, the unhardened manifest fails 8 critical security policies:

**Critical Failures (FAIL):**
1. **`:latest` tag usage** - Using `bkimminich/juice-shop:latest` creates deployment instability and security risks since "latest" can change unpredictably
2. **Missing `runAsNonRoot: true`** - Container runs as root (UID 0), violating principle of least privilege and enabling privilege escalation attacks
3. **Missing `allowPrivilegeEscalation: false`** - Allows processes to gain more privileges than parent, enabling container breakout scenarios
4. **Missing `readOnlyRootFilesystem: true`** - Writable filesystem enables malware persistence, log tampering, and runtime modifications
5. **Missing capability drops** - Container retains all Linux capabilities instead of dropping ALL, violating least privilege
6. **Missing CPU requests/limits** - No resource constraints allow resource exhaustion attacks (CPU starvation, noisy neighbor)
7. **Missing memory requests/limits** - Unbounded memory usage can crash nodes via OOM conditions

**Warnings (WARN):**
8. **Missing readiness/liveness probes** - No health checks prevent detection of application failures and proper traffic routing

### Hardening changes in compliant manifest

Comparing `juice-unhardened.yaml` vs `juice-hardened.yaml`, the following security improvements were applied:

**Image Security:**
- Changed from `bkimminich/juice-shop:latest` → `bkimminich/juice-shop:v19.0.0` (pinned version)

**Security Context Hardening:**
```yaml
securityContext:
  runAsNonRoot: true                    # Forces non-root user execution
  allowPrivilegeEscalation: false       # Prevents privilege escalation
  readOnlyRootFilesystem: true          # Makes filesystem immutable
  capabilities:
    drop: ["ALL"]                       # Removes all Linux capabilities
```

**Resource Management:**
```yaml
resources:
  requests: { cpu: "100m", memory: "256Mi" }  # Guaranteed resources
  limits:   { cpu: "500m", memory: "512Mi" }  # Maximum resource caps
```

**Health Monitoring:**
```yaml
readinessProbe:
  httpGet: { path: /, port: 3000 }      # Traffic routing decisions
livenessProbe:
  httpGet: { path: /, port: 3000 }      # Container restart decisions
```

**Security Impact:**
- **Defense in depth**: Multiple security layers prevent single points of failure
- **Attack surface reduction**: Minimal capabilities and read-only filesystem limit exploitation
- **Resource isolation**: Prevents resource-based DoS attacks
- **Operational reliability**: Health checks ensure service availability

### Docker Compose manifest analysis

Based on `conftest-compose.txt`: **All 15 tests passed** with no violations.

The Docker Compose security policy (`compose-security.rego`) enforces:

**Hard Requirements (deny):**
- Explicit non-root user specification
- Read-only root filesystem (`read_only: true`)
- Drop ALL capabilities (`cap_drop: ["ALL"]`)

**Recommendations (warn):**
- Enable `no-new-privileges` security option

**Result:** The provided Docker Compose manifest properly implements all required security controls, demonstrating that containerized applications can achieve security compliance across both Kubernetes and Docker Compose deployment models.

**Key Insight:** Policy-as-code ensures consistent security baselines regardless of orchestration platform, preventing configuration drift and human error in security-critical settings.
