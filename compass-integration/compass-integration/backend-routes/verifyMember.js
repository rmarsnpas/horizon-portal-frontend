const jwt = require('jsonwebtoken');

// Verifies the member token issued by checkinAuth.js.
function verifyMember(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Not logged in.' });

  try {
    const payload = jwt.verify(token, process.env.CHECKIN_JWT_SECRET);
    if (payload.role !== 'checkin_member') return res.status(403).json({ error: 'Not allowed.' });
    req.member = payload;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Session expired. Please log in again.' });
  }
}

module.exports = { verifyMember };
