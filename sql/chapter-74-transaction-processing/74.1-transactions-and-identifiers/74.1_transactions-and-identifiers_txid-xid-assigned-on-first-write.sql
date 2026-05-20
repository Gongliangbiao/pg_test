--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : 事务第一次写数据库时才分配非虚拟 xid。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-xid-assigned-on-first-write.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V09,F02-V05,F03-V04,F04-V01
-- combination_strategy: single-factor
-- case_id: TXID-XID-ASSIGNED-ON-FIRST-WRITE
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. 首次写入普通表后分配非虚拟 xid
DROP TABLE IF EXISTS tab_741_txid_xid_assigned_on_first_write;
CREATE TABLE tab_741_txid_xid_assigned_on_first_write (
    id int PRIMARY KEY,
    marker text NOT NULL,
    amount numeric(8,2) DEFAULT 0,
    created_on date DEFAULT DATE '2026-05-20'
);
BEGIN;
SELECT pg_current_xact_id_if_assigned() IS NULL AS no_xid_after_begin;
SELECT count(*) AS row_count FROM tab_741_txid_xid_assigned_on_first_write;
SELECT pg_current_xact_id_if_assigned() IS NULL AS no_xid_after_read;
INSERT INTO tab_741_txid_xid_assigned_on_first_write(id, marker, amount) VALUES (1, 'first_write', 10.50);
SELECT pg_current_xact_id_if_assigned() IS NOT NULL AS xid_assigned_after_first_write;
SELECT * FROM tab_741_txid_xid_assigned_on_first_write ORDER BY id;
COMMIT;
SELECT * FROM tab_741_txid_xid_assigned_on_first_write ORDER BY id;
