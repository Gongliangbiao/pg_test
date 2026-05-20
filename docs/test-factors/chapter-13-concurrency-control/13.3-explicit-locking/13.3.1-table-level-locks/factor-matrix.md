# 13.3.1 Table Level Locks 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节结构
- Chapter 13 Concurrency Control
  - 13.3.1 Table Level Locks

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 13 Concurrency Control 中 13.3.1 Table Level Locks 的测试点。测试点来源于已有官方章节化文本用例，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 16 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | SELECT、LOCK / VACUUM、事务/并发控制行为、LOCK、UPDATE / DELETE / INSERT / MERGE、UPDATE / LOCK / VACUUM / INDEX、UPDATE / VACUUM / INDEX、INDEX | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 等待/阻塞状态、常规事务状态转换 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 常规核心路径、诊断观测 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | LOCK-TABLE-ACCESS-EXCLUSIVE-BLOCKS-SELECT: 只有 ACCESS EXCLUSIVE 会阻塞普通 SELECT。 | normal | P0 | 只有 ACCESS EXCLUSIVE 会阻塞普通 SELECT。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | LOCK-TABLE-ACCESS-EXCLUSIVE-COMMANDS-SPLIT: 将 ACCESS EXCLUSIVE 自动加锁命令清单拆成后续独立用例来源，补充 REINDEX、CLUSTER、VACUUM FULL、非 concurrently REFRESH MATERIALIZED VIEW。 | normal | P1 | DROP TABLE, TRUNCATE, REINDEX, CLUSTER, VACUUM FULL, and non-concurrent REFRESH MATERIALIZED VIEW acquire ACCESS EXCLUSIVE in documented contexts. | 单一测试点，不与其他主场景合并。 |
| F01-V03 | LOCK-TABLE-ACCESS-SHARE-CONFLICT: ACCESS SHARE 只与 ACCESS EXCLUSIVE 冲突。 | normal | P0 | ACCESS SHARE 只与 ACCESS EXCLUSIVE 冲突。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | LOCK-TABLE-DEFAULT-MODE-ACCESS-EXCLUSIVE: LOCK TABLE 未指定模式时默认获取 ACCESS EXCLUSIVE。 | normal | P0 | The default lock mode for LOCK TABLE without an explicit mode is ACCESS EXCLUSIVE. | 单一测试点，不与其他主场景合并。 |
| F01-V05 | LOCK-TABLE-DROP-TRUNCATE-ACCESS-EXCLUSIVE: DROP TABLE、TRUNCATE 等命令获取 ACCESS EXCLUSIVE。 | normal | P0 | DROP TABLE、TRUNCATE 等命令获取 ACCESS EXCLUSIVE。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | LOCK-TABLE-EXCLUSIVE: EXCLUSIVE 表级锁的阻塞关系。 | normal | P0 | EXCLUSIVE 表级锁的阻塞关系。 | 单一测试点，不与其他主场景合并。 |
| F01-V07 | LOCK-TABLE-NON-SELF-CONFLICT-MULTI-SESSION: 两个会话可同时持有非自冲突锁模式，例如 ACCESS SHARE。 | normal | P0 | Some lock modes are not self-conflicting, such as ACCESS SHARE. | 单一测试点，不与其他主场景合并。 |
| F01-V08 | LOCK-TABLE-REFRESH-MVIEW-CONCURRENTLY-EXCLUSIVE: REFRESH MATERIALIZED VIEW CONCURRENTLY 获取 EXCLUSIVE 锁。 | normal | P1 | REFRESH MATERIALIZED VIEW CONCURRENTLY acquires an EXCLUSIVE table-level lock. | 单一测试点，不与其他主场景合并。 |
| F01-V09 | LOCK-TABLE-ROW-EXCLUSIVE-CONFLICT: INSERT、UPDATE、DELETE、MERGE 获取 ROW EXCLUSIVE 及其冲突关系。 | normal | P0 | INSERT、UPDATE、DELETE、MERGE 获取 ROW EXCLUSIVE 及其冲突关系。 | 单一测试点，不与其他主场景合并。 |
| F01-V10 | LOCK-TABLE-ROW-SHARE-CONFLICT: ROW SHARE 表级锁冲突矩阵。 | normal | P0 | ROW SHARE 表级锁冲突矩阵。 | 单一测试点，不与其他主场景合并。 |
| F01-V11 | LOCK-TABLE-SAME-TXN-NO-SELF-CONFLICT: 同一事务内先后获取同一表上的冲突模式锁不与自身冲突。 | normal | P0 | A transaction never conflicts with itself, even when it holds lock modes that conflict between sessions. | 单一测试点，不与其他主场景合并。 |
| F01-V12 | LOCK-TABLE-SELF-CONFLICT-MULTI-SESSION: 两个会话不能同时持有自冲突锁模式，例如 ACCESS EXCLUSIVE。 | normal | P0 | Some lock modes are self-conflicting, such as ACCESS EXCLUSIVE. | 单一测试点，不与其他主场景合并。 |
| F01-V13 | LOCK-TABLE-SHARE-ROW-EXCLUSIVE: CREATE TRIGGER 和部分 ALTER TABLE 获取 SHARE ROW EXCLUSIVE。 | normal | P0 | CREATE TRIGGER 和部分 ALTER TABLE 获取 SHARE ROW EXCLUSIVE。 | 单一测试点，不与其他主场景合并。 |
| F01-V14 | LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE-COMMANDS-SPLIT: 将 SHARE UPDATE EXCLUSIVE 自动加锁命令清单拆成后续独立用例来源，至少覆盖 VACUUM without FULL、ANALYZE、CREATE INDEX CONCURRENTLY、REINDEX CONCURRENTLY。 | normal | P1 | VACUUM without FULL, ANALYZE, CREATE INDEX CONCURRENTLY, CREATE STATISTICS, COMMENT ON, and REINDEX CONCURRENTLY acquire SHARE UPDATE EXCLUSIVE in documented contexts. | 单一测试点，不与其他主场景合并。 |
| F01-V15 | LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE: VACUUM、ANALYZE、CREATE INDEX CONCURRENTLY 等获取 SHARE UPDATE EXCLUSIVE。 | normal | P0 | VACUUM、ANALYZE、CREATE INDEX CONCURRENTLY 等获取 SHARE UPDATE EXCLUSIVE。 | 单一测试点，不与其他主场景合并。 |
| F01-V16 | LOCK-TABLE-SHARE: 非 concurrently CREATE INDEX 获取 SHARE。 | normal | P0 | 非 concurrently CREATE INDEX 获取 SHARE。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | SELECT | normal | P0 | 来自 LOCK-TABLE-ACCESS-EXCLUSIVE-BLOCKS-SELECT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | LOCK / VACUUM | normal | P1 | 来自 LOCK-TABLE-ACCESS-EXCLUSIVE-COMMANDS-SPLIT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | 事务/并发控制行为 | normal | P0 | 来自 LOCK-TABLE-SHARE-ROW-EXCLUSIVE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | LOCK | normal | P0 | 来自 LOCK-TABLE-SELF-CONFLICT-MULTI-SESSION 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | UPDATE / DELETE / INSERT / MERGE | normal | P0 | 来自 LOCK-TABLE-ROW-EXCLUSIVE-CONFLICT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V06 | UPDATE / LOCK / VACUUM / INDEX | normal | P1 | 来自 LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE-COMMANDS-SPLIT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V07 | UPDATE / VACUUM / INDEX | normal | P0 | 来自 LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V08 | INDEX | normal | P0 | 来自 LOCK-TABLE-SHARE 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 等待/阻塞状态 | normal/boundary | P0 | 来自 LOCK-TABLE-EXCLUSIVE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 常规事务状态转换 | normal/boundary | P0 | 来自 LOCK-TABLE-SHARE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 LOCK-TABLE-SHARE 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 诊断观测 | boundary/exception/diagnostic | P1 | 来自 LOCK-TABLE-REFRESH-MVIEW-CONCURRENTLY-EXCLUSIVE 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | LOCK-TABLE-ACCESS-EXCLUSIVE-BLOCKS-SELECT、LOCK-TABLE-ACCESS-SHARE-CONFLICT、LOCK-TABLE-EXCLUSIVE、LOCK-TABLE-NON-SELF-CONFLICT-MULTI-SESSION、LOCK-TABLE-ROW-EXCLUSIVE-CONFLICT、LOCK-TABLE-ROW-SHARE-CONFLICT、LOCK-TABLE-SAME-TXN-NO-SELF-CONFLICT、LOCK-TABLE-SELF-CONFLICT-MULTI-SESSION、LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE-COMMANDS-SPLIT、LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE、LOCK-TABLE-SHARE |
| C02 | diagnostic-directed | F01,F02,F03,F04 | 覆盖 diagnostic-directed 类型测试点 | LOCK-TABLE-ACCESS-EXCLUSIVE-COMMANDS-SPLIT、LOCK-TABLE-REFRESH-MVIEW-CONCURRENTLY-EXCLUSIVE |
| C03 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | LOCK-TABLE-DEFAULT-MODE-ACCESS-EXCLUSIVE、LOCK-TABLE-DROP-TRUNCATE-ACCESS-EXCLUSIVE、LOCK-TABLE-SHARE-ROW-EXCLUSIVE |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| LOCK-TABLE-ACCESS-EXCLUSIVE-BLOCKS-SELECT | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 只有 ACCESS EXCLUSIVE 会阻塞普通 SELECT。 | `lock-table-access-exclusive-blocks-select.md` |
| LOCK-TABLE-ACCESS-EXCLUSIVE-COMMANDS-SPLIT | C02 | P1 | F01-V02,F02-V02,F03-V02,F04-V02 | 将 ACCESS EXCLUSIVE 自动加锁命令清单拆成后续独立用例来源，补充 REINDEX、CLUSTER、VACUUM FULL、非 concurrently REFRESH MATERIALIZED VIEW。 | `lock-table-access-exclusive-commands-split.md` |
| LOCK-TABLE-ACCESS-SHARE-CONFLICT | C01 | P0 | F01-V03,F02-V03,F03-V02,F04-V01 | ACCESS SHARE 只与 ACCESS EXCLUSIVE 冲突。 | `lock-table-access-share-conflict.md` |
| LOCK-TABLE-DEFAULT-MODE-ACCESS-EXCLUSIVE | C03 | P0 | F01-V04,F02-V04,F03-V02,F04-V01 | LOCK TABLE 未指定模式时默认获取 ACCESS EXCLUSIVE。 | `lock-table-default-mode-access-exclusive.md` |
| LOCK-TABLE-DROP-TRUNCATE-ACCESS-EXCLUSIVE | C03 | P0 | F01-V05,F02-V03,F03-V02,F04-V01 | DROP TABLE、TRUNCATE 等命令获取 ACCESS EXCLUSIVE。 | `lock-table-drop-truncate-access-exclusive.md` |
| LOCK-TABLE-EXCLUSIVE | C01 | P0 | F01-V06,F02-V04,F03-V01,F04-V01 | EXCLUSIVE 表级锁的阻塞关系。 | `lock-table-exclusive.md` |
| LOCK-TABLE-NON-SELF-CONFLICT-MULTI-SESSION | C01 | P0 | F01-V07,F02-V04,F03-V02,F04-V01 | 两个会话可同时持有非自冲突锁模式，例如 ACCESS SHARE。 | `lock-table-non-self-conflict-multi-session.md` |
| LOCK-TABLE-REFRESH-MVIEW-CONCURRENTLY-EXCLUSIVE | C02 | P1 | F01-V08,F02-V04,F03-V02,F04-V02 | REFRESH MATERIALIZED VIEW CONCURRENTLY 获取 EXCLUSIVE 锁。 | `lock-table-refresh-mview-concurrently-exclusive.md` |
| LOCK-TABLE-ROW-EXCLUSIVE-CONFLICT | C01 | P0 | F01-V09,F02-V05,F03-V02,F04-V01 | INSERT、UPDATE、DELETE、MERGE 获取 ROW EXCLUSIVE 及其冲突关系。 | `lock-table-row-exclusive-conflict.md` |
| LOCK-TABLE-ROW-SHARE-CONFLICT | C01 | P0 | F01-V10,F02-V04,F03-V02,F04-V01 | ROW SHARE 表级锁冲突矩阵。 | `lock-table-row-share-conflict.md` |
| LOCK-TABLE-SAME-TXN-NO-SELF-CONFLICT | C01 | P0 | F01-V11,F02-V04,F03-V02,F04-V01 | 同一事务内先后获取同一表上的冲突模式锁不与自身冲突。 | `lock-table-same-txn-no-self-conflict.md` |
| LOCK-TABLE-SELF-CONFLICT-MULTI-SESSION | C01 | P0 | F01-V12,F02-V04,F03-V02,F04-V01 | 两个会话不能同时持有自冲突锁模式，例如 ACCESS EXCLUSIVE。 | `lock-table-self-conflict-multi-session.md` |
| LOCK-TABLE-SHARE-ROW-EXCLUSIVE | C03 | P0 | F01-V13,F02-V03,F03-V02,F04-V01 | CREATE TRIGGER 和部分 ALTER TABLE 获取 SHARE ROW EXCLUSIVE。 | `lock-table-share-row-exclusive.md` |
| LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE-COMMANDS-SPLIT | C01 | P1 | F01-V14,F02-V06,F03-V02,F04-V01 | 将 SHARE UPDATE EXCLUSIVE 自动加锁命令清单拆成后续独立用例来源，至少覆盖 VACUUM without FULL、ANALYZE、CREATE INDEX CONCURRENTLY、REINDEX CONCURRENTLY。 | `lock-table-share-update-exclusive-commands-split.md` |
| LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE | C01 | P0 | F01-V15,F02-V07,F03-V02,F04-V01 | VACUUM、ANALYZE、CREATE INDEX CONCURRENTLY 等获取 SHARE UPDATE EXCLUSIVE。 | `lock-table-share-update-exclusive.md` |
| LOCK-TABLE-SHARE | C01 | P0 | F01-V16,F02-V08,F03-V02,F04-V01 | 非 concurrently CREATE INDEX 获取 SHARE。 | `lock-table-share.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：16。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。