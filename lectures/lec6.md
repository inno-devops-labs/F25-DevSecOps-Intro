# 📌Lecture 6 - Infrastructure-as-Code Security: Terraform, Pulumi, Ansible & Policy-as-Code

## 📂 Group 1: IaC Foundations

## 📍 Slide 1 – 🌍 What is Infrastructure-as-Code (IaC)?

* 🧩 **Infrastructure-as-Code (IaC)** = managing infrastructure through **machine-readable definition files** rather than manual configuration.
* 📝 Key principle: **"Infrastructure should be versioned, tested, and deployed like application code."**
* ⚡ Core benefits:
  * 🔄 **Repeatability** → deploy identical environments every time
  * 📦 **Version control** → track changes, rollback, audit history
  * 🚀 **Automation** → eliminate manual errors, increase speed
  * 🧪 **Testing** → validate infrastructure before deployment
* 📊 **Industry adoption:** 76% of organizations use IaC in production (HashiCorp State of Cloud Strategy Survey 2024)
* 🔗 **Learn more:** [What is Infrastructure as Code? (HashiCorp)](https://www.hashicorp.com/resources/what-is-infrastructure-as-code), [IaC Best Practices (AWS)](https://docs.aws.amazon.com/whitepapers/latest/introduction-devops-aws/infrastructure-as-code.html)

```mermaid
flowchart LR
    Traditional[🖱️ Manual Configuration<br/>ClickOps, Console] -->|Problems| Issues[❌ Inconsistent<br/>❌ Untracked<br/>❌ Slow]
    IaC[📝 Infrastructure-as-Code<br/>Terraform, Pulumi, Ansible] -->|Benefits| Wins[✅ Repeatable<br/>✅ Versioned<br/>✅ Fast]
    
    style Traditional fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#2c3e50
    style IaC fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#2c3e50
    style Issues fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#2c3e50
    style Wins fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#2c3e50
```

---

### 📈 Evolution Timeline

```mermaid
timeline
    title 🕰️ Infrastructure Management Evolution
    1990s : 🔧 Manual Configuration<br/>Physical servers, manual setup
    2000s : 📜 Shell Scripts<br/>Bash automation, brittle
    2005 : ⚙️ Configuration Management<br/>Puppet, Chef
    2012 : 📦 Ansible Released<br/>Agentless, YAML-based
    2014 : 🏗️ Terraform Released<br/>Declarative, multi-cloud
    2018 : 🚀 Pulumi Released<br/>Real programming languages
    2025 : 🤖 AI-Assisted IaC<br/>Policy-as-code, GitOps
```

---

### 🧩 Declarative vs Imperative

* 🎯 **Declarative (What):**
  * Define **desired end state**
  * Tool figures out **how to get there**
  * Examples: Terraform, CloudFormation, Kubernetes YAML
  * 📝 "I want 3 servers with this config"
* 🛠️ **Imperative (How):**
  * Define **exact steps** to execute
  * Explicit **command sequence**
  * Examples: Bash scripts, Ansible playbooks (can be both)
  * 📝 "Create server 1, then server 2, then server 3"

```mermaid
flowchart TD
    subgraph Declarative
        D1[📋 Desired State - 3 web servers] --> D2[🤖 Tool Calculates Diff]
        D2 --> D3[⚡ Executes Changes]
    end
    
    subgraph Imperative
        I1[📝 Step 1: Create server] --> I2[📝 Step 2: Install nginx]
        I2 --> I3[📝 Step 3: Configure firewall]
    end
    
    style Declarative fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#2c3e50
    style Imperative fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#2c3e50
```

<details>
<summary>💭 <strong>Interactive Quiz:</strong> Is Ansible declarative or imperative?</summary>

**Answer:** **Both!** 🎯

* Ansible playbooks use **declarative modules** (e.g., `state: present`)
* But executed in **imperative order** (top to bottom)
* This makes Ansible a **hybrid approach**
* Often called **"procedural with declarative elements"**

</details>

---

## 📍 Slide 2 – 🚨 Why IaC Security Matters

* 🔥 **Infrastructure misconfigurations = #1 cloud security risk**
  * 67% of cloud breaches stem from misconfigurations (IBM Cost of Data Breach Report 2024)
  * Average breach cost: **$4.88M** (up 10% from 2023)
* 💥 **Major incidents caused by IaC failures:**
  * 🏦 **Capital One (2019):** Misconfigured WAF → 100M records exposed → $190M fine
  * ⚡ **Tesla (2018):** Public Kubernetes dashboard → crypto mining attack
  * 🪣 **Pentagon S3 buckets (2017):** 1.8B social media posts exposed publicly
* ⚠️ **IaC amplifies both security AND insecurity:**
  * ✅ Good config → deployed consistently everywhere
  * ❌ Bad config → replicated across all environments instantly
* 📊 **Attack surface expansion:** IaC tools have access to **everything** (cloud credentials, secrets, production systems)

```mermaid
flowchart TD
    subgraph "❌ Traditional Manual Config"
        M1[Manual Error] --> M2[Single Server Affected]
    end
    
    subgraph "🔥 IaC Without Security"
        I1[Misconfigured Template] --> I2[Automated Deployment]
        I2 --> I3[⚠️ ALL Environments Affected]
        I3 --> I4[💥 Massive Blast Radius]
    end
    
    subgraph "✅ IaC With Security"
        S1[Template with Security Checks] --> S2[Automated Scanning]
        S2 --> S3[❌ Blocks Bad Config]
        S2 --> S4[✅ Deploys Secure Config]
    end
    
    style M1 fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#2c3e50
    style I1 fill:#ffebee,stroke:#d32f2f,stroke-width:3px,color:#2c3e50
    style I4 fill:#ffebee,stroke:#d32f2f,stroke-width:3px,color:#2c3e50
    style S1 fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#2c3e50
    style S4 fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#2c3e50
```

---

### 🎯 Real-World Impact Statistics

* 📊 **95% of cloud breaches** are due to customer misconfigurations, not cloud provider failures (Gartner)
* ⏰ **Average time to detect misconfiguration:** 279 days (IBM)
* 💰 **Cost of remediation:**
  * Fix in development: **$100**
  * Fix in production: **$10,000+**
  * Fix after breach: **$1,000,000+**
* 🔍 **Most common IaC security issues:**
  * 43% → Hardcoded secrets
  * 38% → Overly permissive IAM roles
  * 31% → Unencrypted storage
  * 29% → Public resource exposure

<details>
<summary>💭 <strong>Discussion Question:</strong> Why do you think misconfigurations happen so frequently?</summary>

**Common Reasons:**

1. 🏃‍♂️ **Speed over security** → "Move fast, secure later" mentality
2. 📚 **Complexity** → Cloud services have thousands of configuration options
3. 👥 **Lack of expertise** → Developers learning infrastructure on the fly
4. 🔄 **Copy-paste culture** → Reusing insecure examples from internet
5. 🚫 **No guardrails** → Missing automated security checks in pipelines
6. 👁️ **Visibility gaps** → Hard to audit infrastructure across multiple clouds

**Solution:** Shift-left security + Policy-as-code + Automated scanning!

</details>

---

## 📍 Slide 3 – 📊 IaC Tool Landscape Overview

* 🏗️ **HashiCorp Terraform** (2014)
  * 🌍 Multi-cloud, declarative HCL (HashiCorp Configuration Language)
  * 📦 40,000+ providers, massive ecosystem
  * 🔧 State management with remote backends
  * 💼 Market leader: 67% adoption (CNCF Survey 2024)
* 🚀 **Pulumi** (2018)
  * 💻 Real programming languages (TypeScript, Python, Go, C#, Java)
  * 🔐 Built-in secrets management
  * 🧪 Full testing frameworks (unit, integration)
  * 📈 Growing adoption: 18% (up from 9% in 2023)
* ⚙️ **Ansible** (2012, Red Hat)
  * 🪶 Agentless SSH-based automation
  * 📝 YAML playbooks, imperative + declarative
  * 🔑 Ansible Vault for secrets
  * 🏢 Popular for config management: 52% adoption
* ☁️ **Cloud-Native Tools**
  * 🔶 **AWS CloudFormation** (2011) → JSON/YAML templates
  * 🔵 **Azure Resource Manager (ARM)** (2014) → JSON templates
  * 🔷 **Google Cloud Deployment Manager** (2015) → YAML/Jinja2

```mermaid
flowchart TD
    subgraph "🏗️ Provisioning Tools"
        TF[🏗️ Terraform<br/>Multi-cloud, HCL]
        PU[🚀 Pulumi<br/>Real code, TypeScript/Python]
        CF[☁️ CloudFormation<br/>AWS-native]
    end
    
    subgraph "⚙️ Configuration Management"
        AN[⚙️ Ansible<br/>Agentless, YAML]
        CH[👨‍🍳 Chef<br/>Ruby DSL]
        PU2[🐶 Puppet<br/>Declarative]
    end
    
    subgraph "☸️ Container/K8s"
        K8[☸️ Kubernetes YAML<br/>Declarative manifests]
        HE[⎈ Helm<br/>Templating engine]
        KU[🎨 Kustomize<br/>Overlay system]
    end
    
    Cloud[☁️ Cloud Infrastructure] --> TF
    Cloud --> PU
    Cloud --> CF
    
    Servers[🖥️ Servers/VMs] --> AN
    Servers --> CH
    Servers --> PU2
    
    Containers[🐳 Containers] --> K8[☸️ Kubernetes YAML]
    Containers --> HE
    Containers --> KU
    
    style TF fill:#7B42BC,stroke:#5C2D91,stroke-width:2px,color:#fff
    style PU fill:#8A3FFC,stroke:#6929C4,stroke-width:2px,color:#fff
    style AN fill:#EE0000,stroke:#CC0000,stroke-width:2px,color:#fff
```

---

### ⚖️ Quick Comparison Matrix

| Feature | Terraform | Pulumi | Ansible |
|---------|-----------|--------|---------|
| 🗣️ **Language** | HCL (custom DSL) | TypeScript, Python, Go, C#, Java | YAML |
| 🎯 **Approach** | Declarative | Declarative (with code) | Imperative + Declarative |
| ☁️ **Multi-cloud** | ✅ Best-in-class | ✅ Excellent | ⚠️ Limited |
| 🔧 **Learning curve** | Medium | Medium-High (need programming) | Low-Medium |
| 🧪 **Testing** | Limited (terratest) | ✅ Full unit/integration tests | Medium (molecule) |
| 🔐 **Secrets** | Manual integration | ✅ Built-in encryption | Ansible Vault |
| 📊 **State mgmt** | Remote backends | Pulumi Cloud/self-hosted | No state (idempotent) |
| 💰 **Cost** | Open-source (Cloud paid) | Open-source (Cloud paid) | Open-source (Tower paid) |
| 🏢 **Best for** | Infrastructure provisioning | Modern dev teams | Config management, VMs |

<details>
<summary>💭 <strong>Interactive Question:</strong> Which tool would you choose for a greenfield cloud-native startup?</summary>

**There's no single right answer!** But here's a thought framework:

**Choose Terraform if:**
* ✅ Team is infrastructure-focused
* ✅ Need widest provider ecosystem
* ✅ Declarative mindset preferred
* ✅ Large community and examples available

**Choose Pulumi if:**
* ✅ Team is developer-heavy
* ✅ Want full programming language power
* ✅ Need sophisticated testing
* ✅ Already using TypeScript/Python

**Choose Ansible if:**
* ✅ Managing existing servers/VMs
* ✅ Configuration management is primary need
* ✅ Team prefers simple YAML
* ✅ Want agentless approach

**Modern approach:** Many teams use **Terraform + Ansible** together:
* Terraform provisions infrastructure
* Ansible configures applications

</details>

---

## 📍 Slide 4 – 🔒 Common IaC Security Risks

* 🔑 **Hardcoded Secrets (43% of issues)**
  * API keys, passwords, tokens in plain text
  * Committed to version control → permanent history
  * Attackers scan GitHub for leaked credentials 24/7
  * Example: `aws_access_key = "AKIAIOSFODNN7EXAMPLE"`
* 🔓 **Overly Permissive IAM/RBAC (38%)**
  * `Action: "*"` → grants ALL permissions
  * `Resource: "*"` → applies to ALL resources
  * Service accounts with admin rights
  * No least-privilege enforcement
* 🌍 **Public Exposure (31%)**
  * S3 buckets with public read/write
  * Databases accessible from `0.0.0.0/0`
  * Security groups allowing all ports
  * Load balancers exposing internal services
* 🔐 **Missing Encryption (29%)**
  * Unencrypted storage (S3, EBS, databases)
  * No encryption in transit (HTTP instead of HTTPS)
  * Missing KMS key management
  * Plaintext backups
* 📋 **Compliance Violations (26%)**
  * Missing required tags (cost center, environment)
  * Resources in non-approved regions
  * Violating data residency requirements
  * No audit logging enabled

```mermaid
flowchart TD
    subgraph "🔥 Top IaC Security Risks"
        R1[🔑 Hardcoded Secrets<br/>43%]
        R2[🔓 Overly Permissive IAM<br/>38%]
        R3[🌍 Public Exposure<br/>31%]
        R4[🔐 Missing Encryption<br/>29%]
        R5[📋 Compliance Violations<br/>26%]
    end
    
    R1 -->|Leads to| B1[💥 Credential Theft]
    R2 -->|Leads to| B2[💥 Privilege Escalation]
    R3 -->|Leads to| B3[💥 Data Breach]
    R4 -->|Leads to| B4[💥 Data Exposure]
    R5 -->|Leads to| B5[💥 Regulatory Fines]
    
    B1 --> Impact[🔥 Total Compromise]
    B2 --> Impact
    B3 --> Impact
    B4 --> Impact
    B5 --> Impact
    
    style R1 fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#2c3e50
    style R2 fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#2c3e50
    style R3 fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#2c3e50
    style R4 fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#2c3e50
    style R5 fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#2c3e50
    style Impact fill:#b71c1c,stroke:#d32f2f,stroke-width:3px,color:#fff
```

---

### 💻 Example: Vulnerable Terraform Code

```hcl
# ❌ INSECURE EXAMPLE - DO NOT USE IN PRODUCTION!

# Risk 1: Hardcoded credentials
provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAIOSFODNN7EXAMPLE"  # 🔥 HARDCODED!
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"  # 🔥 LEAKED!
}

# Risk 2: Public S3 bucket
resource "aws_s3_bucket" "data" {
  bucket = "my-company-data"
  acl    = "public-read"  # 🌍 PUBLIC TO THE INTERNET!
}

# Risk 3: Overly permissive security group
resource "aws_security_group" "web" {
  ingress {
    from_port   = 0       # 🔓 ALL PORTS!
    to_port     = 65535   # 🔓 ALL PORTS!
    protocol    = "-1"    # 🔓 ALL PROTOCOLS!
    cidr_blocks = ["0.0.0.0/0"]  # 🌍 FROM ANYWHERE!
  }
}

# Risk 4: Unencrypted database
resource "aws_db_instance" "main" {
  engine         = "postgres"
  storage_encrypted = false  # 🔐 NO ENCRYPTION!
  publicly_accessible = true  # 🌍 PUBLIC DATABASE!
}

# Risk 5: No encryption for EBS volume
resource "aws_ebs_volume" "data" {
  availability_zone = "us-east-1a"
  size              = 100
  encrypted         = false  # 🔐 PLAINTEXT DATA!
}
```

<details>
<summary>💭 <strong>Challenge:</strong> How many security issues can you spot in the above code?</summary>

**Found at least 8 critical issues:**

1. ❌ Hardcoded AWS access key
2. ❌ Hardcoded AWS secret key
3. ❌ Public S3 bucket ACL
4. ❌ Security group allows all ports from anywhere
5. ❌ Database not encrypted
6. ❌ Database publicly accessible
7. ❌ EBS volume not encrypted
8. ❌ No tags for compliance tracking
9. ❌ No backup configuration
10. ❌ No network segmentation

**Real-world impact:** Code like this caused the Capital One breach!

</details>

---

## 📍 Slide 5 – 🧭 IaC in the DevSecOps Pipeline

* 🔄 **Shift-Left Security for Infrastructure**
  * Catch issues **before deployment**, not after breach
  * Test infrastructure code like application code
  * Security as early feedback loop
* 🧪 **IaC Testing Pyramid**
  * 🏗️ **Unit tests** (80%) → syntax, logic, basic checks
  * 🔗 **Integration tests** (15%) → deploy to test env
  * 🌍 **Compliance tests** (5%) → policy validation
* 🚀 **CI/CD Integration Points**
  * 📝 **Pre-commit** → local validation, secret scanning
  * 🔄 **Pull Request** → automated security scans, policy checks
  * 🏗️ **Build stage** → terraform plan, cost estimation
  * 🧪 **Test stage** → deploy to staging, validate
  * 🚀 **Deploy stage** → production deployment with approval
  * 📊 **Runtime** → drift detection, continuous monitoring

```mermaid
flowchart LR
    subgraph "📝 Development"
        Dev[👨‍💻 Write IaC] --> PreCommit[🔍 Pre-commit Hooks]
        PreCommit -->|Secret scan| LocalCheck{✅ Pass?}
        LocalCheck -->|❌ No| Fix[🔧 Fix Issues]
        LocalCheck -->|✅ Yes| Commit[📤 Git Commit]
    end
    
    subgraph "🔄 CI/CD Pipeline"
        Commit --> PR[📋 Pull Request]
        PR --> Scan[🛡️ Security Scan<br/>Checkov/tfsec]
        Scan --> Policy[📜 Policy Check<br/>OPA/Sentinel]
        Policy --> Plan[📊 Terraform Plan]
        Plan --> Review[👀 Manual Review]
        Review -->|✅ Approve| Deploy[🚀 Deploy to Staging]
        Deploy --> Test[🧪 Integration Tests]
        Test -->|✅ Pass| Prod[🌍 Production Deploy]
    end
    
    subgraph "📊 Runtime"
        Prod --> Monitor[📈 Drift Detection]
        Monitor --> Alert[🚨 Security Alerts]
        Alert -->|Issue found| Fix
    end
    
    style PreCommit fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#2c3e50
    style Scan fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#2c3e50
    style Policy fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#2c3e50
    style Prod fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#2c3e50
```

---

### 🔐 GitOps Workflow for Infrastructure

* 📦 **Git as Single Source of Truth**
  * All infrastructure code in version control
  * Pull requests for any changes
  * Automated testing on every commit
* 🔄 **Pull-Based Deployment**
  * Agents watch Git repository
  * Automatically apply approved changes
  * Examples: Flux, ArgoCD (for Kubernetes), Terraform Cloud
* 🛡️ **Security Benefits**
  * 📜 Complete audit trail
  * ↩️ Easy rollback to any previous state
  * 🔍 Drift detection (actual vs desired state)
  * 🚫 No direct production access needed

```mermaid
flowchart LR
    subgraph "📂 Git Repository"
        Code[📝 IaC Code<br/>Terraform/Pulumi]
        Policy[📋 Policies<br/>OPA/Sentinel]
    end
    
    subgraph "🔄 GitOps Operator"
        Watch[👁️ Watch for Changes]
        Validate[✅ Validate & Test]
        Apply[⚡ Auto-apply Changes]
    end
    
    subgraph "☁️ Cloud Infrastructure"
        Resources[🏗️ Infrastructure Resources]
        State[📊 Actual State]
    end
    
    Code --> Watch
    Policy --> Watch
    Watch --> Validate
    Validate --> Apply
    Apply --> Resources
    Resources --> State
    State -.Drift Detection.-> Watch
    
    style Code fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#2c3e50
    style Validate fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#2c3e50
    style Resources fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#2c3e50
```

---

### 📊 Security Testing Layers

| Layer | Stage | Tools | Coverage | Speed |
|-------|-------|-------|----------|-------|
| 🧪 **Unit Tests** | Pre-commit | terraform validate, pulumi preview | Syntax, logic | ⚡ Seconds |
| 🔍 **Security Scan** | PR/CI | Checkov, tfsec, Terrascan | Misconfigs, secrets | ⚡ Seconds |
| 📜 **Policy Check** | PR/CI | OPA, Sentinel, Conftest | Compliance rules | ⚡ Seconds |
| 💰 **Cost Estimation** | PR/CI | Infracost, Terraform Cloud | Budget impact | ⚡ Seconds |
| 🏗️ **Integration Test** | Staging | Deploy + validate | Real environment | 🐌 Minutes |
| 🌍 **Runtime Monitor** | Production | Drift detection, CSPM | Continuous | 🔄 Ongoing |

<details>
<summary>💭 <strong>Discussion:</strong> At which stage should security checks happen?</summary>

**Answer: ALL OF THEM!** 🎯

**Defense in Depth approach:**

1. **👨‍💻 Developer's machine (Pre-commit)**
   * Fast feedback loop
   * Catches obvious issues (syntax, secrets)
   * No waiting for CI/CD

2. **🔄 Pull Request (CI/CD)**
   * Automated security scans
   * Policy enforcement
   * Peer review
   * Prevents bad code from merging

3. **🧪 Staging Environment**
   * Real-world testing
   * Integration validation
   * Final check before production

4. **🌍 Production (Runtime)**
   * Continuous monitoring
   * Drift detection
   * Compliance audits
   * Incident response

**Remember:** Security is **not a checkpoint**, it's a **continuous process**!

</details>

---

## 🎉 **Fun Break: Infrastructure Gone Wild!** 

### 😄 **"The $72,000 Cloud Bill Surprise"**

A developer spun up "just a few instances" to test a machine learning model...

* 🤖 Forgot to set instance size limits
* ⚡ Auto-scaling kicked in
* 📈 Scaled to **500+ GPU instances**
* 💸 Bill arrived: **$72,000** for the weekend
* 🏢 Company lesson learned: **Always set budget alerts!**

### 🤯 **IaC Horror Stories:**

* 🪣 **The S3 Bucket of Doom**: Company made bucket "temporarily public" for testing → forgot to revert → 10M customer records exposed
* 🔐 **The Terraform Destroy Disaster**: Junior dev ran `terraform destroy` thinking it was on testing environment → **was production** → entire infrastructure gone
* 🔑 **The GitHub Secret Leak**: Hardcoded AWS keys in Terraform → pushed to public repo → **$20K charged for crypto mining in 2 hours**
* 🚪 **The Open Security Group**: Security group rule `0.0.0.0/0` → **entire database cluster** accessible to internet → ransomware attack

### 💡 **Key Lesson:**

**"Automate security checks, because humans make mistakes... especially at 3 AM during deployments!"** ☕💤

---

🔗 **Resources for Group 1:**
* [Infrastructure as Code Best Practices (AWS)](https://docs.aws.amazon.com/whitepapers/latest/introduction-devops-aws/infrastructure-as-code.html)
* [Terraform Security Best Practices (HashiCorp)](https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables)
* [Cloud Security Misconfigurations (OWASP)](https://owasp.org/www-community/vulnerabilities/Cloud_Infrastructure_Misconfiguration)
* [CIS Benchmarks for Cloud](https://www.cisecurity.org/benchmark/cloud_computing)

---
## 📂 Group 2: Terraform Security

## 📍 Slide 6 – 🏗️ Terraform Deep Dive & Security Concerns

* 🏗️ **Terraform** = declarative IaC tool using HCL (HashiCorp Configuration Language)
* 🔄 **Workflow:** `init` → `plan` → `apply` → `destroy`
* 📊 **State file** = JSON file tracking all managed resources
* ⚠️ **Critical security issue:** State files contain **secrets in plaintext!**
  * Database passwords
  * API keys
  * Private keys
  * Certificate data

```mermaid
flowchart LR
    Write[📝 Write .tf files] --> Init[⚙️ terraform init]
    Init --> Plan[📊 terraform plan]
    Plan --> Apply[⚡ terraform apply]
    Apply --> State[💾 terraform.tfstate]
    State -->|Contains| Secrets[🔑 SECRETS IN PLAINTEXT!]
    
    style State fill:#ffebee,stroke:#d32f2f,stroke-width:3px,color:#2c3e50
    style Secrets fill:#b71c1c,stroke:#d32f2f,stroke-width:3px,color:#fff
```

### 🔥 State File Security Risks

* 💾 **Local state files:**
  * ❌ Stored on developer's laptop (unencrypted)
  * ❌ Can be committed to Git accidentally
  * ❌ No access control
  * ❌ No audit trail
* ☁️ **Remote state backends (BETTER):**
  * ✅ S3 + DynamoDB (with encryption + locking)
  * ✅ Terraform Cloud (built-in security)
  * ✅ Azure Blob Storage (with encryption)
  * ✅ HashiCorp Consul (with ACLs)

```hcl
# ❌ LOCAL STATE (INSECURE)
# terraform.tfstate stored locally - anyone with filesystem access can read secrets!

# ✅ REMOTE STATE WITH ENCRYPTION
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true                    # ✅ Encryption at rest
    dynamodb_table = "terraform-lock"        # ✅ State locking
    kms_key_id     = "arn:aws:kms:..."      # ✅ KMS encryption
  }
}
```

---

## 📍 Slide 7 – 🔑 Managing Secrets in Terraform

### ❌ **Level 1: Hardcoded (NEVER DO THIS)**

```hcl
resource "aws_db_instance" "db" {
  username = "admin"
  password = "SuperSecret123!"  # 🔥 IN VERSION CONTROL FOREVER!
}
```

### ⚠️ **Level 2: Variables (BETTER, but not great)**

```hcl
# variables.tf
variable "db_password" {
  type      = string
  sensitive = true  # Hides from logs
}

# main.tf
resource "aws_db_instance" "db" {
  password = var.db_password
}

# Run with: terraform apply -var="db_password=..."
```

### ✅ **Level 3: Environment Variables (GOOD)**

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

# Terminal:
# export TF_VAR_db_password="secret"
# terraform apply
```

### 🏆 **Level 4: Secret Managers (BEST PRACTICE)**

```hcl
# Retrieve from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}

resource "aws_db_instance" "db" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

```hcl
# Or HashiCorp Vault
data "vault_generic_secret" "db_creds" {
  path = "secret/database/prod"
}

resource "aws_db_instance" "db" {
  username = data.vault_generic_secret.db_creds.data["username"]
  password = data.vault_generic_secret.db_creds.data["password"]
}
```

### 🔄 **Dynamic Secrets (ENTERPRISE LEVEL)**

```hcl
# Vault generates temporary DB credentials
resource "vault_database_secret_backend_role" "app" {
  name    = "app-role"
  backend = vault_mount.db.path
  db_name = "postgres"
  
  creation_statements = [
    "CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}'",
    "GRANT SELECT ON mydb.* TO '{{name}}'@'%'"
  ]
  
  default_ttl = 3600  # 1 hour expiry
  max_ttl     = 7200
}
```

<details>
<summary>💭 <strong>Challenge:</strong> Rank these from most to least secure</summary>

**Ranking (Best to Worst):**

1. 🥇 **Dynamic secrets from Vault** - Short-lived, auto-rotated, audited
2. 🥈 **Secret Manager with rotation** - Centralized, encrypted, rotatable
3. 🥉 **Environment variables** - Not in code, but still long-lived
4. 😐 **Terraform variables with sensitive flag** - Better than nothing
5. 💀 **Hardcoded in .tf files** - NEVER DO THIS!

**Pro tip:** Combine approaches! Use Vault for app secrets, env vars for Terraform API tokens.
</details>

---

## 📍 Slide 8 – 🛡️ Terraform Security Best Practices

### 🔐 **1. State File Security**

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    encrypt        = true          # ✅ AES-256 encryption
    kms_key_id     = "arn:..."     # ✅ Customer managed key
    dynamodb_table = "tf-lock"     # ✅ State locking
    
    # ✅ Bucket policy restricts access
    # ✅ Versioning enabled for rollback
    # ✅ MFA delete enabled
  }
}
```

### 🔒 **2. Provider Version Pinning**

```hcl
# ❌ BAD: Unpinned versions
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"  # Any version! 🔥
    }
  }
}

# ✅ GOOD: Pinned versions
terraform {
  required_version = "~> 1.6.0"  # Terraform version
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Provider version constraint
    }
  }
}
```

### 🏢 **3. Module Security**

```hcl
# ❌ RISKY: Random internet module
module "vpc" {
  source = "github.com/random-user/terraform-vpc"  # 🔥 Untrusted!
}

# ✅ BETTER: Terraform Registry (verified)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"  # Specific version
}

# 🏆 BEST: Private registry or Git with commit hash
module "vpc" {
  source = "git::ssh://git@github.com/mycompany/terraform-modules.git//vpc?ref=v1.2.3"
}
```

### 📂 **4. Environment Separation**

```hcl
# Use workspaces or separate state files
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "${terraform.workspace}/terraform.tfstate"  # dev/staging/prod
  }
}

# Or separate directories with tfvars
# /terraform/dev/terraform.tfvars
# /terraform/staging/terraform.tfvars  
# /terraform/prod/terraform.tfvars
```

### 🔍 **5. Pre-commit Hooks**

```bash
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    hooks:
      - id: terraform_fmt        # ✅ Format code
      - id: terraform_validate   # ✅ Validate syntax
      - id: terraform_tfsec      # ✅ Security scan
      - id: terraform_docs       # ✅ Generate docs

  - repo: https://github.com/gitleaks/gitleaks
    hooks:
      - id: gitleaks             # ✅ Scan for secrets
```

### 📊 **Quick Checklist**

| Practice | Priority | Effort | Impact |
|----------|----------|--------|--------|
| Remote encrypted state | 🔴 Critical | Low | High |
| Secret manager integration | 🔴 Critical | Medium | High |
| Version pinning | 🟡 High | Low | Medium |
| Security scanning (tfsec) | 🟡 High | Low | High |
| State locking | 🟡 High | Low | High |
| Module vetting | 🟢 Medium | Medium | Medium |
| Pre-commit hooks | 🟢 Medium | Low | Medium |

<details>
<summary>💭 <strong>Discussion:</strong> Should you commit terraform.tfstate to Git?</summary>

**ABSOLUTELY NOT! ❌❌❌**

**Why it's dangerous:**
* Contains secrets in plaintext
* Anyone with repo access sees credentials
* Git history preserves old secrets forever
* No access control or audit trail
* Can't handle concurrent modifications

**What to commit:**
* ✅ `.tf` files (infrastructure code)
* ✅ `.tfvars.example` (template, no real values)
* ✅ `README.md` (documentation)
* ❌ `.tfstate` files (add to `.gitignore`)
* ❌ `.tfvars` with real secrets (add to `.gitignore`)
* ❌ `.terraform/` directory (add to `.gitignore`)

**Always use remote state backends!**
</details>

---

## 📍 Slide 9 – 💻 Hands-On: Secure Terraform Workflow

### 🔍 **Step 1: Scan Vulnerable Code**

```hcl
# vulnerable.tf - Find the issues!
resource "aws_s3_bucket" "data" {
  bucket = "company-data"
  acl    = "public-read"
}

resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t2.micro"
  
  metadata_options {
    http_tokens = "optional"  # IMDSv1 enabled
  }
}

resource "aws_security_group" "allow_all" {
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### 🛠️ **Step 2: Run Security Scanners**

```bash
# tfsec - Fast Terraform security scanner
$ tfsec .

Result #1 HIGH AWS S3 bucket is publicly accessible
────────────────────────────────────────────────────
  vulnerable.tf:3
────────────────────────────────────────────────────
   3   acl    = "public-read"
────────────────────────────────────────────────────

Result #2 HIGH Instance Metadata Service v1 enabled
────────────────────────────────────────────────────
  vulnerable.tf:11
────────────────────────────────────────────────────
   11   http_tokens = "optional"
────────────────────────────────────────────────────

Result #3 CRITICAL Security group allows ingress from 0.0.0.0/0
────────────────────────────────────────────────────
  vulnerable.tf:19
────────────────────────────────────────────────────
   19   cidr_blocks = ["0.0.0.0/0"]
────────────────────────────────────────────────────

3 potential problems detected.
```

```bash
# Checkov - Policy-as-code scanner
$ checkov -f vulnerable.tf

Check: CKV_AWS_20: "S3 Bucket has an ACL defined which allows public READ access"
	FAILED for resource: aws_s3_bucket.data
	File: /vulnerable.tf:1-4

Check: CKV_AWS_79: "Ensure Instance Metadata Service Version 1 is not enabled"
	FAILED for resource: aws_instance.web
	File: /vulnerable.tf:6-14

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	FAILED for resource: aws_security_group.allow_all
	File: /vulnerable.tf:16-23
```

### ✅ **Step 3: Fix Security Issues**

```hcl
# secure.tf - Fixed version
resource "aws_s3_bucket" "data" {
  bucket = "company-data"
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t2.micro"
  
  metadata_options {
    http_tokens   = "required"  # ✅ IMDSv2 only
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true  # ✅ Encrypt root volume
  }
}

resource "aws_security_group" "web" {
  name = "web-sg"

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # ✅ VPC only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### 🚀 **Step 4: CI/CD Integration**

```yaml
# .github/workflows/terraform.yml
name: Terraform Security

on: [pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        
      - name: Terraform Init
        run: terraform init -backend=false
        
      - name: Terraform Validate
        run: terraform validate
        
      - name: Run tfsec
        uses: aquasecurity/tfsec-action@v1.0.0
        with:
          soft_fail: false  # ❌ Fail on issues
          
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          framework: terraform
          soft_fail: false  # ❌ Fail on issues
          
      - name: Terraform Plan
        run: terraform plan
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### 📊 **Before vs After Comparison**

| Metric | Before | After |
|--------|--------|-------|
| 🔴 Critical issues | 3 | 0 |
| 🟡 High issues | 5 | 0 |
| 🟢 Medium issues | 12 | 2 |
| ⚡ Scan time | - | 5 seconds |
| ✅ CI/CD pass | ❌ | ✅ |

<details>
<summary>💭 <strong>Exercise:</strong> What other tools would you add to this pipeline?</summary>

**Additional tools to consider:**

1. **Cost estimation:**
   * 💰 Infracost - Estimates cloud costs before deployment
   * Shows cost impact in PR comments

2. **Compliance checks:**
   * 📋 Terraform Compliance - BDD-style policy testing
   * Tests against regulatory requirements

3. **Secrets scanning:**
   * 🔑 Gitleaks - Detect hardcoded secrets
   * TruffleHog - Find secrets in Git history

4. **Drift detection:**
   * 📊 Driftctl - Compare actual vs Terraform state
   * Terraform Cloud - Built-in drift detection

5. **Documentation:**
   * 📝 terraform-docs - Auto-generate README
   * Keeps docs in sync with code

6. **Policy-as-code:**
   * 🎯 OPA/Conftest - Custom policy checks
   * Sentinel - Terraform Cloud policies

**Example enhanced workflow:**
```yaml
- name: Cost Estimation
  run: infracost breakdown --path .
  
- name: Compliance Testing
  run: terraform-compliance -f compliance/ -p plan.json
  
- name: Secrets Scan
  run: gitleaks detect --source . --verbose
```
</details>

---

🔗 **Terraform Security Resources:**
* [Terraform Security Best Practices (HashiCorp)](https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables)
* [tfsec Documentation](https://aquasecurity.github.io/tfsec/)
* [Checkov Policies](https://www.checkov.io/5.Policy%20Index/terraform.html)
* [Terraform AWS Secure Baseline](https://github.com/nozaq/terraform-aws-secure-baseline)

---
## 📂 Group 3: Pulumi Security

## 📍 Slide 10 – 🚀 Pulumi Overview & Security Model

* 🚀 **Pulumi** = IaC using real programming languages (TypeScript, Python, Go, C#, Java)
* 🆚 **vs Terraform:** Code instead of DSL, full programming features, built-in testing
* 🔐 **Built-in secrets encryption** (automatic, no extra config needed)

```typescript
// TypeScript example
import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

const bucket = new aws.s3.Bucket("secure-bucket", {
    acl: "private",
    serverSideEncryptionConfiguration: {
        rule: {
            applyServerSideEncryptionByDefault: {
                sseAlgorithm: "AES256",
            },
        },
    },
});

export const bucketName = bucket.id;
```

```python
# Python example
import pulumi
import pulumi_aws as aws

bucket = aws.s3.Bucket("secure-bucket",
    acl="private",
    server_side_encryption_configuration={
        "rule": {
            "apply_server_side_encryption_by_default": {
                "sse_algorithm": "AES256",
            },
        },
    })

pulumi.export("bucket_name", bucket.id)
```

### 🔑 Automatic Secrets Management

```typescript
// Secrets are automatically encrypted in state!
const config = new pulumi.Config();
const dbPassword = config.requireSecret("dbPassword");  // 🔐 Auto-encrypted

const db = new aws.rds.Instance("db", {
    engine: "postgres",
    password: dbPassword,  // ✅ Encrypted in state
    storageEncrypted: true,
});

// Secret outputs are also encrypted
export const connectionString = pulumi.secret(
    pulumi.interpolate`postgres://admin:${dbPassword}@${db.endpoint}`
);
```

### 🔒 Encryption Options

```bash
# Default: Pulumi service (managed)
$ pulumi stack init prod

# Passphrase (self-managed)
$ pulumi stack init prod --secrets-provider=passphrase
$ export PULUMI_CONFIG_PASSPHRASE="strong-password"

# AWS KMS
$ pulumi stack init prod --secrets-provider="awskms://alias/pulumi-secrets?region=us-east-1"

# Azure Key Vault
$ pulumi stack init prod --secrets-provider="azurekeyvault://myvault.vault.azure.net/keys/pulumi"

# GCP KMS
$ pulumi stack init prod --secrets-provider="gcpkms://projects/my-project/locations/us/keyRings/my-keyring/cryptoKeys/my-key"
```

<details>
<summary>💭 <strong>Quiz:</strong> What happens if you print a secret in Pulumi?</summary>

```typescript
const secret = config.requireSecret("apiKey");
console.log(secret);  // What gets printed?
```

**Answer:** `[secret]` 🔒

Pulumi automatically redacts secrets in:
* Console output
* Logs  
* Stack exports (unless explicitly outputting as secret)
* API responses

**To actually use the value:**
```typescript
secret.apply(value => {
    // value is the actual string here
    // Use it carefully!
});
```

**This prevents accidental leaks!**
</details>

---

## 📍 Slide 11 – 🧩 Pulumi Policy-as-Code (CrossGuard)

* 📋 **CrossGuard** = policy-as-code framework for Pulumi
* 🎯 **Policies:** Mandatory (block) or Advisory (warn)
* 💻 Written in TypeScript or Python

### 📝 Example Policy: Block Public S3 Buckets

```typescript
// policy.ts
import * as aws from "@pulumi/aws";
import { PolicyPack, validateResourceOfType } from "@pulumi/policy";

new PolicyPack("aws-policies", {
    policies: [{
        name: "s3-no-public-read",
        description: "S3 buckets must not be publicly readable",
        enforcementLevel: "mandatory",  // Blocks deployment!
        validateResource: validateResourceOfType(aws.s3.Bucket, (bucket, args, reportViolation) => {
            if (bucket.acl === "public-read" || bucket.acl === "public-read-write") {
                reportViolation("S3 bucket must not have public ACL");
            }
        }),
    }, {
        name: "s3-encryption-required",
        description: "S3 buckets must be encrypted",
        enforcementLevel: "mandatory",
        validateResource: validateResourceOfType(aws.s3.Bucket, (bucket, args, reportViolation) => {
            if (!bucket.serverSideEncryptionConfiguration) {
                reportViolation("S3 bucket must have encryption enabled");
            }
        }),
    }, {
        name: "required-tags",
        description: "Resources must have required tags",
        enforcementLevel: "advisory",  // Just warns
        validateResource: (args, reportViolation) => {
            if (args.type.startsWith("aws:") && !args.props.tags) {
                reportViolation("Resource should have tags");
            }
        },
    }],
});
```

```python
# policy.py
from pulumi_policy import (
    EnforcementLevel,
    PolicyPack,
    ResourceValidationPolicy,
)

def s3_no_public_acl(args, report_violation):
    if args.resource_type == "aws:s3/bucket:Bucket":
        acl = args.props.get("acl")
        if acl in ["public-read", "public-read-write"]:
            report_violation("S3 bucket must not be public")

PolicyPack(
    name="aws-python-policies",
    enforcement_level=EnforcementLevel.MANDATORY,
    policies=[
        ResourceValidationPolicy(
            name="s3-no-public-acl",
            description="S3 buckets cannot be public",
            validate=s3_no_public_acl,
        ),
    ],
)
```

### 🚀 Using Policies

```bash
# Enable policy pack locally
$ pulumi policy enable policy-pack/

# Preview with policies
$ pulumi preview
Previewing update (dev)

Policy Violations:
    ❌ s3-no-public-read (mandatory)
       S3 bucket must not have public ACL
       aws:s3:Bucket (my-bucket)

# Policy blocks deployment!
error: preview failed

# Fix the issue and try again
$ pulumi up
✅ All policies passed!
```

### 📦 Policy Pack Management

```bash
# Publish policy pack to Pulumi Cloud
$ pulumi policy publish org-name/aws-policies

# Enforce organization-wide
$ pulumi policy enable org-name/aws-policies --policy-group production

# Different policies for different stacks
$ pulumi policy enable dev-policies --policy-group development
```

---

## 📍 Slide 12 – 💻 Hands-On: Secure Pulumi Deployment

### 📝 Secure AWS S3 Bucket Example

```typescript
// index.ts - Secure S3 bucket with Pulumi
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

// Get config
const config = new pulumi.Config();
const environment = config.require("environment");
const kmsKeyId = config.requireSecret("kmsKeyId");

// Create KMS-encrypted S3 bucket
const bucket = new aws.s3.Bucket("app-data", {
    acl: "private",
    
    // ✅ Block all public access
    blockPublicAcls: true,
    blockPublicPolicy: true,
    ignorePublicAcls: true,
    restrictPublicBuckets: true,
    
    // ✅ Enable versioning
    versioning: {
        enabled: true,
    },
    
    // ✅ KMS encryption
    serverSideEncryptionConfiguration: {
        rule: {
            applyServerSideEncryptionByDefault: {
                sseAlgorithm: "aws:kms",
                kmsMasterKeyId: kmsKeyId,
            },
            bucketKeyEnabled: true,
        },
    },
    
    // ✅ Lifecycle rules
    lifecycleRules: [{
        enabled: true,
        transitions: [{
            days: 30,
            storageClass: "STANDARD_IA",
        }, {
            days: 90,
            storageClass: "GLACIER",
        }],
    }],
    
    // ✅ Logging
    loggings: [{
        targetBucket: logBucket.id,
        targetPrefix: "s3-access-logs/",
    }],
    
    // ✅ Tags
    tags: {
        Environment: environment,
        ManagedBy: "Pulumi",
        Encrypted: "true",
    },
});

// ✅ Bucket policy - deny unencrypted uploads
const bucketPolicy = new aws.s3.BucketPolicy("app-data-policy", {
    bucket: bucket.id,
    policy: bucket.arn.apply(arn => JSON.stringify({
        Version: "2012-10-17",
        Statement: [{
            Sid: "DenyUnencryptedUploads",
            Effect: "Deny",
            Principal: "*",
            Action: "s3:PutObject",
            Resource: `${arn}/*`,
            Condition: {
                StringNotEquals: {
                    "s3:x-amz-server-side-encryption": "aws:kms"
                }
            }
        }]
    })),
});

// Export (bucketName is public, encryption key is secret)
export const bucketName = bucket.id;
export const bucketArn = bucket.arn;
export const encryptionKey = pulumi.secret(kmsKeyId);
```

### 🧪 Testing Infrastructure Code

```typescript
// index.test.ts - Unit tests for Pulumi
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import "mocha";

pulumi.runtime.setMocks({
    newResource: function(args: pulumi.runtime.MockResourceArgs): {id: string, state: any} {
        return {
            id: args.inputs.name + "_id",
            state: args.inputs,
        };
    },
    call: function(args: pulumi.runtime.MockCallArgs) {
        return args.inputs;
    },
});

describe("S3 Bucket Security", function() {
    let bucket: aws.s3.Bucket;

    before(async function() {
        const infra = await import("./index");
        // Load the infrastructure
    });

    it("bucket must have private ACL", function(done) {
        pulumi.all([bucket.acl]).apply(([acl]) => {
            if (acl !== "private") {
                done(new Error("Bucket must be private"));
            } else {
                done();
            }
        });
    });

    it("bucket must have encryption", function(done) {
        pulumi.all([bucket.serverSideEncryptionConfiguration]).apply(([encryption]) => {
            if (!encryption) {
                done(new Error("Bucket must be encrypted"));
            } else {
                done();
            }
        });
    });

    it("bucket must block public access", function(done) {
        pulumi.all([
            bucket.blockPublicAcls,
            bucket.blockPublicPolicy,
            bucket.ignorePublicAcls,
            bucket.restrictPublicBuckets
        ]).apply(([acls, policy, ignore, restrict]) => {
            if (!acls || !policy || !ignore || !restrict) {
                done(new Error("Bucket must block all public access"));
            } else {
                done();
            }
        });
    });
});
```

### 🚀 CI/CD Integration

```yaml
# .github/workflows/pulumi.yml
name: Pulumi

on:
  pull_request:
    branches: [main]

jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: 18
          
      - name: Install dependencies
        run: npm install
        
      - name: Run tests
        run: npm test
        
      - name: Pulumi Preview
        uses: pulumi/actions@v4
        with:
          command: preview
          stack-name: dev
        env:
          PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          
      - name: Run Policy Check
        run: pulumi policy enable aws-policies && pulumi preview
```

<details>
<summary>💭 <strong>Comparison:</strong> Pulumi vs Terraform - Which is more secure by default?</summary>

**Pulumi advantages:**
* ✅ Secrets encrypted automatically (no config needed)
* ✅ Built-in testing frameworks (unit/integration)
* ✅ Type safety (compile-time checks)
* ✅ Secret outputs protected by default
* ✅ Programming language tooling (linters, IDEs)

**Terraform advantages:**
* ✅ Declarative = easier to audit
* ✅ Larger ecosystem and examples
* ✅ More mature security tooling (tfsec, Checkov)
* ✅ HCL is simpler for infrastructure-only teams

**Verdict:** Pulumi has **better security defaults**, but Terraform has **more security tooling**.

**Best practice:** Choose based on team skills:
- DevOps/Infra teams → Terraform
- Software dev teams → Pulumi
</details>

---

## 📂 Group 4: Ansible Security

## 📍 Slide 13 – ⚙️ Ansible Overview & Security Challenges

* ⚙️ **Ansible** = agentless automation via SSH (Python)
* 📝 **Playbooks** = YAML files defining tasks
* 🔄 **Idempotent** = safe to run multiple times
* ⚠️ **Security risks:** SSH keys, privileged operations, secrets in playbooks

```yaml
# Basic playbook structure
---
- name: Configure web servers
  hosts: webservers
  become: yes  # Run as root/sudo
  
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        
    - name: Copy config
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: restart nginx
      
  handlers:
    - name: restart nginx
      service:
        name: nginx
        state: restarted
```

### 🔑 Ansible Vault - Encrypt Secrets

```bash
# Create encrypted file
$ ansible-vault create secrets.yml
New Vault password: ****
Confirm: ****

# Edit encrypted file
$ ansible-vault edit secrets.yml

# View encrypted file
$ ansible-vault view secrets.yml

# Encrypt existing file
$ ansible-vault encrypt vars.yml

# Decrypt file
$ ansible-vault decrypt vars.yml
```

```yaml
# secrets.yml (encrypted)
---
db_password: "SuperSecret123!"
api_key: "sk-1234567890abcdef"
ssl_private_key: |
  -----BEGIN PRIVATE KEY-----
  MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
  -----END PRIVATE KEY-----
```

### 🔐 Using Vault in Playbooks

```yaml
# playbook.yml
---
- name: Deploy application
  hosts: app_servers
  vars_files:
    - secrets.yml  # Encrypted with ansible-vault
    
  tasks:
    - name: Create database
      postgresql_db:
        name: myapp
        login_password: "{{ db_password }}"  # From vault
        
    - name: Configure API
      template:
        src: config.j2
        dest: /etc/app/config.yml
      vars:
        api_key: "{{ api_key }}"  # From vault
```

```bash
# Run with vault password
$ ansible-playbook playbook.yml --ask-vault-pass

# Or use password file
$ ansible-playbook playbook.yml --vault-password-file ~/.vault_pass

# Or environment variable
$ export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass
$ ansible-playbook playbook.yml
```

<details>
<summary>💭 <strong>Quiz:</strong> What happens if you print a vaulted variable?</summary>

```yaml
- name: Debug secret
  debug:
    msg: "Password is {{ db_password }}"
```

**Answer:** It prints in plaintext! 🔥

**To prevent leaks, use `no_log`:**
```yaml
- name: Set password
  shell: "mysql -p{{ db_password }} ..."
  no_log: true  # ✅ Hides output from logs
```

**Best practice:** Always use `no_log: true` with secrets!
</details>

---

## 📍 Slide 14 – 🛡️ Ansible Security Best Practices

### 🔒 1. No Logs for Secrets

```yaml
# ❌ BAD: Secrets in logs
- name: Configure database
  postgresql_db:
    login_password: "{{ db_password }}"
  register: result

- name: Show result
  debug:
    var: result  # 🔥 Password visible in logs!

# ✅ GOOD: Hide sensitive output
- name: Configure database
  postgresql_db:
    login_password: "{{ db_password }}"
  no_log: true  # ✅ Redacts from logs

- name: Execute command with secret
  shell: "curl -H 'Authorization: Bearer {{ api_token }}' ..."
  no_log: true
  register: api_result
```

### 🔑 2. SSH Key Management

```yaml
# Use SSH keys, not passwords
[webservers]
server1 ansible_host=192.168.1.10 ansible_user=deploy

# SSH config
$ cat ~/.ssh/config
Host server1
    HostName 192.168.1.10
    User deploy
    IdentityFile ~/.ssh/deploy_key
    StrictHostKeyChecking yes

# Vault SSH keys if storing in repo
$ ansible-vault encrypt files/deploy_key
```

### 👮 3. Least Privilege

```yaml
# ❌ BAD: Always run as root
- name: Install package
  become: yes
  become_user: root
  apt: name=nginx

# ✅ GOOD: Only escalate when needed
- name: Install package
  apt: name=nginx
  become: yes  # Only for this task

- name: Copy user file
  copy:
    src: app.conf
    dest: ~/app.conf
  # No become - runs as regular user
```

### 🧹 4. Ansible Lint

```bash
# Install
$ pip install ansible-lint

# Run
$ ansible-lint playbook.yml

# Example output
playbook.yml:
  [201] Trailing whitespace
  [206] Variables should have spaces before and after: {{ var_name }}
  [301] Commands should not change things if nothing needs doing
  [305] Use shell only when shell functionality is required
  [503] Tasks that run when changed should likely be handlers
```

```yaml
# .ansible-lint config
---
skip_list:
  - '301'  # Sometimes we need non-idempotent tasks

warn_list:
  - experimental
  - role-name

exclude_paths:
  - .github/
  - test/
```

### 🏢 5. Ansible Tower/AWX

* 🔐 Centralized credential management
* 👥 RBAC for playbook execution
* 📊 Audit logs of all runs
* 🔄 Scheduled jobs with approval workflows
* 🚀 Self-service infrastructure for developers

<details>
<summary>💭 <strong>Exercise:</strong> Secure this playbook</summary>

```yaml
# insecure.yml - Find the issues!
---
- hosts: all
  become: yes
  tasks:
    - name: Set root password
      shell: "echo 'root:{{ root_password }}' | chpasswd"
      
    - name: Download script
      get_url:
        url: http://example.com/script.sh
        dest: /tmp/script.sh
        mode: 0777
        
    - name: Run script
      shell: bash /tmp/script.sh
      
    - name: Show database connection
      debug:
        msg: "DB: postgresql://admin:{{ db_pass }}@localhost/app"
```

**Issues found:**
1. ❌ No `no_log` on password change
2. ❌ HTTP instead of HTTPS
3. ❌ Overly permissive file mode (0777)
4. ❌ Running untrusted script
5. ❌ Database password in debug output
6. ❌ Using shell instead of proper module

**Fixed version:**
```yaml
---
- hosts: all
  become: yes
  tasks:
    - name: Set root password
      user:
        name: root
        password: "{{ root_password | password_hash('sha512') }}"
      no_log: true
      
    - name: Download script
      get_url:
        url: https://example.com/script.sh
        dest: /tmp/script.sh
        mode: 0750
        checksum: sha256:abc123...
        
    - name: Run script
      script: /tmp/script.sh
      args:
        creates: /var/app/installed
      no_log: true
      
    # Remove debug statement entirely!
```
</details>

---

## 📍 Slide 15 – 💻 Hands-On: Secure Ansible Playbook

### 📝 Secure Web Server Deployment

```yaml
# site.yml - Main playbook
---
- name: Deploy secure web application
  hosts: webservers
  become: yes
  vars_files:
    - vault.yml  # Encrypted secrets
    
  pre_tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
        
  roles:
    - common
    - security
    - nginx
    - app
    
  post_tasks:
    - name: Verify deployment
      uri:
        url: "https://{{ inventory_hostname }}"
        validate_certs: yes
      delegate_to: localhost
```

```yaml
# roles/security/tasks/main.yml - Security hardening
---
- name: Install security updates
  apt:
    upgrade: dist
    update_cache: yes
  register: updates
  
- name: Configure firewall
  ufw:
    rule: allow
    port: "{{ item }}"
    proto: tcp
  loop:
    - 22    # SSH
    - 443   # HTTPS
  no_log: true
  
- name: Enable firewall
  ufw:
    state: enabled
    policy: deny
    
- name: Disable root login
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^PermitRootLogin'
    line: 'PermitRootLogin no'
  notify: restart sshd
  
- name: Require SSH key auth
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^PasswordAuthentication'
    line: 'PasswordAuthentication no'
  notify: restart sshd
  
- name: Install fail2ban
  apt:
    name: fail2ban
    state: present
    
- name: Configure fail2ban
  template:
    src: jail.local.j2
    dest: /etc/fail2ban/jail.local
  notify: restart fail2ban
  
handlers:
  - name: restart sshd
    service:
      name: sshd
      state: restarted
      
  - name: restart fail2ban
    service:
      name: fail2ban
      state: restarted
```

```yaml
# vault.yml (encrypted)
---
ssl_cert: |
  -----BEGIN CERTIFICATE-----
  ...
ssl_key: |
  -----BEGIN PRIVATE KEY-----
  ...
db_password: "SuperSecure123!"
app_secret_key: "random-secret-key"
```

### 🧪 Testing with Molecule

```bash
# Install molecule
$ pip install molecule[docker]

# Initialize molecule
$ molecule init scenario

# Run tests
$ molecule test
```

```yaml
# molecule/default/molecule.yml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: ubuntu:22.04
    pre_build_image: true
provisioner:
  name: ansible
verifier:
  name: ansible
```

```yaml
# molecule/default/verify.yml - Test security
---
- name: Verify
  hosts: all
  tasks:
    - name: Check firewall enabled
      command: ufw status
      register: ufw_status
      changed_when: false
      
    - name: Assert firewall is active
      assert:
        that:
          - "'Status: active' in ufw_status.stdout"
          
    - name: Check SSH config
      shell: grep "^PermitRootLogin no" /etc/ssh/sshd_config
      changed_when: false
      
    - name: Check HTTPS accessible
      uri:
        url: https://localhost
        validate_certs: no
      delegate_to: localhost
```

### 🚀 CI/CD Integration

```yaml
# .github/workflows/ansible.yml
name: Ansible CI

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      - name: Install dependencies
        run: pip install ansible ansible-lint
      - name: Run ansible-lint
        run: ansible-lint site.yml
        
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run molecule tests
        run: |
          pip install molecule[docker]
          molecule test
```

<details>
<summary>💭 <strong>Pro Tip:</strong> Ansible Tower vs AWX vs Semaphore</summary>

**Ansible Tower (Red Hat):**
* 💰 Commercial ($$$)
* 🏢 Enterprise support
* 📊 Advanced reporting
* 🔄 HA clustering built-in

**AWX (Open Source):**
* 🆓 Free (upstream of Tower)
* 🔄 Frequent updates
* 🐳 Container-based
* ⚠️ Less stable

**Semaphore (Open Source):**
* 🆓 Free alternative
* 🚀 Modern UI
* 🐳 Lightweight
* ⚡ Fast and simple

**Choose based on:**
- Need support? → Tower
- Want latest features? → AWX
- Want simplicity? → Semaphore
- Small team? → Just use Git + CLI
</details>

---

## 🎉 Fun Break: "Ansible Disaster Stories"

### 😱 **"The Playbook That Deleted Production"**

```yaml
# Someone wrote this...
- name: Clean old files
  file:
    path: "{{ cleanup_path }}"
    state: absent

# And ran it with...
$ ansible-playbook cleanup.yml -e "cleanup_path=/"
```
**Result:** 💥 Deleted the entire filesystem

**Lesson:** Always use `--check` mode first!

### 🔥 **"The Leaked Vault Password"**

```bash
# Developer committed this
$ git add .vault_pass
$ git commit -m "Add vault password for convenience"
$ git push
```
**Result:** 🔓 All secrets exposed in Git history

**Lesson:** Add `.vault_pass` to `.gitignore`!

### ⚡ **"The Infinite Loop"**

```yaml
- name: Restart service until it works
  service:
    name: myapp
    state: restarted
  until: result.status == 0
  # Forgot to add retries limit!
```
**Result:** 🔄 Playbook ran for 48 hours straight

**Lesson:** Always set `retries` and `delay`!

---

## 📂 Group 5: Misconfiguration Scanning & Policy-as-Code

## 📍 Slide 16 – 🔍 IaC Security Scanning Tools Deep Dive

### 🛠️ Tool Comparison

| Tool | Speed | Coverage | False Positives | Cost | Best For |
|------|-------|----------|-----------------|------|----------|
| 🔍 **Checkov** | Medium | 1000+ checks | Low | Free | Multi-cloud |
| ⚡ **tfsec** | ⚡ Fast | 300+ checks | Very Low | Free | Terraform |
| 🔎 **Terrascan** | Slow | 500+ checks | Medium | Free | Compliance |
| 🦅 **Prowler** | Medium | 300+ checks | Low | Free | AWS |
| 🔍 **ScoutSuite** | Slow | All services | Medium | Free | Multi-cloud audit |

<details>
<summary>💭 <strong>Interactive:</strong> Which tool should you choose?</summary>

**Choose tfsec if:**
* ✅ You only use Terraform
* ✅ Speed is critical (CI/CD)
* ✅ Want minimal false positives
* ✅ Need IDE integration

**Choose Checkov if:**
* ✅ Multi-cloud or multi-IaC tool
* ✅ Need custom Python policies
* ✅ Want largest policy library
* ✅ Need container/K8s scanning too

**Choose Terrascan if:**
* ✅ Already using OPA/Rego
* ✅ Need custom compliance frameworks
* ✅ Want policy-as-code approach

**Best practice:** Use multiple! They catch different issues.
```bash
tfsec . && checkov -d . && terraform plan
```
</details>

---

## 📍 Slide 17 – 📋 Policy-as-Code Frameworks

### 🎯 Open Policy Agent (OPA)

```bash
# Install
$ brew install opa

# Run as server
$ opa run --server

# Test policy
$ opa test policy/ -v
```

```rego
# policy/s3_public.rego
package terraform.s3

deny[msg] {
    resource := input.resource.aws_s3_bucket[name]
    resource.acl == "public-read"
    msg := sprintf("S3 bucket %v is publicly readable", [name])
}

deny[msg] {
    resource := input.resource.aws_s3_bucket[name]
    not resource.versioning
    msg := sprintf("S3 bucket %v does not have versioning", [name])
}
```

### 🔒 Conftest - Test Configurations

```bash
# Install
$ brew install conftest

# Test Terraform plan
$ terraform plan -out=plan.out
$ terraform show -json plan.out > plan.json
$ conftest test plan.json

# Test Kubernetes
$ conftest test deployment.yaml

# Test Dockerfile
$ conftest test Dockerfile
```

```rego
# policy/kubernetes.rego
package main

deny[msg] {
    input.kind == "Deployment"
    not input.spec.template.spec.securityContext.runAsNonRoot
    msg := "Containers must not run as root"
}

deny[msg] {
    input.kind == "Service"
    input.spec.type == "LoadBalancer"
    msg := "LoadBalancer services are not allowed"
}

warn[msg] {
    input.kind == "Pod"
    not input.spec.containers[_].resources.limits
    msg := "Container should have resource limits"
}
```

### ⚙️ HashiCorp Sentinel

```hcl
# sentinel.hcl
policy "s3-bucket-encryption" {
    enforcement_level = "hard-mandatory"
}

policy "required-tags" {
    enforcement_level = "soft-mandatory"
}
```

```python
# s3-bucket-encryption.sentinel
import "tfplan/v2" as tfplan

s3_buckets = filter tfplan.resource_changes as _, rc {
    rc.type is "aws_s3_bucket" and
    rc.mode is "managed" and
    rc.change.actions is not ["delete"]
}

require_encryption = rule {
    all s3_buckets as _, bucket {
        bucket.change.after.server_side_encryption_configuration is not null
    }
}

main = rule {
    require_encryption
}
```

<details>
<summary>💭 <strong>Quiz:</strong> OPA vs Sentinel - What's the difference?</summary>

**Open Policy Agent (OPA):**
* 🆓 Open source (CNCF)
* 🌍 Universal - works anywhere
* 📝 Rego language (declarative)
* 🔧 Requires integration work
* ⚡ Blazing fast

**HashiCorp Sentinel:**
* 💰 Commercial (Terraform Cloud/Enterprise only)
* 🏗️ Terraform-specific
* 📝 Sentinel language (procedural)
* ✅ Built-in Terraform integration
* 🎯 Terraform-aware (costs, resources, etc.)

**When to use:**
- Open source project? → OPA
- Need multi-tool support? → OPA
- Using Terraform Cloud? → Sentinel
- Need cost controls? → Sentinel
- Want flexibility? → OPA

**Pro tip:** You can use both! OPA for runtime, Sentinel for Terraform.
</details>

---

## 📍 Slide 18 – ☁️ Compliance & Security Standards

### 📋 CIS Benchmarks

* 🏆 **CIS = Center for Internet Security**
* 📊 Industry consensus standards
* ☁️ Benchmarks for AWS, Azure, GCP, Kubernetes

### 🔐 Compliance Frameworks

| Framework | Industry | Key Requirements |
|-----------|----------|------------------|
| 💳 **PCI-DSS** | Payment cards | Encryption, network segmentation, logging |
| 🏥 **HIPAA** | Healthcare | Data encryption, access controls, audit logs |
| 🇪🇺 **GDPR** | EU data | Data privacy, right to deletion, consent |
| 📊 **SOC2** | SaaS/Cloud | Security controls, availability, confidentiality |
| 🏦 **ISO 27001** | Global | Information security management |

### 📊 Mapping IaC Checks to Compliance

```yaml
# compliance-mapping.yml
checks:
  - id: CKV_AWS_18
    title: "Ensure S3 bucket has access logging enabled"
    frameworks:
      - PCI-DSS: "10.2.1"
      - HIPAA: "164.312(b)"
      - SOC2: "CC6.1"
      
  - id: CKV_AWS_19
    title: "Ensure S3 bucket is encrypted"
    frameworks:
      - PCI-DSS: "3.4"
      - HIPAA: "164.312(a)(2)(iv)"
      - GDPR: "Article 32"
      - SOC2: "CC6.7"
```

### 🛡️ Cloud Security Posture Management (CSPM)

```bash
# Example: Using ScoutSuite for multi-cloud audit
$ scout suite --provider aws --profile production

# Or with Prowler for AWS
$ prowler aws --profile prod --html-output

# Output shows:
# ✅ Passed: 234 checks
# ⚠️  Warning: 45 checks
# ❌ Failed: 12 checks
# 📊 Compliance Score: 87%
```

---

## 📂 Group 6: Case Studies & Future Trends

## 📍 Slide 19 – 🎯 Case Studies, Future Trends & Summary

### 🚨 Case Study 1: Capital One Breach (2019)

* 🏦 **Target:** Capital One (major US bank)
* 📅 **Date:** March 2019 (discovered July 2019)
* 🔥 **Impact:** 100M customer records, 140K SSNs, 80K bank accounts
* 💰 **Cost:** $190M settlement + reputation damage

**What happened:**
```hcl
# Misconfigured WAF (simplified example)
resource "aws_waf_rule" "allow_all" {
  name        = "WAF-Rule"
  metric_name = "WAFRule"
  
  predicates {
    data_id = aws_waf_ipset.allow_all.id
    negated = false
    type    = "IPMatch"
  }
}

# SSRF vulnerability + overly permissive IAM role
resource "aws_iam_role_policy" "waf_role" {
  policy = jsonencode({
    Action = [
      "s3:List*",
      "s3:Get*"  # 🔥 Too permissive!
    ]
    Resource = "*"  # 🔥 All buckets!
  })
}
```

**How IaC security could have prevented it:**
```bash
$ checkov -f main.tf

❌ IAM policy should not allow * resource
❌ IAM policy is overly permissive
❌ WAF rule allows all IPs

$ conftest test plan.json -p compliance/

❌ IAM role violates least privilege (PCI-DSS 7.1.2)
```

### 🚨 Case Study 2: Tesla Kubernetes Dashboard (2018)

* ⚡ **Target:** Tesla (electric vehicle company)
* 📅 **Date:** February 2018
* 🔥 **Impact:** Crypto mining attack, potential access to proprietary data
* 💰 **Cost:** Unknown (quickly remediated)

**What happened:**
```yaml
# Exposed Kubernetes dashboard (no authentication!)
apiVersion: v1
kind: Service
metadata:
  name: kubernetes-dashboard
spec:
  type: LoadBalancer  # 🔥 PUBLIC!
  ports:
    - port: 443
      targetPort: 8443
```

**Fixed with policy-as-code:**
```rego
# Block public K8s services
deny[msg] {
    input.kind == "Service"
    input.spec.type == "LoadBalancer"
    not input.metadata.annotations["service.beta.kubernetes.io/aws-load-balancer-internal"]
    msg := "LoadBalancer must be internal-only"
}
```

### 🔮 Future of IaC Security (2025-2030)

* 🤖 **AI-Powered Security:**
  * ML models detect anomalous infrastructure patterns
  * Auto-fix suggestions with context
  * Predictive security (catch issues before they happen)
  
* 🔄 **GitOps Everywhere:**
  * All infrastructure changes via Git
  * Automated policy enforcement
  * Complete audit trails
  
* 🛡️ **Shift-Left Evolution:**
  * IDE plugins catch issues while coding
  * Real-time policy feedback
  * Security as you type
  
* 🌐 **Zero-Trust Infrastructure:**
  * Every resource requires explicit authorization
  * Continuous verification
  * Automated least-privilege
  
* 📦 **Policy Marketplaces:**
  * Pre-built compliance frameworks
  * Community-driven security rules
  * Industry-specific policies

### 📚 Best Practices Checklist

```yaml
✅ Security Fundamentals:
  - [ ] Never hardcode secrets
  - [ ] Use remote encrypted state
  - [ ] Enable state locking
  - [ ] Version pin all dependencies
  - [ ] Use verified modules only

✅ Scanning & Testing:
  - [ ] Run security scans in CI/CD
  - [ ] Implement policy-as-code
  - [ ] Test policies before enforcement
  - [ ] Scan for secrets (gitleaks)
  - [ ] Multiple tools (defense in depth)

✅ Access Control:
  - [ ] RBAC for all operations
  - [ ] MFA for production changes
  - [ ] Separate accounts/workspaces
  - [ ] Audit logs enabled
  - [ ] Least privilege by default

✅ Compliance:
  - [ ] Map checks to frameworks
  - [ ] Automated compliance reports
  - [ ] Regular policy reviews
  - [ ] Documentation up-to-date
  - [ ] Continuous monitoring

✅ Continuous Improvement:
  - [ ] Track security metrics
  - [ ] Regular security training
  - [ ] Incident response plan
  - [ ] Blameless post-mortems
  - [ ] Share learnings across teams
```

### 🎯 Key Takeaways

1. 🏗️ **IaC is powerful** - Automates infrastructure, but also automates vulnerabilities if not secured
2. 🔐 **Secrets management** - Use vaults, never hardcode, encrypt state
3. 🔍 **Scan everything** - tfsec, Checkov, Terrascan in every pipeline
4. 📋 **Policy-as-code** - OPA/Conftest/Sentinel enforce standards automatically
5. 🚀 **Shift-left** - Catch issues in development, not production
6. 📊 **Compliance** - Map IaC checks to regulatory requirements
7. 🔄 **GitOps** - Git as source of truth, automated deployments
8. 🤖 **Future is AI** - ML will revolutionize IaC security detection

### 🔗 Essential Resources

* **📚 Learning:**
  * [Terraform Best Practices](https://www.terraform-best-practices.com/)
  * [Pulumi Examples](https://github.com/pulumi/examples)
  * [Ansible Documentation](https://docs.ansible.com/)
  * [OPA Policy Library](https://github.com/open-policy-agent/library)

* **🛠️ Tools:**
  * [tfsec](https://aquasecurity.github.io/tfsec/)
  * [Checkov](https://www.checkov.io/)
  * [Conftest](https://www.conftest.dev/)
  * [Prowler](https://github.com/prowler-cloud/prowler)

* **📋 Standards:**
  * [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
  * [NIST Cloud Computing](https://www.nist.gov/programs-projects/nist-cloud-computing-program-nccp)
  * [OWASP Cloud Security](https://owasp.org/www-project-cloud-security/)

* **🎓 Certifications:**
  * HashiCorp Certified: Terraform Associate
  * Certified Kubernetes Security Specialist (CKS)
  * AWS Certified Security - Specialty

---
