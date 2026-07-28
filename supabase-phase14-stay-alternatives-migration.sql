-- ============================================================
-- Phase 14 migration — fallback alternatives per stay
-- plus a public projection of the stays so the day cards
-- follow whatever camp is currently locked in.
-- (applied via connector; alternatives seeded with it)
-- ============================================================

create table if not exists site_alternatives (
  id              uuid primary key default gen_random_uuid(),
  booking_id      uuid not null references site_bookings(id) on delete cascade,
  name            text not null,
  blurb           text,
  km_from_site    numeric,   -- detour from the planned camp
  km_from_prior   numeric,   -- driving distance from the previous night's stop
  cost_per_camper numeric,
  contact         text,
  phone           text,
  website         text,
  sort_order      int default 0,
  created_at      timestamptz default now()
);
alter table site_alternatives enable row level security;
create policy "site_alternatives select" on site_alternatives for select
  using (exists (select 1 from crew c where c.id = auth.uid() and c.role <> 'viewer'));
create policy "site_alternatives admin insert" on site_alternatives for insert
  with check ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "site_alternatives admin update" on site_alternatives for update
  using ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "site_alternatives admin delete" on site_alternatives for delete
  using ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- Public projection: name/nights only — rates and contacts stay crew-only.
create or replace view public_stays as
  select day_label, site_name, nights, sort_order from site_bookings;
grant select on public_stays to anon, authenticated;
