-- ============================================================
-- Phase 17 migration — persistent crew-email draft
-- One row, so a half-written note survives a closed tab and can
-- be picked up on another device (or seeded ready for editing).
-- ============================================================

create table if not exists email_draft (
  id         int primary key default 1 check (id = 1),
  subject    text,
  body       text,
  audience   text default 'crew',
  updated_at timestamptz default now()
);
insert into email_draft (id) values (1) on conflict do nothing;
alter table email_draft enable row level security;
create policy "email_draft admin select" on email_draft for select
  using ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "email_draft admin update" on email_draft for update
  using ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
create policy "email_draft admin insert" on email_draft for insert
  with check ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
