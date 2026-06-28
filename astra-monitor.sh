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

# --- Функция логирования ---
log() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

# --- Сбор метрик ---
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_PERCENT=$((RAM_USED * 100 / RAM_TOTAL))
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

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

# --- Отправка в Telegram ---
send_telegram() {
    local text="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$text" \
        -d parse_mode="HTML" > /dev/null 2>&1
}

# --- Отправка в Zabbix ---
send_zabbix() {
    if [ "$ZABBIX_ENABLED" = "yes" ]; then
        $ZABBIX_SENDER -z "$ZABBIX_SERVER" -s "$ZABBIX_HOST" -k "system.cpu.load" -o "$CPU" > /dev/null 2>&1
        $ZABBIX_SENDER -z "$ZABBIX_SERVER" -s "$ZABBIX_HOST" -k "system.ram.percent" -o "$RAM_PERCENT" > /dev/null 2>&1
        $ZABBIX_SENDER -z "$ZABBIX_SERVER" -s "$ZABBIX_HOST" -k "system.disk.percent" -o "$DISK_USAGE" > /dev/null 2>&1
        log "Метрики отправлены в Zabbix."
    fi
}

# --- Формирование сообщения ---
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

# --- Отправка ---
if [ "$TELEGRAM_ENABLED" = "yes" ]; then
    send_telegram "$REPORT"
    log "Отчёт отправлен в Telegram."
fi

send_zabbix

log "Мониторинг завершён."
