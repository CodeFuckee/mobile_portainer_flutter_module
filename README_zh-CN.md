<div style="text-align: center;">
  <img src="https://raw.githubusercontent.com/CodeFuckee/mobile_portainer_flutter/refs/heads/main/icon.png" />
</div>

# Mobile Portainer Flutter

[English](README.md) | [中文](README_zh-CN.md)

基于 Flutter 构建的强大 Docker 环境移动管理客户端。该应用程序允许您直接从移动设备管理多个 Docker 主机，提供实时监控和控制能力。

## ✨ 主要功能

### 🖥️ 服务器管理
- **多服务器支持**：添加并管理多个 Docker 端点。
- **仪表盘概览**：服务器状态一目了然，包括容器数量、镜像数量和 Git 版本。
- **资源监控**：服务器资源的实时可视化：
  - CPU 使用率
  - 内存使用率
  - 磁盘使用率
  - **GPU 监控**：支持 NVIDIA GPU 监控（温度、负载、显存）。
- **安全性**：支持忽略自签名证书的 SSL 验证。

### 📦 容器管理
- **列表与筛选**：查看所有容器或按状态（运行中、已停止、已退出等）和堆栈（Stack）筛选。
- **操作**：新增、启动、停止、重启、暂停、恢复、强制停止和删除容器。
- **详情**：深入查看容器配置：
  - **检查 (Inspect)**：完整的 JSON 检查。
  - **统计 (Stats)**：实时资源使用情况。
  - **日志 (Logs)**：查看容器日志。
  - **环境 (Environment)**：查看环境变量。
  - **网络 (Network)**：端口映射和网络设置。
  - **存储 (Storage)**：卷挂载和绑定。
  - **文件 (Files)**：浏览容器内的文件和文件夹。

### 🖼️ 镜像管理
- 列出可用镜像。
- 从仓库拉取新镜像。
- 删除未使用的镜像。
- 查看镜像详情（大小、ID、创建日期）。

### 💾 卷与网络管理
- **卷 (Volumes)**：列出并检查 Docker 卷。
- **网络 (Networks)**：查看 Docker 网络及其配置。

### 🌐 实时更新
- 通过 WebSocket 集成实现 Docker 主机的实时事件流推送。

## 📸 截图展示

<div align="center">
  <img src="images\dashboard.png" width="30%" />
  <img src="images\containers.png" width="30%" />
  <img src="images\resources.png" width="30%" />
</div>

## 🔌 后端支持

本应用依赖自托管的后端服务与 Docker 主机进行通信。您需要先部署后端服务。

- **后端仓库**：[mobile_portainer](https://github.com/CodeFuckee/mobile_portainer)

## 🚀 快速开始

### 前置要求
- Flutter SDK (3.10.0 或更高版本)
- Android Studio / Xcode (用于移动端部署)

### 安装步骤

1. **克隆仓库**
   ```bash
   git clone https://github.com/yourusername/mobile_portainer_flutter.git
   cd mobile_portainer_flutter
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   flutter run
   ```

## ⚙️ 配置指南

### 添加服务器
1. 导航至 **设置 (Settings)** 标签页。
2. 点击 **编辑服务器列表 (Edit Server List)** 按钮。
3. 添加新服务器，填写以下详情：
   - **名称 (Name)**：服务器的友好名称。
   - **URL**：Docker API 端点 (例如 `http://192.168.1.100:2375` 或 `https://portainer.example.com/api/endpoints/1/docker`)。
   - **API Key**：您的 Portainer API 密钥或 Docker 认证 Token。
   - **忽略 SSL (Ignore SSL)**：如果您的服务器使用自签名证书，请开启此选项。

## 🛠️ 技术栈

- **框架**：[Flutter](https://flutter.dev/)
- **语言**：[Dart](https://dart.dev/)
- **核心依赖**：
  - `http`: API 通信。
  - `web_socket_channel`: 实时事件。
  - `shared_preferences`: 设置的本地存储。
  - `flutter_localizations`: 国际化（支持英语和中文）。
  - `intl`: 日期和数字格式化。

## 未来计划

- **本地 Socket 支持**：实现对 `/var/run/docker.sock` 的直接通信，用于管理设备上的本地 Docker 实例（例如 Android/Termux 或已 root 设备）。

## 📄 许可证

本项目基于 MIT 许可证开源 - 详情请参阅 [LICENSE](LICENSE) 文件。
