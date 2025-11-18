# Lab 12 — Kata Containers: VM-backed Container Sandboxing

## Task 1 — Install and Configure Kata

### 1.1 Kata Runtime Installation

**Kata Containers Shim Version:**
```bash
containerd-shim-kata-v2 --version
```
```
Kata Containers containerd shim (Rust): id: io.containerd.kata.v2, version: 3.23.0, commit: 74254cba8f299e0bd76a60fd7e0da7cbeaf4b29f
```

### 1.2 Containerd Configuration and Test

**Successful Kata Container Test:**
```bash
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 uname -a
```
```
Linux 1c41279c1487 6.12.47 #1 SMP Fri Nov 14 15:34:06 UTC 2025 x86_64 Linux
```

## Task 2 — Run and Compare Containers (runc vs kata)

### Juice Shop Health Check
```bash
curl -s -o /dev/null -w "juice-runc: HTTP %{http_code}\n" http://localhost:3012
```
```
juice-runc: HTTP 200
```
 **Status**: Juice Shop application successfully running under runc runtime

### Kata Containers Execution
```bash
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 uname -a
```
```
Linux 0afd9bbec1bd 6.12.47 #1 SMP Fri Nov 14 15:34:06 UTC 2025 x86_64 Linux
```
 **Status**: Kata containers running successfully with `--runtime io.containerd.kata.v2`

### Kernel Version Comparison

**Runc (uses host kernel):**
```
6.14.0-35-generic
```

**Kata (uses separate guest kernel):**
```
6.12.47
```

### CPU Model Comparison

**Host CPU (real hardware):**
```
12th Gen Intel(R) Core(TM) i7-1255U
```

**Kata VM CPU (virtualized):**
```
Intel(R) Xeon(R) Processor
```

### Isolation Implications

**Runc Isolation:**
- Shared host kernel (6.14.0-35-generic)
- Namespace-based process isolation
- Container processes visible on host
- Direct hardware access
- Lower security boundary - potential kernel escapes
- Better performance, faster startup

**Kata Isolation:**
- Separate guest kernel (6.12.47) in lightweight VM
- Hardware-level virtualization boundary
- Complete process isolation from host
- Virtualized CPU and hardware
- Strong security - prevents kernel escapes
- Higher overhead, slower startup



## Task 3 — Isolation Tests

### dmesg Access Test
```bash
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 dmesg 2>&1 | head -5
```
```
[    0.000000] Linux version 6.12.47 (@4bcec8f4443d) (gcc (Ubuntu 11.4.0-1ubuntu1~22.04.2) 11.4.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #1 SMP Fri Nov 14 15:34:06 UTC 2025
[    0.000000] Command line: reboot=k panic=1 systemd.unit=kata-containers.target systemd.mask=systemd-networkd.service root=/dev/vda1 rootflags=data=ordered,errors=remount-ro ro rootfstype=ext4 agent.container_pipe_size=1 console=ttyS1 agent.log_vport=1025 agent.passfd_listener_port=1027 virtio_mmio.device=8K@0xe0000000:5 virtio_mmio.device=8K@0xe0002000:5
[    0.000000] BIOS-provided physical RAM map:
[    0.000000] BIOS-e820: [mem 0x0000000000000000-0x000000000009fbff] usable
```

 **Kata shows VM boot logs** - proves separate kernel environment

### /proc Filesystem Visibility
```
Host: 417
Kata VM: 52
```

**Kata has significantly fewer /proc entries** - isolated process namespace

### Network Interfaces
```bash
sudo nerdctl run --rm --runtime io.containerd.kata.v2 alpine:3.19 ip addr
```
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether ea:29:d0:7d:3b:06 brd ff:ff:ff:ff:ff:ff
    inet 10.4.0.15/24 brd 10.4.0.255 scope global eth0
       valid_lft forever preferred_lft forever
```

 **Kata has isolated network stack** with virtual interface (eth0) and private IP (10.4.0.15)

### Kernel Modules Count
```
Host kernel modules: 351
Kata guest kernel modules: 72
```

 **Kata uses minimal kernel modules** - reduced attack surface

### Isolation Boundary Differences

**Runc Isolation:**
- Shared kernel with host
- Process namespace isolation only
- Direct /proc filesystem access
- Shared network stack (with namespace separation)
- Full kernel module visibility

**Kata Isolation:**
- Separate guest kernel in lightweight VM
- Hardware-level virtualization boundary
- Isolated /proc filesystem (VM-specific)
- Dedicated virtual network stack
- Minimal kernel modules (reduced surface)

### Security Implications

**Container Escape in Runc:**
- **Impact**: Full host compromise
- **Attack Path**: Kernel exploit → host kernel access
- **Risk Level**: High - direct host kernel exposure

**Container Escape in Kata:**
- **Impact**: VM escape required first
- **Attack Path**: VM escape → then container escape
- **Risk Level**: Low - VM boundary provides strong isolation
- **Protection**: Requires breaking hardware virtualization


## Task 4 — Performance Comparison

### Startup Time Comparison

**Runc Startup Time:**
```
Executed in  361.65 millis
```

**Kata Startup Time:**
```
Executed in  956.17 millis
```

 **Runc**: ~0.36 seconds startup time
 **Kata**: ~0.96 seconds startup time (2.6x slower)

### HTTP Latency Baseline (juice-runc)

**Results for port 3012 (juice-runc):**
```
avg=0.0018s min=0.0010s max=0.0070s n=50
```

 **Average latency**: 1.8ms
 **Minimum latency**: 1.0ms  
 **Maximum latency**: 7.0ms
 **Consistent performance**: Low variance across 50 requests

### Performance Tradeoffs Analysis

**Startup Overhead:**
- **Runc**: Minimal overhead (~0.36s) - direct container startup
- **Kata**: Significant overhead (~0.96s) - VM boot + container startup
- **Impact**: 2.6x slower container initialization

**Runtime Overhead:**
- **Runc**: Near-native performance, minimal runtime penalty
- **Kata**: VM hypervisor overhead, but optimized for steady-state
- **Impact**: Once running, performance gap narrows significantly

**CPU Overhead:**
- **Runc**: Direct CPU access, minimal virtualization overhead
- **Kata**: Hypervisor layer adds ~1-5% CPU overhead
- **Impact**: Acceptable for most workloads, noticeable in CPU-intensive tasks

### Runtime Recommendations

**Use Runc When:**
- Performance-critical applications
- Fast container startup required
- Trusted workloads and environments
- Resource-constrained environments
- Development and testing environments

**Use Kata When:**
- Multi-tenant environments with untrusted workloads
- Strong security isolation requirements
- Compliance with strict security standards
- Hostile workload isolation
- Production environments requiring VM-level security

