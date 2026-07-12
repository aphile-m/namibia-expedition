-- ============================================================
-- Phase 10 migration — verification websites on cost items
-- (URLs for the seeded items were set via the connector: RFA
--  cross-border charges, NWR/MEFT park fees, BURS border levies,
--  fuel price tracker)
-- ============================================================

alter table cost_items add column if not exists website text;
