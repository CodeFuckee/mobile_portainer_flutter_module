<div style="text-align: center;">
  <img src="https://raw.githubusercontent.com/CodeFuckee/mobile_portainer_flutter/refs/heads/main/icon.png" />
</div>

# Mobile Portainer Flutter

[English](README.md) | [中文](README_zh-CN.md)

A powerful mobile management client for Docker environments, built with Flutter. This application allows you to manage multiple Docker hosts directly from your mobile device, providing real-time monitoring and control capabilities.

## ✨ Key Features

### 🖥️ Server Management
- **Multi-Server Support**: Add and manage multiple Docker endpoints.
- **Dashboard Overview**: At-a-glance view of server status including container counts, image counts, and git version.
- **Resource Monitoring**: Real-time visualization of server resources:
  - CPU Usage
  - Memory Usage
  - Disk Usage
  - **GPU Monitoring**: Support for NVIDIA GPU monitoring (Temperature, Load, Memory).
- **Security**: Option to ignore SSL certificate verification for self-signed certificates.

### 📦 Container Management
- **List & Filter**: View all containers or filter by status (Running, Stopped, Exited, etc.) and Stacks.
- **Actions**: Add, Start, Stop, Restart, Pause, Unpause, Kill, and Remove containers.
- **Details**: Deep dive into container configuration:
  - **Inspect**: Full JSON inspection.
  - **Stats**: Real-time resource usage.
  - **Logs**: View container logs.
  - **Environment**: View environment variables.
  - **Network**: Port mappings and network settings.
  - **Storage**: Volume mounts and binds.
  - **Files**: Browse container files and folders.

### 🖼️ Image Management
- List available images.
- Pull new images from registries.
- Remove unused images.
- View image details (Size, ID, Created date).

### 💾 Volume & Network Management
- **Volumes**: List and inspect Docker volumes.
- **Networks**: View Docker networks and their configurations.

### 🌐 Real-time Updates
- Powered by WebSocket integration for live event streaming from Docker hosts.

## 📱 Screenshots

<div align="center">
  <img src="images\dashboard.png" width="30%" />
  <img src="images\containers.png" width="30%" />
  <img src="images\resources.png" width="30%" />
</div>

## 🔌 Backend Support

This application relies on a self-hosted backend service to communicate with Docker hosts. You need to deploy the backend service first.

- **Backend Repository**: [mobile_portainer](https://github.com/CodeFuckee/mobile_portainer)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.0 or higher)
- Android Studio / Xcode (for mobile deployment)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/mobile_portainer_flutter.git
   cd mobile_portainer_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## ⚙️ Configuration

### Adding a Server
1. Navigate to the **Settings** tab.
2. Click on the **Edit Server List** button.
3. Add a new server with the following details:
   - **Name**: A friendly name for your server.
   - **URL**: The Docker API endpoint (e.g., `http://192.168.1.100:2375` or `https://portainer.example.com/api/endpoints/1/docker`).
   - **API Key**: Your Portainer API key or Docker Auth token.
   - **Ignore SSL**: Toggle this if your server uses a self-signed certificate.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: [Dart](https://dart.dev/)
- **Key Dependencies**:
  - `http`: API communication.
  - `web_socket_channel`: Real-time events.
  - `shared_preferences`: Local storage for settings.
  - `flutter_localizations`: Internationalization (English & Chinese support).
  - `intl`: Date and number formatting.

## 🔮 Future Plans

- **Local Socket Support**: Implementation of direct `/var/run/docker.sock` communication for managing the local Docker instance on the device (e.g., Android/Termux or rooted devices).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
