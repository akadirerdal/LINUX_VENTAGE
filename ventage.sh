#!/bin/bash

# ================= TMUX ENTEGRASYONU =================

if [[ -z "$TMUX" ]]; then
    if command -v tmux >/dev/null 2>&1; then
        tmux new-session -d -s powerpanel "$0"
        tmux attach -t powerpanel
        exit
    else
        echo "tmux kurulu değil. sudo pacman -S tmux"
        exit 1
    fi
fi

CPU_GOVERNOR="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
TURBO_PATH="/sys/devices/system/cpu/intel_pstate/no_turbo"

DGPU_PCI="0000:03:00.0"
DGPU_DRM="/sys/class/drm/card0/device"
IGPU_DRM="/sys/class/drm/card1/device"

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ================= SENSORS (TMUX SPLIT) =================

start_sensors_terminal() {
    tmux split-window -h "watch sensors"
    tmux select-pane -L
    SENSORS_PANE=$(tmux list-panes -F "#{pane_id}" | tail -n1)
}

stop_sensors_terminal() {
    [[ -n "$SENSORS_PANE" ]] && tmux kill-pane -t "$SENSORS_PANE" 2>/dev/null
}

start_sensors_terminal
trap stop_sensors_terminal EXIT

# ================= CPU =================

get_cpu_mode() { cat $CPU_GOVERNOR 2>/dev/null; }

set_cpu_mode() {
    MODE=$1
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo $MODE | sudo tee $cpu > /dev/null 2>&1
    done
}

enable_turbo() { echo 0 | sudo tee $TURBO_PATH > /dev/null 2>&1; }
disable_turbo() { echo 1 | sudo tee $TURBO_PATH > /dev/null 2>&1; }

get_turbo_status() {
    [[ $(cat $TURBO_PATH 2>/dev/null) == 0 ]] && echo "AÇIK" || echo "KAPALI"
}

# ================= GPU =================

gpu_enable() { sudo sh -c "echo 1 > /sys/bus/pci/rescan"; }
gpu_disable() { sudo sh -c "echo 1 > /sys/bus/pci/devices/$DGPU_PCI/remove"; }

dgpu_performance() { echo on | sudo tee $DGPU_DRM/power/control > /dev/null 2>&1; }
dgpu_auto() { echo auto | sudo tee $DGPU_DRM/power/control > /dev/null 2>&1; }

get_gpu_status() {
    if [[ -d "/sys/bus/pci/devices/$DGPU_PCI" ]]; then
        MODE=$(cat $DGPU_DRM/power/control 2>/dev/null)
        echo "AKTİF ($MODE)"
    else
        echo "KAPALI"
    fi
}

# ================= Dahili GPU =================

get_igpu_status() {
    if [[ -f "$IGPU_DRM/power/control" ]]; then
        MODE=$(cat $IGPU_DRM/power/control 2>/dev/null)
        if [[ "$MODE" == "auto" ]]; then
            echo "POWERSAVE"
        elif [[ "$MODE" == "on" ]]; then
            echo "PERFORMANCE"
        else
            echo "$MODE"
        fi
    else
        echo "Bulunamadı"
    fi
}

igpu_min() { echo auto | sudo tee $IGPU_DRM/power/control > /dev/null 2>&1; }
igpu_normal() { echo on | sudo tee $IGPU_DRM/power/control > /dev/null 2>&1; }

# ================= BATARYA =================

get_battery_info() {
    BAT=$(ls /sys/class/power_supply/ | grep BAT | head -n1)

    CAP=$(cat /sys/class/power_supply/$BAT/capacity 2>/dev/null)
    STAT=$(cat /sys/class/power_supply/$BAT/status 2>/dev/null)

    ENERGY_NOW=$(cat /sys/class/power_supply/$BAT/energy_now 2>/dev/null)
    POWER_NOW=$(cat /sys/class/power_supply/$BAT/power_now 2>/dev/null)

    if [[ "$STAT" == "Discharging" && -n "$POWER_NOW" && "$POWER_NOW" -gt 0 ]]; then
        HOURS=$(echo "scale=2; $ENERGY_NOW / $POWER_NOW" | bc)
        MINUTES=$(echo "$HOURS * 60" | bc | cut -d'.' -f1)
        H=$((MINUTES / 60))
        M=$((MINUTES % 60))
        TIME="${H}s ${M}dk"
    else
        TIME="--"
    fi

    echo "$CAP% | $STAT | Tahmini: $TIME"
}

# ================= MODLAR =================

hibrit_mod() {
    BAT=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null)
    if [[ "$BAT" == "Charging" ]] || [[ "$BAT" == "Full" ]]; then
        set_cpu_mode performance
        enable_turbo
        gpu_enable
        dgpu_performance
        igpu_normal
    else
        set_cpu_mode powersave
        disable_turbo
        gpu_disable
        igpu_min
    fi
}

extra_saving_mod() {
    set_cpu_mode powersave
    disable_turbo
    gpu_disable
    igpu_min
}

performance_mod() {
    set_cpu_mode performance
    enable_turbo
    gpu_enable
    dgpu_performance
    igpu_normal
}

# ================= ARAYÜZ =================

draw_line() { printf "${CYAN}==============================================${NC}\n"; }

show_status() {
    clear
    draw_line
    printf "${WHITE}        SİSTEM KONTROL PANELİ${NC}\n"
    draw_line
    echo ""

    printf "CPU Modu       : ${YELLOW}%s${NC}\n" "$(get_cpu_mode)"
    printf "Turbo Boost    : ${GREEN}%s${NC}\n" "$(get_turbo_status)"
    printf "Harici GPU     : ${CYAN}%s${NC}\n" "$(get_gpu_status)"
    printf "Dahili GPU     : ${CYAN}%s${NC}\n" "$(get_igpu_status)"
    printf "Pil Durumu     : ${GREEN}%s${NC}\n" "$(get_battery_info)"

    echo ""
    draw_line
    echo -e "${WHITE}1)${NC} Hibrit Mod"
    echo -e "${WHITE}2)${NC} Ekstra Tasarruf"
    echo -e "${WHITE}3)${NC} Performans Modu"
    echo -e "${WHITE}4)${NC} Manuel Mod"
    echo -e "${WHITE}5)${NC} Çıkış"
    draw_line
}

manuel_menu() {
    while true; do
        clear
        draw_line
        printf "${WHITE}           MANUEL MOD${NC}\n"
        draw_line
        echo ""
        printf "CPU Modu       : ${YELLOW}%s${NC}\n" "$(get_cpu_mode)"
        printf "Turbo Boost    : ${GREEN}%s${NC}\n" "$(get_turbo_status)"
        printf "Harici GPU     : ${CYAN}%s${NC}\n" "$(get_gpu_status)"
        printf "Dahili GPU     : ${CYAN}%s${NC}\n" "$(get_igpu_status)"
        printf "Pil Durumu     : ${GREEN}%s${NC}\n" "$(get_battery_info)"
        echo ""
        draw_line

        echo -e "${WHITE}1)${NC} Harici GPU Aç"
        echo -e "${WHITE}2)${NC} Harici GPU Kapat"
        echo -e "${WHITE}3)${NC} Harici GPU Performans"
        echo -e "${WHITE}4)${NC} Harici GPU Minimum"
        echo -e "${WHITE}5)${NC} Dahili GPU Powersave"
        echo -e "${WHITE}6)${NC} Dahili GPU Performance"
        echo -e "${WHITE}7)${NC} Turbo Aç"
        echo -e "${WHITE}8)${NC} Turbo Kapat"
        echo -e "${WHITE}9)${NC} Geri"
        draw_line
        read -p "Seçim: " msec

        case $msec in
            1) gpu_enable ;;
            2) gpu_disable ;;
            3) dgpu_performance ;;
            4) dgpu_auto ;;
            5) igpu_min ;;
            6) igpu_normal ;;
            7) enable_turbo ;;
            8) disable_turbo ;;
            9) break ;;
        esac
    done
}

while true; do
    show_status
    read -p "Seçim: " secim
    case $secim in
        1) hibrit_mod ;;
        2) extra_saving_mod ;;
        3) performance_mod ;;
        4) manuel_menu ;;
        5) exit 0 ;;
    esac
done