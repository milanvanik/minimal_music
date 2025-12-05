# Minimal Music - Offline Music Player

Minimal Music is a clean, lightweight, and intuitive offline music player designed to help you enjoy your local music collection without distractions. Manage your songs, create playlists, and customize your listening experience with a simple and modern interface.

This repository contains the complete source code for the Minimal Music application.

## Features

Minimal Music is designed to provide a seamless listening experience:

• 🎵 **Local Playback**: Play audio files directly from your device storage with support for common formats.\
• 📂 **Folder Management**: Scan and organize music from specific folders on your device.\
• 🗂️ **Custom Playlists**: Create, manage, and organize your favorite tracks into playlists.\
• 🔍 **Smart Search**: Quickly find songs, artists, or albums with an efficient search bar.\
• 🎧 **Background Playback**: Keep the music playing while using other apps or when the screen is off, with full notification controls.\
• ⚙️ **Settings & Customization**: Manage app preferences and scan settings.\
• 📊 **Clean Interface**: A distraction-free UI focused on your music.\

## Screenshots

Here's a sneak peek at the clean and user-friendly interface of Minimal Music.

![App Screenshots](assets/screenshots/preview.png)

## Tech Stack

*   **Framework**: Flutter
*   **State Management**: Provider
*   **Audio Engine**: just_audio, audio_service
*   **Background Playback**: just_audio_background
*   **Storage**: shared_preferences
*   **Permissions**: permission_handler

## Getting Started

To use this App, follow the instructions below:

### Prerequisites

Ensure you have Flutter installed on your machine. For more information on installing Flutter, refer to the official [Flutter documentation](https://docs.flutter.dev/get-started/install).

### Installation

1.  **Clone the repo**
    ```bash
    git clone https://github.com/milanrnw/minimal_music.git
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the app**
    Connect your device or start an emulator.
    ```bash
    flutter run
    ```
