# Lab 7 — Container Security (OWASP Juice Shop)

## Репозиторий и ветка

* Репозиторий: F25-DevSecOps-Intro
* Ветка: `feature/lab7`
* Папка лабы: `labs/lab7/`

## Task 1 — Анализ уязвимостей образа и best practices

**Тестируемый образ:** `bkimminich/juice-shop:v19.0.0`
**Артефакты:**

* Docker Scout: `labs/lab7/scanning/scout-cves.txt`
* Snyk (CLI из Windows): `labs/lab7/scanning/snyk-results.txt`
* Dockle (по hc-образу): `labs/lab7/scanning/dockle-results.txt`

### Сводка Docker Scout

* Найдено 61 уязвимость в 30 пакетах (CRITICAL — 9, HIGH — 20, MEDIUM — 24, LOW — 1, UNSPECIFIED — 7).
* База: `gcr.io/distroless/nodejs22-debian12:latest`.

**Top-5 уязвимостей (по критичности и распространённости):**

1. `vm2` (≤3.9.19): CVE-2023-37903, CVE-2023-37466, CVE-2023-32314 и др. — RCE/Code Injection. Фикс: частично/нет для старых версий; рекомендация — исключить зависимость/перейти на поддерживаемую альтернативу.
2. `lodash` (<4.17.21): CVE-2019-10744, CVE-2020-8203, CVE-2021-23337 — prototype pollution/command injection. Фикс: ≥4.17.21.
3. `jsonwebtoken` (<9.0.0): CVE-2015-9235, CVE-2022-23539/40/41 — проблемы криптографии/аутентификации. Фикс: 9.x.
4. `crypto-js` (<4.2.0): CVE-2023-46233 — небезопасные алгоритмы. Фикс: ≥4.2.0.
5. `minimist` (<1.2.6): CVE-2021-44906 — известная уязвимость. Фикс: ≥1.2.6.
   (Дополнительно по High: `socket.io` <4.6.2, `socket.io-parser` <4.2.3, `engine.io` <6.2.1, `ws` <7.5.10, `moment` <2.29.2 и др.)

### Сводка Snyk

* Аутентификация через персональный API-токен; запуск из Windows (без VPN в WSL).
* Подтвердил ключевые High/Critical: `express-jwt` (≤5.3.3), `jsonwebtoken` (<9), `jws` (<3), `moment` (<2.29.2), `base64url` (<3.0.0) и др.
* Рекомендация: аудит зависимостей `package.json/package-lock.json` и переход на исправленные версии.

### Dockle (best practices)

* Для базового образа предупреждал об отсутствии `HEALTHCHECK`.
* Исправлено: собран hc-образ (`emil/juice-shop:v19.0.0-hc`) с exec-формой HEALTHCHECK (distroless, без `/bin/sh`).
* Актуальные замечания Dockle: мусорные файлы `.DS_Store` внутри node_modules — чистка контекста билда и/или `.dockerignore`.

### Рекомендации по hardening образа

* Пересборка на актуальной базе `distroless/nodejs` (Debian 12, с обновлениями безопасности).
* Обновить уязвимые npm-зависимости: `lodash ≥4.17.21`, `jsonwebtoken 9.x`, `crypto-js ≥4.2.0`, `socket.io ≥4.6.2`, `socket.io-parser ≥4.2.3`, `engine.io ≥6.2.1`, `ws ≥7.5.10`, `moment ≥2.29.2`, `minimist ≥1.2.6` и пр.
* Добавить `HEALTHCHECK` (считаем 2xx/3xx успешными; exec-форма без оболочки).
* Очистка контекста билда (`.dockerignore`), удаление мусора `.DS_Store`.
* Регулярный перескан/пересборка образов.

---

## Task 2 — Docker Bench for Security (CIS)

**Артефакт:** `labs/lab7/hardening/docker-bench-results.txt`
**Итог:** Checks: 105, Score: 16 (улучшился после добавления HEALTHCHECK; пункт 5.26 — PASS).

**Ключевые наблюдения и remediation:**

* 5.26 Healthcheck: теперь **PASS** (вшит HEALTHCHECK в образ).
* 5.1 AppArmor / 5.2 SELinux: **WARN** — на WSL профили часто недоступны; в проде включить AppArmor/SELinux, задать профиль `apparmor=docker-default`/политику.
* 5.10/5.11 Ограничения ресурсов: у baseline-контейнера не заданы — в проде задавать `--memory`, `--cpus` по умолчанию (через оркестратор/политику).
* 5.12 rootfs read-only: **WARN** — где возможно, использовать `--read-only` и выделенные тома для записи.
* 5.13 bind на 0.0.0.0: **WARN** — в проде привязывать к конкретному интерфейсу/через прокси/фаервол.
* 5.14 restart policy = 5: **WARN** — в задании использована `on-failure:3` (учебно), в проде можно поднять до 5.
* 2.6 TLS для демона: **WARN** — если демон слушает TCP, включить TLS; либо не слушать TCP вовсе.
* 2.8 userns-remap: **WARN** — включить в `daemon.json` для изоляции uid/gid.
* 2.11 authz плагин: **WARN** — включить авторизационный плагин для контроля клиентских команд.
* 2.12 централизованные логи: **WARN** — настраивать драйверы/агенты логирования в проде.
* 2.14 live-restore: **WARN** — включить для снижения даунтайма при рестарте демона.

---

## Task 3 — Профили развертывания и сравнение

**Артефакт:** `labs/lab7/analysis/deployment-comparison.txt`
**Контейнеры:**

* Default: `juice-default` (порт 3001)
* Hardened: `juice-hardened` (порт 3002)
* Production: `juice-production` (порт 3003)

**Доступность:**

* HTTP: 200 на всех трёх профилях.
* Health: все три — `healthy` (hc-образ).

**Ресурсные метрики (пример среза):**

* Default: CPU ~0.40%, Mem ~100.8MiB (без лимитов)
* Hardened: CPU ~0.65%, Mem ~92.4MiB из 512MiB
* Production: CPU ~4.36%, Mem ~93.5MiB из 512MiB

**Конфигурации безопасности (docker inspect):**

| Профиль    | CapDrop | CapAdd           | SecurityOpt       | Memory | CPU quota | PIDs | Restart      |
| ---------- | ------- | ---------------- | ----------------- | ------ | --------- | ---- | ------------ |
| Default    | —       | —                | —                 | 0      | 0         | —    | no           |
| Hardened   | ALL     | —                | no-new-privileges | 512MiB | 0         | —    | no           |
| Production | ALL     | NET_BIND_SERVICE | no-new-privileges | 512MiB | 0         | 100  | on-failure:3 |

**Интерпретация:**

* `--cap-drop=ALL` убирает все Linux capabilities по умолчанию → снижает поверхность атаки.
* `--cap-add=NET_BIND_SERVICE` добавлен учебно; для порта 3000 не обязателен (нужен для <1024).
* `--security-opt=no-new-privileges` запрещает повышение привилегий даже при наличии setuid/exec.
* `--memory`, `--cpus`, `--pids-limit` защищают от DoS (OOM, runaway-CPU, fork-bomb).
* `--restart=on-failure` повышает отказоустойчивость; в проде сочетать с мониторингом/алертингом.

**Рекомендации по профилям:**

* Dev/Staging: профиль **Hardened** — баланс между удобством и безопасностью.
* Prod: профиль **Production** — минимум привилегий + лимиты + рестарт-политика; дополнительно рекомендованы: `--read-only`, конкретная привязка к интерфейсу, AppArmor/SELinux, централизованные логи.

---

## Приложения (артефакты)

* `labs/lab7/scanning/scout-cves.txt`
* `labs/lab7/scanning/snyk-results.txt`
* `labs/lab7/scanning/dockle-results.txt`
* `labs/lab7/hardening/docker-bench-results.txt`
* `labs/lab7/analysis/deployment-comparison.txt`
* `labs/lab7/bin/Dockerfile.juice-hc`

## Вывод

* Проведено три независимых скана (Scout/Snyk/Dockle), выявлены критичные уязвимости в npm-зависимостях и недочёты best practices.
* Исправлено отсутствие HEALTHCHECK (hc-образ с exec-проверкой, совместимой с distroless), что улучшило результаты Dockle/CIS.
* Подготовлены и проверены три профиля запуска (Default/Hardened/Production). В прод-профиле реализованы ограничения и меры, снижающие риск DoS и эскалации привилегий.
* Даны чёткие рекомендации по обновлению зависимостей, конфигурации демона и повышению уровня защиты для прод-окружения.
