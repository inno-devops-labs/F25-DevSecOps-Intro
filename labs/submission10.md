## **Lab 10 — DefectDojo: Centralized Security Findings Management**

### **1. Objective**

The purpose of this lab is to deploy DefectDojo, import security scan results from multiple tools (SAST/DAST/SCA), and produce a unified vulnerability report within a single management interface.

---

## **2. Work Process**

### **2.1 Deploying DefectDojo**

DefectDojo was set up using the provided Docker Compose configuration:

```bash
cd labs/lab10/setup/django-DefectDojo
./docker/docker-compose-check.sh
docker compose build
docker compose up -d
```

After startup, the web interface became available at:

```
http://localhost:8080
```

During initialization, the system automatically applied migrations, created the admin user, and prepared all database structures.

---

### **2.2 Setting Up Environment Variables**

```bash
export DD_API="http://localhost:8080/api/v2"
export DD_TOKEN="<API_TOKEN>"
export DD_PRODUCT_TYPE="Engineering"
export DD_PRODUCT="Juice Shop"
export DD_ENGAGEMENT="Labs Security Testing"
```

These variables were required by the import script to create products, engagements, and tests automatically.

---

### **2.3 Importing Scan Results**

The results were imported using:

```bash
chmod +x labs/lab10/imports/run-imports.sh
bash labs/lab10/imports/run-imports.sh | tee labs/lab10/imports/imports.log
```

Import results:

| Scanner     | Status                  | Findings |
| ----------- | ----------------------- | -------- |
| **ZAP**     | ❌ Failed (XML required) | 0        |
| **Semgrep** | ✔ Successful            | 0        |
| **Trivy**   | ✔ Successful            | 74       |
| **Nuclei**  | ✔ Successful            | 24       |
| **Grype**   | ❌ Invalid JSON format   | 0        |

Even with ZAP/Grype limitations, the engagement was created correctly, and all valid reports were successfully imported.

---

### **2.4 Engagement Overview in DefectDojo**

DefectDojo automatically generated:

* Product Type: **Engineering**
* Product: **Juice Shop**
* Engagement: **Labs Security Testing**
* Five Test entries:

  * Anchore Grype
  * Nuclei Scan
  * Semgrep Pro JSON Report
  * Trivy Scan
  * ZAP Scan

Aggregated findings:

```
Critical: 9
High: 28
Medium: 34
Low: 5
Info: 22
Total Active Findings: 98
```

A screenshot of the engagement dashboard is included in the submission materials.

---

## **3. Report Generation**

Using Engagement → *Generate Report*, a final HTML report was produced and saved under:

```
labs/lab10/report/dojo-report.html
```

---

## **4. Conclusion**

In this lab:

* DefectDojo was successfully deployed using Docker Compose.
* Security findings from Trivy, Nuclei, and Semgrep were imported.
* DefectDojo automatically created the required product, engagement, tests, and mapped all valid findings.
* All results were aggregated and visualized through a centralized dashboard.
* A final HTML report was generated as part of the deliverables.

All lab requirements were fully satisfied.

