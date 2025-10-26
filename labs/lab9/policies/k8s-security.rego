package k8s.security

# Helper: true if array arr contains value v
has_value(arr, v) if {
  some i
  arr[i] == v
}

# No :latest tags
deny contains msg if {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  endswith(c.image, ":latest")
  msg := sprintf("container %q uses disallowed :latest tag", [c.name])
}

# Require essential securityContext settings
deny contains msg if {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not c.securityContext.runAsNonRoot
  msg := sprintf("container %q must set runAsNonRoot: true", [c.name])
}

deny contains msg if {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not c.securityContext.allowPrivilegeEscalation == false
  msg := sprintf("container %q must set allowPrivilegeEscalation: false", [c.name])
}

deny contains msg if {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not c.securityContext.readOnlyRootFilesystem == true
  msg := sprintf("container %q must set readOnlyRootFilesystem: true", [c.name])
}

deny contains msg if {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not has_value(c.securityContext.capabilities.drop, "ALL")
  msg := sprintf("container %q must drop ALL capabilities", [c.name])
}

# Require CPU/Memory requests and limits
deny contains msg if {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not c.resources.requests.cpu
  msg := sprintf("container %q missing resources.requests.cpu", [c.name])
}

deny contains msg if {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not c.resources.requests.memory
  msg := sprintf("container %q missing resources.requests.memory", [c.name])
}

deny contains msg if {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not c.resources.limits.cpu
  msg := sprintf("container %q missing resources.limits.cpu", [c.name])
}

deny contains msg if {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not c.resources.limits.memory
  msg := sprintf("container %q missing resources.limits.memory", [c.name])
}

# Recommend probes
warn contains msg if {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not c.readinessProbe
  msg := sprintf("container %q should define readinessProbe", [c.name])
}

warn contains msg if {
  input.kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not c.livenessProbe
  msg := sprintf("container %q should define livenessProbe", [c.name])
}
