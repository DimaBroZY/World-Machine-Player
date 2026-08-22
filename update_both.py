# coding=utf8
import re

# English
with open("README.md", "r", encoding="utf-8") as f:
    content = f.read()

start_idx = content.find("## 🌟")
end_idx = content.find("## 📥")

if start_idx != -1 and end_idx != -1:
    new_features = """## 🌟 Features

### 🎶 **Music Playback**
- **Multi-format Support**: Plays `.ogg`, `.mp3`, `.flac`, and `.opus` audio files
- **Audio Engine**: Powered by a custom BASS engine wrapper, providing a significant performance boost
- **Track Navigation**: Next/Previous track controls and convenient track selection
- **Playback Controls**: Play, Pause, Stop, and Restart functionality

### 🎛️ **Audio Controls**
- **Volume Control**: Precise volume adjustment
- **Speed Control**: Playback speed adjustment from 50-150% 
- **Crossfade**: Smooth transitions between tracks with customizable settings
- **Loop Playback**: Automatic track looping

### 📂 **Organization & Modes**
- **Playlists**: Full playlist system to create, manage, and color-customize your lists
- **Radio Mode**: Built-in radio with metadata parsing and support for adding custom stations
- **Built-in File Explorer**: Custom file explorer for convenient music folder selection

### 🎨 **Customization & Integration**
- **Themes**: Multiple visual themes to customize the player's appearance and match your mood  
- **Discord RPC**: Discord integration to show your friends what you are currently listening to
- **Windows SMTC**: Support for Windows System Media Transport Controls

### ⚙️ **Settings**
- **Custom Music Folder**: Set your own music directory
- **Settings Persistence**: All preferences saved automatically


"""
    content = content[:start_idx] + new_features + content[end_idx:]

with open("README.md", "w", encoding="utf-8") as f:
    f.write(content)

# Russian
with open("README_ru.md", "r", encoding="utf-8") as f:
    content = f.read()

start_idx = content.find("## 🌟")
end_idx = content.find("## 📥")

if start_idx != -1 and end_idx != -1:
    new_features = """## 🌟 Основные возможности

### 🎶 **Воспроизведение музыки**
* **Мультиформатность**: Поддерживает файлы `.ogg`, `.mp3`, `.flac` и `.opus`
* **Движок**: Используется кастомный аудиодвижок BASS, что дает ощутимый прирост производительности
* **Навигация по трекам**: Кнопки следующий/предыдущий трек и удобный выбор треков
* **Управление воспроизведением**: Воспроизведение, пауза, стоп и рестарт

### 🎛️ **Аудио контроль**
* **Управление громкостью**: Точная настройка уровня звука
* **Управление скоростью**: Изменение скорости воспроизведения от 50% до 150%
* **Кроссфейд (Плавный переход)**: Плавные переходы между треками с возможностью настройки
* **Повтор трека**: Автоматическое зацикливание

### 📂 **Организация и Режимы**
* **Плейлисты**: Полноценная система создания плейлистов, управления ими и цветовой кастомизации
* **Радио-режим**: Добавлен радио-режим с поддержкой метаданных и возможностью добавлять собственные радиостанции
* **Встроенный файловый менеджер**: Встроенный кастомный File Explorer для работы с файлами

### 🎨 **Кастомизация и Интеграция**
* **Темы**: Несколько визуальных тем, чтобы плеер соответствовал вашему настроению
* **Discord RPC**: Интеграция с Discord, чтобы друзья видели, что вы сейчас слушаете
* **Windows SMTC**: Поддержка системных элементов управления мультимедиа Windows

### ⚙️ **Настройки**
* **Своя папка**: Укажите путь к вашей папке с музыкой
* **Сохранение настроек**: Все настройки сохраняются автоматически


"""
    content = content[:start_idx] + new_features + content[end_idx:]

with open("README_ru.md", "w", encoding="utf-8") as f:
    f.write(content)