-- ============================================================
-- Phase 2 migration — crew auth + re-keyed votes
-- Run this in the Vinyl Database SQL Editor
-- ============================================================

-- 1. crew table (one row per registered expedition member)
create table if not exists crew (
  id                uuid primary key references auth.users(id) on delete cascade,
  email             text not null unique,
  display_name      text not null,
  role              text not null check (role in ('driver','passenger')),
  awaiting_driver   boolean not null default false,
  comms_opt_out     boolean not null default false,
  unsubscribe_token text not null default gen_random_uuid()::text,
  created_at        timestamptz default now()
);
alter table crew enable row level security;

-- All authenticated members see the roster (emails filtered client-side for non-admins)
create policy "crew select"  on crew for select  using (auth.uid() is not null);
-- Members can only insert/update their own row
create policy "crew insert"  on crew for insert  with check (auth.uid() = id);
create policy "crew update"  on crew for update  using  (auth.uid() = id);
-- Admin only: remove a crew member
create policy "crew delete"  on crew for delete  using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- Enable realtime for crew
alter publication supabase_realtime add table crew;

-- 2. Rebuild votes table keyed on crew_id (drop old voter_key schema)
--    Safe to drop because the site is new and has no real votes yet.
drop table if exists votes;

create table votes (
  poll        text not null,
  crew_id     uuid not null references crew(id) on delete cascade,
  voter_name  text not null,   -- denormalized display_name for fast reads
  choice      text not null,
  updated_at  timestamptz default now(),
  primary key (poll, crew_id)
);
alter table votes enable row level security;

-- All authenticated members can read the tally
create policy "votes select" on votes for select using (auth.uid() is not null);
-- Members can only upsert their own vote
create policy "votes insert" on votes for insert with check (auth.uid() = crew_id);
create policy "votes update" on votes for update using  (auth.uid() = crew_id);
-- Admin only: reset the tally
create policy "votes delete" on votes for delete using  ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');

-- Re-enable realtime (dropped with the old table)
alter publication supabase_realtime add table votes;
