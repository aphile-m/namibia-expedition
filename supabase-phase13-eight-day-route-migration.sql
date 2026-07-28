-- ============================================================
-- Phase 13 migration — 8-day route revision
-- Two-night anchors at Fish River Canyon and Sesriem; Lüderitz
-- dropped. Check-ins and trip photos now span days 1..8.
-- (applied via connector; booking rows restructured with it)
-- ============================================================

alter table check_ins   drop constraint check_ins_day_check;
alter table check_ins   add  constraint check_ins_day_check   check (day between 1 and 8);
alter table trip_photos drop constraint trip_photos_day_check;
alter table trip_photos add  constraint trip_photos_day_check check (day between 1 and 8);
