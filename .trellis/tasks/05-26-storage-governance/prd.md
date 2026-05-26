# UniHub 统一存储与缓存管理系统

## 文档信息

| 项目 | 内容 |
|---|---|
| PRD 名称 | UniHub Storage & Cache Management |
| 版本 | v1.0 |
| 优先级 | P0.5 |
| 适用平台 | Windows 优先，兼容 Android |
| 核心目标 | 让用户明确知道 UniHub 存储了什么、存在哪里、占用多少空间，并提供安全的一键清除缓存与孤儿文件清理能力 |
| 非目标 | 不做云同步、不做在线备份、不默认删除用户核心数据 |

## 设计决策（已确认）

| # | 决策 | 结论 |
|---|------|------|
| 1 | `thought_images` 是否迁移到 `media/` 子目录 | ✅ 迁移，含路径更新逻辑 |
| 2 | `StorageArea.dangerous` 字段去留 | ✅ 保留 |
| 3 | StorageArea 注册方式 | ✅ 两级注册：插件声明 descriptor（不含路径），路径由 AppStoragePaths 拼接 |

## 实施阶段

### Phase 1: 路径统一
- 新增 `lib/src/core/storage/app_storage_paths.dart`
- 新增 `lib/src/core/storage/providers/storage_providers.dart`
- 改造 `database_provider.dart`
- 改造 `file_image_storage.dart`
- 改造 `website_logo_cache_service.dart`
- 实现 thought_images 路径迁移

### Phase 2: 存储扫描
- 新增 `storage_area.dart` / `StorageAreaReport`
- 新增 `storage_manager.dart` (scan)
- 新增 `storage_registry.dart`
- 实现递归大小统计

### Phase 3: 缓存清理
- `WebsiteLogoCacheDao` 增加 `clearAll()`/`count()`/`getAll()`
- `WebsiteLogoCacheService` 增加 `clearCache()`
- `StorageManager.clearRegenerableCache()`

### Phase 4: 孤儿文件
- `findOrphanedFiles()` + `cleanOrphanedFiles()`
- `deleteThoughtWithAssets()` service

### Phase 5: UI 页面
- `storage_management_page.dart`
- 总览 + 分组明细 + 操作按钮

### Phase 6: 规范与治理
- 更新 AGENTS.md / database-guidelines.md
- 测试覆盖

## 验收标准

见 PRD 第 14 节（AC-1 ~ AC-18）。
