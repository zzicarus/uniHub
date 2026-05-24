# PRD：uniHub Thoughts 图片系统 V2 —— AppFlowy 正文图片块统一方案

## 1. 背景

当前 thoughts 模块已经迁移到 AppFlowy Editor 工作台，但图片系统仍处于 V1 过渡状态。现有代码中图片至少存在两种来源：

- **独立附件图片**：通过 `thought.imagePaths` 存储，由 `ThoughtImageService` 负责保存、删除、编码和解码路径。
- **正文图片块**：未来由 AppFlowy document 中的 image block 表示，但当前尚未真正接入。`ThoughtContentCodec.imagePathsFromStored()` 当前第一阶段不解析 AppFlowy 图片块。

这导致用户在编辑工作台中看到两个概念：
- **右侧图片面板**：像是附件图片
- **编辑器正文图片**：像是正文内容块

但二者当前没有统一。`ThoughtCard` 仍通过 `ThoughtContentCodec.mergeImagePaths(widget.imagePaths, widget.content)` 判断卡片是否有图，说明列表页仍依赖 `imagePaths`。

## 2. 问题定义

当前图片系统存在以下问题：

| 问题 | 说明 |
|------|------|
| 图片入口不统一 | 右侧图片面板和 AppFlowy 编辑器正文图片不是同一个数据流 |
| 图片数据源不明确 | `imagePaths` 和 `documentJson` image block 可能同时存在 |
| UI 语义混乱 | 用户不知道"图片"是附件，还是正文内容 |
| 列表页状态不可靠 | 如果图片只存在于正文 block，但没有同步到 `imagePaths`，列表卡片可能无法显示图片状态 |
| 删除规则不清晰 | 删除图片时不知道应删除附件路径、正文 block，还是本地文件 |
| 后续扩展困难 | 粘贴图片、拖拽图片、toolbar 插图都会继续放大冲突 |

## 3. 产品目标

V2 的目标是建立**唯一图片真相源**：

- **AppFlowy document image block = 唯一真相源**
- **imagePaths = 从 document image block 派生出的缓存 / 列表索引**

用户体验目标：

1. 用户添加图片 → 图片出现在正文中
2. 右侧图片面板 → 显示正文中的图片
3. 列表卡片 → 根据 `imagePaths` 缓存显示图片状态
4. 删除图片 → 正文图片块消失，右侧图片列表同步变化

最终用户不需要理解"附件图片"和"正文图片"的区别。对用户来说，图片就是想法内容的一部分。

## 4. 非目标

本阶段不做：

1. 不做云端图片上传
2. 不做图片压缩策略
3. 不做图片裁剪 / 标注 / OCR
4. 不做图片拖拽排序
5. 不做多图画廊详情页
6. 不做跨设备同步
7. 不做 Markdown 图片语法导入
8. 不做历史 imagePaths 附件数据迁移
9. 不做旧 Quill 图片兼容

## 5. 核心设计决策

### 5.1 唯一真相源

- `documentJson` 是主数据
- `imagePaths` 是派生缓存

也就是说，保存时从 AppFlowy document 中提取 image blocks，再生成 `imagePaths`。

### 5.2 imagePaths 的新定位

`imagePaths` 不再是用户直接编辑的主数据，而是列表页和统计用的缓存字段：

用途：
1. 列表卡片快速判断是否有图片
2. 避免每次渲染列表都深度解析 documentJson
3. 支持未来搜索 / 筛选 / 统计

### 5.3 统一图片入口

所有图片入口最终都应该走同一条链路：

```
选择 / 粘贴 / 拖拽图片
→ ThoughtImageService 保存为本地文件
→ 插入 AppFlowy image block
→ 从 documentJson 提取 imageRefs
→ 保存 content + imagePaths 缓存
```

V2 第一阶段只要求右侧图片面板接入这条链路。toolbar、粘贴、拖拽可以后续接管。

## 6. 数据模型

### 6.1 AppFlowy image block 建议结构

如果当前 `appflowy_editor` 版本已有内置 image block schema，应优先使用内置 schema。

如果没有，使用统一自定义结构：

```json
{
  "type": "image",
  "data": {
    "id": "img_abc123",
    "source": "local_file",
    "path": "D:/.../unihub/images/abc123.png",
    "alt": "",
    "caption": ""
  },
  "children": []
}
```

### 6.2 图片引用模型

新增模型：

```dart
class ThoughtImageRef {
  final String id;
  final String path;
  final String? blockId;
  final String? alt;
  final String? caption;
}
```

字段说明：

| 字段 | 说明 |
|------|------|
| `id` | 图片业务 ID，用于删除和定位 |
| `path` | 本地图片路径 |
| `blockId` | AppFlowy document block id，可选 |
| `alt` | 替代文本，可选 |
| `caption` | 图片说明，可选 |

### 6.3 imagePaths 缓存生成规则

保存 thought 时：

```dart
final imageRefs = ThoughtImageBlockCodec.extractImageRefs(documentJson);

final imagePaths = ThoughtImageService.encodeImagePaths(
  imageRefs.map((e) => e.path).toList(),
);
```

要求：
1. `imagePaths` 只从 `documentJson` image blocks 派生。
2. 不允许右侧图片面板直接写 `imagePaths`。
3. 不允许列表卡片从 `content` 再 merge 图片路径。

## 7. 功能需求

### FR-1：新增图片块 Codec

新增：`lib/src/plugins/thoughts/data/thought_image_block_codec.dart`

职责：

```dart
abstract final class ThoughtImageBlockCodec {
  static Map<String, dynamic> createImageNode({
    required String id,
    required String path,
    String? alt,
    String? caption,
  });

  static List<ThoughtImageRef> extractImageRefs(
    Map<String, dynamic> document,
  );

  static Map<String, dynamic> removeImageNode({
    required Map<String, dynamic> document,
    required String imageId,
  });

  static bool containsPath(
    Map<String, dynamic> document,
    String path,
  );
}
```

验收：
1. 能从 documentJson 中提取所有 image block。
2. 能创建标准 image node。
3. 能删除指定 imageId 的 image node。
4. 不影响非图片 block。

### FR-2：AppFlowyThoughtEditor 支持插入图片块

`AppFlowyThoughtEditor` 需要暴露插入图片能力。

建议新增：

```dart
class AppFlowyThoughtEditorController extends ChangeNotifier {
  Future<void> insertImageBlock({
    required String id,
    required String path,
    String? alt,
    String? caption,
  });

  Future<void> removeImageBlock(String imageId);

  Future<void> focusImageBlock(String imageId);
}
```

`AppFlowyThoughtEditor` 新增参数：

```dart
final AppFlowyThoughtEditorController? controller;
```

第一阶段要求：
1. 支持从外部插入 image block。
2. 第一版可以插入到文档末尾。
3. 插入后必须触发 onChanged，输出最新 documentJson。
4. 不要求当前光标位置插入。

### FR-3：ThoughtEditorController 从 document 派生 imageRefs

`ThoughtEditorController` 新增：

```dart
List<ThoughtImageRef> imageRefs = [];
```

加载时：

```dart
imageRefs = ThoughtImageBlockCodec.extractImageRefs(documentJson!);
```

文档变化时：

```dart
void updateDocument({
  required Map<String, dynamic> documentJson,
  required String plainText,
}) {
  this.documentJson = documentJson;
  this.plainText = plainText;
  imageRefs = ThoughtImageBlockCodec.extractImageRefs(documentJson);
  markDirty();
}
```

保存时：

```dart
final imagePaths = ThoughtImageService.encodeImagePaths(
  imageRefs.map((e) => e.path).toList(),
);
```

验收：
1. `imageRefs` 与正文 image blocks 同步。
2. `imagePaths` 从 `imageRefs` 派生。
3. 不再独立维护 images 作为主状态。

### FR-4：右侧图片卡片插入正文图片块

右侧属性栏中的图片卡片继续存在，但语义从"附件图片"改为"正文图片管理"。

交互：
1. 点击添加图片
2. → 调用 ThoughtImageService.pickImage()
3. → 保存成本地文件路径
4. → 调用 AppFlowyThoughtEditorController.insertImageBlock()
5. → 图片出现在正文中
6. → 右侧图片卡片数量更新

如果插入失败：
- 删除刚保存的本地图片文件，避免孤儿文件

验收：
1. 右侧点击添加图片后，正文中出现图片块。
2. 右侧显示图片数量 +1。
3. 保存后关闭再打开，图片仍在正文。
4. 列表卡片显示图片图标。

### FR-5：删除图片同步删除 block 和文件

右侧图片卡片中的删除操作应执行：

```
删除 document image block
→ 更新 documentJson
→ 更新 imageRefs
→ 更新 imagePaths 缓存
→ 如果本地文件不再被任何 block 引用，则删除本地文件
```

引用计数规则：
- 如果多个 image block 引用同一个 path，删除其中一个 block 时不能删除文件。
- 只有当 document 中不再包含该 path 时，才删除文件。

验收：
1. 删除图片后，正文图片块消失。
2. 右侧图片数量减少。
3. 保存后重新打开，图片不再出现。
4. 本地文件在无引用时被删除。

### FR-6：列表卡片只使用 imagePaths 缓存

`ThoughtCard` 当前通过 `ThoughtContentCodec.mergeImagePaths(widget.imagePaths, widget.content)` 判断图片。

V2 应改为：

```dart
final images = ThoughtImageService.decodeImagePaths(widget.imagePaths);
```

要求：
1. 列表卡片不解析 documentJson。
2. 列表卡片不 merge content 中的图片。
3. `imagePaths` 是 document image block 的派生缓存。

验收：
1. 有图片时显示图片图标。
2. 删除图片并保存后，图片图标消失。
3. 列表渲染不依赖 content 解析图片。

### FR-7：禁用未接管的图片入口

所有图片入口必须统一走：
- ThoughtImageService → AppFlowy image block → imageRefs → imagePaths cache

如果 AppFlowy toolbar 默认存在图片按钮，但该按钮不经过统一链路：
- 必须隐藏、禁用，或替换为调用统一插图方法

同理，图片粘贴 / 拖拽如果暂时无法接管：
- 第一阶段先禁用

验收：
1. UI 上不存在第二套图片入口。
2. toolbar image action 不会直接生成未受控 image block。
3. 粘贴图片不会绕过 ThoughtImageService。

## 8. UI 需求

### 8.1 右侧图片卡片

标题：**图片**
副标题：**正文图片**

内容：
- 0 张图片
- [拖拽图片到此处 或 点击添加]

第一阶段可以先不做拖拽，文案可改为：
- 点击添加图片到正文

有图时：
- 图片 2 张
- [图片 1] [图片 2]
- [继续添加]

如果暂时不做缩略图，可显示：
- 图片 1    x
- 图片 2    x

### 8.2 正文图片块

第一阶段最低要求：
- 正文中能看到图片占位 / 图片渲染

如果 AppFlowy 自带 image block 渲染能力不足，则先显示：
- `[图片] filename.png`

但必须作为 document block 存在。

## 9. 技术流程

### 9.1 添加图片流程

```
User clicks Add Image
→ ThoughtEditorController.insertImageIntoDocument()
→ ThoughtImageService.pickImage()
→ local file path returned
→ generate imageId
→ editorController.insertImageBlock(id, path)
→ AppFlowyThoughtEditor emits onChanged
→ ThoughtEditorController.updateDocument()
→ extract imageRefs
→ markDirty
→ autosave/save
→ repo.updateThought(content, imagePaths cache)
```

### 9.2 删除图片流程

```
User clicks delete image
→ ThoughtEditorController.removeImageFromDocument(imageId)
→ editorController.removeImageBlock(imageId)
→ AppFlowyThoughtEditor emits onChanged
→ updateDocument()
→ extract imageRefs
→ if path no longer referenced, delete local file
→ markDirty
→ save
```

### 9.3 列表显示流程

```
ThoughtCard receives imagePaths
→ ThoughtImageService.decodeImagePaths(imagePaths)
→ if not empty, show image icon
```

## 10. 验收标准

### AC-1：添加图片闭环
- Given 用户打开 ThoughtEditorWorkspace
- When 用户点击右侧图片卡片添加图片
- Then 图片保存到本地
- And AppFlowy 正文中出现 image block
- And 右侧图片数量 +1
- And 保存后 imagePaths 缓存包含该路径

### AC-2：重新打开闭环
- Given 用户添加图片并保存
- When 用户关闭并重新打开该 thought
- Then 正文中仍显示图片
- And 右侧图片卡片仍显示该图片
- And 列表卡片显示图片图标

### AC-3：删除图片闭环
- Given thought 中已有一张图片
- When 用户在右侧图片卡片删除该图片
- Then 正文 image block 被删除
- And 右侧图片数量减少
- And 保存后 imagePaths 不再包含该路径
- And 如果没有其它 block 引用该文件，本地文件被删除

### AC-4：图片入口统一
- Given AppFlowy editor toolbar 有图片按钮
- When 图片按钮未接入 ThoughtImageService
- Then 该按钮必须隐藏或禁用
- Given 用户粘贴图片
- When 粘贴逻辑未接入统一图片链路
- Then 不应生成未受控 image block

### AC-5：列表不解析 document
- Given ThoughtCard 渲染列表
- Then 它只通过 imagePaths 判断是否有图片
- And 不调用 ThoughtContentCodec.mergeImagePaths
- And 不深度解析 documentJson

## 11. 分阶段实施

### Phase 1：最小闭环
1. 新增 ThoughtImageBlockCodec
2. AppFlowyThoughtEditor 支持插入 image block
3. ThoughtEditorController 从 document 派生 imageRefs
4. 右侧图片卡片添加图片 → 插入正文 block
5. ThoughtCard 只读 imagePaths 缓存
6. 手动验收添加 / 保存 / 重新打开

### Phase 2：删除闭环
1. AppFlowyThoughtEditor 支持删除 image block
2. 右侧图片卡片支持删除
3. 无引用时删除本地文件
4. 保存后同步 imagePaths

### Phase 3：入口统一
1. 接管 toolbar image action
2. 接管 paste image
3. 接管 drag image
4. 禁止任何未经过 ThoughtImageService 的图片写入

### Phase 4：体验增强
1. 图片缩略图
2. 点击右侧图片定位正文 block
3. 图片 caption
4. 图片 alt
5. 拖拽排序

## 12. 风险与注意事项

| 风险 | 说明 | 处理 |
|------|------|------|
| AppFlowy 插入节点 API 不确定 | 当前项目有 vendor/appflowy_editor override | 实现前必须检索 vendor API，不要猜 |
| image block schema 可能变化 | 自定义 schema 与 AppFlowy 内置 schema 可能冲突 | 优先使用 AppFlowy 内置 image block，如不可用再自定义 |
| 删除文件误删 | 多个 block 可能引用同一路径 | 删除前必须检查引用计数 |
| 列表缓存不一致 | document 更新后 imagePaths 没同步 | updateDocument/save 必须统一派生缓存 |
| 粘贴图片绕过服务 | AppFlowy 可能默认处理 paste image | 暂时禁用或接管 paste image |
| 测试难模拟 AppFlowy 编辑器 | widget test 可能不稳定 | codec 做单测，插入/保存做手动验收 |

## 13. 任务拆分

### V2-1：新增 ThoughtImageBlockCodec
- 新增：`lib/src/plugins/thoughts/data/thought_image_block_codec.dart`
- 实现：ThoughtImageRef, createImageNode, extractImageRefs, removeImageNode, containsPath
- 验收：`flutter analyze`

### V2-2：AppFlowyThoughtEditor 支持插入图片块
- 修改：`lib/src/shared/editor/appflowy_thought_editor.dart`
- 实现：AppFlowyThoughtEditorController, insertImageBlock, controller 绑定 EditorState, 插入后触发 onChanged
- 验收：`flutter analyze`

### V2-3：Controller 派生 imageRefs
- 修改：`lib/src/plugins/thoughts/ui/widgets/thought_editor_controller.dart`
- 实现：imageRefs, load 后 extract imageRefs, updateDocument 后同步 imageRefs, save 时生成 imagePaths 缓存
- 验收：`flutter analyze`

### V2-4：右侧图片卡片插入正文图片
- 修改：`lib/src/plugins/thoughts/ui/widgets/thought_editor_workspace.dart`, `thought_editor_controller.dart`, `appflowy_thought_editor.dart`
- 实现：Workspace 创建 AppFlowyThoughtEditorController, 图片卡片添加按钮调用 ctrl.insertImageIntoDocument, 插入正文 image block, 更新右侧图片列表
- 验收：`flutter analyze`

### V2-5：删除图片同步删除 block 和文件
- 修改：ThoughtImageBlockCodec, ThoughtEditorController, ThoughtEditorWorkspace, AppFlowyThoughtEditor
- 实现：removeImageBlock, removeImageFromDocument, 无引用时 deleteImage(path)
- 验收：`flutter analyze`

### V2-6：ThoughtCard 只使用 imagePaths 缓存
- 修改：`lib/src/plugins/thoughts/ui/widgets/thought_card.dart`
- 实现：删除 mergeImagePaths(content) 逻辑, 使用 ThoughtImageService.decodeImagePaths(widget.imagePaths)
- 验收：`flutter analyze`

### V2-7：禁用未统一图片入口
- 检查：AppFlowy toolbar image action, paste image, drag image
- 要求：未接入 ThoughtImageService 的入口全部禁用或替换
- 验收：`flutter analyze`

### V2-8：测试 ThoughtImageBlockCodec
- 新增：`test/plugins/thoughts/data/thought_image_block_codec_test.dart`
- 测试：createImageNode, extractImageRefs, removeImageNode, nested children, empty path ignore
- 验收：`flutter analyze && flutter test test/plugins/thoughts/data/thought_image_block_codec_test.dart`

### V2-9：手动验收
- 运行：`flutter analyze && flutter test && flutter run -d windows`
- 验收：
  1. 添加图片后正文显示图片
  2. 右侧图片数量更新
  3. 保存后关闭再打开图片仍在
  4. 列表卡片显示图片图标
  5. 删除图片后正文和右侧同步
  6. 保存后列表图标消失

## 14. 成功标准

V2 完成后，必须满足：

1. 用户只感知一套图片系统。
2. 右侧图片面板管理的是正文图片。
3. AppFlowy document image block 是唯一真相源。
4. imagePaths 只是缓存，不是主状态。
5. 列表卡片无需解析 documentJson。
6. 删除图片不会留下 UI 残留。
7. 不存在未接管的第二图片入口。
