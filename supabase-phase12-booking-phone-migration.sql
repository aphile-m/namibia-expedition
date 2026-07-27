-- ============================================================
-- Phase 12 migration — dedicated phone column on stays
-- (applied via connector; existing rows updated to split the
--  phone number out of the mixed contact field)
-- ============================================================

alter table site_bookings add column if not exists phone text;
