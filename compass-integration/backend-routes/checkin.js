// Mount in your existing backend, e.g.:
//   app.use('/api/checkin', require('./backend-routes/checkin')(pool));

const express = require('express');
const { verifyMember } = require('./verifyMember');

const DAY_NAMES = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

module.exports = function (pool) {
  const router = express.Router();

  async function schedulesForHouse(house) {
    const { rows } = await pool.query(
      'SELECT * FROM checkin_schedules WHERE active = TRUE AND (house IS NULL OR house = $1)',
      [house || null]
    );
    return rows;
  }

  async function resolveWindow(memberId, house, now = new Date()) {
    const todayName = DAY_NAMES[now.getDay()];
    const todays = (await schedulesForHouse(house)).filter((s) => s.days.split(',').includes(todayName));

    const withTimes = todays
      .map((s) => {
        const [h, m] = s.time.split(':').map(Number);
        const opensAt = new Date(now);
        opensAt.setHours(h, m, 0, 0);
        return { ...s, opensAt };
      })
      .filter((s) => s.opensAt <= now)
      .sort((a, b) => b.opensAt - a.opensAt);

    const current = withTimes[0] || null;
    if (!current) return { schedule: null };

    const { rows } = await pool.query(
      `SELECT * FROM checkins WHERE member_id = $1 AND schedule_id = $2
       AND date(scheduled_for) = date($3) LIMIT 1`,
      [memberId, current.id, current.opensAt.toISOString()]
    );

    const minutesLate = Math.floor((now - current.opensAt) / 60000);
    const status = minutesLate <= current.grace_minutes ? 'on_time' : 'late';

    return { schedule: current, alreadyDone: rows.length > 0, status, minutesLate };
  }

  router.get('/current', verifyMember, async (req, res) => {
    const { rows } = await pool.query('SELECT * FROM checkin_members WHERE member_id = $1', [req.member.memberId]);
    const member = rows[0];
    const result = await resolveWindow(member.member_id, member.house);

    if (!result.schedule) {
      return res.json({ open: false, message: 'No check-in window is open right now.' });
    }

    res.json({
      open: !result.alreadyDone,
      alreadyDone: result.alreadyDone,
      label: result.schedule.label,
      scheduledFor: result.schedule.opensAt,
      status: result.status,
      minutesLate: result.minutesLate,
    });
  });

  router.post('/', verifyMember, async (req, res) => {
    const { latitude, longitude, accuracyMeters, note } = req.body;
    if (typeof latitude !== 'number' || typeof longitude !== 'number') {
      return res.status(400).json({ error: 'Location is required to check in. Please allow location access.' });
    }

    const { rows: memberRows } = await pool.query('SELECT * FROM checkin_members WHERE member_id = $1', [req.member.memberId]);
    const member = memberRows[0];
    const result = await resolveWindow(member.member_id, member.house);

    if (!result.schedule) {
      await pool.query(
        `INSERT INTO checkins (member_id, schedule_id, scheduled_for, status, latitude, longitude, accuracy_meters, note)
         VALUES ($1, NULL, NULL, 'unscheduled', $2, $3, $4, $5)`,
        [member.member_id, latitude, longitude, accuracyMeters || null, note || null]
      );
      return res.json({ status: 'unscheduled', message: 'Logged. No check-in window was open at this time.' });
    }

    if (result.alreadyDone) {
      return res.status(409).json({ error: 'You already checked in for this window.' });
    }

    await pool.query(
      `INSERT INTO checkins (member_id, schedule_id, scheduled_for, status, latitude, longitude, accuracy_meters, note)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        member.member_id,
        result.schedule.id,
        result.schedule.opensAt.toISOString(),
        result.status,
        latitude,
        longitude,
        accuracyMeters || null,
        note || null,
      ]
    );

    res.json({ status: result.status, label: result.schedule.label });
  });

  router.get('/history', verifyMember, async (req, res) => {
    const { rows } = await pool.query(
      `SELECT c.checked_in_at, c.status, s.label
       FROM checkins c LEFT JOIN checkin_schedules s ON s.id = c.schedule_id
       WHERE c.member_id = $1 ORDER BY c.checked_in_at DESC LIMIT 100`,
      [req.member.memberId]
    );
    res.json(rows);
  });

  return router;
};
