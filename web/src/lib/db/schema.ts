import { query } from "./pool";
import type { RowDataPacket } from "mysql2";

export type TableMap = {
  players: boolean;
  player_vehicles: boolean;
  player_transactions: boolean;
  bank_accounts_new: boolean;
  rp_invoices: boolean;
  users: boolean;
  portal_accounts: boolean;
};

export type ColumnMap = Record<string, Set<string>>;

type Cache = {
  at: number;
  tables: TableMap;
  columns: ColumnMap;
};

let cache: Cache | null = null;
const TTL_MS = 60_000;

async function listTables() {
  const rows = await query<RowDataPacket[]>(
    `SELECT TABLE_NAME AS name
     FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = DATABASE()`,
  );
  return new Set(rows.map((r) => String(r.name)));
}

async function listColumns(table: string) {
  const rows = await query<RowDataPacket[]>(
    `SELECT COLUMN_NAME AS name
     FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :table`,
    { table },
  );
  return new Set(rows.map((r) => String(r.name)));
}

export async function discoverSchema(force = false) {
  if (cache && !force && Date.now() - cache.at < TTL_MS) return cache;

  const tablesPresent = await listTables();
  const tableNames = [
    "players",
    "player_vehicles",
    "player_transactions",
    "bank_accounts_new",
    "rp_invoices",
    "users",
    "portal_accounts",
  ] as const;

  const tables = {} as TableMap;
  const columns: ColumnMap = {};

  for (const name of tableNames) {
    tables[name] = tablesPresent.has(name);
    columns[name] = tables[name] ? await listColumns(name) : new Set();
  }

  cache = { at: Date.now(), tables, columns };
  return cache;
}

export function missingCritical(tables: TableMap) {
  const missing: string[] = [];
  if (!tables.players) missing.push("players (qbx_core)");
  if (!tables.player_vehicles) missing.push("player_vehicles (qbx_vehicles)");
  if (!tables.portal_accounts) missing.push("portal_accounts (migration portail)");
  return missing;
}
