import { discoverSchema, missingCritical } from "@/lib/db/schema";
import { query } from "@/lib/db/pool";
import { safeJsonParse, formatPlaytime } from "@/lib/utils";
import type { RowDataPacket } from "mysql2";

export type Money = { cash: number; bank: number; crypto: number };
export type CharInfo = {
  firstname?: string;
  lastname?: string;
  birthdate?: string;
  phone?: string;
  cid?: number;
};

export type CharacterSummary = {
  citizenid: string;
  cid: number | null;
  license: string;
  name: string;
  firstname: string;
  lastname: string;
  cash: number;
  bank: number;
  jobLabel: string;
  lastUpdated: string | null;
};

export type VehicleRow = {
  id: number;
  citizenid: string;
  vehicle: string;
  plate: string;
  garage: string | null;
  state: number;
  fuel: number | null;
  engine: number | null;
  body: number | null;
  drivingdistance: number | null;
  statusLabel: "rangé" | "sorti" | "fourrière" | "inconnu";
};

export type BankTransaction = {
  id: string;
  amount: number;
  message: string;
  type: string;
  time: number;
  sender?: string;
  receiver?: string;
};

function vehicleStatus(state: number): VehicleRow["statusLabel"] {
  if (state === 0) return "sorti";
  if (state === 1) return "rangé";
  if (state === 2) return "fourrière";
  return "inconnu";
}

function parseMoney(raw: unknown): Money {
  const m = safeJsonParse<Partial<Money>>(raw, {});
  return {
    cash: Number(m.cash ?? 0),
    bank: Number(m.bank ?? 0),
    crypto: Number(m.crypto ?? 0),
  };
}

function parseCharinfo(raw: unknown): CharInfo {
  return safeJsonParse<CharInfo>(raw, {});
}

export async function getSchemaStatus() {
  const schema = await discoverSchema();
  return {
    tables: schema.tables,
    missingCritical: missingCritical(schema.tables),
    banking: {
      playerTransactions: schema.tables.player_transactions,
      bankAccountsNew: schema.tables.bank_accounts_new,
      note: schema.tables.player_transactions
        ? "Historique Renewed-Banking détecté"
        : "Table player_transactions absente — soldes via players.money uniquement",
    },
    invoices: schema.tables.rp_invoices
      ? "rp_invoices détectée"
      : "Aucune table factures connue",
  };
}

export async function getCharactersByLicense(license: string) {
  const schema = await discoverSchema();
  if (!schema.tables.players) {
    throw new Error("Table players introuvable — qbx_core requis.");
  }

  const rows = await query<RowDataPacket[]>(
    `SELECT citizenid, cid, license, name, money, charinfo, job, last_updated, last_logged_out
     FROM players
     WHERE license = :license OR license = :licenseAlt
     ORDER BY cid ASC`,
    {
      license,
      licenseAlt: license.replace(/^license2?:/, "license:"),
    },
  );

  return rows.map((row) => {
    const money = parseMoney(row.money);
    const charinfo = parseCharinfo(row.charinfo);
    const job = safeJsonParse<{ label?: string; name?: string }>(row.job, {});
    return {
      citizenid: String(row.citizenid),
      cid: row.cid == null ? null : Number(row.cid),
      license: String(row.license),
      name: String(row.name ?? ""),
      firstname: charinfo.firstname || "Inconnu",
      lastname: charinfo.lastname || "",
      cash: money.cash,
      bank: money.bank,
      jobLabel: job.label || job.name || "Civil",
      lastUpdated: row.last_logged_out
        ? String(row.last_logged_out)
        : row.last_updated
          ? String(row.last_updated)
          : null,
    } satisfies CharacterSummary;
  });
}

export async function getCharacter(citizenid: string) {
  const rows = await query<RowDataPacket[]>(
    `SELECT citizenid, cid, license, name, money, charinfo, job, gang, metadata,
            phone_number, last_updated, last_logged_out
     FROM players WHERE citizenid = :citizenid LIMIT 1`,
    { citizenid },
  );
  const row = rows[0];
  if (!row) return null;

  const money = parseMoney(row.money);
  const charinfo = parseCharinfo(row.charinfo);
  const metadata = safeJsonParse<Record<string, unknown>>(row.metadata, {});
  const job = safeJsonParse<{ label?: string; name?: string; grade?: { name?: string } }>(
    row.job,
    {},
  );

  return {
    citizenid: String(row.citizenid),
    cid: row.cid == null ? null : Number(row.cid),
    license: String(row.license),
    accountName: String(row.name ?? ""),
    firstname: charinfo.firstname || "Inconnu",
    lastname: charinfo.lastname || "",
    phone: charinfo.phone || row.phone_number || null,
    cash: money.cash,
    bank: money.bank,
    crypto: money.crypto,
    jobLabel: job.label || job.name || "Civil",
    jobGrade: job.grade?.name || null,
    metadataPlaytime: Number(metadata.playtime ?? 0),
    lastUpdated: row.last_updated ? String(row.last_updated) : null,
    lastLoggedOut: row.last_logged_out ? String(row.last_logged_out) : null,
  };
}

export async function getPlaytimeSeconds(citizenid: string) {
  const schema = await discoverSchema();
  let tracked = 0;
  if (schema.tables.portal_accounts) {
    const rows = await query<RowDataPacket[]>(
      `SELECT COALESCE(SUM(seconds), 0) AS total
       FROM portal_playtime_sessions
       WHERE citizenid = :citizenid AND ended_at IS NOT NULL`,
      { citizenid },
    );
    tracked = Number(rows[0]?.total ?? 0);

    const open = await query<RowDataPacket[]>(
      `SELECT COALESCE(SUM(TIMESTAMPDIFF(SECOND, started_at, NOW())), 0) AS open_total
       FROM portal_playtime_sessions
       WHERE citizenid = :citizenid AND ended_at IS NULL`,
      { citizenid },
    );
    tracked += Number(open[0]?.open_total ?? 0);
  }

  const character = await getCharacter(citizenid);
  const meta = character?.metadataPlaytime ?? 0;
  // Prefer the higher of tracked portal sessions vs metadata (avoid double-count display by using max)
  const seconds = Math.max(tracked, meta);
  return { seconds, label: formatPlaytime(seconds), source: tracked >= meta ? "portal" : "metadata" };
}

export async function getVehicles(citizenid: string, opts?: { q?: string; state?: number }) {
  const schema = await discoverSchema();
  if (!schema.tables.player_vehicles) {
    return { vehicles: [] as VehicleRow[], missing: true as const };
  }

  const params: Record<string, unknown> = { citizenid };
  let sql = `SELECT id, citizenid, vehicle, plate, garage, state, fuel, engine, body, drivingdistance
             FROM player_vehicles WHERE citizenid = :citizenid`;

  if (opts?.state != null && !Number.isNaN(opts.state)) {
    sql += ` AND state = :state`;
    params.state = opts.state;
  }
  if (opts?.q) {
    sql += ` AND (plate LIKE :q OR vehicle LIKE :q OR garage LIKE :q)`;
    params.q = `%${opts.q}%`;
  }
  sql += ` ORDER BY vehicle ASC, plate ASC`;

  const rows = await query<RowDataPacket[]>(sql, params);
  return {
    missing: false as const,
    vehicles: rows.map((row) => ({
      id: Number(row.id),
      citizenid: String(row.citizenid),
      vehicle: String(row.vehicle ?? "unknown"),
      plate: String(row.plate ?? ""),
      garage: row.garage == null ? null : String(row.garage),
      state: Number(row.state ?? 1),
      fuel: row.fuel == null ? null : Number(row.fuel),
      engine: row.engine == null ? null : Number(row.engine),
      body: row.body == null ? null : Number(row.body),
      drivingdistance: row.drivingdistance == null ? null : Number(row.drivingdistance),
      statusLabel: vehicleStatus(Number(row.state ?? 1)),
    })),
  };
}

export async function getVehicle(citizenid: string, id: number) {
  const { vehicles, missing } = await getVehicles(citizenid);
  if (missing) return { missing: true as const, vehicle: null };
  return { missing: false as const, vehicle: vehicles.find((v) => v.id === id) ?? null };
}

export async function getBankHistory(
  citizenid: string,
  opts?: { from?: Date; to?: Date; page?: number; pageSize?: number },
) {
  const schema = await discoverSchema();
  const character = await getCharacter(citizenid);
  if (!character) {
    return { missingCharacter: true as const };
  }

  const page = Math.max(1, opts?.page ?? 1);
  const pageSize = Math.min(50, Math.max(5, opts?.pageSize ?? 20));

  if (!schema.tables.player_transactions) {
    return {
      missingCharacter: false as const,
      historyAvailable: false as const,
      cash: character.cash,
      bank: character.bank,
      transactions: [] as BankTransaction[],
      total: 0,
      page,
      pageSize,
      warning:
        "Table player_transactions absente. Soldes lus depuis players.money (Qbox). Aucune table de remplacement n'a été créée.",
    };
  }

  const rows = await query<RowDataPacket[]>(
    `SELECT id, isFrozen, transactions FROM player_transactions WHERE id = :citizenid LIMIT 1`,
    { citizenid },
  );

  type RawTx = {
    amount?: number;
    message?: string;
    type?: string;
    time?: number;
    trans_id?: string;
    sender?: string;
    receiver?: string;
  };

  let all = safeJsonParse<RawTx[]>(rows[0]?.transactions, []).map((tx, idx) => ({
    id: String(tx.trans_id ?? `${citizenid}-${idx}`),
    amount: Number(tx.amount ?? 0),
    message: String(tx.message ?? "Transaction"),
    type: String(tx.type ?? "unknown"),
    time: Number(tx.time ?? 0),
    sender: tx.sender,
    receiver: tx.receiver,
  }));

  if (opts?.from) {
    const from = Math.floor(opts.from.getTime() / 1000);
    all = all.filter((t) => t.time >= from);
  }
  if (opts?.to) {
    const to = Math.floor(opts.to.getTime() / 1000);
    all = all.filter((t) => t.time <= to);
  }

  all.sort((a, b) => b.time - a.time);
  const total = all.length;
  const start = (page - 1) * pageSize;
  const transactions = all.slice(start, start + pageSize);

  return {
    missingCharacter: false as const,
    historyAvailable: true as const,
    cash: character.cash,
    bank: character.bank,
    frozen: Number(rows[0]?.isFrozen ?? 0) === 1,
    transactions,
    total,
    page,
    pageSize,
    warning: null as string | null,
  };
}

export async function getRecentNotifications(citizenid: string, limit = 8) {
  const safeLimit = Math.min(50, Math.max(1, Math.floor(limit)));
  try {
    const rows = await query<RowDataPacket[]>(
      `SELECT id, title, body, level, is_read, created_at
       FROM portal_notifications
       WHERE citizenid = :citizenid
       ORDER BY created_at DESC LIMIT ${safeLimit}`,
      { citizenid },
    );
    return rows.map((r) => ({
      id: Number(r.id),
      title: String(r.title),
      body: String(r.body),
      level: String(r.level),
      isRead: Boolean(r.is_read),
      createdAt: String(r.created_at),
    }));
  } catch {
    return [];
  }
}

export async function getRecentActivities(citizenid: string, limit = 8) {
  const safeLimit = Math.min(50, Math.max(1, Math.floor(limit)));
  try {
    const rows = await query<RowDataPacket[]>(
      `SELECT id, category, summary, created_at
       FROM portal_activities
       WHERE citizenid = :citizenid
       ORDER BY created_at DESC LIMIT ${safeLimit}`,
      { citizenid },
    );
    return rows.map((r) => ({
      id: Number(r.id),
      category: String(r.category),
      summary: String(r.summary),
      createdAt: String(r.created_at),
    }));
  } catch {
    return [];
  }
}

export async function searchPlayersAdmin(q: string) {
  const schema = await discoverSchema();
  if (!schema.tables.players) return [];

  const like = `%${q}%`;
  const rows = await query<RowDataPacket[]>(
    `SELECT p.citizenid, p.cid, p.license, p.name, p.charinfo, p.money,
            a.discord_id, a.discord_username
     FROM players p
     LEFT JOIN portal_account_links l
       ON l.license = p.license AND l.is_active = 1
     LEFT JOIN portal_accounts a ON a.id = l.account_id
     WHERE p.citizenid LIKE :like
        OR p.license LIKE :like
        OR p.name LIKE :like
        OR p.charinfo LIKE :like
        OR a.discord_id LIKE :like
        OR a.discord_username LIKE :like
     ORDER BY p.last_updated DESC
     LIMIT 40`,
    { like },
  );

  return rows.map((row) => {
    const charinfo = parseCharinfo(row.charinfo);
    const money = parseMoney(row.money);
    return {
      citizenid: String(row.citizenid),
      cid: row.cid == null ? null : Number(row.cid),
      license: String(row.license),
      name: String(row.name ?? ""),
      firstname: charinfo.firstname || "",
      lastname: charinfo.lastname || "",
      cash: money.cash,
      bank: money.bank,
      discordId: row.discord_id ? String(row.discord_id) : null,
      discordUsername: row.discord_username ? String(row.discord_username) : null,
    };
  });
}
