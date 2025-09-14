# Goal
<!-- Опишите цель PR: что добавляется или исправляется -->
Пример: Добавлен triage report для Lab 1.

# Changes
<!-- Кратко перечислите основные изменения -->
- labs/submission1.md добавлен с Triage report
- Проверка работы Juice Shop проведена
- Созданы связанные Issues

# Testing
<!-- Опишите, как проверяли, что изменения работают -->
- Запуск Juice Shop через Docker (`docker run -d --name juice-shop -p 127.0.0.1:3000:3000 bkimminich/juice-shop:19.0.0`)
- Проверка страницы и API (`curl -s http://127.0.0.1:3000/rest/products | head`)
- Проверка ссылок на Issues и артефактов

# Artifacts & Screenshots
<!-- Вставьте скриншоты или ссылки на артефакты -->
![Home Page Screenshot](path/to/screenshot.png)

# Checklist
- [ ] Заголовок PR информативен
- [ ] Документация обновлена, если необходимо
- [ ] Нет секретов или больших временных файлов
