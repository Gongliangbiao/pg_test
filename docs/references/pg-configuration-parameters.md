# PostgreSQL 16.4 配置参数参考

> 来源：PostgreSQL 16.4 Documentation - Chapter 20. Server Configuration

---

## 一、参数设置方式分类（第一层）

### 1.1 设置方式概述

PostgreSQL参数可通过多种方式设置，每种方式的生效时机不同：

| 设置方式 | 生效时机 | 适用参数范围 |
|----------|----------|--------------|
| **postgresql.conf** | 启动时或SIGHUP reload | 大部分参数 |
| **ALTER SYSTEM** | 写入postgresql.auto.conf，reload后生效 | 大部分参数 |
| **ALTER DATABASE** | 新会话连接时生效 | 会话级参数 |
| **ALTER ROLE** | 新会话连接时生效 | 会话级参数 |
| **SET 命令** | 当前会话立即生效 | 会话级参数 |
| **命令行 -c** | 启动时生效 | 启动参数 |
| **PGOPTIONS环境变量** | 客户端会话开始时 | 会话级参数 |

### 1.2 参数Context分类

参数的`context`属性决定了何时可以设置：

| Context | 说明 | 设置方式 |
|---------|------|----------|
| `postmaster` | **仅服务器启动时** | postgresql.conf + 重启，或 -c 参数 |
| `sighup` | **需要SIGHUP信号reload** | postgresql.conf + `pg_ctl reload` 或 `pg_reload_conf()` |
| `backend` | **会话开始时** | ALTER DATABASE, ALTER ROLE |
| `superuser` | **超级用户可随时设置** | SET 命令（需超级用户权限） |
| `user` | **普通用户可随时设置** | SET 命令 |

---

## 二、参数类型与值格式

### 2.1 参数类型

| 类型 | 有效值格式 | 示例 |
|------|------------|------|
| **Boolean** | on, off, true, false, yes, no, 1, 0 | `log_connections = on` |
| **String** | 单引号包裹，内部单引号需双写 | `log_destination = 'syslog'` |
| **Integer** | 十进制、十六进制(0x)、八进制(0) | `shared_buffers = 128MB` |
| **Floating Point** | 十进制浮点数 | `checkpoint_completion_target = 0.9` |
| **Enum** | 限定值集合 | `wal_level = replica` |

### 2.2 内存单位

| 单位 | 说明 | 倍数 |
|------|------|------|
| B | 字节 | 1 |
| kB | 千字节 | 1024 |
| MB | 兆字节 | 1024² |
| GB | 吉字节 | 1024³ |
| TB | 太字节 | 1024⁴ |

### 2.3 时间单位

| 单位 | 说明 |
|------|------|
| us | 微秒 |
| ms | 毫秒 |
| s | 秒 |
| min | 分钟 |
| h | 小时 |
| d | 天 |

---

## 三、查看参数设置

### 3.1 查看命令

```sql
-- 查看单个参数
SHOW parameter_name;

-- 查看所有参数
SHOW ALL;

-- 查看参数详细信息
SELECT * FROM pg_settings WHERE name = 'parameter_name';

-- 查看参数来源
SELECT name, setting, source, sourcefile, sourceline FROM pg_settings;

-- 使用current_setting函数
SELECT current_setting('shared_buffers');
```

### 3.2 pg_settings视图字段

| 字段 | 说明 |
|------|------|
| name | 参数名 |
| setting | 当前值 |
| unit | 单位 |
| category | 分类 |
| short_desc | 简短描述 |
| extra_desc | 详细描述 |
| context | 设置上下文（postmaster/sighup/backend/superuser/user） |
| vartype | 类型（bool/string/integer/real/enum） |
| source | 来源（default/configuration file/command line/environment variable等） |
| min_val | 最小值 |
| max_val | 最大值 |
| enumvals | Enum有效值列表 |
| boot_val | 启动默认值 |
| reset_val | RESET后恢复的值 |
| default_val | 编译时默认值 |

---

## 四、功能分类参数（第二层）

### 4.1 文件位置 (File Locations)

**Context: postmaster（仅启动时设置）**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| data_directory | string | - | 数据存储目录 |
| config_file | string | - | 主配置文件路径（仅命令行） |
| hba_file | string | - | pg_hba.conf路径 |
| ident_file | string | - | pg_ident.conf路径 |
| external_pid_file | string | - | PID文件路径 |

---

### 4.2 连接与认证 (Connections and Authentication)

#### 4.2.1 连接设置

**仅启动时设置 (postmaster)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| listen_addresses | string | localhost | 监听IP地址（*表示所有） |
| port | integer | 5432 | TCP端口 |
| max_connections | integer | 100 | 最大并发连接数 |
| reserved_connections | integer | 0 | 保留连接槽 |
| superuser_reserved_connections | integer | 3 | 超级用户保留槽 |
| unix_socket_directories | string | /tmp | Unix socket目录 |
| unix_socket_group | string | - | socket所属组 |
| unix_socket_permissions | integer | 0777 | socket权限 |
| bonjour | boolean | off | Bonjour广播 |
| bonjour_name | string | - | Bonjour服务名 |

#### 4.2.2 TCP设置

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| tcp_keepalives_idle | integer | 0 | sighup | TCP keepalive空闲时间 |
| tcp_keepalives_interval | integer | 0 | sighup | keepalive重传间隔 |
| tcp_keepalives_count | integer | 0 | sighup | keepalive重试次数 |
| tcp_user_timeout | integer | 0 | sighup | TCP用户超时 |
| client_connection_check_interval | integer | 0 | sighup | 连接检查间隔 |

#### 4.2.3 认证设置

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 有效值 | 说明 |
|------|------|--------|--------|------|
| authentication_timeout | integer | 1m | - | 认证超时时间 |
| password_encryption | enum | scram-sha-256 | scram-sha-256, md5 | 密码加密算法 |
| scram_iterations | integer | 4096 | - | SCRAM迭代次数 |
| krb_server_keyfile | string | - | - | Kerberos key文件 |
| krb_caseins_users | boolean | off | - | Kerberos用户名大小写 |
| gss_accept_delegation | boolean | off | - | GSSAPI委托 |
| db_user_namespace | boolean | off | - | 按数据库的用户名空间 |

#### 4.2.4 SSL设置

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| ssl | boolean | off | 启用SSL连接 |
| ssl_ca_file | string | - | CA证书文件 |
| ssl_cert_file | string | server.crt | 服务器证书 |
| ssl_crl_file | string | - | CRL文件 |
| ssl_crl_dir | string | - | CRL目录 |
| ssl_key_file | string | server.key | 服务器私钥 |
| ssl_ciphers | string | HIGH:MEDIUM:+3DES:!aNULL | SSL加密套件 |
| ssl_prefer_server_ciphers | boolean | on | 使用服务器加密偏好 |
| ssl_ecdh_curve | string | prime256v1 | ECDH曲线 |
| ssl_min_protocol_version | enum | TLSv1.2 | TLSv1, TLSv1.1, TLSv1.2, TLSv1.3 |
| ssl_max_protocol_version | enum | - | 同上，空表示任意 |
| ssl_dh_params_file | string | - | DH参数文件 |
| ssl_passphrase_command | string | - | 密码获取命令 |
| ssl_passphrase_command_supports_reload | boolean | off | reload时调用密码命令 |

---

### 4.3 资源消耗 (Resource Consumption)

#### 4.3.1 内存设置

**仅启动时设置 (postmaster)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| shared_buffers | integer | 128MB | 共享内存缓冲区 |
| huge_pages | enum | try | try, on, off |
| huge_page_size | integer | 0 | 大页大小 |
| temp_buffers | integer | 8MB | 临时表缓冲区 |
| max_prepared_transactions | integer | 0 | 最大预备事务数 |
| shared_memory_type | enum | mmap | mmap, sysv, windows |
| dynamic_shared_memory_type | enum | posix | posix, sysv, windows, mmap |
| min_dynamic_shared_memory | integer | 0 | 动态共享内存最小值 |

**会话级设置 (user/superuser)**：

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| work_mem | integer | 4MB | user | 单个操作内存上限 |
| hash_mem_multiplier | float | 2.0 | user | Hash操作内存倍数 |
| maintenance_work_mem | integer | 64MB | user | 维护操作内存上限 |
| autovacuum_work_mem | integer | -1 | sighup | autovacuum内存（-1用maintenance_work_mem） |
| vacuum_buffer_usage_limit | integer | 256kB | user | VACUUM缓冲策略大小 |
| logical_decoding_work_mem | integer | 64MB | user | 逻辑解码内存上限 |
| max_stack_depth | integer | 2MB | superuser | 栈深度上限 |

#### 4.3.2 磁盘设置

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| temp_file_limit | integer | -1 | superuser | 临时文件大小上限（-1无限制） |

#### 4.3.3 内核资源

**仅启动时设置 (postmaster)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| max_files_per_process | integer | 1000 | 每进程最大打开文件数 |

#### 4.3.4 Cost-based Vacuum Delay

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| vacuum_cost_delay | float | 0 | user | 超限后休眠时间（ms） |
| vacuum_cost_page_hit | integer | 1 | user | 缓存页代价 |
| vacuum_cost_page_miss | integer | 2 | user | 磁盘页代价 |
| vacuum_cost_page_dirty | integer | 20 | user | 修改页代价 |
| vacuum_cost_limit | integer | 200 | user | 代价累积上限 |

#### 4.3.5 Background Writer

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| bgwriter_delay | integer | 200ms | 后台写进程间隔 |
| bgwriter_lru_maxpages | integer | 100 | 每轮最大写入页数 |
| bgwriter_lru_multiplier | float | 2.0 | LRU写入倍数 |
| bgwriter_flush_after | integer | 512kB | 强制刷写阈值 |

#### 4.3.6 异步行为

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| backend_flush_after | integer | 0 | sighup | 后端刷写阈值 |
| effective_io_concurrency | integer | 1 | user | 并发I/O数 |
| maintenance_io_concurrency | integer | 10 | user | 维护I/O并发数 |
| max_worker_processes | integer | 8 | postmaster | 最大后台进程数 |
| max_parallel_workers_per_gather | integer | 2 | user | 单Gather最大workers |
| max_parallel_maintenance_workers | integer | 2 | user | 维护并行workers |
| max_parallel_workers | integer | 8 | user | 总并行workers上限 |
| parallel_leader_participation | boolean | on | user | Leader参与并行执行 |
| old_snapshot_threshold | integer | -1 | postmaster | 快照过期阈值（分钟） |

---

### 4.4 WAL设置 (Write Ahead Log)

#### 4.4.1 WAL基本设置

**仅启动时设置 (postmaster)**：

| 参数 | 类型 | 默认值 | 有效值 | 说明 |
|------|------|--------|--------|------|
| wal_level | enum | replica | minimal, replica, logical | WAL记录级别 |

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| fsync | boolean | on | 物理刷写到磁盘 |
| synchronous_commit | enum | on | remote_apply, on, remote_write, local, off |
| wal_sync_method | enum | fdatasync | open_datasync, fdatasync, fsync, fsync_writethrough, open_sync |
| full_page_writes | boolean | on | checkpoint后首次修改写完整页 |
| wal_log_hints | boolean | off | WAL记录hint bits |
| wal_compression | enum | off | off, pglz, lz4, zstd |
| wal_init_zero | boolean | on | 新WAL文件填零 |
| wal_recycle | boolean | on | WAL文件回收 |
| wal_buffers | integer | -1 | WAL缓冲区（-1自动） |
| wal_writer_delay | integer | 200ms | WAL写入间隔 |
| wal_writer_flush_after | integer | 1MB | WAL刷写阈值 |
| wal_skip_threshold | integer | 2MB | WAL跳过阈值 |
| commit_delay | integer | 0 | 组提交延迟（微秒） |
| commit_siblings | integer | 5 | 组提交最小并发事务数 |

#### 4.4.2 Checkpoints

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| checkpoint_timeout | integer | 5min | 自动checkpoint间隔 |
| checkpoint_completion_target | float | 0.9 | checkpoint完成目标比例 |
| checkpoint_flush_after | integer | 256kB | checkpoint刷写阈值 |
| checkpoint_warning | integer | 30s | checkpoint间隔警告阈值 |
| max_wal_size | integer | 1GB | checkpoint间WAL最大大小 |
| min_wal_size | integer | 80MB | WAL最小保留大小 |

#### 4.4.3 Archiving

**仅启动时设置 (postmaster)**：

| 参数 | 类型 | 默认值 | 有效值 | 说明 |
|------|------|--------|--------|------|
| archive_mode | enum | off | off, on, always | WAL归档模式 |

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| archive_command | string | - | 归档Shell命令（%p路径, %f文件名） |
| archive_library | string | - | 归档库 |
| archive_timeout | integer | 0 | 强制归档间隔 |

#### 4.4.4 Recovery

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| recovery_prefetch | enum | try | sighup | off, on, try - 恢复预取 |
| wal_decode_buffer_size | integer | 512kB | sighup | WAL解码缓冲区 |

#### 4.4.5 Archive Recovery

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| restore_command | string | - | 恢复WAL命令 |
| archive_cleanup_command | string | - | 归档清理命令 |
| recovery_end_command | string | - | 恢复结束命令 |

#### 4.4.6 Recovery Target

**仅启动时设置 (postmaster)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| recovery_target | string | - | 恢复目标（immediate） |
| recovery_target_name | string | - | 恢复目标名 |
| recovery_target_time | timestamp | - | 恢复目标时间 |
| recovery_target_xid | string | - | 恢复目标事务ID |
| recovery_target_lsn | pg_lsn | - | 恢复目标LSN |
| recovery_target_inclusive | boolean | on | 包含目标点 |
| recovery_target_timeline | string | latest | 恢复时间线 |
| recovery_target_action | enum | pause | pause, promote, shutdown |

---

### 4.5 复制设置 (Replication)

#### 4.5.1 发送服务器

**仅启动时设置 (postmaster)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| max_wal_senders | integer | 10 | 最大WAL发送进程数 |
| max_replication_slots | integer | 10 | 最大复制槽数 |

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| wal_keep_size | integer | 0 | 保留WAL最小大小 |
| max_slot_wal_keep_size | integer | -1 | 复制槽保留WAL上限 |
| wal_sender_timeout | integer | 60s | WAL发送超时 |
| track_commit_timestamp | boolean | off | 记录提交时间戳 |

#### 4.5.2 主服务器

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| synchronous_standby_names | string | - | 同步备机列表 |

#### 4.5.3 备服务器

**仅启动时设置 (postmaster)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| hot_standby | boolean | on | 恢复期间允许查询 |

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| primary_conninfo | string | - | 连接主服务器的连接串 |
| primary_slot_name | string | - | 主服务器复制槽名 |
| max_standby_archive_delay | integer | 30s | 归档WAL冲突查询延迟 |
| max_standby_streaming_delay | integer | 30s | 流复制WAL冲突查询延迟 |
| wal_receiver_create_temp_slot | boolean | off | 创建临时复制槽 |
| wal_receiver_status_interval | integer | 10s | 复制状态报告间隔 |
| hot_standby_feedback | boolean | off | 向主服务器反馈 |
| wal_receiver_timeout | integer | 60s | WAL接收超时 |
| wal_retrieve_retry_interval | integer | 5s | WAL获取重试间隔 |

#### 4.5.4 订阅服务器

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| max_logical_replication_workers | integer | 4 | 逻辑复制workers |
| max_sync_workers_per_subscription | integer | 2 | 每订阅同步workers |

---

### 4.6 查询规划 (Query Planning)

#### 4.6.1 规划方法配置

**会话级设置 (user)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| enable_async_append | boolean | on | 异步Append |
| enable_bitmapscan | boolean | on | 位图扫描 |
| enable_gathermerge | boolean | on | Gather Merge |
| enable_hashagg | boolean | on | Hash聚合 |
| enable_hashjoin | boolean | on | Hash连接 |
| enable_incremental_sort | boolean | on | 增量排序 |
| enable_indexscan | boolean | on | 索引扫描 |
| enable_indexonlyscan | boolean | on | 仅索引扫描 |
| enable_material | boolean | on | 物化 |
| enable_memoize | boolean | on | Memoize |
| enable_mergejoin | boolean | on | Merge连接 |
| enable_nestloop | boolean | on | 嵌套循环 |
| enable_parallel_append | boolean | on | 并行Append |
| enable_parallel_hash | boolean | on | 并行Hash |
| enable_partition_pruning | boolean | on | 分区剪裁 |
| enable_partitionwise_join | boolean | off | 分区级连接 |
| enable_partitionwise_aggregate | boolean | off | 分区级聚合 |
| enable_seqscan | boolean | on | 序列扫描 |
| enable_sort | boolean | on | 排序 |
| enable_tidscan | boolean | on | TID扫描 |

#### 4.6.2 规划代价常数

**会话级设置 (user)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| seq_page_cost | float | 1.0 | 序列页代价 |
| random_page_cost | float | 4.0 | 随机页代价 |
| cpu_tuple_cost | float | 0.01 | CPU元组代价 |
| cpu_index_tuple_cost | float | 0.005 | CPU索引元组代价 |
| cpu_operator_cost | float | 0.0025 | CPU操作代价 |
| parallel_setup_cost | float | 1000 | 并行设置代价 |
| parallel_tuple_cost | float | 0.1 | 并行元组代价 |
| min_parallel_table_scan_size | integer | 8MB | 最小并行表扫描大小 |
| min_parallel_index_scan_size | integer | 512kB | 最小并行索引扫描大小 |
| effective_cache_size | integer | 4GB | 有效缓存大小 |

#### 4.6.3 遗传查询优化器

**会话级设置 (user)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| geqo | boolean | on | 启用GEQO |
| geqo_threshold | integer | 12 | GEQO触发阈值 |
| geqo_effort | integer | 5 | GEQO努力程度 |
| geqo_pool_size | integer | 0 | GEQO池大小（0自动） |
| geqo_generations | integer | 0 | GEQO代数 |
| geqo_selection_bias | float | 2.0 | GEQO选择偏置 |
| geqo_seed | float | 0 | GEQO随机种子 |

#### 4.6.4 其他规划选项

**会话级设置 (user)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| default_statistics_target | integer | 100 | 默认统计目标 |
| constraint_exclusion | enum | partition | on, off, partition |
| cursor_tuple_fraction | float | 0.1 | 游标元组比例 |
| from_collapse_limit | integer | 8 | FROM列表折叠上限 |
| join_collapse_limit | integer | 8 | JOIN折叠上限 |
| recursive_worktable_factor | float | 10.0 | 递归工作表因子 |
| optimize_bounded_sort | boolean | on | 优化有界排序 |

---

### 4.7 错误报告与日志 (Error Reporting and Logging)

#### 4.7.1 日志位置

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 有效值 | 说明 |
|------|------|--------|--------|------|
| log_destination | string | stderr | stderr, csvlog, jsonlog, syslog, eventlog | 日志目的地 |
| logging_collector | boolean | off | - | 启用日志收集器 |
| log_directory | string | log | - | 日志目录 |
| log_filename | string | postgresql-%Y-%m-%d_%H%M%S.log | - | 日志文件名 |
| log_file_mode | integer | 0600 | - | 日志文件权限 |
| log_rotation_age | integer | 1d | - | 日志轮转间隔 |
| log_rotation_size | integer | 10MB | - | 日志轮转大小 |
| log_truncate_on_rotation | boolean | off | - | 轮转时截断 |

#### 4.7.2 何时记录日志

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| log_min_messages | enum | warning | DEBUG5..DEBUG1, INFO, NOTICE, WARNING, ERROR, LOG, FATAL, PANIC |
| log_min_error_statement | enum | error | 同上 |
| log_min_duration_statement | integer | -1 | 记录超过此时间的语句（-1不记录） |
| log_statement_sample_rate | float | 1.0 | 语句采样率 |
| log_xact_rate_limit | integer | -1 | 事务日志速率限制 |
| log_error_verbosity | enum | default | terse, default, verbose |
| log_hostname | boolean | off | 记录主机名 |
| log_line_prefix | string | - | 日志行前缀 |
| log_statement | enum | none | none, ddl, mod, all |
| log_transaction_sample_rate | float | 0.0 | 事务采样率 |

#### 4.7.3 记录什么内容

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| debug_print_parse | boolean | off | user | 打印解析树 |
| debug_print_rewritten | boolean | off | user | 打印重写树 |
| debug_print_plan | boolean | off | user | 打印计划树 |
| debug_pretty_print | boolean | on | user | 美化打印 |
| log_checkpoints | boolean | off | sighup | 记录checkpoint |
| log_connections | boolean | off | sighup | 记录连接 |
| log_disconnections | boolean | off | sighup | 记录断开连接 |
| log_duration | boolean | off | user | 记录语句时长 |
| log_lock_waits | boolean | off | user | 记录锁等待 |
| log_parameter_max_length | integer | -1 | user | 参数日志长度上限 |
| log_parameter_max_length_on_error | integer | 0 | user | 错误时参数长度 |
| log_recovery_conflict_waits | boolean | off | sighup | 记录恢复冲突等待 |
| log_recovery_conflict_waits_policy | enum | conflict | sighup | 冲突等待记录策略 |
| log_statement_stats | boolean | off | user | 记录语句统计 |
| log_temp_files | integer | -1 | user | 记录临时文件（-1不记录） |
| log_timezone | string | GMT | sighup | 日志时区 |

---

### 4.8 运行时统计 (Run-time Statistics)

#### 4.8.1 累计查询和索引统计

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| track_activities | boolean | on | sighup | 跟踪活动命令 |
| track_activity_query_size | integer | 1024 | postmaster | 活动查询大小上限 |
| track_counts | boolean | on | sighup | 跟踪统计计数 |
| track_io_timing | boolean | off | sighup | 跟踪I/O时间 |
| track_wal_io_timing | boolean | off | sighup | 跟踪WAL I/O时间 |
| track_functions | enum | none | sighup | none, pl, all - 跟踪函数 |
| stats_fetch_consistency | enum | none | user | none, cache, snapshot |

#### 4.8.2 统计监控

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| compute_query_id | enum | auto | user | auto, on, off, regress - 计算查询ID |
| log_parser_stats | boolean | off | user | 记录解析器统计 |
| log_planner_stats | boolean | off | user | 记录规划器统计 |
| log_executor_stats | boolean | off | user | 记录执行器统计 |

---

### 4.9 自动清理 (Automatic Vacuuming)

**仅配置文件/命令行 (sighup)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| autovacuum | boolean | on | 启用autovacuum |
| autovacuum_max_workers | integer | 3 | 最大autovacuum workers |
| autovacuum_naptime | integer | 1min | autovacuum间隔 |
| autovacuum_vacuum_threshold | integer | 50 | vacuum触发阈值 |
| autovacuum_vacuum_insert_threshold | integer | 1000 | insert vacuum阈值 |
| autovacuum_analyze_threshold | integer | 50 | analyze触发阈值 |
| autovacuum_vacuum_scale_factor | float | 0.2 | vacuum比例因子 |
| autovacuum_vacuum_insert_scale_factor | float | 0.2 | insert vacuum比例 |
| autovacuum_analyze_scale_factor | float | 0.1 | analyze比例因子 |
| autovacuum_freeze_max_age | integer | 200M | freeze最大年龄 |
| autovacuum_multixact_freeze_max_age | integer | 400M | multixact freeze最大年龄 |
| autovacuum_vacuum_cost_delay | float | 2ms | autovacuum代价延迟 |
| autovacuum_vacuum_cost_limit | integer | -1 | autovacuum代价上限（-1用vacuum_cost_limit） |
| autovacuum_work_mem | integer | -1 | autovacuum内存 |

---

### 4.10 客户端连接默认值 (Client Connection Defaults)

#### 4.10.1 语句行为

**会话级设置 (user/superuser)**：

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| default_table_access_method | string | heap | user | 默认表访问方法 |
| default_tablespace | string | - | user | 默认表空间 |
| default_toast_compression | enum | pglz | user | pglz, lz4 - 默认TOAST压缩 |
| temp_tablespaces | string | - | user | 临时表空间列表 |
| check_function_bodies | boolean | on | user | 检查函数体 |
| default_transaction_isolation | enum | read committed | user | read committed, repeatable read, serializable |
| default_transaction_read_only | boolean | off | user | 默认只读事务 |
| default_transaction_deferrable | boolean | off | user | 默认可延迟事务 |
| default_transaction_timeout | integer | 0 | user | 默认事务超时（0无限制） |
| session_replication_role | enum | origin | superuser | origin, replica, local |
| statement_timeout | integer | 0 | user | 语句超时（0无限制） |
| lock_timeout | integer | 0 | user | 锁超时 |
| idle_in_transaction_session_timeout | integer | 0 | user | idle事务超时 |
| idle_session_timeout | integer | 0 | user | idle会话超时 |
| transaction_timeout | integer | 0 | user | 事务超时 |
| vacuum_freeze_table_age | integer | 150M | user | vacuum freeze表年龄 |
| vacuum_freeze_min_age | integer | 50M | user | vacuum freeze最小年龄 |
| vacuum_multixact_freeze_table_age | integer | 150M | user | multixact freeze表年龄 |
| vacuum_multixact_freeze_min_age | integer | 5M | user | multixact freeze最小年龄 |
| vacuum_skip_damaged_pages | boolean | off | user | vacuum跳过损坏页 |
| wal_consistency_checking | string | - | superuser | WAL一致性检查 |
| wal_debug | boolean | off | superuser | WAL调试 |
| data_checksum_mode | boolean | off | postmaster | 数据校验模式 |

#### 4.10.2 区域和格式

**会话级设置 (user)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| DateStyle | string | ISO, MDY | 日期格式 |
| IntervalStyle | string | postgres | interval格式 |
| TimeZone | string | GMT | 时区 |
| timezone_abbreviations | string | Default | 时区缩写 |
| extra_float_digits | integer | 1 | 浮点精度位数 |
| float_base_precision_output | enum | decimal | decimal, hexadecimal, short_decimal, short_hexadecimal |
| client_encoding | string | UTF8 | 客户端编码 |
| lc_messages | string | - | 消息语言 |
| lc_monetary | string | - | 货币格式 |
| lc_numeric | string | - | 数字格式 |
| lc_time | string | - | 时间格式 |
| default_text_search_config | string | pg_catalog.simple | 默认文本搜索配置 |

#### 4.10.3 共享库预加载

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| session_preload_libraries | string | - | sighup | 会话预加载库 |
| shared_preload_libraries | string | - | postmaster | 共享预加载库 |
| local_preload_libraries | string | - | backend | 本地预加载库 |

#### 4.10.4 其他默认值

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| dynamic_library_path | string | $libdir | user | 动态库路径 |
| extension_destdir | string | - | postmaster | 扩展目标目录 |
| extension_dynamic_path | string | - | user | 扩展动态路径 |
| gin_pending_list_limit | integer | 4MB | user | GIN待处理列表上限 |
| xmlbinary | enum | base64 | user | base64, hex |
| xmloption | enum | content | user | content, document |

---

### 4.11 锁管理 (Lock Management)

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| deadlock_timeout | integer | 1s | superuser | 死锁检测超时 |
| max_locks_per_transaction | integer | 64 | postmaster | 每事务最大锁数 |
| max_pred_locks_per_transaction | integer | 64 | postmaster | 每事务最大谓词锁数 |
| max_pred_locks_per_relation | integer | -2 | sighup | 每关系最大谓词锁数 |
| max_pred_locks_per_page | integer | 2 | sighup | 每页最大谓词锁数 |

---

### 4.12 版本和平台兼容性 (Version and Platform Compatibility)

#### 4.12.1 PostgreSQL版本兼容

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| array_nulls | boolean | on | user | 数组NULL元素 |
| backslash_quote | enum | safe_encoding | user | safe_encoding, on, off - 反斜杠引号 |
| escape_string_warning | boolean | on | user | 转义字符串警告 |
| lo_compat_privileges | boolean | off | superuser | LO权限兼容 |
| operator_precedence_warning | boolean | off | user | 运算符优先级警告 |
| quote_all_identifiers | boolean | off | user | 引号所有标识符 |
| standard_conforming_strings | boolean | on | user | 标准字符串 |
| synchronize_seqscans | boolean | on | user | 同步序列扫描 |

#### 4.12.2 平台和客户端兼容

| 参数 | 类型 | 默认值 | Context | 说明 |
|------|------|--------|---------|------|
| transform_null_equals | boolean | off | user | NULL = NULL 转换 |

---

### 4.13 错误处理 (Error Handling)

**仅启动时设置 (postmaster)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| exit_on_error | boolean | off | 错误时退出 |
| restart_after_crash | boolean | on | 崩溃后重启 |
| data_sync_retry | enum | off | off, on - 数据同步重试 |
| ignore_invalid_pages | boolean | off | 忽略无效页（仅恢复） |
| ignore_system_indexes | boolean | off | 忽略系统索引 |

---

### 4.14 预设选项 (Preset Options)

**不可更改（只读）**：

| 参数 | 类型 | 说明 |
|------|------|------|
| server_version_num | integer | 服务器版本号 |
| server_version | string | 服务器版本字符串 |
| block_size | integer | 块大小 |
| data_directory_mode | integer | 数据目录模式 |
| data_checksums | boolean | 数据校验启用状态 |
| integer_datetimes | boolean | 整数日期时间 |
| max_function_args | integer | 最大函数参数数 |
| max_identifier_length | integer | 最大标识符长度 |
| max_index_keys | integer | 最大索引键数 |
| segment_size | integer | 段大小 |
| wal_block_size | integer | WAL块大小 |
| wal_segment_size | integer | WAL段大小 |

---

### 4.15 自定义选项 (Customized Options)

自定义选项以自定义前缀命名，格式为 `custom.variable_name`。可通过SET命令设置。

---

### 4.16 开发者选项 (Developer Options)

**会话级设置 (superuser)**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| allow_system_table_mods | boolean | off | 允许修改系统表 |
| ignore_checksum_failure | boolean | off | 忽略校验失败 |
| ignore_memory_references | boolean | off | 忽略内存引用 |
| zero_damaged_pages | boolean | off | 清零损坏页 |
| wal_consistency_checking | string | - | WAL一致性检查 |
| wal_debug | boolean | off | WAL调试 |

---

## 五、设置参数示例

### 5.1 通过配置文件设置

```bash
# 编辑 postgresql.conf
shared_buffers = 256MB
max_connections = 200
log_destination = 'syslog'

# reload配置
pg_ctl reload
# 或SQL
SELECT pg_reload_conf();
```

### 5.2 通过ALTER SYSTEM设置

```sql
-- 设置参数（写入postgresql.auto.conf）
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET log_connections = on;

-- 删除设置（恢复默认）
ALTER SYSTEM RESET log_connections;
ALTER SYSTEM RESET ALL;

-- 需要reload生效
SELECT pg_reload_conf();
```

### 5.3 通过ALTER DATABASE设置

```sql
-- 为特定数据库设置默认值
ALTER DATABASE mydb SET work_mem = '64MB';
ALTER DATABASE mydb SET log_min_duration_statement = 100;
```

### 5.4 通过ALTER ROLE设置

```sql
-- 为特定角色设置默认值
ALTER ROLE myuser SET work_mem = '32MB';

-- 为特定角色在特定数据库设置
ALTER ROLE myuser IN DATABASE mydb SET work_mem = '128MB';
```

### 5.5 通过SET命令设置

```sql
-- 会话级设置
SET work_mem = '64MB';
SET synchronous_commit TO off;

-- 仅当前事务有效
SET LOCAL work_mem = '128MB';

-- 恢复默认值
RESET work_mem;
RESET ALL;
```

### 5.6 查看参数设置

```sql
-- 查看单个参数
SHOW shared_buffers;

-- 查看所有参数
SHOW ALL;

-- 查看参数详细信息
SELECT name, setting, unit, context, source 
FROM pg_settings 
WHERE name LIKE 'wal%';

-- 查看当前值
SELECT current_setting('work_mem');

-- 设置参数值
SELECT set_config('work_mem', '64MB', false);  -- false=会话级
SELECT set_config('work_mem', '64MB', true);   -- true=仅当前事务
```

---

## 六、参数优先级

设置优先级（从高到低）：

1. **命令行 -c 参数**（最高，不可覆盖）
2. **ALTER ROLE IN DATABASE**
3. **ALTER DATABASE**
4. **ALTER ROLE**
5. **SET 命令**
6. **ALTER SYSTEM**（postgresql.auto.conf）
7. **postgresql.conf**
8. **编译时默认值**（最低）

---

## 七、重要参数参考值

### 7.1 内存配置建议

| 系统内存 | shared_buffers | work_mem | maintenance_work_mem | effective_cache_size |
|----------|---------------|----------|---------------------|---------------------|
| 2GB | 512MB | 4-8MB | 128MB | 1.5GB |
| 4GB | 1GB | 8-16MB | 256MB | 3GB |
| 8GB | 2GB | 16-32MB | 512MB | 6GB |
| 16GB | 4GB | 32-64MB | 1GB | 12GB |
| 32GB | 8GB | 64-128MB | 2GB | 24GB |
| 64GB | 16GB | 128-256MB | 4GB | 48GB |

### 7.2 并发配置建议

| 使用场景 | max_connections | max_worker_processes |
|----------|-----------------|---------------------|
| OLTP高并发 | 200-500 | 8-16 |
| OLAP分析 | 50-100 | 16-32 |
| 混合负载 | 100-200 | 8-16 |

---

## 附录：参数Context映射表

| Context值 | 设置方式 |
|-----------|----------|
| postmaster | postgresql.conf + 重启，或 postgres -c |
| sighup | postgresql.conf + pg_ctl reload / pg_reload_conf() |
| backend | ALTER DATABASE, ALTER ROLE（会话开始时） |
| superuser | SET（需超级用户），ALTER DATABASE/ROLE |
| user | SET（任何用户），ALTER DATABASE/ROLE |

---

> **文档版本**: PostgreSQL 16.4
> **生成日期**: 2026-05-13
> **来源**: PostgreSQL 16.4 Documentation Chapter 20