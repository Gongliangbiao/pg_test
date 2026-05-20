--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : 只读事务也具有唯一 VirtualTransactionId。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-vxid-assigned-for-readonly.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V05,F02-V03,F03-V03,F04-V01
-- combination_strategy: single-factor
-- case_id: TXID-VXID-ASSIGNED-FOR-READONLY
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. 只读事务也具有 virtual transaction id
BEGIN READ ONLY;
SELECT pg_current_xact_id_if_assigned() IS NULL AS no_nonvirtual_xid;
SELECT virtualtransaction IS NOT NULL AS has_virtualxid
FROM pg_locks
WHERE pid = pg_backend_pid() AND locktype = 'virtualxid'
ORDER BY virtualtransaction
LIMIT 1;
COMMIT;
