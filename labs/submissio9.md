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
