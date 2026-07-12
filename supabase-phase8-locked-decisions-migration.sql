-- ============================================================
-- Phase 8 migration — locked trip decisions
-- The decided departure date lives in trip_settings (publicly
-- readable) so day dates render for everyone; decision records
-- themselves stay crew-only (no policy changes).
-- ============================================================

alter table trip_settings add column if not exists departure_date date;
