# plugins/thoughts — Thoughts 插件

UniHub 当前唯一的业务插件，管理"想法"笔记。

## 内部分层

```
thoughts/
├── data/            ← 数据层：DAO → Repository → ContentCodec → ImageService
├── providers/       ← Riverpod Provider 层
└── ui/              ← 表示层：页面 + Widget
```

## 数据层详情

### ThoughtsDao
- 封装 drift 查询，纯数据访问
- 接收 `AppDatabase` 构造器注入
- 使用类型安全 API（`select().get()`、`into().insert()`）

### ThoughtsRepository
- 封装用例级 API，业务语义的方法名（`pinThought` 而非 `updatePinnedColumn`）
- 接收 `ThoughtsDao` 构造器注入
- 返回值使用业务模型

### ThoughtImageService
- 管理想法的图片生命周期：选择、保存、删除
- 不直接依赖平台 API，通过构造器注入 `ImagePickerService` + `ImageStorage`
- 平台实现（`PlatformImagePicker`、`FileImageStorage`）依赖 `image_picker`、`path_provider`
- 测试中可通过 `FakeImagePicker` + `FakeImageStorage` 完全解耦文件系统
- `encodeImagePaths` / `decodeImagePaths` 为静态方法，纯 JSON 编解码

### ThoughtContentCodec
- 处理富文本存储格式转换
- `documentFromStored(String)` — 兼容读取：envelope JSON / 裸 Delta / 旧 Markdown
- `encodeDocument(Document)` — 输出 envelope JSON
- `plainTextFromStored(String)` — UI 摘要用纯文本

#### 富文本存储格式（envelope JSON）
```json
{
  "format": "unihub.quill_delta.v1",
  "delta": [{"insert": "内容"}]
}
```
旧 Markdown 数据打开编辑后自动升级为 envelope JSON。

## Provider 模式

```dart
// thoughts Provider 使用 asyncNotifier/Notifier 模式
// 数据流：UI → Provider.watch() → Repository → DAO → DB
```

具体 Provider 定义在 `providers/` 目录，通过 `UniHubPlugin.providers()` 贡献。

## UI 分层

- `thoughts_list_page.dart` — 列表页
- `thoughts_editor_page.dart` — 编辑器页主体
- `thoughts_editor_drawer.dart` — 编辑器附加面板

> **2026-05-21**：编辑状态逻辑已重构。`ThoughtEditorController` 和 `ThoughtEditorImageStrip` 提取至 `thoughts/ui/widgets/`，`thoughts_editor_page.dart` 和 `thought_editor_drawer.dart` 现为纯布局容器。

## 已知代码问题

| 问题 | 位置 | 状态 |
|------|------|------|
| `experimental_member_use` lint 抑制 | `shared/ui/rich_text_editor/rich_text_editor.dart` | 未修复 |
| 遗留 Markdown fallback 路径 | `thought_content_codec.dart` | 未修复 |
| 主页使用硬编码 Mock 数据（5 个 TODO） | `home_page.dart` | 未修复 |
| ~~图片服务硬依赖平台 API~~ | ~~`thought_image_service.dart`~~ | ✅ **P2-15 已完成** |

---

## 近期变更

> 本 section 由 sync-knowledge 自动管理，按时间倒序追加。

### 2026-05-22: P2-15 图片服务抽象为依赖注入模式
- `ThoughtImageService` 改为构造器注入 `ImagePickerService` + `ImageStorage`，不再直接依赖 `ImagePicker`/`File`/`path_provider`
- 新建接口层：`ImagePickerService`（选择）、`ImageStorage`（存储+exists 检查）
- 新建平台实现：`PlatformImagePicker`（`image_picker` 包装）、`FileImageStorage`（`path_provider`+`dart:io`）
- 提供测试 fake：`FakeImagePicker`（预设返回）、`FakeImageStorage`（内存 Map 存储）
- `ThoughtContentCodec.mergeImagePaths` 增加可选 `existsChecker` 参数，解耦 `File.existsSync`
- Provider 层拆分为 `imagePickerServiceProvider` + `imageStorageProvider`
- 新增 13 个单元测试覆盖全路径
