require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const { MongoClient } = require('mongodb');

const uri = process.env.MONGODB_URI || process.env.DATABASE_URL;
const dbName = process.env.MONGODB_DB_NAME || 'visittripoli';

async function dedupeByKeys(db, collName, keys) {
  const coll = db.collection(collName);
  const groupId = {};
  for (const k of keys) groupId[k] = `$${k}`;
  const dups = await coll.aggregate([
    { $group: { _id: groupId, ids: { $push: '$_id' }, count: { $sum: 1 } } },
    { $match: { count: { $gt: 1 } } },
  ]).toArray();
  for (const d of dups) {
    const keep = d.ids[0];
    const drop = d.ids.slice(1);
    if (drop.length) {
      await coll.deleteMany({ _id: { $in: drop } });
      console.log(`Deduped ${collName}: removed ${drop.length} duplicate docs for ${JSON.stringify(d._id)}`);
    }
    if (!keep) break;
  }
}

async function ensureIndexes(db) {
  await dedupeByKeys(db, 'saved_places', ['user_id', 'place_id']);
  await dedupeByKeys(db, 'place_owners', ['user_id', 'place_id']);
  await dedupeByKeys(db, 'feed_likes', ['post_id', 'user_id']);
  await dedupeByKeys(db, 'feed_saves', ['post_id', 'user_id']);
  await dedupeByKeys(db, 'feed_comment_likes', ['comment_id', 'user_id']);
  await dedupeByKeys(db, 'feed_reports', ['post_id', 'user_id']);
  await dedupeByKeys(db, 'coupon_redemptions', ['user_id', 'coupon_id']);

  await Promise.all([
    db.collection('users').createIndex({ id: 1 }, { unique: true }),
    db.collection('users').createIndex({ email_lower: 1 }, { unique: true, sparse: true }),
    db.collection('profiles').createIndex({ user_id: 1 }, { unique: true }),
    db.collection('profiles').createIndex({ username_normalized: 1 }, { unique: true, sparse: true }),
    db.collection('saved_places').createIndex({ user_id: 1, place_id: 1 }, { unique: true }),
    db.collection('place_owners').createIndex({ user_id: 1, place_id: 1 }, { unique: true }),
    db.collection('feed_posts').createIndex({ id: 1 }, { unique: true }),
    db.collection('feed_posts').createIndex({ moderation_status: 1, created_at: -1 }),
    db.collection('feed_posts').createIndex({ place_id: 1, created_at: -1 }),
    db.collection('feed_likes').createIndex({ post_id: 1, user_id: 1 }, { unique: true }),
    db.collection('feed_saves').createIndex({ post_id: 1, user_id: 1 }, { unique: true }),
    db.collection('feed_comments').createIndex({ id: 1 }, { unique: true }),
    db.collection('feed_comments').createIndex({ post_id: 1, created_at: -1 }),
    db.collection('feed_comment_likes').createIndex({ comment_id: 1, user_id: 1 }, { unique: true }),
    db.collection('feed_reports').createIndex({ post_id: 1, user_id: 1 }, { unique: true }),
    db.collection('coupon_redemptions').createIndex({ user_id: 1, coupon_id: 1 }, { unique: true }),
    db.collection('email_verification_tokens').createIndex({ token_hash: 1 }, { unique: true }),
    db.collection('email_verification_tokens').createIndex({ expires_at: 1 }, { expireAfterSeconds: 0 }),
    db.collection('password_reset_tokens').createIndex({ token_hash: 1 }, { unique: true }),
    db.collection('password_reset_tokens').createIndex({ expires_at: 1 }, { expireAfterSeconds: 0 }),
    db.collection('trip_shares').createIndex({ share_token: 1 }, { unique: true }),
  ]);
}

async function main() {
  if (!uri) throw new Error('Missing MONGODB_URI or DATABASE_URL');
  const client = new MongoClient(uri);
  await client.connect();
  const db = client.db(dbName);
  await ensureIndexes(db);
  console.log(`Mongo indexes ensured for ${dbName}`);
  await client.close();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
