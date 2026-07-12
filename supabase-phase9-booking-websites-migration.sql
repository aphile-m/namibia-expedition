-- ============================================================
-- Phase 9 migration — booking websites on stays
-- (contacts, websites and estimate rates were seeded into
--  site_bookings/cost_items via the connector; this is the
--  schema part only)
-- ============================================================

alter table site_bookings add column if not exists website text;
