import { useCallback, useEffect, useRef, useState } from 'react'

type FurnaceConfig = {
  targetMin: number
  targetMax: number
  overheat: number
  underheat: number
}

declare function GetParentResourceName(): string

async function postNui(event: string, data?: unknown): Promise<void> {
  try {
    const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'qbx_druglabs'
    await fetch(`https://${resource}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data ?? {}),
    })
  } catch {
    // ignore outside FiveM
  }
}

export default function App() {
  const [open, setOpen] = useState(false)
  const [cfg, setCfg] = useState<FurnaceConfig>({
    targetMin: 75,
    targetMax: 85,
    overheat: 95,
    underheat: 60,
  })
  const [temp, setTemp] = useState(50)
  const [holding, setHolding] = useState(false)
  const [timeLeft, setTimeLeft] = useState(12)
  const tempRef = useRef(50)
  const holdingRef = useRef(false)
  const finishedRef = useRef(false)

  const finish = useCallback((cancelled: boolean) => {
    if (finishedRef.current) return
    finishedRef.current = true
    setOpen(false)
    setHolding(false)
    holdingRef.current = false
    void postNui(
      'furnaceResult',
      cancelled ? { cancelled: true, temperature: 0 } : { temperature: Math.round(tempRef.current) },
    )
  }, [])

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const { action, data } = event.data || {}
      if (action === 'openFurnace') {
        finishedRef.current = false
        setCfg({
          targetMin: data?.targetMin ?? 75,
          targetMax: data?.targetMax ?? 85,
          overheat: data?.overheat ?? 95,
          underheat: data?.underheat ?? 60,
        })
        const start = 55 + Math.random() * 10
        tempRef.current = start
        setTemp(start)
        setTimeLeft(12)
        setOpen(true)
      }
      if (action === 'close') {
        finish(true)
      }
    }
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') finish(true)
    }
    window.addEventListener('message', onMessage)
    window.addEventListener('keydown', onKey)
    return () => {
      window.removeEventListener('message', onMessage)
      window.removeEventListener('keydown', onKey)
    }
  }, [finish])

  useEffect(() => {
    if (!open) return

    const tick = window.setInterval(() => {
      const next = Math.max(
        20,
        Math.min(120, tempRef.current + (holdingRef.current ? 1.8 : -0.9) + (Math.random() - 0.45) * 2.2),
      )
      tempRef.current = next
      setTemp(next)
      setTimeLeft((s) => {
        if (s <= 1) {
          finish(false)
          return 0
        }
        return s - 1
      })
    }, 1000)

    return () => window.clearInterval(tick)
  }, [open, finish])

  if (!open) return null

  const inTarget = temp >= cfg.targetMin && temp <= cfg.targetMax
  const overheating = temp >= cfg.overheat
  const under = temp <= cfg.underheat

  return (
    <div className="overlay">
      <div className="panel">
        <header>
          <h1>Furnace Control</h1>
          <p>
            Hold heat to stabilize between {cfg.targetMin}°C and {cfg.targetMax}°C
          </p>
        </header>

        <div className={`gauge ${overheating ? 'danger' : inTarget ? 'ok' : under ? 'cold' : ''}`}>
          <div className="gauge-fill" style={{ height: `${((temp - 20) / 100) * 100}%` }} />
          <div
            className="target-band"
            style={{
              bottom: `${((cfg.targetMin - 20) / 100) * 100}%`,
              height: `${((cfg.targetMax - cfg.targetMin) / 100) * 100}%`,
            }}
          />
          <strong>{Math.round(temp)}°C</strong>
        </div>

        <div className="meta">
          <span>{timeLeft}s</span>
          <span>{overheating ? 'OVERHEAT' : inTarget ? 'STABLE' : under ? 'TOO COLD' : 'ADJUST'}</span>
        </div>

        <button
          className={`heat-btn ${holding ? 'active' : ''}`}
          onMouseDown={() => {
            holdingRef.current = true
            setHolding(true)
          }}
          onMouseUp={() => {
            holdingRef.current = false
            setHolding(false)
          }}
          onMouseLeave={() => {
            holdingRef.current = false
            setHolding(false)
          }}
          onTouchStart={() => {
            holdingRef.current = true
            setHolding(true)
          }}
          onTouchEnd={() => {
            holdingRef.current = false
            setHolding(false)
          }}
        >
          Hold to heat
        </button>

        <div className="actions">
          <button className="ghost" onClick={() => finish(true)}>
            Cancel
          </button>
          <button className="primary" onClick={() => finish(false)}>
            Lock temperature
          </button>
        </div>
      </div>
    </div>
  )
}
