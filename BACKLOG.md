# Backlog

Feature ideas agreed for a future phase. Ship one per phase, with its own
`supabase-phaseN-*.sql` migration when schema is needed.

## 1. Campsite photos — Planning HQ upload + front-end gallery

> **Partially shipped:** the day cards now have swipeable multi-photo
> galleries (destination + campsite shots curated from Wikimedia
> Commons, touch swipe / arrows / dots). Still open from this item:
> admin-uploaded photos via Supabase Storage and the `site_photos`
> table, and a full-screen lightbox.

**Goal:** the admin attaches real photos to each stay in Planning HQ, and the
public site elegantly shows each campsite with its related images.

**Admin side (Planning HQ):**
- Supabase Storage bucket `site-photos` (public read; insert/delete restricted
  to the admin email, same RLS pattern as the phase 7 tables).
- New `site_photos` table: `id`, `booking_id → site_bookings(id) on delete cascade`,
  `storage_path`, `caption`, `sort_order`, `created_at`. Select for authenticated,
  writes admin-only.
- In the Campsite Availability table, a photo cell per stay: thumbnail strip of
  existing photos + an upload button (`<input type=file accept=image/*>` →
  `SB.storage.from('site-photos').upload(...)`), with per-photo delete and
  caption edit. Client-side downscale to ~1600px before upload to keep the
  bucket lean.

**Front-end display:**
- Day cards (`#dayCards`): when a stay in `site_bookings` matches the day's
  `stay` name and has photos, replace/augment the single hero image with a
  small gallery — the first photo as the scene image, remaining photos as a
  thumbnail film-strip under the stay line; tapping opens a full-screen
  lightbox (reuse the `#onboardOverlay` overlay pattern) with swipe/arrow
  navigation and captions.
- Decision-point route cards: same treatment for Windpomp 14 / Zelda /
  Phakalane where photos exist.
- Fallback stays exactly as today (Wikimedia photo → SVG scene) when a site
  has no uploaded photos, so nothing breaks before photos are added.
- Matching key: add a nullable `day_id` (e.g. `day2`) column to `site_bookings`
  so the link to a day card is explicit rather than name-matching.

**Acceptance:**
- Admin can add/remove/caption photos per stay from Planning HQ.
- Crew see the photos on the matching day card with a lightbox; page stays
  fast (lazy-loaded, downscaled images) and unchanged for photo-less stays.

## 2. Trip viewer mode + live-trip day tracking (check-ins & photos)

**Goal:** while the convoy is on the road, the site becomes a live trip
tracker. Crew members can invite "viewer" emails (family, friends at home)
who sign in and follow along — dates, progress, and photos from the trip —
without any crew powers (no voting, roster edits, or payments).

**Viewer accounts (built by crew, not admin):**
- Extend `crew.role` with a `viewer` value (or a separate `viewers` table
  keyed on email, mirroring the phase 7 `invites` pattern).
- A "Invite a viewer" control for signed-in crew: enter an email → row in
  `viewer_invites` (`email`, `invited_by → crew(id)`, `created_at`).
  Viewer signs in with the same magic-link flow; onboarding detects the
  invite and creates a viewer profile (name only, no driver/passenger).
- RLS: viewers can select trip content (days, decisions, check-ins, trip
  photos) but cannot insert/update anything except their own profile.
  Existing crew-only surfaces (votes, payments, banking details) must
  exclude viewers — audit each select policy that currently just checks
  `auth.uid() is not null`.

**Live-trip mode (day-aware site):**
- Derived from `trip_settings.departure_date`: `tripDay = today − departure + 1`.
  When `1 ≤ tripDay ≤ 7`, the site opens in live mode: auto-scroll/pin to
  that day's card, "DAY N — LIVE" banner, remaining days collapsed.
- Per-day **check-in button** for crew: writes to `check_ins`
  (`id`, `crew_id`, `day` int, `lat`/`lng` nullable via the browser
  geolocation API, `note`, `created_at`). Day card shows who has checked
  in ("7 of 9 checked in at Sesriem") — doubles as a convoy safety roll-call.
- Trip **progress strip**: map nodes light up as days complete / check-ins land.

**Trip photos with location:**
- Crew upload photos from the day card (Supabase Storage bucket
  `trip-photos`; `trip_photos` table: `id`, `crew_id`, `day`,
  `storage_path`, `caption`, `lat`, `lng`, `place_name`, `taken_at`,
  `created_at`).
- On upload, read EXIF GPS + timestamp client-side (e.g. exifr) — note that
  browsers/apps often strip EXIF, so treat it as best-effort.
- If no EXIF location: prompt with a Google Maps-assisted place search
  (Places Autocomplete; needs a Maps API key with billing — decide budget,
  or fall back to free OSM/Nominatim search if the key is a blocker) and
  offer "use my current location" via the geolocation API as a quick path.
- Photos render on the day card as a film-strip + lightbox (shares the
  gallery/lightbox work from backlog item 1), each tagged with place name
  and uploader; optionally plot photo pins on the route map.

**Dependencies / sequencing:**
- Needs `trip_settings.departure_date` (part of the planned decision-rules
  work) before live mode can compute the trip day.
- Builds on backlog item 1's storage + gallery/lightbox foundation — do
  item 1 first or fold its front-end gallery into this.
- Decide the Google Maps API key question before build.

**Acceptance:**
- A crew member can invite an email; that person signs in and sees dates,
  live progress, and photos but no crew-only controls or data.
- During the trip window the site opens on the current day with a working
  check-in button; check-ins visible to all signed-in users.
- Photo upload attaches a location automatically from EXIF when present,
  otherwise via place search or current location, and photos appear on the
  right day with place labels.
