# test/ — 测试约定

## 数据库隔离

所有测试使用 in-memory Drift 连接，避免依赖文件系统：

```dart
import 'package:drift/native.dart';

final registry = PluginRegistry();
// registry.register(YourPlugin());
final db = AppDatabase(NativeDatabase.memory(), registry);
```

不在测试间共享数据库实例。每个测试套件独立创建。

## ProviderScope 注入模式

Widget 测试通过 `ProviderScope` overrides 注入测试依赖：

```dart
ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWithValue(testDb),
    pluginRegistryProvider.overrideWithValue(registry),
  ],
  child: MaterialApp(...),
);
```

参考 `test/widget_test.dart` 中的完整示例。

## Mock 策略

**零 mockito**。所有 mock 通过以下方式实现：
- 手写 stub 插件实现 `UniHubPlugin` 接口
- 使用 `PluginRegistry()` + `register()` 构造测试专用 registry
- 数据库直接使用真实 Drift 查询（in-memory）
- 手写 fake 实现抽象接口（如 `FakeImagePicker`、`FakeImageStorage`），覆盖平台依赖和文件系统操作

**Service 测试的 Mock HTTP 模式**（`website_logo_cache_service_test.dart` 参考）：
- `HttpClient` / `HttpClientRequest` / `HttpClientResponse` 三个接口分别实现手写 mock 子类
- mock 的响应内容（body、statusCode、contentType）通过工厂函数注入，支持按 URL 返回不同配置
- 服务注入模式：构造函数参数传入 mock client + 临时 `logosDirectory` + in-memory DAO
- 记录 `fetchedUrls` 列表以断言 HTTP 调用次数（用于验证去重行为）

## 测试文件结构

测试目录镜像 `lib/src/` 结构：

```
test/
├── core/
│   ├── app/
│   ├── database/
│   ├── plugin/
│   ├── router/
│   ├── search/
│   └── theme/
├── plugins/
│   ├── thoughts/
│   │   ├── data/
│   │   ├── providers/
│   │   └── ui/
│   │       └── widgets/
│   └── collections/
│       ├── data/
│       ├── domain/
│       ├── services/
│       └── ui/
│           ├── layouts/
│           └── widgets/
├── shared/
│   ├── tags/
│   └── widgets/
│       └── tags/
└── widget_test.dart
```

## 当前覆盖情况（约 140 测试用例，33 个测试文件）

> 最后核对日期：2026-05-25

| 目录 | 覆盖 | 说明 |
|------|------|------|
| `core/app/` | 100% | (4/4 文件) |
| `core/database/` | 33% | (1/3 文件) |
| `core/plugin/` | 50% | (1/2) |
| `core/search/` | 50% | (1/2) |
| `core/router/` | 100% | (2/2 文件) |
| `core/theme/` | 100% | (4/4 文件) |
| `thoughts/data/` | 80% | (4/5 主数据文件) |
| `thoughts/providers/` | 100% | 10 条 |
| `thoughts/ui/` | 40% | 含 widgets 子目录 (2/5 当前可见 UI 文件) |
| `shared/tags/` | 67% | (2/3 文件: tag_codec, tag_filter_logic; tag_models 待覆盖) |
| `shared/widgets/tags/` | 80% | (4/5 文件: app_tag_chip, app_tag_filter_bar, app_selected_tags_bar, app_common_tags_panel; app_more_tags_popover 待覆盖) |
| `shared/widgets/`（非 tags） | 88% | (7/8 其他通用组件，含 `delete_confirm_dialog`） |
| `collections/` | 覆盖新增 | logo cache 服务层 13 条、metadata 解析 7 条、enrichment 4 条、capture 3 条、Card widget 3 条、DetailPanel 2 条、desktop layout 1 条、Repository 7 条、DAO 8 条、domain 24 条 |

**新增功能时建议至少为对应目录添加基本覆盖。**

## 运行测试

```sh
# 所有测试
flutter test

# 单个文件
flutter test test/src/core/plugin/plugin_registry_test.dart

# 单个测试用例（按名称过滤）
flutter test --name "test case name"
```

## 完整验证顺序

提交前按以下顺序验证（参考 `.trellis/workflow.md` 的验证流程）：

```sh
# Step 1: 静态分析
flutter analyze

# Step 2: 自动修复 lint
dart fix --dry-run   # 预览
dart fix --apply     # 应用

# Step 3: 运行测试
flutter test

# Step 4: 确认工作区干净
git status
```

### 验证失败处理
| 失败类型 | 处理方式 |
|----------|----------|
| analyze warning | `dart fix --apply` 自动修复 |
| analyze error | 按错误信息修改代码 |
| 测试失败 | 确认是代码问题还是测试问题 |
| 3 次连续失败 | 停止 → 咨询 Oracle |

---

## 近期变更

> 本 section 由 sync-knowledge 自动管理，按时间倒序追加。

### 2026-05-26: SVG favicon 缓存修复
- `website_logo_cache_service.dart`：`_isEntryValid` 拒绝 `.svg` 路径和 `image/svg+xml` 的 MIME 类型；`_tryFetchCandidate` 新增响应 `Content-Type` 校验，`image/svg+xml` 跳过该候选
- `website_logo_cache_dao.dart`：`markFailed` 同时清除 `localLogoPath` 和 `mimeType`，避免 UI 层继续加载已标记失败的 SVG
- `website_logo.dart`：新增 SVG 路径跳过检查；`_reportedDecodeFailures` 静态 Set 去重错误日志，同路径只打印一次

### 2026-05-25: 收藏删除确认弹窗 UI 改造
- 新增 `test/shared/widgets/delete_confirm_dialog_test.dart` — 9 条（单条弹窗渲染、取消按钮、删除按钮、不再提示跳过、批量弹窗、多收藏夹选择、警示图标、偏好持久化）
- `shared/widgets/` 覆盖从 6→7 文件

### 2026-05-23: TagKit widget 测试覆盖 + 适配 AppCommonTagsPanel
- 新增 `test/shared/widgets/tags/app_common_tags_panel_test.dart` — 8 条（title/helperText/empty/tag chips/count/selected/maxVisibleTags）
- 新增 `test/shared/widgets/tags/app_tag_filter_bar_test.dart` — 10 条（label/empty/onTagToggle/showCounts/maxVisibleTags/onMoreTap/horizontalScroll）
- 新增 `test/shared/widgets/tags/app_selected_tags_bar_test.dart` — 7 条（empty/label/onRemove/onClear/+N/clearLabel）
- `shared/widgets/tags/` 覆盖从 1→4 文件，`shared/` 总体覆盖从 25%→75%
- 移除 `thought_common_tags_panel.dart` 的手写布局，改为委托 `AppCommonTagsPanel`

### 2026-05-23: 标签系统共享模块测试
- 新增 `test/shared/tags/tag_codec_test.dart` — 26 条（normalize/parse/encode/validate）
- 新增 `test/shared/tags/tag_filter_logic_test.dart` — 24 条（toggle/remove/rename/matches/count/sort）
- 新增 `test/shared/widgets/tags/app_tag_chip_test.dart` — 8 条（label/count/selected/onTap/compact/icon）
- `thoughts_providers_test.dart` 从 7 增至 10 条（all 语义验证、commonTagsProvider 排序、tag filter 连锁效果）
- 修复预先存在的 4 个测试失败（settings_page_test 文本变更 + sidebar_test 主题扩展缺失）
- `shared/` 覆盖从 0% 提升至 25%，`thoughts/providers/` 覆盖 100%

### 2026-05-23: 增加设置页主题切换测试覆盖
- `settings_page_theme_test.dart`（新增）— 4 条 widget 测试：验证「主题模式」「主题预设」显示、6 个预设名称渲染、点击 Forest 切换预设、点击深色切换模式
- `core/app/` 覆盖从 0% 提升至 25%

### 2026-05-22: 增加数据库测试覆盖
- `database_test.dart` 新增 3 个测试用例（schemaVersion 计算、跨插件取最大值、缺失表断言）
- 更新 5 个已有测试文件适配 `AppDatabase` 构造函数签名变更

### 2026-05-22: P2-15 图片服务测试 + fake 模式
- 新增 `thought_image_service_test.dart`（13 条用例）
- 新建 `FakeImageStorage`（内存 Map 实现）和 `FakeImagePicker`（预设返回值），作为文件系统/平台依赖的标准 fake 模式，与零 mockito 策略一致
- `thoughts/data/` 覆盖从 60% 提升至 80%
