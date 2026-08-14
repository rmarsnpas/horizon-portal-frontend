// Mount in your existing backend, e.g.:
//   app.use('/api/checkin/admin', requireStaffAuth, require('./backend-routes/checkinAdmin')(pool));
//
// IMPORTANT: replace `requireStaffAuth` above with whatever middleware your staff dashboard
// already uses to verify a logged-in staff session. These routes assume that's already been
// checked before they run — they don't do their own staff auth.

const express = require('express');
const bcrypt = require('bcryptjs');

module.exports = function (pool) {
  const router = express.Router();

  /* ---------- Members ---------- */
  router.get('/members', async (req, res) => {
    const { rows } = await pool.query(
      'SELECT id, member_id, name, house, phone, active, created_at FROM checkin_members ORDER BY name'
    );
    res.json(rows);
  });

  router.post('/members', async (req, res) => {
    const { memberId, name, house, phone, pin } = req.body;
    if (!memberId || !name || !pin) {
      return res.status(400).json({ error: 'Member ID, name, and a starting PIN are required.' });
    }
    const pinHash = bcrypt.hashSync(String(pin), 12);
    try {
      await pool.query(
        'INSERT INTO checkin_members (member_id, name, house, phone, pin_hash) VALUES ($1, $2, $3, $4, $5)',
        [memberId, name, house || null, phone || null, pinHash]
      );
      res.status(201).json({ ok: true });
    } catch (err) {
      res.status(409).json({ error: 'That member ID already exists.' });
    }
  });

  router.post('/members/:memberId/reset-pin', async (req, res) => {
    const { pin } = req.body;
    if (!pin) return res.status(400).json({ error: 'New PIN is required.' });
    const pinHash = bcrypt.hashSync(String(pin), 12);
    await pool.query('UPDATE checkin_members SET pin_hash = $1 WHERE member_id = $2', [pinHash, req.params.memberId]);
    res.json({ ok: true });
  });

  router.post('/members/:memberId/deactivate', async (req, res) => {
    await pool.query('UPDATE checkin_members SET active = FALSE WHERE member_id = $1', [req.params.memberId]);
    res.json({ ok: true });
  });

  /* ---------- Schedules ---------- */
  router.get('/schedules', async (req, res) => {
    const { rows } = await pool.query('SELECT * FROM checkin_schedules ORDER BY time');
    res.json(rows);
  });

  router.post('/schedules', async (req, res) => {
    const { label, time, days, graceMinutes, house } = req.body;
    if (!label || !time || !days || !days.length) {
      return res.status(400).json({ error: 'Label, time, and at least one day are required.' });
    }
    await pool.query(
      'INSERT INTO checkin_schedules (label, time, days, grace_minutes, house) VALUES ($1, $2, $3, $4, $5)',
      [label, time, days.join(','), graceMinutes || 15, house || null]
    );
    res.status(201).json({ ok: true });
  });

  router.post('/schedules/:id/deactivate', async (req, res) => {
    await pool.query('UPDATE checkin_schedules SET active = FALSE WHERE id = $1', [req.params.id]);
    res.json({ ok: true });
  });

  /* ---------- History / live status ---------- */
  router.get('/checkins', async (req, res) => {
    const { memberId, limit } = req.query;
    const lim = Number(limit) || 200;
    let rows;
    if (memberId) {
      ({ rows } = await pool.query(
        `SELECT c.*, s.label FROM checkins c LEFT JOIN checkin_schedules s ON s.id = c.schedule_id
         WHERE c.member_id = $1 ORDER BY c.checked_in_at DESC LIMIT $2`,
        [memberId, lim]
      ));
    } else {
      ({ rows } = await pool.query(
        `SELECT c.*, m.name, s.label FROM checkins c
         JOIN checkin_members m ON m.member_id = c.member_id
         LEFT JOIN checkin_schedules s ON s.id = c.schedule_id
         ORDER BY c.checked_in_at DESC LIMIT $1`,
        [lim]
      ));
    }
    res.json(rows);
  });

  router.get('/today', async (req, res) => {
    const { rows: members } = await pool.query('SELECT * FROM checkin_members WHERE active = TRUE');
    const todayName = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'][new Date().getDay()];
    const { rows: allSchedules } = await pool.query('SELECT * FROM checkin_schedules WHERE active = TRUE');
    const schedules = allSchedules.filter((s) => s.days.split(',').includes(todayName));

    const result = [];
    for (const m of members) {
      const relevant = schedules.filter((s) => !s.house || s.house === m.house);
      const statuses = [];
      for (const s of relevant) {
        const { rows } = await pool.query(
          `SELECT * FROM checkins WHERE member_id = $1 AND schedule_id = $2
           AND date(scheduled_for) = current_date LIMIT 1`,
          [m.member_id, s.id]
        );
        const done = rows[0];
        statuses.push({
          label: s.label,
          time: s.time,
          checkedIn: !!done,
          checkedInAt: done ? done.checked_in_at : null,
          status: done ? done.status : null,
        });
      }
      result.push({ memberId: m.member_id, name: m.name, house: m.house, windows: statuses });
    }

    res.json(result);
  });

  return router;
};
