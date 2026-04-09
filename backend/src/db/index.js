const { MongoClient } = require('mongodb');
const logger = require('../utils/logger');

const connectionString =
  process.env.MONGODB_URI ||
  process.env.DATABASE_URL ||
  '';

const dbName = process.env.MONGODB_DB_NAME || 'visittripoli';
const maxPoolSize = process.env.DB_POOL_SIZE ? parseInt(process.env.DB_POOL_SIZE, 10) : 20;

let _client = null;
let _db = null;

async function connectMongo() {
  if (_db) return _db;
  if (!connectionString) {
    throw new Error('MONGODB_URI (or DATABASE_URL) is required');
  }
  _client = new MongoClient(connectionString, {
    maxPoolSize,
    minPoolSize: 2,
    connectTimeoutMS: 20000,
    socketTimeoutMS: 30000,
    serverSelectionTimeoutMS: 10000,
    retryReads: true,
    retryWrites: true,
  });
  await _client.connect();
  _db = _client.db(dbName);
  logger.info('MongoDB connected', { dbName, maxPoolSize });
  return _db;
}

function getDb() {
  if (!_db) {
    throw new Error('MongoDB is not connected yet. Call connectMongo() first.');
  }
  return _db;
}

function collection(name) {
  return getDb().collection(name);
}

async function ping() {
  const db = await connectMongo();
  await db.command({ ping: 1 });
  return true;
}

async function closeMongo() {
  if (_client) {
    await _client.close();
    _client = null;
    _db = null;
  }
}

// Keep a compatibility export to surface accidental SQL usage quickly.
async function query() {
  throw new Error('SQL query() is no longer supported. Migrate this path to MongoDB.');
}

module.exports = {
  connectMongo,
  closeMongo,
  getDb,
  collection,
  ping,
  query,
  pool: null,
};
