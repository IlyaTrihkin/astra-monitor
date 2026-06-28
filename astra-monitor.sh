#!/bin/bash
# ============================================
# Astra Monitor
# Сбор метрик ресурсов и отправка в Telegram/Zabbix
# ============================================

set -e

# --- Загрузка конфигурации ---
CONFIG_FILE="/root/astra-monitor/config.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Ошибка: файл конфигурации $CONFIG_FILE не найден."
    exit 1
fi

# --- Значения по умолчанию (если не заданы в конфиге) ---
TELEGRAM_ENABLED=${TELEGRAM_ENABLED:-no}
TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-""}
TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID:-""}
ZABBIX_ENABLED=${ZABBIX_ENABLED:-no}
ZABBIX_SERVER=${ZABBIX_SERVER:-127.0.0.1}
ZABBIX_HOST=${ZABBIX_HOST:-astra-server}
ZABBIX_SENDER=${ZABBIX_SENDER:-/usr/bin/zabbix_sender}
CPU_THRESHOLD=${CPU_THRESHOLD:-80}
RAM_THRESHOLD=${RAM_THRESHOLD:-85}
DISK_THRESHOLD=${DISK_THRESHOLD:-90}
LOG_FILE=${LOG_FILE:-/var/log/astra-monitor.log}

# --- Функция логирования ---
log() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

# --- Сбор метрик ---
CPU_RAW=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/,/./')
if [ -z "$CPU_RAW" ]; then
    CPU=0
else
    CPU=$(echo "$CPU_RAW" | awk '{printf "%.0f", $1}')
fi

RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
if [ -z "$RAM_TOTAL" ] || [ -z "$RAM_USED" ]; then
    RAM_PERCENT=0
else
    RAM_PERCENT=$((RAM_USED * 100 / RAM_TOTAL))
fi

DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ -z "$DISK_USAGE" ]; then
    DISK_USAGE=0
fi

# --- Проверка порогов ---
MESSAGES=""
if [ "$CPU" -gt "$CPU_THRESHOLD" ]; then
    MESSAGES="$MESSAGES\n🔴 Высокая загрузка CPU: $CPU% (порог $CPU_THRESHOLD%)"
fi
if [ "$RAM_PERCENT" -gt "$RAM_THRESHOLD" ]; then
    MESSAGES="$MESSAGES\n🔴 Высокое использование RAM: $RAM_PERCENT% (порог $RAM_THRESHOLD%)"
fi
if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    MESSAGES="$MESSAGES\n🔴 Мало свободного места на диске: $DISK_USAGE% (порог $DISK_THRESHOLD%)"
fi

# --- Формирование отчёта ---
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
REPORT="📊 <b>Отчёт по ресурсам Astra Linux</b>\n"
REPORT="$REPORT\n🕐 Время: $CURRENT_TIME"
REPORT="$REPORT\n\n🔹 CPU: $CPU%"
REPORT="$REPORT\n🔹 RAM: $RAM_PERCENT% ($RAM_USED MB / $RAM_TOTAL MB)"
REPORT="$REPORT\n🔹 Диск: $DISK_USAGE%"

if [ -n "$MESSAGES" ]; then
    REPORT="$REPORT\n\n⚠️ <b>Проблемы:</b>"
    REPORT="$REPORT$MESSAGES"
else
    REPORT="$REPORT\n\n✅ Все показатели в норме."
fi

# --- ВСЕГДА ВЫВОДИМ В КОНСОЛЬ ---
echo -e "$REPORT"

# --- Логирование ---
log "Отчёт сгенерирован"

# --- Отправка в Telegram ---
if [ "$TELEGRAM_ENABLED" = "yes" ] && [ -n "$TELEGRAM_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$REPORT" \
        -d parse_mode="HTML" > /dev/null 2>&1
    log "Отчёт отправлен в Telegram."
fi

# --- Отправка в Zabbix ---
if [ "$ZABBIX_ENABLED" = "yes" ] && [ -x "$ZABBIX_SENDER" ]; then
    $ZABBIX_SENDER -z "$ZABBIX_SERVER" -s "$ZABBIX_HOST" -k "system.cpu.load" -o "$CPU" > /dev/null 2>&1
    $ZABBIX_SENDER -z "$ZABBIX_SERVER" -s "$ZABBIX_HOST" -k "system.ram.percent" -o "$RAM_PERCENT" > /dev/null 2>&1
    $ZABBIX_SENDER -z "$ZABBIX_SERVER" -s "$ZABBIX_HOST" -k "system.disk.percent" -o "$DISK_USAGE" > /dev/null 2>&1
    log "Метрики отправлены в Zabbix."
fi

log "Мониторинг завершён."
