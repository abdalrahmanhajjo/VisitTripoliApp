require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const { MongoClient } = require('mongodb');

const uri = process.env.MONGODB_URI || process.env.DATABASE_URL;
const dbName = process.env.MONGODB_DB_NAME || 'visittripoli';

async function main() {
  if (!uri) throw new Error('Missing MONGODB_URI or DATABASE_URL');
  const client = new MongoClient(uri);
  await client.connect();
  const db = client.db(dbName);

  const checks = [
    ['users', {}],
    ['profiles', {}],
    ['places', {}],
    ['categories', {}],
    ['events', {}],
    ['tours', {}],
    ['interests', {}],
    ['feed_posts', {}],
    ['feed_comments', {}],
    ['feed_likes', {}],
    ['feed_saves', {}],
    ['bookings', {}],
    ['trips', {}],
    ['badges', {}],
  ];

  const result = {};
  for (const [name, filter] of checks) {
    result[name] = await db.collection(name).countDocuments(filter);
  }

  const sampleFeed = await db.collection('feed_posts')
    .find({}, { projection: { _id: 0, id: 1, place_id: 1, author_role: 1, moderation_status: 1, created_at: 1 } })
    .sort({ created_at: -1 })
    .limit(5)
    .toArray();

  console.log(JSON.stringify({ counts: result, sampleFeed }, null, 2));
  await client.close();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
