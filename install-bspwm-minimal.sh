#!/usr/bin/env bash
set -Eeuo pipefail

# Minimal monochrome Arch Linux desktop:
# BSPWM + sxhkd + Alacritty + Fish.
# Picom is used only for Alacritty transparency.

readonly HOME_DIR="${HOME:?HOME is not set}"
readonly CONFIG_DIR="$HOME_DIR/.config"

log()  { printf '\033[1;36m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

write_config() {
    local target="$1"
    local mode="$2"
    mkdir -p "$(dirname "$target")"
    cat > "$target"
    chmod "$mode" "$target"
    log "Wrote $target"
}

[[ "$EUID" -ne 0 ]] || die "Не запускай скрипт через sudo."
[[ -f /etc/arch-release ]] || die "Скрипт предназначен для Arch Linux."
command -v sudo >/dev/null 2>&1 || die "Не найден sudo."
command -v pacman >/dev/null 2>&1 || die "Не найден pacman."

log "Будут установлены BSPWM, Xorg, приложения и Picom."
log "Конфигурации будут записаны напрямую, без резервных копий."

read -r -p "Продолжить? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

sudo -v

packages=(
    xorg-server
    xorg-xinit
    xorg-xrandr
    bspwm
    sxhkd
    alacritty
    fish
    firefox
    rofi
    feh
    polybar
    dunst
    picom
    networkmanager
    pipewire
    pipewire-pulse
    wireplumber
    pavucontrol
    terminus-font
    ttf-dejavu
    nano
    code
    btop
    fastfetch
    base-devel
    git
    xorg-setxkbmap
    ranger
    p7zip

    # AMD Radeon RX 5600 XT
    linux-firmware-amdgpu
    mesa
    vulkan-radeon
    libva-mesa-driver
)

log "Обновляю систему и устанавливаю пакеты..."
sudo pacman -Syu --needed "${packages[@]}"

# AUR helper: yay (prebuilt-source package, no Go compilation needed)
if command -v yay >/dev/null 2>&1; then
    log "yay уже установлен."
else
    log "Устанавливаю yay из AUR..."
    yay_tmp="$(mktemp -d)"
    if git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$yay_tmp/yay-bin" \
        && (cd "$yay_tmp/yay-bin" && makepkg -si --noconfirm --needed); then
        log "yay установлен."
    else
        warn "Не удалось установить yay. Установи вручную: https://aur.archlinux.org/packages/yay-bin"
    fi
    rm -rf "$yay_tmp"
fi

# Fish as default shell
if ! grep -Fxq '/usr/bin/fish' /etc/shells; then
    printf '%s\n' '/usr/bin/fish' | sudo tee -a /etc/shells >/dev/null
fi

current_shell="$(getent passwd "$USER" | cut -d: -f7)"

if [[ "$current_shell" != "/usr/bin/fish" ]]; then
    chsh -s /usr/bin/fish "$USER" \
        || warn "Не удалось сменить shell автоматически."
fi

# NetworkManager
sudo systemctl enable --now NetworkManager.service

# PipeWire
if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user enable --now \
        pipewire.socket \
        pipewire-pulse.socket \
        wireplumber.service \
        || warn "Не удалось включить PipeWire автоматически."
else
    warn "Пользовательский systemd manager недоступен."
fi

# Directories
mkdir -p \
    "$CONFIG_DIR/bspwm" \
    "$CONFIG_DIR/sxhkd" \
    "$CONFIG_DIR/alacritty" \
    "$CONFIG_DIR/fish" \
    "$CONFIG_DIR/rofi" \
    "$CONFIG_DIR/polybar" \
    "$CONFIG_DIR/dunst" \
    "$CONFIG_DIR/picom" \
    "$HOME_DIR/Pictures"

# ==========================================
# BSPWM
# ==========================================

write_config "$CONFIG_DIR/bspwm/bspwmrc" 755 <<'BSPWM'
#!/bin/sh

export SXHKD_SHELL=/bin/sh

if ! pgrep -x sxhkd >/dev/null 2>&1; then
    sxhkd &
fi

setxkbmap -layout "us,ru" -option "grp:win_space_toggle"

if ! pgrep -x dunst >/dev/null 2>&1; then
    dunst &
fi

if ! pgrep -x picom >/dev/null 2>&1; then
    picom --config "$HOME/.config/picom/picom.conf" --daemon
fi

bspc monitor -d 1 2 3 4 5 6

bspc config border_width 2
bspc config window_gap 10
bspc config split_ratio 0.50
bspc config borderless_monocle true
bspc config gapless_monocle true
bspc config focus_follows_pointer false
bspc config pointer_follows_focus false
bspc config automatic_scheme spiral
bspc config initial_polarity second_child
bspc config top_padding 26

# Mouse: Super + drag
#   LMB  - move window
#   MMB  - resize by nearest side
#   RMB  - resize by nearest corner
bspc config pointer_modifier mod4
bspc config pointer_action1 move
bspc config pointer_action2 resize_side
bspc config pointer_action3 resize_corner

bspc config normal_border_color '#333333'
bspc config active_border_color '#666666'
bspc config focused_border_color '#FFFFFF'

bspc rule -a Pavucontrol state=floating

if [ -x "$HOME/.config/polybar/launch.sh" ]; then
    "$HOME/.config/polybar/launch.sh" &
fi

if [ -f "$HOME/Pictures/wallpaper.png" ]; then
    feh --no-fehbg --bg-fill "$HOME/Pictures/wallpaper.png" &
fi
BSPWM

# ==========================================
# SXHKD
# ==========================================

write_config "$CONFIG_DIR/sxhkd/sxhkdrc" 644 <<'SXHKD'
# Terminal
super + Return
    alacritty

# Application launcher
super + d
    rofi -show drun

# Applications
super + e
    ranger

super + f
    firefox

# Close window
super + w
    bspc node -c

# Restart / quit BSPWM
super + shift + r
    bspc wm -r

super + shift + q
    bspc quit

# Reload sxhkd
super + Escape
    pkill -USR1 -x sxhkd

# Focus windows
super + {Left,Down,Up,Right}
    bspc node -f {west,south,north,east}

# Swap windows
super + shift + {Left,Down,Up,Right}
    bspc node -s {west,south,north,east}

# Switch desktops
super + {1-6}
    bspc desktop -f '^{1-6}'

# Move window to desktop
super + shift + {1-6}
    bspc node -d '^{1-6}'

# Floating / fullscreen
super + shift + space
    bspc node -t ~floating

super + m
    bspc node -t ~fullscreen

# Resize windows
super + ctrl + {Left,Down,Up,Right}
    bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}

# Move floating windows with keyboard
super + alt + {Left,Down,Up,Right}
    bspc node -v {-20 0,0 20,0 -20,20 0}
SXHKD

# ==========================================
# ALACRITTY
# ==========================================

write_config "$CONFIG_DIR/alacritty/alacritty.toml" 644 <<'ALACRITTY'
[window]
opacity = 0.70
decorations = "none"
padding = { x = 12, y = 10 }
dynamic_padding = true

[font]
size = 12.0

[font.normal]
family = "Terminus"
style = "Regular"

[font.bold]
family = "Terminus"
style = "Bold"

[colors.primary]
background = "#080808"
foreground = "#E5E5E5"

[colors.cursor]
text = "#080808"
cursor = "#FFFFFF"

[colors.normal]
black = "#111111"
red = "#AAAAAA"
green = "#CCCCCC"
yellow = "#888888"
blue = "#777777"
magenta = "#999999"
cyan = "#BBBBBB"
white = "#EEEEEE"

[colors.bright]
black = "#555555"
red = "#BBBBBB"
green = "#DDDDDD"
yellow = "#AAAAAA"
blue = "#999999"
magenta = "#CCCCCC"
cyan = "#DDDDDD"
white = "#FFFFFF"

[cursor]
style = "Block"
unfocused_hollow = false

[selection]
save_to_clipboard = true
ALACRITTY

# ==========================================
# FISH
# ==========================================

write_config "$CONFIG_DIR/fish/config.fish" 644 <<'FISH'
set -g fish_greeting

set -gx EDITOR nano
set -gx VISUAL nano

set -gx SXHKD_SHELL /bin/sh

alias ll 'ls -lah'
alias cls 'clear'
alias update 'sudo pacman -Syu'
alias install 'sudo pacman -S'

set -g fish_color_command white
set -g fish_color_param brwhite
set -g fish_color_error brwhite
set -g fish_color_quote white
set -g fish_color_autosuggestion brblack
FISH

# ==========================================
# ROFI
# ==========================================

write_config "$CONFIG_DIR/rofi/config.rasi" 644 <<'ROFI'
@theme "/dev/null"

configuration {
    modi: "drun";
    show-icons: false;
    display-drun: ">";
    drun-display-format: "{name}";
    disable-history: false;
    font: "DejaVu Sans Mono 10";
}

* {
    background-color: #080808;
    text-color: #CCCCCC;
    border: 0;
    margin: 0;
    padding: 0;
    spacing: 0;
}

window {
    location: center;
    anchor: center;
    width: 420px;
    border: 3px;
    border-color: #555555;
    padding: 0;
}

mainbox {
    padding: 14px;
    children: [ inputbar, listview ];
}

inputbar {
    padding: 0 0 12px 0;
    children: [ prompt, entry ];
}

prompt {
    text-color: #777777;
    padding: 0 10px 0 0;
}

entry {
    text-color: #FFFFFF;
    placeholder: "";
}

listview {
    lines: 8;
    columns: 1;
    scrollbar: false;
    fixed-height: true;
    spacing: 2px;
}

element, element normal.normal, element alternate.normal,
element normal.active, element alternate.active,
element normal.urgent, element alternate.urgent {
    padding: 6px 8px;
    border: 0;
    background-color: #080808;
    text-color: #888888;
}

element selected.normal, element selected.active, element selected.urgent {
    background-color: #333333;
    text-color: #FFFFFF;
}

element-text {
    background-color: transparent;
    text-color: inherit;
}
ROFI

# ==========================================
# POLYBAR
# ==========================================

write_config "$CONFIG_DIR/polybar/config.ini" 644 <<'POLYBAR'
[colors]
background = #080808
foreground = #EEEEEE
muted = #777777
border = #444444

[bar/main]
width = 100%
height = 26
fixed-center = true
bottom = false
background = ${colors.background}
foreground = ${colors.foreground}
override-redirect = false
wm-restack = bspwm
border-size = 0
padding-left = 2
padding-right = 2
module-margin = 1
font-0 = DejaVu Sans Mono:size=10
modules-left = bspwm
modules-center = date
modules-right = cpu memory gpu vram volume keyboard

[module/bspwm]
type = internal/bspwm
label-focused = %name%
label-focused-foreground = #FFFFFF
label-focused-padding = 2
label-occupied = %name%
label-occupied-foreground = #888888
label-occupied-padding = 2
label-empty = %name%
label-empty-foreground = #444444
label-empty-padding = 2

[module/date]
type = internal/date
interval = 30
date = %H:%M
label = %date%

[module/cpu]
type = internal/cpu
interval = 2
label = CPU %percentage%%

[module/memory]
type = internal/memory
interval = 5
label = RAM %percentage_used%%

[module/gpu]
type = custom/script
exec = sh ~/.config/polybar/gpu.sh usage
interval = 2
label = GPU %output%

[module/vram]
type = custom/script
exec = sh ~/.config/polybar/gpu.sh vram
interval = 3
label = VRAM %output%

[module/volume]
type = internal/pulseaudio
use-ui-max = false
interval = 5
format-volume = <label-volume>
label-volume = VOL %percentage%%
label-muted = VOL MUTE
label-muted-foreground = ${colors.muted}
# ЛКМ - открыть/закрыть регулировку громкости (pavucontrol)
# ПКМ - включить/выключить звук
# Колесо мыши - изменить громкость
click-left = sh -c 'pgrep -x pavucontrol >/dev/null && pkill -x pavucontrol || pavucontrol'
click-right = pactl set-sink-mute @DEFAULT_SINK@ toggle

[module/keyboard]
type = internal/xkeyboard
blacklist-0 = num lock
blacklist-1 = caps lock
blacklist-2 = scroll lock
format = <label-layout>
label-layout = %icon%
layout-icon-0 = us;US
layout-icon-1 = ru;RU
POLYBAR

# Polybar launch script
write_config "$CONFIG_DIR/polybar/launch.sh" 755 <<'POLYBARLAUNCH'
#!/bin/sh

pkill -x polybar 2>/dev/null || true

while pgrep -x polybar >/dev/null 2>&1; do
    sleep 0.2
done

polybar main -c "$HOME/.config/polybar/config.ini" &
POLYBARLAUNCH

# GPU / VRAM stats for AMD (amdgpu sysfs)
write_config "$CONFIG_DIR/polybar/gpu.sh" 755 <<'GPUSH'
#!/bin/sh
# Usage: gpu.sh usage|vram
# Finds the first card exposing amdgpu counters (card index may be 0, 1, ...).

dev=""
for d in /sys/class/drm/card[0-9]/device; do
    if [ -r "$d/gpu_busy_percent" ] && [ -r "$d/mem_info_vram_used" ]; then
        dev="$d"
        break
    fi
done

if [ -z "$dev" ]; then
    echo "N/A"
    exit 0
fi

case "$1" in
    usage)
        printf '%s%%\n' "$(cat "$dev/gpu_busy_percent")"
        ;;
    vram)
        used="$(cat "$dev/mem_info_vram_used")"
        total="$(cat "$dev/mem_info_vram_total")"
        awk -v u="$used" -v t="$total" \
            'BEGIN { printf "%.1f/%.1fG\n", u/1073741824, t/1073741824 }'
        ;;
    *)
        echo "N/A"
        ;;
esac
GPUSH

# ==========================================
# DUNST
# ==========================================

write_config "$CONFIG_DIR/dunst/dunstrc" 644 <<'DUNST'
[global]
    width = 300
    height = 100
    offset = 14x14
    origin = top-right
    font = "DejaVu Sans Mono 10"
    frame_width = 1
    frame_color = "#555555"
    separator_color = "#555555"
    background = "#080808"
    foreground = "#EEEEEE"
    corner_radius = 0
    transparency = 0

[urgency_low]
    background = "#080808"
    foreground = "#AAAAAA"
    frame_color = "#444444"

[urgency_normal]
    background = "#080808"
    foreground = "#FFFFFF"
    frame_color = "#666666"

[urgency_critical]
    background = "#222222"
    foreground = "#FFFFFF"
    frame_color = "#FFFFFF"
DUNST

# ==========================================
# PICOM
# ==========================================

write_config "$CONFIG_DIR/picom/picom.conf" 644 <<'PICOM'
# Only window compositing and client opacity.
# No shadows, fading, blur or dimming.

backend = "xrender";
vsync = false;

shadow = false;
fading = false;

active-opacity = 1.0;
inactive-opacity = 1.0;
detect-client-opacity = true;
PICOM

# ==========================================
# XINITRC
# ==========================================

write_config "$HOME_DIR/.xinitrc" 755 <<'XINITRC'
#!/bin/sh
exec bspwm
XINITRC

# ==========================================
# FINISH
# ==========================================

log "Обновляю кеш шрифтов."
fc-cache -f >/dev/null 2>&1 || warn "Не удалось обновить кеш шрифтов."

log "Проверяю установленные команды..."

for cmd in startx bspwm sxhkd alacritty fish pcmanfm firefox rofi polybar dunst picom feh; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf '  [OK] %s\n' "$cmd"
    else
        printf '  [MISSING] %s\n' "$cmd"
    fi
done

cat <<'DONE'

========================================
             ГОТОВО
========================================

Что дальше:

1. Перезагрузи компьютер.
2. Войди в систему под своим пользователем.
3. Перейди в TTY: Ctrl + Alt + F3.
4. Запусти графическую сессию:

   startx

ГОРЯЧИЕ КЛАВИШИ:

Super + Enter        Alacritty
Super + D            Rofi
Super + E            PCManFM
Super + F            Firefox
Super + W            Закрыть окно

Super + H/J/K/L      Переключение между окнами
Super + 1..6         Рабочие столы
Super + Shift + 1..6 Переместить окно

Win + Space          Переключить раскладку (RU/US в Polybar)
Super + Shift + Space Переключить floating
Super + M            Полноэкранный режим

Super + Ctrl + Left,Down,Up,Right  Изменить размер окна
Super + Alt + Left,Down,Up,Right   Сдвинуть floating-окно

МЫШЬ (Super + перетаскивание):

Super + ЛКМ          Переместить окно
Super + СКМ          Изменить размер (по стороне)
Super + ПКМ          Изменить размер (по углу)

Super + Shift + R    Перезапустить BSPWM
Super + Shift + Q    Выйти из BSPWM

Обои:

Положи изображение сюда:
~/Pictures/wallpaper.png

Picom работает только как композитор для прозрачности Alacritty.
Тени, размытие, затемнение и затухания отключены.

Для RX 5600 XT используется открытый драйверный стек AMDGPU/Mesa.
Загрузка GPU и VRAM берутся из sysfs (amdgpu) и показываются в Polybar.

DONE
