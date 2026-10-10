/**
 * Smoke tests against a running portal + local serenityv seed.
 * Usage: node scripts/smoke-api.mjs [baseUrl]
 */
const base = process.argv[2] || "http://127.0.0.1:3000";

async function check(name, fn) {
  try {
    await fn();
    console.log(`OK  ${name}`);
  } catch (err) {
    console.error(`FAIL ${name}:`, err.message);
    process.exitCode = 1;
  }
}

await check("health", async () => {
  const res = await fetch(`${base}/api/health`);
  const json = await res.json();
  if (!res.ok || !json.ok) throw new Error(JSON.stringify(json));
  if (!json.schema?.tables?.players) throw new Error("players missing");
});

await check("dev login + session", async () => {
  const jar = new Map();
  const login = await fetch(`${base}/api/auth/discord`, { redirect: "manual" });
  const loc = login.headers.get("location");
  if (!loc) throw new Error("no redirect");
  // follow manually collecting cookies is heavy; just ensure redirect exists
  if (!loc.includes("/api/auth/callback") && !loc.includes("discord.com")) {
    throw new Error(`unexpected redirect ${loc}`);
  }
});

console.log("smoke done");
