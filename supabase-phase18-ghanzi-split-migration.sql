-- ============================================================
-- Phase 18 — split the Trans-Kalahari crush at Ghanzi
--
-- Day 7 was Gobabis → Gaborone in one go. Measured against real
-- segment distances that leg is ~1,000 km, not the 882 the site
-- claimed, so it broke the eight-hour driving rule by a wide
-- margin. Splitting it at Ghanzi makes the trip nine days:
--
--   Day 7  Gobabis → Ghanzi     315 km  ~3.5 hrs
--   Day 8  Ghanzi  → Gaborone   680 km  ~8 hrs
--   Day 9  Gaborone → Joburg    350 km  ~4.5 hrs
--
-- Ghanzi and Kang are the only two places on that road with fuel,
-- food and beds. Ghanzi is the earlier stop, which front-loads the
-- rest and buys the one cultural afternoon on the itinerary.
--
-- Data only — no schema change. Applied via the connector.
-- ============================================================

-- Gaborone moves back a day
update site_bookings
   set day_label = 'Day 8', sort_order = 8
 where day_label = 'Day 7' and site_name like 'Gaborone%';

-- the new overnight. Contact and rate deliberately null: they are
-- unverified, and the booking table reads a blank as "still to do"
-- rather than showing a number nobody has confirmed.
insert into site_bookings
  (day_label, site_name, nights, status, cost_per_camper, contact, phone, website, notes, sort_order)
values
  ('Day 7', 'Thakadu Bush Camp, Ghanzi', 1, 'not_queried', 250,
   null, null,
   'https://www.google.com/search?q=Thakadu+Bush+Camp+Ghanzi+Botswana+camping',
   'Contact + rate still to be confirmed — 12 km east of Ghanzi on the A3. Check in early enough for an afternoon San tracking walk.',
   7);

with b as (select id from site_bookings where day_label = 'Day 7' and site_name like 'Thakadu%')
insert into site_alternatives
  (booking_id, name, blurb, km_from_site, km_from_prior, cost_per_camper, website, sort_order)
select b.id, v.name, v.blurb, v.kms, v.kmp, v.cost, v.web, v.so
from b, (values
  ('Ghanzi Trailblazers',
   'San-guided tracking walks and dance, 4 km outside town. The strongest reason to be in Ghanzi at all.',
   8, 319, 200,
   'https://www.google.com/search?q=Ghanzi+Trailblazers+camping+Botswana', 1),
  ('Dqae Qare San Lodge',
   'Community-owned San lodge on a 7,500 ha reserve, 35 km southwest on gravel. Best experience, small detour after a driving day.',
   45, 350, 200,
   'https://www.google.com/search?q=Dqae+Qare+San+Lodge+Ghanzi', 2),
  ('Kalahari Arms Hotel',
   'In town, rooms and camping, walkable to fuel and shops. Functional rather than scenic.',
   12, 315, 170,
   'https://www.google.com/search?q=Kalahari+Arms+Hotel+Ghanzi+camping', 3)
) as v(name, blurb, kms, kmp, cost, web, so);

with b as (select id from site_bookings where day_label = 'Day 7' and site_name like 'Thakadu%')
insert into stop_activities (booking_id, name, blurb, cost_per_person, duration, website, sort_order)
select b.id, v.name, v.blurb, v.cost, v.dur, v.web, v.so
from b, (values
  ('San tracking walk',
   'Guided bush walk with San trackers — plant use, snares, fire-making. The one cultural stop on the route.',
   250, '2-3 hrs', 'https://www.google.com/search?q=Ghanzi+San+bushman+guided+walk', 1),
  ('Traditional dance evening',
   'After-dark dance around the fire at the camps outside town. Usually needs booking on arrival.',
   150, 'evening', 'https://www.google.com/search?q=Ghanzi+San+traditional+dance', 2),
  ('Ghanzi town resupply',
   'Choppies and the fuel stations — last proper shops before the 300 km empty run to Kang.',
   0, '1 hr', null, 3)
) as v(name, blurb, cost, dur, web, so);
