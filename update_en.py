# coding=utf8
import re

with open("README.md", "r", encoding="utf-8") as f:
    content = f.read()

start_idx = content.find("## \u1f31f")
if start_idx == -1:
    start_idx = content.find("## \u2b50")
if start_idx == -1:
    start_idx = content.find("## ✨")
if start_idx == -1:
    start_idx = content.find("## 🌟")
    
end_idx = content.find("## \u1f4e5")
if end_idx == -1:
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