--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : prepared transaction 除 vxid、xid 外，还具有 GID。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-gid-assigned-for-prepared.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V19,F02-V09,F03-V04,F04-V01
-- combination_strategy: state-transition
-- case_id: TXID-GID-ASSIGNED-FOR-PREPARED
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. prepared transaction 需要 max_prepared_transactions > 0
DROP TABLE IF EXISTS tab_741_txid_gid_assigned_for_prepared;
CREATE TABLE tab_741_txid_gid_assigned_for_prepared (
    id int PRIMARY KEY,
    marker text NOT NULL,
    amount numeric(8,2) DEFAULT 0,
    created_on date DEFAULT DATE '2026-05-20'
);
SELECT current_setting('max_prepared_transactions')::int > 0 AS prepared_transaction_available \gset
\if :prepared_transaction_available
BEGIN;
INSERT INTO tab_741_txid_gid_assigned_for_prepared(id, marker) VALUES (1, 'prepared_probe');
PREPARE TRANSACTION 'txid_gid_assigned_for_prepared_gid';
SELECT gid, database, owner IS NOT NULL AS has_owner
FROM pg_prepared_xacts
WHERE gid = 'txid_gid_assigned_for_prepared_gid'
ORDER BY gid;
COMMIT PREPARED 'txid_gid_assigned_for_prepared_gid';
SELECT * FROM tab_741_txid_gid_assigned_for_prepared ORDER BY id;
\else
SELECT 'max_prepared_transactions is 0; prepared transaction SQL path skipped' AS prepared_transaction_note;
\endif
