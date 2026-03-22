/**
 * Dump the current database schema to a SQL file.
 * Uses DATABASE_URL from backend/.env (no pg_dump needed).
 *
 * Run from project root:  cd backend && node scripts/dump-schema.js
 * Output: backend/supabase_schema.sql
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const { query } = require('../src/db');
const fs = require('fs');
const path = require('path');

const OUT_FILE = path.join(__dirname, '../supabase_schema.sql');

function pgType(info) {
  const { data_type, character_maximum_length, numeric_precision, numeric_scale } = info;
  switch (data_type) {
    case 'character varying':
    case 'varchar':
      return character_maximum_length != null ? `VARCHAR(${character_maximum_length})` : 'VARCHAR';
    case 'character':
      return character_maximum_length != null ? `CHAR(${character_maximum_length})` : 'CHAR';
    case 'text':
      return 'TEXT';
    case 'integer':
    case 'int4':
      return 'INTEGER';
    case 'bigint':
    case 'int8':
      return 'BIGINT';
    case 'smallint':
    case 'int2':
      return 'SMALLINT';
    case 'real':
    case 'float4':
      return 'REAL';
    case 'double precision':
    case 'float8':
      return 'DOUBLE PRECISION';
    case 'numeric':
    case 'decimal':
      if (numeric_precision != null) {
        return numeric_scale != null
          ? `NUMERIC(${numeric_precision},${numeric_scale})`
          : `NUMERIC(${numeric_precision})`;
      }
      return 'NUMERIC';
    case 'boolean':
      return 'BOOLEAN';
    case 'date':
      return 'DATE';
    case 'timestamp with time zone':
    case 'timestamptz':
      return 'TIMESTAMPTZ';
    case 'timestamp without time zone':
    case 'timestamp':
      return 'TIMESTAMP';
    case 'time with time zone':
      return 'TIMETZ';
    case 'time without time zone':
      return 'TIME';
    case 'jsonb':
      return 'JSONB';
    case 'json':
      return 'JSON';
    case 'uuid':
      return 'UUID';
    default:
      return (data_type || 'TEXT').toUpperCase();
  }
}

async function main() {
  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL not set. Add it to backend/.env');
    process.exit(1);
  }
  console.log('Connecting and reading schema...');
  const tables = await query(`
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    ORDER BY table_name
  `);
  const lines = [
    '-- Schema dump from DATABASE_URL (backend/.env)',
    `-- Generated: ${new Date().toISOString()}`,
    '',
  ];
  for (const { table_name } of tables.rows) {
    const cols = await query(
      `SELECT column_name, data_type, character_maximum_length, numeric_precision, numeric_scale, is_nullable, column_default
       FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = $1
       ORDER BY ordinal_position`,
      [table_name],
    );
    const pk = await query(
      `SELECT a.attname
       FROM pg_index i
       JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey) AND a.attisdropped = false
       JOIN pg_class c ON c.oid = i.indrelid
       JOIN pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname = 'public' AND c.relname = $1 AND i.indisprimary`,
      [table_name],
    );
    const pkCols = new Set(pk.rows.map((r) => r.attname));
    const colDefs = cols.rows.map((c) => {
      let def = `  "${c.column_name}" ${pgType(c)}`;
      if (c.column_default) def += ` DEFAULT ${c.column_default}`;
      if (c.is_nullable === 'NO') def += ' NOT NULL';
      if (pkCols.has(c.column_name)) def += ' PRIMARY KEY';
      return def;
    });
    lines.push(`CREATE TABLE IF NOT EXISTS "${table_name}" (`);
    lines.push(colDefs.join(',\n'));
    lines.push(');');
    lines.push('');
  }
  fs.writeFileSync(OUT_FILE, lines.join('\n'), 'utf8');
  console.log('Written:', path.relative(process.cwd(), OUT_FILE));
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
