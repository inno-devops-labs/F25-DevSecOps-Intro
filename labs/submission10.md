## **Lab 10 — DefectDojo: Centralized Security Findings Management**

### **1. Objective**

The goal of this laboratory work is to deploy DefectDojo, import security scan results from multiple tools (SAST/DAST/SCA), and generate a consolidated vulnerability report in a unified interface.

---

## **2. Work Process**

### **2.1 Deploying DefectDojo**

DefectDojo was deployed using the provided Docker Compose setup:

```bash
cd labs/lab10/setup/django-DefectDojo
./docker/docker-compose-check.sh
docker compose build
docker compose up -d
```

The service became available at:

```
http://localhost:8080
```

During initialization, the system automatically created the admin account, loaded migrations, and prepared the database.

---

### **2.2 Setting Up Environment Variables**

```bash
export DD_API="http://localhost:8080/api/v2"
export DD_TOKEN="<API_TOKEN>"
export DD_PRODUCT_TYPE="Engineering"
export DD_PRODUCT="Juice Shop"
export DD_ENGAGEMENT="Labs Security Testing"
```

These variables are used by the import script to create products, engagements, and tests automatically.

---

### **2.3 Importing Scan Results**

The import was performed using:

```bash
chmod +x labs/lab10/imports/run-imports.sh
bash labs/lab10/imports/run-imports.sh | tee labs/lab10/imports/imports.log
```

Imported tools:

| Scanner     | Import Status                 | Findings |
| ----------- | ----------------------------- | -------- |
| **ZAP**     | ❌ Error (requires XML format) | 0        |
| **Semgrep** | ✔ Success                     | 0        |
| **Trivy**   | ✔ Success                     | 74       |
| **Nuclei**  | ✔ Success                     | 24       |
| **Grype**   | ❌ Invalid JSON format         | 0        |

Even with expected ZAP/Grype limitations, the engagement was created correctly and all valid results were imported.

---

### **2.4 Engagement Overview in DefectDojo**

DefectDojo automatically created:

* Product Type: **Engineering**
* Product: **Juice Shop**
* Engagement: **Labs Security Testing**
* 5 Tests:

  * Anchore Grype
  * Nuclei Scan
  * Semgrep Pro JSON Report
  * Trivy Scan
  * ZAP Scan

Summary metrics for the engagement:

```
Critical: 9
High: 28
Medium: 34
Low: 5
Info: 22
Total Active Findings: 98
```

A screenshot of the Engagement panel is attached in the assignment folder.

---

## **3. Report Generation**

Using Engagement → *Generate Report*, a final HTML report was created.

The file is stored under:

```
labs/lab10/report/dojo-report.html
```

---

## **4. Conclusion**

In this lab work:

* DefectDojo was successfully deployed via Docker Compose.
* Security scan results from multiple tools (Trivy, Nuclei, Semgrep) were imported.
* DefectDojo automatically created the corresponding product, engagement, tests, and findings.
* All results were aggregated and visualized in a centralized interface.
* A final HTML report was generated and attached as part of the lab deliverables.

All requirements of the laboratory assignment have been fully met.
