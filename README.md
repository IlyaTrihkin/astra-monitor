# 📊 Astra Monitor

Скрипт для мониторинга ресурсов (CPU, RAM, диск) в Astra Linux с отправкой уведомлений в Telegram и/или Zabbix.

---

## 📦 Что делает

- Собирает метрики:
  - Загрузка CPU (%)
  - Использование RAM (% и MB)
  - Использование дискового пространства (%)
- Отправляет отчёт в Telegram (с оповещениями при превышении порогов)
- Отправляет метрики в Zabbix (опционально)
- Работает по расписанию через cron
- Логирует все действия

---

## 🚀 Установка и настройка

```bash
git clone https://github.com/IlyaTrihkin/astra-monitor.git
cd astra-monitor
cp config.example config.conf
nano config.conf   # укажи токен и chat_id Telegram
chmod +x astra-monitor.sh
