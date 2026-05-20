# PostgreSQL 16 Chapter 13.1 Concurrency Control 测试点汇报大纲

## 13.1 Introduction

### 章节定位
- 官方章节：13.1 Introduction
- 模块：Chapter 13 Concurrency Control
- 核心目标：验证 PostgreSQL MVCC 基础语义，包括一致视图、未提交版本不可见、普通读写互不阻塞，以及同一行并发更新时外部可观察结果保持一致。
- 会话原则：默认使用 2 个会话；13.1 不需要第三会话。

### 官方范围摘要
- PostgreSQL 使用 MVCC 管理并发访问。
- 每个 SQL 语句看到一致的数据视图。
- 普通查询不读取其他事务尚未提交的数据版本。
- 普通读写在 MVCC 模型下尽量互不阻塞。
- 并发写入同一行时，用户只能观察到一致的数据版本，而不是半完成状态。

## 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖目的 |
|---|---|---|---|---|---|
| F01 | behavior | MVCC 可见性 | 已提交版本、未提交版本 | P0 | 验证普通查询只读取一致可见版本。 |
| F02 | object | 语句类型 | 普通 SELECT、UPDATE | P0 | 覆盖 13.1 中基础读写行为。 |
| F03 | state | 并发事务状态 | 未提交、已提交、并发更新中 | P0 | 覆盖提交前后和并发状态转换。 |
| F04 | condition | 读写并发方向 | 读先于写、写先于读、同一行双写 | P0 | 验证 MVCC 下普通读写互不阻塞和写写一致性。 |
| F05 | parameter | 隔离级别上下文 | READ COMMITTED | P1 | 作为 13.1 基础可见性上下文，隔离级别全矩阵放到 13.2。 |
| F06 | exception/no-test | 章节概念性描述 | 无直接 SQL 行为 | P3 | 概念说明不单独生成用例，由行为类测试点覆盖。 |

## 因子值细化

### F01 MVCC 可见性
| 值ID | 值 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|
| F01-V01 | 普通 SELECT 看不到其他事务未提交版本 | P0 | `MVCC-SNAPSHOT-SELECT-COMMITTED`、`MVCC-SNAPSHOT-NO-DIRTY-READ` |
| F01-V02 | 普通 SELECT 可以看到其他事务提交后的新版本 | P0 | `MVCC-SNAPSHOT-SELECT-COMMITTED` |
| F01-V03 | 并发更新过程中外部只暴露一致版本 | P0 | `MVCC-CONCURRENT-UPDATE-SAME-ROW` |

### F02 语句类型
| 值ID | 值 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|
| F02-V01 | 普通 SELECT | P0 | 所有可见性和读写互不阻塞测试点 |
| F02-V02 | UPDATE | P0 | 读写互不阻塞和同一行并发更新测试点 |

### F03 并发事务状态
| 值ID | 值 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|
| F03-V01 | 并发事务已修改但未提交 | P0 | `MVCC-SNAPSHOT-NO-DIRTY-READ` |
| F03-V02 | 并发事务提交后 | P0 | `MVCC-SNAPSHOT-SELECT-COMMITTED` |
| F03-V03 | 并发事务持有写入状态时另一会话读 | P0 | `MVCC-READ-WRITE-NONBLOCKING-UPDATE-SELECT` |
| F03-V04 | 并发事务持有读视图时另一会话写 | P0 | `MVCC-READ-WRITE-NONBLOCKING-SELECT-UPDATE` |
| F03-V05 | 两个事务并发更新同一行 | P0 | `MVCC-CONCURRENT-UPDATE-SAME-ROW` |

### F04 读写并发方向
| 值ID | 值 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|
| F04-V01 | 普通读不阻塞写 | P0 | `MVCC-READ-WRITE-NONBLOCKING-SELECT-UPDATE` |
| F04-V02 | 写不阻塞普通读 | P0 | `MVCC-READ-WRITE-NONBLOCKING-UPDATE-SELECT` |
| F04-V03 | 同一行并发写入保持一致版本暴露 | P0 | `MVCC-CONCURRENT-UPDATE-SAME-ROW` |

### F05 隔离级别上下文
| 值ID | 值 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|
| F05-V01 | READ COMMITTED 普通语句视图 | P1 | `MVCC-SNAPSHOT-SELECT-COMMITTED` |

### F06 章节概念性描述
| 值ID | 值 | 优先级 | 处理方式 |
|---|---|---|---|
| F06-V01 | MVCC 目标和概念性说明 | P3 | 不单独生成用例，由 F01-F04 的行为测试点覆盖。 |

## No-test 记录

| no-test ID | 对应因子/因子值 | 官方内容 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|---|
| NT01 | F06 / F06-V01 | 13.1 中关于 MVCC 目标、一致视图和并发控制模型的概念性说明。 | 该内容不是一个可直接执行的独立 SQL 行为；如果单独生成用例，会与 F01-F04 的行为测试点重复。 | 在因子矩阵中保留为 P3 no-test，并由 `MVCC-SNAPSHOT-SELECT-COMMITTED`、`MVCC-SNAPSHOT-NO-DIRTY-READ`、读写非阻塞和同一行并发更新类测试点共同证明。 |

## 组合方式

| 组合ID | 组合方法 | 覆盖因子 | 生成的测试点 | 组合理由 |
|---|---|---|---|---|
| C01 | state-transition | F01,F02,F03,F05 | `MVCC-SNAPSHOT-SELECT-COMMITTED` | 覆盖提交前不可见、提交后新语句可见的最小状态转换。 |
| C02 | boundary-directed | F01,F02,F03 | `MVCC-SNAPSHOT-NO-DIRTY-READ` | 单独验证 dirty read 边界，避免被一般“已提交可见”用例吞并。 |
| C03 | single-factor | F02,F04 | `MVCC-READ-WRITE-NONBLOCKING-SELECT-UPDATE` | 单独验证普通读不阻塞写。 |
| C04 | single-factor | F02,F04 | `MVCC-READ-WRITE-NONBLOCKING-UPDATE-SELECT` | 单独验证写不阻塞普通读。 |
| C05 | concurrency-directed | F01,F02,F03,F04 | `MVCC-CONCURRENT-UPDATE-SAME-ROW` | 单独验证同一行并发更新下的一致版本暴露。 |
| C06 | no-test | F06 | 不生成测试点 | 纯概念说明已被行为测试点覆盖。 |

## 测试点清单

### MVCC-SNAPSHOT-SELECT-COMMITTED
- 优先级：P0
- 覆盖类型：并发 / 正向 / 边界
- 测试点：普通 `SELECT` 只看到已提交版本；并发事务提交后，READ COMMITTED 下的新语句能看到提交后的值。
- 覆盖因子值：F01-V01、F01-V02、F02-V01、F03-V01、F03-V02、F05-V01
- 组合方式：C01 state-transition
- 充分性说明：覆盖 13.1 中“一致视图”和“已提交版本可见”的基础状态转换。

### MVCC-SNAPSHOT-NO-DIRTY-READ
- 优先级：P0
- 覆盖类型：并发 / 反向 / 边界
- 测试点：并发事务未提交变更不可见。
- 覆盖因子值：F01-V01、F02-V01、F03-V01
- 组合方式：C02 boundary-directed
- 充分性说明：单独验证未提交版本不可见，避免 dirty read 边界被主路径覆盖得不清楚。

### MVCC-READ-WRITE-NONBLOCKING-SELECT-UPDATE
- 优先级：P0
- 覆盖类型：并发 / 正向
- 测试点：普通读不阻塞写。
- 覆盖因子值：F02-V01、F02-V02、F03-V04、F04-V01
- 组合方式：C03 single-factor
- 充分性说明：单独验证读先于写方向的非阻塞语义。

### MVCC-READ-WRITE-NONBLOCKING-UPDATE-SELECT
- 优先级：P0
- 覆盖类型：并发 / 正向
- 测试点：写不阻塞普通读。
- 覆盖因子值：F02-V01、F02-V02、F03-V03、F04-V02
- 组合方式：C04 single-factor
- 充分性说明：单独验证写先于读方向的非阻塞语义，与 C03 互补。

### MVCC-CONCURRENT-UPDATE-SAME-ROW
- 优先级：P0
- 覆盖类型：并发 / 正向
- 测试点：同一行并发更新只暴露一致版本。
- 覆盖因子值：F01-V03、F02-V02、F03-V05、F04-V03
- 组合方式：C05 concurrency-directed
- 充分性说明：补足普通读写互不阻塞之外的同一行并发写一致性场景。

## 充分性结论
- 13.1 的 P0 行为因子均已有对应测试点。
- 已覆盖 MVCC 基础可见性、未提交版本不可见、提交后可见、读写两个方向互不阻塞、同一行并发更新一致性。
- 隔离级别矩阵、锁模式矩阵、死锁、Serializable、显式锁和索引并发不放在 13.1 覆盖，避免与 13.2-13.7 重复。
- 纯概念性描述不单独生成用例，但在因子矩阵中保留 no-test 说明。
