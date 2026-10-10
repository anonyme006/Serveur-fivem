import assert from "node:assert/strict";
import { safeJsonParse } from "@/lib/utils";

// Smoke tests without DB — parsing helpers used by the Qbox adapter
const money = safeJsonParse<{ cash?: number; bank?: number }>(
  '{"cash":100,"bank":500}',
  {},
);
assert.equal(money.cash, 100);
assert.equal(money.bank, 500);

const broken = safeJsonParse<{ cash?: number }>("not-json", { cash: 0 });
assert.equal(broken.cash, 0);

const charinfo = safeJsonParse<{ firstname?: string; lastname?: string }>(
  '{"firstname":"Alex","lastname":"Moreau"}',
  {},
);
assert.equal(`${charinfo.firstname} ${charinfo.lastname}`, "Alex Moreau");

console.log("adapter parsing tests ok");
