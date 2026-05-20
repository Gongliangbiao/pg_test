--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : 非虚拟 xid 来自整个 PostgreSQL cluster 的全局计数器，而不是单库局部计数器。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-xid-global-cluster-counter.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V12,F02-V05,F03-V04,F04-V01
-- combination_strategy: single-factor
-- case_id: TXID-XID-GLOBAL-CLUSTER-COUNTER
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. 非虚拟 xid 来自 cluster 级分配器，连续写入后 xid 单调推进
DROP TABLE IF EXISTS tab_741_txid_xid_global_cluster_counter;
CREATE TABLE tab_741_txid_xid_global_cluster_counter (
    id int PRIMARY KEY,
    marker text NOT NULL,
    amount numeric(8,2) DEFAULT 0,
    created_on date DEFAULT DATE '2026-05-20'
);
BEGIN;
INSERT INTO tab_741_txid_xid_global_cluster_counter(id, marker) VALUES (1, 'first_xid');
SELECT pg_current_xact_id_if_assigned() IS NOT NULL AS first_xid_assigned;
COMMIT;
BEGIN;
INSERT INTO tab_741_txid_xid_global_cluster_counter(id, marker) VALUES (2, 'second_xid');
SELECT pg_current_xact_id_if_assigned() IS NOT NULL AS second_xid_assigned;
COMMIT;
SELECT * FROM tab_741_txid_xid_global_cluster_counter ORDER BY id;
