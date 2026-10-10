import { z } from "zod";

export const linkCodeSchema = z.object({
  code: z
    .string()
    .trim()
    .regex(/^\d{6}$/, "Code à 6 chiffres requis"),
  csrfToken: z.string().min(16),
});

export const selectCharacterSchema = z.object({
  citizenid: z
    .string()
    .trim()
    .min(3)
    .max(50)
    .regex(/^[A-Za-z0-9_-]+$/, "citizenid invalide"),
  csrfToken: z.string().min(16),
});

export const ticketCreateSchema = z.object({
  subject: z.string().trim().min(5).max(180),
  body: z.string().trim().min(10).max(4000),
  csrfToken: z.string().min(16),
});

export const adminSearchSchema = z.object({
  q: z.string().trim().min(2).max(80),
});

export const bankQuerySchema = z.object({
  from: z.string().min(4).max(40).optional(),
  to: z.string().min(4).max(40).optional(),
  page: z.coerce.number().int().min(1).max(500).optional(),
  pageSize: z.coerce.number().int().min(5).max(50).optional(),
});

export const garageQuerySchema = z.object({
  q: z.string().trim().max(64).optional(),
  state: z.coerce.number().int().min(0).max(2).optional(),
});

export const fivemSyncSchema = z.object({
  event: z.string().min(1).max(64),
  at: z.number().int().optional(),
  serverId: z.number().int().optional(),
  player: z.object({
    citizenid: z.string().min(1).max(50),
    cid: z.union([z.number(), z.null()]).optional(),
    license: z.string().optional(),
    name: z.string().optional(),
    firstname: z.string().optional(),
    lastname: z.string().optional(),
    cash: z.number().optional(),
    bank: z.number().optional(),
    job: z.string().nullable().optional(),
    playtime: z.number().optional(),
  }),
});
