# 13.7 Locking And Indexes 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节结构
- Chapter 13 Concurrency Control
  - 13.7 Locking And Indexes

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 13 Concurrency Control 中 13.7 Locking And Indexes 的测试点。测试点来源于已有官方章节化文本用例，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 9 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | INSERT / INDEX、SELECT / INSERT / LOCK / INDEX、事务/并发控制行为、INDEX、LOCK / INDEX | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 常规核心路径 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | IDX-BTREE-PAGE-LOCK-CONCURRENCY: B-tree 使用短期 share/exclusive page-level locks，索引行 fetch 或 insert 后立即释放。 | normal | P1 | B-tree 使用短期 share/exclusive page-level locks，索引行 fetch 或 insert 后立即释放。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | IDX-GIN-MULTI-KEY-INSERT: GIN 单个 indexed value 插入通常产生多个 index key insertions。 | normal | P1 | GIN 单个 indexed value 插入通常产生多个 index key insertions。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | IDX-GIST-PAGE-LOCK-CONCURRENCY: GiST 索引读写使用短期 page-level share/exclusive lock，并在每个 index row 读取或插入后立即释放。 | normal | P1 | GiST indexes use short-term share/exclusive page-level locks for read/write access and release them immediately after each index row is fetched or inserted. | 单一测试点，不与其他主场景合并。 |
| F01-V04 | IDX-GIST-SPGIST-PAGE-LOCK-CONCURRENCY: GiST、SP-GiST 使用短期 page-level locks，提供较高并发。 | normal | P1 | GiST、SP-GiST 使用短期 page-level locks，提供较高并发。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | IDX-HASH-BUCKET-LOCK-CONCURRENCY: Hash index 使用 hash-bucket-level share/exclusive locks，bucket 处理完释放。 | normal | P1 | Hash index 使用 hash-bucket-level share/exclusive locks，bucket 处理完释放。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | IDX-HASH-DEADLOCK-RISK: Hash index 比 index-level 并发更好，但可能死锁。 | normal | P1 | Hash index 比 index-level 并发更好，但可能死锁。 | 单一测试点，不与其他主场景合并。 |
| F01-V07 | IDX-NONSCALAR-DATA-GIST-SPGIST-GIN-RECOMMENDATION: 并发应用中非 scalar data 推荐 GiST、SP-GiST 或 GIN。 | normal | P2 | 并发应用中非 scalar data 推荐 GiST、SP-GiST 或 GIN。 | 单一测试点，不与其他主场景合并。 |
| F01-V08 | IDX-SCALAR-DATA-BTREE-RECOMMENDATION: 并发应用中 scalar data 推荐 B-tree。 | normal | P2 | 并发应用中 scalar data 推荐 B-tree。 | 单一测试点，不与其他主场景合并。 |
| F01-V09 | IDX-SPGIST-PAGE-LOCK-CONCURRENCY: SP-GiST 索引读写使用短期 page-level share/exclusive lock，并在每个 index row 读取或插入后立即释放。 | normal | P1 | SP-GiST indexes use short-term share/exclusive page-level locks for read/write access and release them immediately after each index row is fetched or inserted. | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | INSERT / INDEX | normal | P1 | 来自 IDX-GIN-MULTI-KEY-INSERT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | SELECT / INSERT / LOCK / INDEX | normal | P1 | 来自 IDX-SPGIST-PAGE-LOCK-CONCURRENCY 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | 事务/并发控制行为 | normal | P2 | 来自 IDX-SCALAR-DATA-BTREE-RECOMMENDATION 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | INDEX | normal | P1 | 来自 IDX-HASH-BUCKET-LOCK-CONCURRENCY 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | LOCK / INDEX | normal | P1 | 来自 IDX-HASH-DEADLOCK-RISK 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P1 | 来自 IDX-SPGIST-PAGE-LOCK-CONCURRENCY 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 常规核心路径 | boundary/exception/diagnostic | P1 | 来自 IDX-SPGIST-PAGE-LOCK-CONCURRENCY 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | IDX-BTREE-PAGE-LOCK-CONCURRENCY、IDX-GIN-MULTI-KEY-INSERT、IDX-GIST-PAGE-LOCK-CONCURRENCY、IDX-HASH-BUCKET-LOCK-CONCURRENCY、IDX-SPGIST-PAGE-LOCK-CONCURRENCY |
| C02 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | IDX-GIST-SPGIST-PAGE-LOCK-CONCURRENCY、IDX-HASH-DEADLOCK-RISK、IDX-NONSCALAR-DATA-GIST-SPGIST-GIN-RECOMMENDATION、IDX-SCALAR-DATA-BTREE-RECOMMENDATION |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| IDX-BTREE-PAGE-LOCK-CONCURRENCY | C01 | P1 | F01-V01,F02-V01,F03-V01,F04-V01 | B-tree 使用短期 share/exclusive page-level locks，索引行 fetch 或 insert 后立即释放。 | `idx-btree-page-lock-concurrency.md` |
| IDX-GIN-MULTI-KEY-INSERT | C01 | P1 | F01-V02,F02-V01,F03-V01,F04-V01 | GIN 单个 indexed value 插入通常产生多个 index key insertions。 | `idx-gin-multi-key-insert.md` |
| IDX-GIST-PAGE-LOCK-CONCURRENCY | C01 | P1 | F01-V03,F02-V02,F03-V01,F04-V01 | GiST 索引读写使用短期 page-level share/exclusive lock，并在每个 index row 读取或插入后立即释放。 | `idx-gist-page-lock-concurrency.md` |
| IDX-GIST-SPGIST-PAGE-LOCK-CONCURRENCY | C02 | P1 | F01-V04,F02-V03,F03-V01,F04-V01 | GiST、SP-GiST 使用短期 page-level locks，提供较高并发。 | `idx-gist-spgist-page-lock-concurrency.md` |
| IDX-HASH-BUCKET-LOCK-CONCURRENCY | C01 | P1 | F01-V05,F02-V04,F03-V01,F04-V01 | Hash index 使用 hash-bucket-level share/exclusive locks，bucket 处理完释放。 | `idx-hash-bucket-lock-concurrency.md` |
| IDX-HASH-DEADLOCK-RISK | C02 | P1 | F01-V06,F02-V05,F03-V01,F04-V01 | Hash index 比 index-level 并发更好，但可能死锁。 | `idx-hash-deadlock-risk.md` |
| IDX-NONSCALAR-DATA-GIST-SPGIST-GIN-RECOMMENDATION | C02 | P2 | F01-V07,F02-V03,F03-V01,F04-V01 | 并发应用中非 scalar data 推荐 GiST、SP-GiST 或 GIN。 | `idx-nonscalar-data-gist-spgist-gin-recommendation.md` |
| IDX-SCALAR-DATA-BTREE-RECOMMENDATION | C02 | P2 | F01-V08,F02-V03,F03-V01,F04-V01 | 并发应用中 scalar data 推荐 B-tree。 | `idx-scalar-data-btree-recommendation.md` |
| IDX-SPGIST-PAGE-LOCK-CONCURRENCY | C01 | P1 | F01-V09,F02-V02,F03-V01,F04-V01 | SP-GiST 索引读写使用短期 page-level share/exclusive lock，并在每个 index row 读取或插入后立即释放。 | `idx-spgist-page-lock-concurrency.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：9。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。