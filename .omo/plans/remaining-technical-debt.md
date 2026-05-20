# 剩余技术债务

> 2026-05-20 代码库全面缺陷分析后尚未处理的剩余项。

## 完成情况总览

| 优先级 | 总量 | 已修复 | 剩余 |
|--------|------|--------|------|
| P0 | 2 | 2 | 0 |
| P1 | 4 | 4 | 0 |
| P2 | 3 | 3 | 0 |
| P3 | 4 | 4 | 0 |
| P4 | 1 | 0 | 1 |
| 测试 | 2 | 0 | 2 |
| **合计** | **16** | **13** | **3** |

---

## 剩余工作

### #14 — 替换仪表盘硬编码 Mock 数据

**位置**：`lib/src/plugins/thoughts/ui/home_page.dart`（5 处 `// TODO`）

**描述**：仪表盘的统计卡片使用了硬编码值——thoughts 总数、todos 总数、标签数量、统计图表等。这些数据应该从真实 provider 获取。

**涉及文件**：
- `lib/src/plugins/thoughts/ui/home_page.dart`

**验收标准**：
- [ ] 仪表盘数据全部来自真实 Provider/DAO
- [ ] 删除 5 处 `// TODO` 硬编码
- [ ] `flutter analyze` 通过

---

### #5 — 添加测试覆盖

**位置**：36/44 源文件零测试

**描述**：以下模块完全没有测试覆盖：
- `core/app/` — 应用启动、布局适配
- `core/router/` — 路由定义
- `core/theme/` — 主题配置
- `shared/layouts/` — 响应式布局组件
- 所有插件 UI（widget 层）
- 所有 Provider

**优先级建议**：
1. 核心基础设施（core/）— 影响面最大
2. Repository + DAO 测试补全（已有模式可参考）
3. Provider 单元测试
4. 组件 Widget 测试

**涉及目录**：
- `lib/src/core/app/`
- `lib/src/core/router/`
- `lib/src/core/theme/`
- `lib/src/shared/layouts/`
- `lib/src/plugins/*/ui/`

**验收标准**：
- [ ] core/ 基础设施层每个文件至少 1 个测试
- [ ] 每个 DAO 至少 1 个集成测试
- [ ] 每个 Provider 至少 1 个单元测试
- [ ] `flutter test` 全部通过

---

### #8 — 拆分脆弱的全量冒烟测试

**位置**：`test/src/plugins/thoughts/widget/widget_test.dart`

**描述**：当前唯一的 widget 测试是整个应用加载的冒烟测试。当任何组件变化时这个测试容易失败，且无法定位具体问题。

**方案**：
- 保留一个基础冒烟测试（确保应用可以启动）
- 将具体功能验证拆分为独立的 widget 测试

**验收标准**：
- [ ] 至少有 3 个独立的 widget 测试覆盖不同组件
- [ ] 全量冒烟测试依然保留
- [ ] `flutter test` 全部通过
