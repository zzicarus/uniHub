# Collections 插件

## 模块定位

Collections 是 uniHub 的收藏插件，负责 URL 快速收藏、本地持久化、基础元数据抓取、Inbox/Box/状态/来源/媒介筛选。

## 分层约定

```text
collections/
├── domain/      # 枚举、轻量模型、URL normalizer、platform detector
├── data/        # DAO + Repository，只通过 AppDatabase 访问 Drift
├── services/    # 捕获、元数据抓取、异步 enrichment 服务
├── providers/   # Riverpod providers，UI 不直接访问 DAO/Database
└── ui/          # 页面、布局、组件
```

## 数据库约定

- Drift Table 放在 `lib/src/core/database/tables/`，并由 `collections_plugin.dart` 的 `tables` 声明。
- 新增/修改表时同步更新 `lib/src/core/database/app_database.dart` 的 `@DriftDatabase(tables: [...])` 与 migration。
- DAO 只做 CRUD；业务语义放在 `CollectionsRepository`。

## UI 约定

- 使用 Material 3 `ColorScheme` 与 `app_tokens.dart` 间距/圆角。
- URL 捕获、筛选、列表都通过 `providers/collections_providers.dart` 访问状态。
