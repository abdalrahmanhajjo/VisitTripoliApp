require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const { query } = require('../src/db');

async function main() {
  try {
    const t = await query(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('feed_likes', 'feed_comments') ORDER BY table_name"
    );
    console.log('Tables found:', t.rows.map((r) => r.table_name).join(', ') || 'none');
    const l = await query('SELECT COUNT(*) as c FROM feed_likes');
    const c = await query('SELECT COUNT(*) as c FROM feed_comments');
    console.log('feed_likes rows:', l.rows[0].c);
    console.log('feed_comments rows:', c.rows[0].c);
    console.log('Database is ready for likes and comments.');
  } catch (e) {
    console.error('Error:', e.message);
    process.exit(1);
  }
  process.exit(0);
}

main();
