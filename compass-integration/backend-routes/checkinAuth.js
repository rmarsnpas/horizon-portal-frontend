// Member login: member ID + PIN. Mount in your existing backend, e.g.:
//   app.use('/api/checkin/auth', require('./backend-routes/checkinAuth')(pool));
//
// Requires: npm install bcryptjs jsonwebtoken express-rate-limit
// Requires env var: CHECKIN_JWT_SECRET (a long random string, separate from any secret
// your staff login already uses)

const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');

module.exports = function (pool) {
  const router = express.Router();

  const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 10,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many attempts. Try again in a few minutes.' },
  });

  router.post('/login', loginLimiter, async (req, res) => {
    const { memberId, pin } = req.body;
    if (!memberId || !pin) {
      return res.status(400).json({ error: 'Member ID and PIN are required.' });
    }

    const { rows } = await pool.query(
      'SELECT * FROM checkin_members WHERE member_id = $1 AND active = TRUE',
      [memberId]
    );
    const member = rows[0];

    if (!member || !bcrypt.compareSync(String(pin), member.pin_hash)) {
      return res.status(401).json({ error: 'Incorrect member ID or PIN.' });
    }

    const token = jwt.sign(
      { role: 'checkin_member', memberId: member.member_id, name: member.name },
      process.env.CHECKIN_JWT_SECRET,
      { expiresIn: '12h' }
    );

    res.json({ token, name: member.name, memberId: member.member_id });
  });

  return router;
};
