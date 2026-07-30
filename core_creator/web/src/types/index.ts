export type ModuleName =
  | 'shops'
  | 'blips'
  | 'vehicles'
  | 'farms'
  | 'jobs'
  | 'garages'
  | 'gangs'
  | 'apartments'
  | 'robberies'

export interface Coords {
  x: number
  y: number
  z: number
  w?: number
}

export interface CreatorEntity {
  id?: number
  name: string
  label: string
  coords?: Coords | null
  data: Record<string, unknown>
  active: boolean
  created_by?: string
  updated_by?: string
  created_at?: string
  updated_at?: string
}

export interface BootstrapData {
  modules: ModuleName[]
  counts: Record<string, number>
  locale: string
  framework: string
  autoSave: { enabled: boolean; intervalMs: number }
  permissions: { admin: boolean; modules: Record<string, boolean> }
}

export interface ApiResult<T = unknown> {
  ok: boolean
  data?: T
  message?: string
}
