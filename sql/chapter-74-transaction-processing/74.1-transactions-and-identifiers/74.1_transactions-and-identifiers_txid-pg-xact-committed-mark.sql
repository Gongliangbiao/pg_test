--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : 带非虚拟 xid 的顶层事务提交后，在 pg_xact 中记录 committed 状态。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-pg-xact-committed-mark.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V17,F02-V08,F03-V01,F04-V01
-- combination_strategy: state-transition
-- case_id: TXID-PG-XACT-COMMITTED-MARK
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. 提交事务后用 pg_xact_status 观测 committed 状态
DROP TABLE IF EXISTS tab_741_txid_pg_xact_committed_mark;
CREATE TABLE tab_741_txid_pg_xact_committed_mark (
    id int PRIMARY KEY,
    marker text NOT NULL,
    amount numeric(8,2) DEFAULT 0,
    created_on date DEFAULT DATE '2026-05-20'
);
BEGIN;
INSERT INTO tab_741_txid_pg_xact_committed_mark(id, marker) VALUES (1, 'commit_status_probe');
SELECT pg_current_xact_id()::text AS captured_xid_text \gset
COMMIT;
SELECT pg_xact_status(:'captured_xid_text'::xid8) AS committed_status;
SELECT * FROM tab_741_txid_pg_xact_committed_mark ORDER BY id;
