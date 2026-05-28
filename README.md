# UniHub

**个人工具箱**——用 Flutter 构建的桌面端优先本地应用，统一管理想法、收藏和待办。

| 维度 | 内容 |
|------|------|
| 定位 | 本地优先的个人知识管理工具，离线可用，数据完全归用户 |
| 口号 | 记录一次，随时触达 |
| 平台 | Windows / macOS / Linux（桌面端优先），Android / iOS（响应式适配） |

## 技术栈

| 层 | 技术 | 用途 |
|----|------|------|
| 框架 | Flutter + Dart 3 | 跨平台 UI |
| 状态管理 | Riverpod (flutter_riverpod) | Provider 体系 |
| 路由 | GoRouter | 声明式路由 |
| 数据库 | Drift (SQLite) | 本地持久化 |
| 编辑器 | AppFlowy Editor (主) + flutter_quill (迁移遗留) | 富文本编辑 |
| 插件系统 | UniHubPlugin 接口 | 功能解耦 |

## 架构

```
lib/src/
├── core/         # 基础设施（数据库、路由、主题、插件系统、Shell 布局）
├── shared/       # 共享组件（编辑器集成、TagKit、通用 Widget）
└── plugins/      # 功能插件（thoughts、collections…）
```

详见 [AGENTS.md](AGENTS.md) 和 `.trellis/spec/` 下的开发规范。

## 开始使用

```bash
# 克隆
git clone https://github.com/{owner}/unihub.git
cd unihub

# 安装依赖
flutter pub get

# 生成代码（Drift）
dart run build_runner build --delete-conflicting-outputs

# 运行
flutter run
```

> Dart SDK 版本要求以 `pubspec.yaml` 的 `environment.sdk` 为准（当前为 `^3.11.5`）。参考 [Flutter 安装指南](https://docs.flutter.dev/get-started/install)。

## 构建

```bash
flutter build windows   # Windows
flutter build macos    # macOS
flutter build linux    # Linux
flutter build apk      # Android
```

## 许可证

[MIT](LICENSE)
