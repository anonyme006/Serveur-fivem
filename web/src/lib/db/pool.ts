import mysql, { type Pool, type RowDataPacket, type ResultSetHeader } from "mysql2/promise";

let pool: Pool | null = null;

export function getPool() {
  if (pool) return pool;

  const host = process.env.MYSQL_HOST;
  const user = process.env.MYSQL_USER;
  const password = process.env.MYSQL_PASSWORD;
  const database = process.env.MYSQL_DATABASE || "serenityv";

  if (!host || !user) {
    throw new Error("MySQL non configuré (MYSQL_HOST / MYSQL_USER).");
  }

  pool = mysql.createPool({
    host,
    port: Number(process.env.MYSQL_PORT || 3306),
    user,
    password: password || "",
    database,
    waitForConnections: true,
    connectionLimit: 10,
    namedPlaceholders: true,
    timezone: "Z",
  });

  return pool;
}

export async function query<T extends RowDataPacket[]>(
  sql: string,
  params?: object,
) {
  const [rows] = await getPool().query<T>(sql, params as never);
  return rows;
}

export async function execute(sql: string, params?: object) {
  const [result] = await getPool().execute<ResultSetHeader>(sql, params as never);
  return result;
}
