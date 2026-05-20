# 13.8.5 Mvcc Vacuum And Long Transactions 测试因子矩阵

## 来源声明
- source_type: local-knowledge
- source_ref: 本地锁知识目录与用户补充的 PostgreSQL 锁相关扩展测试点
- source_note: 该目录不是 PostgreSQL 官方 Chapter 13 章节；13.8 是项目内扩展编号，用于承载本地知识补充测试点。


## 扩展目录结构
- Chapter 13 Concurrency Control 本地知识补充
  - 13.8.5 Mvcc Vacuum And Long Transactions

## 范围摘要
本矩阵覆盖项目本地知识补充目录 13.8.5 Mvcc Vacuum And Long Transactions 的扩展测试点。测试点来源于本地知识补充与用户扩展测试点，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 来源依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 6 个单一测试点 | P0/P1/P2 | 来自本地知识补充目录及已有扩展测试点。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | VACUUM / diagnostic view、DELETE、LOCK / VACUUM、VACUUM / snapshot、UPDATE / DELETE / LOCK、SELECT / UPDATE / snapshot | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 等待/阻塞状态、常规事务状态转换 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 诊断观测、常规核心路径 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 本地知识补充中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | MVCC-BACKEND-XMIN-IDENTIFIES-VACUUM-BLOCKER: 通过 pg_stat_activity.backend_xmin 辅助识别阻碍 VACUUM 清理的长事务。 | normal | P0 | 通过 pg_stat_activity.backend_xmin 辅助识别阻碍 VACUUM 清理的长事务。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | MVCC-DELETE-MARKS-OLD-TUPLE-NOT-IMMEDIATE-PHYSICAL-DELETE: DELETE 标记旧 tuple 对新事务不可见，但不是立即物理删除。 | normal | P0 | DELETE 标记旧 tuple 对新事务不可见，但不是立即物理删除。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | MVCC-IDLE-IN-TRANSACTION-VACUUM-RISK: idle in transaction 不只是持锁风险，还会阻碍 vacuum、造成膨胀和事务 ID 年龄风险。 | normal | P0 | idle in transaction 不只是持锁风险，还会阻碍 vacuum、造成膨胀和事务 ID 年龄风险。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | MVCC-LONG-TRANSACTION-BLOCKS-VACUUM-CLEANUP: 长事务持有旧 snapshot，会阻止旧 tuple 被 VACUUM 完全清理。 | normal | P0 | 长事务持有旧 snapshot，会阻止旧 tuple 被 VACUUM 完全清理。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | MVCC-TUPLE-VERSION-XMIN-XMAX-OBSERVE: 通过系统列观察 xmin/xmax，理解 tuple version 的创建、更新、删除或锁定元信息。 | normal | P0 | 通过系统列观察 xmin/xmax，理解 tuple version 的创建、更新、删除或锁定元信息。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | MVCC-UPDATE-CREATES-NEW-TUPLE-VERSION: UPDATE 创建新的 tuple version，旧版本仍可被旧 snapshot 读取。 | normal | P0 | UPDATE 创建新的 tuple version，旧版本仍可被旧 snapshot 读取。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | VACUUM / diagnostic view | normal | P0 | 来自 MVCC-BACKEND-XMIN-IDENTIFIES-VACUUM-BLOCKER 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | DELETE | normal | P0 | 来自 MVCC-DELETE-MARKS-OLD-TUPLE-NOT-IMMEDIATE-PHYSICAL-DELETE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | LOCK / VACUUM | normal | P0 | 来自 MVCC-IDLE-IN-TRANSACTION-VACUUM-RISK 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | VACUUM / snapshot | normal | P0 | 来自 MVCC-LONG-TRANSACTION-BLOCKS-VACUUM-CLEANUP 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | UPDATE / DELETE / LOCK | normal | P0 | 来自 MVCC-TUPLE-VERSION-XMIN-XMAX-OBSERVE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V06 | SELECT / UPDATE / snapshot | normal | P0 | 来自 MVCC-UPDATE-CREATES-NEW-TUPLE-VERSION 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 等待/阻塞状态 | normal/boundary | P0 | 来自 MVCC-LONG-TRANSACTION-BLOCKS-VACUUM-CLEANUP 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 常规事务状态转换 | normal/boundary | P0 | 来自 MVCC-UPDATE-CREATES-NEW-TUPLE-VERSION 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 诊断观测 | boundary/exception/diagnostic | P0 | 来自 MVCC-BACKEND-XMIN-IDENTIFIES-VACUUM-BLOCKER 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 MVCC-UPDATE-CREATES-NEW-TUPLE-VERSION 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 本地知识补充或扩展说明中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | diagnostic-directed | F01,F02,F03,F04 | 覆盖 diagnostic-directed 类型测试点 | MVCC-BACKEND-XMIN-IDENTIFIES-VACUUM-BLOCKER |
| C02 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | MVCC-DELETE-MARKS-OLD-TUPLE-NOT-IMMEDIATE-PHYSICAL-DELETE、MVCC-LONG-TRANSACTION-BLOCKS-VACUUM-CLEANUP、MVCC-TUPLE-VERSION-XMIN-XMAX-OBSERVE、MVCC-UPDATE-CREATES-NEW-TUPLE-VERSION |
| C03 | risk-based | F01,F02,F03,F04 | 覆盖 risk-based 类型测试点 | MVCC-IDLE-IN-TRANSACTION-VACUUM-RISK |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| MVCC-BACKEND-XMIN-IDENTIFIES-VACUUM-BLOCKER | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 通过 pg_stat_activity.backend_xmin 辅助识别阻碍 VACUUM 清理的长事务。 | `mvcc-backend-xmin-identifies-vacuum-blocker.md` |
| MVCC-DELETE-MARKS-OLD-TUPLE-NOT-IMMEDIATE-PHYSICAL-DELETE | C02 | P0 | F01-V02,F02-V02,F03-V02,F04-V02 | DELETE 标记旧 tuple 对新事务不可见，但不是立即物理删除。 | `mvcc-delete-marks-old-tuple-not-immediate-physical-delete.md` |
| MVCC-IDLE-IN-TRANSACTION-VACUUM-RISK | C03 | P0 | F01-V03,F02-V03,F03-V02,F04-V02 | idle in transaction 不只是持锁风险，还会阻碍 vacuum、造成膨胀和事务 ID 年龄风险。 | `mvcc-idle-in-transaction-vacuum-risk.md` |
| MVCC-LONG-TRANSACTION-BLOCKS-VACUUM-CLEANUP | C02 | P0 | F01-V04,F02-V04,F03-V01,F04-V02 | 长事务持有旧 snapshot，会阻止旧 tuple 被 VACUUM 完全清理。 | `mvcc-long-transaction-blocks-vacuum-cleanup.md` |
| MVCC-TUPLE-VERSION-XMIN-XMAX-OBSERVE | C02 | P0 | F01-V05,F02-V05,F03-V02,F04-V02 | 通过系统列观察 xmin/xmax，理解 tuple version 的创建、更新、删除或锁定元信息。 | `mvcc-tuple-version-xmin-xmax-observe.md` |
| MVCC-UPDATE-CREATES-NEW-TUPLE-VERSION | C02 | P0 | F01-V06,F02-V06,F03-V02,F04-V02 | UPDATE 创建新的 tuple version，旧版本仍可被旧 snapshot 读取。 | `mvcc-update-creates-new-tuple-version.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：本地知识补充中的概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：6。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。