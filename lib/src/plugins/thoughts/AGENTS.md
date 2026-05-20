# plugins/thoughts — Thoughts 插件

UniHub 当前唯一的业务插件，管理"想法"笔记。

## 内部分层

```
thoughts/
├── data/            ← 数据层：DAO → Repository → ContentCodec
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

⚠️ **已知重复**：`thoughts_editor_page.dart`（576 行）和 `thoughts_editor_drawer.dart`（545 行）之间约 **50% 代码重复**，包括：
- `_formatTimestamp`（3 处副本）
- Tag 解析逻辑（6+ 处副本）
- `_Panel` 组件（3 处副本）
- 颜色十六进制解析（2 处副本）
- 颜色圆点 Widget（2 处副本）
- 图片插入逻辑（3 处副本）

如果有意重构，建议提取到 `thoughts/ui/widgets/` 目录。

## 已知代码问题

| 问题 | 位置 |
|------|------|
| `experimental_member_use` lint 抑制 | `thoughts_rich_editor.dart` |
| 遗留 Markdown fallback 路径 | `thought_content_codec.dart` |
| 主页使用硬编码 Mock 数据（5 个 TODO） | `home_page.dart` |
