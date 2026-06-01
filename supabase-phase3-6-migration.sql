-- ============================================================
-- Phase 3 + 6 migration — crew roster + costs & payments
-- Run in Supabase SQL Editor (Vinyl Database)
-- ============================================================

-- 1. trip_settings (single-row: deposit amount + deadline)
create table if not exists trip_settings (
  id                  int primary key default 1 check (id = 1),
  deposit_amount      numeric,
  collection_deadline date,
  route_locked        text check (route_locked in ('route1','route2')),
  updated_at          timestamptz default now()
);
insert into trip_settings (id) values (1) on conflict do nothing;
alter table trip_settings enable row level security;
create policy "trip_settings select" on trip_settings for select using (true);
create policy "trip_settings update" on trip_settings for update
  using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- 2. payment_account (single-row: banking details)
create table if not exists payment_account (
  id               int primary key default 1 check (id = 1),
  bank             text,
  account_name     text,
  account_number   text,
  branch_code      text,
  reference_format text default 'NAMIBIA-{NAME}',
  updated_at       timestamptz default now()
);
insert into payment_account (id) values (1) on conflict do nothing;
alter table payment_account enable row level security;
create policy "payment_account select" on payment_account for select
  using (auth.uid() is not null);
create policy "payment_account update" on payment_account for update
  using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- 3. payments (per-person deposit tracking)
create table if not exists payments (
  crew_id    uuid primary key references crew(id) on delete cascade,
  amount_due numeric not null default 2310,
  status     text    not null default 'unpaid' check (status in ('unpaid','claimed','verified')),
  reference  text,
  paid_at    timestamptz,
  verified_at timestamptz,
  created_at timestamptz default now()
);
alter table payments enable row level security;
-- Any registered member can read all statuses
create policy "payments select"        on payments for select
  using (auth.uid() is not null);
-- Member can insert their own row
create policy "payments insert"        on payments for insert
  with check (auth.uid() = crew_id);
-- Member can update their own unpaid row to claimed
create policy "payments member update" on payments for update
  using  (auth.uid() = crew_id and status = 'unpaid')
  with check (auth.uid() = crew_id and status = 'claimed');
-- Admin can update any row (to verify)
create policy "payments admin update"  on payments for update
  using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
-- Admin can delete
create policy "payments delete"        on payments for delete
  using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- Enable realtime
alter publication supabase_realtime add table payments;
