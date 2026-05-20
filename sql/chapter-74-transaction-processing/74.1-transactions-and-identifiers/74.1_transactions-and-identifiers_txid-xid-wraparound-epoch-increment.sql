--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : 普通 xid 是 32 位循环空间，超过 2^32 次分配后低 32 位数值会 wraparound 并再次出现；每次 wraparound 时 32 位 epoch 递增，完整逻辑顺序应结合 epoch/xid8 理解。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-xid-wraparound-epoch-increment.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V14,F02-V07,F03-V04,F04-V04
-- combination_strategy: boundary-directed
-- case_id: TXID-XID-WRAPAROUND-EPOCH-INCREMENT
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. 记录 xid wraparound 设计边界，不执行 2^32 次事务分配
DROP TABLE IF EXISTS tab_741_txid_xid_wraparound_epoch_increment;
CREATE TABLE tab_741_txid_xid_wraparound_epoch_increment (
    id int PRIMARY KEY,
    marker text NOT NULL,
    amount numeric(8,2) DEFAULT 0,
    created_on date DEFAULT DATE '2026-05-20'
);
INSERT INTO tab_741_txid_xid_wraparound_epoch_increment(id, marker, amount) VALUES (1, 'wraparound_requires_cluster_scale', 42949672.95);
SELECT id, marker, amount FROM tab_741_txid_xid_wraparound_epoch_increment ORDER BY id;
SELECT 'xid low 32 bits wrap after 2^32 assignments; xid8/epoch is required for full logical order' AS wraparound_design_note;
