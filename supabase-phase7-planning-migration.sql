-- ============================================================
-- Phase 7 migration — Trip Planning HQ (admin organiser module)
-- Run in Supabase SQL Editor (Vinyl Database)
-- ============================================================

-- 1. decisions — calls made offline (WhatsApp, phone, in person).
--    poll_key optionally links a decision to one of the voting rulings.
create table if not exists decisions (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  outcome    text not null,
  decided_on date,
  context    text,   -- where/how it was made (e.g. WhatsApp group)
  poll_key   text,   -- matches POLLS keys in the app (departure_date, shark, driving, coast)
  created_at timestamptz default now()
);
alter table decisions enable row level security;
create policy "decisions select"       on decisions for select using (auth.uid() is not null);
create policy "decisions admin insert" on decisions for insert with check ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "decisions admin update" on decisions for update using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "decisions admin delete" on decisions for delete using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- 2. invites — admin pre-registers crew by email before they've signed in.
--    display_name/role pre-fill the onboarding modal when that email signs in,
--    and unclaimed invites count toward the planning headcount.
create table if not exists invites (
  email        text primary key,
  display_name text,
  role         text check (role in ('driver','passenger')),
  created_at   timestamptz default now()
);
alter table invites enable row level security;
create policy "invites select"       on invites for select using (auth.uid() is not null);
create policy "invites admin insert" on invites for insert with check ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "invites admin update" on invites for update using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "invites admin delete" on invites for delete using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- 3. site_bookings — campsite availability -> booking pipeline, one row per stay.
create table if not exists site_bookings (
  id              uuid primary key default gen_random_uuid(),
  day_label       text,
  site_name       text not null,
  nights          int  not null default 1,
  status          text not null default 'not_queried'
                  check (status in ('not_queried','enquiry_sent','available','unavailable','booked','paid')),
  cost_per_camper numeric,   -- verified rate per camper per night
  contact         text,      -- reservations contact / booking reference
  notes           text,
  sort_order      int default 0,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);
alter table site_bookings enable row level security;
create policy "site_bookings select"       on site_bookings for select using (auth.uid() is not null);
create policy "site_bookings admin insert" on site_bookings for insert with check ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "site_bookings admin update" on site_bookings for update using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "site_bookings admin delete" on site_bookings for delete using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- 4. cost_items — any cost verifiable before departure
--    (park & conservation fees, cross-border charges, fuel per vehicle, food kitty…).
create table if not exists cost_items (
  id         uuid primary key default gen_random_uuid(),
  label      text    not null,
  amount     numeric not null default 0,
  basis      text    not null default 'per_camper' check (basis in ('per_camper','per_vehicle','total')),
  verified   boolean not null default false,
  source     text,   -- who/what confirmed the number
  notes      text,
  created_at timestamptz default now()
);
alter table cost_items enable row level security;
create policy "cost_items select"       on cost_items for select using (auth.uid() is not null);
create policy "cost_items admin insert" on cost_items for insert with check ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "cost_items admin update" on cost_items for update using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "cost_items admin delete" on cost_items for delete using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- 5. admin may update any crew row (assign roles from Planning HQ)
create policy "crew admin update" on crew for update
  using ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
