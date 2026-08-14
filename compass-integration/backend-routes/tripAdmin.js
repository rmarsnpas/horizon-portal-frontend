// Staff view of trips. Protect with your existing staff auth middleware when mounting:
//   app.use('/api/checkin/admin/trips', requireStaffAuth, require('./backend-routes/tripAdmin')(pool));

const express = require('express');

module.exports = function (pool) {
  const router = express.Router();

  // List trips, optionally filtered by member, most recent first.
  router.get('/', async (req, res) => {
    const { memberId } = req.query;
    let rows;
    if (memberId) {
      ({ rows } = await pool.query(
        `SELECT t.*, m.name FROM trips t JOIN checkin_members m ON m.member_id = t.member_id
         WHERE t.member_id = $1 ORDER BY t.started_at DESC LIMIT 100`,
        [memberId]
      ));
    } else {
      ({ rows } = await pool.query(
        `SELECT t.*, m.name FROM trips t JOIN checkin_members m ON m.member_id = t.member_id
         ORDER BY t.started_at DESC LIMIT 100`
      ));
    }
    res.json(rows);
  });

  // All recorded points for one trip, in order — this is what draws the route on the map.
  router.get('/:id/points', async (req, res) => {
    const { rows } = await pool.query(
      `SELECT latitude, longitude, accuracy_meters, recorded_at FROM trip_points
       WHERE trip_id = $1 ORDER BY recorded_at ASC`,
      [req.params.id]
    );
    res.json(rows);
  });

  return router;
};
