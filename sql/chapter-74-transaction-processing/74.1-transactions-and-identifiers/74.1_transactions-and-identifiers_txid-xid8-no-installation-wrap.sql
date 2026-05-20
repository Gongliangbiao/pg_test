--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : xid8 包含 epoch，在单个 installation 生命周期内不发生 xid 式 wraparound。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-xid8-no-installation-wrap.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V15,F02-V07,F03-V04,F04-V04
-- combination_strategy: boundary-directed
-- case_id: TXID-XID8-NO-INSTALLATION-WRAP
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. xid8 作为带 epoch 的完整事务 ID 观测
DROP TABLE IF EXISTS tab_741_txid_xid8_no_installation_wrap;
CREATE TABLE tab_741_txid_xid8_no_installation_wrap (
    id int PRIMARY KEY,
    marker text NOT NULL,
    amount numeric(8,2) DEFAULT 0,
    created_on date DEFAULT DATE '2026-05-20'
);
BEGIN;
INSERT INTO tab_741_txid_xid8_no_installation_wrap(id, marker) VALUES (1, 'xid8_probe');
SELECT pg_current_xact_id() IS NOT NULL AS xid8_available;
SELECT pg_typeof(pg_current_xact_id()) AS xid8_type;
COMMIT;
SELECT * FROM tab_741_txid_xid8_no_installation_wrap ORDER BY id;
