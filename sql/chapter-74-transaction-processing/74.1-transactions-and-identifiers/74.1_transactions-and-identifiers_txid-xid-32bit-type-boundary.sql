--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : 内部 xid 是 32 位类型，测试设计需覆盖接近 32 位上界的显示、比较或转换边界。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-xid-32bit-type-boundary.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V13,F02-V05,F03-V04,F04-V04
-- combination_strategy: boundary-directed
-- case_id: TXID-XID-32BIT-TYPE-BOUNDARY
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. xid 类型可转换为文本并体现 32 位标识空间
DROP TABLE IF EXISTS tab_741_txid_xid_32bit_type_boundary;
CREATE TABLE tab_741_txid_xid_32bit_type_boundary (
    id int PRIMARY KEY,
    marker text NOT NULL,
    amount numeric(8,2) DEFAULT 0,
    created_on date DEFAULT DATE '2026-05-20'
);
BEGIN;
INSERT INTO tab_741_txid_xid_32bit_type_boundary(id, marker) VALUES (1, 'xid_boundary_probe');
SELECT pg_current_xact_id_if_assigned() IS NOT NULL AS xid_assigned;
SELECT pg_typeof(pg_current_xact_id_if_assigned()::xid8) AS xid8_type;
COMMIT;
SELECT * FROM tab_741_txid_xid_32bit_type_boundary ORDER BY id;
