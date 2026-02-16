#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# REMNAWAVE NODE BENCHMARK SCRIPT v1.0
# ═══════════════════════════════════════════════════════════════════════════
# Комплексный тест VPS для Remnawave Node
# Включает: CPU, RAM, Disk I/O, Network, Оценка цена/качество
# 
# Использование: wget -qO- https://your-url/remnawave-node-bench.sh | bash
# Или: bash remnawave-node-bench.sh
# ═══════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════════════════
# ФУНКЦИИ
# ═══════════════════════════════════════════════════════════════════════════

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Оценка результата
rate_result() {
    local value=$1
    local min=$2
    local good=$3
    local excellent=$4
    
    if (( $(echo "$value >= $excellent" | bc -l) )); then
        echo -e "${GREEN}⭐⭐⭐⭐⭐ Отлично${NC}"
    elif (( $(echo "$value >= $good" | bc -l) )); then
        echo -e "${GREEN}⭐⭐⭐⭐ Хорошо${NC}"
    elif (( $(echo "$value >= $min" | bc -l) )); then
        echo -e "${YELLOW}⭐⭐⭐ Приемлемо${NC}"
    else
        echo -e "${RED}⭐⭐ Слабовато${NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# СИСТЕМНАЯ ИНФОРМАЦИЯ
# ═══════════════════════════════════════════════════════════════════════════

get_system_info() {
    print_header "СИСТЕМНАЯ ИНФОРМАЦИЯ"
    
    # Uptime
    uptime_sec=$(cat /proc/uptime | awk '{print $1}')
    uptime_days=$(echo "$uptime_sec/86400" | bc)
    uptime_hours=$(echo "($uptime_sec%86400)/3600" | bc)
    uptime_mins=$(echo "($uptime_sec%3600)/60" | bc)
    echo "Uptime       : $uptime_days дней, $uptime_hours часов, $uptime_mins минут"
    
    # CPU
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//')
    cpu_cores=$(grep -c '^processor' /proc/cpuinfo)
    cpu_freq=$(grep -m1 'cpu MHz' /proc/cpuinfo | awk '{print $4}')
    echo "Процессор    : $cpu_model"
    echo "CPU ядер     : $cpu_cores"
    echo "CPU частота  : ${cpu_freq} MHz"
    
    # Virtualization
    if [ -f /proc/cpuinfo ]; then
        if grep -q "vmx\|svm" /proc/cpuinfo; then
            virt_enabled="✓ Включена"
        else
            virt_enabled="✗ Отключена"
        fi
        echo "Виртуализация: $virt_enabled"
    fi
    
    # RAM
    total_ram=$(free -h | awk '/^Mem:/ {print $2}')
    used_ram=$(free -h | awk '/^Mem:/ {print $3}')
    free_ram=$(free -h | awk '/^Mem:/ {print $4}')
    echo "RAM (всего)  : $total_ram"
    echo "RAM (занято) : $used_ram"
    echo "RAM (свободно): $free_ram"
    
    # SWAP
    total_swap=$(free -h | awk '/^Swap:/ {print $2}')
    echo "SWAP         : $total_swap"
    
    # Диск
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    disk_free=$(df -h / | awk 'NR==2 {print $4}')
    disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    echo "Диск (всего) : $disk_total"
    echo "Диск (занято): $disk_used ($disk_usage)"
    echo "Диск (свободно): $disk_free"
    
    # OS
    if [ -f /etc/os-release ]; then
        os_name=$(grep '^PRETTY_NAME' /etc/os-release | cut -d'"' -f2)
    else
        os_name=$(uname -s)
    fi
    kernel=$(uname -r)
    arch=$(uname -m)
    echo "ОС           : $os_name"
    echo "Ядро         : $kernel"
    echo "Архитектура  : $arch"
    
    # Виртуализация
    if command -v systemd-detect-virt &> /dev/null; then
        virt_type=$(systemd-detect-virt)
        echo "Тип VM       : $virt_type"
    fi
    
    # IPv4/IPv6
    ipv4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "N/A")
    ipv6=$(curl -s -6 ifconfig.me 2>/dev/null || echo "N/A")
    echo "IPv4         : $ipv4"
    echo "IPv6         : $ipv6"
}

# ═══════════════════════════════════════════════════════════════════════════
# CPU ТЕСТЫ
# ═══════════════════════════════════════════════════════════════════════════

test_cpu() {
    print_header "CPU ТЕСТЫ"
    
    print_section "Простой CPU тест (SHA256)"
    
    # SHA256 test
    print_info "Хеширование 500MB данных..."
    sha_time=$(dd if=/dev/zero bs=1M count=500 2>/dev/null | sha256sum | awk '{print "done"}')
    sha_elapsed=$(dd if=/dev/zero bs=1M count=500 2>&1 | sha256sum >/dev/null && echo "done")
    
    # Простой CPU bench через dd + gzip
    print_info "Тест сжатия (bzip2)..."
    bzip_start=$(date +%s.%N)
    dd if=/dev/zero bs=1M count=100 2>/dev/null | bzip2 -9 > /dev/null 2>&1
    bzip_end=$(date +%s.%N)
    bzip_time=$(echo "$bzip_end - $bzip_start" | bc)
    echo "Время сжатия 100MB: ${bzip_time}s"
    
    # AES encryption test
    print_info "Тест AES шифрования..."
    aes_start=$(date +%s.%N)
    dd if=/dev/zero bs=1M count=100 2>/dev/null | openssl enc -aes-256-cbc -pass pass:test -pbkdf2 > /dev/null 2>&1
    aes_end=$(date +%s.%N)
    aes_time=$(echo "$aes_end - $aes_start" | bc)
    echo "Время шифрования 100MB: ${aes_time}s"
    
    # Оценка CPU
    print_section "Оценка CPU"
    
    # Простая математика для оценки
    if (( cpu_cores >= 4 )); then
        print_success "Количество ядер: отлично (4+)"
    elif (( cpu_cores >= 2 )); then
        print_success "Количество ядер: хорошо (2+)"
    else
        print_warning "Количество ядер: минимум (1)"
    fi
    
    # Проверка частоты
    cpu_freq_num=${cpu_freq%.*}
    if (( cpu_freq_num >= 2400 )); then
        print_success "Частота CPU: отлично (2.4+ GHz)"
    elif (( cpu_freq_num >= 2000 )); then
        print_success "Частота CPU: хорошо (2.0+ GHz)"
    else
        print_warning "Частота CPU: приемлемо (<2.0 GHz)"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# DISK I/O ТЕСТЫ
# ═══════════════════════════════════════════════════════════════════════════

test_disk() {
    print_header "DISK I/O ТЕСТЫ"
    
    print_section "Тест скорости диска (dd)"
    
    # Write test
    print_info "Тест записи (3 прогона)..."
    write_speeds=()
    for i in {1..3}; do
        write_speed=$(dd if=/dev/zero of=/tmp/test_write bs=64k count=16k conv=fdatasync 2>&1 | grep -oP '\d+\.?\d* [MG]B/s' | tail -1)
        write_speeds+=("$write_speed")
        echo "  Прогон $i: $write_speed"
        rm -f /tmp/test_write
    done
    
    # Read test
    print_info "Тест чтения (используем кэш)..."
    dd if=/dev/zero of=/tmp/test_read bs=64k count=16k 2>/dev/null
    read_speed=$(dd if=/tmp/test_read of=/dev/null bs=64k 2>&1 | grep -oP '\d+\.?\d* [MG]B/s' | tail -1)
    echo "  Скорость чтения: $read_speed"
    rm -f /tmp/test_read
    
    # IOPS test (если есть fio)
    if command -v fio &> /dev/null; then
        print_section "IOPS тест (fio)"
        print_info "4K random read IOPS..."
        
        fio --name=rand-read --ioengine=libaio --iodepth=32 --rw=randread \
            --bs=4k --direct=1 --size=128M --numjobs=1 --runtime=10 \
            --group_reporting --filename=/tmp/fio-test 2>/dev/null | \
            grep -E "read.*IOPS" | head -1
        
        rm -f /tmp/fio-test
    else
        print_warning "fio не установлен, пропускаем IOPS тест"
        print_info "Установка: apt install fio -y"
    fi
    
    # Оценка диска
    print_section "Оценка диска"
    
    # Простая эвристика для определения типа диска
    first_write="${write_speeds[0]}"
    if [[ $first_write == *"GB/s"* ]]; then
        print_success "Тип диска: NVMe SSD (⭐⭐⭐⭐⭐)"
        print_info "Идеально для Remnawave Node!"
    elif [[ $first_write == *"MB/s"* ]]; then
        speed_value=$(echo "$first_write" | grep -oP '\d+\.?\d*')
        if (( $(echo "$speed_value > 300" | bc -l) )); then
            print_success "Тип диска: Быстрый SSD (⭐⭐⭐⭐)"
        elif (( $(echo "$speed_value > 100" | bc -l) )); then
            print_success "Тип диска: SSD (⭐⭐⭐)"
        else
            print_warning "Тип диска: Медленный SSD или HDD (⭐⭐)"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# NETWORK ТЕСТЫ
# ═══════════════════════════════════════════════════════════════════════════

test_network() {
    print_header "NETWORK ТЕСТЫ"
    
    print_section "Speedtest (curl к CDN)"
    
    # Проверяем доступность curl
    if ! command -v curl &> /dev/null; then
        print_error "curl не установлен!"
        return 1
    fi
    
    # Тест загрузки с разных CDN
    declare -A cdn_urls=(
        ["Cachefly (US)"]="http://cachefly.cachefly.net/100mb.test"
        ["OVH (FR)"]="http://proof.ovh.net/files/100Mb.dat"
        ["Hetzner (DE)"]="http://speed.hetzner.de/100MB.bin"
    )
    
    for location in "${!cdn_urls[@]}"; do
        url="${cdn_urls[$location]}"
        echo -n "  $location: "
        
        speed=$(curl -o /dev/null -s -w '%{speed_download}' --max-time 15 "$url" 2>/dev/null)
        
        if [ -z "$speed" ] || [ "$speed" = "0" ]; then
            echo "N/A"
        else
            # Конвертируем в MB/s
            speed_mb=$(echo "scale=2; $speed / 1024 / 1024" | bc)
            echo "${speed_mb} MB/s"
        fi
    done
    
    # Ping тесты
    print_section "Latency тесты (ping)"
    
    declare -A ping_hosts=(
        ["Google DNS"]="8.8.8.8"
        ["Cloudflare"]="1.1.1.1"
        ["Europe"]="ping.online.net"
    )
    
    for name in "${!ping_hosts[@]}"; do
        host="${ping_hosts[$name]}"
        echo -n "  $name ($host): "
        
        ping_result=$(ping -c 3 -W 2 "$host" 2>/dev/null | tail -1 | awk -F '/' '{print $5}')
        
        if [ -z "$ping_result" ]; then
            echo "N/A"
        else
            echo "${ping_result} ms"
        fi
    done
    
    # Оценка сети
    print_section "Оценка сети"
    
    print_info "Для Remnawave Node важны:"
    echo "  • Стабильный uplink (100+ Mbps)"
    echo "  • Низкий ping к основным регионам (<150ms)"
    echo "  • Достаточный bandwidth (обычно 1-5 TB/мес)"
}

# ═══════════════════════════════════════════════════════════════════════════
# ПРОВЕРКА ПРИГОДНОСТИ ДЛЯ REMNAWAVE NODE
# ═══════════════════════════════════════════════════════════════════════════

check_remnawave_suitability() {
    print_header "ПРОВЕРКА ПРИГОДНОСТИ ДЛЯ REMNAWAVE NODE"
    
    issues=0
    warnings=0
    
    # RAM check
    total_ram_mb=$(free -m | awk '/^Mem:/ {print $2}')
    echo -n "RAM: ${total_ram_mb}MB - "
    if (( total_ram_mb >= 2048 )); then
        print_success "Отлично (2GB+)"
    elif (( total_ram_mb >= 1024 )); then
        print_success "Хорошо (1GB+)"
        warnings=$((warnings+1))
    else
        print_error "Недостаточно (<1GB)"
        issues=$((issues+1))
    fi
    
    # Disk check
    disk_free_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    echo -n "Свободно на диске: ${disk_free_gb}GB - "
    if (( disk_free_gb >= 20 )); then
        print_success "Отлично (20GB+)"
    elif (( disk_free_gb >= 10 )); then
        print_success "Хорошо (10GB+)"
    else
        print_warning "Маловато (<10GB)"
        warnings=$((warnings+1))
    fi
    
    # CPU cores check
    echo -n "CPU ядер: $cpu_cores - "
    if (( cpu_cores >= 2 )); then
        print_success "Отлично (2+)"
    elif (( cpu_cores >= 1 )); then
        print_success "Минимум (1)"
        warnings=$((warnings+1))
    fi
    
    # IPv4 check
    echo -n "IPv4: "
    if [ "$ipv4" != "N/A" ]; then
        print_success "Доступен ($ipv4)"
    else
        print_error "Недоступен"
        issues=$((issues+1))
    fi
    
    # Virtualization type
    if [ -n "$virt_type" ] && [ "$virt_type" != "none" ]; then
        echo -n "Виртуализация: $virt_type - "
        if [ "$virt_type" = "kvm" ] || [ "$virt_type" = "xen" ]; then
            print_success "Хорошо"
        else
            print_warning "Работает, но не идеально"
            warnings=$((warnings+1))
        fi
    fi
    
    # Итоговая оценка
    echo ""
    print_section "ИТОГОВАЯ ОЦЕНКА"
    
    if (( issues == 0 && warnings == 0 )); then
        print_success "⭐⭐⭐⭐⭐ ОТЛИЧНО! Идеально подходит для Remnawave Node!"
    elif (( issues == 0 && warnings <= 2 )); then
        print_success "⭐⭐⭐⭐ ХОРОШО! Подходит для Remnawave Node с небольшими оговорками."
    elif (( issues <= 1 )); then
        print_warning "⭐⭐⭐ ПРИЕМЛЕМО. Будет работать, но лучше улучшить некоторые параметры."
    else
        print_error "⭐⭐ НЕ РЕКОМЕНДУЕТСЯ. Слишком много проблем для стабильной работы."
    fi
    
    echo ""
    echo "Проблем: $issues | Предупреждений: $warnings"
}

# ═══════════════════════════════════════════════════════════════════════════
# СРАВНЕНИЕ ЦЕН
# ═══════════════════════════════════════════════════════════════════════════

compare_pricing() {
    print_header "СРАВНЕНИЕ ЦЕН VPS (2026)"
    
    echo ""
    echo "Типичные цены на VPS для нод в 2026:"
    echo ""
    echo -e "${GREEN}БЮДЖЕТНЫЕ ($2-5/мес):${NC}"
    echo "  • IONOS     : от $2/мес  (1 vCPU, 1GB RAM, 10GB NVMe)"
    echo "  • OVH       : от $3/мес  (1 vCPU, 2GB RAM, 20GB SSD)"
    echo "  • Contabo   : от $4/мес  (2 vCPU, 4GB RAM, 50GB SSD)"
    echo ""
    echo -e "${CYAN}СРЕДНИЕ ($5-15/мес):${NC}"
    echo "  • Hetzner   : от $5/мес  (2 vCPU, 4GB RAM, 40GB SSD) ⭐"
    echo "  • DigitalOcean: от $6/мес (1 vCPU, 1GB RAM, 25GB SSD)"
    echo "  • SSD Nodes : от $8/мес  (2 vCPU, 4GB RAM, 60GB SSD)"
    echo "  • Vultr     : от $6/мес  (1 vCPU, 1GB RAM, 25GB SSD)"
    echo ""
    echo -e "${YELLOW}ПРЕМИУМ ($15-30/мес):${NC}"
    echo "  • AWS       : от $15/мес (2 vCPU, 4GB RAM, 20GB SSD)"
    echo "  • Linode    : от $12/мес (2 vCPU, 4GB RAM, 80GB SSD)"
    echo ""
    echo -e "${BLUE}💡 Рекомендации для Remnawave Node:${NC}"
    echo "  • Минимум: 1GB RAM, 1 vCPU, 10GB SSD"
    echo "  • Оптимум: 2GB RAM, 2 vCPU, 20GB NVMe"
    echo "  • Bandwidth: 1-5TB/мес"
    echo "  • Лучшие провайдеры: Hetzner, OVH, DigitalOcean"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# РЕКОМЕНДАЦИИ
# ═══════════════════════════════════════════════════════════════════════════

print_recommendations() {
    print_header "РЕКОМЕНДАЦИИ"
    
    echo ""
    echo "📋 Чеклист для Remnawave Node:"
    echo ""
    echo "  ✓ Минимум 1GB RAM (2GB рекомендуется)"
    echo "  ✓ SSD или NVMe диск"
    echo "  ✓ Стабильный network с низким пингом"
    echo "  ✓ KVM или Xen виртуализация (предпочтительно)"
    echo "  ✓ Достаточный bandwidth (1TB+ в месяц)"
    echo "  ✓ IPv4 адрес"
    echo ""
    echo "🔧 Установка Remnawave Node:"
    echo ""
    echo "  1. Обновите систему:"
    echo "     apt update && apt upgrade -y"
    echo ""
    echo "  2. Установите Docker:"
    echo "     curl -fsSL https://get.docker.com | sh"
    echo ""
    echo "  3. Следуйте инструкции:"
    echo "     https://docs.rw/docs/install/remnawave-node"
    echo ""
    echo "📊 Мониторинг производительности:"
    echo ""
    echo "  • htop          - процессы и память"
    echo "  • iotop         - диск I/O"
    echo "  • iftop         - сеть"
    echo "  • docker stats  - статистика контейнеров"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    clear
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}║        REMNAWAVE NODE BENCHMARK SCRIPT v1.0                   ║${NC}"
    echo -e "${CYAN}║        Комплексное тестирование VPS                           ║${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    start_time=$(date +%s)
    
    # Проверка прав
    if [ "$EUID" -ne 0 ]; then 
        print_warning "Скрипт запущен не от root. Некоторые тесты могут быть недоступны."
        echo ""
    fi
    
    # Запуск тестов
    get_system_info
    test_cpu
    test_disk
    test_network
    check_remnawave_suitability
    compare_pricing
    print_recommendations
    
    # Время выполнения
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    
    print_header "ЗАВЕРШЕНО"
    echo "Время выполнения: ${elapsed}s"
    echo ""
    echo -e "${GREEN}Тестирование завершено успешно!${NC}"
    echo ""
    echo "📝 Сохраните результаты для сравнения с другими VPS"
    echo "🔗 Документация: https://docs.rw"
    echo "💬 Telegram: https://t.me/remnawave"
    echo ""
}

# Запуск
main
