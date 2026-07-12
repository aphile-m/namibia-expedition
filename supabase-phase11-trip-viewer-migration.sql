-- ============================================================
-- Phase 11 migration — trip viewer mode + live-trip tracking
-- (applied via connector; kept here as the schema record)
-- ============================================================

-- 1. viewer role on crew
alter table crew drop constraint crew_role_check;
alter table crew add constraint crew_role_check check (role in ('driver','passenger','viewer'));

-- 2. viewer_invites — any full crew member can invite a follower email
create table if not exists viewer_invites (
  email      text primary key,
  invited_by uuid references crew(id) on delete set null,
  created_at timestamptz default now()
);
alter table viewer_invites enable row level security;
create policy "viewer_invites select" on viewer_invites for select
  using (exists (select 1 from crew c where c.id = auth.uid() and c.role <> 'viewer')
         or lower(email) = lower(auth.jwt() ->> 'email'));
create policy "viewer_invites insert" on viewer_invites for insert
  with check (exists (select 1 from crew c where c.id = auth.uid() and c.role <> 'viewer'));
create policy "viewer_invites delete" on viewer_invites for delete
  using (invited_by = auth.uid() or (auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- 3. check_ins — one per crew member per trip day (viewers cannot check in)
create table if not exists check_ins (
  crew_id    uuid not null references crew(id) on delete cascade,
  day        int  not null check (day between 1 and 7),
  lat        double precision,
  lng        double precision,
  created_at timestamptz default now(),
  primary key (crew_id, day)
);
alter table check_ins enable row level security;
create policy "check_ins select" on check_ins for select using (auth.uid() is not null);
create policy "check_ins insert" on check_ins for insert
  with check (crew_id = auth.uid()
              and exists (select 1 from crew c where c.id = auth.uid() and c.role <> 'viewer'));
create policy "check_ins update" on check_ins for update using (crew_id = auth.uid());
create policy "check_ins delete" on check_ins for delete
  using (crew_id = auth.uid() or (auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- 4. trip_photos — uploaded from the road, with best-effort location
create table if not exists trip_photos (
  id           uuid primary key default gen_random_uuid(),
  crew_id      uuid not null references crew(id) on delete cascade,
  day          int  not null check (day between 1 and 7),
  storage_path text not null,
  caption      text,
  lat          double precision,
  lng          double precision,
  place_name   text,
  taken_at     timestamptz,
  created_at   timestamptz default now()
);
alter table trip_photos enable row level security;
create policy "trip_photos select" on trip_photos for select using (auth.uid() is not null);
create policy "trip_photos insert" on trip_photos for insert
  with check (crew_id = auth.uid()
              and exists (select 1 from crew c where c.id = auth.uid() and c.role <> 'viewer'));
create policy "trip_photos delete" on trip_photos for delete
  using (crew_id = auth.uid() or (auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- 5. storage bucket for trip photos (public read; crew-only writes)
insert into storage.buckets (id, name, public) values ('trip-photos','trip-photos', true)
  on conflict (id) do nothing;
create policy "trip photos upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'trip-photos'
              and exists (select 1 from crew c where c.id = auth.uid() and c.role <> 'viewer'));
create policy "trip photos delete" on storage.objects for delete to authenticated
  using (bucket_id = 'trip-photos'
         and (owner = auth.uid() or (auth.jwt() ->> 'email') = 'aphilem@gmail.com'));

-- 6. RLS audit: crew-only tables must exclude viewers
drop policy "votes select" on votes;
create policy "votes select" on votes for select
  using (exists (select 1 from crew c where c.id = auth.uid() and c.role <> 'viewer'));
drop policy "payments select" on payments;
create policy "payments select" on payments for select
  using (exists (select 1 from crew c where c.id = auth.uid() and c.role <> 'viewer'));
drop policy "payment_account select" on payment_account;
create policy "payment_account select" on payment_account for select
  using (exists (select 1 from crew c where c.id = auth.uid() and c.role <> 'viewer'));
drop policy "invites select" on invites;
create policy "invites select" on invites for select
  using (exists (select 1 from crew c where c.id = auth.uid() and c.role <> 'viewer'));
drop policy "site_bookings select" on site_bookings;
create policy "site_bookings select" on site_bookings for select
  using (exists (select 1 from crew c where c.id = auth.uid() and c.role <> 'viewer'));
drop policy "cost_items select" on cost_items;
create policy "cost_items select" on cost_items for select
  using (exists (select 1 from crew c where c.id = auth.uid() and c.role <> 'viewer'));

-- 7. realtime for the live surfaces
alter publication supabase_realtime add table check_ins;
alter publication supabase_realtime add table trip_photos;
