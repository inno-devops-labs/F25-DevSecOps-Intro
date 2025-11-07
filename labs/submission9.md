# Lab 9 — Falco Runtime Detection + Conftest Policies

## Environment
- OS: Windows 11 + WSL2 (Ubuntu 24.04.3)
- Docker Desktop (WSL integration), Docker Engine 27.5.1
- Kernel: 6.6.87.2-microsoft-standard-WSL2
- Falco: 0.42.1 (container `falcosecurity/falco:latest`)
- Conftest: `openpolicyagent/conftest:latest`

---

## Task 1 — Falco Runtime Detection

### How Falco was launched
- `--privileged`
- mounts: `/proc:/host/proc:ro`, `/var/run/docker.sock:/host/var/run/docker.sock`, rules: `/etc/falco/rules.d`
- options: `-U`, `-o json_output=true`, `-o time_format_iso_8601=true`
- logs: `labs/lab9/falco/logs/falco.log`
(WSL2: TOCTOU-mitigation warnings — детекция работает)

### Baseline alerts (evidence)
- **Terminal shell in container**: зафиксировано на `lab9-helper` (`alpine:3.19`, `sh -lc echo hello-from-shell`).
- **Custom rule /usr/local/bin write**: `Write Binary Under UsrLocalBin`, файл `/usr/local/bin/custom-rule.txt`.

### Custom rule
`labs/lab9/falco/rules/custom-rules.yaml` — правило на запись под `/usr/local/bin`, перезагрузка `SIGHUP`, алерт получен.

### Event generator (subset)
- Directory traversal read `/etc/shadow`
- Clear Log Activities
- Fileless execution via memfd_create (CRITICAL)
- Netcat RCE pattern
- Drop & execute new binary in container (CRITICAL)

---

## Task 2 — Conftest (OPA/Rego 1.0)

### Policies
- `k8s-security.rego`: deny privileged container; deny отсутствие `runAsNonRoot`.
- `compose-security.rego`: deny привилегированный сервис.

### Manifests
- K8s: `juice-unhardened.yaml` (плохой), `juice-hardened.yaml` (хороший)
- Compose: `juice-compose.yml` (плохой)

### Results (fact)
- Unhardened: **FAIL** (2 deny)
- Hardened: **PASS** (0 failures)
- Compose: **FAIL** (1 deny)
Полные логи: `labs/lab9/analysis/conftest-*.txt`.

---

## Conclusion
Falco на WSL2 корректно ловит интерактивные шеллы, записи в чувствительные пути и подозрительные паттерны. Кастомное правило валидировано. Rego 1.0 политики через Conftest блокируют очевидные мисконфиги (privileged, отсутствие runAsNonRoot) для K8s/Compose.
