# Minimal Arch Linux

Минималистичная графическая среда на базе Arch Linux.

## Стек

| Компонент | Программа |
|---|---|
| ОС | Arch Linux |
| Display Server | Xorg |
| Window Manager | BSPWM |
| Hotkey Daemon | sxhkd |
| Terminal | Alacritty |
| Shell | Fish |
| File Manager | PCManFM |
| Browser | Firefox |
| Application Launcher | Rofi |
| Status Bar | Polybar |
| Notifications | Dunst |
| Compositor | Picom |
| Wallpaper | feh |
| Audio | PipeWire + WirePlumber |
| Network | NetworkManager |

## Визуальный стиль

- Monochrome: black / white / gray
- Минималистичный интерфейс
- Отсутствие теней и размытия
- Прозрачность терминала: 90%
- Terminus / DejaVu fonts

## Установка

Скрипт рассчитан на чистую установку Arch Linux.

1. Создать файл:

   nano install-bspwm-minimal.sh

2. Вставить содержимое скрипта.
3. Сохранить файл.
4. Сделать его исполняемым:

   chmod +x install-bspwm-minimal.sh

5. Запустить:

   ./install-bspwm-minimal.sh

Скрипт запросит подтверждение перед установкой пакетов.

## Запуск графической среды

После завершения установки перезагрузить компьютер.

Перейти в TTY:

Ctrl + Alt + F3

Авторизоваться и выполнить:

startx

Display Manager не используется.

## Горячие клавиши

| Комбинация | Действие |
|---|---|
| Super + Enter | Alacritty |
| Super + D | Rofi |
| Super + E | PCManFM |
| Super + W | Firefox |
| Super + Q | Закрыть окно |
| Super + H/J/K/L | Переключение между окнами |
| Super + Shift + H/J/K/L | Перемещение окон |
| Super + 1-5 | Переключение рабочих столов |
| Super + Shift + 1-5 | Перемещение окна на рабочий стол |
| Super + Space | Переключение Floating |
| Super + F | Полноэкранный режим |
| Super + Shift + R | Перезапуск BSPWM |
| Super + Shift + Q | Выход из BSPWM |
| Super + Escape | Перезагрузка конфигурации sxhkd |

Super — клавиша Windows.

## Обои

Изображение необходимо поместить сюда:

~/Pictures/wallpaper.png

При следующем запуске BSPWM оно будет установлено автоматически.

## Picom

Picom используется для композитинга окон и поддержки прозрачности Alacritty.

Отключены:
- Shadows
- Fading
- Blur
- Dimming

## GPU

Видеокарта: AMD Radeon RX 5600 XT.

Используется открытый драйверный стек AMDGPU/Mesa.

## Конфигурации

Все конфигурации находятся в:

~/.config/

Основные файлы:

- bspwm/bspwmrc
- sxhkd/sxhkdrc
- alacritty/alacritty.toml
- fish/config.fish
- rofi/config.rasi
- polybar/config.ini
- dunst/dunstrc
- picom/picom.conf
