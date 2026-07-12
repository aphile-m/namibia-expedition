# Backlog

Feature ideas agreed for a future phase. Ship one per phase, with its own
`supabase-phaseN-*.sql` migration when schema is needed.

## 1. Campsite photos — Planning HQ upload + front-end gallery

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
