# Submission 2 — Threagile Model & Automated Report

## Overview
Threagile was run locally using Docker on Linux. The provided model `labs/lab2/threagile-model.yaml` was used without restructuring, with a small change applied during the Delta Run to switch one communication link to HTTPS.

## Artifacts
The following files were generated in `labs/lab2/`:

- `threagile-model.yaml` — input YAML model  
- `report.pdf` — full PDF report with diagrams  
- `data-flow-diagram.png` — data flow diagram  
- `data-asset-diagram.png` — data asset diagram (additional)  
- `risks.json` — risk outputs  
- `stats.json` — statistics snapshot  

## Top 5 Risks

| Severity  | Category                       | Asset               | Likelihood   | Impact |
|-----------|--------------------------------|-------------------|-------------|--------|
| elevated  | unencrypted-communication       | User Browser       | likely      | high   |
| elevated  | unencrypted-communication       | User Browser       | likely      | high   |
| elevated  | cross-site-scripting            | Juice Shop         | likely      | medium |
| elevated  | missing-authentication          | Juice Shop         | likely      | medium |
| medium    | cross-site-request-forgery      | Juice Shop         | very-likely | low    |

*Ranking was calculated using the composite score: Severity100 + Likelihood10 + Impact.*

## Stats Snapshot
From `stats.json`:

```json
[{"category":"unencrypted-asset","risk_status":"unchecked","severity":"medium","exploitation_likelihood":"unlikely","exploitation_impact":"medium","title":"\u003cb\u003eUnencrypted Technical Asset\u003c/b\u003e named \u003cb\u003eJuice Shop\u003c/b\u003e","synthetic_id":"unencrypted-asset@juice-shop","most_relevant_data_asset":"","most_relevant_technical_asset":"juice-shop","most_relevant_trust_boundary":"","most_relevant_shared_runtime":"","most_relevant_communication_link":"","data_breach_probability":"improbable","data_breach_technical_assets":["juice-shop"]}
