// Trip tracking — member starts a trip, the app pings location periodically while
// it's open and the screen is on, and the member can stop it at any time. There is
// no server-side way to force a trip to keep running once the member stops it or
// closes the app; this is by design.
//
// Mount in your existing backend, e.g.:
//   app.use('/api/checkin/trip', require('./backend-routes/trip')(pool));

const express = require('express');
const { verifyMember } = require('./verifyMember');

// Hard ceiling so a forgotten/abandoned trip can't run forever even if the client
// never calls /stop. Adjust to whatever's reasonable for your longest expected trip.
const MAX_TRIP_HOURS = 6;

module.exports = function (pool) {
  const router = express.Router();

  router.get('/current', verifyMember, async (req, res) => {
    const { rows } = await pool.query(
      `SELECT * FROM trips WHERE member_id = $1 AND status = 'active' ORDER BY started_at DESC LIMIT 1`,
      [req.member.memberId]
    );
    res.json(rows[0] || null);
  });

  router.post('/start', verifyMember, async (req, res) => {
    // Only one active trip per member at a time.
    const { rows: existing } = await pool.query(
      `SELECT id FROM trips WHERE member_id = $1 AND status = 'active'`,
      [req.member.memberId]
    );
    if (existing.length) {
      return res.status(409).json({ error: 'You already have an active trip. Stop it before starting a new one.' });
    }

    const { label } = req.body;
    const { rows } = await pool.query(
      `INSERT INTO trips (member_id, label) VALUES ($1, $2) RETURNING *`,
      [req.member.memberId, label || null]
    );
    res.status(201).json(rows[0]);
  });

  router.post('/:id/ping', verifyMember, async (req, res) => {
    const { latitude, longitude, accuracyMeters } = req.body;
    if (typeof latitude !== 'number' || typeof longitude !== 'number') {
      return res.status(400).json({ error: 'latitude and longitude are required.' });
    }

    const { rows } = await pool.query(
      `SELECT * FROM trips WHERE id = $1 AND member_id = $2 AND status = 'active'`,
      [req.params.id, req.member.memberId]
    );
    const trip = rows[0];
    if (!trip) return res.status(404).json({ error: 'No active trip with that ID.' });

    const ageHours = (Date.now() - new Date(trip.started_at)) / 3600000;
    if (ageHours > MAX_TRIP_HOURS) {
      await pool.query(`UPDATE trips SET status = 'cancelled', ended_at = now() WHERE id = $1`, [trip.id]);
      return res.status(410).json({ error: 'This trip auto-expired. Start a new one if you\'re still traveling.' });
    }

    await pool.query(
      `INSERT INTO trip_points (trip_id, latitude, longitude, accuracy_meters) VALUES ($1, $2, $3, $4)`,
      [trip.id, latitude, longitude, accuracyMeters || null]
    );
    res.json({ ok: true });
  });

  router.post('/:id/stop', verifyMember, async (req, res) => {
    const { rows } = await pool.query(
      `UPDATE trips SET status = 'completed', ended_at = now()
       WHERE id = $1 AND member_id = $2 AND status = 'active' RETURNING *`,
      [req.params.id, req.member.memberId]
    );
    if (!rows.length) return res.status(404).json({ error: 'No active trip with that ID.' });
    res.json(rows[0]);
  });

  router.get('/history', verifyMember, async (req, res) => {
    const { rows } = await pool.query(
      `SELECT id, status, started_at, ended_at, label FROM trips
       WHERE member_id = $1 ORDER BY started_at DESC LIMIT 50`,
      [req.member.memberId]
    );
    res.json(rows);
  });

  return router;
};
