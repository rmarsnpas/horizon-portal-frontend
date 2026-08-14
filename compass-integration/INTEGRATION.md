# Compass Check-In — Integration Guide

This is built to merge into your existing setup: GitHub repo, static frontend on Vercel,
Node backend on Railway. No new services to stand up.

## 1. Database (Railway Postgres)

If you don't already have Postgres attached to your Railway backend, add the Postgres plugin
in your Railway project — it sets a `DATABASE_URL` environment variable automatically.

Run `schema.sql` against it once:

```bash
psql $DATABASE_URL -f schema.sql
```

(or paste it into Railway's query console). This creates three new tables —
`checkin_members`, `checkin_schedules`, `checkins` — namespaced so they won't collide with
anything you already have.

## 2. Backend (your Railway Node app)

Copy the `backend-routes/` folder into your backend repo. Then, wherever you set up routes:

```js
const pool = require('./db'); // your existing pg Pool — reuse it, don't create a second one

app.use('/api/checkin/auth', require('./backend-routes/checkinAuth')(pool));
app.use('/api/checkin', require('./backend-routes/checkin')(pool));

// Staff-only routes — protect with whatever middleware already guards your staff dashboard's
// API calls (session check, JWT, whatever you use today):
app.use('/api/checkin/admin', requireStaffAuth, require('./backend-routes/checkinAdmin')(pool));
```

Install the two new dependencies if you don't already have them:

```bash
npm install bcryptjs jsonwebtoken express-rate-limit
```

Add one new environment variable in Railway: `CHECKIN_JWT_SECRET` — a long random string,
separate from any secret your staff login already uses. Generate one with:

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

`backend-routes/db.js` is only there in case you don't already have a `pg` Pool set up —
if you do, ignore that file and pass your existing pool into the route factories instead.

## 3. Frontend (your Vercel static repo)

Copy the two files from `frontend-pages/` into your portal repo:

- `checkin.html` → member-facing, e.g. serve at `/checkin`
- `staff-checkin.html` → add as a page/section in your staff dashboard, e.g. `/staff/checkin`

Both already point at your Railway backend URL
(`https://horizon-portal-backend-production-3532.up.railway.app`) — update that constant at
the top of each `<script>` block if your backend URL changes.

**One thing to fix in `staff-checkin.html` before shipping it**: it currently calls the backend
with `credentials: 'include'` (cookie-based auth) as a placeholder. Update the `staffFetch`
function to match however your dashboard actually authenticates its API calls today — copy
whatever pattern your other staff dashboard pages already use for calling the Railway backend.

Add links to `/checkin` and `/staff/checkin` from your existing portal/dashboard navigation.

## 4. Try it end to end

1. In the staff page, add a check-in window (e.g. "Morning," 08:00, all days).
2. Add a test member with a member ID and PIN.
3. Open `/checkin` on a phone (or desktop with location permission), log in, and check in.
4. Confirm it shows up in the staff "Today" and "Full History" views with a working map link.

## Trip tracking (added)

A member-initiated, session-based location feature: a member taps "Start trip tracking,"
their location is sent every ~30 seconds while the page stays open, and they can tap "Stop"
at any time — there's no server-side way to force a trip to keep running once they stop it
or close the app. Staff can see a list of trips per member and click one to see the route
drawn on a map (using Leaflet, loaded via CDN — no build step, fits your static setup).

**Before turning this on with real members:**

- **Get written consent first.** A tap of "Start tracking" is consent for that session, but
  you should also have members sign something at intake (or before this feature is enabled
  for them) acknowledging that trip tracking exists, what it captures, and that it's their
  choice to use it each time. This is what actually protects you and the member — verbal or
  assumed consent isn't a substitute for something in writing that outlines the scope.
- **This is not covert or continuous tracking**, and it shouldn't become that. It only runs
  during an active, visible session the member started, and it stops working (not just
  "should stop" — actually stops sending data) within seconds of the browser tab losing
  focus or the phone locking, especially on iOS. If you need tracking that survives a locked
  screen, that's a different, much bigger project (a native app with background location
  permission, its own App Store/Play Store privacy review, etc.) — worth a separate
  conversation if you actually need that.
- **New env var**: none needed beyond what you already have — trip routes reuse the same
  `CHECKIN_JWT_SECRET` and `pool` as the check-in routes.

Mount the two new route files alongside the existing ones:

```js
app.use('/api/checkin/trip', require('./backend-routes/trip')(pool));
app.use('/api/checkin/admin/trips', requireStaffAuth, require('./backend-routes/tripAdmin')(pool));
```

Re-run `schema.sql` (or just the new `trips`/`trip_points` section) against your Railway
Postgres to add the two new tables.

## Notes carried over from the original build

- Location is captured only at the moment of check-in, not continuously.
- A window counts as `on_time` within its grace period, `late` after, and a check-in with no
  open window is logged as `unscheduled` rather than rejected.
- Before real members use this: HTTPS is already covered by Vercel/Railway, but double check
  data retention (the `checkins` table grows indefinitely — add a cleanup job if needed) and
  who has staff access to location history. Recovery-program membership + location data can
  touch 42 CFR Part 2 and state privacy rules in the US — worth a quick compliance check.
- To sync `checkin_members` from your real member database instead of adding people by hand
  in the staff page, write a small script that upserts into `checkin_members` on a schedule,
  matching on `member_id`. Don't copy PINs over — issue fresh ones through
  `POST /api/checkin/admin/members` instead.
