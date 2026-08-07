-- ============================================================
-- Phase 16 migration — crew comms
-- Wires up the comms_opt_out / unsubscribe_token columns that
-- have been on `crew` since phase 2 but were never used.
-- Sending lives in the `send-crew-email` Edge Function so the
-- mail API key never reaches the browser; `unsubscribe` is a
-- public function because it is linked from every email.
-- ============================================================

create table if not exists email_log (
  id          uuid primary key default gen_random_uuid(),
  subject     text not null,
  body        text not null,
  audience    text not null default 'crew' check (audience in ('crew','viewers','all')),
  sent_by     uuid references crew(id) on delete set null,
  recipients  int  not null default 0,
  failed      int  not null default 0,
  detail      jsonb,
  created_at  timestamptz default now()
);
alter table email_log enable row level security;
create policy "email_log admin select" on email_log for select
  using ((auth.jwt() ->> 'email') = 'aphilem@gmail.com');
-- writes come from the Edge Function via the service role, which bypasses RLS

update crew set unsubscribe_token = gen_random_uuid()::text
 where unsubscribe_token is null or unsubscribe_token = '';

create index if not exists crew_unsub_token_idx on crew (unsubscribe_token);

-- Activation (once off, outside SQL):
--   1. Create a Resend account and an API key.
--   2. Supabase → Edge Functions → Secrets:
--        RESEND_API_KEY = re_...
--        RESEND_FROM    = Namibia Expedition <trip@yourdomain.com>   (optional)
--      Without a verified domain, Resend only delivers to the account owner,
--      which is enough for the "Send me a test" button.
