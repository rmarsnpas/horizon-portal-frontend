-- Compass Check-In — Postgres schema
-- Run this against your Railway Postgres database (via `psql $DATABASE_URL -f schema.sql`
-- or Railway's built-in query console).
--
-- If you already have a `members` table in your portal database, skip creating a new one —
-- just make sure it has a unique text ID column and a pin_hash column, and adjust the
-- column names referenced in backend-routes/*.js to match.

CREATE TABLE IF NOT EXISTS checkin_members (
  id SERIAL PRIMARY KEY,
  member_id TEXT UNIQUE NOT NULL,      -- should match the ID used in your existing member database
  name TEXT NOT NULL,
  house TEXT,
  phone TEXT,
  pin_hash TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- A recurring check-in window, e.g. "Morning" at 08:00, Mon-Sun, 15 min grace.
CREATE TABLE IF NOT EXISTS checkin_schedules (
  id SERIAL PRIMARY KEY,
  label TEXT NOT NULL,
  time TEXT NOT NULL,                  -- "HH:MM" 24hr, local house time
  days TEXT NOT NULL,                  -- comma separated: "mon,tue,wed,thu,fri,sat,sun"
  grace_minutes INTEGER NOT NULL DEFAULT 15,
  house TEXT,                          -- optional: restrict to one house, null = all houses
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS checkins (
  id SERIAL PRIMARY KEY,
  member_id TEXT NOT NULL REFERENCES checkin_members(member_id),
  schedule_id INTEGER REFERENCES checkin_schedules(id),
  checked_in_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  scheduled_for TIMESTAMPTZ,
  status TEXT NOT NULL,                -- 'on_time' | 'late' | 'unscheduled'
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  accuracy_meters DOUBLE PRECISION,
  note TEXT
);

CREATE INDEX IF NOT EXISTS idx_checkins_member ON checkins(member_id);
CREATE INDEX IF NOT EXISTS idx_checkins_time ON checkins(checked_in_at);

-- ---------- Trip tracking (session-based, member-initiated, opt-out anytime) ----------
-- A trip is only ever running because the member started it (or approved a staff request)
-- and stopped it themselves, or it timed out. There is no always-on tracking here.
CREATE TABLE IF NOT EXISTS trips (
  id SERIAL PRIMARY KEY,
  member_id TEXT NOT NULL REFERENCES checkin_members(member_id),
  status TEXT NOT NULL DEFAULT 'active',   -- 'active' | 'completed' | 'cancelled'
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at TIMESTAMPTZ,
  label TEXT                                -- optional, e.g. "Doctor appointment"
);

CREATE TABLE IF NOT EXISTS trip_points (
  id SERIAL PRIMARY KEY,
  trip_id INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  accuracy_meters DOUBLE PRECISION
);

CREATE INDEX IF NOT EXISTS idx_trip_points_trip ON trip_points(trip_id);
CREATE INDEX IF NOT EXISTS idx_trips_member ON trips(member_id);

-- Safety net: auto-expire trips nobody explicitly stopped (e.g. app was killed).
-- Run this periodically (cron, or a scheduled Railway job) rather than relying on
-- the client alone to close out stale sessions:
--   UPDATE trips SET status = 'cancelled', ended_at = now()
--   WHERE status = 'active' AND started_at < now() - interval '6 hours';
