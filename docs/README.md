# docs 目录说明

本文档用于说明当前 `docs/` 下各目录的用途，避免测试点、用例设计、历史材料和流程文档混在一起。

## 主工作流目录

以下目录是当前生成 SQL 用例的主链路，后续新增内容优先放在这里：

```text
官方文档
  -> pg-doc-extract
  -> docs/test-factors/
  -> docs/test-points/
  -> pg-case-design
  -> docs/case-designs/
  -> pg-casegen
  -> sql/
```

| 目录 | 用途 | 维护原则 |
|---|---|---|
| `docs/test-factors/` | 测试因子矩阵，记录官方章节、测试因子、优先级和组合策略。 | 用于证明覆盖来源，优先从官方文档抽取。 |
| `docs/test-points/` | 测试点概览，记录由测试因子组合生成的单一测试目标。 | 一个测试点尽量只验证一个场景，并保留因子来源。 |
| `docs/case-designs/` | 用例设计明细，面向 SQL 生成，补充会话、数据、预期结果和命名约束。 | 作为 `pg-casegen` 的直接输入，不直接写成回归 SQL。 |

## 规划文档

| 目录 | 用途 |
|---|---|
| `docs/plans/concurrency-control/` | Concurrency Control 相关规划、审查和历史测试设计。 |
| `docs/plans/transaction-processing/` | Transaction Processing 相关测试点规划。 |

## 工作流文档

| 目录 | 用途 |
|---|---|
| `docs/workflow/architecture-notes.md` | 多 skill 架构、职责边界和流程说明。 |
| `docs/workflow/work-checklist.md` | 后续工作清单和遗留问题。 |
| `docs/workflow/concurrency-vs-transaction-processing-summary.md` | Concurrency Control 与 Transaction Processing 的交集、区别和去重原则。 |

## 参考资料

| 目录 | 用途 |
|---|---|
| `docs/references/pg-configuration-parameters.md` | PostgreSQL 配置参数整理。 |
| `docs/references/pg16-concurrency-control-system-parameters.md` | Concurrency Control 相关系统参数整理。 |

## 历史归档

| 目录 | 用途 |
|---|---|
| `docs/archive/concurrency-control-by-official-chapter/` | 早期按官方章节生成的 Concurrency Control 文本用例和补充测试点。 |
| `docs/archive/concurrency-control-test-cases/` | 早期按 M1-M10 模块分类生成的文本用例。 |

归档目录只作为追溯、比对和迁移来源。新流程下，不建议直接把归档目录作为 `pg-casegen` 的输入；应先迁移或抽取到 `docs/test-points/` 与 `docs/case-designs/`。
