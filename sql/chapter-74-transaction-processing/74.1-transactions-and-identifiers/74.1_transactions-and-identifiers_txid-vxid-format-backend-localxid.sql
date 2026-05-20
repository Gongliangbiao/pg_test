--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : VirtualTransactionId 由 backendID/localXID 组成，格式可通过 pg_locks.virtualxid 观测。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-vxid-format-backend-localxid.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V06,F02-V04,F03-V04,F04-V03
-- combination_strategy: diagnostic-directed
-- case_id: TXID-VXID-FORMAT-BACKEND-LOCALXID
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. 通过 pg_locks 观测 virtualxid 格式
BEGIN;
SELECT virtualtransaction ~ '^[0-9]+/[0-9]+$' AS virtualxid_has_backend_local_format
FROM pg_locks
WHERE pid = pg_backend_pid() AND locktype = 'virtualxid'
ORDER BY virtualtransaction
LIMIT 1;
COMMIT;
