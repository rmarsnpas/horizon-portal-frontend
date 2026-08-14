// If your existing Railway backend already creates a `pg` Pool somewhere (most Express +
// Postgres backends do), skip this file and just import your existing pool into the route
// files instead. This is only here in case you need one.

const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL, // Railway sets this automatically
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

module.exports = pool;
