# Lab 6 Submission

## 1. Сканирование Terraform
- tfsec: 53 findings
- Checkov: 4 findings
- Terrascan: 3 findings

## 2. KICS Pulumi
- HIGH: 2
- MEDIUM: 2
- INFO: 2
- CRITICAL/LOW/TRACE: 0

## 3. KICS Ansible
- HIGH: 8
- LOW: 1
- CRITICAL/MEDIUM/INFO/TRACE: 0

## 4. Сравнение инструментов
- tfsec находит больше всего проблем в Terraform-коде, Checkov и Terrascan — меньше.
- KICS для Pulumi и Ansible выявляет уязвимости разной критичности, для Ansible — больше HIGH.
- Каждый инструмент даёт разный охват и детализацию.

## Вывод
Использование нескольких инструментов позволяет получить более полную картину безопасности IaC. Разные сканеры находят разные типы проблем, поэтому для комплексного анализа стоит применять их вместе.
