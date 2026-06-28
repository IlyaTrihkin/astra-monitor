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
```

---

## 📱 Настройка Telegram

1. Создай бота в Telegram через @BotFather.

2. Получи токен.

3. Узнай свой chat_id (например, через @userinfobot).

4. Впиши их в `config.conf`.

---

## 🧪 Тестирование

```bash
./astra-monitor.sh
```

Проверь лог:

```bash
cat /var/log/astra-monitor.log
```

---

## ⏰ Настройка cron

```bash
crontab -e
```

Добавь, например, каждые 30 минут:

```text
*/30 * * * * /root/astra-monitor/astra-monitor.sh
```

---

## ⚙️ Конфигурация

Файл config.conf:

| Параметр | Описание |
|----------|----------|
| `TELEGRAM_ENABLED` | Включить отправку в Telegram (`yes`/`no`) |
| `TELEGRAM_TOKEN` | Токен Telegram бота |
| `TELEGRAM_CHAT_ID` | ID чата для уведомлений |
| `ZABBIX_ENABLED` | Включить отправку в Zabbix (`yes`/`no`) |
| `CPU_THRESHOLD` | Порог загрузки CPU в % |
| `RAM_THRESHOLD` | Порог использования RAM в % |
| `DISK_THRESHOLD` | Порог заполнения диска в % |
| `LOG_FILE` | Путь к лог-файлу |

---

## 👤 Автор

Илья Тришкин — специалист по информационной безопасности.

#### GitHub: 
https://github.com/IlyaTrihkin

#### TenChat: 
https://tenchat.ru/ilya_trishkin

#### Habr: 
https://habr.com/ru/users/ilya_trishkin

---

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. Подробнее см. [LICENSE](LICENSE).
