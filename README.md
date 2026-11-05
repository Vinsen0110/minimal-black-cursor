# Minimal 黑色白边阴影鼠标主题

macOS 自定义鼠标指针主题：黑色主体、白色描边、柔和阴影。

## 特性

- **普通箭头**：80% 大小，细白边、直边小圆角尖端
- **链接手型**：短食指
- **其他指针**：75% 大小
- **一键安装**：无需 GUI、无需管理员密码
- **登录自启**：配置后每次登录自动应用

## 兼容性

- **Apple 芯片 + macOS 27+**：原生 arm64 工具
- **Apple 芯片 + 旧版 macOS**：Intel 工具（需 Rosetta）
- **Intel Mac**：Intel 工具

已在 Apple 芯片 macOS 27.0.1 上验证。

## 快速使用

### 1. 安装主题

下载并解压本项目，双击 **一键安装鼠标.command**：

- 自动检查文件完整性
- 复制工具和主题到系统目录
- 立即应用主题

### 2. 设置登录自启（推荐）

运行以下命令创建登录启动项：

```bash
cat > ~/Library/LaunchAgents/local.minimalblack80.login.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>local.minimalblack80.login</string>
    <key>ProgramArguments</key>
    <array>
        <string>$HOME/Library/Application Support/MinimalBlack80/mousecloak-arm64</string>
        <string>--suppressCopyright</string>
        <string>--apply</string>
        <string>$HOME/Library/Application Support/Mousecape/capes/local.minimal.cursor.softblack75.cape</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Application Support/MinimalBlack80/login.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Application Support/MinimalBlack80/login.stderr.log</string>
</dict>
</plist>
EOF

# 验证文件格式
plutil -lint ~/Library/LaunchAgents/local.minimalblack80.login.plist

# 设置权限
chmod 644 ~/Library/LaunchAgents/local.minimalblack80.login.plist

# 加载启动项
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.minimalblack80.login.plist
```

注销或重启后会自动应用主题。

### 3. 移除启动项

```bash
launchctl bootout gui/$(id -u)/local.minimalblack80.login
rm ~/Library/LaunchAgents/local.minimalblack80.login.plist
```

## 目录结构

```
.
├── 一键安装鼠标.command    # 安装脚本
├── 先看这里.txt           # 详细说明
├── bin/                  # 命令行工具
│   ├── mousecloak-arm64
│   └── mousecloak-x86_64
├── Themes/               # 主题文件
│   ├── Minimal-Soft-Black-75.cape
│   └── 全套预览.png
├── Software/             # 官方 Mousecape GUI（可选）
│   └── Mousecape_1813.zip
├── Preview/              # 预览图
├── SHA256SUMS.txt        # 文件校验
└── Mousecape-LICENSE.txt # 许可证
```

## 安装后的文件位置

- **工具**：`~/Library/Application Support/MinimalBlack80/mousecloak-arm64`
- **主题**：`~/Library/Application Support/Mousecape/capes/local.minimal.cursor.softblack75.cape`
- **日志**：`~/Library/Application Support/MinimalBlack80/login.*.log`

安装完成后，可以删除本项目文件夹，不影响使用。

## 恢复系统默认指针

使用 Mousecape GUI 的恢复默认功能，或运行：

```bash
# 停用并移除启动项
launchctl bootout gui/$(id -u)/local.minimalblack80.login
rm ~/Library/LaunchAgents/local.minimalblack80.login.plist

# 恢复默认指针（需要 Mousecape 工具）
~/Library/Application\ Support/MinimalBlack80/mousecloak-arm64 --restore
```

## 安全说明

- 本包未获 Apple 公证，首次运行可能需要在"隐私与安全性"中允许
- 不需要关闭 Gatekeeper 或 SIP
- 不需要 sudo 或管理员权限
- 仅修改用户目录下的文件

## 许可证

基于 [Mousecape](https://github.com/alexzielenski/Mousecape) 项目，仅限个人非商业用途。

完整许可条款见 [Mousecape-LICENSE.txt](Mousecape-LICENSE.txt)。

## 鸣谢

- [Mousecape](https://github.com/alexzielenski/Mousecape) by @alexzielenski
- arm64 工具由该项目源码本地编译（最低 macOS 27.0）
