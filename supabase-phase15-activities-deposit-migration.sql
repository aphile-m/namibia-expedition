-- ============================================================
-- Phase 15 migration — optional activities per stop, and a
-- deposit that tracks the accommodation total unless overridden.
-- (applied via connector; activities seeded with it)
-- ============================================================

create table if not exists stop_activities (
  id              uuid primary key default gen_random_uuid(),
  booking_id      uuid not null references site_bookings(id) on delete cascade,
  name            text not null,
  blurb           text,
  cost_per_person numeric,
  duration        text,
  website         text,
  sort_order      int default 0,
  created_at      timestamptz default now()
);
alter table stop_activities enable row level security;
create policy "stop_activities select" on stop_activities for select using (true);
create policy "stop_activities admin insert" on stop_activities for insert
  with check ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "stop_activities admin update" on stop_activities for update
  using ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "stop_activities admin delete" on stop_activities for delete
  using ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');

alter table trip_settings add column if not exists deposit_auto boolean not null default true;

create or replace view public_activities as
  select a.id, b.day_label, b.nights, a.name, a.blurb, a.cost_per_person, a.duration, a.website, a.sort_order
    from stop_activities a join site_bookings b on b.id = a.booking_id;
grant select on public_activities to anon, authenticated;
