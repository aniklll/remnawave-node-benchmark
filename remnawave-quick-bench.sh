#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# REMNAWAVE NODE QUICK BENCH v1.0
# ═══════════════════════════════════════════════════════════════════════════
# Быстрое тестирование VPS (30-60 секунд)
# Использование: bash remnawave-quick-bench.sh
# ═══════════════════════════════════════════════════════════════════════════

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  REMNAWAVE NODE QUICK BENCH${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# System info
cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
cpu_cores=$(grep -c '^processor' /proc/cpuinfo)
total_ram=$(free -h | awk '/^Mem:/ {print $2}')
disk_total=$(df -h / | awk 'NR==2 {print $2}')
disk_free=$(df -h / | awk 'NR==2 {print $4}')

echo -e "${CYAN}📊 СИСТЕМА:${NC}"
echo "  CPU: $cpu_model ($cpu_cores cores)"
echo "  RAM: $total_ram"
echo "  Disk: $disk_free / $disk_total free"
echo ""

# Quick disk test
echo -e "${CYAN}💾 DISK (быстрый тест):${NC}"
write_speed=$(dd if=/dev/zero of=/tmp/test bs=64k count=4k conv=fdatasync 2>&1 | grep -oP '\d+\.?\d* [MG]B/s' | tail -1)
echo "  Запись: $write_speed"
rm -f /tmp/test
echo ""

# Quick network test
echo -e "${CYAN}🌐 NETWORK (ping):${NC}"
ping_google=$(ping -c 3 -W 2 8.8.8.8 2>/dev/null | tail -1 | awk -F '/' '{print $5}')
echo "  Google DNS (8.8.8.8): ${ping_google} ms"
echo ""

# Check for Node
echo -e "${CYAN}✓ ПРИГОДНОСТЬ:${NC}"
ram_mb=$(free -m | awk '/^Mem:/ {print $2}')
disk_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')

score=0
issues=()

# RAM
if (( ram_mb >= 2048 )); then
    echo -e "  ${GREEN}✓${NC} RAM: Отлично (2GB+)"
    score=$((score+2))
elif (( ram_mb >= 1024 )); then
    echo -e "  ${GREEN}✓${NC} RAM: Хорошо (1GB+)"
    score=$((score+1))
else
    echo -e "  ${RED}✗${NC} RAM: Мало (<1GB)"
    issues+=("Недостаточно RAM")
fi

# Disk
if (( disk_gb >= 20 )); then
    echo -e "  ${GREEN}✓${NC} Диск: Отлично (20GB+)"
    score=$((score+2))
elif (( disk_gb >= 10 )); then
    echo -e "  ${GREEN}✓${NC} Диск: Хорошо (10GB+)"
    score=$((score+1))
else
    echo -e "  ${YELLOW}⚠${NC} Диск: Маловато (<10GB)"
    issues+=("Мало свободного места")
fi

# CPU
if (( cpu_cores >= 2 )); then
    echo -e "  ${GREEN}✓${NC} CPU: Отлично (2+ cores)"
    score=$((score+2))
else
    echo -e "  ${YELLOW}⚠${NC} CPU: Минимум (1 core)"
    score=$((score+1))
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Final score
if (( score >= 5 )); then
    echo -e "${GREEN}⭐⭐⭐⭐⭐ ОТЛИЧНО!${NC} Идеально для Remnawave Node!"
elif (( score >= 3 )); then
    echo -e "${GREEN}⭐⭐⭐⭐ ХОРОШО!${NC} Подходит для Node."
else
    echo -e "${YELLOW}⭐⭐⭐ ПРИЕМЛЕМО.${NC} Будет работать, но есть ограничения."
    if [ ${#issues[@]} -gt 0 ]; then
        echo ""
        echo "Проблемы:"
        for issue in "${issues[@]}"; do
            echo "  • $issue"
        done
    fi
fi

echo ""
echo "💡 Для детального теста используйте полную версию скрипта"
echo "🔗 https://docs.rw"
echo ""
