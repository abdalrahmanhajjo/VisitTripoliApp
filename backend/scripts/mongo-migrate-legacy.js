require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const { MongoClient } = require('mongodb');

const uri = process.env.MONGODB_URI || process.env.DATABASE_URL;
const dbName = process.env.MONGODB_DB_NAME || 'visittripoli';

async function normalizeUsers(db) {
  const users = db.collection('users');
  await users.updateMany(
    { email: { $type: 'string' } },
    [{ $set: { email_lower: { $toLower: '$email' } } }]
  );
}

async function normalizeProfiles(db) {
  const profiles = db.collection('profiles');
  const rows = await profiles.find({ username: { $type: 'string' } }, { projection: { _id: 1, username: 1 } }).toArray();
  for (const row of rows) {
    const normalized = String(row.username).replace(/^@+/, '').trim().toLowerCase();
    await profiles.updateOne({ _id: row._id }, { $set: { username_normalized: normalized } });
  }
}

async function normalizeDates(db, collName, fields) {
  const coll = db.collection(collName);
  const rows = await coll.find({}, { projection: { _id: 1, ...Object.fromEntries(fields.map((f) => [f, 1])) } }).toArray();
  for (const row of rows) {
    const set = {};
    for (const f of fields) {
      const v = row[f];
      if (v && !(v instanceof Date)) {
        const d = new Date(v);
        if (!Number.isNaN(d.getTime())) set[f] = d;
      }
    }
    if (Object.keys(set).length) await coll.updateOne({ _id: row._id }, { $set: set });
  }
}

async function main() {
  if (!uri) throw new Error('Missing MONGODB_URI or DATABASE_URL');
  const client = new MongoClient(uri);
  await client.connect();
  const db = client.db(dbName);

  await normalizeUsers(db);
  await normalizeProfiles(db);
  await normalizeDates(db, 'feed_posts', ['created_at', 'updated_at']);
  await normalizeDates(db, 'feed_comments', ['created_at', 'updated_at']);
  await normalizeDates(db, 'bookings', ['created_at', 'updated_at']);
  await normalizeDates(db, 'trips', ['created_at', 'updated_at']);
  await normalizeDates(db, 'place_reviews', ['created_at', 'updated_at', 'visit_date']);

  console.log('Legacy Mongo normalization complete.');
  await client.close();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
