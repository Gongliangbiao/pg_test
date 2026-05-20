--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : pg_prepared_xacts 可查看 GID 到 xid 的映射关系。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-gid-mapped-in-pg-prepared-xacts.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V20,F02-V10,F03-V04,F04-V01
-- combination_strategy: state-transition
-- case_id: TXID-GID-MAPPED-IN-PG-PREPARED-XACTS
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. prepared transaction 需要 max_prepared_transactions > 0
DROP TABLE IF EXISTS tab_741_txid_gid_mapped_in_pg_prepared_xacts;
CREATE TABLE tab_741_txid_gid_mapped_in_pg_prepared_xacts (
    id int PRIMARY KEY,
    marker text NOT NULL,
    amount numeric(8,2) DEFAULT 0,
    created_on date DEFAULT DATE '2026-05-20'
);
SELECT current_setting('max_prepared_transactions')::int > 0 AS prepared_transaction_available \gset
\if :prepared_transaction_available
BEGIN;
INSERT INTO tab_741_txid_gid_mapped_in_pg_prepared_xacts(id, marker) VALUES (1, 'prepared_probe');
PREPARE TRANSACTION 'txid_gid_mapped_in_pg_prepared_xacts_gid';
SELECT gid, database, owner IS NOT NULL AS has_owner
FROM pg_prepared_xacts
WHERE gid = 'txid_gid_mapped_in_pg_prepared_xacts_gid'
ORDER BY gid;
COMMIT PREPARED 'txid_gid_mapped_in_pg_prepared_xacts_gid';
SELECT * FROM tab_741_txid_gid_mapped_in_pg_prepared_xacts ORDER BY id;
\else
SELECT 'max_prepared_transactions is 0; prepared transaction SQL path skipped' AS prepared_transaction_note;
\endif
