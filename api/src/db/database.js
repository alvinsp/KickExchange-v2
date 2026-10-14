import fs from 'node:fs';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { config } from '../config/env.js';
import { SCHEMA_SQL } from './schema.js';

let db;
let txDepth = 0;

export function getDb() {
  if (db) return db;

  if (config.dbPath !== ':memory:') {
    fs.mkdirSync(path.dirname(path.resolve(config.dbPath)), { recursive: true });
  }

  db = new DatabaseSync(config.dbPath);
  db.exec('PRAGMA foreign_keys = ON;');
  db.exec('PRAGMA busy_timeout = 5000;');
  if (config.dbPath !== ':memory:') db.exec('PRAGMA journal_mode = WAL;');
  db.exec(SCHEMA_SQL);
  return db;
}

/**
 * Runs `fn` atomically. Nested calls use SAVEPOINTs so services can compose.
 * `fn` MUST be synchronous (node:sqlite is synchronous).
 */
export function transaction(fn) {
  const conn = getDb();
  const savepoint = `sp_${txDepth}`;
  if (txDepth === 0) conn.exec('BEGIN IMMEDIATE');
  else conn.exec(`SAVEPOINT ${savepoint}`);
  txDepth += 1;
  try {
    const result = fn(conn);
    txDepth -= 1;
    if (txDepth === 0) conn.exec('COMMIT');
    else conn.exec(`RELEASE ${savepoint}`);
    return result;
  } catch (err) {
    txDepth -= 1;
    if (txDepth === 0) conn.exec('ROLLBACK');
    else conn.exec(`ROLLBACK TO ${savepoint}; RELEASE ${savepoint}`);
    throw err;
  }
}

export function closeDb() {
  if (db) {
    db.close();
    db = undefined;
  }
}
